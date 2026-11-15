import request from 'supertest';
import { createApp } from '../src/app';

const app = createApp();

describe('Authentication & Access Control Middleware', () => {
  it('rejects requests without Authorization Bearer header (401)', async () => {
    const res = await request(app).get('/api/v1/me');
    expect(res.status).toBe(401);
    expect(res.body.error).toBe('Unauthorized');
  });

  it('rejects malformed authorization header (401)', async () => {
    const res = await request(app)
      .get('/api/v1/me')
      .set('Authorization', 'Basic invalid-token');
    expect(res.status).toBe(401);
  });

  it('allows authenticated requests with demo patient token', async () => {
    const res = await request(app)
      .get('/api/v1/me')
      .set('Authorization', 'Bearer demo-patient-token');
    expect(res.status).toBe(200);
    expect(res.body.user.role).toBe('patient');
    expect(res.body.user.fullName).toBe('Eleanor Vance');
  });

  it('blocks patients from creating doctor care plans (403 Forbidden)', async () => {
    const res = await request(app)
      .post('/api/v1/patients/p1/care-plans')
      .set('Authorization', 'Bearer demo-patient-token')
      .send({
        title: 'Unauthorized Plan',
        summary_of_changes: 'Attempting self-prescription',
      });
    expect(res.status).toBe(403);
    expect(res.body.error).toBe('Forbidden');
  });

  it('blocks patients from accessing another patient workspace (403 Forbidden)', async () => {
    const res = await request(app)
      .get('/api/v1/patients/unassigned-patient-999/overview')
      .set('Authorization', 'Bearer demo-patient-token');
    expect(res.status).toBe(403);
    expect(res.body.error).toBe('Forbidden');
  });
});
