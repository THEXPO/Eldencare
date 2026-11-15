import { Response } from 'express';
import { AuthenticatedRequest } from '../types';
import { recordAuditLog } from '../utils/audit';

export const ConsultationController = {
  getConsultations: async (req: AuthenticatedRequest, res: Response) => {
    const { patientId } = req.params;

    if (req.supabase) {
      const { data, error } = await req.supabase
        .from('consultation_notes')
        .select('*')
        .eq('patient_id', patientId)
        .order('date', { ascending: false });

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
      res.json({ success: true, consultations: data || [] });
      return;
    }

    res.json({ success: true, consultations: [] });
  },

  createConsultation: async (req: AuthenticatedRequest, res: Response) => {
    const { patientId } = req.params;
    const { date, observations, follow_up_instructions, suggested_follow_up_date } = req.body;

    if (req.user?.role !== 'doctor') {
      res.status(403).json({ error: 'Forbidden', message: 'Only authorized doctors can record consultation notes.' });
      return;
    }

    let saved: any = {
      id: `note_${Date.now()}`,
      patient_id: patientId,
      doctor_name: req.user.fullName,
      doctor_id: req.user.id,
      date: date || new Date().toISOString(),
      observations,
      follow_up_instructions,
      suggested_follow_up_date,
      created_at: new Date().toISOString(),
    };

    if (req.supabase) {
      const { data, error } = await req.supabase
        .from('consultation_notes')
        .insert({
          patient_id: patientId,
          doctor_name: req.user.fullName,
          doctor_id: req.user.id,
          date: date || new Date().toISOString(),
          observations,
          follow_up_instructions,
          suggested_follow_up_date,
        })
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
      saved = data;
    }

    await recordAuditLog({
      patientId,
      actorId: req.user.id,
      actorRole: 'doctor',
      action: 'ADD_CONSULTATION_NOTE',
      entityType: 'CONSULTATION_NOTE',
      entityId: saved.id,
      supabase: req.supabase,
    });

    res.status(201).json({ success: true, consultation: saved });
  },
};
