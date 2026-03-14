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

    init(
        stack: AtlasDatabaseStack,
        healthKit: any HealthKitManaging
    ) {
        self.stack = stack
        self.healthKit = healthKit
    }

    public func currentSettingsSnapshot() async throws -> AtlasSettingsSnapshot {
        try await stack.canonical.read { db in
            try buildSettingsSnapshot(db: db, healthKit: healthKit)
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

            return try buildSettingsSnapshot(db: db, healthKit: healthKit)
        }
    }
}

public actor GRDBSharedProjectionWriter: SharedProjectionWriting {
    private let stack: AtlasDatabaseStack

    init(stack: AtlasDatabaseStack) {
        self.stack = stack
    }

    public func writeImportedProjection(
        nextDue: AtlasSharedNextDueSnapshot?,
        timeline: [AtlasSharedTimelineSummary],
        labels: [AtlasSharedLabelProjection],
        quickActions: [AtlasSharedQuickAction],
        featureFlags: AtlasSharedFeatureFlagProjection
    ) async throws {
        try await stack.projections.write { db in
            try db.execute(sql: "DELETE FROM next_due_snapshot")
            try db.execute(sql: "DELETE FROM widget_timeline_summary")
            try db.execute(sql: "DELETE FROM label_projection")
            try db.execute(sql: "DELETE FROM quick_action_projection")
            try db.execute(sql: "DELETE FROM feature_flag_projection")

            if let nextDue {
                try AtlasNextDueProjectionDBRecord(snapshot: nextDue).insert(db)
            }

            for item in timeline {
                try AtlasTimelineProjectionDBRecord(summary: item).insert(db)
            }

            for item in labels {
                try AtlasLabelProjectionDBRecord(projection: item).insert(db)
            }

            for item in quickActions {
                try AtlasQuickActionProjectionDBRecord(projection: item).insert(db)
            }

            let allFlags: [(AtlasFeatureFlag, Bool)] = [
                (.nativeWidgets, featureFlags.flags.nativeWidgets),
                (.nativeIntents, featureFlags.flags.nativeIntents),
                (.trustVaultShell, featureFlags.flags.trustVaultShell),
                (.importShell, featureFlags.flags.importShell),
                (.reviewMode, featureFlags.flags.reviewMode),
                (.liveReviewSessions, featureFlags.flags.liveReviewSessions)
            ]

            for flag in allFlags {
                try AtlasFeatureFlagProjectionDBRecord(flag: flag.0.rawValue, isEnabled: flag.1).insert(db)
            }
        }
    }

    public func loadProjectionDebugState() async throws -> AtlasProjectionDebugState {
        try await stack.projections.read { db in
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
                liveReviewSessions: false
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
                }
            }

            return AtlasProjectionDebugState(
                nextDue: nextDue,
                timeline: timeline,
                labels: labels,
                quickActions: quickActions,
                featureFlags: AtlasSharedFeatureFlagProjection(flags: state)
            )
        }
    }

    nonisolated public func projectionDescription() -> String {
        "Extensions read privacy-safe app-group projections, never the canonical database."
    }
}
