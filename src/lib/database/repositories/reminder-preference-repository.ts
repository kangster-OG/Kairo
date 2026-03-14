import type { DatabaseClient } from '@/src/lib/database/client';
import { createIsoTimestamp } from '@/src/lib/database/id';
import {
  mapReminderPreferenceRow,
  toReminderPreferenceRow,
  toSqliteBooleanValue,
} from '@/src/lib/database/mappers';
import {
  createReminderPreferenceInputSchema,
  updateReminderPreferenceInputSchema,
  type CreateReminderPreferenceInput,
  type ReminderPreference,
  type UpdateReminderPreferenceInput,
} from '@/src/lib/database/schemas';

export interface ReminderPreferenceRepository {
  get(): Promise<ReminderPreference>;
  save(input: CreateReminderPreferenceInput): Promise<ReminderPreference>;
  update(input: UpdateReminderPreferenceInput): Promise<ReminderPreference>;
}

const DEFAULT_PREFERENCE_ID = 'default';

export class SqliteReminderPreferenceRepository implements ReminderPreferenceRepository {
  constructor(private readonly client: DatabaseClient) {}

  async get(): Promise<ReminderPreference> {
    const row = await this.client.getFirst(
      'SELECT * FROM reminder_preferences WHERE id = ?',
      [DEFAULT_PREFERENCE_ID]
    );

    if (row) {
      return mapReminderPreferenceRow(row);
    }

    return this.save({
      id: DEFAULT_PREFERENCE_ID,
      leadTimeMinutes: 0,
      privacyMode: 'full_detail',
      remindersEnabled: true,
    });
  }

  async save(input: CreateReminderPreferenceInput): Promise<ReminderPreference> {
    const row = toReminderPreferenceRow(createReminderPreferenceInputSchema.parse(input));

    await this.client.run(
      `INSERT OR REPLACE INTO reminder_preferences (
        id, reminders_enabled, privacy_mode, lead_time_minutes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.reminders_enabled,
        row.privacy_mode,
        row.lead_time_minutes,
        row.created_at,
        row.updated_at,
      ]
    );

    return mapReminderPreferenceRow(row);
  }

  async update(input: UpdateReminderPreferenceInput): Promise<ReminderPreference> {
    const parsed = updateReminderPreferenceInputSchema.parse(input);
    const existing = await this.get();
    const next: ReminderPreference = {
      ...existing,
      remindersEnabled: parsed.remindersEnabled ?? existing.remindersEnabled,
      privacyMode: parsed.privacyMode ?? existing.privacyMode,
      leadTimeMinutes: parsed.leadTimeMinutes ?? existing.leadTimeMinutes,
      updatedAt: createIsoTimestamp(),
    };

    await this.client.run(
      `UPDATE reminder_preferences
       SET reminders_enabled = ?, privacy_mode = ?, lead_time_minutes = ?, updated_at = ?
       WHERE id = ?`,
      [
        toSqliteBooleanValue(next.remindersEnabled),
        next.privacyMode,
        next.leadTimeMinutes,
        next.updatedAt,
        next.id,
      ]
    );

    return next;
  }
}
