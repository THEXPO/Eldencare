import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../src/app';
import { config } from '../src/config/env';
import { getAnonymousSupabaseClient, getUserSupabaseClient } from '../src/config/supabase';

jest.mock('../src/config/env', () => ({
  config: { nodeEnv: 'test', demoAuthEnabled: false, isConfigured: false },
}));
jest.mock('../src/config/supabase');

const anonymousClient = jest.mocked(getAnonymousSupabaseClient);
const userClient = jest.mocked(getUserSupabaseClient);
const app = createApp();
const demoTokens = ['demo-patient-token', 'demo-caretaker-token', 'demo-doctor-token', 'test-token'];

beforeEach(() => {
  jest.resetAllMocks();
  Object.assign(config, { nodeEnv: 'test', demoAuthEnabled: false, isConfigured: false });
  anonymousClient.mockReturnValue(null);
});

describe('Authentication trust boundary', () => {
  it.each(demoTokens)('rejects %s by default', async (token) => {
    const res = await request(app).get('/api/v1/me').auth(token, { type: 'bearer' });
    expect(res.status).toBe(401);
  });

  it.each(['production', 'staging'])('disables demo auth in %s even with opt-in', async (environment) => {
    Object.assign(config, { nodeEnv: environment, demoAuthEnabled: true });
    for (const token of demoTokens) {
      const res = await request(app).get('/api/v1/me').auth(token, { type: 'bearer' });
      expect(res.status).toBe(401);
    }
  });

  it.each(['development', 'test'])('allows explicit offline demos in %s', async (environment) => {
    Object.assign(config, { nodeEnv: environment, demoAuthEnabled: true });
    for (const [token, role] of [
      ['demo-patient-token', 'patient'],
      ['demo-caretaker-token', 'caretaker'],
      ['demo-doctor-token', 'doctor'],
      ['test-token', 'patient'],
    ]) {
      const res = await request(app).get('/api/v1/me').auth(token, { type: 'bearer' });
      expect(res.status).toBe(200);
      expect(res.body.user.role).toBe(role);
    }
    expect(anonymousClient).not.toHaveBeenCalled();
  });

  it('rejects invented demo token names', async () => {
    config.demoAuthEnabled = true;
    const res = await request(app).get('/api/v1/me').auth('demo-invented-doctor', { type: 'bearer' });
    expect(res.status).toBe(401);
  });

  it('rejects self-signed JWTs when Supabase is unavailable, even in demo mode', async () => {
    config.demoAuthEnabled = true;
    const token = jwt.sign(
      { sub: 'someone-else', user_metadata: { role: 'caretaker' } },
      'untrusted-test-key'
    );
    const res = await request(app).get('/api/v1/me').auth(token, { type: 'bearer' });
    expect(res.status).toBe(401);
    expect(userClient).not.toHaveBeenCalled();
  });

  it('verifies demo-looking tokens when connected to Supabase', async () => {
    Object.assign(config, { demoAuthEnabled: true, isConfigured: true });
    const getUser = jest.fn().mockResolvedValue({ data: { user: null }, error: { message: 'Invalid token' } });
    anonymousClient.mockReturnValue({ auth: { getUser } } as any);
    for (const token of demoTokens) {
      const res = await request(app).get('/api/v1/me').auth(token, { type: 'bearer' });
      expect(res.status).toBe(401);
      expect(getUser).toHaveBeenCalledWith(token);
    }
    expect(userClient).not.toHaveBeenCalled();
  });

  it('preserves verified Supabase authentication and workspace lookup', async () => {
    Object.assign(config, { nodeEnv: 'production', isConfigured: true });
    const getUser = jest.fn().mockResolvedValue({
      data: { user: { id: 'patient-123', email: 'patient@example.test' } }, error: null,
    });
    anonymousClient.mockReturnValue({ auth: { getUser } } as any);
    const query = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      maybeSingle: jest.fn()
        .mockResolvedValueOnce({ data: { role: 'patient', full_name: 'Verified Patient' } })
        .mockResolvedValueOnce({ data: { id: 'workspace-123' } }),
    };
    userClient.mockReturnValue({ from: jest.fn().mockReturnValue(query) } as any);
    const res = await request(app).get('/api/v1/me').auth('verified-session', { type: 'bearer' });
    expect(res.status).toBe(200);
    expect(getUser).toHaveBeenCalledWith('verified-session');
    expect(userClient).toHaveBeenCalledWith('verified-session');
    expect(res.body.user.authorizedPatientIds).toEqual(['workspace-123', 'patient-123']);
    expect(res.body.user.fullName).toBe('Verified Patient');
  });

  it('rejects Supabase verification failures', async () => {
    config.isConfigured = true;
    anonymousClient.mockReturnValue({
      auth: { getUser: jest.fn().mockRejectedValue(new Error('Test connection failure')) },
    } as any);
    const res = await request(app).get('/api/v1/me').auth('unverified-session', { type: 'bearer' });
    expect(res.status).toBe(401);
    expect(userClient).not.toHaveBeenCalled();
  });
});
