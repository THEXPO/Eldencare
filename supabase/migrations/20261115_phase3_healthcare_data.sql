-- =============================================================================
-- EldenCare Phase 3: Healthcare Data Structures, Cloud Sync & RLS Migration
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Medications Table
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.medications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patient_workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    strength TEXT NOT NULL,
    dosage TEXT NOT NULL,
    dosage_form TEXT NOT NULL DEFAULT 'tablet',
    meal_instruction TEXT,
    scheduled_times_minutes INTEGER[] NOT NULL DEFAULT '{}',
    start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_date TIMESTAMPTZ,
    additional_instructions TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_medications_patient ON public.medications(patient_id);
CREATE INDEX IF NOT EXISTS idx_medications_active ON public.medications(patient_id, is_active);

-- -----------------------------------------------------------------------------
-- 2. Daily Tasks Table (Unified for Medication, Diet, Exercise)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.daily_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patient_workspaces(id) ON DELETE CASCADE,
    task_type TEXT NOT NULL CHECK (task_type IN ('medication', 'diet', 'exercise')),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    instructions TEXT,
    scheduled_time_minutes INTEGER NOT NULL,
    source_medication_id UUID REFERENCES public.medications(id) ON DELETE SET NULL,
    meal_slot TEXT,
    dual_confirmation_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_tasks_patient ON public.daily_tasks(patient_id);

-- -----------------------------------------------------------------------------
-- 3. Task Confirmations (Independent Dual Confirmations)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.task_confirmations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_instance_id TEXT NOT NULL,
    patient_id UUID NOT NULL REFERENCES public.patient_workspaces(id) ON DELETE CASCADE,
    actor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    actor_role TEXT NOT NULL CHECK (actor_role IN ('patient', 'caretaker')),
    response TEXT NOT NULL CHECK (response IN ('completed', 'not_completed')),
    actor_name TEXT NOT NULL DEFAULT 'User',
    timestamp TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT unique_instance_actor UNIQUE (task_instance_id, actor_role)
);

CREATE INDEX IF NOT EXISTS idx_confirmations_instance ON public.task_confirmations(task_instance_id);
CREATE INDEX IF NOT EXISTS idx_confirmations_patient ON public.task_confirmations(patient_id);

-- -----------------------------------------------------------------------------
-- 4. Task Discrepancies Table
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.task_discrepancies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_instance_id TEXT NOT NULL,
    patient_id UUID NOT NULL REFERENCES public.patient_workspaces(id) ON DELETE CASCADE,
    task_title TEXT NOT NULL,
    patient_response TEXT NOT NULL,
    caretaker_response TEXT NOT NULL,
    patient_actor_name TEXT NOT NULL,
    caretaker_actor_name TEXT NOT NULL,
    occurred_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    doctor_review_notes TEXT,
    reviewed_at TIMESTAMPTZ,
    reviewed_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_discrepancies_patient ON public.task_discrepancies(patient_id);

-- -----------------------------------------------------------------------------
-- 5. Blood Pressure Readings
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.blood_pressure_readings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patient_workspaces(id) ON DELETE CASCADE,
    systolic INTEGER NOT NULL,
    diastolic INTEGER NOT NULL,
    recorded_by TEXT NOT NULL,
    recorded_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_bp_patient_date ON public.blood_pressure_readings(patient_id, recorded_at DESC);

-- -----------------------------------------------------------------------------
-- 6. Glucose Readings
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.glucose_readings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patient_workspaces(id) ON DELETE CASCADE,
    value NUMERIC(6, 2) NOT NULL,
    unit TEXT NOT NULL DEFAULT 'mg/dL',
    recorded_by TEXT NOT NULL,
    recorded_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_glucose_patient_date ON public.glucose_readings(patient_id, recorded_at DESC);

-- -----------------------------------------------------------------------------
-- 7. Appointments Table
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patient_workspaces(id) ON DELETE CASCADE,
    doctor_name TEXT NOT NULL,
    specialty TEXT NOT NULL,
    date_time TIMESTAMPTZ NOT NULL,
    location TEXT NOT NULL,
    notes TEXT,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_appointments_patient ON public.appointments(patient_id, date_time);

-- -----------------------------------------------------------------------------
-- 8. Care Plan Versions Table
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.care_plan_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patient_workspaces(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    title TEXT NOT NULL,
    doctor_name TEXT NOT NULL,
    doctor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    status TEXT NOT NULL CHECK (status IN ('draft', 'active', 'superseded')) DEFAULT 'draft',
    summary_of_changes TEXT NOT NULL,
    medications_snapshot JSONB NOT NULL DEFAULT '[]'::jsonb,
    diet_snapshot JSONB NOT NULL DEFAULT '[]'::jsonb,
    exercise_snapshot JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_care_plans_patient ON public.care_plan_versions(patient_id, version_number DESC);

-- -----------------------------------------------------------------------------
-- 9. Consultation Notes Table
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.consultation_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patient_workspaces(id) ON DELETE CASCADE,
    doctor_name TEXT NOT NULL,
    doctor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    observations TEXT NOT NULL,
    follow_up_instructions TEXT NOT NULL,
    suggested_follow_up_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_consultations_patient ON public.consultation_notes(patient_id, date DESC);

-- -----------------------------------------------------------------------------
-- 10. Audit Logs Table
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patient_workspaces(id) ON DELETE CASCADE,
    actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    actor_role TEXT NOT NULL,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_audit_patient ON public.audit_logs(patient_id, timestamp DESC);

-- =============================================================================
-- Row Level Security (RLS) Helper Functions & Policies
-- =============================================================================

-- Helper function: Check if auth user has access to patient workspace
CREATE OR REPLACE FUNCTION public.has_workspace_access(p_workspace_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        -- 1. Owner patient
        SELECT 1 FROM public.patient_workspaces pw
        WHERE pw.id = p_workspace_id AND pw.patient_user_id = auth.uid()
        UNION ALL
        -- 2. Active care team member
        SELECT 1 FROM public.care_team_members ctm
        WHERE ctm.patient_id = p_workspace_id AND ctm.user_id = auth.uid() AND ctm.status = 'active'
        UNION ALL
        -- 3. Approved assigned doctor
        SELECT 1 FROM public.doctor_patient_assignments dpa
        WHERE dpa.patient_id = p_workspace_id AND dpa.doctor_user_id = auth.uid() AND dpa.status = 'approved'
    );
$$;

-- Enable RLS on all healthcare tables
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_confirmations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_discrepancies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blood_pressure_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.glucose_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.care_plan_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consultation_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Unified RLS Policies using has_workspace_access()
CREATE POLICY "Medications access" ON public.medications FOR ALL USING (public.has_workspace_access(patient_id));
CREATE POLICY "Daily tasks access" ON public.daily_tasks FOR ALL USING (public.has_workspace_access(patient_id));
CREATE POLICY "Confirmations access" ON public.task_confirmations FOR ALL USING (public.has_workspace_access(patient_id));
CREATE POLICY "Discrepancies access" ON public.task_discrepancies FOR ALL USING (public.has_workspace_access(patient_id));
CREATE POLICY "BP readings access" ON public.blood_pressure_readings FOR ALL USING (public.has_workspace_access(patient_id));
CREATE POLICY "Glucose readings access" ON public.glucose_readings FOR ALL USING (public.has_workspace_access(patient_id));
CREATE POLICY "Appointments access" ON public.appointments FOR ALL USING (public.has_workspace_access(patient_id));
CREATE POLICY "Care plans access" ON public.care_plan_versions FOR ALL USING (public.has_workspace_access(patient_id));
CREATE POLICY "Consultation notes access" ON public.consultation_notes FOR ALL USING (public.has_workspace_access(patient_id));
CREATE POLICY "Audit logs read access" ON public.audit_logs FOR SELECT USING (public.has_workspace_access(patient_id));
