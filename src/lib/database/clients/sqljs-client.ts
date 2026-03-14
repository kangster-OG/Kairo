import initSqlJs from 'sql.js/dist/sql-asm.js';

import type {
  DatabaseClient,
  DatabaseParams,
  DatabaseRow,
  DatabaseRunResult,
} from '@/src/lib/database/client';

type SqlJsStatement = {
  free(): void;
  getAsObject(): Record<string, unknown>;
  step(): boolean;
};

type SqlJsDatabase = {
  close(): void;
  exec(sql: string): unknown;
  getRowsModified(): number;
  prepare(sql: string, params?: readonly (string | number | null)[]): SqlJsStatement;
  run(sql: string, params?: readonly (string | number | null)[]): void;
};

type SqlJsStatic = {
  Database: new () => SqlJsDatabase;
};

class SqlJsDatabaseClient implements DatabaseClient {
  constructor(private readonly database: SqlJsDatabase) {}

  async close(): Promise<void> {
    this.database.close();
  }

  async exec(sql: string): Promise<void> {
    this.database.exec(sql);
  }

  async getAll<T extends DatabaseRow>(
    sql: string,
    params: DatabaseParams = []
  ): Promise<T[]> {
    const statement = this.database.prepare(sql, params);
    const rows: T[] = [];

    try {
      while (statement.step()) {
        rows.push(statement.getAsObject() as T);
      }
    } finally {
      statement.free();
    }

    return rows;
  }

  async getFirst<T extends DatabaseRow>(
    sql: string,
    params: DatabaseParams = []
  ): Promise<T | null> {
    const rows = await this.getAll<T>(sql, params);
    return rows[0] ?? null;
  }

  async run(sql: string, params: DatabaseParams = []): Promise<DatabaseRunResult> {
    this.database.run(sql, params);

    const row = await this.getFirst<{ id: number }>(
      'SELECT CAST(last_insert_rowid() AS INTEGER) AS id'
    );

    return {
      changes: this.database.getRowsModified(),
      lastInsertRowId: row?.id ?? null,
    };
  }

  async withTransaction<T>(task: (client: DatabaseClient) => Promise<T>): Promise<T> {
    await this.exec('BEGIN IMMEDIATE TRANSACTION');

    try {
      const result = await task(this);
      await this.exec('COMMIT');
      return result;
    } catch (error) {
      await this.exec('ROLLBACK');
      throw error;
    }
  }
}

export async function createSqlJsDatabaseClient(): Promise<DatabaseClient> {
  const SQL = (await initSqlJs({})) as SqlJsStatic;
  const database = new SQL.Database();

  return new SqlJsDatabaseClient(database);
}
