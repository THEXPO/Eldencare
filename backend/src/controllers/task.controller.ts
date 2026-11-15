import { Response } from 'express';
import { AuthenticatedRequest } from '../types';
import { recordAuditLog } from '../utils/audit';

export const TaskController = {
  getTasks: async (req: AuthenticatedRequest, res: Response) => {
    const { patientId } = req.params;

    if (req.supabase) {
      const { data, error } = await req.supabase
        .from('daily_tasks')
        .select('*')
        .eq('patient_id', patientId)
        .order('scheduled_time_minutes', { ascending: true });

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
      res.json({ success: true, tasks: data || [] });
      return;
    }

    res.json({ success: true, tasks: [] });
  },

  createTask: async (req: AuthenticatedRequest, res: Response) => {
    const { patientId } = req.params;
    const taskData = req.body;

    let savedTask: any = {
      id: `task_${Date.now()}`,
      patient_id: patientId,
      ...taskData,
      created_by: req.user?.id,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    if (req.supabase) {
      const { data, error } = await req.supabase
        .from('daily_tasks')
        .insert({
          patient_id: patientId,
          ...taskData,
          created_by: req.user?.id,
          updated_by: req.user?.id,
        })
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
      savedTask = data;
    }

    await recordAuditLog({
      patientId,
      actorId: req.user?.id || 'unknown',
      actorRole: req.user?.role || 'user',
      action: 'CREATE_TASK',
      entityType: 'DAILY_TASK',
      entityId: savedTask.id,
      supabase: req.supabase,
    });

    res.status(201).json({ success: true, task: savedTask });
  },

  updateTask: async (req: AuthenticatedRequest, res: Response) => {
    const { taskId } = req.params;
    const updates = req.body;

    if (req.supabase) {
      const { data, error } = await req.supabase
        .from('daily_tasks')
        .update({
          ...updates,
          updated_by: req.user?.id,
          updated_at: new Date().toISOString(),
        })
        .eq('id', taskId)
        .select()
        .single();

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }

      res.json({ success: true, task: data });
      return;
    }

    res.json({ success: true, task: { id: taskId, ...updates } });
  },

  deleteTask: async (req: AuthenticatedRequest, res: Response) => {
    const { taskId } = req.params;

    if (req.supabase) {
      const { error } = await req.supabase
        .from('daily_tasks')
        .delete()
        .eq('id', taskId);

      if (error) {
        res.status(500).json({ error: error.message });
        return;
      }
    }

    res.json({ success: true, message: 'Task deleted successfully.' });
  },
};
