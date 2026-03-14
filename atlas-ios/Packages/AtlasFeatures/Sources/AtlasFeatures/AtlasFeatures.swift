import AtlasDesignSystem
import AtlasDomain
import AtlasPersistence
import AtlasPrivacy
import AtlasSystem
import Observation
import SwiftUI

public struct AtlasAppDependencies: Sendable {
    public var featureFlags: any AtlasFeatureFlagProviding
    public var notifications: any NotificationManaging
    public var biometrics: any BiometricGating
    public var healthKit: any HealthKitManaging
    public var importExport: any ImportExportBridging
    public var sharedProjectionWriter: any SharedProjectionWriting
    public var persistence: AtlasPersistenceContainer
    public var reminders: any ReminderCoordinating
    public var privacyFormatter: AtlasPrivacyFormatter

    public init(
        featureFlags: any AtlasFeatureFlagProviding,
        notifications: any NotificationManaging,
        biometrics: any BiometricGating,
        healthKit: any HealthKitManaging,
        importExport: any ImportExportBridging,
        sharedProjectionWriter: any SharedProjectionWriting,
        persistence: AtlasPersistenceContainer,
        reminders: any ReminderCoordinating,
        privacyFormatter: AtlasPrivacyFormatter
    ) {
        self.featureFlags = featureFlags
        self.notifications = notifications
        self.biometrics = biometrics
        self.healthKit = healthKit
        self.importExport = importExport
        self.sharedProjectionWriter = sharedProjectionWriter
        self.persistence = persistence
        self.reminders = reminders
        self.privacyFormatter = privacyFormatter
    }
}

@MainActor
@Observable
public final class AtlasAppModel {
    public var activeTab: AtlasTab
    public var routePath: [AtlasRoute]
    public let dependencies: AtlasAppDependencies
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
    public var trustVaultSnapshot: AtlasTrustVaultSnapshot
    public var reviewOwnerSnapshot: AtlasReviewOwnerSnapshot
    public var reviewWorkspace: AtlasReviewWorkspace?
    public var isLoading: Bool
    public var loadErrorMessage: String?
    public var activeOnboardingStep: AtlasOnboardingStep
    private var hasLoadedBootstrap: Bool
    private var hasLoadedShellData: Bool
    private var hasConfiguredReminderHandling: Bool
    var protocolDetails: [String: AtlasProtocolDetailSnapshot]
    var vialDetails: [String: AtlasVialDetailSnapshot]
    var protocolSiteOptions: [String: AtlasProtocolSiteOptions]

    public init(
        activeTab: AtlasTab = .today,
        routePath: [AtlasRoute] = [],
        dependencies: AtlasAppDependencies
    ) {
        self.activeTab = activeTab
        self.routePath = routePath
        self.dependencies = dependencies
        self.bootstrapSnapshot = AtlasBootstrapSnapshot(
            destination: .onboarding,
            reason: .firstRun,
            onboardingDraft: .empty(),
            onboardingCompleted: false,
            hasLocalData: false,
            isImportedLocalUser: false
        )
        self.settingsSnapshot = AtlasSettingsSnapshot()
        self.todaySnapshot = AtlasTodaySnapshot(hasProtocols: false, nextDue: nil, overdue: [], upcoming: [])
        self.libraryProtocols = []
        self.timelineEntries = []
        self.timelineFilter = .all
        self.reminderSettings = AtlasReminderSettingsSnapshot()
        self.notificationPermissionStatus = .notDetermined
        self.inventorySnapshot = AtlasInventorySnapshot()
        self.calculatorProfiles = []
        self.insightsSnapshot = AtlasInsightsSnapshot()
        self.trustVaultSnapshot = AtlasTrustVaultSnapshot(
            privacyProfile: .default(),
            aliases: [],
            audits: []
        )
        self.reviewOwnerSnapshot = AtlasReviewOwnerSnapshot(
            sessions: [],
            liveReviewEnabled: dependencies.featureFlags.flags.liveReviewSessions
        )
        self.reviewWorkspace = nil
        self.isLoading = false
        self.loadErrorMessage = nil
        self.activeOnboardingStep = .splash
        self.hasLoadedBootstrap = false
        self.hasLoadedShellData = false
        self.hasConfiguredReminderHandling = false
        self.protocolDetails = [:]
        self.vialDetails = [:]
        self.protocolSiteOptions = [:]
    }

    public func open(_ route: AtlasRoute) {
        routePath.append(route)
    }

    public func loadBootstrapIfNeeded() async {
        guard hasLoadedBootstrap == false else {
            return
        }
        await refreshBootstrap()
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
        } catch {
            loadErrorMessage = error.localizedDescription
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
                loadErrorMessage = error.localizedDescription
            }
        }

        await refreshShellData()
    }

    public func refreshShellData() async {
        guard isLoading == false else {
            return
        }

        isLoading = true
        loadErrorMessage = nil
        defer { isLoading = false }

        do {
            let now = Date()
            try await dependencies.persistence.coreLoop.ensureProjectedOccurrences(referenceDate: now)
            try await dependencies.reminders.syncReminders(referenceDate: now)

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
            trustVaultSnapshot = try await trustVault
            reviewOwnerSnapshot = try await reviewOwner
            hasLoadedShellData = true
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func saveOnboardingDraft(_ draft: AtlasOnboardingDraft) async {
        do {
            bootstrapSnapshot = try await dependencies.persistence.onboarding.saveDraft(draft, now: Date())
        } catch {
            loadErrorMessage = error.localizedDescription
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
                now: Date()
            )
            settingsSnapshot = try await dependencies.persistence.settings.currentSettingsSnapshot()
            activeOnboardingStep = .planReady
            hasLoadedShellData = false
            if bootstrapSnapshot.destination == .app {
                await loadShellDataIfNeeded()
            }
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func resetOnboarding() async {
        do {
            bootstrapSnapshot = try await dependencies.persistence.onboarding.resetOnboarding(now: Date())
            settingsSnapshot = try await dependencies.persistence.settings.currentSettingsSnapshot()
            activeOnboardingStep = .splash
            hasLoadedShellData = false
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func refreshTimeline() async {
        do {
            timelineEntries = try await dependencies.persistence.timeline.fetchTimeline(
                AtlasTimelineQuery(filter: timelineFilter, limit: 80)
            )
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func protocolDetail(id: String) async -> AtlasProtocolDetailSnapshot? {
        if let existing = protocolDetails[id] {
            return existing
        }

        do {
            try await dependencies.persistence.coreLoop.ensureProjectedOccurrences(referenceDate: Date())
            let detail = try await dependencies.persistence.protocols.fetchProtocolDetail(id: id)
            if let detail {
                protocolDetails[id] = detail
            }
            return detail
        } catch {
            loadErrorMessage = error.localizedDescription
            return nil
        }
    }

    public func createProtocol(_ draft: AtlasProtocolDraft) async -> AtlasProtocolDetailSnapshot? {
        do {
            let now = Date()
            let detail = try await dependencies.persistence.protocols.createProtocol(draft, now: now)
            try await dependencies.reminders.syncReminders(referenceDate: now)
            protocolDetails[detail.id] = detail
            await refreshShellData()
            return detail
        } catch {
            loadErrorMessage = error.localizedDescription
            return nil
        }
    }

    public func updateProtocol(id: String, draft: AtlasProtocolDraft) async -> AtlasProtocolDetailSnapshot? {
        do {
            let now = Date()
            let detail = try await dependencies.persistence.protocols.updateProtocol(id: id, draft: draft, now: now)
            try await dependencies.reminders.syncReminders(referenceDate: now)
            protocolDetails[id] = detail
            await refreshShellData()
            return detail
        } catch {
            loadErrorMessage = error.localizedDescription
            return nil
        }
    }

    public func logOccurrence(_ request: AtlasOccurrenceLogRequest) async {
        do {
            let now = Date()
            try await dependencies.persistence.coreLoop.logOccurrence(request, now: now)
            try await dependencies.reminders.syncReminders(referenceDate: now)
            await refreshShellData()
            if let detail = try await dependencies.persistence.protocols.fetchProtocolDetail(id: request.protocolID) {
                protocolDetails[request.protocolID] = detail
            }
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func requestReminderPermission() async {
        do {
            notificationPermissionStatus = try await dependencies.reminders.requestAuthorization()
            await refreshShellData()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func updateReminderSettings(_ update: AtlasReminderPreferenceUpdate) async {
        do {
            reminderSettings = try await dependencies.reminders.updateReminderSettings(update, referenceDate: Date())
            await refreshShellData()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func updatePrivacyRenderMode(_ renderMode: AtlasPrivacyRenderMode) async {
        do {
            settingsSnapshot = try await dependencies.persistence.settings.updateTrustVaultRenderMode(renderMode, now: Date())
            await refreshShellData()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func vialDetail(id: String) async -> AtlasVialDetailSnapshot? {
        if let cached = vialDetails[id] {
            return cached
        }

        do {
            let detail = try await dependencies.persistence.inventory.fetchVialDetail(id: id, referenceDate: Date())
            if let detail {
                vialDetails[id] = detail
            }
            return detail
        } catch {
            loadErrorMessage = error.localizedDescription
            return nil
        }
    }

    public func saveVial(_ draft: AtlasVialDraft) async -> AtlasVialDetailSnapshot? {
        do {
            let detail = try await dependencies.persistence.inventory.saveVial(draft, now: Date())
            invalidateInventoryCaches()
            await refreshShellData()
            vialDetails[detail.summary.id] = detail
            return detail
        } catch {
            loadErrorMessage = error.localizedDescription
            return nil
        }
    }

    public func archiveVial(id: String) async {
        do {
            try await dependencies.persistence.inventory.archiveVial(id: id, now: Date())
            invalidateInventoryCaches()
            await refreshShellData()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func updateProtocolInventorySettings(_ update: AtlasProtocolInventorySettingsUpdate) async {
        do {
            _ = try await dependencies.persistence.inventory.updateProtocolInventorySettings(update, now: Date())
            invalidateInventoryCaches()
            await refreshShellData()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func applyManualCorrection(_ correction: AtlasInventoryCorrectionDraft) async -> AtlasInventoryCorrectionResult? {
        do {
            let result = try await dependencies.persistence.inventory.applyManualCorrection(correction, now: Date())
            invalidateInventoryCaches()
            await refreshShellData()
            vialDetails[result.vial.summary.id] = result.vial
            return result
        } catch {
            loadErrorMessage = error.localizedDescription
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
            loadErrorMessage = error.localizedDescription
            return nil
        }
    }

    public func saveSite(_ draft: AtlasSiteDraft) async {
        do {
            _ = try await dependencies.persistence.inventory.saveSite(draft, now: Date())
            invalidateInventoryCaches()
            await refreshShellData()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func saveCalculatorProfile(_ draft: AtlasCalculatorProfileDraft) async {
        do {
            _ = try await dependencies.persistence.calculator.saveProfile(draft, now: Date())
            await refreshShellData()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func deleteCalculatorProfile(id: String) async {
        do {
            try await dependencies.persistence.calculator.deleteProfile(id: id)
            invalidateInventoryCaches()
            await refreshShellData()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func saveWeightEntry(_ draft: AtlasWeightEntryDraft) async {
        do {
            _ = try await dependencies.persistence.metrics.saveWeightEntry(draft, now: Date())
            await refreshShellData()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func saveSymptomEntry(_ draft: AtlasSymptomEntryDraft) async {
        do {
            _ = try await dependencies.persistence.metrics.saveSymptomEntry(draft, now: Date())
            await refreshShellData()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func saveMetricDefinition(_ draft: AtlasMetricDefinitionDraft) async {
        do {
            _ = try await dependencies.persistence.metrics.saveMetricDefinition(draft, now: Date())
            await refreshShellData()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func archiveMetricDefinition(id: String) async {
        do {
            try await dependencies.persistence.metrics.archiveMetricDefinition(id: id, now: Date())
            await refreshShellData()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func deleteMetricDefinition(id: String) async {
        do {
            try await dependencies.persistence.metrics.deleteMetricDefinition(id: id)
            await refreshShellData()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func saveMetricValueEntry(_ draft: AtlasMetricValueEntryDraft) async {
        do {
            _ = try await dependencies.persistence.metrics.saveMetricValueEntry(draft, now: Date())
            await refreshShellData()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    public func renderedTitle(canonical: String, alias: String?) -> String {
        dependencies.privacyFormatter.title(
            canonical: canonical,
            alias: alias,
            mode: settingsSnapshot.trustVaultStatus.renderMode
        )
    }

    public func renderedMetricLabel(canonical: String) -> String {
        dependencies.privacyFormatter.metricLabel(
            canonical: canonical,
            mode: settingsSnapshot.trustVaultStatus.renderMode
        )
    }

    public func reminderPreview() -> AtlasReminderPreview {
        dependencies.privacyFormatter.reminderPreview(
            occurrence: todaySnapshot.nextDue ?? AtlasScheduledOccurrence(
                id: "preview",
                protocolID: "preview",
                canonicalTitle: "Atlas protocol",
                aliasTitle: "Alias protocol",
                kindLabel: "Routine",
                cadenceLabel: "Daily cadence",
                doseLabel: nil,
                scheduledAt: Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date(),
                state: .upcoming
            ),
            selectedMode: reminderSettings.privacyMode,
            renderMode: settingsSnapshot.trustVaultStatus.renderMode
        )
    }

    private func invalidateInventoryCaches() {
        vialDetails.removeAll()
        protocolSiteOptions.removeAll()
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
                    TabView(selection: $model.activeTab) {
                        AtlasTodayScreen(model: model)
                            .tabItem { Label(AtlasTab.today.title, systemImage: AtlasTab.today.systemImage) }
                            .tag(AtlasTab.today)

                        AtlasTimelineScreen(model: model)
                            .tabItem { Label(AtlasTab.timeline.title, systemImage: AtlasTab.timeline.systemImage) }
                            .tag(AtlasTab.timeline)

                        AtlasLibraryScreen(model: model)
                            .tabItem { Label(AtlasTab.library.title, systemImage: AtlasTab.library.systemImage) }
                            .tag(AtlasTab.library)

                        AtlasInsightsScreen(model: model)
                            .tabItem { Label(AtlasTab.insights.title, systemImage: AtlasTab.insights.systemImage) }
                            .tag(AtlasTab.insights)

                        AtlasSettingsScreen(model: model)
                            .tabItem { Label(AtlasTab.settings.title, systemImage: AtlasTab.settings.systemImage) }
                            .tag(AtlasTab.settings)
                    }
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
        .task {
            await model.loadBootstrapIfNeeded()
        }
    }
}

public struct AtlasTodayScreen: View {
    let model: AtlasAppModel
    @State private var sheetContext: AtlasLogSheetContext?

    public var body: some View {
        List {
            if let error = model.loadErrorMessage {
                AtlasInlineMessage(text: error)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            if model.todaySnapshot.hasProtocols == false {
                AtlasEmptyStateCard(
                    title: "No protocols yet",
                    message: "Imported users will see their next due card here, and new native users can start by creating a protocol."
                ) {
                    Button("Create protocol") {
                        model.open(.protocolCreate)
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } else if let nextDue = model.todaySnapshot.nextDue {
                Section("Next due") {
                    AtlasOccurrenceHero(
                        occurrence: nextDue,
                        displayTitle: model.renderedTitle(
                            canonical: nextDue.canonicalTitle,
                            alias: nextDue.aliasTitle
                        ),
                        onLog: { action in
                            sheetContext = AtlasLogSheetContext(occurrence: nextDue, initialAction: action)
                        },
                        onOpenProtocol: {
                            model.open(.protocolDetail(nextDue.protocolID))
                        },
                        onOpenChangeStudio: {
                            model.open(.protocolChange(nextDue.protocolID))
                        }
                    )
                    .listRowInsets(EdgeInsets())
                }
            } else {
                AtlasEmptyStateCard(
                    title: "Nothing due right now",
                    message: "Your future schedule is clear. Create another protocol or check the Library to review current plans."
                ) {
                    Button("Open Library") {
                        model.activeTab = .library
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            if model.todaySnapshot.overdue.isEmpty == false {
                Section("Overdue") {
                    ForEach(model.todaySnapshot.overdue) { occurrence in
                        AtlasOccurrenceRow(
                            occurrence: occurrence,
                            title: model.renderedTitle(
                                canonical: occurrence.canonicalTitle,
                                alias: occurrence.aliasTitle
                            ),
                            action: { action in
                                sheetContext = AtlasLogSheetContext(occurrence: occurrence, initialAction: action)
                            },
                            onOpenChangeStudio: {
                                model.open(.protocolChange(occurrence.protocolID))
                            }
                        )
                    }
                }
            }

            if model.todaySnapshot.upcoming.isEmpty == false {
                Section("Upcoming") {
                    ForEach(model.todaySnapshot.upcoming) { occurrence in
                        AtlasOccurrenceRow(
                            occurrence: occurrence,
                            title: model.renderedTitle(
                                canonical: occurrence.canonicalTitle,
                                alias: occurrence.aliasTitle
                            ),
                            action: { action in
                                sheetContext = AtlasLogSheetContext(occurrence: occurrence, initialAction: action)
                            },
                            onOpenChangeStudio: {
                                model.open(.protocolChange(occurrence.protocolID))
                            }
                        )
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AtlasPalette.canvas)
        .navigationTitle("Today")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await model.refreshShellData() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .sheet(item: $sheetContext) { context in
            AtlasLogSheet(model: model, context: context) { request in
                await model.logOccurrence(request)
            }
        }
    }
}

public struct AtlasTimelineScreen: View {
    let model: AtlasAppModel

    public var body: some View {
        List {
            Section {
                Picker("Filter", selection: Binding(
                    get: { model.timelineFilter },
                    set: { value in
                        model.timelineFilter = value
                        Task { await model.refreshTimeline() }
                    }
                )) {
                    ForEach(AtlasTimelineFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            if model.timelineEntries.isEmpty {
                AtlasEmptyStateCard(
                    title: "No history yet",
                    message: "Quick logs, imports, and protocol edits will appear here with immutable timestamps."
                ) { EmptyView() }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } else {
                ForEach(groupedTimelineEntries, id: \.dateLabel) { section in
                    Section(section.dateLabel) {
                    ForEach(section.entries) { entry in
                        Button {
                            if entry.type == .protocolCreated || entry.type == .protocolEdited {
                                model.open(.protocolChange(entry.protocolID))
                            } else if entry.type == .weightLogged || entry.type == .symptomLogged || entry.type == .customMetricLogged {
                                model.activeTab = .insights
                            } else {
                                model.open(.protocolDetail(entry.protocolID))
                            }
                            } label: {
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    Text(entry.summary)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                    Text(entry.recordedAt.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AtlasPalette.canvas)
        .navigationTitle("Timeline")
    }

    private var groupedTimelineEntries: [AtlasTimelineSection] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let groups = Dictionary(grouping: model.timelineEntries) { entry in
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

    public var body: some View {
        List {
            Section("Tools") {
                Button("Open Inventory") {
                    model.open(.inventory)
                }
                Button("Open Calculator") {
                    model.open(.calculator)
                }
            }

            if model.libraryProtocols.isEmpty {
                AtlasEmptyStateCard(
                    title: "Library is empty",
                    message: "Create a native protocol or import an Atlas Export v1 bundle to start building your core loop."
                ) {
                    Button("Create protocol") {
                        model.open(.protocolCreate)
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } else {
                Section("Protocols") {
                    ForEach(model.libraryProtocols) { summary in
                        Button {
                            model.open(.protocolDetail(summary.id))
                        } label: {
                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(model.renderedTitle(
                                        canonical: summary.canonicalTitle,
                                        alias: summary.aliasTitle
                                    ))
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                    Spacer()
                                    Text(summary.status.rawValue.capitalized)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AtlasPalette.primary)
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
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Change") {
                                model.open(.protocolChange(summary.id))
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AtlasPalette.canvas)
        .navigationTitle("Library")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    model.open(.protocolCreate)
                } label: {
                    Image(systemName: "plus")
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

    public var body: some View {
        List {
            if let detail {
                Section {
                    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                        Text(model.renderedTitle(canonical: detail.canonicalTitle, alias: detail.aliasTitle))
                            .font(.title2.weight(.bold))
                        Text("\(detail.kindLabel) • \(detail.cadenceLabel)")
                            .foregroundStyle(AtlasPalette.textSecondary)
                        if let doseLabel = detail.doseLabel {
                            Text("Dose \(doseLabel)")
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                    .padding(.vertical, AtlasSpacing.small)
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
                            }
                        )
                    }
                }

                Section("Notes") {
                    Text(detail.notes ?? "No notes")
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                Section("Future plan") {
                    Button("Edit core fields") {
                        model.open(.protocolEdit(protocolID))
                    }
                    Button("Inventory and sites") {
                        model.open(.inventory)
                    }
                    Button("Open Change Studio") {
                        model.open(.protocolChange(protocolID))
                    }
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
        .navigationTitle(mode.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(mode.buttonTitle) {
                    Task { await submit() }
                }
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

    public var body: some View {
        AtlasScreen {
            header("Settings", subtitle: "Local-first privacy controls remain visible while the app grows into a native iPhone experience.")

            AtlasSectionCard(title: "Account & sync") {
                Text(accountModeSummary)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text("Sync scaffold: \(syncSummary)")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
                if model.settingsSnapshot.onboardingCompleted {
                    Text("Onboarding complete")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.success)
                } else {
                    Text("Onboarding not completed on this local profile")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }
                Button("Reset onboarding state") {
                    Task { await model.resetOnboarding() }
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
            }

            AtlasSectionCard(title: "Privacy & trust") {
                Text(model.dependencies.privacyFormatter.summary(mode: model.settingsSnapshot.trustVaultStatus.renderMode))
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text("Account mode: \(model.settingsSnapshot.accountMode.rawValue)")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Picker(
                    "Display mode",
                    selection: Binding(
                        get: { model.settingsSnapshot.trustVaultStatus.renderMode },
                        set: { value in
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

            AtlasSectionCard(title: "Reminders") {
                Text("Scheduled locally from Atlas projections. Guest mode stays supported, and reminder copy follows your current privacy render mode.")
                    .foregroundStyle(AtlasPalette.textSecondary)

                Text("Permission: \(permissionLabel(model.notificationPermissionStatus))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textSecondary)

                if model.notificationPermissionStatus == .notDetermined {
                    Button("Allow notifications") {
                        Task { await model.requestReminderPermission() }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                } else if model.notificationPermissionStatus == .denied {
                    Text("Notifications are disabled for Atlas on this device.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Toggle(
                    "Enable local reminders",
                    isOn: Binding(
                        get: { model.reminderSettings.remindersEnabled },
                        set: { value in
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
                        get: { model.reminderSettings.leadTimeMinutes },
                        set: { value in
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
                        get: { model.reminderSettings.privacyMode },
                        set: { value in
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

                let preview = model.reminderPreview()
                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
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

            AtlasSectionCard(title: "System scaffolds") {
                let health = model.settingsSnapshot.healthScaffold
                Text(health.isAvailable ? "Apple Health scaffold is available and non-blocking." : "Health connection is unavailable on this device.")
                    .foregroundStyle(AtlasPalette.textSecondary)
                if let connection = health.connections.first {
                    Text("Health status: \(connection.connected ? "Connected" : "Connect later")")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Text(model.dependencies.healthKit.connectionDescription())
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text(model.dependencies.importExport.importStatusDescription())
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text(model.dependencies.sharedProjectionWriter.projectionDescription())
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
        }
    }

    private var accountModeSummary: String {
        switch model.settingsSnapshot.accountStartMode {
        case .guest:
            return "This profile started in guest mode."
        case .create:
            return "This profile started through the create-account boundary. Cloud sync still stays optional."
        case .signIn:
            return "This profile started through the sign-in boundary. Local-first access remains intact."
        case nil:
            return model.settingsSnapshot.accountMode == .guest
                ? "This profile is local-first and guest-friendly."
                : "Account scaffolding is available without making sync mandatory."
        }
    }

    private var syncSummary: String {
        switch model.settingsSnapshot.syncStatus {
        case .localOnly:
            return "Local only"
        case .accountBoundary:
            return "Account boundary scaffold"
        case .syncDeferred:
            return "Deferred"
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
            ForEach(actions, id: \.0) { action in
                Button(action.0) {
                    model.open(action.1)
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
            }
        }
    }
}

private struct AtlasOccurrenceHero: View {
    let occurrence: AtlasScheduledOccurrence
    let displayTitle: String
    let onLog: (AtlasOccurrenceLogAction) -> Void
    let onOpenProtocol: () -> Void
    let onOpenChangeStudio: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
            Text(displayTitle)
                .font(.title3.weight(.bold))
                .foregroundStyle(AtlasPalette.textPrimary)
            Text("\(occurrence.kindLabel) • \(occurrence.cadenceLabel)")
                .foregroundStyle(AtlasPalette.textSecondary)
            if let doseLabel = occurrence.doseLabel {
                Text("Dose \(doseLabel)")
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
            Text(occurrence.scheduledAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AtlasPalette.primary)

            VStack(spacing: AtlasSpacing.small) {
                Button("Mark taken") { onLog(.taken) }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                HStack(spacing: AtlasSpacing.small) {
                    Button("Skip") { onLog(.skipped) }
                        .buttonStyle(.bordered)
                    Button("Reschedule") { onLog(.rescheduled) }
                        .buttonStyle(.bordered)
                    Button("Protocol") { onOpenProtocol() }
                        .buttonStyle(.bordered)
                    Button("Change plan") { onOpenChangeStudio() }
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(AtlasSpacing.large)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AtlasPalette.border, lineWidth: 1)
        )
    }
}

private struct AtlasOccurrenceRow: View {
    let occurrence: AtlasScheduledOccurrence
    let title: String
    let action: (AtlasOccurrenceLogAction) -> Void
    var onOpenChangeStudio: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
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
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Taken") { action(.taken) }
                .tint(.green)
            Button("Skip") { action(.skipped) }
                .tint(.orange)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button("Reschedule") { action(.rescheduled) }
                .tint(.blue)
        }
        .contextMenu {
            if let onOpenChangeStudio {
                Button("Change plan") { onOpenChangeStudio() }
            }
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
    let actions: Actions

    init(
        title: String,
        message: String,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.message = message
        self.actions = actions()
    }

    var body: some View {
        AtlasSectionCard {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AtlasPalette.textPrimary)
            Text(message)
                .foregroundStyle(AtlasPalette.textSecondary)
            actions
        }
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
                            rescheduledAt = Date().addingTimeInterval(2 * 60 * 60)
                        }
                        Button("Tomorrow") {
                            rescheduledAt = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? rescheduledAt
                        }
                        Button("In 2 days") {
                            rescheduledAt = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? rescheduledAt
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
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
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
                }
            }
        }
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
