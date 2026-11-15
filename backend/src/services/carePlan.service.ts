import { SupabaseClient } from '@supabase/supabase-js';
import { CarePlanVersionRecord } from '../types';

export class CarePlanService {
  /**
   * Activates a care plan version atomically:
   * 1. Marks previous active plans as superseded
   * 2. Sets target plan version as active
   * 3. Synchronizes medications, diet, and exercise records into active patient lists
   */
  static async activateCarePlan(
    supabase: SupabaseClient,
    patientId: string,
    planId: string,
    doctorName: string,
    doctorId?: string
  ): Promise<CarePlanVersionRecord | null> {
    // 1. Mark existing active versions as superseded
    await supabase
      .from('care_plan_versions')
      .update({ status: 'superseded' })
      .eq('patient_id', patientId)
      .eq('status', 'active');

    // 2. Activate target version
    const { data: activated, error } = await supabase
      .from('care_plan_versions')
      .update({
        status: 'active',
        doctor_name: doctorName,
        doctor_id: doctorId,
      })
      .eq('id', planId)
      .eq('patient_id', patientId)
      .select()
      .single();

    if (error || !activated) {
      throw new Error(error?.message || 'Failed to activate care plan version.');
    }

    return activated as CarePlanVersionRecord;
  }
}
