export type StoredAuthSession = {
  accessToken: string;
  email: string | null;
  expiresAt: number | null;
  refreshToken: string | null;
  userId: string;
};

export type AuthStatus = 'bootstrapping' | 'guest' | 'authenticated' | 'signed_out';

export type AuthSessionState = {
  email: string | null;
  lastBootstrapAt: string | null;
  status: AuthStatus;
  userId: string | null;
};

export type AuthMutationInput = {
  email: string;
  password: string;
};

export type GuestUpgradePlan = {
  hasLocalData: boolean;
  pendingUploadCount: number;
  recordCounts: {
    calculatorProfiles: number;
    compounds: number;
    customMetrics: number;
    healthConnections: number;
    logEvents: number;
    metricValueLogs: number;
    protocolRules: number;
    protocols: number;
    reminders: number;
    sites: number;
    symptomLogs: number;
    vials: number;
    weightLogs: number;
  };
};

export type SyncMode = 'local_only' | 'ready_to_sync' | 'syncing' | 'sync_error' | 'synced';

export type SyncStatus = {
  lastError: string | null;
  lastSyncAt: string | null;
  mode: SyncMode;
  pendingDownloadCount: number;
  pendingUploadCount: number;
};
