declare module 'sql.js/dist/sql-asm.js' {
  export type SqlJsBindValue = string | number | null;

  export interface SqlJsStatement {
    free(): void;
    getAsObject(): Record<string, unknown>;
    step(): boolean;
  }

  export interface SqlJsDatabase {
    close(): void;
    exec(sql: string): unknown;
    getRowsModified(): number;
    prepare(sql: string, params?: readonly SqlJsBindValue[]): SqlJsStatement;
    run(sql: string, params?: readonly SqlJsBindValue[]): void;
  }

  export interface SqlJsStatic {
    Database: new () => SqlJsDatabase;
  }

  export default function initSqlJs(
    config?: Record<string, unknown>
  ): Promise<SqlJsStatic>;
}
