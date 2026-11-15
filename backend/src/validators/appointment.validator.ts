import { z } from 'zod';

export const createAppointmentSchema = z.object({
  doctor_name: z.string().min(1, 'Doctor name is required.'),
  specialty: z.string().min(1, 'Specialty is required.'),
  date_time: z.string().datetime(),
  location: z.string().min(1, 'Location / Hospital is required.'),
  notes: z.string().optional().nullable(),
});

export const updateAppointmentSchema = createAppointmentSchema.partial();
