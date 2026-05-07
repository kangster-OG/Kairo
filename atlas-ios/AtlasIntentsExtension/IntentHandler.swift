import AppIntents
import Foundation
import Intents

final class IntentHandler: INExtension {}

private enum AtlasIntentConfiguration {
    static let appGroupIdentifier = "group.com.dkang2000.Atlas.shared"
    static let sharedDirectoryName = "AtlasShared"
    static let pendingActionFileName = "atlas-pending-extension-action.json"
    static let projectionFileName = "atlas-extension-projection.json"
}

private enum AtlasPendingIntentActionStore {
    private struct Payload: Codable {
        var urlString: String
        var createdAt: String
    }

    static func write(route: String, query: [URLQueryItem] = []) throws {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AtlasIntentConfiguration.appGroupIdentifier
        ) else {
            return
        }

        let sharedURL = containerURL.appendingPathComponent(AtlasIntentConfiguration.sharedDirectoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: sharedURL, withIntermediateDirectories: true)
        let fileURL = sharedURL.appendingPathComponent(AtlasIntentConfiguration.pendingActionFileName)

        var components = URLComponents()
        components.scheme = "atlas"
        components.host = route
        components.queryItems = query.isEmpty ? nil : query
        let payload = Payload(
            urlString: components.url?.absoluteString ?? "atlas://today",
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        let data = try JSONEncoder().encode(payload)
        try data.write(to: fileURL, options: .atomic)
    }
}

private enum AtlasIntentProjectionStore {
    static func load() -> AtlasIntentProjectionSnapshot? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AtlasIntentConfiguration.appGroupIdentifier
        ) else {
            return nil
        }

        let fileURL = containerURL
            .appendingPathComponent(AtlasIntentConfiguration.sharedDirectoryName, isDirectory: true)
            .appendingPathComponent(AtlasIntentConfiguration.projectionFileName)
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        return try? JSONDecoder().decode(AtlasIntentProjectionSnapshot.self, from: data)
    }
}

private struct AtlasIntentQuickAction: Codable {
    var id: String
    var protocolID: String
    var occurrenceID: String
}

private struct AtlasIntentFeatureFlags: Codable {
    var nativeIntents: Bool
}

private struct AtlasIntentFeatureFlagProjection: Codable {
    var flags: AtlasIntentFeatureFlags
}

private struct AtlasIntentProjectionSnapshot: Codable {
    var generatedAt: String
    var quickActions: [AtlasIntentQuickAction]
    var featureFlags: AtlasIntentFeatureFlagProjection
}

private enum AtlasIntentTime {
    static func date(from value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value)
    }
}

private struct AtlasIntentProjectionFreshness {
    var generatedAt: Date?
    var referenceDate: Date

    var isStale: Bool {
        guard let generatedAt else {
            return true
        }
        return max(referenceDate.timeIntervalSince(generatedAt), 0) >= (2 * 60 * 60)
    }
}

private extension AtlasIntentProjectionSnapshot {
    func freshness(referenceDate: Date = Date()) -> AtlasIntentProjectionFreshness {
        AtlasIntentProjectionFreshness(
            generatedAt: AtlasIntentTime.date(from: generatedAt),
            referenceDate: referenceDate
        )
    }
}

private enum AtlasIntentError: LocalizedError {
    case nextDueUnavailable
    case nextDueProjectionStale

    var errorDescription: String? {
        switch self {
        case .nextDueUnavailable:
            return "Kairo does not have a projected next-due action ready right now."
        case .nextDueProjectionStale:
            return "Open Kairo first to refresh your local next-due action before running this shortcut."
        }
    }
}

private enum AtlasNextDueIntentAction: String {
    case taken
    case skip
}

private enum AtlasNextDueQuickLogRouteWriter {
    static func write(action: AtlasNextDueIntentAction) throws {
        guard let snapshot = AtlasIntentProjectionStore.load(),
              snapshot.featureFlags.flags.nativeIntents else {
            throw AtlasIntentError.nextDueUnavailable
        }

        guard snapshot.freshness().isStale == false else {
            throw AtlasIntentError.nextDueProjectionStale
        }

        guard let quickAction = snapshot.quickActions.first else {
            throw AtlasIntentError.nextDueUnavailable
        }

        try AtlasPendingIntentActionStore.write(
            route: "quick-log",
            query: [
                URLQueryItem(name: "action", value: action.rawValue),
                URLQueryItem(name: "occurrenceId", value: quickAction.occurrenceID),
                URLQueryItem(name: "protocolId", value: quickAction.protocolID)
            ]
        )
    }
}

enum AtlasShortcutWeightUnit: String, AppEnum {
    case lb
    case kg

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Weight Unit"
    static let caseDisplayRepresentations: [AtlasShortcutWeightUnit: DisplayRepresentation] = [
        .lb: "lb",
        .kg: "kg"
    ]
}

enum AtlasWatchContextShortcutKind: String, AppEnum {
    case proteinMeal
    case hydration
    case lowAppetite
    case giCheckIn

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Watch Context"
    static let caseDisplayRepresentations: [AtlasWatchContextShortcutKind: DisplayRepresentation] = [
        .proteinMeal: "Protein Meal",
        .hydration: "Hydration",
        .lowAppetite: "Low Appetite",
        .giCheckIn: "GI Check-In"
    ]

    var routeValue: String {
        rawValue
    }
}

enum AtlasQuickCaptureIntentKind: String, AppEnum {
    case shot
    case weight
    case symptom
    case hydration
    case protein
    case progressPhoto = "progress_photo"

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Capture Focus"
    static let caseDisplayRepresentations: [AtlasQuickCaptureIntentKind: DisplayRepresentation] = [
        .shot: "Shot",
        .weight: "Weight",
        .symptom: "Symptom",
        .hydration: "Hydration",
        .protein: "Protein",
        .progressPhoto: "Progress Photo"
    ]
}

struct AtlasOpenTodayIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Today"
    static let description = IntentDescription("Open Kairo to the Today tab.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(route: "today")
        return .result()
    }
}

struct AtlasOpenWatchCompanionIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Apple Watch Companion"
    static let description = IntentDescription("Open Kairo to the Apple Watch companion handoff surface.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(route: "watch-companion")
        return .result()
    }
}

struct AtlasOpenRecoveryHandlingIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Recovery Handling"
    static let description = IntentDescription("Open Kairo directly to recovery handling for the watch companion.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(route: "watch-recovery")
        return .result()
    }
}

struct AtlasOpenInventoryIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Inventory"
    static let description = IntentDescription("Open Kairo to inventory and supplies.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(route: "inventory")
        return .result()
    }
}

struct AtlasOpenTrustVaultIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Trust Vault"
    static let description = IntentDescription("Open Kairo to Trust Vault privacy controls.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(route: "trust-vault")
        return .result()
    }
}

struct AtlasOpenQuickCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Quick Capture"
    static let description = IntentDescription("Open Kairo directly to the fast capture hub.")
    static let openAppWhenRun = true

    @Parameter(title: "Focus")
    var focus: AtlasQuickCaptureIntentKind

    static var parameterSummary: some ParameterSummary {
        Summary("Open quick capture for \(\.$focus)")
    }

    init() {
        focus = .shot
    }

    init(focus: AtlasQuickCaptureIntentKind = .shot) {
        self.focus = focus
    }

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(
            route: "quick-capture",
            query: [URLQueryItem(name: "kind", value: focus.rawValue)]
        )
        return .result()
    }
}

struct AtlasOpenProgressEvidenceIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Progress Evidence"
    static let description = IntentDescription("Open Kairo to visual progress capture and compare.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(route: "progress-evidence")
        return .result()
    }
}

struct AtlasOpenRewardsIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Rewards"
    static let description = IntentDescription("Open Kairo to the rewards and mascot momentum surfaces.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(route: "rewards")
        return .result()
    }
}

struct AtlasOpenWeeklyReviewIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Weekly Review"
    static let description = IntentDescription("Open Kairo to the weekly closeout and follow-through surface.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(route: "weekly-review")
        return .result()
    }
}

struct AtlasOpenMascotIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Mascot"
    static let description = IntentDescription("Open Kairo to the mascot detail screen.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(route: "mascot")
        return .result()
    }
}

struct AtlasCheckInWithMascotIntent: AppIntent {
    static let title: LocalizedStringResource = "Check In With Mascot"
    static let description = IntentDescription("Open Kairo, let the mascot react, and add a fresh mascot-moment entry.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(
            route: "mascot-moment",
            query: [URLQueryItem(name: "kind", value: "shortcut")]
        )
        return .result()
    }
}

struct AtlasMarkNextDueTakenIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Next Due Taken"
    static let description = IntentDescription("Open Kairo and mark the projected next-due item as taken.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasNextDueQuickLogRouteWriter.write(action: .taken)
        return .result()
    }
}

struct AtlasSkipNextDueIntent: AppIntent {
    static let title: LocalizedStringResource = "Skip Next Due"
    static let description = IntentDescription("Open Kairo and skip the projected next-due item.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasNextDueQuickLogRouteWriter.write(action: .skip)
        return .result()
    }
}

struct AtlasLogWatchContextIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Watch Context"
    static let description = IntentDescription("Open Kairo and capture a fast watch-friendly support signal.")
    static let openAppWhenRun = true

    @Parameter(title: "Signal")
    var signal: AtlasWatchContextShortcutKind

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$signal) in Kairo")
    }

    init() {
        signal = .hydration
    }

    init(signal: AtlasWatchContextShortcutKind) {
        self.signal = signal
    }

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(
            route: "context-shortcut",
            query: [URLQueryItem(name: "kind", value: signal.routeValue)]
        )
        return .result()
    }
}

struct AtlasLogHydrationIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Hydration"
    static let description = IntentDescription("Open Kairo and add a fast hydration check-in.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(
            route: "context-shortcut",
            query: [URLQueryItem(name: "kind", value: AtlasWatchContextShortcutKind.hydration.routeValue)]
        )
        return .result()
    }
}

struct AtlasLogProteinMealIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Protein Meal"
    static let description = IntentDescription("Open Kairo and start a protein meal check-in.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(
            route: "context-shortcut",
            query: [URLQueryItem(name: "kind", value: AtlasWatchContextShortcutKind.proteinMeal.routeValue)]
        )
        return .result()
    }
}

struct AtlasLogLowAppetiteIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Low Appetite"
    static let description = IntentDescription("Open Kairo and add a fast low-appetite signal.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(
            route: "context-shortcut",
            query: [URLQueryItem(name: "kind", value: AtlasWatchContextShortcutKind.lowAppetite.routeValue)]
        )
        return .result()
    }
}

struct AtlasLogGIRecoveryIntent: AppIntent {
    static let title: LocalizedStringResource = "Log GI Check-In"
    static let description = IntentDescription("Open Kairo and start a fuller GI recovery note.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(
            route: "context-shortcut",
            query: [URLQueryItem(name: "kind", value: AtlasWatchContextShortcutKind.giCheckIn.routeValue)]
        )
        return .result()
    }
}

struct AtlasLogWeightIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Weight"
    static let description = IntentDescription("Open Kairo and add a weight entry.")
    static let openAppWhenRun = true

    @Parameter(title: "Value")
    var value: Double

    @Parameter(title: "Unit")
    var unit: AtlasShortcutWeightUnit

    @Parameter(title: "Note")
    var note: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Log weight \(\.$value) \(\.$unit)")
    }

    init() {
        value = 0
        unit = .lb
        note = nil
    }

    init(value: Double, unit: AtlasShortcutWeightUnit = .lb, note: String? = nil) {
        self.value = value
        self.unit = unit
        self.note = note
    }

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(
            route: "weight-entry",
            query: [
                URLQueryItem(name: "value", value: String(value)),
                URLQueryItem(name: "unit", value: unit.rawValue),
                URLQueryItem(name: "notes", value: note)
            ]
        )
        return .result()
    }
}

struct AtlasLogSymptomIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Symptom"
    static let description = IntentDescription("Open Kairo and add a symptom entry.")
    static let openAppWhenRun = true

    @Parameter(title: "Symptom")
    var symptom: String

    @Parameter(title: "Severity")
    var severity: Int

    @Parameter(title: "Note")
    var note: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Log symptom \(\.$symptom) at severity \(\.$severity)")
    }

    init() {
        symptom = ""
        severity = 3
        note = nil
    }

    init(symptom: String, severity: Int = 3, note: String? = nil) {
        self.symptom = symptom
        self.severity = severity
        self.note = note
    }

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(
            route: "symptom-entry",
            query: [
                URLQueryItem(name: "symptom", value: symptom),
                URLQueryItem(name: "severity", value: String(severity)),
                URLQueryItem(name: "notes", value: note)
            ]
        )
        return .result()
    }
}

struct AtlasShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            AppShortcut(
                intent: AtlasOpenWatchCompanionIntent(),
                phrases: [
                    "Open Apple Watch companion in \(.applicationName)",
                    "Show \(.applicationName) watch companion"
                ],
                shortTitle: "Watch Companion",
                systemImageName: "applewatch"
            ),
            AppShortcut(
                intent: AtlasOpenRecoveryHandlingIntent(),
                phrases: [
                    "Open recovery handling in \(.applicationName)",
                    "Show \(.applicationName) recovery handling"
                ],
                shortTitle: "Recovery",
                systemImageName: "cross.case.fill"
            ),
            AppShortcut(
                intent: AtlasMarkNextDueTakenIntent(),
                phrases: [
                    "Mark next due taken in \(.applicationName)",
                    "Log next due as taken in \(.applicationName)"
                ],
                shortTitle: "Mark Next Due",
                systemImageName: "checkmark.circle.fill"
            ),
            AppShortcut(
                intent: AtlasSkipNextDueIntent(),
                phrases: [
                    "Skip next due in \(.applicationName)",
                    "Skip my next due item in \(.applicationName)"
                ],
                shortTitle: "Skip Next Due",
                systemImageName: "forward.fill"
            ),
            AppShortcut(
                intent: AtlasLogHydrationIntent(),
                phrases: [
                    "Log hydration in \(.applicationName)",
                    "Add hydration in \(.applicationName)"
                ],
                shortTitle: "Log Hydration",
                systemImageName: "drop.fill"
            ),
            AppShortcut(
                intent: AtlasLogProteinMealIntent(),
                phrases: [
                    "Log protein meal in \(.applicationName)",
                    "Add protein meal in \(.applicationName)"
                ],
                shortTitle: "Log Protein",
                systemImageName: "bolt.heart.fill"
            ),
            AppShortcut(
                intent: AtlasLogLowAppetiteIntent(),
                phrases: [
                    "Log low appetite in \(.applicationName)",
                    "Add low appetite in \(.applicationName)"
                ],
                shortTitle: "Low Appetite",
                systemImageName: "fork.knife.circle.fill"
            ),
            AppShortcut(
                intent: AtlasLogGIRecoveryIntent(),
                phrases: [
                    "Log GI check-in in \(.applicationName)",
                    "Add GI recovery note in \(.applicationName)"
                ],
                shortTitle: "GI Check-In",
                systemImageName: "waveform.path.ecg.rectangle"
            ),
            AppShortcut(
                intent: AtlasLogWeightIntent(),
                phrases: [
                    "Log weight in \(.applicationName)",
                    "Add \(.applicationName) weight entry"
                ],
                shortTitle: "Log Weight",
                systemImageName: "scalemass.fill"
            ),
            AppShortcut(
                intent: AtlasLogSymptomIntent(),
                phrases: [
                    "Log symptom in \(.applicationName)",
                    "Add \(.applicationName) symptom entry"
                ],
                shortTitle: "Log Symptom",
                systemImageName: "waveform.path.ecg"
            )
        ]
    }
}
