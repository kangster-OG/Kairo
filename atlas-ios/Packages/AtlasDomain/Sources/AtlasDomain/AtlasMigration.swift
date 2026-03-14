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

public struct AtlasUniversalImportDryRunSummary: Sendable, Equatable {
    public var importer: AtlasImporterKind
    public var sourceSummary: String
    public var datasetDiffs: [AtlasDatasetDiff]
    public var recordsToCreate: Int
    public var recordsToUpdate: Int
    public var warnings: [String]
    public var conflicts: [String]
    public var unsupportedRows: [String]
    public var privacyNotes: [String]
    public var backfillNotes: [String]

    public init(
        importer: AtlasImporterKind,
        sourceSummary: String,
        datasetDiffs: [AtlasDatasetDiff],
        recordsToCreate: Int,
        recordsToUpdate: Int,
        warnings: [String],
        conflicts: [String],
        unsupportedRows: [String],
        privacyNotes: [String],
        backfillNotes: [String]
    ) {
        self.importer = importer
        self.sourceSummary = sourceSummary
        self.datasetDiffs = datasetDiffs
        self.recordsToCreate = recordsToCreate
        self.recordsToUpdate = recordsToUpdate
        self.warnings = warnings
        self.conflicts = conflicts
        self.unsupportedRows = unsupportedRows
        self.privacyNotes = privacyNotes
        self.backfillNotes = backfillNotes
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
    public var datasets: [AtlasProviderHandoffDatasetSummary]
    public var sections: [AtlasProviderHandoffPreviewSection]
    public var rowCount: Int

    public init(
        scopeKind: AtlasProviderHandoffScopeKind,
        renderMode: AtlasPrivacyRenderMode,
        summary: String,
        datasets: [AtlasProviderHandoffDatasetSummary],
        sections: [AtlasProviderHandoffPreviewSection],
        rowCount: Int
    ) {
        self.scopeKind = scopeKind
        self.renderMode = renderMode
        self.summary = summary
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
