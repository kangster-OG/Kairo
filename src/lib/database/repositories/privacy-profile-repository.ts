import type { DatabaseClient } from '@/src/lib/database/client';
import { createIsoTimestamp } from '@/src/lib/database/id';
import {
  mapPrivacyProfileRow,
  toPrivacyProfileRow,
  toSqliteBooleanValue,
} from '@/src/lib/database/mappers';
import {
  createPrivacyProfileInputSchema,
  updatePrivacyProfileInputSchema,
  type CreatePrivacyProfileInput,
  type PrivacyProfile,
  type UpdatePrivacyProfileInput,
} from '@/src/lib/database/schemas';

const DEFAULT_PRIVACY_PROFILE_ID = 'default';

export interface PrivacyProfileRepository {
  get(): Promise<PrivacyProfile>;
  save(input: CreatePrivacyProfileInput): Promise<PrivacyProfile>;
  update(input: UpdatePrivacyProfileInput): Promise<PrivacyProfile>;
}

export class SqlitePrivacyProfileRepository implements PrivacyProfileRepository {
  constructor(private readonly client: DatabaseClient) {}

  async get(): Promise<PrivacyProfile> {
    const row = await this.client.getFirst('SELECT * FROM privacy_profile WHERE id = ?', [
      DEFAULT_PRIVACY_PROFILE_ID,
    ]);

    if (row) {
      return mapPrivacyProfileRow(row);
    }

    return this.save({
      aliasModeEnabled: false,
      biometricGateMode: 'best_effort',
      biometricLockEnabled: false,
      exportAliasByDefault: false,
      shareAliasByDefault: true,
      id: DEFAULT_PRIVACY_PROFILE_ID,
    });
  }

  async save(input: CreatePrivacyProfileInput): Promise<PrivacyProfile> {
    const row = toPrivacyProfileRow(createPrivacyProfileInputSchema.parse(input));

    await this.client.run(
      `INSERT OR REPLACE INTO privacy_profile (
        id, alias_mode_enabled, biometric_lock_enabled, biometric_gate_mode,
        share_alias_by_default, export_alias_by_default, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.alias_mode_enabled,
        row.biometric_lock_enabled,
        row.biometric_gate_mode,
        row.share_alias_by_default,
        row.export_alias_by_default,
        row.created_at,
        row.updated_at,
      ]
    );

    return mapPrivacyProfileRow(row);
  }

  async update(input: UpdatePrivacyProfileInput): Promise<PrivacyProfile> {
    const parsed = updatePrivacyProfileInputSchema.parse(input);
    const existing = await this.get();
    const next: PrivacyProfile = {
      ...existing,
      aliasModeEnabled: parsed.aliasModeEnabled ?? existing.aliasModeEnabled,
      biometricLockEnabled: parsed.biometricLockEnabled ?? existing.biometricLockEnabled,
      biometricGateMode: parsed.biometricGateMode ?? existing.biometricGateMode,
      shareAliasByDefault: parsed.shareAliasByDefault ?? existing.shareAliasByDefault,
      exportAliasByDefault: parsed.exportAliasByDefault ?? existing.exportAliasByDefault,
      updatedAt: createIsoTimestamp(),
    };

    await this.client.run(
      `UPDATE privacy_profile
       SET alias_mode_enabled = ?, biometric_lock_enabled = ?, biometric_gate_mode = ?,
           share_alias_by_default = ?, export_alias_by_default = ?, updated_at = ?
       WHERE id = ?`,
      [
        toSqliteBooleanValue(next.aliasModeEnabled),
        toSqliteBooleanValue(next.biometricLockEnabled),
        next.biometricGateMode,
        toSqliteBooleanValue(next.shareAliasByDefault),
        toSqliteBooleanValue(next.exportAliasByDefault),
        next.updatedAt,
        next.id,
      ]
    );

    return next;
  }
}
