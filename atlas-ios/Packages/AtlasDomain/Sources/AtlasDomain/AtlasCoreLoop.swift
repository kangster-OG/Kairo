import Foundation

public struct AtlasProtocolDraft: Equatable, Sendable {
    public var name: String
    public var kind: AtlasProtocolKind
    public var cadenceType: AtlasProtocolRuleType
    public var intervalDays: Int
    public var weekday: Int?
    public var defaultTimeOfDay: String?
    public var doseAmount: Double?
    public var doseUnit: String?
    public var notes: String?

    public init(
        name: String,
        kind: AtlasProtocolKind,
        cadenceType: AtlasProtocolRuleType,
        intervalDays: Int = 1,
        weekday: Int? = nil,
        defaultTimeOfDay: String? = nil,
        doseAmount: Double? = nil,
        doseUnit: String? = nil,
        notes: String? = nil
    ) {
        self.name = name
        self.kind = kind
        self.cadenceType = cadenceType
        self.intervalDays = intervalDays
        self.weekday = weekday
        self.defaultTimeOfDay = defaultTimeOfDay
        self.doseAmount = doseAmount
        self.doseUnit = doseUnit
        self.notes = notes
    }
}

public enum AtlasOccurrenceDisplayState: String, Equatable, Sendable {
    case overdue
    case due
    case upcoming
    case completed
    case skipped
    case superseded
}

public struct AtlasScheduledOccurrence: Identifiable, Hashable, Sendable {
    public var id: String
    public var protocolID: String
    public var canonicalTitle: String
    public var aliasTitle: String?
    public var kindLabel: String
    public var cadenceLabel: String
    public var doseLabel: String?
    public var scheduledAt: Date
    public var state: AtlasOccurrenceDisplayState

    public init(
        id: String,
        protocolID: String,
        canonicalTitle: String,
        aliasTitle: String?,
        kindLabel: String,
        cadenceLabel: String,
        doseLabel: String?,
        scheduledAt: Date,
        state: AtlasOccurrenceDisplayState
    ) {
        self.id = id
        self.protocolID = protocolID
        self.canonicalTitle = canonicalTitle
        self.aliasTitle = aliasTitle
        self.kindLabel = kindLabel
        self.cadenceLabel = cadenceLabel
        self.doseLabel = doseLabel
        self.scheduledAt = scheduledAt
        self.state = state
    }
}

public struct AtlasTodaySnapshot: Equatable, Sendable {
    public var hasProtocols: Bool
    public var nextDue: AtlasScheduledOccurrence?
    public var overdue: [AtlasScheduledOccurrence]
    public var upcoming: [AtlasScheduledOccurrence]

    public init(
        hasProtocols: Bool,
        nextDue: AtlasScheduledOccurrence?,
        overdue: [AtlasScheduledOccurrence],
        upcoming: [AtlasScheduledOccurrence]
    ) {
        self.hasProtocols = hasProtocols
        self.nextDue = nextDue
        self.overdue = overdue
        self.upcoming = upcoming
    }
}

public struct AtlasProtocolDetailSnapshot: Identifiable, Equatable, Sendable {
    public var id: String
    public var canonicalTitle: String
    public var aliasTitle: String?
    public var status: AtlasProtocolStatus
    public var kindLabel: String
    public var cadenceLabel: String
    public var doseLabel: String?
    public var notes: String?
    public var editableDraft: AtlasProtocolDraft
    public var nextOccurrence: AtlasScheduledOccurrence?

    public init(
        id: String,
        canonicalTitle: String,
        aliasTitle: String?,
        status: AtlasProtocolStatus,
        kindLabel: String,
        cadenceLabel: String,
        doseLabel: String?,
        notes: String?,
        editableDraft: AtlasProtocolDraft,
        nextOccurrence: AtlasScheduledOccurrence?
    ) {
        self.id = id
        self.canonicalTitle = canonicalTitle
        self.aliasTitle = aliasTitle
        self.status = status
        self.kindLabel = kindLabel
        self.cadenceLabel = cadenceLabel
        self.doseLabel = doseLabel
        self.notes = notes
        self.editableDraft = editableDraft
        self.nextOccurrence = nextOccurrence
    }
}

public enum AtlasTimelineFilter: String, CaseIterable, Equatable, Sendable, Identifiable {
    case all
    case dosing
    case changes
    case wellness

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all: "All"
        case .dosing: "Doses"
        case .changes: "Changes"
        case .wellness: "Wellness"
        }
    }
}

public enum AtlasTimelineEntryType: String, Equatable, Sendable {
    case doseTaken
    case doseSkipped
    case doseRescheduled
    case protocolCreated
    case protocolEdited
    case weightLogged
    case symptomLogged
    case customMetricLogged
}

public struct AtlasTimelineQuery: Equatable, Sendable {
    public var filter: AtlasTimelineFilter
    public var protocolID: String?
    public var limit: Int

    public init(filter: AtlasTimelineFilter = .all, protocolID: String? = nil, limit: Int = 100) {
        self.filter = filter
        self.protocolID = protocolID
        self.limit = limit
    }
}

public struct AtlasTimelineEntry: Identifiable, Hashable, Sendable {
    public var id: String
    public var protocolID: String
    public var canonicalTitle: String
    public var aliasTitle: String?
    public var type: AtlasTimelineEntryType
    public var summary: String
    public var recordedAt: Date

    public init(
        id: String,
        protocolID: String,
        canonicalTitle: String,
        aliasTitle: String?,
        type: AtlasTimelineEntryType,
        summary: String,
        recordedAt: Date
    ) {
        self.id = id
        self.protocolID = protocolID
        self.canonicalTitle = canonicalTitle
        self.aliasTitle = aliasTitle
        self.type = type
        self.summary = summary
        self.recordedAt = recordedAt
    }
}

public enum AtlasOccurrenceLogAction: String, Equatable, Sendable {
    case taken
    case skipped
    case rescheduled
}

public struct AtlasOccurrenceLogRequest: Equatable, Sendable {
    public var occurrenceID: String
    public var protocolID: String
    public var action: AtlasOccurrenceLogAction
    public var siteID: String?
    public var note: String?
    public var rescheduledAt: Date?

    public init(
        occurrenceID: String,
        protocolID: String,
        action: AtlasOccurrenceLogAction,
        siteID: String? = nil,
        note: String? = nil,
        rescheduledAt: Date? = nil
    ) {
        self.occurrenceID = occurrenceID
        self.protocolID = protocolID
        self.action = action
        self.siteID = siteID
        self.note = note
        self.rescheduledAt = rescheduledAt
    }
}
