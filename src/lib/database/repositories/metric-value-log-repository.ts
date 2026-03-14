import type { DatabaseClient } from '@/src/lib/database/client';
import { mapMetricValueLogRow, toMetricValueLogRow } from '@/src/lib/database/mappers';
import {
  createMetricValueLogInputSchema,
  type CreateMetricValueLogInput,
  type MetricValueLog,
} from '@/src/lib/database/schemas';

export interface MetricValueLogRepository {
  create(input: CreateMetricValueLogInput): Promise<MetricValueLog>;
  delete(id: string): Promise<boolean>;
  listAll(): Promise<MetricValueLog[]>;
  listByMetricId(metricId: string): Promise<MetricValueLog[]>;
  listRecent(limit?: number): Promise<MetricValueLog[]>;
}

export class SqliteMetricValueLogRepository implements MetricValueLogRepository {
  constructor(private readonly client: DatabaseClient) {}

  async create(input: CreateMetricValueLogInput): Promise<MetricValueLog> {
    const row = toMetricValueLogRow(createMetricValueLogInputSchema.parse(input));

    await this.client.run(
      `INSERT INTO metric_value_logs (
        id, metric_id, protocol_id, logged_at, number_value, text_value, boolean_value, source, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.metric_id,
        row.protocol_id,
        row.logged_at,
        row.number_value,
        row.text_value,
        row.boolean_value,
        row.source,
        row.created_at,
        row.updated_at,
      ]
    );

    return mapMetricValueLogRow(row);
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.client.run('DELETE FROM metric_value_logs WHERE id = ?', [id]);
    return result.changes > 0;
  }

  async listAll(): Promise<MetricValueLog[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM metric_value_logs ORDER BY logged_at DESC'
    );
    return rows.map(mapMetricValueLogRow);
  }

  async listByMetricId(metricId: string): Promise<MetricValueLog[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM metric_value_logs WHERE metric_id = ? ORDER BY logged_at DESC',
      [metricId]
    );
    return rows.map(mapMetricValueLogRow);
  }

  async listRecent(limit = 30): Promise<MetricValueLog[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM metric_value_logs ORDER BY logged_at DESC LIMIT ?',
      [limit]
    );
    return rows.map(mapMetricValueLogRow);
  }
}
