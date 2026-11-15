import { z } from 'zod';

export const createTaskSchema = z.object({
  task_type: z.enum(['medication', 'diet', 'exercise']),
  title: z.string().min(1, 'Task title is required.'),
  description: z.string().min(1, 'Description is required.'),
  instructions: z.string().optional().nullable(),
  scheduled_time_minutes: z.number().min(0).max(1439),
  source_medication_id: z.string().uuid().optional().nullable(),
  meal_slot: z.enum(['breakfast', 'lunch', 'dinner', 'snack', 'bedtime']).optional().nullable(),
  dual_confirmation_enabled: z.boolean().default(true),
  is_active: z.boolean().default(true),
});

export const updateTaskSchema = createTaskSchema.partial();
