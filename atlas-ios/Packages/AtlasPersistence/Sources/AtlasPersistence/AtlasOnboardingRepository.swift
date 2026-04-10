import AtlasDomain
import AtlasSystem
import GRDB
import Foundation

enum AtlasOnboardingRepositoryError: LocalizedError {
    case incompleteDraft([String])

    var errorDescription: String? {
        switch self {
        case .incompleteDraft(let fields):
            "Onboarding is incomplete: \(fields.joined(separator: ", "))"
        }
    }
}

public struct GRDBOnboardingRepository: OnboardingRepository, Sendable {
    let stack: AtlasDatabaseStack
    let healthKit: any HealthKitManaging

    init(
        stack: AtlasDatabaseStack,
        healthKit: any HealthKitManaging
    ) {
        self.stack = stack
        self.healthKit = healthKit
    }

    public func loadBootstrapSnapshot() async throws -> AtlasBootstrapSnapshot {
        try await stack.canonical.write { db in
            try ensureDefaultHealthConnection(db: db)
            return try buildBootstrapSnapshot(db: db)
        }
    }

    public func saveDraft(_ draft: AtlasOnboardingDraft, now: Date) async throws -> AtlasBootstrapSnapshot {
        try await stack.canonical.write { db in
            try ensureDefaultHealthConnection(db: db)
            try writeAppSetting(db: db, key: "onboarding_draft_json", value: encodeDraft(draft), now: now)
            if let accountMode = draft.accountMode {
                try writeAppSetting(db: db, key: "account_start_mode", value: accountMode.rawValue, now: now)
            }
            return try buildBootstrapSnapshot(db: db)
        }
    }

    public func completeOnboarding(_ draft: AtlasOnboardingDraft, now: Date) async throws -> AtlasBootstrapSnapshot {
        let missing = draft.requiredMissingFields()
        guard missing.isEmpty else {
            throw AtlasOnboardingRepositoryError.incompleteDraft(missing)
        }

        return try await stack.canonical.write { db in
            try ensureDefaultHealthConnection(db: db)
            try writeAppSetting(db: db, key: "onboarding_draft_json", value: encodeDraft(draft), now: now)
            try writeAppSetting(db: db, key: "onboarding_completed", value: "1", now: now)
            try writeAppSetting(db: db, key: "onboarding_completed_at", value: atlasTimestamp(from: now), now: now)
            try writeAppSetting(db: db, key: "account_start_mode", value: draft.accountMode?.rawValue, now: now)
            try writeAppSetting(
                db: db,
                key: "account_mode",
                value: draft.accountMode == .guest ? AtlasAccountMode.guest.rawValue : AtlasAccountMode.account.rawValue,
                now: now
            )
            try writeAppSetting(
                db: db,
                key: "analytics_opt_in",
                value: draft.privacy.analyticsOptIn ? "1" : "0",
                now: now
            )

            var profile = try AtlasPrivacyProfileDBRecord.fetchOne(db)?.domain ?? .default()
            let shouldUseDiscreet = draft.privacy.discreetNotifications || draft.privacy.hideSensitiveLabels
            profile.renderMode = shouldUseDiscreet ? .discreet : .full
            profile.aliasModeEnabled = false
            profile.biometricLockEnabled = false
            profile.biometricGateMode = draft.privacy.biometricLater ? .bestEffort : .off
            profile.updatedAt = atlasTimestamp(from: now)
            try AtlasPrivacyProfileDBRecord(record: profile).save(db)

            _ = try AtlasHealthConnectionDBRecord
                .filter(Column("provider_key") == AtlasHealthProviderKey.appleHealth.rawValue)
                .fetchOne(db)?.domain ?? AtlasHealthConnectionRecord.make(
                    providerKey: .appleHealth,
                    enabled: false,
                    connected: false,
                    lastSyncAt: nil,
                    lastError: nil,
                    createdAt: atlasTimestamp(from: now),
                    updatedAt: atlasTimestamp(from: now)
                )
            try writeHealthConnection(
                db: db,
                provider: .appleHealth,
                enabled: false,
                connected: false,
                lastSyncAt: nil,
                lastError: nil,
                now: now
            )

            return try buildBootstrapSnapshot(
                db: db,
                overrideDraft: draft,
                onboardingCompleted: true
            )
        }
    }

    public func resetOnboarding(now: Date) async throws -> AtlasBootstrapSnapshot {
        try await stack.canonical.write { db in
            try ensureDefaultHealthConnection(db: db)
            try writeAppSetting(db: db, key: "onboarding_draft_json", value: nil, now: now)
            try writeAppSetting(db: db, key: "onboarding_completed", value: "0", now: now)
            try writeAppSetting(db: db, key: "onboarding_completed_at", value: nil, now: now)
            try writeAppSetting(db: db, key: "account_start_mode", value: nil, now: now)
            return try buildBootstrapSnapshot(db: db)
        }
    }
}

func buildBootstrapSnapshot(
    db: Database,
    overrideDraft: AtlasOnboardingDraft? = nil,
    onboardingCompleted forcedCompleted: Bool? = nil
) throws -> AtlasBootstrapSnapshot {
    let hasLocalData = try hasCanonicalLocalData(db: db)
    let completedValue = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'onboarding_completed'"
    )
    let onboardingCompleted = forcedCompleted ?? (completedValue == "1")
    let draft = try (overrideDraft ?? readDraft(db: db) ?? .empty())
    let isImportedLocalUser = hasLocalData && onboardingCompleted == false

    let reason: AtlasBootstrapReason
    let destination: AtlasBootstrapDestination

    if onboardingCompleted {
        reason = .completedOnboarding
        destination = .app
    } else if isImportedLocalUser {
        reason = .importedLocalUser
        destination = .app
    } else if draft.accountMode != nil || draft.trackType != nil || draft.healthConnectionPromptSeen {
        reason = .resumedOnboarding
        destination = .onboarding
    } else if hasLocalData {
        reason = .existingLocalUser
        destination = .app
    } else {
        reason = .firstRun
        destination = .onboarding
    }

    return AtlasBootstrapSnapshot(
        destination: destination,
        reason: reason,
        onboardingDraft: draft,
        onboardingCompleted: onboardingCompleted,
        hasLocalData: hasLocalData,
        isImportedLocalUser: isImportedLocalUser
    )
}

func buildSettingsSnapshot(
    db: Database,
    healthKit: any HealthKitManaging,
    featureFlags: AtlasFeatureFlagState
) throws -> AtlasSettingsSnapshot {
    let accountModeRaw = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'account_mode'"
    )
    let accountStartModeRaw = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'account_start_mode'"
    )
    let onboardingCompletedRaw = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'onboarding_completed'"
    )
    let accountMode = AtlasAccountMode(rawValue: accountModeRaw ?? AtlasAccountMode.guest.rawValue) ?? .guest
    let accountStartMode = accountStartModeRaw.flatMap(AtlasOnboardingAccountMode.init(rawValue:))
    let onboardingCompleted = onboardingCompletedRaw == "1"
    let profile = try AtlasPrivacyProfileDBRecord.fetchOne(db)?.domain ?? .default()
    let connections = try AtlasHealthConnectionDBRecord.fetchAll(db).map(\.domain).sorted {
        $0.providerKey.rawValue < $1.providerKey.rawValue
    }
    let syncStatus: AtlasSyncScaffoldStatus = accountMode == .guest ? .localOnly : .accountBoundary
    let summarySettings = try readSummarySettings(db: db, featureFlags: featureFlags)
    let retentionSettings = try readRetentionSettings(db: db, featureFlags: featureFlags)

    return AtlasSettingsSnapshot(
        accountMode: accountMode,
        accountStartMode: accountStartMode,
        onboardingCompleted: onboardingCompleted,
        syncStatus: syncStatus,
        healthScaffold: AtlasHealthScaffoldSnapshot(
            isAvailable: healthKit.isAvailable(),
            connections: connections
        ),
        trustVaultStatus: TrustVaultStatus(
            renderMode: profile.renderMode ?? (profile.aliasModeEnabled ? .alias : .full),
            biometricLockEnabled: profile.biometricLockEnabled
        ),
        summarySettings: summarySettings,
        retentionSettings: retentionSettings
    )
}

func readSummarySettings(
    db: Database,
    featureFlags: AtlasFeatureFlagState
) throws -> AtlasSummarySettingsSnapshot {
    let onDeviceValue = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'summary_on_device_enabled'"
    )
    let externalValue = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'summary_external_provider_enabled'"
    )
    let consentAtValue = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'summary_external_provider_consent_at'"
    )

    let onDeviceEnabled = featureFlags.boundedSummaries && onDeviceValue == "1"
    let externalProviderEnabled = featureFlags.externalSummaryProviders && externalValue == "1"

    return AtlasSummarySettingsSnapshot(
        onDeviceEnabled: onDeviceEnabled,
        externalProviderEnabled: externalProviderEnabled,
        externalProviderConsentRecordedAt: consentAtValue.map(atlasDate(from:))
    )
}

func readRetentionSettings(
    db: Database,
    featureFlags: AtlasFeatureFlagState
) throws -> AtlasRetentionSettingsSnapshot {
    let progressValue = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'retention_progress_enabled'"
    )
    let companionValue = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'retention_companion_enabled'"
    )

    let progressEnabled = featureFlags.calmRetention && progressValue == "1"
    let companionEnabled = featureFlags.calmRetention
        && featureFlags.companionSkin
        && companionValue == "1"

    return AtlasRetentionSettingsSnapshot(
        progressEnabled: progressEnabled,
        companionEnabled: companionEnabled
    )
}

func ensureDefaultHealthConnection(db: Database) throws {
    let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM health_connections") ?? 0
    guard count == 0 else {
        return
    }
    let now = atlasTimestamp(from: Date())
    let record = AtlasHealthConnectionRecord.make(
        providerKey: .appleHealth,
        enabled: false,
        connected: false,
        lastSyncAt: nil,
        lastError: nil,
        createdAt: now,
        updatedAt: now
    )
    try AtlasHealthConnectionDBRecord(record: record).insert(db)
}

func writeHealthConnection(
    db: Database,
    provider: AtlasHealthProviderKey,
    enabled: Bool,
    connected: Bool,
    lastSyncAt: Date?,
    lastError: String?,
    now: Date
) throws {
    let timestamp = atlasTimestamp(from: now)
    let existing = try AtlasHealthConnectionDBRecord
        .filter(Column("provider_key") == provider.rawValue)
        .fetchOne(db)?.domain

    let record = AtlasHealthConnectionRecord.make(
        providerKey: provider,
        enabled: enabled,
        connected: connected,
        lastSyncAt: lastSyncAt.map { atlasTimestamp(from: $0) },
        lastError: lastError,
        createdAt: existing?.createdAt ?? timestamp,
        updatedAt: timestamp
    )
    try AtlasHealthConnectionDBRecord(record: record).save(db)
}

private func hasCanonicalLocalData(db: Database) throws -> Bool {
    let protocolCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM protocols") ?? 0
    let logCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM log_events") ?? 0
    let vialCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM vials") ?? 0
    let consumableCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM consumables") ?? 0
    let weightCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM weight_logs") ?? 0
    let symptomCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM symptom_logs") ?? 0
    let contextCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM context_logs") ?? 0
    return protocolCount + logCount + vialCount + consumableCount + weightCount + symptomCount + contextCount > 0
}

private func readDraft(db: Database) throws -> AtlasOnboardingDraft? {
    guard let json = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'onboarding_draft_json'"
    ), json.isEmpty == false else {
        return nil
    }
    return try JSONDecoder().decode(AtlasOnboardingDraft.self, from: Data(json.utf8))
}

private func encodeDraft(_ draft: AtlasOnboardingDraft) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(draft)
    return String(decoding: data, as: UTF8.self)
}

func writeAppSetting(
    db: Database,
    key: String,
    value: String?,
    now: Date
) throws {
    if let value {
        try db.execute(
            sql: """
            INSERT INTO atlas_app_settings (key, value, updated_at)
            VALUES (?, ?, ?)
            ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at
            """,
            arguments: [key, value, atlasTimestamp(from: now)]
        )
    } else {
        try db.execute(
            sql: "DELETE FROM atlas_app_settings WHERE key = ?",
            arguments: [key]
        )
    }
}
