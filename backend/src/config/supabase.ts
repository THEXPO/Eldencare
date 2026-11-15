import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { config } from './env';

let anonClient: SupabaseClient | null = null;

export function getAnonymousSupabaseClient(): SupabaseClient | null {
  if (!config.isConfigured) return null;
  if (!anonClient) {
    anonClient = createClient(config.supabase.url, config.supabase.anonKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
  }
  return anonClient;
}

/**
 * Creates a user-scoped Supabase client that forwards the verified user's Bearer token.
 * This guarantees PostgreSQL Row Level Security (RLS) policies are always enforced
 * by the database engine for ordinary requests.
 */
export function getUserSupabaseClient(userAccessToken: string): SupabaseClient {
  return createClient(config.supabase.url, config.supabase.anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: {
      headers: {
        Authorization: `Bearer ${userAccessToken}`,
      },
    },
  });
}
