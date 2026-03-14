import type { DatabaseClient } from '@/src/lib/database/client';
import { createIsoTimestamp } from '@/src/lib/database/id';
import {
  mapProtocolRuleRow,
  toProtocolRuleRow,
  toSqliteBooleanValue,
} from '@/src/lib/database/mappers';
import {
  createProtocolRuleInputSchema,
  updateProtocolRuleInputSchema,
  type CreateProtocolRuleInput,
  type ProtocolRule,
  type UpdateProtocolRuleInput,
} from '@/src/lib/database/schemas';

export interface ProtocolRuleRepository {
  create(input: CreateProtocolRuleInput): Promise<ProtocolRule>;
  delete(id: string): Promise<boolean>;
  getById(id: string): Promise<ProtocolRule | null>;
  listAll(): Promise<ProtocolRule[]>;
  listByProtocolId(protocolId: string): Promise<ProtocolRule[]>;
  replaceForProtocol(
    protocolId: string,
    rules: CreateProtocolRuleInput[]
  ): Promise<ProtocolRule[]>;
  update(input: UpdateProtocolRuleInput): Promise<ProtocolRule | null>;
}

export class SqliteProtocolRuleRepository implements ProtocolRuleRepository {
  constructor(private readonly client: DatabaseClient) {}

  async create(input: CreateProtocolRuleInput): Promise<ProtocolRule> {
    const row = toProtocolRuleRow(createProtocolRuleInputSchema.parse(input));

    await this.client.run(
      `INSERT INTO protocol_rules (
        id, protocol_id, rule_type, interval_count, weekday, time_of_day, anchor_date, is_active, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.protocol_id,
        row.rule_type,
        row.interval_count,
        row.weekday,
        row.time_of_day,
        row.anchor_date,
        row.is_active,
        row.created_at,
        row.updated_at,
      ]
    );

    return mapProtocolRuleRow(row);
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.client.run('DELETE FROM protocol_rules WHERE id = ?', [id]);
    return result.changes > 0;
  }

  async getById(id: string): Promise<ProtocolRule | null> {
    const row = await this.client.getFirst('SELECT * FROM protocol_rules WHERE id = ?', [id]);
    return row ? mapProtocolRuleRow(row) : null;
  }

  async listAll(): Promise<ProtocolRule[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM protocol_rules ORDER BY created_at ASC'
    );
    return rows.map(mapProtocolRuleRow);
  }

  async listByProtocolId(protocolId: string): Promise<ProtocolRule[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM protocol_rules WHERE protocol_id = ? ORDER BY created_at ASC',
      [protocolId]
    );
    return rows.map(mapProtocolRuleRow);
  }

  async replaceForProtocol(
    protocolId: string,
    rules: CreateProtocolRuleInput[]
  ): Promise<ProtocolRule[]> {
    return this.client.withTransaction(async (txn) => {
      const repository = new SqliteProtocolRuleRepository(txn);
      await txn.run('DELETE FROM protocol_rules WHERE protocol_id = ?', [protocolId]);

      const created: ProtocolRule[] = [];
      for (const rule of rules) {
        created.push(
          await repository.create({
            ...rule,
            protocolId,
          })
        );
      }

      return created;
    });
  }

  async update(input: UpdateProtocolRuleInput): Promise<ProtocolRule | null> {
    const parsed = updateProtocolRuleInputSchema.parse(input);
    const existing = await this.getById(parsed.id);

    if (!existing) {
      return null;
    }

    const next: ProtocolRule = {
      ...existing,
      protocolId: parsed.protocolId ?? existing.protocolId,
      ruleType: parsed.ruleType ?? existing.ruleType,
      intervalCount: parsed.intervalCount ?? existing.intervalCount,
      weekday: parsed.weekday !== undefined ? parsed.weekday : existing.weekday,
      timeOfDay: parsed.timeOfDay !== undefined ? parsed.timeOfDay : existing.timeOfDay,
      anchorDate: parsed.anchorDate !== undefined ? parsed.anchorDate : existing.anchorDate,
      isActive: parsed.isActive ?? existing.isActive,
      updatedAt: createIsoTimestamp(),
    };

    await this.client.run(
      `UPDATE protocol_rules
        SET protocol_id = ?, rule_type = ?, interval_count = ?, weekday = ?, time_of_day = ?, anchor_date = ?, is_active = ?, updated_at = ?
        WHERE id = ?`,
      [
        next.protocolId,
        next.ruleType,
        next.intervalCount,
        next.weekday,
        next.timeOfDay,
        next.anchorDate,
        toSqliteBooleanValue(next.isActive),
        next.updatedAt,
        next.id,
      ]
    );

    return next;
  }
}
