import { Router } from 'express';
import { MedicationController } from '../controllers/medication.controller';
import { authenticateToken } from '../middleware/auth';
import { requirePatientAccess, requireRole } from '../middleware/rbac';
import { validateBody } from '../middleware/validate';
import { createMedicationSchema, updateMedicationSchema } from '../validators/medication.validator';

const router = Router();

router.use(authenticateToken);

router.get('/patients/:patientId/medications', requirePatientAccess('patientId'), MedicationController.getMedications);
router.post(
  '/patients/:patientId/medications',
  requirePatientAccess('patientId'),
  requireRole(['caretaker', 'doctor']),
  validateBody(createMedicationSchema),
  MedicationController.createMedication
);
router.patch(
  '/medications/:medicationId',
  requireRole(['caretaker', 'doctor']),
  validateBody(updateMedicationSchema),
  MedicationController.updateMedication
);
router.delete(
  '/medications/:medicationId',
  requireRole(['caretaker', 'doctor']),
  MedicationController.deleteMedication
);

export default router;
