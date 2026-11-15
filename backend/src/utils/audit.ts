import { SupabaseClient } from '@supabase/supabase-js';
import { logger } from './logger';

export interface AuditParams {
  patientId: string;
  actorId: string;
  actorRole: string;
  action: string;
  entityType: string;
  entityId?: string;
  supabase?: SupabaseClient;
}

export async function recordAuditLog(params: AuditParams): Promise<void> {
  try {
    logger.info(`AUDIT: [${params.actorRole}] performed [${params.action}] on [${params.entityType}:${params.entityId || 'N/A'}] for patient [${params.patientId}]`);
    
    if (params.supabase) {
      await params.supabase.from('audit_logs').insert({
        patient_id: params.patientId,
        actor_id: params.actorId,
        actor_role: params.actorRole,
        action: params.action,
        entity_type: params.entityType,
        entity_id: params.entityId,
      });
    }
  } catch (err) {
    logger.warn('Failed to persist audit log to DB, recorded in application log only.', err);
  }
}
