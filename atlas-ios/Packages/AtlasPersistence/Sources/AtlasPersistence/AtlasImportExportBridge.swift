import AtlasDomain
import AtlasPrivacy
import AtlasSystem
import GRDB
import Foundation

public enum AtlasImportError: Error, LocalizedError, Sendable {
    case invalidPayload
    case unsupportedFormat(String)
    case unsupportedVersion(Int)
    case replaceImportRequired

    public var errorDescription: String? {
        switch self {
        case .invalidPayload:
            "Atlas could not validate the export bundle."
        case let .unsupportedFormat(format):
            "Atlas Export format '\(format)' is not supported."
        case let .unsupportedVersion(version):
            "Atlas Export version \(version) is not supported."
        case .replaceImportRequired:
            "Existing native Atlas data was found. Phase 2 requires an explicit replace-import flow."
        }
    }
}

public actor GRDBImportExportBridge: ImportExportBridging {
    let stack: AtlasDatabaseStack
    let projectionWriter: GRDBSharedProjectionWriter
    let featureFlags: AtlasFeatureFlagState
    let privacyFormatter: AtlasPrivacyFormatter

    init(
        stack: AtlasDatabaseStack,
        projectionWriter: GRDBSharedProjectionWriter,
        featureFlags: AtlasFeatureFlagState,
        privacyFormatter: AtlasPrivacyFormatter
    ) {
        self.stack = stack
        self.projectionWriter = projectionWriter
        self.featureFlags = featureFlags
        self.privacyFormatter = privacyFormatter
    }

    public func validateImport(at url: URL) async throws -> AtlasImportValidationResult {
        let (bundle, snapshotKeys, unsupportedDatasets) = try decodeBundle(at: url)
        try validateManifest(bundle.manifest)

        let missingDatasets = AtlasImportDataset.allCases
            .map(\.rawValue)
            .filter { snapshotKeys.contains($0) == false }
            .sorted()

        return AtlasImportValidationResult(
            manifest: bundle.manifest,
            isLegacyBundle: bundle.isLegacyEnvelope,
            missingDatasets: missingDatasets,
            unsupportedDatasets: unsupportedDatasets.sorted()
        )
    }

    nonisolated public func importerDescriptors() -> [AtlasImporterDescriptor] {
        [
            AtlasImporterDescriptor(
                kind: .atlasJSON,
                title: "Atlas JSON",
                subtitle: "Canonical Atlas Export v1 import with full dry-run and backfill support.",
                isCanonical: true,
                requiresFilePath: true,
                requiresRawText: false
            ),
            AtlasImporterDescriptor(
                kind: .atlasCSV,
                title: "Atlas CSV",
                subtitle: "Reconstruct from Atlas CSV exports with explicit warnings for lossy fields.",
                isCanonical: false,
                requiresFilePath: false,
                requiresRawText: true
            ),
            AtlasImporterDescriptor(
                kind: .genericCSV,
                title: "Generic CSV",
                subtitle: "Map columns into Atlas protocol fields and review the dry-run before import.",
                isCanonical: false,
                requiresFilePath: false,
                requiresRawText: true
            ),
            AtlasImporterDescriptor(
                kind: .manualText,
                title: "Manual text",
                subtitle: "Paste simple schedule text for explicit, reviewable protocol reconstruction.",
                isCanonical: false,
                requiresFilePath: false,
                requiresRawText: true
            )
        ]
    }

    public func prepareImport(at url: URL) async throws -> AtlasPreparedImport {
        let (bundle, _, _) = try decodeBundle(at: url)
        let validation = try await validateImport(at: url)
        let staged = stage(bundle: bundle, validation: validation)
        let dryRun = try await stack.canonical.read { db in
            try Self.buildDryRunSummary(
                snapshot: staged.snapshot,
                validation: validation,
                warnings: staged.warnings,
                privacyNotes: staged.privacyNotes,
                backfillNotes: staged.backfillNotes,
                db: db
            )
        }

        return AtlasPreparedImport(
            bundle: bundle,
            stagedSnapshot: staged.snapshot,
            dryRun: dryRun
        )
    }

    public func commitPreparedImport(
        _ prepared: AtlasPreparedImport,
        mode: AtlasImportMode
    ) async throws -> AtlasImportCommitResult {
        try await commitSnapshot(
            prepared.stagedSnapshot,
            mode: mode,
            sourceSummary: prepared.bundle.manifest.source,
            now: Date()
        )
    }

    public func cancelPreparedImport(_ prepared: AtlasPreparedImport) async {
        _ = prepared
    }

    nonisolated public func exportStatusDescription() -> String {
        "Native Atlas can create deterministic JSON and CSV exports plus encrypted selective-share snapshots."
    }

    nonisolated public func importStatusDescription() -> String {
        "Import Center now supports Atlas JSON, Atlas CSV reconstruction, generic CSV mapping, and manual text dry-runs before commit."
    }

    private func validateManifest(_ manifest: AtlasExportManifest) throws {
        guard manifest.format == "atlas_export" else {
            throw AtlasImportError.unsupportedFormat(manifest.format)
        }

        guard manifest.version == 1 else {
            throw AtlasImportError.unsupportedVersion(manifest.version)
        }
    }

    private func decodeBundle(at url: URL) throws -> (AtlasExportBundle, Set<String>, [String]) {
        let data = try Data(contentsOf: url)
        let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard
            let payload,
            let snapshotDictionary = payload["snapshot"] as? [String: Any]
        else {
            throw AtlasImportError.invalidPayload
        }

        let decoder = JSONDecoder()
        let bundle = try decoder.decode(AtlasExportBundle.self, from: data)
        let snapshotKeys = Set(snapshotDictionary.keys)
        let supported = Set(AtlasImportDataset.allCases.map(\.rawValue))
        let unsupported = snapshotKeys.subtracting(supported)

        return (bundle, snapshotKeys, Array(unsupported))
    }

    private func stage(
        bundle: AtlasExportBundle,
        validation: AtlasImportValidationResult
    ) -> (snapshot: AtlasExportSnapshot, warnings: [String], privacyNotes: [String], backfillNotes: [String]) {
        var snapshot = bundle.snapshot
        var warnings: [String] = []
        var privacyNotes: [String] = []
        var backfillNotes: [String] = []

        if validation.missingDatasets.contains(AtlasImportDataset.privacyProfile.rawValue) {
            snapshot.privacyProfile = .default(timestamp: bundle.manifest.generatedAt)
            backfillNotes.append("Legacy bundle did not include Trust Vault profile rows; native defaults were backfilled.")
        }

        if validation.missingDatasets.contains(AtlasImportDataset.reminderPreference.rawValue) {
            snapshot.reminderPreference = .default(timestamp: bundle.manifest.generatedAt)
            backfillNotes.append("Legacy bundle did not include reminder preference rows; native defaults were backfilled.")
        }

        if snapshot.protocolRevisions.isEmpty {
            snapshot.protocolRevisions = snapshot.protocols.map { record in
                AtlasProtocolRevisionRecord(
                    id: "prv_\(record.id)_1",
                    protocolId: record.id,
                    revisionNumber: 1,
                    previousRevisionId: nil,
                    effectiveFrom: atlasDayStartTimestamp(record.startDate),
                    effectiveTo: nil,
                    lifecycleState: record.status == .paused ? .paused : .active,
                    timezone: record.timezone,
                    timezoneStrategy: .keepLocalClock,
                    defaultTimeOfDay: record.defaultTimeOfDay,
                    doseAmount: record.doseAmount,
                    doseUnit: record.doseUnit,
                    linkedVialId: record.linkedVialId,
                    missedDosePolicy: .skipAndContinue,
                    notes: record.notes,
                    createdAt: record.createdAt,
                    updatedAt: record.updatedAt
                )
            }
            backfillNotes.append("Revision rows were backfilled from base protocol definitions for legacy exports.")
        }

        if snapshot.protocolRevisionRules.isEmpty {
            let revisionLookup = Dictionary(uniqueKeysWithValues: snapshot.protocolRevisions.map { ($0.protocolId, $0.id) })
            snapshot.protocolRevisionRules = snapshot.protocolRules.enumerated().compactMap { offset, rule in
                guard let revisionID = revisionLookup[rule.protocolId] else {
                    return nil
                }

                return AtlasProtocolRevisionRuleRecord(
                    id: "prr_\(rule.id)",
                    revisionId: revisionID,
                    phaseType: .base,
                    phaseOrder: offset,
                    ruleType: rule.ruleType,
                    intervalCount: rule.intervalCount,
                    weekday: rule.weekday,
                    timeOfDay: rule.timeOfDay,
                    anchorDate: rule.anchorDate,
                    phaseStartDayOffset: 0,
                    phaseLengthDays: nil,
                    doseAmountOverride: nil,
                    doseUnitOverride: nil,
                    createdAt: rule.createdAt,
                    updatedAt: rule.updatedAt
                )
            }
            backfillNotes.append("Revision rule rows were backfilled from legacy protocol rules.")
        }

        if snapshot.protocolChangeAudits.isEmpty {
            backfillNotes.append("Legacy bundle contained no protocol change audit rows; native import preserved this as empty history.")
        }

        if snapshot.sensitiveActionAudits.isEmpty {
            backfillNotes.append("Legacy bundle contained no Trust Vault audit rows; native import preserved this as empty history.")
        }

        if bundle.isLegacyEnvelope {
            warnings.append("This bundle uses the legacy React Native export envelope without an explicit manifest block.")
        }

        if snapshot.protocols.isEmpty {
            warnings.append("The bundle does not contain any protocols to import.")
        }

        privacyNotes.append(
            snapshot.privacyProfile.exportAliasByDefault
                ? "Export alias-by-default preference will be preserved in native Trust Vault."
                : "Canonical export labels remain enabled for broad exports."
        )
        privacyNotes.append(
            snapshot.privacyProfile.aliasModeEnabled
                ? "Alias mode will render imported labels through the native privacy layer."
                : "Imported labels will render canonically until native privacy preferences change."
        )

        return (snapshot, warnings, privacyNotes, backfillNotes)
    }

    nonisolated private static func buildDryRunSummary(
        snapshot: AtlasExportSnapshot,
        validation: AtlasImportValidationResult,
        warnings: [String],
        privacyNotes: [String],
        backfillNotes: [String],
        db: Database
    ) throws -> AtlasImportDryRunSummary {
        let datasetDiffs = try AtlasImportDataset.allCases.map { dataset in
            let incomingIDs = datasetIdentifiers(from: snapshot, for: dataset)
            let existingIDs = try existingIdentifiers(in: db, for: dataset)
            let updates = incomingIDs.filter(existingIDs.contains).count
            let creates = incomingIDs.count - updates
            return AtlasDatasetDiff(dataset: dataset.rawValue, creates: creates, updates: updates)
        }

        return AtlasImportDryRunSummary(
            validation: validation,
            datasetDiffs: datasetDiffs,
            recordsToCreate: datasetDiffs.reduce(0) { $0 + $1.creates },
            recordsToUpdate: datasetDiffs.reduce(0) { $0 + $1.updates },
            warnings: warnings,
            privacyNotes: privacyNotes,
            backfillNotes: backfillNotes
        )
    }

    private func exportBackupSnapshot() async throws -> URL {
        let generatedAt = atlasTimestamp(from: Date())
        let snapshot = try await stack.canonical.read { db in
            try canonicalSnapshot(from: db)
        }
        let bundle = AtlasExportBundle(
            manifest: AtlasExportManifest(
                generatedAt: generatedAt,
                source: "atlas-ios-native"
            ),
            snapshot: snapshot
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(bundle)
        let directoryURL = stack.locations?.backupDirectoryURL ?? URL(fileURLWithPath: NSTemporaryDirectory())
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        let url = directoryURL.appendingPathComponent("atlas-native-backup-\(generatedAt.replacingOccurrences(of: ":", with: "-")).json")
        try data.write(to: url)
        return url
    }

    private func buildProjectionState(
        snapshot: AtlasExportSnapshot,
        occurrenceProjections: [AtlasOccurrenceProjectionRecord]
    ) -> (
        nextDue: AtlasSharedNextDueSnapshot?,
        timeline: [AtlasSharedTimelineSummary],
        labels: [AtlasSharedLabelProjection],
        quickActions: [AtlasSharedQuickAction],
        featureFlags: AtlasSharedFeatureFlagProjection
    ) {
        let protocols = Dictionary(uniqueKeysWithValues: snapshot.protocols.map { ($0.id, $0) })
        let aliases = Dictionary(uniqueKeysWithValues: snapshot.protocolAliases.map { ($0.protocolId, $0) })
        let nextOccurrence = occurrenceProjections.sorted { $0.scheduledAt < $1.scheduledAt }.first
        let privacyProfile = snapshot.privacyProfile
        let extensionMode: AtlasPrivacyRenderMode = privacyProfile.aliasModeEnabled ? .alias : .discreet

        let nextDue = nextOccurrence.flatMap { projection -> AtlasSharedNextDueSnapshot? in
            guard let protocolRecord = protocols[projection.protocolId] else {
                return nil
            }

            let title = privacyFormatter.title(
                canonical: protocolRecord.name,
                alias: aliases[projection.protocolId]?.aliasLabel,
                mode: extensionMode
            )
            return AtlasSharedNextDueSnapshot(
                occurrenceID: projection.id,
                protocolID: projection.protocolId,
                displayTitle: title,
                dueLabel: relativeDueLabel(for: atlasDate(from: projection.scheduledAt)),
                scheduledAt: projection.scheduledAt
            )
        }

        let renderMode = privacyFormatter.renderMode(for: privacyProfile)
        let timeline = snapshot.logEvents
            .sorted { $0.loggedAt > $1.loggedAt }
            .prefix(10)
            .compactMap { event -> AtlasSharedTimelineSummary? in
                guard let protocolRecord = protocols[event.protocolId] else {
                    return nil
                }

                let alias = aliases[event.protocolId]?.aliasLabel
                let displayTitle = privacyFormatter.title(
                    canonical: protocolRecord.name,
                    alias: alias,
                    mode: extensionMode
                )
                return AtlasSharedTimelineSummary(
                    id: event.id,
                    protocolID: event.protocolId,
                    displayTitle: displayTitle,
                    summary: privacyFormatter.timelineSummary(
                        eventType: event.eventType,
                        canonical: protocolRecord.name,
                        alias: alias,
                        mode: renderMode
                    ),
                    recordedAt: event.loggedAt
                )
            }

        let labels = snapshot.protocols.map { protocolRecord in
            AtlasSharedLabelProjection(
                id: protocolRecord.id,
                canonicalTitle: protocolRecord.name,
                aliasTitle: aliases[protocolRecord.id]?.aliasLabel,
                discreetTitle: privacyFormatter.title(
                    canonical: protocolRecord.name,
                    alias: aliases[protocolRecord.id]?.aliasLabel,
                    mode: .discreet
                )
            )
        }

        let quickActions = occurrenceProjections.prefix(3).compactMap { projection -> AtlasSharedQuickAction? in
            guard let protocolRecord = protocols[projection.protocolId] else {
                return nil
            }

            return AtlasSharedQuickAction(
                id: "quick_\(projection.id)",
                protocolID: projection.protocolId,
                occurrenceID: projection.id,
                title: privacyFormatter.title(
                    canonical: protocolRecord.name,
                    alias: aliases[projection.protocolId]?.aliasLabel,
                    mode: extensionMode
                )
            )
        }

        return (
            nextDue,
            timeline,
            labels,
            quickActions,
            AtlasSharedFeatureFlagProjection(flags: featureFlags)
        )
    }
}
