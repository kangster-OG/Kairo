import type { DatabaseClient } from '@/src/lib/database/client';
import { createIsoTimestamp } from '@/src/lib/database/id';
import {
  mapReminderRow,
  toReminderRow,
  toSqliteBooleanValue,
} from '@/src/lib/database/mappers';
import {
  createReminderInputSchema,
  updateReminderInputSchema,
  type CreateReminderInput,
  type Reminder,
  type UpdateReminderInput,
} from '@/src/lib/database/schemas';

export interface ReminderRepository {
  create(input: CreateReminderInput): Promise<Reminder>;
  delete(id: string): Promise<boolean>;
  deleteByProtocolId(protocolId: string): Promise<number>;
  getById(id: string): Promise<Reminder | null>;
  listAll(): Promise<Reminder[]>;
  listByProtocolId(protocolId: string): Promise<Reminder[]>;
  listEnabled(): Promise<Reminder[]>;
  update(input: UpdateReminderInput): Promise<Reminder | null>;
}

export class SqliteReminderRepository implements ReminderRepository {
  constructor(private readonly client: DatabaseClient) {}

  async create(input: CreateReminderInput): Promise<Reminder> {
    const row = toReminderRow(createReminderInputSchema.parse(input));

    await this.client.run(
      `INSERT INTO reminders (
        id, protocol_id, occurrence_id, offset_minutes, channel, is_enabled, discreet_copy_enabled, privacy_mode, scheduled_for, notification_id, title, body, status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.protocol_id,
        row.occurrence_id,
        row.offset_minutes,
        row.channel,
        row.is_enabled,
        row.discreet_copy_enabled,
        row.privacy_mode,
        row.scheduled_for,
        row.notification_id,
        row.title,
        row.body,
        row.status,
        row.created_at,
        row.updated_at,
      ]
    );

    return mapReminderRow(row);
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.client.run('DELETE FROM reminders WHERE id = ?', [id]);
    return result.changes > 0;
  }

  async deleteByProtocolId(protocolId: string): Promise<number> {
    const result = await this.client.run('DELETE FROM reminders WHERE protocol_id = ?', [protocolId]);
    return result.changes;
  }

  async getById(id: string): Promise<Reminder | null> {
    const row = await this.client.getFirst('SELECT * FROM reminders WHERE id = ?', [id]);
    return row ? mapReminderRow(row) : null;
  }

  async listAll(): Promise<Reminder[]> {
    const rows = await this.client.getAll('SELECT * FROM reminders ORDER BY scheduled_for ASC, created_at ASC');
    return rows.map(mapReminderRow);
  }

  async listByProtocolId(protocolId: string): Promise<Reminder[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM reminders WHERE protocol_id = ? ORDER BY scheduled_for ASC, created_at ASC',
      [protocolId]
    );
    return rows.map(mapReminderRow);
  }

  async listEnabled(): Promise<Reminder[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM reminders WHERE is_enabled = 1 ORDER BY scheduled_for ASC, created_at ASC'
    );
    return rows.map(mapReminderRow);
  }

  async update(input: UpdateReminderInput): Promise<Reminder | null> {
    const parsed = updateReminderInputSchema.parse(input);
    const existing = await this.getById(parsed.id);

    if (!existing) {
      return null;
    }

    const next: Reminder = {
      ...existing,
      protocolId: parsed.protocolId ?? existing.protocolId,
      occurrenceId: parsed.occurrenceId ?? existing.occurrenceId,
      offsetMinutes: parsed.offsetMinutes ?? existing.offsetMinutes,
      channel: parsed.channel ?? existing.channel,
      isEnabled: parsed.isEnabled ?? existing.isEnabled,
      discreetCopyEnabled:
        parsed.discreetCopyEnabled ?? existing.discreetCopyEnabled,
      privacyMode: parsed.privacyMode ?? existing.privacyMode,
      scheduledFor: parsed.scheduledFor ?? existing.scheduledFor,
      notificationId:
        parsed.notificationId === undefined ? existing.notificationId : parsed.notificationId,
      title: parsed.title ?? existing.title,
      body: parsed.body ?? existing.body,
      status: parsed.status ?? existing.status,
      updatedAt: createIsoTimestamp(),
    };

    await this.client.run(
      `UPDATE reminders
        SET protocol_id = ?, occurrence_id = ?, offset_minutes = ?, channel = ?, is_enabled = ?, discreet_copy_enabled = ?, privacy_mode = ?, scheduled_for = ?, notification_id = ?, title = ?, body = ?, status = ?, updated_at = ?
        WHERE id = ?`,
      [
        next.protocolId,
        next.occurrenceId,
        next.offsetMinutes,
        next.channel,
        toSqliteBooleanValue(next.isEnabled),
        toSqliteBooleanValue(next.discreetCopyEnabled),
        next.privacyMode,
        next.scheduledFor,
        next.notificationId,
        next.title,
        next.body,
        next.status,
        next.updatedAt,
        next.id,
      ]
    );

    return next;
  }
}
