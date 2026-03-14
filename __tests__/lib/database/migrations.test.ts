import { createSqlJsDatabaseClient } from '@/src/lib/database/clients/sqljs-client';
import { atlasMigrations, runMigrations } from '@/src/lib/database/migrations';

describe('database migrations', () => {
  it('creates the expected tables on a fresh database and records the migration', async () => {
    const client = await createSqlJsDatabaseClient();

    await runMigrations(client);

    const tables = await client.getAll<{ name: string }>(
      `SELECT name FROM sqlite_master
       WHERE type = 'table'
       ORDER BY name ASC`
    );

    expect(tables.map((table) => table.name)).toEqual(
      expect.arrayContaining([
        'atlas_migrations',
        'calculator_profiles',
        'compounds',
        'custom_metrics',
        'health_connections',
        'log_events',
        'metric_value_logs',
        'privacy_profile',
        'protocol_change_audit_events',
        'protocol_aliases',
        'protocol_revision_rules',
        'protocol_revisions',
        'protocol_rules',
        'protocols',
        'reminder_preferences',
        'reminders',
        'sensitive_action_audit_events',
        'sites',
        'symptom_logs',
        'vials',
        'weight_logs',
      ])
    );

    const applied = await client.getAll<{ version: number; name: string }>(
      'SELECT version, name FROM atlas_migrations ORDER BY version ASC'
    );

    expect(applied).toEqual(
      atlasMigrations.map((migration) => ({
        version: migration.version,
        name: migration.name,
      }))
    );

    await client.close();
  });

  it('is idempotent when run more than once', async () => {
    const client = await createSqlJsDatabaseClient();

    await runMigrations(client);
    await runMigrations(client);

    const count = await client.getFirst<{ count: number }>(
      'SELECT COUNT(*) AS count FROM atlas_migrations'
    );

    expect(count?.count).toBe(atlasMigrations.length);

    await client.close();
  });
});
