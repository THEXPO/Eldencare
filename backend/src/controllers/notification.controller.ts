import { Response } from 'express';
import { AuthenticatedRequest } from '../types';
import { logger } from '../utils/logger';

export const NotificationController = {
  registerDevice: async (req: AuthenticatedRequest, res: Response) => {
    const { fcm_token, device_platform, device_name } = req.body;
    const userId = req.user?.id;

    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    if (req.supabase) {
      // Upsert device token for this user
      const { data, error } = await req.supabase
        .from('device_tokens')
        .upsert(
          {
            user_id: userId,
            fcm_token,
            device_platform,
            device_name,
            is_active: true,
            last_used_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          },
          { onConflict: 'fcm_token' }
        )
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
      res.status(200).json({ success: true, device: data });
      return;
    }

    res.json({
      success: true,
      device: {
        id: `dev_${Date.now()}`,
        user_id: userId,
        fcm_token,
        device_platform,
        device_name,
        is_active: true,
      },
    });
  },

  deleteDevice: async (req: AuthenticatedRequest, res: Response) => {
    const { fcm_token } = req.body;
    const userId = req.user?.id;

    if (!userId || !fcm_token) {
      res.status(400).json({ error: 'Bad Request', message: 'FCM token is required.' });
      return;
    }

    if (req.supabase) {
      await req.supabase
        .from('device_tokens')
        .update({ is_active: false, updated_at: new Date().toISOString() })
        .eq('user_id', userId)
        .eq('fcm_token', fcm_token);
    }

    res.json({ success: true, message: 'Device token deactivated.' });
  },

  getDevices: async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;

    if (req.supabase && userId) {
      const { data, error } = await req.supabase
        .from('device_tokens')
        .select('id, device_platform, device_name, is_active, last_used_at, created_at')
        .eq('user_id', userId)
        .order('last_used_at', { ascending: false });

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
      res.json({ success: true, devices: data || [] });
      return;
    }

    res.json({ success: true, devices: [] });
  },

  getPreferences: async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;

    if (req.supabase && userId) {
      const { data, error } = await req.supabase
        .from('notification_preferences')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();

      if (data) {
        res.json({ success: true, preferences: data });
        return;
      }
    }

    // Default preferences fallback
    res.json({
      success: true,
      preferences: {
        user_id: userId,
        medication_reminders_enabled: true,
        diet_reminders_enabled: true,
        exercise_reminders_enabled: true,
        appointment_reminders_enabled: true,
        caretaker_alerts_enabled: true,
        quiet_hours_enabled: false,
        quiet_hours_start: '22:00',
        quiet_hours_end: '07:00',
        timezone: 'UTC',
      },
    });
  },

  updatePreferences: async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;
    const updates = req.body;

    if (req.supabase && userId) {
      const { data, error } = await req.supabase
        .from('notification_preferences')
        .upsert(
          {
            user_id: userId,
            ...updates,
            updated_at: new Date().toISOString(),
          },
          { onConflict: 'user_id' }
        )
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
      res.json({ success: true, preferences: data });
      return;
    }

    res.json({ success: true, preferences: { user_id: userId, ...updates } });
  },

  getHistory: async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;

    if (req.supabase && userId) {
      const { data, error } = await req.supabase
        .from('notification_records')
        .select('*')
        .eq('recipient_user_id', userId)
        .order('created_at', { ascending: false })
        .limit(100);

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
      res.json({ success: true, notifications: data || [] });
      return;
    }

    // Mock history for dev
    res.json({
      success: true,
      notifications: [
        {
          id: 'notif_demo_1',
          title: 'Morning Medication Due',
          body: 'It is time for your scheduled morning medication (Amlodipine 5 mg).',
          notification_type: 'medication',
          created_at: new Date(Date.now() - 3600000).toISOString(),
          delivery_status: 'sent',
          read_at: null,
        },
        {
          id: 'notif_demo_2',
          title: 'Breakfast Reminder',
          body: 'Your scheduled meal (Oatmeal with berries) is coming up.',
          notification_type: 'diet',
          created_at: new Date(Date.now() - 7200000).toISOString(),
          delivery_status: 'sent',
          read_at: new Date().toISOString(),
        },
      ],
    });
  },

  markAsRead: async (req: AuthenticatedRequest, res: Response) => {
    const { id } = req.params;
    const userId = req.user?.id;

    if (req.supabase && userId) {
      const { data, error } = await req.supabase
        .from('notification_records')
        .update({ read_at: new Date().toISOString() })
        .eq('id', id)
        .eq('recipient_user_id', userId)
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
      res.json({ success: true, notification: data });
      return;
    }

    res.json({ success: true, notification: { id, read_at: new Date().toISOString() } });
  },

  markAllAsRead: async (req: AuthenticatedRequest, res: Response) => {
    const userId = req.user?.id;

    if (req.supabase && userId) {
      await req.supabase
        .from('notification_records')
        .update({ read_at: new Date().toISOString() })
        .eq('recipient_user_id', userId)
        .is('read_at', null);
    }

    res.json({ success: true, message: 'All notifications marked as read.' });
  },
};
