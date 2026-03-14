import AtlasDomain
import Foundation
import UserNotifications

public protocol AtlasFeatureFlagProviding: Sendable {
    var flags: AtlasFeatureFlagState { get }
}

public protocol NotificationManaging: Sendable {
    func authorizationStatus() async -> AtlasNotificationAuthorizationStatus
    func requestAuthorization() async throws -> AtlasNotificationAuthorizationStatus
    func configureReminderNotifications(
        handler: (@Sendable (AtlasReminderNotificationResponse) async -> Void)?
    ) async throws
    func scheduleReminder(_ request: AtlasReminderScheduleRequest) async throws -> String
    func cancelReminder(identifier: String) async throws
}

public protocol BiometricGating: Sendable {
    func authorize(reason: String) async -> Bool
}

public protocol HealthKitManaging: Sendable {
    func isAvailable() -> Bool
    func connectionDescription() -> String
}

public protocol ImportExportBridging: Sendable {
    func importerDescriptors() -> [AtlasImporterDescriptor]
    func validateImport(at url: URL) async throws -> AtlasImportValidationResult
    func prepareImport(at url: URL) async throws -> AtlasPreparedImport
    func commitPreparedImport(
        _ prepared: AtlasPreparedImport,
        mode: AtlasImportMode
    ) async throws -> AtlasImportCommitResult
    func cancelPreparedImport(_ prepared: AtlasPreparedImport) async
    func prepareUniversalImport(
        _ request: AtlasUniversalImportRequest
    ) async throws -> AtlasUniversalPreparedImport
    func commitUniversalImport(
        _ prepared: AtlasUniversalPreparedImport,
        mode: AtlasImportMode
    ) async throws -> AtlasImportCommitResult
    func cancelUniversalImport(_ prepared: AtlasUniversalPreparedImport) async
    func createRawExport(
        _ request: AtlasRawExportRequest,
        now: Date
    ) async throws -> AtlasRawExportResult
    func previewSelectiveShare(
        _ request: AtlasSelectiveShareRequest,
        now: Date
    ) async throws -> AtlasSelectiveSharePreview
    func createSelectiveShare(
        _ request: AtlasSelectiveShareRequest,
        now: Date
    ) async throws -> AtlasSelectiveShareResult
    func previewProviderHandoff(
        _ request: AtlasProviderHandoffRequest,
        now: Date
    ) async throws -> AtlasProviderHandoffPreview
    func createProviderHandoff(
        _ request: AtlasProviderHandoffRequest,
        now: Date
    ) async throws -> AtlasProviderHandoffResult
    func exportStatusDescription() -> String
    func importStatusDescription() -> String
}

public protocol SharedProjectionWriting: Sendable {
    func writeImportedProjection(
        nextDue: AtlasSharedNextDueSnapshot?,
        timeline: [AtlasSharedTimelineSummary],
        labels: [AtlasSharedLabelProjection],
        quickActions: [AtlasSharedQuickAction],
        featureFlags: AtlasSharedFeatureFlagProjection
    ) async throws
    func loadProjectionDebugState() async throws -> AtlasProjectionDebugState
    func projectionDescription() -> String
}

public struct AtlasFeatureFlags: AtlasFeatureFlagProviding {
    public let flags: AtlasFeatureFlagState

    public init(flags: AtlasFeatureFlagState = .init()) {
        self.flags = flags
    }
}

public enum AtlasNotificationPresentationPolicy {
    public static func options(isSilent: Bool) -> UNNotificationPresentationOptions {
        isSilent ? [.banner, .list] : [.banner, .list, .sound]
    }
}

public actor AtlasNotificationManager: NotificationManaging {
    private let center: UNUserNotificationCenter
    private let delegateProxy: AtlasNotificationDelegateProxy

    public init() {
        self.center = UNUserNotificationCenter.current()
        self.delegateProxy = AtlasNotificationDelegateProxy()
    }

    public func authorizationStatus() async -> AtlasNotificationAuthorizationStatus {
        let settings = await center.notificationSettings()
        return mapAuthorizationStatus(settings.authorizationStatus)
    }

    public func requestAuthorization() async throws -> AtlasNotificationAuthorizationStatus {
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        let currentStatus = await authorizationStatus()
        if granted {
            return currentStatus == .notDetermined ? .authorized : currentStatus
        }
        return currentStatus
    }

    public func configureReminderNotifications(
        handler: (@Sendable (AtlasReminderNotificationResponse) async -> Void)?
    ) async throws {
        delegateProxy.setHandler(handler)
        center.delegate = delegateProxy

        let category = UNNotificationCategory(
            identifier: AtlasReminderNotificationCategory.categoryID,
            actions: [
                UNNotificationAction(
                    identifier: AtlasReminderNotificationAction.markTaken.rawValue,
                    title: "Mark taken",
                    options: []
                ),
                UNNotificationAction(
                    identifier: AtlasReminderNotificationAction.skip.rawValue,
                    title: "Skip",
                    options: []
                ),
                UNNotificationAction(
                    identifier: AtlasReminderNotificationAction.openApp.rawValue,
                    title: "Open Atlas",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([category])
    }

    public func scheduleReminder(_ request: AtlasReminderScheduleRequest) async throws -> String {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = request.isSilent ? nil : .default
        content.categoryIdentifier = AtlasReminderNotificationCategory.categoryID
        content.userInfo = [
            "occurrenceId": request.occurrenceID,
            "protocolId": request.protocolID,
            "scheduledAt": ISO8601DateFormatter.atlas.string(from: request.scheduledAt)
        ]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: request.triggerAt
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = "atlas.reminder.\(request.protocolID).\(request.occurrenceID)"
        let notificationRequest = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await center.add(notificationRequest)
        return identifier
    }

    public func cancelReminder(identifier: String) async throws {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

public actor AtlasBiometricGate: BiometricGating {
    public init() {}

    public func authorize(reason: String) async -> Bool {
        _ = reason
        return true
    }
}

public struct AtlasHealthKitManager: HealthKitManaging {
    public init() {}

    public func isAvailable() -> Bool {
        true
    }

    public func connectionDescription() -> String {
        "Health connection remains scaffold-only in Phase 6."
    }
}

private enum AtlasReminderNotificationCategory {
    static let categoryID = "atlas-reminder-actions"
}

private final class AtlasNotificationDelegateProxy: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    private let queue = DispatchQueue(label: "AtlasNotificationDelegateProxy")
    private var handler: (@Sendable (AtlasReminderNotificationResponse) async -> Void)?

    func setHandler(
        _ handler: (@Sendable (AtlasReminderNotificationResponse) async -> Void)?
    ) {
        queue.sync {
            self.handler = handler
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let action = mapActionIdentifier(response.actionIdentifier)
        let payload = response.notification.request.content.userInfo
        let occurrenceID = String(describing: payload["occurrenceId"] ?? "")
        let protocolID = String(describing: payload["protocolId"] ?? "")
        let scheduledAtString = String(describing: payload["scheduledAt"] ?? "")
        let scheduledAt = ISO8601DateFormatter.atlas.date(from: scheduledAtString) ?? Date()

        let currentHandler = queue.sync { handler }

        if let currentHandler {
            await currentHandler(
                AtlasReminderNotificationResponse(
                    action: action,
                    occurrenceID: occurrenceID,
                    protocolID: protocolID,
                    scheduledAt: scheduledAt
                )
            )
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        AtlasNotificationPresentationPolicy.options(isSilent: notification.request.content.sound == nil)
    }
}

private func mapAuthorizationStatus(
    _ status: UNAuthorizationStatus
) -> AtlasNotificationAuthorizationStatus {
    switch status {
    case .notDetermined:
        return .notDetermined
    case .denied:
        return .denied
    case .authorized:
        return .authorized
    case .provisional:
        return .provisional
    case .ephemeral:
        return .ephemeral
    @unknown default:
        return .denied
    }
}

private func mapActionIdentifier(_ value: String) -> AtlasReminderNotificationAction {
    AtlasReminderNotificationAction(rawValue: value) ?? .openApp
}
