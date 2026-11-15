import { z } from 'zod';

export const createBloodPressureSchema = z.object({
  systolic: z.number().int().min(50).max(280),
  diastolic: z.number().int().min(30).max(180),
  recorded_at: z.string().datetime().optional(),
  notes: z.string().optional().nullable(),
});

export const createGlucoseSchema = z.object({
  value: z.number().positive().max(1000),
  unit: z.enum(['mg/dL', 'mmol/L']).default('mg/dL'),
  recorded_at: z.string().datetime().optional(),
  notes: z.string().optional().nullable(),
});
