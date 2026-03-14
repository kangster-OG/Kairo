import type { DatabaseClient } from '@/src/lib/database/client';
import { createIsoTimestamp } from '@/src/lib/database/id';
import { mapCustomMetricRow, toCustomMetricRow } from '@/src/lib/database/mappers';
import {
  createCustomMetricInputSchema,
  updateCustomMetricInputSchema,
  type CreateCustomMetricInput,
  type CustomMetric,
  type UpdateCustomMetricInput,
} from '@/src/lib/database/schemas';

export interface CustomMetricRepository {
  create(input: CreateCustomMetricInput): Promise<CustomMetric>;
  delete(id: string): Promise<boolean>;
  getById(id: string): Promise<CustomMetric | null>;
  listAll(): Promise<CustomMetric[]>;
  listByProtocolId(protocolId: string): Promise<CustomMetric[]>;
  update(input: UpdateCustomMetricInput): Promise<CustomMetric | null>;
}

export class SqliteCustomMetricRepository implements CustomMetricRepository {
  constructor(private readonly client: DatabaseClient) {}

  async create(input: CreateCustomMetricInput): Promise<CustomMetric> {
    const row = toCustomMetricRow(createCustomMetricInputSchema.parse(input));

    await this.client.run(
      `INSERT INTO custom_metrics (
        id, protocol_id, metric_key, label, value_type, unit, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.protocol_id,
        row.metric_key,
        row.label,
        row.value_type,
        row.unit,
        row.created_at,
        row.updated_at,
      ]
    );

    return mapCustomMetricRow(row);
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.client.run('DELETE FROM custom_metrics WHERE id = ?', [id]);
    return result.changes > 0;
  }

  async getById(id: string): Promise<CustomMetric | null> {
    const row = await this.client.getFirst('SELECT * FROM custom_metrics WHERE id = ?', [id]);
    return row ? mapCustomMetricRow(row) : null;
  }

  async listAll(): Promise<CustomMetric[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM custom_metrics ORDER BY created_at DESC'
    );
    return rows.map(mapCustomMetricRow);
  }

  async listByProtocolId(protocolId: string): Promise<CustomMetric[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM custom_metrics WHERE protocol_id = ? ORDER BY created_at DESC',
      [protocolId]
    );
    return rows.map(mapCustomMetricRow);
  }

  async update(input: UpdateCustomMetricInput): Promise<CustomMetric | null> {
    const parsed = updateCustomMetricInputSchema.parse(input);
    const existing = await this.getById(parsed.id);

    if (!existing) {
      return null;
    }

    const next: CustomMetric = {
      ...existing,
      protocolId: parsed.protocolId !== undefined ? parsed.protocolId : existing.protocolId,
      metricKey: parsed.metricKey ?? existing.metricKey,
      label: parsed.label ?? existing.label,
      valueType: parsed.valueType ?? existing.valueType,
      unit: parsed.unit !== undefined ? parsed.unit : existing.unit,
      updatedAt: createIsoTimestamp(),
    };

    await this.client.run(
      `UPDATE custom_metrics
        SET protocol_id = ?, metric_key = ?, label = ?, value_type = ?, unit = ?, updated_at = ?
        WHERE id = ?`,
      [
        next.protocolId,
        next.metricKey,
        next.label,
        next.valueType,
        next.unit,
        next.updatedAt,
        next.id,
      ]
    );

    return next;
  }
}
