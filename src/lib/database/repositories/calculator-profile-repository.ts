import type { DatabaseClient } from '@/src/lib/database/client';
import { createIsoTimestamp } from '@/src/lib/database/id';
import { mapCalculatorProfileRow, toCalculatorProfileRow } from '@/src/lib/database/mappers';
import {
  createCalculatorProfileInputSchema,
  updateCalculatorProfileInputSchema,
  type CalculatorProfile,
  type CreateCalculatorProfileInput,
  type UpdateCalculatorProfileInput,
} from '@/src/lib/database/schemas';

export interface CalculatorProfileRepository {
  create(input: CreateCalculatorProfileInput): Promise<CalculatorProfile>;
  delete(id: string): Promise<boolean>;
  getById(id: string): Promise<CalculatorProfile | null>;
  listAll(): Promise<CalculatorProfile[]>;
  update(input: UpdateCalculatorProfileInput): Promise<CalculatorProfile | null>;
}

export class SqliteCalculatorProfileRepository implements CalculatorProfileRepository {
  constructor(private readonly client: DatabaseClient) {}

  async create(input: CreateCalculatorProfileInput): Promise<CalculatorProfile> {
    const row = toCalculatorProfileRow(createCalculatorProfileInputSchema.parse(input));

    await this.client.run(
      `INSERT INTO calculator_profiles (
        id, label, powder_amount, powder_unit, diluent_volume, diluent_unit, draw_volume, draw_unit, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.label,
        row.powder_amount,
        row.powder_unit,
        row.diluent_volume,
        row.diluent_unit,
        row.draw_volume,
        row.draw_unit,
        row.created_at,
        row.updated_at,
      ]
    );

    return mapCalculatorProfileRow(row);
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.client.run('DELETE FROM calculator_profiles WHERE id = ?', [id]);
    return result.changes > 0;
  }

  async getById(id: string): Promise<CalculatorProfile | null> {
    const row = await this.client.getFirst('SELECT * FROM calculator_profiles WHERE id = ?', [id]);
    return row ? mapCalculatorProfileRow(row) : null;
  }

  async listAll(): Promise<CalculatorProfile[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM calculator_profiles ORDER BY updated_at DESC, created_at DESC'
    );
    return rows.map(mapCalculatorProfileRow);
  }

  async update(input: UpdateCalculatorProfileInput): Promise<CalculatorProfile | null> {
    const parsed = updateCalculatorProfileInputSchema.parse(input);
    const existing = await this.getById(parsed.id);

    if (!existing) {
      return null;
    }

    const next: CalculatorProfile = {
      ...existing,
      label: parsed.label ?? existing.label,
      powderAmount: parsed.powderAmount ?? existing.powderAmount,
      powderUnit: parsed.powderUnit ?? existing.powderUnit,
      diluentVolume: parsed.diluentVolume ?? existing.diluentVolume,
      diluentUnit: parsed.diluentUnit ?? existing.diluentUnit,
      drawVolume: parsed.drawVolume ?? existing.drawVolume,
      drawUnit: parsed.drawUnit ?? existing.drawUnit,
      updatedAt: createIsoTimestamp(),
    };

    await this.client.run(
      `UPDATE calculator_profiles
       SET label = ?, powder_amount = ?, powder_unit = ?, diluent_volume = ?, diluent_unit = ?, draw_volume = ?, draw_unit = ?, updated_at = ?
       WHERE id = ?`,
      [
        next.label,
        next.powderAmount,
        next.powderUnit,
        next.diluentVolume,
        next.diluentUnit,
        next.drawVolume,
        next.drawUnit,
        next.updatedAt,
        next.id,
      ]
    );

    return next;
  }
}
