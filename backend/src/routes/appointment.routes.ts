import { Router } from 'express';
import { AppointmentController } from '../controllers/appointment.controller';
import { authenticateToken } from '../middleware/auth';
import { requirePatientAccess, requireRole } from '../middleware/rbac';
import { validateBody } from '../middleware/validate';
import { createAppointmentSchema, updateAppointmentSchema } from '../validators/appointment.validator';

const router = Router();

router.use(authenticateToken);

router.get('/patients/:patientId/appointments', requirePatientAccess('patientId'), AppointmentController.getAppointments);
router.post(
  '/patients/:patientId/appointments',
  requirePatientAccess('patientId'),
  requireRole(['patient', 'caretaker', 'doctor']),
  validateBody(createAppointmentSchema),
  AppointmentController.createAppointment
);
router.patch('/appointments/:appointmentId', requireRole(['patient', 'caretaker', 'doctor']), validateBody(updateAppointmentSchema), AppointmentController.updateAppointment);
router.delete('/appointments/:appointmentId', requireRole(['patient', 'caretaker', 'doctor']), AppointmentController.deleteAppointment);

export default router;
