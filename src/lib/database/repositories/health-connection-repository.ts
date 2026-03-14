import type { DatabaseClient } from '@/src/lib/database/client';
import { createIsoTimestamp } from '@/src/lib/database/id';
import { mapHealthConnectionRow, toHealthConnectionRow, toSqliteBooleanValue } from '@/src/lib/database/mappers';
import {
  createHealthConnectionInputSchema,
  updateHealthConnectionInputSchema,
  type CreateHealthConnectionInput,
  type HealthConnection,
  type HealthProviderKey,
  type UpdateHealthConnectionInput,
} from '@/src/lib/database/schemas';

export interface HealthConnectionRepository {
  getByProviderKey(providerKey: HealthProviderKey): Promise<HealthConnection | null>;
  listAll(): Promise<HealthConnection[]>;
  upsert(input: CreateHealthConnectionInput): Promise<HealthConnection>;
  update(input: UpdateHealthConnectionInput): Promise<HealthConnection | null>;
}

export class SqliteHealthConnectionRepository implements HealthConnectionRepository {
  constructor(private readonly client: DatabaseClient) {}

  async getByProviderKey(providerKey: HealthProviderKey): Promise<HealthConnection | null> {
    const row = await this.client.getFirst(
      'SELECT * FROM health_connections WHERE provider_key = ?',
      [providerKey]
    );
    return row ? mapHealthConnectionRow(row) : null;
  }

  async listAll(): Promise<HealthConnection[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM health_connections ORDER BY provider_key ASC'
    );
    return rows.map(mapHealthConnectionRow);
  }

  async upsert(input: CreateHealthConnectionInput): Promise<HealthConnection> {
    const row = toHealthConnectionRow(createHealthConnectionInputSchema.parse(input));

    await this.client.run(
      `INSERT INTO health_connections (
        provider_key, enabled, connected, last_sync_at, last_error, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(provider_key) DO UPDATE SET
        enabled = excluded.enabled,
        connected = excluded.connected,
        last_sync_at = excluded.last_sync_at,
        last_error = excluded.last_error,
        updated_at = excluded.updated_at`,
      [
        row.provider_key,
        row.enabled,
        row.connected,
        row.last_sync_at,
        row.last_error,
        row.created_at,
        row.updated_at,
      ]
    );

    return this.getByProviderKey(row.provider_key) as Promise<HealthConnection>;
  }

  async update(input: UpdateHealthConnectionInput): Promise<HealthConnection | null> {
    const parsed = updateHealthConnectionInputSchema.parse(input);
    const existing = await this.getByProviderKey(parsed.providerKey);

    if (!existing) {
      return null;
    }

    const next: HealthConnection = {
      ...existing,
      enabled: parsed.enabled ?? existing.enabled,
      connected: parsed.connected ?? existing.connected,
      lastError: parsed.lastError !== undefined ? parsed.lastError : existing.lastError,
      lastSyncAt: parsed.lastSyncAt !== undefined ? parsed.lastSyncAt : existing.lastSyncAt,
      updatedAt: createIsoTimestamp(),
    };

    await this.client.run(
      `UPDATE health_connections
        SET enabled = ?, connected = ?, last_sync_at = ?, last_error = ?, updated_at = ?
        WHERE provider_key = ?`,
      [
        toSqliteBooleanValue(next.enabled),
        toSqliteBooleanValue(next.connected),
        next.lastSyncAt,
        next.lastError,
        next.updatedAt,
        next.providerKey,
      ]
    );

    return next;
  }
}
