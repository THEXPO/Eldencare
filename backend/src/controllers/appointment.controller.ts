import { Response } from 'express';
import { AuthenticatedRequest } from '../types';
import { SchedulerService } from '../services/scheduler.service';
import { recordAuditLog } from '../utils/audit';

export const AppointmentController = {
  getAppointments: async (req: AuthenticatedRequest, res: Response) => {
    const { patientId } = req.params;

    if (req.supabase) {
      const { data, error } = await req.supabase
        .from('appointments')
        .select('*')
        .eq('patient_id', patientId)
        .order('date_time', { ascending: true });

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
      res.json({ success: true, appointments: data || [] });
      return;
    }

    res.json({ success: true, appointments: [] });
  },

  createAppointment: async (req: AuthenticatedRequest, res: Response) => {
    const { patientId } = req.params;
    const apptData = req.body;

    let saved: any = {
      id: `appt_${Date.now()}`,
      patient_id: patientId,
      ...apptData,
      created_by: req.user?.id,
      created_at: new Date().toISOString(),
    };

    if (req.supabase) {
      const { data, error } = await req.supabase
        .from('appointments')
        .insert({
          patient_id: patientId,
          ...apptData,
          created_by: req.user?.id,
          updated_by: req.user?.id,
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
      action: 'CREATE_APPOINTMENT',
      entityType: 'APPOINTMENT',
      entityId: saved.id,
      supabase: req.supabase,
    });

    // Schedule automated 24-hour and 1-hour reminders
    SchedulerService.scheduleAppointmentReminders(req.supabase, {
      appointmentId: saved.id,
      patientId,
      dateTime: apptData.date_time,
      doctorName: apptData.doctor_name,
      specialty: apptData.specialty,
    }).catch((err) => console.error('Appointment reminder scheduling error:', err));

    res.status(201).json({ success: true, appointment: saved });
  },

  updateAppointment: async (req: AuthenticatedRequest, res: Response) => {
    const { appointmentId } = req.params;
    const updates = req.body;

    if (req.supabase) {
      const { data, error } = await req.supabase
        .from('appointments')
        .update({
          ...updates,
          updated_by: req.user?.id,
          updated_at: new Date().toISOString(),
        })
        .eq('id', appointmentId)
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      if (updates.date_time) {
        // Reschedule reminders for the new appointment time
        SchedulerService.cancelAppointmentReminders(req.supabase, appointmentId).then(() => {
          SchedulerService.scheduleAppointmentReminders(req.supabase, {
            appointmentId,
            patientId: data.patient_id,
            dateTime: data.date_time,
            doctorName: data.doctor_name,
            specialty: data.specialty,
          });
        }).catch((err) => console.error('Appointment reschedule reminder error:', err));
      }

      res.json({ success: true, appointment: data });
      return;
    }

    res.json({ success: true, appointment: { id: appointmentId, ...updates } });
  },

  deleteAppointment: async (req: AuthenticatedRequest, res: Response) => {
    const { appointmentId } = req.params;

    if (req.supabase) {
      // Cancel pending reminders for this appointment
      SchedulerService.cancelAppointmentReminders(req.supabase, appointmentId)
        .catch((err) => console.error('Appointment cancel reminder error:', err));

      const { error } = await req.supabase
        .from('appointments')
        .delete()
        .eq('id', appointmentId);

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
    }

    res.json({ success: true, message: 'Appointment deleted successfully.' });
  },
};
