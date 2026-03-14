export type DatabaseValue = string | number | null;
export type DatabaseParams = readonly DatabaseValue[];
export type DatabaseRow = Record<string, unknown>;

export type DatabaseRunResult = {
  changes: number;
  lastInsertRowId: number | null;
};

export interface DatabaseClient {
  close(): Promise<void>;
  exec(sql: string): Promise<void>;
  getAll<T extends DatabaseRow>(sql: string, params?: DatabaseParams): Promise<T[]>;
  getFirst<T extends DatabaseRow>(sql: string, params?: DatabaseParams): Promise<T | null>;
  run(sql: string, params?: DatabaseParams): Promise<DatabaseRunResult>;
  withTransaction<T>(task: (client: DatabaseClient) => Promise<T>): Promise<T>;
}
