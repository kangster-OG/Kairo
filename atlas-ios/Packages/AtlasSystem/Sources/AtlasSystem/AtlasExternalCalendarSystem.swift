import AtlasDomain
import Foundation
#if canImport(EventKit)
import EventKit
#endif

public protocol ExternalCalendarManaging: Sendable {
    func isAvailable() -> Bool
    func authorizationStatus() async -> AtlasCalendarAuthorizationStatus
    func requestFullAccess() async throws -> AtlasCalendarAuthorizationStatus
    func writableCalendars() async throws -> [AtlasExternalCalendarDescriptor]
    func saveEvent(
        _ draft: AtlasExternalCalendarEventDraft,
        existingIdentifier: String?
    ) async throws -> AtlasExternalCalendarSavedEvent
    func deleteEvent(identifier: String) async throws
}

public actor AtlasEventKitCalendarManager: @preconcurrency ExternalCalendarManaging {
    #if canImport(EventKit)
    private let store = EKEventStore()
    #endif

    public init() {}

    public nonisolated func isAvailable() -> Bool {
        #if canImport(EventKit)
        return true
        #else
        return false
        #endif
    }

    public func authorizationStatus() async -> AtlasCalendarAuthorizationStatus {
        #if canImport(EventKit)
        return atlasCalendarAuthorizationStatus(
            for: EKEventStore.authorizationStatus(for: .event)
        )
        #else
        return .unavailable
        #endif
    }

    public func requestFullAccess() async throws -> AtlasCalendarAuthorizationStatus {
        #if canImport(EventKit)
        if #available(iOS 17.0, macOS 14.0, *) {
            _ = try await store.requestFullAccessToEvents()
        } else {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                store.requestAccess(to: .event) { granted, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
        return await authorizationStatus()
        #else
        return .unavailable
        #endif
    }

    public func writableCalendars() async throws -> [AtlasExternalCalendarDescriptor] {
        #if canImport(EventKit)
        guard await authorizationStatus().canListCalendars else {
            return []
        }

        return store.calendars(for: .event)
            .filter(\.allowsContentModifications)
            .map {
                AtlasExternalCalendarDescriptor(
                    id: $0.calendarIdentifier,
                    title: $0.title,
                    sourceTitle: $0.source.title
                )
            }
            .sorted {
                if $0.sourceTitle == $1.sourceTitle {
                    return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
                return $0.sourceTitle.localizedCaseInsensitiveCompare($1.sourceTitle) == .orderedAscending
            }
        #else
        return []
        #endif
    }

    public func saveEvent(
        _ draft: AtlasExternalCalendarEventDraft,
        existingIdentifier: String?
    ) async throws -> AtlasExternalCalendarSavedEvent {
        #if canImport(EventKit)
        guard let calendar = store.calendar(withIdentifier: draft.calendarID),
              calendar.allowsContentModifications else {
            throw AtlasExternalCalendarSystemError.calendarUnavailable
        }

        let event: EKEvent
        if let existingIdentifier,
           let existingEvent = store.event(withIdentifier: existingIdentifier) {
            event = existingEvent
        } else {
            event = EKEvent(eventStore: store)
        }

        event.calendar = calendar
        event.title = draft.title
        event.notes = draft.notes
        event.startDate = draft.startDate
        event.endDate = max(draft.endDate, draft.startDate.addingTimeInterval(60))
        event.url = draft.url
        event.timeZone = .current

        try store.save(event, span: .thisEvent, commit: true)
        guard let eventIdentifier = event.eventIdentifier else {
            throw AtlasExternalCalendarSystemError.saveFailed
        }
        return AtlasExternalCalendarSavedEvent(eventIdentifier: eventIdentifier)
        #else
        _ = draft
        _ = existingIdentifier
        throw AtlasExternalCalendarSystemError.unavailable
        #endif
    }

    public func deleteEvent(identifier: String) async throws {
        #if canImport(EventKit)
        guard let event = store.event(withIdentifier: identifier) else {
            return
        }
        try store.remove(event, span: .thisEvent, commit: true)
        #else
        _ = identifier
        #endif
    }
}

public enum AtlasExternalCalendarSystemError: LocalizedError {
    case unavailable
    case calendarUnavailable
    case saveFailed

    public var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Calendar sync is unavailable on this device."
        case .calendarUnavailable:
            return "The selected calendar is no longer available."
        case .saveFailed:
            return "Atlas couldn't save the calendar event."
        }
    }
}

#if canImport(EventKit)
private func atlasCalendarAuthorizationStatus(
    for status: EKAuthorizationStatus
) -> AtlasCalendarAuthorizationStatus {
    switch status {
    case .notDetermined:
        return .notDetermined
    case .restricted:
        return .restricted
    case .denied:
        return .denied
    case .authorized:
        return .fullAccess
    case .fullAccess:
        return .fullAccess
    case .writeOnly:
        return .writeOnly
    @unknown default:
        return .denied
    }
}
#endif
