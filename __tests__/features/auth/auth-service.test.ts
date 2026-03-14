import { buildGuestUpgradePlan, bootstrapAuthSession, deriveSyncStatus, signInWithEmail, signOutSession, signUpWithEmail } from '@/src/features/auth/service';
import type { AuthGateway } from '@/src/features/auth/gateway';
import type { AtlasRepositories } from '@/src/lib/database/repositories';

function createMemoryStorage(initial: Record<string, string> = {}) {
  const store = { ...initial };

  return {
    async getItem(key: string) {
      return store[key] ?? null;
    },
    async removeItem(key: string) {
      delete store[key];
    },
    async setItem(key: string, value: string) {
      store[key] = value;
    },
    snapshot() {
      return store;
    },
  };
}

function createGateway(sessionOverrides: Partial<Awaited<ReturnType<AuthGateway['signInWithEmail']>>> = {}): AuthGateway {
  const baseSession = {
    accessToken: 'token',
    email: 'member@example.com',
    expiresAt: 123456,
    refreshToken: 'refresh',
    userId: 'user_123',
  };

  return {
    async getCurrentSession() {
      return { ...baseSession, ...sessionOverrides };
    },
    hasClient() {
      return true;
    },
    async signInWithEmail() {
      return { ...baseSession, ...sessionOverrides };
    },
    async signOut() {},
    async signUpWithEmail() {
      return { ...baseSession, ...sessionOverrides };
    },
  };
}

function createCountingRepositories(counts: {
  calculatorProfiles?: number;
  compounds?: number;
  customMetrics?: number;
  healthConnections?: number;
  logEvents?: number;
  metricValueLogs?: number;
  protocolRules?: number;
  protocols?: number;
  reminders?: number;
  sites?: number;
  symptomLogs?: number;
  vials?: number;
  weightLogs?: number;
}): Pick<
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
> {
  const list = (count = 0) => async () => Array.from({ length: count }, (_, index) => ({ id: `${index}` }));

  return {
    calculatorProfiles: { listAll: list(counts.calculatorProfiles) } as AtlasRepositories['calculatorProfiles'],
    compounds: { listAll: list(counts.compounds) } as AtlasRepositories['compounds'],
    customMetrics: { listAll: list(counts.customMetrics) } as AtlasRepositories['customMetrics'],
    healthConnections: { listAll: list(counts.healthConnections) } as unknown as AtlasRepositories['healthConnections'],
    logEvents: { listAll: list(counts.logEvents) } as AtlasRepositories['logEvents'],
    metricValueLogs: { listAll: list(counts.metricValueLogs) } as AtlasRepositories['metricValueLogs'],
    protocolRules: { listAll: list(counts.protocolRules) } as AtlasRepositories['protocolRules'],
    protocols: { listAll: list(counts.protocols) } as AtlasRepositories['protocols'],
    reminders: { listAll: list(counts.reminders) } as AtlasRepositories['reminders'],
    sites: { listAll: list(counts.sites) } as AtlasRepositories['sites'],
    symptomLogs: { listAll: list(counts.symptomLogs) } as AtlasRepositories['symptomLogs'],
    vials: { listAll: list(counts.vials) } as AtlasRepositories['vials'],
    weightLogs: { listAll: list(counts.weightLogs) } as AtlasRepositories['weightLogs'],
  };
}

describe('auth service', () => {
  it('bootstraps to guest mode when no stored session exists', async () => {
    const storage = createMemoryStorage();

    const session = await bootstrapAuthSession({
      gateway: createGateway(),
      storage,
    });

    expect(session.status).toBe('guest');
    expect(session.userId).toBeNull();
  });

  it('bootstraps an authenticated session from SecureStore state', async () => {
    const storage = createMemoryStorage({
      'atlas.auth.session.v1': JSON.stringify({
        accessToken: 'token',
        email: 'member@example.com',
        expiresAt: 123456,
        refreshToken: 'refresh',
        userId: 'user_123',
      }),
    });

    const session = await bootstrapAuthSession({
      gateway: createGateway(),
      storage,
    });

    expect(session.status).toBe('authenticated');
    expect(session.email).toBe('member@example.com');
    expect(session.userId).toBe('user_123');
  });

  it('writes the signed-in session to SecureStore', async () => {
    const storage = createMemoryStorage();

    const session = await signInWithEmail({
      gateway: createGateway(),
      input: { email: 'member@example.com', password: 'password123' },
      storage,
    });

    expect(session.status).toBe('authenticated');
    expect(storage.snapshot()['atlas.auth.session.v1']).toContain('member@example.com');
  });

  it('writes the signed-up session and clears it on sign out', async () => {
    const storage = createMemoryStorage();
    const gateway = createGateway();

    await signUpWithEmail({
      gateway,
      input: { email: 'member@example.com', password: 'password123' },
      storage,
    });

    expect(storage.snapshot()['atlas.auth.session.v1']).toContain('member@example.com');

    const nextSession = await signOutSession({
      gateway,
      storage,
    });

    expect(nextSession.status).toBe('guest');
    expect(storage.snapshot()['atlas.auth.session.v1']).toBeUndefined();
  });

  it('builds a guest upgrade plan from local repository counts', async () => {
    const plan = await buildGuestUpgradePlan(
      createCountingRepositories({
        compounds: 2,
        logEvents: 3,
        protocolRules: 2,
        protocols: 1,
        reminders: 4,
        sites: 2,
        vials: 1,
      })
    );

    expect(plan.hasLocalData).toBe(true);
    expect(plan.pendingUploadCount).toBe(15);
    expect(plan.recordCounts.logEvents).toBe(3);
  });

  it('derives sync state without blocking local-first guest usage', () => {
    const guestSync = deriveSyncStatus({
      plan: {
        hasLocalData: true,
        pendingUploadCount: 12,
        recordCounts: {
          calculatorProfiles: 0,
          compounds: 1,
          customMetrics: 0,
          healthConnections: 0,
          logEvents: 5,
          metricValueLogs: 0,
          protocolRules: 2,
          protocols: 1,
          reminders: 1,
          sites: 1,
          symptomLogs: 0,
          vials: 1,
          weightLogs: 0,
        },
      },
      session: {
        email: null,
        lastBootstrapAt: null,
        status: 'guest',
        userId: null,
      },
    });

    const accountSync = deriveSyncStatus({
      plan: {
        hasLocalData: true,
        pendingUploadCount: 12,
        recordCounts: {
          calculatorProfiles: 0,
          compounds: 1,
          customMetrics: 0,
          healthConnections: 0,
          logEvents: 5,
          metricValueLogs: 0,
          protocolRules: 2,
          protocols: 1,
          reminders: 1,
          sites: 1,
          symptomLogs: 0,
          vials: 1,
          weightLogs: 0,
        },
      },
      session: {
        email: 'member@example.com',
        lastBootstrapAt: null,
        status: 'authenticated',
        userId: 'user_123',
      },
    });

    expect(guestSync.mode).toBe('local_only');
    expect(accountSync.mode).toBe('ready_to_sync');
    expect(accountSync.pendingUploadCount).toBe(12);
  });
});
