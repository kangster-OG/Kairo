import type { DatabaseClient } from '@/src/lib/database/client';
import { mapSymptomLogRow, toSymptomLogRow } from '@/src/lib/database/mappers';
import {
  createSymptomLogInputSchema,
  type CreateSymptomLogInput,
  type SymptomLog,
} from '@/src/lib/database/schemas';

export interface SymptomLogRepository {
  create(input: CreateSymptomLogInput): Promise<SymptomLog>;
  delete(id: string): Promise<boolean>;
  listAll(): Promise<SymptomLog[]>;
  listRecent(limit?: number): Promise<SymptomLog[]>;
}

export class SqliteSymptomLogRepository implements SymptomLogRepository {
  constructor(private readonly client: DatabaseClient) {}

  async create(input: CreateSymptomLogInput): Promise<SymptomLog> {
    const row = toSymptomLogRow(createSymptomLogInputSchema.parse(input));

    await this.client.run(
      `INSERT INTO symptom_logs (
        id, logged_at, symptom_key, severity, notes, source, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.logged_at,
        row.symptom_key,
        row.severity,
        row.notes,
        row.source,
        row.created_at,
        row.updated_at,
      ]
    );

    return mapSymptomLogRow(row);
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.client.run('DELETE FROM symptom_logs WHERE id = ?', [id]);
    return result.changes > 0;
  }

  async listAll(): Promise<SymptomLog[]> {
    const rows = await this.client.getAll('SELECT * FROM symptom_logs ORDER BY logged_at DESC');
    return rows.map(mapSymptomLogRow);
  }

  async listRecent(limit = 30): Promise<SymptomLog[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM symptom_logs ORDER BY logged_at DESC LIMIT ?',
      [limit]
    );
    return rows.map(mapSymptomLogRow);
  }
}
