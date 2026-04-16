import AtlasDesignSystem
import AtlasDomain
import AtlasPersistence
import AtlasPrivacy
import AtlasSystem
import Observation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(PhotosUI)
import PhotosUI
#endif

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
    public var calendarSync: any CalendarSyncCoordinating
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
        calendarSync: any CalendarSyncCoordinating,
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
        self.calendarSync = calendarSync
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
    public var searchText: String
    public var renderMode: AtlasPrivacyRenderMode

    public init(
        loadErrorMessage: String? = nil,
        entries: [AtlasTimelineEntry],
        filter: AtlasTimelineFilter,
        searchText: String = "",
        renderMode: AtlasPrivacyRenderMode
    ) {
        self.loadErrorMessage = loadErrorMessage
        self.entries = entries
        self.filter = filter
        self.searchText = searchText
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
    public var calendarPermissionStatus: AtlasCalendarAuthorizationStatus
    public var availableExternalCalendars: [AtlasExternalCalendarDescriptor]
    public var retentionSnapshot: AtlasRetentionSnapshot
    public var rewardsSnapshot: AtlasRewardsSnapshot

    public init(
        settingsSnapshot: AtlasSettingsSnapshot,
        todaySnapshot: AtlasTodaySnapshot,
        reminderSettings: AtlasReminderSettingsSnapshot,
        notificationPermissionStatus: AtlasNotificationAuthorizationStatus,
        calendarPermissionStatus: AtlasCalendarAuthorizationStatus,
        availableExternalCalendars: [AtlasExternalCalendarDescriptor],
        retentionSnapshot: AtlasRetentionSnapshot,
        rewardsSnapshot: AtlasRewardsSnapshot
    ) {
        self.settingsSnapshot = settingsSnapshot
        self.todaySnapshot = todaySnapshot
        self.reminderSettings = reminderSettings
        self.notificationPermissionStatus = notificationPermissionStatus
        self.calendarPermissionStatus = calendarPermissionStatus
        self.availableExternalCalendars = availableExternalCalendars
        self.retentionSnapshot = retentionSnapshot
        self.rewardsSnapshot = rewardsSnapshot
    }
}

enum AtlasUndoOperation: Equatable {
    case deleteContextEntry(String)
    case deleteWeightEntry(String)
    case deleteSymptomEntry(String)
    case deleteMetricValueEntry(String)
    case setVialArchived(id: String, isArchived: Bool)
    case setConsumableArchived(id: String, isArchived: Bool)
}

struct AtlasUndoBannerState: Identifiable, Equatable {
    var id: String
    var title: String
    var detail: String
    var actionTitle: String
    var operation: AtlasUndoOperation

    init(
        id: String = UUID().uuidString.lowercased(),
        title: String,
        detail: String,
        actionTitle: String = "Undo",
        operation: AtlasUndoOperation
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.actionTitle = actionTitle
        self.operation = operation
    }
}

private struct AtlasMascotReturnBaseline: Equatable {
    let totalPoints: Int
    let level: Int
    let earnedBadgeCount: Int
    let strongestStreak: Int
    let activeStreakCount: Int
    let latestMomentEventKey: String?
    let archivedRecapCount: Int
    let progressPhotoCount: Int
    let progressMeasurementCount: Int

    @MainActor
    static func capture(from model: AtlasAppModel) -> Self {
        let selection = model.settingsSnapshot.mascotSelection
        return AtlasMascotReturnBaseline(
            totalPoints: model.rewardsSnapshot.totalPoints,
            level: model.rewardsSnapshot.level,
            earnedBadgeCount: model.rewardsSnapshot.badges.filter(\.isEarned).count,
            strongestStreak: model.rewardsSnapshot.streaks.filter(\.isActive).map(\.count).max() ?? 0,
            activeStreakCount: model.rewardsSnapshot.streaks.filter(\.isActive).count,
            latestMomentEventKey: model.settingsSnapshot.mascotMoments.first(where: { $0.selection == selection })?.eventKey,
            archivedRecapCount: model.settingsSnapshot.mascotArchivedRecaps.filter { $0.selection == selection }.count,
            progressPhotoCount: model.insightsSnapshot.progressEvidence.recentPhotos.count,
            progressMeasurementCount: model.insightsSnapshot.progressEvidence.recentMeasurements.count
        )
    }

    func hasMeaningfulProgress(since previous: AtlasMascotReturnBaseline) -> Bool {
        totalPoints > previous.totalPoints
            || level > previous.level
            || earnedBadgeCount > previous.earnedBadgeCount
            || strongestStreak > previous.strongestStreak
            || activeStreakCount > previous.activeStreakCount
            || archivedRecapCount > previous.archivedRecapCount
            || progressPhotoCount > previous.progressPhotoCount
            || progressMeasurementCount > previous.progressMeasurementCount
            || (latestMomentEventKey != nil && latestMomentEventKey != previous.latestMomentEventKey)
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
    public var timelineSearchText: String
    public var reminderSettings: AtlasReminderSettingsSnapshot
    public var notificationPermissionStatus: AtlasNotificationAuthorizationStatus
    public var calendarPermissionStatus: AtlasCalendarAuthorizationStatus
    public var availableExternalCalendars: [AtlasExternalCalendarDescriptor]
    public var inventorySnapshot: AtlasInventorySnapshot
    public var calculatorProfiles: [AtlasCalculatorProfileRecord]
    public var insightsSnapshot: AtlasInsightsSnapshot
    public var retentionSnapshot: AtlasRetentionSnapshot
    public var rewardsSnapshot: AtlasRewardsSnapshot
    public var trustVaultSnapshot: AtlasTrustVaultSnapshot
    public var reviewOwnerSnapshot: AtlasReviewOwnerSnapshot
    public var reviewWorkspace: AtlasReviewWorkspace?
    public var pendingMascotCelebration: AtlasMascotCelebrationState?
    var ambientMascotReactionSignal: AtlasAmbientMascotReactionSignal?
    var undoBanner: AtlasUndoBannerState?
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
    private var autoCloudSyncTask: Task<Void, Never>?
    private var timelineSearchRefreshTask: Task<Void, Never>?
    private var ambientMascotReactionCounter: Int
    private var mascotReturnBaseline: AtlasMascotReturnBaseline?

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
        let timelineSearchText = ""
        let reminderSettings = AtlasReminderSettingsSnapshot()
        let notificationPermissionStatus = AtlasNotificationAuthorizationStatus.notDetermined
        let calendarPermissionStatus = AtlasCalendarAuthorizationStatus.notDetermined
        let availableExternalCalendars: [AtlasExternalCalendarDescriptor] = []
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
            searchText: timelineSearchText,
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
            calendarPermissionStatus: calendarPermissionStatus,
            availableExternalCalendars: availableExternalCalendars,
            retentionSnapshot: retentionSnapshot,
            rewardsSnapshot: rewardsSnapshot
        )
        self.bootstrapSnapshot = bootstrapSnapshot
        self.settingsSnapshot = settingsSnapshot
        self.todaySnapshot = todaySnapshot
        self.libraryProtocols = libraryProtocols
        self.timelineEntries = timelineEntries
        self.timelineFilter = timelineFilter
        self.timelineSearchText = timelineSearchText
        self.reminderSettings = reminderSettings
        self.notificationPermissionStatus = notificationPermissionStatus
        self.calendarPermissionStatus = calendarPermissionStatus
        self.availableExternalCalendars = availableExternalCalendars
        self.inventorySnapshot = inventorySnapshot
        self.calculatorProfiles = calculatorProfiles
        self.insightsSnapshot = insightsSnapshot
        self.retentionSnapshot = retentionSnapshot
        self.rewardsSnapshot = rewardsSnapshot
        self.trustVaultSnapshot = trustVaultSnapshot
        self.reviewOwnerSnapshot = reviewOwnerSnapshot
        self.reviewWorkspace = nil
        self.pendingMascotCelebration = nil
        self.ambientMascotReactionSignal = nil
        self.undoBanner = nil
        self.cloudSession = nil
        self.cloudStatusDescription = dependencies.cloudSync.isConfigured()
            ? "Cloud sync is ready for sign-in."
            : "Cloud sync is not configured yet. The app continues to work locally."
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
        self.autoCloudSyncTask = nil
        self.timelineSearchRefreshTask = nil
        self.ambientMascotReactionCounter = 0
        self.mascotReturnBaseline = nil
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
            await syncExternalCalendarIfPossible(referenceDate: now)
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
                AtlasTimelineQuery(
                    filter: timelineFilter,
                    searchText: timelineSearchText,
                    limit: 80
                )
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
            calendarPermissionStatus = await dependencies.calendarSync.authorizationStatus()
            if calendarPermissionStatus.canListCalendars {
                do {
                    availableExternalCalendars = try await dependencies.calendarSync.listWritableCalendars()
                } catch {
                    availableExternalCalendars = []
                }
            } else {
                availableExternalCalendars = []
            }
            await processMascotEvolutionIfNeeded(referenceDate: now)
            await processMascotMomentsIfNeeded(referenceDate: now)
            await scheduleMascotRecapNotificationsIfNeeded(referenceDate: now)
            await scheduleWeeklyReviewReminderIfNeeded(referenceDate: now)
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
                AtlasTimelineQuery(
                    filter: timelineFilter,
                    searchText: timelineSearchText,
                    limit: 80
                )
            )
            syncTimelineViewState()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateTimelineSearchText(_ searchText: String) {
        timelineSearchText = searchText
        timelineViewState.searchText = searchText
        timelineSearchRefreshTask?.cancel()
        timelineSearchRefreshTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard Task.isCancelled == false, let self else {
                return
            }
            await self.refreshTimeline()
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
            queueAutomaticCloudSync(reason: "protocol creation")
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
            queueAutomaticCloudSync(reason: "protocol update")
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
            triggerAmbientMascotReaction(.logSuccess)
            queueAutomaticCloudSync(reason: "timeline logging")
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

    public func requestCalendarPermission() async {
        do {
            calendarPermissionStatus = try await dependencies.calendarSync.requestAuthorization()
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateReminderSettings(_ update: AtlasReminderPreferenceUpdate) async {
        do {
            reminderSettings = try await dependencies.reminders.updateReminderSettings(update, referenceDate: currentDate())
            await refreshShellData()
            queueAutomaticCloudSync(reason: "reminder settings")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateExternalCalendarEnabled(_ enabled: Bool) async {
        do {
            settingsSnapshot.externalCalendarSettings = try await dependencies.calendarSync.updateSettings(
                AtlasExternalCalendarSettingsUpdate(syncEnabled: enabled, clearError: true),
                referenceDate: currentDate()
            )
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateExternalCalendarSelection(_ descriptor: AtlasExternalCalendarDescriptor) async {
        do {
            settingsSnapshot.externalCalendarSettings = try await dependencies.calendarSync.updateSettings(
                AtlasExternalCalendarSettingsUpdate(
                    calendarSelection: .select(descriptor),
                    clearError: true
                ),
                referenceDate: currentDate()
            )
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func clearExternalCalendarSelection() async {
        do {
            settingsSnapshot.externalCalendarSettings = try await dependencies.calendarSync.updateSettings(
                AtlasExternalCalendarSettingsUpdate(
                    calendarSelection: .clear,
                    clearError: true
                ),
                referenceDate: currentDate()
            )
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func syncExternalCalendarNow() async {
        do {
            try await dependencies.calendarSync.sync(referenceDate: currentDate())
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updatePrivacyRenderMode(_ renderMode: AtlasPrivacyRenderMode) async {
        do {
            settingsSnapshot = try await dependencies.persistence.settings.updateTrustVaultRenderMode(renderMode, now: currentDate())
            await refreshShellData()
            queueAutomaticCloudSync(reason: "privacy mode change")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateSummarySettings(_ update: AtlasSummarySettingsUpdate) async {
        do {
            settingsSnapshot = try await dependencies.persistence.settings.updateSummarySettings(update, now: currentDate())
            await refreshShellData()
            queueAutomaticCloudSync(reason: "summary settings")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateRetentionSettings(_ update: AtlasRetentionSettingsUpdate) async {
        do {
            settingsSnapshot = try await dependencies.persistence.settings.updateRetentionSettings(update, now: currentDate())
            await refreshShellData()
            queueAutomaticCloudSync(reason: "retention settings")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateMascotSelection(_ mascotSelection: AtlasMascotSelection) async {
        do {
            settingsSnapshot = try await dependencies.persistence.settings.updateMascotSelection(mascotSelection, now: currentDate())
            await refreshShellData()
            queueAutomaticCloudSync(reason: "mascot selection")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateMascotNickname(_ nickname: String?) async {
        do {
            settingsSnapshot = try await dependencies.persistence.settings.updateMascotNickname(nickname, now: currentDate())
            await refreshShellData()
            queueAutomaticCloudSync(reason: "mascot nickname")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateAmbientMascotPresence(_ presence: AtlasAmbientMascotPresence) async {
        do {
            settingsSnapshot = try await dependencies.persistence.settings.updateAmbientMascotPresence(
                presence,
                now: currentDate()
            )
            syncShellViewStates()
            queueAutomaticCloudSync(reason: "ambient mascot presence")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateMascotRecapNotificationSettings(
        _ recapSettings: AtlasMascotRecapNotificationSettings
    ) async {
        do {
            settingsSnapshot = try await dependencies.persistence.settings.updateMascotRecapNotificationSettings(
                recapSettings,
                now: currentDate()
            )
            syncShellViewStates()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func exportMascotRecapCard(
        _ descriptor: AtlasMascotRecapDescriptor
    ) async throws -> AtlasMascotExportArtifact {
        let now = currentDate()
        let artifact = try atlasExportMascotRecapCard(
            descriptor: descriptor,
            exportedAt: now
        )
        settingsSnapshot = try await dependencies.persistence.settings.recordMascotArchivedRecap(
            artifact.archiveRecord,
            now: now
        )
        if settingsSnapshot.mascotSelectionConfirmed,
           rewardsSnapshot.settings.enabled {
            var recapMoment = atlasMascotManualMoment(
                selection: settingsSnapshot.mascotSelection,
                nickname: settingsSnapshot.mascotNickname,
                stage: atlasRewardsMascotStage(for: rewardsSnapshot),
                kind: .recapExport,
                recordedAt: now
            )
            let sourceDetail = artifact.archiveRecord.sourceMomentTitle.map { " It was pulled from \"\($0)\" in the journal." } ?? ""
            recapMoment = AtlasMascotMomentRecord(
                selection: recapMoment.selection,
                stage: recapMoment.stage,
                kind: recapMoment.kind,
                title: recapMoment.title,
                detail: "\(recapMoment.detail)\(sourceDetail)",
                symbolName: recapMoment.symbolName,
                recordedAt: recapMoment.recordedAt,
                eventKey: "recap-export-\(artifact.archiveRecord.id)",
                relatedRecapID: artifact.archiveRecord.id,
                relatedRecapKind: descriptor.kind.rawValue,
                recapHeadline: descriptor.headline
            )
            settingsSnapshot = try await dependencies.persistence.settings.recordMascotMoment(recapMoment, now: now)

            let archiveCount = settingsSnapshot.mascotArchivedRecaps.filter {
                $0.selection == settingsSnapshot.mascotSelection
            }.count
            if [1, 3, 5, 10].contains(archiveCount) {
                var archiveMoment = atlasMascotManualMoment(
                    selection: settingsSnapshot.mascotSelection,
                    nickname: settingsSnapshot.mascotNickname,
                    stage: atlasRewardsMascotStage(for: rewardsSnapshot),
                    kind: .archiveMilestone,
                    recordedAt: now
                )
                archiveMoment = AtlasMascotMomentRecord(
                    selection: archiveMoment.selection,
                    stage: archiveMoment.stage,
                    kind: archiveMoment.kind,
                    title: archiveMoment.title,
                    detail: "\(archiveMoment.detail) \(archiveCount) collectible poster\(archiveCount == 1 ? "" : "s") in the gallery.",
                    symbolName: archiveMoment.symbolName,
                    recordedAt: archiveMoment.recordedAt,
                    eventKey: "archive-\(settingsSnapshot.mascotSelection.rawValue)-\(archiveCount)",
                    relatedRecapID: artifact.archiveRecord.id,
                    relatedRecapKind: descriptor.kind.rawValue,
                    recapHeadline: descriptor.headline
                )
                settingsSnapshot = try await dependencies.persistence.settings.recordMascotMoment(
                    archiveMoment,
                    now: now
                )
            }
        }
        triggerAmbientMascotReaction(.artifactReady)
        syncShellViewStates()
        return artifact
    }

    public func recordMascotInteractionMoment(kind: AtlasMascotMomentKind = .interaction) async {
        guard settingsSnapshot.mascotSelectionConfirmed,
              rewardsSnapshot.settings.enabled else {
            return
        }

        do {
            let selection = settingsSnapshot.mascotSelection
            let stage = atlasRewardsMascotStage(for: rewardsSnapshot)
            let moment = atlasMascotManualMoment(
                selection: selection,
                nickname: settingsSnapshot.mascotNickname,
                stage: stage,
                kind: kind,
                recordedAt: currentDate()
            )
            settingsSnapshot = try await dependencies.persistence.settings.recordMascotMoment(moment, now: currentDate())
            await refreshShellData()
            triggerAmbientMascotReaction(.capturedMoment)
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func dismissMascotCelebration() {
        pendingMascotCelebration = nil
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
                try await syncHealthKitData(since: previousSyncDate)
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

    private func syncHealthKitData(since: Date?) async throws {
        let syncDate = currentDate()
        let weights = try await dependencies.healthKit.fetchWeightSamples(since: since)
        let workouts = try await dependencies.healthKit.fetchWorkouts(since: since)
        let nutrition = try await dependencies.healthKit.fetchNutritionSamples(since: since)
        let metrics = try await dependencies.healthKit.fetchMetricSamples(since: since)
        _ = try await dependencies.persistence.metrics.importWeightSamples(weights, now: syncDate)
        _ = try await dependencies.persistence.metrics.importWorkoutSamples(workouts, now: syncDate)
        _ = try await dependencies.persistence.metrics.importNutritionSamples(nutrition, now: syncDate)
        _ = try await dependencies.persistence.metrics.importHealthMetricSamples(metrics, now: syncDate)
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

    public func updateLabsEnabled(_ enabled: Bool) async {
        do {
            settingsSnapshot = try await dependencies.persistence.settings.updateLabsEnabled(enabled, now: currentDate())
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateSurfacePreferences(_ preferences: AtlasSurfacePreferences) async {
        do {
            settingsSnapshot = try await dependencies.persistence.settings.updateSurfacePreferences(
                preferences,
                now: currentDate()
            )
            syncShellViewStates()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func dismissUndoBanner() {
        undoBanner = nil
    }

    public func performUndo() async {
        guard let banner = undoBanner else {
            return
        }
        undoBanner = nil

        do {
            switch banner.operation {
            case .deleteContextEntry(let id):
                try await dependencies.persistence.metrics.deleteContextEntry(id: id)
            case .deleteWeightEntry(let id):
                try await dependencies.persistence.metrics.deleteWeightEntry(id: id)
            case .deleteSymptomEntry(let id):
                try await dependencies.persistence.metrics.deleteSymptomEntry(id: id)
            case .deleteMetricValueEntry(let id):
                try await dependencies.persistence.metrics.deleteMetricValueEntry(id: id)
            case .setVialArchived(let id, let isArchived):
                try await dependencies.persistence.inventory.setVialArchived(id: id, isArchived: isArchived, now: currentDate())
            case .setConsumableArchived(let id, let isArchived):
                try await dependencies.persistence.inventory.setConsumableArchived(id: id, isArchived: isArchived, now: currentDate())
            }
            invalidateInventoryCaches()
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    private func presentUndoBanner(_ banner: AtlasUndoBannerState?) {
        undoBanner = banner
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
            _ = try await self.runCloudSync(generatedAt: now)
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
            let momentDate = currentDate()
            retentionSnapshot = try await dependencies.persistence.retention.markWeeklyReviewComplete(now: momentDate)
            if settingsSnapshot.mascotSelectionConfirmed,
               rewardsSnapshot.settings.enabled {
                let selection = settingsSnapshot.mascotSelection
                let nickname = settingsSnapshot.mascotNickname
                let stage = atlasRewardsMascotStage(for: rewardsSnapshot)
                let moment = atlasMascotManualMoment(
                    selection: settingsSnapshot.mascotSelection,
                    nickname: settingsSnapshot.mascotNickname,
                    stage: stage,
                    kind: .weeklyCloseout,
                    recordedAt: momentDate
                )
                settingsSnapshot = try await dependencies.persistence.settings.recordMascotMoment(moment, now: momentDate)

                if let carriedFocus = settingsSnapshot.weeklyReviewActionPlans.first(where: {
                    $0.isPinnedForNextWeek && $0.isCompleted == false
                }) {
                    var focusMoment = atlasMascotManualMoment(
                        selection: selection,
                        nickname: nickname,
                        stage: stage,
                        kind: .focusCarryForward,
                        recordedAt: momentDate
                    )
                    focusMoment = AtlasMascotMomentRecord(
                        selection: focusMoment.selection,
                        stage: focusMoment.stage,
                        kind: focusMoment.kind,
                        title: focusMoment.title,
                        detail: "\(focusMoment.detail) \"\(carriedFocus.title)\" stays pinned into the new week.",
                        symbolName: focusMoment.symbolName,
                        recordedAt: focusMoment.recordedAt,
                        eventKey: "focus-carry-forward-\(selection.rawValue)-\(carriedFocus.id)"
                    )
                    settingsSnapshot = try await dependencies.persistence.settings.recordMascotMoment(
                        focusMoment,
                        now: momentDate
                    )
                }
            }
            await refreshShellData()
            triggerAmbientMascotReaction(.reviewComplete)
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
            queueAutomaticCloudSync(reason: "vial update")
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
            queueAutomaticCloudSync(reason: "supply update")
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
            queueAutomaticCloudSync(reason: "vial archive")
            presentUndoBanner(
                AtlasUndoBannerState(
                    title: "Vial archived",
                    detail: "Removed from active planning. You can restore it right away.",
                    operation: .setVialArchived(id: id, isArchived: false)
                )
            )
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func setVialArchived(id: String, isArchived: Bool) async {
        do {
            try await dependencies.persistence.inventory.setVialArchived(id: id, isArchived: isArchived, now: currentDate())
            invalidateInventoryCaches()
            await refreshShellData()
            queueAutomaticCloudSync(reason: isArchived ? "vial archive" : "vial restore")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func setConsumableArchived(id: String, isArchived: Bool) async {
        do {
            try await dependencies.persistence.inventory.setConsumableArchived(id: id, isArchived: isArchived, now: currentDate())
            invalidateInventoryCaches()
            await refreshShellData()
            queueAutomaticCloudSync(reason: isArchived ? "supply archive" : "supply restore")
            presentUndoBanner(
                AtlasUndoBannerState(
                    title: isArchived ? "Supply archived" : "Supply restored",
                    detail: isArchived
                        ? "Removed this supply from active planning."
                        : "Restored this supply to active planning.",
                    operation: .setConsumableArchived(id: id, isArchived: !isArchived)
                )
            )
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func updateProtocolInventorySettings(_ update: AtlasProtocolInventorySettingsUpdate) async {
        do {
            _ = try await dependencies.persistence.inventory.updateProtocolInventorySettings(update, now: currentDate())
            invalidateInventoryCaches()
            await refreshShellData()
            queueAutomaticCloudSync(reason: "protocol inventory settings")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func applyManualCorrection(_ correction: AtlasInventoryCorrectionDraft) async -> AtlasInventoryCorrectionResult? {
        do {
            let result = try await dependencies.persistence.inventory.applyManualCorrection(correction, now: currentDate())
            invalidateInventoryCaches()
            await refreshShellData()
            queueAutomaticCloudSync(reason: "inventory correction")
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
            queueAutomaticCloudSync(reason: "supply adjustment")
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
            queueAutomaticCloudSync(reason: "procurement history")
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
            queueAutomaticCloudSync(reason: "site update")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func saveCalculatorProfile(_ draft: AtlasCalculatorProfileDraft) async {
        do {
            _ = try await dependencies.persistence.calculator.saveProfile(draft, now: currentDate())
            await refreshShellData()
            queueAutomaticCloudSync(reason: "calculator profile")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func deleteCalculatorProfile(id: String) async {
        do {
            try await dependencies.persistence.calculator.deleteProfile(id: id)
            invalidateInventoryCaches()
            await refreshShellData()
            queueAutomaticCloudSync(reason: "calculator profile removal")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func saveContextEntry(_ draft: AtlasContextEntryDraft) async {
        do {
            let record = try await dependencies.persistence.metrics.saveContextEntry(draft, now: currentDate())
            await refreshShellData()
            triggerAmbientMascotReaction(.logSuccess)
            queueAutomaticCloudSync(reason: "context entry")
            if draft.id == nil {
                presentUndoBanner(
                    AtlasUndoBannerState(
                        title: "Context saved",
                        detail: "The new context check-in is part of your local timeline.",
                        operation: .deleteContextEntry(record.id)
                    )
                )
            }
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func saveContextPreset(_ draft: AtlasContextPresetDraft) async -> AtlasContextPresetRecord? {
        do {
            let preset = try await dependencies.persistence.metrics.saveContextPreset(draft, now: currentDate())
            await refreshShellData()
            queueAutomaticCloudSync(reason: "context preset")
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
            queueAutomaticCloudSync(reason: "context preset removal")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func saveWeightEntry(_ draft: AtlasWeightEntryDraft) async {
        do {
            let record = try await dependencies.persistence.metrics.saveWeightEntry(draft, now: currentDate())
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
            triggerAmbientMascotReaction(.logSuccess)
            queueAutomaticCloudSync(reason: "weight entry")
            if draft.id == nil {
                presentUndoBanner(
                    AtlasUndoBannerState(
                        title: "Weight logged",
                        detail: "Added the new weight entry to your trends.",
                        operation: .deleteWeightEntry(record.id)
                    )
                )
            }
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func saveSymptomEntry(_ draft: AtlasSymptomEntryDraft) async {
        do {
            let record = try await dependencies.persistence.metrics.saveSymptomEntry(draft, now: currentDate())
            await refreshShellData()
            triggerAmbientMascotReaction(.logSuccess)
            queueAutomaticCloudSync(reason: "symptom entry")
            if draft.id == nil {
                presentUndoBanner(
                    AtlasUndoBannerState(
                        title: "Symptom logged",
                        detail: "Added the symptom entry to the current review window.",
                        operation: .deleteSymptomEntry(record.id)
                    )
                )
            }
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func saveProgressMeasurement(_ draft: AtlasProgressMeasurementDraft) async {
        do {
            _ = try await dependencies.persistence.metrics.saveProgressMeasurement(draft, now: currentDate())
            await refreshShellData()
            triggerAmbientMascotReaction(.logSuccess)
            queueAutomaticCloudSync(reason: "progress measurement")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func saveProgressPhoto(_ draft: AtlasProgressPhotoDraft) async {
        do {
            _ = try await dependencies.persistence.metrics.saveProgressPhoto(draft, now: currentDate())
            await refreshShellData()
            triggerAmbientMascotReaction(.logSuccess)
            queueAutomaticCloudSync(reason: "progress photo")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func saveMetricDefinition(_ draft: AtlasMetricDefinitionDraft) async {
        do {
            _ = try await dependencies.persistence.metrics.saveMetricDefinition(draft, now: currentDate())
            await refreshShellData()
            triggerAmbientMascotReaction(.logSuccess)
            queueAutomaticCloudSync(reason: "metric definition")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func archiveMetricDefinition(id: String) async {
        do {
            try await dependencies.persistence.metrics.archiveMetricDefinition(id: id, now: currentDate())
            await refreshShellData()
            queueAutomaticCloudSync(reason: "metric archive")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func deleteMetricDefinition(id: String) async {
        do {
            try await dependencies.persistence.metrics.deleteMetricDefinition(id: id)
            await refreshShellData()
            queueAutomaticCloudSync(reason: "metric removal")
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    public func saveMetricValueEntry(_ draft: AtlasMetricValueEntryDraft) async {
        do {
            let record = try await dependencies.persistence.metrics.saveMetricValueEntry(draft, now: currentDate())
            await refreshShellData()
            triggerAmbientMascotReaction(.logSuccess)
            queueAutomaticCloudSync(reason: "metric value")
            if draft.id == nil {
                presentUndoBanner(
                    AtlasUndoBannerState(
                        title: "Metric logged",
                        detail: "Added the metric point to the current trend set.",
                        operation: .deleteMetricValueEntry(record.id)
                    )
                )
            }
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
        case "rewards":
            routePath.removeAll()
            activeTab = .today
            open(.rewards)
        case "compound-intelligence", "compoundintelligence":
            guard let slug = atlasURLValue("slug", in: query),
                  slug.isEmpty == false else {
                return
            }

            routePath.removeAll()
            activeTab = .library
            open(.compoundIntelligence(slug))
        case "watch-companion", "watchcompanion":
            routePath.removeAll()
            activeTab = .today
            open(.watchCompanion)
        case "watch-recovery", "watchrecovery":
            routePath.removeAll()
            activeTab = .today
            open(.watchCompanion)
        case "weekly-review", "weeklyreview":
            routePath.removeAll()
            activeTab = .insights
            open(.weeklyReview)
        case "progress-evidence", "progressevidence":
            routePath.removeAll()
            activeTab = .insights
            open(.progressEvidence)
        case "quick-capture", "quickcapture":
            routePath.removeAll()
            activeTab = .today
            let kind = AtlasQuickCaptureKind(
                rawValue: atlasURLValue("kind", in: query)?.lowercased() ?? ""
            ) ?? .shot
            open(.quickCapture(kind))
        case "mascot":
            routePath.removeAll()
            activeTab = .today
            open(.mascot)
        case "mascot-moment":
            routePath.removeAll()
            activeTab = .today
            let kind = AtlasMascotMomentKind(
                rawValue: atlasURLValue("kind", in: query)?.lowercased() ?? ""
            ) ?? .shortcut
            await recordMascotInteractionMoment(kind: kind)
            open(.mascot)
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
        case "context-shortcut":
            guard let shortcut = AtlasTodayContextShortcut(
                rawValue: atlasURLValue("kind", in: query) ?? ""
            ) else {
                return
            }

            routePath.removeAll()
            activeTab = .today
            await refreshShellData()

            switch shortcut.delivery {
            case .saveNow:
                await saveContextEntry(
                    shortcut.makeDraft(
                        loggedAt: atlasURLDateValue("loggedat", in: query) ?? currentDate(),
                        protocolID: atlasTodayContextProtocolID(snapshot: todaySnapshot)
                    )
                )
            case .openEditor:
                open(.watchCompanion)
            }
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

    private func runCloudSync(generatedAt: Date) async throws -> AtlasCloudSessionSnapshot {
        let export = try await dependencies.importExport.createRawExport(
            AtlasRawExportRequest(format: .json, renderMode: .full),
            now: generatedAt
        )
        let data = try Data(contentsOf: export.fileURL)
        let session = try await dependencies.cloudSync.uploadExportBundle(
            data,
            generatedAt: generatedAt,
            deviceID: dependencies.cloudSync.deviceIdentifier()
        )
        cloudSession = session
        return session
    }

    private func queueAutomaticCloudSync(reason: String) {
        guard dependencies.cloudSync.isConfigured(),
              cloudSession != nil else {
            return
        }

        autoCloudSyncTask?.cancel()
        autoCloudSyncTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard Task.isCancelled == false else {
                return
            }
            await self?.performAutomaticCloudSync(reason: reason)
        }
    }

    private func performAutomaticCloudSync(reason: String) async {
        guard cloudSession != nil,
              isPerformingCloudAction == false else {
            return
        }

        let now = currentDate()
        if let lastSyncAt = cloudSession?.lastSyncAt,
           now.timeIntervalSince(lastSyncAt) < 15 {
            return
        }

        do {
            _ = try await runCloudSync(generatedAt: now)
            await refreshCloudStatus()
        } catch {
            setLoadErrorMessage("Automatic Atlas Cloud backup failed after \(reason.lowercased()): \(error.localizedDescription)")
        }
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

    func triggerAmbientMascotReaction(_ kind: AtlasAmbientMascotReactionKind) {
        guard settingsSnapshot.ambientMascotPresence != .off else {
            return
        }
        ambientMascotReactionCounter &+= 1
        ambientMascotReactionSignal = AtlasAmbientMascotReactionSignal(
            token: ambientMascotReactionCounter,
            kind: kind
        )
    }

    func handleAppScenePhaseChange(_ phase: ScenePhase) async {
        switch phase {
        case .active:
            guard hasLoadedBootstrap else {
                return
            }

            guard bootstrapSnapshot.destination == .app, hasLoadedShellData else {
                mascotReturnBaseline = AtlasMascotReturnBaseline.capture(from: self)
                return
            }

            let previousBaseline = mascotReturnBaseline
            await refreshShellData()
            let currentBaseline = AtlasMascotReturnBaseline.capture(from: self)
            mascotReturnBaseline = currentBaseline

            guard let previousBaseline,
                  currentBaseline.hasMeaningfulProgress(since: previousBaseline) else {
                return
            }
            triggerAmbientMascotReaction(.welcomeBack)
        case .background:
            mascotReturnBaseline = AtlasMascotReturnBaseline.capture(from: self)
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    private func syncRemindersIfPossible(referenceDate: Date) async {
        do {
            try await dependencies.reminders.syncReminders(referenceDate: referenceDate)
        } catch {
            // Reminder scheduling should not block shell loading or core protocol flows.
        }
    }

    private func syncExternalCalendarIfPossible(referenceDate: Date) async {
        do {
            try await dependencies.calendarSync.sync(referenceDate: referenceDate)
        } catch {
            // Calendar mirroring should stay best-effort so Atlas remains fully usable offline.
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
        timelineViewState.searchText = timelineSearchText
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
        settingsViewState.calendarPermissionStatus = calendarPermissionStatus
        settingsViewState.availableExternalCalendars = availableExternalCalendars
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

    private func processMascotEvolutionIfNeeded(referenceDate: Date) async {
        guard settingsSnapshot.mascotSelectionConfirmed,
              rewardsSnapshot.settings.enabled else {
            return
        }

        let selection = settingsSnapshot.mascotSelection
        let evolution = atlasRewardsEvolutionProgress(for: rewardsSnapshot, selection: selection)
        let unlockedStage = settingsSnapshot.highestUnlockedStage(for: selection)

        guard evolution.stage.rank > unlockedStage.rank,
              evolution.stage != .stage1 else {
            return
        }

        do {
            let missingStages = AtlasMascotStage.allCases.filter {
                $0 != .stage1 && $0.rank > unlockedStage.rank && $0.rank <= evolution.stage.rank
            }

            for stage in missingStages {
                settingsSnapshot = try await dependencies.persistence.settings.recordMascotEvolution(
                    selection: selection,
                    stage: stage,
                    earnedAt: referenceDate,
                    now: referenceDate
                )
            }

            pendingMascotCelebration = AtlasMascotCelebrationState(
                selection: selection,
                stage: evolution.stage,
                totalPoints: rewardsSnapshot.totalPoints,
                earnedAt: referenceDate
            )
            triggerAmbientMascotReaction(.milestone)
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    private func processMascotMomentsIfNeeded(referenceDate: Date) async {
        guard settingsSnapshot.mascotSelectionConfirmed,
              rewardsSnapshot.settings.enabled else {
            return
        }

        let selection = settingsSnapshot.mascotSelection
        let candidates = atlasMascotAutomaticMomentCandidates(
            selection: selection,
            nickname: settingsSnapshot.mascotNickname,
            rewardsSnapshot: rewardsSnapshot,
            evolutionHistory: settingsSnapshot.mascotEvolutionHistory,
            archivedRecaps: settingsSnapshot.mascotArchivedRecaps,
            existingMoments: settingsSnapshot.mascotMoments,
            recordedAt: referenceDate
        )

        guard candidates.isEmpty == false else {
            return
        }

        do {
            for candidate in candidates {
                settingsSnapshot = try await dependencies.persistence.settings.recordMascotMoment(
                    candidate,
                    now: referenceDate
                )

                if let request = atlasMascotNotificationRequest(
                    for: candidate,
                    referenceDate: referenceDate
                ) {
                    _ = try? await dependencies.notifications.scheduleMascotNotification(request)
                }
            }
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    private func scheduleMascotRecapNotificationsIfNeeded(referenceDate: Date) async {
        guard settingsSnapshot.mascotSelectionConfirmed,
              rewardsSnapshot.settings.enabled else {
            return
        }

        let requests = atlasMascotTimelineNotificationRequests(
            selection: settingsSnapshot.mascotSelection,
            nickname: settingsSnapshot.mascotNickname,
            notificationSettings: settingsSnapshot.mascotRecapNotificationSettings,
            rewardsSnapshot: rewardsSnapshot,
            evolutionHistory: settingsSnapshot.mascotEvolutionHistory,
            moments: settingsSnapshot.mascotMoments,
            referenceDate: referenceDate
        )

        for request in requests {
            _ = try? await dependencies.notifications.scheduleMascotNotification(request)
        }
    }

    private func scheduleWeeklyReviewReminderIfNeeded(referenceDate: Date) async {
        let identifier = atlasWeeklyReviewReminderIdentifier()

        guard settingsSnapshot.weeklyReviewReminderSettings.enabled,
              notificationPermissionStatus != .denied,
              let weeklyReview = weeklyReviewPresentation(),
              weeklyReview.isMarkedReviewed == false else {
            try? await dependencies.notifications.cancelReminder(identifier: identifier)
            return
        }

        let request = AtlasMascotNotificationRequest(
            identifier: identifier,
            title: "Weekly Review is ready",
            body: weeklyReview.summaryText,
            triggerAt: atlasWeeklyReviewReminderTriggerDate(after: referenceDate),
            isSilent: false,
            route: "weekly-review"
        )

        _ = try? await dependencies.notifications.scheduleMascotNotification(request)
    }
}

private func atlasWeeklyReviewReminderTriggerDate(after referenceDate: Date) -> Date {
    var calendar = Calendar.current
    calendar.firstWeekday = 2

    let reviewHour = 18
    let targetWeekday = 1
    var components = DateComponents()
    components.weekday = targetWeekday
    components.hour = reviewHour
    components.minute = 0

    let candidate = calendar.nextDate(
        after: referenceDate,
        matching: components,
        matchingPolicy: .nextTime
    )

    return candidate ?? referenceDate.addingTimeInterval(86_400)
}

private func atlasWeeklyReviewReminderIdentifier() -> String {
    "atlas.weekly-review"
}

private enum AtlasCloudRestoreError: LocalizedError {
    case noBackup

    var errorDescription: String? {
        switch self {
        case .noBackup:
            return "No cloud backup was found for this account yet."
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
                        case .medicationLevels(let id):
                            AtlasMedicationLevelsScreen(model: model, protocolID: id)
                        case .compoundIntelligence(let slug):
                            AtlasCompoundIntelligenceScreen(model: model, knowledgeSlug: slug)
                        case .rewards:
                            AtlasRewardsScreen(model: model)
                        case .inventory:
                            AtlasInventoryScreen(model: model)
                        case .labs:
                            AtlasLabsScreen(model: model)
                        case .mascot:
                            AtlasMascotDetailScreen(model: model)
                        case .calculator:
                            AtlasCalculatorScreen(model: model)
                        case .trustVault:
                            AtlasTrustVaultScreen(model: model)
                        case .importFlow:
                            AtlasImportScreen(model: model)
                        case .reviewMode:
                            AtlasReviewModeScreen(model: model)
                        case .weeklyReview:
                            AtlasWeeklyReviewScreen(model: model)
                        case .progressEvidence:
                            AtlasProgressEvidenceScreen(model: model)
                        case .quickCapture(let kind):
                            AtlasQuickCaptureScreen(model: model, initialKind: kind)
                        case .watchCompanion:
                            AtlasWatchCompanionScreen(model: model)
                        case .insightsLogs:
                            AtlasInsightsLogsScreen(model: model, state: model.insightsViewState)
                        case .insightsAnalysis:
                            AtlasInsightsAnalysisScreen(model: model, state: model.insightsViewState)
                        case .settingsAccount:
                            AtlasSettingsAccountScreen(model: model, state: model.settingsViewState)
                        case .settingsPrivacy:
                            AtlasSettingsPrivacyScreen(model: model, state: model.settingsViewState)
                        case .settingsNotifications:
                            AtlasSettingsNotificationsScreen(model: model, state: model.settingsViewState)
                        case .settingsServices:
                            AtlasSettingsServicesScreen(model: model, state: model.settingsViewState)
                        case .settingsPersonalization:
                            AtlasSettingsPersonalizationScreen(model: model, state: model.settingsViewState)
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
    @Environment(\.scenePhase) private var scenePhase
    @State private var mascotFlight: AtlasAmbientMascotFlightState?
    @State private var mascotSettleTrigger = 0
    @State private var keyboardVisible = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AtlasAppBackground()

                currentScreen
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                if let mascotFlight {
                    AtlasAmbientMascotFlightOverlay(flight: mascotFlight) {
                        self.mascotFlight = nil
                    }
                }
            }
            .sheet(
                item: Binding(
                    get: { model.pendingMascotCelebration },
                    set: { value in
                        if value == nil {
                            model.dismissMascotCelebration()
                        }
                    }
                )
            ) { celebration in
                AtlasMascotCelebrationSheet(celebration: celebration) {
                    model.dismissMascotCelebration()
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if let banner = model.undoBanner {
                    AtlasUndoBanner(banner: banner) {
                        Task { await model.performUndo() }
                    } onDismiss: {
                        model.dismissUndoBanner()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AtlasBottomTabBar(
                    selection: $model.activeTab,
                    ambientMascotSelection: ambientMascotSelection,
                    ambientMascotStage: ambientMascotStage,
                    ambientMascotPresence: model.settingsSnapshot.ambientMascotPresence,
                    ambientMascotSuppression: atlasAmbientMascotSuppression(
                        presentingSheet: model.pendingMascotCelebration != nil,
                        denseEntryActive: keyboardVisible
                    ),
                    reactionSignal: model.ambientMascotReactionSignal,
                    milestoneNearby: ambientMascotMilestoneNearby,
                    settleTrigger: mascotSettleTrigger,
                    hidesAmbientMascot: mascotFlight?.destinationPlacement == .tabShelf,
                    onSelect: { tab in
                        performTabSelection(
                            tab,
                            containerSize: geometry.size,
                            safeAreaInsets: geometry.safeAreaInsets
                        )
                    }
                )
            }
            .atlasRootNavigationBarHidden()
            .onChange(of: scenePhase) { _, newPhase in
                Task {
                    await model.handleAppScenePhaseChange(newPhase)
                }
            }
            .task {
                #if canImport(UIKit)
                for await _ in NotificationCenter.default.notifications(
                    named: UIResponder.keyboardWillShowNotification
                ) {
                    guard Task.isCancelled == false else {
                        return
                    }
                    keyboardVisible = true
                }
                #endif
            }
            .task {
                #if canImport(UIKit)
                for await _ in NotificationCenter.default.notifications(
                    named: UIResponder.keyboardWillHideNotification
                ) {
                    guard Task.isCancelled == false else {
                        return
                    }
                    keyboardVisible = false
                }
                #endif
            }
        }
    }

    private var ambientMascotSelection: AtlasMascotSelection? {
        atlasAmbientMascotSelection(settingsSnapshot: model.settingsSnapshot)
    }

    private var ambientMascotStage: AtlasMascotStage? {
        atlasAmbientMascotStage(
            settingsSnapshot: model.settingsSnapshot,
            rewardsSnapshot: model.rewardsSnapshot
        )
    }

    private var ambientMascotMilestoneNearby: Bool {
        return atlasAmbientMascotMilestoneNearby(
            settingsSnapshot: model.settingsSnapshot,
            rewardsSnapshot: model.rewardsSnapshot,
            pendingCelebration: model.pendingMascotCelebration
        )
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
            AtlasInsightsScreen(
                model: model,
                state: model.insightsViewState,
                ambientMascotVisible: mascotFlight?.destinationPlacement != .cardCorner
            )
        case .settings:
            AtlasSettingsScreen(model: model, state: model.settingsViewState)
        }
    }

    private func performTabSelection(
        _ tab: AtlasTab,
        containerSize: CGSize,
        safeAreaInsets: EdgeInsets
    ) {
        guard tab != model.activeTab else {
            return
        }

        let previousTab = model.activeTab
        let flight = ambientMascotFlight(
            from: previousTab,
            to: tab,
            containerSize: containerSize,
            safeAreaInsets: safeAreaInsets
        )

        mascotFlight = flight
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            model.activeTab = tab
        }

        if flight == nil {
            mascotSettleTrigger &+= 1
        }
    }

    private func ambientMascotFlight(
        from sourceTab: AtlasTab,
        to destinationTab: AtlasTab,
        containerSize: CGSize,
        safeAreaInsets: EdgeInsets
    ) -> AtlasAmbientMascotFlightState? {
        guard sourceTab == .today,
              let ambientMascotSelection,
              let ambientMascotStage else {
            return nil
        }

        switch destinationTab {
        case .library:
            return AtlasAmbientMascotFlightState(
                selection: ambientMascotSelection,
                stage: ambientMascotStage,
                startPoint: todayMascotPoint(containerSize: containerSize, safeAreaInsets: safeAreaInsets),
                endPoint: shelfMascotPoint(
                    for: destinationTab,
                    containerSize: containerSize,
                    safeAreaInsets: safeAreaInsets
                ),
                destinationPlacement: .tabShelf
            )
        case .insights:
            return AtlasAmbientMascotFlightState(
                selection: ambientMascotSelection,
                stage: ambientMascotStage,
                startPoint: todayMascotPoint(containerSize: containerSize, safeAreaInsets: safeAreaInsets),
                endPoint: insightsMascotPoint(containerSize: containerSize, safeAreaInsets: safeAreaInsets),
                destinationPlacement: .cardCorner
            )
        default:
            return nil
        }
    }

    private func todayMascotPoint(
        containerSize: CGSize,
        safeAreaInsets: EdgeInsets
    ) -> CGPoint {
        CGPoint(
            x: containerSize.width - 76,
            y: safeAreaInsets.top + 170
        )
    }

    private func insightsMascotPoint(
        containerSize: CGSize,
        safeAreaInsets: EdgeInsets
    ) -> CGPoint {
        CGPoint(
            x: containerSize.width - 80,
            y: safeAreaInsets.top + 360
        )
    }

    private func shelfMascotPoint(
        for tab: AtlasTab,
        containerSize: CGSize,
        safeAreaInsets: EdgeInsets
    ) -> CGPoint {
        let outerPadding: CGFloat = 16
        let innerPadding: CGFloat = 10
        let totalWidth = max(containerSize.width - (outerPadding * 2), 1)
        let contentWidth = max(totalWidth - (innerPadding * 2), 1)
        let tabWidth = contentWidth / CGFloat(AtlasTab.allCases.count)
        let index = CGFloat(AtlasTab.allCases.firstIndex(of: tab) ?? 0)

        return CGPoint(
            x: outerPadding + innerPadding + (index * tabWidth) + (tabWidth / 2),
            y: containerSize.height - safeAreaInsets.bottom - 66
        )
    }
}

private struct AtlasRewardsScreen: View {
    @Bindable var model: AtlasAppModel
    @State private var mascotContentNoticeTrigger = 0
    @State private var mascotPeekTrigger = 0
    @State private var seenPeekKey: String?

    var body: some View {
        let ambientMascotSelection = atlasAmbientMascotSelection(settingsSnapshot: model.settingsSnapshot)
        let ambientMascotStage = atlasAmbientMascotStage(
            settingsSnapshot: model.settingsSnapshot,
            rewardsSnapshot: model.rewardsSnapshot
        )
        let ambientMascotMilestoneNearby = atlasAmbientMascotMilestoneNearby(
            settingsSnapshot: model.settingsSnapshot,
            rewardsSnapshot: model.rewardsSnapshot,
            pendingCelebration: model.pendingMascotCelebration
        )
        let rewardNoticeKey = atlasRewardsMascotNoticeKey(model: model)
        let rewardPeekKey = atlasRewardsMascotPeekKey(model: model)

        AtlasScreen {
            AtlasSectionCard(style: .hero) {
                Text("Rewards momentum")
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.reward)
                Text("Keep the next unlock visible.")
                    .atlasTextRole(.screenTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text("See mascot progress, badges, and the next milestone at a glance.")
                    .atlasTextRole(.screenSubtitle)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
            .overlay(alignment: .topTrailing) {
                if let ambientMascotSelection,
                   let ambientMascotStage {
                    AtlasAmbientMascotPerch(
                        selection: ambientMascotSelection,
                        stage: ambientMascotStage,
                        presence: model.settingsSnapshot.ambientMascotPresence,
                        placement: .cardCorner,
                        context: .rewardsHero,
                        size: 62,
                        contentNoticeTrigger: mascotContentNoticeTrigger,
                        peekTrigger: mascotPeekTrigger,
                        suppression: atlasAmbientMascotSuppression(
                            presentingSheet: model.pendingMascotCelebration != nil
                        ),
                        reactionSignal: model.ambientMascotReactionSignal,
                        milestoneNearby: ambientMascotMilestoneNearby
                    )
                    .offset(x: -12, y: -10)
                }
            }

            VStack(alignment: .leading, spacing: AtlasSpacing.large) {
                AtlasRewardsTodayCard(
                    snapshot: model.rewardsSnapshot,
                    mascotSelection: model.settingsSnapshot.mascotSelection,
                    mascotNickname: model.settingsSnapshot.mascotNickname,
                    mascotHistory: model.settingsSnapshot.mascotEvolutionHistory
                )

                AtlasMascotHomeCard(
                    selection: model.settingsSnapshot.mascotSelection,
                    nickname: model.settingsSnapshot.mascotNickname,
                    rewardsSnapshot: model.rewardsSnapshot,
                    history: model.settingsSnapshot.mascotEvolutionHistory,
                    moments: model.settingsSnapshot.mascotMoments,
                    compact: false,
                    onOpenDetail: {
                        model.open(.mascot)
                    }
                )
            }
        }
        .navigationTitle("Rewards")
        .navigationBarTitleDisplayMode(.inline)
        .atlasAmbientMascotOpenReaction(model: model, kind: .openedRewards)
        .onChange(of: rewardNoticeKey) { oldValue, newValue in
            guard oldValue != newValue else {
                return
            }
            mascotContentNoticeTrigger &+= 1
        }
        .onAppear {
            guard let rewardPeekKey,
                  seenPeekKey != rewardPeekKey else {
                return
            }
            seenPeekKey = rewardPeekKey
            mascotPeekTrigger &+= 1
        }
        .onChange(of: rewardPeekKey) { oldValue, newValue in
            guard oldValue != newValue,
                  let newValue,
                  seenPeekKey != newValue else {
                return
            }
            seenPeekKey = newValue
            mascotPeekTrigger &+= 1
        }
    }
}

@MainActor
private func atlasRewardsMascotNoticeKey(model: AtlasAppModel) -> String {
    let selection = model.settingsSnapshot.mascotSelection
    let latestMomentKey = model.settingsSnapshot.mascotMoments.first {
        $0.selection == selection
    }?.eventKey ?? "none"
    let archivedCount = model.settingsSnapshot.mascotArchivedRecaps.filter {
        $0.selection == selection
    }.count

    return [
        selection.rawValue,
        "\(model.rewardsSnapshot.totalPoints)",
        "\(model.rewardsSnapshot.level)",
        "\(model.rewardsSnapshot.badges.filter(\.isEarned).count)",
        "\(archivedCount)",
        latestMomentKey
    ].joined(separator: "|")
}

@MainActor
private func atlasRewardsMascotPeekKey(model: AtlasAppModel) -> String? {
    let selection = model.settingsSnapshot.mascotSelection
    let evolution = atlasRewardsEvolutionProgress(for: model.rewardsSnapshot, selection: selection)

    if evolution.nextFormName == nil {
        return "final_form"
    }

    if (evolution.progressFraction ?? 0) >= 0.86 {
        return "near_unlock_\(evolution.stageBadge)"
    }

    if model.rewardsSnapshot.badges.contains(where: \.isEarned) == false {
        return "empty_badges"
    }

    return nil
}

private struct AtlasUndoBanner: View {
    let banner: AtlasUndoBannerState
    let onUndo: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.small) {
            VStack(alignment: .leading, spacing: 4) {
                Text(banner.title)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(banner.detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
            Spacer(minLength: 12)
            Button(banner.actionTitle, action: onUndo)
                .buttonStyle(AtlasTertiaryButtonStyle())
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 11, height: 11)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(AtlasSpacing.small)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AtlasPalette.surfaceTop.opacity(0.96), AtlasPalette.surfaceSecondary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AtlasPalette.chromeStroke, lineWidth: 1)
        )
        .shadow(color: AtlasPalette.shadow.opacity(0.18), radius: 14, x: 0, y: 10)
    }
}

private struct AtlasBottomTabBar: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var selection: AtlasTab
    let ambientMascotSelection: AtlasMascotSelection?
    let ambientMascotStage: AtlasMascotStage?
    let ambientMascotPresence: AtlasAmbientMascotPresence
    let ambientMascotSuppression: AtlasAmbientMascotSuppression
    let reactionSignal: AtlasAmbientMascotReactionSignal?
    let milestoneNearby: Bool
    let settleTrigger: Int
    let hidesAmbientMascot: Bool
    let onSelect: (AtlasTab) -> Void

    var body: some View {
        HStack(spacing: dynamicTypeSize.isAccessibilitySize ? 4 : AtlasSpacing.xSmall) {
            ForEach(AtlasTab.allCases) { tab in
                let isSelected = selection == tab

                Button {
                    onSelect(tab)
                } label: {
                    VStack(spacing: dynamicTypeSize.isAccessibilitySize ? 5 : 7) {
                        Image(systemName: tab.systemImage)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: dynamicTypeSize.isAccessibilitySize ? 16 : 18,
                                height: dynamicTypeSize.isAccessibilitySize ? 16 : 18
                            )
                            .symbolVariant(isSelected ? .fill : .none)
                        Text(tab.title)
                            .font(tabLabelFont)
                            .tracking(dynamicTypeSize.isAccessibilitySize ? 0.08 : 0)
                            .lineLimit(1)
                            .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 0.58 : 0.75)
                            .allowsTightening(true)
                    }
                    .foregroundStyle(isSelected ? AtlasPalette.primary : AtlasPalette.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 10 : 11)
                    .padding(.horizontal, dynamicTypeSize.isAccessibilitySize ? 1 : 4)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                isSelected
                                    ? AnyShapeStyle(
                                        LinearGradient(
                                            colors: [AtlasPalette.surfaceTop, AtlasPalette.secondaryFill],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    : AnyShapeStyle(Color.clear)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isSelected ? AtlasPalette.chromeStroke : Color.clear, lineWidth: 1)
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
        .padding(.horizontal, dynamicTypeSize.isAccessibilitySize ? 6 : 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AtlasPalette.surfaceTop.opacity(0.95), AtlasPalette.surfaceSecondary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AtlasPalette.chromeStroke, lineWidth: 1)
        )
        .shadow(color: AtlasPalette.shadow.opacity(0.34), radius: 22, x: 0, y: 16)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color.clear.ignoresSafeArea(edges: .bottom))
    }

    private var tabLabelFont: Font {
        if dynamicTypeSize.isAccessibilitySize {
            return .system(size: 11, weight: .semibold, design: .rounded)
        }

        return .system(size: 12, weight: .semibold, design: .rounded)
    }

}

public struct AtlasTodayScreen: View {
    let model: AtlasAppModel
    let state: AtlasTodayViewState
    @State private var sheetContext: AtlasLogSheetContext?
    @State private var explanationSheet: AtlasExplanationSheetItem?
    @State private var contextEditor = AtlasContextEditorState(referenceDate: Date())
    @State private var contextSheetPresented = false
    @State private var queueExpanded = false
    @State private var commandDeckCourtesySignal = 0

    public var body: some View {
        let weeklyReview = model.weeklyReviewPresentation()
        let guidance = atlasTodayGuidancePresentation(
            todaySnapshot: state.todaySnapshot,
            weeklyReviewSeed: weeklyReview?.seed,
            actionPlans: weeklyReview?.actionPlans ?? []
        )
        let recovery = atlasTodayRecoveryPresentation(
            todaySnapshot: state.todaySnapshot,
            weeklyReviewSeed: weeklyReview?.seed,
            actionPlans: weeklyReview?.actionPlans ?? []
        )

        AtlasRootScrollSurface {
            AtlasTabHeader(
                title: "Today",
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

            AtlasTodayCommandDeck(
                presentation: atlasTodayCommandDeckPresentation(
                    model: model,
                    state: state,
                    weeklyReview: weeklyReview
                ),
                courtesySignal: commandDeckCourtesySignal,
                onNearbyInteraction: {
                    commandDeckCourtesySignal &+= 1
                },
                suppression: atlasAmbientMascotSuppression(
                    presentingSheet: contextSheetPresented
                        || explanationSheet != nil
                        || model.pendingMascotCelebration != nil,
                    denseEntryActive: sheetContext != nil
                ),
                action: performTodayCommand
            )

            if let nextDue = state.todaySnapshot.nextDue {
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
                    message: "",
                    systemImage: "checkmark.circle",
                    note: nil,
                    titleLineLimit: 1
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

            let featuredCard = atlasTodayFeaturedCard(
                preferences: model.settingsSnapshot.surfacePreferences,
                guidance: guidance,
                recovery: recovery,
                weeklyReview: weeklyReview,
                rewardsEnabled: state.rewardsSnapshot.settings.enabled,
                continuityEnabled: state.retentionSnapshot.settings.progressEnabled,
                shouldPromptForMascot: atlasShouldPromptForMascotConfirmation(
                    bootstrapSnapshot: model.bootstrapSnapshot,
                    settingsSnapshot: model.settingsSnapshot
                )
            )

            if let featuredCard {
                AtlasRootSectionHeader(featuredCard.title)
                todayLandingCard(
                    featuredCard,
                    guidance: guidance,
                    recovery: recovery,
                    weeklyReview: weeklyReview
                )
            }

            let secondaryModules = atlasTodaySecondaryModules(
                preferences: model.settingsSnapshot.surfacePreferences,
                excluding: featuredCard,
                weeklyReview: weeklyReview,
                rewardsEnabled: state.rewardsSnapshot.settings.enabled,
                continuityEnabled: state.retentionSnapshot.settings.progressEnabled,
                shouldPromptForMascot: atlasShouldPromptForMascotConfirmation(
                    bootstrapSnapshot: model.bootstrapSnapshot,
                    settingsSnapshot: model.settingsSnapshot
                )
            )

            if secondaryModules.isEmpty == false {
                AtlasRootSectionHeader("More today")
                AtlasTodayWorkspaceCard(
                    modules: secondaryModules,
                    onSelect: performTodayWorkspaceModule
                )
            }

            if state.todaySnapshot.overdue.isEmpty == false || state.todaySnapshot.upcoming.isEmpty == false {
                AtlasRootSectionHeader("Queue")
                AtlasTodayQueueOverviewCard(
                    model: model,
                    state: state,
                    isExpanded: $queueExpanded,
                    onSelectOccurrence: { occurrence, action in
                        sheetContext = AtlasLogSheetContext(occurrence: occurrence, initialAction: action)
                    },
                    onOpenChangeStudio: { protocolID in
                        model.open(.protocolChange(protocolID))
                    },
                    onExplain: { occurrence in
                        guard let explanation = occurrence.explanation else {
                            return
                        }
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
                )
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

    @ViewBuilder
    private func todayLandingCard(
        _ card: AtlasTodayLandingCard,
        guidance: AtlasTodayGuidancePresentation?,
        recovery: AtlasTodayRecoveryPresentation?,
        weeklyReview: AtlasWeeklyReviewPresentation?
    ) -> some View {
        switch card {
        case .guidance:
            if let guidance {
                AtlasTodayGuidanceCard(
                    guidance: guidance,
                    primaryAction: {
                        performTodayGuidanceAction(guidance.primaryAction)
                    },
                    secondaryAction: { action in
                        performTodayGuidanceAction(action)
                    }
                )
            }
        case .recovery:
            if let recovery {
                AtlasTodayRecoveryCard(
                    recovery: recovery,
                    primaryAction: {
                        performTodayGuidanceAction(recovery.primaryAction)
                    },
                    secondaryAction: recovery.secondaryAction.map { action in
                        {
                            performTodayGuidanceAction(action)
                        }
                    }
                )
            }
        case .quickCapture:
            if state.todaySnapshot.hasProtocols {
                AtlasTodayQuickCaptureCard(model: model, state: state)
            }
        case .quickContext:
            if state.todaySnapshot.hasProtocols {
                AtlasTodayContextQuickCard(
                    model: model,
                    defaultProtocolID: atlasTodayContextProtocolID(snapshot: state.todaySnapshot),
                    onTriggerShortcut: { shortcut in
                        performTodayContextShortcut(shortcut)
                    },
                    onOpenDetailedCapture: {
                        contextEditor = atlasTodayContextEditorState(
                            shortcut: nil,
                            referenceDate: model.currentDate(),
                            protocolID: atlasTodayContextProtocolID(snapshot: state.todaySnapshot)
                        )
                        contextSheetPresented = true
                    }
                )
            }
        case .weeklyFocus:
            if let weeklyReview,
               weeklyReview.actionPlans.isEmpty == false || weeklyReview.actions.isEmpty == false {
                AtlasWeeklyFocusTodaySection(model: model)
            }
        case .watchCompanion:
            if state.todaySnapshot.hasProtocols {
                AtlasSectionCard(style: .utility, title: "Wrist-ready handoff") {
                    Text("Keep next due, recovery handling, and quick context close through App Shortcuts and the focused watch companion surface.")
                        .foregroundStyle(AtlasPalette.textSecondary)

                    HStack(spacing: AtlasSpacing.small) {
                        AtlasStatusBadge("Next due")
                        AtlasStatusBadge("Recovery", tint: AtlasPalette.warning)
                        AtlasStatusBadge("Quick context", tint: AtlasPalette.secondaryText)
                    }

                    Button("Open Apple Watch companion") {
                        model.open(.watchCompanion)
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
        case .mascot:
            if atlasShouldPromptForMascotConfirmation(
                bootstrapSnapshot: model.bootstrapSnapshot,
                settingsSnapshot: model.settingsSnapshot
            ) {
                AtlasMascotConfirmationCard(
                    bootstrapReason: model.bootstrapSnapshot.reason,
                    currentSelection: model.settingsSnapshot.mascotSelection
                ) { selection in
                    Task { await model.updateMascotSelection(selection) }
                }
            } else if state.rewardsSnapshot.settings.enabled {
                AtlasMascotHomeCard(
                    selection: model.settingsSnapshot.mascotSelection,
                    nickname: model.settingsSnapshot.mascotNickname,
                    rewardsSnapshot: state.rewardsSnapshot,
                    history: model.settingsSnapshot.mascotEvolutionHistory,
                    moments: model.settingsSnapshot.mascotMoments,
                    compact: true,
                    onOpenDetail: {
                        model.open(.mascot)
                    }
                )
            }
        case .rewards:
            if state.rewardsSnapshot.settings.enabled {
                AtlasRewardsTodayCard(
                    snapshot: state.rewardsSnapshot,
                    mascotSelection: model.settingsSnapshot.mascotSelection,
                    mascotNickname: model.settingsSnapshot.mascotNickname,
                    mascotHistory: model.settingsSnapshot.mascotEvolutionHistory
                )
            }
        case .calmContinuity:
            if state.retentionSnapshot.settings.progressEnabled {
                AtlasRetentionTodayCard(
                    model: model,
                    snapshot: state.retentionSnapshot,
                    mascotSelection: model.settingsSnapshot.mascotSelection
                )
            }
        }
    }

    private func performTodayGuidanceAction(_ action: AtlasTodayGuidanceAction) {
        switch action.destination {
        case .protocolDetail(let id):
            model.open(.protocolDetail(id))
        case .protocolChange(let id):
            model.open(.protocolChange(id))
        case .weeklyReview:
            model.open(.weeklyReview)
        case .library:
            model.activeTab = .library
        case .contextShortcut(let shortcut):
            performTodayContextShortcut(shortcut)
        case .detailedContext(let shortcut):
            contextEditor = atlasTodayContextEditorState(
                shortcut: shortcut,
                referenceDate: model.currentDate(),
                protocolID: atlasTodayContextProtocolID(snapshot: state.todaySnapshot)
            )
            contextSheetPresented = true
        }
    }

    private func performTodayContextShortcut(_ shortcut: AtlasTodayContextShortcut) {
        switch shortcut.delivery {
        case .saveNow:
            Task {
                await model.saveContextEntry(
                    shortcut.makeDraft(
                        loggedAt: model.currentDate(),
                        protocolID: atlasTodayContextProtocolID(snapshot: state.todaySnapshot)
                    )
                )
            }
        case .openEditor:
            contextEditor = atlasTodayContextEditorState(
                shortcut: shortcut,
                referenceDate: model.currentDate(),
                protocolID: atlasTodayContextProtocolID(snapshot: state.todaySnapshot)
            )
            contextSheetPresented = true
        }
    }

    private func performTodayCommand(_ destination: AtlasTodayCommandDestination) {
        AtlasFeedback.selection()

        switch destination {
        case .createProtocol:
            model.open(.protocolCreate)
        case .importFlow:
            model.open(.importFlow)
        case .quickCapture(let kind):
            model.open(.quickCapture(kind))
        case .library:
            model.activeTab = .library
        case .insights:
            model.activeTab = .insights
        case .weeklyReview:
            model.routePath.removeAll()
            model.activeTab = .insights
            model.open(.weeklyReview)
        case .protocolDetail(let id):
            model.open(.protocolDetail(id))
        }
    }

    private func performTodayWorkspaceModule(_ module: AtlasTodayWorkspaceModule) {
        AtlasFeedback.selection()

        switch module {
        case .quickContext:
            contextEditor = atlasTodayContextEditorState(
                shortcut: nil,
                referenceDate: model.currentDate(),
                protocolID: atlasTodayContextProtocolID(snapshot: state.todaySnapshot)
            )
            contextSheetPresented = true
        case .weeklyFocus:
            model.routePath.removeAll()
            model.activeTab = .insights
            model.open(.weeklyReview)
        case .watchCompanion:
            model.open(.watchCompanion)
        case .mascot:
            model.open(.mascot)
        case .rewards:
            model.open(.rewards)
        case .calmContinuity:
            model.activeTab = .settings
            model.open(.settingsPersonalization)
        }
    }
}

private enum AtlasTodayWorkspaceModule: Identifiable {
    case quickContext
    case weeklyFocus
    case watchCompanion
    case mascot
    case rewards
    case calmContinuity

    var id: String { title }

    var title: String {
        switch self {
        case .quickContext: return "Quick context"
        case .weeklyFocus: return "Weekly focus"
        case .watchCompanion: return "Watch companion"
        case .mascot: return "Mascot"
        case .rewards: return "Rewards"
        case .calmContinuity: return "Calm continuity"
        }
    }

    var detail: String {
        switch self {
        case .quickContext: return "Open a more detailed context capture draft."
        case .weeklyFocus: return "Carry weekly priorities into the next move."
        case .watchCompanion: return "Keep the wrist-ready handoff nearby."
        case .mascot: return "Open the current mascot line and archive."
        case .rewards: return "See streaks, targets, and the next unlock."
        case .calmContinuity: return "Adjust continuity and companion surfaces."
        }
    }

    var symbolName: String {
        switch self {
        case .quickContext: return "drop.fill"
        case .weeklyFocus: return "calendar.badge.clock"
        case .watchCompanion: return "applewatch"
        case .mascot: return "sparkles.rectangle.stack"
        case .rewards: return "sparkles"
        case .calmContinuity: return "leaf.circle"
        }
    }

    var tint: Color {
        switch self {
        case .rewards, .mascot:
            return AtlasPalette.reward
        default:
            return AtlasPalette.primary
        }
    }
}

private enum AtlasTodayCommandDestination {
    case createProtocol
    case importFlow
    case quickCapture(AtlasQuickCaptureKind)
    case library
    case insights
    case weeklyReview
    case protocolDetail(String)
}

private func atlasTodayFeaturedCard(
    preferences: AtlasSurfacePreferences,
    guidance: AtlasTodayGuidancePresentation?,
    recovery: AtlasTodayRecoveryPresentation?,
    weeklyReview: AtlasWeeklyReviewPresentation?,
    rewardsEnabled: Bool,
    continuityEnabled: Bool,
    shouldPromptForMascot: Bool
) -> AtlasTodayLandingCard? {
    preferences.visibleTodayCards.first { card in
        switch card {
        case .guidance:
            return guidance != nil
        case .recovery:
            return recovery != nil
        case .quickCapture, .quickContext:
            return true
        case .weeklyFocus:
            return weeklyReview.map { $0.actionPlans.isEmpty == false || $0.actions.isEmpty == false } ?? false
        case .watchCompanion:
            return false
        case .mascot:
            return shouldPromptForMascot || rewardsEnabled
        case .rewards:
            return rewardsEnabled
        case .calmContinuity:
            return continuityEnabled
        }
    }
}

private func atlasTodaySecondaryModules(
    preferences: AtlasSurfacePreferences,
    excluding featuredCard: AtlasTodayLandingCard?,
    weeklyReview: AtlasWeeklyReviewPresentation?,
    rewardsEnabled: Bool,
    continuityEnabled: Bool,
    shouldPromptForMascot: Bool
) -> [AtlasTodayWorkspaceModule] {
    preferences.visibleTodayCards.compactMap { card in
        guard card != featuredCard else {
            return nil
        }

        switch card {
        case .quickContext:
            return .quickContext
        case .weeklyFocus:
            return weeklyReview.map { $0.actionPlans.isEmpty == false || $0.actions.isEmpty == false } == true ? .weeklyFocus : nil
        case .watchCompanion:
            return .watchCompanion
        case .mascot:
            return shouldPromptForMascot || rewardsEnabled ? .mascot : nil
        case .rewards:
            return rewardsEnabled ? .rewards : nil
        case .calmContinuity:
            return continuityEnabled ? .calmContinuity : nil
        case .guidance, .recovery, .quickCapture:
            return nil
        }
    }
}

private struct AtlasTodayCommandDeckPresentation {
    let eyebrow: String?
    let title: String
    let detail: String?
    let metrics: [AtlasMetricItem]
    let primaryTitle: String
    let primaryAction: AtlasTodayCommandDestination
    let secondaryTitle: String?
    let secondaryAction: AtlasTodayCommandDestination?
    let rewardProgress: Double?
    let rewardDetail: String?
    let rewardHeadline: String?
    let rewardBadge: String?
    let rewardTint: Color?
    let ambientMascotSelection: AtlasMascotSelection?
    let ambientMascotStage: AtlasMascotStage?
    let ambientMascotPresence: AtlasAmbientMascotPresence
    let ambientMascotReactionSignal: AtlasAmbientMascotReactionSignal?
    let ambientMascotMilestoneNearby: Bool
}

@MainActor
private func atlasTodayCommandDeckPresentation(
    model: AtlasAppModel,
    state: AtlasTodayViewState,
    weeklyReview: AtlasWeeklyReviewPresentation?
) -> AtlasTodayCommandDeckPresentation {
    let snapshot = state.todaySnapshot
    let ambientMascotSelection = atlasAmbientMascotSelection(settingsSnapshot: model.settingsSnapshot)
    let ambientMascotStage = atlasAmbientMascotStage(
        settingsSnapshot: model.settingsSnapshot,
        rewardsSnapshot: state.rewardsSnapshot
    )
    let ambientMascotMilestoneNearby = atlasAmbientMascotMilestoneNearby(
        settingsSnapshot: model.settingsSnapshot,
        rewardsSnapshot: state.rewardsSnapshot,
        pendingCelebration: model.pendingMascotCelebration
    )
    let rewardEvolution = atlasRewardsEvolutionProgress(
        for: state.rewardsSnapshot,
        selection: model.settingsSnapshot.mascotSelection
    )
    var metrics: [AtlasMetricItem] = [
        .init(
            id: "overdue",
            title: "Overdue",
            value: "\(snapshot.overdue.count)",
            tint: snapshot.overdue.isEmpty ? AtlasPalette.secondaryText : AtlasPalette.warning
        ),
        .init(
            id: "upcoming",
            title: "Upcoming",
            value: "\(snapshot.upcoming.count)",
            tint: AtlasPalette.secondaryText
        )
    ]

    if snapshot.nextDue != nil {
        metrics.insert(
            .init(id: "due", title: "Due now", value: "1", tint: AtlasPalette.primary),
            at: 0
        )
    }

    if state.rewardsSnapshot.settings.enabled {
        metrics.append(
            .init(
                id: "points",
                title: "Points",
                value: "\(state.rewardsSnapshot.totalPoints)",
                tint: AtlasPalette.reward
            )
        )
    } else if let weeklyReview, weeklyReview.actionPlans.isEmpty == false {
        metrics.append(
            .init(
                id: "focus",
                title: "Saved focus",
                value: "\(weeklyReview.actionPlans.count)",
                tint: AtlasPalette.primary
            )
        )
    }

    if snapshot.hasProtocols == false {
        return AtlasTodayCommandDeckPresentation(
            eyebrow: nil,
            title: "Build your first active protocol.",
            detail: nil,
            metrics: metrics,
            primaryTitle: "Create protocol",
            primaryAction: .createProtocol,
            secondaryTitle: "Import Atlas data",
            secondaryAction: .importFlow,
            rewardProgress: nil,
            rewardDetail: nil,
            rewardHeadline: nil,
            rewardBadge: nil,
            rewardTint: nil,
            ambientMascotSelection: ambientMascotSelection,
            ambientMascotStage: ambientMascotStage,
            ambientMascotPresence: model.settingsSnapshot.ambientMascotPresence,
            ambientMascotReactionSignal: model.ambientMascotReactionSignal,
            ambientMascotMilestoneNearby: ambientMascotMilestoneNearby
        )
    }

    if let overdue = snapshot.overdue.first {
        return AtlasTodayCommandDeckPresentation(
            eyebrow: "Needs attention",
            title: "Clear the oldest visible dose first.",
            detail: nil,
            metrics: metrics,
            primaryTitle: "Open shot capture",
            primaryAction: .quickCapture(.shot),
            secondaryTitle: weeklyReview.map { _ in "Open weekly review" } ?? "Open protocol",
            secondaryAction: weeklyReview.map { _ in .weeklyReview } ?? .protocolDetail(overdue.protocolID),
            rewardProgress: atlasTodayRewardProgress(snapshot: state.rewardsSnapshot),
            rewardDetail: atlasTodayRewardDetail(snapshot: state.rewardsSnapshot),
            rewardHeadline: atlasTodayRewardHeadline(snapshot: state.rewardsSnapshot, evolution: rewardEvolution),
            rewardBadge: atlasTodayRewardBadge(snapshot: state.rewardsSnapshot, evolution: rewardEvolution),
            rewardTint: state.rewardsSnapshot.settings.enabled ? atlasMascotLineTint(for: model.settingsSnapshot.mascotSelection) : nil,
            ambientMascotSelection: ambientMascotSelection,
            ambientMascotStage: ambientMascotStage,
            ambientMascotPresence: model.settingsSnapshot.ambientMascotPresence,
            ambientMascotReactionSignal: model.ambientMascotReactionSignal,
            ambientMascotMilestoneNearby: ambientMascotMilestoneNearby
        )
    }

    if let nextDue = snapshot.nextDue {
        return AtlasTodayCommandDeckPresentation(
            eyebrow: "Next anchor",
            title: "Your next scheduled action is visible.",
            detail: "\(model.renderedTitle(canonical: nextDue.canonicalTitle, alias: nextDue.aliasTitle, renderMode: state.renderMode)) is due \(nextDue.scheduledAt.formatted(date: .omitted, time: .shortened)).",
            metrics: metrics,
            primaryTitle: "Open shot capture",
            primaryAction: .quickCapture(.shot),
            secondaryTitle: weeklyReview.map { _ in "Open weekly review" } ?? "Open protocol",
            secondaryAction: weeklyReview.map { _ in .weeklyReview } ?? .protocolDetail(nextDue.protocolID),
            rewardProgress: atlasTodayRewardProgress(snapshot: state.rewardsSnapshot),
            rewardDetail: atlasTodayRewardDetail(snapshot: state.rewardsSnapshot),
            rewardHeadline: atlasTodayRewardHeadline(snapshot: state.rewardsSnapshot, evolution: rewardEvolution),
            rewardBadge: atlasTodayRewardBadge(snapshot: state.rewardsSnapshot, evolution: rewardEvolution),
            rewardTint: state.rewardsSnapshot.settings.enabled ? atlasMascotLineTint(for: model.settingsSnapshot.mascotSelection) : nil,
            ambientMascotSelection: ambientMascotSelection,
            ambientMascotStage: ambientMascotStage,
            ambientMascotPresence: model.settingsSnapshot.ambientMascotPresence,
            ambientMascotReactionSignal: model.ambientMascotReactionSignal,
            ambientMascotMilestoneNearby: ambientMascotMilestoneNearby
        )
    }

    return AtlasTodayCommandDeckPresentation(
        eyebrow: nil,
        title: "Today is caught up.",
        detail: nil,
        metrics: metrics,
        primaryTitle: "Open Library",
        primaryAction: .library,
        secondaryTitle: weeklyReview.map { _ in "Open weekly review" } ?? "Open Insights",
        secondaryAction: weeklyReview.map { _ in .weeklyReview } ?? .insights,
        rewardProgress: atlasTodayRewardProgress(snapshot: state.rewardsSnapshot),
        rewardDetail: atlasTodayRewardDetail(snapshot: state.rewardsSnapshot),
        rewardHeadline: atlasTodayRewardHeadline(snapshot: state.rewardsSnapshot, evolution: rewardEvolution),
        rewardBadge: atlasTodayRewardBadge(snapshot: state.rewardsSnapshot, evolution: rewardEvolution),
        rewardTint: state.rewardsSnapshot.settings.enabled ? atlasMascotLineTint(for: model.settingsSnapshot.mascotSelection) : nil,
        ambientMascotSelection: ambientMascotSelection,
        ambientMascotStage: ambientMascotStage,
        ambientMascotPresence: model.settingsSnapshot.ambientMascotPresence,
        ambientMascotReactionSignal: model.ambientMascotReactionSignal,
        ambientMascotMilestoneNearby: ambientMascotMilestoneNearby
    )
}

private func atlasTodayRewardProgress(snapshot: AtlasRewardsSnapshot) -> Double? {
    guard snapshot.settings.enabled, snapshot.nextLevelPoints > 0 else {
        return nil
    }
    return min(max(Double(snapshot.totalPoints) / Double(snapshot.nextLevelPoints), 0), 1)
}

private func atlasTodayRewardDetail(snapshot: AtlasRewardsSnapshot) -> String? {
    guard snapshot.settings.enabled else {
        return nil
    }
    let remaining = max(snapshot.nextLevelPoints - snapshot.totalPoints, 0)
    return remaining == 0
        ? "Level \(snapshot.level) reached. The next milestone is ready."
        : "Next level in progress."
}

private func atlasTodayRewardHeadline(
    snapshot: AtlasRewardsSnapshot,
    evolution: AtlasMascotEvolutionProgress
) -> String? {
    guard snapshot.settings.enabled else {
        return nil
    }

    if let nextFormName = evolution.nextFormName,
       let nextThresholdPoints = evolution.nextThresholdPoints {
        let remainingFormPoints = max(nextThresholdPoints - snapshot.totalPoints, 0)
        if remainingFormPoints == 0 || (evolution.progressFraction ?? 0) >= 0.86 {
            return "\(nextFormName) is close enough that one more honest win could unlock it."
        }
        return "\(remainingFormPoints) more points unlock \(nextFormName)."
    }

    return "\(evolution.currentFormName) is fully evolved."
}

private func atlasTodayRewardBadge(
    snapshot: AtlasRewardsSnapshot,
    evolution: AtlasMascotEvolutionProgress
) -> String? {
    guard snapshot.settings.enabled else {
        return nil
    }

    if evolution.nextFormName == nil {
        return "Final form"
    }

    if (evolution.progressFraction ?? 0) >= 0.86 {
        return "Near unlock"
    }

    if max(snapshot.nextLevelPoints - snapshot.totalPoints, 0) == 0 {
        return "Level ready"
    }

    return "In motion"
}

private struct AtlasTodayCommandDeck: View {
    let presentation: AtlasTodayCommandDeckPresentation
    let courtesySignal: Int
    let onNearbyInteraction: () -> Void
    let suppression: AtlasAmbientMascotSuppression
    let action: (AtlasTodayCommandDestination) -> Void
    @State private var mascotContentNoticeTrigger = 0
    @State private var mascotPeekTrigger = 0
    @State private var seenPeekKey: String?

    var body: some View {
        AtlasCommandDeck(
            eyebrow: presentation.eyebrow,
            title: presentation.title,
            detail: presentation.detail,
            metrics: presentation.metrics,
            tint: AtlasPalette.primary,
            style: .task
        ) {
            VStack(spacing: AtlasSpacing.small) {
                Button(presentation.primaryTitle) {
                    onNearbyInteraction()
                    action(presentation.primaryAction)
                }
                .buttonStyle(AtlasPrimaryButtonStyle())

                if let secondaryTitle = presentation.secondaryTitle,
                   let secondaryAction = presentation.secondaryAction {
                    Button(secondaryTitle) {
                        onNearbyInteraction()
                        action(secondaryAction)
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
        } footer: {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                if let rewardProgress = presentation.rewardProgress,
                   let rewardDetail = presentation.rewardDetail {
                    AtlasProgressMeter(
                        title: "Momentum",
                        detail: rewardDetail,
                        value: rewardProgress,
                        tint: AtlasPalette.reward
                    )
                }

                if let rewardHeadline = presentation.rewardHeadline {
                    AtlasMilestoneRevealBanner(
                        eyebrow: "Next unlock",
                        title: rewardHeadline,
                        detail: presentation.rewardDetail ?? "Keep the next reward threshold visible.",
                        tint: presentation.rewardTint ?? AtlasPalette.reward,
                        badge: presentation.rewardBadge,
                        symbolName: "sparkles"
                    )
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if let ambientMascotSelection = presentation.ambientMascotSelection,
               let ambientMascotStage = presentation.ambientMascotStage {
                AtlasAmbientMascotPerch(
                    selection: ambientMascotSelection,
                    stage: ambientMascotStage,
                    presence: presentation.ambientMascotPresence,
                    placement: .cardCorner,
                    context: .todayCommandDeck,
                    size: 66,
                    courtesySignal: courtesySignal,
                    contentNoticeTrigger: mascotContentNoticeTrigger,
                    peekTrigger: mascotPeekTrigger,
                    suppression: suppression,
                    reactionSignal: presentation.ambientMascotReactionSignal,
                    milestoneNearby: presentation.ambientMascotMilestoneNearby
                )
                .offset(x: -14, y: -12)
            }
        }
        .onAppear {
            guard let mascotPeekKey,
                  seenPeekKey != mascotPeekKey else {
                return
            }
            seenPeekKey = mascotPeekKey
            mascotPeekTrigger &+= 1
        }
        .onChange(of: mascotNoticeKey) { oldValue, newValue in
            guard oldValue != newValue else {
                return
            }
            mascotContentNoticeTrigger &+= 1
        }
        .onChange(of: mascotPeekKey) { oldValue, newValue in
            guard oldValue != newValue,
                  let newValue,
                  seenPeekKey != newValue else {
                return
            }
            seenPeekKey = newValue
            mascotPeekTrigger &+= 1
        }
    }

    private var mascotNoticeKey: String {
        [
            presentation.eyebrow ?? "none",
            presentation.title,
            presentation.primaryTitle,
            presentation.secondaryTitle ?? "none",
            presentation.rewardHeadline ?? "none",
            presentation.rewardBadge ?? "none",
            presentation.rewardDetail ?? "none"
        ].joined(separator: "|")
    }

    private var mascotPeekKey: String? {
        switch presentation.primaryAction {
        case .createProtocol:
            return "empty_protocol"
        case .library:
            return "caught_up"
        case .importFlow,
             .quickCapture(_),
             .insights,
             .weeklyReview,
             .protocolDetail(_):
            break
        }

        guard let rewardBadge = presentation.rewardBadge else {
            return nil
        }
        switch rewardBadge {
        case "Near unlock", "Level ready", "Final form":
            return "reward_\(rewardBadge)"
        default:
            return nil
        }
    }
}

private struct AtlasTodayWorkspaceCard: View {
    let modules: [AtlasTodayWorkspaceModule]
    let onSelect: (AtlasTodayWorkspaceModule) -> Void

    var body: some View {
        AtlasSectionCard(style: .utility) {
            VStack(spacing: AtlasSpacing.small) {
                ForEach(modules) { module in
                    Button {
                        onSelect(module)
                    } label: {
                        HStack(alignment: .center, spacing: AtlasSpacing.small) {
                            Image(systemName: module.symbolName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(module.tint)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(module.tint.opacity(0.12))
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(module.title)
                                    .atlasTextRole(.cardBody)
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Text(module.detail)
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(AtlasPalette.textTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AtlasSpacing.medium)
                        .padding(.vertical, AtlasSpacing.small)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(AtlasPalette.secondaryFill)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct AtlasTodayQueueOverviewCard: View {
    let model: AtlasAppModel
    let state: AtlasTodayViewState
    @Binding var isExpanded: Bool
    let onSelectOccurrence: (AtlasScheduledOccurrence, AtlasOccurrenceLogAction) -> Void
    let onOpenChangeStudio: (String) -> Void
    let onExplain: (AtlasScheduledOccurrence) -> Void

    var body: some View {
        let overdue = state.todaySnapshot.overdue
        let upcoming = state.todaySnapshot.upcoming
        let visibleOverdue = isExpanded ? overdue : Array(overdue.prefix(1))
        let visibleUpcoming = isExpanded ? upcoming : Array(upcoming.prefix(1))

        AtlasSectionCard(style: .utility) {
            AtlasMetricStrip(metrics: [
                AtlasMetricItem(
                    id: "today_overdue",
                    title: "Overdue",
                    value: "\(overdue.count)",
                    tint: overdue.isEmpty ? AtlasPalette.secondaryText : AtlasPalette.warning
                ),
                AtlasMetricItem(
                    id: "today_upcoming",
                    title: "Later",
                    value: "\(upcoming.count)",
                    tint: AtlasPalette.secondaryText
                )
            ])

            if visibleOverdue.isEmpty == false {
                queueSection(title: "Overdue", tint: AtlasPalette.warning, occurrences: visibleOverdue)
            }

            if visibleUpcoming.isEmpty == false {
                queueSection(title: "Later today", tint: AtlasPalette.secondaryText, occurrences: visibleUpcoming)
            }

            if overdue.count + upcoming.count > visibleOverdue.count + visibleUpcoming.count {
                Button(isExpanded ? "Show only the next items" : "Show the full visible queue") {
                    AtlasFeedback.selection()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                        isExpanded.toggle()
                    }
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
            }
        }
    }

    @ViewBuilder
    private func queueSection(
        title: String,
        tint: Color,
        occurrences: [AtlasScheduledOccurrence]
    ) -> some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            Text(title)
                .atlasTextRole(.deckEyebrow)
                .foregroundStyle(tint)

            ForEach(occurrences) { occurrence in
                AtlasOccurrenceRow(
                    occurrence: occurrence,
                    title: model.renderedTitle(
                        canonical: occurrence.canonicalTitle,
                        alias: occurrence.aliasTitle,
                        renderMode: state.renderMode
                    ),
                    action: { action in
                        onSelectOccurrence(occurrence, action)
                    },
                    onOpenChangeStudio: {
                        onOpenChangeStudio(occurrence.protocolID)
                    },
                    onExplain: occurrence.explanation.map { _ in
                        { onExplain(occurrence) }
                    }
                )
            }
        }
    }
}

private struct AtlasTodayQuickCaptureCard: View {
    let model: AtlasAppModel
    let state: AtlasTodayViewState

    var body: some View {
        let recommendation = atlasTodayQuickCaptureRecommendation(model: model, state: state)
        let secondaryKinds = atlasTodayQuickCaptureSecondaryKinds(excluding: recommendation.kind)
        let statusBadges = atlasTodayQuickCaptureStatusBadges(model: model)

        AtlasSectionCard(style: .hero) {
            VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    Text(recommendation.eyebrow)
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(recommendation.tint)

                    Text(recommendation.title)
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(AtlasPalette.textPrimary)

                    if let detail = recommendation.detail {
                        Text(detail)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    HStack(spacing: AtlasSpacing.small) {
                        AtlasStatusBadge(recommendation.statusLabel, tint: recommendation.tint)
                        if let supportLabel = recommendation.supportLabel {
                            AtlasStatusBadge(supportLabel, tint: AtlasPalette.secondaryText)
                        }
                    }
                }

                Button(recommendation.buttonTitle) {
                    AtlasFeedback.selection()
                    model.open(.quickCapture(recommendation.kind))
                }
                .buttonStyle(AtlasPrimaryButtonStyle())

                if statusBadges.isEmpty == false {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AtlasSpacing.small) {
                            ForEach(statusBadges) { badge in
                                AtlasStatusBadge(badge.title, tint: badge.tint)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                    Text("Fast follow-ups")
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.primary)

                    AtlasTodayQuickCaptureGrid {
                        ForEach(secondaryKinds, id: \.self) { kind in
                            AtlasTodayQuickCaptureTile(kind: kind) {
                                model.open(.quickCapture(kind))
                            }
                        }
                    }
                }

                if let nextDue = state.todaySnapshot.nextDue {
                    Divider()
                    AtlasCalloutRow(
                        systemImage: "clock.badge.checkmark",
                        title: model.renderedTitle(
                            canonical: nextDue.canonicalTitle,
                            alias: nextDue.aliasTitle,
                            renderMode: state.renderMode
                        ),
                        detail: "\(atlasTodayActionTitle(for: nextDue)) • \(nextDue.scheduledAt.formatted(date: .omitted, time: .shortened))",
                        tint: recommendation.kind == .shot ? recommendation.tint : AtlasPalette.primary,
                        badge: recommendation.kind == .shot ? "Current anchor" : "Still visible"
                    )
                }
            }
        }
    }
}

private struct AtlasTodayQuickCaptureBadge: Identifiable {
    let title: String
    let tint: Color

    var id: String { title }
}

private struct AtlasTodayQuickCaptureRecommendation {
    let kind: AtlasQuickCaptureKind
    let eyebrow: String
    let title: String
    let detail: String?
    let statusLabel: String
    let supportLabel: String?
    let tint: Color

    var buttonTitle: String {
        switch kind {
        case .shot:
            return "Open shot capture"
        case .weight:
            return "Log today's weight"
        case .symptom:
            return "Capture a symptom"
        case .context:
            return "Open context capture"
        case .hydration:
            return "Log hydration"
        case .protein:
            return "Log protein meal"
        case .progressPhoto:
            return "Open progress evidence"
        }
    }
}

@MainActor
private func atlasTodayQuickCaptureRecommendation(
    model: AtlasAppModel,
    state: AtlasTodayViewState
) -> AtlasTodayQuickCaptureRecommendation {
    let calendar = Calendar.current

    if let overdue = state.todaySnapshot.overdue.first {
        return AtlasTodayQuickCaptureRecommendation(
            kind: .shot,
            eyebrow: "Recommended next",
            title: "Clear the oldest visible dose first.",
            detail: nil,
            statusLabel: "Overdue now",
            supportLabel: overdue.scheduledAt.formatted(date: .abbreviated, time: .shortened),
            tint: .orange
        )
    }

    if let nextDue = state.todaySnapshot.nextDue {
        return AtlasTodayQuickCaptureRecommendation(
            kind: .shot,
            eyebrow: "Recommended next",
            title: "Start with the next scheduled shot.",
            detail: nil,
            statusLabel: "Due \(nextDue.scheduledAt.formatted(date: .omitted, time: .shortened))",
            supportLabel: nextDue.kindLabel,
            tint: AtlasPalette.primary
        )
    }

    if let latestWeight = model.insightsSnapshot.recentWeightEntries.first,
       calendar.isDateInToday(latestWeight.loggedAt) == false {
        return AtlasTodayQuickCaptureRecommendation(
            kind: .weight,
            eyebrow: "Recommended next",
            title: "Keep today's weight trend current.",
            detail: nil,
            statusLabel: "Last logged \(latestWeight.loggedAt.formatted(date: .abbreviated, time: .omitted))",
            supportLabel: latestWeight.valueLabel,
            tint: AtlasPalette.primary
        )
    }

    if model.insightsSnapshot.recentSymptomEntries.first.map({ calendar.isDateInToday($0.loggedAt) }) != true {
        let latestSymptom = model.insightsSnapshot.recentSymptomEntries.first
        return AtlasTodayQuickCaptureRecommendation(
            kind: .symptom,
            eyebrow: "Recommended next",
            title: "Capture the clearest symptom signal.",
            detail: nil,
            statusLabel: latestSymptom.map { "\($0.symptomKey.capitalized) • \($0.severity)/5" } ?? "No symptom check-in yet",
            supportLabel: latestSymptom.map { $0.loggedAt.formatted(date: .abbreviated, time: .omitted) },
            tint: AtlasPalette.secondaryText
        )
    }

    if let latestPhoto = model.insightsSnapshot.progressEvidence.recentPhotos.first {
        let daysSincePhoto = calendar.dateComponents([.day], from: latestPhoto.loggedAt, to: model.currentDate()).day ?? 0
        if daysSincePhoto >= 14 {
            return AtlasTodayQuickCaptureRecommendation(
                kind: .progressPhoto,
                eyebrow: "Recommended next",
                title: "Match another progress frame.",
                detail: nil,
                statusLabel: "Last \(latestPhoto.angle.title.lowercased()) frame \(daysSincePhoto)d ago",
                supportLabel: latestPhoto.loggedAt.formatted(date: .abbreviated, time: .omitted),
                tint: AtlasPalette.secondaryText
            )
        }
    } else {
        return AtlasTodayQuickCaptureRecommendation(
            kind: .progressPhoto,
            eyebrow: "Recommended next",
            title: "Start a visual baseline now.",
            detail: nil,
            statusLabel: "No photo baseline yet",
            supportLabel: "Private and local-first",
            tint: AtlasPalette.secondaryText
        )
    }

    return AtlasTodayQuickCaptureRecommendation(
        kind: .hydration,
        eyebrow: "Recommended next",
        title: "Close the loop with a lightweight context check-in.",
        detail: nil,
        statusLabel: model.insightsSnapshot.contextTrend.latestLabel ?? "No context logged yet",
        supportLabel: "One tap from Today",
        tint: AtlasPalette.primary
    )
}

private func atlasTodayQuickCaptureSecondaryKinds(excluding recommendedKind: AtlasQuickCaptureKind) -> [AtlasQuickCaptureKind] {
    [AtlasQuickCaptureKind.shot, .weight, .symptom, .hydration]
        .filter { $0 != recommendedKind }
}

@MainActor
private func atlasTodayQuickCaptureStatusBadges(model: AtlasAppModel) -> [AtlasTodayQuickCaptureBadge] {
    var badges: [AtlasTodayQuickCaptureBadge] = []

    if let weight = model.insightsSnapshot.recentWeightEntries.first {
        badges.append(.init(title: "Weight \(weight.valueLabel)", tint: AtlasPalette.primary))
    }

    if let symptom = model.insightsSnapshot.recentSymptomEntries.first {
        badges.append(.init(title: "\(symptom.symptomKey.capitalized) \(symptom.severity)/5", tint: AtlasPalette.secondaryText))
    }

    if let photo = model.insightsSnapshot.progressEvidence.recentPhotos.first {
        badges.append(.init(title: "\(photo.angle.title) photo \(photo.loggedAt.formatted(date: .abbreviated, time: .omitted))", tint: AtlasPalette.secondaryText))
    }

    return badges
}

private struct AtlasTodayQuickCaptureGrid<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: AtlasSpacing.small), GridItem(.flexible(), spacing: AtlasSpacing.small)],
            spacing: AtlasSpacing.small
        ) {
            content()
        }
    }
}

private struct AtlasTodayQuickCaptureTile: View {
    let kind: AtlasQuickCaptureKind
    let action: () -> Void

    var body: some View {
        Button {
            AtlasFeedback.selection()
            action()
        } label: {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                Image(systemName: kind.systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(AtlasPalette.primary.opacity(0.88), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text(kind.title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)

                Text(subtitle)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AtlasSpacing.medium)
        }
        .buttonStyle(AtlasTactileTileButtonStyle())
    }

    private var subtitle: String {
        switch kind {
        case .shot: "Clear the visible dose first."
        case .weight: "Add today's trend anchor."
        case .symptom: "Capture one bounded signal fast."
        case .context: "Save meal and surrounding context."
        case .hydration: "One-tap surrounding context."
        case .protein: "Log a protein-forward meal context."
        case .progressPhoto: "Refresh the visual story."
        }
    }
}

private struct AtlasTodayContextQuickCard: View {
    let model: AtlasAppModel
    let defaultProtocolID: String?
    let onTriggerShortcut: (AtlasTodayContextShortcut) -> Void
    let onOpenDetailedCapture: () -> Void
    @State private var quickMealText = ""
    @State private var selectedMealPhoto: PhotosPickerItem?
    @State private var mealPhotoPreviewData = Data()
    @State private var mealPhotoAnalysisState: AtlasImageAnalysisState = .idle

    var body: some View {
        let presets = model.contextQuickPresets(limit: 3)
        let recentMeals = model.recentMealQuickItems(limit: 3)
        let nutritionTargets = model.insightsSnapshot.nutritionSnapshot.dailyTargets
        let featuredFoods = model.nutritionFeaturedLookupItems(limit: 4)
        let textSuggestion = model.nutritionQuickCaptureSuggestion(
            for: quickMealText,
            loggedAt: model.currentDate()
        )

        AtlasSectionCard(style: .utility) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                Text(
                    model.insightsSnapshot.savedContextPresets.isEmpty
                        ? "Capture meals, hydration, and surrounding context without leaving Today."
                        : "Favorites and repeat meals now live here too for faster nutrition logging."
                )
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                AtlasTodayContextShortcutRail(shortcuts: AtlasTodayContextShortcut.allCases) { shortcut in
                    onTriggerShortcut(shortcut)
                }

                if defaultProtocolID != nil {
                    Text("New Today captures will attach to the current visible plan until you choose a different context path.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                TextField("Type or dictate a meal", text: $quickMealText, axis: .vertical)
                    .atlasStandaloneInputSurface()

                PhotosPicker(selection: $selectedMealPhoto, matching: .images) {
                    AtlasMealPhotoPickerLabel(helperText: mealPhotoHelperText)
                }
                .buttonStyle(.plain)

                if mealPhotoPreviewData.isEmpty == false {
                    AtlasInlinePhotoPreview(data: mealPhotoPreviewData, height: 168)
                }

                if case let .ready(summary) = mealPhotoAnalysisState {
                    Text(summary)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else if case let .failed(message) = mealPhotoAnalysisState {
                    Text(message)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(.orange)
                }

                if let textSuggestion {
                    AtlasNutritionSuggestionButton(
                        suggestion: textSuggestion,
                        buttonTitle: "Log parsed meal"
                    ) {
                        var draft = textSuggestion.draft
                        draft.protocolID = defaultProtocolID
                        if let note = draft.note, quickMealText.isEmpty == false, note == textSuggestion.draft.note {
                            draft.note = note
                        }
                        Task { await model.saveContextEntry(draft) }
                        quickMealText = ""
                    }
                } else if quickMealText.isEmpty == false {
                    Text("No structured meal match yet. Use a lookup suggestion below.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                if nutritionTargets.isEmpty == false {
                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                        Text("Today's nutrition targets")
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.primary)

                        ForEach(nutritionTargets) { target in
                            HStack(spacing: AtlasSpacing.small) {
                                Text(target.title)
                                    .atlasTextRole(.supporting)
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
                    var draft = preset.makeDraft(loggedAt: model.currentDate())
                    draft.protocolID = defaultProtocolID
                    Task { await model.saveContextEntry(draft) }
                }

                if recentMeals.isEmpty == false {
                    AtlasRecentMealQuickRail(items: recentMeals) { item in
                        var draft = item.draft(loggedAt: model.currentDate())
                        if draft.protocolID == nil {
                            draft.protocolID = defaultProtocolID
                        }
                        Task { await model.saveContextEntry(draft) }
                    }
                }

                AtlasNutritionLookupRail(
                    title: "Common foods",
                    items: featuredFoods
                ) { item in
                    var draft = item.makeDraft(loggedAt: model.currentDate())
                    draft.protocolID = defaultProtocolID
                    Task { await model.saveContextEntry(draft) }
                }

                Button("Log with notes or more detail") {
                    onOpenDetailedCapture()
                }
                .buttonStyle(AtlasSecondaryButtonStyle())

                if model.insightsSnapshot.savedContextPresets.isEmpty {
                    Text("Use Insights to save your own favorites once you find repeats worth keeping.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    Text("Use Insights to refine favorites, reuse recent meals, add notes, or capture fuller meal detail.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
        }
        .task(id: selectedMealPhoto) {
            guard let selectedMealPhoto else {
                return
            }
            mealPhotoAnalysisState = .loading
            guard let data = try? await selectedMealPhoto.loadTransferable(type: Data.self),
                  let jpegData = atlasNormalizedJPEGData(from: data) else {
                mealPhotoAnalysisState = .failed("Couldn't read that photo. Try a brighter image or type the meal instead.")
                return
            }

            mealPhotoPreviewData = jpegData
            if let suggestion = await atlasMealPhotoSuggestion(from: jpegData, loggedAt: model.currentDate()) {
                quickMealText = [suggestion.title, suggestion.subtitle].joined(separator: " ")
                mealPhotoAnalysisState = .ready(suggestion.helperText)
            } else {
                mealPhotoAnalysisState = .failed("Couldn't find a confident meal structure from that photo yet.")
            }
        }
    }

    private var mealPhotoHelperText: String {
        switch mealPhotoAnalysisState {
        case .idle:
            return "Use OCR and image cues to prefill a meal instead of typing."
        case .loading:
            return "Reading the label and plate."
        case let .ready(summary):
            return summary
        case let .failed(message):
            return message
        }
    }
}

@MainActor
private struct AtlasMealPhotoPickerLabel: View {
    let helperText: String

    var body: some View {
        HStack(spacing: AtlasSpacing.small) {
            Image(systemName: "camera.viewfinder")
                .foregroundStyle(AtlasPalette.primary)
            VStack(alignment: .leading, spacing: 4) {
                Text("Analyze meal photo")
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(helperText)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
            Spacer()
        }
        .padding(AtlasSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AtlasPalette.surfacePrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.55), lineWidth: 1)
        )
    }
}

public struct AtlasQuickCaptureScreen: View {
    static let supportedKinds: [AtlasQuickCaptureKind] = [
        .shot,
        .weight,
        .symptom,
        .hydration,
        .protein,
        .progressPhoto
    ]

    let model: AtlasAppModel
    let initialKind: AtlasQuickCaptureKind

    @State private var selectedKind: AtlasQuickCaptureKind
    @State private var weightValue = ""
    @State private var weightUnit: AtlasWeightUnit = .lb
    @State private var symptomKey = "Nausea"
    @State private var symptomSeverity = 3
    @State private var symptomNote = ""
    @State private var mascotCourtesySignal = 0
    @State private var mascotSettleTrigger = 0

    public init(model: AtlasAppModel, initialKind: AtlasQuickCaptureKind) {
        self.model = model
        self.initialKind = initialKind
        _selectedKind = State(initialValue: initialKind)
    }

    public var body: some View {
        AtlasRootScrollSurface {
            AtlasTabHeader(
                title: "Quick Capture",
                subtitle: nil
            )

            AtlasSectionCard(style: .utility) {
                VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                    Text("Capture focus")
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.primary)

                    AtlasQuickCaptureFocusRail(
                        selectedKind: selectedKind,
                        onSelect: {
                            mascotCourtesySignal &+= 1
                            selectedKind = $0
                        }
                    )
                }
            }

            AtlasQuickCaptureLaneSummaryCard(model: model, kind: selectedKind)
                .overlay(alignment: .topTrailing) {
                    if let ambientMascotSelection = atlasAmbientMascotSelection(settingsSnapshot: model.settingsSnapshot),
                       let ambientMascotStage = atlasAmbientMascotStage(
                           settingsSnapshot: model.settingsSnapshot,
                           rewardsSnapshot: model.rewardsSnapshot
                       ) {
                        AtlasAmbientMascotPerch(
                            selection: ambientMascotSelection,
                            stage: ambientMascotStage,
                            presence: model.settingsSnapshot.ambientMascotPresence,
                            placement: .cardCorner,
                            context: .neutralCard,
                            size: 58,
                            settleTrigger: mascotSettleTrigger,
                            courtesySignal: mascotCourtesySignal,
                            suppression: atlasAmbientMascotSuppression(
                                presentingSheet: model.pendingMascotCelebration != nil,
                                denseEntryActive: {
                                    switch selectedKind {
                                    case .weight, .symptom, .context, .hydration, .protein:
                                        return true
                                    case .shot, .progressPhoto:
                                        return false
                                    }
                                }()
                            ),
                            reactionSignal: model.ambientMascotReactionSignal,
                            milestoneNearby: atlasAmbientMascotMilestoneNearby(
                                settingsSnapshot: model.settingsSnapshot,
                                rewardsSnapshot: model.rewardsSnapshot,
                                pendingCelebration: model.pendingMascotCelebration
                            )
                        )
                        .offset(x: -12, y: -10)
                    }
                }
                .id(selectedKind)

            switch selectedKind {
            case .shot:
                AtlasQuickCaptureShotCard(model: model)
            case .weight:
                AtlasQuickCaptureWeightCard(
                    model: model,
                    weightValue: $weightValue,
                    weightUnit: $weightUnit
                )
            case .symptom:
                AtlasQuickCaptureSymptomCard(
                    model: model,
                    symptomKey: $symptomKey,
                    symptomSeverity: $symptomSeverity,
                    symptomNote: $symptomNote
                )
            case .context, .hydration, .protein:
                AtlasQuickCaptureContextCard(model: model, kind: selectedKind)
            case .progressPhoto:
                AtlasQuickCaptureProgressCard(model: model)
            }
        }
        .navigationTitle("Quick Capture")
        .navigationBarTitleDisplayMode(.inline)
        .atlasKeyboardDoneAccessory()
        .animation(.spring(response: 0.24, dampingFraction: 0.84), value: selectedKind)
        .atlasAmbientMascotOpenReaction(model: model, kind: .openedSurface)
        .onChange(of: selectedKind) { _, _ in
            mascotSettleTrigger &+= 1
        }
    }
}

private struct AtlasQuickCaptureFocusRail: View {
    let selectedKind: AtlasQuickCaptureKind
    let onSelect: (AtlasQuickCaptureKind) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AtlasSpacing.small) {
                ForEach(AtlasQuickCaptureScreen.supportedKinds) { kind in
                    Button {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
                            onSelect(kind)
                        }
                    } label: {
                        Label(kind.title, systemImage: kind.systemImage)
                    }
                    .buttonStyle(AtlasTagButtonStyle(isActive: selectedKind == kind))
                }
            }
        }
    }
}

private struct AtlasQuickCaptureLaneSummaryCard: View {
    let model: AtlasAppModel
    let kind: AtlasQuickCaptureKind

    var body: some View {
        AtlasSectionCard(style: .hero) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack(spacing: AtlasSpacing.small) {
                    AtlasStatusBadge(primaryBadge, tint: tint)
                    if let secondaryBadge {
                        AtlasStatusBadge(secondaryBadge, tint: AtlasPalette.secondaryText)
                    }
                }

                Text(title)
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)

                if let detail {
                    Text(detail)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
        }
    }

    private var title: String {
        switch kind {
        case .shot:
            return model.todaySnapshot.nextDue == nil
                ? "Use this lane when the protocol loop needs a clean close."
                : "Clear the visible dose before the rest of the day gets noisy."
        case .weight:
            return "Log today's weight."
        case .symptom:
            return "Choose one signal, describe it calmly, and move on."
        case .context:
            return "Open the richer context surface when one tap is not enough."
        case .hydration:
            return "This is the fastest way to add surrounding context without friction."
        case .protein:
            return "Keep the nutrition loop light by logging the clearest protein moment."
        case .progressPhoto:
            return "Matched visual check-ins are what make before-and-after feel believable."
        }
    }

    private var detail: String? {
        switch kind {
        case .shot:
            return nil
        case .weight:
            return nil
        case .symptom:
            return nil
        case .context:
            return nil
        case .hydration:
            return nil
        case .protein:
            return nil
        case .progressPhoto:
            return nil
        }
    }

    private var primaryBadge: String {
        switch kind {
        case .shot:
            return model.todaySnapshot.nextDue == nil ? "Catch-up lane" : "Primary daily loop"
        case .weight:
            return "Trend anchor"
        case .symptom:
            return "Bounded signal"
        case .context, .hydration, .protein:
            return "Support context"
        case .progressPhoto:
            return "Visual proof"
        }
    }

    private var secondaryBadge: String? {
        switch kind {
        case .shot:
            return model.todaySnapshot.nextDue?.scheduledAt.formatted(date: .omitted, time: .shortened)
        case .weight:
            return model.insightsSnapshot.weightTrend.latestLabel
        case .symptom:
            return model.insightsSnapshot.recentSymptomEntries.first.map { "\($0.symptomKey.capitalized) • \($0.severity)/5" }
        case .context:
            return "More detail"
        case .hydration:
            return model.insightsSnapshot.contextTrend.latestLabel ?? "One tap"
        case .protein:
            return model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .proteinMeals })?.progressLabel
        case .progressPhoto:
            return model.insightsSnapshot.progressEvidence.recentPhotos.first.map { $0.loggedAt.formatted(date: .abbreviated, time: .omitted) } ?? "No baseline yet"
        }
    }

    private var tint: Color {
        switch kind {
        case .shot, .weight, .hydration, .protein:
            return AtlasPalette.primary
        case .symptom, .context, .progressPhoto:
            return AtlasPalette.secondaryText
        }
    }
}

private struct AtlasQuickCaptureShotCard: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasSectionCard(style: .hero) {
            VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                if let nextDue = model.todaySnapshot.nextDue {
                    Text(model.renderedTitle(
                        canonical: nextDue.canonicalTitle,
                        alias: nextDue.aliasTitle
                    ))
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)

                    Text("\(nextDue.kindLabel) • \(nextDue.cadenceLabel)")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    HStack(spacing: AtlasSpacing.small) {
                        Button("Mark taken") {
                            AtlasFeedback.notify(.success)
                            Task {
                                await model.logOccurrence(
                                    AtlasOccurrenceLogRequest(
                                        occurrenceID: nextDue.id,
                                        protocolID: nextDue.protocolID,
                                        action: .taken
                                    )
                                )
                            }
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())

                        Button("Skip") {
                            AtlasFeedback.impact(.medium)
                            Task {
                                await model.logOccurrence(
                                    AtlasOccurrenceLogRequest(
                                        occurrenceID: nextDue.id,
                                        protocolID: nextDue.protocolID,
                                        action: .skipped
                                    )
                                )
                            }
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                } else {
                    Text("No due shot is waiting right now.")
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(AtlasPalette.textPrimary)

                    Button("Open full Today") {
                        AtlasFeedback.selection()
                        model.routePath.removeAll()
                        model.activeTab = .today
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
        }
    }
}

private struct AtlasQuickCaptureWeightCard: View {
    let model: AtlasAppModel
    @Binding var weightValue: String
    @Binding var weightUnit: AtlasWeightUnit

    var body: some View {
        AtlasSectionCard(style: .hero) {
            VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                Text("Log weight")
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(model.insightsSnapshot.weightTrend.latestLabel ?? "Keep the trend current with one fast check-in.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                if let changeLabel = model.insightsSnapshot.weightTrend.changeLabel {
                    AtlasStatusBadge(changeLabel, tint: AtlasPalette.primary)
                }

                HStack(spacing: AtlasSpacing.small) {
                    TextField("Weight", text: $weightValue)
                        .keyboardType(.decimalPad)
                        .atlasStandaloneInputSurface()

                    Picker("Unit", selection: $weightUnit) {
                        Text("lb").tag(AtlasWeightUnit.lb)
                        Text("kg").tag(AtlasWeightUnit.kg)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 150)
                }

                Button("Save weight") {
                    guard let value = Double(weightValue), value > 0 else {
                        return
                    }
                    AtlasFeedback.selection()
                    Task {
                        await model.saveWeightEntry(
                            AtlasWeightEntryDraft(
                                loggedAt: model.currentDate(),
                                value: value,
                                unit: weightUnit
                            )
                        )
                        weightValue = ""
                    }
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
                .disabled(Double(weightValue) == nil)
            }
        }
    }
}

private struct AtlasQuickCaptureSymptomCard: View {
    let model: AtlasAppModel
    @Binding var symptomKey: String
    @Binding var symptomSeverity: Int
    @Binding var symptomNote: String

    private let suggestedSymptoms = ["Nausea", "GI", "Energy", "Appetite", "Sleep", "Headache"]

    var body: some View {
        AtlasSectionCard(style: .hero) {
            VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                Text("Log symptom")
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AtlasSpacing.small) {
                        ForEach(suggestedSymptoms, id: \.self) { suggestion in
                            Button(suggestion) {
                                AtlasFeedback.selection()
                                symptomKey = suggestion
                            }
                            .buttonStyle(AtlasTagButtonStyle(isActive: symptomKey == suggestion))
                        }
                    }
                }

                TextField("Symptom", text: $symptomKey)
                    .atlasStandaloneInputSurface()

                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    Text("Severity: \(symptomSeverity)/5")
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Slider(value: Binding(
                        get: { Double(symptomSeverity) },
                        set: { symptomSeverity = Int($0.rounded()) }
                    ), in: 1...5, step: 1)
                    .tint(AtlasPalette.primary)
                }

                TextField("Optional note", text: $symptomNote, axis: .vertical)
                    .atlasStandaloneInputSurface()

                Button("Save symptom") {
                    guard symptomKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
                        return
                    }
                    AtlasFeedback.selection()
                    Task {
                        await model.saveSymptomEntry(
                            AtlasSymptomEntryDraft(
                                loggedAt: model.currentDate(),
                                symptomKey: symptomKey.trimmingCharacters(in: .whitespacesAndNewlines),
                                severity: symptomSeverity,
                                notes: symptomNote.isEmpty ? nil : symptomNote
                            )
                        )
                        symptomNote = ""
                    }
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
                .disabled(symptomKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

private struct AtlasQuickCaptureContextCard: View {
    let model: AtlasAppModel
    let kind: AtlasQuickCaptureKind

    var body: some View {
        AtlasSectionCard(style: .hero) {
            VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                Text(kind.title)
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(description)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                if let shortcut = shortcut {
                    Button(primaryTitle) {
                        AtlasFeedback.selection()
                        Task {
                            await model.saveContextEntry(
                                shortcut.makeDraft(
                                    loggedAt: model.currentDate(),
                                    protocolID: atlasTodayContextProtocolID(snapshot: model.todaySnapshot)
                                )
                            )
                        }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                }

                Button("Open detailed context capture") {
                    AtlasFeedback.selection()
                    model.routePath.removeAll()
                    model.activeTab = .insights
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
            }
        }
    }

    private var shortcut: AtlasTodayContextShortcut? {
        switch kind {
        case .context:
            return nil
        case .hydration:
            return .hydration
        case .protein:
            return .proteinMeal
        default:
            return nil
        }
    }

    private var description: String {
        switch kind {
        case .context:
            return "Jump into the richer context flow for meal timing, GI tags, and surrounding notes."
        case .hydration:
            return "Keep a hydration check-in close without opening the full Insights stack."
        case .protein:
            return "Capture a protein-forward meal signal to support the daily nutrition loop."
        default:
            return ""
        }
    }

    private var primaryTitle: String {
        switch kind {
        case .hydration:
            return "Log hydration"
        case .protein:
            return "Log protein meal"
        default:
            return "Save"
        }
    }
}

private struct AtlasQuickCaptureProgressCard: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasSectionCard(style: .hero) {
            VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                Text("Progress photo")
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text("Jump into guided recapture, same-angle compare, and private visual summaries without leaving Atlas.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                Button("Open progress evidence") {
                    AtlasFeedback.selection()
                    model.open(.progressEvidence)
                }
                .buttonStyle(AtlasPrimaryButtonStyle())

                if let note = model.insightsSnapshot.progressEvidence.comparisonNote {
                    Text(note)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
        }
    }
}

private struct AtlasTagButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .atlasTextRole(.deckEyebrow)
            .foregroundStyle(isActive ? .white : AtlasPalette.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isActive ? AtlasPalette.primary : AtlasPalette.surfacePrimary)
            )
            .overlay {
                Capsule()
                    .stroke(AtlasPalette.border.opacity(isActive ? 0 : 0.55), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.82), value: isActive)
    }
}

enum AtlasTodayGuidanceDestination: Equatable {
    case protocolDetail(String)
    case protocolChange(String)
    case weeklyReview
    case library
    case contextShortcut(AtlasTodayContextShortcut)
    case detailedContext(AtlasTodayContextShortcut?)
}

struct AtlasTodayGuidanceAction: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let symbolName: String
    let destination: AtlasTodayGuidanceDestination
}

struct AtlasTodayGuidancePresentation: Equatable {
    let headline: String
    let summary: String
    let recentChangeLine: String?
    let waitLine: String?
    let facts: [AtlasExplainerFact]
    let primaryAction: AtlasTodayGuidanceAction
    let secondaryActions: [AtlasTodayGuidanceAction]
}

struct AtlasTodayRecoveryPresentation: Equatable {
    let title: String
    let summary: String
    let facts: [AtlasExplainerFact]
    let primaryAction: AtlasTodayGuidanceAction
    let secondaryAction: AtlasTodayGuidanceAction?
}

enum AtlasTodayContextShortcutDelivery: Equatable {
    case saveNow
    case openEditor
}

enum AtlasTodayContextShortcut: String, CaseIterable, Identifiable, Equatable {
    case hydration
    case lowAppetite
    case proteinMeal
    case giCheckIn

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hydration:
            return "Hydrated"
        case .lowAppetite:
            return "Low appetite"
        case .proteinMeal:
            return "Protein meal"
        case .giCheckIn:
            return "GI check-in"
        }
    }

    var subtitle: String {
        switch self {
        case .hydration:
            return "One-tap hydration check-in"
        case .lowAppetite:
            return "Quick appetite signal"
        case .proteinMeal:
            return "Open a meal draft"
        case .giCheckIn:
            return "Capture symptoms with context"
        }
    }

    var symbolName: String {
        switch self {
        case .hydration:
            return "drop.fill"
        case .lowAppetite:
            return "fork.knife.circle.fill"
        case .proteinMeal:
            return "takeoutbag.and.cup.and.straw.fill"
        case .giCheckIn:
            return "waveform.path.ecg"
        }
    }

    var delivery: AtlasTodayContextShortcutDelivery {
        switch self {
        case .hydration, .lowAppetite:
            return .saveNow
        case .proteinMeal, .giCheckIn:
            return .openEditor
        }
    }

    func makeDraft(loggedAt: Date, protocolID: String?) -> AtlasContextEntryDraft {
        switch self {
        case .hydration:
            return AtlasContextEntryDraft(
                protocolID: protocolID,
                loggedAt: loggedAt,
                hydration: .high,
                giTags: [.calm],
                tags: ["hydration", "today-quick-capture"],
                presetKey: AtlasContextBuiltinPreset.steadyHydration.id
            )
        case .lowAppetite:
            return AtlasContextEntryDraft(
                protocolID: protocolID,
                loggedAt: loggedAt,
                appetite: .low,
                tags: ["appetite", "today-quick-capture"]
            )
        case .proteinMeal:
            return AtlasContextQuickPreset(.proteinMeal).makeDraft(loggedAt: loggedAt)
        case .giCheckIn:
            return AtlasContextEntryDraft(
                protocolID: protocolID,
                loggedAt: loggedAt,
                appetite: .low,
                giTags: [.nausea],
                tags: ["gi", "today-quick-capture"],
                presetKey: AtlasContextBuiltinPreset.giOff.id
            )
        }
    }
}

private struct AtlasTodayGuidanceCard: View {
    let guidance: AtlasTodayGuidancePresentation
    let primaryAction: () -> Void
    let secondaryAction: (AtlasTodayGuidanceAction) -> Void

    var body: some View {
        AtlasSectionCard(style: .utility, title: "Operational guidance") {
            Text(guidance.headline)
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)

            if guidance.facts.isEmpty == false {
                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    ForEach(guidance.facts) { fact in
                        HStack(spacing: AtlasSpacing.small) {
                            Text(fact.label)
                                .atlasTextRole(.deckEyebrow)
                                .foregroundStyle(AtlasPalette.primary)
                            Spacer()
                            Text(fact.value)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                }
            }

            Button(guidance.primaryAction.title) {
                AtlasFeedback.selection()
                primaryAction()
            }
            .buttonStyle(AtlasPrimaryButtonStyle())

            if guidance.secondaryActions.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AtlasSpacing.small) {
                        ForEach(guidance.secondaryActions) { action in
                            Button(action.title) {
                                AtlasFeedback.selection()
                                secondaryAction(action)
                            }
                            .buttonStyle(AtlasChipButtonStyle(tint: AtlasPalette.secondaryText))
                        }
                    }
                }
            }
        }
    }
}

private struct AtlasTodayRecoveryCard: View {
    let recovery: AtlasTodayRecoveryPresentation
    let primaryAction: () -> Void
    let secondaryAction: (() -> Void)?

    var body: some View {
        AtlasSectionCard(style: .elevated, title: recovery.title) {
            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                ForEach(recovery.facts) { fact in
                    HStack(spacing: AtlasSpacing.small) {
                        Text(fact.label)
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.primary)
                        Spacer()
                        Text(fact.value)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                }
            }

            Button(recovery.primaryAction.title) {
                AtlasFeedback.selection()
                primaryAction()
            }
            .buttonStyle(AtlasPrimaryButtonStyle())

            if let secondaryAction, let action = recovery.secondaryAction {
                Button(action.title) {
                    AtlasFeedback.selection()
                    secondaryAction()
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
            }
        }
    }
}

private struct AtlasTodayContextShortcutRail: View {
    let shortcuts: [AtlasTodayContextShortcut]
    let action: (AtlasTodayContextShortcut) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            Text("Faster check-ins")
                .atlasTextRole(.deckEyebrow)
                .foregroundStyle(AtlasPalette.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AtlasSpacing.small) {
                    ForEach(shortcuts) { shortcut in
                        Button {
                            AtlasFeedback.selection()
                            action(shortcut)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Label(shortcut.title, systemImage: shortcut.symbolName)
                                    .atlasTextRole(.deckEyebrow)
                                Text(shortcut.subtitle)
                                    .atlasTextRole(.supporting)
                                    .multilineTextAlignment(.leading)
                            }
                            .foregroundStyle(AtlasPalette.textPrimary)
                            .padding(.horizontal, AtlasSpacing.small)
                            .padding(.vertical, AtlasSpacing.small)
                            .frame(width: 156, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(AtlasPalette.secondaryFill)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

func atlasTodayGuidancePresentation(
    todaySnapshot: AtlasTodaySnapshot,
    weeklyReviewSeed: AtlasWeeklyReviewSeed?,
    actionPlans: [AtlasWeeklyReviewActionPlan]
) -> AtlasTodayGuidancePresentation? {
    guard todaySnapshot.hasProtocols else {
        return nil
    }

    let overdueCount = todaySnapshot.overdue.count
    let upcomingCount = todaySnapshot.upcoming.count
    let nextDue = todaySnapshot.nextDue
    let focusTitle = actionPlans.first?.title
    let nextTitle = atlasTodayActionTitle(for: nextDue)
    let recentChangeLine: String?
    if let change = weeklyReviewSeed?.protocolChangeSummary {
        var fragments = ["Latest plan change"]
        if let title = change.latestTitle {
            fragments.append("for \(title)")
        }
        if let changedAt = change.latestChangedAt {
            fragments.append("landed \(changedAt.formatted(date: .abbreviated, time: .omitted))")
        }
        recentChangeLine = fragments.joined(separator: " ") + "."
    } else {
        recentChangeLine = nil
    }

    let facts = [
        overdueCount > 0 ? AtlasExplainerFact(label: "Overdue", value: String(overdueCount)) : nil,
        nextDue.map {
            AtlasExplainerFact(
                label: "Next due",
                value: "\($0.scheduledAt.formatted(date: .omitted, time: .shortened)) • \(atlasTodayActionTitle(for: $0))"
            )
        },
        upcomingCount > 0 ? AtlasExplainerFact(label: "Later today", value: String(upcomingCount)) : nil,
        focusTitle.map { AtlasExplainerFact(label: "Weekly focus", value: $0) }
    ].compactMap { $0 }

    if overdueCount > 0 {
        let primary = AtlasTodayGuidanceAction(
            id: "recovery-open",
            title: "Open the first overdue plan",
            detail: "Start with the oldest visible item.",
            symbolName: "arrow.turn.down.right",
            destination: .protocolDetail(todaySnapshot.overdue.first?.protocolID ?? nextDue?.protocolID ?? "")
        )
        let secondary = [
            nextDue.map {
                AtlasTodayGuidanceAction(
                    id: "recovery-change",
                    title: "Review recovery handling",
                    detail: "Open Change Studio if the future plan needs adjustment.",
                    symbolName: "slider.horizontal.3",
                    destination: .protocolChange($0.protocolID)
                )
            },
            AtlasTodayGuidanceAction(
                id: "recovery-context",
                title: "Capture quick context",
                detail: "Add one note or symptom signal.",
                symbolName: "waveform.path.ecg",
                destination: .detailedContext(.giCheckIn)
            )
        ]
        .compactMap { $0 }

        return AtlasTodayGuidancePresentation(
            headline: "Recovery comes before optimization.",
            summary: "",
            recentChangeLine: nil,
            waitLine: nil,
            facts: facts,
            primaryAction: primary,
            secondaryActions: secondary
        )
    }

    if let nextDue {
        return AtlasTodayGuidancePresentation(
            headline: "One clear next step is ready.",
            summary: "",
            recentChangeLine: nil,
            waitLine: nil,
            facts: facts,
            primaryAction: AtlasTodayGuidanceAction(
                id: "open-next",
                title: "Open the next plan",
                detail: "Stay with the plan that is due now.",
                symbolName: "arrow.right.circle.fill",
                destination: .protocolDetail(nextDue.protocolID)
            ),
            secondaryActions: [
                AtlasTodayGuidanceAction(
                    id: "open-weekly-review",
                    title: "Open weekly review",
                    detail: "Open the week-level view first if needed.",
                    symbolName: "calendar",
                    destination: .weeklyReview
                ),
                AtlasTodayGuidanceAction(
                    id: "quick-hydration",
                    title: "Log hydration",
                    detail: "Add a simple surrounding signal without leaving Today.",
                    symbolName: "drop.fill",
                    destination: .contextShortcut(.hydration)
                )
            ]
        )
    }

    return AtlasTodayGuidancePresentation(
        headline: "Today is relatively clear.",
        summary: "",
        recentChangeLine: nil,
        waitLine: nil,
        facts: facts,
        primaryAction: AtlasTodayGuidanceAction(
            id: focusTitle == nil ? "open-library" : "open-weekly-review",
            title: focusTitle == nil ? "Open Library" : "Open weekly review",
            detail: focusTitle == nil
                ? "Review current plans or create another protocol."
                : "Use the weekly view for broader context.",
            symbolName: focusTitle == nil ? "books.vertical.fill" : "calendar",
            destination: focusTitle == nil ? .library : .weeklyReview
        ),
        secondaryActions: [
            AtlasTodayGuidanceAction(
                id: "open-context-capture",
                title: "Open context capture",
                detail: "Add context now if you need it later.",
                symbolName: "square.and.pencil",
                destination: .detailedContext(nil)
            )
        ]
    )
}

func atlasTodayRecoveryPresentation(
    todaySnapshot: AtlasTodaySnapshot,
    weeklyReviewSeed: AtlasWeeklyReviewSeed?,
    actionPlans: [AtlasWeeklyReviewActionPlan]
) -> AtlasTodayRecoveryPresentation? {
    let overdueCount = todaySnapshot.overdue.count
    let skippedCount = weeklyReviewSeed?.skippedCount ?? 0
    let rescheduledCount = weeklyReviewSeed?.rescheduledCount ?? 0
    let followUp = weeklyReviewSeed?.protocolFollowUpSummary

    guard overdueCount > 0 || skippedCount > 0 || rescheduledCount > 0 || followUp != nil else {
        return nil
    }

    let primaryProtocolID = followUp?.protocolID
        ?? todaySnapshot.nextDue?.protocolID
        ?? todaySnapshot.overdue.first?.protocolID
        ?? ""
    let facts = [
        overdueCount > 0 ? AtlasExplainerFact(label: "Overdue now", value: String(overdueCount)) : nil,
        skippedCount > 0 ? AtlasExplainerFact(label: "Skipped this week", value: String(skippedCount)) : nil,
        rescheduledCount > 0 ? AtlasExplainerFact(label: "Rescheduled this week", value: String(rescheduledCount)) : nil,
        actionPlans.first.map { AtlasExplainerFact(label: "Carried focus", value: $0.title) },
        followUp.map {
            AtlasExplainerFact(
                label: "Latest changed plan",
                value: $0.title ?? "Atlas protocol"
            )
        }
    ].compactMap { $0 }

    return AtlasTodayRecoveryPresentation(
        title: "Recovery handling",
        summary: followUp.map {
            "\($0.title ?? "The latest changed plan") is still inside a \($0.windowDays)-day follow-up window. Review the next steps without changing past logs."
        } ?? "Use recovery handling to decide whether the future plan should hold or shift.",
        facts: facts,
        primaryAction: AtlasTodayGuidanceAction(
            id: "recovery-plan",
            title: "Review recovery plan",
            detail: "Open Change Studio if the future plan or missed-dose handling needs a reset.",
            symbolName: "slider.horizontal.3",
            destination: .protocolChange(primaryProtocolID)
        ),
        secondaryAction: AtlasTodayGuidanceAction(
            id: "recovery-note",
            title: "Add a recovery check-in",
            detail: "Capture GI, appetite, or hydration context while it is still recent.",
            symbolName: "waveform.path.ecg",
            destination: .detailedContext(.giCheckIn)
        )
    )
}

func atlasTodayActionTitle(for occurrence: AtlasScheduledOccurrence?) -> String {
    occurrence?.aliasTitle ?? occurrence?.canonicalTitle ?? "your next plan"
}

func atlasTodayContextProtocolID(snapshot: AtlasTodaySnapshot) -> String? {
    snapshot.nextDue?.protocolID ?? snapshot.overdue.first?.protocolID ?? snapshot.upcoming.first?.protocolID
}

func atlasTodayContextEditorState(
    shortcut: AtlasTodayContextShortcut?,
    referenceDate: Date,
    protocolID: String?
) -> AtlasContextEditorState {
    var state = AtlasContextEditorState(referenceDate: referenceDate)
    state.protocolID = protocolID

    guard let shortcut else {
        return state
    }

    switch shortcut {
    case .hydration:
        state.applyQuickPreset(AtlasContextQuickPreset(.steadyHydration))
    case .lowAppetite:
        state.appetite = .low
    case .proteinMeal:
        state.applyQuickPreset(AtlasContextQuickPreset(.proteinMeal))
    case .giCheckIn:
        state.applyQuickPreset(AtlasContextQuickPreset(.giOff))
    }

    return state
}

public struct AtlasTimelineScreen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let model: AtlasAppModel
    let state: AtlasTimelineViewState
    @State private var explanationSheet: AtlasExplanationSheetItem?
    @State private var showOlderHistory = false
    @State private var searchFocusBaseline = ""
    @FocusState private var searchFocused: Bool

    public var body: some View {
        let timelineMetrics = [
            AtlasMetricItem(id: "entries", title: "Visible", value: "\(state.entries.count)", tint: AtlasPalette.primary),
            AtlasMetricItem(id: "filter", title: "Filter", value: state.filter.title, tint: AtlasPalette.secondaryText),
            AtlasMetricItem(
                id: "search",
                title: "Search",
                value: state.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "All" : "Active",
                tint: state.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AtlasPalette.secondaryText : AtlasPalette.primary
            )
        ]

        AtlasRootScrollSurface {
            AtlasTabHeader(
                title: "Timeline",
                subtitle: nil
            )

            AtlasSectionCard(style: .utility, title: "History filters") {
                AtlasMetricStrip(metrics: timelineMetrics)

                Picker("Filter", selection: Binding(
                    get: { state.filter },
                    set: { value in
                        AtlasFeedback.selection()
                        model.timelineFilter = value
                        state.filter = value
                        showOlderHistory = false
                        Task { await model.refreshTimeline() }
                    }
                )) {
                    ForEach(AtlasTimelineFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                HStack(spacing: AtlasSpacing.small) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AtlasPalette.textSecondary)
                    TextField("Search immutable history", text: Binding(
                        get: { state.searchText },
                        set: { value in
                            state.searchText = value
                            model.updateTimelineSearchText(value)
                            if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                                showOlderHistory = true
                            }
                        }
                    ))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .focused($searchFocused)
                    .onSubmit {
                        searchFocused = false
                        AtlasKeyboard.dismiss()
                    }
                    if state.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                        Button {
                            AtlasFeedback.selection()
                            state.searchText = ""
                            model.updateTimelineSearchText("")
                            showOlderHistory = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .atlasStandaloneInputSurface()
                .atlasKeyboardCommitAccessory(
                    onCancel: {
                        cancelSearchEdit()
                    },
                    onSave: {
                        saveSearchEdit()
                    },
                    onDone: {
                        finishSearchEdit()
                    }
                )

                if searchFocused {
                    HStack(spacing: AtlasSpacing.small) {
                        Button("Cancel") {
                            cancelSearchEdit()
                            AtlasKeyboard.dismiss()
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                        .frame(maxWidth: .infinity)

                        Button("Save") {
                            saveSearchEdit()
                            AtlasKeyboard.dismiss()
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                        .frame(maxWidth: .infinity)

                        Button("Done") {
                            finishSearchEdit()
                            AtlasKeyboard.dismiss()
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            if state.entries.isEmpty {
                if state.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    AtlasEmptyStateCard(
                        title: "No matches",
                        message: "Try a broader keyword or clear the search to return to the full record.",
                        systemImage: "magnifyingglass.circle",
                        note: "Search only covers history"
                    ) {
                        Button("Clear search") {
                            state.searchText = ""
                            model.updateTimelineSearchText("")
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                } else {
                    AtlasEmptyStateCard(
                        title: "No history yet",
                        message: "Quick logs, imports, and protocol edits will appear here with immutable timestamps.",
                        systemImage: "clock.badge.questionmark",
                        note: nil
                    ) {
                        Button("Create protocol") {
                            model.open(.protocolCreate)
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                    }
                }
            } else {
                ForEach(displayedTimelineSections, id: \.dateLabel) { section in
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

                if shouldShowOlderHistoryToggle {
                    AtlasSectionCard(style: .utility) {
                        Button(showOlderHistory ? "Show only recent history" : "Show older history") {
                            AtlasFeedback.selection()
                            withAnimation(reduceMotion ? .easeOut(duration: 0.16) : AtlasMotion.interactiveSpring) {
                                showOlderHistory.toggle()
                            }
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                }
            }
        }
        .sheet(item: $explanationSheet) { item in
            AtlasExplanationSheet(item: item)
        }
        .onChange(of: searchFocused) { _, focused in
            if focused {
                searchFocusBaseline = state.searchText
            }
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

    private var displayedTimelineSections: [AtlasTimelineSection] {
        guard shouldShowOlderHistoryToggle, showOlderHistory == false else {
            return groupedTimelineEntries
        }
        return Array(groupedTimelineEntries.prefix(2))
    }

    private var shouldShowOlderHistoryToggle: Bool {
        state.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && state.filter == .all
            && groupedTimelineEntries.count > 2
    }

    private func cancelSearchEdit() {
        state.searchText = searchFocusBaseline
        model.updateTimelineSearchText(searchFocusBaseline)
        showOlderHistory = searchFocusBaseline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        searchFocused = false
    }

    private func saveSearchEdit() {
        searchFocused = false
    }

    private func finishSearchEdit() {
        searchFocused = false
    }
}

public struct AtlasLibraryScreen: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let model: AtlasAppModel
    let state: AtlasLibraryViewState

    public var body: some View {
        AtlasRootScrollSurface {
            AtlasTabHeader(
                title: "Library",
                subtitle: nil,
                action: AtlasTabHeaderAction(
                    systemImage: "plus",
                    accessibilityLabel: "Create protocol",
                    accessibilityHint: "Opens the native protocol creation form."
                ) {
                    model.open(.protocolCreate)
                }
            )

            AtlasCommandDeck(
                eyebrow: "LIBRARY CONTROL",
                title: state.protocols.isEmpty ? "Set up protocols and tools." : "Manage protocols and tools.",
                detail: nil,
                metrics: [
                    AtlasMetricItem(id: "protocol_count", title: "Protocols", value: "\(state.protocols.count)", tint: state.protocols.isEmpty ? AtlasPalette.secondaryText : AtlasPalette.primary),
                    AtlasMetricItem(id: "privacy_mode", title: "Privacy", value: state.renderMode.rawValue.capitalized, tint: AtlasPalette.secondaryText),
                    AtlasMetricItem(id: "workspaces", title: "Tools", value: "2", tint: AtlasPalette.primary)
                ],
                style: .task
            ) {
                VStack(spacing: AtlasSpacing.small) {
                    Button("Create protocol") {
                        AtlasFeedback.selection()
                        model.open(.protocolCreate)
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())

                    HStack(spacing: AtlasSpacing.small) {
                        Button("Open Inventory") {
                            AtlasFeedback.selection()
                            model.open(.inventory)
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())

                        Button(state.protocols.isEmpty ? "Import Atlas data" : "Open Calculator") {
                            AtlasFeedback.selection()
                            model.open(state.protocols.isEmpty ? .importFlow : .calculator)
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                }
            } footer: { EmptyView() }

            AtlasSectionCard(style: .utility, title: "Tools") {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(spacing: AtlasSpacing.small) {
                            atlasLibraryToolButtons
                        }
                    } else {
                        HStack(spacing: AtlasSpacing.small) {
                            atlasLibraryToolButtons
                        }
                    }
                }
            }

            if state.protocols.isEmpty {
                AtlasEmptyStateCard(
                    title: "Library is empty",
                    message: "Create a protocol or import data to get started.",
                    systemImage: "square.stack.3d.up",
                    note: nil
                ) {
                    VStack(spacing: AtlasSpacing.small) {
                        Button("Create protocol") {
                            AtlasFeedback.selection()
                            model.open(.protocolCreate)
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())

                        Button("Import Atlas data") {
                            AtlasFeedback.selection()
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

    @ViewBuilder
    private var atlasLibraryToolButtons: some View {
        AtlasToolLauncherButton(
            title: "Inventory",
            subtitle: nil,
            systemImage: "shippingbox.fill"
        ) {
            model.open(.inventory)
        }

        AtlasToolLauncherButton(
            title: "Calculator",
            subtitle: nil,
            systemImage: "function"
        ) {
            model.open(.calculator)
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
        AtlasScreen {
            if let detail {
                let headerMetrics = [
                    AtlasMetricItem(id: "status", title: "Status", value: detail.status.rawValue.capitalized, tint: AtlasPalette.primary),
                    AtlasMetricItem(id: "kind", title: "Kind", value: detail.kindLabel, tint: AtlasPalette.secondaryText),
                    AtlasMetricItem(
                        id: "dose",
                        title: "Dose",
                        value: detail.doseLabel ?? "Atlas-managed",
                        tint: detail.doseLabel == nil ? AtlasPalette.secondaryText : AtlasPalette.success
                    )
                ]

                AtlasCommandDeck(
                    eyebrow: "Protocol detail",
                    title: model.renderedTitle(canonical: detail.canonicalTitle, alias: detail.aliasTitle),
                    detail: "Cadence \(detail.cadenceLabel)\(detail.nextOccurrence.map { " • next due \($0.scheduledAt.formatted(date: .abbreviated, time: .shortened))" } ?? "").",
                    metrics: headerMetrics,
                    tint: AtlasPalette.primary,
                    style: .hero
                ) {
                    if let administrationLabel = detail.administrationLabel {
                        AtlasCalloutRow(
                            systemImage: "cross.case.fill",
                            title: "Administration",
                            detail: administrationLabel,
                            tint: AtlasPalette.primary
                        )
                    }

                    if let supplyLabel = detail.supplyLabel {
                        AtlasCalloutRow(
                            systemImage: "shippingbox.fill",
                            title: "Supply source",
                            detail: supplyLabel,
                            tint: AtlasPalette.secondaryText
                        )
                    }
                } footer: {
                    HStack(spacing: AtlasSpacing.small) {
                        Button("Edit core fields") {
                            AtlasFeedback.selection()
                            model.open(.protocolEdit(protocolID))
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())

                        Button("Open Change Studio") {
                            AtlasFeedback.selection()
                            model.open(.protocolChange(protocolID))
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                    }
                }

                if let nextOccurrence = detail.nextOccurrence {
                    AtlasRootSectionHeader("Next Due")
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
                }

                if let medicationLevel = detail.medicationLevel {
                    AtlasRootSectionHeader("Level View")
                    AtlasMedicationLevelCard(
                        model: model,
                        item: medicationLevel,
                        actionTitle: "Open Level Studio"
                    ) {
                        model.open(.medicationLevels(protocolID))
                    }
                }

                if let knowledge = detail.compoundKnowledge {
                    AtlasRootSectionHeader("Compound Intelligence")
                    AtlasSectionCard(title: "Compound profile") {
                        AtlasCalloutRow(
                            systemImage: "waveform.path.ecg.text",
                            title: "\(knowledge.categoryLabel) • \(knowledge.routeLabel)",
                            detail: knowledge.protocolSummary,
                            tint: AtlasPalette.primary
                        )

                        if let kineticsProfile = knowledge.kineticsProfile {
                            AtlasCalloutRow(
                                systemImage: "waveform",
                                title: "Relative level support",
                                detail: "Models a relative curve from a \(atlasCompoundHalfLifeLabel(hours: kineticsProfile.halfLifeHours)) half-life profile.",
                                tint: AtlasPalette.secondaryText
                            )
                        }

                        Button("Open compound intelligence") {
                            AtlasFeedback.selection()
                            model.open(.compoundIntelligence(knowledge.slug))
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                }

                if detail.recentChanges.isEmpty == false {
                    AtlasRootSectionHeader("Recent Changes")
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
                    }
                }

                AtlasRootSectionHeader("Notes")
                AtlasSectionCard {
                    Text(detail.notes ?? "No notes")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                AtlasRootSectionHeader("Future Plan")
                AtlasSectionCard {
                    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                        AtlasCalloutRow(
                            systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                            title: "Future edits stay deliberate",
                            detail: "Past logs stay in place. Only future projections change.",
                            tint: AtlasPalette.secondaryText
                        )

                        Button("Edit core fields") {
                            AtlasFeedback.selection()
                            model.open(.protocolEdit(protocolID))
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())

                        Button("Inventory and sites") {
                            AtlasFeedback.selection()
                            model.open(.inventory)
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())

                        Button("Open Change Studio") {
                            AtlasFeedback.selection()
                            model.open(.protocolChange(protocolID))
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                    }
                }
            } else if let error = model.loadErrorMessage {
                AtlasInlineMessage(text: error)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
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
        AtlasScreen(dismissKeyboardImmediately: true) {
            AtlasCommandDeck(
                eyebrow: mode == .create ? "Protocol composer" : "Future plan edit",
                title: mode == .create ? "Build a protocol." : "Update the future schedule without rewriting history.",
                detail: protocolPreviewHeadline,
                metrics: protocolPreviewMetrics,
                tint: form.kind.editorTint,
                style: .hero
            ) {
                VStack(spacing: AtlasSpacing.small) {
                    Button(mode.buttonTitle) {
                        AtlasKeyboard.dismiss()
                        Task { await submit() }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                    .disabled(form.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("protocolEditorSubmitButton")

                    if case .edit(let id) = mode {
                        Button("Open Change Studio") {
                            AtlasFeedback.selection()
                            model.open(.protocolChange(id))
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    } else {
                        Button("Import Atlas data instead") {
                            AtlasFeedback.selection()
                            model.open(.importFlow)
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                }
            } footer: {
                AtlasProgressMeter(
                    title: "Plan clarity",
                    detail: protocolPreviewSupport,
                    value: protocolClarityScore,
                    tint: form.kind.editorTint
                )
            }

            AtlasSectionCard(style: .task, title: "Protocol identity") {
                TextField("Name your protocol", text: $form.name)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit { AtlasKeyboard.dismiss() }
                    .atlasStandaloneInputSurface()

                VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                    Text("Kind")
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(form.kind.editorTint)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: AtlasSpacing.small), GridItem(.flexible(), spacing: AtlasSpacing.small)], spacing: AtlasSpacing.small) {
                        ForEach(AtlasProtocolKind.allCases, id: \.self) { kind in
                            AtlasProtocolChoiceCard(
                                title: kind.editorTitle,
                                subtitle: kind.editorSubtitle,
                                isSelected: form.kind == kind,
                                tint: kind.editorTint
                            ) {
                                AtlasFeedback.selection()
                                form.kind = kind
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                    Text("Route")
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(form.kind.editorTint)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: AtlasSpacing.small), GridItem(.flexible(), spacing: AtlasSpacing.small)], spacing: AtlasSpacing.small) {
                        ForEach(AtlasProtocolAdministrationRoute.allCases, id: \.self) { route in
                            AtlasProtocolChoiceCard(
                                title: route.atlasTitle,
                                subtitle: route.editorSubtitle,
                                isSelected: form.administrationRoute == route,
                                tint: form.kind.editorTint
                            ) {
                                AtlasFeedback.selection()
                                form.administrationRoute = route
                            }
                        }
                    }
                }
            }

            AtlasSectionCard(style: .task, title: "Cadence") {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: AtlasSpacing.small), GridItem(.flexible(), spacing: AtlasSpacing.small)], spacing: AtlasSpacing.small) {
                    ForEach(AtlasProtocolRuleType.allCases, id: \.self) { cadence in
                        AtlasProtocolChoiceCard(
                            title: cadence.editorTitle,
                            subtitle: cadence.editorSubtitle,
                            isSelected: form.cadenceType == cadence,
                            tint: form.kind.editorTint
                        ) {
                            AtlasFeedback.selection()
                            form.cadenceType = cadence
                        }
                    }
                }

                if form.cadenceType == .weekly {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AtlasSpacing.small) {
                            ForEach(0..<7, id: \.self) { index in
                                let isSelected = form.weekday == index
                                Button(weekdayName(index)) {
                                    AtlasFeedback.selection()
                                    form.weekday = index
                                }
                                .buttonStyle(
                                    AtlasChipButtonStyle(
                                        tint: isSelected ? form.kind.editorTint : AtlasPalette.textSecondary
                                    )
                                )
                            }
                        }
                    }
                } else if form.cadenceType == .everyNDays {
                    AtlasProtocolStepperRow(
                        title: "Interval",
                        value: "Every \(form.intervalDays) days",
                        tint: form.kind.editorTint,
                        onDecrease: {
                            guard form.intervalDays > 1 else { return }
                            AtlasFeedback.selection()
                            form.intervalDays -= 1
                        },
                        onIncrease: {
                            guard form.intervalDays < 30 else { return }
                            AtlasFeedback.selection()
                            form.intervalDays += 1
                        }
                    )
                }

                TextField("Default time (for example 08:00)", text: $form.defaultTimeOfDay)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit { AtlasKeyboard.dismiss() }
                    .atlasStandaloneInputSurface()

                AtlasCalloutRow(
                    systemImage: "clock.badge.checkmark",
                    title: "Cadence preview",
                    detail: protocolCadenceSummary,
                    tint: form.kind.editorTint
                )
            }

            AtlasSectionCard(style: .task, title: "Dose & delivery") {
                HStack(spacing: AtlasSpacing.small) {
                    TextField("Amount", text: $form.doseAmount)
                        .keyboardType(.decimalPad)
                        .submitLabel(.done)
                        .onSubmit { AtlasKeyboard.dismiss() }
                        .atlasStandaloneInputSurface()

                    TextField("Unit", text: $form.doseUnit)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit { AtlasKeyboard.dismiss() }
                        .atlasStandaloneInputSurface()
                }

                VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                    Text("Supply")
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(form.kind.editorTint)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: AtlasSpacing.small), GridItem(.flexible(), spacing: AtlasSpacing.small)], spacing: AtlasSpacing.small) {
                        AtlasProtocolChoiceCard(
                            title: "None",
                            subtitle: "No linked supply tracking",
                            isSelected: form.supplyType == nil,
                            tint: AtlasPalette.textSecondary
                        ) {
                            AtlasFeedback.selection()
                            form.supplyType = nil
                        }

                        ForEach(AtlasProtocolSupplyType.allCases, id: \.self) { supplyType in
                            AtlasProtocolChoiceCard(
                                title: supplyType.atlasTitle,
                                subtitle: supplyType.editorSubtitle,
                                isSelected: form.supplyType == supplyType,
                                tint: form.kind.editorTint
                            ) {
                                AtlasFeedback.selection()
                                form.supplyType = supplyType
                            }
                        }
                    }
                }

                if form.supplyType != nil {
                    AtlasProtocolStepperRow(
                        title: "Planned supply life",
                        value: "\(form.dosesPerSupply) dose\(form.dosesPerSupply == 1 ? "" : "s") per \(form.supplyType?.atlasTitle.lowercased() ?? "supply")",
                        tint: form.kind.editorTint,
                        onDecrease: {
                            guard form.dosesPerSupply > 1 else { return }
                            AtlasFeedback.selection()
                            form.dosesPerSupply -= 1
                        },
                        onIncrease: {
                            guard form.dosesPerSupply < 60 else { return }
                            AtlasFeedback.selection()
                            form.dosesPerSupply += 1
                        }
                    )
                }
            }

            AtlasSectionCard(style: .utility, title: "Notes") {
                TextField("Optional notes for yourself", text: $form.notes, axis: .vertical)
                    .lineLimit(3...6)
                    .submitLabel(.done)
                    .onSubmit { AtlasKeyboard.dismiss() }
                    .atlasStandaloneInputSurface()
            }

            AtlasSectionCard(style: .reward, title: "Preview") {
                AtlasCalloutRow(
                    systemImage: form.kind.previewSystemImage,
                    title: form.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unnamed protocol" : form.name,
                    detail: protocolPreviewSupport,
                    tint: form.kind.editorTint,
                    badge: form.kind.editorTitle
                )

                AtlasCalloutRow(
                    systemImage: "calendar",
                    title: "Cadence",
                    detail: protocolCadenceSummary,
                    tint: form.kind.editorTint
                )

                AtlasCalloutRow(
                    systemImage: "shippingbox.fill",
                    title: "Delivery",
                    detail: protocolDeliverySummary,
                    tint: form.kind.editorTint
                )
            }
        }
        .navigationTitle(mode.title)
        .atlasInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(mode.buttonTitle) {
                    AtlasKeyboard.dismiss()
                    Task { await submit() }
                }
                .disabled(form.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("protocolEditorToolbarSubmitButton")
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

    private var protocolPreviewHeadline: String {
        if form.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Set the name, cadence, route, and supply details before previewing the future schedule."
        }
        return "\(form.name) is set to \(protocolCadenceSummary.lowercased()) via \(form.administrationRoute.atlasTitle.lowercased())."
    }

    private var protocolPreviewSupport: String {
        let dose = form.doseAmount.isEmpty ? "Dose pending" : "\(form.doseAmount) \(form.doseUnit)"
        let supply = form.supplyType.map { "\($0.atlasTitle) tracked" } ?? "No supply link"
        return "\(dose) • \(supply)"
    }

    private var protocolPreviewMetrics: [AtlasMetricItem] {
        [
            .init(id: "kind", title: "Kind", value: form.kind.editorTitle, tint: form.kind.editorTint),
            .init(id: "route", title: "Route", value: form.administrationRoute.atlasTitle, tint: AtlasPalette.secondaryText),
            .init(id: "cadence", title: "Cadence", value: form.cadenceMetricLabel, tint: AtlasPalette.primary)
        ]
    }

    private var protocolCadenceSummary: String {
        switch form.cadenceType {
        case .daily:
            return "Daily at \(form.defaultTimeOfDay.ifEmpty("an unset time"))"
        case .weekly:
            return "\(weekdayName(form.weekday ?? 1)) at \(form.defaultTimeOfDay.ifEmpty("an unset time"))"
        case .everyNDays:
            return "Every \(form.intervalDays) days at \(form.defaultTimeOfDay.ifEmpty("an unset time"))"
        }
    }

    private var protocolDeliverySummary: String {
        let supply = form.supplyType.map { "\($0.atlasTitle) • \(form.dosesPerSupply) dose\(form.dosesPerSupply == 1 ? "" : "s") per supply" } ?? "No linked supply"
        return "\(form.administrationRoute.atlasTitle) • \(supply)"
    }

    private var protocolClarityScore: Double {
        var score = 0.2
        if form.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false { score += 0.2 }
        if form.defaultTimeOfDay.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false { score += 0.2 }
        if form.doseAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false { score += 0.2 }
        if form.supplyType != nil { score += 0.1 }
        if form.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false { score += 0.1 }
        return min(score, 1)
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

private struct AtlasProtocolChoiceCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack(alignment: .top, spacing: AtlasSpacing.small) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(subtitle)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(isSelected ? tint : AtlasPalette.border)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AtlasSpacing.medium)
        }
        .buttonStyle(AtlasTactileTileButtonStyle(tint: isSelected ? tint : AtlasPalette.border))
    }
}

private struct AtlasProtocolStepperRow: View {
    let title: String
    let value: String
    let tint: Color
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        HStack(spacing: AtlasSpacing.small) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(tint)
                Text(value)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
            }

            Spacer(minLength: 0)

            HStack(spacing: AtlasSpacing.small) {
                Button(action: onDecrease) {
                    Image(systemName: "minus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(AtlasTactileTileButtonStyle(tint: tint))

                Button(action: onIncrease) {
                    Image(systemName: "plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(AtlasTactileTileButtonStyle(tint: tint))
            }
        }
    }
}

public struct AtlasSettingsScreen: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let model: AtlasAppModel
    let state: AtlasSettingsViewState
    @State private var cloudEmail = ""
    @State private var cloudPassword = ""
    @State private var mascotNicknameDraft = ""

    public var body: some View {
        AtlasRootScrollSurface {
            AtlasTabHeader(
                title: "Settings",
                subtitle: nil
            )

            AtlasCommandDeck(
                eyebrow: "Control center",
                title: settingsDeckTitle,
                detail: nil,
                metrics: settingsDeckMetrics,
                style: .hero
            ) {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(spacing: AtlasSpacing.small) {
                            atlasSettingsPrimaryActions
                        }
                    } else {
                        HStack(spacing: AtlasSpacing.small) {
                            atlasSettingsPrimaryActions
                        }
                    }
                }
            } footer: {
                EmptyView()
            }

            AtlasSectionCard(style: .utility, title: "Workspaces") {
                VStack(spacing: AtlasSpacing.small) {
                    AtlasSettingsHubLink(
                        title: "Account & sync",
                        detail: nil,
                        symbolName: "icloud.and.arrow.up",
                        tint: AtlasPalette.primary
                    ) {
                        model.open(.settingsAccount)
                    }

                    AtlasSettingsHubLink(
                        title: "Privacy & trust",
                        detail: nil,
                        symbolName: "eye.slash",
                        tint: AtlasPalette.primary
                    ) {
                        model.open(.settingsPrivacy)
                    }

                    AtlasSettingsHubLink(
                        title: "Notifications & calendar",
                        detail: nil,
                        symbolName: "bell.badge",
                        tint: AtlasPalette.primary
                    ) {
                        model.open(.settingsNotifications)
                    }

                    AtlasSettingsHubLink(
                        title: "Services & devices",
                        detail: nil,
                        symbolName: "heart.text.square",
                        tint: AtlasPalette.secondaryText
                    ) {
                        model.open(.settingsServices)
                    }

                    AtlasSettingsHubLink(
                        title: "Personalization",
                        detail: nil,
                        symbolName: "sparkles",
                        tint: AtlasPalette.reward
                    ) {
                        model.open(.settingsPersonalization)
                    }
                }
            }

            AtlasSectionCard(style: .utility, title: "Status") {
                AtlasCalloutRow(
                    systemImage: settingsStatusCallout.systemImage,
                    title: settingsStatusCallout.title,
                    detail: settingsStatusCallout.detail,
                    tint: settingsStatusCallout.tint
                )

                AtlasSettingsStatusRow(title: "Mode", value: state.settingsSnapshot.accountMode.rawValue.capitalized)
                AtlasSettingsStatusRow(title: "Display", value: state.settingsSnapshot.trustVaultStatus.renderMode.rawValue.capitalized)
                AtlasSettingsStatusRow(title: "Notifications", value: permissionLabel(state.notificationPermissionStatus))

                if let action = settingsStatusCallout.action {
                    Button(action.title) {
                        AtlasFeedback.navigation()
                        action.handler()
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
        }
        .task(id: state.settingsSnapshot.mascotNickname ?? "") {
            if mascotNicknameDraft != (state.settingsSnapshot.mascotNickname ?? "") {
                mascotNicknameDraft = state.settingsSnapshot.mascotNickname ?? ""
            }
        }
        .atlasKeyboardDoneAccessory()
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
        if model.cloudSession?.newerBackupAvailable == true {
            return "Newer remote backup available"
        }
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

    private var settingsDeckTitle: String {
        if model.cloudSession != nil {
            return "Trust and recovery."
        }
        return "Settings"
    }

    private var settingsStatusCallout: (
        systemImage: String,
        title: String,
        detail: String,
        tint: Color,
        action: (title: String, handler: () -> Void)?
    ) {
        if state.notificationPermissionStatus == .denied {
            return (
                systemImage: "bell.slash.fill",
                title: "Alerts need permission",
                detail: "Reminder and weekly review alerts are blocked until notifications are re-enabled.",
                tint: AtlasPalette.warning,
                action: ("Open notifications", { model.open(.settingsNotifications) })
            )
        }

        if state.calendarPermissionStatus == .denied || state.calendarPermissionStatus == .restricted {
            return (
                systemImage: "calendar.badge.exclamationmark",
                title: "Calendar mirroring needs access",
                detail: "External calendar mirroring is paused until calendar permission is restored.",
                tint: AtlasPalette.warning,
                action: ("Open notifications", { model.open(.settingsNotifications) })
            )
        }

        if model.cloudSession?.newerBackupAvailable == true {
            return (
                systemImage: "arrow.triangle.2.circlepath.icloud",
                title: "A newer backup is ready",
                detail: "Open Account & Sync to restore the latest cloud backup on this device.",
                tint: AtlasPalette.success,
                action: ("Open account & sync", { model.open(.settingsAccount) })
            )
        }

        if model.cloudSession == nil {
            return (
                systemImage: "internaldrive",
                title: "Local-first remains active",
                detail: "This device is fully usable without sync.",
                tint: AtlasPalette.primary,
                action: nil
            )
        }

        return (
            systemImage: state.settingsSnapshot.rewardsSettings.enabled ? "sparkles" : "shield.checkered",
            title: state.settingsSnapshot.rewardsSettings.enabled ? "Trust surfaces look healthy." : "Trust surfaces are quiet.",
            detail: state.settingsSnapshot.retentionSettings.progressEnabled
                ? "Recovery, reminders, and continuity are ready."
                : "Recovery and reminders are ready. Continuity is optional.",
            tint: state.settingsSnapshot.rewardsSettings.enabled ? AtlasPalette.reward : AtlasPalette.secondaryText,
            action: nil
        )
    }

    private var settingsDeckMetrics: [AtlasMetricItem] {
        [
            AtlasMetricItem(
                id: "alerts",
                title: "Alerts",
                value: permissionLabel(state.notificationPermissionStatus),
                tint: state.notificationPermissionStatus == .authorized ? AtlasPalette.success : AtlasPalette.secondaryText
            )
        ]
    }

    @ViewBuilder
    private var atlasSettingsPrimaryActions: some View {
        Button(state.notificationPermissionStatus == .authorized ? "Account & sync" : "Open notifications") {
            AtlasFeedback.selection()
            if state.notificationPermissionStatus == .authorized {
                model.open(.settingsAccount)
            } else {
                model.open(.settingsNotifications)
            }
        }
        .buttonStyle(AtlasPrimaryButtonStyle())

        Button("Privacy & trust") {
            AtlasFeedback.selection()
            model.open(.settingsPrivacy)
        }
        .buttonStyle(AtlasSecondaryButtonStyle())
    }

    @ViewBuilder
    private var heroStatusBadges: some View {
        AtlasStatusBadge(
            model.cloudSession == nil ? "Local-first" : "Recovery ready",
            tint: model.cloudSession == nil ? AtlasPalette.primary : AtlasPalette.success
        )
        AtlasStatusBadge(
            state.settingsSnapshot.healthScaffold.connections.contains(where: { $0.connected }) ? "Health connected" : "Health optional",
            tint: state.settingsSnapshot.healthScaffold.connections.contains(where: { $0.connected }) ? AtlasPalette.success : AtlasPalette.secondaryText
        )
        AtlasStatusBadge(
            state.settingsSnapshot.trustVaultStatus.renderMode.rawValue.capitalized,
            tint: AtlasPalette.secondaryText
        )
    }
}

private enum AtlasLandingCardMoveDirection {
    case up
    case down
}

@MainActor
@ViewBuilder
private func atlasLandingCardSettingsList<Card: Identifiable & Hashable & Sendable>(
    title: String,
    cards: [Card],
    order: [Card],
    isVisible: @escaping (Card) -> Bool,
    titleFor: @escaping (Card) -> String,
    onToggleVisibility: @MainActor @escaping (Card, Bool) -> Void,
    onMove: @MainActor @escaping (Card, AtlasLandingCardMoveDirection) -> Void
) -> some View {
    let orderedCards = cards.sorted { atlasOrderIndex($0, order: order) < atlasOrderIndex($1, order: order) }

    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
        Text(title)
            .atlasTextRole(.deckEyebrow)
            .foregroundStyle(AtlasPalette.primary)

        ForEach(Array(orderedCards.enumerated()), id: \.element.id) { index, card in
            HStack(spacing: AtlasSpacing.small) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(titleFor(card))
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(isVisible(card) ? "Visible on the landing surface." : "Hidden from the landing surface.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { isVisible(card) },
                    set: {
                        AtlasFeedback.selection()
                        onToggleVisibility(card, $0)
                    }
                ))
                .labelsHidden()

                VStack(spacing: 4) {
                    AtlasMiniIconControlButton(
                        systemImage: "chevron.up",
                        accessibilityLabel: "Move \(titleFor(card)) up",
                        isEnabled: index > 0
                    ) {
                        AtlasFeedback.selection()
                        onMove(card, .up)
                    }

                    AtlasMiniIconControlButton(
                        systemImage: "chevron.down",
                        accessibilityLabel: "Move \(titleFor(card)) down",
                        isEnabled: index < orderedCards.count - 1
                    ) {
                        AtlasFeedback.selection()
                        onMove(card, .down)
                    }
                }
                .foregroundStyle(AtlasPalette.textSecondary)
            }
            .padding(.vertical, 4)
        }
    }
}

private func atlasSetVisibility<Card: Equatable & Sendable>(
    card: Card,
    isVisible: Bool,
    hiddenCards: inout [Card]
) {
    hiddenCards.removeAll { $0 == card }
    if isVisible == false {
        hiddenCards.append(card)
    }
}

private func atlasMove<Card: Equatable & Sendable>(
    card: Card,
    direction: AtlasLandingCardMoveDirection,
    order: inout [Card],
    fallback: [Card]
) {
    if order.isEmpty {
        order = fallback
    } else {
        for item in fallback where order.contains(item) == false {
            order.append(item)
        }
    }

    guard let index = order.firstIndex(of: card) else {
        return
    }

    let destination: Int
    switch direction {
    case .up:
        destination = max(index - 1, 0)
    case .down:
        destination = min(index + 1, order.count - 1)
    }
    guard destination != index else {
        return
    }

    order.swapAt(index, destination)
}

private func atlasOrderIndex<Card: Equatable & Sendable>(_ card: Card, order: [Card]) -> Int {
    order.firstIndex(of: card) ?? order.count
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

private func atlasSettingsAccountModeSummary(
    settingsSnapshot: AtlasSettingsSnapshot
) -> String {
    switch settingsSnapshot.accountStartMode {
    case .guest:
        return "This profile started in guest mode."
    case .create:
        return "This profile started with account creation enabled. Local tracking still remains available."
    case .signIn:
        return "This profile started through sign-in. Local-first access remains intact."
    case nil:
        return settingsSnapshot.accountMode == .guest
            ? "This profile is local-first and guest-friendly."
            : "This profile can keep local data while account features stay optional."
    }
}

@MainActor
private func atlasSettingsSyncSummary(
    model: AtlasAppModel,
    state: AtlasSettingsViewState
) -> String {
    if model.cloudSession?.newerBackupAvailable == true {
        return "Newer remote backup available"
    }
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

private struct AtlasSettingsHubLink: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    let detail: String?
    let symbolName: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button {
            AtlasFeedback.navigation()
            action()
        } label: {
            HStack(spacing: AtlasSpacing.small) {
                Image(systemName: symbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(tint.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    if let detail, detail.isEmpty == false {
                        Text(detail)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 54)
            .padding(.horizontal, AtlasSpacing.medium)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AtlasPalette.secondaryFill)
            )
        }
        .buttonStyle(AtlasSurfacePressButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(detail ?? "")
    }
}

private struct AtlasSettingsMetricSummaryRow: View {
    let metrics: [AtlasMetricItem]

    var body: some View {
        HStack(spacing: AtlasSpacing.small) {
            ForEach(metrics) { metric in
                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.title)
                        .atlasTextRole(.metricLabel)
                        .foregroundStyle(metric.tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)

                    Text(metric.value)
                        .atlasTextRole(.metricValue)
                        .foregroundStyle(AtlasPalette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AtlasPalette.surfaceTop.opacity(0.95), metric.tint.opacity(0.08)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(metric.tint.opacity(0.22), lineWidth: 1)
                )
            }
        }
        .padding(.vertical, 2)
    }
}

private struct AtlasSettingsAccountScreen: View {
    let model: AtlasAppModel
    let state: AtlasSettingsViewState
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        AtlasScreen {
            AtlasSectionCard(style: .task, title: "Account & sync") {
                AtlasSettingsMetricSummaryRow(metrics: [
                    AtlasMetricItem(id: "account_mode", title: "Mode", value: state.settingsSnapshot.accountMode.rawValue.capitalized),
                    AtlasMetricItem(
                        id: "sync_state",
                        title: "Sync",
                        value: atlasSettingsSyncSummary(model: model, state: state),
                        tint: model.cloudSession == nil ? AtlasPalette.secondaryText : AtlasPalette.success
                    )
                ])

                AtlasCalloutRow(
                    systemImage: model.cloudSession == nil ? "internaldrive" : "arrow.triangle.2.circlepath.icloud",
                    title: model.cloudSession == nil ? "Account mode" : "Recovery-ready account connected",
                    detail: atlasSettingsAccountModeSummary(settingsSnapshot: state.settingsSnapshot),
                    tint: model.cloudSession == nil ? AtlasPalette.primary : AtlasPalette.success
                )

                Text(model.cloudStatusDescription)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                if model.isPerformingCloudAction {
                    AtlasSectionCard(style: .utility, title: "Working") {
                        HStack(spacing: AtlasSpacing.small) {
                            ProgressView()
                                .tint(AtlasPalette.primary)
                            Text("Updating cloud sync and recovery state.")
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                }

                if let session = model.cloudSession {
                    Text("Connected account: \(session.email)")
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.primary)

                    if let lastSyncAt = session.lastSyncAt {
                        Text("Cloud backup updated \(lastSyncAt.formatted(date: .abbreviated, time: .shortened))")
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    if session.newerBackupAvailable {
                        AtlasCalloutRow(
                            systemImage: "arrow.triangle.2.circlepath.icloud",
                            title: "A newer Atlas Cloud backup is available",
                            detail: "Restore it when you want this device to catch up. Local data remains intact until you choose that restore.",
                            tint: AtlasPalette.primary
                        )
                    }

                    Button("Sync to Atlas Cloud") {
                        AtlasFeedback.navigation()
                        Task { await model.syncToCloud() }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                    .disabled(model.isPerformingCloudAction)

                    HStack(spacing: AtlasSpacing.small) {
                        Button("Restore latest cloud backup") {
                            AtlasFeedback.caution()
                            Task { await model.restoreLatestCloudBackup() }
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                        .disabled(model.isPerformingCloudAction)

                        Button("Sign out") {
                            AtlasFeedback.caution()
                            Task { await model.signOutOfCloud() }
                        }
                        .buttonStyle(AtlasTertiaryButtonStyle())
                        .disabled(model.isPerformingCloudAction)
                    }
                } else if model.dependencies.cloudSync.isConfigured() {
                    TextField("Email", text: $email)
                        .autocorrectionDisabled()
                        .atlasStandaloneInputSurface()
                    SecureField("Password", text: $password)
                        .atlasStandaloneInputSurface()

                    Button("Sign in") {
                        AtlasFeedback.navigation()
                        Task { await model.signInToCloud(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password) }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                    .disabled(model.isPerformingCloudAction || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)

                    HStack(spacing: AtlasSpacing.small) {
                        Button("Continue with Google") {
                            AtlasFeedback.navigation()
                            Task { await model.signInToCloud(with: .google) }
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                        .disabled(model.isPerformingCloudAction)

                        Button("Continue with Apple") {
                            AtlasFeedback.navigation()
                            Task { await model.signInToCloud(with: .apple) }
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                        .disabled(model.isPerformingCloudAction)
                    }

                    Button("Create Atlas account") {
                        AtlasFeedback.navigation()
                        Task { await model.signUpToCloud(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password) }
                    }
                    .buttonStyle(AtlasTertiaryButtonStyle())
                    .disabled(model.isPerformingCloudAction || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
                } else {
                    AtlasCalloutRow(
                        systemImage: "internaldrive",
                        title: "Atlas Cloud is not active on this build",
                        detail: "This device stays local-first until recovery sync is configured again.",
                        tint: AtlasPalette.secondaryText
                    )
                }

                Button("Reset onboarding state") {
                    AtlasFeedback.selection()
                    Task { await model.resetOnboarding() }
                }
                .buttonStyle(AtlasWarningButtonStyle())
            }

            AtlasSectionCard {
                AtlasSettingsToggleRow(
                    title: "Enable on-device summaries",
                    subtitle: "Generate on-device recaps.",
                    isOn: Binding(
                        get: { state.settingsSnapshot.summarySettings.onDeviceEnabled },
                        set: { value in
                            state.settingsSnapshot.summarySettings.onDeviceEnabled = value
                            model.settingsSnapshot.summarySettings.onDeviceEnabled = value
                            Task { await model.updateSummarySettings(AtlasSummarySettingsUpdate(onDeviceEnabled: value)) }
                        }
                    ),
                    isEnabled: model.dependencies.featureFlags.flags.boundedSummaries
                )
            }
        }
        .navigationTitle("Account & Sync")
        .atlasInlineNavigationTitle()
    }
}

private struct AtlasSettingsPrivacyScreen: View {
    let model: AtlasAppModel
    let state: AtlasSettingsViewState

    var body: some View {
        AtlasScreen {
            AtlasSectionCard(style: .task, title: "Privacy & trust") {
                AtlasMetricStrip(metrics: [
                    AtlasMetricItem(id: "privacy_mode", title: "Display", value: state.settingsSnapshot.trustVaultStatus.renderMode.rawValue.capitalized),
                    AtlasMetricItem(id: "account_boundary", title: "Account", value: state.settingsSnapshot.accountMode.rawValue.capitalized, tint: AtlasPalette.secondaryText)
                ])

                Picker(
                    "Display mode",
                    selection: Binding(
                        get: { state.settingsSnapshot.trustVaultStatus.renderMode },
                        set: { value in
                            state.settingsSnapshot.trustVaultStatus.renderMode = value
                            model.settingsSnapshot.trustVaultStatus.renderMode = value
                            Task { await model.updatePrivacyRenderMode(value) }
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
        }
        .navigationTitle("Privacy & Trust")
        .atlasInlineNavigationTitle()
    }
}

private struct AtlasSettingsNotificationsScreen: View {
    let model: AtlasAppModel
    let state: AtlasSettingsViewState
    @State private var showCalendarAdvanced = false

    var body: some View {
        let reminderPreview = model.reminderPreview()

        AtlasScreen {
            AtlasSectionCard(style: .task, title: "Permissions") {
                AtlasMetricStrip(metrics: [
                    AtlasMetricItem(
                        id: "notification_permission",
                        title: "Notifications",
                        value: permissionLabel(state.notificationPermissionStatus),
                        tint: state.notificationPermissionStatus == .authorized ? AtlasPalette.success : AtlasPalette.secondaryText
                    ),
                    AtlasMetricItem(
                        id: "calendar_permission",
                        title: "Calendar",
                        value: calendarPermissionLabel(state.calendarPermissionStatus),
                        tint: state.calendarPermissionStatus.canListCalendars ? AtlasPalette.success : AtlasPalette.secondaryText
                    )
                ])

                if state.notificationPermissionStatus == .denied {
                        AtlasCalloutRow(
                            systemImage: "bell.slash.fill",
                            title: "Notification permission is off",
                            detail: "Reminders and weekly review prompts are blocked until notifications are re-enabled.",
                            tint: AtlasPalette.warning
                        )

                    Button("Open system settings") {
                        atlasOpenSystemSettings()
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                } else if state.notificationPermissionStatus != .authorized {
                    Text("Reminder alerts are off until notifications are allowed.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    Button("Allow notifications") {
                        AtlasFeedback.selection()
                        Task { await model.requestReminderPermission() }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                }

                if state.calendarPermissionStatus == .denied {
                        AtlasCalloutRow(
                            systemImage: "calendar.badge.exclamationmark",
                            title: "Calendar access is off",
                            detail: "Mirroring is paused until calendar access is restored.",
                            tint: AtlasPalette.warning
                        )

                    Button("Open system settings") {
                        atlasOpenSystemSettings()
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                } else if state.calendarPermissionStatus == .restricted {
                    AtlasCalloutRow(
                        systemImage: "calendar.badge.exclamationmark",
                        title: "Calendar access is restricted",
                        detail: "Schedule entries can't be mirrored while calendar access is restricted on this device.",
                        tint: AtlasPalette.warning
                    )
                } else if state.calendarPermissionStatus == .unavailable {
                        AtlasCalloutRow(
                            systemImage: "calendar.badge.minus",
                            title: "Calendar isn’t available here",
                            detail: "Calendar mirroring is unavailable on this device.",
                            tint: AtlasPalette.secondaryText
                        )
                } else if state.calendarPermissionStatus.canListCalendars == false {
                    Text("Calendar mirroring is optional.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    Button("Allow calendar access") {
                        AtlasFeedback.selection()
                        Task { await model.requestCalendarPermission() }
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }

            AtlasSectionCard(style: .task, title: "Reminder delivery") {
                AtlasSettingsToggleRow(
                    title: "Enable local reminders",
                    subtitle: "Schedule local reminder alerts.",
                    isOn: Binding(
                        get: { state.reminderSettings.remindersEnabled },
                        set: { value in
                            state.reminderSettings.remindersEnabled = value
                            model.reminderSettings.remindersEnabled = value
                            Task { await model.updateReminderSettings(AtlasReminderPreferenceUpdate(remindersEnabled: value)) }
                        }
                    )
                )

                AtlasSettingsToggleRow(
                    title: "Weekly review reminders",
                    subtitle: "Send a reminder when a weekly review is ready.",
                    isOn: Binding(
                        get: { state.settingsSnapshot.weeklyReviewReminderSettings.enabled },
                        set: { value in
                            state.settingsSnapshot.weeklyReviewReminderSettings.enabled = value
                            model.settingsSnapshot.weeklyReviewReminderSettings.enabled = value
                            Task { await model.updateWeeklyReviewReminderSettings(AtlasWeeklyReviewReminderSettings(enabled: value)) }
                        }
                    )
                )

                if state.reminderSettings.remindersEnabled {
                    if state.notificationPermissionStatus == .denied {
                        AtlasCalloutRow(
                            systemImage: "bell.badge.slash",
                            title: "Reminder delivery is blocked",
                            detail: "Reminder settings stay saved locally, but alerts will not fire until notification permission is restored.",
                            tint: AtlasPalette.warning
                        )
                    }

                    AtlasSettingsMenuRow(
                        title: "Reminder copy",
                        subtitle: "Choose how much detail reminder alerts show.",
                        selectionTitle: state.reminderSettings.privacyMode.title,
                        options: AtlasReminderPrivacyMode.allCases.map {
                            AtlasSettingsMenuOption(title: $0.title, value: $0)
                        },
                        selection: Binding(
                            get: { state.reminderSettings.privacyMode },
                            set: { value in
                                state.reminderSettings.privacyMode = value
                                model.reminderSettings.privacyMode = value
                                Task { await model.updateReminderSettings(AtlasReminderPreferenceUpdate(privacyMode: value)) }
                            }
                        )
                    )

                    AtlasSettingsMenuRow(
                        title: "Lead time",
                        subtitle: "Choose how early reminders fire.",
                        selectionTitle: atlasReminderLeadTimeTitle(state.reminderSettings.leadTimeMinutes),
                        options: AtlasReminderLeadTime.allCases.map {
                            AtlasSettingsMenuOption(title: $0.title, value: $0.minutes)
                        },
                        selection: Binding(
                            get: { state.reminderSettings.leadTimeMinutes },
                            set: { value in
                                state.reminderSettings.leadTimeMinutes = value
                                model.reminderSettings.leadTimeMinutes = value
                                Task { await model.updateReminderSettings(AtlasReminderPreferenceUpdate(leadTimeMinutes: value)) }
                            }
                        )
                    )

                    AtlasSectionCard(style: .utility, title: "Preview") {
                        AtlasSettingsStatusRow(title: "Title", value: reminderPreview.title)
                        AtlasSettingsStatusRow(title: "Body", value: reminderPreview.body)
                        AtlasSettingsStatusRow(title: "Mode", value: reminderPreview.effectiveMode.title)
                    }
                } else {
                    Text("Reminder copy and lead time are hidden until reminders are enabled.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }

            AtlasSectionCard(style: .utility, title: "External calendar") {
                AtlasSettingsToggleRow(
                    title: "Mirror upcoming schedule",
                    subtitle: "Write upcoming schedule entries into the selected calendar.",
                    isOn: Binding(
                        get: { state.settingsSnapshot.externalCalendarSettings.syncEnabled },
                        set: { value in
                            state.settingsSnapshot.externalCalendarSettings.syncEnabled = value
                            model.settingsSnapshot.externalCalendarSettings.syncEnabled = value
                            Task { await model.updateExternalCalendarEnabled(value) }
                        }
                    )
                )

                AtlasSettingsStatusRow(
                    title: "Selected",
                    value: state.settingsSnapshot.externalCalendarSettings.selectedCalendarTitle ?? "None"
                )
                AtlasSettingsStatusRow(
                    title: "Last sync",
                    value: atlasCalendarSyncStatusLabel(state.settingsSnapshot.externalCalendarSettings.lastSyncAt)
                )

                if state.settingsSnapshot.externalCalendarSettings.syncEnabled
                    && state.settingsSnapshot.externalCalendarSettings.selectedCalendarID == nil {
                    AtlasCalloutRow(
                        systemImage: "calendar.badge.clock",
                        title: "Choose a destination calendar",
                        detail: "Mirroring is on, but no destination calendar is selected.",
                        tint: AtlasPalette.primary
                    )
                }

                if let lastError = state.settingsSnapshot.externalCalendarSettings.lastError,
                   lastError.isEmpty == false {
                    AtlasCalloutRow(
                        systemImage: "exclamationmark.triangle.fill",
                        title: "Calendar sync needs attention",
                        detail: lastError,
                        tint: AtlasPalette.warning
                    )
                }

                if state.calendarPermissionStatus.canListCalendars {
                    AtlasSettingsDisclosureRow(
                        title: "Calendar destination",
                        detail: state.settingsSnapshot.externalCalendarSettings.selectedCalendarTitle ?? "Choose where mirrored schedule entries go.",
                        isExpanded: $showCalendarAdvanced,
                        tint: AtlasPalette.primary
                    )

                    if showCalendarAdvanced {
                        if state.availableExternalCalendars.isEmpty {
                            AtlasCalloutRow(
                                systemImage: "calendar.badge.minus",
                                title: "No writable calendars found",
                                detail: "Calendar access is on, but there are no writable calendars available.",
                                tint: AtlasPalette.secondaryText
                            )
                        }

                        AtlasSettingsMenuRow(
                            title: "Destination calendar",
                            subtitle: "Choose where mirrored schedule entries should be written.",
                            selectionTitle: state.settingsSnapshot.externalCalendarSettings.selectedCalendarTitle ?? "Choose a calendar",
                            options: [AtlasSettingsMenuOption(title: "Choose a calendar", value: "")] + state.availableExternalCalendars.map {
                                AtlasSettingsMenuOption(title: "\($0.title) • \($0.sourceTitle)", value: $0.id)
                            },
                            selection: Binding(
                                get: { state.settingsSnapshot.externalCalendarSettings.selectedCalendarID ?? "" },
                                set: { value in
                                    if value.isEmpty {
                                        Task { await model.clearExternalCalendarSelection() }
                                        return
                                    }
                                    guard let descriptor = state.availableExternalCalendars.first(where: { $0.id == value }) else {
                                        return
                                    }
                                    state.settingsSnapshot.externalCalendarSettings.selectedCalendarID = descriptor.id
                                    state.settingsSnapshot.externalCalendarSettings.selectedCalendarTitle = descriptor.title
                                    model.settingsSnapshot.externalCalendarSettings.selectedCalendarID = descriptor.id
                                    model.settingsSnapshot.externalCalendarSettings.selectedCalendarTitle = descriptor.title
                                    Task { await model.updateExternalCalendarSelection(descriptor) }
                                }
                            )
                        )

                        VStack(spacing: AtlasSpacing.small) {
                            Button("Sync now") {
                                AtlasFeedback.selection()
                                Task { await model.syncExternalCalendarNow() }
                            }
                            .buttonStyle(AtlasPrimaryButtonStyle())
                            .disabled(state.settingsSnapshot.externalCalendarSettings.syncEnabled == false)

                            Button("Clear calendar") {
                                AtlasFeedback.selection()
                                Task { await model.clearExternalCalendarSelection() }
                            }
                            .buttonStyle(AtlasTertiaryButtonStyle())
                            .disabled(state.settingsSnapshot.externalCalendarSettings.selectedCalendarID == nil)
                        }
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .atlasInlineNavigationTitle()
    }
}

private struct AtlasSettingsServicesScreen: View {
    let model: AtlasAppModel
    let state: AtlasSettingsViewState

    var body: some View {
        let health = model.settingsSnapshot.healthScaffold
        let appleHealthConnection = health.connections.first(where: { $0.providerKey == .appleHealth })

        AtlasScreen {
            AtlasSectionCard(style: .task, title: "Services & devices") {
                AtlasMetricStrip(metrics: [
                    AtlasMetricItem(
                        id: "services_health",
                        title: "Health",
                        value: appleHealthConnection?.connected == true ? "Connected" : "Optional",
                        tint: appleHealthConnection?.connected == true ? AtlasPalette.success : AtlasPalette.secondaryText
                    ),
                    AtlasMetricItem(
                        id: "services_labs",
                        title: "Labs",
                        value: state.settingsSnapshot.labsEnabled ? "On" : "Off",
                        tint: state.settingsSnapshot.labsEnabled ? AtlasPalette.primary : AtlasPalette.secondaryText
                    ),
                    AtlasMetricItem(
                        id: "services_watch",
                        title: "Watch",
                        value: state.settingsSnapshot.retentionSettings.companionEnabled ? "Ready" : "Quiet",
                        tint: state.settingsSnapshot.retentionSettings.companionEnabled ? AtlasPalette.success : AtlasPalette.secondaryText
                    )
                ])

                Text("Only the services you enable extend the local core.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                if appleHealthConnection?.connected != true
                    && state.settingsSnapshot.labsEnabled == false
                    && state.settingsSnapshot.retentionSettings.companionEnabled == false {
                    AtlasCalloutRow(
                        systemImage: "shield.lefthalf.filled",
                        title: "Services stay quiet by default",
                        detail: "Apple Health, labs, and companion cues are off until you enable them.",
                        tint: AtlasPalette.secondaryText
                    )
                }
            }

            AtlasSectionCard(title: "Apple Health") {
                AtlasSettingsStatusRow(
                    title: "Connection",
                    value: appleHealthConnection?.connected == true ? "Connected" : "Optional"
                )

                if appleHealthConnection?.connected == true {
                    AtlasSettingsStatusRow(title: "Weight entries", value: "\(health.syncedWeightEntryCount)")
                    AtlasSettingsStatusRow(title: "Workout entries", value: "\(health.syncedWorkoutEntryCount)")
                }

                if let appleHealthConnection, appleHealthConnection.connected {
                    AtlasSettingsStatusRow(
                        title: "Last sync",
                        value: atlasCalendarSyncStatusLabel(appleHealthConnection.lastSyncAt)
                    )

                    if let lastError = appleHealthConnection.lastError,
                       lastError.isEmpty == false {
                        AtlasCalloutRow(
                            systemImage: "exclamationmark.triangle.fill",
                            title: "Apple Health needs attention",
                            detail: lastError,
                            tint: AtlasPalette.warning
                        )
                    }
                }

                Text(
                    appleHealthConnection?.connected == true
                        ? "Only the health data you allow is read."
                        : "Apple Health is optional."
                )
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                if health.isAvailable {
                    if appleHealthConnection?.connected == true {
                        Button("Disconnect Apple Health") {
                            AtlasFeedback.caution()
                            Task { await model.disconnectHealthKit() }
                        }
                        .buttonStyle(AtlasTertiaryButtonStyle())
                    } else {
                        Button("Connect Apple Health") {
                            AtlasFeedback.navigation()
                            Task { await model.connectHealthKit() }
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                    }
                } else {
                    AtlasCalloutRow(
                        systemImage: "heart.slash",
                        title: "Apple Health is unavailable",
                        detail: "Apple Health isn't available on this device.",
                        tint: AtlasPalette.secondaryText
                    )
                }
            }

            AtlasSectionCard(title: "Lab tracking") {
                AtlasSettingsToggleRow(
                    title: "Enable advanced lab tracking",
                    subtitle: "Turn on lab work and ranges when you need them.",
                    isOn: Binding(
                        get: { state.settingsSnapshot.labsEnabled },
                        set: { value in
                            state.settingsSnapshot.labsEnabled = value
                            model.settingsSnapshot.labsEnabled = value
                            Task { await model.updateLabsEnabled(value) }
                        }
                    )
                )

                if state.settingsSnapshot.labsEnabled {
                    Button("Open lab tracking") {
                        AtlasFeedback.selection()
                        model.open(.labs)
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                } else {
                    Text("Lab ranges stay hidden until you turn them on.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }

            AtlasSectionCard(title: "Watch companion") {
                AtlasSettingsStatusRow(
                    title: "Companion cues",
                    value: state.settingsSnapshot.retentionSettings.companionEnabled ? "Ready" : "Quiet"
                )

                Text("Use the focused companion for next-due checks, recovery handling, and quick context.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                Button("Open Apple Watch companion") {
                    AtlasFeedback.navigation()
                    model.routePath.removeAll()
                    model.activeTab = .today
                    model.open(.watchCompanion)
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
            }
        }
        .navigationTitle("Services")
        .atlasInlineNavigationTitle()
    }
}

private struct AtlasSettingsPersonalizationScreen: View {
    let model: AtlasAppModel
    let state: AtlasSettingsViewState
    @State private var mascotNicknameDraft = ""
    @State private var rewardsWorkoutGoal = 3
    @State private var rewardsSelfGoalTarget = 2
    @State private var showSurfaceLayoutTools = false
    @State private var showMascotControls = false

    var body: some View {
        AtlasScreen {
            AtlasSectionCard(title: "Experience") {
                if state.settingsSnapshot.surfacePreferences.stackDashboardEnabled == false
                    && state.settingsSnapshot.surfacePreferences.biometricsOverlayEnabled == false {
                    AtlasCalloutRow(
                        systemImage: "sparkles.rectangle.stack",
                        title: "The shell is minimal by default",
                        detail: nil,
                        tint: AtlasPalette.secondaryText
                    )
                }

                AtlasSettingsToggleRow(
                    title: "Enable stack dashboard",
                    isOn: Binding(
                        get: { state.settingsSnapshot.surfacePreferences.stackDashboardEnabled },
                        set: { value in
                            var prefs = state.settingsSnapshot.surfacePreferences
                            prefs.stackDashboardEnabled = value
                            state.settingsSnapshot.surfacePreferences = prefs
                            model.settingsSnapshot.surfacePreferences = prefs
                            Task { await model.updateSurfacePreferences(prefs) }
                        }
                    )
                )

                AtlasSettingsToggleRow(
                    title: "Enable biometrics overlays",
                    isOn: Binding(
                        get: { state.settingsSnapshot.surfacePreferences.biometricsOverlayEnabled },
                        set: { value in
                            var prefs = state.settingsSnapshot.surfacePreferences
                            prefs.biometricsOverlayEnabled = value
                            state.settingsSnapshot.surfacePreferences = prefs
                            model.settingsSnapshot.surfacePreferences = prefs
                            Task { await model.updateSurfacePreferences(prefs) }
                        }
                    )
                )

                if state.settingsSnapshot.surfacePreferences.biometricsOverlayEnabled {
                    AtlasSettingsToggleRow(
                        title: "Show protocol changes in overlays",
                        isOn: Binding(
                            get: { state.settingsSnapshot.surfacePreferences.biometricsOverlayShowsProtocolChanges },
                            set: { value in
                                var prefs = state.settingsSnapshot.surfacePreferences
                                prefs.biometricsOverlayShowsProtocolChanges = value
                                state.settingsSnapshot.surfacePreferences = prefs
                                model.settingsSnapshot.surfacePreferences = prefs
                                Task { await model.updateSurfacePreferences(prefs) }
                            }
                        )
                    )
                }

                AtlasSettingsDisclosureRow(
                    title: "Adjust landing layouts",
                    detail: "\(state.settingsSnapshot.surfacePreferences.visibleTodayCards.count) Today cards and \(state.settingsSnapshot.surfacePreferences.visibleInsightsCards.count) analysis cards are currently visible.",
                    isExpanded: $showSurfaceLayoutTools,
                    tint: AtlasPalette.primary
                )

                if showSurfaceLayoutTools {
                    atlasLandingCardSettingsList(
                        title: "Today layout",
                        cards: AtlasTodayLandingCard.allCases,
                        order: state.settingsSnapshot.surfacePreferences.todayCardOrder,
                        isVisible: { state.settingsSnapshot.surfacePreferences.isTodayCardVisible($0) },
                        titleFor: { $0.title },
                        onToggleVisibility: { card, isVisible in
                            var prefs = state.settingsSnapshot.surfacePreferences
                            atlasSetVisibility(card: card, isVisible: isVisible, hiddenCards: &prefs.hiddenTodayCards)
                            state.settingsSnapshot.surfacePreferences = prefs
                            model.settingsSnapshot.surfacePreferences = prefs
                            Task { await model.updateSurfacePreferences(prefs) }
                        },
                        onMove: { card, direction in
                            var prefs = state.settingsSnapshot.surfacePreferences
                            atlasMove(card: card, direction: direction, order: &prefs.todayCardOrder, fallback: AtlasTodayLandingCard.allCases)
                            state.settingsSnapshot.surfacePreferences = prefs
                            model.settingsSnapshot.surfacePreferences = prefs
                            Task { await model.updateSurfacePreferences(prefs) }
                        }
                    )

                    atlasLandingCardSettingsList(
                        title: "Insights layout",
                        cards: AtlasInsightsLandingCard.allCases,
                        order: state.settingsSnapshot.surfacePreferences.insightsCardOrder,
                        isVisible: { state.settingsSnapshot.surfacePreferences.isInsightsCardVisible($0) },
                        titleFor: { $0.title },
                        onToggleVisibility: { card, isVisible in
                            var prefs = state.settingsSnapshot.surfacePreferences
                            atlasSetVisibility(card: card, isVisible: isVisible, hiddenCards: &prefs.hiddenInsightsCards)
                            state.settingsSnapshot.surfacePreferences = prefs
                            model.settingsSnapshot.surfacePreferences = prefs
                            Task { await model.updateSurfacePreferences(prefs) }
                        },
                        onMove: { card, direction in
                            var prefs = state.settingsSnapshot.surfacePreferences
                            atlasMove(card: card, direction: direction, order: &prefs.insightsCardOrder, fallback: AtlasInsightsLandingCard.allCases)
                            state.settingsSnapshot.surfacePreferences = prefs
                            model.settingsSnapshot.surfacePreferences = prefs
                            Task { await model.updateSurfacePreferences(prefs) }
                        }
                    )
                }
            }

            AtlasSectionCard(style: .reward, title: "Rewards & mascot") {
                AtlasSettingsToggleRow(
                    title: "Show streaks and badges",
                    isOn: Binding(
                        get: { state.settingsSnapshot.rewardsSettings.enabled },
                        set: { value in
                            state.settingsSnapshot.rewardsSettings.enabled = value
                            model.settingsSnapshot.rewardsSettings.enabled = value
                            Task { await model.updateRewardsSettings(AtlasRewardsSettingsUpdate(enabled: value)) }
                        }
                    ),
                    isEnabled: true
                )

                if state.settingsSnapshot.rewardsSettings.enabled {
                    AtlasSettingsStepperCard(
                        title: "Weekly workout goal",
                        subtitle: nil,
                        value: $rewardsWorkoutGoal,
                        range: 1...7,
                        isEnabled: state.settingsSnapshot.rewardsSettings.enabled,
                        tint: AtlasPalette.reward
                    )

                    AtlasSettingsStepperCard(
                        title: "Weekly self goal target",
                        subtitle: nil,
                        value: $rewardsSelfGoalTarget,
                        range: 1...7,
                        isEnabled: state.settingsSnapshot.rewardsSettings.enabled,
                        tint: AtlasPalette.primary
                    )
                } else {
                    Text("Goals and mascot recap prompts stay hidden until rewards are enabled.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                AtlasSettingsMenuRow(
                    title: "Ambient mascot presence",
                    subtitle: state.settingsSnapshot.ambientMascotPresence.detail,
                    selectionTitle: state.settingsSnapshot.ambientMascotPresence.title,
                    options: AtlasAmbientMascotPresence.allCases.map {
                        AtlasSettingsMenuOption(title: $0.title, value: $0)
                    },
                    selection: Binding(
                        get: { state.settingsSnapshot.ambientMascotPresence },
                        set: { presence in
                            state.settingsSnapshot.ambientMascotPresence = presence
                            model.settingsSnapshot.ambientMascotPresence = presence
                            Task { await model.updateAmbientMascotPresence(presence) }
                        }
                    )
                )

                AtlasSettingsDisclosureRow(
                    title: "Mascot controls",
                    detail: state.settingsSnapshot.mascotNickname.map { "Line \(state.settingsSnapshot.mascotSelection.title), nickname \($0)." }
                        ?? "Line \(state.settingsSnapshot.mascotSelection.title), no nickname set.",
                    isExpanded: $showMascotControls,
                    tint: AtlasPalette.reward
                )

                if showMascotControls {
                    AtlasSettingsMenuRow(
                        title: "Mascot line",
                        subtitle: nil,
                        selectionTitle: state.settingsSnapshot.mascotSelection.title,
                        options: AtlasMascotSelection.allCases.map {
                            AtlasSettingsMenuOption(title: $0.title, value: $0)
                        },
                        selection: Binding(
                            get: { state.settingsSnapshot.mascotSelection },
                            set: { selection in
                                state.settingsSnapshot.mascotSelection = selection
                                model.settingsSnapshot.mascotSelection = selection
                                Task { await model.updateMascotSelection(selection) }
                            }
                        )
                    )

                    AtlasSettingsStatusRow(
                        title: "Current form",
                        value: state.settingsSnapshot.mascotSelection.title(
                            for: state.settingsSnapshot.highestUnlockedStage(for: state.settingsSnapshot.mascotSelection)
                        )
                    )

                    TextField("Mascot nickname", text: $mascotNicknameDraft)
                        .autocorrectionDisabled()
                        .atlasStandaloneInputSurface()

                    Button("Save mascot nickname") {
                        let trimmed = mascotNicknameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        AtlasFeedback.selection()
                        Task { await model.updateMascotNickname(trimmed.isEmpty ? nil : trimmed) }
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())

                    AtlasSettingsToggleRow(
                        title: "Daily mascot recap prompts",
                        isOn: Binding(
                            get: { state.settingsSnapshot.mascotRecapNotificationSettings.dailyEnabled },
                            set: { value in
                                var settings = state.settingsSnapshot.mascotRecapNotificationSettings
                                settings.dailyEnabled = value
                                state.settingsSnapshot.mascotRecapNotificationSettings = settings
                                model.settingsSnapshot.mascotRecapNotificationSettings = settings
                                Task { await model.updateMascotRecapNotificationSettings(settings) }
                            }
                        ),
                        isEnabled: state.settingsSnapshot.rewardsSettings.enabled
                    )

                    AtlasSettingsToggleRow(
                        title: "Weekly mascot recap prompts",
                        isOn: Binding(
                            get: { state.settingsSnapshot.mascotRecapNotificationSettings.weeklyEnabled },
                            set: { value in
                                var settings = state.settingsSnapshot.mascotRecapNotificationSettings
                                settings.weeklyEnabled = value
                                state.settingsSnapshot.mascotRecapNotificationSettings = settings
                                model.settingsSnapshot.mascotRecapNotificationSettings = settings
                                Task { await model.updateMascotRecapNotificationSettings(settings) }
                            }
                        ),
                        isEnabled: state.settingsSnapshot.rewardsSettings.enabled
                    )

                    AtlasMascotHomeCard(
                        selection: state.settingsSnapshot.mascotSelection,
                        nickname: state.settingsSnapshot.mascotNickname,
                        rewardsSnapshot: state.rewardsSnapshot,
                        history: state.settingsSnapshot.mascotEvolutionHistory,
                        moments: state.settingsSnapshot.mascotMoments,
                        compact: true,
                        onOpenDetail: {
                            model.open(.mascot)
                        }
                    )
                }
            }

            AtlasSectionCard(style: .utility, title: "Calm continuity") {
                if model.dependencies.featureFlags.flags.calmRetention {
                    AtlasSettingsToggleRow(
                        title: "Show calm continuity",
                        isOn: Binding(
                            get: { state.settingsSnapshot.retentionSettings.progressEnabled },
                            set: { value in
                                state.settingsSnapshot.retentionSettings.progressEnabled = value
                                model.settingsSnapshot.retentionSettings.progressEnabled = value
                                Task { await model.updateRetentionSettings(AtlasRetentionSettingsUpdate(progressEnabled: value)) }
                            }
                        ),
                        isEnabled: true
                    )

                    if state.settingsSnapshot.retentionSettings.progressEnabled {
                        AtlasSettingsToggleRow(
                            title: "Enable companion cues",
                            isOn: Binding(
                                get: { state.settingsSnapshot.retentionSettings.companionEnabled },
                                set: { value in
                                    state.settingsSnapshot.retentionSettings.companionEnabled = value
                                    model.settingsSnapshot.retentionSettings.companionEnabled = value
                                    Task { await model.updateRetentionSettings(AtlasRetentionSettingsUpdate(companionEnabled: value)) }
                                }
                            ),
                            isEnabled: true
                        )
                    }
                } else {
                    AtlasCalloutRow(
                        systemImage: "pause.circle",
                        title: "Calm continuity is unavailable",
                        detail: nil,
                        tint: AtlasPalette.secondaryText
                    )
                }
            }
        }
        .navigationTitle("Personalization")
        .atlasInlineNavigationTitle()
        .task(id: state.settingsSnapshot.mascotNickname ?? "") {
            if mascotNicknameDraft != (state.settingsSnapshot.mascotNickname ?? "") {
                mascotNicknameDraft = state.settingsSnapshot.mascotNickname ?? ""
            }
        }
        .task(id: state.settingsSnapshot.rewardsSettings.weeklyWorkoutGoal) {
            rewardsWorkoutGoal = state.settingsSnapshot.rewardsSettings.weeklyWorkoutGoal
        }
        .task(id: state.settingsSnapshot.rewardsSettings.weeklySelfGoalTarget) {
            rewardsSelfGoalTarget = state.settingsSnapshot.rewardsSettings.weeklySelfGoalTarget
        }
        .onChange(of: rewardsWorkoutGoal) { _, newValue in
            guard newValue != state.settingsSnapshot.rewardsSettings.weeklyWorkoutGoal else {
                return
            }
            state.settingsSnapshot.rewardsSettings.weeklyWorkoutGoal = newValue
            model.settingsSnapshot.rewardsSettings.weeklyWorkoutGoal = newValue
            Task { await model.updateRewardsSettings(AtlasRewardsSettingsUpdate(weeklyWorkoutGoal: newValue)) }
        }
        .onChange(of: rewardsSelfGoalTarget) { _, newValue in
            guard newValue != state.settingsSnapshot.rewardsSettings.weeklySelfGoalTarget else {
                return
            }
            state.settingsSnapshot.rewardsSettings.weeklySelfGoalTarget = newValue
            model.settingsSnapshot.rewardsSettings.weeklySelfGoalTarget = newValue
            Task { await model.updateRewardsSettings(AtlasRewardsSettingsUpdate(weeklySelfGoalTarget: newValue)) }
        }
    }
}

private struct AtlasSettingsStatusRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    let value: String

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    label
                    valueText(multilineAlignment: .leading)
                }
            } else {
                HStack(alignment: .top, spacing: AtlasSpacing.small) {
                    label
                    Spacer(minLength: 12)
                    valueText(multilineAlignment: .trailing)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var label: some View {
        Text(title)
            .atlasTextRole(.supporting)
            .foregroundStyle(AtlasPalette.primary)
            .textCase(.uppercase)
    }

    private func valueText(multilineAlignment: TextAlignment) -> some View {
        Text(value)
            .atlasTextRole(.supporting)
            .multilineTextAlignment(multilineAlignment)
            .foregroundStyle(AtlasPalette.textPrimary)
    }
}

private struct AtlasSettingsStepperCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    let subtitle: String?
    @Binding var value: Int
    let range: ClosedRange<Int>
    let isEnabled: Bool
    let tint: Color

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                    header
                    controls
                }
            } else {
                HStack(spacing: AtlasSpacing.medium) {
                    header
                    Spacer(minLength: AtlasSpacing.medium)
                    controls
                }
            }
        }
        .padding(.horizontal, AtlasSpacing.medium)
        .padding(.vertical, AtlasSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isEnabled
                            ? [Color.white.opacity(0.97), tint.opacity(0.08)]
                            : [AtlasPalette.surfaceMuted.opacity(0.82), AtlasPalette.surfaceMuted.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isEnabled ? tint.opacity(0.14) : AtlasPalette.border.opacity(0.6), lineWidth: 1)
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .atlasTextRole(.cardBody)
                .foregroundStyle(isEnabled ? AtlasPalette.textPrimary : AtlasPalette.textSecondary)
            if let subtitle, subtitle.isEmpty == false {
                Text(subtitle)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: AtlasSpacing.small) {
            Button {
                guard isEnabled, value > range.lowerBound else {
                    return
                }
                AtlasFeedback.selection()
                value -= 1
            } label: {
                Image(systemName: "minus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(AtlasTactileTileButtonStyle(tint: tint))
            .disabled(isEnabled == false || value <= range.lowerBound)
            .accessibilityLabel("Decrease \(title)")

            Text("\(value)")
                .atlasTextRole(.cardTitle)
                .foregroundStyle(isEnabled ? AtlasPalette.textPrimary : AtlasPalette.textSecondary)
                .frame(minWidth: 40)

            Button {
                guard isEnabled, value < range.upperBound else {
                    return
                }
                AtlasFeedback.selection()
                value += 1
            } label: {
                Image(systemName: "plus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(AtlasTactileTileButtonStyle(tint: tint))
            .disabled(isEnabled == false || value >= range.upperBound)
            .accessibilityLabel("Increase \(title)")
        }
    }
}

private struct AtlasSettingsDisclosureRow: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let title: String
    let detail: String
    @Binding var isExpanded: Bool
    let tint: Color

    var body: some View {
        Button {
            AtlasFeedback.selection()
            withAnimation(reduceMotion ? .easeOut(duration: 0.16) : AtlasMotion.interactiveSpring) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: AtlasSpacing.medium) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(detail)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .lineLimit(isExpanded ? nil : 2)
                }

                Spacer(minLength: AtlasSpacing.medium)

                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(tint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 58)
            .padding(.horizontal, AtlasSpacing.medium)
            .padding(.vertical, AtlasSpacing.small)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AtlasPalette.surfaceTop.opacity(0.97), AtlasPalette.surfaceSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(tint.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(AtlasSurfacePressButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityHint(detail)
    }
}

private struct AtlasSettingsMenuOption<Value: Hashable>: Identifiable {
    let title: String
    let value: Value

    var id: String { title }
}

private struct AtlasSettingsMenuRow<Value: Hashable>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    let subtitle: String?
    let selectionTitle: String
    let options: [AtlasSettingsMenuOption<Value>]
    @Binding var selection: Value
    var isEnabled: Bool = true

    var body: some View {
        Menu {
            ForEach(options) { option in
                Button {
                    guard isEnabled else {
                        return
                    }
                    AtlasFeedback.selection()
                    selection = option.value
                } label: {
                    if option.value == selection {
                        Label(option.title, systemImage: "checkmark")
                    } else {
                        Text(option.title)
                    }
                }
            }
        } label: {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                        labelBlock
                        valueBadge
                    }
                } else {
                    HStack(spacing: AtlasSpacing.medium) {
                        labelBlock
                        Spacer(minLength: AtlasSpacing.medium)
                        valueBadge
                    }
                }
            }
            .padding(.horizontal, AtlasSpacing.medium)
            .padding(.vertical, AtlasSpacing.small)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isEnabled
                                ? [AtlasPalette.surfaceTop.opacity(0.97), AtlasPalette.surfaceSecondary]
                                : [AtlasPalette.surfaceMuted.opacity(0.8), AtlasPalette.surfaceMuted.opacity(0.68)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isEnabled ? AtlasPalette.chromeStroke.opacity(0.92) : AtlasPalette.border.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(AtlasSurfacePressButtonStyle())
        .disabled(isEnabled == false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(selectionTitle)
        .accessibilityHint(isEnabled ? "Double tap to open choices." : "Unavailable in the current configuration.")
    }

    private var labelBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .atlasTextRole(.cardBody)
                .foregroundStyle(isEnabled ? AtlasPalette.textPrimary : AtlasPalette.textSecondary)

            if let subtitle {
                Text(subtitle)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
            }
        }
    }

    private var valueBadge: some View {
        HStack(spacing: 8) {
            Text(selectionTitle)
                .atlasTextRole(.supporting)
                .foregroundStyle(isEnabled ? AtlasPalette.primary : AtlasPalette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Image(systemName: "chevron.up.chevron.down")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AtlasPalette.textTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(AtlasPalette.secondaryFill)
        )
    }
}

private struct AtlasMiniIconControlButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(isEnabled ? AtlasPalette.textSecondary : AtlasPalette.textTertiary)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isEnabled ? AtlasPalette.secondaryFill : AtlasPalette.surfaceMuted.opacity(0.7))
                )
        }
        .buttonStyle(AtlasSurfacePressButtonStyle())
        .disabled(isEnabled == false)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct AtlasSurfacePressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.965 : 1)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.84), value: configuration.isPressed)
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

private func atlasReminderLeadTimeTitle(_ minutes: Int) -> String {
    AtlasReminderLeadTime(rawValue: minutes)?.title ?? "\(minutes) minutes before"
}

private extension AtlasReminderPrivacyMode {
    var title: String {
        switch self {
        case .fullDetail:
            return "Full detail"
        case .generic:
            return "Generic"
        case .silent:
            return "Silent"
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
                        AtlasFeedback.selection()
                        model.open(action.1)
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                } else {
                    Button(action.0) {
                        AtlasFeedback.selection()
                        model.open(action.1)
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
        }
    }
}

private struct AtlasSettingsToggleRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
            AtlasFeedback.toggleChanged(isOn: isOn)
        } label: {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                        labelBlock
                        AtlasSettingsSwitch(isOn: isOn, isEnabled: isEnabled)
                    }
                } else {
                    HStack(alignment: .center, spacing: AtlasSpacing.medium) {
                        labelBlock
                        Spacer(minLength: AtlasSpacing.medium)
                        AtlasSettingsSwitch(isOn: isOn, isEnabled: isEnabled)
                    }
                }
            }
            .padding(.horizontal, AtlasSpacing.medium)
            .padding(.vertical, AtlasSpacing.small)
            .frame(minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isEnabled
                                ? [AtlasPalette.surfaceTop.opacity(0.97), AtlasPalette.surfaceSecondary]
                                : [AtlasPalette.surfaceMuted.opacity(0.8), AtlasPalette.surfaceMuted.opacity(0.68)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isEnabled ? AtlasPalette.chromeStroke.opacity(0.92) : AtlasPalette.border.opacity(0.5), lineWidth: 1)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AtlasPalette.chromeStrokeSoft.opacity(isEnabled ? 1 : 0.6), lineWidth: 1)
                    .mask(
                        LinearGradient(
                            colors: [.white, .white.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(AtlasSurfacePressButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint(isEnabled ? "Double tap to toggle." : "Unavailable in the current configuration.")
        .accessibilityAddTraits(.isButton)
    }

    private var labelBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .atlasTextRole(.cardBody)
                .foregroundStyle(isEnabled ? AtlasPalette.textPrimary : AtlasPalette.textSecondary)

            if let subtitle {
                Text(subtitle)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
            }
        }
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
                .fill(AtlasPalette.controlKnob)
                .frame(width: 28, height: 28)
                .padding(3)
                .shadow(color: AtlasPalette.shadow.opacity(isEnabled ? 0.55 : 0.28), radius: 4, x: 0, y: 2)
                .overlay(
                    Image(systemName: isOn ? "checkmark" : "circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: isOn ? 10 : 8, height: isOn ? 10 : 8)
                        .foregroundStyle(isOn ? trackColor : AtlasPalette.border)
                )
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
        isEnabled ? AtlasPalette.chromeStroke.opacity(0.7) : AtlasPalette.border.opacity(0.3)
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
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(entry.summary)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                        Text(entry.recordedAt.formatted(date: .abbreviated, time: .shortened))
                            .atlasTextRole(.supporting)
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
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text("Effective \(explanation.effectiveDateLabel)")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                if let firstFact = explanation.facts.first {
                    Text("\(firstFact.label): \(firstFact.value)")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Button("Open detail") {
                    AtlasFeedback.selection()
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
            AtlasScreen {
                AtlasCommandDeck(
                    eyebrow: item.panelTitle,
                    title: item.title,
                    detail: item.detailLine ?? item.summary,
                    metrics: [
                        AtlasMetricItem(id: "facts", title: "Facts", value: "\(item.facts.count)", tint: AtlasPalette.primary),
                        AtlasMetricItem(id: "notes", title: "Notes", value: "\(item.notes.count)", tint: AtlasPalette.secondaryText)
                    ],
                    tint: AtlasPalette.primary,
                    style: .hero
                ) { } footer: {
                    if item.detailLine != nil {
                        Text(item.summary)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                }

                if item.facts.isEmpty == false {
                    AtlasRootSectionHeader("Deterministic Facts")
                    AtlasSectionCard(style: .task) {
                        AtlasExplainerFactList(facts: item.facts)
                    }
                }

                if item.notes.isEmpty == false {
                    AtlasRootSectionHeader("Notes")
                    AtlasSectionCard(style: .utility) {
                        ForEach(item.notes, id: \.self) { note in
                            Text(note)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                }
            }
            .navigationTitle(item.panelTitle)
            .atlasInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        AtlasFeedback.selection()
                        dismiss()
                    }
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
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.primary)
                Text(fact.value)
                    .atlasTextRole(.cardBody)
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
                    .atlasTextRole(.deckEyebrow)
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
                .atlasTextRole(.screenTitle)
                .foregroundStyle(.white)
            Text(occurrence.cadenceLabel)
                .atlasTextRole(.screenSubtitle)
                .foregroundStyle(.white.opacity(0.8))
            if let doseLabel = occurrence.doseLabel {
                Text("Dose \(doseLabel)")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(.white.opacity(0.76))
            }

            VStack(spacing: AtlasSpacing.small) {
                Button("Mark taken") {
                    AtlasFeedback.notify(.success)
                    onLog(.taken)
                }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                VStack(spacing: AtlasSpacing.small) {
                    HStack(spacing: AtlasSpacing.small) {
                        Button("Skip") {
                            AtlasFeedback.impact(.medium)
                            onLog(.skipped)
                        }
                            .buttonStyle(AtlasInverseSecondaryButtonStyle())
                        Button("Reschedule") {
                            AtlasFeedback.selection()
                            onLog(.rescheduled)
                        }
                            .buttonStyle(AtlasInverseSecondaryButtonStyle())
                    }

                    HStack(spacing: AtlasSpacing.small) {
                        Button("Protocol") {
                            AtlasFeedback.selection()
                            onOpenProtocol()
                        }
                            .buttonStyle(AtlasInverseSecondaryButtonStyle())
                        Button("Change plan") {
                            AtlasFeedback.selection()
                            onOpenChangeStudio()
                        }
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
                    AtlasFeedback.selection()
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
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text("\(occurrence.cadenceLabel) • \(occurrence.scheduledAt.formatted(date: .abbreviated, time: .shortened))")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                if let doseLabel = occurrence.doseLabel {
                    Text("Dose \(doseLabel)")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AtlasSpacing.small) {
                        Button("Taken") {
                            AtlasFeedback.notify(.success)
                            action(.taken)
                        }
                            .buttonStyle(AtlasChipButtonStyle(tint: AtlasPalette.success))
                        Button("Skip") {
                            AtlasFeedback.impact(.medium)
                            action(.skipped)
                        }
                            .buttonStyle(AtlasChipButtonStyle(tint: .orange))
                        Button("Reschedule") {
                            AtlasFeedback.selection()
                            action(.rescheduled)
                        }
                            .buttonStyle(AtlasChipButtonStyle(tint: AtlasPalette.primary))
                        if let onOpenChangeStudio {
                            Button("Change plan") {
                                AtlasFeedback.selection()
                                onOpenChangeStudio()
                            }
                                .buttonStyle(AtlasChipButtonStyle(tint: AtlasPalette.textSecondary))
                        }
                    }
                }

                if let onExplain {
                    Button("Why this is due") {
                        AtlasFeedback.selection()
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
        AtlasSectionCard(style: .task) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack(alignment: .firstTextBaseline) {
                    Text(model.renderedTitle(
                        canonical: summary.canonicalTitle,
                        alias: summary.aliasTitle,
                        renderMode: renderMode
                    ))
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    Spacer()
                    AtlasStatusBadge(summary.status.rawValue.capitalized)
                }

                Text("\(summary.kindLabel) • \(summary.cadenceLabel)")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                if let doseLabel = summary.doseLabel {
                    Text("Dose: \(doseLabel)")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                if let nextDueLabel = summary.nextDueLabel {
                    Text("Next due \(nextDueLabel)")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                if let knowledge = summary.compoundKnowledge {
                    AtlasCalloutRow(
                        systemImage: "waveform.path.ecg.text",
                        title: "Compound context",
                        detail: knowledge.protocolSummary,
                        tint: AtlasPalette.secondaryText
                    )

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
                        AtlasFeedback.selection()
                        model.open(.protocolDetail(summary.id))
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())

                    Button("Change") {
                        AtlasFeedback.selection()
                        model.open(.protocolChange(summary.id))
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())

                    Button("Compare") {
                        AtlasFeedback.selection()
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
            .atlasTextRole(.supporting)
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
            AtlasScreen {
                AtlasCommandDeck(
                    eyebrow: "Compare / swap",
                    title: protocolTitle,
                    detail: currentKnowledge?.protocolSummary ?? "This protocol uses the broader \(kindTitle.lowercased()) catalog because it does not map cleanly to a stronger compound profile yet.",
                    metrics: [
                        AtlasMetricItem(id: "catalog", title: "Candidates", value: "\(candidates.count)", tint: AtlasPalette.primary),
                        AtlasMetricItem(id: "recognized", title: "Recognized", value: currentKnowledge == nil ? "No" : "Yes", tint: currentKnowledge == nil ? AtlasPalette.warning : AtlasPalette.success)
                    ],
                    tint: AtlasPalette.primary,
                    style: .hero
                ) { } footer: {
                    Text("Use compare mode to stress-test a future swap before editing the protocol schedule itself.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                if let currentKnowledge {
                    AtlasRootSectionHeader("Current Protocol")
                    AtlasSectionCard(style: .task) {
                        AtlasCompoundKnowledgeSummary(knowledge: currentKnowledge)
                    }
                }

                AtlasRootSectionHeader("Compare Against")
                AtlasSectionCard(style: .task) {
                    if candidates.isEmpty {
                        Text("No compare catalog is available for this protocol yet.")
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    } else {
                        Picker("Compound", selection: selectedBinding) {
                            ForEach(candidates) { candidate in
                                Text(candidate.displayName).tag(candidate.slug)
                            }
                        }
                        .pickerStyle(.menu)

                        if let selectedCandidate {
                            AtlasCompoundKnowledgeSummary(knowledge: selectedCandidate)
                        }
                    }
                }

                if let currentKnowledge, let selectedCandidate {
                    AtlasRootSectionHeader("Swap Guidance")
                    AtlasSectionCard(style: .utility) {
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

                    AtlasRootSectionHeader("Change Notes")
                    AtlasSectionCard(style: .utility) {
                        ForEach(AtlasCompoundKnowledgeCatalog.swapGuidance(from: currentKnowledge, to: selectedCandidate), id: \.self) { note in
                            Text(note)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                }
            }
            .navigationTitle("Compare / swap")
            .atlasInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        AtlasFeedback.selection()
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
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)

            Text(knowledge.protocolSummary)
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)

            Text("\(knowledge.categoryLabel) • \(knowledge.routeLabel)")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)

            Text("Typical cadence: \(knowledge.typicalCadenceLabel)")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)

            Text("Availability: \(knowledge.availabilityLabel)")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)

            Text("Common units: \(knowledge.commonDoseUnits.joined(separator: ", "))")
                .atlasTextRole(.supporting)
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
                .atlasTextRole(.deckEyebrow)
                .foregroundStyle(AtlasPalette.primary)
            Text("Current: \(currentValue)")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
            Text("Compared: \(nextValue)")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
    }
}

private struct AtlasInlineMessage: View {
    let text: String

    var body: some View {
        Text(text)
            .atlasTextRole(.deckEyebrow)
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
    let titleLineLimit: Int?
    let actions: Actions

    init(
        title: String,
        message: String,
        systemImage: String = "sparkles",
        note: String? = nil,
        titleLineLimit: Int? = nil,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.note = note
        self.titleLineLimit = titleLineLimit
        self.actions = actions()
    }

    var body: some View {
        AtlasSectionCard(style: .task) {
            AtlasCalloutRow(
                systemImage: systemImage,
                title: title,
                detail: message,
                tint: AtlasPalette.primary,
                badge: note,
                titleLineLimit: titleLineLimit
            )

            actions
        }
    }
}

private struct AtlasToolLauncherButton: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    let subtitle: String?
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button {
            AtlasFeedback.selection()
            action()
        } label: {
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
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundStyle(AtlasPalette.primary)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.88), lineWidth: 1)
                        )

                    Spacer(minLength: AtlasSpacing.small)

                    Image(systemName: "arrow.up.right")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 10)
                        .foregroundStyle(AtlasPalette.textTertiary)
                }

                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)

                if let subtitle, subtitle.isEmpty == false {
                    Text(subtitle)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? 108 : 110, alignment: .topLeading)
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
        .buttonStyle(AtlasSurfacePressButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle ?? "")
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
            AtlasScreen {
                AtlasCommandDeck(
                    eyebrow: "Quick log",
                    title: model.renderedTitle(canonical: context.occurrence.canonicalTitle, alias: context.occurrence.aliasTitle),
                    detail: "\(context.occurrence.kindLabel) • \(context.occurrence.cadenceLabel) • \(context.occurrence.scheduledAt.formatted(date: .abbreviated, time: .shortened))",
                    metrics: [
                        AtlasMetricItem(id: "state", title: "State", value: context.occurrence.state.rawValue.capitalized, tint: AtlasPalette.primary),
                        AtlasMetricItem(id: "action", title: "Action", value: actionLabel, tint: AtlasPalette.secondaryText)
                    ],
                    tint: AtlasPalette.primary,
                    style: .hero
                ) { } footer: { }

                AtlasSectionCard(style: .utility, title: "Action") {
                    Picker("Action", selection: $action) {
                        Text("Taken").tag(AtlasOccurrenceLogAction.taken)
                        Text("Skip").tag(AtlasOccurrenceLogAction.skipped)
                        Text("Reschedule").tag(AtlasOccurrenceLogAction.rescheduled)
                    }
                    .pickerStyle(.segmented)
                }

                if action == .rescheduled {
                    AtlasSectionCard(title: "New time") {
                        DatePicker("When", selection: $rescheduledAt)

                        HStack(spacing: AtlasSpacing.small) {
                            Button("Later today (+2h)") {
                                AtlasFeedback.selection()
                                rescheduledAt = model.currentDate().addingTimeInterval(2 * 60 * 60)
                            }
                            .buttonStyle(AtlasSecondaryButtonStyle())

                            Button("Tomorrow") {
                                AtlasFeedback.selection()
                                rescheduledAt = Calendar.current.date(byAdding: .day, value: 1, to: model.currentDate()) ?? rescheduledAt
                            }
                            .buttonStyle(AtlasSecondaryButtonStyle())
                        }

                        Button("In 2 days") {
                            AtlasFeedback.selection()
                            rescheduledAt = Calendar.current.date(byAdding: .day, value: 2, to: model.currentDate()) ?? rescheduledAt
                        }
                        .buttonStyle(AtlasTertiaryButtonStyle())
                    }
                }

                if action == .taken,
                   let siteOptions,
                   siteOptions.siteTrackingEnabled,
                   siteOptions.sites.isEmpty == false {
                    AtlasSectionCard(title: "Site") {
                        if siteOptions.sites.contains(where: { $0.mapRegionKey != nil }) {
                            AtlasQuickLogSiteMap(
                                sites: siteOptions.sites,
                                selectedSiteID: Binding(
                                    get: { selectedSiteID },
                                    set: { selectedSiteID = $0 }
                                )
                            )
                        }

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
                                AtlasFeedback.selection()
                                selectedSiteID = suggested.id
                            }
                            .buttonStyle(AtlasSecondaryButtonStyle())
                        }
                    }
                }

                AtlasSectionCard(title: "Note") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .atlasStandaloneInputSurface()
                }

                AtlasSectionCard(style: .utility, title: "Commit") {
                    Button("Save quick log") {
                        AtlasFeedback.selection()
                        Task { await commitQuickLog() }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                    .accessibilityIdentifier("quickLogPrimarySaveButton")
                    .disabled(isSubmitting)

                    Button("Cancel") {
                        AtlasFeedback.selection()
                        dismiss()
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                    .accessibilityIdentifier("quickLogSecondaryCancelButton")
                    .disabled(isSubmitting)
                }
            }
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

    private var actionLabel: String {
        switch action {
        case .taken: "Taken"
        case .skipped: "Skip"
        case .rescheduled: "Reschedule"
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

private struct AtlasQuickLogSiteMap: View {
    let sites: [AtlasSiteSummary]
    @Binding var selectedSiteID: String?
    @State private var surface: AtlasBodyMapSurface = .front

    private var visibleSites: [AtlasSiteSummary] {
        sites.filter { $0.mapRegionKey?.surface == surface }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            Picker("Body surface", selection: $surface) {
                ForEach(AtlasBodyMapSurface.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)

            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height

                ZStack {
                    AtlasQuickLogBodyMapSilhouette(surface: surface)
                        .fill(AtlasPalette.surfaceSecondary)
                        .overlay {
                            AtlasQuickLogBodyMapSilhouette(surface: surface)
                                .stroke(AtlasPalette.border, lineWidth: 1)
                        }

                    ForEach(visibleSites) { site in
                        if let region = site.mapRegionKey {
                            Button {
                                selectedSiteID = site.id
                            } label: {
                                VStack(spacing: 2) {
                                    Circle()
                                        .fill(selectedSiteID == site.id ? AtlasPalette.primary : AtlasPalette.success)
                                        .frame(
                                            width: max(width * region.markerDiameter, 28),
                                            height: max(width * region.markerDiameter, 28)
                                        )
                                        .overlay {
                                            Circle().stroke(Color.white.opacity(0.85), lineWidth: selectedSiteID == site.id ? 2 : 1)
                                        }
                                    Text(region.shortLabel)
                                        .atlasTextRole(.metricLabel)
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                }
                            }
                            .buttonStyle(.plain)
                            .position(x: width * region.normalizedX, y: height * region.normalizedY)
                        }
                    }
                }
            }
            .frame(height: 260)

            Text("Tap a saved hotspot to select the site visually.")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
        .onAppear {
            if let selectedSite = sites.first(where: { $0.id == selectedSiteID }),
               let region = selectedSite.mapRegionKey {
                surface = region.surface
            }
        }
    }
}

private struct AtlasQuickLogBodyMapSilhouette: Shape {
    let surface: AtlasBodyMapSurface

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let head = CGRect(
            x: rect.midX - rect.width * 0.09,
            y: rect.minY + rect.height * 0.03,
            width: rect.width * 0.18,
            height: rect.width * 0.18
        )
        path.addEllipse(in: head)

        let torso = CGRect(
            x: rect.midX - rect.width * 0.16,
            y: rect.minY + rect.height * 0.21,
            width: rect.width * 0.32,
            height: rect.height * 0.34
        )
        path.addRoundedRect(in: torso, cornerSize: CGSize(width: rect.width * 0.07, height: rect.width * 0.07))

        let leftArm = CGRect(
            x: rect.midX - rect.width * 0.33,
            y: rect.minY + rect.height * 0.23,
            width: rect.width * 0.12,
            height: rect.height * 0.30
        )
        let rightArm = CGRect(
            x: rect.midX + rect.width * 0.21,
            y: rect.minY + rect.height * 0.23,
            width: rect.width * 0.12,
            height: rect.height * 0.30
        )
        path.addRoundedRect(in: leftArm, cornerSize: CGSize(width: rect.width * 0.06, height: rect.width * 0.06))
        path.addRoundedRect(in: rightArm, cornerSize: CGSize(width: rect.width * 0.06, height: rect.width * 0.06))

        let hips = CGRect(
            x: rect.midX - rect.width * 0.18,
            y: rect.minY + rect.height * 0.50,
            width: rect.width * 0.36,
            height: rect.height * 0.11
        )
        path.addRoundedRect(in: hips, cornerSize: CGSize(width: rect.width * 0.08, height: rect.width * 0.08))

        let leftLeg = CGRect(
            x: rect.midX - rect.width * 0.16,
            y: rect.minY + rect.height * 0.58,
            width: rect.width * 0.12,
            height: rect.height * 0.29
        )
        let rightLeg = CGRect(
            x: rect.midX + rect.width * 0.04,
            y: rect.minY + rect.height * 0.58,
            width: rect.width * 0.12,
            height: rect.height * 0.29
        )
        path.addRoundedRect(in: leftLeg, cornerSize: CGSize(width: rect.width * 0.06, height: rect.width * 0.06))
        path.addRoundedRect(in: rightLeg, cornerSize: CGSize(width: rect.width * 0.06, height: rect.width * 0.06))

        if surface == .back {
            let spine = CGRect(
                x: rect.midX - rect.width * 0.015,
                y: rect.minY + rect.height * 0.25,
                width: rect.width * 0.03,
                height: rect.height * 0.28
            )
            path.addRoundedRect(in: spine, cornerSize: CGSize(width: rect.width * 0.015, height: rect.width * 0.015))
        }

        return path
    }
}

private struct AtlasProtocolFormState {
    var name: String = ""
    var kind: AtlasProtocolKind = .glp
    var administrationRoute: AtlasProtocolAdministrationRoute = .injection
    var supplyType: AtlasProtocolSupplyType?
    var dosesPerSupply: Int = 4
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
        administrationRoute = draft.administrationRoute
        supplyType = draft.supplyType
        dosesPerSupply = draft.dosesPerSupply ?? 4
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
            administrationRoute: administrationRoute,
            supplyType: supplyType,
            dosesPerSupply: supplyType == nil ? nil : dosesPerSupply,
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

private extension AtlasProtocolKind {
    var editorTitle: String {
        switch self {
        case .glp:
            return "GLP"
        case .peptide:
            return "Peptide"
        case .custom:
            return "Custom"
        }
    }

    var editorSubtitle: String {
        switch self {
        case .glp:
            return "Clinical-feeling long-view protocol"
        case .peptide:
            return "Performance or recovery-first loop"
        case .custom:
            return "Open format when you need more flexibility"
        }
    }

    var editorTint: Color {
        switch self {
        case .glp:
            return AtlasPalette.primary
        case .peptide:
            return AtlasPalette.reward
        case .custom:
            return AtlasPalette.secondaryText
        }
    }

    var previewSystemImage: String {
        switch self {
        case .glp:
            return "waveform.path.ecg"
        case .peptide:
            return "bolt.heart.fill"
        case .custom:
            return "slider.horizontal.3"
        }
    }
}

private extension AtlasProtocolRuleType {
    var editorTitle: String {
        switch self {
        case .weekly:
            return "Weekly"
        case .daily:
            return "Daily"
        case .everyNDays:
            return "Every N days"
        }
    }

    var editorSubtitle: String {
        switch self {
        case .weekly:
            return "Best for set weekly anchors"
        case .daily:
            return "Simple repeat for daily schedules"
        case .everyNDays:
            return "Flexible interval-based cadence"
        }
    }
}

private func weekdayName(_ weekday: Int) -> String {
    ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][weekday]
}

private extension AtlasProtocolAdministrationRoute {
    var atlasTitle: String {
        switch self {
        case .injection:
            return "Injection"
        case .oral:
            return "Oral"
        case .sublingual:
            return "Sublingual"
        case .nasal:
            return "Nasal"
        case .topical:
            return "Topical"
        case .transdermal:
            return "Transdermal"
        case .other:
            return "Other"
        }
    }

    var editorSubtitle: String {
        switch self {
        case .injection:
            return "Shots and site rotation"
        case .oral:
            return "Capsule, tablet, or liquid"
        case .sublingual:
            return "Held under the tongue"
        case .nasal:
            return "Spray or nasal delivery"
        case .topical:
            return "Applied to the skin"
        case .transdermal:
            return "Patch or slow delivery"
        case .other:
            return "Non-standard route"
        }
    }
}

private extension AtlasProtocolSupplyType {
    var atlasTitle: String {
        switch self {
        case .vial:
            return "Vial"
        case .pen:
            return "Pen"
        case .bottle:
            return "Bottle"
        case .blisterPack:
            return "Blister pack"
        case .syringe:
            return "Prefilled syringe"
        case .other:
            return "Other"
        }
    }

    var editorSubtitle: String {
        switch self {
        case .vial:
            return "Best for reconstituted tracking"
        case .pen:
            return "Handy for device-based dosing"
        case .bottle:
            return "Liquid or oral supply"
        case .blisterPack:
            return "Carded or pre-portioned doses"
        case .syringe:
            return "Single-use prefilled format"
        case .other:
            return "Bring your own supply model"
        }
    }
}

private extension AtlasProtocolFormState {
    var cadenceMetricLabel: String {
        switch cadenceType {
        case .daily:
            return "Daily"
        case .weekly:
            return weekdayName(weekday ?? 1)
        case .everyNDays:
            return "\(intervalDays)d"
        }
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
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

private func calendarPermissionLabel(_ status: AtlasCalendarAuthorizationStatus) -> String {
    switch status {
    case .notDetermined:
        return "Not requested"
    case .denied:
        return "Denied"
    case .restricted:
        return "Restricted"
    case .writeOnly:
        return "Write only"
    case .fullAccess:
        return "Full access"
    case .unavailable:
        return "Unavailable"
    }
}

private func atlasCalendarSyncStatusLabel(_ timestamp: String?) -> String {
    guard let timestamp,
          let date = ISO8601DateFormatter.atlas.date(from: timestamp) else {
        return "Not synced yet"
    }
    return date.formatted(date: .abbreviated, time: .shortened)
}

private enum AtlasKeyboard {
    @MainActor
    static func dismiss() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
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

struct AtlasRootScrollSurface<Content: View>: View {
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
            .atlasTextRole(.deckEyebrow)
            .foregroundStyle(AtlasPalette.textTertiary)
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
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    let title: String
    var subtitle: String? = nil
    var action: AtlasTabHeaderAction? = nil
    var fullBleed: Bool = true

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.medium) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                Text(title)
                    .atlasTextRole(.screenTitle)
                    .foregroundStyle(.white)
                if let subtitle, subtitle.isEmpty == false {
                    Text(subtitle)
                        .atlasTextRole(.screenSubtitle)
                        .foregroundStyle(colorSchemeContrast == .increased ? .white : .white.opacity(0.76))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: AtlasSpacing.small)

            if let action {
                Button(action: action.action) {
                    Image(systemName: action.systemImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
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
                    .fill((reduceTransparency || colorSchemeContrast == .increased) ? Color.clear : AtlasPalette.shellGlow.opacity(0.22))
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

private func atlasOpenSystemSettings() {
    #if canImport(UIKit)
    guard let url = URL(string: UIApplication.openSettingsURLString),
          UIApplication.shared.canOpenURL(url) else {
        return
    }

    AtlasFeedback.navigation()
    UIApplication.shared.open(url)
    #endif
}

@MainActor
@ViewBuilder
private func header(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
        Text(title)
            .atlasTextRole(.screenTitle)
            .foregroundStyle(AtlasPalette.textPrimary)
        Text(subtitle)
            .atlasTextRole(.screenSubtitle)
            .foregroundStyle(AtlasPalette.textSecondary)
    }
}
