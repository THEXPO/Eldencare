import { SupabaseClient } from '@supabase/supabase-js';
import { FcmService } from './fcm.service';
import { logger } from '../utils/logger';

export class NotificationTriggerService {
  /**
   * Dispatches push notifications when task confirmations are submitted or discrepancies occur.
   */
  static async handleConfirmationEvent(
    supabase: SupabaseClient | undefined,
    params: {
      taskInstanceId: string;
      patientId: string;
      taskTitle: string;
      actorRole: 'patient' | 'caretaker';
      actorName: string;
      isDiscrepancy: boolean;
      patientResponse?: string;
      caretakerResponse?: string;
    }
  ): Promise<void> {
    if (!supabase) return;

    try {
      if (params.isDiscrepancy) {
        // Discrepancy Alert -> Notify Caretaker and Assigned Doctor
        const recipients = await getCaretakersAndDoctors(supabase, params.patientId);

        for (const recipientId of recipients) {
          const title = 'Task Discrepancy Alert';
          const body = `Discrepancy recorded for "${params.taskTitle}". Patient: ${params.patientResponse}, Caretaker: ${params.caretakerResponse}.`;
          
          await recordAndSendPush(supabase, {
            recipientId,
            patientId: params.patientId,
            type: 'dual_confirmation',
            title,
            body,
            relatedEntityType: 'DISCREPANCY',
            relatedEntityId: params.taskInstanceId,
            isUrgent: true,
          });
        }
      } else if (params.actorRole === 'patient') {
        // Patient confirmed first -> Notify active Caretaker
        const caretakerIds = await getActiveCaretakers(supabase, params.patientId);
        for (const caretakerId of caretakerIds) {
          await recordAndSendPush(supabase, {
            recipientId: caretakerId,
            patientId: params.patientId,
            type: 'dual_confirmation',
            title: 'Patient Confirmation Logged',
            body: `${params.actorName} marked "${params.taskTitle}" as done. Please verify.`,
            relatedEntityType: 'TASK_INSTANCE',
            relatedEntityId: params.taskInstanceId,
            isUrgent: false,
          });
        }
      } else if (params.actorRole === 'caretaker') {
        // Caretaker confirmed first -> Notify Patient
        const patientUserId = await getPatientUserId(supabase, params.patientId);
        if (patientUserId) {
          await recordAndSendPush(supabase, {
            recipientId: patientUserId,
            patientId: params.patientId,
            type: 'dual_confirmation',
            title: 'Caretaker Verified Activity',
            body: `Caretaker ${params.actorName} logged verification for "${params.taskTitle}".`,
            relatedEntityType: 'TASK_INSTANCE',
            relatedEntityId: params.taskInstanceId,
            isUrgent: false,
          });
        }
      }
    } catch (err) {
      logger.error('Error handling confirmation notification trigger:', err);
    }
  }

  /**
   * Dispatches push notifications when a Doctor activates an updated care plan.
   */
  static async handleCarePlanActivated(
    supabase: SupabaseClient | undefined,
    params: {
      patientId: string;
      planTitle: string;
      doctorName: string;
      planId: string;
    }
  ): Promise<void> {
    if (!supabase) return;

    try {
      const patientUserId = await getPatientUserId(supabase, params.patientId);
      const caretakerIds = await getActiveCaretakers(supabase, params.patientId);
      const allRecipients = patientUserId ? [patientUserId, ...caretakerIds] : caretakerIds;

      for (const recipientId of allRecipients) {
        await recordAndSendPush(supabase, {
          recipientId,
          patientId: params.patientId,
          type: 'doctor_alert',
          title: 'Care Plan Updated',
          body: `${params.doctorName} activated a new care plan: "${params.planTitle}".`,
          relatedEntityType: 'CARE_PLAN',
          relatedEntityId: params.planId,
          isUrgent: false,
        });
      }
    } catch (err) {
      logger.error('Error handling care plan activated notification:', err);
    }
  }
}

// ---------------------------------------------------------------------------
// Helper Queries
// ---------------------------------------------------------------------------

async function getPatientUserId(supabase: SupabaseClient, patientWorkspaceId: string): Promise<string | null> {
  const { data } = await supabase
    .from('patient_workspaces')
    .select('patient_user_id')
    .eq('id', patientWorkspaceId)
    .maybeSingle();
  return data?.patient_user_id || null;
}

async function getActiveCaretakers(supabase: SupabaseClient, patientWorkspaceId: string): Promise<string[]> {
  const { data } = await supabase
    .from('care_team_members')
    .select('user_id')
    .eq('patient_id', patientWorkspaceId)
    .eq('status', 'active');
  return (data || []).map((c) => c.user_id);
}

async function getCaretakersAndDoctors(supabase: SupabaseClient, patientWorkspaceId: string): Promise<string[]> {
  const [caretakers, doctors] = await Promise.all([
    supabase.from('care_team_members').select('user_id').eq('patient_id', patientWorkspaceId).eq('status', 'active'),
    supabase.from('doctor_patient_assignments').select('doctor_user_id').eq('patient_id', patientWorkspaceId).eq('status', 'approved'),
  ]);

  const set = new Set<string>();
  (caretakers.data || []).forEach((c) => set.add(c.user_id));
  (doctors.data || []).forEach((d) => set.add(d.doctor_user_id));
  return Array.from(set);
}

async function recordAndSendPush(
  supabase: SupabaseClient,
  params: {
    recipientId: string;
    patientId: string;
    type: string;
    title: string;
    body: string;
    relatedEntityType: string;
    relatedEntityId: string;
    isUrgent: boolean;
  }
): Promise<void> {
  // 1. Insert notification record
  const { data: record } = await supabase
    .from('notification_records')
    .insert({
      recipient_user_id: params.recipientId,
      patient_id: params.patientId,
      notification_type: params.type,
      title: params.title,
      body: params.body,
      related_entity_type: params.relatedEntityType,
      related_entity_id: params.relatedEntityId,
      delivery_status: 'pending',
      scheduled_at: new Date().toISOString(),
    })
    .select()
    .single();

  // 2. Fetch active FCM tokens for this user
  const { data: tokens } = await supabase
    .from('device_tokens')
    .select('fcm_token')
    .eq('user_id', params.recipientId)
    .eq('is_active', true);

  const tokenList = (tokens || []).map((t) => t.fcm_token);

  if (tokenList.length > 0) {
    const res = await FcmService.sendPushNotification(
      {
        tokens: tokenList,
        title: params.title,
        body: params.body,
        data: {
          entityType: params.relatedEntityType,
          entityId: params.relatedEntityId,
          patientId: params.patientId,
        },
        isUrgent: params.isUrgent,
      },
      supabase
    );

    if (record) {
      await supabase
        .from('notification_records')
        .update({
          delivery_status: res.successCount > 0 ? 'sent' : 'failed',
          sent_at: new Date().toISOString(),
        })
        .eq('id', record.id);
    }
  }
}
