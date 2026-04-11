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
    var featureFlags: AtlasWidgetFeatureFlagProjection
}

private enum AtlasWidgetProjectionSurface {
    case nextDue
    case lowStock

    var staleAfter: TimeInterval {
        switch self {
        case .nextDue:
            return 2 * 60 * 60
        case .lowStock:
            return 12 * 60 * 60
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

private struct AtlasNextDueWidget: Widget {
    let kind = "AtlasNextDueWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AtlasNextDueProvider()) { entry in
            AtlasNextDueWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Due")
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
        .configurationDisplayName("Low Stock")
        .description("See privacy-aware supply and inventory status.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct AtlasWidgetsBundle: WidgetBundle {
    var body: some Widget {
        AtlasNextDueWidget()
        AtlasLowStockWidget()
    }
}
