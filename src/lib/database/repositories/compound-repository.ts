import type { DatabaseClient } from '@/src/lib/database/client';
import { createIsoTimestamp } from '@/src/lib/database/id';
import { mapCompoundRow, toCompoundRow, toSqliteBooleanValue } from '@/src/lib/database/mappers';
import {
  compoundTypeSchema,
  createCompoundInputSchema,
  updateCompoundInputSchema,
  type Compound,
  type CompoundType,
  type CreateCompoundInput,
  type UpdateCompoundInput,
} from '@/src/lib/database/schemas';

export interface CompoundRepository {
  create(input: CreateCompoundInput): Promise<Compound>;
  delete(id: string): Promise<boolean>;
  getById(id: string): Promise<Compound | null>;
  getBySlug(slug: string): Promise<Compound | null>;
  listAll(): Promise<Compound[]>;
  listByType(type: CompoundType): Promise<Compound[]>;
  update(input: UpdateCompoundInput): Promise<Compound | null>;
}

export class SqliteCompoundRepository implements CompoundRepository {
  constructor(private readonly client: DatabaseClient) {}

  async create(input: CreateCompoundInput): Promise<Compound> {
    const row = toCompoundRow(createCompoundInputSchema.parse(input));

    await this.client.run(
      `INSERT INTO compounds (
        id, slug, display_name, compound_type, is_user_defined, notes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        row.id,
        row.slug,
        row.display_name,
        row.compound_type,
        row.is_user_defined,
        row.notes,
        row.created_at,
        row.updated_at,
      ]
    );

    return mapCompoundRow(row);
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.client.run('DELETE FROM compounds WHERE id = ?', [id]);
    return result.changes > 0;
  }

  async getById(id: string): Promise<Compound | null> {
    const row = await this.client.getFirst('SELECT * FROM compounds WHERE id = ?', [id]);
    return row ? mapCompoundRow(row) : null;
  }

  async getBySlug(slug: string): Promise<Compound | null> {
    const row = await this.client.getFirst('SELECT * FROM compounds WHERE slug = ?', [slug]);
    return row ? mapCompoundRow(row) : null;
  }

  async listAll(): Promise<Compound[]> {
    const rows = await this.client.getAll('SELECT * FROM compounds ORDER BY display_name ASC');
    return rows.map(mapCompoundRow);
  }

  async listByType(type: CompoundType): Promise<Compound[]> {
    const parsedType = compoundTypeSchema.parse(type);
    const rows = await this.client.getAll(
      'SELECT * FROM compounds WHERE compound_type = ? ORDER BY display_name ASC',
      [parsedType]
    );

    return rows.map(mapCompoundRow);
  }

  async update(input: UpdateCompoundInput): Promise<Compound | null> {
    const parsed = updateCompoundInputSchema.parse(input);
    const existing = await this.getById(parsed.id);

    if (!existing) {
      return null;
    }

    const next: Compound = {
      ...existing,
      slug: parsed.slug ?? existing.slug,
      displayName: parsed.displayName ?? existing.displayName,
      compoundType: parsed.compoundType ?? existing.compoundType,
      isUserDefined: parsed.isUserDefined ?? existing.isUserDefined,
      notes: parsed.notes !== undefined ? parsed.notes : existing.notes,
      updatedAt: createIsoTimestamp(),
    };

    await this.client.run(
      `UPDATE compounds
        SET slug = ?, display_name = ?, compound_type = ?, is_user_defined = ?, notes = ?, updated_at = ?
        WHERE id = ?`,
      [
        next.slug,
        next.displayName,
        next.compoundType,
        toSqliteBooleanValue(next.isUserDefined),
        next.notes,
        next.updatedAt,
        next.id,
      ]
    );

    return next;
  }
}
