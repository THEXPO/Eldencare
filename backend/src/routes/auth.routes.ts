import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { authenticateToken } from '../middleware/auth';

const router = Router();

router.use(authenticateToken);
router.get('/me', AuthController.getMe);
router.get('/me/profile', AuthController.getProfile);
router.patch('/me/profile', AuthController.updateProfile);

export default router;
