import type { DatabaseClient } from '@/src/lib/database/client';

export type Migration = {
  name: string;
  statements: string[];
  version: number;
};

export const atlasMigrations: Migration[] = [
  {
    version: 1,
    name: 'create_core_tables',
    statements: [
      `CREATE TABLE IF NOT EXISTS atlas_migrations (
        version INTEGER PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        applied_at TEXT NOT NULL
      )`,
      `CREATE TABLE IF NOT EXISTS compounds (
        id TEXT PRIMARY KEY NOT NULL,
        slug TEXT NOT NULL UNIQUE,
        display_name TEXT NOT NULL,
        compound_type TEXT NOT NULL,
        is_user_defined INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )`,
      `CREATE TABLE IF NOT EXISTS protocols (
        id TEXT PRIMARY KEY NOT NULL,
        compound_id TEXT,
        name TEXT NOT NULL,
        kind TEXT NOT NULL,
        status TEXT NOT NULL,
        timezone TEXT NOT NULL,
        start_date TEXT NOT NULL,
        default_time_of_day TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (compound_id) REFERENCES compounds(id) ON DELETE SET NULL
      )`,
      `CREATE TABLE IF NOT EXISTS protocol_rules (
        id TEXT PRIMARY KEY NOT NULL,
        protocol_id TEXT NOT NULL,
        rule_type TEXT NOT NULL,
        interval_count INTEGER NOT NULL,
        weekday INTEGER,
        time_of_day TEXT,
        anchor_date TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (protocol_id) REFERENCES protocols(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS vials (
        id TEXT PRIMARY KEY NOT NULL,
        protocol_id TEXT,
        compound_id TEXT,
        label TEXT NOT NULL,
        concentration_value REAL,
        concentration_unit TEXT,
        volume_ml REAL,
        remaining_quantity REAL NOT NULL,
        quantity_unit TEXT NOT NULL,
        opened_at TEXT,
        expires_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (protocol_id) REFERENCES protocols(id) ON DELETE SET NULL,
        FOREIGN KEY (compound_id) REFERENCES compounds(id) ON DELETE SET NULL
      )`,
      `CREATE TABLE IF NOT EXISTS sites (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        body_area TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        archived_at TEXT
      )`,
      `CREATE TABLE IF NOT EXISTS log_events (
        id TEXT PRIMARY KEY NOT NULL,
        protocol_id TEXT NOT NULL,
        vial_id TEXT,
        site_id TEXT,
        occurrence_id TEXT,
        event_type TEXT NOT NULL,
        effective_at TEXT NOT NULL,
        logged_at TEXT NOT NULL,
        quantity REAL,
        quantity_unit TEXT,
        notes TEXT,
        source TEXT NOT NULL,
        FOREIGN KEY (protocol_id) REFERENCES protocols(id) ON DELETE CASCADE,
        FOREIGN KEY (vial_id) REFERENCES vials(id) ON DELETE SET NULL,
        FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE SET NULL
      )`,
      `CREATE TABLE IF NOT EXISTS reminders (
        id TEXT PRIMARY KEY NOT NULL,
        protocol_id TEXT NOT NULL,
        offset_minutes INTEGER NOT NULL DEFAULT 0,
        channel TEXT NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        discreet_copy_enabled INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (protocol_id) REFERENCES protocols(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS custom_metrics (
        id TEXT PRIMARY KEY NOT NULL,
        protocol_id TEXT,
        metric_key TEXT NOT NULL,
        label TEXT NOT NULL,
        value_type TEXT NOT NULL,
        unit TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (protocol_id) REFERENCES protocols(id) ON DELETE SET NULL
      )`,
      `CREATE INDEX IF NOT EXISTS idx_protocols_status ON protocols(status)`,
      `CREATE INDEX IF NOT EXISTS idx_protocol_rules_protocol_id ON protocol_rules(protocol_id)`,
      `CREATE INDEX IF NOT EXISTS idx_vials_protocol_id ON vials(protocol_id)`,
      `CREATE INDEX IF NOT EXISTS idx_log_events_protocol_id ON log_events(protocol_id)`,
      `CREATE INDEX IF NOT EXISTS idx_log_events_effective_at ON log_events(effective_at DESC)`,
      `CREATE INDEX IF NOT EXISTS idx_reminders_protocol_id ON reminders(protocol_id)`,
      `CREATE INDEX IF NOT EXISTS idx_custom_metrics_protocol_id ON custom_metrics(protocol_id)`,
    ],
  },
  {
    version: 2,
    name: 'add_protocol_dose_fields',
    statements: [
      `ALTER TABLE protocols ADD COLUMN dose_amount REAL`,
      `ALTER TABLE protocols ADD COLUMN dose_unit TEXT`,
    ],
  },
  {
    version: 3,
    name: 'add_reminder_preferences_and_schedule_fields',
    statements: [
      `CREATE TABLE IF NOT EXISTS reminder_preferences (
        id TEXT PRIMARY KEY NOT NULL,
        reminders_enabled INTEGER NOT NULL DEFAULT 1,
        privacy_mode TEXT NOT NULL DEFAULT 'full_detail',
        lead_time_minutes INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )`,
      `INSERT OR IGNORE INTO reminder_preferences (
        id, reminders_enabled, privacy_mode, lead_time_minutes, created_at, updated_at
      ) VALUES (
        'default', 1, 'full_detail', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      )`,
      `ALTER TABLE reminders ADD COLUMN occurrence_id TEXT`,
      `ALTER TABLE reminders ADD COLUMN privacy_mode TEXT NOT NULL DEFAULT 'full_detail'`,
      `ALTER TABLE reminders ADD COLUMN scheduled_for TEXT`,
      `ALTER TABLE reminders ADD COLUMN notification_id TEXT`,
      `ALTER TABLE reminders ADD COLUMN title TEXT NOT NULL DEFAULT ''`,
      `ALTER TABLE reminders ADD COLUMN body TEXT NOT NULL DEFAULT ''`,
      `ALTER TABLE reminders ADD COLUMN status TEXT NOT NULL DEFAULT 'scheduled'`,
      `CREATE INDEX IF NOT EXISTS idx_reminders_occurrence_id ON reminders(occurrence_id)`,
      `CREATE INDEX IF NOT EXISTS idx_reminders_status ON reminders(status)`,
    ],
  },
  {
    version: 4,
    name: 'add_inventory_and_calculator_fields',
    statements: [
      `ALTER TABLE protocols ADD COLUMN linked_vial_id TEXT`,
      `ALTER TABLE protocols ADD COLUMN site_tracking_enabled INTEGER NOT NULL DEFAULT 0`,
      `ALTER TABLE protocols ADD COLUMN site_rotation_enabled INTEGER NOT NULL DEFAULT 0`,
      `ALTER TABLE vials ADD COLUMN starting_quantity REAL NOT NULL DEFAULT 0`,
      `ALTER TABLE vials ADD COLUMN low_stock_threshold REAL`,
      `UPDATE vials SET starting_quantity = remaining_quantity WHERE starting_quantity = 0`,
      `CREATE TABLE IF NOT EXISTS calculator_profiles (
        id TEXT PRIMARY KEY NOT NULL,
        label TEXT NOT NULL,
        powder_amount REAL NOT NULL,
        powder_unit TEXT NOT NULL,
        diluent_volume REAL NOT NULL,
        diluent_unit TEXT NOT NULL,
        draw_volume REAL NOT NULL,
        draw_unit TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )`,
      `CREATE INDEX IF NOT EXISTS idx_protocols_linked_vial_id ON protocols(linked_vial_id)`,
      `CREATE INDEX IF NOT EXISTS idx_calculator_profiles_label ON calculator_profiles(label)`,
    ],
  },
  {
    version: 5,
    name: 'add_insight_logs_and_health_connections',
    statements: [
      `CREATE TABLE IF NOT EXISTS weight_logs (
        id TEXT PRIMARY KEY NOT NULL,
        logged_at TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        source TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )`,
      `CREATE TABLE IF NOT EXISTS symptom_logs (
        id TEXT PRIMARY KEY NOT NULL,
        logged_at TEXT NOT NULL,
        symptom_key TEXT NOT NULL,
        severity INTEGER NOT NULL,
        notes TEXT,
        source TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )`,
      `CREATE TABLE IF NOT EXISTS metric_value_logs (
        id TEXT PRIMARY KEY NOT NULL,
        metric_id TEXT NOT NULL,
        protocol_id TEXT,
        logged_at TEXT NOT NULL,
        number_value REAL,
        text_value TEXT,
        boolean_value INTEGER,
        source TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (metric_id) REFERENCES custom_metrics(id) ON DELETE CASCADE,
        FOREIGN KEY (protocol_id) REFERENCES protocols(id) ON DELETE SET NULL
      )`,
      `CREATE TABLE IF NOT EXISTS health_connections (
        provider_key TEXT PRIMARY KEY NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 0,
        connected INTEGER NOT NULL DEFAULT 0,
        last_sync_at TEXT,
        last_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )`,
      `INSERT OR IGNORE INTO health_connections (
        provider_key, enabled, connected, last_sync_at, last_error, created_at, updated_at
      ) VALUES
        ('apple_health', 0, 0, NULL, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('health_connect', 0, 0, NULL, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
      `CREATE INDEX IF NOT EXISTS idx_weight_logs_logged_at ON weight_logs(logged_at DESC)`,
      `CREATE INDEX IF NOT EXISTS idx_symptom_logs_logged_at ON symptom_logs(logged_at DESC)`,
      `CREATE INDEX IF NOT EXISTS idx_metric_value_logs_metric_id ON metric_value_logs(metric_id)`,
      `CREATE INDEX IF NOT EXISTS idx_metric_value_logs_logged_at ON metric_value_logs(logged_at DESC)`,
    ],
  },
  {
    version: 6,
    name: 'add_protocol_revision_tables',
    statements: [
      `CREATE TABLE IF NOT EXISTS protocol_revisions (
        id TEXT PRIMARY KEY NOT NULL,
        protocol_id TEXT NOT NULL,
        revision_number INTEGER NOT NULL,
        previous_revision_id TEXT,
        effective_from TEXT NOT NULL,
        effective_to TEXT,
        lifecycle_state TEXT NOT NULL,
        timezone TEXT NOT NULL,
        timezone_strategy TEXT NOT NULL,
        default_time_of_day TEXT,
        dose_amount REAL,
        dose_unit TEXT,
        linked_vial_id TEXT,
        missed_dose_policy TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (protocol_id) REFERENCES protocols(id) ON DELETE CASCADE,
        FOREIGN KEY (previous_revision_id) REFERENCES protocol_revisions(id) ON DELETE SET NULL,
        FOREIGN KEY (linked_vial_id) REFERENCES vials(id) ON DELETE SET NULL
      )`,
      `CREATE TABLE IF NOT EXISTS protocol_revision_rules (
        id TEXT PRIMARY KEY NOT NULL,
        revision_id TEXT NOT NULL,
        phase_type TEXT NOT NULL,
        phase_order INTEGER NOT NULL DEFAULT 0,
        rule_type TEXT NOT NULL,
        interval_count INTEGER NOT NULL,
        weekday INTEGER,
        time_of_day TEXT,
        anchor_date TEXT,
        phase_start_day_offset INTEGER NOT NULL DEFAULT 0,
        phase_length_days INTEGER,
        dose_amount_override REAL,
        dose_unit_override TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (revision_id) REFERENCES protocol_revisions(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS protocol_change_audit_events (
        id TEXT PRIMARY KEY NOT NULL,
        protocol_id TEXT NOT NULL,
        revision_id TEXT NOT NULL,
        previous_revision_id TEXT,
        change_type TEXT NOT NULL,
        effective_from TEXT NOT NULL,
        summary TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (protocol_id) REFERENCES protocols(id) ON DELETE CASCADE,
        FOREIGN KEY (revision_id) REFERENCES protocol_revisions(id) ON DELETE CASCADE,
        FOREIGN KEY (previous_revision_id) REFERENCES protocol_revisions(id) ON DELETE SET NULL
      )`,
      `CREATE INDEX IF NOT EXISTS idx_protocol_revisions_protocol_id ON protocol_revisions(protocol_id, effective_from ASC)`,
      `CREATE INDEX IF NOT EXISTS idx_protocol_revision_rules_revision_id ON protocol_revision_rules(revision_id, phase_order ASC)`,
      `CREATE INDEX IF NOT EXISTS idx_protocol_change_audit_protocol_id ON protocol_change_audit_events(protocol_id, created_at DESC)`,
      `INSERT INTO protocol_revisions (
        id, protocol_id, revision_number, previous_revision_id, effective_from, effective_to,
        lifecycle_state, timezone, timezone_strategy, default_time_of_day, dose_amount, dose_unit,
        linked_vial_id, missed_dose_policy, notes, created_at, updated_at
      )
      SELECT
        'prv_' || p.id || '_1',
        p.id,
        1,
        NULL,
        printf('%sT00:00:00.000Z', p.start_date),
        NULL,
        CASE WHEN p.status = 'paused' THEN 'paused' ELSE 'active' END,
        p.timezone,
        'keep_local_clock',
        p.default_time_of_day,
        p.dose_amount,
        p.dose_unit,
        p.linked_vial_id,
        'skip_and_continue',
        p.notes,
        p.created_at,
        p.updated_at
      FROM protocols p
      WHERE NOT EXISTS (
        SELECT 1 FROM protocol_revisions pr WHERE pr.protocol_id = p.id
      )`,
      `INSERT INTO protocol_revision_rules (
        id, revision_id, phase_type, phase_order, rule_type, interval_count, weekday, time_of_day,
        anchor_date, phase_start_day_offset, phase_length_days, dose_amount_override, dose_unit_override,
        created_at, updated_at
      )
      SELECT
        'prr_' || r.id,
        'prv_' || r.protocol_id || '_1',
        'base',
        ROW_NUMBER() OVER (PARTITION BY r.protocol_id ORDER BY r.created_at ASC) - 1,
        r.rule_type,
        r.interval_count,
        r.weekday,
        r.time_of_day,
        r.anchor_date,
        0,
        NULL,
        NULL,
        NULL,
        r.created_at,
        r.updated_at
      FROM protocol_rules r
      WHERE EXISTS (
        SELECT 1 FROM protocol_revisions pr
        WHERE pr.id = 'prv_' || r.protocol_id || '_1'
      )
      AND NOT EXISTS (
        SELECT 1 FROM protocol_revision_rules prr WHERE prr.id = 'prr_' || r.id
      )`,
    ],
  },
  {
    version: 7,
    name: 'add_trust_vault_tables',
    statements: [
      `CREATE TABLE IF NOT EXISTS privacy_profile (
        id TEXT PRIMARY KEY NOT NULL,
        alias_mode_enabled INTEGER NOT NULL DEFAULT 0,
        biometric_lock_enabled INTEGER NOT NULL DEFAULT 0,
        biometric_gate_mode TEXT NOT NULL DEFAULT 'best_effort',
        share_alias_by_default INTEGER NOT NULL DEFAULT 1,
        export_alias_by_default INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )`,
      `INSERT OR IGNORE INTO privacy_profile (
        id, alias_mode_enabled, biometric_lock_enabled, biometric_gate_mode,
        share_alias_by_default, export_alias_by_default, created_at, updated_at
      ) VALUES (
        'default', 0, 0, 'best_effort', 1, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      )`,
      `CREATE TABLE IF NOT EXISTS protocol_aliases (
        id TEXT PRIMARY KEY NOT NULL,
        protocol_id TEXT NOT NULL UNIQUE,
        alias_label TEXT NOT NULL,
        alias_compound_label TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        archived_at TEXT,
        FOREIGN KEY (protocol_id) REFERENCES protocols(id) ON DELETE CASCADE
      )`,
      `CREATE TABLE IF NOT EXISTS sensitive_action_audit_events (
        id TEXT PRIMARY KEY NOT NULL,
        event_type TEXT NOT NULL,
        surface TEXT NOT NULL,
        protocol_id TEXT,
        scope_kind TEXT,
        render_mode TEXT,
        manifest_version INTEGER,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (protocol_id) REFERENCES protocols(id) ON DELETE SET NULL
      )`,
      `CREATE INDEX IF NOT EXISTS idx_protocol_aliases_protocol_id ON protocol_aliases(protocol_id)`,
      `CREATE INDEX IF NOT EXISTS idx_sensitive_action_audit_created_at ON sensitive_action_audit_events(created_at DESC)`,
      `CREATE INDEX IF NOT EXISTS idx_sensitive_action_audit_protocol_id ON sensitive_action_audit_events(protocol_id, created_at DESC)`,
    ],
  },
];

export async function runMigrations(client: DatabaseClient): Promise<void> {
  await client.exec(`CREATE TABLE IF NOT EXISTS atlas_migrations (
    version INTEGER PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    applied_at TEXT NOT NULL
  )`);

  const applied = await client.getAll<{ version: number }>(
    'SELECT version FROM atlas_migrations ORDER BY version ASC'
  );
  const appliedVersions = new Set(applied.map((row) => row.version));

  for (const migration of atlasMigrations) {
    if (appliedVersions.has(migration.version)) {
      continue;
    }

    await client.withTransaction(async (txn) => {
      for (const statement of migration.statements) {
        await txn.exec(statement);
      }

      await txn.run(
        'INSERT INTO atlas_migrations (version, name, applied_at) VALUES (?, ?, ?)',
        [migration.version, migration.name, new Date().toISOString()]
      );
    });
  }
}
