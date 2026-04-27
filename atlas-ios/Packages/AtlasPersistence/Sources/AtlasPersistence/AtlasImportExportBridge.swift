import AtlasDomain
import AtlasPrivacy
import AtlasSystem
import CryptoKit
import GRDB
import Foundation

public enum AtlasImportError: Error, LocalizedError, Sendable {
    case invalidPayload
    case unsupportedFormat(String)
    case unsupportedVersion(Int)
    case replaceImportRequired
    case restorePointUnavailable(String)
    case restorePointCorrupted(String)
    case restorePointIntegrityMismatch(String)

    public var errorDescription: String? {
        switch self {
        case .invalidPayload:
            "Could not validate the export bundle."
        case let .unsupportedFormat(format):
            "Atlas Export format '\(format)' is not supported."
        case let .unsupportedVersion(version):
            "Atlas Export version \(version) is not supported."
        case .replaceImportRequired:
            "Existing native Atlas data was found. Phase 2 requires an explicit replace-import flow."
        case let .restorePointUnavailable(title):
            "Restore point '\(title)' is no longer available on this device."
        case let .restorePointCorrupted(title):
            "Restore point '\(title)' could not be validated. The saved backup file may be damaged or incomplete."
        case let .restorePointIntegrityMismatch(title):
            "Restore point '\(title)' no longer matches Atlas's saved integrity checks, so restore was blocked."
        }
    }
}

struct AtlasImportTemplateDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "import_templates"

    var id: String
    var name: String
    var importer: AtlasImporterKind
    var genericCsvMappingJson: String?
    var manualOptionsJson: String?
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case importer
        case genericCsvMappingJson = "generic_csv_mapping_json"
        case manualOptionsJson = "manual_options_json"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var domain: AtlasSavedImportTemplate {
        AtlasSavedImportTemplate(
            id: id,
            name: name,
            importer: importer,
            genericCsvMapping: atlasImportDecode(AtlasGenericCsvMapping.self, from: genericCsvMappingJson),
            manualOptions: atlasImportDecode(AtlasManualImportOptions.self, from: manualOptionsJson),
            createdAt: atlasDate(from: createdAt),
            updatedAt: atlasDate(from: updatedAt)
        )
    }

    init(template: AtlasSavedImportTemplate) {
        id = template.id
        name = template.name
        importer = template.importer
        genericCsvMappingJson = atlasImportEncode(template.genericCsvMapping)
        manualOptionsJson = atlasImportEncode(template.manualOptions)
        createdAt = atlasTimestamp(from: template.createdAt)
        updatedAt = atlasTimestamp(from: template.updatedAt)
    }
}

struct AtlasRestorePointDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "restore_points"

    var id: String
    var title: String
    var actionKind: AtlasRestorePointActionKind
    var sourceSummary: String
    var fileURL: String
    var rowCount: Int
    var fileSHA256: String?
    var fileByteCount: Int?
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case actionKind = "action_kind"
        case sourceSummary = "source_summary"
        case fileURL = "file_url"
        case rowCount = "row_count"
        case fileSHA256 = "file_sha256"
        case fileByteCount = "file_byte_count"
        case createdAt = "created_at"
    }

    var domain: AtlasRestorePointSummary {
        AtlasRestorePointSummary(
            id: id,
            title: title,
            actionKind: actionKind,
            sourceSummary: sourceSummary,
            fileURL: URL(fileURLWithPath: fileURL),
            rowCount: rowCount,
            createdAt: atlasDate(from: createdAt)
        )
    }

    init(
        summary: AtlasRestorePointSummary,
        fileSHA256: String? = nil,
        fileByteCount: Int? = nil
    ) {
        id = summary.id
        title = summary.title
        actionKind = summary.actionKind
        sourceSummary = summary.sourceSummary
        fileURL = summary.fileURL.path
        rowCount = summary.rowCount
        self.fileSHA256 = fileSHA256
        self.fileByteCount = fileByteCount
        createdAt = atlasTimestamp(from: summary.createdAt)
    }
}

struct AtlasRestorePointIntegrity: Equatable {
    var fileSHA256: String
    var fileByteCount: Int
}

private extension AtlasRestorePointDBRecord {
    var hasIntegrityMetadata: Bool {
        guard let fileSHA256, fileSHA256.isEmpty == false, let fileByteCount else {
            return false
        }
        return fileByteCount >= 0
    }

    func matchesIntegrity(_ integrity: AtlasRestorePointIntegrity) -> Bool {
        fileSHA256 == integrity.fileSHA256 && fileByteCount == integrity.fileByteCount
    }

    mutating func applyIntegrity(_ integrity: AtlasRestorePointIntegrity) {
        fileSHA256 = integrity.fileSHA256
        fileByteCount = integrity.fileByteCount
    }
}

func atlasRestorePointIntegrity(for data: Data) -> AtlasRestorePointIntegrity {
    let digest = SHA256.hash(data: data)
    return AtlasRestorePointIntegrity(
        fileSHA256: digest.map { String(format: "%02x", $0) }.joined(),
        fileByteCount: data.count
    )
}

private func atlasImportEncode<T: Encodable>(_ value: T?) -> String? {
    guard let value else {
        return nil
    }
    let encoder = JSONEncoder()
    return (try? encoder.encode(value)).flatMap { String(data: $0, encoding: .utf8) }
}

private func atlasImportDecode<T: Decodable>(_ type: T.Type, from string: String?) -> T? {
    guard let string, let data = string.data(using: .utf8) else {
        return nil
    }
    return try? JSONDecoder().decode(type, from: data)
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

    public func listImportTemplates(importer: AtlasImporterKind?) async throws -> [AtlasSavedImportTemplate] {
        try await stack.canonical.read { db in
            if let importer {
                return try AtlasImportTemplateDBRecord
                    .filter(Column("importer") == importer.rawValue)
                    .order(Column("updated_at").desc)
                    .fetchAll(db)
                    .map(\.domain)
            }

            return try AtlasImportTemplateDBRecord
                .order(Column("updated_at").desc)
                .fetchAll(db)
                .map(\.domain)
        }
    }

    public func saveImportTemplate(
        _ draft: AtlasImportTemplateDraft,
        now: Date
    ) async throws -> AtlasSavedImportTemplate {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isEmpty == false else {
            throw AtlasImportError.invalidPayload
        }

        switch draft.importer {
        case .genericCSV:
            guard draft.genericCsvMapping != nil else {
                throw AtlasImportError.invalidPayload
            }
        case .manualText:
            guard draft.manualOptions != nil else {
                throw AtlasImportError.invalidPayload
            }
        default:
            throw AtlasImportError.invalidPayload
        }

        return try await stack.canonical.write { db in
            let existing = try AtlasImportTemplateDBRecord
                .filter(sql: "lower(name) = lower(?) AND importer = ?", arguments: [trimmedName, draft.importer.rawValue])
                .fetchOne(db)

            let template = AtlasSavedImportTemplate(
                id: existing?.id ?? "import_template_\(UUID().uuidString.lowercased())",
                name: trimmedName,
                importer: draft.importer,
                genericCsvMapping: draft.genericCsvMapping,
                manualOptions: draft.manualOptions,
                createdAt: existing.map { atlasDate(from: $0.createdAt) } ?? now,
                updatedAt: now
            )
            let record = AtlasImportTemplateDBRecord(template: template)
            if existing == nil {
                try record.insert(db)
            } else {
                try record.update(db)
            }
            return template
        }
    }

    public func deleteImportTemplate(id: String) async throws {
        try await stack.canonical.write { db in
            _ = try AtlasImportTemplateDBRecord.deleteOne(db, key: id)
        }
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
                lintFindings: [],
                db: db,
                featureFlags: featureFlags
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

    public func listRestorePoints() async throws -> [AtlasRestorePointSummary] {
        let records = try await stack.canonical.read { db in
            try AtlasRestorePointDBRecord
                .order(Column("created_at").desc)
                .fetchAll(db)
        }
        var summaries: [AtlasRestorePointSummary] = []
        var healedRecords: [AtlasRestorePointDBRecord] = []

        for var record in records {
            let fileURL = URL(fileURLWithPath: record.fileURL)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                continue
            }

            if record.hasIntegrityMetadata == false,
               let data = try? Data(contentsOf: fileURL) {
                let integrity = atlasRestorePointIntegrity(for: data)
                record.applyIntegrity(integrity)
                healedRecords.append(record)
            }

            summaries.append(record.domain)
        }

        if healedRecords.isEmpty == false {
            let recordsToHeal = healedRecords
            try await stack.canonical.write { db in
                for record in recordsToHeal {
                    try record.update(db)
                }
            }
        }

        return summaries
    }

    public func previewRestorePoint(id: String) async throws -> AtlasRestorePointPreview {
        let (restorePoint, prepared) = try await loadPreparedRestorePoint(id: id)
        return AtlasRestorePointPreview(
            restorePoint: restorePoint,
            datasetDiffs: prepared.dryRun.datasetDiffs,
            recordsToCreate: prepared.dryRun.recordsToCreate,
            recordsToUpdate: prepared.dryRun.recordsToUpdate,
            warnings: prepared.dryRun.warnings,
            notes: [
                "Restore replays the saved Atlas JSON snapshot transactionally.",
                "Current local data is backed up again before the restore replaces anything.",
                "Historical logs inside the restore point remain immutable rows."
            ],
            rowCount: snapshotRowCount(prepared.stagedSnapshot)
        )
    }

    public func restoreRestorePoint(
        id: String,
        now: Date
    ) async throws -> AtlasRestoreCommitResult {
        let (restorePoint, prepared) = try await loadPreparedRestorePoint(id: id)
        let result = try await commitSnapshot(
            prepared.stagedSnapshot,
            mode: .replaceExisting,
            sourceSummary: restorePoint.title,
            now: now,
            auditEventType: .restoreCommitted,
            auditSurface: "restore_center",
            destructiveActionKind: .restoreCommit
        )

        return AtlasRestoreCommitResult(
            restoredPoint: restorePoint,
            backupURL: result.backupURL,
            restoredProtocolCount: result.importedProtocolCount,
            restoredLogEventCount: result.importedLogEventCount,
            nextDue: result.nextDue
        )
    }

    nonisolated public func exportStatusDescription() -> String {
        "Creates deterministic JSON and CSV exports plus encrypted selective-share snapshots."
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

    private func loadPreparedRestorePoint(id: String) async throws -> (AtlasRestorePointSummary, AtlasPreparedImport) {
        var record = try await stack.canonical.read { db in
            guard let record = try AtlasRestorePointDBRecord.fetchOne(db, key: id) else {
                throw AtlasImportError.invalidPayload
            }
            return record
        }
        let fileURL = URL(fileURLWithPath: record.fileURL)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw AtlasImportError.restorePointUnavailable(record.title)
        }

        let data = try Data(contentsOf: fileURL)
        let integrity = atlasRestorePointIntegrity(for: data)
        if record.hasIntegrityMetadata {
            guard record.matchesIntegrity(integrity) else {
                throw AtlasImportError.restorePointIntegrityMismatch(record.title)
            }
        } else {
            record.applyIntegrity(integrity)
            let healedRecord = record
            try await stack.canonical.write { db in
                try healedRecord.update(db)
            }
        }

        let prepared: AtlasPreparedImport
        do {
            prepared = try await prepareImport(at: fileURL)
        } catch let error as AtlasImportError {
            switch error {
            case .invalidPayload, .unsupportedFormat, .unsupportedVersion:
                throw AtlasImportError.restorePointCorrupted(record.title)
            default:
                throw error
            }
        } catch {
            throw AtlasImportError.restorePointCorrupted(record.title)
        }

        guard snapshotRowCount(prepared.stagedSnapshot) == record.rowCount else {
            throw AtlasImportError.restorePointIntegrityMismatch(record.title)
        }

        return (record.domain, prepared)
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
            backfillNotes.append("Legacy bundle did not include privacy control profile rows; native defaults were backfilled.")
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
            backfillNotes.append("Legacy bundle contained no privacy control audit rows; native import preserved this as empty history.")
        }

        if bundle.isLegacyEnvelope {
            warnings.append("This bundle uses the legacy React Native export envelope without an explicit manifest block.")
        }

        if snapshot.protocols.isEmpty {
            warnings.append("The bundle does not contain any protocols to import.")
        }

        privacyNotes.append(
            snapshot.privacyProfile.exportAliasByDefault
                ? "Export alias-by-default preference will be preserved in privacy controls."
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
        lintFindings: [AtlasImportLintItem],
        db: Database,
        featureFlags: AtlasFeatureFlagState
    ) throws -> AtlasImportDryRunSummary {
        let datasetDiffs = try AtlasImportDataset.allCases.map { dataset in
            let incomingIDs = datasetIdentifiers(from: snapshot, for: dataset)
            let existingIDs = try existingIdentifiers(in: db, for: dataset)
            let updates = incomingIDs.filter(existingIDs.contains).count
            let creates = incomingIDs.count - updates
            return AtlasDatasetDiff(dataset: dataset.rawValue, creates: creates, updates: updates)
        }
        let mergedLintFindings = try lintImportSnapshot(
            snapshot: snapshot,
            datasetDiffs: datasetDiffs,
            existingProtocolNames: Set(
                String.fetchAll(db, sql: "SELECT name FROM protocols")
                    .map(normalizedProtocolName(_:))
            ),
            supplemental: lintFindings
        )
        let summarySettings = try readSummarySettings(db: db, featureFlags: featureFlags)
        let plainLanguageSummary = buildImportDiffSummaryRequest(
            sourceLabel: validation.manifest.format,
            datasetDiffs: datasetDiffs,
            recordsToCreate: datasetDiffs.reduce(0) { $0 + $1.creates },
            recordsToUpdate: datasetDiffs.reduce(0) { $0 + $1.updates },
            lintFindings: mergedLintFindings,
            warnings: warnings,
            privacyNotes: privacyNotes,
            backfillNotes: backfillNotes,
            referenceDate: Date()
        ).flatMap {
            AtlasSummaryService(
                featureFlags: featureFlags,
                settings: summarySettings
            ).generate($0)
        }

        return AtlasImportDryRunSummary(
            validation: validation,
            datasetDiffs: datasetDiffs,
            recordsToCreate: datasetDiffs.reduce(0) { $0 + $1.creates },
            recordsToUpdate: datasetDiffs.reduce(0) { $0 + $1.updates },
            lintFindings: mergedLintFindings,
            warnings: warnings,
            privacyNotes: privacyNotes,
            backfillNotes: backfillNotes,
            plainLanguageSummary: plainLanguageSummary
        )
    }

    nonisolated static func lintImportSnapshot(
        snapshot: AtlasExportSnapshot,
        datasetDiffs: [AtlasDatasetDiff],
        existingProtocolNames: Set<String>,
        supplemental: [AtlasImportLintItem]
    ) throws -> [AtlasImportLintItem] {
        var findings = supplemental

        let groupedImportedNames = Dictionary(grouping: snapshot.protocols, by: {
            normalizedProtocolName($0.name)
        })
        let duplicatedImportedNames = groupedImportedNames
            .filter { $0.key.isEmpty == false && $0.value.count > 1 }
            .keys
            .sorted()
        if duplicatedImportedNames.isEmpty == false {
            findings.append(
                AtlasImportLintItem(
                    id: "lint.duplicate.imported_names",
                    category: .duplicateProtocolName,
                    severity: .warning,
                    summary: "Imported protocol names repeat after normalization.",
                    detail: duplicatedImportedNames.joined(separator: ", ")
                )
            )
        }

        let overlappingNames = Set(groupedImportedNames.keys)
            .subtracting([""])
            .intersection(existingProtocolNames)
            .sorted()
        if overlappingNames.isEmpty == false {
            findings.append(
                AtlasImportLintItem(
                    id: "lint.duplicate.existing_names",
                    category: .duplicateProtocolName,
                    severity: .warning,
                    summary: "Imported protocol names already exist locally.",
                    detail: overlappingNames.joined(separator: ", ")
                )
            )
        }

        let overlappingDatasets = datasetDiffs
            .filter { $0.updates > 0 }
            .map { "\($0.dataset): \($0.updates)" }
        if overlappingDatasets.isEmpty == false {
            findings.append(
                AtlasImportLintItem(
                    id: "lint.stable_id_overlap",
                    category: .stableIDOverlap,
                    severity: .warning,
                    summary: "Stable ids already exist locally and will be replaced on commit.",
                    detail: overlappingDatasets.joined(separator: " • ")
                )
            )
        }

        let scheduleGroups = Dictionary(grouping: snapshot.protocols) {
            [
                $0.startDate,
                $0.defaultTimeOfDay ?? "none",
                $0.timezone,
                $0.kind.rawValue
            ].joined(separator: "|")
        }
        let collisions = scheduleGroups
            .filter { $0.value.count > 1 }
            .map { group in
                group.value.map(\.name).sorted().joined(separator: ", ")
            }
            .sorted()
        if collisions.isEmpty == false {
            findings.append(
                AtlasImportLintItem(
                    id: "lint.schedule_collisions",
                    category: .dateTimeParsingCollision,
                    severity: .info,
                    summary: "Multiple imported rows resolve to the same parsed schedule window.",
                    detail: collisions.joined(separator: " • ")
                )
            )
        }

        let missingUnits = snapshot.protocols
            .filter { $0.doseAmount != nil && ($0.doseUnit?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false) }
            .map(\.name)
            .sorted()
        if missingUnits.isEmpty == false {
            findings.append(
                AtlasImportLintItem(
                    id: "lint.ambiguous_units.missing",
                    category: .ambiguousUnitMapping,
                    severity: .warning,
                    summary: "Dose amounts were imported without a clear unit.",
                    detail: missingUnits.joined(separator: ", ")
                )
            )
        }

        let mixedUnits = Dictionary(grouping: snapshot.protocols, by: { normalizedProtocolName($0.name) })
            .compactMap { entry -> String? in
                let units = Set(entry.value.compactMap { $0.doseUnit?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { $0.isEmpty == false })
                guard units.count > 1 else {
                    return nil
                }
                return "\(entry.value.first?.name ?? "Imported protocol"): \(units.sorted().joined(separator: ", "))"
            }
            .sorted()
        if mixedUnits.isEmpty == false {
            findings.append(
                AtlasImportLintItem(
                    id: "lint.ambiguous_units.mixed",
                    category: .ambiguousUnitMapping,
                    severity: .info,
                    summary: "Imported rows for the same protocol name use multiple units.",
                    detail: mixedUnits.joined(separator: " • ")
                )
            )
        }

        return findings
    }

    nonisolated static func normalizedProtocolName(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
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
                scheduledAt: projection.scheduledAt,
                state: .upcoming,
                statusSummary: relativeDueLabel(for: atlasDate(from: projection.scheduledAt))
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
                ),
                dueLabel: relativeDueLabel(for: atlasDate(from: projection.scheduledAt)),
                state: .upcoming
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
