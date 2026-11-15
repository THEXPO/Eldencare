import { Response } from 'express';
import { AuthenticatedRequest, MedicationRecord } from '../types';
import { DuplicateMedicationService } from '../services/duplicateMedication.service';
import { recordAuditLog } from '../utils/audit';

export const MedicationController = {
  getMedications: async (req: AuthenticatedRequest, res: Response) => {
    const { patientId } = req.params;

    if (req.supabase) {
      const { data, error } = await req.supabase
        .from('medications')
        .select('*')
        .eq('patient_id', patientId)
        .order('created_at', { ascending: false });

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
      res.json({ success: true, medications: data || [] });
      return;
    }

    res.json({ success: true, medications: [] });
  },

  createMedication: async (req: AuthenticatedRequest, res: Response) => {
    const { patientId } = req.params;
    const medData = req.body;

    let existingMeds: MedicationRecord[] = [];
    if (req.supabase) {
      const { data } = await req.supabase
        .from('medications')
        .select('*')
        .eq('patient_id', patientId);
      existingMeds = (data as MedicationRecord[]) || [];
    }

    // 1. Business Logic: Duplicate Medication Detection Check
    const duplicateCheck = DuplicateMedicationService.checkDuplicate(medData, existingMeds);

    // 2. Persist medication
    let savedMed: any = {
      id: `med_${Date.now()}`,
      patient_id: patientId,
      ...medData,
      created_by: req.user?.id,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    if (req.supabase) {
      const { data, error } = await req.supabase
        .from('medications')
        .insert({
          patient_id: patientId,
          ...medData,
          created_by: req.user?.id,
          updated_by: req.user?.id,
        })
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
      savedMed = data;
    }

    // Record audit log
    await recordAuditLog({
      patientId,
      actorId: req.user?.id || 'unknown',
      actorRole: req.user?.role || 'patient',
      action: 'CREATE_MEDICATION',
      entityType: 'MEDICATION',
      entityId: savedMed.id,
      supabase: req.supabase,
    });

    res.status(201).json({
      success: true,
      medication: savedMed,
      duplicateWarning: duplicateCheck.isDuplicate ? duplicateCheck : null,
    });
  },

  updateMedication: async (req: AuthenticatedRequest, res: Response) => {
    const { medicationId } = req.params;
    const updates = req.body;

    if (req.supabase) {
      const { data, error } = await req.supabase
        .from('medications')
        .update({
          ...updates,
          updated_by: req.user?.id,
          updated_at: new Date().toISOString(),
        })
        .eq('id', medicationId)
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      await recordAuditLog({
        patientId: data.patient_id,
        actorId: req.user?.id || 'unknown',
        actorRole: req.user?.role || 'user',
        action: 'UPDATE_MEDICATION',
        entityType: 'MEDICATION',
        entityId: medicationId,
        supabase: req.supabase,
      });

      res.json({ success: true, medication: data });
      return;
    }

    res.json({ success: true, medication: { id: medicationId, ...updates } });
  },

  deleteMedication: async (req: AuthenticatedRequest, res: Response) => {
    const { medicationId } = req.params;

    if (req.supabase) {
      const { error } = await req.supabase
        .from('medications')
        .delete()
        .eq('id', medicationId);

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
    }

    res.json({ success: true, message: 'Medication removed successfully.' });
  },
};
