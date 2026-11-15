import { z } from 'zod';

export const submitConfirmationSchema = z.object({
  patient_id: z.string().min(1, 'Patient ID is required.'),
  task_title: z.string().min(1, 'Task title is required.'),
  response: z.enum(['completed', 'not_completed']),
});

export const reviewDiscrepancySchema = z.object({
  doctor_review_notes: z.string().min(1, 'Doctor review notes are required.'),
});
