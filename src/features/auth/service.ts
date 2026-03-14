import { authCredentialsSchema } from '@/src/features/auth/schema';
import {
  clearStoredAuthSession,
  readStoredAuthSession,
  writeStoredAuthSession,
} from '@/src/features/auth/session-storage';
import type {
  AuthMutationInput,
  AuthSessionState,
  GuestUpgradePlan,
  StoredAuthSession,
  SyncStatus,
} from '@/src/features/auth/types';
import type { AuthGateway } from '@/src/features/auth/gateway';
import { createSupabaseAuthGateway } from '@/src/features/auth/gateway';
import type { AtlasRepositories } from '@/src/lib/database/repositories';
import {
  secureStoreAdapter,
  type SupabaseStorageAdapter,
} from '@/src/lib/supabase/secure-store-adapter';

type UpgradeRepositories = Pick<
  AtlasRepositories,
  | 'calculatorProfiles'
  | 'compounds'
  | 'customMetrics'
  | 'healthConnections'
  | 'logEvents'
  | 'metricValueLogs'
  | 'protocolRules'
  | 'protocols'
  | 'reminders'
  | 'sites'
  | 'symptomLogs'
  | 'vials'
  | 'weightLogs'
>;

export async function bootstrapAuthSession({
  gateway = createSupabaseAuthGateway(),
  storage = secureStoreAdapter,
}: {
  gateway?: AuthGateway;
  storage?: SupabaseStorageAdapter;
} = {}): Promise<AuthSessionState> {
  const stored = await readStoredAuthSession(storage);

  if (!stored) {
    return {
      email: null,
      lastBootstrapAt: new Date().toISOString(),
      status: 'guest',
      userId: null,
    };
  }

  return toSessionState(stored);
}

export async function signInWithEmail({
  gateway = createSupabaseAuthGateway(),
  input,
  storage = secureStoreAdapter,
}: {
  gateway?: AuthGateway;
  input: AuthMutationInput;
  storage?: SupabaseStorageAdapter;
}): Promise<AuthSessionState> {
  const parsed = authCredentialsSchema.parse(input);
  const session = await gateway.signInWithEmail(parsed.email, parsed.password);
  await writeStoredAuthSession(session, storage);
  return toSessionState(session);
}

export async function signUpWithEmail({
  gateway = createSupabaseAuthGateway(),
  input,
  storage = secureStoreAdapter,
}: {
  gateway?: AuthGateway;
  input: AuthMutationInput;
  storage?: SupabaseStorageAdapter;
}): Promise<AuthSessionState> {
  const parsed = authCredentialsSchema.parse(input);
  const session = await gateway.signUpWithEmail(parsed.email, parsed.password);
  await writeStoredAuthSession(session, storage);
  return toSessionState(session);
}

export async function signOutSession({
  gateway = createSupabaseAuthGateway(),
  storage = secureStoreAdapter,
}: {
  gateway?: AuthGateway;
  storage?: SupabaseStorageAdapter;
} = {}): Promise<AuthSessionState> {
  await gateway.signOut();
  await clearStoredAuthSession(storage);

  return {
    email: null,
    lastBootstrapAt: new Date().toISOString(),
    status: 'guest',
    userId: null,
  };
}

export async function buildGuestUpgradePlan(
  repositories?: UpgradeRepositories | Promise<UpgradeRepositories>
): Promise<GuestUpgradePlan> {
  const resolved = repositories
    ? await repositories
    : await (await import('@/src/lib/database')).getAtlasRepositories();
  const [
    calculatorProfiles,
    compounds,
    customMetrics,
    healthConnections,
    logEvents,
    metricValueLogs,
    protocolRules,
    protocols,
    reminders,
    sites,
    symptomLogs,
    vials,
    weightLogs,
  ] = await Promise.all([
    resolved.calculatorProfiles.listAll(),
    resolved.compounds.listAll(),
    resolved.customMetrics.listAll(),
    resolved.healthConnections.listAll(),
    resolved.logEvents.listAll(),
    resolved.metricValueLogs.listAll(),
    resolved.protocolRules.listAll(),
    resolved.protocols.listAll(),
    resolved.reminders.listAll(),
    resolved.sites.listAll(),
    resolved.symptomLogs.listAll(),
    resolved.vials.listAll(),
    resolved.weightLogs.listAll(),
  ]);

  const recordCounts = {
    calculatorProfiles: calculatorProfiles.length,
    compounds: compounds.length,
    customMetrics: customMetrics.length,
    healthConnections: healthConnections.length,
    logEvents: logEvents.length,
    metricValueLogs: metricValueLogs.length,
    protocolRules: protocolRules.length,
    protocols: protocols.length,
    reminders: reminders.length,
    sites: sites.length,
    symptomLogs: symptomLogs.length,
    vials: vials.length,
    weightLogs: weightLogs.length,
  };
  const pendingUploadCount = Object.values(recordCounts).reduce(
    (sum, count) => sum + count,
    0
  );

  return {
    hasLocalData: pendingUploadCount > 0,
    pendingUploadCount,
    recordCounts,
  };
}

export function deriveSyncStatus({
  lastError = null,
  lastSyncAt = null,
  plan,
  session,
}: {
  lastError?: string | null;
  lastSyncAt?: string | null;
  plan: GuestUpgradePlan;
  session: AuthSessionState;
}): SyncStatus {
  if (lastError) {
    return {
      lastError,
      lastSyncAt,
      mode: 'sync_error',
      pendingDownloadCount: 0,
      pendingUploadCount: plan.pendingUploadCount,
    };
  }

  if (session.status !== 'authenticated') {
    return {
      lastError: null,
      lastSyncAt,
      mode: 'local_only',
      pendingDownloadCount: 0,
      pendingUploadCount: 0,
    };
  }

  if (plan.pendingUploadCount > 0) {
    return {
      lastError: null,
      lastSyncAt,
      mode: 'ready_to_sync',
      pendingDownloadCount: 0,
      pendingUploadCount: plan.pendingUploadCount,
    };
  }

  return {
    lastError: null,
    lastSyncAt,
    mode: 'synced',
    pendingDownloadCount: 0,
    pendingUploadCount: 0,
  };
}

function toSessionState(session: StoredAuthSession): AuthSessionState {
  return {
    email: session.email,
    lastBootstrapAt: new Date().toISOString(),
    status: 'authenticated',
    userId: session.userId,
  };
}
