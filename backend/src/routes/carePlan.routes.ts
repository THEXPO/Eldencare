import { Router } from 'express';
import { CarePlanController } from '../controllers/carePlan.controller';
import { authenticateToken } from '../middleware/auth';
import { requirePatientAccess, requireRole } from '../middleware/rbac';
import { validateBody } from '../middleware/validate';
import { createCarePlanSchema } from '../validators/carePlan.validator';

const router = Router();

router.use(authenticateToken);

router.get('/patients/:patientId/care-plans', requirePatientAccess('patientId'), CarePlanController.getCarePlans);
router.post(
  '/patients/:patientId/care-plans',
  requirePatientAccess('patientId'),
  requireRole('doctor'),
  validateBody(createCarePlanSchema),
  CarePlanController.createCarePlan
);
router.post(
  '/care-plans/:planId/activate',
  requireRole('doctor'),
  CarePlanController.activateCarePlan
);

export default router;
