import { z } from 'zod';

export const registerDeviceTokenSchema = z.object({
  fcm_token: z.string().min(1, 'FCM device token is required.'),
  device_platform: z.enum(['android', 'ios', 'web', 'windows', 'macos', 'linux']).default('android'),
  device_name: z.string().optional(),
});

export const updatePreferencesSchema = z.object({
  medication_reminders_enabled: z.boolean().optional(),
  diet_reminders_enabled: z.boolean().optional(),
  exercise_reminders_enabled: z.boolean().optional(),
  appointment_reminders_enabled: z.boolean().optional(),
  caretaker_alerts_enabled: z.boolean().optional(),
  quiet_hours_enabled: z.boolean().optional(),
  quiet_hours_start: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Invalid time format (HH:mm)').optional(),
  quiet_hours_end: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Invalid time format (HH:mm)').optional(),
  timezone: z.string().optional(),
});
