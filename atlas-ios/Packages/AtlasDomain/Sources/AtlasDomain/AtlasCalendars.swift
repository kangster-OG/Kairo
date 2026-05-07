import Foundation

public enum AtlasCalendarAuthorizationStatus: String, Equatable, Sendable {
    case notDetermined
    case denied
    case restricted
    case writeOnly
    case fullAccess
    case unavailable

    public var canListCalendars: Bool {
        switch self {
        case .fullAccess, .writeOnly:
            return true
        case .notDetermined, .denied, .restricted, .unavailable:
            return false
        }
    }

    public var canManageEvents: Bool {
        self == .fullAccess
    }
}

public struct AtlasExternalCalendarDescriptor: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var title: String
    public var sourceTitle: String

    public init(
        id: String,
        title: String,
        sourceTitle: String
    ) {
        self.id = id
        self.title = title
        self.sourceTitle = sourceTitle
    }
}

public struct AtlasExternalCalendarSettingsSnapshot: Codable, Equatable, Sendable {
    public var syncEnabled: Bool
    public var selectedCalendarID: String?
    public var selectedCalendarTitle: String?
    public var syncedEventCount: Int
    public var lastSyncAt: String?
    public var lastError: String?

    public init(
        syncEnabled: Bool = false,
        selectedCalendarID: String? = nil,
        selectedCalendarTitle: String? = nil,
        syncedEventCount: Int = 0,
        lastSyncAt: String? = nil,
        lastError: String? = nil
    ) {
        self.syncEnabled = syncEnabled
        self.selectedCalendarID = selectedCalendarID
        self.selectedCalendarTitle = selectedCalendarTitle
        self.syncedEventCount = syncedEventCount
        self.lastSyncAt = lastSyncAt
        self.lastError = lastError
    }
}

public struct AtlasExternalCalendarSettingsUpdate: Equatable, Sendable {
    public enum CalendarSelection: Equatable, Sendable {
        case keepCurrent
        case clear
        case select(AtlasExternalCalendarDescriptor)
    }

    public var syncEnabled: Bool?
    public var calendarSelection: CalendarSelection
    public var clearError: Bool

    public init(
        syncEnabled: Bool? = nil,
        calendarSelection: CalendarSelection = .keepCurrent,
        clearError: Bool = false
    ) {
        self.syncEnabled = syncEnabled
        self.calendarSelection = calendarSelection
        self.clearError = clearError
    }
}

public struct AtlasExternalCalendarEventDraft: Equatable, Sendable {
    public var stableID: String
    public var occurrenceID: String
    public var protocolID: String
    public var calendarID: String
    public var title: String
    public var notes: String
    public var startDate: Date
    public var endDate: Date
    public var url: URL?

    public init(
        stableID: String,
        occurrenceID: String,
        protocolID: String,
        calendarID: String,
        title: String,
        notes: String,
        startDate: Date,
        endDate: Date,
        url: URL? = nil
    ) {
        self.stableID = stableID
        self.occurrenceID = occurrenceID
        self.protocolID = protocolID
        self.calendarID = calendarID
        self.title = title
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.url = url
    }
}

public struct AtlasExternalCalendarSavedEvent: Equatable, Sendable {
    public var eventIdentifier: String

    public init(eventIdentifier: String) {
        self.eventIdentifier = eventIdentifier
    }
}
