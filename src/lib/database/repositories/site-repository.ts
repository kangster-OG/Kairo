import type { DatabaseClient } from '@/src/lib/database/client';
import { createIsoTimestamp } from '@/src/lib/database/id';
import { mapSiteRow, toSiteRow } from '@/src/lib/database/mappers';
import {
  createSiteInputSchema,
  updateSiteInputSchema,
  type CreateSiteInput,
  type Site,
  type UpdateSiteInput,
} from '@/src/lib/database/schemas';

export interface SiteRepository {
  create(input: CreateSiteInput): Promise<Site>;
  delete(id: string): Promise<boolean>;
  getById(id: string): Promise<Site | null>;
  listAll(): Promise<Site[]>;
  listAvailable(): Promise<Site[]>;
  update(input: UpdateSiteInput): Promise<Site | null>;
}

export class SqliteSiteRepository implements SiteRepository {
  constructor(private readonly client: DatabaseClient) {}

  async create(input: CreateSiteInput): Promise<Site> {
    const row = toSiteRow(createSiteInputSchema.parse(input));

    await this.client.run(
      `INSERT INTO sites (
        id, name, body_area, notes, created_at, updated_at, archived_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.name,
        row.body_area,
        row.notes,
        row.created_at,
        row.updated_at,
        row.archived_at,
      ]
    );

    return mapSiteRow(row);
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.client.run('DELETE FROM sites WHERE id = ?', [id]);
    return result.changes > 0;
  }

  async getById(id: string): Promise<Site | null> {
    const row = await this.client.getFirst('SELECT * FROM sites WHERE id = ?', [id]);
    return row ? mapSiteRow(row) : null;
  }

  async listAll(): Promise<Site[]> {
    const rows = await this.client.getAll('SELECT * FROM sites ORDER BY name ASC');
    return rows.map(mapSiteRow);
  }

  async listAvailable(): Promise<Site[]> {
    const rows = await this.client.getAll(
      'SELECT * FROM sites WHERE archived_at IS NULL ORDER BY name ASC'
    );
    return rows.map(mapSiteRow);
  }

  async update(input: UpdateSiteInput): Promise<Site | null> {
    const parsed = updateSiteInputSchema.parse(input);
    const existing = await this.getById(parsed.id);

    if (!existing) {
      return null;
    }

    const next: Site = {
      ...existing,
      name: parsed.name ?? existing.name,
      bodyArea: parsed.bodyArea !== undefined ? parsed.bodyArea : existing.bodyArea,
      notes: parsed.notes !== undefined ? parsed.notes : existing.notes,
      archivedAt: parsed.archivedAt !== undefined ? parsed.archivedAt : existing.archivedAt,
      updatedAt: createIsoTimestamp(),
    };

    await this.client.run(
      `UPDATE sites
        SET name = ?, body_area = ?, notes = ?, updated_at = ?, archived_at = ?
        WHERE id = ?`,
      [next.name, next.bodyArea, next.notes, next.updatedAt, next.archivedAt, next.id]
    );

    return next;
  }
}
