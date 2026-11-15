import { Router } from 'express';
import { ConsultationController } from '../controllers/consultation.controller';
import { authenticateToken } from '../middleware/auth';
import { requirePatientAccess, requireRole } from '../middleware/rbac';
import { validateBody } from '../middleware/validate';
import { createConsultationSchema } from '../validators/consultation.validator';

const router = Router();

router.use(authenticateToken);

router.get('/patients/:patientId/consultations', requirePatientAccess('patientId'), ConsultationController.getConsultations);
router.post(
  '/patients/:patientId/consultations',
  requirePatientAccess('patientId'),
  requireRole('doctor'),
  validateBody(createConsultationSchema),
  ConsultationController.createConsultation
);

export default router;
