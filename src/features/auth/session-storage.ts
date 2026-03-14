import { z } from 'zod';

import { secureStoreAdapter, type SupabaseStorageAdapter } from '@/src/lib/supabase/secure-store-adapter';
import type { StoredAuthSession } from '@/src/features/auth/types';

const AUTH_SESSION_KEY = 'atlas.auth.session.v1';

const storedAuthSessionSchema = z.object({
  accessToken: z.string().min(1),
  email: z.string().email().nullable(),
  expiresAt: z.number().int().nullable(),
  refreshToken: z.string().min(1).nullable(),
  userId: z.string().min(1),
});

export async function readStoredAuthSession(
  storage: SupabaseStorageAdapter = secureStoreAdapter
): Promise<StoredAuthSession | null> {
  const raw = await storage.getItem(AUTH_SESSION_KEY);

  if (!raw) {
    return null;
  }

  try {
    return storedAuthSessionSchema.parse(JSON.parse(raw));
  } catch {
    await storage.removeItem(AUTH_SESSION_KEY);
    return null;
  }
}

export async function writeStoredAuthSession(
  session: StoredAuthSession,
  storage: SupabaseStorageAdapter = secureStoreAdapter
): Promise<void> {
  await storage.setItem(AUTH_SESSION_KEY, JSON.stringify(session));
}

export async function clearStoredAuthSession(
  storage: SupabaseStorageAdapter = secureStoreAdapter
): Promise<void> {
  await storage.removeItem(AUTH_SESSION_KEY);
}
