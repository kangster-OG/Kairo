import { create } from 'zustand';

import {
  bootstrapAuthSession,
  buildGuestUpgradePlan,
  deriveSyncStatus,
  signInWithEmail,
  signOutSession,
  signUpWithEmail,
} from '@/src/features/auth/service';
import type {
  AuthMutationInput,
  AuthSessionState,
  GuestUpgradePlan,
  SyncStatus,
} from '@/src/features/auth/types';
import { hasSupabaseConfig } from '@/src/lib/supabase/config';

type AuthStore = {
  bootstrap: () => Promise<void>;
  error: string | null;
  guestUpgradePlan: GuestUpgradePlan;
  isBootstrapped: boolean;
  isConfigAvailable: boolean;
  isPending: boolean;
  refreshGuestUpgradePlan: () => Promise<void>;
  session: AuthSessionState;
  signIn: (input: AuthMutationInput) => Promise<void>;
  signOut: () => Promise<void>;
  signUp: (input: AuthMutationInput) => Promise<void>;
  syncStatus: SyncStatus;
};

const emptyUpgradePlan: GuestUpgradePlan = {
  hasLocalData: false,
  pendingUploadCount: 0,
  recordCounts: {
    calculatorProfiles: 0,
    compounds: 0,
    customMetrics: 0,
    healthConnections: 0,
    logEvents: 0,
    metricValueLogs: 0,
    protocolRules: 0,
    protocols: 0,
    reminders: 0,
    sites: 0,
    symptomLogs: 0,
    vials: 0,
    weightLogs: 0,
  },
};

const initialSession: AuthSessionState = {
  email: null,
  lastBootstrapAt: null,
  status: 'bootstrapping',
  userId: null,
};

const initialSyncStatus: SyncStatus = {
  lastError: null,
  lastSyncAt: null,
  mode: 'local_only',
  pendingDownloadCount: 0,
  pendingUploadCount: 0,
};

export const useAuthStore = create<AuthStore>((set, get) => ({
  async bootstrap() {
    if (get().isBootstrapped || get().isPending) {
      return;
    }

    set({ error: null, isPending: true });

    try {
      const [session, plan] = await Promise.all([
        bootstrapAuthSession(),
        buildGuestUpgradePlan(),
      ]);

      set({
        error: null,
        guestUpgradePlan: plan,
        isBootstrapped: true,
        isPending: false,
        session,
        syncStatus: deriveSyncStatus({ plan, session }),
      });
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Atlas could not restore the auth session.',
        guestUpgradePlan: emptyUpgradePlan,
        isBootstrapped: true,
        isPending: false,
        session: {
          ...initialSession,
          lastBootstrapAt: new Date().toISOString(),
          status: 'guest',
        },
        syncStatus: {
          ...initialSyncStatus,
          lastError:
            error instanceof Error ? error.message : 'Atlas could not restore the auth session.',
          mode: 'sync_error',
        },
      });
    }
  },
  error: null,
  guestUpgradePlan: emptyUpgradePlan,
  isBootstrapped: false,
  isConfigAvailable: hasSupabaseConfig(),
  isPending: false,
  async refreshGuestUpgradePlan() {
    const session = get().session;
    try {
      const plan = await buildGuestUpgradePlan();

      set({
        error: null,
        guestUpgradePlan: plan,
        syncStatus: deriveSyncStatus({
          lastError: get().syncStatus.lastError,
          lastSyncAt: get().syncStatus.lastSyncAt,
          plan,
          session,
        }),
      });
    } catch (error) {
      set({
        error:
          error instanceof Error
            ? error.message
            : 'Atlas could not refresh the local sync status.',
        syncStatus: {
          ...get().syncStatus,
          lastError:
            error instanceof Error
              ? error.message
              : 'Atlas could not refresh the local sync status.',
          mode: 'sync_error',
        },
      });
    }
  },
  session: initialSession,
  async signIn(input) {
    set({ error: null, isPending: true });

    try {
      const [session, plan] = await Promise.all([
        signInWithEmail({ input }),
        buildGuestUpgradePlan(),
      ]);

      set({
        error: null,
        guestUpgradePlan: plan,
        isBootstrapped: true,
        isPending: false,
        session,
        syncStatus: deriveSyncStatus({ plan, session }),
      });
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Atlas could not sign in.',
        isPending: false,
      });
    }
  },
  async signOut() {
    set({ error: null, isPending: true });

    try {
      const [session, plan] = await Promise.all([
        signOutSession(),
        buildGuestUpgradePlan(),
      ]);

      set({
        error: null,
        guestUpgradePlan: plan,
        isBootstrapped: true,
        isPending: false,
        session,
        syncStatus: deriveSyncStatus({ plan, session }),
      });
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Atlas could not sign out.',
        isPending: false,
      });
    }
  },
  async signUp(input) {
    set({ error: null, isPending: true });

    try {
      const [session, plan] = await Promise.all([
        signUpWithEmail({ input }),
        buildGuestUpgradePlan(),
      ]);

      set({
        error: null,
        guestUpgradePlan: plan,
        isBootstrapped: true,
        isPending: false,
        session,
        syncStatus: deriveSyncStatus({ plan, session }),
      });
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Atlas could not create the account.',
        isPending: false,
      });
    }
  },
  syncStatus: initialSyncStatus,
}));
