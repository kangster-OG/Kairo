import Foundation

public struct AtlasTrustVaultSnapshot: Sendable, Equatable {
    public var privacyProfile: AtlasPrivacyProfileRecord
    public var aliases: [AtlasTrustVaultAliasItem]
    public var audits: [AtlasTrustVaultAuditItem]

    public init(
        privacyProfile: AtlasPrivacyProfileRecord,
        aliases: [AtlasTrustVaultAliasItem],
        audits: [AtlasTrustVaultAuditItem]
    ) {
        self.privacyProfile = privacyProfile
        self.aliases = aliases
        self.audits = audits
    }
}

public struct AtlasTrustVaultAliasItem: Sendable, Equatable, Identifiable {
    public var id: String { protocolID }
    public var protocolID: String
    public var canonicalTitle: String
    public var kind: AtlasProtocolKind
    public var aliasLabel: String?
    public var aliasCompoundLabel: String?

    public init(
        protocolID: String,
        canonicalTitle: String,
        kind: AtlasProtocolKind,
        aliasLabel: String?,
        aliasCompoundLabel: String?
    ) {
        self.protocolID = protocolID
        self.canonicalTitle = canonicalTitle
        self.kind = kind
        self.aliasLabel = aliasLabel
        self.aliasCompoundLabel = aliasCompoundLabel
    }
}

public struct AtlasTrustVaultAuditItem: Sendable, Equatable, Identifiable {
    public var id: String
    public var eventType: AtlasSensitiveActionAuditEventType
    public var summary: String
    public var createdAt: Date

    public init(
        id: String,
        eventType: AtlasSensitiveActionAuditEventType,
        summary: String,
        createdAt: Date
    ) {
        self.id = id
        self.eventType = eventType
        self.summary = summary
        self.createdAt = createdAt
    }
}

public struct AtlasTrustVaultProfileUpdate: Sendable, Equatable {
    public var renderMode: AtlasPrivacyRenderMode?
    public var biometricLockEnabled: Bool?
    public var biometricGateMode: AtlasBiometricGateMode?
    public var shareAliasByDefault: Bool?
    public var exportAliasByDefault: Bool?

    public init(
        renderMode: AtlasPrivacyRenderMode? = nil,
        biometricLockEnabled: Bool? = nil,
        biometricGateMode: AtlasBiometricGateMode? = nil,
        shareAliasByDefault: Bool? = nil,
        exportAliasByDefault: Bool? = nil
    ) {
        self.renderMode = renderMode
        self.biometricLockEnabled = biometricLockEnabled
        self.biometricGateMode = biometricGateMode
        self.shareAliasByDefault = shareAliasByDefault
        self.exportAliasByDefault = exportAliasByDefault
    }
}

public struct AtlasProtocolAliasDraft: Sendable, Equatable {
    public var protocolID: String
    public var aliasLabel: String
    public var aliasCompoundLabel: String?

    public init(
        protocolID: String,
        aliasLabel: String,
        aliasCompoundLabel: String? = nil
    ) {
        self.protocolID = protocolID
        self.aliasLabel = aliasLabel
        self.aliasCompoundLabel = aliasCompoundLabel
    }
}

public enum AtlasRawExportFormat: String, Codable, CaseIterable, Sendable {
    case json
    case csv
}

public struct AtlasRawExportRequest: Sendable, Equatable {
    public var format: AtlasRawExportFormat
    public var renderMode: AtlasPrivacyRenderMode

    public init(
        format: AtlasRawExportFormat,
        renderMode: AtlasPrivacyRenderMode
    ) {
        self.format = format
        self.renderMode = renderMode
    }
}

public struct AtlasRawExportResult: Sendable, Equatable {
    public var format: AtlasRawExportFormat
    public var renderMode: AtlasPrivacyRenderMode
    public var fileURL: URL
    public var rowCount: Int
    public var manifestVersion: Int

    public init(
        format: AtlasRawExportFormat,
        renderMode: AtlasPrivacyRenderMode,
        fileURL: URL,
        rowCount: Int,
        manifestVersion: Int
    ) {
        self.format = format
        self.renderMode = renderMode
        self.fileURL = fileURL
        self.rowCount = rowCount
        self.manifestVersion = manifestVersion
    }
}

public struct AtlasDateRange: Codable, Sendable, Equatable {
    public var start: Date
    public var end: Date

    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}

public enum AtlasShareFacet: String, Codable, CaseIterable, Sendable {
    case logs
    case symptoms
    case inventory
    case summary
}

public enum AtlasSelectiveShareScopeKind: String, Codable, CaseIterable, Sendable {
    case currentProtocolOnly = "current_protocol_only"
    case protocolWithRecentTimeline = "protocol_with_recent_timeline"
    case last30DaysLogs = "last_30_days_logs"
    case symptomsOnly = "symptoms_only"
    case inventoryOnly = "inventory_only"
    case summaryOnly = "summary_only"
    case customDateRange = "custom_date_range"
}

public struct AtlasSelectiveShareRequest: Sendable, Equatable {
    public var scopeKind: AtlasSelectiveShareScopeKind
    public var renderMode: AtlasPrivacyRenderMode
    public var protocolID: String?
    public var protocolIDs: [String]
    public var dateRange: AtlasDateRange?
    public var include: [AtlasShareFacet]

    public init(
        scopeKind: AtlasSelectiveShareScopeKind,
        renderMode: AtlasPrivacyRenderMode,
        protocolID: String? = nil,
        protocolIDs: [String] = [],
        dateRange: AtlasDateRange? = nil,
        include: [AtlasShareFacet] = []
    ) {
        self.scopeKind = scopeKind
        self.renderMode = renderMode
        self.protocolID = protocolID
        self.protocolIDs = protocolIDs
        self.dateRange = dateRange
        self.include = include
    }
}

public struct AtlasSelectiveShareDatasetSummary: Codable, Sendable, Equatable, Identifiable {
    public var id: String { dataset }
    public var dataset: String
    public var rowCount: Int

    public init(dataset: String, rowCount: Int) {
        self.dataset = dataset
        self.rowCount = rowCount
    }
}

public struct AtlasSelectiveSharePreviewSection: Sendable, Equatable, Identifiable {
    public var id: String { title }
    public var title: String
    public var lines: [String]

    public init(title: String, lines: [String]) {
        self.title = title
        self.lines = lines
    }
}

public struct AtlasSelectiveSharePreview: Sendable, Equatable {
    public var scopeKind: AtlasSelectiveShareScopeKind
    public var renderMode: AtlasPrivacyRenderMode
    public var summary: String
    public var datasets: [AtlasSelectiveShareDatasetSummary]
    public var sections: [AtlasSelectiveSharePreviewSection]
    public var rowCount: Int

    public init(
        scopeKind: AtlasSelectiveShareScopeKind,
        renderMode: AtlasPrivacyRenderMode,
        summary: String,
        datasets: [AtlasSelectiveShareDatasetSummary],
        sections: [AtlasSelectiveSharePreviewSection],
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

public struct AtlasSelectiveShareResult: Sendable, Equatable {
    public var fileURL: URL
    public var shareCode: String
    public var preview: AtlasSelectiveSharePreview
    public var snapshot: AtlasExportSnapshot
    public var manifestVersion: Int

    public init(
        fileURL: URL,
        shareCode: String,
        preview: AtlasSelectiveSharePreview,
        snapshot: AtlasExportSnapshot,
        manifestVersion: Int
    ) {
        self.fileURL = fileURL
        self.shareCode = shareCode
        self.preview = preview
        self.snapshot = snapshot
        self.manifestVersion = manifestVersion
    }
}
