import { SupabaseClient } from '@supabase/supabase-js';
import { FcmService } from './fcm.service';
import { logger } from '../utils/logger';

export class SchedulerService {
  private static timer: NodeJS.Timeout | null = null;
  private static isRunning = false;

  /**
   * Starts the persistent database-backed background scheduler.
   * Polls every 60 seconds for due notification jobs.
   */
  static start(supabase: SupabaseClient | null, intervalMs: number = 60000): void {
    if (this.timer) return;
    logger.info(`Starting Notification Scheduler (interval: ${intervalMs / 1000}s)...`);

    this.timer = setInterval(async () => {
      if (this.isRunning || !supabase) return;
      this.isRunning = true;
      try {
        await this.processDueNotifications(supabase);
      } catch (err) {
        logger.error('Error in scheduler cycle:', err);
      } finally {
        this.isRunning = false;
      }
    }, intervalMs);
  }

  static stop(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
      logger.info('Notification Scheduler stopped.');
    }
  }

  /**
   * Processes all pending notifications whose scheduled_at timestamp has passed.
   */
  static async processDueNotifications(supabase: SupabaseClient): Promise<number> {
    const nowIso = new Date().toISOString();

    // 1. Fetch due pending records
    const { data: dueRecords, error } = await supabase
      .from('notification_records')
      .select('*')
      .eq('delivery_status', 'pending')
      .lte('scheduled_at', nowIso)
      .limit(50);

    if (error || !dueRecords || dueRecords.length === 0) {
      return 0;
    }

    logger.info(`Scheduler: Processing ${dueRecords.length} due notification(s)...`);
    let processedCount = 0;

    for (const record of dueRecords) {
      try {
        // Mark as in-progress to prevent race conditions across parallel runs
        await supabase
          .from('notification_records')
          .update({ delivery_status: 'in_progress' })
          .eq('id', record.id);

        // Check recipient notification preferences & quiet hours
        const { data: prefs } = await supabase
          .from('notification_preferences')
          .select('*')
          .eq('user_id', record.recipient_user_id)
          .maybeSingle();

        if (prefs) {
          // Check if category is enabled in user preferences
          if (!isCategoryEnabled(record.notification_type, prefs)) {
            await supabase
              .from('notification_records')
              .update({ delivery_status: 'cancelled' })
              .eq('id', record.id);
            continue;
          }

          // Check Quiet Hours
          if (prefs.quiet_hours_enabled && isInQuietHours(prefs.quiet_hours_start, prefs.quiet_hours_end)) {
            // Postpone non-urgent notifications
            await supabase
              .from('notification_records')
              .update({ delivery_status: 'skipped_quiet_hours' })
              .eq('id', record.id);
            continue;
          }
        }

        // Fetch recipient active FCM tokens
        const { data: tokens } = await supabase
          .from('device_tokens')
          .select('fcm_token')
          .eq('user_id', record.recipient_user_id)
          .eq('is_active', true);

        const tokenList = (tokens || []).map((t) => t.fcm_token);

        if (tokenList.length > 0) {
          const pushRes = await FcmService.sendPushNotification(
            {
              tokens: tokenList,
              title: record.title,
              body: record.body,
              data: {
                notificationId: record.id,
                entityType: record.related_entity_type || '',
                entityId: record.related_entity_id || '',
              },
              isUrgent: record.notification_type === 'dual_confirmation',
            },
            supabase
          );

          await supabase
            .from('notification_records')
            .update({
              delivery_status: pushRes.successCount > 0 ? 'sent' : 'failed',
              sent_at: new Date().toISOString(),
            })
            .eq('id', record.id);
        } else {
          // In-app only delivery if no push devices registered
          await supabase
            .from('notification_records')
            .update({
              delivery_status: 'sent',
              sent_at: new Date().toISOString(),
            })
            .eq('id', record.id);
        }

        processedCount++;
      } catch (itemErr) {
        logger.error(`Error processing notification ${record.id}:`, itemErr);
        await supabase
          .from('notification_records')
          .update({
            delivery_status: 'failed',
            retry_count: (record.retry_count || 0) + 1,
          })
          .eq('id', record.id);
      }
    }

    return processedCount;
  }

  /**
   * Schedules automated 24-hour and 1-hour appointment reminders.
   * Prevents duplicates via unique idempotency keys.
   */
  static async scheduleAppointmentReminders(
    supabase: SupabaseClient | undefined,
    params: {
      appointmentId: string;
      patientId: string;
      dateTime: string;
      doctorName: string;
      specialty: string;
    }
  ): Promise<void> {
    if (!supabase) return;

    try {
      const apptDate = new Date(params.dateTime);
      const now = new Date();

      // Recipient IDs: Patient + Caretakers
      const { data: ws } = await supabase
        .from('patient_workspaces')
        .select('patient_user_id')
        .eq('id', params.patientId)
        .maybeSingle();

      const { data: caretakers } = await supabase
        .from('care_team_members')
        .select('user_id')
        .eq('patient_id', params.patientId)
        .eq('status', 'active');

      const recipientIds = new Set<string>();
      if (ws?.patient_user_id) recipientIds.add(ws.patient_user_id);
      (caretakers || []).forEach((c) => recipientIds.add(c.user_id));

      for (const recipientId of recipientIds) {
        // 1. 24-hour reminder
        const time24h = new Date(apptDate.getTime() - 24 * 60 * 60 * 1000);
        if (time24h > now) {
          await supabase.from('notification_records').upsert(
            {
              recipient_user_id: recipientId,
              patient_id: params.patientId,
              notification_type: 'appointment',
              title: 'Upcoming Appointment (Tomorrow)',
              body: `Appointment scheduled with ${params.doctorName} (${params.specialty}) tomorrow.`,
              related_entity_type: 'APPOINTMENT',
              related_entity_id: params.appointmentId,
              scheduled_at: time24h.toISOString(),
              delivery_status: 'pending',
              idempotency_key: `appt_24h_${params.appointmentId}_${recipientId}`,
            },
            { onConflict: 'idempotency_key' }
          );
        }

        // 2. 1-hour reminder
        const time1h = new Date(apptDate.getTime() - 60 * 60 * 1000);
        if (time1h > now) {
          await supabase.from('notification_records').upsert(
            {
              recipient_user_id: recipientId,
              patient_id: params.patientId,
              notification_type: 'appointment',
              title: 'Appointment Reminder (in 1 hour)',
              body: `Your appointment with ${params.doctorName} begins in 1 hour.`,
              related_entity_type: 'APPOINTMENT',
              related_entity_id: params.appointmentId,
              scheduled_at: time1h.toISOString(),
              delivery_status: 'pending',
              idempotency_key: `appt_1h_${params.appointmentId}_${recipientId}`,
            },
            { onConflict: 'idempotency_key' }
          );
        }
      }
    } catch (err) {
      logger.error('Failed to schedule appointment reminders:', err);
    }
  }

  /**
   * Cancels pending reminders when an appointment is rescheduled or deleted.
   */
  static async cancelAppointmentReminders(
    supabase: SupabaseClient | undefined,
    appointmentId: string
  ): Promise<void> {
    if (!supabase) return;

    try {
      await supabase
        .from('notification_records')
        .update({ delivery_status: 'cancelled' })
        .eq('related_entity_type', 'APPOINTMENT')
        .eq('related_entity_id', appointmentId)
        .eq('delivery_status', 'pending');
    } catch (err) {
      logger.error('Failed to cancel appointment reminders:', err);
    }
  }
}

// ---------------------------------------------------------------------------
// Quiet Hours & Category Helpers
// ---------------------------------------------------------------------------

function isCategoryEnabled(type: string, prefs: any): boolean {
  switch (type) {
    case 'medication':
      return prefs.medication_reminders_enabled;
    case 'diet':
      return prefs.diet_reminders_enabled;
    case 'exercise':
      return prefs.exercise_reminders_enabled;
    case 'appointment':
      return prefs.appointment_reminders_enabled;
    case 'caretaker_alert':
    case 'dual_confirmation':
      return prefs.caretaker_alerts_enabled;
    default:
      return true;
  }
}

export function isInQuietHours(startStr: string, endStr: string, now: Date = new Date()): boolean {
  try {
    const [startH, startM] = startStr.split(':').map(Number);
    const [endH, endM] = endStr.split(':').map(Number);

    const currentMinutes = now.getHours() * 60 + now.getMinutes();
    const startMinutes = startH * 60 + startM;
    const endMinutes = endH * 60 + endM;

    if (startMinutes < endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Overnights (e.g. 22:00 to 07:00)
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  } catch (_) {
    return false;
  }
}
