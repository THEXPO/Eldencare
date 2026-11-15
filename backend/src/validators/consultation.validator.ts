import { z } from 'zod';

export const createConsultationSchema = z.object({
  date: z.string().datetime().optional(),
  observations: z.string().min(1, 'Clinical observations are required.'),
  follow_up_instructions: z.string().min(1, 'Follow-up instructions are required.'),
  suggested_follow_up_date: z.string().datetime().optional().nullable(),
});
