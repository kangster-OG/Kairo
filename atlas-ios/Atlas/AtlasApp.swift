import AtlasFeatures
import SwiftUI

@main
struct AtlasApp: App {
    @State private var bootstrapState = AtlasAppBootstrap.makeState()

    var body: some Scene {
        WindowGroup {
            switch bootstrapState {
            case .ready(let model):
                AtlasRootView(model: model)
                    .tint(.blue)
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
    }
}
