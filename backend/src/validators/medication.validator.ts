import { z } from 'zod';

export const createMedicationSchema = z.object({
  name: z.string().min(1, 'Medication name is required.'),
  strength: z.string().min(1, 'Strength is required (e.g. 5 mg).'),
  dosage: z.string().min(1, 'Dosage is required (e.g. 1 tablet).'),
  dosage_form: z.enum(['tablet', 'capsule', 'syrup', 'injection', 'drops', 'inhaler', 'other']).default('tablet'),
  meal_instruction: z.string().optional(),
  scheduled_times_minutes: z.array(z.number().min(0).max(1439)).min(1, 'At least one scheduled time is required.'),
  start_date: z.string().datetime().optional(),
  end_date: z.string().datetime().optional().nullable(),
  additional_instructions: z.string().optional().nullable(),
  is_active: z.boolean().default(true),
});

export const updateMedicationSchema = createMedicationSchema.partial();
