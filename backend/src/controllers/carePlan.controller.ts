import { Response } from 'express';
import { AuthenticatedRequest, CarePlanVersionRecord } from '../types';
import { CarePlanService } from '../services/carePlan.service';
import { NotificationTriggerService } from '../services/notificationTrigger.service';
import { recordAuditLog } from '../utils/audit';

export const CarePlanController = {
  getCarePlans: async (req: AuthenticatedRequest, res: Response) => {
    const { patientId } = req.params;

    if (req.supabase) {
      const { data, error } = await req.supabase
        .from('care_plan_versions')
        .select('*')
        .eq('patient_id', patientId)
        .order('version_number', { ascending: false });

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
      res.json({ success: true, carePlans: data || [] });
      return;
    }

    res.json({ success: true, carePlans: [] });
  },

  createCarePlan: async (req: AuthenticatedRequest, res: Response) => {
    const { patientId } = req.params;
    const { title, summary_of_changes, activate, medications_snapshot, diet_snapshot, exercise_snapshot } = req.body;

    if (req.user?.role !== 'doctor') {
      res.status(403).json({ error: 'Forbidden', message: 'Only authorized doctors can author care plans.' });
      return;
    }

    let versionNumber = 1;

    if (req.supabase) {
      // Find latest version
      const { data: latest } = await req.supabase
        .from('care_plan_versions')
        .select('version_number')
        .eq('patient_id', patientId)
        .order('version_number', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (latest) {
        versionNumber = latest.version_number + 1;
      }

      if (activate) {
        // Mark existing active versions as superseded
        await req.supabase
          .from('care_plan_versions')
          .update({ status: 'superseded' })
          .eq('patient_id', patientId)
          .eq('status', 'active');
      }

      const { data, error } = await req.supabase
        .from('care_plan_versions')
        .insert({
          patient_id: patientId,
          version_number: versionNumber,
          title,
          doctor_name: req.user.fullName,
          doctor_id: req.user.id,
          status: activate ? 'active' : 'draft',
          summary_of_changes,
          medications_snapshot: medications_snapshot || [],
          diet_snapshot: diet_snapshot || [],
          exercise_snapshot: exercise_snapshot || [],
        })
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      await recordAuditLog({
        patientId,
        actorId: req.user.id,
        actorRole: 'doctor',
        action: activate ? 'ACTIVATE_CARE_PLAN' : 'CREATE_CARE_PLAN_DRAFT',
        entityType: 'CARE_PLAN_VERSION',
        entityId: data.id,
        supabase: req.supabase,
      });

      res.status(201).json({ success: true, carePlan: data });
      return;
    }

    res.status(201).json({
      success: true,
      carePlan: {
        id: `plan_${Date.now()}`,
        patient_id: patientId,
        version_number: 1,
        title,
        doctor_name: req.user?.fullName,
        status: activate ? 'active' : 'draft',
        summary_of_changes,
        medications_snapshot,
        diet_snapshot,
        exercise_snapshot,
      },
    });
  },

  activateCarePlan: async (req: AuthenticatedRequest, res: Response) => {
    const { planId } = req.params;
    const { patientId } = req.body;

    if (req.user?.role !== 'doctor') {
      res.status(403).json({ error: 'Forbidden', message: 'Only authorized doctors can activate care plans.' });
      return;
    }

    if (req.supabase && patientId) {
      try {
        const activated = await CarePlanService.activateCarePlan(
          req.supabase,
          patientId,
          planId,
          req.user.fullName,
          req.user.id
        );

        await recordAuditLog({
          patientId,
          actorId: req.user.id,
          actorRole: 'doctor',
          action: 'ACTIVATE_CARE_PLAN',
          entityType: 'CARE_PLAN_VERSION',
          entityId: planId,
          supabase: req.supabase,
        });

        // Trigger notification to patient and caretaker
        NotificationTriggerService.handleCarePlanActivated(req.supabase, {
          patientId,
          planTitle: activated?.title || 'Care Plan',
          doctorName: req.user.fullName,
          planId,
        }).catch((err) => console.error('Care plan notification trigger error:', err));

        res.json({ success: true, carePlan: activated });
        return;
      } catch (err: any) {
        res.status(500).json({ error: err.message });
        return;
      }
    }

    res.json({ success: true, carePlan: { id: planId, status: 'active' } });
  },
};
