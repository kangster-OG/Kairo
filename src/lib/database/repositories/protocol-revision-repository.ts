import type { DatabaseClient } from '@/src/lib/database/client';
import { createIsoTimestamp } from '@/src/lib/database/id';
import {
  mapProtocolRevisionRow,
  toProtocolRevisionRow,
} from '@/src/lib/database/mappers';
import {
  createProtocolRevisionInputSchema,
  updateProtocolRevisionInputSchema,
  type CreateProtocolRevisionInput,
  type ProtocolRevision,
  type UpdateProtocolRevisionInput,
} from '@/src/lib/database/schemas';

export interface ProtocolRevisionRepository {
  closeCurrentAndSupersedeFuture(protocolId: string, effectiveFrom: string): Promise<void>;
  create(input: CreateProtocolRevisionInput): Promise<ProtocolRevision>;
  getById(id: string): Promise<ProtocolRevision | null>;
  getEffectiveAt(protocolId: string, effectiveAt: string): Promise<ProtocolRevision | null>;
  listAll(): Promise<ProtocolRevision[]>;
  listByProtocolId(protocolId: string): Promise<ProtocolRevision[]>;
  update(input: UpdateProtocolRevisionInput): Promise<ProtocolRevision | null>;
}

export class SqliteProtocolRevisionRepository implements ProtocolRevisionRepository {
  constructor(private readonly client: DatabaseClient) {}

  async closeCurrentAndSupersedeFuture(protocolId: string, effectiveFrom: string): Promise<void> {
    await this.client.run(
      `UPDATE protocol_revisions
         SET effective_to = CASE
           WHEN effective_from >= ? THEN effective_from
           ELSE ?
         END,
             updated_at = ?
       WHERE protocol_id = ?
         AND (
           effective_from >= ?
           OR (effective_from < ? AND (effective_to IS NULL OR effective_to > ?))
         )`,
      [effectiveFrom, effectiveFrom, createIsoTimestamp(), protocolId, effectiveFrom, effectiveFrom, effectiveFrom]
    );
  }

  async create(input: CreateProtocolRevisionInput): Promise<ProtocolRevision> {
    const row = toProtocolRevisionRow(createProtocolRevisionInputSchema.parse(input));

    await this.client.run(
      `INSERT INTO protocol_revisions (
        id, protocol_id, revision_number, previous_revision_id, effective_from, effective_to,
        lifecycle_state, timezone, timezone_strategy, default_time_of_day, dose_amount, dose_unit,
        linked_vial_id, missed_dose_policy, notes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.protocol_id,
        row.revision_number,
        row.previous_revision_id,
        row.effective_from,
        row.effective_to,
        row.lifecycle_state,
        row.timezone,
        row.timezone_strategy,
        row.default_time_of_day,
        row.dose_amount,
        row.dose_unit,
        row.linked_vial_id,
        row.missed_dose_policy,
        row.notes,
        row.created_at,
        row.updated_at,
      ]
    );

    return mapProtocolRevisionRow(row);
  }

  async getById(id: string): Promise<ProtocolRevision | null> {
    const row = await this.client.getFirst('SELECT * FROM protocol_revisions WHERE id = ?', [id]);
    return row ? mapProtocolRevisionRow(row) : null;
  }

  async getEffectiveAt(protocolId: string, effectiveAt: string): Promise<ProtocolRevision | null> {
    const row = await this.client.getFirst(
      `SELECT * FROM protocol_revisions
       WHERE protocol_id = ?
         AND effective_from <= ?
         AND (effective_to IS NULL OR effective_to > ?)
       ORDER BY effective_from DESC, revision_number DESC
       LIMIT 1`,
      [protocolId, effectiveAt, effectiveAt]
    );

    return row ? mapProtocolRevisionRow(row) : null;
  }

  async listAll(): Promise<ProtocolRevision[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM protocol_revisions ORDER BY effective_from ASC, revision_number ASC'
    );
    return rows.map(mapProtocolRevisionRow);
  }

  async listByProtocolId(protocolId: string): Promise<ProtocolRevision[]> {
    const rows = await this.client.getAll(
      `SELECT * FROM protocol_revisions
       WHERE protocol_id = ?
       ORDER BY effective_from ASC, revision_number ASC`,
      [protocolId]
    );

    return rows.map(mapProtocolRevisionRow);
  }

  async update(input: UpdateProtocolRevisionInput): Promise<ProtocolRevision | null> {
    const parsed = updateProtocolRevisionInputSchema.parse(input);
    const existing = await this.getById(parsed.id);

    if (!existing) {
      return null;
    }

    const next: ProtocolRevision = {
      ...existing,
      revisionNumber: parsed.revisionNumber ?? existing.revisionNumber,
      previousRevisionId:
        parsed.previousRevisionId !== undefined
          ? parsed.previousRevisionId
          : existing.previousRevisionId,
      effectiveFrom: parsed.effectiveFrom ?? existing.effectiveFrom,
      effectiveTo: parsed.effectiveTo !== undefined ? parsed.effectiveTo : existing.effectiveTo,
      lifecycleState: parsed.lifecycleState ?? existing.lifecycleState,
      timezone: parsed.timezone ?? existing.timezone,
      timezoneStrategy: parsed.timezoneStrategy ?? existing.timezoneStrategy,
      defaultTimeOfDay:
        parsed.defaultTimeOfDay !== undefined
          ? parsed.defaultTimeOfDay
          : existing.defaultTimeOfDay,
      doseAmount: parsed.doseAmount !== undefined ? parsed.doseAmount : existing.doseAmount,
      doseUnit: parsed.doseUnit !== undefined ? parsed.doseUnit : existing.doseUnit,
      linkedVialId:
        parsed.linkedVialId !== undefined ? parsed.linkedVialId : existing.linkedVialId,
      missedDosePolicy: parsed.missedDosePolicy ?? existing.missedDosePolicy,
      notes: parsed.notes !== undefined ? parsed.notes : existing.notes,
      updatedAt: createIsoTimestamp(),
    };

    await this.client.run(
      `UPDATE protocol_revisions
         SET revision_number = ?, previous_revision_id = ?, effective_from = ?, effective_to = ?,
             lifecycle_state = ?, timezone = ?, timezone_strategy = ?, default_time_of_day = ?,
             dose_amount = ?, dose_unit = ?, linked_vial_id = ?, missed_dose_policy = ?,
             notes = ?, updated_at = ?
       WHERE id = ?`,
      [
        next.revisionNumber,
        next.previousRevisionId,
        next.effectiveFrom,
        next.effectiveTo,
        next.lifecycleState,
        next.timezone,
        next.timezoneStrategy,
        next.defaultTimeOfDay,
        next.doseAmount,
        next.doseUnit,
        next.linkedVialId,
        next.missedDosePolicy,
        next.notes,
        next.updatedAt,
        next.id,
      ]
    );

    return next;
  }
}
