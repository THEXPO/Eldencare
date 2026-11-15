import { Router } from 'express';
import { HealthReadingController } from '../controllers/healthReading.controller';
import { authenticateToken } from '../middleware/auth';
import { requirePatientAccess, requireRole } from '../middleware/rbac';
import { validateBody } from '../middleware/validate';
import { createBloodPressureSchema, createGlucoseSchema } from '../validators/healthReading.validator';

const router = Router();

router.use(authenticateToken);

router.get('/patients/:patientId/health-readings', requirePatientAccess('patientId'), HealthReadingController.getReadings);
router.post(
  '/patients/:patientId/blood-pressure',
  requirePatientAccess('patientId'),
  requireRole(['patient', 'caretaker', 'doctor']),
  validateBody(createBloodPressureSchema),
  HealthReadingController.createBloodPressure
);
router.post(
  '/patients/:patientId/glucose',
  requirePatientAccess('patientId'),
  requireRole(['patient', 'caretaker', 'doctor']),
  validateBody(createGlucoseSchema),
  HealthReadingController.createGlucose
);

export default router;
