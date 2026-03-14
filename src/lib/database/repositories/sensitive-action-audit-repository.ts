import type { DatabaseClient } from '@/src/lib/database/client';
import {
  mapSensitiveActionAuditEventRow,
  toSensitiveActionAuditEventRow,
} from '@/src/lib/database/mappers';
import {
  createSensitiveActionAuditEventInputSchema,
  type CreateSensitiveActionAuditEventInput,
  type SensitiveActionAuditEvent,
} from '@/src/lib/database/schemas';

export interface SensitiveActionAuditRepository {
  create(input: CreateSensitiveActionAuditEventInput): Promise<SensitiveActionAuditEvent>;
  listAll(): Promise<SensitiveActionAuditEvent[]>;
  listByProtocolId(protocolId: string): Promise<SensitiveActionAuditEvent[]>;
}

export class SqliteSensitiveActionAuditRepository implements SensitiveActionAuditRepository {
  constructor(private readonly client: DatabaseClient) {}

  async create(input: CreateSensitiveActionAuditEventInput): Promise<SensitiveActionAuditEvent> {
    const row = toSensitiveActionAuditEventRow(
      createSensitiveActionAuditEventInputSchema.parse(input)
    );

    await this.client.run(
      `INSERT INTO sensitive_action_audit_events (
        id, event_type, surface, protocol_id, scope_kind, render_mode, manifest_version, payload_json, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.event_type,
        row.surface,
        row.protocol_id,
        row.scope_kind,
        row.render_mode,
        row.manifest_version,
        row.payload_json,
        row.created_at,
      ]
    );

    return mapSensitiveActionAuditEventRow(row);
  }

  async listAll(): Promise<SensitiveActionAuditEvent[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM sensitive_action_audit_events ORDER BY created_at DESC'
    );
    return rows.map(mapSensitiveActionAuditEventRow);
  }

  async listByProtocolId(protocolId: string): Promise<SensitiveActionAuditEvent[]> {
    const rows = await this.client.getAll(
      `SELECT * FROM sensitive_action_audit_events
       WHERE protocol_id = ?
       ORDER BY created_at DESC`,
      [protocolId]
    );
    return rows.map(mapSensitiveActionAuditEventRow);
  }
}
