import { Router } from 'express';
import { NotificationController } from '../controllers/notification.controller';
import { authenticateToken } from '../middleware/auth';
import { validateBody } from '../middleware/validate';
import { registerDeviceTokenSchema, updatePreferencesSchema } from '../validators/notification.validator';

const router = Router();

router.use(authenticateToken);

// Device Tokens
router.post('/notifications/devices', validateBody(registerDeviceTokenSchema), NotificationController.registerDevice);
router.delete('/notifications/devices', NotificationController.deleteDevice);
router.get('/notifications/devices', NotificationController.getDevices);

// Notification Preferences
router.get('/notifications/preferences', NotificationController.getPreferences);
router.patch('/notifications/preferences', validateBody(updatePreferencesSchema), NotificationController.updatePreferences);

// Notification History & Read Status
router.get('/notifications/history', NotificationController.getHistory);
router.patch('/notifications/:id/read', NotificationController.markAsRead);
router.post('/notifications/mark-all-read', NotificationController.markAllAsRead);

export default router;
