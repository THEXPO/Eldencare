import { Response } from 'express';
import { AuthenticatedRequest, ConfirmationRecord } from '../types';
import { DualConfirmationService } from '../services/dualConfirmation.service';
import { NotificationTriggerService } from '../services/notificationTrigger.service';
import { recordAuditLog } from '../utils/audit';

export const ConfirmationController = {
  submitConfirmation: async (req: AuthenticatedRequest, res: Response) => {
    const { instanceId } = req.params;
    const { patient_id, task_title, response } = req.body;
    const actorRole = req.user?.role;

    if (actorRole !== 'patient' && actorRole !== 'caretaker') {
      res.status(403).json({
        error: 'Forbidden',
        message: 'Only patients and caretakers can submit task completion confirmations.',
      });
      return;
    }

    let allConfirmations: ConfirmationRecord[] = [];

    if (req.supabase) {
      // Upsert confirmation record for this instance + actor_role
      const { data: record, error } = await req.supabase
        .from('task_confirmations')
        .upsert(
          {
            task_instance_id: instanceId,
            patient_id,
            actor_id: req.user?.id,
            actor_role: actorRole,
            actor_name: req.user?.fullName || 'User',
            response,
            timestamp: new Date().toISOString(),
          },
          { onConflict: 'task_instance_id,actor_role' }
        )
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      // Fetch all confirmations for this task instance to compute overall status
      const { data: confs } = await req.supabase
        .from('task_confirmations')
        .select('*')
        .eq('task_instance_id', instanceId);

      allConfirmations = (confs as ConfirmationRecord[]) || [record as ConfirmationRecord];
    } else {
      allConfirmations = [
        {
          id: `conf_${Date.now()}`,
          task_instance_id: instanceId,
          patient_id,
          actor_id: req.user?.id || 'demo-actor',
          actor_role: actorRole,
          response,
          actor_name: req.user?.fullName || 'User',
          timestamp: new Date().toISOString(),
        },
      ];
    }

    // Business Logic: Compute Dual Confirmation Status
    const statusResult = DualConfirmationService.calculateStatus(allConfirmations, true);

    // If discrepancy detected, persist into task_discrepancies
    if (statusResult.isDiscrepancy && req.supabase) {
      const patientConf = allConfirmations.find((c) => c.actor_role === 'patient');
      const caretakerConf = allConfirmations.find((c) => c.actor_role === 'caretaker');

      await req.supabase.from('task_discrepancies').upsert(
        {
          task_instance_id: instanceId,
          patient_id,
          task_title,
          patient_response: patientConf?.response || 'none',
          caretaker_response: caretakerConf?.response || 'none',
          patient_actor_name: patientConf?.actor_name || 'Patient',
          caretaker_actor_name: caretakerConf?.actor_name || 'Caretaker',
          occurred_at: new Date().toISOString(),
        },
        { onConflict: 'task_instance_id' }
      );
    }

    await recordAuditLog({
      patientId: patient_id,
      actorId: req.user?.id || 'unknown',
      actorRole,
      action: 'SUBMIT_CONFIRMATION',
      entityType: 'TASK_CONFIRMATION',
      entityId: instanceId,
      supabase: req.supabase,
    });

    // Trigger asynchronous notification dispatch
    NotificationTriggerService.handleConfirmationEvent(req.supabase, {
      taskInstanceId: instanceId,
      patientId: patient_id,
      taskTitle: task_title,
      actorRole,
      actorName: req.user?.fullName || 'User',
      isDiscrepancy: statusResult.isDiscrepancy,
      patientResponse: statusResult.patientResponse,
      caretakerResponse: statusResult.caretakerResponse,
    }).catch((err) => console.error('Notification trigger error:', err));

    res.status(200).json({
      success: true,
      instanceId,
      status: statusResult.status,
      isDiscrepancy: statusResult.isDiscrepancy,
      confirmations: allConfirmations,
    });
  },

  getConfirmations: async (req: AuthenticatedRequest, res: Response) => {
    const { instanceId } = req.params;

    if (req.supabase) {
      const { data, error } = await req.supabase
        .from('task_confirmations')
        .select('*')
        .eq('task_instance_id', instanceId);

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
      res.json({ success: true, confirmations: data || [] });
      return;
    }

    res.json({ success: true, confirmations: [] });
  },

  getDiscrepancies: async (req: AuthenticatedRequest, res: Response) => {
    const { patientId } = req.params;

    if (req.supabase) {
      const { data, error } = await req.supabase
        .from('task_discrepancies')
        .select('*')
        .eq('patient_id', patientId)
        .order('occurred_at', { ascending: false });

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
      res.json({ success: true, discrepancies: data || [] });
      return;
    }

    res.json({ success: true, discrepancies: [] });
  },

  reviewDiscrepancy: async (req: AuthenticatedRequest, res: Response) => {
    const { discrepancyId } = req.params;
    const { doctor_review_notes } = req.body;

    if (req.user?.role !== 'doctor') {
      res.status(403).json({ error: 'Forbidden', message: 'Only authorized doctors can review discrepancies.' });
      return;
    }

    if (req.supabase) {
      const { data, error } = await req.supabase
        .from('task_discrepancies')
        .update({
          doctor_review_notes,
          reviewed_at: new Date().toISOString(),
          reviewed_by: req.user.fullName,
        })
        .eq('id', discrepancyId)
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      await recordAuditLog({
        patientId: data.patient_id,
        actorId: req.user.id,
        actorRole: 'doctor',
        action: 'REVIEW_DISCREPANCY',
        entityType: 'TASK_DISCREPANCY',
        entityId: discrepancyId,
        supabase: req.supabase,
      });

      res.json({ success: true, discrepancy: data });
      return;
    }

    res.json({
      success: true,
      discrepancy: {
        id: discrepancyId,
        doctor_review_notes,
        reviewed_at: new Date().toISOString(),
        reviewed_by: req.user?.fullName,
      },
    });
  },
};
