import type { DatabaseClient } from '@/src/lib/database/client';
import { createIsoTimestamp } from '@/src/lib/database/id';
import { mapVialRow, toVialRow } from '@/src/lib/database/mappers';
import {
  createVialInputSchema,
  updateVialInputSchema,
  type CreateVialInput,
  type UpdateVialInput,
  type Vial,
} from '@/src/lib/database/schemas';

export interface VialRepository {
  create(input: CreateVialInput): Promise<Vial>;
  delete(id: string): Promise<boolean>;
  getById(id: string): Promise<Vial | null>;
  listAll(): Promise<Vial[]>;
  listByProtocolId(protocolId: string): Promise<Vial[]>;
  update(input: UpdateVialInput): Promise<Vial | null>;
}

export class SqliteVialRepository implements VialRepository {
  constructor(private readonly client: DatabaseClient) {}

  async create(input: CreateVialInput): Promise<Vial> {
    const row = toVialRow(createVialInputSchema.parse(input));

    await this.client.run(
      `INSERT INTO vials (
        id, protocol_id, compound_id, label, starting_quantity, concentration_value, concentration_unit, volume_ml, remaining_quantity, low_stock_threshold, quantity_unit, opened_at, expires_at, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.protocol_id,
        row.compound_id,
        row.label,
        row.starting_quantity,
        row.concentration_value,
        row.concentration_unit,
        row.volume_ml,
        row.remaining_quantity,
        row.low_stock_threshold,
        row.quantity_unit,
        row.opened_at,
        row.expires_at,
        row.created_at,
        row.updated_at,
      ]
    );

    return mapVialRow(row);
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.client.run('DELETE FROM vials WHERE id = ?', [id]);
    return result.changes > 0;
  }

  async getById(id: string): Promise<Vial | null> {
    const row = await this.client.getFirst('SELECT * FROM vials WHERE id = ?', [id]);
    return row ? mapVialRow(row) : null;
  }

  async listAll(): Promise<Vial[]> {
    const rows = await this.client.getAll('SELECT * FROM vials ORDER BY created_at DESC');
    return rows.map(mapVialRow);
  }

  async listByProtocolId(protocolId: string): Promise<Vial[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM vials WHERE protocol_id = ? ORDER BY created_at DESC',
      [protocolId]
    );
    return rows.map(mapVialRow);
  }

  async update(input: UpdateVialInput): Promise<Vial | null> {
    const parsed = updateVialInputSchema.parse(input);
    const existing = await this.getById(parsed.id);

    if (!existing) {
      return null;
    }

    const next: Vial = {
      ...existing,
      protocolId: parsed.protocolId !== undefined ? parsed.protocolId : existing.protocolId,
      compoundId: parsed.compoundId !== undefined ? parsed.compoundId : existing.compoundId,
      label: parsed.label ?? existing.label,
      startingQuantity:
        parsed.startingQuantity !== undefined ? parsed.startingQuantity : existing.startingQuantity,
      concentrationValue:
        parsed.concentrationValue !== undefined
          ? parsed.concentrationValue
          : existing.concentrationValue,
      concentrationUnit:
        parsed.concentrationUnit !== undefined
          ? parsed.concentrationUnit
          : existing.concentrationUnit,
      volumeMl: parsed.volumeMl !== undefined ? parsed.volumeMl : existing.volumeMl,
      remainingQuantity: parsed.remainingQuantity ?? existing.remainingQuantity,
      lowStockThreshold:
        parsed.lowStockThreshold !== undefined ? parsed.lowStockThreshold : existing.lowStockThreshold,
      quantityUnit: parsed.quantityUnit ?? existing.quantityUnit,
      openedAt: parsed.openedAt !== undefined ? parsed.openedAt : existing.openedAt,
      expiresAt: parsed.expiresAt !== undefined ? parsed.expiresAt : existing.expiresAt,
      updatedAt: createIsoTimestamp(),
    };

    await this.client.run(
      `UPDATE vials
        SET protocol_id = ?, compound_id = ?, label = ?, starting_quantity = ?, concentration_value = ?, concentration_unit = ?, volume_ml = ?, remaining_quantity = ?, low_stock_threshold = ?, quantity_unit = ?, opened_at = ?, expires_at = ?, updated_at = ?
        WHERE id = ?`,
      [
        next.protocolId,
        next.compoundId,
        next.label,
        next.startingQuantity,
        next.concentrationValue,
        next.concentrationUnit,
        next.volumeMl,
        next.remainingQuantity,
        next.lowStockThreshold,
        next.quantityUnit,
        next.openedAt,
        next.expiresAt,
        next.updatedAt,
        next.id,
      ]
    );

    return next;
  }
}
