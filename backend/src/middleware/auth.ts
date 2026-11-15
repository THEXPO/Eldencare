import { Response, NextFunction } from 'express';
import { AuthenticatedRequest, AuthenticatedUser, AppRole } from '../types';
import { config } from '../config/env';
import { getAnonymousSupabaseClient, getUserSupabaseClient } from '../config/supabase';
import { logger } from '../utils/logger';

export async function authenticateToken(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({
      error: 'Unauthorized',
      message: 'Missing or malformed Authorization Bearer header.',
    });
    return;
  }

  const token = authHeader.split(' ')[1];
  req.token = token;

  // Demo identities must never bypass authentication against a real database.
  const isDemoToken = [
    'demo-patient-token',
    'demo-caretaker-token',
    'demo-doctor-token',
    'test-token',
  ].includes(token);
  if (
    isDemoToken &&
    config.demoAuthEnabled &&
    ['development', 'test'].includes(config.nodeEnv) &&
    !config.isConfigured
  ) {
    req.user = getDemoUser(token);
    next();
    return;
  }

  // Supabase JWT Authentication
  const anonSupabase = getAnonymousSupabaseClient();
  if (!anonSupabase) {
    res.status(401).json({ error: 'Unauthorized', message: 'Invalid authentication token.' });
    return;
  }

  try {
    // Verify token with Supabase Auth
    const { data: authData, error: authError } = await anonSupabase.auth.getUser(token);
    if (authError || !authData.user) {
      res.status(401).json({
        error: 'Unauthorized',
        message: authError?.message || 'Invalid or expired authentication session.',
      });
      return;
    }

    const authUser = authData.user;
    req.supabase = getUserSupabaseClient(token);

    // Fetch verified profile from database
    const { data: profile } = await req.supabase
      .from('profiles')
      .select('*')
      .eq('id', authUser.id)
      .maybeSingle();

    const role: AppRole = (profile?.role as AppRole) || (authUser.user_metadata?.role as AppRole) || 'patient';
    const fullName: string = profile?.full_name || authUser.user_metadata?.full_name || 'Member';
    const isDoctorApproved: boolean = profile?.is_doctor_approved ?? (role !== 'doctor');

    // Fetch authorized patient workspaces
    const authorizedPatientIds: string[] = [];

    if (role === 'patient') {
      const { data: ws } = await req.supabase
        .from('patient_workspaces')
        .select('id')
        .eq('patient_user_id', authUser.id)
        .maybeSingle();
      if (ws) authorizedPatientIds.push(ws.id);
      authorizedPatientIds.push(authUser.id); // Also include direct ID
    } else if (role === 'caretaker') {
      const { data: team } = await req.supabase
        .from('care_team_members')
        .select('patient_id')
        .eq('user_id', authUser.id)
        .eq('status', 'active');
      if (team) {
        team.forEach((t) => authorizedPatientIds.push(t.patient_id));
      }
    } else if (role === 'doctor') {
      const { data: docs } = await req.supabase
        .from('doctor_patient_assignments')
        .select('patient_id')
        .eq('doctor_user_id', authUser.id)
        .eq('status', 'approved');
      if (docs) {
        docs.forEach((d) => authorizedPatientIds.push(d.patient_id));
      }
    }

    req.user = {
      id: authUser.id,
      email: authUser.email || '',
      fullName,
      role,
      isDoctorApproved,
      authorizedPatientIds,
    };

    next();
  } catch (err) {
    logger.error('Authentication verification error', err);
    res.status(401).json({ error: 'Unauthorized', message: 'Authentication verification failed.' });
  }
}

function getDemoUser(token: string): AuthenticatedUser {
  if (token.includes('caretaker')) {
    return {
      id: 'demo-caretaker-001',
      email: 'priya@eldencare.org',
      fullName: 'Priya Hart',
      role: 'caretaker',
      isDoctorApproved: true,
      authorizedPatientIds: ['p1', 'p2', 'demo_workspace', 'default_demo'],
    };
  }
  if (token.includes('doctor')) {
    return {
      id: 'demo-doctor-001',
      email: 'doctor@eldencare.org',
      fullName: 'Dr. Sarah Nguyen, MD',
      role: 'doctor',
      isDoctorApproved: true,
      authorizedPatientIds: ['p1', 'p2', 'p3', 'demo_workspace', 'default_demo'],
    };
  }
  // Default demo patient
  return {
    id: 'demo-patient-001',
    email: 'eleanor@eldencare.org',
    fullName: 'Eleanor Vance',
    role: 'patient',
    workspaceId: 'p1',
    isDoctorApproved: true,
    authorizedPatientIds: ['p1', 'demo-patient-001', 'demo_workspace', 'default_demo'],
  };
}
