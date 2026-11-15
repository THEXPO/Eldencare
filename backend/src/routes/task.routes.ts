import { Router } from 'express';
import { TaskController } from '../controllers/task.controller';
import { authenticateToken } from '../middleware/auth';
import { requirePatientAccess, requireRole } from '../middleware/rbac';
import { validateBody } from '../middleware/validate';
import { createTaskSchema, updateTaskSchema } from '../validators/task.validator';

const router = Router();

router.use(authenticateToken);

router.get('/patients/:patientId/tasks', requirePatientAccess('patientId'), TaskController.getTasks);
router.post(
  '/patients/:patientId/tasks',
  requirePatientAccess('patientId'),
  requireRole(['caretaker', 'doctor']),
  validateBody(createTaskSchema),
  TaskController.createTask
);
router.patch('/tasks/:taskId', requireRole(['caretaker', 'doctor']), validateBody(updateTaskSchema), TaskController.updateTask);
router.delete('/tasks/:taskId', requireRole(['caretaker', 'doctor']), TaskController.deleteTask);

export default router;
