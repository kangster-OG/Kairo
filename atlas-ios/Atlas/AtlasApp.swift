import AtlasFeatures
import AtlasDesignSystem
import SwiftUI
import WidgetKit

@main
struct AtlasApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var bootstrapState = AtlasAppBootstrap.makeState()

    init() {
        AtlasTypography.registerCustomFonts()
        AtlasPlatformAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            rootContent
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        if AtlasTypographyAudition.isEnabled {
            AtlasTypographyAuditionView()
        } else {
            productionRootContent
        }
    }

    @ViewBuilder
    private var productionRootContent: some View {
        switch bootstrapState {
        case .ready(let model):
            AtlasRootView(model: model)
                .tint(.blue)
                .task {
                    model.dependencies.diagnostics.markLaunchCompleted()
                    AtlasWidgetRefreshCoordinator.reloadAll()
                }
                .onOpenURL { url in
                    Task {
                        await model.handleIncomingURL(url)
                    }
                }
                .onChange(of: model.widgetProjectionVersion) { _, _ in
                    AtlasWidgetRefreshCoordinator.reloadAll()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else {
                        return
                    }
                    AtlasWidgetRefreshCoordinator.reloadAll()
                    Task {
                        await model.consumePendingExtensionActionIfNeeded()
                    }
                }
        case .failed(let message):
            AtlasBootstrapFailureView(message: message) {
                bootstrapState = AtlasAppBootstrap.makeState()
            }
        }
    }
}

private enum AtlasTypographyAudition {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-AtlasTypographyAudition")
            || ProcessInfo.processInfo.environment["ATLAS_TYPOGRAPHY_AUDITION"] == "1"
    }
}

private struct AtlasTypographyAuditionView: View {
    private var candidateName: String {
        switch AtlasTypography.currentCandidate {
        case .system:
            return "Current SF Rounded"
        case .avenir:
            return "Avenir Next + SF Body"
        case .plex:
            return "IBM Plex Sans"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroSample
                commandSample
                denseSample
                mascotSample
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AtlasPalette.background.ignoresSafeArea())
    }

    private var heroSample: some View {
        VStack(alignment: .leading, spacing: 14) {
            AtlasStatusBadge(candidateName, tint: .white)

            Text("Atlas")
                .font(AtlasTypography.brandFont(size: 46, weight: .bold, relativeTo: .largeTitle))
                .foregroundStyle(.white)

            Text("Protocol tracking for injections, reminders, inventory, and review.")
                .atlasTextRole(.screenSubtitle)
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AtlasPalette.shellTop, AtlasPalette.shellTopAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var commandSample: some View {
        AtlasSectionCard(
            style: .hero,
            title: "Today"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("One clear move, then the rest of the plan stays quiet.")
                    .atlasTextRole(.screenSubtitle)
                    .foregroundStyle(AtlasPalette.textSecondary)

                AtlasMetricStrip(
                    metrics: [
                        .init(id: "due", title: "Next due", value: "8:30 PM", tint: AtlasPalette.primary),
                        .init(id: "stock", title: "Inventory", value: "12 days", tint: AtlasPalette.warning),
                        .init(id: "review", title: "Review", value: "Ready", tint: AtlasPalette.success)
                    ]
                )
                Button("Log current protocol") {}
                    .buttonStyle(AtlasPrimaryButtonStyle())
            }
        }
    }

    private var denseSample: some View {
        AtlasSectionCard(style: .elevated, title: "Protocol stack") {
            VStack(alignment: .leading, spacing: 14) {
                sampleRow(title: "Medication level", detail: "Estimated peak window is narrowing.", badge: "Review")
                sampleRow(title: "Inventory check", detail: "Supply crosses your reorder buffer soon.", badge: "12 days")
                sampleRow(title: "Weekly review", detail: "Three logs are ready to roll into the summary.", badge: "Ready")
            }
        }
    }

    private var mascotSample: some View {
        AtlasSectionCard(
            style: .utility,
            title: "Mascot momentum"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Cindlet is close to Voltflare.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                HStack(spacing: 12) {
                    AtlasStatusBadge("Next form", tint: AtlasPalette.reward)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Evolution path")
                            .atlasTextRole(.deckEyebrow)
                        Text("Cindlet -> Voltflare -> Aetherion")
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                    }
                    Spacer()
                }
            }
        }
    }

    private func sampleRow(title: String, detail: String, badge: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.secondaryText)
            }
            Spacer(minLength: 10)
            AtlasStatusBadge(badge, tint: AtlasPalette.primary)
        }
    }
}

private struct AtlasBootstrapFailureView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.orange)
            Text("Atlas couldn't finish launch")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.body)
                .foregroundStyle(AtlasPalette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Try again", action: retry)
                .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding(24)
    }
}

private enum AtlasWidgetRefreshCoordinator {
    private static let widgetKinds = [
        "AtlasNextDueWidget",
        "AtlasLowStockWidget",
        "AtlasQuickCaptureWidget",
        "AtlasMascotWidget"
    ]

    static func reloadAll() {
        WidgetCenter.shared.reloadAllTimelines()
        widgetKinds.forEach { WidgetCenter.shared.reloadTimelines(ofKind: $0) }
    }
}
