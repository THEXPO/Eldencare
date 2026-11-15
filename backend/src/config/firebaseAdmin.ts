import * as admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { logger } from '../utils/logger';

let isFirebaseAdminInitialized = false;

export function initializeFirebaseAdmin(): admin.app.App | null {
  if (isFirebaseAdminInitialized && admin.apps.length > 0) {
    return admin.app();
  }

  try {
    const rawServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
    const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

    let credential: admin.credential.Credential | null = null;

    if (rawServiceAccount) {
      try {
        const parsed = JSON.parse(rawServiceAccount);
        credential = admin.credential.cert(parsed);
      } catch (parseErr) {
        logger.warn('FIREBASE_SERVICE_ACCOUNT_KEY is not valid JSON string, trying file path.');
        if (fs.existsSync(rawServiceAccount)) {
          credential = admin.credential.cert(rawServiceAccount);
        }
      }
    } else if (serviceAccountPath && fs.existsSync(serviceAccountPath)) {
      credential = admin.credential.cert(serviceAccountPath);
    }

    if (credential) {
      const app = admin.initializeApp({ credential });
      isFirebaseAdminInitialized = true;
      logger.info('Firebase Admin SDK initialized successfully.');
      return app;
    } else {
      logger.info('Firebase Admin credentials not provided. Push notifications will run in mock/log mode.');
      return null;
    }
  } catch (err) {
    logger.error('Failed to initialize Firebase Admin SDK', err);
    return null;
  }
}

export function getFirebaseMessaging(): admin.messaging.Messaging | null {
  if (!isFirebaseAdminInitialized && admin.apps.length === 0) {
    initializeFirebaseAdmin();
  }
  if (admin.apps.length > 0) {
    return admin.messaging();
  }
  return null;
}
