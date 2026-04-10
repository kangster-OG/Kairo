import Foundation

public enum AtlasImporterKind: String, Codable, CaseIterable, Sendable {
    case atlasJSON = "atlas_json"
    case atlasCSV = "atlas_csv"
    case genericCSV = "generic_csv"
    case manualText = "manual_text"
}

public struct AtlasImporterDescriptor: Sendable, Equatable, Identifiable {
    public var id: AtlasImporterKind { kind }
    public var kind: AtlasImporterKind
    public var title: String
    public var subtitle: String
    public var isCanonical: Bool
    public var requiresFilePath: Bool
    public var requiresRawText: Bool

    public init(
        kind: AtlasImporterKind,
        title: String,
        subtitle: String,
        isCanonical: Bool,
        requiresFilePath: Bool,
        requiresRawText: Bool
    ) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.isCanonical = isCanonical
        self.requiresFilePath = requiresFilePath
        self.requiresRawText = requiresRawText
    }
}

public struct AtlasGenericCsvMapping: Codable, Sendable, Equatable {
    public var nameColumn: String
    public var kindColumn: String?
    public var cadenceColumn: String
    public var weekdayColumn: String?
    public var intervalDaysColumn: String?
    public var timeColumn: String?
    public var doseAmountColumn: String?
    public var doseUnitColumn: String?
    public var notesColumn: String?
    public var startDateColumn: String?

    public init(
        nameColumn: String,
        kindColumn: String? = nil,
        cadenceColumn: String,
        weekdayColumn: String? = nil,
        intervalDaysColumn: String? = nil,
        timeColumn: String? = nil,
        doseAmountColumn: String? = nil,
        doseUnitColumn: String? = nil,
        notesColumn: String? = nil,
        startDateColumn: String? = nil
    ) {
        self.nameColumn = nameColumn
        self.kindColumn = kindColumn
        self.cadenceColumn = cadenceColumn
        self.weekdayColumn = weekdayColumn
        self.intervalDaysColumn = intervalDaysColumn
        self.timeColumn = timeColumn
        self.doseAmountColumn = doseAmountColumn
        self.doseUnitColumn = doseUnitColumn
        self.notesColumn = notesColumn
        self.startDateColumn = startDateColumn
    }
}

public struct AtlasManualImportOptions: Codable, Sendable, Equatable {
    public var defaultKind: AtlasProtocolKind
    public var timezone: String
    public var anchorDate: Date

    public init(
        defaultKind: AtlasProtocolKind = .custom,
        timezone: String = TimeZone.current.identifier,
        anchorDate: Date = Date()
    ) {
        self.defaultKind = defaultKind
        self.timezone = timezone
        self.anchorDate = anchorDate
    }
}

public struct AtlasUniversalImportRequest: Sendable, Equatable {
    public var importer: AtlasImporterKind
    public var fileURL: URL?
    public var rawText: String?
    public var genericCsvMapping: AtlasGenericCsvMapping?
    public var manualOptions: AtlasManualImportOptions

    public init(
        importer: AtlasImporterKind,
        fileURL: URL? = nil,
        rawText: String? = nil,
        genericCsvMapping: AtlasGenericCsvMapping? = nil,
        manualOptions: AtlasManualImportOptions = .init()
    ) {
        self.importer = importer
        self.fileURL = fileURL
        self.rawText = rawText
        self.genericCsvMapping = genericCsvMapping
        self.manualOptions = manualOptions
    }
}

public struct AtlasImportTemplateDraft: Sendable, Equatable {
    public var name: String
    public var importer: AtlasImporterKind
    public var genericCsvMapping: AtlasGenericCsvMapping?
    public var manualOptions: AtlasManualImportOptions?

    public init(
        name: String,
        importer: AtlasImporterKind,
        genericCsvMapping: AtlasGenericCsvMapping? = nil,
        manualOptions: AtlasManualImportOptions? = nil
    ) {
        self.name = name
        self.importer = importer
        self.genericCsvMapping = genericCsvMapping
        self.manualOptions = manualOptions
    }
}

public struct AtlasSavedImportTemplate: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var importer: AtlasImporterKind
    public var genericCsvMapping: AtlasGenericCsvMapping?
    public var manualOptions: AtlasManualImportOptions?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String,
        name: String,
        importer: AtlasImporterKind,
        genericCsvMapping: AtlasGenericCsvMapping? = nil,
        manualOptions: AtlasManualImportOptions? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.importer = importer
        self.genericCsvMapping = genericCsvMapping
        self.manualOptions = manualOptions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum AtlasImportLintSeverity: String, Codable, CaseIterable, Sendable {
    case info
    case warning
    case error
}

public enum AtlasImportLintCategory: String, Codable, CaseIterable, Sendable {
    case duplicateProtocolName = "duplicate_protocol_name"
    case stableIDOverlap = "stable_id_overlap"
    case dateTimeParsingCollision = "date_time_parsing_collision"
    case ambiguousUnitMapping = "ambiguous_unit_mapping"
}

public struct AtlasImportLintItem: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var category: AtlasImportLintCategory
    public var severity: AtlasImportLintSeverity
    public var summary: String
    public var detail: String

    public init(
        id: String,
        category: AtlasImportLintCategory,
        severity: AtlasImportLintSeverity,
        summary: String,
        detail: String
    ) {
        self.id = id
        self.category = category
        self.severity = severity
        self.summary = summary
        self.detail = detail
    }
}

public struct AtlasUniversalImportDryRunSummary: Sendable, Equatable {
    public var importer: AtlasImporterKind
    public var sourceSummary: String
    public var datasetDiffs: [AtlasDatasetDiff]
    public var recordsToCreate: Int
    public var recordsToUpdate: Int
    public var lintFindings: [AtlasImportLintItem]
    public var warnings: [String]
    public var conflicts: [String]
    public var unsupportedRows: [String]
    public var privacyNotes: [String]
    public var backfillNotes: [String]
    public var plainLanguageSummary: AtlasGeneratedSummary?

    public init(
        importer: AtlasImporterKind,
        sourceSummary: String,
        datasetDiffs: [AtlasDatasetDiff],
        recordsToCreate: Int,
        recordsToUpdate: Int,
        lintFindings: [AtlasImportLintItem],
        warnings: [String],
        conflicts: [String],
        unsupportedRows: [String],
        privacyNotes: [String],
        backfillNotes: [String],
        plainLanguageSummary: AtlasGeneratedSummary? = nil
    ) {
        self.importer = importer
        self.sourceSummary = sourceSummary
        self.datasetDiffs = datasetDiffs
        self.recordsToCreate = recordsToCreate
        self.recordsToUpdate = recordsToUpdate
        self.lintFindings = lintFindings
        self.warnings = warnings
        self.conflicts = conflicts
        self.unsupportedRows = unsupportedRows
        self.privacyNotes = privacyNotes
        self.backfillNotes = backfillNotes
        self.plainLanguageSummary = plainLanguageSummary
    }
}

public struct AtlasUniversalPreparedImport: Sendable {
    public var request: AtlasUniversalImportRequest
    public var stagedSnapshot: AtlasExportSnapshot
    public var dryRun: AtlasUniversalImportDryRunSummary

    public init(
        request: AtlasUniversalImportRequest,
        stagedSnapshot: AtlasExportSnapshot,
        dryRun: AtlasUniversalImportDryRunSummary
    ) {
        self.request = request
        self.stagedSnapshot = stagedSnapshot
        self.dryRun = dryRun
    }
}

public enum AtlasRestorePointActionKind: String, Codable, CaseIterable, Sendable {
    case replaceImport = "replace_import"
    case restoreCommit = "restore_commit"
}

public struct AtlasRestorePointSummary: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var title: String
    public var actionKind: AtlasRestorePointActionKind
    public var sourceSummary: String
    public var fileURL: URL
    public var rowCount: Int
    public var createdAt: Date

    public init(
        id: String,
        title: String,
        actionKind: AtlasRestorePointActionKind,
        sourceSummary: String,
        fileURL: URL,
        rowCount: Int,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.actionKind = actionKind
        self.sourceSummary = sourceSummary
        self.fileURL = fileURL
        self.rowCount = rowCount
        self.createdAt = createdAt
    }
}

public struct AtlasRestorePointPreview: Sendable, Equatable {
    public var restorePoint: AtlasRestorePointSummary
    public var datasetDiffs: [AtlasDatasetDiff]
    public var recordsToCreate: Int
    public var recordsToUpdate: Int
    public var warnings: [String]
    public var notes: [String]
    public var rowCount: Int

    public init(
        restorePoint: AtlasRestorePointSummary,
        datasetDiffs: [AtlasDatasetDiff],
        recordsToCreate: Int,
        recordsToUpdate: Int,
        warnings: [String],
        notes: [String],
        rowCount: Int
    ) {
        self.restorePoint = restorePoint
        self.datasetDiffs = datasetDiffs
        self.recordsToCreate = recordsToCreate
        self.recordsToUpdate = recordsToUpdate
        self.warnings = warnings
        self.notes = notes
        self.rowCount = rowCount
    }
}

public struct AtlasRestoreCommitResult: Sendable, Equatable {
    public var restoredPoint: AtlasRestorePointSummary
    public var backupURL: URL?
    public var restoredProtocolCount: Int
    public var restoredLogEventCount: Int
    public var nextDue: AtlasSharedNextDueSnapshot?

    public init(
        restoredPoint: AtlasRestorePointSummary,
        backupURL: URL?,
        restoredProtocolCount: Int,
        restoredLogEventCount: Int,
        nextDue: AtlasSharedNextDueSnapshot?
    ) {
        self.restoredPoint = restoredPoint
        self.backupURL = backupURL
        self.restoredProtocolCount = restoredProtocolCount
        self.restoredLogEventCount = restoredLogEventCount
        self.nextDue = nextDue
    }
}

public enum AtlasProviderHandoffPreset: String, Codable, CaseIterable, Sendable, Identifiable {
    case clinicianSummary = "clinician_summary"
    case coachSummary = "coach_summary"
    case partnerReview = "partner_review"
    case selfArchive = "self_archive"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .clinicianSummary:
            return "Clinician summary"
        case .coachSummary:
            return "Coach summary"
        case .partnerReview:
            return "Partner review"
        case .selfArchive:
            return "Self archive"
        }
    }

    public var subtitle: String {
        switch self {
        case .clinicianSummary:
            return "Current protocol snapshot with canonical labels."
        case .coachSummary:
            return "Selected protocol timeline context with bounded rows."
        case .partnerReview:
            return "Alias-safe summary with minimal surface area."
        case .selfArchive:
            return "Static date-range archive for your own records."
        }
    }

    public var scopeKind: AtlasProviderHandoffScopeKind {
        switch self {
        case .clinicianSummary:
            return .currentProtocolOnly
        case .coachSummary:
            return .selectedProtocols
        case .partnerReview:
            return .summaryOnly
        case .selfArchive:
            return .customDateRange
        }
    }

    public var aliasModeEnabled: Bool {
        switch self {
        case .partnerReview:
            return true
        default:
            return false
        }
    }
}

public enum AtlasProviderHandoffScopeKind: String, Codable, CaseIterable, Sendable {
    case currentProtocolOnly = "current_protocol_only"
    case selectedProtocols = "selected_protocols"
    case last30Days = "last_30_days"
    case symptomsOnly = "symptoms_only"
    case inventoryOnly = "inventory_only"
    case summaryOnly = "summary_only"
    case customDateRange = "custom_date_range"
}

public struct AtlasProviderHandoffRequest: Sendable, Equatable {
    public var scopeKind: AtlasProviderHandoffScopeKind
    public var protocolID: String?
    public var protocolIDs: [String]
    public var dateRange: AtlasDateRange?
    public var aliasModeEnabled: Bool

    public init(
        scopeKind: AtlasProviderHandoffScopeKind,
        protocolID: String? = nil,
        protocolIDs: [String] = [],
        dateRange: AtlasDateRange? = nil,
        aliasModeEnabled: Bool
    ) {
        self.scopeKind = scopeKind
        self.protocolID = protocolID
        self.protocolIDs = protocolIDs
        self.dateRange = dateRange
        self.aliasModeEnabled = aliasModeEnabled
    }
}

public struct AtlasProviderHandoffDatasetSummary: Codable, Sendable, Equatable, Identifiable {
    public var id: String { dataset }
    public var dataset: String
    public var rowCount: Int

    public init(dataset: String, rowCount: Int) {
        self.dataset = dataset
        self.rowCount = rowCount
    }
}

public struct AtlasProviderHandoffPreviewSection: Sendable, Equatable, Identifiable {
    public var id: String { title }
    public var title: String
    public var lines: [String]

    public init(title: String, lines: [String]) {
        self.title = title
        self.lines = lines
    }
}

public struct AtlasProviderHandoffPreview: Sendable, Equatable {
    public var scopeKind: AtlasProviderHandoffScopeKind
    public var renderMode: AtlasPrivacyRenderMode
    public var summary: String
    public var plainLanguageSummary: AtlasGeneratedSummary?
    public var datasets: [AtlasProviderHandoffDatasetSummary]
    public var sections: [AtlasProviderHandoffPreviewSection]
    public var rowCount: Int

    public init(
        scopeKind: AtlasProviderHandoffScopeKind,
        renderMode: AtlasPrivacyRenderMode,
        summary: String,
        plainLanguageSummary: AtlasGeneratedSummary? = nil,
        datasets: [AtlasProviderHandoffDatasetSummary],
        sections: [AtlasProviderHandoffPreviewSection],
        rowCount: Int
    ) {
        self.scopeKind = scopeKind
        self.renderMode = renderMode
        self.summary = summary
        self.plainLanguageSummary = plainLanguageSummary
        self.datasets = datasets
        self.sections = sections
        self.rowCount = rowCount
    }
}

public struct AtlasProviderHandoffResult: Sendable, Equatable {
    public var directoryURL: URL
    public var summaryURL: URL
    public var attachmentURL: URL
    public var preview: AtlasProviderHandoffPreview
    public var manifestVersion: Int

    public init(
        directoryURL: URL,
        summaryURL: URL,
        attachmentURL: URL,
        preview: AtlasProviderHandoffPreview,
        manifestVersion: Int
    ) {
        self.directoryURL = directoryURL
        self.summaryURL = summaryURL
        self.attachmentURL = attachmentURL
        self.preview = preview
        self.manifestVersion = manifestVersion
    }
}

public extension AtlasProviderHandoffPreset {
    func makeRequest(
        protocolID: String?,
        protocolIDs: [String],
        dateRange: AtlasDateRange?,
        now: Date = Date()
    ) -> AtlasProviderHandoffRequest {
        let fallbackRange = AtlasDateRange(
            start: Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now,
            end: now
        )

        return AtlasProviderHandoffRequest(
            scopeKind: scopeKind,
            protocolID: scopeKind == .currentProtocolOnly || scopeKind == .summaryOnly || scopeKind == .inventoryOnly
                ? protocolID
                : nil,
            protocolIDs: scopeKind == .selectedProtocols || scopeKind == .customDateRange
                ? protocolIDs
                : [],
            dateRange: scopeKind == .customDateRange ? (dateRange ?? fallbackRange) : nil,
            aliasModeEnabled: aliasModeEnabled
        )
    }
}
