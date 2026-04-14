import AtlasDomain
import AtlasPrivacy
import AtlasSystem
import GRDB
import Foundation

public struct GRDBProtocolRepository: ProtocolRepository, Sendable {
    let stack: AtlasDatabaseStack

    init(stack: AtlasDatabaseStack) {
        self.stack = stack
    }

    public func listProtocolSummaries() async throws -> [ProtocolSummary] {
        try await stack.canonical.read { db in
            let context = try loadCoreLoopContext(db: db)
            return context.protocols.values
                .sorted { $0.createdAt > $1.createdAt }
                .map { protocolRecord in
                    buildProtocolSummary(
                        protocolRecord: protocolRecord,
                        alias: context.aliases[protocolRecord.id],
                        protocolRules: context.protocolRules[protocolRecord.id] ?? [],
                        revisionSlices: context.revisionSlices[protocolRecord.id] ?? [],
                        pendingOccurrences: context.pendingOccurrences[protocolRecord.id] ?? [],
                        now: Date()
                    )
                }
        }
    }
}

public struct GRDBTimelineRepository: TimelineRepository, Sendable {
    let stack: AtlasDatabaseStack
    let privacyFormatter: AtlasPrivacyFormatter

    init(stack: AtlasDatabaseStack, privacyFormatter: AtlasPrivacyFormatter) {
        self.stack = stack
        self.privacyFormatter = privacyFormatter
    }

    public func fetchHistory(limit: Int) async throws -> [ImmutableLogEventSummary] {
        try await stack.canonical.read { db in
            let logRows = try AtlasLogEventDBRecord
                .order(Column("logged_at").desc)
                .limit(limit)
                .fetchAll(db)
                .map(\.domain)
            let protocols = Dictionary(uniqueKeysWithValues: try AtlasProtocolDBRecord.fetchAll(db).map { ($0.id, $0.domain) })
            let aliases = Dictionary(uniqueKeysWithValues: try AtlasProtocolAliasDBRecord.fetchAll(db).map { ($0.protocolId, $0.domain) })
            let renderMode = privacyFormatter.renderMode(
                for: try AtlasPrivacyProfileDBRecord.fetchOne(db)?.domain ?? .default()
            )

            return logRows.map { row in
                let protocolRecord = protocols[row.protocolId]
                let alias = aliases[row.protocolId]?.aliasLabel
                let canonicalTitle = protocolRecord?.name ?? "Atlas protocol"
                return ImmutableLogEventSummary(
                    id: row.id,
                    protocolID: row.protocolId,
                    summary: privacyFormatter.timelineSummary(
                        eventType: row.eventType,
                        canonical: canonicalTitle,
                        alias: alias,
                        mode: renderMode
                    ),
                    recordedAt: atlasDate(from: row.loggedAt)
                )
            }
        }
    }
}

public struct GRDBTodayRepository: TodayRepository, Sendable {
    let stack: AtlasDatabaseStack

    init(stack: AtlasDatabaseStack) {
        self.stack = stack
    }

    public func fetchNextDue() async throws -> FutureOccurrenceSummary? {
        let snapshot = try await fetchTodaySnapshot(referenceDate: Date())
        guard let nextDue = snapshot.nextDue else {
            return nil
        }

        return FutureOccurrenceSummary(
            id: nextDue.id,
            protocolID: nextDue.protocolID,
            canonicalTitle: nextDue.canonicalTitle,
            aliasTitle: nextDue.aliasTitle,
            kindLabel: nextDue.kindLabel,
            dueLabel: relativeDueLabel(for: nextDue.scheduledAt),
            scheduledAt: nextDue.scheduledAt
        )
    }
}

public struct GRDBSettingsRepository: SettingsRepository, Sendable {
    let stack: AtlasDatabaseStack
    let healthKit: any HealthKitManaging
    let featureFlags: AtlasFeatureFlagState

    init(
        stack: AtlasDatabaseStack,
        healthKit: any HealthKitManaging,
        featureFlags: AtlasFeatureFlagState
    ) {
        self.stack = stack
        self.healthKit = healthKit
        self.featureFlags = featureFlags
    }

    public func currentSettingsSnapshot() async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.read { db in
            try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func updateAccountMode(_ accountMode: AtlasAccountMode, now: Date) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            try writeAppSetting(db: db, key: "account_mode", value: accountMode.rawValue, now: now)
            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func updateSurfacePreferences(
        _ preferences: AtlasSurfacePreferences,
        now: Date
    ) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            try writeAppSetting(
                db: db,
                key: "surface_preferences_json",
                value: try atlasEncodeSurfacePreferences(preferences),
                now: now
            )
            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func updateTrustVaultRenderMode(_ renderMode: AtlasPrivacyRenderMode, now: Date) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            var profile = try AtlasPrivacyProfileDBRecord.fetchOne(db)?.domain ?? .default()
            let previousMode = profile.renderMode ?? (profile.aliasModeEnabled ? .alias : .full)
            profile.renderMode = renderMode
            profile.aliasModeEnabled = renderMode == .alias
            profile.updatedAt = atlasTimestamp(from: now)

            try AtlasPrivacyProfileDBRecord(record: profile).save(db)
            if previousMode != renderMode {
                try writeSensitiveActionAudit(
                    db: db,
                    eventType: .privacyModeChanged,
                    surface: "settings",
                    protocolId: nil,
                    scopeKind: nil,
                    renderMode: renderMode,
                    manifestVersion: 1,
                    payloadJson: trustVaultPayload([
                        "previousRenderMode": previousMode.rawValue,
                        "nextRenderMode": renderMode.rawValue
                    ]),
                    now: now
                )
            }

            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func updateMascotSelection(_ mascotSelection: AtlasMascotSelection, now: Date) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            try writeAppSetting(db: db, key: "mascot_selection", value: mascotSelection.rawValue, now: now)
            try writeAppSetting(db: db, key: "mascot_selection_confirmed", value: "1", now: now)
            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func updateMascotNickname(_ nickname: String?, now: Date) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            try writeAppSetting(
                db: db,
                key: "mascot_nickname",
                value: atlasMascotSanitizedNickname(nickname),
                now: now
            )
            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func recordMascotEvolution(
        selection: AtlasMascotSelection,
        stage: AtlasMascotStage,
        earnedAt: Date,
        now: Date
    ) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            let currentUnlocks = try atlasReadMascotUnlockSnapshots(db: db)
            let currentStage = currentUnlocks.first(where: { $0.selection == selection })?.highestUnlockedStage ?? .stage1

            guard stage.rank > currentStage.rank else {
                return try buildSettingsSnapshot(
                    db: db,
                    healthKit: healthKit,
                    featureFlags: featureFlags
                )
            }

            try writeAppSetting(
                db: db,
                key: atlasMascotUnlockedStageSettingKey(for: selection),
                value: stage.rawValue,
                now: now
            )

            var history = try atlasReadMascotEvolutionHistory(db: db)
            if history.contains(where: { $0.selection == selection && $0.stage == stage }) == false {
                history.insert(
                    AtlasMascotEvolutionRecord(
                        selection: selection,
                        stage: stage,
                        earnedAt: atlasTimestamp(from: earnedAt)
                    ),
                    at: 0
                )
                try writeAppSetting(
                    db: db,
                    key: "mascot_evolution_history_json",
                    value: try atlasEncodeMascotEvolutionHistory(history),
                    now: now
                )
            }

            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func recordMascotMoment(
        _ moment: AtlasMascotMomentRecord,
        now: Date
    ) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            var moments = try atlasReadMascotMoments(db: db)
            if let eventKey = moment.eventKey,
               moments.contains(where: { $0.selection == moment.selection && $0.eventKey == eventKey }) {
                return try buildSettingsSnapshot(
                    db: db,
                    healthKit: healthKit,
                    featureFlags: featureFlags
                )
            }

            moments.insert(moment, at: 0)
            if moments.count > 60 {
                moments = Array(moments.prefix(60))
            }

            try writeAppSetting(
                db: db,
                key: "mascot_moments_json",
                value: try atlasEncodeMascotMoments(moments),
                now: now
            )

            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func recordMascotArchivedRecap(
        _ recap: AtlasMascotArchivedRecapRecord,
        now: Date
    ) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            var recaps = try atlasReadMascotArchivedRecaps(db: db)
            recaps.removeAll { $0.id == recap.id }
            recaps.insert(recap, at: 0)
            if recaps.count > 40 {
                recaps = Array(recaps.prefix(40))
            }

            try writeAppSetting(
                db: db,
                key: "mascot_archived_recaps_json",
                value: try atlasEncodeMascotArchivedRecaps(recaps),
                now: now
            )

            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func updateMascotRecapNotificationSettings(
        _ settings: AtlasMascotRecapNotificationSettings,
        now: Date
    ) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            try writeAppSetting(
                db: db,
                key: "mascot_recap_daily_enabled",
                value: settings.dailyEnabled ? "1" : "0",
                now: now
            )
            try writeAppSetting(
                db: db,
                key: "mascot_recap_weekly_enabled",
                value: settings.weeklyEnabled ? "1" : "0",
                now: now
            )

            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func updateWeeklyReviewReminderSettings(
        _ settings: AtlasWeeklyReviewReminderSettings,
        now: Date
    ) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            try writeAppSetting(
                db: db,
                key: "weekly_review_reminder_enabled",
                value: settings.enabled ? "1" : "0",
                now: now
            )

            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func saveWeeklyReviewActionPlan(
        _ plan: AtlasWeeklyReviewActionPlan,
        now: Date
    ) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            var plans = try atlasReadWeeklyReviewActionPlans(db: db)
            plans.removeAll { $0.id == plan.id }
            plans.insert(plan, at: 0)
            if plans.count > 16 {
                plans = Array(plans.prefix(16))
            }

            try writeAppSetting(
                db: db,
                key: "weekly_review_action_plans_json",
                value: try atlasEncodeWeeklyReviewActionPlans(plans),
                now: now
            )

            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func updateWeeklyReviewActionPlan(
        id: String,
        isCompleted: Bool?,
        isPinnedForNextWeek: Bool?,
        now: Date
    ) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            var plans = try atlasReadWeeklyReviewActionPlans(db: db)
            if let index = plans.firstIndex(where: { $0.id == id }) {
                if let isCompleted {
                    plans[index].isCompleted = isCompleted
                }
                if let isPinnedForNextWeek {
                    plans[index].isPinnedForNextWeek = isPinnedForNextWeek
                }
            }

            try writeAppSetting(
                db: db,
                key: "weekly_review_action_plans_json",
                value: try atlasEncodeWeeklyReviewActionPlans(plans),
                now: now
            )

            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func removeWeeklyReviewActionPlan(id: String, now: Date) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            let plans = try atlasReadWeeklyReviewActionPlans(db: db).filter { $0.id != id }
            try writeAppSetting(
                db: db,
                key: "weekly_review_action_plans_json",
                value: try atlasEncodeWeeklyReviewActionPlans(plans),
                now: now
            )

            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func updateSummarySettings(_ update: AtlasSummarySettingsUpdate, now: Date) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            let current = try readSummarySettings(db: db, featureFlags: featureFlags)

            let nextOnDeviceEnabled = update.onDeviceEnabled ?? current.onDeviceEnabled
            let nextExternalEnabled = update.externalProviderEnabled ?? current.externalProviderEnabled
            let consentAt = update.externalProviderConsentRecordedAt ?? current.externalProviderConsentRecordedAt

            try writeAppSetting(
                db: db,
                key: "summary_on_device_enabled",
                value: nextOnDeviceEnabled ? "1" : "0",
                now: now
            )
            try writeAppSetting(
                db: db,
                key: "summary_external_provider_enabled",
                value: nextExternalEnabled ? "1" : "0",
                now: now
            )
            try writeAppSetting(
                db: db,
                key: "summary_external_provider_consent_at",
                value: consentAt.map(atlasTimestamp(from:)),
                now: now
            )

            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func updateRetentionSettings(_ update: AtlasRetentionSettingsUpdate, now: Date) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            let current = try readRetentionSettings(db: db, featureFlags: featureFlags)
            let nextProgressEnabled = update.progressEnabled ?? current.progressEnabled
            let nextCompanionEnabled = (update.companionEnabled ?? current.companionEnabled) && nextProgressEnabled

            try writeAppSetting(
                db: db,
                key: "retention_progress_enabled",
                value: nextProgressEnabled ? "1" : "0",
                now: now
            )
            try writeAppSetting(
                db: db,
                key: "retention_companion_enabled",
                value: nextCompanionEnabled ? "1" : "0",
                now: now
            )

            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func updateHealthConnection(
        provider: AtlasHealthProviderKey,
        enabled: Bool,
        connected: Bool,
        lastSyncAt: Date?,
        lastError: String?,
        now: Date
    ) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            try ensureDefaultHealthConnection(db: db)
            try writeHealthConnection(
                db: db,
                provider: provider,
                enabled: enabled,
                connected: connected,
                lastSyncAt: lastSyncAt,
                lastError: lastError,
                now: now
            )

            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func updateRewardsSettings(_ update: AtlasRewardsSettingsUpdate, now: Date) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            let current = try readRewardsSettings(db: db)
            let nextEnabled = update.enabled ?? current.enabled
            let nextWorkoutGoal = max(update.weeklyWorkoutGoal ?? current.weeklyWorkoutGoal, 1)
            let nextSelfGoalTarget = max(update.weeklySelfGoalTarget ?? current.weeklySelfGoalTarget, 1)

            try writeAppSetting(
                db: db,
                key: "rewards_enabled",
                value: nextEnabled ? "1" : "0",
                now: now
            )
            try writeAppSetting(
                db: db,
                key: "rewards_weekly_workout_goal",
                value: String(nextWorkoutGoal),
                now: now
            )
            try writeAppSetting(
                db: db,
                key: "rewards_weekly_self_goal_target",
                value: String(nextSelfGoalTarget),
                now: now
            )

            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }

    public func updateLabsEnabled(_ enabled: Bool, now: Date) async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.write { db in
            try writeAppSetting(
                db: db,
                key: "labs_enabled",
                value: enabled ? "1" : "0",
                now: now
            )
            return try buildSettingsSnapshot(
                db: db,
                healthKit: healthKit,
                featureFlags: featureFlags
            )
        }
    }
}

public actor GRDBSharedProjectionWriter: SharedProjectionWriting {
    private let stack: AtlasDatabaseStack
    private let featureFlags: AtlasFeatureFlagState
    private let privacyFormatter: AtlasPrivacyFormatter

    init(
        stack: AtlasDatabaseStack,
        featureFlags: AtlasFeatureFlagState,
        privacyFormatter: AtlasPrivacyFormatter
    ) {
        self.stack = stack
        self.featureFlags = featureFlags
        self.privacyFormatter = privacyFormatter
    }

    public func writeImportedProjection(
        nextDue: AtlasSharedNextDueSnapshot?,
        timeline: [AtlasSharedTimelineSummary],
        labels: [AtlasSharedLabelProjection],
        quickActions: [AtlasSharedQuickAction],
        featureFlags: AtlasSharedFeatureFlagProjection
    ) async throws {
        let state = AtlasProjectionWriteState(
            nextDue: nextDue,
            timeline: timeline,
            labels: labels,
            quickActions: quickActions,
            featureFlags: featureFlags,
            extensionSnapshot: AtlasSharedExtensionProjectionSnapshot(
                generatedAt: atlasTimestamp(from: Date()),
                renderMode: .discreet,
                nextDue: nextDue,
                quickActions: quickActions,
                lowStock: AtlasSharedLowStockSnapshot(
                    lowStockCount: 0,
                    procurementReviewCount: 0,
                    summary: "No low-stock items in the current projection.",
                    items: [],
                    updatedAt: atlasTimestamp(from: Date())
                ),
                mascot: nil,
                watchCompanion: buildWatchCompanionProjectionSnapshot(
                    referenceDate: Date(),
                    nextDue: nextDue,
                    quickActions: quickActions,
                    overdueCount: nextDue?.overdueCount ?? 0,
                    upcomingCount: max(quickActions.count - min(nextDue == nil ? 0 : 1, quickActions.count), 0)
                ),
                featureFlags: featureFlags
            )
        )
        try await writeProjectionState(state)
    }

    public func refreshProjection(referenceDate: Date) async throws {
        let state = try await stack.canonical.read { db in
            try buildProjectionWriteState(
                db: db,
                referenceDate: referenceDate,
                privacyFormatter: privacyFormatter,
                featureFlags: featureFlags
            )
        }
        try await writeProjectionState(state)
    }

    public func loadProjectionDebugState() async throws -> AtlasProjectionDebugState {
        let extensionSnapshot = try await loadExtensionProjectionSnapshot()
        return try await stack.projections.read { db in
            let nextDue = try AtlasNextDueProjectionDBRecord.fetchOne(db).map(\.domain)
            let timeline = try AtlasTimelineProjectionDBRecord.fetchAll(db).map(\.domain)
            let labels = try AtlasLabelProjectionDBRecord.fetchAll(db).map(\.domain)
            let quickActions = try AtlasQuickActionProjectionDBRecord.fetchAll(db).map(\.domain)
            let featureFlagRows = try AtlasFeatureFlagProjectionDBRecord.fetchAll(db)
            var state = AtlasFeatureFlagState(
                nativeWidgets: true,
                nativeIntents: true,
                trustVaultShell: true,
                importShell: true,
                reviewMode: true,
                liveReviewSessions: false,
                boundedSummaries: true,
                externalSummaryProviders: false,
                calmRetention: true,
                companionSkin: true
            )

            for row in featureFlagRows {
                guard let flag = AtlasFeatureFlag(rawValue: row.flag) else {
                    continue
                }

                switch flag {
                case .nativeWidgets:
                    state.nativeWidgets = row.isEnabled
                case .nativeIntents:
                    state.nativeIntents = row.isEnabled
                case .trustVaultShell:
                    state.trustVaultShell = row.isEnabled
                case .importShell:
                    state.importShell = row.isEnabled
                case .reviewMode:
                    state.reviewMode = row.isEnabled
                case .liveReviewSessions:
                    state.liveReviewSessions = row.isEnabled
                case .boundedSummaries, .externalSummaryProviders:
                    continue
                case .calmRetention, .companionSkin:
                    continue
                }
            }

            return AtlasProjectionDebugState(
                nextDue: nextDue,
                timeline: timeline,
                labels: labels,
                quickActions: quickActions,
                featureFlags: AtlasSharedFeatureFlagProjection(flags: state),
                extensionSnapshot: extensionSnapshot
            )
        }
    }

    public func loadExtensionProjectionSnapshot() async throws -> AtlasSharedExtensionProjectionSnapshot? {
        guard let url = stack.locations?.extensionProjectionSnapshotURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(AtlasSharedExtensionProjectionSnapshot.self, from: data)
    }

    nonisolated public func projectionDescription() -> String {
        "Extensions read privacy-safe app-group projections, never the canonical database."
    }

    private func writeProjectionState(_ state: AtlasProjectionWriteState) async throws {
        try await stack.projections.write { db in
            try db.execute(sql: "DELETE FROM next_due_snapshot")
            try db.execute(sql: "DELETE FROM widget_timeline_summary")
            try db.execute(sql: "DELETE FROM label_projection")
            try db.execute(sql: "DELETE FROM quick_action_projection")
            try db.execute(sql: "DELETE FROM feature_flag_projection")

            if let nextDue = state.nextDue {
                try AtlasNextDueProjectionDBRecord(snapshot: nextDue).insert(db)
            }

            for item in state.timeline {
                try AtlasTimelineProjectionDBRecord(summary: item).insert(db)
            }

            for item in state.labels {
                try AtlasLabelProjectionDBRecord(projection: item).insert(db)
            }

            for item in state.quickActions {
                try AtlasQuickActionProjectionDBRecord(projection: item).insert(db)
            }

            let allFlags: [(AtlasFeatureFlag, Bool)] = [
                (.nativeWidgets, state.featureFlags.flags.nativeWidgets),
                (.nativeIntents, state.featureFlags.flags.nativeIntents),
                (.trustVaultShell, state.featureFlags.flags.trustVaultShell),
                (.importShell, state.featureFlags.flags.importShell),
                (.reviewMode, state.featureFlags.flags.reviewMode),
                (.liveReviewSessions, state.featureFlags.flags.liveReviewSessions),
                (.boundedSummaries, state.featureFlags.flags.boundedSummaries),
                (.externalSummaryProviders, state.featureFlags.flags.externalSummaryProviders),
                (.calmRetention, state.featureFlags.flags.calmRetention),
                (.companionSkin, state.featureFlags.flags.companionSkin)
            ]

            for flag in allFlags {
                try AtlasFeatureFlagProjectionDBRecord(flag: flag.0.rawValue, isEnabled: flag.1).insert(db)
            }
        }
        if let url = stack.locations?.extensionProjectionSnapshotURL {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            let data = try encoder.encode(state.extensionSnapshot)
            try data.write(to: url, options: .atomic)
        }
    }
}

private struct AtlasProjectionWriteState {
    var nextDue: AtlasSharedNextDueSnapshot?
    var timeline: [AtlasSharedTimelineSummary]
    var labels: [AtlasSharedLabelProjection]
    var quickActions: [AtlasSharedQuickAction]
    var featureFlags: AtlasSharedFeatureFlagProjection
    var extensionSnapshot: AtlasSharedExtensionProjectionSnapshot
}

private func buildProjectionWriteState(
    db: Database,
    referenceDate: Date,
    privacyFormatter: AtlasPrivacyFormatter,
    featureFlags: AtlasFeatureFlagState
) throws -> AtlasProjectionWriteState {
    let context = try loadCoreLoopContext(db: db)
    let privacyProfile = try AtlasPrivacyProfileDBRecord.fetchOne(db)?.domain ?? .default()
    let renderMode = privacyFormatter.renderMode(for: privacyProfile)
    let pending = context.pendingOccurrences.values
        .flatMap { $0 }
        .map { occurrence in
            buildScheduledOccurrence(
                occurrence: occurrence,
                context: context,
                now: referenceDate
            )
        }
        .sorted { $0.scheduledAt < $1.scheduledAt }
    let overdue = pending.filter { $0.state == .overdue }
    let dueAndUpcoming = pending.filter { $0.state == .due || $0.state == .upcoming }
    let primaryOccurrence = overdue.first ?? dueAndUpcoming.first

    let nextDue = primaryOccurrence.map { occurrence in
        AtlasSharedNextDueSnapshot(
            occurrenceID: occurrence.id,
            protocolID: occurrence.protocolID,
            displayTitle: privacyFormatter.title(
                canonical: occurrence.canonicalTitle,
                alias: occurrence.aliasTitle,
                mode: renderMode
            ),
            dueLabel: relativeDueLabel(for: occurrence.scheduledAt),
            scheduledAt: atlasTimestamp(from: occurrence.scheduledAt),
            state: occurrence.state,
            statusSummary: sharedProjectionStatusSummary(
                primaryOccurrence: occurrence,
                overdueCount: overdue.count
            ),
            overdueCount: overdue.count
        )
    }

    let logs = try AtlasLogEventDBRecord
        .order(Column("logged_at").desc)
        .fetchAll(db)
        .map(\.domain)
    let timeline = logs.prefix(10).compactMap { event -> AtlasSharedTimelineSummary? in
        guard let protocolRecord = context.protocols[event.protocolId] else {
            return nil
        }
        let alias = context.aliases[event.protocolId]?.aliasLabel
        return AtlasSharedTimelineSummary(
            id: event.id,
            protocolID: event.protocolId,
            displayTitle: privacyFormatter.title(
                canonical: protocolRecord.name,
                alias: alias,
                mode: renderMode
            ),
            summary: privacyFormatter.timelineSummary(
                eventType: event.eventType,
                canonical: protocolRecord.name,
                alias: alias,
                mode: renderMode
            ),
            recordedAt: event.loggedAt
        )
    }

    let labels = context.protocols.values
        .sorted { $0.createdAt > $1.createdAt }
        .map { protocolRecord in
            AtlasSharedLabelProjection(
                id: protocolRecord.id,
                canonicalTitle: protocolRecord.name,
                aliasTitle: context.aliases[protocolRecord.id]?.aliasLabel,
                discreetTitle: privacyFormatter.title(
                    canonical: protocolRecord.name,
                    alias: context.aliases[protocolRecord.id]?.aliasLabel,
                    mode: .discreet
                )
            )
        }

    let quickActionOccurrences = Array((overdue + dueAndUpcoming).uniquePreservingOrder(by: \.id).prefix(3))
    let quickActions = quickActionOccurrences.map { occurrence in
        AtlasSharedQuickAction(
            id: "quick_\(occurrence.id)",
            protocolID: occurrence.protocolID,
            occurrenceID: occurrence.id,
            title: privacyFormatter.title(
                canonical: occurrence.canonicalTitle,
                alias: occurrence.aliasTitle,
                mode: renderMode
            ),
            dueLabel: relativeDueLabel(for: occurrence.scheduledAt),
            state: occurrence.state
        )
    }

    let inventorySnapshot = try buildInventorySnapshot(db: db, referenceDate: referenceDate)
    let lowStockItems = buildLowStockProjectionItems(
        inventorySnapshot: inventorySnapshot,
        renderMode: renderMode,
        privacyFormatter: privacyFormatter
    )
    let lowStockSnapshot = AtlasSharedLowStockSnapshot(
        lowStockCount: inventorySnapshot.lowStockCount,
        procurementReviewCount: inventorySnapshot.procurementReviewCount,
        summary: lowStockSummary(for: inventorySnapshot.lowStockCount),
        items: lowStockItems,
        updatedAt: atlasTimestamp(from: referenceDate)
    )
    let featureFlagProjection = AtlasSharedFeatureFlagProjection(flags: featureFlags)
    let mascotSnapshot = try buildMascotProjection(db: db, referenceDate: referenceDate)
    let watchCompanionSnapshot = buildWatchCompanionProjectionSnapshot(
        referenceDate: referenceDate,
        nextDue: nextDue,
        quickActions: quickActions,
        overdueCount: overdue.count,
        upcomingCount: dueAndUpcoming.count
    )

    return AtlasProjectionWriteState(
        nextDue: nextDue,
        timeline: timeline,
        labels: labels,
        quickActions: quickActions,
        featureFlags: featureFlagProjection,
        extensionSnapshot: AtlasSharedExtensionProjectionSnapshot(
            generatedAt: atlasTimestamp(from: referenceDate),
            renderMode: renderMode,
            nextDue: nextDue,
            quickActions: quickActions,
            lowStock: lowStockSnapshot,
            mascot: mascotSnapshot,
            watchCompanion: watchCompanionSnapshot,
            featureFlags: featureFlagProjection
        )
    )
}

private func buildWatchCompanionProjectionSnapshot(
    referenceDate: Date,
    nextDue: AtlasSharedNextDueSnapshot?,
    quickActions: [AtlasSharedQuickAction],
    overdueCount: Int,
    upcomingCount: Int
) -> AtlasSharedWatchCompanionSnapshot {
    let headline: String
    let summary: String
    let recoverySummary: String?

    if overdueCount > 0 {
        headline = "Recovery comes first on wrist."
        summary = "Atlas keeps the next recovery move visible so you can clear drift before touching later plans."
        recoverySummary = "\(overdueCount) overdue item\(overdueCount == 1 ? "" : "s") still need attention."
    } else if let nextDue {
        headline = "One next due action is ready."
        summary = "\(nextDue.displayTitle) is the current anchor, with later items intentionally pushed into the background."
        recoverySummary = nil
    } else {
        headline = "Atlas is quiet right now."
        summary = "There is nothing due at the moment, so the watch companion stays focused on quick context capture and recovery readiness."
        recoverySummary = nil
    }

    let nextDueDetail = nextDue.map { "\($0.dueLabel) • \($0.statusSummary)" }
    let laterCount = max(upcomingCount - (nextDue == nil ? 0 : 1), 0)
    let adjustedSummary: String
    if laterCount > 0 {
        adjustedSummary = summary + " \(laterCount) later item\(laterCount == 1 ? "" : "s") can wait."
    } else {
        adjustedSummary = summary
    }

    return AtlasSharedWatchCompanionSnapshot(
        generatedAt: atlasTimestamp(from: referenceDate),
        headline: headline,
        summary: adjustedSummary,
        nextDueTitle: nextDue?.displayTitle,
        nextDueDetail: nextDueDetail,
        recoverySummary: recoverySummary,
        quickContextShortcuts: AtlasWatchCompanionContextShortcut.allCases
    )
}

private func buildMascotProjection(
    db: Database,
    referenceDate: Date
) throws -> AtlasSharedMascotSnapshot? {
    let rewardsSnapshot = try buildRewardsSnapshot(db: db, referenceDate: referenceDate)
    guard rewardsSnapshot.settings.enabled else {
        return nil
    }

    let onboardingDraft = try readMascotProjectionOnboardingDraft(db: db)
    let selectionRaw = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'mascot_selection'"
    )
    let selectionConfirmedRaw = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'mascot_selection_confirmed'"
    )
    let nicknameRaw = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'mascot_nickname'"
    )
    let selection = selectionRaw.flatMap(AtlasMascotSelection.init(rawValue:))
        ?? onboardingDraft?.profile.mascotSelection
        ?? atlasInferredMascotSelection(from: onboardingDraft?.profile.gender)
        ?? .aetherion
    guard selectionConfirmedRaw == "1" else {
        return nil
    }

    let stage = AtlasMascotMilestone.stage(for: rewardsSnapshot.totalPoints)
    let nextThresholdPoints = AtlasMascotMilestone.nextThreshold(after: stage)
    let nextFormName = nextThresholdPoints.map { _ in
        switch stage {
        case .stage1:
            return selection.stage2Title
        case .stage2:
            return selection.stage3Title
        case .stage3:
            return selection.stage3Title
        }
    }
    let currentFormName = selection.title(for: stage)
    let nickname = atlasMascotSanitizedNickname(nicknameRaw ?? onboardingDraft?.profile.mascotNickname)
    let displayName = atlasMascotDisplayName(selection: selection, stage: stage, nickname: nickname)
    let milestoneHeadline: String
    let progressLabel: String
    if let nextThresholdPoints, let nextFormName {
        milestoneHeadline = "\(currentFormName) evolves into \(nextFormName) at \(mascotPointLabel(nextThresholdPoints))."
        progressLabel = "\(max(nextThresholdPoints - rewardsSnapshot.totalPoints, 0)) points to \(nextFormName)."
    } else {
        milestoneHeadline = "\(currentFormName) has reached its final evolution."
        progressLabel = "Final form unlocked."
    }

    let history = try atlasReadMascotEvolutionHistory(db: db)
        .filter { $0.selection == selection }
    let latestMoment = try atlasReadMascotMoments(db: db)
        .first(where: { $0.selection == selection })
    let pose = atlasMascotSharedPose(
        rewardsSnapshot: rewardsSnapshot,
        latestMoment: latestMoment
    )
    let reaction = atlasMascotReactionSummary(
        selection: selection,
        nickname: nickname,
        rewardsSnapshot: rewardsSnapshot,
        history: history
    )
    let statusLine = atlasMascotStatusLine(
        selection: selection,
        nickname: nickname,
        rewardsSnapshot: rewardsSnapshot
    )

    return AtlasSharedMascotSnapshot(
        selection: selection,
        nickname: nickname,
        displayName: displayName,
        stage: stage,
        pose: pose,
        currentFormName: currentFormName,
        nextFormName: nextThresholdPoints == nil ? nil : nextFormName,
        nextThresholdPoints: nextThresholdPoints,
        totalPoints: rewardsSnapshot.totalPoints,
        milestoneHeadline: milestoneHeadline,
        progressLabel: progressLabel,
        statusLine: statusLine,
        reactionTitle: reaction?.title,
        reactionSymbolName: reaction?.symbolName,
        lastEvolution: history.first,
        latestMomentTitle: latestMoment?.title,
        latestMomentDetail: latestMoment?.detail,
        latestMomentSymbolName: latestMoment?.symbolName,
        latestMomentRecordedAt: latestMoment?.recordedAt
    )
}

private func mascotPointLabel(_ points: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return "\(formatter.string(from: NSNumber(value: points)) ?? "\(points)") points"
}

private func readMascotProjectionOnboardingDraft(db: Database) throws -> AtlasOnboardingDraft? {
    guard let json = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'onboarding_draft_json'"
    ) else {
        return nil
    }
    return try? JSONDecoder().decode(AtlasOnboardingDraft.self, from: Data(json.utf8))
}

private func sharedProjectionStatusSummary(
    primaryOccurrence: AtlasScheduledOccurrence,
    overdueCount: Int
) -> String {
    if overdueCount > 1 {
        return "\(overdueCount) overdue"
    }

    switch primaryOccurrence.state {
    case .overdue:
        return "Overdue"
    case .due:
        return "Due now"
    case .upcoming:
        return "Up next"
    case .completed:
        return "Completed"
    case .skipped:
        return "Skipped"
    case .superseded:
        return "Updated"
    }
}

private func buildLowStockProjectionItems(
    inventorySnapshot: AtlasInventorySnapshot,
    renderMode: AtlasPrivacyRenderMode,
    privacyFormatter: AtlasPrivacyFormatter
) -> [AtlasSharedLowStockItem] {
    let vialItems = inventorySnapshot.vials
        .filter { $0.isLowStock && $0.archivedAt == nil }
        .map { vial in
            AtlasSharedLowStockItem(
                id: vial.id,
                kind: .vial,
                displayTitle: privacyFormatter.vialTitle(canonical: vial.label, mode: renderMode),
                detail: vial.lowStockLabel ?? vial.projectedDepletionLabel ?? vial.quantityLabel
            )
        }
    let consumableItems = inventorySnapshot.consumables
        .filter { $0.isLowStock && $0.archivedAt == nil }
        .map { consumable in
            AtlasSharedLowStockItem(
                id: consumable.id,
                kind: .consumable,
                displayTitle: privacyFormatter.consumableTitle(
                    canonical: consumable.name,
                    category: consumable.category,
                    mode: renderMode
                ),
                detail: lowStockDetail(for: consumable)
            )
        }

    return Array((vialItems + consumableItems).prefix(4))
}

private func lowStockSummary(for count: Int) -> String {
    switch count {
    case 0:
        return "Inventory looks steady."
    case 1:
        return "1 item is below threshold."
    default:
        return "\(count) items are below threshold."
    }
}

private func lowStockDetail(for consumable: AtlasConsumableSummary) -> String {
    if consumable.needsProcurementReview {
        return consumable.procurementStatusLabel ?? "Procurement review now."
    }

    return consumable.procurementStatusLabel
        ?? consumable.lowStockLabel
        ?? consumable.projectedDepletionLabel
        ?? consumable.quantityLabel
}

private extension Array {
    func uniquePreservingOrder<ID: Hashable>(by keyPath: KeyPath<Element, ID>) -> [Element] {
        var seen: Set<ID> = []
        return filter { element in
            let id = element[keyPath: keyPath]
            return seen.insert(id).inserted
        }
    }
}
