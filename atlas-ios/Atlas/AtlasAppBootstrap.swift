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
                    notificationManager: notificationManager
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
                    notificationManager: notificationManager
                )
            )
        }
    }

    @MainActor
    private static func makeModel(
        persistenceController: AtlasPersistenceController,
        featureFlags: AtlasFeatureFlags,
        privacyFormatter: AtlasPrivacyFormatter,
        notificationManager: AtlasNotificationManager
    ) -> AtlasAppModel {
        let dependencies = AtlasAppDependencies(
            featureFlags: featureFlags,
            notifications: notificationManager,
            biometrics: AtlasBiometricGate(),
            healthKit: AtlasHealthKitManager(),
            importExport: persistenceController.importExportBridge,
            sharedProjectionWriter: persistenceController.sharedProjectionWriter,
            persistence: persistenceController.container,
            reminders: persistenceController.reminderCoordinator,
            privacyFormatter: privacyFormatter
        )

        return AtlasAppModel(dependencies: dependencies)
    }
}
