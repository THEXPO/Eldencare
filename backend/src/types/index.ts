import { Request } from 'express';
import { ParamsDictionary, Query } from 'express-serve-static-core';
import { SupabaseClient } from '@supabase/supabase-js';

export type AppRole = 'patient' | 'caretaker' | 'doctor';

export interface AuthenticatedUser {
  id: string;
  email: string;
  fullName: string;
  role: AppRole;
  isDoctorApproved: boolean;
  workspaceId?: string;
  authorizedPatientIds: string[];
}

export interface AuthenticatedRequest<
  P = ParamsDictionary,
  ResBody = any,
  ReqBody = any,
  ReqQuery = Query
> extends Request<P, ResBody, ReqBody, ReqQuery> {
  user?: AuthenticatedUser;
  token?: string;
  supabase?: SupabaseClient;
}

export interface MedicationRecord {
  id: string;
  patient_id: string;
  name: string;
  strength: string;
  dosage: string;
  dosage_form: string;
  meal_instruction?: string;
  scheduled_times_minutes: number[];
  start_date: string;
  end_date?: string;
  additional_instructions?: string;
  is_active: boolean;
  created_by?: string;
  updated_by?: string;
  created_at: string;
  updated_at: string;
}

export interface DailyTaskRecord {
  id: string;
  patient_id: string;
  task_type: 'medication' | 'diet' | 'exercise';
  title: string;
  description: string;
  instructions?: string;
  scheduled_time_minutes: number;
  source_medication_id?: string;
  meal_slot?: string;
  dual_confirmation_enabled: boolean;
  is_active: boolean;
  created_by?: string;
  updated_by?: string;
  created_at: string;
  updated_at: string;
}

export interface ConfirmationRecord {
  id: string;
  task_instance_id: string;
  patient_id: string;
  actor_id: string;
  actor_role: 'patient' | 'caretaker';
  response: 'completed' | 'not_completed';
  actor_name: string;
  timestamp: string;
}

export interface DiscrepancyRecord {
  id: string;
  task_instance_id: string;
  patient_id: string;
  task_title: string;
  patient_response: string;
  caretaker_response: string;
  patient_actor_name: string;
  caretaker_actor_name: string;
  occurred_at: string;
  doctor_review_notes?: string;
  reviewed_at?: string;
  reviewed_by?: string;
  created_at: string;
}

export interface BloodPressureRecord {
  id: string;
  patient_id: string;
  systolic: number;
  diastolic: number;
  recorded_by: string;
  recorded_at: string;
  notes?: string;
  created_at: string;
}

export interface GlucoseRecord {
  id: string;
  patient_id: string;
  value: number;
  unit: string;
  recorded_by: string;
  recorded_at: string;
  notes?: string;
  created_at: string;
}

export interface AppointmentRecord {
  id: string;
  patient_id: string;
  doctor_name: string;
  specialty: string;
  date_time: string;
  location: string;
  notes?: string;
  created_by?: string;
  updated_by?: string;
  created_at: string;
  updated_at: string;
}

export interface CarePlanVersionRecord {
  id: string;
  patient_id: string;
  version_number: number;
  title: string;
  doctor_name: string;
  doctor_id?: string;
  status: 'draft' | 'active' | 'superseded';
  summary_of_changes: string;
  medications_snapshot: any[];
  diet_snapshot: any[];
  exercise_snapshot: any[];
  created_at: string;
}

export interface ConsultationNoteRecord {
  id: string;
  patient_id: string;
  doctor_name: string;
  doctor_id?: string;
  date: string;
  observations: string;
  follow_up_instructions: string;
  suggested_follow_up_date?: string;
  created_at: string;
}
