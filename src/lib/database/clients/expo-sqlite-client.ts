import * as SQLite from 'expo-sqlite';

import type {
  DatabaseClient,
  DatabaseParams,
  DatabaseRow,
  DatabaseRunResult,
} from '@/src/lib/database/client';

class ExpoSQLiteDatabaseClient implements DatabaseClient {
  private transactionDepth = 0;
  private transactionQueue: Promise<void> = Promise.resolve();

  constructor(private readonly database: SQLite.SQLiteDatabase) {}

  async close(): Promise<void> {
    await this.database.closeAsync();
  }

  async exec(sql: string): Promise<void> {
    await this.database.execAsync(sql);
  }

  async getAll<T extends DatabaseRow>(
    sql: string,
    params: DatabaseParams = []
  ): Promise<T[]> {
    return this.database.getAllAsync<T>(sql, [...params]);
  }

  async getFirst<T extends DatabaseRow>(
    sql: string,
    params: DatabaseParams = []
  ): Promise<T | null> {
    return this.database.getFirstAsync<T>(sql, [...params]);
  }

  async run(sql: string, params: DatabaseParams = []): Promise<DatabaseRunResult> {
    const result = await this.database.runAsync(sql, [...params]);

    return {
      changes: result.changes,
      lastInsertRowId:
        typeof result.lastInsertRowId === 'number' ? result.lastInsertRowId : null,
    };
  }

  async withTransaction<T>(task: (client: DatabaseClient) => Promise<T>): Promise<T> {
    if (this.transactionDepth > 0) {
      return task(this);
    }

    const runTransaction = async () => {
      let result: T | undefined;
      this.transactionDepth += 1;

      try {
        await this.database.withTransactionAsync(async () => {
          result = await task(this);
        });
      } finally {
        this.transactionDepth = Math.max(0, this.transactionDepth - 1);
      }

      return result as T;
    };

    const queued = this.transactionQueue.then(runTransaction, runTransaction);
    this.transactionQueue = queued.then(
      () => undefined,
      () => undefined
    );

    return queued;
  }
}

export async function createExpoSQLiteDatabaseClient(
  databaseName = 'atlas.db'
): Promise<DatabaseClient> {
  const database = await SQLite.openDatabaseAsync(databaseName);

  return new ExpoSQLiteDatabaseClient(database);
}
