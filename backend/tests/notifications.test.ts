import request from 'supertest';
import { createApp } from '../src/app';
import { isInQuietHours } from '../src/services/scheduler.service';

jest.mock('../src/config/env', () => ({
  config: { nodeEnv: 'test', demoAuthEnabled: true, isConfigured: false },
}));

const app = createApp();

describe('Phase 4: Notifications & Automation Tests', () => {
  describe('Authentication & Access Control', () => {
    it('rejects unauthenticated requests to get preferences (401)', async () => {
      const res = await request(app).get('/api/v1/notifications/preferences');
      expect(res.status).toBe(401);
      expect(res.body.error).toBe('Unauthorized');
    });

    it('rejects unauthenticated device registration (401)', async () => {
      const res = await request(app)
        .post('/api/v1/notifications/devices')
        .send({
          fcm_token: 'test_fcm_token_123',
          platform: 'android',
        });
      expect(res.status).toBe(401);
    });
  });

  describe('Validation & Payload Checks', () => {
    it('rejects device registration missing fcm_token (400)', async () => {
      const res = await request(app)
        .post('/api/v1/notifications/devices')
        .set('Authorization', 'Bearer demo-patient-token')
        .send({
          platform: 'android',
        });
      expect(res.status).toBe(400);
      expect(res.body.error).toBe('Validation failed');
    });

    it('rejects device registration with invalid platform (400)', async () => {
      const res = await request(app)
        .post('/api/v1/notifications/devices')
        .set('Authorization', 'Bearer demo-patient-token')
        .send({
          fcm_token: 'test_token_abc',
          platform: 'windows_phone',
        });
      expect(res.status).toBe(400);
      expect(res.body.error).toBe('Validation failed');
    });

    it('rejects update preferences with invalid time format (400)', async () => {
      const res = await request(app)
        .patch('/api/v1/notifications/preferences')
        .set('Authorization', 'Bearer demo-patient-token')
        .send({
          quiet_hours_start: '25:99', // Invalid time
        });
      expect(res.status).toBe(400);
      expect(res.body.error).toBe('Validation failed');
    });
  });

  describe('Notification Preferences & History API', () => {
    it('returns default notification preferences for authenticated user', async () => {
      const res = await request(app)
        .get('/api/v1/notifications/preferences')
        .set('Authorization', 'Bearer demo-patient-token');
      expect(res.status).toBe(200);
      expect(res.body.preferences).toBeDefined();
      expect(res.body.preferences.medication_reminders_enabled).toBe(true);
      expect(res.body.preferences.quiet_hours_start).toBe('22:00');
      expect(res.body.preferences.quiet_hours_end).toBe('07:00');
    });

    it('allows updating notification preferences', async () => {
      const res = await request(app)
        .patch('/api/v1/notifications/preferences')
        .set('Authorization', 'Bearer demo-patient-token')
        .send({
          medication_reminders_enabled: true,
          quiet_hours_enabled: true,
          quiet_hours_start: '23:00',
          quiet_hours_end: '06:30',
        });
      expect(res.status).toBe(200);
      expect(res.body.message).toContain('Preferences updated');
      expect(res.body.preferences.quiet_hours_start).toBe('23:00');
      expect(res.body.preferences.quiet_hours_end).toBe('06:30');
    });

    it('retrieves notification history list', async () => {
      const res = await request(app)
        .get('/api/v1/notifications/history')
        .set('Authorization', 'Bearer demo-patient-token');
      expect(res.status).toBe(200);
      expect(Array.isArray(res.body.notifications)).toBe(true);
      expect(typeof res.body.unread_count).toBe('number');
    });

    it('marks all notifications as read', async () => {
      const res = await request(app)
        .post('/api/v1/notifications/mark-all-read')
        .set('Authorization', 'Bearer demo-patient-token');
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe('Device Registration & Management', () => {
    it('allows registering a valid device token', async () => {
      const res = await request(app)
        .post('/api/v1/notifications/devices')
        .set('Authorization', 'Bearer demo-patient-token')
        .send({
          fcm_token: 'demo_fcm_token_test_123',
          platform: 'android',
          device_name: 'Pixel 8 Pro',
        });
      expect(res.status).toBe(200);
      expect(res.body.message).toContain('Device registered');
    });

    it('allows unregistering a device token', async () => {
      const res = await request(app)
        .delete('/api/v1/notifications/devices')
        .set('Authorization', 'Bearer demo-patient-token')
        .send({
          fcm_token: 'demo_fcm_token_test_123',
        });
      expect(res.status).toBe(200);
      expect(res.body.message).toContain('Device unregistered');
    });
  });

  describe('Quiet Hours Logic (isInQuietHours)', () => {
    it('detects overnight quiet hours correctly (e.g., 22:00 to 07:00)', () => {
      // 23:30 is in quiet hours
      const lateNight = new Date(2026, 10, 15, 23, 30);
      expect(isInQuietHours('22:00', '07:00', lateNight)).toBe(true);

      // 03:00 is in quiet hours
      const earlyMorning = new Date(2026, 10, 15, 3, 0);
      expect(isInQuietHours('22:00', '07:00', earlyMorning)).toBe(true);

      // 06:59 is in quiet hours
      const justBeforeEnd = new Date(2026, 10, 15, 6, 59);
      expect(isInQuietHours('22:00', '07:00', justBeforeEnd)).toBe(true);

      // 07:00 is awake (outside quiet hours)
      const wakeTime = new Date(2026, 10, 15, 7, 0);
      expect(isInQuietHours('22:00', '07:00', wakeTime)).toBe(false);

      // 14:00 is awake (outside quiet hours)
      const afternoon = new Date(2026, 10, 15, 14, 0);
      expect(isInQuietHours('22:00', '07:00', afternoon)).toBe(false);

      // 21:59 is awake (outside quiet hours)
      const beforeQuiet = new Date(2026, 10, 15, 21, 59);
      expect(isInQuietHours('22:00', '07:00', beforeQuiet)).toBe(false);
    });

    it('detects daytime quiet hours correctly (e.g., 13:00 to 15:00 afternoon rest)', () => {
      const duringNap = new Date(2026, 10, 15, 14, 15);
      expect(isInQuietHours('13:00', '15:00', duringNap)).toBe(true);

      const beforeNap = new Date(2026, 10, 15, 12, 30);
      expect(isInQuietHours('13:00', '15:00', beforeNap)).toBe(false);

      const afterNap = new Date(2026, 10, 15, 15, 30);
      expect(isInQuietHours('13:00', '15:00', afterNap)).toBe(false);
    });
  });
});
