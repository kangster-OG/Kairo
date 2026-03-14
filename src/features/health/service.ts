import type { AtlasRepositories } from '@/src/lib/database/repositories';
import type { HealthConnection, HealthProviderKey } from '@/src/lib/database/schemas';
import { createIsoTimestamp } from '@/src/lib/database/id';
import {
  getHealthProviderAdapter,
  getHealthProviderAdapters,
} from '@/src/lib/health/client';

export type HealthConnectionListItem = {
  connected: boolean;
  description: string;
  enabled: boolean;
  lastError: string | null;
  lastSyncAt: string | null;
  platformLabel: string;
  providerKey: HealthProviderKey;
  statusLabel: string;
  supportedOnDevice: boolean;
  title: string;
};

type HealthRepositories = Pick<AtlasRepositories, 'healthConnections'>;

export async function getHealthConnectionItems({
  adapters = getHealthProviderAdapters(),
  repositories = loadHealthRepositories(),
}: {
  adapters?: ReturnType<typeof getHealthProviderAdapters>;
  repositories?: HealthRepositories | Promise<HealthRepositories>;
} = {}): Promise<HealthConnectionListItem[]> {
  const resolvedRepositories = await repositories;
  const stored = await resolvedRepositories.healthConnections.listAll();

  return Promise.all(
    adapters.map(async (adapter) => {
      const saved =
        stored.find((item) => item.providerKey === adapter.providerKey) ??
        (await resolvedRepositories.healthConnections.upsert({
          connected: false,
          enabled: false,
          providerKey: adapter.providerKey,
        }));
      const supportedOnDevice = await adapter.isAvailable();

      return toHealthConnectionListItem(saved, adapter.displayName, adapter.description, supportedOnDevice);
    })
  );
}

export async function setHealthConnectionEnabled(
  providerKey: HealthProviderKey,
  enabled: boolean,
  {
    adapterGetter = getHealthProviderAdapter,
    repositories = loadHealthRepositories(),
  }: {
    adapterGetter?: typeof getHealthProviderAdapter;
    repositories?: HealthRepositories | Promise<HealthRepositories>;
  } = {}
): Promise<HealthConnection | null> {
  const resolvedRepositories = await repositories;
  const adapter = adapterGetter(providerKey);

  if (!enabled) {
    const disconnectResult = await adapter.disconnect();
    return resolvedRepositories.healthConnections.update({
      connected: disconnectResult.connected,
      enabled: false,
      lastError: disconnectResult.lastError,
      lastSyncAt: disconnectResult.lastSyncAt,
      providerKey,
    });
  }

  return resolvedRepositories.healthConnections.update({
    enabled: true,
    lastError: null,
    providerKey,
  });
}

export async function attemptHealthConnection(
  providerKey: HealthProviderKey,
  {
    adapterGetter = getHealthProviderAdapter,
    repositories = loadHealthRepositories(),
  }: {
    adapterGetter?: typeof getHealthProviderAdapter;
    repositories?: HealthRepositories | Promise<HealthRepositories>;
  } = {}
): Promise<HealthConnection | null> {
  const resolvedRepositories = await repositories;
  const adapter = adapterGetter(providerKey);

  try {
    const supportedOnDevice = await adapter.isAvailable();

    if (!supportedOnDevice) {
      return resolvedRepositories.healthConnections.update({
        connected: false,
        enabled: true,
        lastError: providerKey === 'apple_health' ? 'Available on iPhone only.' : 'Available on Android only.',
        lastSyncAt: null,
        providerKey,
      });
    }

    const result = await adapter.connect();

    return resolvedRepositories.healthConnections.update({
      connected: result.connected,
      enabled: true,
      lastError: result.lastError,
      lastSyncAt: result.lastSyncAt ?? createIsoTimestamp(),
      providerKey,
    });
  } catch (error) {
    return resolvedRepositories.healthConnections.update({
      connected: false,
      enabled: true,
      lastError:
        error instanceof Error ? error.message : 'Atlas could not check the health connection.',
      lastSyncAt: null,
      providerKey,
    });
  }
}

function toHealthConnectionListItem(
  connection: HealthConnection,
  title: string,
  description: string,
  supportedOnDevice: boolean
): HealthConnectionListItem {
  return {
    connected: connection.connected,
    description,
    enabled: connection.enabled,
    lastError: connection.lastError,
    lastSyncAt: connection.lastSyncAt,
    platformLabel:
      connection.providerKey === 'apple_health' ? 'iOS only' : 'Android only',
    providerKey: connection.providerKey,
    statusLabel: connection.connected
      ? 'Connected'
      : connection.enabled
        ? supportedOnDevice
          ? 'Scaffolded'
          : 'Unavailable here'
        : 'Disabled',
    supportedOnDevice,
    title,
  };
}

async function loadHealthRepositories(): Promise<HealthRepositories> {
  const module = await import('@/src/lib/database');
  return module.getAtlasRepositories();
}
