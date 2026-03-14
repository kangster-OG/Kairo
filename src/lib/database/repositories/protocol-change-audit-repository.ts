import type { DatabaseClient } from '@/src/lib/database/client';
import {
  mapProtocolChangeAuditEventRow,
  toProtocolChangeAuditEventRow,
} from '@/src/lib/database/mappers';
import {
  createProtocolChangeAuditEventInputSchema,
  type CreateProtocolChangeAuditEventInput,
  type ProtocolChangeAuditEvent,
} from '@/src/lib/database/schemas';

export interface ProtocolChangeAuditRepository {
  create(input: CreateProtocolChangeAuditEventInput): Promise<ProtocolChangeAuditEvent>;
  listAll(): Promise<ProtocolChangeAuditEvent[]>;
  listByProtocolId(protocolId: string): Promise<ProtocolChangeAuditEvent[]>;
}

export class SqliteProtocolChangeAuditRepository implements ProtocolChangeAuditRepository {
  constructor(private readonly client: DatabaseClient) {}

  async create(input: CreateProtocolChangeAuditEventInput): Promise<ProtocolChangeAuditEvent> {
    const row = toProtocolChangeAuditEventRow(
      createProtocolChangeAuditEventInputSchema.parse(input)
    );

    await this.client.run(
      `INSERT INTO protocol_change_audit_events (
        id, protocol_id, revision_id, previous_revision_id, change_type, effective_from,
        summary, payload_json, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.protocol_id,
        row.revision_id,
        row.previous_revision_id,
        row.change_type,
        row.effective_from,
        row.summary,
        row.payload_json,
        row.created_at,
      ]
    );

    return mapProtocolChangeAuditEventRow(row);
  }

  async listAll(): Promise<ProtocolChangeAuditEvent[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM protocol_change_audit_events ORDER BY created_at DESC'
    );
    return rows.map(mapProtocolChangeAuditEventRow);
  }

  async listByProtocolId(protocolId: string): Promise<ProtocolChangeAuditEvent[]> {
    const rows = await this.client.getAll(
      `SELECT * FROM protocol_change_audit_events
       WHERE protocol_id = ?
       ORDER BY created_at DESC`,
      [protocolId]
    );
    return rows.map(mapProtocolChangeAuditEventRow);
  }
}
