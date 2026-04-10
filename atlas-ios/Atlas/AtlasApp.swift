import AtlasFeatures
import AtlasDesignSystem
import SwiftUI
import WidgetKit

@main
struct AtlasApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var bootstrapState = AtlasAppBootstrap.makeState()

    init() {
        AtlasPlatformAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            switch bootstrapState {
            case .ready(let model):
                AtlasRootView(model: model)
                    .preferredColorScheme(.light)
                    .tint(.blue)
                    .task {
                        model.dependencies.diagnostics.markLaunchCompleted()
                    }
                    .onOpenURL { url in
                        Task {
                            await model.handleIncomingURL(url)
                        }
                    }
                    .onChange(of: model.widgetProjectionVersion) { _, _ in
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        guard newPhase == .active else {
                            return
                        }
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
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Try again", action: retry)
                .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding(24)
        .preferredColorScheme(.light)
    }
}
