import type { DatabaseClient } from '@/src/lib/database/client';
import { createIsoTimestamp } from '@/src/lib/database/id';
import {
  mapProtocolAliasRow,
  toProtocolAliasRow,
} from '@/src/lib/database/mappers';
import {
  createProtocolAliasInputSchema,
  updateProtocolAliasInputSchema,
  type CreateProtocolAliasInput,
  type ProtocolAlias,
  type UpdateProtocolAliasInput,
} from '@/src/lib/database/schemas';

export interface ProtocolAliasRepository {
  getByProtocolId(protocolId: string): Promise<ProtocolAlias | null>;
  listAllActive(): Promise<ProtocolAlias[]>;
  upsert(input: CreateProtocolAliasInput): Promise<ProtocolAlias>;
  update(input: UpdateProtocolAliasInput): Promise<ProtocolAlias | null>;
}

export class SqliteProtocolAliasRepository implements ProtocolAliasRepository {
  constructor(private readonly client: DatabaseClient) {}

  async getByProtocolId(protocolId: string): Promise<ProtocolAlias | null> {
    const row = await this.client.getFirst(
      `SELECT * FROM protocol_aliases
       WHERE protocol_id = ? AND archived_at IS NULL
       LIMIT 1`,
      [protocolId]
    );
    return row ? mapProtocolAliasRow(row) : null;
  }

  async listAllActive(): Promise<ProtocolAlias[]> {
    const rows = await this.client.getAll(
      `SELECT * FROM protocol_aliases
       WHERE archived_at IS NULL
       ORDER BY updated_at DESC`
    );
    return rows.map(mapProtocolAliasRow);
  }

  async upsert(input: CreateProtocolAliasInput): Promise<ProtocolAlias> {
    const existing = await this.getByProtocolId(input.protocolId);

    if (existing) {
      const next = await this.update({
        aliasCompoundLabel: input.aliasCompoundLabel ?? null,
        aliasLabel: input.aliasLabel,
        archivedAt: input.archivedAt ?? null,
        id: existing.id,
      });

      if (!next) {
        throw new Error('Protocol alias update failed.');
      }

      return next;
    }

    const row = toProtocolAliasRow(createProtocolAliasInputSchema.parse(input));

    await this.client.run(
      `INSERT INTO protocol_aliases (
        id, protocol_id, alias_label, alias_compound_label, created_at, updated_at, archived_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.protocol_id,
        row.alias_label,
        row.alias_compound_label,
        row.created_at,
        row.updated_at,
        row.archived_at,
      ]
    );

    return mapProtocolAliasRow(row);
  }

  async update(input: UpdateProtocolAliasInput): Promise<ProtocolAlias | null> {
    const parsed = updateProtocolAliasInputSchema.parse(input);
    const existingRow = await this.client.getFirst('SELECT * FROM protocol_aliases WHERE id = ?', [
      parsed.id,
    ]);

    if (!existingRow) {
      return null;
    }

    const existing = mapProtocolAliasRow(existingRow);
    const next: ProtocolAlias = {
      ...existing,
      aliasLabel: parsed.aliasLabel ?? existing.aliasLabel,
      aliasCompoundLabel:
        parsed.aliasCompoundLabel !== undefined
          ? parsed.aliasCompoundLabel
          : existing.aliasCompoundLabel,
      archivedAt: parsed.archivedAt !== undefined ? parsed.archivedAt : existing.archivedAt,
      updatedAt: createIsoTimestamp(),
    };

    await this.client.run(
      `UPDATE protocol_aliases
       SET alias_label = ?, alias_compound_label = ?, archived_at = ?, updated_at = ?
       WHERE id = ?`,
      [
        next.aliasLabel,
        next.aliasCompoundLabel,
        next.archivedAt,
        next.updatedAt,
        next.id,
      ]
    );

    return next;
  }
}
