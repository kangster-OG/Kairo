import type { Session, SupabaseClient } from '@supabase/supabase-js';

import { getSupabaseClient } from '@/src/lib/supabase';
import type { StoredAuthSession } from '@/src/features/auth/types';

export type AuthGateway = {
  getCurrentSession: () => Promise<StoredAuthSession | null>;
  hasClient: () => boolean;
  signInWithEmail: (email: string, password: string) => Promise<StoredAuthSession>;
  signOut: () => Promise<void>;
  signUpWithEmail: (email: string, password: string) => Promise<StoredAuthSession>;
};

export function createSupabaseAuthGateway(
  client: SupabaseClient | null = getSupabaseClient()
): AuthGateway {
  return {
    async getCurrentSession() {
      if (!client) {
        return null;
      }

      const { data, error } = await client.auth.getSession();

      if (error) {
        throw new Error(error.message);
      }

      return data.session ? mapSession(data.session) : null;
    },
    hasClient() {
      return client !== null;
    },
    async signInWithEmail(email, password) {
      if (!client) {
        throw new Error('Supabase is not configured for this build.');
      }

      const { data, error } = await client.auth.signInWithPassword({
        email,
        password,
      });

      if (error || !data.session) {
        throw new Error(error?.message ?? 'Sign in failed.');
      }

      return mapSession(data.session);
    },
    async signOut() {
      if (!client) {
        return;
      }

      const { error } = await client.auth.signOut();

      if (error) {
        throw new Error(error.message);
      }
    },
    async signUpWithEmail(email, password) {
      if (!client) {
        throw new Error('Supabase is not configured for this build.');
      }

      const { data, error } = await client.auth.signUp({
        email,
        password,
      });

      if (error || !data.session) {
        throw new Error(
          error?.message ??
            'Atlas could not create the account. Confirm email auth is enabled in Supabase.'
        );
      }

      return mapSession(data.session);
    },
  };
}

function mapSession(session: Session): StoredAuthSession {
  return {
    accessToken: session.access_token,
    email: session.user.email ?? null,
    expiresAt: session.expires_at ?? null,
    refreshToken: session.refresh_token ?? null,
    userId: session.user.id,
  };
}
