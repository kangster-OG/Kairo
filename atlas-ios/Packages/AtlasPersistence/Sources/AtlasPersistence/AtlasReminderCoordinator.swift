import AtlasDomain
import AtlasPrivacy
import AtlasSystem
import GRDB
import Foundation

private let atlasReminderScheduleSkew: TimeInterval = 5

public struct GRDBReminderRepository: ReminderRepository, Sendable {
    let stack: AtlasDatabaseStack

    init(stack: AtlasDatabaseStack) {
        self.stack = stack
    }

    public func fetchReminderSettings() async throws -> AtlasReminderSettingsSnapshot {
        try await stack.canonical.read { db in
            let preference = try fetchReminderPreference(db: db)
            return AtlasReminderSettingsSnapshot(
                remindersEnabled: preference.remindersEnabled,
                privacyMode: preference.privacyMode,
                leadTimeMinutes: preference.leadTimeMinutes
            )
        }
    }

    public func listScheduledReminders() async throws -> [AtlasReminderRecord] {
        try await stack.canonical.read { db in
            try AtlasReminderDBRecord
                .order(Column("scheduled_for"))
                .fetchAll(db)
                .map(\.domain)
        }
    }
}

public actor GRDBReminderCoordinator: ReminderCoordinating {
    private let stack: AtlasDatabaseStack
    private let notifications: any NotificationManaging
    private let privacyFormatter: AtlasPrivacyFormatter
    private var actionAppliedHandler: (@Sendable () async -> Void)?
    private var hasConfiguredNotifications = false

    init(
        stack: AtlasDatabaseStack,
        notifications: any NotificationManaging,
        privacyFormatter: AtlasPrivacyFormatter
    ) {
        self.stack = stack
        self.notifications = notifications
        self.privacyFormatter = privacyFormatter
    }

    public func authorizationStatus() async -> AtlasNotificationAuthorizationStatus {
        await notifications.authorizationStatus()
    }

    public func requestAuthorization() async throws -> AtlasNotificationAuthorizationStatus {
        let status = try await notifications.requestAuthorization()
        if status.canScheduleReminders {
            try await syncReminders(referenceDate: Date())
        }
        return status
    }

    public func configureReminderHandling(
        onActionApplied: (@Sendable () async -> Void)?
    ) async throws {
        actionAppliedHandler = onActionApplied
        guard hasConfiguredNotifications == false else {
            return
        }

        try await notifications.configureReminderNotifications { [self] response in
            await handleNotificationResponse(response)
        }
        hasConfiguredNotifications = true
    }

    public func fetchReminderSettings() async throws -> AtlasReminderSettingsSnapshot {
        try await GRDBReminderRepository(stack: stack).fetchReminderSettings()
    }

    public func updateReminderSettings(
        _ update: AtlasReminderPreferenceUpdate,
        referenceDate: Date
    ) async throws -> AtlasReminderSettingsSnapshot {
        let snapshot = try await stack.canonical.write { db in
            var preference = try fetchReminderPreference(db: db)
            let timestamp = atlasTimestamp(from: referenceDate)

            if let remindersEnabled = update.remindersEnabled {
                preference.remindersEnabled = remindersEnabled
            }
            if let privacyMode = update.privacyMode {
                preference.privacyMode = privacyMode
            }
            if let leadTimeMinutes = update.leadTimeMinutes {
                preference.leadTimeMinutes = max(leadTimeMinutes, 0)
            }
            preference.updatedAt = timestamp

            try AtlasReminderPreferenceDBRecord(record: preference).save(db)

            return AtlasReminderSettingsSnapshot(
                remindersEnabled: preference.remindersEnabled,
                privacyMode: preference.privacyMode,
                leadTimeMinutes: preference.leadTimeMinutes
            )
        }

        try await syncReminders(referenceDate: referenceDate)
        return snapshot
    }

    public func syncReminders(referenceDate: Date) async throws {
        try await GRDBCoreLoopRepository(stack: stack).ensureProjectedOccurrences(referenceDate: referenceDate)
        let authorizationStatus = await notifications.authorizationStatus()

        let plan = try await stack.canonical.read { db in
            try buildReminderSyncPlan(db: db, referenceDate: referenceDate)
        }

        for existing in plan.existingReminders {
            if let notificationID = existing.notificationId {
                try await notifications.cancelReminder(identifier: notificationID)
            }
        }

        guard plan.shouldSchedule, authorizationStatus.canScheduleReminders else {
            try await writeReminderRows([], existingReminders: plan.existingReminders)
            return
        }

        var createdRows: [AtlasReminderRecord] = []
        do {
            for request in plan.requests {
                let notificationID = try await notifications.scheduleReminder(request.scheduleRequest)
                createdRows.append(
                    AtlasReminderRecord.make(
                        id: request.reminderID,
                        protocolId: request.scheduleRequest.protocolID,
                        occurrenceId: request.scheduleRequest.occurrenceID,
                        offsetMinutes: request.offsetMinutes,
                        channel: .localNotification,
                        isEnabled: true,
                        discreetCopyEnabled: request.preview.effectiveMode != .fullDetail,
                        privacyMode: request.preview.effectiveMode,
                        scheduledFor: atlasTimestamp(from: request.scheduleRequest.triggerAt),
                        notificationId: notificationID,
                        title: request.preview.title,
                        body: request.preview.body,
                        status: .scheduled,
                        createdAt: request.timestamp,
                        updatedAt: request.timestamp
                    )
                )
            }

            try await writeReminderRows(createdRows, existingReminders: plan.existingReminders)
        } catch {
            for created in createdRows {
                if let notificationID = created.notificationId {
                    try? await notifications.cancelReminder(identifier: notificationID)
                }
            }
            throw error
        }
    }

    private func handleNotificationResponse(_ response: AtlasReminderNotificationResponse) async {
        do {
            switch response.action {
            case .markTaken:
                try await GRDBCoreLoopRepository(stack: stack).logOccurrence(
                    AtlasOccurrenceLogRequest(
                        occurrenceID: response.occurrenceID,
                        protocolID: response.protocolID,
                        action: .taken
                    ),
                    now: Date()
                )
                try await syncReminders(referenceDate: Date())
                if let actionAppliedHandler {
                    await actionAppliedHandler()
                }
            case .skip:
                try await GRDBCoreLoopRepository(stack: stack).logOccurrence(
                    AtlasOccurrenceLogRequest(
                        occurrenceID: response.occurrenceID,
                        protocolID: response.protocolID,
                        action: .skipped
                    ),
                    now: Date()
                )
                try await syncReminders(referenceDate: Date())
                if let actionAppliedHandler {
                    await actionAppliedHandler()
                }
            case .openApp:
                if let actionAppliedHandler {
                    await actionAppliedHandler()
                }
            }
        } catch {
            assertionFailure("Atlas reminder action handling failed: \(error.localizedDescription)")
        }
    }

    private func writeReminderRows(
        _ reminders: [AtlasReminderRecord],
        existingReminders: [AtlasReminderRecord]
    ) async throws {
        try await stack.canonical.write { db in
            for existing in existingReminders {
                try db.execute(
                    sql: "UPDATE occurrence_projections SET reminder_id = NULL WHERE reminder_id = ?",
                    arguments: [existing.id]
                )
            }

            try AtlasReminderDBRecord.deleteAll(db)

            for reminder in reminders {
                try AtlasReminderDBRecord(record: reminder).insert(db)
                try db.execute(
                    sql: "UPDATE occurrence_projections SET reminder_id = ?, updated_at = ? WHERE id = ?",
                    arguments: [reminder.id, reminder.updatedAt, reminder.occurrenceId]
                )
            }
        }
    }
}

private struct AtlasReminderSyncPlan {
    var shouldSchedule: Bool
    var existingReminders: [AtlasReminderRecord]
    var requests: [AtlasReminderPlanRequest]
}

private struct AtlasReminderPlanRequest {
    var reminderID: String
    var offsetMinutes: Int
    var preview: AtlasReminderPreview
    var scheduleRequest: AtlasReminderScheduleRequest
    var timestamp: String
}

private func fetchReminderPreference(db: Database) throws -> AtlasReminderPreferenceRecord {
    try AtlasReminderPreferenceDBRecord.fetchOne(db)?.domain ?? .default()
}

private func buildReminderSyncPlan(
    db: Database,
    referenceDate: Date,
    privacyFormatter: AtlasPrivacyFormatter = AtlasPrivacyFormatter()
) throws -> AtlasReminderSyncPlan {
    let existingReminders = try AtlasReminderDBRecord.fetchAll(db).map(\.domain)
    let preference = try fetchReminderPreference(db: db)

    guard preference.remindersEnabled else {
        return AtlasReminderSyncPlan(shouldSchedule: false, existingReminders: existingReminders, requests: [])
    }

    let privacyProfile = try AtlasPrivacyProfileDBRecord.fetchOne(db)?.domain ?? .default()
    let renderMode = privacyFormatter.renderMode(for: privacyProfile)
    let context = try loadCoreLoopContext(db: db)
    let activeProtocolIDs = context.pendingOccurrences.keys.sorted()
    let timestamp = atlasTimestamp(from: referenceDate)
    var requests: [AtlasReminderPlanRequest] = []

    for protocolID in activeProtocolIDs {
        let pendingOccurrences = (context.pendingOccurrences[protocolID] ?? [])
            .sorted(by: { atlasDate(from: $0.scheduledAt) < atlasDate(from: $1.scheduledAt) })

        guard let planned = pendingOccurrences.compactMap({ occurrenceRecord -> AtlasReminderPlanRequest? in
            let occurrence = buildScheduledOccurrence(
                occurrence: occurrenceRecord,
                context: context,
                now: referenceDate
            )
            let triggerAt = occurrence.scheduledAt.addingTimeInterval(TimeInterval(preference.leadTimeMinutes * -60))

            guard triggerAt.timeIntervalSince(referenceDate) > atlasReminderScheduleSkew else {
                return nil
            }

            let preview = privacyFormatter.reminderPreview(
                occurrence: occurrence,
                selectedMode: preference.privacyMode,
                renderMode: renderMode,
                now: referenceDate
            )
            let reminderID = "reminder:\(occurrence.id)"
            return AtlasReminderPlanRequest(
                reminderID: reminderID,
                offsetMinutes: preference.leadTimeMinutes * -1,
                preview: preview,
                scheduleRequest: AtlasReminderScheduleRequest(
                    occurrenceID: occurrence.id,
                    protocolID: occurrence.protocolID,
                    scheduledAt: occurrence.scheduledAt,
                    triggerAt: triggerAt,
                    title: preview.title,
                    body: preview.body,
                    isSilent: preview.isSilent
                ),
                timestamp: timestamp
            )
        }).first else {
            continue
        }
        requests.append(planned)
    }

    return AtlasReminderSyncPlan(
        shouldSchedule: true,
        existingReminders: existingReminders,
        requests: requests
    )
}

private extension AtlasNotificationAuthorizationStatus {
    var canScheduleReminders: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        }
    }
}
