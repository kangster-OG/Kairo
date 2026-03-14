import type { DatabaseClient } from '@/src/lib/database/client';
import { mapLogEventRow, toLogEventRow } from '@/src/lib/database/mappers';
import {
  createLogEventInputSchema,
  type CreateLogEventInput,
  type LogEvent,
} from '@/src/lib/database/schemas';

export interface LogEventRepository {
  create(input: CreateLogEventInput): Promise<LogEvent>;
  getById(id: string): Promise<LogEvent | null>;
  listAll(): Promise<LogEvent[]>;
  listByProtocolId(protocolId: string): Promise<LogEvent[]>;
  listRecent(limit?: number): Promise<LogEvent[]>;
}

export class SqliteLogEventRepository implements LogEventRepository {
  constructor(private readonly client: DatabaseClient) {}

  async create(input: CreateLogEventInput): Promise<LogEvent> {
    const row = toLogEventRow(createLogEventInputSchema.parse(input));

    await this.client.run(
      `INSERT INTO log_events (
        id, protocol_id, vial_id, site_id, occurrence_id, event_type, effective_at, logged_at, quantity, quantity_unit, notes, source
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.protocol_id,
        row.vial_id,
        row.site_id,
        row.occurrence_id,
        row.event_type,
        row.effective_at,
        row.logged_at,
        row.quantity,
        row.quantity_unit,
        row.notes,
        row.source,
      ]
    );

    return mapLogEventRow(row);
  }

  async getById(id: string): Promise<LogEvent | null> {
    const row = await this.client.getFirst('SELECT * FROM log_events WHERE id = ?', [id]);
    return row ? mapLogEventRow(row) : null;
  }

  async listAll(): Promise<LogEvent[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM log_events ORDER BY effective_at DESC, logged_at DESC'
    );
    return rows.map(mapLogEventRow);
  }

  async listByProtocolId(protocolId: string): Promise<LogEvent[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM log_events WHERE protocol_id = ? ORDER BY effective_at DESC, logged_at DESC',
      [protocolId]
    );
    return rows.map(mapLogEventRow);
  }

  async listRecent(limit = 20): Promise<LogEvent[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM log_events ORDER BY effective_at DESC, logged_at DESC LIMIT ?',
      [limit]
    );
    return rows.map(mapLogEventRow);
  }
}
