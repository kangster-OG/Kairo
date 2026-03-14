import { createClient, type SupabaseClient } from '@supabase/supabase-js';

import { getSupabaseConfig } from '@/src/lib/supabase/config';

let cachedClient: SupabaseClient | null | undefined;

export function getSupabaseClient(): SupabaseClient | null {
  if (cachedClient !== undefined) {
    return cachedClient;
  }

  const config = getSupabaseConfig();

  if (!config) {
    cachedClient = null;
    return cachedClient;
  }

  cachedClient = createClient(config.url, config.anonKey, {
    auth: {
      autoRefreshToken: false,
      detectSessionInUrl: false,
      persistSession: false,
    },
  });

  return cachedClient;
}
