import { Response } from 'express';
import { AuthenticatedRequest } from '../types';

export const PatientController = {
  getPatients: async (req: AuthenticatedRequest, res: Response) => {
    // Return list of patient profiles accessible to this user
    if (req.supabase && req.user) {
      if (req.user.role === 'patient') {
        const { data } = await req.supabase
          .from('patient_workspaces')
          .select('id, patient_user_id, profiles(full_name, phone)')
          .eq('patient_user_id', req.user.id);
        res.json({ success: true, patients: data || [] });
        return;
      }

      if (req.user.role === 'caretaker') {
        const { data } = await req.supabase
          .from('care_team_members')
          .select('patient_id, relationship_role, status, patient_workspaces(patient_user_id, profiles(full_name))')
          .eq('user_id', req.user.id)
          .eq('status', 'active');
        res.json({ success: true, patients: data || [] });
        return;
      }

      if (req.user.role === 'doctor') {
        const { data } = await req.supabase
          .from('doctor_patient_assignments')
          .select('patient_id, status, patient_workspaces(patient_user_id, profiles(full_name))')
          .eq('doctor_user_id', req.user.id)
          .eq('status', 'approved');
        res.json({ success: true, patients: data || [] });
        return;
      }
    }

    // Demo Patients fallback
    res.json({
      success: true,
      patients: [
        {
          id: 'p1',
          fullName: 'Eleanor Vance',
          preferredName: 'Eleanor',
          age: 78,
          bloodGroup: 'O+',
          primaryDoctor: 'Dr. Sarah Nguyen, MD',
        },
        {
          id: 'p2',
          fullName: 'Arthur Vance',
          preferredName: 'Arthur',
          age: 82,
          bloodGroup: 'A+',
          primaryDoctor: 'Dr. Sarah Nguyen, MD',
        },
        {
          id: 'p3',
          fullName: 'Kamala Sharma',
          preferredName: 'Kamala',
          age: 74,
          bloodGroup: 'B+',
          primaryDoctor: 'Dr. Sarah Nguyen, MD',
        },
      ],
    });
  },

  getPatientOverview: async (req: AuthenticatedRequest, res: Response) => {
    const { patientId } = req.params;

    if (req.supabase) {
      const [meds, tasks, bps, glucose, appointments, discrepancies, carePlan] =
        await Promise.all([
          req.supabase.from('medications').select('*').eq('patient_id', patientId).eq('is_active', true),
          req.supabase.from('daily_tasks').select('*').eq('patient_id', patientId).eq('is_active', true),
          req.supabase.from('blood_pressure_readings').select('*').eq('patient_id', patientId).order('recorded_at', { ascending: false }).limit(5),
          req.supabase.from('glucose_readings').select('*').eq('patient_id', patientId).order('recorded_at', { ascending: false }).limit(5),
          req.supabase.from('appointments').select('*').eq('patient_id', patientId).order('date_time', { ascending: true }).limit(3),
          req.supabase.from('task_discrepancies').select('*').eq('patient_id', patientId),
          req.supabase.from('care_plan_versions').select('*').eq('patient_id', patientId).eq('status', 'active').maybeSingle(),
        ]);

      res.json({
        success: true,
        overview: {
          patientId,
          medications: meds.data || [],
          tasks: tasks.data || [],
          recentBloodPressure: bps.data || [],
          recentGlucose: glucose.data || [],
          upcomingAppointments: appointments.data || [],
          discrepancies: discrepancies.data || [],
          activeCarePlan: carePlan.data || null,
        },
      });
      return;
    }

    // Dev/Demo fallback response
    res.json({
      success: true,
      overview: {
        patientId,
        medications: [],
        tasks: [],
        recentBloodPressure: [],
        recentGlucose: [],
        upcomingAppointments: [],
        discrepancies: [],
        activeCarePlan: null,
      },
    });
  },
};
