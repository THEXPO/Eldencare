import { Response } from 'express';
import { AuthenticatedRequest } from '../types';

export const AuthController = {
  getMe: async (req: AuthenticatedRequest, res: Response) => {
    res.json({
      success: true,
      user: req.user,
    });
  },

  getProfile: async (req: AuthenticatedRequest, res: Response) => {
    if (req.supabase && req.user) {
      const { data: profile } = await req.supabase
        .from('profiles')
        .select('*')
        .eq('id', req.user.id)
        .maybeSingle();

      if (profile) {
        res.json({ success: true, profile });
        return;
      }
    }

    res.json({
      success: true,
      profile: {
        id: req.user?.id,
        full_name: req.user?.fullName,
        role: req.user?.role,
        is_doctor_approved: req.user?.isDoctorApproved,
      },
    });
  },

  updateProfile: async (req: AuthenticatedRequest, res: Response) => {
    const { full_name, phone, avatar_url } = req.body;

    if (req.supabase && req.user) {
      const { data, error } = await req.supabase
        .from('profiles')
        .update({
          full_name,
          phone,
          avatar_url,
          updated_at: new Date().toISOString(),
        })
        .eq('id', req.user.id)
        .select()
        .single();

      if (error) {
        res.status(400).json({ error: error.message });
        return;
      }

      res.json({ success: true, profile: data });
      return;
    }

    res.json({
      success: true,
      profile: { ...req.user, fullName: full_name || req.user?.fullName },
    });
  },
};
