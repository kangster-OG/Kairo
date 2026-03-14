import { Platform } from 'react-native';

import type { HealthProviderKey } from '@/src/lib/database/schemas';

export type HealthAdapterResult = {
  connected: boolean;
  lastError: string | null;
  lastSyncAt: string | null;
};

export type HealthProviderAdapter = {
  connect: () => Promise<HealthAdapterResult>;
  description: string;
  disconnect: () => Promise<HealthAdapterResult>;
  displayName: string;
  isAvailable: () => Promise<boolean>;
  providerKey: HealthProviderKey;
};

const adapters: Record<HealthProviderKey, HealthProviderAdapter> = {
  apple_health: {
    async connect() {
      return {
        connected: false,
        lastError: 'Apple Health scaffolding is ready, but native read/write is not enabled in this build yet.',
        lastSyncAt: null,
      };
    },
    description: 'Optional Apple Health import/export bridge for future weight and wellness context.',
    async disconnect() {
      return {
        connected: false,
        lastError: null,
        lastSyncAt: null,
      };
    },
    displayName: 'Apple Health',
    async isAvailable() {
      return Platform.OS === 'ios';
    },
    providerKey: 'apple_health',
  },
  health_connect: {
    async connect() {
      return {
        connected: false,
        lastError:
          'Health Connect scaffolding is ready, but native permission and sync flows are not enabled in this build yet.',
        lastSyncAt: null,
      };
    },
    description: 'Optional Health Connect bridge for Android wellness and body metrics.',
    async disconnect() {
      return {
        connected: false,
        lastError: null,
        lastSyncAt: null,
      };
    },
    displayName: 'Health Connect',
    async isAvailable() {
      return Platform.OS === 'android';
    },
    providerKey: 'health_connect',
  },
};

export function getHealthProviderAdapters(): HealthProviderAdapter[] {
  return Object.values(adapters);
}

export function getHealthProviderAdapter(providerKey: HealthProviderKey): HealthProviderAdapter {
  return adapters[providerKey];
}
