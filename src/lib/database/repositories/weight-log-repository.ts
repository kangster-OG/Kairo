import type { DatabaseClient } from '@/src/lib/database/client';
import { mapWeightLogRow, toWeightLogRow } from '@/src/lib/database/mappers';
import {
  createWeightLogInputSchema,
  type CreateWeightLogInput,
  type WeightLog,
} from '@/src/lib/database/schemas';

export interface WeightLogRepository {
  create(input: CreateWeightLogInput): Promise<WeightLog>;
  delete(id: string): Promise<boolean>;
  listAll(): Promise<WeightLog[]>;
  listRecent(limit?: number): Promise<WeightLog[]>;
}

export class SqliteWeightLogRepository implements WeightLogRepository {
  constructor(private readonly client: DatabaseClient) {}

  async create(input: CreateWeightLogInput): Promise<WeightLog> {
    const row = toWeightLogRow(createWeightLogInputSchema.parse(input));

    await this.client.run(
      `INSERT INTO weight_logs (
        id, logged_at, value, unit, source, notes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.logged_at,
        row.value,
        row.unit,
        row.source,
        row.notes,
        row.created_at,
        row.updated_at,
      ]
    );

    return mapWeightLogRow(row);
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.client.run('DELETE FROM weight_logs WHERE id = ?', [id]);
    return result.changes > 0;
  }

  async listAll(): Promise<WeightLog[]> {
    const rows = await this.client.getAll('SELECT * FROM weight_logs ORDER BY logged_at DESC');
    return rows.map(mapWeightLogRow);
  }

  async listRecent(limit = 30): Promise<WeightLog[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM weight_logs ORDER BY logged_at DESC LIMIT ?',
      [limit]
    );
    return rows.map(mapWeightLogRow);
  }
}
