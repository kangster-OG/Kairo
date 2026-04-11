import AtlasDesignSystem
import AtlasDomain
import AtlasPersistence
import AtlasPrivacy
import AtlasSystem
import Observation
import SwiftUI

private enum AtlasPendingExtensionActionStore {
    static let appGroupIdentifier = "group.com.dkang2000.Atlas.shared"
    static let fileName = "atlas-pending-extension-action.json"

    struct Payload: Codable {
        var urlString: String
        var createdAt: String
    }

    static func consumeURL() -> URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            return nil
        }

        let sharedURL = containerURL.appendingPathComponent("AtlasShared", isDirectory: true)
        let fileURL = sharedURL.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        try? FileManager.default.removeItem(at: fileURL)

        guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            return nil
        }
        return URL(string: payload.urlString)
    }
}

public struct AtlasAppDependencies: Sendable {
    public var featureFlags: any AtlasFeatureFlagProviding
    public var notifications: any NotificationManaging
    public var biometrics: any BiometricGating
    public var healthKit: any HealthKitManaging
    public var cloudSync: any CloudSyncManaging
    public var diagnostics: any DiagnosticsReporting
    public var importExport: any ImportExportBridging
    public var sharedProjectionWriter: any SharedProjectionWriting
    public var persistence: AtlasPersistenceContainer
    public var reminders: any ReminderCoordinating
    public var privacyFormatter: AtlasPrivacyFormatter
    public var dateProvider: @Sendable () -> Date

    public init(
        featureFlags: any AtlasFeatureFlagProviding,
        notifications: any NotificationManaging,
        biometrics: any BiometricGating,
        healthKit: any HealthKitManaging,
        cloudSync: any CloudSyncManaging,
        diagnostics: any DiagnosticsReporting,
        importExport: any ImportExportBridging,
        sharedProjectionWriter: any SharedProjectionWriting,
        persistence: AtlasPersistenceContainer,
        reminders: any ReminderCoordinating,
        privacyFormatter: AtlasPrivacyFormatter,
        dateProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        self.featureFlags = featureFlags
        self.notifications = notifications
        self.biometrics = biometrics
        self.healthKit = healthKit
        self.cloudSync = cloudSync
        self.diagnostics = diagnostics
        self.importExport = importExport
        self.sharedProjectionWriter = sharedProjectionWriter
        self.persistence = persistence
        self.reminders = reminders
        self.privacyFormatter = privacyFormatter
        self.dateProvider = dateProvider
    }
}

@MainActor
@Observable
public final class AtlasTodayViewState {
    public var loadErrorMessage: String?
    public var todaySnapshot: AtlasTodaySnapshot
    public var retentionSnapshot: AtlasRetentionSnapshot
    public var rewardsSnapshot: AtlasRewardsSnapshot
    public var renderMode: AtlasPrivacyRenderMode

    public init(
        loadErrorMessage: String? = nil,
        todaySnapshot: AtlasTodaySnapshot,
        retentionSnapshot: AtlasRetentionSnapshot,
        rewardsSnapshot: AtlasRewardsSnapshot,
        renderMode: AtlasPrivacyRenderMode
    ) {
        self.loadErrorMessage = loadErrorMessage
        self.todaySnapshot = todaySnapshot
        self.retentionSnapshot = retentionSnapshot
        self.rewardsSnapshot = rewardsSnapshot
        self.renderMode = renderMode
    }
}

@MainActor
@Observable
public final class AtlasTimelineViewState {
    public var loadErrorMessage: String?
    public var entries: [AtlasTimelineEntry]
    public var filter: AtlasTimelineFilter
    public var renderMode: AtlasPrivacyRenderMode

    public init(
        loadErrorMessage: String? = nil,
        entries: [AtlasTimelineEntry],
        filter: AtlasTimelineFilter,
        renderMode: AtlasPrivacyRenderMode
    ) {
        self.loadErrorMessage = loadErrorMessage
        self.entries = entries
        self.filter = filter
        self.renderMode = renderMode
    }
}

@MainActor
@Observable
public final class AtlasLibraryViewState {
    public var protocols: [ProtocolSummary]
    public var renderMode: AtlasPrivacyRenderMode

    public init(
        protocols: [ProtocolSummary],
        renderMode: AtlasPrivacyRenderMode
    ) {
        self.protocols = protocols
        self.renderMode = renderMode
    }
}

@MainActor
@Observable
public final class AtlasInsightsViewState {
    public var loadErrorMessage: String?
    public var insightsSnapshot: AtlasInsightsSnapshot
    public var retentionSnapshot: AtlasRetentionSnapshot
    public var rewardsSnapshot: AtlasRewardsSnapshot
    public var summarySettings: AtlasSummarySettingsSnapshot
    public var libraryProtocols: [ProtocolSummary]
    public var renderMode: AtlasPrivacyRenderMode

    public init(
        loadErrorMessage: String? = nil,
        insightsSnapshot: AtlasInsightsSnapshot,
        retentionSnapshot: AtlasRetentionSnapshot,
        rewardsSnapshot: AtlasRewardsSnapshot,
        summarySettings: AtlasSummarySettingsSnapshot,
        libraryProtocols: [ProtocolSummary],
        renderMode: AtlasPrivacyRenderMode
    ) {
        self.loadErrorMessage = loadErrorMessage
        self.insightsSnapshot = insightsSnapshot
        self.retentionSnapshot = retentionSnapshot
        self.rewardsSnapshot = rewardsSnapshot
        self.summarySettings = summarySettings
        self.libraryProtocols = libraryProtocols
        self.renderMode = renderMode
    }
}

@MainActor
@Observable
public final class AtlasSettingsViewState {
    public var settingsSnapshot: AtlasSettingsSnapshot
    public var todaySnapshot: AtlasTodaySnapshot
    public var reminderSettings: AtlasReminderSettingsSnapshot
    public var notificationPermissionStatus: AtlasNotificationAuthorizationStatus
    public var retentionSnapshot: AtlasRetentionSnapshot
    public var rewardsSnapshot: AtlasRewardsSnapshot

    public init(
        settingsSnapshot: AtlasSettingsSnapshot,
        todaySnapshot: AtlasTodaySnapshot,
        reminderSettings: AtlasReminderSettingsSnapshot,
        notificationPermissionStatus: AtlasNotificationAuthorizationStatus,
        retentionSnapshot: AtlasRetentionSnapshot,
        rewardsSnapshot: AtlasRewardsSnapshot
    ) {
        self.settingsSnapshot = settingsSnapshot
        self.todaySnapshot = todaySnapshot
        self.reminderSettings = reminderSettings
        self.notificationPermissionStatus = notificationPermissionStatus
        self.retentionSnapshot = retentionSnapshot
        self.rewardsSnapshot = rewardsSnapshot
    }
}

@MainActor
@Observable
public final class AtlasAppModel {
    public var activeTab: AtlasTab
    public var routePath: [AtlasRoute]
    public let dependencies: AtlasAppDependencies
    public let todayViewState: AtlasTodayViewState
    public let timelineViewState: AtlasTimelineViewState
    public let libraryViewState: AtlasLibraryViewState
    public let insightsViewState: AtlasInsightsViewState
    public let settingsViewState: AtlasSettingsViewState
    public var bootstrapSnapshot: AtlasBootstrapSnapshot
    public var settingsSnapshot: AtlasSettingsSnapshot
    public var todaySnapshot: AtlasTodaySnapshot
    public var libraryProtocols: [ProtocolSummary]
    public var timelineEntries: [AtlasTimelineEntry]
    public var timelineFilter: AtlasTimelineFilter
    public var reminderSettings: AtlasReminderSettingsSnapshot
    public var notificationPermissionStatus: AtlasNotificationAuthorizationStatus
    public var inventorySnapshot: AtlasInventorySnapshot
    public var calculatorProfiles: [AtlasCalculatorProfileRecord]
    public var insightsSnapshot: AtlasInsightsSnapshot
    public var retentionSnapshot: AtlasRetentionSnapshot
    public var rewardsSnapshot: AtlasRewardsSnapshot
    public var trustVaultSnapshot: AtlasTrustVaultSnapshot
    public var reviewOwnerSnapshot: AtlasReviewOwnerSnapshot
    public var reviewWorkspace: AtlasReviewWorkspace?
    public var cloudSession: AtlasCloudSessionSnapshot?
    public var cloudStatusDescription: String
    public var isPerformingCloudAction: Bool
    public var isLoading: Bool
    public var loadErrorMessage: String?
    public private(set) var widgetProjectionVersion: Int
    public var activeOnboardingStep: AtlasOnboardingStep
    private var hasLoadedBootstrap: Bool
    private var hasLoadedShellData: Bool
    private var hasConfiguredReminderHandling: Bool
    var protocolDetails: [String: AtlasProtocolDetailSnapshot]
    var vialDetails: [String: AtlasVialDetailSnapshot]
    var consumableDetails: [String: AtlasConsumableDetailSnapshot]
    var protocolSiteOptions: [String: AtlasProtocolSiteOptions]

    public init(
        activeTab: AtlasTab = .today,
        routePath: [AtlasRoute] = [],
        dependencies: AtlasAppDependencies
    ) {
        let bootstrapSnapshot = AtlasBootstrapSnapshot(
            destination: .onboarding,
            reason: .firstRun,
            onboardingDraft: .empty(),
            onboardingCompleted: false,
            hasLocalData: false,
            isImportedLocalUser: false
        )
        let settingsSnapshot = AtlasSettingsSnapshot()
        let todaySnapshot = AtlasTodaySnapshot(hasProtocols: false, nextDue: nil, overdue: [], upcoming: [])
        let libraryProtocols: [ProtocolSummary] = []
        let timelineEntries: [AtlasTimelineEntry] = []
        let timelineFilter = AtlasTimelineFilter.all
        let reminderSettings = AtlasReminderSettingsSnapshot()
        let notificationPermissionStatus = AtlasNotificationAuthorizationStatus.notDetermined
        let inventorySnapshot = AtlasInventorySnapshot()
        let calculatorProfiles: [AtlasCalculatorProfileRecord] = []
        let insightsSnapshot = AtlasInsightsSnapshot()
        let retentionSnapshot = AtlasRetentionSnapshot()
        let rewardsSnapshot = AtlasRewardsSnapshot()
        let trustVaultSnapshot = AtlasTrustVaultSnapshot(
            privacyProfile: .default(),
            aliases: [],
            audits: []
        )
        let reviewOwnerSnapshot = AtlasReviewOwnerSnapshot(
            sessions: [],
            liveReviewEnabled: dependencies.featureFlags.flags.liveReviewSessions
        )
        let renderMode = settingsSnapshot.trustVaultStatus.renderMode

        self.activeTab = activeTab
        self.routePath = routePath
        self.dependencies = dependencies
        self.todayViewState = AtlasTodayViewState(
            todaySnapshot: todaySnapshot,
            retentionSnapshot: retentionSnapshot,
            rewardsSnapshot: rewardsSnapshot,
            renderMode: renderMode
        )
        self.timelineViewState = AtlasTimelineViewState(
            entries: timelineEntries,
            filter: timelineFilter,
            renderMode: renderMode
        )
        self.libraryViewState = AtlasLibraryViewState(
            protocols: libraryProtocols,
            renderMode: renderMode
        )
        self.insightsViewState = AtlasInsightsViewState(
            insightsSnapshot: insightsSnapshot,
            retentionSnapshot: retentionSnapshot,
            rewardsSnapshot: rewardsSnapshot,
            summarySettings: settingsSnapshot.summarySettings,
            libraryProtocols: libraryProtocols,
            renderMode: renderMode
        )
        self.settingsViewState = AtlasSettingsViewState(
            settingsSnapshot: settingsSnapshot,
            todaySnapshot: todaySnapshot,
            reminderSettings: reminderSettings,
            notificationPermissionStatus: notificationPermissionStatus,
            retentionSnapshot: retentionSnapshot,
            rewardsSnapshot: rewardsSnapshot
        )
        self.bootstrapSnapshot = bootstrapSnapshot
        self.settingsSnapshot = settingsSnapshot
        self.todaySnapshot = todaySnapshot
        self.libraryProtocols = libraryProtocols
        self.timelineEntries = timelineEntries
        self.timelineFilter = timelineFilter
        self.reminderSettings = reminderSettings
        self.notificationPermissionStatus = notificationPermissionStatus
        self.inventorySnapshot = inventorySnapshot
        self.calculatorProfiles = calculatorProfiles
        self.insightsSnapshot = insightsSnapshot
        self.retentionSnapshot = retentionSnapshot
        self.rewardsSnapshot = rewardsSnapshot
        self.trustVaultSnapshot = trustVaultSnapshot
        self.reviewOwnerSnapshot = reviewOwnerSnapshot
        self.reviewWorkspace = nil
        self.cloudSession = nil
        self.cloudStatusDescription = dependencies.cloudSync.isConfigured()
            ? "Cloud sync is ready for sign-in."
            : "Cloud sync is not configured yet. Atlas continues to work locally."
        self.isPerformingCloudAction = false
        self.isLoading = false
        self.loadErrorMessage = nil
        self.widgetProjectionVersion = 0
        self.activeOnboardingStep = .splash
        self.hasLoadedBootstrap = false
        self.hasLoadedShellData = false
        self.hasConfiguredReminderHandling = false
        self.protocolDetails = [:]
        self.vialDetails = [:]
        self.consumableDetails = [:]
        self.protocolSiteOptions = [:]
        syncShellViewStates()
    }

    public func open(_ route: AtlasRoute) {
        routePath.append(route)
    }

    public func loadBootstrapIfNeeded() async {
        guard hasLoadedBootstrap == false else {
            return
        }
        await refreshBootstrap()
        await refreshCloudStatus()
        hasLoadedBootstrap = true
        if bootstrapSnapshot.destination == .app {
            await loadShellDataIfNeeded()
        }
    }

    public func refreshBootstrap() async {
        do {
            bootstrapSnapshot = try await dependencies.persistence.onboarding.loadBootstrapSnapshot()
            let sequence = bootstrapSnapshot.onboardingDraft.sequence()
            activeOnboardingStep = sequence.contains(activeOnboardingStep) ? activeOnboardingStep : sequence.first ?? .splash
            settingsSnapshot = try await dependencies.persistence.settings.currentSettingsSnapshot()
            syncShellViewStates()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func loadShellDataIfNeeded() async {
        guard hasLoadedShellData == false else {
            return
        }

        if hasConfiguredReminderHandling == false {
            do {
                try await dependencies.reminders.configureReminderHandling { [weak self] in
                    guard let self else {
                        return
                    }
                    await self.refreshShellData()
                }
                hasConfiguredReminderHandling = true
            } catch {
                setLoadErrorMessage(error.localizedDescription)
            }
        }

        await refreshShellData()
    }

    public func refreshShellData() async {
        guard isLoading == false else {
            return
        }

        isLoading = true
        setLoadErrorMessage(nil)
        defer { isLoading = false }

        do {
            let now = dependencies.dateProvider()
            await syncRemindersIfPossible(referenceDate: now)
            do {
                try await dependencies.sharedProjectionWriter.refreshProjection(referenceDate: now)
                widgetProjectionVersion &+= 1
            } catch {
                // Keep the main app usable even if extension-safe projections fail to refresh.
            }

            async let settings = dependencies.persistence.settings.currentSettingsSnapshot()
            async let today = dependencies.persistence.today.fetchTodaySnapshot(referenceDate: now)
            async let protocols = dependencies.persistence.protocols.listProtocolSummaries()
            async let timeline = dependencies.persistence.timeline.fetchTimeline(
                AtlasTimelineQuery(filter: timelineFilter, limit: 80)
            )
            async let reminders = dependencies.reminders.fetchReminderSettings()
            async let permission = dependencies.reminders.authorizationStatus()
            async let inventory = dependencies.persistence.inventory.fetchInventorySnapshot(referenceDate: now)
            async let calculatorProfiles = dependencies.persistence.calculator.listProfiles()
            async let insights = dependencies.persistence.metrics.fetchInsightsSnapshot(referenceDate: now)
            async let retention = dependencies.persistence.retention.fetchRetentionSnapshot(referenceDate: now)
            async let rewards = dependencies.persistence.rewards.fetchRewardsSnapshot(referenceDate: now)
            async let trustVault = dependencies.persistence.trustVault.fetchTrustVaultSnapshot()
            async let reviewOwner = dependencies.persistence.reviewMode.fetchOwnerSnapshot(now: now)

            settingsSnapshot = try await settings
            todaySnapshot = try await today
            libraryProtocols = try await protocols
            timelineEntries = try await timeline
            reminderSettings = try await reminders
            notificationPermissionStatus = await permission
            inventorySnapshot = try await inventory
            self.calculatorProfiles = try await calculatorProfiles
            insightsSnapshot = try await insights
            retentionSnapshot = try await retention
            rewardsSnapshot = try await rewards
            trustVaultSnapshot = try await trustVault
            reviewOwnerSnapshot = decorateReviewOwnerSnapshot(try await reviewOwner)
            hasLoadedShellData = true
            await refreshCloudStatus()
            syncShellViewStates()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func saveOnboardingDraft(_ draft: AtlasOnboardingDraft) async {
        do {
            bootstrapSnapshot = try await dependencies.persistence.onboarding.saveDraft(draft, now: currentDate())
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateOnboardingDraft(_ update: (inout AtlasOnboardingDraft) -> Void) async {
        var draft = bootstrapSnapshot.onboardingDraft
        update(&draft)
        await saveOnboardingDraft(draft)
    }

    public func advanceOnboarding() {
        let sequence = bootstrapSnapshot.onboardingDraft.sequence()
        guard let index = sequence.firstIndex(of: activeOnboardingStep), index < sequence.endIndex - 1 else {
            return
        }
        activeOnboardingStep = sequence[index + 1]
    }

    public func retreatOnboarding() {
        let sequence = bootstrapSnapshot.onboardingDraft.sequence()
        guard let index = sequence.firstIndex(of: activeOnboardingStep), index > sequence.startIndex else {
            return
        }
        activeOnboardingStep = sequence[index - 1]
    }

    public func completeOnboarding() async {
        do {
            bootstrapSnapshot = try await dependencies.persistence.onboarding.completeOnboarding(
                bootstrapSnapshot.onboardingDraft,
                now: currentDate()
            )
            settingsSnapshot = try await dependencies.persistence.settings.currentSettingsSnapshot()
            activeOnboardingStep = .planReady
            hasLoadedShellData = false
            syncShellViewStates()
            if bootstrapSnapshot.destination == .app {
                await loadShellDataIfNeeded()
            }
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func resetOnboarding() async {
        do {
            bootstrapSnapshot = try await dependencies.persistence.onboarding.resetOnboarding(now: currentDate())
            settingsSnapshot = try await dependencies.persistence.settings.currentSettingsSnapshot()
            activeOnboardingStep = .splash
            hasLoadedShellData = false
            syncShellViewStates()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func refreshTimeline() async {
        do {
            timelineEntries = try await dependencies.persistence.timeline.fetchTimeline(
                AtlasTimelineQuery(filter: timelineFilter, limit: 80)
            )
            syncTimelineViewState()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func protocolDetail(id: String) async -> AtlasProtocolDetailSnapshot? {
        if let existing = protocolDetails[id] {
            return existing
        }

        do {
            try await dependencies.persistence.coreLoop.ensureProjectedOccurrences(referenceDate: currentDate())
            let detail = try await dependencies.persistence.protocols.fetchProtocolDetail(id: id)
            if let detail {
                protocolDetails[id] = detail
            }
            return detail
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    public func createProtocol(_ draft: AtlasProtocolDraft) async -> AtlasProtocolDetailSnapshot? {
        do {
            let now = currentDate()
            let detail = try await dependencies.persistence.protocols.createProtocol(draft, now: now)
            await syncRemindersIfPossible(referenceDate: now)
            protocolDetails[detail.id] = detail
            await refreshShellData()
            return detail
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    public func updateProtocol(id: String, draft: AtlasProtocolDraft) async -> AtlasProtocolDetailSnapshot? {
        do {
            let now = currentDate()
            let detail = try await dependencies.persistence.protocols.updateProtocol(id: id, draft: draft, now: now)
            await syncRemindersIfPossible(referenceDate: now)
            protocolDetails[id] = detail
            await refreshShellData()
            return detail
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    public func logOccurrence(_ request: AtlasOccurrenceLogRequest) async {
        do {
            let now = currentDate()
            try await dependencies.persistence.coreLoop.logOccurrence(request, now: now)
            await syncRemindersIfPossible(referenceDate: now)
            await refreshShellData()
            if let detail = try await dependencies.persistence.protocols.fetchProtocolDetail(id: request.protocolID) {
                protocolDetails[request.protocolID] = detail
            }
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func requestReminderPermission() async {
        do {
            notificationPermissionStatus = try await dependencies.reminders.requestAuthorization()
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateReminderSettings(_ update: AtlasReminderPreferenceUpdate) async {
        do {
            reminderSettings = try await dependencies.reminders.updateReminderSettings(update, referenceDate: currentDate())
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updatePrivacyRenderMode(_ renderMode: AtlasPrivacyRenderMode) async {
        do {
            settingsSnapshot = try await dependencies.persistence.settings.updateTrustVaultRenderMode(renderMode, now: currentDate())
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateSummarySettings(_ update: AtlasSummarySettingsUpdate) async {
        do {
            settingsSnapshot = try await dependencies.persistence.settings.updateSummarySettings(update, now: currentDate())
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateRetentionSettings(_ update: AtlasRetentionSettingsUpdate) async {
        do {
            settingsSnapshot = try await dependencies.persistence.settings.updateRetentionSettings(update, now: currentDate())
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateRewardsSettings(_ update: AtlasRewardsSettingsUpdate) async {
        do {
            settingsSnapshot = try await dependencies.persistence.settings.updateRewardsSettings(update, now: currentDate())
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func connectHealthKit() async {
        do {
            let previousSyncDate = settingsSnapshot.healthScaffold.connections
                .first { $0.providerKey == .appleHealth }?
                .lastSyncAt
                .flatMap { ISO8601DateFormatter.atlas.date(from: $0) }
            let connected = try await dependencies.healthKit.requestAuthorization()
            settingsSnapshot = try await dependencies.persistence.settings.updateHealthConnection(
                provider: .appleHealth,
                enabled: connected,
                connected: connected,
                lastSyncAt: connected ? currentDate() : nil,
                lastError: nil,
                now: currentDate()
            )
            if connected {
                try await syncHealthKitWorkouts(since: previousSyncDate)
            }
            syncShellViewStates()
        } catch {
            do {
                settingsSnapshot = try await dependencies.persistence.settings.updateHealthConnection(
                    provider: .appleHealth,
                    enabled: false,
                    connected: false,
                    lastSyncAt: nil,
                    lastError: error.localizedDescription,
                    now: currentDate()
                )
                syncShellViewStates()
            } catch {}
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func disconnectHealthKit() async {
        await dependencies.healthKit.disconnect()
        do {
            settingsSnapshot = try await dependencies.persistence.settings.updateHealthConnection(
                provider: .appleHealth,
                enabled: false,
                connected: false,
                lastSyncAt: nil,
                lastError: nil,
                now: currentDate()
            )
            syncShellViewStates()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    private func syncHealthKitWorkouts(since: Date?) async throws {
        let syncDate = currentDate()
        let workouts = try await dependencies.healthKit.fetchWorkouts(since: since)
        _ = try await dependencies.persistence.metrics.importWorkoutSamples(workouts, now: syncDate)
        settingsSnapshot = try await dependencies.persistence.settings.updateHealthConnection(
            provider: .appleHealth,
            enabled: true,
            connected: true,
            lastSyncAt: syncDate,
            lastError: nil,
            now: syncDate
        )
        await refreshShellData()
    }

    public func refreshCloudStatus() async {
        cloudSession = await dependencies.cloudSync.currentSession()
        cloudStatusDescription = await dependencies.cloudSync.statusDescription()
        syncShellViewStates()
    }

    public func signUpToCloud(email: String, password: String) async {
        await performCloudAction { [self] in
            _ = try await self.dependencies.cloudSync.signUp(email: email, password: password)
            self.settingsSnapshot = try await self.dependencies.persistence.settings.updateAccountMode(.account, now: self.currentDate())
            await self.refreshCloudStatus()
        }
    }

    public func signInToCloud(email: String, password: String) async {
        await performCloudAction { [self] in
            _ = try await self.dependencies.cloudSync.signIn(email: email, password: password)
            self.settingsSnapshot = try await self.dependencies.persistence.settings.updateAccountMode(.account, now: self.currentDate())
            await self.refreshCloudStatus()
        }
    }

    public func signInToCloud(with provider: AtlasCloudIdentityProvider) async {
        await performCloudAction { [self] in
            _ = try await self.dependencies.cloudSync.signIn(with: provider)
            self.settingsSnapshot = try await self.dependencies.persistence.settings.updateAccountMode(.account, now: self.currentDate())
            await self.refreshCloudStatus()
        }
    }

    public func signOutOfCloud() async {
        await performCloudAction { [self] in
            try await self.dependencies.cloudSync.signOut()
            self.settingsSnapshot = try await self.dependencies.persistence.settings.updateAccountMode(.guest, now: self.currentDate())
            await self.refreshCloudStatus()
        }
    }

    public func syncToCloud() async {
        await performCloudAction { [self] in
            let now = self.currentDate()
            let deviceID: String? = nil
            let export = try await self.dependencies.importExport.createRawExport(
                AtlasRawExportRequest(format: .json, renderMode: .full),
                now: now
            )
            let data = try Data(contentsOf: export.fileURL)
            _ = try await self.dependencies.cloudSync.uploadExportBundle(
                data,
                generatedAt: now,
                deviceID: deviceID
            )
            self.settingsSnapshot = try await self.dependencies.persistence.settings.updateAccountMode(.account, now: now)
            await self.refreshCloudStatus()
        }
    }

    public func restoreLatestCloudBackup() async {
        await performCloudAction { [self] in
            guard let data = try await self.dependencies.cloudSync.downloadLatestExportBundle() else {
                throw AtlasCloudRestoreError.noBackup
            }

            let restoreDirectory = FileManager.default.temporaryDirectory
                .appendingPathComponent("atlas-cloud-restore-\(UUID().uuidString.lowercased())", isDirectory: true)
            try FileManager.default.createDirectory(at: restoreDirectory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: restoreDirectory) }

            let fileURL = restoreDirectory.appendingPathComponent("atlas-cloud-restore.json")
            try data.write(to: fileURL, options: [.atomic])
            let prepared = try await self.dependencies.importExport.prepareImport(at: fileURL)
            _ = try await self.dependencies.importExport.commitPreparedImport(prepared, mode: .replaceExisting)
            self.settingsSnapshot = try await self.dependencies.persistence.settings.updateAccountMode(.account, now: self.currentDate())
            self.hasLoadedBootstrap = false
            self.hasLoadedShellData = false
            await self.refreshBootstrap()
            await self.loadBootstrapIfNeeded()
            await self.refreshCloudStatus()
        }
    }

    public func markWeeklyReviewComplete() async {
        do {
            retentionSnapshot = try await dependencies.persistence.retention.markWeeklyReviewComplete(now: currentDate())
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func vialDetail(id: String) async -> AtlasVialDetailSnapshot? {
        if let cached = vialDetails[id] {
            return cached
        }

        do {
            let detail = try await dependencies.persistence.inventory.fetchVialDetail(id: id, referenceDate: currentDate())
            if let detail {
                vialDetails[id] = detail
            }
            return detail
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    public func consumableDetail(id: String) async -> AtlasConsumableDetailSnapshot? {
        if let cached = consumableDetails[id] {
            return cached
        }

        do {
            let detail = try await dependencies.persistence.inventory.fetchConsumableDetail(id: id, referenceDate: currentDate())
            if let detail {
                consumableDetails[id] = detail
            }
            return detail
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    public func saveVial(_ draft: AtlasVialDraft) async -> AtlasVialDetailSnapshot? {
        do {
            let detail = try await dependencies.persistence.inventory.saveVial(draft, now: currentDate())
            invalidateInventoryCaches()
            await refreshShellData()
            vialDetails[detail.summary.id] = detail
            return detail
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    public func saveConsumable(_ draft: AtlasConsumableDraft) async -> AtlasConsumableDetailSnapshot? {
        do {
            let detail = try await dependencies.persistence.inventory.saveConsumable(draft, now: currentDate())
            invalidateInventoryCaches()
            await refreshShellData()
            consumableDetails[detail.summary.id] = detail
            return detail
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    public func archiveVial(id: String) async {
        do {
            try await dependencies.persistence.inventory.archiveVial(id: id, now: currentDate())
            invalidateInventoryCaches()
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func setConsumableArchived(id: String, isArchived: Bool) async {
        do {
            try await dependencies.persistence.inventory.setConsumableArchived(id: id, isArchived: isArchived, now: currentDate())
            invalidateInventoryCaches()
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateProtocolInventorySettings(_ update: AtlasProtocolInventorySettingsUpdate) async {
        do {
            _ = try await dependencies.persistence.inventory.updateProtocolInventorySettings(update, now: currentDate())
            invalidateInventoryCaches()
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func applyManualCorrection(_ correction: AtlasInventoryCorrectionDraft) async -> AtlasInventoryCorrectionResult? {
        do {
            let result = try await dependencies.persistence.inventory.applyManualCorrection(correction, now: currentDate())
            invalidateInventoryCaches()
            await refreshShellData()
            vialDetails[result.vial.summary.id] = result.vial
            return result
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    public func applyConsumableAdjustment(_ adjustment: AtlasConsumableAdjustmentDraft) async -> AtlasConsumableAdjustmentResult? {
        do {
            let result = try await dependencies.persistence.inventory.applyConsumableAdjustment(adjustment, now: currentDate())
            invalidateInventoryCaches()
            await refreshShellData()
            consumableDetails[result.consumable.summary.id] = result.consumable
            return result
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    public func recordConsumableProcurement(_ procurement: AtlasConsumableProcurementDraft) async -> AtlasConsumableAdjustmentResult? {
        do {
            let result = try await dependencies.persistence.inventory.recordConsumableProcurement(procurement, now: currentDate())
            invalidateInventoryCaches()
            await refreshShellData()
            consumableDetails[result.consumable.summary.id] = result.consumable
            return result
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    public func siteOptions(for protocolID: String) async -> AtlasProtocolSiteOptions? {
        if let cached = protocolSiteOptions[protocolID] {
            return cached
        }

        do {
            let options = try await dependencies.persistence.inventory.fetchProtocolSiteOptions(protocolID: protocolID)
            protocolSiteOptions[protocolID] = options
            return options
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    public func saveSite(_ draft: AtlasSiteDraft) async {
        do {
            _ = try await dependencies.persistence.inventory.saveSite(draft, now: currentDate())
            invalidateInventoryCaches()
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func saveCalculatorProfile(_ draft: AtlasCalculatorProfileDraft) async {
        do {
            _ = try await dependencies.persistence.calculator.saveProfile(draft, now: currentDate())
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func deleteCalculatorProfile(id: String) async {
        do {
            try await dependencies.persistence.calculator.deleteProfile(id: id)
            invalidateInventoryCaches()
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func saveContextEntry(_ draft: AtlasContextEntryDraft) async {
        do {
            _ = try await dependencies.persistence.metrics.saveContextEntry(draft, now: currentDate())
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func saveContextPreset(_ draft: AtlasContextPresetDraft) async -> AtlasContextPresetRecord? {
        do {
            let preset = try await dependencies.persistence.metrics.saveContextPreset(draft, now: currentDate())
            await refreshShellData()
            return preset
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    public func deleteContextPreset(id: String) async {
        do {
            try await dependencies.persistence.metrics.deleteContextPreset(id: id)
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func saveWeightEntry(_ draft: AtlasWeightEntryDraft) async {
        do {
            _ = try await dependencies.persistence.metrics.saveWeightEntry(draft, now: currentDate())
            if settingsSnapshot.healthScaffold.connections.contains(where: { $0.providerKey == .appleHealth && $0.connected }) {
                do {
                    try await dependencies.healthKit.saveWeightSample(
                        value: draft.value,
                        unit: draft.unit,
                        recordedAt: draft.loggedAt
                    )
                    settingsSnapshot = try await dependencies.persistence.settings.updateHealthConnection(
                        provider: .appleHealth,
                        enabled: true,
                        connected: true,
                        lastSyncAt: draft.loggedAt,
                        lastError: nil,
                        now: currentDate()
                    )
                } catch {
                    settingsSnapshot = try await dependencies.persistence.settings.updateHealthConnection(
                        provider: .appleHealth,
                        enabled: true,
                        connected: false,
                        lastSyncAt: nil,
                        lastError: error.localizedDescription,
                        now: currentDate()
                    )
                }
            }
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func saveSymptomEntry(_ draft: AtlasSymptomEntryDraft) async {
        do {
            _ = try await dependencies.persistence.metrics.saveSymptomEntry(draft, now: currentDate())
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func saveMetricDefinition(_ draft: AtlasMetricDefinitionDraft) async {
        do {
            _ = try await dependencies.persistence.metrics.saveMetricDefinition(draft, now: currentDate())
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func archiveMetricDefinition(id: String) async {
        do {
            try await dependencies.persistence.metrics.archiveMetricDefinition(id: id, now: currentDate())
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func deleteMetricDefinition(id: String) async {
        do {
            try await dependencies.persistence.metrics.deleteMetricDefinition(id: id)
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func saveMetricValueEntry(_ draft: AtlasMetricValueEntryDraft) async {
        do {
            _ = try await dependencies.persistence.metrics.saveMetricValueEntry(draft, now: currentDate())
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func renderedTitle(canonical: String, alias: String?) -> String {
        renderedTitle(
            canonical: canonical,
            alias: alias,
            renderMode: settingsSnapshot.trustVaultStatus.renderMode
        )
    }

    func renderedTitle(
        canonical: String,
        alias: String?,
        renderMode: AtlasPrivacyRenderMode
    ) -> String {
        dependencies.privacyFormatter.title(
            canonical: canonical,
            alias: alias,
            mode: renderMode
        )
    }

    public func renderedConsumableTitle(canonical: String, category: String?) -> String {
        renderedConsumableTitle(
            canonical: canonical,
            category: category,
            renderMode: settingsSnapshot.trustVaultStatus.renderMode
        )
    }

    func renderedConsumableTitle(
        canonical: String,
        category: String?,
        renderMode: AtlasPrivacyRenderMode
    ) -> String {
        dependencies.privacyFormatter.consumableTitle(
            canonical: canonical,
            category: category,
            mode: renderMode
        )
    }

    public func renderedMetricLabel(canonical: String) -> String {
        renderedMetricLabel(
            canonical: canonical,
            renderMode: settingsSnapshot.trustVaultStatus.renderMode
        )
    }

    func renderedMetricLabel(
        canonical: String,
        renderMode: AtlasPrivacyRenderMode
    ) -> String {
        dependencies.privacyFormatter.metricLabel(
            canonical: canonical,
            mode: renderMode
        )
    }

    public func renderedContextTitle(_ entry: AtlasContextEntrySummary) -> String {
        renderedContextTitle(
            entry,
            renderMode: settingsSnapshot.trustVaultStatus.renderMode
        )
    }

    func renderedContextTitle(
        _ entry: AtlasContextEntrySummary,
        renderMode: AtlasPrivacyRenderMode
    ) -> String {
        dependencies.privacyFormatter.contextEntryTitle(
            mealTiming: entry.mealTiming,
            mealSize: entry.mealSize,
            mealComposition: entry.mealComposition,
            fedState: entry.fedState,
            appetite: entry.appetite,
            hydration: entry.hydration,
            giTags: entry.giTags,
            mode: renderMode
        )
    }

    public func renderedContextDetail(_ entry: AtlasContextEntrySummary) -> String? {
        renderedContextDetail(
            entry,
            renderMode: settingsSnapshot.trustVaultStatus.renderMode
        )
    }

    func renderedContextDetail(
        _ entry: AtlasContextEntrySummary,
        renderMode: AtlasPrivacyRenderMode
    ) -> String? {
        dependencies.privacyFormatter.contextEntryDetail(
            note: entry.note,
            tags: entry.tags,
            canonicalProtocol: entry.canonicalProtocolTitle,
            aliasProtocol: entry.aliasProtocolTitle,
            mode: renderMode
        )
    }

    func contextPresetTitle(for key: String?) -> String? {
        guard let key else {
            return nil
        }

        if let savedTitle = insightsSnapshot.savedContextPresets.first(where: { $0.id == key })?.title {
            return savedTitle
        }

        return AtlasContextBuiltinPreset.allCases.first(where: { $0.id == key })?.title
    }

    func contextQuickPresets(limit: Int) -> [AtlasContextQuickPreset] {
        let saved = insightsSnapshot.savedContextPresets.map { AtlasContextQuickPreset(preset: $0) }
        let builtIn = AtlasContextBuiltinPreset.allCases.map { AtlasContextQuickPreset($0) }
        return Array((saved + builtIn).prefix(limit))
    }

    func recentMealQuickItems(limit: Int) -> [AtlasRecentMealQuickItem] {
        Array(
            insightsSnapshot.recentContextEntries
                .filter { entry in
                    entry.mealTiming != nil
                        || entry.mealSize != nil
                        || entry.mealComposition != nil
                        || entry.fedState != nil
                        || entry.hydration != nil
                }
                .prefix(limit)
                .map(AtlasRecentMealQuickItem.init(entry:))
        )
    }

    func nutritionFeaturedLookupItems(limit: Int) -> [AtlasNutritionFoodLookupItem] {
        Array(atlasDefaultNutritionFoodCatalog().prefix(limit))
    }

    func nutritionLookupItems(query: String, limit: Int = 6) -> [AtlasNutritionFoodLookupItem] {
        atlasNutritionLookupItems(matching: query, limit: limit)
    }

    func nutritionQuickCaptureSuggestion(
        for text: String,
        loggedAt: Date
    ) -> AtlasNutritionQuickCaptureSuggestion? {
        atlasNutritionQuickCaptureSuggestion(for: text, loggedAt: loggedAt)
    }

    func nutritionPackageCodeSuggestion(
        for code: String,
        loggedAt: Date
    ) -> AtlasNutritionQuickCaptureSuggestion? {
        atlasNutritionPackageCodeSuggestion(for: code, loggedAt: loggedAt)
    }

    public func handleIncomingURL(_ url: URL) async {
        guard url.scheme?.lowercased() == "atlas" else {
            return
        }

        await loadBootstrapIfNeeded()
        guard bootstrapSnapshot.destination == .app else {
            return
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let route = (url.host ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))).lowercased()
        let query = Dictionary(
            uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name.lowercased(), $0.value ?? "") }
        )

        switch route {
        case "today":
            routePath.removeAll()
            activeTab = .today
        case "inventory", "supplies":
            routePath.removeAll()
            activeTab = .library
            open(.inventory)
        case "trust-vault", "trustvault":
            routePath.removeAll()
            activeTab = .settings
            open(.trustVault)
        case "quick-log":
            routePath.removeAll()
            activeTab = .today
            await refreshShellData()
            guard let protocolID = atlasURLValue("protocolid", in: query),
                  let occurrenceID = atlasURLValue("occurrenceid", in: query),
                  let occurrence = atlasScheduledOccurrence(
                    protocolID: protocolID,
                    occurrenceID: occurrenceID
                  ) else {
                return
            }

            let action = atlasURLValue("action", in: query)?.lowercased()
            let requestAction: AtlasOccurrenceLogAction
            switch action {
            case "taken":
                requestAction = .taken
            case "skip", "skipped":
                requestAction = .skipped
            default:
                return
            }

            await logOccurrence(
                AtlasOccurrenceLogRequest(
                    occurrenceID: occurrence.id,
                    protocolID: occurrence.protocolID,
                    action: requestAction
                )
            )
        case "weight-entry":
            guard let rawValue = atlasURLValue("value", in: query),
                  let value = Double(rawValue),
                  value > 0 else {
                return
            }

            routePath.removeAll()
            activeTab = .insights
            await saveWeightEntry(
                AtlasWeightEntryDraft(
                    loggedAt: atlasURLDateValue("loggedat", in: query) ?? currentDate(),
                    value: value,
                    unit: AtlasWeightUnit(rawValue: atlasURLValue("unit", in: query)?.lowercased() ?? "") ?? .lb,
                    notes: atlasURLValue("notes", in: query)
                )
            )
        case "symptom-entry":
            guard let symptomKey = atlasURLValue("symptom", in: query) ?? atlasURLValue("symptomkey", in: query),
                  symptomKey.isEmpty == false else {
                return
            }

            routePath.removeAll()
            activeTab = .insights
            await saveSymptomEntry(
                AtlasSymptomEntryDraft(
                    loggedAt: atlasURLDateValue("loggedat", in: query) ?? currentDate(),
                    symptomKey: symptomKey,
                    severity: min(
                        max(Int(atlasURLValue("severity", in: query) ?? "") ?? 3, 1),
                        5
                    ),
                    notes: atlasURLValue("notes", in: query)
                )
            )
        default:
            return
        }
    }

    public func consumePendingExtensionActionIfNeeded() async {
        guard let url = AtlasPendingExtensionActionStore.consumeURL() else {
            return
        }
        await handleIncomingURL(url)
    }

    public func reminderPreview() -> AtlasReminderPreview {
        reminderPreview(
            nextDue: todaySnapshot.nextDue,
            privacyMode: reminderSettings.privacyMode,
            renderMode: settingsSnapshot.trustVaultStatus.renderMode,
            referenceDate: currentDate()
        )
    }

    func reminderPreview(
        nextDue: AtlasScheduledOccurrence?,
        privacyMode: AtlasReminderPrivacyMode,
        renderMode: AtlasPrivacyRenderMode,
        referenceDate: Date
    ) -> AtlasReminderPreview {
        dependencies.privacyFormatter.reminderPreview(
            occurrence: nextDue ?? AtlasScheduledOccurrence(
                id: "preview",
                protocolID: "preview",
                canonicalTitle: "Atlas protocol",
                aliasTitle: "Alias protocol",
                kindLabel: "Routine",
                cadenceLabel: "Daily cadence",
                doseLabel: nil,
                scheduledAt: Calendar.current.date(byAdding: .hour, value: 6, to: referenceDate) ?? referenceDate,
                state: .upcoming
            ),
            selectedMode: privacyMode,
            renderMode: renderMode
        )
    }

    func currentDate() -> Date {
        dependencies.dateProvider()
    }

    var canCreateLiveReviewSession: Bool {
        dependencies.cloudSync.isConfigured() && cloudSession != nil
    }

    private func performCloudAction(
        _ action: @escaping @MainActor () async throws -> Void
    ) async {
        guard isPerformingCloudAction == false else {
            return
        }

        isPerformingCloudAction = true
        defer { isPerformingCloudAction = false }

        do {
            try await action()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    private func syncRemindersIfPossible(referenceDate: Date) async {
        do {
            try await dependencies.reminders.syncReminders(referenceDate: referenceDate)
        } catch {
            // Reminder scheduling should not block shell loading or core protocol flows.
        }
    }

    func setLoadErrorMessage(_ message: String?) {
        loadErrorMessage = message
        if let message {
            Task {
                await dependencies.diagnostics.recordError(
                    message,
                    context: "app_model",
                    metadata: [
                        "activeTab": activeTab.rawValue,
                        "routeDepth": String(routePath.count)
                    ]
                )
            }
        }
        syncTodayViewState()
        syncTimelineViewState()
        syncInsightsViewState()
    }

    private func syncShellViewStates() {
        syncTodayViewState()
        syncTimelineViewState()
        syncLibraryViewState()
        syncInsightsViewState()
        syncSettingsViewState()
    }

    private func syncTodayViewState() {
        todayViewState.loadErrorMessage = loadErrorMessage
        todayViewState.todaySnapshot = todaySnapshot
        todayViewState.retentionSnapshot = retentionSnapshot
        todayViewState.rewardsSnapshot = rewardsSnapshot
        todayViewState.renderMode = settingsSnapshot.trustVaultStatus.renderMode
    }

    private func syncTimelineViewState() {
        timelineViewState.loadErrorMessage = loadErrorMessage
        timelineViewState.entries = timelineEntries
        timelineViewState.filter = timelineFilter
        timelineViewState.renderMode = settingsSnapshot.trustVaultStatus.renderMode
    }

    private func syncLibraryViewState() {
        libraryViewState.protocols = libraryProtocols
        libraryViewState.renderMode = settingsSnapshot.trustVaultStatus.renderMode
    }

    private func syncInsightsViewState() {
        insightsViewState.loadErrorMessage = loadErrorMessage
        insightsViewState.insightsSnapshot = insightsSnapshot
        insightsViewState.retentionSnapshot = retentionSnapshot
        insightsViewState.rewardsSnapshot = rewardsSnapshot
        insightsViewState.summarySettings = settingsSnapshot.summarySettings
        insightsViewState.libraryProtocols = libraryProtocols
        insightsViewState.renderMode = settingsSnapshot.trustVaultStatus.renderMode
    }

    private func syncSettingsViewState() {
        settingsViewState.settingsSnapshot = settingsSnapshot
        settingsViewState.todaySnapshot = todaySnapshot
        settingsViewState.reminderSettings = reminderSettings
        settingsViewState.notificationPermissionStatus = notificationPermissionStatus
        settingsViewState.retentionSnapshot = retentionSnapshot
        settingsViewState.rewardsSnapshot = rewardsSnapshot
    }

    private func invalidateInventoryCaches() {
        vialDetails.removeAll()
        consumableDetails.removeAll()
        protocolSiteOptions.removeAll()
    }

    private func atlasScheduledOccurrence(protocolID: String, occurrenceID: String) -> AtlasScheduledOccurrence? {
        let candidates = ([todaySnapshot.nextDue].compactMap { $0 }) + todaySnapshot.overdue + todaySnapshot.upcoming
        return candidates.first { $0.protocolID == protocolID && $0.id == occurrenceID }
    }

    private func atlasURLValue(_ key: String, in query: [String: String]) -> String? {
        guard let value = query[key], value.isEmpty == false else {
            return nil
        }
        return value
    }

    private func atlasURLDateValue(_ key: String, in query: [String: String]) -> Date? {
        guard let value = atlasURLValue(key, in: query) else {
            return nil
        }
        return AtlasAppModel.atlasURLDateFormatter.date(from: value)
    }

    private static let atlasURLDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

private enum AtlasCloudRestoreError: LocalizedError {
    case noBackup

    var errorDescription: String? {
        switch self {
        case .noBackup:
            return "Atlas did not find a cloud backup for this account yet."
        }
    }
}

public struct AtlasRootView: View {
    @Bindable private var model: AtlasAppModel

    public init(model: AtlasAppModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            if model.bootstrapSnapshot.destination == .onboarding {
                AtlasOnboardingFlowScreen(model: model)
            } else {
                NavigationStack(path: $model.routePath) {
                    AtlasShellView(model: model)
                    .task {
                        await model.loadShellDataIfNeeded()
                    }
                    .navigationDestination(for: AtlasRoute.self) { route in
                        switch route {
                        case .protocolDetail(let id):
                            AtlasProtocolDetailScreen(model: model, protocolID: id)
                        case .protocolCreate:
                            AtlasProtocolEditorScreen(model: model, mode: .create)
                        case .protocolEdit(let id):
                            AtlasProtocolEditorScreen(model: model, mode: .edit(id))
                        case .protocolChange(let id):
                            AtlasProtocolChangeStudioScreen(model: model, protocolID: id)
                        case .inventory:
                            AtlasInventoryScreen(model: model)
                        case .calculator:
                            AtlasCalculatorScreen(model: model)
                        case .trustVault:
                            AtlasTrustVaultScreen(model: model)
                        case .importFlow:
                            AtlasImportScreen(model: model)
                        case .reviewMode:
                            AtlasReviewModeScreen(model: model)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task {
            await model.loadBootstrapIfNeeded()
        }
    }
}

private struct AtlasShellView: View {
    @Bindable var model: AtlasAppModel

    var body: some View {
        ZStack {
            AtlasAppBackground()

            currentScreen
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AtlasBottomTabBar(selection: $model.activeTab)
        }
        .atlasRootNavigationBarHidden()
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch model.activeTab {
        case .today:
            AtlasTodayScreen(model: model, state: model.todayViewState)
        case .timeline:
            AtlasTimelineScreen(model: model, state: model.timelineViewState)
        case .library:
            AtlasLibraryScreen(model: model, state: model.libraryViewState)
        case .insights:
            AtlasInsightsScreen(model: model, state: model.insightsViewState)
        case .settings:
            AtlasSettingsScreen(model: model, state: model.settingsViewState)
        }
    }
}

private struct AtlasBottomTabBar: View {
    @Binding var selection: AtlasTab

    var body: some View {
        HStack(spacing: AtlasSpacing.xSmall) {
            ForEach(AtlasTab.allCases) { tab in
                let isSelected = selection == tab

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 7) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .symbolVariant(isSelected ? .fill : .none)
                        Text(tab.title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(isSelected ? AtlasPalette.primary : AtlasPalette.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                isSelected
                                    ? AnyShapeStyle(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.98), AtlasPalette.secondaryFill],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    : AnyShapeStyle(Color.clear)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isSelected ? Color.white.opacity(0.9) : Color.clear, lineWidth: 1)
                    )
                    .shadow(
                        color: isSelected ? AtlasPalette.shadow.opacity(0.24) : .clear,
                        radius: 12,
                        x: 0,
                        y: 7
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.95), AtlasPalette.surfaceSecondary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.88), lineWidth: 1)
        )
        .shadow(color: AtlasPalette.shadow.opacity(0.34), radius: 22, x: 0, y: 16)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color.clear.ignoresSafeArea(edges: .bottom))
    }
}

public struct AtlasTodayScreen: View {
    let model: AtlasAppModel
    let state: AtlasTodayViewState
    @State private var sheetContext: AtlasLogSheetContext?
    @State private var explanationSheet: AtlasExplanationSheetItem?
    @State private var contextEditor = AtlasContextEditorState(referenceDate: Date())
    @State private var contextSheetPresented = false

    public var body: some View {
        AtlasRootScrollSurface {
            AtlasTabHeader(
                title: "Today",
                subtitle: "What needs attention now, with clear actions and no hidden state.",
                action: AtlasTabHeaderAction(
                    systemImage: "arrow.clockwise",
                    accessibilityLabel: "Refresh Today",
                    accessibilityHint: "Reloads due, overdue, and upcoming items."
                ) {
                    Task { await model.refreshShellData() }
                }
            )

            if let error = state.loadErrorMessage {
                AtlasInlineMessage(text: error)
            }

            if state.todaySnapshot.hasProtocols == false {
                AtlasEmptyStateCard(
                    title: "No protocols yet",
                    message: "Imported users will see their next due card here, and new native users can start by creating a protocol.",
                    systemImage: "calendar.badge.plus",
                    note: "Start the loop"
                ) {
                    VStack(spacing: AtlasSpacing.small) {
                        Button("Create protocol") {
                            model.open(.protocolCreate)
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())

                        Button("Import Atlas data") {
                            model.open(.importFlow)
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                }

                AtlasSectionCard(style: .utility, title: "What shows up here") {
                    HStack(spacing: AtlasSpacing.small) {
                        AtlasStatusBadge("Next due")
                        AtlasStatusBadge("Overdue", tint: AtlasPalette.warning)
                        AtlasStatusBadge("Upcoming", tint: AtlasPalette.secondaryText)
                    }

                    Text("Once Atlas has a live schedule, Today becomes the calm action surface for logging, rescheduling, and reviewing what needs attention next.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            } else if let nextDue = state.todaySnapshot.nextDue {
                AtlasRootSectionHeader("Next due")
                AtlasOccurrenceHero(
                    occurrence: nextDue,
                    displayTitle: model.renderedTitle(
                        canonical: nextDue.canonicalTitle,
                        alias: nextDue.aliasTitle,
                        renderMode: state.renderMode
                    ),
                    onLog: { action in
                        sheetContext = AtlasLogSheetContext(occurrence: nextDue, initialAction: action)
                    },
                    onOpenProtocol: {
                        model.open(.protocolDetail(nextDue.protocolID))
                    },
                    onOpenChangeStudio: {
                        model.open(.protocolChange(nextDue.protocolID))
                    },
                    onExplain: nextDue.explanation.map { explanation in
                        {
                            explanationSheet = .occurrence(
                                id: "today:\(nextDue.id)",
                                title: model.renderedTitle(
                                    canonical: nextDue.canonicalTitle,
                                    alias: nextDue.aliasTitle,
                                    renderMode: state.renderMode
                                ),
                                explanation: explanation
                            )
                        }
                    }
                )
            } else {
                AtlasEmptyStateCard(
                    title: "Nothing due right now",
                    message: "Your future schedule is clear. Create another protocol or check the Library to review current plans.",
                    systemImage: "checkmark.circle",
                    note: "Clear for now"
                ) {
                    VStack(spacing: AtlasSpacing.small) {
                        Button("Open Library") {
                            model.activeTab = .library
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())

                        Button("Create another protocol") {
                            model.open(.protocolCreate)
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                }
            }

            if state.todaySnapshot.hasProtocols {
                AtlasRootSectionHeader("Quick context")
                AtlasTodayContextQuickCard(
                    model: model,
                    onOpenDetailedCapture: {
                        contextEditor = AtlasContextEditorState(referenceDate: model.currentDate())
                        contextSheetPresented = true
                    }
                )
            }

            if state.rewardsSnapshot.settings.enabled {
                AtlasRootSectionHeader("Rewards")
                AtlasRewardsTodayCard(snapshot: state.rewardsSnapshot)
            }

            if state.retentionSnapshot.settings.progressEnabled {
                AtlasRootSectionHeader("Calm continuity")
                AtlasRetentionTodayCard(model: model, snapshot: state.retentionSnapshot)
            }

            if state.todaySnapshot.overdue.isEmpty == false {
                AtlasRootSectionHeader("Overdue")
                VStack(spacing: AtlasSpacing.medium) {
                    ForEach(state.todaySnapshot.overdue) { occurrence in
                        AtlasOccurrenceRow(
                            occurrence: occurrence,
                            title: model.renderedTitle(
                                canonical: occurrence.canonicalTitle,
                                alias: occurrence.aliasTitle,
                                renderMode: state.renderMode
                            ),
                            action: { action in
                                sheetContext = AtlasLogSheetContext(occurrence: occurrence, initialAction: action)
                            },
                            onOpenChangeStudio: {
                                model.open(.protocolChange(occurrence.protocolID))
                            },
                            onExplain: occurrence.explanation.map { explanation in
                                {
                                    explanationSheet = .occurrence(
                                        id: "today:\(occurrence.id)",
                                        title: model.renderedTitle(
                                            canonical: occurrence.canonicalTitle,
                                            alias: occurrence.aliasTitle,
                                            renderMode: state.renderMode
                                        ),
                                        explanation: explanation
                                    )
                                }
                            }
                        )
                    }
                }
            }

            if state.todaySnapshot.upcoming.isEmpty == false {
                AtlasRootSectionHeader("Upcoming")
                VStack(spacing: AtlasSpacing.medium) {
                    ForEach(state.todaySnapshot.upcoming) { occurrence in
                        AtlasOccurrenceRow(
                            occurrence: occurrence,
                            title: model.renderedTitle(
                                canonical: occurrence.canonicalTitle,
                                alias: occurrence.aliasTitle,
                                renderMode: state.renderMode
                            ),
                            action: { action in
                                sheetContext = AtlasLogSheetContext(occurrence: occurrence, initialAction: action)
                            },
                            onOpenChangeStudio: {
                                model.open(.protocolChange(occurrence.protocolID))
                            },
                            onExplain: occurrence.explanation.map { explanation in
                                {
                                    explanationSheet = .occurrence(
                                        id: "today:\(occurrence.id)",
                                        title: model.renderedTitle(
                                            canonical: occurrence.canonicalTitle,
                                            alias: occurrence.aliasTitle,
                                            renderMode: state.renderMode
                                        ),
                                        explanation: explanation
                                    )
                                }
                            }
                        )
                    }
                }
            }
        }
        .sheet(item: $sheetContext) { context in
            AtlasLogSheet(model: model, context: context) { request in
                await model.logOccurrence(request)
            }
        }
        .sheet(isPresented: $contextSheetPresented) {
            AtlasContextEntrySheet(model: model, state: contextEditor)
        }
        .sheet(item: $explanationSheet) { item in
            AtlasExplanationSheet(item: item)
        }
    }
}

private struct AtlasTodayContextQuickCard: View {
    let model: AtlasAppModel
    let onOpenDetailedCapture: () -> Void

    var body: some View {
        let presets = model.contextQuickPresets(limit: 3)
        let recentMeals = model.recentMealQuickItems(limit: 3)
        let nutritionTargets = model.insightsSnapshot.nutritionSnapshot.dailyTargets
        let featuredFoods = model.nutritionFeaturedLookupItems(limit: 4)

        AtlasSectionCard(style: .utility) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                Text(
                    model.insightsSnapshot.savedContextPresets.isEmpty
                        ? "Capture meals, hydration, and surrounding context without leaving Today."
                        : "Favorites and repeat meals now live here too for faster nutrition logging."
                )
                    .foregroundStyle(AtlasPalette.textSecondary)

                if nutritionTargets.isEmpty == false {
                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                        Text("Today's nutrition targets")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AtlasPalette.primary)
                            .textCase(.uppercase)

                        ForEach(nutritionTargets) { target in
                            HStack(spacing: AtlasSpacing.small) {
                                Text(target.title)
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                Spacer()
                                AtlasStatusBadge(
                                    target.progressLabel,
                                    tint: target.isMet ? AtlasPalette.success : AtlasPalette.primary
                                )
                            }
                        }
                    }
                }

                AtlasContextQuickPresetRail(presets: presets) { preset in
                    Task { await model.saveContextEntry(preset.makeDraft(loggedAt: model.currentDate())) }
                }

                if recentMeals.isEmpty == false {
                    AtlasRecentMealQuickRail(items: recentMeals) { item in
                        Task { await model.saveContextEntry(item.draft(loggedAt: model.currentDate())) }
                    }
                }

                AtlasNutritionLookupRail(
                    title: "Common foods",
                    items: featuredFoods
                ) { item in
                    Task { await model.saveContextEntry(item.makeDraft(loggedAt: model.currentDate())) }
                }

                Button("Log with notes or more detail") {
                    onOpenDetailedCapture()
                }
                .buttonStyle(AtlasSecondaryButtonStyle())

                if model.insightsSnapshot.savedContextPresets.isEmpty {
                    Text("Use Insights to save your own favorites once you find repeats worth keeping.")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    Text("Use Insights to refine favorites, reuse recent meals, add notes, or capture fuller meal detail.")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
        }
    }
}

public struct AtlasTimelineScreen: View {
    let model: AtlasAppModel
    let state: AtlasTimelineViewState
    @State private var explanationSheet: AtlasExplanationSheetItem?

    public var body: some View {
        AtlasRootScrollSurface {
            AtlasTabHeader(
                title: "Timeline",
                subtitle: "Immutable history, protocol changes, and surrounding context in one place."
            )

            AtlasSectionCard(style: .utility, title: "Timeline lens") {
                HStack(spacing: AtlasSpacing.small) {
                    AtlasStatusBadge(state.filter.title)
                    AtlasStatusBadge("Immutable log", tint: AtlasPalette.secondaryText)
                }

                Text("History stays immutable. Narrow the view before you read so protocol logs, changes, and surrounding context never blur together.")
                    .foregroundStyle(AtlasPalette.textSecondary)

                Picker("Filter", selection: Binding(
                    get: { state.filter },
                    set: { value in
                        model.timelineFilter = value
                        state.filter = value
                        Task { await model.refreshTimeline() }
                    }
                )) {
                    ForEach(AtlasTimelineFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            if state.entries.isEmpty {
                AtlasEmptyStateCard(
                    title: "No history yet",
                    message: "Quick logs, imports, and protocol edits will appear here with immutable timestamps.",
                    systemImage: "clock.badge.questionmark",
                    note: "Immutable from the first event"
                ) {
                    Button("Create protocol") {
                        model.open(.protocolCreate)
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                }
            } else {
                ForEach(groupedTimelineEntries, id: \.dateLabel) { section in
                    AtlasRootSectionHeader(section.dateLabel)
                    VStack(spacing: AtlasSpacing.medium) {
                        ForEach(section.entries) { entry in
                            AtlasTimelineEntryCard(
                                model: model,
                                entry: entry,
                                onExplainOccurrence: entry.occurrenceExplanation.map { explanation in
                                    {
                                        explanationSheet = .occurrence(
                                            id: "timeline:\(entry.id)",
                                            title: model.renderedTitle(
                                                canonical: entry.canonicalTitle,
                                                alias: entry.aliasTitle,
                                                renderMode: state.renderMode
                                            ),
                                            explanation: explanation
                                        )
                                    }
                                },
                                onExplainChange: entry.changeExplanation.map { explanation in
                                    {
                                        explanationSheet = .change(
                                            id: "timeline:\(entry.id)",
                                            title: model.renderedTitle(
                                                canonical: entry.canonicalTitle,
                                                alias: entry.aliasTitle,
                                                renderMode: state.renderMode
                                            ),
                                            explanation: explanation
                                        )
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
        .sheet(item: $explanationSheet) { item in
            AtlasExplanationSheet(item: item)
        }
    }

    private var groupedTimelineEntries: [AtlasTimelineSection] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let groups = Dictionary(grouping: state.entries) { entry in
            Calendar.current.startOfDay(for: entry.recordedAt)
        }

        return groups.keys.sorted(by: >).map { date in
            AtlasTimelineSection(
                dateLabel: formatter.string(from: date),
                entries: groups[date]?.sorted(by: { $0.recordedAt > $1.recordedAt }) ?? []
            )
        }
    }
}

public struct AtlasLibraryScreen: View {
    let model: AtlasAppModel
    let state: AtlasLibraryViewState

    public var body: some View {
        AtlasRootScrollSurface {
            AtlasTabHeader(
                title: "Library",
                subtitle: "Protocols, tools, and core loop planning from the native shell.",
                action: AtlasTabHeaderAction(
                    systemImage: "plus",
                    accessibilityLabel: "Create protocol",
                    accessibilityHint: "Opens the native protocol creation form."
                ) {
                    model.open(.protocolCreate)
                }
            )

            AtlasSectionCard(style: .utility, title: "Tools") {
                Text("Open the supporting workspaces that shape your protocol library without losing the main planning context.")
                    .foregroundStyle(AtlasPalette.textSecondary)

                HStack(spacing: AtlasSpacing.small) {
                    AtlasToolLauncherButton(
                        title: "Inventory",
                        subtitle: "Vials, supplies, and restock context",
                        systemImage: "shippingbox.fill"
                    ) {
                        model.open(.inventory)
                    }

                    AtlasToolLauncherButton(
                        title: "Calculator",
                        subtitle: "Dose math and saved reference profiles",
                        systemImage: "function"
                    ) {
                        model.open(.calculator)
                    }
                }
            }

            if state.protocols.isEmpty {
                AtlasEmptyStateCard(
                    title: "Library is empty",
                    message: "Create a native protocol or import an Atlas Export v1 bundle to start building your core loop.",
                    systemImage: "square.stack.3d.up",
                    note: "Build the foundation"
                ) {
                    VStack(spacing: AtlasSpacing.small) {
                        Button("Create protocol") {
                            model.open(.protocolCreate)
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())

                        Button("Import Atlas data") {
                            model.open(.importFlow)
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                }
            } else {
                AtlasRootSectionHeader("Protocols")
                VStack(spacing: AtlasSpacing.medium) {
                    ForEach(state.protocols) { summary in
                        AtlasProtocolLibraryCard(model: model, summary: summary, renderMode: state.renderMode)
                    }
                }
            }
        }
    }
}

public struct AtlasProtocolDetailScreen: View {
    let model: AtlasAppModel
    let protocolID: String
    @State private var detail: AtlasProtocolDetailSnapshot?
    @State private var sheetContext: AtlasLogSheetContext?
    @State private var explanationSheet: AtlasExplanationSheetItem?

    public var body: some View {
        List {
            if let detail {
                Section {
                    AtlasSectionCard {
                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(model.renderedTitle(canonical: detail.canonicalTitle, alias: detail.aliasTitle))
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Spacer()
                                AtlasStatusBadge(detail.status.rawValue.capitalized)
                            }
                            Text("\(detail.kindLabel) • \(detail.cadenceLabel)")
                                .foregroundStyle(AtlasPalette.textSecondary)
                            if let doseLabel = detail.doseLabel {
                                Text("Dose \(doseLabel)")
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                if let nextOccurrence = detail.nextOccurrence {
                    Section("Next due") {
                        AtlasOccurrenceRow(
                            occurrence: nextOccurrence,
                            title: model.renderedTitle(
                                canonical: nextOccurrence.canonicalTitle,
                                alias: nextOccurrence.aliasTitle
                            ),
                            action: { action in
                                sheetContext = AtlasLogSheetContext(occurrence: nextOccurrence, initialAction: action)
                            },
                            onExplain: nextOccurrence.explanation.map { explanation in
                                {
                                    explanationSheet = .occurrence(
                                        id: "protocol:\(nextOccurrence.id)",
                                        title: model.renderedTitle(
                                            canonical: nextOccurrence.canonicalTitle,
                                            alias: nextOccurrence.aliasTitle
                                        ),
                                        explanation: explanation
                                    )
                                }
                            }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }

                if detail.recentChanges.isEmpty == false {
                    Section("Recent changes") {
                        ForEach(detail.recentChanges) { change in
                            AtlasProtocolChangeExplanationCard(
                                title: model.renderedTitle(
                                    canonical: detail.canonicalTitle,
                                    alias: detail.aliasTitle
                                ),
                                explanation: change,
                                onOpenDetail: {
                                    explanationSheet = .change(
                                        id: "protocol:\(change.id)",
                                        title: model.renderedTitle(
                                            canonical: detail.canonicalTitle,
                                            alias: detail.aliasTitle
                                        ),
                                        explanation: change
                                    )
                                }
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        }
                    }
                }

                Section("Notes") {
                    AtlasSectionCard {
                        Text(detail.notes ?? "No notes")
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("Future plan") {
                    AtlasSectionCard {
                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            Text("Future edits stay deliberate. Atlas preserves historical logs and only reshapes future projections.")
                                .foregroundStyle(AtlasPalette.textSecondary)

                            Button("Edit core fields") {
                                model.open(.protocolEdit(protocolID))
                            }
                            .buttonStyle(AtlasSecondaryButtonStyle())

                            Button("Inventory and sites") {
                                model.open(.inventory)
                            }
                            .buttonStyle(AtlasSecondaryButtonStyle())

                            Button("Open Change Studio") {
                                model.open(.protocolChange(protocolID))
                            }
                            .buttonStyle(AtlasPrimaryButtonStyle())
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            } else if let error = model.loadErrorMessage {
                AtlasInlineMessage(text: error)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AtlasPalette.canvas)
        .navigationTitle("Protocol")
        .atlasInlineNavigationTitle()
        .task {
            detail = await model.protocolDetail(id: protocolID)
        }
        .sheet(item: $sheetContext) { context in
            AtlasLogSheet(model: model, context: context) { request in
                await model.logOccurrence(request)
                detail = await model.protocolDetail(id: protocolID)
            }
        }
        .sheet(item: $explanationSheet) { item in
            AtlasExplanationSheet(item: item)
        }
    }
}

public enum AtlasProtocolEditorMode: Equatable {
    case create
    case edit(String)
}

public struct AtlasProtocolEditorScreen: View {
    let model: AtlasAppModel
    let mode: AtlasProtocolEditorMode
    @State private var form = AtlasProtocolFormState()
    @State private var didLoad = false

    public var body: some View {
        Form {
            Section("Protocol") {
                TextField("Name", text: $form.name)
                Picker("Kind", selection: $form.kind) {
                    Text("GLP").tag(AtlasProtocolKind.glp)
                    Text("Peptide").tag(AtlasProtocolKind.peptide)
                    Text("Custom").tag(AtlasProtocolKind.custom)
                }
            }

            Section("Cadence") {
                Picker("Cadence", selection: $form.cadenceType) {
                    Text("Weekly").tag(AtlasProtocolRuleType.weekly)
                    Text("Daily").tag(AtlasProtocolRuleType.daily)
                    Text("Every N days").tag(AtlasProtocolRuleType.everyNDays)
                }
                if form.cadenceType == .weekly {
                    Picker("Day", selection: $form.weekday) {
                        ForEach(0..<7, id: \.self) { index in
                            Text(weekdayName(index)).tag(Optional(index))
                        }
                    }
                } else if form.cadenceType == .everyNDays {
                    Stepper(value: $form.intervalDays, in: 1...30) {
                        Text("Every \(form.intervalDays) days")
                    }
                }
                TextField("Default time", text: $form.defaultTimeOfDay)
                    .autocorrectionDisabled()
            }

            Section("Dose") {
                TextField("Amount", text: $form.doseAmount)
                TextField("Unit", text: $form.doseUnit)
            }

            Section("Notes") {
                TextField("Optional notes", text: $form.notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .atlasFormSurface()
        .navigationTitle(mode.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(mode.buttonTitle) {
                    Task { await submit() }
                }
                .accessibilityIdentifier("protocolEditorSubmitButton")
            }
        }
        .task {
            guard didLoad == false else {
                return
            }
            didLoad = true
            if case .edit(let id) = mode, let detail = await model.protocolDetail(id: id) {
                form = AtlasProtocolFormState(detail.editableDraft)
            }
        }
    }

    private func submit() async {
        let draft = form.domainDraft

        switch mode {
        case .create:
            if let detail = await model.createProtocol(draft) {
                model.routePath.removeAll()
                model.activeTab = .library
                model.open(.protocolDetail(detail.id))
            }
        case .edit(let id):
            if let detail = await model.updateProtocol(id: id, draft: draft) {
                model.routePath.removeAll()
                model.activeTab = .library
                model.open(.protocolDetail(detail.id))
            }
        }
    }
}

public struct AtlasSettingsScreen: View {
    let model: AtlasAppModel
    let state: AtlasSettingsViewState
    @State private var cloudEmail = ""
    @State private var cloudPassword = ""

    public var body: some View {
        AtlasRootScrollSurface {
            AtlasTabHeader(
                title: "Settings",
                subtitle: "Privacy, reminders, and local-first controls stay visible and deliberate."
            )

            AtlasSectionCard(style: .elevated, title: "Account & sync") {
                HStack(spacing: AtlasSpacing.small) {
                    AtlasStatusBadge(
                        model.cloudSession == nil ? "Local-first" : "Cloud connected",
                        tint: model.cloudSession == nil ? AtlasPalette.primary : AtlasPalette.success
                    )
                    AtlasStatusBadge(
                        state.settingsSnapshot.accountMode.rawValue.capitalized,
                        tint: AtlasPalette.secondaryText
                    )
                }
                Text(accountModeSummary)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text("Sync status: \(syncSummary)")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text(model.cloudStatusDescription)
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
                if state.settingsSnapshot.onboardingCompleted {
                    Text("Onboarding complete")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.success)
                } else {
                    Text("Onboarding not completed on this local profile")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }
                if let session = model.cloudSession {
                    Text("Connected account: \(session.email)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.primary)
                    if let lastSyncAt = session.lastSyncAt {
                        Text("Cloud backup updated \(lastSyncAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                    Button("Sync to Atlas Cloud") {
                        Task { await model.syncToCloud() }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                    .disabled(model.isPerformingCloudAction)

                    HStack(spacing: AtlasSpacing.small) {
                        Button("Restore latest cloud backup") {
                            Task { await model.restoreLatestCloudBackup() }
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                        .disabled(model.isPerformingCloudAction)

                        Button("Sign out") {
                            Task { await model.signOutOfCloud() }
                        }
                        .buttonStyle(AtlasTertiaryButtonStyle())
                        .disabled(model.isPerformingCloudAction)
                    }
                } else {
                    if model.dependencies.cloudSync.isConfigured() {
                        TextField("Email", text: $cloudEmail)
                            .autocorrectionDisabled()
                            .atlasStandaloneInputSurface()
                        SecureField("Password", text: $cloudPassword)
                            .atlasStandaloneInputSurface()
                        Button("Sign in") {
                            Task { await model.signInToCloud(email: cloudEmail.trimmingCharacters(in: .whitespacesAndNewlines), password: cloudPassword) }
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                        .disabled(model.isPerformingCloudAction || cloudEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || cloudPassword.isEmpty)

                        HStack(spacing: AtlasSpacing.small) {
                            Button("Continue with Google") {
                                Task { await model.signInToCloud(with: .google) }
                            }
                            .buttonStyle(AtlasSecondaryButtonStyle())
                            .disabled(model.isPerformingCloudAction)

                            Button("Continue with Apple") {
                                Task { await model.signInToCloud(with: .apple) }
                            }
                            .buttonStyle(AtlasSecondaryButtonStyle())
                            .disabled(model.isPerformingCloudAction)
                        }

                        Button("Create Atlas account") {
                            Task { await model.signUpToCloud(email: cloudEmail.trimmingCharacters(in: .whitespacesAndNewlines), password: cloudPassword) }
                        }
                        .buttonStyle(AtlasTertiaryButtonStyle())
                        .disabled(model.isPerformingCloudAction || cloudEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || cloudPassword.isEmpty)
                    } else {
                        Text("Cloud sync can be added to this build by setting Atlas Supabase configuration before release.")
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                }
                Button("Reset onboarding state") {
                    Task { await model.resetOnboarding() }
                }
                .buttonStyle(AtlasWarningButtonStyle())
            }

            AtlasSectionCard(style: .elevated, title: "Privacy & trust") {
                HStack(spacing: AtlasSpacing.small) {
                    AtlasStatusBadge(state.settingsSnapshot.trustVaultStatus.renderMode.rawValue.capitalized)
                    AtlasStatusBadge("Trust tools", tint: AtlasPalette.secondaryText)
                }
                Text(model.dependencies.privacyFormatter.summary(mode: state.settingsSnapshot.trustVaultStatus.renderMode))
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text("Account mode: \(state.settingsSnapshot.accountMode.rawValue)")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Picker(
                    "Display mode",
                    selection: Binding(
                        get: { state.settingsSnapshot.trustVaultStatus.renderMode },
                        set: { value in
                            state.settingsSnapshot.trustVaultStatus.renderMode = value
                            model.settingsSnapshot.trustVaultStatus.renderMode = value
                            Task {
                                await model.updatePrivacyRenderMode(value)
                            }
                        }
                    )
                ) {
                    Text("Full").tag(AtlasPrivacyRenderMode.full)
                    Text("Discreet").tag(AtlasPrivacyRenderMode.discreet)
                    Text("Alias").tag(AtlasPrivacyRenderMode.alias)
                }
                AtlasActionGrid(actions: [
                    ("Trust Vault", .trustVault),
                    ("Import", .importFlow),
                    ("Review Mode", .reviewMode)
                ], model: model)
            }

            AtlasSectionCard(title: "Plain-language summaries") {
                Text("Optional, bounded recaps are generated from Atlas data already on device. They stay descriptive and keep the source facts visible.")
                    .foregroundStyle(AtlasPalette.textSecondary)

                AtlasSettingsToggleRow(
                    title: "Enable on-device summaries",
                    subtitle: "Generate optional bounded recaps on this device only.",
                    isOn: Binding(
                        get: { state.settingsSnapshot.summarySettings.onDeviceEnabled },
                        set: { value in
                            state.settingsSnapshot.summarySettings.onDeviceEnabled = value
                            model.settingsSnapshot.summarySettings.onDeviceEnabled = value
                            Task {
                                await model.updateSummarySettings(
                                    AtlasSummarySettingsUpdate(onDeviceEnabled: value)
                                )
                            }
                        }
                    ),
                    isEnabled: model.dependencies.featureFlags.flags.boundedSummaries
                )

                AtlasSettingsToggleRow(
                    title: "Allow external summary processing",
                    subtitle: "Not available on this device today.",
                    isOn: .constant(false),
                    isEnabled: false
                )

                Text("External provider summaries are not turned on here. Atlas keeps summary payloads on device in this build.")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            AtlasSectionCard(title: "Rewards") {
                Text("Turn on streaks, badges, and progress rewards for consistency, workout completion, self-defined goals, and descriptive weight milestones.")
                    .foregroundStyle(AtlasPalette.textSecondary)

                AtlasSettingsToggleRow(
                    title: "Show streaks and badges",
                    subtitle: "Surface rewards on Today and Insights.",
                    isOn: Binding(
                        get: { state.settingsSnapshot.rewardsSettings.enabled },
                        set: { value in
                            state.settingsSnapshot.rewardsSettings.enabled = value
                            model.settingsSnapshot.rewardsSettings.enabled = value
                            Task {
                                await model.updateRewardsSettings(
                                    AtlasRewardsSettingsUpdate(enabled: value)
                                )
                            }
                        }
                    ),
                    isEnabled: true
                )

                Stepper(
                    value: Binding(
                        get: { state.settingsSnapshot.rewardsSettings.weeklyWorkoutGoal },
                        set: { value in
                            state.settingsSnapshot.rewardsSettings.weeklyWorkoutGoal = value
                            model.settingsSnapshot.rewardsSettings.weeklyWorkoutGoal = value
                            Task {
                                await model.updateRewardsSettings(
                                    AtlasRewardsSettingsUpdate(weeklyWorkoutGoal: value)
                                )
                            }
                        }
                    ),
                    in: 1...14
                ) {
                    Text("Weekly workout goal: \(state.settingsSnapshot.rewardsSettings.weeklyWorkoutGoal)")
                }
                .disabled(state.settingsSnapshot.rewardsSettings.enabled == false)

                Stepper(
                    value: Binding(
                        get: { state.settingsSnapshot.rewardsSettings.weeklySelfGoalTarget },
                        set: { value in
                            state.settingsSnapshot.rewardsSettings.weeklySelfGoalTarget = value
                            model.settingsSnapshot.rewardsSettings.weeklySelfGoalTarget = value
                            Task {
                                await model.updateRewardsSettings(
                                    AtlasRewardsSettingsUpdate(weeklySelfGoalTarget: value)
                                )
                            }
                        }
                    ),
                    in: 1...7
                ) {
                    Text("Weekly self-goal target: \(state.settingsSnapshot.rewardsSettings.weeklySelfGoalTarget)")
                }
                .disabled(state.settingsSnapshot.rewardsSettings.enabled == false)

                Text("Self-defined rewards use Yes/No custom metrics from Insights. Weight milestones automatically use the goal weight from onboarding when Atlas has one, but stay descriptive instead of over-rewarding every change.")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            AtlasSectionCard(title: "Calm continuity") {
                Text("Optional local milestones can quietly reflect recent entries, weekly review, inventory upkeep, and steady context logging. They stay descriptive, local, and non-punitive.")
                    .foregroundStyle(AtlasPalette.textSecondary)

                AtlasSettingsToggleRow(
                    title: "Show calm continuity",
                    subtitle: "Surface optional local continuity on Today and Insights.",
                    isOn: Binding(
                        get: { state.settingsSnapshot.retentionSettings.progressEnabled },
                        set: { value in
                            state.settingsSnapshot.retentionSettings.progressEnabled = value
                            model.settingsSnapshot.retentionSettings.progressEnabled = value
                            if value == false {
                                state.settingsSnapshot.retentionSettings.companionEnabled = false
                                model.settingsSnapshot.retentionSettings.companionEnabled = false
                            }
                            Task {
                                await model.updateRetentionSettings(
                                    AtlasRetentionSettingsUpdate(progressEnabled: value)
                                )
                            }
                        }
                    ),
                    isEnabled: model.dependencies.featureFlags.flags.calmRetention
                )

                AtlasSettingsToggleRow(
                    title: "Show companion accent",
                    subtitle: "Allows Atlas's optional companion card when continuity has a meaningful update.",
                    isOn: Binding(
                        get: { state.settingsSnapshot.retentionSettings.companionEnabled },
                        set: { value in
                            state.settingsSnapshot.retentionSettings.companionEnabled = value
                            model.settingsSnapshot.retentionSettings.companionEnabled = value
                            Task {
                                await model.updateRetentionSettings(
                                    AtlasRetentionSettingsUpdate(companionEnabled: value)
                                )
                            }
                        }
                    ),
                    isEnabled: model.dependencies.featureFlags.flags.calmRetention
                        && model.dependencies.featureFlags.flags.companionSkin
                        && state.settingsSnapshot.retentionSettings.progressEnabled
                )

                Text(
                    model.dependencies.featureFlags.flags.companionSkin
                        ? "The companion only appears when Atlas has a calm continuity update to show, and it stays optional, local, and easy to hide."
                        : "The companion layer is deferred by feature flag in this build."
                )
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)

                if model.dependencies.featureFlags.flags.companionSkin {
                    AtlasRetentionCompanionPreview(
                        companion: state.retentionSnapshot.companion ?? AtlasRetentionCompanionSnapshot(
                            mood: .quiet,
                            title: "Quiet accent",
                            subtitle: "The companion stays hidden until Atlas has a calm continuity update.",
                            systemImage: "circle.dashed"
                        ),
                        title: "Companion preview",
                        caption: state.settingsSnapshot.retentionSettings.companionEnabled
                            ? "This is the current restrained companion style."
                            : "Enable calm continuity and the companion toggle to allow this accent on Today and Insights when it has something real to say."
                    )
                }
            }

            AtlasSectionCard(title: "Reminders") {
                Text("Scheduled locally from Atlas projections. Guest mode stays supported, and reminder copy follows your current privacy render mode.")
                    .foregroundStyle(AtlasPalette.textSecondary)

                Text("Permission: \(permissionLabel(state.notificationPermissionStatus))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textSecondary)

                if state.notificationPermissionStatus == .notDetermined {
                    Button("Allow notifications") {
                        Task { await model.requestReminderPermission() }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                } else if state.notificationPermissionStatus == .denied {
                    Text("Notifications are disabled for Atlas on this device.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                AtlasSettingsToggleRow(
                    title: "Enable local reminders",
                    subtitle: "Use Atlas projections to schedule local reminder notifications.",
                    isOn: Binding(
                        get: { state.reminderSettings.remindersEnabled },
                        set: { value in
                            state.reminderSettings.remindersEnabled = value
                            model.reminderSettings.remindersEnabled = value
                            Task {
                                await model.updateReminderSettings(
                                    AtlasReminderPreferenceUpdate(remindersEnabled: value)
                                )
                            }
                        }
                    )
                )

                Picker(
                    "Lead time",
                    selection: Binding(
                        get: { state.reminderSettings.leadTimeMinutes },
                        set: { value in
                            state.reminderSettings.leadTimeMinutes = value
                            model.reminderSettings.leadTimeMinutes = value
                            Task {
                                await model.updateReminderSettings(
                                    AtlasReminderPreferenceUpdate(leadTimeMinutes: value)
                                )
                            }
                        }
                    )
                ) {
                    ForEach(AtlasReminderLeadTime.allCases) { option in
                        Text(option.title).tag(option.minutes)
                    }
                }

                Picker(
                    "Reminder copy",
                    selection: Binding(
                        get: { state.reminderSettings.privacyMode },
                        set: { value in
                            state.reminderSettings.privacyMode = value
                            model.reminderSettings.privacyMode = value
                            Task {
                                await model.updateReminderSettings(
                                    AtlasReminderPreferenceUpdate(privacyMode: value)
                                )
                            }
                        }
                    )
                ) {
                    Text("Full detail").tag(AtlasReminderPrivacyMode.fullDetail)
                    Text("Generic").tag(AtlasReminderPrivacyMode.generic)
                    Text("Silent").tag(AtlasReminderPrivacyMode.silent)
                }

                let preview = model.reminderPreview(
                    nextDue: state.todaySnapshot.nextDue,
                    privacyMode: state.reminderSettings.privacyMode,
                    renderMode: state.settingsSnapshot.trustVaultStatus.renderMode,
                    referenceDate: model.currentDate()
                )
                AtlasSectionCard(style: .utility, title: "Preview") {
                    Text("Preview")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Text(preview.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(preview.body)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Text("Effective mode: \(preview.effectiveMode.rawValue)")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }

            AtlasSectionCard(title: "Connected services") {
                let health = model.settingsSnapshot.healthScaffold
                Text(health.isAvailable ? "Apple Health is available as an optional connection." : "Apple Health is unavailable on this device.")
                    .foregroundStyle(AtlasPalette.textSecondary)
                if let connection = health.connections.first {
                    Text("Health status: \(connection.connected ? "Connected" : "Not connected")")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textSecondary)
                    if let lastError = connection.lastError, lastError.isEmpty == false {
                        Text(lastError)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if let lastSyncAt = connection.lastSyncAt {
                        let parsedLastSync = ISO8601DateFormatter().date(from: lastSyncAt)
                        Text(
                            parsedLastSync.map {
                                "Last Health sync: \($0.formatted(date: .abbreviated, time: .shortened))"
                            } ?? "Last Health sync recorded"
                        )
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                }
                Text(model.dependencies.healthKit.connectionDescription())
                    .foregroundStyle(AtlasPalette.textSecondary)
                if health.isAvailable {
                    if health.connections.contains(where: { $0.providerKey == .appleHealth && $0.connected }) {
                        Button("Disconnect Apple Health") {
                            Task { await model.disconnectHealthKit() }
                        }
                        .buttonStyle(AtlasTertiaryButtonStyle())
                    } else {
                        Button("Connect Apple Health") {
                            Task { await model.connectHealthKit() }
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                    }
                }
                Text(model.dependencies.importExport.importStatusDescription())
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text(model.dependencies.sharedProjectionWriter.projectionDescription())
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text(model.dependencies.diagnostics.statusDescription())
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
        }
    }

    private var accountModeSummary: String {
        switch state.settingsSnapshot.accountStartMode {
        case .guest:
            return "This profile started in guest mode."
        case .create:
            return "This profile started with account creation enabled. Local tracking still remains available."
        case .signIn:
            return "This profile started through sign-in. Local-first access remains intact."
        case nil:
            return state.settingsSnapshot.accountMode == .guest
                ? "This profile is local-first and guest-friendly."
                : "This profile can keep local data while account features stay optional."
        }
    }

    private var syncSummary: String {
        if model.cloudSession != nil {
            return "Connected"
        }
        switch state.settingsSnapshot.syncStatus {
        case .localOnly:
            return model.dependencies.cloudSync.isConfigured() ? "Ready to connect" : "Local only"
        case .accountBoundary:
            return "Account-enabled"
        case .syncDeferred:
            return "Configured later"
        }
    }
}

public struct AtlasTrustVaultScreen: View {
    let model: AtlasAppModel

    public var body: some View {
        AtlasTrustVaultHomeScreen(model: model)
    }
}

public struct AtlasImportScreen: View {
    let model: AtlasAppModel

    public var body: some View {
        AtlasImportCenterScreen(model: model)
    }
}

public struct AtlasReviewModeScreen: View {
    let model: AtlasAppModel

    public var body: some View {
        AtlasReviewModeHomeScreen(model: model)
    }
}

public struct AtlasDetailPlaceholderScreen: View {
    let title: String
    let message: String

    public var body: some View {
        AtlasScreen {
            header(title, subtitle: message)
        }
        .navigationTitle(title)
        .atlasInlineNavigationTitle()
    }
}

private struct AtlasTimelineSection {
    let dateLabel: String
    let entries: [AtlasTimelineEntry]
}

private enum AtlasExplanationSheetItem: Identifiable {
    case occurrence(id: String, title: String, explanation: AtlasOccurrenceExplanation)
    case change(id: String, title: String, explanation: AtlasProtocolChangeExplanation)

    var id: String {
        switch self {
        case let .occurrence(id, _, _), let .change(id, _, _):
            return id
        }
    }

    var title: String {
        switch self {
        case let .occurrence(_, title, _), let .change(_, title, _):
            return title
        }
    }

    var panelTitle: String {
        switch self {
        case .occurrence:
            return "Why this is due"
        case .change:
            return "What changed"
        }
    }

    var summary: String {
        switch self {
        case let .occurrence(_, _, explanation):
            return explanation.summary
        case let .change(_, _, explanation):
            return explanation.summary
        }
    }

    var detailLine: String? {
        switch self {
        case .occurrence:
            return nil
        case let .change(_, _, explanation):
            return "Effective \(explanation.effectiveDateLabel)"
        }
    }

    var facts: [AtlasExplainerFact] {
        switch self {
        case let .occurrence(_, _, explanation):
            return explanation.facts
        case let .change(_, _, explanation):
            return explanation.facts
        }
    }

    var notes: [String] {
        switch self {
        case let .occurrence(_, _, explanation):
            return explanation.notes
        case let .change(_, _, explanation):
            return explanation.notes
        }
    }
}

private enum AtlasReminderLeadTime: Int, CaseIterable, Identifiable {
    case atTime = 0
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60

    var id: Int { rawValue }

    var minutes: Int { rawValue }

    var title: String {
        switch self {
        case .atTime:
            return "At time due"
        case .fifteenMinutes:
            return "15 minutes before"
        case .thirtyMinutes:
            return "30 minutes before"
        case .oneHour:
            return "1 hour before"
        }
    }
}

private struct AtlasActionGrid: View {
    let actions: [(String, AtlasRoute)]
    let model: AtlasAppModel

    var body: some View {
        VStack(spacing: AtlasSpacing.small) {
            ForEach(Array(actions.enumerated()), id: \.element.0) { index, action in
                if index == 0 {
                    Button(action.0) {
                        model.open(action.1)
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                } else {
                    Button(action.0) {
                        model.open(action.1)
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
        }
    }
}

private struct AtlasSettingsToggleRow: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    var isEnabled: Bool = true

    var body: some View {
        Button {
            guard isEnabled else {
                return
            }
            isOn.toggle()
        } label: {
            HStack(alignment: .center, spacing: AtlasSpacing.medium) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isEnabled ? AtlasPalette.textPrimary : AtlasPalette.textSecondary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                }

                Spacer(minLength: AtlasSpacing.medium)

                AtlasSettingsSwitch(isOn: isOn, isEnabled: isEnabled)
            }
            .padding(.horizontal, AtlasSpacing.medium)
            .padding(.vertical, AtlasSpacing.small)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isEnabled
                                ? [Color.white.opacity(0.97), AtlasPalette.surfaceSecondary]
                                : [AtlasPalette.surfaceMuted.opacity(0.8), AtlasPalette.surfaceMuted.opacity(0.68)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isEnabled ? Color.white.opacity(0.82) : AtlasPalette.border.opacity(0.5), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint(isEnabled ? "Double tap to toggle." : "Unavailable in the current configuration.")
        .accessibilityAddTraits(.isButton)
    }
}

private struct AtlasSettingsSwitch: View {
    let isOn: Bool
    let isEnabled: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule(style: .continuous)
                .fill(trackColor)
                .frame(width: 58, height: 34)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(trackStroke, lineWidth: 1)
                )

            Circle()
                .fill(Color.white)
                .frame(width: 28, height: 28)
                .padding(3)
                .shadow(color: .black.opacity(isEnabled ? 0.12 : 0.04), radius: 4, x: 0, y: 2)
        }
        .animation(.spring(response: 0.22, dampingFraction: 0.82), value: isOn)
    }

    private var trackColor: Color {
        if isEnabled == false {
            return AtlasPalette.border.opacity(0.45)
        }
        return isOn ? AtlasPalette.primary : AtlasPalette.border.opacity(0.9)
    }

    private var trackStroke: Color {
        isEnabled ? Color.white.opacity(0.55) : AtlasPalette.border.opacity(0.3)
    }
}

private struct AtlasTimelineEntryCard: View {
    let model: AtlasAppModel
    let entry: AtlasTimelineEntry
    var onExplainOccurrence: (() -> Void)? = nil
    var onExplainChange: (() -> Void)? = nil

    var body: some View {
        AtlasSectionCard {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack(alignment: .top, spacing: AtlasSpacing.small) {
                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                        Text(model.renderedTitle(canonical: entry.canonicalTitle, alias: entry.aliasTitle))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(entry.summary)
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)
                        Text(entry.recordedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                    Spacer()
                    AtlasStatusBadge(entryBadgeTitle, tint: entryBadgeTint)
                }

                if onExplainOccurrence != nil || onExplainChange != nil || entry.protocolID != "insights" {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AtlasSpacing.small) {
                            if let onExplainOccurrence {
                                Button("Why this was due") { onExplainOccurrence() }
                                    .buttonStyle(AtlasChipButtonStyle())
                            }
                            if let onExplainChange {
                                Button("What changed") { onExplainChange() }
                                    .buttonStyle(AtlasChipButtonStyle())
                            }
                            if entry.protocolID != "insights" {
                                Button("Protocol") {
                                    model.open(.protocolDetail(entry.protocolID))
                                }
                                .buttonStyle(AtlasChipButtonStyle(tint: AtlasPalette.primary))
                            }
                        }
                    }
                }
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }

    private var entryBadgeTitle: String {
        switch entry.type {
        case .doseTaken:
            return "Taken"
        case .doseSkipped:
            return "Skipped"
        case .doseRescheduled:
            return "Rescheduled"
        case .protocolCreated:
            return "Created"
        case .protocolEdited:
            return "Changed"
        case .weightLogged, .symptomLogged, .customMetricLogged, .contextLogged:
            return "Logged"
        }
    }

    private var entryBadgeTint: Color {
        switch entry.type {
        case .doseTaken:
            return AtlasPalette.success
        case .doseSkipped:
            return .orange
        case .doseRescheduled:
            return .blue
        case .protocolCreated, .protocolEdited:
            return AtlasPalette.primary
        case .weightLogged, .symptomLogged, .customMetricLogged, .contextLogged:
            return AtlasPalette.textSecondary
        }
    }
}

private struct AtlasProtocolChangeExplanationCard: View {
    let title: String
    let explanation: AtlasProtocolChangeExplanation
    let onOpenDetail: () -> Void

    var body: some View {
        AtlasSectionCard {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                Text(explanation.summary)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text("Effective \(explanation.effectiveDateLabel)")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
                if let firstFact = explanation.facts.first {
                    Text("\(firstFact.label): \(firstFact.value)")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Button("Open detail") {
                    onOpenDetail()
                }
                .buttonStyle(AtlasChipButtonStyle())
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title). \(explanation.summary)")
    }
}

private struct AtlasExplanationSheet: View {
    let item: AtlasExplanationSheetItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                        Text(item.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(item.panelTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AtlasPalette.primary)
                        if let detailLine = item.detailLine {
                            Text(detailLine)
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                        Text(item.summary)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                    .padding(.vertical, AtlasSpacing.xSmall)
                }

                if item.facts.isEmpty == false {
                    Section("Deterministic facts") {
                        AtlasExplainerFactList(facts: item.facts)
                    }
                }

                if item.notes.isEmpty == false {
                    Section("Notes") {
                        ForEach(item.notes, id: \.self) { note in
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AtlasPalette.canvas)
            .navigationTitle(item.panelTitle)
            .atlasInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct AtlasExplainerFactList: View {
    let facts: [AtlasExplainerFact]

    var body: some View {
        ForEach(facts) { fact in
            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                Text(fact.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasPalette.primary)
                Text(fact.value)
                    .font(.body)
                    .foregroundStyle(AtlasPalette.textPrimary)
            }
            .padding(.vertical, 2)
        }
    }
}

private struct AtlasOccurrenceHero: View {
    let occurrence: AtlasScheduledOccurrence
    let displayTitle: String
    let onLog: (AtlasOccurrenceLogAction) -> Void
    let onOpenProtocol: () -> Void
    let onOpenChangeStudio: () -> Void
    var onExplain: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
            HStack(alignment: .center, spacing: AtlasSpacing.small) {
                AtlasStatusBadge(occurrence.state.rawValue.capitalized, tint: .white)
                AtlasStatusBadge(occurrence.kindLabel, tint: .white.opacity(0.92))
                Spacer()
                Text(occurrence.scheduledAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(.white.opacity(0.14))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                    )
            }
            Text(displayTitle)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(occurrence.cadenceLabel)
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
            if let doseLabel = occurrence.doseLabel {
                Text("Dose \(doseLabel)")
                    .foregroundStyle(.white.opacity(0.76))
            }

            VStack(spacing: AtlasSpacing.small) {
                Button("Mark taken") { onLog(.taken) }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                VStack(spacing: AtlasSpacing.small) {
                    HStack(spacing: AtlasSpacing.small) {
                        Button("Skip") { onLog(.skipped) }
                            .buttonStyle(AtlasInverseSecondaryButtonStyle())
                        Button("Reschedule") { onLog(.rescheduled) }
                            .buttonStyle(AtlasInverseSecondaryButtonStyle())
                    }

                    HStack(spacing: AtlasSpacing.small) {
                        Button("Protocol") { onOpenProtocol() }
                            .buttonStyle(AtlasInverseSecondaryButtonStyle())
                        Button("Change plan") { onOpenChangeStudio() }
                            .buttonStyle(AtlasInverseSecondaryButtonStyle())
                    }
                }
                .padding(AtlasSpacing.small)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
            }

            if let onExplain {
                Button("Why this is due") {
                    onExplain()
                }
                .buttonStyle(AtlasInverseSecondaryButtonStyle())
            }
        }
        .padding(AtlasSpacing.large)
        .background(
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AtlasPalette.shellTop, AtlasPalette.shellTopAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .fill(AtlasPalette.shellGlow.opacity(0.18))
                    .frame(width: 180, height: 180)
                    .offset(x: 54, y: -74)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: AtlasPalette.shadow.opacity(0.5), radius: 18, x: 0, y: 12)
        .accessibilityElement(children: .contain)
        .accessibilityHint("Contains quick actions for logging, protocol detail, and future change planning.")
    }
}

private struct AtlasOccurrenceRow: View {
    let occurrence: AtlasScheduledOccurrence
    let title: String
    let action: (AtlasOccurrenceLogAction) -> Void
    var onOpenChangeStudio: (() -> Void)? = nil
    var onExplain: (() -> Void)? = nil

    var body: some View {
        AtlasSectionCard(style: .elevated) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text("\(occurrence.cadenceLabel) • \(occurrence.scheduledAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
                if let doseLabel = occurrence.doseLabel {
                    Text("Dose \(doseLabel)")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AtlasSpacing.small) {
                        Button("Taken") { action(.taken) }
                            .buttonStyle(AtlasChipButtonStyle(tint: AtlasPalette.success))
                        Button("Skip") { action(.skipped) }
                            .buttonStyle(AtlasChipButtonStyle(tint: .orange))
                        Button("Reschedule") { action(.rescheduled) }
                            .buttonStyle(AtlasChipButtonStyle(tint: AtlasPalette.primary))
                        if let onOpenChangeStudio {
                            Button("Change plan") { onOpenChangeStudio() }
                                .buttonStyle(AtlasChipButtonStyle(tint: AtlasPalette.textSecondary))
                        }
                    }
                }

                if let onExplain {
                    Button("Why this is due") {
                        onExplain()
                    }
                    .buttonStyle(AtlasChipButtonStyle())
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Contains visible quick actions for taken, skip, reschedule, and change planning.")
    }
}

private struct AtlasProtocolLibraryCard: View {
    let model: AtlasAppModel
    let summary: ProtocolSummary
    let renderMode: AtlasPrivacyRenderMode
    @State private var showingCompare = false

    var body: some View {
        AtlasSectionCard(style: .elevated) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack(alignment: .firstTextBaseline) {
                    Text(model.renderedTitle(
                        canonical: summary.canonicalTitle,
                        alias: summary.aliasTitle,
                        renderMode: renderMode
                    ))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    Spacer()
                    AtlasStatusBadge(summary.status.rawValue.capitalized)
                }

                Text("\(summary.kindLabel) • \(summary.cadenceLabel)")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)

                if let doseLabel = summary.doseLabel {
                    Text("Dose: \(doseLabel)")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                if let nextDueLabel = summary.nextDueLabel {
                    Text("Next due \(nextDueLabel)")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                if let knowledge = summary.compoundKnowledge {
                    Text(knowledge.protocolSummary)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AtlasSpacing.xSmall) {
                            AtlasCompoundContextChip(label: knowledge.categoryLabel)
                            AtlasCompoundContextChip(label: knowledge.typicalCadenceLabel)
                            AtlasCompoundContextChip(label: knowledge.availabilityLabel)
                            ForEach(Array(knowledge.operationalTags.prefix(3)), id: \.self) { tag in
                                AtlasCompoundContextChip(label: tag.title)
                            }
                        }
                    }
                }

                HStack(spacing: AtlasSpacing.small) {
                    Button("Open") {
                        model.open(.protocolDetail(summary.id))
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())

                    Button("Change") {
                        model.open(.protocolChange(summary.id))
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())

                    Button("Compare") {
                        showingCompare = true
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
        }
        .sheet(isPresented: $showingCompare) {
            AtlasCompoundCompareSheet(
                protocolTitle: model.renderedTitle(
                    canonical: summary.canonicalTitle,
                    alias: summary.aliasTitle,
                    renderMode: renderMode
                ),
                protocolKind: summary.protocolKind,
                currentKnowledge: summary.compoundKnowledge
            )
        }
    }
}

private struct AtlasCompoundContextChip: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AtlasPalette.primary)
            .padding(.horizontal, AtlasSpacing.small)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(AtlasPalette.secondaryFill)
            )
    }
}

private struct AtlasCompoundCompareSheet: View {
    let protocolTitle: String
    let protocolKind: AtlasProtocolKind
    let currentKnowledge: AtlasCompoundKnowledge?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCandidateSlug = ""

    private var candidates: [AtlasCompoundKnowledge] {
        AtlasCompoundKnowledgeCatalog.compareCandidates(for: currentKnowledge, kind: protocolKind)
    }

    private var selectedCandidate: AtlasCompoundKnowledge? {
        candidates.first(where: { $0.slug == selectedCandidateSlug }) ?? candidates.first
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                        Text(protocolTitle)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AtlasPalette.textPrimary)

                        if let currentKnowledge {
                            Text(currentKnowledge.protocolSummary)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        } else {
                            Text("Atlas does not recognize this compound strongly enough yet, so compare mode is using the broader \(kindTitle.lowercased()) catalog.")
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                    .padding(.vertical, AtlasSpacing.xSmall)
                }

                if let currentKnowledge {
                    Section("Current protocol") {
                        AtlasCompoundKnowledgeSummary(knowledge: currentKnowledge)
                    }
                }

                Section("Compare against") {
                    if candidates.isEmpty {
                        Text("Atlas does not have a compare catalog for this protocol yet.")
                            .foregroundStyle(AtlasPalette.textSecondary)
                    } else {
                        Picker("Compound", selection: selectedBinding) {
                            ForEach(candidates) { candidate in
                                Text(candidate.displayName).tag(candidate.slug)
                            }
                        }

                        if let selectedCandidate {
                            AtlasCompoundKnowledgeSummary(knowledge: selectedCandidate)
                        }
                    }
                }

                if let currentKnowledge, let selectedCandidate {
                    Section("Swap guidance") {
                        AtlasCompareValueRow(
                            title: "Category",
                            currentValue: currentKnowledge.categoryLabel,
                            nextValue: selectedCandidate.categoryLabel
                        )
                        AtlasCompareValueRow(
                            title: "Cadence",
                            currentValue: currentKnowledge.typicalCadenceLabel,
                            nextValue: selectedCandidate.typicalCadenceLabel
                        )
                        AtlasCompareValueRow(
                            title: "Route",
                            currentValue: currentKnowledge.routeLabel,
                            nextValue: selectedCandidate.routeLabel
                        )
                        AtlasCompareValueRow(
                            title: "Dose units",
                            currentValue: currentKnowledge.commonDoseUnits.joined(separator: ", "),
                            nextValue: selectedCandidate.commonDoseUnits.joined(separator: ", ")
                        )
                        AtlasCompareValueRow(
                            title: "Availability",
                            currentValue: currentKnowledge.availabilityLabel,
                            nextValue: selectedCandidate.availabilityLabel
                        )
                    }

                    Section("Atlas change notes") {
                        ForEach(AtlasCompoundKnowledgeCatalog.swapGuidance(from: currentKnowledge, to: selectedCandidate), id: \.self) { note in
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Compare / swap")
            .atlasInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if selectedCandidateSlug.isEmpty {
                    selectedCandidateSlug = candidates.first?.slug ?? ""
                }
            }
        }
    }

    private var kindTitle: String {
        switch protocolKind {
        case .glp: "GLP"
        case .peptide: "Peptide"
        case .custom: "Custom"
        }
    }

    private var selectedBinding: Binding<String> {
        Binding(
            get: { selectedCandidateSlug.isEmpty ? candidates.first?.slug ?? "" : selectedCandidateSlug },
            set: { selectedCandidateSlug = $0 }
        )
    }
}

private struct AtlasCompoundKnowledgeSummary: View {
    let knowledge: AtlasCompoundKnowledge

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            Text(knowledge.displayName)
                .font(.body.weight(.semibold))
                .foregroundStyle(AtlasPalette.textPrimary)

            Text(knowledge.protocolSummary)
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)

            Text("\(knowledge.categoryLabel) • \(knowledge.routeLabel)")
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)

            Text("Typical cadence: \(knowledge.typicalCadenceLabel)")
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)

            Text("Availability: \(knowledge.availabilityLabel)")
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)

            Text("Common units: \(knowledge.commonDoseUnits.joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AtlasSpacing.xSmall) {
                    ForEach(knowledge.operationalTags, id: \.self) { tag in
                        AtlasCompoundContextChip(label: tag.title)
                    }
                }
            }
        }
        .padding(.vertical, AtlasSpacing.xSmall)
    }
}

private struct AtlasCompareValueRow: View {
    let title: String
    let currentValue: String
    let nextValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AtlasPalette.primary)
            Text("Current: \(currentValue)")
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)
            Text("Compared: \(nextValue)")
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
    }
}

private struct AtlasInlineMessage: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.red)
            .padding(AtlasSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.red.opacity(0.08))
            )
    }
}

private struct AtlasEmptyStateCard<Actions: View>: View {
    let title: String
    let message: String
    let systemImage: String
    let note: String?
    let actions: Actions

    init(
        title: String,
        message: String,
        systemImage: String = "sparkles",
        note: String? = nil,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.note = note
        self.actions = actions()
    }

    var body: some View {
        AtlasSectionCard(style: .elevated) {
            HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.98), AtlasPalette.secondaryFill],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: systemImage)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AtlasPalette.primary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.9), lineWidth: 1)
                    )
                    .shadow(color: AtlasPalette.shadow.opacity(0.16), radius: 10, x: 0, y: 6)

                VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                    if let note {
                        AtlasStatusBadge(note, tint: AtlasPalette.secondaryText)
                    }

                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)

                    Text(message)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }

            actions
        }
    }
}

private struct AtlasToolLauncherButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.98), AtlasPalette.secondaryFill],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: systemImage)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AtlasPalette.primary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.88), lineWidth: 1)
                        )

                    Spacer(minLength: AtlasSpacing.small)

                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AtlasPalette.textTertiary)
                }

                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.97), AtlasPalette.surfaceSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.88), lineWidth: 1)
            )
            .shadow(color: AtlasPalette.shadow.opacity(0.16), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

private struct AtlasLogSheetContext: Identifiable {
    let occurrence: AtlasScheduledOccurrence
    let initialAction: AtlasOccurrenceLogAction

    var id: String {
        "\(occurrence.id):\(initialAction.rawValue)"
    }
}

private struct AtlasLogSheet: View {
    let model: AtlasAppModel
    let context: AtlasLogSheetContext
    let submit: @MainActor (AtlasOccurrenceLogRequest) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var action: AtlasOccurrenceLogAction
    @State private var note: String
    @State private var rescheduledAt: Date
    @State private var siteOptions: AtlasProtocolSiteOptions?
    @State private var selectedSiteID: String?
    @State private var isSubmitting = false

    init(
        model: AtlasAppModel,
        context: AtlasLogSheetContext,
        submit: @escaping @MainActor (AtlasOccurrenceLogRequest) async -> Void
    ) {
        self.model = model
        self.context = context
        self.submit = submit
        _action = State(initialValue: context.initialAction)
        _note = State(initialValue: "")
        _rescheduledAt = State(initialValue: context.occurrence.scheduledAt.addingTimeInterval(2 * 60 * 60))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Action") {
                    Picker("Action", selection: $action) {
                        Text("Taken").tag(AtlasOccurrenceLogAction.taken)
                        Text("Skip").tag(AtlasOccurrenceLogAction.skipped)
                        Text("Reschedule").tag(AtlasOccurrenceLogAction.rescheduled)
                    }
                    .pickerStyle(.segmented)
                }

                if action == .rescheduled {
                    Section("New time") {
                        DatePicker("When", selection: $rescheduledAt)
                        Button("Later today (+2h)") {
                            rescheduledAt = model.currentDate().addingTimeInterval(2 * 60 * 60)
                        }
                        Button("Tomorrow") {
                            rescheduledAt = Calendar.current.date(byAdding: .day, value: 1, to: model.currentDate()) ?? rescheduledAt
                        }
                        Button("In 2 days") {
                            rescheduledAt = Calendar.current.date(byAdding: .day, value: 2, to: model.currentDate()) ?? rescheduledAt
                        }
                    }
                }

                if action == .taken,
                   let siteOptions,
                   siteOptions.siteTrackingEnabled,
                   siteOptions.sites.isEmpty == false {
                    Section("Site") {
                        Picker("Injection site", selection: Binding(
                            get: { selectedSiteID },
                            set: { selectedSiteID = $0 }
                        )) {
                            Text("No site").tag(Optional<String>.none)
                            ForEach(siteOptions.sites) { site in
                                let label = [site.name, site.bodyArea].compactMap { $0 }.joined(separator: " • ")
                                Text(label).tag(Optional(site.id))
                            }
                        }

                        if let suggestedSiteID = siteOptions.suggestedSiteID,
                           let suggested = siteOptions.sites.first(where: { $0.id == suggestedSiteID }) {
                            Button("Use suggested next site: \(suggested.name)") {
                                selectedSiteID = suggested.id
                            }
                        }
                    }
                }

                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical)
                }

                Section {
                    Button("Save quick log") {
                        Task { await commitQuickLog() }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                    .accessibilityIdentifier("quickLogPrimarySaveButton")
                    .disabled(isSubmitting)

                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                    .accessibilityIdentifier("quickLogSecondaryCancelButton")
                    .disabled(isSubmitting)
                }
            }
            .atlasFormSurface()
            .navigationTitle("Quick log")
            .task {
                guard action == .taken else {
                    return
                }
                siteOptions = await model.siteOptions(for: context.occurrence.protocolID)
                if selectedSiteID == nil {
                    selectedSiteID = siteOptions?.suggestedSiteID
                }
            }
            .onChange(of: action) { _, newValue in
                guard newValue == .taken else {
                    return
                }
                Task {
                    siteOptions = await model.siteOptions(for: context.occurrence.protocolID)
                    if selectedSiteID == nil {
                        selectedSiteID = siteOptions?.suggestedSiteID
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("quickLogCancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await commitQuickLog() }
                    }
                    .accessibilityIdentifier("quickLogSaveButton")
                    .disabled(isSubmitting)
                }
            }
        }
    }

    @MainActor
    private func commitQuickLog() async {
        guard isSubmitting == false else {
            return
        }
        isSubmitting = true
        await submit(
            AtlasOccurrenceLogRequest(
                occurrenceID: context.occurrence.id,
                protocolID: context.occurrence.protocolID,
                action: action,
                siteID: action == .taken ? selectedSiteID : nil,
                note: note.isEmpty ? nil : note,
                rescheduledAt: action == .rescheduled ? rescheduledAt : nil
            )
        )
        dismiss()
    }
}

private struct AtlasProtocolFormState {
    var name: String = ""
    var kind: AtlasProtocolKind = .glp
    var cadenceType: AtlasProtocolRuleType = .weekly
    var intervalDays: Int = 3
    var weekday: Int? = 1
    var defaultTimeOfDay: String = "08:00"
    var doseAmount: String = ""
    var doseUnit: String = "mg"
    var notes: String = ""

    init() {}

    init(_ draft: AtlasProtocolDraft) {
        name = draft.name
        kind = draft.kind
        cadenceType = draft.cadenceType
        intervalDays = draft.intervalDays
        weekday = draft.weekday
        defaultTimeOfDay = draft.defaultTimeOfDay ?? ""
        doseAmount = draft.doseAmount.map { String($0) } ?? ""
        doseUnit = draft.doseUnit ?? ""
        notes = draft.notes ?? ""
    }

    var domainDraft: AtlasProtocolDraft {
        AtlasProtocolDraft(
            name: name,
            kind: kind,
            cadenceType: cadenceType,
            intervalDays: intervalDays,
            weekday: weekday,
            defaultTimeOfDay: defaultTimeOfDay.isEmpty ? nil : defaultTimeOfDay,
            doseAmount: Double(doseAmount),
            doseUnit: doseUnit.isEmpty ? nil : doseUnit,
            notes: notes.isEmpty ? nil : notes
        )
    }
}

private extension AtlasProtocolEditorMode {
    var title: String {
        switch self {
        case .create: "New Protocol"
        case .edit: "Edit Protocol"
        }
    }

    var buttonTitle: String {
        switch self {
        case .create: "Create"
        case .edit: "Save"
        }
    }
}

private func weekdayName(_ weekday: Int) -> String {
    ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][weekday]
}

private func permissionLabel(_ status: AtlasNotificationAuthorizationStatus) -> String {
    switch status {
    case .notDetermined:
        return "Not requested"
    case .denied:
        return "Denied"
    case .authorized:
        return "Authorized"
    case .provisional:
        return "Provisional"
    case .ephemeral:
        return "Ephemeral"
    }
}

private extension View {
    @ViewBuilder
    func atlasInlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

extension View {
    @ViewBuilder
    func atlasRootNavigationBarHidden() -> some View {
        #if os(iOS)
        self.toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func atlasRootListSurface() -> some View {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            self
                .listStyle(.plain)
                .listRowSeparator(.hidden)
                .scrollContentBackground(.hidden)
                .contentMargins(.top, 0, for: .scrollContent)
                .contentMargins(.bottom, 0, for: .scrollContent)
                .listSectionSpacing(.custom(AtlasSpacing.medium))
                .background(AtlasAppBackground())
                .atlasRootNavigationBarHidden()
        } else {
            self
                .listStyle(.plain)
                .listRowSeparator(.hidden)
                .scrollContentBackground(.hidden)
                .background(AtlasAppBackground())
                .atlasRootNavigationBarHidden()
        }
        #else
        self
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AtlasAppBackground())
            .atlasRootNavigationBarHidden()
        #endif
    }
}

private struct AtlasRootScrollSurface<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                content
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .background(AtlasAppBackground())
        .atlasRootNavigationBarHidden()
    }
}

private struct AtlasRootSectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .tracking(0.8)
            .foregroundStyle(AtlasPalette.textTertiary)
            .textCase(.uppercase)
            .padding(.top, 6)
    }
}

struct AtlasTabHeaderAction {
    let systemImage: String
    let accessibilityLabel: String
    let accessibilityHint: String?
    let action: () -> Void
}

struct AtlasTabHeader: View {
    let title: String
    let subtitle: String
    var action: AtlasTabHeaderAction? = nil
    var fullBleed: Bool = true

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.medium) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                Text(title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .tracking(-0.5)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.76))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AtlasSpacing.small)

            if let action {
                Button(action: action.action) {
                    Image(systemName: action.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                }
                .buttonStyle(AtlasGlassButtonStyle())
                .accessibilityLabel(action.accessibilityLabel)
                .accessibilityHint(action.accessibilityHint ?? "")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .topTrailing) {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 28,
                    bottomTrailingRadius: 28,
                    topTrailingRadius: 0,
                    style: .continuous
                )
                .fill(
                    LinearGradient(
                        colors: [AtlasPalette.shellTop, AtlasPalette.shellTopAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                Circle()
                    .fill(AtlasPalette.shellGlow.opacity(0.22))
                    .frame(width: 188, height: 188)
                    .offset(x: 54, y: -92)
            }
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 28,
                bottomTrailingRadius: 28,
                topTrailingRadius: 0,
                style: .continuous
            )
            .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: AtlasPalette.shadow.opacity(0.28), radius: 18, x: 0, y: 12)
        .padding(.horizontal, fullBleed ? -20 : 0)
        .padding(.bottom, 8)
    }
}

@ViewBuilder
private func header(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
        Text(title)
            .font(.largeTitle.weight(.bold))
            .foregroundStyle(AtlasPalette.textPrimary)
        Text(subtitle)
            .font(.body)
            .foregroundStyle(AtlasPalette.textSecondary)
    }
}
