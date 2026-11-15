import { Router } from 'express';
import { ConfirmationController } from '../controllers/confirmation.controller';
import { authenticateToken } from '../middleware/auth';
import { requirePatientAccess, requireRole } from '../middleware/rbac';
import { validateBody } from '../middleware/validate';
import { submitConfirmationSchema, reviewDiscrepancySchema } from '../validators/confirmation.validator';

const router = Router();

router.use(authenticateToken);

router.post(
  '/task-instances/:instanceId/confirmations',
  requireRole(['patient', 'caretaker']),
  validateBody(submitConfirmationSchema),
  ConfirmationController.submitConfirmation
);
router.get('/task-instances/:instanceId/confirmations', ConfirmationController.getConfirmations);
router.get('/patients/:patientId/discrepancies', requirePatientAccess('patientId'), ConfirmationController.getDiscrepancies);
router.patch(
  '/discrepancies/:discrepancyId/review',
  requireRole('doctor'),
  validateBody(reviewDiscrepancySchema),
  ConfirmationController.reviewDiscrepancy
);

export default router;
