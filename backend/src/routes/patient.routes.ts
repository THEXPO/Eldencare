import { Router } from 'express';
import { PatientController } from '../controllers/patient.controller';
import { authenticateToken } from '../middleware/auth';
import { requirePatientAccess } from '../middleware/rbac';

const router = Router();

router.use(authenticateToken);
router.get('/patients', PatientController.getPatients);
router.get('/patients/:patientId/overview', requirePatientAccess('patientId'), PatientController.getPatientOverview);

export default router;
