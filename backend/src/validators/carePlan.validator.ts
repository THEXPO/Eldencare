import { z } from 'zod';

export const createCarePlanSchema = z.object({
  title: z.string().min(1, 'Care plan title is required.'),
  summary_of_changes: z.string().min(1, 'Summary of changes is required.'),
  activate: z.boolean().default(false),
  medications_snapshot: z.array(z.any()).default([]),
  diet_snapshot: z.array(z.any()).default([]),
  exercise_snapshot: z.array(z.any()).default([]),
});

export const updateCarePlanSchema = z.object({
  title: z.string().optional(),
  summary_of_changes: z.string().optional(),
  medications_snapshot: z.array(z.any()).optional(),
  diet_snapshot: z.array(z.any()).optional(),
  exercise_snapshot: z.array(z.any()).optional(),
});
