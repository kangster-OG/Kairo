import AtlasDomain
import AtlasPrivacy
import GRDB
import Foundation

private enum AtlasReviewModeError: LocalizedError {
    case liveSessionsDisabled
    case invalidReviewPack

    var errorDescription: String? {
        switch self {
        case .liveSessionsDisabled:
            return "Live review sessions are not enabled in this build."
        case .invalidReviewPack:
            return "The selected review pack could not be opened."
        }
    }
}

struct AtlasReviewSessionDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "review_sessions"

    var id: String
    var title: String
    var scopeKind: AtlasReviewScopeKind
    var deliveryKind: AtlasReviewDeliveryKind
    var renderMode: AtlasPrivacyRenderMode
    var rowCount: Int
    var summary: String
    var sourceDescription: String
    var workspaceJson: String
    var summaryURL: String?
    var packURL: String?
    var expiresAt: String?
    var revokedAt: String?
    var canRevoke: Bool
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case scopeKind = "scope_kind"
        case deliveryKind = "delivery_kind"
        case renderMode = "render_mode"
        case rowCount = "row_count"
        case summary
        case sourceDescription = "source_description"
        case workspaceJson = "workspace_json"
        case summaryURL = "summary_url"
        case packURL = "pack_url"
        case expiresAt = "expires_at"
        case revokedAt = "revoked_at"
        case canRevoke = "can_revoke"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var workspace: AtlasReviewWorkspace? {
        guard let data = workspaceJson.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(AtlasReviewWorkspace.self, from: data)
    }
}

private struct AtlasReviewPackManifest: Codable, Equatable {
    var format: String = "atlas_review_pack"
    var version: Int = 1
    var generatedAt: String
    var source: String = "atlas-ios-native"
    var scopeKind: AtlasReviewScopeKind
    var renderMode: AtlasPrivacyRenderMode
    var deliveryKind: AtlasReviewDeliveryKind
    var rowCount: Int
    var expiresAt: String?
    var readOnly: Bool = true
}

private struct AtlasReviewPackEnvelope: Codable, Equatable {
    var manifest: AtlasReviewPackManifest
    var workspace: AtlasReviewWorkspace
    var bundle: AtlasExportBundle
}

public struct GRDBReviewModeRepository: ReviewModeRepository, Sendable {
    let stack: AtlasDatabaseStack
    let featureFlags: AtlasFeatureFlagState
    let privacyFormatter: AtlasPrivacyFormatter

    init(
        stack: AtlasDatabaseStack,
        featureFlags: AtlasFeatureFlagState,
        privacyFormatter: AtlasPrivacyFormatter
    ) {
        self.stack = stack
        self.featureFlags = featureFlags
        self.privacyFormatter = privacyFormatter
    }

    public func fetchOwnerSnapshot(now: Date) async throws -> AtlasReviewOwnerSnapshot {
        try await stack.canonical.read { db in
            let rows = try AtlasReviewSessionDBRecord
                .order(Column("created_at").desc)
                .fetchAll(db)

            return AtlasReviewOwnerSnapshot(
                sessions: rows.map { reviewSessionSummary(from: $0, now: now) },
                liveReviewEnabled: featureFlags.liveReviewSessions
            )
        }
    }

    public func createReview(_ request: AtlasReviewRequest, now: Date) async throws -> AtlasReviewCreationResult {
        guard request.deliveryKind == .staticPack || featureFlags.liveReviewSessions else {
            throw AtlasReviewModeError.liveSessionsDisabled
        }

        let canonical = try await stack.canonical.read { db in
            try sortExportSnapshot(canonicalSnapshot(from: db))
        }
        let snapshot = reviewSnapshot(from: canonical, request: request, now: now)
        let workspace = buildReviewWorkspace(
            from: snapshot,
            request: request,
            createdAt: now,
            sourceDescription: request.deliveryKind == .staticPack ? "Static local review pack" : "Live review session"
        )
        let title = reviewTitle(for: request.scopeKind)

        let exportBase = try reviewExportDirectoryURL()
        let timestamp = sanitizedFileTimestamp(atlasTimestamp(from: now))
        let directoryURL = exportBase.appendingPathComponent("atlas-review-\(timestamp)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let summaryURL = directoryURL.appendingPathComponent("review-summary.md")
        let packURL = directoryURL.appendingPathComponent("atlas-review-pack.json")

        try buildReviewSummaryMarkdown(workspace: workspace).write(
            to: summaryURL,
            atomically: true,
            encoding: .utf8
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(
            AtlasReviewPackEnvelope(
                manifest: AtlasReviewPackManifest(
                    generatedAt: atlasTimestamp(from: now),
                    scopeKind: request.scopeKind,
                    renderMode: workspace.renderMode,
                    deliveryKind: request.deliveryKind,
                    rowCount: workspace.rowCount,
                    expiresAt: request.expiresAt.map(atlasTimestamp)
                ),
                workspace: workspace,
                bundle: AtlasExportBundle(
                    manifest: AtlasExportManifest(
                        format: "atlas_review_pack",
                        version: 1,
                        generatedAt: atlasTimestamp(from: now),
                        source: "atlas-ios-native"
                    ),
                    snapshot: snapshot
                )
            )
        ).write(to: packURL, options: [.atomic])

        let workspaceJson = String(
            data: try JSONEncoder().encode(workspace),
            encoding: .utf8
        ) ?? "{}"
        let record = AtlasReviewSessionDBRecord(
            id: "review_\(UUID().uuidString.lowercased())",
            title: title,
            scopeKind: request.scopeKind,
            deliveryKind: request.deliveryKind,
            renderMode: workspace.renderMode,
            rowCount: workspace.rowCount,
            summary: workspace.summary,
            sourceDescription: workspace.sourceDescription,
            workspaceJson: workspaceJson,
            summaryURL: summaryURL.path,
            packURL: packURL.path,
            expiresAt: request.expiresAt.map(atlasTimestamp),
            revokedAt: nil,
            canRevoke: request.deliveryKind == .liveSession,
            createdAt: atlasTimestamp(from: now),
            updatedAt: atlasTimestamp(from: now)
        )

        try await stack.canonical.write { db in
            try record.insert(db)
            try writeSensitiveActionAudit(
                db: db,
                eventType: .reviewPackCreated,
                surface: "review_mode",
                protocolId: request.protocolID,
                scopeKind: request.scopeKind.rawValue,
                renderMode: workspace.renderMode,
                manifestVersion: 1,
                payloadJson: trustVaultPayload([
                    "deliveryKind": request.deliveryKind.rawValue,
                    "rowCount": "\(workspace.rowCount)",
                    "expiresAt": request.expiresAt.map(atlasTimestamp) ?? ""
                ]),
                now: now
            )
        }

        return AtlasReviewCreationResult(
            session: reviewSessionSummary(from: record, now: now),
            workspace: workspace,
            summaryURL: summaryURL,
            packURL: packURL,
            manifestVersion: 1
        )
    }

    public func loadWorkspace(from fileURL: URL, now: Date) async throws -> AtlasReviewWorkspace {
        let data = try Data(contentsOf: fileURL)
        let envelope = try JSONDecoder().decode(AtlasReviewPackEnvelope.self, from: data)
        guard envelope.manifest.format == "atlas_review_pack", envelope.workspace.readOnly else {
            throw AtlasReviewModeError.invalidReviewPack
        }
        _ = now
        return envelope.workspace
    }

    public func revokeReviewSession(id: String, now: Date) async throws -> AtlasReviewOwnerSnapshot {
        try await stack.canonical.write { db in
            guard var record = try AtlasReviewSessionDBRecord.fetchOne(db, key: id) else {
                return AtlasReviewOwnerSnapshot(
                    sessions: [],
                    liveReviewEnabled: featureFlags.liveReviewSessions
                )
            }

            record.revokedAt = atlasTimestamp(from: now)
            record.updatedAt = atlasTimestamp(from: now)
            try record.save(db)

            let rows = try AtlasReviewSessionDBRecord
                .order(Column("created_at").desc)
                .fetchAll(db)

            return AtlasReviewOwnerSnapshot(
                sessions: rows.map { reviewSessionSummary(from: $0, now: now) },
                liveReviewEnabled: featureFlags.liveReviewSessions
            )
        }
    }
}

private extension GRDBReviewModeRepository {
    func reviewSnapshot(
        from snapshot: AtlasExportSnapshot,
        request: AtlasReviewRequest,
        now: Date
    ) -> AtlasExportSnapshot {
        let renderMode: AtlasPrivacyRenderMode = request.aliasModeEnabled ? .alias : .full
        let range30 = AtlasDateRange(
            start: Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now,
            end: now
        )

        switch request.scopeKind {
        case .currentProtocol:
            return selectiveShareSnapshot(
                from: snapshot,
                request: AtlasSelectiveShareRequest(
                    scopeKind: .currentProtocolOnly,
                    renderMode: renderMode,
                    protocolID: request.protocolID
                ),
                now: now
            )
        case .selectedProtocols:
            return selectiveShareSnapshot(
                from: snapshot,
                request: AtlasSelectiveShareRequest(
                    scopeKind: .customDateRange,
                    renderMode: renderMode,
                    protocolIDs: request.protocolIDs,
                    dateRange: request.dateRange ?? range30,
                    include: [.summary, .logs]
                ),
                now: now
            )
        case .last30Days:
            return selectiveShareSnapshot(
                from: snapshot,
                request: AtlasSelectiveShareRequest(
                    scopeKind: .last30DaysLogs,
                    renderMode: renderMode
                ),
                now: now
            )
        case .symptomsOnly:
            return selectiveShareSnapshot(
                from: snapshot,
                request: AtlasSelectiveShareRequest(
                    scopeKind: .symptomsOnly,
                    renderMode: renderMode,
                    dateRange: request.dateRange ?? range30
                ),
                now: now
            )
        case .inventoryOnly:
            return selectiveShareSnapshot(
                from: snapshot,
                request: AtlasSelectiveShareRequest(
                    scopeKind: .inventoryOnly,
                    renderMode: renderMode,
                    protocolID: request.protocolID
                ),
                now: now
            )
        case .summaryOnly:
            return selectiveShareSnapshot(
                from: snapshot,
                request: AtlasSelectiveShareRequest(
                    scopeKind: .summaryOnly,
                    renderMode: renderMode,
                    protocolID: request.protocolID
                ),
                now: now
            )
        case .customDateRange:
            return selectiveShareSnapshot(
                from: snapshot,
                request: AtlasSelectiveShareRequest(
                    scopeKind: .customDateRange,
                    renderMode: renderMode,
                    protocolIDs: request.protocolIDs,
                    dateRange: request.dateRange ?? range30,
                    include: [.summary, .logs, .symptoms, .inventory]
                ),
                now: now
            )
        }
    }

    func buildReviewWorkspace(
        from snapshot: AtlasExportSnapshot,
        request: AtlasReviewRequest,
        createdAt: Date,
        sourceDescription: String
    ) -> AtlasReviewWorkspace {
        let renderMode: AtlasPrivacyRenderMode = request.aliasModeEnabled ? .alias : .full
        let datasets = selectiveShareDatasetSummaries(snapshot: snapshot).map {
            AtlasReviewDatasetSummary(dataset: $0.dataset, rowCount: $0.rowCount)
        }
        let sections = [
            AtlasReviewSection(
                title: "Overview",
                lines: reviewOverviewLines(request: request, renderMode: renderMode, createdAt: createdAt)
            ),
            AtlasReviewSection(
                title: "Protocol summary",
                lines: snapshot.protocols.prefix(6).map { protocolRecord in
                    let cadence = snapshot.protocolRules.first(where: { $0.protocolId == protocolRecord.id }).map(reviewCadenceLine(for:)) ?? "Scheduled routine"
                    let dose = [protocolRecord.doseAmount.map { "\($0)" }, protocolRecord.doseUnit].compactMap { $0 }.joined(separator: " ")
                    return [protocolRecord.name, cadence, dose.reviewNilIfBlank].compactMap { $0 }.joined(separator: " • ")
                }
            ),
            AtlasReviewSection(
                title: "Timeline summary",
                lines: reviewTimelineLines(from: snapshot)
            ),
            AtlasReviewSection(
                title: "Context, symptoms, and metrics",
                lines: reviewHealthLines(from: snapshot)
            ),
            AtlasReviewSection(
                title: "Inventory summary",
                lines: snapshot.vials.prefix(3).map { vial in
                    let quantity = "\(vial.remainingQuantity.formatted(.number.precision(.fractionLength(0...2)))) \(vial.quantityUnit)"
                    return "\(vial.label): \(quantity)"
                } + snapshot.consumables.prefix(3).map { consumable in
                    let quantity = "\(consumable.quantityOnHand.formatted(.number.precision(.fractionLength(0...2)))) \(consumable.unit)"
                    return "\(consumable.name): \(quantity)"
                }
            )
        ]
        .filter { $0.lines.isEmpty == false }

        return AtlasReviewWorkspace(
            scopeKind: request.scopeKind,
            renderMode: renderMode,
            readOnly: true,
            summary: "Read-only review pack for \(reviewScopeTitle(request.scopeKind).lowercased()) with \(snapshotRowCount(snapshot)) row(s).",
            sections: sections,
            datasets: datasets,
            rowCount: snapshotRowCount(snapshot),
            createdAt: createdAt,
            expiresAt: request.expiresAt,
            sourceDescription: sourceDescription
        )
    }

    func reviewSessionSummary(from record: AtlasReviewSessionDBRecord, now: Date) -> AtlasReviewSessionSummary {
        let status: AtlasReviewSessionStatus
        if record.revokedAt != nil {
            status = .revoked
        } else if let expiresAt = record.expiresAt, atlasDate(from: expiresAt) < now {
            status = .expired
        } else {
            status = .active
        }

        return AtlasReviewSessionSummary(
            id: record.id,
            title: record.title,
            scopeKind: record.scopeKind,
            deliveryKind: record.deliveryKind,
            renderMode: record.renderMode,
            rowCount: record.rowCount,
            createdAt: atlasDate(from: record.createdAt),
            expiresAt: record.expiresAt.map(atlasDate),
            status: status,
            canRevoke: record.canRevoke,
            summaryURL: record.summaryURL.map(URL.init(fileURLWithPath:)),
            packURL: record.packURL.map(URL.init(fileURLWithPath:)),
            summary: record.summary
        )
    }

    func reviewOverviewLines(
        request: AtlasReviewRequest,
        renderMode: AtlasPrivacyRenderMode,
        createdAt: Date
    ) -> [String] {
        var lines = [
            reviewScopeTitle(request.scopeKind),
            "Render mode: \(renderMode.rawValue.capitalized)",
            "Read-only static snapshot",
            "Created \(createdAt.formatted(date: .abbreviated, time: .shortened))"
        ]
        if let expiresAt = request.expiresAt {
            lines.append("Expires \(expiresAt.formatted(date: .abbreviated, time: .shortened))")
        } else {
            lines.append("No expiration")
        }
        if request.deliveryKind == .staticPack {
            lines.append("Static packs cannot be revoked after delivery.")
        }
        return lines
    }

    func reviewHealthLines(from snapshot: AtlasExportSnapshot) -> [String] {
        var lines: [String] = []
        if snapshot.contextLogs.isEmpty == false {
            let recentContexts = snapshot.contextLogs
                .sorted(by: { $0.loggedAt > $1.loggedAt })
                .prefix(3)
                .map { context in
                    let details = [
                        context.mealTiming?.title,
                        context.fedState?.title,
                        context.appetite?.title,
                        context.hydration?.title
                    ]
                    .compactMap { $0 }
                    let giLabel = context.giTags
                        .filter { $0 != .calm }
                        .map(\.title)
                        .joined(separator: ", ")
                    let giDetail = {
                        let trimmed = giLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                        return trimmed.isEmpty ? nil : trimmed
                    }()
                    return ([details.isEmpty ? "Context entry" : details.joined(separator: " • ")]
                        + [giDetail])
                        .compactMap { $0 }
                        .joined(separator: " • ")
                }
            lines.append(contentsOf: recentContexts)
        }
        if let latestWeight = snapshot.weightLogs.sorted(by: { $0.loggedAt > $1.loggedAt }).first {
            lines.append("Latest weight: \(latestWeight.value.formatted(.number.precision(.fractionLength(0...1)))) \(latestWeight.unit.rawValue)")
        }
        if snapshot.symptomLogs.isEmpty == false {
            let symptomSummary = Dictionary(grouping: snapshot.symptomLogs, by: \.symptomKey)
                .map { "\($0.key): \($0.value.count) entr\($0.value.count == 1 ? "y" : "ies")" }
                .sorted()
            lines.append(contentsOf: symptomSummary.prefix(4))
        }
        if snapshot.metricValueLogs.isEmpty == false {
            let metricLabels = Dictionary(uniqueKeysWithValues: snapshot.customMetrics.map { ($0.id, $0.label) })
            let recentMetricLines = snapshot.metricValueLogs.sorted(by: { $0.loggedAt > $1.loggedAt }).prefix(4).map { value in
                let label = metricLabels[value.metricId] ?? "Metric"
                let displayValue = value.numberValue.map { String($0) } ?? value.textValue ?? value.booleanValue.map { $0 ? "True" : "False" } ?? "Logged"
                return "\(label): \(displayValue)"
            }
            lines.append(contentsOf: recentMetricLines)
        }
        let episodeInsights = buildEpisodeInsightsSnapshot(snapshot: snapshot, now: Date())
        if episodeInsights.hasAnyEpisodeData {
            lines.append(contentsOf: episodePreviewLines(from: episodeInsights).prefix(3))
        }
        return lines
    }

    func reviewCadenceLine(for rule: AtlasProtocolRuleRecord) -> String {
        switch rule.ruleType {
        case .weekly:
            let weekday = rule.weekday.map { Calendar.current.weekdaySymbols[max(0, min($0 - 1, 6))] } ?? "weekly"
            return "Weekly on \(weekday)"
        case .everyNDays:
            return "Every \(rule.intervalCount) day\(rule.intervalCount == 1 ? "" : "s")"
        case .daily:
            return "Daily"
        }
    }

    func reviewTimelineLines(from snapshot: AtlasExportSnapshot) -> [String] {
        let eventLines = snapshot.logEvents.sorted { $0.loggedAt > $1.loggedAt }.prefix(6).map { event in
            let title = snapshot.protocols.first(where: { $0.id == event.protocolId })?.name ?? "Atlas protocol"
            return "\(title): \(reviewTimelineLabel(for: event.eventType)) on \(atlasDate(from: event.loggedAt).formatted(date: .abbreviated, time: .omitted))"
        }
        let auditLines = snapshot.protocolChangeAudits.sorted { $0.createdAt > $1.createdAt }.prefix(4).map { audit in
            let title = snapshot.protocols.first(where: { $0.id == audit.protocolId })?.name ?? "Atlas protocol"
            return "\(title): plan updated on \(atlasDate(from: audit.createdAt).formatted(date: .abbreviated, time: .omitted))"
        }
        return Array((eventLines + auditLines).prefix(8))
    }

    func reviewTimelineLabel(for eventType: AtlasLogEventType) -> String {
        switch eventType {
        case .completed:
            return "dose taken"
        case .skipped:
            return "dose skipped"
        case .rescheduled:
            return "dose rescheduled"
        case .inventoryAdjustment:
            return "inventory correction"
        case .manualLog:
            return "manual log"
        }
    }

    func reviewTitle(for scopeKind: AtlasReviewScopeKind) -> String {
        "Review: \(reviewScopeTitle(scopeKind))"
    }

    func reviewScopeTitle(_ scopeKind: AtlasReviewScopeKind) -> String {
        switch scopeKind {
        case .currentProtocol:
            return "Current protocol"
        case .selectedProtocols:
            return "Selected protocols"
        case .last30Days:
            return "Last 30 days"
        case .symptomsOnly:
            return "Symptoms only"
        case .inventoryOnly:
            return "Inventory only"
        case .summaryOnly:
            return "Summary only"
        case .customDateRange:
            return "Custom date range"
        }
    }

    func buildReviewSummaryMarkdown(workspace: AtlasReviewWorkspace) -> String {
        let datasetLines = workspace.datasets.map { "- \($0.dataset): \($0.rowCount)" }.joined(separator: "\n")
        let sectionLines = workspace.sections.map { section in
            """
            ## \(section.title)
            \(section.lines.map { "- \($0)" }.joined(separator: "\n"))
            """
        }.joined(separator: "\n\n")

        return """
        # Atlas Review Pack

        This is a read-only static snapshot.

        Scope: \(reviewScopeTitle(workspace.scopeKind))
        Render mode: \(workspace.renderMode.rawValue.capitalized)
        Rows included: \(workspace.rowCount)
        Created: \(workspace.createdAt.formatted(date: .abbreviated, time: .shortened))
        \(workspace.expiresAt.map { "Expires: \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "Expires: none")

        ## Included datasets
        \(datasetLines)

        \(sectionLines)
        """
    }

    func reviewExportDirectoryURL() throws -> URL {
        let directoryURL = stack.locations?.backupDirectoryURL ?? URL(fileURLWithPath: NSTemporaryDirectory())
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }
}

private extension String {
    var reviewNilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
