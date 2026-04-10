import AtlasDomain
import AtlasPrivacy
import AtlasSystem
import Foundation

public protocol ProtocolRepository: Sendable {
    func listProtocolSummaries() async throws -> [ProtocolSummary]
    func fetchProtocolDetail(id: String) async throws -> AtlasProtocolDetailSnapshot?
    func createProtocol(_ draft: AtlasProtocolDraft, now: Date) async throws -> AtlasProtocolDetailSnapshot
    func updateProtocol(id: String, draft: AtlasProtocolDraft, now: Date) async throws -> AtlasProtocolDetailSnapshot
}

public protocol TimelineRepository: Sendable {
    func fetchHistory(limit: Int) async throws -> [ImmutableLogEventSummary]
    func fetchTimeline(_ query: AtlasTimelineQuery) async throws -> [AtlasTimelineEntry]
}

public protocol TodayRepository: Sendable {
    func fetchNextDue() async throws -> FutureOccurrenceSummary?
    func fetchTodaySnapshot(referenceDate: Date) async throws -> AtlasTodaySnapshot
}

public protocol CoreLoopRepository: Sendable {
    func ensureProjectedOccurrences(referenceDate: Date) async throws
    func logOccurrence(_ request: AtlasOccurrenceLogRequest, now: Date) async throws
}

public protocol SettingsRepository: Sendable {
    func currentSettingsSnapshot() async throws -> AtlasSettingsSnapshot
    func updateAccountMode(_ accountMode: AtlasAccountMode, now: Date) async throws -> AtlasSettingsSnapshot
    func updateTrustVaultRenderMode(_ renderMode: AtlasPrivacyRenderMode, now: Date) async throws -> AtlasSettingsSnapshot
    func updateSummarySettings(_ update: AtlasSummarySettingsUpdate, now: Date) async throws -> AtlasSettingsSnapshot
    func updateRetentionSettings(_ update: AtlasRetentionSettingsUpdate, now: Date) async throws -> AtlasSettingsSnapshot
    func updateHealthConnection(
        provider: AtlasHealthProviderKey,
        enabled: Bool,
        connected: Bool,
        lastSyncAt: Date?,
        lastError: String?,
        now: Date
    ) async throws -> AtlasSettingsSnapshot
}

public protocol OnboardingRepository: Sendable {
    func loadBootstrapSnapshot() async throws -> AtlasBootstrapSnapshot
    func saveDraft(_ draft: AtlasOnboardingDraft, now: Date) async throws -> AtlasBootstrapSnapshot
    func completeOnboarding(_ draft: AtlasOnboardingDraft, now: Date) async throws -> AtlasBootstrapSnapshot
    func resetOnboarding(now: Date) async throws -> AtlasBootstrapSnapshot
}

public protocol TrustVaultRepository: Sendable {
    func fetchTrustVaultSnapshot() async throws -> AtlasTrustVaultSnapshot
    func updatePrivacyProfile(
        _ update: AtlasTrustVaultProfileUpdate,
        now: Date
    ) async throws -> AtlasTrustVaultSnapshot
    func saveProtocolAlias(
        _ draft: AtlasProtocolAliasDraft,
        now: Date
    ) async throws -> AtlasTrustVaultSnapshot
    func recordVaultUnlock(surface: String, now: Date) async throws
}

public protocol ReminderRepository: Sendable {
    func fetchReminderSettings() async throws -> AtlasReminderSettingsSnapshot
    func listScheduledReminders() async throws -> [AtlasReminderRecord]
}

public protocol InventoryRepository: Sendable {
    func fetchInventorySnapshot(referenceDate: Date) async throws -> AtlasInventorySnapshot
    func fetchVialDetail(id: String, referenceDate: Date) async throws -> AtlasVialDetailSnapshot?
    func fetchConsumableDetail(id: String, referenceDate: Date) async throws -> AtlasConsumableDetailSnapshot?
    func saveVial(_ draft: AtlasVialDraft, now: Date) async throws -> AtlasVialDetailSnapshot
    func saveConsumable(_ draft: AtlasConsumableDraft, now: Date) async throws -> AtlasConsumableDetailSnapshot
    func archiveVial(id: String, now: Date) async throws
    func setConsumableArchived(id: String, isArchived: Bool, now: Date) async throws
    func updateProtocolInventorySettings(
        _ update: AtlasProtocolInventorySettingsUpdate,
        now: Date
    ) async throws -> AtlasProtocolInventorySetting
    func applyManualCorrection(
        _ correction: AtlasInventoryCorrectionDraft,
        now: Date
    ) async throws -> AtlasInventoryCorrectionResult
    func applyConsumableAdjustment(
        _ adjustment: AtlasConsumableAdjustmentDraft,
        now: Date
    ) async throws -> AtlasConsumableAdjustmentResult
    func fetchProtocolSiteOptions(protocolID: String) async throws -> AtlasProtocolSiteOptions
    func listSites() async throws -> [AtlasSiteSummary]
    func saveSite(_ draft: AtlasSiteDraft, now: Date) async throws -> AtlasSiteSummary
}

public protocol CalculatorRepository: Sendable {
    func listProfiles() async throws -> [AtlasCalculatorProfileRecord]
    func saveProfile(_ draft: AtlasCalculatorProfileDraft, now: Date) async throws -> AtlasCalculatorProfileRecord
    func deleteProfile(id: String) async throws
}

public protocol MetricsRepository: Sendable {
    func fetchInsightsSnapshot(referenceDate: Date) async throws -> AtlasInsightsSnapshot
    func saveContextEntry(_ draft: AtlasContextEntryDraft, now: Date) async throws -> AtlasContextLogRecord
    func saveWeightEntry(_ draft: AtlasWeightEntryDraft, now: Date) async throws -> AtlasWeightLogRecord
    func saveSymptomEntry(_ draft: AtlasSymptomEntryDraft, now: Date) async throws -> AtlasSymptomLogRecord
    func saveMetricDefinition(_ draft: AtlasMetricDefinitionDraft, now: Date) async throws -> AtlasCustomMetricRecord
    func archiveMetricDefinition(id: String, now: Date) async throws
    func deleteMetricDefinition(id: String) async throws
    func saveMetricValueEntry(_ draft: AtlasMetricValueEntryDraft, now: Date) async throws -> AtlasMetricValueLogRecord
}

public protocol ProtocolChangeStudioRepository: Sendable {
    func loadStudio(protocolID: String, referenceDate: Date) async throws -> AtlasProtocolChangeStudioContext
    func buildPreview(
        protocolID: String,
        draft: AtlasProtocolChangeDraft,
        referenceDate: Date
    ) async throws -> AtlasProtocolChangePreview
    func commitChange(
        protocolID: String,
        draft: AtlasProtocolChangeDraft,
        referenceDate: Date
    ) async throws -> AtlasProtocolChangeCommitResult
}

public protocol ReviewModeRepository: Sendable {
    func fetchOwnerSnapshot(now: Date) async throws -> AtlasReviewOwnerSnapshot
    func createReview(_ request: AtlasReviewRequest, now: Date) async throws -> AtlasReviewCreationResult
    func loadWorkspace(from fileURL: URL, now: Date) async throws -> AtlasReviewWorkspace
    func revokeReviewSession(id: String, now: Date) async throws -> AtlasReviewOwnerSnapshot
}

public protocol RetentionRepository: Sendable {
    func fetchRetentionSnapshot(referenceDate: Date) async throws -> AtlasRetentionSnapshot
    func markWeeklyReviewComplete(now: Date) async throws -> AtlasRetentionSnapshot
}

public protocol ReminderCoordinating: Sendable {
    func authorizationStatus() async -> AtlasNotificationAuthorizationStatus
    func requestAuthorization() async throws -> AtlasNotificationAuthorizationStatus
    func configureReminderHandling(
        onActionApplied: (@Sendable () async -> Void)?
    ) async throws
    func fetchReminderSettings() async throws -> AtlasReminderSettingsSnapshot
    func updateReminderSettings(
        _ update: AtlasReminderPreferenceUpdate,
        referenceDate: Date
    ) async throws -> AtlasReminderSettingsSnapshot
    func syncReminders(referenceDate: Date) async throws
}

public struct AtlasPersistenceContainer: Sendable {
    public var onboarding: any OnboardingRepository
    public var protocols: any ProtocolRepository
    public var timeline: any TimelineRepository
    public var today: any TodayRepository
    public var coreLoop: any CoreLoopRepository
    public var settings: any SettingsRepository
    public var trustVault: any TrustVaultRepository
    public var reminders: any ReminderRepository
    public var inventory: any InventoryRepository
    public var calculator: any CalculatorRepository
    public var metrics: any MetricsRepository
    public var changeStudio: any ProtocolChangeStudioRepository
    public var reviewMode: any ReviewModeRepository
    public var retention: any RetentionRepository

    public init(
        onboarding: any OnboardingRepository,
        protocols: any ProtocolRepository,
        timeline: any TimelineRepository,
        today: any TodayRepository,
        coreLoop: any CoreLoopRepository,
        settings: any SettingsRepository,
        trustVault: any TrustVaultRepository,
        reminders: any ReminderRepository,
        inventory: any InventoryRepository,
        calculator: any CalculatorRepository,
        metrics: any MetricsRepository,
        changeStudio: any ProtocolChangeStudioRepository,
        reviewMode: any ReviewModeRepository,
        retention: any RetentionRepository
    ) {
        self.onboarding = onboarding
        self.protocols = protocols
        self.timeline = timeline
        self.today = today
        self.coreLoop = coreLoop
        self.settings = settings
        self.trustVault = trustVault
        self.reminders = reminders
        self.inventory = inventory
        self.calculator = calculator
        self.metrics = metrics
        self.changeStudio = changeStudio
        self.reviewMode = reviewMode
        self.retention = retention
    }
}

public struct AtlasPersistenceController: Sendable {
    public var container: AtlasPersistenceContainer
    public var importExportBridge: any ImportExportBridging
    public var sharedProjectionWriter: any SharedProjectionWriting
    public var reminderCoordinator: any ReminderCoordinating
    public var locations: AtlasDatabaseLocations?

    public init(
        container: AtlasPersistenceContainer,
        importExportBridge: any ImportExportBridging,
        sharedProjectionWriter: any SharedProjectionWriting,
        reminderCoordinator: any ReminderCoordinating,
        locations: AtlasDatabaseLocations?
    ) {
        self.container = container
        self.importExportBridge = importExportBridge
        self.sharedProjectionWriter = sharedProjectionWriter
        self.reminderCoordinator = reminderCoordinator
        self.locations = locations
    }

    public static func live(
        appGroupIdentifier: String,
        featureFlags: AtlasFeatureFlagState,
        privacyFormatter: AtlasPrivacyFormatter,
        notifications: any NotificationManaging = AtlasNotificationManager()
    ) throws -> AtlasPersistenceController {
        let locations = try AtlasDatabaseLocations.live(appGroupIdentifier: appGroupIdentifier)
        let stack = try AtlasDatabaseStack(locations: locations)
        let healthKit = AtlasHealthKitManager()
        let writer = GRDBSharedProjectionWriter(
            stack: stack,
            featureFlags: featureFlags,
            privacyFormatter: privacyFormatter
        )
        let reminderRepository = GRDBReminderRepository(stack: stack)
        let inventoryRepository = GRDBInventoryRepository(stack: stack)
        let calculatorRepository = GRDBCalculatorRepository(stack: stack)
        let metricsRepository = GRDBMetricsRepository(
            stack: stack,
            featureFlags: featureFlags,
            privacyFormatter: privacyFormatter
        )
        let trustVaultRepository = GRDBTrustVaultRepository(
            stack: stack,
            privacyFormatter: privacyFormatter
        )
        let changeStudioRepository = GRDBProtocolChangeStudioRepository(
            stack: stack,
            privacyFormatter: privacyFormatter
        )
        let reviewModeRepository = GRDBReviewModeRepository(
            stack: stack,
            featureFlags: featureFlags,
            privacyFormatter: privacyFormatter
        )
        let retentionRepository = GRDBRetentionRepository(
            stack: stack,
            featureFlags: featureFlags
        )
        let container = AtlasPersistenceContainer(
            onboarding: GRDBOnboardingRepository(
                stack: stack,
                healthKit: healthKit
            ),
            protocols: GRDBProtocolRepository(stack: stack),
            timeline: GRDBTimelineRepository(stack: stack, privacyFormatter: privacyFormatter),
            today: GRDBTodayRepository(stack: stack),
            coreLoop: GRDBCoreLoopRepository(stack: stack),
            settings: GRDBSettingsRepository(
                stack: stack,
                healthKit: healthKit,
                featureFlags: featureFlags
            ),
            trustVault: trustVaultRepository,
            reminders: reminderRepository,
            inventory: inventoryRepository,
            calculator: calculatorRepository,
            metrics: metricsRepository,
            changeStudio: changeStudioRepository,
            reviewMode: reviewModeRepository,
            retention: retentionRepository
        )
        let bridge = GRDBImportExportBridge(
            stack: stack,
            projectionWriter: writer,
            featureFlags: featureFlags,
            privacyFormatter: privacyFormatter
        )
        let reminderCoordinator = GRDBReminderCoordinator(
            stack: stack,
            notifications: notifications,
            privacyFormatter: privacyFormatter
        )

        return AtlasPersistenceController(
            container: container,
            importExportBridge: bridge,
            sharedProjectionWriter: writer,
            reminderCoordinator: reminderCoordinator,
            locations: locations
        )
    }

    public static func inMemory(
        featureFlags: AtlasFeatureFlagState,
        privacyFormatter: AtlasPrivacyFormatter,
        notifications: any NotificationManaging = AtlasNotificationManager()
    ) throws -> AtlasPersistenceController {
        let stack = try AtlasDatabaseStack.inMemory()
        let healthKit = AtlasHealthKitManager()
        let writer = GRDBSharedProjectionWriter(
            stack: stack,
            featureFlags: featureFlags,
            privacyFormatter: privacyFormatter
        )
        let reminderRepository = GRDBReminderRepository(stack: stack)
        let inventoryRepository = GRDBInventoryRepository(stack: stack)
        let calculatorRepository = GRDBCalculatorRepository(stack: stack)
        let metricsRepository = GRDBMetricsRepository(
            stack: stack,
            featureFlags: featureFlags,
            privacyFormatter: privacyFormatter
        )
        let trustVaultRepository = GRDBTrustVaultRepository(
            stack: stack,
            privacyFormatter: privacyFormatter
        )
        let changeStudioRepository = GRDBProtocolChangeStudioRepository(
            stack: stack,
            privacyFormatter: privacyFormatter
        )
        let reviewModeRepository = GRDBReviewModeRepository(
            stack: stack,
            featureFlags: featureFlags,
            privacyFormatter: privacyFormatter
        )
        let retentionRepository = GRDBRetentionRepository(
            stack: stack,
            featureFlags: featureFlags
        )
        let container = AtlasPersistenceContainer(
            onboarding: GRDBOnboardingRepository(
                stack: stack,
                healthKit: healthKit
            ),
            protocols: GRDBProtocolRepository(stack: stack),
            timeline: GRDBTimelineRepository(stack: stack, privacyFormatter: privacyFormatter),
            today: GRDBTodayRepository(stack: stack),
            coreLoop: GRDBCoreLoopRepository(stack: stack),
            settings: GRDBSettingsRepository(
                stack: stack,
                healthKit: healthKit,
                featureFlags: featureFlags
            ),
            trustVault: trustVaultRepository,
            reminders: reminderRepository,
            inventory: inventoryRepository,
            calculator: calculatorRepository,
            metrics: metricsRepository,
            changeStudio: changeStudioRepository,
            reviewMode: reviewModeRepository,
            retention: retentionRepository
        )
        let bridge = GRDBImportExportBridge(
            stack: stack,
            projectionWriter: writer,
            featureFlags: featureFlags,
            privacyFormatter: privacyFormatter
        )
        let reminderCoordinator = GRDBReminderCoordinator(
            stack: stack,
            notifications: notifications,
            privacyFormatter: privacyFormatter
        )

        return AtlasPersistenceController(
            container: container,
            importExportBridge: bridge,
            sharedProjectionWriter: writer,
            reminderCoordinator: reminderCoordinator,
            locations: nil
        )
    }

    public static func temporary(
        baseURL: URL,
        featureFlags: AtlasFeatureFlagState,
        privacyFormatter: AtlasPrivacyFormatter,
        notifications: any NotificationManaging = AtlasNotificationManager()
    ) throws -> AtlasPersistenceController {
        let locations = AtlasDatabaseLocations.temporary(baseURL: baseURL)
        try FileManager.default.createDirectory(
            at: locations.backupDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        let stack = try AtlasDatabaseStack(locations: locations)
        let healthKit = AtlasHealthKitManager()
        let writer = GRDBSharedProjectionWriter(
            stack: stack,
            featureFlags: featureFlags,
            privacyFormatter: privacyFormatter
        )
        let reminderRepository = GRDBReminderRepository(stack: stack)
        let inventoryRepository = GRDBInventoryRepository(stack: stack)
        let calculatorRepository = GRDBCalculatorRepository(stack: stack)
        let metricsRepository = GRDBMetricsRepository(
            stack: stack,
            featureFlags: featureFlags,
            privacyFormatter: privacyFormatter
        )
        let trustVaultRepository = GRDBTrustVaultRepository(
            stack: stack,
            privacyFormatter: privacyFormatter
        )
        let changeStudioRepository = GRDBProtocolChangeStudioRepository(
            stack: stack,
            privacyFormatter: privacyFormatter
        )
        let reviewModeRepository = GRDBReviewModeRepository(
            stack: stack,
            featureFlags: featureFlags,
            privacyFormatter: privacyFormatter
        )
        let retentionRepository = GRDBRetentionRepository(
            stack: stack,
            featureFlags: featureFlags
        )
        let container = AtlasPersistenceContainer(
            onboarding: GRDBOnboardingRepository(
                stack: stack,
                healthKit: healthKit
            ),
            protocols: GRDBProtocolRepository(stack: stack),
            timeline: GRDBTimelineRepository(stack: stack, privacyFormatter: privacyFormatter),
            today: GRDBTodayRepository(stack: stack),
            coreLoop: GRDBCoreLoopRepository(stack: stack),
            settings: GRDBSettingsRepository(
                stack: stack,
                healthKit: healthKit,
                featureFlags: featureFlags
            ),
            trustVault: trustVaultRepository,
            reminders: reminderRepository,
            inventory: inventoryRepository,
            calculator: calculatorRepository,
            metrics: metricsRepository,
            changeStudio: changeStudioRepository,
            reviewMode: reviewModeRepository,
            retention: retentionRepository
        )
        let bridge = GRDBImportExportBridge(
            stack: stack,
            projectionWriter: writer,
            featureFlags: featureFlags,
            privacyFormatter: privacyFormatter
        )
        let reminderCoordinator = GRDBReminderCoordinator(
            stack: stack,
            notifications: notifications,
            privacyFormatter: privacyFormatter
        )

        return AtlasPersistenceController(
            container: container,
            importExportBridge: bridge,
            sharedProjectionWriter: writer,
            reminderCoordinator: reminderCoordinator,
            locations: locations
        )
    }
}
