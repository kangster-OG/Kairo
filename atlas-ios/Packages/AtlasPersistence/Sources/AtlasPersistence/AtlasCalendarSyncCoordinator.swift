import AtlasDomain
import AtlasPrivacy
import AtlasSystem
import GRDB
import Foundation

private let atlasExternalCalendarEventDuration: TimeInterval = 15 * 60

private enum AtlasExternalCalendarSettingKey {
    static let syncEnabled = "external_calendar_sync_enabled"
    static let selectedCalendarID = "external_calendar_selected_calendar_id"
    static let selectedCalendarTitle = "external_calendar_selected_calendar_title"
    static let lastSyncAt = "external_calendar_last_sync_at"
    static let lastError = "external_calendar_last_error"
}

private struct AtlasExternalCalendarPlan {
    var selectedCalendarID: String?
    var existingEvents: [AtlasExternalCalendarEventDBRecord]
    var desiredEvents: [AtlasExternalCalendarEventDraft]
    var staleEvents: [AtlasExternalCalendarEventDBRecord]
}

public actor GRDBCalendarSyncCoordinator: CalendarSyncCoordinating {
    private let stack: AtlasDatabaseStack
    private let externalCalendars: any ExternalCalendarManaging
    private let privacyFormatter: AtlasPrivacyFormatter

    init(
        stack: AtlasDatabaseStack,
        externalCalendars: any ExternalCalendarManaging,
        privacyFormatter: AtlasPrivacyFormatter
    ) {
        self.stack = stack
        self.externalCalendars = externalCalendars
        self.privacyFormatter = privacyFormatter
    }

    public func authorizationStatus() async -> AtlasCalendarAuthorizationStatus {
        guard externalCalendars.isAvailable() else {
            return .unavailable
        }
        return await externalCalendars.authorizationStatus()
    }

    public func requestAuthorization() async throws -> AtlasCalendarAuthorizationStatus {
        guard externalCalendars.isAvailable() else {
            return .unavailable
        }

        let status = try await externalCalendars.requestFullAccess()
        if status.canManageEvents {
            try await clearExternalCalendarError()
            try await sync(referenceDate: Date())
        } else {
            try await persistExternalCalendarError(message: atlasCalendarPermissionMessage(for: status))
        }
        return status
    }

    public func fetchSettings() async throws -> AtlasExternalCalendarSettingsSnapshot {
        try await stack.canonical.read { db in
            try readExternalCalendarSettings(db: db)
        }
    }

    public func listWritableCalendars() async throws -> [AtlasExternalCalendarDescriptor] {
        try await externalCalendars.writableCalendars()
    }

    public func updateSettings(
        _ update: AtlasExternalCalendarSettingsUpdate,
        referenceDate: Date
    ) async throws -> AtlasExternalCalendarSettingsSnapshot {
        try await stack.canonical.write { db in
            if let syncEnabled = update.syncEnabled {
                try writeAppSetting(
                    db: db,
                    key: AtlasExternalCalendarSettingKey.syncEnabled,
                    value: syncEnabled ? "1" : "0",
                    now: referenceDate
                )
            }

            switch update.calendarSelection {
            case .keepCurrent:
                break
            case .clear:
                try writeAppSetting(
                    db: db,
                    key: AtlasExternalCalendarSettingKey.selectedCalendarID,
                    value: nil,
                    now: referenceDate
                )
                try writeAppSetting(
                    db: db,
                    key: AtlasExternalCalendarSettingKey.selectedCalendarTitle,
                    value: nil,
                    now: referenceDate
                )
            case .select(let descriptor):
                try writeAppSetting(
                    db: db,
                    key: AtlasExternalCalendarSettingKey.selectedCalendarID,
                    value: descriptor.id,
                    now: referenceDate
                )
                try writeAppSetting(
                    db: db,
                    key: AtlasExternalCalendarSettingKey.selectedCalendarTitle,
                    value: descriptor.title,
                    now: referenceDate
                )
            }

            if update.clearError {
                try writeAppSetting(
                    db: db,
                    key: AtlasExternalCalendarSettingKey.lastError,
                    value: nil,
                    now: referenceDate
                )
            }
        }

        try await sync(referenceDate: referenceDate)
        return try await fetchSettings()
    }

    public func sync(referenceDate: Date) async throws {
        guard externalCalendars.isAvailable() else {
            try await persistExternalCalendarError(message: AtlasExternalCalendarSystemError.unavailable.localizedDescription)
            return
        }

        let status = await authorizationStatus()
        let settings = try await fetchSettings()

        guard settings.syncEnabled else {
            try await clearExternalCalendarEvents(referenceDate: referenceDate, recordSyncTimestamp: false)
            return
        }

        guard status.canManageEvents else {
            try await persistExternalCalendarError(message: atlasCalendarPermissionMessage(for: status))
            return
        }

        guard let selectedCalendarID = settings.selectedCalendarID, selectedCalendarID.isEmpty == false else {
            try await clearExternalCalendarEvents(referenceDate: referenceDate)
            try await persistExternalCalendarError(message: "Choose a calendar before turning on external calendar sync.")
            return
        }

        do {
            try await GRDBCoreLoopRepository(stack: stack).ensureProjectedOccurrences(referenceDate: referenceDate)

            let writableCalendars = try await externalCalendars.writableCalendars()
            guard let selectedCalendar = writableCalendars.first(where: { $0.id == selectedCalendarID }) else {
                try await persistExternalCalendarError(message: AtlasExternalCalendarSystemError.calendarUnavailable.localizedDescription)
                return
            }
            try await persistSelectedCalendar(selectedCalendar, now: referenceDate)

            let plan = try await stack.canonical.read { db in
                try buildExternalCalendarPlan(
                    db: db,
                    referenceDate: referenceDate,
                    selectedCalendarID: selectedCalendar.id,
                    privacyFormatter: privacyFormatter
                )
            }

            let existingByOccurrenceID = Dictionary(
                uniqueKeysWithValues: plan.existingEvents.map { ($0.occurrenceId, $0) }
            )
            var savedEvents: [AtlasExternalCalendarEventDBRecord] = []
            savedEvents.reserveCapacity(plan.desiredEvents.count)

            for draft in plan.desiredEvents {
                let existingIdentifier = existingByOccurrenceID[draft.occurrenceID]
                    .flatMap { $0.calendarId == draft.calendarID ? $0.eventIdentifier : nil }
                let saved = try await externalCalendars.saveEvent(draft, existingIdentifier: existingIdentifier)
                let timestamp = atlasTimestamp(from: referenceDate)
                let existingRow = existingByOccurrenceID[draft.occurrenceID]
                savedEvents.append(
                    AtlasExternalCalendarEventDBRecord(
                        id: draft.stableID,
                        occurrenceId: draft.occurrenceID,
                        protocolId: draft.protocolID,
                        calendarId: draft.calendarID,
                        eventIdentifier: saved.eventIdentifier,
                        title: draft.title,
                        notes: draft.notes,
                        startsAt: atlasTimestamp(from: draft.startDate),
                        endsAt: atlasTimestamp(from: draft.endDate),
                        createdAt: existingRow?.createdAt ?? timestamp,
                        updatedAt: timestamp
                    )
                )
            }

            for stale in plan.staleEvents {
                try? await externalCalendars.deleteEvent(identifier: stale.eventIdentifier)
            }

            let persistedEvents = savedEvents
            try await stack.canonical.write { db in
                try replaceExternalCalendarEvents(persistedEvents, in: db)
                try writeAppSetting(
                    db: db,
                    key: AtlasExternalCalendarSettingKey.lastSyncAt,
                    value: atlasTimestamp(from: referenceDate),
                    now: referenceDate
                )
                try writeAppSetting(
                    db: db,
                    key: AtlasExternalCalendarSettingKey.lastError,
                    value: nil,
                    now: referenceDate
                )
            }
        } catch {
            try await persistExternalCalendarError(message: error.localizedDescription)
        }
    }
}

private func buildExternalCalendarPlan(
    db: Database,
    referenceDate: Date,
    selectedCalendarID: String,
    privacyFormatter: AtlasPrivacyFormatter
) throws -> AtlasExternalCalendarPlan {
    let context = try loadCoreLoopContext(db: db)
    let profile = try AtlasPrivacyProfileDBRecord.fetchOne(db)?.domain ?? .default()
    let renderMode = privacyFormatter.renderMode(for: profile)
    let existingEvents = try AtlasExternalCalendarEventDBRecord
        .order(Column("starts_at"))
        .fetchAll(db)

    let desiredEvents = context.pendingOccurrences.values
        .flatMap { $0 }
        .map {
            buildScheduledOccurrence(
                occurrence: $0,
                context: context,
                now: referenceDate
            )
        }
        .filter { $0.scheduledAt >= referenceDate }
        .sorted { $0.scheduledAt < $1.scheduledAt }
        .map { occurrence in
            buildExternalCalendarEventDraft(
                occurrence: occurrence,
                calendarID: selectedCalendarID,
                renderMode: renderMode,
                privacyFormatter: privacyFormatter
            )
        }

    let desiredOccurrenceIDs = Set(desiredEvents.map(\.occurrenceID))
    let staleEvents = existingEvents.filter { existing in
        existing.calendarId != selectedCalendarID || desiredOccurrenceIDs.contains(existing.occurrenceId) == false
    }

    return AtlasExternalCalendarPlan(
        selectedCalendarID: selectedCalendarID,
        existingEvents: existingEvents,
        desiredEvents: desiredEvents,
        staleEvents: staleEvents
    )
}

private func buildExternalCalendarEventDraft(
    occurrence: AtlasScheduledOccurrence,
    calendarID: String,
    renderMode: AtlasPrivacyRenderMode,
    privacyFormatter: AtlasPrivacyFormatter
) -> AtlasExternalCalendarEventDraft {
    let title: String
    let notes: String

    switch renderMode {
    case .discreet:
        title = "Atlas routine"
        notes = "Private Atlas routine. Open Atlas to review or log this occurrence."
    case .full, .alias:
        title = privacyFormatter.title(
            canonical: occurrence.canonicalTitle,
            alias: occurrence.aliasTitle,
            mode: renderMode
        )

        var lines = ["Scheduled from Atlas."]
        lines.append("Cadence: \(occurrence.cadenceLabel)")
        if let doseLabel = occurrence.doseLabel, doseLabel.isEmpty == false {
            lines.append("Dose: \(doseLabel)")
        }
        lines.append("Open Atlas to log or adjust this occurrence.")
        notes = lines.joined(separator: "\n")
    }

    return AtlasExternalCalendarEventDraft(
        stableID: "calendar:\(occurrence.id)",
        occurrenceID: occurrence.id,
        protocolID: occurrence.protocolID,
        calendarID: calendarID,
        title: title,
        notes: notes,
        startDate: occurrence.scheduledAt,
        endDate: occurrence.scheduledAt.addingTimeInterval(atlasExternalCalendarEventDuration),
        url: URL(string: "atlas://today")
    )
}

func readExternalCalendarSettings(db: Database) throws -> AtlasExternalCalendarSettingsSnapshot {
    let syncEnabledValue = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = ?",
        arguments: [AtlasExternalCalendarSettingKey.syncEnabled]
    )
    let selectedCalendarID = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = ?",
        arguments: [AtlasExternalCalendarSettingKey.selectedCalendarID]
    )
    let selectedCalendarTitle = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = ?",
        arguments: [AtlasExternalCalendarSettingKey.selectedCalendarTitle]
    )
    let lastSyncAt = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = ?",
        arguments: [AtlasExternalCalendarSettingKey.lastSyncAt]
    )
    let lastError = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = ?",
        arguments: [AtlasExternalCalendarSettingKey.lastError]
    )
    let syncedEventCount = try Int.fetchOne(
        db,
        sql: "SELECT COUNT(*) FROM external_calendar_events"
    ) ?? 0

    return AtlasExternalCalendarSettingsSnapshot(
        syncEnabled: syncEnabledValue == "1",
        selectedCalendarID: selectedCalendarID,
        selectedCalendarTitle: selectedCalendarTitle,
        syncedEventCount: syncedEventCount,
        lastSyncAt: lastSyncAt,
        lastError: lastError
    )
}

func replaceExternalCalendarEvents(
    _ events: [AtlasExternalCalendarEventDBRecord],
    in db: Database
) throws {
    try AtlasExternalCalendarEventDBRecord.deleteAll(db)
    for event in events {
        try event.insert(db)
    }
}

private func atlasCalendarPermissionMessage(
    for status: AtlasCalendarAuthorizationStatus
) -> String {
    switch status {
    case .notDetermined:
        return "Allow full calendar access to mirror upcoming occurrences."
    case .denied:
        return "Calendar access is denied for Atlas on this device."
    case .restricted:
        return "Calendar access is restricted on this device."
    case .writeOnly:
        return "Full calendar access is required to keep synced events up to date."
    case .fullAccess:
        return ""
    case .unavailable:
        return "Calendar sync is unavailable on this device."
    }
}

private extension GRDBCalendarSyncCoordinator {
    func persistExternalCalendarError(message: String) async throws {
        let now = Date()
        try await stack.canonical.write { db in
            try writeAppSetting(
                db: db,
                key: AtlasExternalCalendarSettingKey.lastError,
                value: message,
                now: now
            )
        }
    }

    func clearExternalCalendarError() async throws {
        let now = Date()
        try await stack.canonical.write { db in
            try writeAppSetting(
                db: db,
                key: AtlasExternalCalendarSettingKey.lastError,
                value: nil,
                now: now
            )
        }
    }

    func persistSelectedCalendar(
        _ descriptor: AtlasExternalCalendarDescriptor,
        now: Date
    ) async throws {
        try await stack.canonical.write { db in
            try writeAppSetting(
                db: db,
                key: AtlasExternalCalendarSettingKey.selectedCalendarID,
                value: descriptor.id,
                now: now
            )
            try writeAppSetting(
                db: db,
                key: AtlasExternalCalendarSettingKey.selectedCalendarTitle,
                value: descriptor.title,
                now: now
            )
        }
    }

    func clearExternalCalendarEvents(referenceDate: Date) async throws {
        try await clearExternalCalendarEvents(referenceDate: referenceDate, recordSyncTimestamp: true)
    }

    func clearExternalCalendarEvents(
        referenceDate: Date,
        recordSyncTimestamp: Bool
    ) async throws {
        let existingEvents = try await stack.canonical.read { db in
            try AtlasExternalCalendarEventDBRecord.fetchAll(db)
        }

        for event in existingEvents {
            try? await externalCalendars.deleteEvent(identifier: event.eventIdentifier)
        }

        try await stack.canonical.write { db in
            try replaceExternalCalendarEvents([], in: db)
            if recordSyncTimestamp {
                try writeAppSetting(
                    db: db,
                    key: AtlasExternalCalendarSettingKey.lastSyncAt,
                    value: atlasTimestamp(from: referenceDate),
                    now: referenceDate
                )
            }
            try writeAppSetting(
                db: db,
                key: AtlasExternalCalendarSettingKey.lastError,
                value: nil,
                now: referenceDate
            )
        }
    }
}
