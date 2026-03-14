import {
  attemptHealthConnection,
  getHealthConnectionItems,
  setHealthConnectionEnabled,
} from '@/src/features/health/service';
import type {
  HealthConnection,
  HealthProviderKey,
} from '@/src/lib/database/schemas';

describe('health service', () => {
  it('maps provider scaffolding into settings-safe list items', async () => {
    const repository = createHealthRepository();

    const items = await getHealthConnectionItems({
      adapters: [
        {
          async connect() {
            return { connected: false, lastError: 'Not ready', lastSyncAt: null };
          },
          description: 'iOS bridge',
          async disconnect() {
            return { connected: false, lastError: null, lastSyncAt: null };
          },
          displayName: 'Apple Health',
          async isAvailable() {
            return true;
          },
          providerKey: 'apple_health',
        },
      ],
      repositories: repository,
    });

    expect(items[0]).toEqual(
      expect.objectContaining({
        statusLabel: 'Disabled',
        supportedOnDevice: true,
        title: 'Apple Health',
      })
    );
  });

  it('keeps failures isolated when the adapter throws during connection', async () => {
    const repository = createHealthRepository();

    const result = await attemptHealthConnection('health_connect', {
      adapterGetter() {
        return {
          async connect() {
            throw new Error('Native bridge offline');
          },
          description: 'Android bridge',
          async disconnect() {
            return { connected: false, lastError: null, lastSyncAt: null };
          },
          displayName: 'Health Connect',
          async isAvailable() {
            return true;
          },
          providerKey: 'health_connect',
        };
      },
      repositories: repository,
    });

    expect(result?.connected).toBe(false);
    expect(result?.lastError).toBe('Native bridge offline');

    const disabled = await setHealthConnectionEnabled('health_connect', false, {
      adapterGetter() {
        return {
          async connect() {
            return { connected: false, lastError: null, lastSyncAt: null };
          },
          description: 'Android bridge',
          async disconnect() {
            return { connected: false, lastError: null, lastSyncAt: null };
          },
          displayName: 'Health Connect',
          async isAvailable() {
            return true;
          },
          providerKey: 'health_connect',
        };
      },
      repositories: repository,
    });

    expect(disabled?.enabled).toBe(false);
  });
});

function createHealthRepository() {
  const store = new Map<HealthProviderKey, HealthConnection>([
    [
      'apple_health',
      createHealthConnection('apple_health'),
    ],
    [
      'health_connect',
      createHealthConnection('health_connect'),
    ],
  ]);

  return {
    healthConnections: {
      async getByProviderKey(providerKey: HealthProviderKey) {
        return store.get(providerKey) ?? null;
      },
      async listAll() {
        return [...store.values()];
      },
      async update(input: {
        providerKey: HealthProviderKey;
        connected?: boolean;
        enabled?: boolean;
        lastSyncAt?: string | null;
        lastError?: string | null;
      }) {
        const existing = store.get(input.providerKey);
        if (!existing) {
          return null;
        }

        const next: HealthConnection = {
          ...existing,
          connected: input.connected ?? existing.connected,
          enabled: input.enabled ?? existing.enabled,
          lastError: input.lastError !== undefined ? input.lastError : existing.lastError,
          lastSyncAt: input.lastSyncAt !== undefined ? input.lastSyncAt : existing.lastSyncAt,
          updatedAt: '2026-03-13T12:00:00.000Z',
        };
        store.set(input.providerKey, next);
        return next;
      },
      async upsert(input: {
        providerKey: HealthProviderKey;
        connected: boolean;
        enabled: boolean;
        lastSyncAt?: string | null;
        lastError?: string | null;
      }) {
        const next: HealthConnection = {
          createdAt: '2026-03-01T00:00:00.000Z',
          lastError: input.lastError ?? null,
          lastSyncAt: input.lastSyncAt ?? null,
          providerKey: input.providerKey,
          connected: input.connected,
          enabled: input.enabled,
          updatedAt: '2026-03-13T12:00:00.000Z',
        };
        store.set(input.providerKey, next);
        return next;
      },
    },
  };
}

function createHealthConnection(providerKey: HealthProviderKey): HealthConnection {
  return {
    connected: false,
    createdAt: '2026-03-01T00:00:00.000Z',
    enabled: false,
    lastError: null,
    lastSyncAt: null,
    providerKey,
    updatedAt: '2026-03-01T00:00:00.000Z',
  };
}
