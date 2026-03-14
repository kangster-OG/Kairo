import type { DatabaseClient } from '@/src/lib/database/client';
import { createIsoTimestamp } from '@/src/lib/database/id';
import { mapProtocolRow, toProtocolRow } from '@/src/lib/database/mappers';
import {
  createProtocolInputSchema,
  protocolStatusSchema,
  updateProtocolInputSchema,
  type CreateProtocolInput,
  type Protocol,
  type ProtocolStatus,
  type UpdateProtocolInput,
} from '@/src/lib/database/schemas';

export interface ProtocolRepository {
  create(input: CreateProtocolInput): Promise<Protocol>;
  delete(id: string): Promise<boolean>;
  getById(id: string): Promise<Protocol | null>;
  listActive(): Promise<Protocol[]>;
  listAll(): Promise<Protocol[]>;
  listByCompoundId(compoundId: string): Promise<Protocol[]>;
  update(input: UpdateProtocolInput): Promise<Protocol | null>;
  updateStatus(id: string, status: ProtocolStatus): Promise<Protocol | null>;
}

export class SqliteProtocolRepository implements ProtocolRepository {
  constructor(private readonly client: DatabaseClient) {}

  async create(input: CreateProtocolInput): Promise<Protocol> {
    const row = toProtocolRow(createProtocolInputSchema.parse(input));

    await this.client.run(
      `INSERT INTO protocols (
        id, compound_id, linked_vial_id, name, kind, status, timezone, start_date, default_time_of_day, dose_amount, dose_unit, site_tracking_enabled, site_rotation_enabled, notes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.compound_id,
        row.linked_vial_id,
        row.name,
        row.kind,
        row.status,
        row.timezone,
        row.start_date,
        row.default_time_of_day,
        row.dose_amount,
        row.dose_unit,
        row.site_tracking_enabled,
        row.site_rotation_enabled,
        row.notes,
        row.created_at,
        row.updated_at,
      ]
    );

    return mapProtocolRow(row);
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.client.run('DELETE FROM protocols WHERE id = ?', [id]);
    return result.changes > 0;
  }

  async getById(id: string): Promise<Protocol | null> {
    const row = await this.client.getFirst('SELECT * FROM protocols WHERE id = ?', [id]);
    return row ? mapProtocolRow(row) : null;
  }

  async listActive(): Promise<Protocol[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM protocols WHERE status = ? ORDER BY created_at DESC',
      ['active']
    );

    return rows.map(mapProtocolRow);
  }

  async listAll(): Promise<Protocol[]> {
    const rows = await this.client.getAll('SELECT * FROM protocols ORDER BY created_at DESC');
    return rows.map(mapProtocolRow);
  }

  async listByCompoundId(compoundId: string): Promise<Protocol[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM protocols WHERE compound_id = ? ORDER BY created_at DESC',
      [compoundId]
    );
    return rows.map(mapProtocolRow);
  }

  async update(input: UpdateProtocolInput): Promise<Protocol | null> {
    const parsed = updateProtocolInputSchema.parse(input);
    const existing = await this.getById(parsed.id);

    if (!existing) {
      return null;
    }

    const next: Protocol = {
      ...existing,
      compoundId: parsed.compoundId !== undefined ? parsed.compoundId : existing.compoundId,
      linkedVialId: parsed.linkedVialId !== undefined ? parsed.linkedVialId : existing.linkedVialId,
      name: parsed.name ?? existing.name,
      kind: parsed.kind ?? existing.kind,
      status: parsed.status ?? existing.status,
      timezone: parsed.timezone ?? existing.timezone,
      startDate: parsed.startDate ?? existing.startDate,
      defaultTimeOfDay:
        parsed.defaultTimeOfDay !== undefined
          ? parsed.defaultTimeOfDay
          : existing.defaultTimeOfDay,
      doseAmount: parsed.doseAmount !== undefined ? parsed.doseAmount : existing.doseAmount,
      doseUnit: parsed.doseUnit !== undefined ? parsed.doseUnit : existing.doseUnit,
      siteTrackingEnabled:
        parsed.siteTrackingEnabled !== undefined
          ? parsed.siteTrackingEnabled
          : existing.siteTrackingEnabled,
      siteRotationEnabled:
        parsed.siteRotationEnabled !== undefined
          ? parsed.siteRotationEnabled
          : existing.siteRotationEnabled,
      notes: parsed.notes !== undefined ? parsed.notes : existing.notes,
      updatedAt: createIsoTimestamp(),
    };

    await this.client.run(
      `UPDATE protocols
        SET compound_id = ?, linked_vial_id = ?, name = ?, kind = ?, status = ?, timezone = ?, start_date = ?, default_time_of_day = ?, dose_amount = ?, dose_unit = ?, site_tracking_enabled = ?, site_rotation_enabled = ?, notes = ?, updated_at = ?
        WHERE id = ?`,
      [
        next.compoundId,
        next.linkedVialId,
        next.name,
        next.kind,
        next.status,
        next.timezone,
        next.startDate,
        next.defaultTimeOfDay,
        next.doseAmount,
        next.doseUnit,
        next.siteTrackingEnabled ? 1 : 0,
        next.siteRotationEnabled ? 1 : 0,
        next.notes,
        next.updatedAt,
        next.id,
      ]
    );

    return next;
  }

  async updateStatus(id: string, status: ProtocolStatus): Promise<Protocol | null> {
    return this.update({
      id,
      status: protocolStatusSchema.parse(status),
    });
  }
}
