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
            try writeAppSetting(
                db: db,
                key: "mascot_nickname",
                value: atlasMascotSanitizedNickname(draft.profile.mascotNickname),
                now: now
            )
            if let mascotSelection = draft.profile.mascotSelection ?? atlasInferredMascotSelection(from: draft.profile.gender) {
                try writeAppSetting(db: db, key: "mascot_selection", value: mascotSelection.rawValue, now: now)
                try writeAppSetting(
                    db: db,
                    key: "mascot_selection_confirmed",
                    value: draft.profile.mascotSelection == nil ? "0" : "1",
                    now: now
                )
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
                key: "mascot_selection",
                value: (draft.profile.mascotSelection ?? atlasInferredMascotSelection(from: draft.profile.gender) ?? .aetherion).rawValue,
                now: now
            )
            try writeAppSetting(
                db: db,
                key: "mascot_nickname",
                value: atlasMascotSanitizedNickname(draft.profile.mascotNickname),
                now: now
            )
            try writeAppSetting(db: db, key: "mascot_selection_confirmed", value: "1", now: now)
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
            try writeAppSetting(db: db, key: "mascot_selection", value: nil, now: now)
            try writeAppSetting(db: db, key: "mascot_nickname", value: nil, now: now)
            try writeAppSetting(db: db, key: "mascot_selection_confirmed", value: nil, now: now)
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
    let mascotSelectionRaw = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'mascot_selection'"
    )
    let mascotSelectionConfirmedRaw = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'mascot_selection_confirmed'"
    )
    let mascotNicknameRaw = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'mascot_nickname'"
    )
    let mascotUnlocks = try atlasReadMascotUnlockSnapshots(db: db)
    let mascotEvolutionHistory = try atlasReadMascotEvolutionHistory(db: db)
    let mascotMoments = try atlasReadMascotMoments(db: db)
    let mascotArchivedRecaps = try atlasReadMascotArchivedRecaps(db: db)
    let mascotRecapNotificationSettings = try atlasReadMascotRecapNotificationSettings(db: db)
    let weeklyReviewReminderSettings = try atlasReadWeeklyReviewReminderSettings(db: db)
    let weeklyReviewActionPlans = try atlasReadWeeklyReviewActionPlans(db: db)
    let accountMode = AtlasAccountMode(rawValue: accountModeRaw ?? AtlasAccountMode.guest.rawValue) ?? .guest
    let accountStartMode = accountStartModeRaw.flatMap(AtlasOnboardingAccountMode.init(rawValue:))
    let onboardingCompleted = onboardingCompletedRaw == "1"
    let onboardingDraft = try readDraft(db: db)
    let mascotSelection = mascotSelectionRaw.flatMap(AtlasMascotSelection.init(rawValue:))
        ?? onboardingDraft?.profile.mascotSelection
        ?? atlasInferredMascotSelection(from: onboardingDraft?.profile.gender)
        ?? .aetherion
    let mascotSelectionConfirmed = mascotSelectionConfirmedRaw == "1"
    let profile = try AtlasPrivacyProfileDBRecord.fetchOne(db)?.domain ?? .default()
    let connections = try AtlasHealthConnectionDBRecord.fetchAll(db).map(\.domain).sorted {
        $0.providerKey.rawValue < $1.providerKey.rawValue
    }
    let syncedWeightEntryCount = try Int.fetchOne(
        db,
        sql: "SELECT COUNT(*) FROM weight_logs WHERE source = ?",
        arguments: [AtlasHealthDataSource.health.rawValue]
    ) ?? 0
    let lastWeightEntryAt = try String.fetchOne(
        db,
        sql: "SELECT logged_at FROM weight_logs WHERE source = ? ORDER BY logged_at DESC LIMIT 1",
        arguments: [AtlasHealthDataSource.health.rawValue]
    )
    let syncedWorkoutEntryCount = try Int.fetchOne(
        db,
        sql: "SELECT COUNT(*) FROM workout_logs WHERE source = ?",
        arguments: [AtlasHealthDataSource.health.rawValue]
    ) ?? 0
    let lastWorkoutEntryAt = try String.fetchOne(
        db,
        sql: "SELECT started_at FROM workout_logs WHERE source = ? ORDER BY started_at DESC LIMIT 1",
        arguments: [AtlasHealthDataSource.health.rawValue]
    )
    let syncStatus: AtlasSyncScaffoldStatus = accountMode == .guest ? .localOnly : .accountBoundary
    let summarySettings = try readSummarySettings(db: db, featureFlags: featureFlags)
    let retentionSettings = try readRetentionSettings(db: db, featureFlags: featureFlags)
    let rewardsSettings = try readRewardsSettings(db: db)
    let labsEnabled = try readLabsEnabled(db: db)

    return AtlasSettingsSnapshot(
        accountMode: accountMode,
        accountStartMode: accountStartMode,
        onboardingCompleted: onboardingCompleted,
        syncStatus: syncStatus,
        healthScaffold: AtlasHealthScaffoldSnapshot(
            isAvailable: healthKit.isAvailable(),
            connections: connections,
            syncsWeight: true,
            syncsWorkouts: true,
            syncedWeightEntryCount: syncedWeightEntryCount,
            lastWeightEntryAt: lastWeightEntryAt,
            syncedWorkoutEntryCount: syncedWorkoutEntryCount,
            lastWorkoutEntryAt: lastWorkoutEntryAt
        ),
        labsEnabled: labsEnabled,
        trustVaultStatus: TrustVaultStatus(
            renderMode: profile.renderMode ?? (profile.aliasModeEnabled ? .alias : .full),
            biometricLockEnabled: profile.biometricLockEnabled
        ),
        mascotSelection: mascotSelection,
        mascotNickname: atlasMascotSanitizedNickname(mascotNicknameRaw ?? onboardingDraft?.profile.mascotNickname),
        mascotSelectionConfirmed: mascotSelectionConfirmed,
        mascotUnlocks: mascotUnlocks,
        mascotEvolutionHistory: mascotEvolutionHistory,
        mascotMoments: mascotMoments,
        mascotArchivedRecaps: mascotArchivedRecaps,
        mascotRecapNotificationSettings: mascotRecapNotificationSettings,
        weeklyReviewReminderSettings: weeklyReviewReminderSettings,
        weeklyReviewActionPlans: weeklyReviewActionPlans,
        summarySettings: summarySettings,
        retentionSettings: retentionSettings,
        rewardsSettings: rewardsSettings
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

func readRewardsSettings(db: Database) throws -> AtlasRewardsSettingsSnapshot {
    let enabledValue = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'rewards_enabled'"
    )
    let workoutGoalValue = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'rewards_weekly_workout_goal'"
    )
    let selfGoalTargetValue = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'rewards_weekly_self_goal_target'"
    )

    return AtlasRewardsSettingsSnapshot(
        enabled: enabledValue == "1",
        weeklyWorkoutGoal: max(Int(workoutGoalValue ?? "") ?? 3, 1),
        weeklySelfGoalTarget: max(Int(selfGoalTargetValue ?? "") ?? 2, 1)
    )
}

func readLabsEnabled(db: Database) throws -> Bool {
    try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'labs_enabled'"
    ) == "1"
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

func atlasMascotUnlockedStageSettingKey(for selection: AtlasMascotSelection) -> String {
    "mascot_unlocked_stage_\(selection.rawValue)"
}

func atlasReadMascotUnlockSnapshots(db: Database) throws -> [AtlasMascotUnlockSnapshot] {
    try AtlasMascotSelection.allCases.map { selection in
        let stageRaw = try String.fetchOne(
            db,
            sql: "SELECT value FROM atlas_app_settings WHERE key = ?",
            arguments: [atlasMascotUnlockedStageSettingKey(for: selection)]
        )
        let stage = stageRaw.flatMap(AtlasMascotStage.init(rawValue:)) ?? .stage1
        return AtlasMascotUnlockSnapshot(selection: selection, highestUnlockedStage: stage)
    }
}

func atlasReadMascotEvolutionHistory(db: Database) throws -> [AtlasMascotEvolutionRecord] {
    guard let json = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'mascot_evolution_history_json'"
    ), json.isEmpty == false else {
        return []
    }
    return try JSONDecoder().decode([AtlasMascotEvolutionRecord].self, from: Data(json.utf8))
}

func atlasEncodeMascotEvolutionHistory(_ history: [AtlasMascotEvolutionRecord]) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(history)
    return String(decoding: data, as: UTF8.self)
}

func atlasReadMascotMoments(db: Database) throws -> [AtlasMascotMomentRecord] {
    guard let json = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'mascot_moments_json'"
    ), json.isEmpty == false else {
        return []
    }
    return try JSONDecoder().decode([AtlasMascotMomentRecord].self, from: Data(json.utf8))
}

func atlasEncodeMascotMoments(_ moments: [AtlasMascotMomentRecord]) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(moments)
    return String(decoding: data, as: UTF8.self)
}

func atlasReadMascotArchivedRecaps(db: Database) throws -> [AtlasMascotArchivedRecapRecord] {
    guard let json = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'mascot_archived_recaps_json'"
    ), json.isEmpty == false else {
        return []
    }
    return try JSONDecoder().decode([AtlasMascotArchivedRecapRecord].self, from: Data(json.utf8))
}

func atlasEncodeMascotArchivedRecaps(_ recaps: [AtlasMascotArchivedRecapRecord]) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(recaps)
    return String(decoding: data, as: UTF8.self)
}

func atlasReadMascotRecapNotificationSettings(
    db: Database
) throws -> AtlasMascotRecapNotificationSettings {
    let dailyEnabled = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'mascot_recap_daily_enabled'"
    ) == "1"
    let weeklyEnabled = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'mascot_recap_weekly_enabled'"
    ) == "1"
    return AtlasMascotRecapNotificationSettings(
        dailyEnabled: dailyEnabled,
        weeklyEnabled: weeklyEnabled
    )
}

func atlasReadWeeklyReviewReminderSettings(
    db: Database
) throws -> AtlasWeeklyReviewReminderSettings {
    AtlasWeeklyReviewReminderSettings(
        enabled: try String.fetchOne(
            db,
            sql: "SELECT value FROM atlas_app_settings WHERE key = 'weekly_review_reminder_enabled'"
        ) == "1"
    )
}

func atlasReadWeeklyReviewActionPlans(db: Database) throws -> [AtlasWeeklyReviewActionPlan] {
    guard let json = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'weekly_review_action_plans_json'"
    ), json.isEmpty == false else {
        return []
    }
    return try JSONDecoder().decode([AtlasWeeklyReviewActionPlan].self, from: Data(json.utf8))
}

func atlasEncodeWeeklyReviewActionPlans(_ plans: [AtlasWeeklyReviewActionPlan]) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(plans)
    return String(decoding: data, as: UTF8.self)
}

func atlasInferredMascotSelection(from gender: String?) -> AtlasMascotSelection? {
    guard let normalized = gender?
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased(),
          normalized.isEmpty == false else {
        return nil
    }

    let femaleTokens = ["female", "woman", "girl", "f", "she", "her"]
    if femaleTokens.contains(where: { normalized == $0 || normalized.contains($0) }) {
        return .aurielle
    }

    let maleTokens = ["male", "man", "boy", "m", "he", "him"]
    if maleTokens.contains(where: { normalized == $0 || normalized.contains($0) }) {
        return .aetherion
    }

    return nil
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
