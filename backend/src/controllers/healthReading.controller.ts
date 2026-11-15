import { Response } from 'express';
import { AuthenticatedRequest } from '../types';
import { recordAuditLog } from '../utils/audit';

export const HealthReadingController = {
  getReadings: async (req: AuthenticatedRequest, res: Response) => {
    const { patientId } = req.params;

    if (req.supabase) {
      const [bpRes, gluRes] = await Promise.all([
        req.supabase
          .from('blood_pressure_readings')
          .select('*')
          .eq('patient_id', patientId)
          .order('recorded_at', { ascending: false }),
        req.supabase
          .from('glucose_readings')
          .select('*')
          .eq('patient_id', patientId)
          .order('recorded_at', { ascending: false }),
      ]);

      res.json({
        success: true,
        bloodPressure: bpRes.data || [],
        glucose: gluRes.data || [],
      });
      return;
    }

    res.json({ success: true, bloodPressure: [], glucose: [] });
  },

  createBloodPressure: async (req: AuthenticatedRequest, res: Response) => {
    const { patientId } = req.params;
    const { systolic, diastolic, recorded_at, notes } = req.body;
    const recordedBy = req.user?.fullName || 'User';

    let saved: any = {
      id: `bp_${Date.now()}`,
      patient_id: patientId,
      systolic,
      diastolic,
      recorded_by: recordedBy,
      recorded_at: recorded_at || new Date().toISOString(),
      notes,
    };

    if (req.supabase) {
      const { data, error } = await req.supabase
        .from('blood_pressure_readings')
        .insert({
          patient_id: patientId,
          systolic,
          diastolic,
          recorded_by: recordedBy,
          recorded_at: recorded_at || new Date().toISOString(),
          notes,
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
      actorId: req.user?.id || 'unknown',
      actorRole: req.user?.role || 'user',
      action: 'RECORD_BLOOD_PRESSURE',
      entityType: 'HEALTH_READING',
      entityId: saved.id,
      supabase: req.supabase,
    });

    res.status(201).json({ success: true, reading: saved });
  },

  createGlucose: async (req: AuthenticatedRequest, res: Response) => {
    const { patientId } = req.params;
    const { value, unit, recorded_at, notes } = req.body;
    const recordedBy = req.user?.fullName || 'User';

    let saved: any = {
      id: `glu_${Date.now()}`,
      patient_id: patientId,
      value,
      unit: unit || 'mg/dL',
      recorded_by: recordedBy,
      recorded_at: recorded_at || new Date().toISOString(),
      notes,
    };

    if (req.supabase) {
      const { data, error } = await req.supabase
        .from('glucose_readings')
        .insert({
          patient_id: patientId,
          value,
          unit: unit || 'mg/dL',
          recorded_by: recordedBy,
          recorded_at: recorded_at || new Date().toISOString(),
          notes,
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
      actorId: req.user?.id || 'unknown',
      actorRole: req.user?.role || 'user',
      action: 'RECORD_GLUCOSE',
      entityType: 'HEALTH_READING',
      entityId: saved.id,
      supabase: req.supabase,
    });

    res.status(201).json({ success: true, reading: saved });
  },
};
