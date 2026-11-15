import { Router } from 'express';
import authRoutes from './auth.routes';
import patientRoutes from './patient.routes';
import medicationRoutes from './medication.routes';
import taskRoutes from './task.routes';
import confirmationRoutes from './confirmation.routes';
import healthReadingRoutes from './healthReading.routes';
import appointmentRoutes from './appointment.routes';
import carePlanRoutes from './carePlan.routes';
import consultationRoutes from './consultation.routes';
import notificationRoutes from './notification.routes';

const router = Router();

router.use('/', authRoutes);
router.use('/', patientRoutes);
router.use('/', medicationRoutes);
router.use('/', taskRoutes);
router.use('/', confirmationRoutes);
router.use('/', healthReadingRoutes);
router.use('/', appointmentRoutes);
router.use('/', carePlanRoutes);
router.use('/', consultationRoutes);
router.use('/', notificationRoutes);

export default router;
