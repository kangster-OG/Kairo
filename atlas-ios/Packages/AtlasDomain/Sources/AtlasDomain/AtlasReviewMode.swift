import Foundation

public enum AtlasReviewScopeKind: String, Codable, CaseIterable, Sendable {
    case currentProtocol = "current_protocol"
    case selectedProtocols = "selected_protocols"
    case last30Days = "last_30_days"
    case symptomsOnly = "symptoms_only"
    case inventoryOnly = "inventory_only"
    case summaryOnly = "summary_only"
    case customDateRange = "custom_date_range"
}

public enum AtlasReviewDeliveryKind: String, Codable, CaseIterable, Sendable {
    case staticPack = "static_pack"
    case liveSession = "live_session"
}

public enum AtlasReviewPreset: String, Codable, CaseIterable, Sendable, Identifiable {
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
            return "Selected protocol context in a read-only pack."
        case .partnerReview:
            return "Alias-safe summary with minimal scope."
        case .selfArchive:
            return "Static date-range archive for your own records."
        }
    }

    public var scopeKind: AtlasReviewScopeKind {
        switch self {
        case .clinicianSummary:
            return .currentProtocol
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

    public var defaultExpirationDays: Int? {
        switch self {
        case .partnerReview:
            return 14
        case .coachSummary:
            return 14
        default:
            return nil
        }
    }
}

public enum AtlasReviewSessionStatus: String, Codable, CaseIterable, Sendable {
    case active
    case expired
    case revoked
}

public struct AtlasReviewRequest: Sendable, Equatable {
    public var scopeKind: AtlasReviewScopeKind
    public var protocolID: String?
    public var protocolIDs: [String]
    public var dateRange: AtlasDateRange?
    public var aliasModeEnabled: Bool
    public var expiresAt: Date?
    public var deliveryKind: AtlasReviewDeliveryKind

    public init(
        scopeKind: AtlasReviewScopeKind,
        protocolID: String? = nil,
        protocolIDs: [String] = [],
        dateRange: AtlasDateRange? = nil,
        aliasModeEnabled: Bool,
        expiresAt: Date? = nil,
        deliveryKind: AtlasReviewDeliveryKind = .staticPack
    ) {
        self.scopeKind = scopeKind
        self.protocolID = protocolID
        self.protocolIDs = protocolIDs
        self.dateRange = dateRange
        self.aliasModeEnabled = aliasModeEnabled
        self.expiresAt = expiresAt
        self.deliveryKind = deliveryKind
    }
}

public struct AtlasReviewDatasetSummary: Codable, Sendable, Equatable, Identifiable {
    public var id: String { dataset }
    public var dataset: String
    public var rowCount: Int

    public init(dataset: String, rowCount: Int) {
        self.dataset = dataset
        self.rowCount = rowCount
    }
}

public struct AtlasReviewSection: Codable, Sendable, Equatable, Identifiable {
    public var id: String { title }
    public var title: String
    public var lines: [String]

    public init(title: String, lines: [String]) {
        self.title = title
        self.lines = lines
    }
}

public struct AtlasReviewWorkspace: Codable, Sendable, Equatable {
    public var scopeKind: AtlasReviewScopeKind
    public var renderMode: AtlasPrivacyRenderMode
    public var readOnly: Bool
    public var summary: String
    public var sections: [AtlasReviewSection]
    public var datasets: [AtlasReviewDatasetSummary]
    public var rowCount: Int
    public var createdAt: Date
    public var expiresAt: Date?
    public var sourceDescription: String

    public init(
        scopeKind: AtlasReviewScopeKind,
        renderMode: AtlasPrivacyRenderMode,
        readOnly: Bool,
        summary: String,
        sections: [AtlasReviewSection],
        datasets: [AtlasReviewDatasetSummary],
        rowCount: Int,
        createdAt: Date,
        expiresAt: Date?,
        sourceDescription: String
    ) {
        self.scopeKind = scopeKind
        self.renderMode = renderMode
        self.readOnly = readOnly
        self.summary = summary
        self.sections = sections
        self.datasets = datasets
        self.rowCount = rowCount
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.sourceDescription = sourceDescription
    }
}

public struct AtlasReviewSessionSummary: Sendable, Equatable, Identifiable {
    public var id: String
    public var title: String
    public var scopeKind: AtlasReviewScopeKind
    public var deliveryKind: AtlasReviewDeliveryKind
    public var renderMode: AtlasPrivacyRenderMode
    public var rowCount: Int
    public var createdAt: Date
    public var expiresAt: Date?
    public var status: AtlasReviewSessionStatus
    public var canRevoke: Bool
    public var summaryURL: URL?
    public var packURL: URL?
    public var summary: String

    public init(
        id: String,
        title: String,
        scopeKind: AtlasReviewScopeKind,
        deliveryKind: AtlasReviewDeliveryKind,
        renderMode: AtlasPrivacyRenderMode,
        rowCount: Int,
        createdAt: Date,
        expiresAt: Date?,
        status: AtlasReviewSessionStatus,
        canRevoke: Bool,
        summaryURL: URL?,
        packURL: URL?,
        summary: String
    ) {
        self.id = id
        self.title = title
        self.scopeKind = scopeKind
        self.deliveryKind = deliveryKind
        self.renderMode = renderMode
        self.rowCount = rowCount
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.status = status
        self.canRevoke = canRevoke
        self.summaryURL = summaryURL
        self.packURL = packURL
        self.summary = summary
    }
}

public struct AtlasReviewOwnerSnapshot: Sendable, Equatable {
    public var sessions: [AtlasReviewSessionSummary]
    public var liveReviewEnabled: Bool

    public init(
        sessions: [AtlasReviewSessionSummary],
        liveReviewEnabled: Bool
    ) {
        self.sessions = sessions
        self.liveReviewEnabled = liveReviewEnabled
    }
}

public struct AtlasReviewCreationResult: Sendable, Equatable {
    public var session: AtlasReviewSessionSummary
    public var workspace: AtlasReviewWorkspace
    public var summaryURL: URL
    public var packURL: URL
    public var manifestVersion: Int

    public init(
        session: AtlasReviewSessionSummary,
        workspace: AtlasReviewWorkspace,
        summaryURL: URL,
        packURL: URL,
        manifestVersion: Int
    ) {
        self.session = session
        self.workspace = workspace
        self.summaryURL = summaryURL
        self.packURL = packURL
        self.manifestVersion = manifestVersion
    }
}

public extension AtlasReviewPreset {
    func makeRequest(
        protocolID: String?,
        protocolIDs: [String],
        dateRange: AtlasDateRange?,
        now: Date = Date()
    ) -> AtlasReviewRequest {
        let fallbackRange = AtlasDateRange(
            start: Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now,
            end: now
        )
        let expiration = defaultExpirationDays.flatMap {
            Calendar.current.date(byAdding: .day, value: $0, to: now)
        }

        return AtlasReviewRequest(
            scopeKind: scopeKind,
            protocolID: scopeKind == .currentProtocol || scopeKind == .inventoryOnly || scopeKind == .summaryOnly
                ? protocolID
                : nil,
            protocolIDs: scopeKind == .selectedProtocols || scopeKind == .customDateRange
                ? protocolIDs
                : [],
            dateRange: scopeKind == .customDateRange ? (dateRange ?? fallbackRange) : nil,
            aliasModeEnabled: aliasModeEnabled,
            expiresAt: expiration,
            deliveryKind: .staticPack
        )
    }
}
