import AtlasDomain
import Foundation
import LocalAuthentication
import OSLog
import UserNotifications
#if canImport(HealthKit)
import HealthKit
#endif

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
    func scheduleMascotNotification(_ request: AtlasMascotNotificationRequest) async throws -> String
    func cancelReminder(identifier: String) async throws
}

public protocol BiometricGating: Sendable {
    func isAvailable() async -> Bool
    func authorize(reason: String) async -> Bool
}

public protocol HealthKitManaging: Sendable {
    func isAvailable() -> Bool
    func isConnected() async -> Bool
    func requestAuthorization() async throws -> Bool
    func disconnect() async
    func fetchWeightSamples(since: Date?) async throws -> [AtlasHealthWeightSample]
    func fetchWorkouts(since: Date?) async throws -> [AtlasHealthWorkoutSample]
    func saveWeightSample(value: Double, unit: AtlasWeightUnit, recordedAt: Date) async throws
    func connectionDescription() -> String
}

public protocol DiagnosticsReporting: Sendable {
    func markLaunchStarted()
    func markLaunchCompleted()
    func recordError(_ message: String, context: String, metadata: [String: String]) async
    func statusDescription() -> String
}

public protocol ImportExportBridging: Sendable {
    func importerDescriptors() -> [AtlasImporterDescriptor]
    func listImportTemplates(importer: AtlasImporterKind?) async throws -> [AtlasSavedImportTemplate]
    func saveImportTemplate(_ draft: AtlasImportTemplateDraft, now: Date) async throws -> AtlasSavedImportTemplate
    func deleteImportTemplate(id: String) async throws
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
    func listRestorePoints() async throws -> [AtlasRestorePointSummary]
    func previewRestorePoint(id: String) async throws -> AtlasRestorePointPreview
    func restoreRestorePoint(id: String, now: Date) async throws -> AtlasRestoreCommitResult
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
    func refreshProjection(referenceDate: Date) async throws
    func loadProjectionDebugState() async throws -> AtlasProjectionDebugState
    func loadExtensionProjectionSnapshot() async throws -> AtlasSharedExtensionProjectionSnapshot?
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

    public func scheduleMascotNotification(_ request: AtlasMascotNotificationRequest) async throws -> String {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = request.isSilent ? nil : .default
        content.userInfo = [
            "route": request.route,
            "notificationKind": "mascot"
        ]

        let interval = max(request.triggerAt.timeIntervalSinceNow, 1)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let notificationRequest = UNNotificationRequest(
            identifier: request.identifier,
            content: content,
            trigger: trigger
        )

        try await center.add(notificationRequest)
        return request.identifier
    }

    public func cancelReminder(identifier: String) async throws {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

public actor AtlasBiometricGate: BiometricGating {
    public init() {}

    public func isAvailable() async -> Bool {
        let context = makeContext()
        return biometricPolicy(for: context) != nil
    }

    public func authorize(reason: String) async -> Bool {
        let context = makeContext()
        guard let policy = biometricPolicy(for: context) else {
            return false
        }

        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(policy, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }

    private func makeContext() -> LAContext {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        return context
    }

    private func biometricPolicy(for context: LAContext) -> LAPolicy? {
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return .deviceOwnerAuthenticationWithBiometrics
        }

        if let error,
           LAError.Code(rawValue: error.code) == .biometryLockout,
           context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
            return .deviceOwnerAuthentication
        }

        return nil
    }
}

public struct AtlasHealthKitManager: HealthKitManaging {
    public init() {}

    public func isAvailable() -> Bool {
        #if canImport(HealthKit)
        HKHealthStore.isHealthDataAvailable()
        #else
        false
        #endif
    }

    public func isConnected() async -> Bool {
        #if canImport(HealthKit)
        guard let store = makeStore(),
              let quantityType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return false
        }
        return store.authorizationStatus(for: quantityType) == .sharingAuthorized
        #else
        return false
        #endif
    }

    public func requestAuthorization() async throws -> Bool {
        #if canImport(HealthKit)
        guard let store = makeStore(),
              let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return false
        }
        let workoutType = HKObjectType.workoutType()

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            store.requestAuthorization(
                toShare: Set([weightType]),
                read: Set([weightType, workoutType])
            ) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
        #else
        return false
        #endif
    }

    public func disconnect() async {
        // HealthKit permissions are managed by the system. Atlas can clear its local
        // connection state, but revocation still happens in the Health app / Settings.
    }

    public func fetchWorkouts(since: Date?) async throws -> [AtlasHealthWorkoutSample] {
        #if canImport(HealthKit)
        guard let store = makeStore() else {
            return []
        }

        let predicate = since.map {
            HKQuery.predicateForSamples(withStart: $0, end: nil, options: .strictStartDate)
        }
        let sortDescriptors = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[AtlasHealthWorkoutSample], Error>) in
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: sortDescriptors
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = (samples as? [HKWorkout] ?? []).map { workout in
                    AtlasHealthWorkoutSample(
                        id: workout.uuid.uuidString,
                        activityKind: mapWorkoutActivityKind(workout.workoutActivityType),
                        startedAt: workout.startDate,
                        endedAt: workout.endDate,
                        durationMinutes: max(workout.duration / 60, 1),
                        energyBurnedKilocalories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
                        distanceMeters: workout.totalDistance?.doubleValue(for: .meter())
                    )
                }
                continuation.resume(returning: workouts)
            }

            store.execute(query)
        }
        #else
        return []
        #endif
    }

    public func fetchWeightSamples(since: Date?) async throws -> [AtlasHealthWeightSample] {
        #if canImport(HealthKit)
        guard let store = makeStore(),
              let quantityType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return []
        }

        let predicate = since.map {
            HKQuery.predicateForSamples(withStart: $0, end: nil, options: .strictStartDate)
        }
        let sortDescriptors = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[AtlasHealthWeightSample], Error>) in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: sortDescriptors
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let weights = (samples as? [HKQuantitySample] ?? []).map { sample in
                    let metricUnit = HKUnit.gramUnit(with: .kilo)
                    let usesMetric = sample.quantity.is(compatibleWith: metricUnit)
                    let atlasUnit: AtlasWeightUnit = usesMetric ? .kg : .lb
                    let sampleUnit: HKUnit = atlasUnit == .kg ? metricUnit : .pound()

                    return AtlasHealthWeightSample(
                        id: sample.uuid.uuidString,
                        recordedAt: sample.startDate,
                        value: sample.quantity.doubleValue(for: sampleUnit),
                        unit: atlasUnit
                    )
                }
                continuation.resume(returning: weights)
            }

            store.execute(query)
        }
        #else
        return []
        #endif
    }

    public func saveWeightSample(value: Double, unit: AtlasWeightUnit, recordedAt: Date) async throws {
        #if canImport(HealthKit)
        guard let store = makeStore(),
              let quantityType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return
        }

        let quantityUnit: HKUnit = unit == .kg ? .gramUnit(with: .kilo) : .pound()
        let sample = HKQuantitySample(
            type: quantityType,
            quantity: HKQuantity(unit: quantityUnit, doubleValue: value),
            start: recordedAt,
            end: recordedAt
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.save(sample) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: AtlasSystemError.healthKitSaveFailed)
                }
            }
        }
        #endif
    }

    public func connectionDescription() -> String {
        guard isAvailable() else {
            return "Apple Health is unavailable on this device."
        }
        return "Apple Health can import workouts, bring weight history into Atlas, and sync Atlas weight entries back when you connect it."
    }

    #if canImport(HealthKit)
    private func mapWorkoutActivityKind(_ type: HKWorkoutActivityType) -> AtlasWorkoutActivityKind {
        switch type {
        case .walking, .wheelchairWalkPace:
            return .walk
        case .running, .wheelchairRunPace:
            return .run
        case .cycling, .handCycling:
            return .cycle
        case .traditionalStrengthTraining, .functionalStrengthTraining, .coreTraining:
            return .strength
        case .yoga:
            return .yoga
        case .barre, .cooldown, .flexibility, .mindAndBody, .pilates, .preparationAndRecovery, .taiChi:
            return .mobility
        case .swimming, .waterFitness, .waterPolo, .waterSports, .underwaterDiving:
            return .swim
        case .fishing, .hiking, .hunting:
            return .hike
        case .cardioDance,
             .crossTraining,
             .dance,
             .danceInspiredTraining,
             .elliptical,
             .fitnessGaming,
             .highIntensityIntervalTraining,
             .jumpRope,
             .mixedCardio,
             .mixedMetabolicCardioTraining,
             .rowing,
             .stairClimbing,
             .stairs,
             .stepTraining,
             .swimBikeRun,
             .transition:
            return .cardio
        case .americanFootball,
             .archery,
             .australianFootball,
             .badminton,
             .baseball,
             .basketball,
             .bowling,
             .boxing,
             .climbing,
             .cricket,
             .crossCountrySkiing,
             .curling,
             .discSports,
             .downhillSkiing,
             .equestrianSports,
             .fencing,
             .golf,
             .gymnastics,
             .handball,
             .hockey,
             .kickboxing,
             .lacrosse,
             .martialArts,
             .paddleSports,
             .pickleball,
             .play,
             .racquetball,
             .rugby,
             .sailing,
             .skatingSports,
             .snowboarding,
             .snowSports,
             .socialDance,
             .soccer,
             .softball,
             .squash,
             .surfingSports,
             .tableTennis,
             .tennis,
             .trackAndField,
             .volleyball,
             .wrestling:
            return .sport
        default:
            return .other
        }
    }

    private func makeStore() -> HKHealthStore? {
        guard HKHealthStore.isHealthDataAvailable() else {
            return nil
        }
        return HKHealthStore()
    }
    #endif
}

public final class AtlasDiagnosticsReporter: DiagnosticsReporting, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.dkang2000.Atlas", category: "diagnostics")
    private let defaults: UserDefaults
    private let launchMarkerKey = "atlas.launch.inflight"
    private let lastCrashKey = "atlas.launch.lastCrashDetected"
    private let eventStoreKey = "atlas.diagnostics.events"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.bool(forKey: launchMarkerKey) {
            defaults.set(true, forKey: lastCrashKey)
            appendEvent(
                StoredDiagnosticsEvent(
                    kind: "launch_recovered_after_incomplete_exit",
                    message: "Atlas detected an incomplete previous launch.",
                    context: "lifecycle",
                    metadata: [:],
                    recordedAt: Date()
                )
            )
        }
    }

    public func markLaunchStarted() {
        defaults.set(true, forKey: launchMarkerKey)
        logger.log("Atlas launch started")
        appendEvent(
            StoredDiagnosticsEvent(
                kind: "launch_started",
                message: "Atlas launch started.",
                context: "lifecycle",
                metadata: [:],
                recordedAt: Date()
            )
        )
    }

    public func markLaunchCompleted() {
        defaults.set(false, forKey: launchMarkerKey)
        logger.log("Atlas launch completed")
        appendEvent(
            StoredDiagnosticsEvent(
                kind: "launch_completed",
                message: "Atlas launch completed.",
                context: "lifecycle",
                metadata: [:],
                recordedAt: Date()
            )
        )
    }

    public func recordError(_ message: String, context: String, metadata: [String: String]) async {
        let metadataSummary = metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")
        logger.error("Atlas error [\(context, privacy: .public)]: \(message, privacy: .public) \(metadataSummary, privacy: .public)")
        appendEvent(
            StoredDiagnosticsEvent(
                kind: "runtime_error",
                message: message,
                context: context,
                metadata: metadata,
                recordedAt: Date()
            )
        )
    }

    public func statusDescription() -> String {
        let events = storedEvents()
        let latestEvent = events.last
        if defaults.bool(forKey: lastCrashKey) {
            let latest = latestEvent.map { " Latest event: \($0.kindLabel) at \(formatted($0.recordedAt))." } ?? ""
            return "Reliability logging is active. Atlas detected an incomplete previous launch and is keeping a local diagnostics trail.\(latest)"
        }
        if let latestEvent {
            return "Reliability logging is active for launch and runtime errors on this device. Latest event: \(latestEvent.kindLabel) at \(formatted(latestEvent.recordedAt))."
        }
        return "Reliability logging is active for launch and runtime errors on this device."
    }

    private func appendEvent(_ event: StoredDiagnosticsEvent) {
        var events = storedEvents()
        events.append(event)
        if events.count > 50 {
            events.removeFirst(events.count - 50)
        }
        if let data = try? JSONEncoder().encode(events) {
            defaults.set(data, forKey: eventStoreKey)
        }
    }

    private func storedEvents() -> [StoredDiagnosticsEvent] {
        guard let data = defaults.data(forKey: eventStoreKey),
              let events = try? JSONDecoder().decode([StoredDiagnosticsEvent].self, from: data) else {
            return []
        }
        return events
    }

    private func formatted(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}

private struct StoredDiagnosticsEvent: Codable {
    var kind: String
    var message: String
    var context: String
    var metadata: [String: String]
    var recordedAt: Date

    var kindLabel: String {
        switch kind {
        case "launch_started":
            return "launch started"
        case "launch_completed":
            return "launch completed"
        case "launch_recovered_after_incomplete_exit":
            return "recovered after incomplete exit"
        default:
            return "runtime error"
        }
    }
}

private enum AtlasSystemError: LocalizedError {
    case healthKitSaveFailed

    var errorDescription: String? {
        switch self {
        case .healthKitSaveFailed:
            return "Atlas couldn't save the Health sample."
        }
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
