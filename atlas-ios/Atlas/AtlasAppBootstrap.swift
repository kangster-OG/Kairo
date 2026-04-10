import AtlasDomain
import AtlasFeatures
import AtlasPersistence
import AtlasPrivacy
import AtlasSystem
import Foundation

enum AtlasAppBootstrapState {
    case ready(AtlasAppModel)
    case failed(String)
}

enum AtlasAppBootstrap {
    @MainActor
    static func makeState() -> AtlasAppBootstrapState {
        let featureFlags = AtlasFeatureFlags()
        let privacyFormatter = AtlasPrivacyFormatter()
        let notificationManager = AtlasNotificationManager()
        let cloudSync = AtlasSupabaseCloudSyncManager()
        let diagnostics = AtlasDiagnosticsReporter()
        diagnostics.markLaunchStarted()

        do {
            let persistenceController = try AtlasPersistenceController.live(
                appGroupIdentifier: "group.com.dkang2000.Atlas.shared",
                featureFlags: featureFlags.flags,
                privacyFormatter: privacyFormatter,
                notifications: notificationManager
            )
            return .ready(
                makeModel(
                    persistenceController: persistenceController,
                    featureFlags: featureFlags,
                    privacyFormatter: privacyFormatter,
                    notificationManager: notificationManager,
                    cloudSync: cloudSync,
                    diagnostics: diagnostics
                )
            )
        } catch {
            guard let persistenceController = try? AtlasPersistenceController.inMemory(
                featureFlags: featureFlags.flags,
                privacyFormatter: privacyFormatter,
                notifications: notificationManager
            ) else {
                return .failed(
                    "Atlas couldn't open local storage on this device. Try again. If the problem keeps happening, reinstall the beta before importing or creating new data."
                )
            }

            return .ready(
                makeModel(
                    persistenceController: persistenceController,
                    featureFlags: featureFlags,
                    privacyFormatter: privacyFormatter,
                    notificationManager: notificationManager,
                    cloudSync: cloudSync,
                    diagnostics: diagnostics
                )
            )
        }
    }

    @MainActor
    private static func makeModel(
        persistenceController: AtlasPersistenceController,
        featureFlags: AtlasFeatureFlags,
        privacyFormatter: AtlasPrivacyFormatter,
        notificationManager: AtlasNotificationManager,
        cloudSync: any CloudSyncManaging,
        diagnostics: AtlasDiagnosticsReporter
    ) -> AtlasAppModel {
        let dependencies = AtlasAppDependencies(
            featureFlags: featureFlags,
            notifications: notificationManager,
            biometrics: AtlasBiometricGate(),
            healthKit: AtlasHealthKitManager(),
            cloudSync: cloudSync,
            diagnostics: diagnostics,
            importExport: persistenceController.importExportBridge,
            sharedProjectionWriter: persistenceController.sharedProjectionWriter,
            persistence: persistenceController.container,
            reminders: persistenceController.reminderCoordinator,
            privacyFormatter: privacyFormatter
        )

        let model = AtlasAppModel(dependencies: dependencies)
        #if DEBUG
        applyQALaunchOverrides(to: model)
        #endif
        return model
    }
}

#if DEBUG
private extension AtlasAppBootstrap {
    @MainActor
    static func applyQALaunchOverrides(to model: AtlasAppModel) {
        let environment = ProcessInfo.processInfo.environment

        if let rawTab = atlasQALaunchValue(
            environmentKey: "ATLAS_QA_ACTIVE_TAB",
            argumentName: "--atlas-qa-active-tab"
        ),
           let tab = AtlasTab(rawValue: rawTab) {
            model.activeTab = tab
        }

        guard let rawRoute = atlasQALaunchValue(
            environmentKey: "ATLAS_QA_ROUTE",
            argumentName: "--atlas-qa-route"
        ) else {
            return
        }

        switch rawRoute {
        case "inventory":
            model.open(.inventory)
        case "calculator":
            model.open(.calculator)
        case "trustVault":
            model.open(.trustVault)
        case "importFlow":
            model.open(.importFlow)
        case "reviewMode":
            model.open(.reviewMode)
        default:
            if rawRoute.hasPrefix("protocolDetail:") {
                model.open(.protocolDetail(String(rawRoute.dropFirst("protocolDetail:".count))))
            } else if rawRoute.hasPrefix("protocolEdit:") {
                model.open(.protocolEdit(String(rawRoute.dropFirst("protocolEdit:".count))))
            } else if rawRoute.hasPrefix("protocolChange:") {
                model.open(.protocolChange(String(rawRoute.dropFirst("protocolChange:".count))))
            }
        }
    }

    static func atlasQALaunchValue(environmentKey: String, argumentName: String) -> String? {
        if let rawValue = ProcessInfo.processInfo.environment[environmentKey]?.trimmingCharacters(in: .whitespacesAndNewlines),
           rawValue.isEmpty == false {
            return rawValue
        }

        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: argumentName),
              arguments.indices.contains(arguments.index(after: index)) else {
            return nil
        }

        let rawValue = arguments[arguments.index(after: index)].trimmingCharacters(in: .whitespacesAndNewlines)
        return rawValue.isEmpty ? nil : rawValue
    }
}
#endif
