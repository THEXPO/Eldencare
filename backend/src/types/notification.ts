export interface DeviceTokenRecord {
  id: string;
  user_id: string;
  fcm_token: string;
  device_platform: 'android' | 'ios' | 'web' | 'windows' | 'macos' | 'linux';
  device_name?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
  last_used_at: string;
}

export interface NotificationPreferenceRecord {
  id: string;
  user_id: string;
  medication_reminders_enabled: boolean;
  diet_reminders_enabled: boolean;
  exercise_reminders_enabled: boolean;
  appointment_reminders_enabled: boolean;
  caretaker_alerts_enabled: boolean;
  quiet_hours_enabled: boolean;
  quiet_hours_start: string;
  quiet_hours_end: string;
  timezone: string;
  created_at: string;
  updated_at: string;
}

export interface NotificationRecord {
  id: string;
  recipient_user_id: string;
  patient_id?: string;
  notification_type:
    | 'medication'
    | 'diet'
    | 'exercise'
    | 'appointment'
    | 'dual_confirmation'
    | 'caretaker_alert'
    | 'doctor_alert'
    | 'general';
  title: string;
  body: string;
  related_entity_type?: string;
  related_entity_id?: string;
  scheduled_at: string;
  sent_at?: string;
  delivery_status: 'pending' | 'in_progress' | 'sent' | 'failed' | 'skipped_quiet_hours' | 'cancelled';
  read_at?: string;
  retry_count: number;
  idempotency_key?: string;
  created_at: string;
}
