import AppIntents
import Foundation
import SwiftUI
import UIKit
import WidgetKit

private enum AtlasWidgetConfiguration {
    static let appGroupIdentifier = "group.com.dkang2000.Atlas.shared"
    static let projectionFileName = "atlas-extension-projection.json"
}

private enum AtlasWidgetProjectionStore {
    static func load() -> AtlasWidgetProjectionSnapshot? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AtlasWidgetConfiguration.appGroupIdentifier
        ) else {
            return nil
        }

        let url = containerURL
            .appendingPathComponent("AtlasShared", isDirectory: true)
            .appendingPathComponent(AtlasWidgetConfiguration.projectionFileName)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(AtlasWidgetProjectionSnapshot.self, from: data)
    }
}

private enum AtlasWidgetRenderMode: String, Codable {
    case full
    case discreet
    case alias
}

private enum AtlasWidgetOccurrenceState: String, Codable {
    case overdue
    case due
    case upcoming
    case completed
    case skipped
    case superseded
}

private enum AtlasWidgetInventoryItemKind: String, Codable {
    case vial
    case consumable
}

private struct AtlasWidgetNextDueSnapshot: Codable {
    var occurrenceID: String
    var protocolID: String
    var displayTitle: String
    var dueLabel: String
    var scheduledAt: String
    var state: AtlasWidgetOccurrenceState
    var statusSummary: String
    var overdueCount: Int
}

private struct AtlasWidgetQuickAction: Codable, Identifiable {
    var id: String
    var protocolID: String
    var occurrenceID: String
    var title: String
    var dueLabel: String
    var state: AtlasWidgetOccurrenceState
}

private struct AtlasWidgetLowStockItem: Codable, Identifiable {
    var id: String
    var kind: AtlasWidgetInventoryItemKind
    var displayTitle: String
    var detail: String
}

private struct AtlasWidgetLowStockSnapshot: Codable {
    var lowStockCount: Int
    var procurementReviewCount: Int
    var summary: String
    var items: [AtlasWidgetLowStockItem]
    var updatedAt: String
}

private struct AtlasWidgetSupportRingSnapshot: Codable, Identifiable {
    var id: String { kind }
    var kind: String
    var title: String
    var valueLabel: String
    var progress: Double
    var symbolName: String
}

private struct AtlasWidgetSupportRingsSnapshot: Codable {
    var score: Int
    var summary: String
    var rings: [AtlasWidgetSupportRingSnapshot]
    var updatedAt: String
}

private enum AtlasWidgetMascotSelection: String, Codable {
    case aetherion
    case aurielle
}

private enum AtlasWidgetMascotStage: String, Codable {
    case stage1
    case stage2
    case stage3
}

private enum AtlasWidgetMascotPose: String, Codable {
    case idle
    case happy
    case recovery
    case evolutionReady
    case milestone
    case rest
}

private struct AtlasWidgetMascotEvolutionRecord: Codable {
    var selection: AtlasWidgetMascotSelection
    var stage: AtlasWidgetMascotStage
    var earnedAt: String
}

private struct AtlasWidgetMascotSnapshot: Codable {
    var selection: AtlasWidgetMascotSelection
    var nickname: String?
    var displayName: String
    var stage: AtlasWidgetMascotStage
    var pose: AtlasWidgetMascotPose
    var currentFormName: String
    var nextFormName: String?
    var nextThresholdPoints: Int?
    var totalPoints: Int
    var milestoneHeadline: String
    var progressLabel: String
    var statusLine: String
    var reactionTitle: String?
    var reactionSymbolName: String?
    var lastEvolution: AtlasWidgetMascotEvolutionRecord?
    var latestMomentTitle: String?
    var latestMomentDetail: String?
    var latestMomentSymbolName: String?
    var latestMomentRecordedAt: String?
}

private enum AtlasMascotWidgetFocus: String, AppEnum, Codable {
    case automatic
    case progress
    case status
    case moments
    case history

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Mascot Focus"
    static let caseDisplayRepresentations: [AtlasMascotWidgetFocus: DisplayRepresentation] = [
        .automatic: "Automatic",
        .progress: "Progress",
        .status: "Status",
        .moments: "Moments",
        .history: "History"
    ]
}

private struct AtlasMascotWidgetConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Mascot Widget"
    static let description = IntentDescription("Choose which mascot detail Kairo should emphasize in this widget.")

    @Parameter(title: "Focus", default: .automatic)
    var focus: AtlasMascotWidgetFocus

    init() {}

    init(resolvedFocus: AtlasMascotWidgetFocus) {
        self.focus = resolvedFocus
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Show mascot \(\.$focus)")
    }
}

private struct AtlasWidgetFeatureFlags: Codable {
    var nativeWidgets: Bool
    var nativeIntents: Bool
    var trustVaultShell: Bool
    var importShell: Bool
    var reviewMode: Bool
    var liveReviewSessions: Bool
}

private struct AtlasWidgetFeatureFlagProjection: Codable {
    var flags: AtlasWidgetFeatureFlags
}

private struct AtlasWidgetProjectionSnapshot: Codable {
    var generatedAt: String
    var renderMode: AtlasWidgetRenderMode
    var nextDue: AtlasWidgetNextDueSnapshot?
    var quickActions: [AtlasWidgetQuickAction]
    var lowStock: AtlasWidgetLowStockSnapshot
    var support: AtlasWidgetSupportRingsSnapshot?
    var mascot: AtlasWidgetMascotSnapshot?
    var featureFlags: AtlasWidgetFeatureFlagProjection
}

private enum AtlasWidgetProjectionSurface {
    case nextDue
    case lowStock
    case mascot

    var staleAfter: TimeInterval {
        switch self {
        case .nextDue:
            return 2 * 60 * 60
        case .lowStock:
            return 12 * 60 * 60
        case .mascot:
            return 2 * 60 * 60
        }
    }
}

private struct AtlasWidgetProjectionFreshness {
    var generatedAt: Date?
    var referenceDate: Date
    var staleAfter: TimeInterval

    var isStale: Bool {
        guard let generatedAt else {
            return true
        }
        return max(referenceDate.timeIntervalSince(generatedAt), 0) >= staleAfter
    }
}

private enum AtlasWidgetTime {
    static func date(from value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value)
    }
}

private extension AtlasWidgetProjectionSnapshot {
    func freshness(for surface: AtlasWidgetProjectionSurface, referenceDate: Date) -> AtlasWidgetProjectionFreshness {
        AtlasWidgetProjectionFreshness(
            generatedAt: AtlasWidgetTime.date(from: generatedAt),
            referenceDate: referenceDate,
            staleAfter: surface.staleAfter
        )
    }
}

private enum AtlasPendingWidgetActionStore {
    private struct Payload: Codable {
        var urlString: String
        var createdAt: String
    }

    static func write(route: String, query: [URLQueryItem] = []) throws {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AtlasWidgetConfiguration.appGroupIdentifier
        ) else {
            return
        }

        let sharedURL = containerURL.appendingPathComponent("AtlasShared", isDirectory: true)
        try FileManager.default.createDirectory(at: sharedURL, withIntermediateDirectories: true)
        let fileURL = sharedURL.appendingPathComponent("atlas-pending-extension-action.json")

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

private struct AtlasWidgetEntry: TimelineEntry {
    var date: Date
    var snapshot: AtlasWidgetProjectionSnapshot?
}

private struct AtlasMascotWidgetEntry: TimelineEntry {
    var date: Date
    var snapshot: AtlasWidgetProjectionSnapshot?
    var configuration: AtlasMascotWidgetConfigurationIntent
}

private struct AtlasWidgetSnapshotContext {
    var snapshot: AtlasWidgetProjectionSnapshot
    var freshness: AtlasWidgetProjectionFreshness
}

private extension AtlasWidgetEntry {
    func snapshotContext(for surface: AtlasWidgetProjectionSurface) -> AtlasWidgetSnapshotContext? {
        guard let snapshot else {
            return nil
        }
        return AtlasWidgetSnapshotContext(
            snapshot: snapshot,
            freshness: snapshot.freshness(for: surface, referenceDate: date)
        )
    }
}

private extension AtlasMascotWidgetEntry {
    func snapshotContext(for surface: AtlasWidgetProjectionSurface) -> AtlasWidgetSnapshotContext? {
        guard let snapshot else {
            return nil
        }
        return AtlasWidgetSnapshotContext(
            snapshot: snapshot,
            freshness: snapshot.freshness(for: surface, referenceDate: date)
        )
    }
}

private struct AtlasNextDueProvider: TimelineProvider {
    func placeholder(in context: Context) -> AtlasWidgetEntry {
        AtlasWidgetEntry(date: .now, snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (AtlasWidgetEntry) -> Void) {
        completion(AtlasWidgetEntry(date: .now, snapshot: AtlasWidgetProjectionStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AtlasWidgetEntry>) -> Void) {
        let entry = AtlasWidgetEntry(date: .now, snapshot: AtlasWidgetProjectionStore.load())
        completion(
            Timeline(
                entries: [entry],
                policy: .after(.now.addingTimeInterval(15 * 60))
            )
        )
    }
}

private struct AtlasLowStockProvider: TimelineProvider {
    func placeholder(in context: Context) -> AtlasWidgetEntry {
        AtlasWidgetEntry(date: .now, snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (AtlasWidgetEntry) -> Void) {
        completion(AtlasWidgetEntry(date: .now, snapshot: AtlasWidgetProjectionStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AtlasWidgetEntry>) -> Void) {
        let entry = AtlasWidgetEntry(date: .now, snapshot: AtlasWidgetProjectionStore.load())
        completion(
            Timeline(
                entries: [entry],
                policy: .after(.now.addingTimeInterval(30 * 60))
            )
        )
    }
}

private struct AtlasMascotProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> AtlasMascotWidgetEntry {
        AtlasMascotWidgetEntry(
            date: .now,
            snapshot: atlasWidgetPreviewProjectionSnapshot(),
            configuration: AtlasMascotWidgetConfigurationIntent()
        )
    }

    func snapshot(
        for configuration: AtlasMascotWidgetConfigurationIntent,
        in context: Context
    ) async -> AtlasMascotWidgetEntry {
        AtlasMascotWidgetEntry(
            date: .now,
            snapshot: AtlasWidgetProjectionStore.load(),
            configuration: configuration
        )
    }

    func timeline(
        for configuration: AtlasMascotWidgetConfigurationIntent,
        in context: Context
    ) async -> Timeline<AtlasMascotWidgetEntry> {
        let snapshot = AtlasWidgetProjectionStore.load()
        let entries: [AtlasMascotWidgetEntry]

        if configuration.focus == .automatic,
           let mascot = snapshot?.mascot {
            let focusSequence = automaticFocuses(for: mascot)
            entries = focusSequence.enumerated().map { index, focus in
                let resolvedConfiguration = AtlasMascotWidgetConfigurationIntent(resolvedFocus: focus)
                return AtlasMascotWidgetEntry(
                    date: .now.addingTimeInterval(Double(index) * 60 * 60),
                    snapshot: snapshot,
                    configuration: resolvedConfiguration
                )
            }
        } else {
            entries = [
                AtlasMascotWidgetEntry(
                    date: .now,
                    snapshot: snapshot,
                    configuration: configuration
                )
            ]
        }

        return Timeline(
            entries: entries,
            policy: .after((entries.last?.date ?? .now).addingTimeInterval(60 * 60))
        )
    }

    private func automaticFocuses(for mascot: AtlasWidgetMascotSnapshot) -> [AtlasMascotWidgetFocus] {
        var focuses: [AtlasMascotWidgetFocus] = [.progress, .status]
        if mascot.latestMomentTitle != nil {
            focuses.append(.moments)
        }
        if mascot.lastEvolution != nil {
            focuses.append(.history)
        }
        return focuses
    }
}

private func atlasWidgetPreviewProjectionSnapshot() -> AtlasWidgetProjectionSnapshot {
    let now = Date()
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime]
    return AtlasWidgetProjectionSnapshot(
        generatedAt: iso.string(from: now),
        renderMode: .full,
        nextDue: AtlasWidgetNextDueSnapshot(
            occurrenceID: "preview-occurrence",
            protocolID: "preview-protocol",
            displayTitle: "Open Kairo Today",
            dueLabel: "in 15 min",
            scheduledAt: iso.string(from: now.addingTimeInterval(15 * 60)),
            state: .due,
            statusSummary: "A calm preview of the Kairo command loop.",
            overdueCount: 0
        ),
        quickActions: [],
        lowStock: AtlasWidgetLowStockSnapshot(
            lowStockCount: 0,
            procurementReviewCount: 0,
            summary: "No low-stock items projected.",
            items: [],
            updatedAt: iso.string(from: now)
        ),
        support: AtlasWidgetSupportRingsSnapshot(
            score: 72,
            summary: "Protein, hydration, and workouts keep today's support loop visible.",
            rings: [
                AtlasWidgetSupportRingSnapshot(kind: "protein", title: "Protein", valueLabel: "1 / 2", progress: 0.5, symbolName: "bolt.heart.fill"),
                AtlasWidgetSupportRingSnapshot(kind: "hydration", title: "Hydration", valueLabel: "2 / 2", progress: 1, symbolName: "drop.fill"),
                AtlasWidgetSupportRingSnapshot(kind: "workout", title: "Workout", valueLabel: "1 recent", progress: 1, symbolName: "dumbbell.fill")
            ],
            updatedAt: iso.string(from: now)
        ),
        mascot: AtlasWidgetMascotSnapshot(
            selection: .aetherion,
            nickname: nil,
            displayName: "Cindlet",
            stage: .stage1,
            pose: .milestone,
            currentFormName: "Cindlet",
            nextFormName: "Voltflare",
            nextThresholdPoints: 500,
            totalPoints: 182,
            milestoneHeadline: "Cindlet evolves into Voltflare at 500 points.",
            progressLabel: "318 points to Voltflare.",
            statusLine: "Cindlet is growing with every step toward weekly workout goal.",
            reactionTitle: "Momentum building",
            reactionSymbolName: "sparkles",
            lastEvolution: AtlasWidgetMascotEvolutionRecord(
                selection: .aetherion,
                stage: .stage1,
                earnedAt: iso.string(from: now.addingTimeInterval(-3 * 24 * 60 * 60))
            ),
            latestMomentTitle: "Weekly workout streak",
            latestMomentDetail: "Three more workouts this week keeps the line alive and moving.",
            latestMomentSymbolName: "figure.run.circle.fill",
            latestMomentRecordedAt: iso.string(from: now.addingTimeInterval(-90 * 60))
        ),
        featureFlags: AtlasWidgetFeatureFlagProjection(
            flags: AtlasWidgetFeatureFlags(
                nativeWidgets: true,
                nativeIntents: true,
                trustVaultShell: true,
                importShell: true,
                reviewMode: true,
                liveReviewSessions: true
            )
        )
    )
}

private struct AtlasOpenTodayWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Today"
    static let description = IntentDescription("Open Kairo to Today.")
    static let openAppWhenRun = true
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        try AtlasPendingWidgetActionStore.write(route: "today")
        return .result()
    }
}

private enum AtlasWidgetQuickCaptureKind: String {
    case shot
    case weight
    case symptom
    case hydration
    case protein
    case progressPhoto = "progress_photo"
}

private struct AtlasOpenQuickCaptureWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Quick Capture"
    static let description = IntentDescription("Open Kairo to a focused quick-capture lane.")
    static let openAppWhenRun = true
    static let isDiscoverable = false

    @Parameter(title: "Focus")
    var focus: String

    init() {
        focus = AtlasWidgetQuickCaptureKind.shot.rawValue
    }

    init(focus: AtlasWidgetQuickCaptureKind) {
        self.focus = focus.rawValue
    }

    func perform() async throws -> some IntentResult {
        try AtlasPendingWidgetActionStore.write(
            route: "quick-capture",
            query: [URLQueryItem(name: "kind", value: focus)]
        )
        return .result()
    }
}

private struct AtlasOpenProgressEvidenceWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Progress Evidence"
    static let description = IntentDescription("Open Kairo to visual progress capture and compare.")
    static let openAppWhenRun = true
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        try AtlasPendingWidgetActionStore.write(route: "progress-evidence")
        return .result()
    }
}

private struct AtlasOpenInventoryWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Inventory"
    static let description = IntentDescription("Open Kairo to Inventory.")
    static let openAppWhenRun = true
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        try AtlasPendingWidgetActionStore.write(route: "inventory")
        return .result()
    }
}

private struct AtlasOpenMascotWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Companion"
    static let description = IntentDescription("Open Kairo to the companion detail screen.")
    static let openAppWhenRun = true
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        try AtlasPendingWidgetActionStore.write(route: "mascot")
        return .result()
    }
}

private struct AtlasMarkTakenWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Shot"
    static let description = IntentDescription("Open Kairo and log the projected shot as taken.")
    static let openAppWhenRun = true
    static let isDiscoverable = false

    @Parameter(title: "Occurrence ID")
    var occurrenceID: String

    @Parameter(title: "Protocol ID")
    var protocolID: String

    init() {
        occurrenceID = ""
        protocolID = ""
    }

    init(occurrenceID: String, protocolID: String) {
        self.occurrenceID = occurrenceID
        self.protocolID = protocolID
    }

    func perform() async throws -> some IntentResult {
        try AtlasPendingWidgetActionStore.write(
            route: "quick-log",
            query: [
                URLQueryItem(name: "action", value: "taken"),
                URLQueryItem(name: "occurrenceId", value: occurrenceID),
                URLQueryItem(name: "protocolId", value: protocolID)
            ]
        )
        return .result()
    }
}

private struct AtlasSkipWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Skip"
    static let description = IntentDescription("Open Kairo and skip the projected occurrence.")
    static let openAppWhenRun = true
    static let isDiscoverable = false

    @Parameter(title: "Occurrence ID")
    var occurrenceID: String

    @Parameter(title: "Protocol ID")
    var protocolID: String

    init() {
        occurrenceID = ""
        protocolID = ""
    }

    init(occurrenceID: String, protocolID: String) {
        self.occurrenceID = occurrenceID
        self.protocolID = protocolID
    }

    func perform() async throws -> some IntentResult {
        try AtlasPendingWidgetActionStore.write(
            route: "quick-log",
            query: [
                URLQueryItem(name: "action", value: "skip"),
                URLQueryItem(name: "occurrenceId", value: occurrenceID),
                URLQueryItem(name: "protocolId", value: protocolID)
            ]
        )
        return .result()
    }
}

private enum AtlasWidgetPalette {
    static let background = Color(red: 0.985, green: 0.975, blue: 0.955)
    static let surface = Color(red: 1.0, green: 0.992, blue: 0.972)
    static let surfaceMuted = Color(red: 0.925, green: 0.945, blue: 0.905)
    static let primary = Color(red: 0.12, green: 0.45, blue: 0.36)
    static let primarySoft = Color(red: 0.86, green: 0.94, blue: 0.90)
    static let reward = Color(red: 0.76, green: 0.55, blue: 0.13)
    static let textPrimary = Color(red: 0.09, green: 0.13, blue: 0.12)
    static let textSecondary = Color(red: 0.37, green: 0.40, blue: 0.37)
    static let border = Color(red: 0.82, green: 0.80, blue: 0.74)
}

private struct AtlasWidgetCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(
                LinearGradient(
                    colors: [
                        AtlasWidgetPalette.background,
                        AtlasWidgetPalette.surface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                for: .widget
            )
    }
}

private extension View {
    func atlasWidgetCardBackground() -> some View {
        modifier(AtlasWidgetCardBackground())
    }
}

private struct AtlasStatusBadge: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.9))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AtlasWidgetPalette.primarySoft, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(AtlasWidgetPalette.border.opacity(0.45), lineWidth: 1)
            )
    }
}

private struct AtlasProjectionTimestampLine: View {
    var prefix: String
    var date: Date

    var body: some View {
        HStack(spacing: 4) {
            Text(prefix)
            Text(date, style: .relative)
        }
        .font(.caption2)
        .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.68))
        .lineLimit(1)
    }
}

private struct AtlasNextDueWidgetView: View {
    var entry: AtlasWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            let context = entry.snapshotContext(for: .nextDue)
            if let context,
               context.snapshot.featureFlags.flags.nativeWidgets,
               context.freshness.isStale == false,
               let nextDue = context.snapshot.nextDue {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Next shot")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.72))
                            Text(nextDue.displayTitle)
                                .font(family == .systemSmall ? .headline.weight(.semibold) : .title3.weight(.semibold))
                                .foregroundStyle(AtlasWidgetPalette.textPrimary)
                                .lineLimit(family == .systemSmall ? 2 : 3)
                            Text(nextDue.statusSummary)
                                .font(.caption)
                                .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.78))
                                .lineLimit(2)
                        }
                        Spacer(minLength: 8)
                        AtlasStatusBadge(text: atlasBadgeText(for: nextDue))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(nextDue.dueLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AtlasWidgetPalette.textPrimary)
                        if nextDue.overdueCount > 1 {
                            Text("\(nextDue.overdueCount) items currently need attention.")
                                .font(.caption2)
                                .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.72))
                                .lineLimit(2)
                        }
                    }

                    if family != .systemSmall, let support = context.snapshot.support {
                        AtlasWidgetSupportScoreStrip(support: support)
                    }

                    Spacer(minLength: 0)

                    if let quickAction = context.snapshot.quickActions.first {
                        if family == .systemSmall {
                            HStack(spacing: 8) {
                                Button(intent: AtlasMarkTakenWidgetIntent(
                                    occurrenceID: quickAction.occurrenceID,
                                    protocolID: quickAction.protocolID
                                )) {
                                    Label("Log", systemImage: "checkmark.circle.fill")
                                }
                                .buttonStyle(.borderedProminent)

                                Button(intent: AtlasSkipWidgetIntent(
                                    occurrenceID: quickAction.occurrenceID,
                                    protocolID: quickAction.protocolID
                                )) {
                                    Label("Skip", systemImage: "forward.fill")
                                }
                                .buttonStyle(.bordered)
                            }
                            .tint(AtlasWidgetPalette.primarySoft)
                            .labelStyle(.iconOnly)
                        } else {
                            HStack(spacing: 8) {
                                Button(intent: AtlasMarkTakenWidgetIntent(
                                    occurrenceID: quickAction.occurrenceID,
                                    protocolID: quickAction.protocolID
                                )) {
                                    Label("Log shot", systemImage: "checkmark.circle.fill")
                                }
                                .buttonStyle(.borderedProminent)

                                Button(intent: AtlasSkipWidgetIntent(
                                    occurrenceID: quickAction.occurrenceID,
                                    protocolID: quickAction.protocolID
                                )) {
                                    Label("Skip", systemImage: "forward.fill")
                                }
                                .buttonStyle(.bordered)
                            }
                            .tint(AtlasWidgetPalette.primarySoft)
                        }
                    } else {
                        HStack {
                            Button(intent: AtlasOpenTodayWidgetIntent()) {
                                Label("Open Kairo", systemImage: "arrow.up.forward.app")
                            }
                            .buttonStyle(.bordered)
                            .tint(AtlasWidgetPalette.primarySoft)
                        }
                    }
                    if let generatedAt = context.freshness.generatedAt {
                        AtlasProjectionTimestampLine(prefix: "Updated", date: generatedAt)
                    }
                }
                .atlasWidgetCardBackground()
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Next shot")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.72))
                    Text(
                        (context?.freshness.isStale ?? false)
                            ? "Open Kairo to refresh your local next due summary before taking action."
                            : "Open Kairo to refresh your next due summary."
                    )
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AtlasWidgetPalette.textPrimary)
                        .lineLimit(3)
                    if let generatedAt = context?.freshness.generatedAt {
                        AtlasProjectionTimestampLine(prefix: "Last refreshed", date: generatedAt)
                    }
                    Spacer()
                    Button(intent: AtlasOpenTodayWidgetIntent()) {
                        Label("Open Kairo", systemImage: "arrow.up.forward.app")
                    }
                    .buttonStyle(.bordered)
                    .tint(AtlasWidgetPalette.primarySoft)
                }
                .atlasWidgetCardBackground()
            }
        }
    }

    private func atlasBadgeText(for nextDue: AtlasWidgetNextDueSnapshot) -> String {
        switch nextDue.state {
        case .overdue:
            return "Overdue"
        case .due:
            return "Due"
        case .upcoming:
            return "Upcoming"
        case .completed:
            return "Completed"
        case .skipped:
            return "Skipped"
        case .superseded:
            return "Updated"
        }
    }
}

private struct AtlasLowStockWidgetView: View {
    var entry: AtlasWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            let context = entry.snapshotContext(for: .lowStock)
            if let context,
               context.snapshot.featureFlags.flags.nativeWidgets,
               context.freshness.isStale == false {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Vial runway")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.72))
                            Text(atlasHeadline(for: context.snapshot.lowStock))
                                .font(family == .systemSmall ? .headline.weight(.semibold) : .title3.weight(.semibold))
                                .foregroundStyle(AtlasWidgetPalette.textPrimary)
                                .lineLimit(family == .systemSmall ? 3 : 2)
                        }
                        Spacer(minLength: 8)
                        AtlasStatusBadge(text: atlasBadgeText(for: context.snapshot.lowStock))
                    }

                    if let firstItem = context.snapshot.lowStock.items.first {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(firstItem.displayTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AtlasWidgetPalette.textPrimary)
                                .lineLimit(2)
                            Text(firstItem.detail)
                                .font(.caption)
                                .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.78))
                                .lineLimit(family == .systemSmall ? 2 : 3)
                        }
                    } else {
                        Text("No low-stock items are currently projected.")
                            .font(.caption)
                            .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.78))
                            .lineLimit(3)
                    }

                    Spacer(minLength: 0)

                    HStack {
                        Button(intent: AtlasOpenInventoryWidgetIntent()) {
                            Label("Open Inventory", systemImage: "shippingbox.fill")
                        }
                        .buttonStyle(.bordered)
                        .tint(AtlasWidgetPalette.primarySoft)
                        Spacer(minLength: 8)
                        if let generatedAt = context.freshness.generatedAt {
                            AtlasProjectionTimestampLine(prefix: "Updated", date: generatedAt)
                        }
                    }
                }
                .atlasWidgetCardBackground()
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Vial runway")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.72))
                    Text(
                        (context?.freshness.isStale ?? false)
                            ? "Open Kairo to refresh supplies and procurement review status."
                            : "Open Kairo to refresh supplies and inventory status."
                    )
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AtlasWidgetPalette.textPrimary)
                        .lineLimit(3)
                    if let generatedAt = context?.freshness.generatedAt {
                        AtlasProjectionTimestampLine(prefix: "Last refreshed", date: generatedAt)
                    }
                    Spacer()
                    Button(intent: AtlasOpenInventoryWidgetIntent()) {
                        Label("Open Kairo", systemImage: "arrow.up.forward.app")
                    }
                    .buttonStyle(.bordered)
                    .tint(AtlasWidgetPalette.primarySoft)
                }
                .atlasWidgetCardBackground()
            }
        }
    }

    private func atlasHeadline(for snapshot: AtlasWidgetLowStockSnapshot) -> String {
        if snapshot.procurementReviewCount > 0 {
            let count = snapshot.procurementReviewCount
            return count == 1
                ? "1 supply plan needs review."
                : "\(count) supply plans need review."
        }
        return snapshot.summary
    }

    private func atlasBadgeText(for snapshot: AtlasWidgetLowStockSnapshot) -> String {
        if snapshot.procurementReviewCount > 0 {
            return "\(snapshot.procurementReviewCount) review"
        }
        return "\(snapshot.lowStockCount)"
    }
}

private struct AtlasWidgetMascotSprite: View {
    var snapshot: AtlasWidgetMascotSnapshot
    var size: CGFloat

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [highlightTint.opacity(0.42), accentTint.opacity(0.16), .clear],
                        center: .center,
                        startRadius: 6,
                        endRadius: size * 0.72
                    )
                )
                .frame(width: size * 1.1, height: size * 1.1)

            Circle()
                .stroke(AtlasWidgetPalette.border.opacity(0.14), lineWidth: 1)
                .frame(width: size * 0.94, height: size * 0.94)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [AtlasWidgetPalette.surface.opacity(0.12), accentTint.opacity(0.12), Color.clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: size * 0.52
                    )
                )
                .frame(width: size * 0.88, height: size * 0.88)

            Group {
                if let spriteImage {
                    Image(uiImage: spriteImage)
                        .renderingMode(.original)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                } else {
                    Image(systemName: fallbackSymbol)
                        .resizable()
                        .scaledToFit()
                        .padding(size * 0.18)
                        .foregroundStyle(highlightTint)
                }
            }
            .saturation(snapshot.pose == .rest ? 0.72 : 1)
            .brightness(snapshot.selection == .aetherion ? 0.06 : 0.02)
            .contrast(1.06)
            .opacity(snapshot.pose == .rest ? 0.9 : 1)
            .scaleEffect(snapshot.pose == .milestone ? 1.04 : (snapshot.pose == .evolutionReady ? 1.03 : 1))
            .shadow(color: AtlasWidgetPalette.surface.opacity(0.08), radius: size * 0.08, y: size * 0.02)
            .shadow(color: accentTint.opacity(0.22), radius: size * 0.12, y: size * 0.06)
            .frame(width: size, height: size)

            if let badgeSymbol {
                Image(systemName: badgeSymbol)
                    .font(.system(size: max(size * 0.14, 10), weight: .bold))
                    .foregroundStyle(badgeTint)
                    .padding(max(size * 0.05, 4))
                    .background(Circle().fill(Color.black.opacity(0.72)))
                    .overlay(
                        Circle()
                            .stroke(AtlasWidgetPalette.border.opacity(0.18), lineWidth: 1)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipped()
    }

    private var assetName: String {
        switch (snapshot.selection, snapshot.stage) {
        case (.aetherion, .stage1):
            return "AtlasMascotAetherionStage1Mockup"
        case (.aetherion, .stage2):
            return "AtlasMascotAetherionStage2Mockup"
        case (.aetherion, .stage3):
            return "AtlasMascotAetherionStage3Mockup"
        case (.aurielle, .stage1):
            return "AtlasMascotAurielleStage1Mockup"
        case (.aurielle, .stage2):
            return "AtlasMascotAurielleStage2Mockup"
        case (.aurielle, .stage3):
            return "AtlasMascotAurielleStage3Mockup"
        }
    }

    private var spriteImage: UIImage? {
        UIImage(named: assetName, in: .main, compatibleWith: nil)
    }

    private var fallbackSymbol: String {
        switch snapshot.selection {
        case .aetherion:
            return "bolt.circle.fill"
        case .aurielle:
            return "moon.stars.fill"
        }
    }

    private var badgeSymbol: String? {
        switch snapshot.pose {
        case .recovery:
            return "arrow.clockwise.circle.fill"
        case .evolutionReady:
            return "sparkles"
        case .milestone:
            return "rosette"
        case .rest:
            return "moon.zzz.fill"
        case .idle, .happy:
            return nil
        }
    }

    private var badgeTint: Color {
        switch snapshot.pose {
        case .recovery:
            return .blue
        case .evolutionReady:
            return .yellow
        case .milestone:
            return .orange
        case .rest:
            return .indigo
        case .idle, .happy:
            return AtlasWidgetPalette.textPrimary
        }
    }

    private var accentTint: Color {
        switch snapshot.selection {
        case .aetherion:
            return Color(red: 0.16, green: 0.42, blue: 0.96)
        case .aurielle:
            return Color(red: 0.39, green: 0.69, blue: 0.96)
        }
    }

    private var highlightTint: Color {
        switch snapshot.selection {
        case .aetherion:
            return Color(red: 0.95, green: 0.74, blue: 0.34)
        case .aurielle:
            return Color(red: 0.92, green: 0.97, blue: 1.00)
        }
    }
}

private struct AtlasWidgetMascotStickerArt: View {
    var snapshot: AtlasWidgetMascotSnapshot
    var size: CGFloat

    var body: some View {
        Group {
            if let stickerImage {
                Image(uiImage: stickerImage)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
            } else {
                AtlasWidgetMascotSprite(snapshot: snapshot, size: size * 0.82)
            }
        }
        .frame(width: size, height: size)
    }

    private var stickerImage: UIImage? {
        UIImage(named: stickerAssetName, in: .main, compatibleWith: nil)
    }

    private var stickerAssetName: String {
        switch (snapshot.selection, snapshot.stage) {
        case (.aetherion, .stage1):
            return "AtlasMascotAetherionStage1Mockup"
        case (.aetherion, .stage2):
            return "AtlasMascotAetherionStage2Mockup"
        case (.aetherion, .stage3):
            return "AtlasMascotAetherionStage3Mockup"
        case (.aurielle, .stage1):
            return "AtlasMascotAurielleStage1Mockup"
        case (.aurielle, .stage2):
            return "AtlasMascotAurielleStage2Mockup"
        case (.aurielle, .stage3):
            return "AtlasMascotAurielleStage3Mockup"
        }
    }
}

private struct AtlasMascotWidgetView: View {
    var entry: AtlasMascotWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            let context = entry.snapshotContext(for: .mascot)
            if let context,
               context.snapshot.featureFlags.flags.nativeWidgets,
               let mascot = context.snapshot.mascot {
                let focus = resolvedFocus(for: mascot, configuredFocus: entry.configuration.focus)
                liveContent(
                    mascot: mascot,
                    focus: focus,
                    freshness: context.freshness
                )
            } else {
                let focus = fallbackFocus(for: entry.configuration.focus)
                fallbackContent(
                    focus: focus,
                    isStale: context?.freshness.isStale ?? false,
                    freshness: context?.freshness
                )
            }
        }
        .unredacted()
        .widgetURL(URL(string: "atlas://mascot"))
    }

    private func lastEvolutionLabel(for record: AtlasWidgetMascotEvolutionRecord) -> String {
        let selection = record.selection
        let title: String
        switch (selection, record.stage) {
        case (.aetherion, .stage1):
            title = "Cindlet"
        case (.aetherion, .stage2):
            title = "Voltflare"
        case (.aetherion, .stage3):
            title = "Aetherion"
        case (.aurielle, .stage1):
            title = "Moppet"
        case (.aurielle, .stage2):
            title = "Glisshare"
        case (.aurielle, .stage3):
            title = "Aurielle"
        }
        return "\(title) unlocked."
    }

    private func resolvedFocus(
        for mascot: AtlasWidgetMascotSnapshot,
        configuredFocus: AtlasMascotWidgetFocus
    ) -> AtlasMascotWidgetFocus {
        guard configuredFocus == .automatic else {
            return configuredFocus
        }
        if mascot.latestMomentTitle != nil {
            return .moments
        }
        if mascot.lastEvolution != nil {
            return .history
        }
        return .progress
    }

    private func fallbackFocus(for configuredFocus: AtlasMascotWidgetFocus) -> AtlasMascotWidgetFocus {
        configuredFocus == .automatic ? .progress : configuredFocus
    }

    @ViewBuilder
    private func liveContent(
        mascot: AtlasWidgetMascotSnapshot,
        focus: AtlasMascotWidgetFocus,
        freshness: AtlasWidgetProjectionFreshness
    ) -> some View {
        switch family {
        case .accessoryInline:
            Text("\(mascot.displayName): \(inlineSummary(for: mascot, focus: focus))")
        case .accessoryCircular:
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [widgetHighlightTint(for: mascot).opacity(0.4), widgetAccentTint(for: mascot).opacity(0.22), AtlasWidgetPalette.surface.opacity(0.04)],
                            center: .center,
                            startRadius: 6,
                            endRadius: 46
                        )
                    )
                Circle()
                    .stroke(AtlasWidgetPalette.surface.opacity(0.12), lineWidth: 1)
                Circle()
                    .trim(from: 0, to: progressArcValue(for: mascot, focus: focus))
                    .stroke(widgetHighlightTint(for: mascot), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(4)
                AtlasWidgetMascotStickerArt(snapshot: mascot, size: 42)
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: focusAccentSymbol(for: mascot, focus: focus))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(widgetHighlightTint(for: mascot))
                            .padding(5)
                            .background(.black.opacity(0.24), in: Circle())
                    }
                    Spacer()
                    Text(shortStageLabel(for: mascot))
                        .font(.system(size: 8, weight: .bold, design: .default))
                        .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.82))
                }
                .padding(6)
            }
        case .accessoryRectangular:
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [widgetAccentTint(for: mascot).opacity(0.34), widgetHighlightTint(for: mascot).opacity(0.12), AtlasWidgetPalette.surface.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AtlasWidgetPalette.surface.opacity(0.1), lineWidth: 1)
                        )
                    AtlasWidgetMascotStickerArt(snapshot: mascot, size: 46)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(mascot.displayName)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        AtlasStatusBadge(text: widgetFocusBadge(for: focus))
                    }
                    Text(rectangularDetail(for: mascot, focus: focus))
                        .font(.caption2.weight(.semibold))
                        .lineLimit(2)
                    Text(rectangularSubdetail(for: mascot, focus: focus))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if let footer = focusFooter(for: mascot, focus: focus) {
                        Label(footer.text, systemImage: footer.symbol)
                            .font(.system(size: 10, weight: .semibold, design: .default))
                            .foregroundStyle(widgetHighlightTint(for: mascot))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }
        case .systemSmall:
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            AtlasStatusBadge(text: widgetStageBadge(for: mascot))
                            AtlasStatusBadge(text: widgetFocusBadge(for: focus))
                        }
                        Text(mascot.displayName)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AtlasWidgetPalette.textPrimary)
                            .lineLimit(1)
                        Text(focusHeadline(for: mascot, focus: focus))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(widgetHighlightTint(for: mascot))
                            .lineLimit(2)
                    }

                    Spacer(minLength: 6)

                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        widgetAccentTint(for: mascot).opacity(0.3),
                                        widgetHighlightTint(for: mascot).opacity(0.12),
                                        AtlasWidgetPalette.surface.opacity(0.03)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(AtlasWidgetPalette.surface.opacity(0.08), lineWidth: 1)
                            )
                        AtlasWidgetMascotStickerArt(snapshot: mascot, size: 60)
                    }
                    .frame(width: 76, height: 76)
                }

                Text(focusBody(for: mascot, focus: focus))
                    .font(.caption2)
                    .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.82))
                    .lineLimit(3)

                HStack(spacing: 8) {
                    AtlasWidgetMetricPill(
                        title: "Points",
                        value: "\(mascot.totalPoints)",
                        tint: widgetHighlightTint(for: mascot)
                    )
                    if let nextFormName = mascot.nextFormName {
                        AtlasWidgetMetricPill(
                            title: "Next",
                            value: nextFormName,
                            tint: widgetAccentTint(for: mascot)
                        )
                    } else {
                        AtlasWidgetMetricPill(
                            title: "Form",
                            value: mascot.currentFormName,
                            tint: widgetAccentTint(for: mascot)
                        )
                    }
                }

                if let footer = focusFooter(for: mascot, focus: focus) {
                    Label(footer.text, systemImage: footer.symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.86))
                        .lineLimit(1)
                }
            }
            .atlasWidgetCardBackground()
        default:
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text(widgetLineLabel(for: mascot))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.72))
                            AtlasStatusBadge(text: widgetFocusBadge(for: focus))
                            AtlasStatusBadge(text: widgetStageBadge(for: mascot))
                            if freshness.isStale {
                                AtlasStatusBadge(text: "Needs refresh")
                            }
                        }
                        Text(mascot.displayName)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AtlasWidgetPalette.textPrimary)
                            .lineLimit(2)
                        Text(focusHeadline(for: mascot, focus: focus))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(widgetHighlightTint(for: mascot))
                            .lineLimit(2)
                    }

                    Spacer(minLength: 8)

                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        widgetAccentTint(for: mascot).opacity(0.28),
                                        widgetHighlightTint(for: mascot).opacity(0.12),
                                        AtlasWidgetPalette.surface.opacity(0.04)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(AtlasWidgetPalette.surface.opacity(0.08), lineWidth: 1)
                            )
                        AtlasWidgetMascotStickerArt(snapshot: mascot, size: 98)
                    }
                    .frame(width: 126, height: 126)
                }

                Text(focusBody(for: mascot, focus: focus))
                    .font(.caption)
                    .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.8))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    AtlasWidgetMetricPill(
                        title: "Points",
                        value: "\(mascot.totalPoints)",
                        tint: widgetHighlightTint(for: mascot)
                    )
                    AtlasWidgetMetricPill(
                        title: "Focus",
                        value: widgetFocusBadge(for: focus),
                        tint: widgetAccentTint(for: mascot)
                    )
                    if let nextFormName = mascot.nextFormName {
                        AtlasWidgetMetricPill(
                            title: "Next",
                            value: nextFormName,
                            tint: AtlasWidgetPalette.surface.opacity(0.9)
                        )
                    }
                }

                if let footer = focusFooter(for: mascot, focus: focus) {
                    Label(footer.text, systemImage: footer.symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.88))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                HStack {
                    Button(intent: AtlasOpenMascotWidgetIntent()) {
                        Label("Open Companion", systemImage: "sparkles")
                    }
                    .buttonStyle(.bordered)
                    .tint(AtlasWidgetPalette.primarySoft)

                    Spacer(minLength: 8)

                    if let generatedAt = freshness.generatedAt {
                        AtlasProjectionTimestampLine(prefix: "Updated", date: generatedAt)
                    }
                }
            }
            .atlasWidgetCardBackground()
        }
    }

    @ViewBuilder
    private func fallbackContent(
        focus: AtlasMascotWidgetFocus,
        isStale: Bool,
        freshness: AtlasWidgetProjectionFreshness?
    ) -> some View {
        switch family {
        case .accessoryInline:
            Text(isStale ? "Open Kairo to refresh mascot" : "Turn on rewards to enable mascot")
        case .accessoryCircular:
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AtlasWidgetPalette.surface.opacity(0.18), AtlasWidgetPalette.surface.opacity(0.06)],
                            center: .center,
                            startRadius: 4,
                            endRadius: 46
                        )
                    )
                Circle()
                    .stroke(AtlasWidgetPalette.surface.opacity(0.12), lineWidth: 1)
                Image(systemName: isStale ? "arrow.clockwise.circle.fill" : "sparkles")
                    .font(.system(size: 20, weight: .semibold))
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Kairo Companion")
                    .font(.caption.weight(.semibold))
                Text(
                    isStale
                        ? "Open Kairo to refresh companion progression."
                        : "Turn on rewards to bring the companion widget to life."
                )
                .font(.caption2)
                .lineLimit(3)
            }
        case .systemSmall:
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    AtlasStatusBadge(text: isStale ? "Needs refresh" : "Standby")
                    AtlasStatusBadge(text: widgetFocusBadge(for: focus))
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AtlasWidgetPalette.surface.opacity(0.08), AtlasWidgetPalette.surface.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: isStale ? "arrow.clockwise.circle.fill" : "sparkles")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.88))
                }
                .frame(height: 74)
                Text(
                    isStale
                        ? "Open Kairo to refresh companion progression."
                        : "Turn on rewards to activate the companion widget."
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(AtlasWidgetPalette.textPrimary)
                .lineLimit(3)
                if let generatedAt = freshness?.generatedAt {
                    AtlasProjectionTimestampLine(prefix: "Last refreshed", date: generatedAt)
                }
            }
            .atlasWidgetCardBackground()
        default:
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("Kairo Companion")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.72))
                    AtlasStatusBadge(text: isStale ? "Needs refresh" : "Standby")
                }
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AtlasWidgetPalette.surface.opacity(0.08), AtlasWidgetPalette.surface.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: isStale ? "arrow.clockwise.circle.fill" : "sparkles")
                        .font(.system(size: family == .systemSmall ? 32 : 38, weight: .semibold))
                        .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.88))
                }
                .frame(height: family == .systemSmall ? 76 : 92)
                Text(
                    isStale
                        ? "Open Kairo to refresh your companion progression and sprite state."
                        : "Turn on rewards in Kairo to bring the \(focus.rawValue) companion widget to life."
                )
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AtlasWidgetPalette.textPrimary)
                    .lineLimit(3)
                if let generatedAt = freshness?.generatedAt {
                    AtlasProjectionTimestampLine(prefix: "Last refreshed", date: generatedAt)
                }
                Spacer()
                Button(intent: AtlasOpenMascotWidgetIntent()) {
                    Label("Open Kairo", systemImage: "sparkles")
                }
                .buttonStyle(.bordered)
                .tint(AtlasWidgetPalette.primarySoft)
            }
            .atlasWidgetCardBackground()
        }
    }

    private func inlineSummary(for mascot: AtlasWidgetMascotSnapshot, focus: AtlasMascotWidgetFocus) -> String {
        switch focus {
        case .automatic:
            return mascot.progressLabel
        case .progress:
            return mascot.progressLabel
        case .status:
            return mascot.statusLine
        case .moments:
            return mascot.latestMomentTitle ?? mascot.reactionTitle ?? "No mascot moment yet"
        case .history:
            if let lastEvolution = mascot.lastEvolution {
                return lastEvolutionLabel(for: lastEvolution)
            }
            return "No evolution history yet"
        }
    }

    private func rectangularDetail(for mascot: AtlasWidgetMascotSnapshot, focus: AtlasMascotWidgetFocus) -> String {
        switch focus {
        case .automatic:
            return mascot.progressLabel
        case .progress:
            return mascot.progressLabel
        case .status:
            return mascot.statusLine
        case .moments:
            return mascot.latestMomentTitle ?? mascot.reactionTitle ?? "No mascot moment yet"
        case .history:
            if let lastEvolution = mascot.lastEvolution {
                return lastEvolutionLabel(for: lastEvolution)
            }
            return "No evolution history yet"
        }
    }

    private func rectangularSubdetail(for mascot: AtlasWidgetMascotSnapshot, focus: AtlasMascotWidgetFocus) -> String {
        switch focus {
        case .automatic:
            return "\(mascot.totalPoints) total rewards points"
        case .progress:
            return "\(mascot.totalPoints) total rewards points"
        case .status:
            return mascot.progressLabel
        case .moments:
            return mascot.latestMomentRecordedAt.map { formatMomentTimestamp($0) } ?? mascot.progressLabel
        case .history:
            return mascot.progressLabel
        }
    }

    private func focusHeadline(for mascot: AtlasWidgetMascotSnapshot, focus: AtlasMascotWidgetFocus) -> String {
        switch focus {
        case .automatic:
            return mascot.progressLabel
        case .progress:
            return mascot.progressLabel
        case .status:
            return mascot.statusLine
        case .moments:
            return mascot.latestMomentTitle ?? mascot.reactionTitle ?? "No mascot moment yet"
        case .history:
            if let lastEvolution = mascot.lastEvolution {
                return lastEvolutionLabel(for: lastEvolution)
            }
            return "No evolution history yet"
        }
    }

    private func focusBody(for mascot: AtlasWidgetMascotSnapshot, focus: AtlasMascotWidgetFocus) -> String {
        switch focus {
        case .automatic:
            return mascot.statusLine
        case .progress:
            return mascot.statusLine
        case .status:
            return mascot.statusLine
        case .moments:
            return mascot.latestMomentDetail ?? mascot.statusLine
        case .history:
            return mascot.lastEvolution.map(lastEvolutionLabel(for:)) ?? mascot.statusLine
        }
    }

    private func secondaryMetric(for mascot: AtlasWidgetMascotSnapshot, focus: AtlasMascotWidgetFocus) -> String {
        switch focus {
        case .automatic:
            return "\(mascot.totalPoints) total rewards points"
        case .progress:
            return "\(mascot.totalPoints) total rewards points"
        case .status:
            return mascot.progressLabel
        case .moments:
            return mascot.latestMomentRecordedAt.map { formatMomentTimestamp($0) } ?? mascot.progressLabel
        case .history:
            if let earnedAt = mascot.lastEvolution?.earnedAt {
                return formatMomentTimestamp(earnedAt)
            }
            return mascot.progressLabel
        }
    }

    private func focusFooter(
        for mascot: AtlasWidgetMascotSnapshot,
        focus: AtlasMascotWidgetFocus
    ) -> (text: String, symbol: String)? {
        switch focus {
        case .automatic:
            if let reactionTitle = mascot.reactionTitle {
                return (reactionTitle, mascot.reactionSymbolName ?? "sparkles")
            }
            return nil
        case .progress:
            if let reactionTitle = mascot.reactionTitle {
                return (reactionTitle, mascot.reactionSymbolName ?? "sparkles")
            }
            return nil
        case .status:
            return ("Current form: \(mascot.currentFormName)", "person.crop.circle.badge.checkmark")
        case .moments:
            if let latestMomentTitle = mascot.latestMomentTitle {
                return (latestMomentTitle, mascot.latestMomentSymbolName ?? "sparkles")
            }
            return mascot.reactionTitle.map { ($0, mascot.reactionSymbolName ?? "sparkles") }
        case .history:
            if let lastEvolution = mascot.lastEvolution {
                return (lastEvolutionLabel(for: lastEvolution), "clock.arrow.circlepath")
            }
            return nil
        }
    }

    private func widgetStageBadge(for mascot: AtlasWidgetMascotSnapshot) -> String {
        switch mascot.stage {
        case .stage1:
            return "Stage 1"
        case .stage2:
            return "Stage 2"
        case .stage3:
            return "Stage 3"
        }
    }

    private func focusAccentSymbol(for mascot: AtlasWidgetMascotSnapshot, focus: AtlasMascotWidgetFocus) -> String {
        switch focus {
        case .automatic, .progress:
            return mascot.nextFormName == nil ? "crown.fill" : "sparkles"
        case .status:
            return mascot.reactionSymbolName ?? "person.crop.circle.badge.checkmark"
        case .moments:
            return mascot.latestMomentSymbolName ?? "star.bubble.fill"
        case .history:
            return "clock.arrow.circlepath"
        }
    }

    private func widgetHighlightTint(for mascot: AtlasWidgetMascotSnapshot) -> Color {
        switch mascot.selection {
        case .aetherion:
            return Color(red: 0.95, green: 0.74, blue: 0.34)
        case .aurielle:
            return Color(red: 0.88, green: 0.97, blue: 1.0)
        }
    }

    private func widgetAccentTint(for mascot: AtlasWidgetMascotSnapshot) -> Color {
        switch mascot.selection {
        case .aetherion:
            return Color(red: 0.18, green: 0.42, blue: 0.94)
        case .aurielle:
            return Color(red: 0.43, green: 0.74, blue: 0.98)
        }
    }

    private func widgetLineLabel(for mascot: AtlasWidgetMascotSnapshot) -> String {
        switch mascot.selection {
        case .aetherion:
            return "Aetherion line"
        case .aurielle:
            return "Aurielle line"
        }
    }

    private func widgetFocusBadge(for focus: AtlasMascotWidgetFocus) -> String {
        switch focus {
        case .automatic:
            return "Auto"
        case .progress:
            return "Progress"
        case .status:
            return "Status"
        case .moments:
            return "Moment"
        case .history:
            return "History"
        }
    }

    private func shortStageLabel(for mascot: AtlasWidgetMascotSnapshot) -> String {
        switch mascot.stage {
        case .stage1:
            return "I"
        case .stage2:
            return "II"
        case .stage3:
            return "III"
        }
    }

    private func progressArcValue(for mascot: AtlasWidgetMascotSnapshot, focus: AtlasMascotWidgetFocus) -> CGFloat {
        if case .progress = focus,
           let threshold = mascot.nextThresholdPoints,
           threshold > mascot.totalPoints {
            let span = max(threshold, 1)
            return CGFloat(min(max(Double(mascot.totalPoints) / Double(span), 0.15), 0.92))
        }
        return 0.78
    }

    private func formatMomentTimestamp(_ timestamp: String) -> String {
        guard let date = AtlasWidgetTime.date(from: timestamp) else {
            return timestamp
        }
        return "Updated \(date.formatted(date: .abbreviated, time: .shortened))"
    }
}

private struct AtlasWidgetMetricPill: View {
    var title: String
    var value: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold, design: .default))
                .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.58))
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.94))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.18), AtlasWidgetPalette.surface.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasWidgetPalette.surface.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct AtlasQuickCaptureWidgetView: View {
    var entry: AtlasWidgetEntry?
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick Capture")
                    .font(.caption.weight(.semibold))
                Text("Shot, protein, hydration, workout context, and progress actions stay one tap away.")
                    .font(.caption2)
                    .lineLimit(3)
            }
        default:
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Capture")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.72))

                Text("Fast Kairo actions for the daily loop.")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AtlasWidgetPalette.textPrimary)

                if let support {
                    AtlasWidgetSupportScoreStrip(support: support)
                }

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button(intent: AtlasOpenQuickCaptureWidgetIntent(focus: .shot)) {
                            Label("Shot", systemImage: "syringe.fill")
                        }
                        .buttonStyle(.borderedProminent)

                        Button(intent: AtlasOpenQuickCaptureWidgetIntent(focus: .weight)) {
                            Label("Weight", systemImage: "scalemass.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                    .tint(AtlasWidgetPalette.primarySoft)

                    HStack(spacing: 8) {
                        Button(intent: AtlasOpenQuickCaptureWidgetIntent(focus: .protein)) {
                            Label("Protein", systemImage: "bolt.heart.fill")
                        }
                        .buttonStyle(.bordered)

                        Button(intent: AtlasOpenQuickCaptureWidgetIntent(focus: .hydration)) {
                            Label("Water", systemImage: "drop.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                    .tint(AtlasWidgetPalette.primarySoft)

                    HStack(spacing: 8) {
                        Button(intent: AtlasOpenQuickCaptureWidgetIntent(focus: .symptom)) {
                            Label("Symptom", systemImage: "waveform.path.ecg")
                        }
                        .buttonStyle(.bordered)

                        Button(intent: AtlasOpenProgressEvidenceWidgetIntent()) {
                            Label("Photos", systemImage: "camera.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                    .tint(AtlasWidgetPalette.primarySoft)
                }

                Spacer(minLength: 0)

                Text("Widgets support next shot, vial runway, companion state, and support signals.")
                    .font(.caption2)
                    .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.68))
                    .lineLimit(2)
            }
            .atlasWidgetCardBackground()
        }
    }

    private var support: AtlasWidgetSupportRingsSnapshot? {
        entry?.snapshot?.support ?? atlasWidgetPreviewProjectionSnapshot().support
    }
}

private struct AtlasWidgetSupportScoreStrip: View {
    var support: AtlasWidgetSupportRingsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Support \(support.score)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.9))
                Spacer()
                Text("Today")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AtlasWidgetPalette.textPrimary.opacity(0.62))
            }

            HStack(spacing: 6) {
                ForEach(support.rings.prefix(3)) { ring in
                    VStack(alignment: .leading, spacing: 4) {
                        Image(systemName: ring.symbolName)
                            .font(.system(size: 11, weight: .semibold))
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule().fill(AtlasWidgetPalette.surfaceMuted.opacity(0.14))
                                Capsule()
                                    .fill(tint(for: ring))
                                    .frame(width: proxy.size.width * min(max(ring.progress, 0), 1))
                            }
                        }
                        .frame(height: 4)
                        Text(ring.valueLabel)
                            .font(.system(size: 9, weight: .bold, design: .default))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .foregroundStyle(tint(for: ring))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(7)
                    .background(AtlasWidgetPalette.surfaceMuted.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .padding(10)
        .background(AtlasWidgetPalette.surfaceMuted.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func tint(for ring: AtlasWidgetSupportRingSnapshot) -> Color {
        switch ring.kind {
        case "protein":
            return Color(red: 0.45, green: 0.86, blue: 0.62)
        case "hydration":
            return Color(red: 0.38, green: 0.72, blue: 1)
        case "workout":
            return Color(red: 1, green: 0.72, blue: 0.35)
        default:
            return AtlasWidgetPalette.textPrimary.opacity(0.86)
        }
    }
}

private struct AtlasNextDueWidget: Widget {
    let kind = "AtlasNextDueWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AtlasNextDueProvider()) { entry in
            AtlasNextDueWidgetView(entry: entry)
        }
        .configurationDisplayName("Kairo Next Shot")
        .description("See the next Kairo shot and open a quick log action.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct AtlasLowStockWidget: Widget {
    let kind = "AtlasLowStockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AtlasLowStockProvider()) { entry in
            AtlasLowStockWidgetView(entry: entry)
        }
        .configurationDisplayName("Kairo Vial Runway")
        .description("See Kairo supply, vial runway, and inventory status.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct AtlasMascotWidget: Widget {
    let kind = "AtlasMascotWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: AtlasMascotWidgetConfigurationIntent.self, provider: AtlasMascotProvider()) { entry in
            AtlasMascotWidgetView(entry: entry)
        }
        .configurationDisplayName("Kairo Companion")
        .description("Track your Kairo companion with a configurable focus on progress, status, moments, or history.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

private struct AtlasQuickCaptureWidget: Widget {
    let kind = "AtlasQuickCaptureWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AtlasNextDueProvider()) { entry in
            AtlasQuickCaptureWidgetView(entry: entry)
        }
        .configurationDisplayName("Kairo Quick Capture")
        .description("Keep Kairo daily actions within easy reach from the Home Screen or Lock Screen.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

@main
struct AtlasWidgetsBundle: WidgetBundle {
    var body: some Widget {
        AtlasNextDueWidget()
        AtlasLowStockWidget()
        AtlasQuickCaptureWidget()
        AtlasMascotWidget()
    }
}
