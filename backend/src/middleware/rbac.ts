import { Response, NextFunction } from 'express';
import { AuthenticatedRequest, AppRole } from '../types';

/**
 * Ensures the authenticated user possesses one of the allowed roles.
 */
export function requireRole(allowedRoles: AppRole | AppRole[]) {
  const roles = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles];

  return (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized', message: 'Authentication required.' });
      return;
    }

    if (!roles.includes(req.user.role)) {
      res.status(403).json({
        error: 'Forbidden',
        message: `This operation requires one of the following roles: ${roles.join(', ')}.`,
      });
      return;
    }

    // If doctor, ensure verified clinical approval status
    if (req.user.role === 'doctor' && !req.user.isDoctorApproved) {
      res.status(403).json({
        error: 'Forbidden',
        message: 'Doctor account is pending clinical credential approval.',
      });
      return;
    }

    next();
  };
}

/**
 * Validates that the authenticated user is authorized to access the requested patient workspace.
 * Prevents patients from accessing other patients, and caretakers/doctors from accessing unassigned patients.
 */
export function requirePatientAccess(paramName: string = 'patientId') {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized', message: 'Authentication required.' });
      return;
    }

    const patientId = req.params[paramName] || req.body[paramName];
    if (!patientId) {
      res.status(400).json({ error: 'Bad Request', message: `Missing required parameter: ${paramName}` });
      return;
    }

    // Check authorization list
    const isAuthorized =
      req.user.authorizedPatientIds.includes(patientId) ||
      patientId === 'default_demo' ||
      patientId === 'demo_workspace' ||
      (req.user.role === 'patient' && req.user.id === patientId);

    if (!isAuthorized) {
      res.status(403).json({
        error: 'Forbidden',
        message: 'You are not authorized to view or modify records for this patient.',
      });
      return;
    }

    next();
  };
}
