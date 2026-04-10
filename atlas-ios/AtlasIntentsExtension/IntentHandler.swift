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
    var quickActions: [AtlasIntentQuickAction]
    var featureFlags: AtlasIntentFeatureFlagProjection
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

private enum AtlasIntentError: LocalizedError {
    case nextDueUnavailable

    var errorDescription: String? {
        switch self {
        case .nextDueUnavailable:
            return "Atlas does not have a projected next-due action ready right now."
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
              snapshot.featureFlags.flags.nativeIntents,
              let quickAction = snapshot.quickActions.first else {
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

struct AtlasOpenTodayIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Today"
    static let description = IntentDescription("Open Atlas to the Today tab.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(route: "today")
        return .result()
    }
}

struct AtlasOpenInventoryIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Inventory"
    static let description = IntentDescription("Open Atlas to inventory and supplies.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasPendingIntentActionStore.write(route: "inventory")
        return .result()
    }
}

struct AtlasMarkNextDueTakenIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Next Due Taken"
    static let description = IntentDescription("Open Atlas and mark the projected next-due item as taken.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasNextDueQuickLogRouteWriter.write(action: .taken)
        return .result()
    }
}

struct AtlasSkipNextDueIntent: AppIntent {
    static let title: LocalizedStringResource = "Skip Next Due"
    static let description = IntentDescription("Open Atlas and skip the projected next-due item.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try AtlasNextDueQuickLogRouteWriter.write(action: .skip)
        return .result()
    }
}

struct AtlasLogWeightIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Weight"
    static let description = IntentDescription("Open Atlas and add a weight entry.")
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
    static let description = IntentDescription("Open Atlas and add a symptom entry.")
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
                intent: AtlasOpenTodayIntent(),
                phrases: [
                    "Open Today in \(.applicationName)",
                    "Show \(.applicationName) Today"
                ],
                shortTitle: "Open Today",
                systemImageName: "sparkles"
            ),
            AppShortcut(
                intent: AtlasOpenInventoryIntent(),
                phrases: [
                    "Open Inventory in \(.applicationName)",
                    "Show \(.applicationName) Supplies"
                ],
                shortTitle: "Open Inventory",
                systemImageName: "shippingbox.fill"
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
