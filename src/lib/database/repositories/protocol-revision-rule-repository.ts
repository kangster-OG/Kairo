import type { DatabaseClient } from '@/src/lib/database/client';
import { createIsoTimestamp } from '@/src/lib/database/id';
import {
  mapProtocolRevisionRuleRow,
  toProtocolRevisionRuleRow,
} from '@/src/lib/database/mappers';
import {
  createProtocolRevisionRuleInputSchema,
  updateProtocolRevisionRuleInputSchema,
  type CreateProtocolRevisionRuleInput,
  type ProtocolRevisionRule,
  type UpdateProtocolRevisionRuleInput,
} from '@/src/lib/database/schemas';

export interface ProtocolRevisionRuleRepository {
  create(input: CreateProtocolRevisionRuleInput): Promise<ProtocolRevisionRule>;
  deleteByRevisionId(revisionId: string): Promise<number>;
  listAll(): Promise<ProtocolRevisionRule[]>;
  listByRevisionId(revisionId: string): Promise<ProtocolRevisionRule[]>;
  replaceForRevision(
    revisionId: string,
    rules: CreateProtocolRevisionRuleInput[]
  ): Promise<ProtocolRevisionRule[]>;
  update(input: UpdateProtocolRevisionRuleInput): Promise<ProtocolRevisionRule | null>;
}

export class SqliteProtocolRevisionRuleRepository implements ProtocolRevisionRuleRepository {
  constructor(private readonly client: DatabaseClient) {}

  async create(input: CreateProtocolRevisionRuleInput): Promise<ProtocolRevisionRule> {
    const row = toProtocolRevisionRuleRow(createProtocolRevisionRuleInputSchema.parse(input));

    await this.client.run(
      `INSERT INTO protocol_revision_rules (
        id, revision_id, phase_type, phase_order, rule_type, interval_count, weekday, time_of_day,
        anchor_date, phase_start_day_offset, phase_length_days, dose_amount_override, dose_unit_override,
        created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.revision_id,
        row.phase_type,
        row.phase_order,
        row.rule_type,
        row.interval_count,
        row.weekday,
        row.time_of_day,
        row.anchor_date,
        row.phase_start_day_offset,
        row.phase_length_days,
        row.dose_amount_override,
        row.dose_unit_override,
        row.created_at,
        row.updated_at,
      ]
    );

    return mapProtocolRevisionRuleRow(row);
  }

  async deleteByRevisionId(revisionId: string): Promise<number> {
    const result = await this.client.run(
      'DELETE FROM protocol_revision_rules WHERE revision_id = ?',
      [revisionId]
    );
    return result.changes;
  }

  async listAll(): Promise<ProtocolRevisionRule[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM protocol_revision_rules ORDER BY phase_order ASC, created_at ASC'
    );
    return rows.map(mapProtocolRevisionRuleRow);
  }

  async listByRevisionId(revisionId: string): Promise<ProtocolRevisionRule[]> {
    const rows = await this.client.getAll(
      `SELECT * FROM protocol_revision_rules
       WHERE revision_id = ?
       ORDER BY phase_order ASC, created_at ASC`,
      [revisionId]
    );
    return rows.map(mapProtocolRevisionRuleRow);
  }

  async replaceForRevision(
    revisionId: string,
    rules: CreateProtocolRevisionRuleInput[]
  ): Promise<ProtocolRevisionRule[]> {
    return this.client.withTransaction(async (txn) => {
      const repository = new SqliteProtocolRevisionRuleRepository(txn);
      await repository.deleteByRevisionId(revisionId);

      const created: ProtocolRevisionRule[] = [];
      for (const rule of rules) {
        created.push(
          await repository.create({
            ...rule,
            revisionId,
          })
        );
      }

      return created;
    });
  }

  async update(input: UpdateProtocolRevisionRuleInput): Promise<ProtocolRevisionRule | null> {
    const parsed = updateProtocolRevisionRuleInputSchema.parse(input);
    const rows = await this.client.getAll('SELECT * FROM protocol_revision_rules WHERE id = ?', [parsed.id]);
    const existingRow = rows[0];

    if (!existingRow) {
      return null;
    }

    const existing = mapProtocolRevisionRuleRow(existingRow);
    const next: ProtocolRevisionRule = {
      ...existing,
      phaseType: parsed.phaseType ?? existing.phaseType,
      phaseOrder: parsed.phaseOrder ?? existing.phaseOrder,
      ruleType: parsed.ruleType ?? existing.ruleType,
      intervalCount: parsed.intervalCount ?? existing.intervalCount,
      weekday: parsed.weekday !== undefined ? parsed.weekday : existing.weekday,
      timeOfDay: parsed.timeOfDay !== undefined ? parsed.timeOfDay : existing.timeOfDay,
      anchorDate: parsed.anchorDate !== undefined ? parsed.anchorDate : existing.anchorDate,
      phaseStartDayOffset:
        parsed.phaseStartDayOffset ?? existing.phaseStartDayOffset,
      phaseLengthDays:
        parsed.phaseLengthDays !== undefined ? parsed.phaseLengthDays : existing.phaseLengthDays,
      doseAmountOverride:
        parsed.doseAmountOverride !== undefined
          ? parsed.doseAmountOverride
          : existing.doseAmountOverride,
      doseUnitOverride:
        parsed.doseUnitOverride !== undefined
          ? parsed.doseUnitOverride
          : existing.doseUnitOverride,
      updatedAt: createIsoTimestamp(),
    };

    await this.client.run(
      `UPDATE protocol_revision_rules
         SET phase_type = ?, phase_order = ?, rule_type = ?, interval_count = ?, weekday = ?,
             time_of_day = ?, anchor_date = ?, phase_start_day_offset = ?, phase_length_days = ?,
             dose_amount_override = ?, dose_unit_override = ?, updated_at = ?
       WHERE id = ?`,
      [
        next.phaseType,
        next.phaseOrder,
        next.ruleType,
        next.intervalCount,
        next.weekday,
        next.timeOfDay,
        next.anchorDate,
        next.phaseStartDayOffset,
        next.phaseLengthDays,
        next.doseAmountOverride,
        next.doseUnitOverride,
        next.updatedAt,
        next.id,
      ]
    );

    return next;
  }
}
