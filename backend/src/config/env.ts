import dotenv from 'dotenv';
import path from 'path';

// Load from backend/.env or root .env
dotenv.config();
dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

export const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  supabase: {
    url: process.env.SUPABASE_URL || '',
    anonKey: process.env.SUPABASE_PUBLISHABLE_KEY || process.env.SUPABASE_ANON_KEY || '',
    jwtSecret: process.env.SUPABASE_JWT_SECRET || '',
  },
  isConfigured: Boolean(
    process.env.SUPABASE_URL && 
    (process.env.SUPABASE_PUBLISHABLE_KEY || process.env.SUPABASE_ANON_KEY)
  ),
};
