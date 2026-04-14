import AppIntents
import Foundation
import SwiftUI
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
    static let description = IntentDescription("Choose which mascot detail Atlas should emphasize in this widget.")

    @Parameter(title: "Focus")
    var focus: AtlasMascotWidgetFocus

    init() {
        focus = .automatic
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
            snapshot: nil,
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
                var resolvedConfiguration = configuration
                resolvedConfiguration.focus = focus
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

private struct AtlasOpenTodayWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Today"
    static let description = IntentDescription("Open Atlas to Today.")
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
    case progressPhoto = "progress_photo"
}

private struct AtlasOpenQuickCaptureWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Quick Capture"
    static let description = IntentDescription("Open Atlas to a focused quick-capture lane.")
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
    static let description = IntentDescription("Open Atlas to visual progress capture and compare.")
    static let openAppWhenRun = true
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        try AtlasPendingWidgetActionStore.write(route: "progress-evidence")
        return .result()
    }
}

private struct AtlasOpenInventoryWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Inventory"
    static let description = IntentDescription("Open Atlas to Inventory.")
    static let openAppWhenRun = true
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        try AtlasPendingWidgetActionStore.write(route: "inventory")
        return .result()
    }
}

private struct AtlasOpenMascotWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Mascot"
    static let description = IntentDescription("Open Atlas to the mascot detail screen.")
    static let openAppWhenRun = true
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        try AtlasPendingWidgetActionStore.write(route: "mascot")
        return .result()
    }
}

private struct AtlasMarkTakenWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Taken"
    static let description = IntentDescription("Open Atlas and mark the projected occurrence as taken.")
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
    static let description = IntentDescription("Open Atlas and skip the projected occurrence.")
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

private struct AtlasWidgetCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.14, blue: 0.20),
                        Color(red: 0.17, green: 0.23, blue: 0.32)
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
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.white.opacity(0.14), in: Capsule())
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
        .foregroundStyle(.white.opacity(0.68))
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
                            Text("Next due")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.72))
                            Text(nextDue.displayTitle)
                                .font(family == .systemSmall ? .headline.weight(.semibold) : .title3.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(family == .systemSmall ? 2 : 3)
                            Text(nextDue.statusSummary)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.78))
                                .lineLimit(2)
                        }
                        Spacer(minLength: 8)
                        AtlasStatusBadge(text: atlasBadgeText(for: nextDue))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(nextDue.dueLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        if nextDue.overdueCount > 1 {
                            Text("\(nextDue.overdueCount) items currently need attention.")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.72))
                                .lineLimit(2)
                        }
                    }

                    Spacer(minLength: 0)

                    if let quickAction = context.snapshot.quickActions.first {
                        if family == .systemSmall {
                            HStack(spacing: 8) {
                                Button(intent: AtlasMarkTakenWidgetIntent(
                                    occurrenceID: quickAction.occurrenceID,
                                    protocolID: quickAction.protocolID
                                )) {
                                    Label("Taken", systemImage: "checkmark.circle.fill")
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
                            .tint(.white.opacity(0.18))
                            .labelStyle(.iconOnly)
                        } else {
                            HStack(spacing: 8) {
                                Button(intent: AtlasMarkTakenWidgetIntent(
                                    occurrenceID: quickAction.occurrenceID,
                                    protocolID: quickAction.protocolID
                                )) {
                                    Label("Mark taken", systemImage: "checkmark.circle.fill")
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
                            .tint(.white.opacity(0.18))
                        }
                    } else {
                        HStack {
                            Button(intent: AtlasOpenTodayWidgetIntent()) {
                                Label("Open Atlas", systemImage: "arrow.up.forward.app")
                            }
                            .buttonStyle(.bordered)
                            .tint(.white.opacity(0.18))
                        }
                    }
                    if let generatedAt = context.freshness.generatedAt {
                        AtlasProjectionTimestampLine(prefix: "Updated", date: generatedAt)
                    }
                }
                .atlasWidgetCardBackground()
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Next due")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                    Text(
                        (context?.freshness.isStale ?? false)
                            ? "Open Atlas to refresh your local next due summary before taking action."
                            : "Open Atlas to refresh your next due summary."
                    )
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                    if let generatedAt = context?.freshness.generatedAt {
                        AtlasProjectionTimestampLine(prefix: "Last refreshed", date: generatedAt)
                    }
                    Spacer()
                    Button(intent: AtlasOpenTodayWidgetIntent()) {
                        Label("Open Atlas", systemImage: "arrow.up.forward.app")
                    }
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.18))
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
                            Text("Low stock")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.72))
                            Text(atlasHeadline(for: context.snapshot.lowStock))
                                .font(family == .systemSmall ? .headline.weight(.semibold) : .title3.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(family == .systemSmall ? 3 : 2)
                        }
                        Spacer(minLength: 8)
                        AtlasStatusBadge(text: atlasBadgeText(for: context.snapshot.lowStock))
                    }

                    if let firstItem = context.snapshot.lowStock.items.first {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(firstItem.displayTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                            Text(firstItem.detail)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.78))
                                .lineLimit(family == .systemSmall ? 2 : 3)
                        }
                    } else {
                        Text("No low-stock items are currently projected.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.78))
                            .lineLimit(3)
                    }

                    Spacer(minLength: 0)

                    HStack {
                        Button(intent: AtlasOpenInventoryWidgetIntent()) {
                            Label("Open Inventory", systemImage: "shippingbox.fill")
                        }
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.18))
                        Spacer(minLength: 8)
                        if let generatedAt = context.freshness.generatedAt {
                            AtlasProjectionTimestampLine(prefix: "Updated", date: generatedAt)
                        }
                    }
                }
                .atlasWidgetCardBackground()
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Low stock")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                    Text(
                        (context?.freshness.isStale ?? false)
                            ? "Open Atlas to refresh supplies and procurement review status."
                            : "Open Atlas to refresh supplies and inventory status."
                    )
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                    if let generatedAt = context?.freshness.generatedAt {
                        AtlasProjectionTimestampLine(prefix: "Last refreshed", date: generatedAt)
                    }
                    Spacer()
                    Button(intent: AtlasOpenInventoryWidgetIntent()) {
                        Label("Open Atlas", systemImage: "arrow.up.forward.app")
                    }
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.18))
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
                .stroke(.white.opacity(0.14), lineWidth: 1)
                .frame(width: size * 0.94, height: size * 0.94)

            Image(assetName)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .saturation(snapshot.pose == .rest ? 0.72 : 1)
                .opacity(snapshot.pose == .rest ? 0.9 : 1)
                .scaleEffect(snapshot.pose == .milestone ? 1.04 : (snapshot.pose == .evolutionReady ? 1.03 : 1))
                .shadow(color: accentTint.opacity(0.16), radius: size * 0.12, y: size * 0.06)
                .frame(width: size, height: size)

            if let badgeSymbol {
                Image(systemName: badgeSymbol)
                    .font(.system(size: max(size * 0.14, 10), weight: .bold))
                    .foregroundStyle(badgeTint)
                    .padding(max(size * 0.05, 4))
                    .background(Circle().fill(Color.black.opacity(0.72)))
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                    )
            }
        }
    }

    private var assetName: String {
        switch (snapshot.selection, snapshot.stage, usesHappyAsset) {
        case (.aetherion, .stage1, false):
            return "AtlasMascotAetherionStage1Idle"
        case (.aetherion, .stage1, true):
            return "AtlasMascotAetherionStage1Happy"
        case (.aetherion, .stage2, false):
            return "AtlasMascotAetherionStage2Idle"
        case (.aetherion, .stage2, true):
            return "AtlasMascotAetherionStage2Happy"
        case (.aetherion, .stage3, false):
            return "AtlasMascotAetherionStage3Idle"
        case (.aetherion, .stage3, true):
            return "AtlasMascotAetherionStage3Happy"
        case (.aurielle, .stage1, false):
            return "AtlasMascotAurielleStage1Idle"
        case (.aurielle, .stage1, true):
            return "AtlasMascotAurielleStage1Happy"
        case (.aurielle, .stage2, false):
            return "AtlasMascotAurielleStage2Idle"
        case (.aurielle, .stage2, true):
            return "AtlasMascotAurielleStage2Happy"
        case (.aurielle, .stage3, false):
            return "AtlasMascotAurielleStage3Idle"
        case (.aurielle, .stage3, true):
            return "AtlasMascotAurielleStage3Happy"
        }
    }

    private var usesHappyAsset: Bool {
        switch snapshot.pose {
        case .happy, .evolutionReady, .milestone:
            return true
        case .idle, .recovery, .rest:
            return false
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
            return .white
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

private struct AtlasMascotWidgetView: View {
    var entry: AtlasMascotWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            let context = entry.snapshotContext(for: .mascot)
            if let context,
               context.snapshot.featureFlags.flags.nativeWidgets,
               context.freshness.isStale == false,
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
                            colors: [widgetHighlightTint(for: mascot).opacity(0.28), Color.white.opacity(0.06)],
                            center: .center,
                            startRadius: 6,
                            endRadius: 46
                        )
                    )
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                AtlasWidgetMascotSprite(snapshot: mascot, size: 44)
            }
        case .accessoryRectangular:
            HStack(spacing: 10) {
                AtlasWidgetMascotSprite(snapshot: mascot, size: 46)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(mascot.displayName)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        AtlasStatusBadge(text: widgetStageBadge(for: mascot))
                    }
                    Text(rectangularDetail(for: mascot, focus: focus))
                        .font(.caption2)
                        .lineLimit(2)
                    Text(rectangularSubdetail(for: mascot, focus: focus))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
        default:
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text("Mascot")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.72))
                            AtlasStatusBadge(text: widgetStageBadge(for: mascot))
                        }
                        Text(mascot.displayName)
                            .font(family == .systemSmall ? .headline.weight(.semibold) : .title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        if mascot.displayName != mascot.currentFormName {
                            Text(mascot.currentFormName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.76))
                        }
                        Text(focusBody(for: mascot, focus: focus))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.78))
                            .lineLimit(family == .systemSmall ? 3 : 2)
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .center, spacing: 6) {
                        AtlasWidgetMascotSprite(
                            snapshot: mascot,
                            size: family == .systemSmall ? 62 : 84
                        )
                        Text(mascot.currentFormName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.82))
                            .lineLimit(1)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(focusHeadline(for: mascot, focus: focus))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(secondaryMetric(for: mascot, focus: focus))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.72))
                }

                if let footer = focusFooter(for: mascot, focus: focus) {
                    Label(footer.text, systemImage: footer.symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.86))
                        .lineLimit(2)
                }

                if let nextFormName = mascot.nextFormName {
                    Label("Next unlock: \(nextFormName)", systemImage: "sparkles")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(widgetHighlightTint(for: mascot))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                HStack {
                    Button(intent: AtlasOpenMascotWidgetIntent()) {
                        Label("Open Mascot", systemImage: "sparkles")
                    }
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.18))

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
            Text(isStale ? "Open Atlas to refresh mascot" : "Turn on rewards to enable mascot")
        case .accessoryCircular:
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Mascot")
                    .font(.caption.weight(.semibold))
                Text(
                    isStale
                        ? "Open Atlas to refresh mascot progression."
                        : "Turn on rewards to bring the mascot widget to life."
                )
                .font(.caption2)
                .lineLimit(3)
            }
        default:
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("Mascot")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                    AtlasStatusBadge(text: isStale ? "Needs refresh" : "Standby")
                }
                Text(
                    isStale
                        ? "Open Atlas to refresh your mascot progression and sprite state."
                        : "Turn on rewards in Atlas to bring the \(focus.rawValue) mascot widget to life."
                )
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                if let generatedAt = freshness?.generatedAt {
                    AtlasProjectionTimestampLine(prefix: "Last refreshed", date: generatedAt)
                }
                Spacer()
                Button(intent: AtlasOpenMascotWidgetIntent()) {
                    Label("Open Atlas", systemImage: "sparkles")
                }
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.18))
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

    private func widgetHighlightTint(for mascot: AtlasWidgetMascotSnapshot) -> Color {
        switch mascot.selection {
        case .aetherion:
            return Color(red: 0.95, green: 0.74, blue: 0.34)
        case .aurielle:
            return Color(red: 0.88, green: 0.97, blue: 1.0)
        }
    }

    private func formatMomentTimestamp(_ timestamp: String) -> String {
        guard let date = AtlasWidgetTime.date(from: timestamp) else {
            return timestamp
        }
        return "Updated \(date.formatted(date: .abbreviated, time: .shortened))"
    }
}

private struct AtlasQuickCaptureWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick Capture")
                    .font(.caption.weight(.semibold))
                Text("Shot, weight, symptom, and progress actions stay one tap away.")
                    .font(.caption2)
                    .lineLimit(3)
            }
        default:
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Capture")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))

                Text("Fast Atlas actions for the daily loop.")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

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
                    .tint(.white.opacity(0.18))

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
                    .tint(.white.opacity(0.18))
                }

                Spacer(minLength: 0)

                Text("Also supports hydration and protein quick capture from Atlas shortcuts.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(2)
            }
            .atlasWidgetCardBackground()
        }
    }
}

private struct AtlasNextDueWidget: Widget {
    let kind = "AtlasNextDueWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AtlasNextDueProvider()) { entry in
            AtlasNextDueWidgetView(entry: entry)
        }
        .configurationDisplayName("Atlas Next Due")
        .description("See the next Atlas due item and open a quick log action.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct AtlasLowStockWidget: Widget {
    let kind = "AtlasLowStockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AtlasLowStockProvider()) { entry in
            AtlasLowStockWidgetView(entry: entry)
        }
        .configurationDisplayName("Atlas Low Stock")
        .description("See privacy-aware Atlas supply and inventory status.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct AtlasMascotWidget: Widget {
    let kind = "AtlasMascotWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: AtlasMascotWidgetConfigurationIntent.self, provider: AtlasMascotProvider()) { entry in
            AtlasMascotWidgetView(entry: entry)
        }
        .configurationDisplayName("Atlas Mascot")
        .description("Track your Atlas mascot with a configurable focus on progress, status, moments, or history.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

private struct AtlasQuickCaptureWidget: Widget {
    let kind = "AtlasQuickCaptureWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AtlasNextDueProvider()) { _ in
            AtlasQuickCaptureWidgetView()
        }
        .configurationDisplayName("Atlas Quick Capture")
        .description("Keep Atlas daily actions within easy reach from the Home Screen or Lock Screen.")
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
