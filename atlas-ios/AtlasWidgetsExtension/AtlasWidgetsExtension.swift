import SwiftUI
import WidgetKit

struct AtlasWidgetEntry: TimelineEntry {
    let date: Date
}

struct AtlasWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> AtlasWidgetEntry {
        AtlasWidgetEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (AtlasWidgetEntry) -> Void) {
        completion(AtlasWidgetEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AtlasWidgetEntry>) -> Void) {
        let timeline = Timeline(
            entries: [AtlasWidgetEntry(date: .now)],
            policy: .after(.now.addingTimeInterval(60 * 30))
        )
        completion(timeline)
    }
}

struct AtlasWidgetView: View {
    var entry: AtlasWidgetProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Atlas")
                .font(.headline)
            Text("Widget scaffold")
                .font(.subheadline.weight(.semibold))
            Text("Shared projection wiring begins after Phase 2 persistence.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(entry.date, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct AtlasWidget: Widget {
    let kind: String = "AtlasWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AtlasWidgetProvider()) { entry in
            AtlasWidgetView(entry: entry)
        }
        .configurationDisplayName("Atlas")
        .description("Phase 1 widget scaffold for Atlas native iOS.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct AtlasWidgetsBundle: WidgetBundle {
    var body: some Widget {
        AtlasWidget()
    }
}
