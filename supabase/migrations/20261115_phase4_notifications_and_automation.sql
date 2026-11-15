-- =============================================================================
-- EldenCare Phase 4: Notifications, Device Tokens & Automation Migration
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Device Tokens Table (FCM Registration per Device)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL UNIQUE,
    device_platform TEXT NOT NULL CHECK (device_platform IN ('android', 'ios', 'web', 'windows', 'macos', 'linux')),
    device_name TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    last_used_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON public.device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_active ON public.device_tokens(user_id, is_active);

-- -----------------------------------------------------------------------------
-- 2. Notification Preferences Table
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    medication_reminders_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    diet_reminders_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    exercise_reminders_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    appointment_reminders_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    caretaker_alerts_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    quiet_hours_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    quiet_hours_start TEXT NOT NULL DEFAULT '22:00',
    quiet_hours_end TEXT NOT NULL DEFAULT '07:00',
    timezone TEXT NOT NULL DEFAULT 'UTC',
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notif_prefs_user ON public.notification_preferences(user_id);

-- -----------------------------------------------------------------------------
-- 3. Notification Records Table (History, Queue & Idempotency)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notification_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    patient_id UUID REFERENCES public.patient_workspaces(id) ON DELETE SET NULL,
    notification_type TEXT NOT NULL CHECK (
        notification_type IN (
            'medication',
            'diet',
            'exercise',
            'appointment',
            'dual_confirmation',
            'caretaker_alert',
            'doctor_alert',
            'general'
        )
    ),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    related_entity_type TEXT,
    related_entity_id TEXT,
    scheduled_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    sent_at TIMESTAMPTZ,
    delivery_status TEXT NOT NULL CHECK (
        delivery_status IN ('pending', 'in_progress', 'sent', 'failed', 'skipped_quiet_hours', 'cancelled')
    ) DEFAULT 'pending',
    read_at TIMESTAMPTZ,
    retry_count INTEGER NOT NULL DEFAULT 0,
    idempotency_key TEXT UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notif_records_recipient ON public.notification_records(recipient_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notif_records_pending ON public.notification_records(delivery_status, scheduled_at)
    WHERE delivery_status = 'pending';
CREATE INDEX IF NOT EXISTS idx_notif_records_idempotency ON public.notification_records(idempotency_key);

-- -----------------------------------------------------------------------------
-- 4. Trigger: Default Notification Preferences on User Creation
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_user_preferences()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.notification_preferences (user_id)
    VALUES (new.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_profile_created_prefs ON public.profiles;
CREATE TRIGGER on_profile_created_prefs
    AFTER INSERT ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_user_preferences();

-- -----------------------------------------------------------------------------
-- 5. Row Level Security (RLS) Policies
-- -----------------------------------------------------------------------------
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_records ENABLE ROW LEVEL SECURITY;

-- Device Tokens Policies
CREATE POLICY "Users can manage own device tokens"
    ON public.device_tokens FOR ALL
    USING (user_id = auth.uid());

-- Notification Preferences Policies
CREATE POLICY "Users can view and edit own preferences"
    ON public.notification_preferences FOR ALL
    USING (user_id = auth.uid());

-- Notification Records Policies
CREATE POLICY "Recipients can view own notification records"
    ON public.notification_records FOR SELECT
    USING (recipient_user_id = auth.uid());

CREATE POLICY "Recipients can mark own notifications as read"
    ON public.notification_records FOR UPDATE
    USING (recipient_user_id = auth.uid())
    WITH CHECK (recipient_user_id = auth.uid());
