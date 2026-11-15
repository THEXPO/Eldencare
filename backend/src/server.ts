import { createApp } from './app';
import { config } from './config/env';
import { initializeFirebaseAdmin } from './config/firebaseAdmin';
import { getAnonymousSupabaseClient } from './config/supabase';
import { SchedulerService } from './services/scheduler.service';
import { logger } from './utils/logger';

const app = createApp();

app.listen(config.port, () => {
  logger.info(`EldenCare Backend API running on port ${config.port} [${config.nodeEnv}]`);
  logger.info(`Swagger API Documentation available at http://localhost:${config.port}/api-docs`);

  // Initialize Firebase Admin SDK
  initializeFirebaseAdmin();

  // Start Background Notification Scheduler
  const supabase = getAnonymousSupabaseClient();
  SchedulerService.start(supabase);
});
