import AtlasDomain
import GRDB
import Foundation

public struct AtlasDatabaseLocations: Sendable, Equatable {
    public var canonicalDatabaseURL: URL
    public var projectionDatabaseURL: URL
    public var backupDirectoryURL: URL
    public var extensionProjectionSnapshotURL: URL {
        projectionDatabaseURL.deletingLastPathComponent().appendingPathComponent("atlas-extension-projection.json")
    }

    public init(
        canonicalDatabaseURL: URL,
        projectionDatabaseURL: URL,
        backupDirectoryURL: URL
    ) {
        self.canonicalDatabaseURL = canonicalDatabaseURL
        self.projectionDatabaseURL = projectionDatabaseURL
        self.backupDirectoryURL = backupDirectoryURL
    }

    public static func live(appGroupIdentifier: String) throws -> AtlasDatabaseLocations {
        let fileManager = FileManager.default
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appBase = appSupport.appendingPathComponent("Atlas", isDirectory: true)
        let groupBase =
            fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent("AtlasShared", isDirectory: true)

        try fileManager.createDirectory(at: appBase, withIntermediateDirectories: true, attributes: nil)
        let projectionBase = groupBase ?? appBase.appendingPathComponent("SharedFallback", isDirectory: true)
        try fileManager.createDirectory(at: projectionBase, withIntermediateDirectories: true, attributes: nil)
        let backupBase = appBase.appendingPathComponent("Backups", isDirectory: true)
        try fileManager.createDirectory(at: backupBase, withIntermediateDirectories: true, attributes: nil)

        return AtlasDatabaseLocations(
            canonicalDatabaseURL: appBase.appendingPathComponent("atlas.sqlite"),
            projectionDatabaseURL: projectionBase.appendingPathComponent("atlas-projections.sqlite"),
            backupDirectoryURL: backupBase
        )
    }

    public static func temporary(baseURL: URL) -> AtlasDatabaseLocations {
        AtlasDatabaseLocations(
            canonicalDatabaseURL: baseURL.appendingPathComponent("atlas.sqlite"),
            projectionDatabaseURL: baseURL.appendingPathComponent("atlas-projections.sqlite"),
            backupDirectoryURL: baseURL.appendingPathComponent("Backups", isDirectory: true)
        )
    }
}

final class AtlasDatabaseStack: @unchecked Sendable {
    let canonical: DatabaseQueue
    let projections: DatabaseQueue
    let locations: AtlasDatabaseLocations?

    init(locations: AtlasDatabaseLocations) throws {
        let configuration = Configuration()
        self.canonical = try DatabaseQueue(path: locations.canonicalDatabaseURL.path, configuration: configuration)
        self.projections = try DatabaseQueue(path: locations.projectionDatabaseURL.path, configuration: configuration)
        self.locations = locations
        try Self.makeCanonicalMigrator().migrate(canonical)
        try Self.makeProjectionMigrator().migrate(projections)
    }

    init(canonical: DatabaseQueue, projections: DatabaseQueue, locations: AtlasDatabaseLocations?) throws {
        self.canonical = canonical
        self.projections = projections
        self.locations = locations
        try Self.makeCanonicalMigrator().migrate(canonical)
        try Self.makeProjectionMigrator().migrate(projections)
    }

    static func inMemory() throws -> AtlasDatabaseStack {
        try AtlasDatabaseStack(
            canonical: DatabaseQueue(),
            projections: DatabaseQueue(),
            locations: nil
        )
    }

    private static func makeCanonicalMigrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_canonical_schema") { db in
            try db.create(table: "atlas_app_settings") { table in
                table.column("key", .text).primaryKey()
                table.column("value", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "import_templates") { table in
                table.column("id", .text).primaryKey()
                table.column("name", .text).notNull()
                table.column("importer", .text).notNull()
                table.column("generic_csv_mapping_json", .text)
                table.column("manual_options_json", .text)
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "restore_points") { table in
                table.column("id", .text).primaryKey()
                table.column("title", .text).notNull()
                table.column("action_kind", .text).notNull()
                table.column("source_summary", .text).notNull()
                table.column("file_url", .text).notNull()
                table.column("row_count", .integer).notNull()
                table.column("created_at", .text).notNull()
            }

            try db.create(table: "calculator_profiles") { table in
                table.column("id", .text).primaryKey()
                table.column("label", .text).notNull()
                table.column("powder_amount", .double).notNull()
                table.column("powder_unit", .text).notNull()
                table.column("diluent_volume", .double).notNull()
                table.column("diluent_unit", .text).notNull()
                table.column("draw_volume", .double).notNull()
                table.column("draw_unit", .text).notNull()
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "compounds") { table in
                table.column("id", .text).primaryKey()
                table.column("slug", .text).notNull().unique()
                table.column("display_name", .text).notNull()
                table.column("compound_type", .text).notNull()
                table.column("is_user_defined", .boolean).notNull()
                table.column("notes", .text)
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "health_connections") { table in
                table.column("provider_key", .text).primaryKey()
                table.column("enabled", .boolean).notNull()
                table.column("connected", .boolean).notNull()
                table.column("last_sync_at", .text)
                table.column("last_error", .text)
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "protocols") { table in
                table.column("id", .text).primaryKey()
                table.column("compound_id", .text).references("compounds", onDelete: .setNull)
                table.column("linked_vial_id", .text)
                table.column("name", .text).notNull()
                table.column("kind", .text).notNull()
                table.column("administration_route", .text)
                table.column("supply_type", .text)
                table.column("doses_per_supply", .integer)
                table.column("status", .text).notNull()
                table.column("timezone", .text).notNull()
                table.column("start_date", .text).notNull()
                table.column("default_time_of_day", .text)
                table.column("dose_amount", .double)
                table.column("dose_unit", .text)
                table.column("site_tracking_enabled", .boolean).notNull()
                table.column("site_rotation_enabled", .boolean).notNull()
                table.column("notes", .text)
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "custom_metrics") { table in
                table.column("id", .text).primaryKey()
                table.column("protocol_id", .text).references("protocols", onDelete: .setNull)
                table.column("metric_key", .text).notNull()
                table.column("label", .text).notNull()
                table.column("value_type", .text).notNull()
                table.column("unit", .text)
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "protocol_rules") { table in
                table.column("id", .text).primaryKey()
                table.column("protocol_id", .text).notNull().references("protocols", onDelete: .cascade)
                table.column("rule_type", .text).notNull()
                table.column("interval_count", .integer).notNull()
                table.column("weekday", .integer)
                table.column("time_of_day", .text)
                table.column("anchor_date", .text)
                table.column("is_active", .boolean).notNull()
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "protocol_revisions") { table in
                table.column("id", .text).primaryKey()
                table.column("protocol_id", .text).notNull().references("protocols", onDelete: .cascade)
                table.column("revision_number", .integer).notNull()
                table.column("previous_revision_id", .text).references("protocol_revisions", onDelete: .setNull)
                table.column("effective_from", .text).notNull()
                table.column("effective_to", .text)
                table.column("lifecycle_state", .text).notNull()
                table.column("timezone", .text).notNull()
                table.column("timezone_strategy", .text).notNull()
                table.column("administration_route", .text)
                table.column("supply_type", .text)
                table.column("doses_per_supply", .integer)
                table.column("default_time_of_day", .text)
                table.column("dose_amount", .double)
                table.column("dose_unit", .text)
                table.column("linked_vial_id", .text)
                table.column("missed_dose_policy", .text).notNull()
                table.column("notes", .text)
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "protocol_revision_rules") { table in
                table.column("id", .text).primaryKey()
                table.column("revision_id", .text).notNull().references("protocol_revisions", onDelete: .cascade)
                table.column("phase_type", .text).notNull()
                table.column("phase_order", .integer).notNull()
                table.column("rule_type", .text).notNull()
                table.column("interval_count", .integer).notNull()
                table.column("weekday", .integer)
                table.column("time_of_day", .text)
                table.column("anchor_date", .text)
                table.column("phase_start_day_offset", .integer).notNull()
                table.column("phase_length_days", .integer)
                table.column("dose_amount_override", .double)
                table.column("dose_unit_override", .text)
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "protocol_change_audit_events") { table in
                table.column("id", .text).primaryKey()
                table.column("protocol_id", .text).notNull().references("protocols", onDelete: .cascade)
                table.column("revision_id", .text).notNull().references("protocol_revisions", onDelete: .cascade)
                table.column("previous_revision_id", .text).references("protocol_revisions", onDelete: .setNull)
                table.column("change_type", .text).notNull()
                table.column("effective_from", .text).notNull()
                table.column("summary", .text).notNull()
                table.column("payload_json", .text).notNull()
                table.column("created_at", .text).notNull()
            }

            try db.create(table: "sites") { table in
                table.column("id", .text).primaryKey()
                table.column("name", .text).notNull()
                table.column("body_area", .text)
                table.column("map_region_key", .text)
                table.column("notes", .text)
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
                table.column("archived_at", .text)
            }

            try db.create(table: "vials") { table in
                table.column("id", .text).primaryKey()
                table.column("protocol_id", .text).references("protocols", onDelete: .setNull)
                table.column("compound_id", .text).references("compounds", onDelete: .setNull)
                table.column("label", .text).notNull()
                table.column("starting_quantity", .double).notNull()
                table.column("concentration_value", .double)
                table.column("concentration_unit", .text)
                table.column("volume_ml", .double)
                table.column("remaining_quantity", .double).notNull()
                table.column("low_stock_threshold", .double)
                table.column("quantity_unit", .text).notNull()
                table.column("opened_at", .text)
                table.column("expires_at", .text)
                table.column("reference_photo_relative_path", .text)
                table.column("label_scan_text", .text)
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "log_events") { table in
                table.column("id", .text).primaryKey()
                table.column("protocol_id", .text).notNull().references("protocols", onDelete: .cascade)
                table.column("vial_id", .text).references("vials", onDelete: .setNull)
                table.column("site_id", .text).references("sites", onDelete: .setNull)
                table.column("occurrence_id", .text)
                table.column("event_type", .text).notNull()
                table.column("effective_at", .text).notNull()
                table.column("logged_at", .text).notNull()
                table.column("quantity", .double)
                table.column("quantity_unit", .text)
                table.column("notes", .text)
                table.column("source", .text).notNull()
            }

            try db.create(table: "reminder_preferences") { table in
                table.column("id", .text).primaryKey()
                table.column("reminders_enabled", .boolean).notNull()
                table.column("privacy_mode", .text).notNull()
                table.column("lead_time_minutes", .integer).notNull()
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "reminders") { table in
                table.column("id", .text).primaryKey()
                table.column("protocol_id", .text).notNull().references("protocols", onDelete: .cascade)
                table.column("occurrence_id", .text).notNull()
                table.column("offset_minutes", .integer).notNull()
                table.column("channel", .text).notNull()
                table.column("is_enabled", .boolean).notNull()
                table.column("discreet_copy_enabled", .boolean).notNull()
                table.column("privacy_mode", .text).notNull()
                table.column("scheduled_for", .text).notNull()
                table.column("notification_id", .text)
                table.column("title", .text).notNull()
                table.column("body", .text).notNull()
                table.column("status", .text).notNull()
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "privacy_profile") { table in
                table.column("id", .text).primaryKey()
                table.column("alias_mode_enabled", .boolean).notNull()
                table.column("biometric_lock_enabled", .boolean).notNull()
                table.column("biometric_gate_mode", .text).notNull()
                table.column("share_alias_by_default", .boolean).notNull()
                table.column("export_alias_by_default", .boolean).notNull()
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "protocol_aliases") { table in
                table.column("id", .text).primaryKey()
                table.column("protocol_id", .text).notNull().unique().references("protocols", onDelete: .cascade)
                table.column("alias_label", .text).notNull()
                table.column("alias_compound_label", .text)
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
                table.column("archived_at", .text)
            }

            try db.create(table: "sensitive_action_audit_events") { table in
                table.column("id", .text).primaryKey()
                table.column("event_type", .text).notNull()
                table.column("surface", .text).notNull()
                table.column("protocol_id", .text).references("protocols", onDelete: .setNull)
                table.column("scope_kind", .text)
                table.column("render_mode", .text)
                table.column("manifest_version", .integer)
                table.column("payload_json", .text).notNull()
                table.column("created_at", .text).notNull()
            }

            try db.create(table: "metric_value_logs") { table in
                table.column("id", .text).primaryKey()
                table.column("metric_id", .text).notNull().references("custom_metrics", onDelete: .cascade)
                table.column("protocol_id", .text).references("protocols", onDelete: .setNull)
                table.column("logged_at", .text).notNull()
                table.column("number_value", .double)
                table.column("text_value", .text)
                table.column("boolean_value", .boolean)
                table.column("source", .text).notNull()
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "symptom_logs") { table in
                table.column("id", .text).primaryKey()
                table.column("logged_at", .text).notNull()
                table.column("symptom_key", .text).notNull()
                table.column("severity", .integer).notNull()
                table.column("notes", .text)
                table.column("source", .text).notNull()
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "weight_logs") { table in
                table.column("id", .text).primaryKey()
                table.column("logged_at", .text).notNull()
                table.column("value", .double).notNull()
                table.column("unit", .text).notNull()
                table.column("source", .text).notNull()
                table.column("notes", .text)
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(index: "idx_protocol_rules_protocol_id", on: "protocol_rules", columns: ["protocol_id"])
            try db.create(index: "idx_protocol_revisions_protocol_id", on: "protocol_revisions", columns: ["protocol_id", "effective_from"])
            try db.create(index: "idx_log_events_protocol_id", on: "log_events", columns: ["protocol_id", "logged_at"])
            try db.create(index: "idx_reminders_protocol_id", on: "reminders", columns: ["protocol_id", "scheduled_for"])
            try db.create(index: "idx_sensitive_action_protocol_id", on: "sensitive_action_audit_events", columns: ["protocol_id", "created_at"])

            let now = ISO8601DateFormatter.atlas.string(from: Date())
            try db.execute(
                sql: """
                INSERT OR IGNORE INTO atlas_app_settings (key, value, updated_at)
                VALUES ('account_mode', 'guest', ?)
                """,
                arguments: [now]
            )
            try db.execute(
                sql: """
                INSERT OR IGNORE INTO reminder_preferences (
                  id, reminders_enabled, privacy_mode, lead_time_minutes, created_at, updated_at
                ) VALUES ('default', 1, 'full_detail', 0, ?, ?)
                """,
                arguments: [now, now]
            )
            try db.execute(
                sql: """
                INSERT OR IGNORE INTO privacy_profile (
                  id, alias_mode_enabled, biometric_lock_enabled, biometric_gate_mode,
                  share_alias_by_default, export_alias_by_default, created_at, updated_at
                ) VALUES ('default', 0, 0, 'best_effort', 1, 1, ?, ?)
                """,
                arguments: [now, now]
            )
        }

        migrator.registerMigration("v2_add_occurrence_projection_cache") { db in
            try db.create(table: "occurrence_projections") { table in
                table.column("id", .text).primaryKey()
                table.column("protocol_id", .text).notNull().references("protocols", onDelete: .cascade)
                table.column("reminder_id", .text).references("reminders", onDelete: .setNull)
                table.column("scheduled_at", .text).notNull()
                table.column("state", .text).notNull()
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }
            try db.create(index: "idx_occurrence_projections_next_due", on: "occurrence_projections", columns: ["state", "scheduled_at"])
        }

        migrator.registerMigration("v3_add_privacy_render_mode") { db in
            try db.alter(table: "privacy_profile") { table in
                table.add(column: "render_mode", .text)
            }

            try db.execute(
                sql: """
                UPDATE privacy_profile
                SET render_mode = CASE
                    WHEN alias_mode_enabled = 1 THEN 'alias'
                    ELSE 'full'
                END
                WHERE render_mode IS NULL
                """
            )
        }

        migrator.registerMigration("v4_add_vial_archive_and_profile_link") { db in
            try db.alter(table: "vials") { table in
                table.add(column: "calculator_profile_id", .text)
                table.add(column: "archived_at", .text)
            }
        }

        migrator.registerMigration("v5_seed_health_connection_and_onboarding_defaults") { db in
            let now = ISO8601DateFormatter.atlas.string(from: Date())
            try db.execute(
                sql: """
                INSERT OR IGNORE INTO health_connections (
                  provider_key, enabled, connected, last_sync_at, last_error, created_at, updated_at
                ) VALUES ('apple_health', 0, 0, NULL, NULL, ?, ?)
                """,
                arguments: [now, now]
            )
            try db.execute(
                sql: """
                INSERT OR IGNORE INTO atlas_app_settings (key, value, updated_at)
                VALUES ('onboarding_completed', '0', ?)
                """,
                arguments: [now]
            )
        }

        migrator.registerMigration("v6_add_metric_config_and_archive") { db in
            try db.alter(table: "custom_metrics") { table in
                table.add(column: "scale_min", .integer)
                table.add(column: "scale_max", .integer)
                table.add(column: "archived_at", .text)
            }
        }

        migrator.registerMigration("v7_add_review_sessions") { db in
            try db.create(table: "review_sessions") { table in
                table.column("id", .text).primaryKey()
                table.column("title", .text).notNull()
                table.column("scope_kind", .text).notNull()
                table.column("delivery_kind", .text).notNull()
                table.column("render_mode", .text).notNull()
                table.column("row_count", .integer).notNull()
                table.column("summary", .text).notNull()
                table.column("source_description", .text).notNull()
                table.column("workspace_json", .text).notNull()
                table.column("summary_url", .text)
                table.column("pack_url", .text)
                table.column("expires_at", .text)
                table.column("revoked_at", .text)
                table.column("can_revoke", .boolean).notNull()
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }
        }

        migrator.registerMigration("v8_add_import_templates_and_restore_points") { db in
            try db.create(table: "import_templates", ifNotExists: true) { table in
                table.column("id", .text).primaryKey()
                table.column("name", .text).notNull()
                table.column("importer", .text).notNull()
                table.column("generic_csv_mapping_json", .text)
                table.column("manual_options_json", .text)
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "restore_points", ifNotExists: true) { table in
                table.column("id", .text).primaryKey()
                table.column("title", .text).notNull()
                table.column("action_kind", .text).notNull()
                table.column("source_summary", .text).notNull()
                table.column("file_url", .text).notNull()
                table.column("row_count", .integer).notNull()
                table.column("created_at", .text).notNull()
            }
        }

        migrator.registerMigration("v9_add_consumables") { db in
            try db.create(table: "consumables") { table in
                table.column("id", .text).primaryKey()
                table.column("protocol_id", .text).references("protocols", onDelete: .setNull)
                table.column("name", .text).notNull()
                table.column("category", .text)
                table.column("quantity_on_hand", .double).notNull()
                table.column("unit", .text).notNull()
                table.column("reorder_threshold", .double)
                table.column("reorder_lead_time_days", .integer)
                table.column("quantity_per_use", .double)
                table.column("lot_number", .text)
                table.column("size_description", .text)
                table.column("notes", .text)
                table.column("vendor_label", .text)
                table.column("purchase_notes", .text)
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
                table.column("archived_at", .text)
            }

            try db.create(table: "consumable_adjustments") { table in
                table.column("id", .text).primaryKey()
                table.column("consumable_id", .text).notNull().references("consumables", onDelete: .cascade)
                table.column("protocol_id", .text).references("protocols", onDelete: .setNull)
                table.column("occurrence_id", .text)
                table.column("kind", .text).notNull()
                table.column("delta_quantity", .double).notNull()
                table.column("resulting_quantity", .double).notNull()
                table.column("quantity_unit", .text).notNull()
                table.column("note", .text)
                table.column("recorded_at", .text).notNull()
                table.column("created_at", .text).notNull()
            }

            try db.create(index: "idx_consumables_protocol_id", on: "consumables", columns: ["protocol_id", "updated_at"])
            try db.create(index: "idx_consumable_adjustments_consumable_id", on: "consumable_adjustments", columns: ["consumable_id", "recorded_at"])
        }

        migrator.registerMigration("v10_add_context_logs") { db in
            try db.create(table: "context_logs") { table in
                table.column("id", .text).primaryKey()
                table.column("protocol_id", .text).references("protocols", onDelete: .setNull)
                table.column("logged_at", .text).notNull()
                table.column("meal_timing", .text)
                table.column("fed_state", .text)
                table.column("appetite", .text)
                table.column("hydration", .text)
                table.column("gi_context_json", .text).notNull()
                table.column("note", .text)
                table.column("tags_json", .text).notNull()
                table.column("source", .text).notNull()
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(index: "idx_context_logs_logged_at", on: "context_logs", columns: ["logged_at"])
            try db.create(index: "idx_context_logs_protocol_id", on: "context_logs", columns: ["protocol_id", "logged_at"])
        }

        migrator.registerMigration("v11_expand_context_logs_for_meal_detail") { db in
            try db.alter(table: "context_logs") { table in
                table.add(column: "meal_size", .text)
                table.add(column: "meal_composition", .text)
                table.add(column: "preset_key", .text)
            }
        }

        migrator.registerMigration("v12_add_context_presets") { db in
            try db.create(table: "context_presets") { table in
                table.column("id", .text).primaryKey()
                table.column("title", .text).notNull()
                table.column("meal_timing", .text)
                table.column("meal_size", .text)
                table.column("meal_composition", .text)
                table.column("fed_state", .text)
                table.column("appetite", .text)
                table.column("hydration", .text)
                table.column("gi_context_json", .text).notNull()
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
                table.column("last_used_at", .text)
            }
            try db.create(index: "idx_context_presets_last_used", on: "context_presets", columns: ["last_used_at", "updated_at"])
        }

        migrator.registerMigration("v13_add_workout_logs") { db in
            try db.create(table: "workout_logs") { table in
                table.column("id", .text).primaryKey()
                table.column("activity_kind", .text).notNull()
                table.column("started_at", .text).notNull()
                table.column("ended_at", .text).notNull()
                table.column("duration_minutes", .double).notNull()
                table.column("energy_burned_kilocalories", .double)
                table.column("distance_meters", .double)
                table.column("source", .text).notNull()
                table.column("external_source_id", .text).unique()
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }
            try db.create(index: "idx_workout_logs_started_at", on: "workout_logs", columns: ["started_at"])
        }

        migrator.registerMigration("v14_add_restore_point_integrity_columns") { db in
            try db.alter(table: "restore_points") { table in
                table.add(column: "file_sha256", .text)
                table.add(column: "file_byte_count", .integer)
            }
        }

        migrator.registerMigration("v15_add_consumable_procurement_metadata") { db in
            try db.alter(table: "consumable_adjustments") { table in
                table.add(column: "vendor_label", .text)
                table.add(column: "source_detail", .text)
            }
        }

        migrator.registerMigration("v16_add_progress_evidence") { db in
            try db.create(table: "progress_measurements") { table in
                table.column("id", .text).primaryKey()
                table.column("protocol_id", .text).references("protocols", onDelete: .setNull)
                table.column("kind", .text).notNull()
                table.column("value", .double).notNull()
                table.column("unit", .text).notNull()
                table.column("note", .text)
                table.column("logged_at", .text).notNull()
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(table: "progress_photos") { table in
                table.column("id", .text).primaryKey()
                table.column("protocol_id", .text).references("protocols", onDelete: .setNull)
                table.column("angle", .text).notNull()
                table.column("note", .text)
                table.column("relative_asset_path", .text).notNull()
                table.column("logged_at", .text).notNull()
                table.column("created_at", .text).notNull()
                table.column("updated_at", .text).notNull()
            }

            try db.create(index: "idx_progress_measurements_logged_at", on: "progress_measurements", columns: ["logged_at"])
            try db.create(index: "idx_progress_photos_logged_at", on: "progress_photos", columns: ["logged_at"])
        }

        migrator.registerMigration("v17_add_protocol_delivery_metadata") { db in
            let protocolColumns = Set(try String.fetchAll(db, sql: "SELECT name FROM pragma_table_info('protocols')"))
            if protocolColumns.contains("administration_route") == false ||
                protocolColumns.contains("supply_type") == false ||
                protocolColumns.contains("doses_per_supply") == false {
                try db.alter(table: "protocols") { table in
                    if protocolColumns.contains("administration_route") == false {
                        table.add(column: "administration_route", .text)
                    }
                    if protocolColumns.contains("supply_type") == false {
                        table.add(column: "supply_type", .text)
                    }
                    if protocolColumns.contains("doses_per_supply") == false {
                        table.add(column: "doses_per_supply", .integer)
                    }
                }
            }

            let revisionColumns = Set(try String.fetchAll(db, sql: "SELECT name FROM pragma_table_info('protocol_revisions')"))
            if revisionColumns.contains("administration_route") == false ||
                revisionColumns.contains("supply_type") == false ||
                revisionColumns.contains("doses_per_supply") == false {
                try db.alter(table: "protocol_revisions") { table in
                    if revisionColumns.contains("administration_route") == false {
                        table.add(column: "administration_route", .text)
                    }
                    if revisionColumns.contains("supply_type") == false {
                        table.add(column: "supply_type", .text)
                    }
                    if revisionColumns.contains("doses_per_supply") == false {
                        table.add(column: "doses_per_supply", .integer)
                    }
                }
            }
        }

        migrator.registerMigration("v18_add_vial_media_capture") { db in
            let vialColumns = Set(try String.fetchAll(db, sql: "SELECT name FROM pragma_table_info('vials')"))
            if vialColumns.contains("reference_photo_relative_path") == false ||
                vialColumns.contains("label_scan_text") == false {
                try db.alter(table: "vials") { table in
                    if vialColumns.contains("reference_photo_relative_path") == false {
                        table.add(column: "reference_photo_relative_path", .text)
                    }
                    if vialColumns.contains("label_scan_text") == false {
                        table.add(column: "label_scan_text", .text)
                    }
                }
            }
        }

        migrator.registerMigration("v19_add_site_map_regions") { db in
            let siteColumns = Set(try String.fetchAll(db, sql: "SELECT name FROM pragma_table_info('sites')"))
            if siteColumns.contains("map_region_key") == false {
                try db.alter(table: "sites") { table in
                    table.add(column: "map_region_key", .text)
                }
            }
        }

        return migrator
    }

    private static func makeProjectionMigrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_projection_schema") { db in
            try db.create(table: "next_due_snapshot") { table in
                table.column("id", .text).primaryKey()
                table.column("protocol_id", .text).notNull()
                table.column("display_title", .text).notNull()
                table.column("due_label", .text).notNull()
                table.column("scheduled_at", .text).notNull()
            }

            try db.create(table: "widget_timeline_summary") { table in
                table.column("id", .text).primaryKey()
                table.column("protocol_id", .text).notNull()
                table.column("display_title", .text).notNull()
                table.column("summary", .text).notNull()
                table.column("recorded_at", .text).notNull()
            }

            try db.create(table: "label_projection") { table in
                table.column("id", .text).primaryKey()
                table.column("canonical_title", .text).notNull()
                table.column("alias_title", .text)
                table.column("discreet_title", .text).notNull()
            }

            try db.create(table: "quick_action_projection") { table in
                table.column("id", .text).primaryKey()
                table.column("protocol_id", .text).notNull()
                table.column("occurrence_id", .text).notNull()
                table.column("title", .text).notNull()
            }

            try db.create(table: "feature_flag_projection") { table in
                table.column("flag", .text).primaryKey()
                table.column("is_enabled", .boolean).notNull()
            }
        }

        return migrator
    }
}
