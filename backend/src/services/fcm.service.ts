import { SupabaseClient } from '@supabase/supabase-js';
import { getFirebaseMessaging } from '../config/firebaseAdmin';
import { logger } from '../utils/logger';

export interface SendPushPayload {
  tokens: string[];
  title: string;
  body: string;
  data?: Record<string, string>;
  isUrgent?: boolean;
}

export class FcmService {
  /**
   * Dispatches push notifications to multiple device tokens via Firebase Cloud Messaging.
   * Cleans up expired/unregistered device tokens automatically.
   */
  static async sendPushNotification(
    payload: SendPushPayload,
    supabase?: SupabaseClient
  ): Promise<{ successCount: number; failureCount: number }> {
    const messaging = getFirebaseMessaging();

    if (!payload.tokens || payload.tokens.length === 0) {
      return { successCount: 0, failureCount: 0 };
    }

    if (!messaging) {
      logger.info(`[FCM-SIMULATED] "${payload.title}" -> ${payload.tokens.length} token(s). Body: "${payload.body}"`);
      return { successCount: payload.tokens.length, failureCount: 0 };
    }

    const message: any = {
      tokens: payload.tokens,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data || {},
      android: {
        priority: payload.isUrgent ? 'high' : 'normal',
        notification: {
          channelId: payload.isUrgent ? 'eldencare_alerts' : 'eldencare_reminders',
          sound: 'default',
        },
      },
    };

    try {
      const response = await messaging.sendEachForMulticast(message);
      logger.info(`FCM Multicast sent: ${response.successCount} succeeded, ${response.failureCount} failed.`);

      // Clean up invalid or unregistered tokens
      if (response.failureCount > 0 && supabase) {
        const invalidTokens: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success && resp.error) {
            const errorCode = resp.error.code;
            if (
              errorCode === 'messaging/invalid-registration-token' ||
              errorCode === 'messaging/registration-token-not-registered'
            ) {
              invalidTokens.push(payload.tokens[idx]);
            }
          }
        });

        if (invalidTokens.length > 0) {
          logger.info(`Deactivating ${invalidTokens.length} expired FCM token(s)...`);
          await supabase
            .from('device_tokens')
            .update({ is_active: false, updated_at: new Date().toISOString() })
            .in('fcm_token', invalidTokens);
        }
      }

      return {
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
    } catch (error) {
      logger.error('FCM Multicast send error:', error);
      return { successCount: 0, failureCount: payload.tokens.length };
    }
  }
}
