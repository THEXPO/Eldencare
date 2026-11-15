-- =============================================================================
-- EldenCare Phase 2: Authentication, User Accounts & Access Control Migration
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- -----------------------------------------------------------------------------
-- 1. Profiles Table
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('patient', 'caretaker', 'doctor')),
    phone TEXT,
    avatar_url TEXT,
    is_doctor_approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index for role lookup
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- -----------------------------------------------------------------------------
-- 2. Patient Workspaces Table
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.patient_workspaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_user_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_workspaces_patient ON public.patient_workspaces(patient_user_id);

-- -----------------------------------------------------------------------------
-- 3. Care Team Members Table (Patient - Caretaker Relationships)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.care_team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patient_workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    relationship_role TEXT NOT NULL DEFAULT 'primary_caretaker',
    permissions JSONB NOT NULL DEFAULT '{"can_record_vitals": true, "can_confirm_tasks": true, "can_manage_schedule": true}'::jsonb,
    status TEXT NOT NULL CHECK (status IN ('pending', 'active', 'revoked')) DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT unique_patient_caretaker UNIQUE (patient_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_care_team_user ON public.care_team_members(user_id);
CREATE INDEX IF NOT EXISTS idx_care_team_patient ON public.care_team_members(patient_id);

-- -----------------------------------------------------------------------------
-- 4. Doctor-Patient Assignments Table
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.doctor_patient_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patient_workspaces(id) ON DELETE CASCADE,
    doctor_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'inactive')) DEFAULT 'approved',
    assigned_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT unique_doctor_patient UNIQUE (patient_id, doctor_user_id)
);

CREATE INDEX IF NOT EXISTS idx_doctor_assignments_doc ON public.doctor_patient_assignments(doctor_user_id);
CREATE INDEX IF NOT EXISTS idx_doctor_assignments_pat ON public.doctor_patient_assignments(patient_id);

-- -----------------------------------------------------------------------------
-- 5. Invitations Table (Secure Single-Use Onboarding Tokens)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patient_workspaces(id) ON DELETE CASCADE,
    invitation_code_hash TEXT NOT NULL UNIQUE,
    intended_role TEXT NOT NULL CHECK (intended_role IN ('caretaker', 'doctor')),
    relationship_role TEXT DEFAULT 'family_caretaker',
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
    redeemed_at TIMESTAMPTZ,
    redeemed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_invitations_hash ON public.invitations(invitation_code_hash);

-- -----------------------------------------------------------------------------
-- 6. Trigger: Automatically Create Profile on Auth Signup
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    assigned_role TEXT;
    user_full_name TEXT;
    new_workspace_id UUID;
BEGIN
    -- Read metadata supplied at signup, falling back safely
    assigned_role := COALESCE(new.raw_user_meta_data->>'role', 'patient');
    IF assigned_role NOT IN ('patient', 'caretaker', 'doctor') THEN
        assigned_role := 'patient';
    END IF;

    user_full_name := COALESCE(new.raw_user_meta_data->>'full_name', 'EldenCare Member');

    -- Insert into public profiles
    INSERT INTO public.profiles (id, full_name, role, is_doctor_approved)
    VALUES (
        new.id,
        user_full_name,
        assigned_role,
        CASE WHEN assigned_role = 'doctor' THEN FALSE ELSE TRUE END
    );

    -- If patient, automatically provision their personal workspace
    IF assigned_role = 'patient' THEN
        INSERT INTO public.patient_workspaces (patient_user_id)
        VALUES (new.id)
        RETURNING id INTO new_workspace_id;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- -----------------------------------------------------------------------------
-- 7. Secure Invitation Creation & Redemption RPC Functions
-- -----------------------------------------------------------------------------

-- Create invitation code (hashes code before storage)
CREATE OR REPLACE FUNCTION public.create_invitation(
    p_code TEXT,
    p_intended_role TEXT,
    p_relationship_role TEXT DEFAULT 'family_caretaker'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_workspace_id UUID;
    v_code_hash TEXT;
    v_invitation_id UUID;
BEGIN
    -- Only patient or authorized caretaker can create invitations for their workspace
    SELECT id INTO v_workspace_id
    FROM public.patient_workspaces
    WHERE patient_user_id = auth.uid();

    IF v_workspace_id IS NULL THEN
        RAISE EXCEPTION 'Only patient owners can generate invitations for their workspace.';
    END IF;

    v_code_hash := encode(digest(upper(trim(p_code)), 'sha256'), 'hex');

    INSERT INTO public.invitations (
        patient_id,
        invitation_code_hash,
        intended_role,
        relationship_role,
        created_by
    )
    VALUES (
        v_workspace_id,
        v_code_hash,
        p_intended_role,
        p_relationship_role,
        auth.uid()
    )
    RETURNING id INTO v_invitation_id;

    RETURN jsonb_build_object(
        'success', true,
        'invitation_id', v_invitation_id,
        'code', upper(trim(p_code))
    );
END;
$$;

-- Redeem invitation code (atomic & single-use)
CREATE OR REPLACE FUNCTION public.redeem_invitation(p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_hash TEXT;
    v_inv RECORD;
    v_user_role TEXT;
BEGIN
    -- Verify authenticated user
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required.';
    END IF;

    SELECT role INTO v_user_role
    FROM public.profiles
    WHERE id = auth.uid();

    v_hash := encode(digest(upper(trim(p_code)), 'sha256'), 'hex');

    -- Find matching active invitation
    SELECT * INTO v_inv
    FROM public.invitations
    WHERE invitation_code_hash = v_hash
      AND redeemed_at IS NULL
      AND expires_at > NOW();

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Invalid or expired invitation code.');
    END IF;

    -- Verify role compatibility
    IF v_inv.intended_role <> v_user_role THEN
        RETURN jsonb_build_object('success', false, 'message', 'This invitation is reserved for role: ' || v_inv.intended_role);
    END IF;

    -- Create relationship based on role
    IF v_user_role = 'caretaker' THEN
        INSERT INTO public.care_team_members (patient_id, user_id, relationship_role, status)
        VALUES (v_inv.patient_id, auth.uid(), COALESCE(v_inv.relationship_role, 'primary_caretaker'), 'active')
        ON CONFLICT (patient_id, user_id)
        DO UPDATE SET status = 'active';
    ELSIF v_user_role = 'doctor' THEN
        INSERT INTO public.doctor_patient_assignments (patient_id, doctor_user_id, status)
        VALUES (v_inv.patient_id, auth.uid(), 'approved')
        ON CONFLICT (patient_id, doctor_user_id)
        DO UPDATE SET status = 'approved';
    END IF;

    -- Mark invitation as redeemed
    UPDATE public.invitations
    SET redeemed_at = NOW(),
        redeemed_by = auth.uid()
    WHERE id = v_inv.id;

    RETURN jsonb_build_object(
        'success', true,
        'patient_id', v_inv.patient_id,
        'message', 'Successfully connected to patient workspace.'
    );
END;
$$;

-- -----------------------------------------------------------------------------
-- 8. Row Level Security (RLS) Policies
-- -----------------------------------------------------------------------------

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.care_team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_patient_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;

-- A. Profiles Policies
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (id = auth.uid());

CREATE POLICY "Users can update own non-role profile fields"
    ON public.profiles FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid() AND role = (SELECT role FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Team members can view patient and peer profiles"
    ON public.profiles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.care_team_members ctm
            JOIN public.patient_workspaces pw ON pw.id = ctm.patient_id
            WHERE (ctm.user_id = auth.uid() AND (pw.patient_user_id = profiles.id OR ctm.user_id = profiles.id))
               OR (pw.patient_user_id = auth.uid() AND ctm.user_id = profiles.id)
        )
        OR
        EXISTS (
            SELECT 1 FROM public.doctor_patient_assignments dpa
            JOIN public.patient_workspaces pw ON pw.id = dpa.patient_id
            WHERE (dpa.doctor_user_id = auth.uid() AND (pw.patient_user_id = profiles.id OR dpa.doctor_user_id = profiles.id))
               OR (pw.patient_user_id = auth.uid() AND dpa.doctor_user_id = profiles.id)
        )
    );

-- B. Patient Workspaces Policies
CREATE POLICY "Patient can access own workspace"
    ON public.patient_workspaces FOR ALL
    USING (patient_user_id = auth.uid());

CREATE POLICY "Caretaker can access assigned workspace"
    ON public.patient_workspaces FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.care_team_members
            WHERE care_team_members.patient_id = patient_workspaces.id
              AND care_team_members.user_id = auth.uid()
              AND care_team_members.status = 'active'
        )
    );

CREATE POLICY "Doctor can access assigned workspace"
    ON public.patient_workspaces FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.doctor_patient_assignments
            WHERE doctor_patient_assignments.patient_id = patient_workspaces.id
              AND doctor_patient_assignments.doctor_user_id = auth.uid()
              AND doctor_patient_assignments.status = 'approved'
        )
    );

-- C. Care Team Members Policies
CREATE POLICY "Patients view and manage their own care team"
    ON public.care_team_members FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.patient_workspaces
            WHERE patient_workspaces.id = care_team_members.patient_id
              AND patient_workspaces.patient_user_id = auth.uid()
        )
    );

CREATE POLICY "Caretakers view their own care team memberships"
    ON public.care_team_members FOR SELECT
    USING (user_id = auth.uid());

-- D. Doctor Patient Assignments Policies
CREATE POLICY "Patients view their assigned doctors"
    ON public.doctor_patient_assignments FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.patient_workspaces
            WHERE patient_workspaces.id = doctor_patient_assignments.patient_id
              AND patient_workspaces.patient_user_id = auth.uid()
        )
    );

CREATE POLICY "Doctors view their own patient assignments"
    ON public.doctor_patient_assignments FOR SELECT
    USING (doctor_user_id = auth.uid());

-- E. Invitations Policies
CREATE POLICY "Patients can view and create invitations for their workspace"
    ON public.invitations FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.patient_workspaces
            WHERE patient_workspaces.id = invitations.patient_id
              AND patient_workspaces.patient_user_id = auth.uid()
        )
    );
