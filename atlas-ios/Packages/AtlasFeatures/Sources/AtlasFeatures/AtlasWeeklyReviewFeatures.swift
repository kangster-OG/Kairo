import AtlasDesignSystem
import AtlasDomain
import SwiftUI

enum AtlasWeeklyReviewActionDestination: Equatable {
    case today
    case insights
    case settings
    case protocolDetail(String)
    case protocolChange(String)
    case markReviewComplete
}

struct AtlasWeeklyReviewHighlightItem: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let symbolName: String
}

struct AtlasWeeklyReviewShiftItem: Identifiable, Equatable {
    let id: String
    let title: String
    let summary: String
    let facts: [AtlasExplainerFact]
    let symbolName: String
}

struct AtlasWeeklyReviewActionItem: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let symbolName: String
    let destination: AtlasWeeklyReviewActionDestination
}

struct AtlasWeeklyReviewActionOutcomeItem: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let statusLabel: String
    let statusDetail: String
    let symbolName: String
}

struct AtlasWeeklyReviewActionOutcomeSummary: Equatable {
    let previousPeriodTitle: String
    let summary: String
    let items: [AtlasWeeklyReviewActionOutcomeItem]
}

struct AtlasWeeklyReviewHistoryItem: Identifiable, Equatable {
    let id: String
    let periodTitle: String
    let summary: String
    let comparisonLabel: String
    let seed: AtlasWeeklyReviewSeed
}

struct AtlasWeeklyReviewComparisonMetric: Identifiable, Equatable {
    let id: String
    let label: String
    let currentValue: String
    let historicalValue: String
    let deltaLabel: String
}

struct AtlasWeeklyReviewComparisonSnapshot: Identifiable, Equatable {
    let id: String
    let historicalPeriodTitle: String
    let headline: String
    let summary: String
    let metrics: [AtlasWeeklyReviewComparisonMetric]
}

struct AtlasWeeklyReviewPresentation: Equatable {
    let seed: AtlasWeeklyReviewSeed
    let periodTitle: String
    let generatedAt: Date
    let summaryText: String
    let trustLabel: String
    let disclaimer: String
    let highlights: [AtlasWeeklyReviewHighlightItem]
    let shifts: [AtlasWeeklyReviewShiftItem]
    let actions: [AtlasWeeklyReviewActionItem]
    let history: [AtlasWeeklyReviewHistoryItem]
    let comparison: AtlasWeeklyReviewComparisonSnapshot?
    let actionOutcomes: AtlasWeeklyReviewActionOutcomeSummary?
    let protocolFollowUp: AtlasWeeklyReviewProtocolFollowUpSummary?
    let actionPlans: [AtlasWeeklyReviewActionPlan]
    let sourceSections: [AtlasSummarySourceSection]
    let isMarkedReviewed: Bool
    let summarySettingEnabled: Bool
    let reminderEnabled: Bool
}

private enum AtlasWeeklyReviewDetailSheet: Identifiable, Equatable {
    case shift(AtlasWeeklyReviewShiftItem)
    case history(AtlasWeeklyReviewHistoryItem)

    var id: String {
        switch self {
        case .shift(let item):
            return "shift:\(item.id)"
        case .history(let item):
            return "history:\(item.id)"
        }
    }
}

extension AtlasAppModel {
    func weeklyReviewPresentation() -> AtlasWeeklyReviewPresentation? {
        atlasWeeklyReviewPresentation(
            insightsSnapshot: insightsSnapshot,
            retentionSnapshot: retentionSnapshot,
            rewardsSnapshot: rewardsSnapshot,
            settingsSnapshot: settingsSnapshot
        )
    }

    func updateWeeklyReviewReminderSettings(
        _ settings: AtlasWeeklyReviewReminderSettings
    ) async {
        do {
            settingsSnapshot = try await dependencies.persistence.settings.updateWeeklyReviewReminderSettings(
                settings,
                now: currentDate()
            )
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    func saveWeeklyReviewActionPlan(
        _ action: AtlasWeeklyReviewActionItem,
        seed: AtlasWeeklyReviewSeed
    ) async {
        guard let route = atlasWeeklyReviewRoute(for: action.destination) else {
            return
        }

        let plan = AtlasWeeklyReviewActionPlan(
            id: "weekly-review-\(seed.windowStart.timeIntervalSince1970)-\(action.id)",
            title: action.title,
            detail: action.detail,
            symbolName: action.symbolName,
            route: route,
            reviewPeriodStart: ISO8601DateFormatter.atlas.string(from: seed.windowStart),
            reviewPeriodEnd: ISO8601DateFormatter.atlas.string(from: seed.windowEnd),
            createdAt: ISO8601DateFormatter.atlas.string(from: currentDate())
        )

        do {
            settingsSnapshot = try await dependencies.persistence.settings.saveWeeklyReviewActionPlan(
                plan,
                now: currentDate()
            )
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    func updateWeeklyReviewActionPlan(
        id: String,
        isCompleted: Bool? = nil,
        isPinnedForNextWeek: Bool? = nil
    ) async {
        do {
            settingsSnapshot = try await dependencies.persistence.settings.updateWeeklyReviewActionPlan(
                id: id,
                isCompleted: isCompleted,
                isPinnedForNextWeek: isPinnedForNextWeek,
                now: currentDate()
            )
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    func removeWeeklyReviewActionPlan(id: String) async {
        do {
            settingsSnapshot = try await dependencies.persistence.settings.removeWeeklyReviewActionPlan(
                id: id,
                now: currentDate()
            )
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    func openWeeklyReviewRoute(_ route: AtlasWeeklyReviewActionRoute) {
        switch route {
        case .today:
            routePath.removeAll()
            activeTab = .today
        case .insights:
            routePath.removeAll()
            activeTab = .insights
        case .settings:
            routePath.removeAll()
            activeTab = .settings
        case .protocolDetail(let id):
            routePath.removeAll()
            activeTab = .today
            open(.protocolDetail(id))
        case .protocolChange(let id):
            routePath.removeAll()
            activeTab = .today
            open(.protocolChange(id))
        }
    }

    func exportWeeklyReviewPack(_ snapshot: AtlasWeeklyReviewPresentation) async -> URL? {
        guard await unlockTrustVaultIfNeeded(reason: "Export Weekly Review") else {
            return nil
        }

        do {
            let url = try atlasWriteWeeklyReviewExport(snapshot: snapshot)
            triggerAmbientMascotReaction(.artifactReady)
            return url
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }
}

public struct AtlasWeeklyReviewScreen: View {
    @Bindable private var model: AtlasAppModel
    @State private var detailSheet: AtlasWeeklyReviewDetailSheet?
    @State private var archivePresented = false
    @State private var shareURL: URL?
    @State private var isExporting = false
    @State private var closeoutState: AtlasWeeklyReviewCloseoutState?
    @State private var mascotContentNoticeTrigger = 0

    public init(model: AtlasAppModel) {
        self.model = model
    }

    public var body: some View {
        let snapshot = model.weeklyReviewPresentation()

        AtlasScreen {
            if let snapshot {
                AtlasCommandDeck(
                    eyebrow: snapshot.periodTitle,
                    title: weeklyReviewDeckTitle(snapshot),
                    detail: snapshot.summaryText,
                    metrics: weeklyReviewMetrics(snapshot),
                    style: .hero
                ) {
                    VStack(spacing: AtlasSpacing.small) {
                        if let primaryAction = snapshot.actions.first {
                            Button(primaryAction.title) {
                                AtlasFeedback.selection()
                                perform(primaryAction)
                            }
                            .buttonStyle(AtlasPrimaryButtonStyle())

                            if atlasWeeklyReviewRoute(for: primaryAction.destination) != nil,
                               snapshot.actionPlans.contains(where: { $0.id == atlasWeeklyReviewActionPlanID(for: primaryAction, seed: snapshot.seed) }) == false {
                                Button("Save for next week") {
                                    AtlasFeedback.selection()
                                    Task {
                                        await model.saveWeeklyReviewActionPlan(primaryAction, seed: snapshot.seed)
                                    }
                                }
                                .buttonStyle(AtlasSecondaryButtonStyle())
                            }
                        }

                        if snapshot.isMarkedReviewed == false {
                            Button("Mark weekly review complete") {
                                Task { await completeWeeklyReviewWithReveal() }
                            }
                            .buttonStyle(AtlasTertiaryButtonStyle())
                        }
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                        AtlasWeeklyReviewSignalStrip(snapshot: snapshot)

                        AtlasWeeklyReviewTrustPanel(
                            trustLabel: snapshot.trustLabel,
                            disclaimer: snapshot.disclaimer
                        )

                        AtlasProgressMeter(
                            title: "Closure",
                            detail: weeklyReviewClosureDetail(snapshot),
                            value: weeklyReviewClosureValue(snapshot),
                            tint: snapshot.isMarkedReviewed ? AtlasPalette.success : AtlasPalette.primary
                        )
                    }
                }

                AtlasWeeklyReviewCommandDeck(
                    model: model,
                    snapshot: snapshot
                )

                if let closeoutState {
                    AtlasMilestoneRevealBanner(
                        eyebrow: closeoutState.eyebrow,
                        title: closeoutState.title,
                        detail: closeoutState.detail,
                        tint: closeoutState.tint,
                        badge: closeoutState.badge,
                        symbolName: closeoutState.symbolName
                    )
                }

                AtlasWeeklyReviewPayoffCard(
                    model: model,
                    snapshot: snapshot,
                    closureValue: weeklyReviewClosureValue(snapshot),
                    closureDetail: weeklyReviewClosureDetail(snapshot),
                    contentNoticeTrigger: mascotContentNoticeTrigger,
                    suppression: atlasAmbientMascotSuppression(
                        presentingSheet: detailSheet != nil
                            || archivePresented
                            || model.pendingMascotCelebration != nil,
                        presentingExport: shareURL != nil
                    ),
                    exportAction: { await exportWeeklyReview(snapshot) },
                    markCompleteAction: snapshot.isMarkedReviewed
                        ? nil
                        : { await completeWeeklyReviewWithReveal() },
                    openMascotAction: model.rewardsSnapshot.settings.enabled
                        ? {
                            model.routePath.removeAll()
                            model.activeTab = .today
                            model.open(.mascot)
                        }
                        : nil
                )

                if snapshot.highlights.isEmpty == false {
                    AtlasSectionCard(style: .reward, title: "Weekly highlights") {
                        ForEach(Array(snapshot.highlights.prefix(3).enumerated()), id: \.element.id) { index, highlight in
                            if index > 0 {
                                Divider()
                            }
                            AtlasWeeklyReviewHighlightRow(item: highlight)
                        }
                    }
                }

                if snapshot.shifts.isEmpty == false {
                    AtlasSectionCard(style: .task, title: "What shifted") {
                        AtlasCalloutRow(
                            systemImage: "waveform.path.ecg.text",
                            title: "Visible patterns",
                            detail: nil,
                            tint: AtlasPalette.secondaryText
                        )

                        ForEach(Array(snapshot.shifts.prefix(3).enumerated()), id: \.element.id) { index, shift in
                            if index > 0 {
                                Divider()
                            }
                            AtlasWeeklyReviewShiftRow(item: shift) {
                                detailSheet = .shift(shift)
                            }
                        }
                    }
                }

                if let stackSummary = snapshot.seed.stackSummary {
                    AtlasSectionCard(style: .task, title: "Stack review") {
                        AtlasCalloutRow(
                            systemImage: "square.stack.3d.up.fill",
                            title: "Current stack burden",
                            detail: stackSummary.burdenSummary,
                            tint: AtlasPalette.primary
                        )

                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            ForEach([
                                AtlasExplainerFact(label: "Active stack items", value: String(stackSummary.activeProtocolCount)),
                                AtlasExplainerFact(label: "Protocols changed", value: String(stackSummary.protocolsWithChanges)),
                                AtlasExplainerFact(label: "Completed logs", value: String(stackSummary.weeklyCompletedCount)),
                                AtlasExplainerFact(label: "Moved logs", value: String(stackSummary.weeklyRescheduledCount)),
                                AtlasExplainerFact(label: "Inventory risk", value: String(stackSummary.lowStockRiskCount))
                            ]) { fact in
                                Text("\(fact.label): \(fact.value)")
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                    }
                }

                if let actionOutcomes = snapshot.actionOutcomes {
                    AtlasSectionCard(style: .task, title: "Action follow-through") {
                        AtlasCalloutRow(
                            systemImage: "checkmark.circle.badge.questionmark",
                            title: "Follow-through signal",
                            detail: actionOutcomes.summary,
                            tint: AtlasPalette.success
                        )

                        ForEach(Array(actionOutcomes.items.enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Divider()
                            }
                            AtlasWeeklyReviewActionOutcomeRow(item: item)
                        }
                    }
                }

                if let protocolFollowUp = snapshot.protocolFollowUp {
                    AtlasSectionCard(style: .task, title: "Since the latest plan change") {
                        AtlasWeeklyReviewProtocolFollowUpView(
                            summary: protocolFollowUp,
                            openAction: {
                                model.openWeeklyReviewRoute(.protocolChange(protocolFollowUp.protocolID))
                            }
                        )
                    }
                }

                if snapshot.history.isEmpty == false {
                    AtlasSectionCard(style: .utility, title: "Archive & compare") {
                        AtlasCalloutRow(
                            systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                            title: "Past weeks stay available",
                            detail: nil,
                            tint: AtlasPalette.secondaryText
                        )

                        if let comparison = snapshot.comparison {
                            AtlasWeeklyReviewComparisonCard(snapshot: comparison) {
                                archivePresented = true
                            }
                        }

                        ForEach(Array(snapshot.history.prefix(2).enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Divider()
                            }
                            AtlasWeeklyReviewHistoryRow(item: item) {
                                detailSheet = .history(item)
                            }
                        }

                        Button("Open full archive") {
                            AtlasFeedback.selection()
                            archivePresented = true
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                }

                if snapshot.actionPlans.isEmpty == false {
                    AtlasSectionCard(style: .reward, title: "Weekly focus") {
                        AtlasCalloutRow(
                            systemImage: "flag.2.crossed",
                            title: "Saved follow-through",
                            detail: nil,
                            tint: AtlasPalette.reward
                        )

                        ForEach(Array(snapshot.actionPlans.enumerated()), id: \.element.id) { index, plan in
                            if index > 0 {
                                Divider()
                            }
                            AtlasWeeklyReviewSavedActionRow(
                                item: plan,
                                openAction: {
                                    model.openWeeklyReviewRoute(plan.route)
                                },
                                toggleCompleteAction: {
                                    Task {
                                        await model.updateWeeklyReviewActionPlan(
                                            id: plan.id,
                                            isCompleted: !plan.isCompleted
                                        )
                                    }
                                },
                                togglePinnedAction: {
                                    Task {
                                        await model.updateWeeklyReviewActionPlan(
                                            id: plan.id,
                                            isPinnedForNextWeek: !plan.isPinnedForNextWeek
                                        )
                                    }
                                },
                                removeAction: {
                                    Task {
                                        await model.removeWeeklyReviewActionPlan(id: plan.id)
                                    }
                                }
                            )
                        }
                    }
                }

                if snapshot.actions.count > 1 {
                    AtlasSectionCard(style: .task, title: "Next actions") {
                        ForEach(Array(snapshot.actions.dropFirst().enumerated()), id: \.element.id) { index, action in
                            if index > 0 {
                                Divider()
                            }
                            AtlasWeeklyReviewActionRow(
                                item: action,
                                isSaved: snapshot.actionPlans.contains(where: {
                                    $0.id == atlasWeeklyReviewActionPlanID(for: action, seed: snapshot.seed)
                                }),
                                action: {
                                    perform(action)
                                },
                                saveAction: atlasWeeklyReviewRoute(for: action.destination).map { _ in
                                    {
                                        Task {
                                            await model.saveWeeklyReviewActionPlan(action, seed: snapshot.seed)
                                        }
                                    }
                                }
                            )
                        }
                    }
                }

                AtlasSectionCard(style: .utility, title: "Source facts") {
                    ForEach(Array(snapshot.sourceSections.enumerated()), id: \.element.id) { index, section in
                        if index > 0 {
                            Divider()
                        }

                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            Text(section.title)
                                .atlasTextRole(.deckEyebrow)
                                .foregroundStyle(AtlasPalette.primary)

                            ForEach(section.facts) { fact in
                                HStack(alignment: .top, spacing: AtlasSpacing.small) {
                                    Text(fact.label)
                                        .atlasTextRole(.supporting)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                    Spacer(minLength: 12)
                                    Text(fact.value)
                                        .atlasTextRole(.supporting)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                }
                            }
                        }
                    }
                }
            } else {
                AtlasCommandDeck(
                    eyebrow: "WEEKLY REVIEW",
                    title: "Weekly Review needs more signal.",
                    detail: "Add more logs and context first.",
                    style: .hero
                ) {
                    Button("Open Insights") {
                        AtlasFeedback.selection()
                        model.routePath.removeAll()
                        model.activeTab = .insights
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                } footer: {
                    AtlasCalloutRow(
                        systemImage: "sparkles.rectangle.stack",
                        title: "Check back after more activity",
                        detail: nil,
                        tint: AtlasPalette.secondaryText
                    )
                }
            }
        }
        .navigationTitle("Weekly Review")
        .navigationBarTitleDisplayMode(.inline)
        .atlasAmbientMascotOpenReaction(model: model, kind: .openedSurface)
        .onChange(of: closeoutState?.title) { oldValue, newValue in
            guard oldValue != newValue,
                  newValue != nil else {
                return
            }
            mascotContentNoticeTrigger &+= 1
        }
        .toolbar {
            if let snapshot {
                ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            AtlasFeedback.selection()
                            Task {
                                await exportWeeklyReview(snapshot)
                            }
                        } label: {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .disabled(isExporting)
                    .accessibilityLabel("Share weekly review")
                }
            }
        }
        .sheet(item: $detailSheet) { item in
            AtlasWeeklyReviewDetailSheetView(item: item)
        }
        .sheet(isPresented: $archivePresented) {
            if let snapshot {
                AtlasWeeklyReviewArchiveScreen(snapshot: snapshot)
            }
        }
        .sheet(
            isPresented: Binding(
                get: { shareURL != nil },
                set: { isPresented in
                    if isPresented == false {
                        shareURL = nil
                    }
                }
            )
        ) {
            if let shareURL {
                AtlasFileShareSheet(fileURL: shareURL)
            }
        }
        .task(id: snapshot == nil) {
            guard snapshot == nil else {
                return
            }
            await model.loadShellDataIfNeeded()
        }
    }

    private func perform(_ action: AtlasWeeklyReviewActionItem) {
        switch action.destination {
        case .today:
            model.routePath.removeAll()
            model.activeTab = .today
        case .insights:
            model.routePath.removeAll()
            model.activeTab = .insights
        case .settings:
            model.routePath.removeAll()
            model.activeTab = .settings
        case .protocolDetail(let id):
            model.routePath.removeAll()
            model.activeTab = .today
            model.open(.protocolDetail(id))
        case .protocolChange(let id):
            model.routePath.removeAll()
            model.activeTab = .today
            model.open(.protocolChange(id))
        case .markReviewComplete:
            Task { await completeWeeklyReviewWithReveal() }
        }
    }

    private func exportWeeklyReview(_ snapshot: AtlasWeeklyReviewPresentation) async {
        isExporting = true
        defer { isExporting = false }
        closeoutState = AtlasWeeklyReviewCloseoutState(
            eyebrow: "Pack staging",
            title: "Preparing weekly review export.",
            detail: "Building the recap pack.",
            tint: AtlasPalette.reward,
            badge: snapshot.periodTitle,
            symbolName: "square.and.arrow.up.fill"
        )
        AtlasFeedback.milestoneReveal()
        shareURL = await model.exportWeeklyReviewPack(snapshot)
        if shareURL != nil {
            closeoutState = AtlasWeeklyReviewCloseoutState(
                eyebrow: "Pack ready",
                title: "Weekly review export is ready.",
                detail: "Share when ready.",
                tint: model.rewardsSnapshot.settings.enabled ? atlasMascotLineTint(for: model.settingsSnapshot.mascotSelection) : AtlasPalette.success,
                badge: model.rewardsSnapshot.settings.enabled ? atlasRewardsEvolutionProgress(for: model.rewardsSnapshot, selection: model.settingsSnapshot.mascotSelection).stageBadge : "Review",
                symbolName: "sparkles"
            )
            AtlasFeedback.weeklyCloseout()
        } else {
            closeoutState = nil
        }
    }

    private func completeWeeklyReviewWithReveal() async {
        closeoutState = AtlasWeeklyReviewCloseoutState(
            eyebrow: "Closing the loop",
            title: "Marking this week reviewed.",
            detail: "Saving the review and carry-forward state.",
            tint: AtlasPalette.reward,
            badge: model.rewardsSnapshot.settings.enabled ? atlasRewardsEvolutionProgress(for: model.rewardsSnapshot, selection: model.settingsSnapshot.mascotSelection).stageBadge : "Review",
            symbolName: "checkmark.seal.fill"
        )
        AtlasFeedback.milestoneReveal()
        await model.markWeeklyReviewComplete()
        closeoutState = AtlasWeeklyReviewCloseoutState(
            eyebrow: "Week anchored",
            title: "Week marked reviewed.",
            detail: model.rewardsSnapshot.settings.enabled
                ? "\(atlasRewardsEvolutionProgress(for: model.rewardsSnapshot, selection: model.settingsSnapshot.mascotSelection).currentFormName) remains the weekly guardian. The next unlock stays visible."
                : "The review is saved and follow-through stays visible.",
            tint: model.rewardsSnapshot.settings.enabled ? atlasMascotLineTint(for: model.settingsSnapshot.mascotSelection) : AtlasPalette.success,
            badge: model.rewardsSnapshot.settings.enabled ? "Guardian payoff" : "Reviewed",
            symbolName: model.rewardsSnapshot.settings.enabled ? atlasMascotLineSymbol(for: model.settingsSnapshot.mascotSelection) : "checkmark.circle.fill"
        )
        AtlasFeedback.weeklyCloseout()
    }

    private func weeklyReviewDeckTitle(_ snapshot: AtlasWeeklyReviewPresentation) -> String {
        if snapshot.isMarkedReviewed {
            return "This week has been reviewed and anchored."
        }
        if snapshot.actions.isEmpty == false {
            return "Close the week with one clear next move."
        }
        return "Review the week, then carry the right signal forward."
    }

    private func weeklyReviewMetrics(_ snapshot: AtlasWeeklyReviewPresentation) -> [AtlasMetricItem] {
        [
            AtlasMetricItem(
                id: "review_status",
                title: "Status",
                value: snapshot.isMarkedReviewed ? "Reviewed" : "Ready",
                tint: snapshot.isMarkedReviewed ? AtlasPalette.success : AtlasPalette.primary
            ),
            AtlasMetricItem(
                id: "highlights",
                title: "Highlights",
                value: "\(snapshot.highlights.count)",
                tint: AtlasPalette.reward
            ),
            AtlasMetricItem(
                id: "shifts",
                title: "Shifts",
                value: "\(snapshot.shifts.count)",
                tint: AtlasPalette.secondaryText
            ),
            AtlasMetricItem(
                id: "saved",
                title: "Saved",
                value: "\(snapshot.actionPlans.count)",
                tint: AtlasPalette.secondaryText
            )
        ]
    }

    private func weeklyReviewClosureValue(_ snapshot: AtlasWeeklyReviewPresentation) -> Double {
        if snapshot.isMarkedReviewed {
            return 1
        }
        let total = max(snapshot.actions.count + snapshot.actionPlans.count, 1)
        let completed = snapshot.actionPlans.filter(\.isCompleted).count
        return min(max(Double(completed) / Double(total), 0.18), 0.92)
    }

    private func weeklyReviewClosureDetail(_ snapshot: AtlasWeeklyReviewPresentation) -> String {
        if snapshot.isMarkedReviewed {
            return "Review complete. Saved follow-through stays visible in Today."
        }
        if let primaryAction = snapshot.actions.first {
            return "Primary focus: \(primaryAction.title). Save it for next week if needed."
        }
        return "No single follow-through item stands above the rest."
    }
}

private struct AtlasWeeklyReviewCommandDeck: View {
    let model: AtlasAppModel
    let snapshot: AtlasWeeklyReviewPresentation

    var body: some View {
        AtlasCommandDeck(
            eyebrow: "AT A GLANCE",
            title: snapshot.actions.first?.title ?? "No follow-through queued",
            detail: snapshot.actions.first?.detail ?? "No single follow-through item stands out right now.",
            metrics: [
                AtlasMetricItem(id: "plans", title: "Saved plans", value: "\(snapshot.actionPlans.count)", tint: AtlasPalette.reward),
                AtlasMetricItem(id: "history", title: "History", value: "\(snapshot.history.count)", tint: AtlasPalette.secondaryText)
            ],
            tint: AtlasPalette.primary,
            style: .task
        ) {
            HStack(spacing: AtlasSpacing.small) {
                Button("Open Today") {
                    AtlasFeedback.selection()
                    model.routePath.removeAll()
                    model.activeTab = .today
                }
                .buttonStyle(AtlasPrimaryButtonStyle())

                Button("Open Insights") {
                    AtlasFeedback.selection()
                    model.routePath.removeAll()
                    model.activeTab = .insights
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
            }
        } footer: {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                AtlasCalloutRow(
                    systemImage: "waveform.path.ecg",
                    title: continuityTitle,
                    detail: continuityDetail,
                    tint: AtlasPalette.secondaryText,
                    badge: model.settingsSnapshot.labsEnabled ? "Labs" : nil
                )

                AtlasCalloutRow(
                    systemImage: "pin",
                    title: snapshot.actionPlans.isEmpty ? "No saved plans yet" : "\(snapshot.actionPlans.count) follow-through item(s) saved",
                    detail: snapshot.actionPlans.isEmpty
                        ? "Save one action to keep it visible in Today next week."
                        : "Saved follow-through stays visible in Weekly Review and Today.",
                    tint: AtlasPalette.reward,
                    badge: snapshot.actionPlans.isEmpty ? nil : "Pinned"
                )
            }
        }
    }

    private var continuityTitle: String {
        if model.settingsSnapshot.healthScaffold.connections.contains(where: { $0.connected }) {
            return model.settingsSnapshot.labsEnabled ? "Health connected + labs enabled" : "Health connected"
        }
        return model.settingsSnapshot.labsEnabled ? "Local review + labs enabled" : "Local review"
    }

    private var continuityDetail: String {
        let health = model.settingsSnapshot.healthScaffold
        var details: [String] = []

        if health.connections.contains(where: { $0.connected }) {
            if health.syncedWeightEntryCount > 0 {
                details.append("\(health.syncedWeightEntryCount) Health weight import\(health.syncedWeightEntryCount == 1 ? "" : "s")")
            } else {
                details.append("Health connected")
            }
            if health.syncedWorkoutEntryCount > 0 {
                details.append("\(health.syncedWorkoutEntryCount) Health workout import\(health.syncedWorkoutEntryCount == 1 ? "" : "s")")
            }
        } else {
            details.append("Health optional")
        }

        if model.settingsSnapshot.labsEnabled {
            details.append("Labs enabled")
        }

        if let lastSyncAt = health.connections.first?.lastSyncAt,
           let date = ISO8601DateFormatter.atlas.date(from: lastSyncAt) {
            details.append("Last sync \(date.formatted(date: .abbreviated, time: .shortened))")
        }
        details.append("Trust mode: \(snapshot.trustLabel)")

        return details.joined(separator: " • ")
    }
}

private struct AtlasWeeklyReviewSignalStrip: View {
    let snapshot: AtlasWeeklyReviewPresentation

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AtlasSpacing.small) {
                signalPills
            }

            VStack(spacing: AtlasSpacing.small) {
                HStack(spacing: AtlasSpacing.small) {
                    AtlasWeeklyReviewSignalPill(
                        title: "Highlights",
                        value: "\(snapshot.highlights.count)"
                    )
                    AtlasWeeklyReviewSignalPill(
                        title: "Shifts",
                        value: "\(snapshot.shifts.count)"
                    )
                }
                AtlasWeeklyReviewSignalPill(
                    title: "Saved",
                    value: "\(snapshot.actionPlans.count)"
                )
            }
        }
    }

    @ViewBuilder
    private var signalPills: some View {
        AtlasWeeklyReviewSignalPill(
            title: "Highlights",
            value: "\(snapshot.highlights.count)"
        )
        AtlasWeeklyReviewSignalPill(
            title: "Shifts",
            value: "\(snapshot.shifts.count)"
        )
        AtlasWeeklyReviewSignalPill(
            title: "Saved",
            value: "\(snapshot.actionPlans.count)"
        )
    }
}

private struct AtlasWeeklyReviewSignalPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .atlasTextRole(.metricLabel)
                .foregroundStyle(AtlasPalette.primary)
            Text(value)
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct AtlasWeeklyReviewPayoffCard: View {
    let model: AtlasAppModel
    let snapshot: AtlasWeeklyReviewPresentation
    let closureValue: Double
    let closureDetail: String
    let contentNoticeTrigger: Int
    let suppression: AtlasAmbientMascotSuppression
    let exportAction: () async -> Void
    let markCompleteAction: (() async -> Void)?
    let openMascotAction: (() -> Void)?
    @State private var isSharingPack = false
    @State private var isClosingWeek = false
    @State private var courtesySignal = 0

    var body: some View {
        let rewardsEnabled = model.rewardsSnapshot.settings.enabled
        let selection = model.settingsSnapshot.mascotSelection
        let evolution = atlasRewardsEvolutionProgress(for: model.rewardsSnapshot, selection: selection)
        let latestMoment = model.settingsSnapshot.mascotMoments.first { $0.selection == selection }

        AtlasSectionCard(style: .reward) {
            VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                        HStack(spacing: AtlasSpacing.small) {
                            AtlasStatusBadge(
                                snapshot.isMarkedReviewed ? "Week anchored" : "Review payoff",
                                tint: snapshot.isMarkedReviewed ? AtlasPalette.success : AtlasPalette.reward
                            )
                            if rewardsEnabled {
                                AtlasStatusBadge(evolution.stageBadge, tint: atlasMascotLineTint(for: selection))
                            }
                        }

                        Text(
                            snapshot.isMarkedReviewed
                                ? "This week is already stored as a finished chapter."
                                : "Close the week with a payoff that feels earned."
                        )
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(AtlasPalette.textPrimary)

                        Text(
                            rewardsEnabled
                                ? (snapshot.isMarkedReviewed
                                    ? "\(evolution.currentFormName) remains the weekly guardian. The next unlock stays visible."
                                    : "\(evolution.currentFormName) carries the week forward. Save the week or export the pack to keep the next unlock moving.")
                                : closureDetail
                        )
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    Spacer(minLength: 8)

                    if rewardsEnabled {
                        VStack(spacing: AtlasSpacing.small) {
                            AtlasMascotSticker(
                                line: atlasMascotLine(for: selection),
                                stage: evolution.stage,
                                size: 96
                            )
                            AtlasStatusBadge("Weekly guardian", tint: atlasMascotLineHighlight(for: selection))
                        }
                    }
                }

                AtlasMetricStrip(
                    metrics: [
                        AtlasMetricItem(
                            id: "closure",
                            title: "Closure",
                            value: snapshot.isMarkedReviewed ? "Done" : "\(Int(closureValue * 100))%",
                            tint: snapshot.isMarkedReviewed ? AtlasPalette.success : AtlasPalette.reward
                        ),
                        AtlasMetricItem(
                            id: "saved",
                            title: "Saved plans",
                            value: "\(snapshot.actionPlans.count)",
                            tint: snapshot.actionPlans.isEmpty ? AtlasPalette.secondaryText : AtlasPalette.primary
                        ),
                        AtlasMetricItem(
                            id: "archive",
                            title: "Archive",
                            value: "\(snapshot.history.count)",
                            tint: AtlasPalette.secondaryText
                        )
                    ]
                )

                AtlasProgressMeter(
                    title: rewardsEnabled ? "Mascot payoff" : "Review payoff",
                    detail: rewardsEnabled
                        ? (evolution.nextFormName == nil
                            ? "The guardian line is fully evolved, so this week now feeds archive quality and recap poster strength."
                            : evolution.progressLabel)
                        : closureDetail,
                    value: rewardsEnabled ? max(evolution.progressFraction ?? 1, closureValue) : closureValue,
                    tint: rewardsEnabled ? atlasMascotLineTint(for: selection) : AtlasPalette.reward
                )

                if rewardsEnabled {
                    AtlasCalloutRow(
                        systemImage: latestMoment?.symbolName ?? atlasMascotLineSymbol(for: selection),
                        title: latestMoment == nil ? "Next unlock stays attached" : "Mascot momentum is already visible",
                        detail: latestMoment == nil
                            ? (evolution.nextFormName == nil
                                ? "The full line is already unlocked."
                                : "\(evolution.nextFormName ?? "Next form") is the next unlock.")
                            : "Latest moment: \(latestMoment?.title ?? "recent mascot moment").",
                        tint: atlasMascotLineTint(for: selection),
                        badge: latestMoment == nil ? evolution.stageBadge : "Journaled"
                    )
                }

                HStack(spacing: AtlasSpacing.small) {
                    if let markCompleteAction {
                        Button(isClosingWeek ? "Anchoring week…" : "Mark review complete") {
                            guard isClosingWeek == false else {
                                return
                            }
                            courtesySignal &+= 1
                            isClosingWeek = true
                            Task {
                                await markCompleteAction()
                                isClosingWeek = false
                            }
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                        .disabled(isClosingWeek)
                    }

                    Button(isSharingPack ? "Preparing pack…" : "Share weekly pack") {
                        guard isSharingPack == false else {
                            return
                        }
                        courtesySignal &+= 1
                        isSharingPack = true
                        Task {
                            await exportAction()
                            isSharingPack = false
                        }
                    }
                    .modifier(
                        AtlasWeeklyReviewShareButtonStyleModifier(usePrimary: markCompleteAction == nil)
                    )
                    .disabled(isSharingPack)

                    if let openMascotAction {
                        Button("Open mascot") {
                            courtesySignal &+= 1
                            AtlasFeedback.selection()
                            openMascotAction()
                        }
                        .buttonStyle(AtlasTertiaryButtonStyle())
                    }
                }
            }
        }
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
                    context: .weeklyReviewPayoff,
                    size: 64,
                    courtesySignal: courtesySignal,
                    contentNoticeTrigger: contentNoticeTrigger,
                    suppression: suppression,
                    reactionSignal: model.ambientMascotReactionSignal,
                    milestoneNearby: atlasAmbientMascotMilestoneNearby(
                        settingsSnapshot: model.settingsSnapshot,
                        rewardsSnapshot: model.rewardsSnapshot,
                        pendingCelebration: model.pendingMascotCelebration
                    )
                )
                .offset(x: -14, y: -12)
            }
        }
    }
}

private struct AtlasWeeklyReviewCloseoutState {
    let eyebrow: String
    let title: String
    let detail: String
    let tint: Color
    let badge: String?
    let symbolName: String
}

private struct AtlasWeeklyReviewShareButtonStyleModifier: ViewModifier {
    let usePrimary: Bool

    func body(content: Content) -> some View {
        if usePrimary {
            content.buttonStyle(AtlasPrimaryButtonStyle())
        } else {
            content.buttonStyle(AtlasSecondaryButtonStyle())
        }
    }
}

private struct AtlasWeeklyReviewCommandCard: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            Text(title)
                .atlasTextRole(.deckEyebrow)
                .foregroundStyle(AtlasPalette.primary)
            Text(value)
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)
            Text(detail)
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.62))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}

struct AtlasWeeklyReviewEntrySection: View {
    @Bindable var model: AtlasAppModel

    var body: some View {
        let snapshot = model.weeklyReviewPresentation()

        if let snapshot {
            Section("Weekly review") {
                AtlasSectionCard(style: .elevated) {
                    HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            Text("Weekly Review")
                                .atlasTextRole(.cardBody)
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text(snapshot.generatedAt.formatted(date: .abbreviated, time: .shortened))
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }

                        Spacer()

                        AtlasStatusBadge(
                            snapshot.isMarkedReviewed ? "Reviewed" : "Open",
                            tint: snapshot.isMarkedReviewed ? AtlasPalette.success : AtlasPalette.secondaryText
                        )
                    }

                    Text(snapshot.summaryText)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .lineLimit(4)

                    if let highlight = snapshot.highlights.first {
                        HStack(spacing: AtlasSpacing.small) {
                            Image(systemName: highlight.symbolName)
                                .foregroundStyle(AtlasPalette.primary)
                            Text(highlight.title)
                                .atlasTextRole(.deckEyebrow)
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Spacer()
                        }
                    }

                    Button("Open weekly review") {
                        AtlasFeedback.selection()
                        model.open(.weeklyReview)
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                }
            }
        }
    }
}

struct AtlasWeeklyFocusTodaySection: View {
    @Bindable var model: AtlasAppModel

    var body: some View {
        let snapshot = model.weeklyReviewPresentation()

        if let snapshot, snapshot.actionPlans.isEmpty == false || snapshot.actions.isEmpty == false {
            AtlasSectionCard(style: .elevated) {
                VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                    HStack(alignment: .top, spacing: AtlasSpacing.small) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weekly focus")
                                .atlasTextRole(.cardBody)
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text(snapshot.periodTitle)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                        Spacer()
                        AtlasStatusBadge(
                            snapshot.actionPlans.isEmpty ? "Ready" : "\(snapshot.actionPlans.count) saved",
                            tint: snapshot.actionPlans.isEmpty ? AtlasPalette.secondaryText : AtlasPalette.primary
                        )
                    }

                    if let savedPlan = snapshot.actionPlans.first {
                        Text(savedPlan.title)
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(savedPlan.detail)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)

                        HStack(spacing: AtlasSpacing.small) {
                            Button("Open focus") {
                                AtlasFeedback.selection()
                                model.openWeeklyReviewRoute(savedPlan.route)
                            }
                            .buttonStyle(AtlasSecondaryButtonStyle())

                            Button(savedPlan.isCompleted ? "Mark active" : "Mark done") {
                                AtlasFeedback.selection()
                                Task {
                                    await model.updateWeeklyReviewActionPlan(
                                        id: savedPlan.id,
                                        isCompleted: !savedPlan.isCompleted
                                    )
                                }
                            }
                            .buttonStyle(AtlasTertiaryButtonStyle())
                        }
                    } else if let nextAction = snapshot.actions.first {
                        Text(nextAction.title)
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(nextAction.detail)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)

                        HStack(spacing: AtlasSpacing.small) {
                            Button("Open weekly review") {
                                AtlasFeedback.selection()
                                model.open(.weeklyReview)
                            }
                            .buttonStyle(AtlasPrimaryButtonStyle())

                            if atlasWeeklyReviewRoute(for: nextAction.destination) != nil {
                                Button("Save focus") {
                                    AtlasFeedback.selection()
                                    Task {
                                        await model.saveWeeklyReviewActionPlan(nextAction, seed: snapshot.seed)
                                    }
                                }
                                .buttonStyle(AtlasSecondaryButtonStyle())
                            }
                        }
                    }
                }
            }
        }
    }
}

private func atlasWeeklyReviewPresentation(
    insightsSnapshot: AtlasInsightsSnapshot,
    retentionSnapshot: AtlasRetentionSnapshot,
    rewardsSnapshot: AtlasRewardsSnapshot,
    settingsSnapshot: AtlasSettingsSnapshot
) -> AtlasWeeklyReviewPresentation? {
    guard let seed = insightsSnapshot.weeklyReviewSeed else {
        return nil
    }

    let reviewCompleted = retentionSnapshot.milestones.first(where: { $0.kind == .weeklyReviewCompleted })?.isEarned == true
    let summaryText = seed.plainLanguageSummary?.summary ?? seed.fallbackSummary
    let disclaimer = seed.plainLanguageSummary?.disclaimer
        ?? "Local facts and suggested next steps only. No causal claims."
    let trustLabel = seed.plainLanguageSummary?.executionMode.label ?? "Source-backed week view"
    let sourceSections = seed.sourceSections
        + atlasWeeklyReviewRewardsSections(
            rewardsSnapshot: rewardsSnapshot,
            settingsSnapshot: settingsSnapshot
        )
        + atlasWeeklyReviewMascotSections(
            rewardsSnapshot: rewardsSnapshot,
            settingsSnapshot: settingsSnapshot,
            windowStart: seed.windowStart
        )
        + atlasWeeklyReviewReviewSections(
            retentionSnapshot: retentionSnapshot,
            isMarkedReviewed: reviewCompleted
        )
    let actionPlans = atlasWeeklyReviewVisibleActionPlans(
        seed: seed,
        plans: settingsSnapshot.weeklyReviewActionPlans
    )
    let history = atlasWeeklyReviewHistoryItems(
        currentSeed: seed,
        historicalSeeds: insightsSnapshot.weeklyReviewHistory
    )

    return AtlasWeeklyReviewPresentation(
        seed: seed,
        periodTitle: seed.periodTitle,
        generatedAt: seed.generatedAt,
        summaryText: summaryText,
        trustLabel: trustLabel,
        disclaimer: disclaimer,
        highlights: atlasWeeklyReviewHighlights(
            seed: seed,
            rewardsSnapshot: rewardsSnapshot,
            settingsSnapshot: settingsSnapshot,
            windowStart: seed.windowStart
        ),
        shifts: atlasWeeklyReviewShifts(
            insightsSnapshot: insightsSnapshot,
            seed: seed
        ),
        actions: atlasWeeklyReviewActions(
            seed: seed,
            rewardsSnapshot: rewardsSnapshot,
            retentionSnapshot: retentionSnapshot,
            settingsSnapshot: settingsSnapshot,
            reviewCompleted: reviewCompleted
        ),
        history: history,
        comparison: history.first.map {
            atlasWeeklyReviewComparisonSnapshot(currentSeed: seed, historical: $0.seed)
        },
        actionOutcomes: atlasWeeklyReviewActionOutcomeSummary(
            currentSeed: seed,
            plans: settingsSnapshot.weeklyReviewActionPlans
        ),
        protocolFollowUp: seed.protocolFollowUpSummary,
        actionPlans: actionPlans,
        sourceSections: sourceSections,
        isMarkedReviewed: reviewCompleted,
        summarySettingEnabled: seed.summarySettingEnabled,
        reminderEnabled: settingsSnapshot.weeklyReviewReminderSettings.enabled
    )
}

private struct AtlasWeeklyReviewTrustPanel: View {
    let trustLabel: String
    let disclaimer: String

    var body: some View {
        AtlasCalloutRow(
            systemImage: "lock.shield.fill",
            title: trustLabel,
            detail: disclaimer,
            tint: AtlasPalette.secondaryText
        )
    }
}

private struct AtlasWeeklyReviewHighlightRow: View {
    let item: AtlasWeeklyReviewHighlightItem

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.medium) {
            Image(systemName: item.symbolName)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(AtlasPalette.primary)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(item.detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
        }
    }
}

private struct AtlasWeeklyReviewShiftRow: View {
    let item: AtlasWeeklyReviewShiftItem
    let action: () -> Void

    var body: some View {
        Button {
            AtlasFeedback.selection()
            action()
        } label: {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack(alignment: .top, spacing: AtlasSpacing.small) {
                    Image(systemName: item.symbolName)
                        .foregroundStyle(AtlasPalette.primary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(item.summary)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                if item.facts.isEmpty == false {
                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                        ForEach(item.facts.prefix(2)) { fact in
                            Text("\(fact.label): \(fact.value)")
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                    .padding(.leading, 28)
                }
            }
            .padding(.vertical, AtlasSpacing.xSmall)
        }
        .buttonStyle(.plain)
    }
}

private struct AtlasWeeklyReviewActionRow: View {
    let item: AtlasWeeklyReviewActionItem
    let isSaved: Bool
    let action: () -> Void
    let saveAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            HStack(alignment: .top, spacing: AtlasSpacing.small) {
                Image(systemName: item.symbolName)
                    .foregroundStyle(AtlasPalette.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(item.detail)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }

            HStack(spacing: AtlasSpacing.small) {
                Button(item.title) {
                    AtlasFeedback.selection()
                    action()
                }
                    .buttonStyle(AtlasSecondaryButtonStyle())

                if let saveAction, isSaved == false {
                    Button("Save") {
                        AtlasFeedback.selection()
                        saveAction()
                    }
                    .buttonStyle(AtlasTertiaryButtonStyle())
                } else if isSaved {
                    AtlasStatusBadge("Saved", tint: AtlasPalette.success)
                }
            }
        }
        .padding(.vertical, AtlasSpacing.xSmall)
    }
}

private struct AtlasWeeklyReviewHistoryRow: View {
    let item: AtlasWeeklyReviewHistoryItem
    let action: () -> Void

    var body: some View {
        Button {
            AtlasFeedback.selection()
            action()
        } label: {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack(alignment: .top, spacing: AtlasSpacing.small) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.periodTitle)
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(item.comparisonLabel)
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.primary)
                    }
                    Spacer()
                    Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                Text(item.summary)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(3)
            }
            .padding(.vertical, AtlasSpacing.xSmall)
        }
        .buttonStyle(.plain)
    }
}

private struct AtlasWeeklyReviewComparisonCard: View {
    let snapshot: AtlasWeeklyReviewComparisonSnapshot
    let action: () -> Void

    var body: some View {
        Button {
            AtlasFeedback.selection()
            action()
        } label: {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack(alignment: .top, spacing: AtlasSpacing.small) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Compared with \(snapshot.historicalPeriodTitle)")
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.primary)
                        Text(snapshot.headline)
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                    }
                    Spacer()
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .foregroundStyle(AtlasPalette.primary)
                }

                Text(snapshot.summary)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    ForEach(snapshot.metrics.prefix(3)) { metric in
                        Text("\(metric.label): \(metric.deltaLabel)")
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                }
            }
            .padding(AtlasSpacing.small)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.62))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AtlasWeeklyReviewActionOutcomeRow: View {
    let item: AtlasWeeklyReviewActionOutcomeItem

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            HStack(alignment: .top, spacing: AtlasSpacing.small) {
                Image(systemName: item.symbolName)
                    .foregroundStyle(AtlasPalette.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(item.detail)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer()
                AtlasStatusBadge(item.statusLabel, tint: atlasWeeklyReviewOutcomeTint(item.statusLabel))
            }

            Text(item.statusDetail)
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
                .padding(.leading, 28)
        }
        .padding(.vertical, AtlasSpacing.xSmall)
    }
}

private struct AtlasWeeklyReviewProtocolFollowUpView: View {
    let summary: AtlasWeeklyReviewProtocolFollowUpSummary
    let openAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            HStack(alignment: .top, spacing: AtlasSpacing.small) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(AtlasPalette.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.title ?? "Atlas protocol")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(summary.summary ?? "\(summary.changeTypeTitle) is still within the follow-up window.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                Text("Changed \(summary.changedAt.formatted(date: .abbreviated, time: .omitted)) • \(summary.windowDays)-day follow-up")
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.primary)
                Text("Completed logs: \(summary.completedCount) • Skipped: \(summary.skippedCount) • Rescheduled: \(summary.rescheduledCount) • Context: \(summary.contextEntryCount)")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text(summary.hasVisibleSupportingData
                    ? "Visible follow-through is attached to this change."
                    : "There is not much follow-through around this change yet.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            Button("Open change follow-up") {
                AtlasFeedback.selection()
                openAction()
            }
                .buttonStyle(AtlasSecondaryButtonStyle())
        }
    }
}

private struct AtlasWeeklyReviewSavedActionRow: View {
    let item: AtlasWeeklyReviewActionPlan
    let openAction: () -> Void
    let toggleCompleteAction: () -> Void
    let togglePinnedAction: () -> Void
    let removeAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            HStack(alignment: .top, spacing: AtlasSpacing.small) {
                Image(systemName: item.symbolName)
                    .foregroundStyle(item.isCompleted ? AtlasPalette.success : AtlasPalette.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(item.detail)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer()
                AtlasStatusBadge(
                    item.isCompleted ? "Done" : (item.isPinnedForNextWeek ? "Pinned" : "Active"),
                    tint: item.isCompleted ? AtlasPalette.success : AtlasPalette.secondaryText
                )
            }

            HStack(spacing: AtlasSpacing.small) {
                Button("Open") {
                    AtlasFeedback.selection()
                    openAction()
                }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                Button(item.isCompleted ? "Mark active" : "Mark done") {
                    AtlasFeedback.selection()
                    toggleCompleteAction()
                }
                    .buttonStyle(AtlasTertiaryButtonStyle())
                Button(item.isPinnedForNextWeek ? "Unpin" : "Pin") {
                    AtlasFeedback.selection()
                    togglePinnedAction()
                }
                    .buttonStyle(AtlasTertiaryButtonStyle())
                Button("Remove") {
                    AtlasFeedback.selection()
                    removeAction()
                }
                    .buttonStyle(AtlasTertiaryButtonStyle())
            }
        }
        .padding(.vertical, AtlasSpacing.xSmall)
    }
}

private struct AtlasWeeklyReviewDetailSheetView: View {
    let item: AtlasWeeklyReviewDetailSheet
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AtlasScreen {
                switch item {
                case .shift(let shift):
                    AtlasSectionCard(style: .hero) {
                        VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                            Label(shift.title, systemImage: shift.symbolName)
                                .atlasTextRole(.cardTitle)
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text(shift.summary)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }

                    AtlasSectionCard(title: "Source facts") {
                        ForEach(shift.facts) { fact in
                            HStack(alignment: .top, spacing: AtlasSpacing.small) {
                                Text(fact.label)
                                    .atlasTextRole(.deckEyebrow)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                Spacer()
                                Text(fact.value)
                                    .atlasTextRole(.supporting)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(AtlasPalette.textPrimary)
                            }
                        }
                    }
                case .history(let history):
                    AtlasSectionCard(style: .hero) {
                        VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                            Text(history.periodTitle)
                                .atlasTextRole(.cardTitle)
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text(history.comparisonLabel)
                                .atlasTextRole(.deckEyebrow)
                                .foregroundStyle(AtlasPalette.primary)
                            Text(history.summary)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }

                    AtlasSectionCard(title: "Source facts") {
                        ForEach(Array(history.seed.sourceSections.enumerated()), id: \.element.id) { index, section in
                            if index > 0 {
                                Divider()
                            }
                            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                                Text(section.title)
                                    .atlasTextRole(.deckEyebrow)
                                    .foregroundStyle(AtlasPalette.primary)

                                ForEach(section.facts) { fact in
                                    HStack(alignment: .top, spacing: AtlasSpacing.small) {
                                        Text(fact.label)
                                            .atlasTextRole(.deckEyebrow)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                        Spacer()
                                        Text(fact.value)
                                            .atlasTextRole(.supporting)
                                            .multilineTextAlignment(.trailing)
                                            .foregroundStyle(AtlasPalette.textPrimary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Weekly detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        AtlasFeedback.selection()
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct AtlasWeeklyReviewArchiveScreen: View {
    let snapshot: AtlasWeeklyReviewPresentation
    @Environment(\.dismiss) private var dismiss
    @State private var selectedHistoryID: String

    init(snapshot: AtlasWeeklyReviewPresentation) {
        self.snapshot = snapshot
        _selectedHistoryID = State(initialValue: snapshot.history.first?.id ?? "")
    }

    private var selectedHistory: AtlasWeeklyReviewHistoryItem? {
        snapshot.history.first(where: { $0.id == selectedHistoryID }) ?? snapshot.history.first
    }

    var body: some View {
        NavigationStack {
            AtlasScreen {
                if let selectedHistory {
                    let comparison = atlasWeeklyReviewComparisonSnapshot(
                        currentSeed: snapshot.seed,
                        historical: selectedHistory.seed
                    )

                    AtlasSectionCard(style: .hero) {
                        VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                            Text("Archive & Compare")
                                .atlasTextRole(.screenTitle)
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text("Comparing \(snapshot.periodTitle) with \(selectedHistory.periodTitle)")
                                .atlasTextRole(.deckEyebrow)
                                .foregroundStyle(AtlasPalette.primary)
                            Text(comparison.headline)
                                .atlasTextRole(.cardTitle)
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text(comparison.summary)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }

                    AtlasSectionCard(style: .elevated, title: "Comparison") {
                        ForEach(Array(comparison.metrics.enumerated()), id: \.element.id) { index, metric in
                            if index > 0 {
                                Divider()
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(metric.label)
                                        .atlasTextRole(.cardBody)
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                    Spacer()
                                    Text(metric.deltaLabel)
                                        .atlasTextRole(.deckEyebrow)
                                        .foregroundStyle(AtlasPalette.primary)
                                }
                                Text("This week: \(metric.currentValue) • Archive week: \(metric.historicalValue)")
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                            .padding(.vertical, AtlasSpacing.xSmall)
                        }
                    }

                    AtlasSectionCard(style: .utility, title: "Archive weeks") {
                        ForEach(snapshot.history) { item in
                            Button {
                                AtlasFeedback.selection()
                                selectedHistoryID = item.id
                            } label: {
                                HStack(alignment: .top, spacing: AtlasSpacing.small) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.periodTitle)
                                            .atlasTextRole(.cardBody)
                                            .foregroundStyle(AtlasPalette.textPrimary)
                                        Text(item.comparisonLabel)
                                            .atlasTextRole(.supporting)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }
                                    Spacer()
                                    AtlasStatusBadge(
                                        selectedHistoryID == item.id ? "Selected" : "Archive",
                                        tint: selectedHistoryID == item.id ? AtlasPalette.primary : AtlasPalette.secondaryText
                                    )
                                }
                                .padding(.vertical, AtlasSpacing.xSmall)
                            }
                            .buttonStyle(.plain)

                            if item.id != snapshot.history.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        AtlasFeedback.selection()
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct AtlasFileShareSheet: UIViewControllerRepresentable {
    let fileURL: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private func atlasWeeklyReviewHighlights(
    seed: AtlasWeeklyReviewSeed,
    rewardsSnapshot: AtlasRewardsSnapshot,
    settingsSnapshot: AtlasSettingsSnapshot,
    windowStart: Date
) -> [AtlasWeeklyReviewHighlightItem] {
    var items: [AtlasWeeklyReviewHighlightItem] = [
        atlasWeeklyReviewAdherenceHighlight(seed: seed),
        atlasWeeklyReviewContextHighlight(seed: seed)
    ]

    if let protocolChangeHighlight = atlasWeeklyReviewProtocolChangeHighlight(seed: seed) {
        items.append(protocolChangeHighlight)
    }

    if rewardsSnapshot.settings.enabled {
        items.append(atlasWeeklyReviewRewardsHighlight(rewardsSnapshot: rewardsSnapshot))

        if let mascotHighlight = atlasWeeklyReviewMascotHighlight(
            rewardsSnapshot: rewardsSnapshot,
            settingsSnapshot: settingsSnapshot,
            windowStart: windowStart
        ) {
            items.append(mascotHighlight)
        }
    }

    return items
}

private func atlasWeeklyReviewAdherenceHighlight(
    seed: AtlasWeeklyReviewSeed
) -> AtlasWeeklyReviewHighlightItem {
    let counted = seed.completedCount + seed.skippedCount + seed.overdueCount
    let completionRate = counted > 0 ? Int(round((Double(seed.completedCount) / Double(counted)) * 100)) : nil
    let title = completionRate.map { "\($0)% of visible schedule stayed on track" }
        ?? "\(seed.completedCount) completed logs recorded"

    let detail: String
    if seed.skippedCount + seed.rescheduledCount + seed.overdueCount == 0 {
        detail = "No skipped, rescheduled, or still-open items showed up in the visible week."
    } else {
        var fragments: [String] = []
        if seed.skippedCount > 0 {
            fragments.append("\(seed.skippedCount) skipped")
        }
        if seed.rescheduledCount > 0 {
            fragments.append("\(seed.rescheduledCount) rescheduled")
        }
        if seed.overdueCount > 0 {
            fragments.append("\(seed.overdueCount) still open")
        }
        detail = "Schedule movement included \(fragments.joined(separator: ", "))."
    }

    return AtlasWeeklyReviewHighlightItem(
        id: "adherence",
        title: title,
        detail: detail,
        symbolName: "checkmark.circle.fill"
    )
}

private func atlasWeeklyReviewContextHighlight(
    seed: AtlasWeeklyReviewSeed
) -> AtlasWeeklyReviewHighlightItem {
    let detailParts = [
        seed.contextEntryCount > 0 ? "\(seed.contextEntryCount) context" : nil,
        seed.symptomEntryCount > 0 ? "\(seed.symptomEntryCount) symptom" : nil,
        seed.weightEntryCount > 0 ? "\(seed.weightEntryCount) weight" : nil,
        seed.workoutEntryCount > 0 ? "\(seed.workoutEntryCount) workout" : nil
    ].compactMap { $0 }

    return AtlasWeeklyReviewHighlightItem(
        id: "context",
        title: detailParts.isEmpty ? "Supporting context stayed light" : "Supporting records stayed in the loop",
        detail: detailParts.isEmpty
            ? "There was little surrounding context to compare against the schedule this week."
            : "This week included \(detailParts.joined(separator: ", ")) entries.",
        symbolName: "waveform.path.ecg"
    )
}

private func atlasWeeklyReviewProtocolChangeHighlight(
    seed: AtlasWeeklyReviewSeed
) -> AtlasWeeklyReviewHighlightItem? {
    guard let summary = seed.protocolChangeSummary else {
        return nil
    }

    let title = "\(summary.changeCount) protocol change\(summary.changeCount == 1 ? "" : "s") landed this week"
    let detail = [
        summary.latestTitle.map { "Latest: \($0)" },
        summary.latestSummary
    ]
    .compactMap { $0 }
    .joined(separator: " • ")

    return AtlasWeeklyReviewHighlightItem(
        id: "protocol-change",
        title: title,
        detail: detail.isEmpty ? "Change audit only." : detail,
        symbolName: "slider.horizontal.3"
    )
}

private func atlasWeeklyReviewRewardsHighlight(
    rewardsSnapshot: AtlasRewardsSnapshot
) -> AtlasWeeklyReviewHighlightItem {
    let goalsMet = rewardsSnapshot.goals.filter(\.isMet).count
    let activeStreak = rewardsSnapshot.streaks.filter(\.isActive).map(\.count).max() ?? 0
    let badgeCount = rewardsSnapshot.badges.filter(\.isEarned).count
    let detailParts = [
        "Level \(rewardsSnapshot.level)",
        goalsMet > 0 ? "\(goalsMet) goals closed" : nil,
        activeStreak > 0 ? "\(activeStreak)-step streak active" : nil,
        badgeCount > 0 ? "\(badgeCount) badges earned" : nil
    ].compactMap { $0 }

    return AtlasWeeklyReviewHighlightItem(
        id: "rewards",
        title: "\(rewardsSnapshot.totalPoints) rewards points are in motion",
        detail: detailParts.joined(separator: " • "),
        symbolName: "sparkles"
    )
}

private func atlasWeeklyReviewMascotHighlight(
    rewardsSnapshot: AtlasRewardsSnapshot,
    settingsSnapshot: AtlasSettingsSnapshot,
    windowStart: Date
) -> AtlasWeeklyReviewHighlightItem? {
    let stage = AtlasMascotMilestone.stage(for: rewardsSnapshot.totalPoints)
    let latestMoment = settingsSnapshot.mascotMoments.first {
        atlasWeeklyReviewDate(from: $0.recordedAt) >= windowStart
    }

    if let latestMoment {
        return AtlasWeeklyReviewHighlightItem(
            id: "mascot-moment",
            title: latestMoment.title,
            detail: latestMoment.detail,
            symbolName: latestMoment.symbolName
        )
    }

    let displayName = atlasMascotDisplayName(
        selection: settingsSnapshot.mascotSelection,
        stage: stage,
        nickname: settingsSnapshot.mascotNickname
    )
    return AtlasWeeklyReviewHighlightItem(
        id: "mascot-status",
        title: "\(displayName) is in \(settingsSnapshot.mascotSelection.title(for: stage))",
        detail: atlasMascotStatusLine(
            selection: settingsSnapshot.mascotSelection,
            nickname: settingsSnapshot.mascotNickname,
            rewardsSnapshot: rewardsSnapshot
        ),
        symbolName: settingsSnapshot.mascotSelection == .aetherion ? "bolt.fill" : "moon.stars.fill"
    )
}

private func atlasWeeklyReviewShifts(
    insightsSnapshot: AtlasInsightsSnapshot,
    seed: AtlasWeeklyReviewSeed
) -> [AtlasWeeklyReviewShiftItem] {
    var items: [AtlasWeeklyReviewShiftItem] = []

    if let protocolChangeSummary = seed.protocolChangeSummary {
        items.append(
            AtlasWeeklyReviewShiftItem(
                id: "protocol-change-shift",
                title: "Protocol planning shifted",
                summary: protocolChangeSummary.latestSummary
                    ?? "\(protocolChangeSummary.changeCount) plan edit\(protocolChangeSummary.changeCount == 1 ? "" : "s") in this review window.",
                facts: [
                    AtlasExplainerFact(label: "Changes", value: String(protocolChangeSummary.changeCount)),
                    AtlasExplainerFact(label: "Latest protocol", value: protocolChangeSummary.latestTitle ?? "Atlas protocol"),
                    AtlasExplainerFact(label: "Supporting logs", value: String(protocolChangeSummary.supportingLogCount)),
                    AtlasExplainerFact(label: "Supporting context", value: String(protocolChangeSummary.supportingContextCount))
                ],
                symbolName: "slider.horizontal.3"
            )
        )
    }

    items.append(contentsOf: insightsSnapshot.deterministicExplanations.prefix(2).map {
        AtlasWeeklyReviewShiftItem(
            id: $0.id,
            title: $0.title,
            summary: $0.summary,
            facts: $0.facts,
            symbolName: atlasWeeklyReviewShiftSymbol(for: $0.kind)
        )
    })

    if let previousWeek = insightsSnapshot.weeklyReviewHistory.first {
        items.append(
            AtlasWeeklyReviewShiftItem(
                id: "week-over-week",
                title: "Compared with the prior week",
                summary: atlasWeeklyReviewComparisonLabel(current: seed, historical: previousWeek),
                facts: [
                    AtlasExplainerFact(label: "This week completed", value: String(seed.completedCount)),
                    AtlasExplainerFact(label: "Previous week completed", value: String(previousWeek.completedCount)),
                    AtlasExplainerFact(label: "This week context", value: String(seed.contextEntryCount)),
                    AtlasExplainerFact(label: "Previous week context", value: String(previousWeek.contextEntryCount))
                ],
                symbolName: "arrow.left.arrow.right.circle.fill"
            )
        )
    }

    if items.isEmpty, let changeLabel = insightsSnapshot.weightTrend.changeLabel {
        items.append(
            AtlasWeeklyReviewShiftItem(
                id: "weight-trend",
                title: "Weight trend moved enough to notice",
                summary: changeLabel,
                facts: [
                    AtlasExplainerFact(label: "Latest", value: insightsSnapshot.weightTrend.latestLabel ?? "No latest weight available")
                ],
                symbolName: "scalemass.fill"
            )
        )
    }

    if items.count < 2, let symptom = insightsSnapshot.symptomTrend.first {
        items.append(
            AtlasWeeklyReviewShiftItem(
                id: "symptom-\(symptom.symptomKey)",
                title: "\(symptom.symptomKey) stayed visible",
                summary: "\(symptom.entryCount) entries were logged, with \(symptom.latestLabel.lowercased()).",
                facts: [
                    AtlasExplainerFact(label: "Average severity", value: symptom.averageSeverityLabel),
                    AtlasExplainerFact(label: "Latest", value: symptom.latestLabel)
                ],
                symbolName: "waveform.path.ecg"
            )
        )
    }

    if items.isEmpty {
        items.append(
            AtlasWeeklyReviewShiftItem(
                id: "context-coverage",
                title: "Weekly context coverage",
                summary: seed.contextEntryCount > 0
                    ? "\(seed.contextEntryCount) context entries were logged during the review window."
                    : "There was not much surrounding context this week.",
                facts: [
                    AtlasExplainerFact(label: "Context entries", value: String(seed.contextEntryCount)),
                    AtlasExplainerFact(label: "Symptom entries", value: String(seed.symptomEntryCount))
                ],
                symbolName: "leaf.circle.fill"
            )
        )
    }

    return Array(items.uniqued(on: \.id).prefix(4))
}

private func atlasWeeklyReviewShiftSymbol(
    for kind: AtlasDeterministicInsightKind
) -> String {
    switch kind {
    case .symptomContext:
        return "fork.knife.circle.fill"
    case .symptomWorkout:
        return "figure.run.circle.fill"
    case .symptomWeight:
        return "scalemass.fill"
    case .symptomMetric:
        return "chart.xyaxis.line"
    }
}

private func atlasWeeklyReviewActions(
    seed: AtlasWeeklyReviewSeed,
    rewardsSnapshot: AtlasRewardsSnapshot,
    retentionSnapshot: AtlasRetentionSnapshot,
    settingsSnapshot: AtlasSettingsSnapshot,
    reviewCompleted: Bool
) -> [AtlasWeeklyReviewActionItem] {
    var actions: [AtlasWeeklyReviewActionItem] = []

    if seed.overdueCount > 0 {
        actions.append(
            AtlasWeeklyReviewActionItem(
                id: "open-today",
                title: "Clear the open Today queue",
                detail: "\(seed.overdueCount) due or overdue item\(seed.overdueCount == 1 ? "" : "s") still need attention.",
                symbolName: "clock.badge.checkmark",
                destination: .today
            )
        )
    } else if seed.skippedCount > 0 || seed.rescheduledCount > 0 {
        let detail = "\(seed.skippedCount) skipped and \(seed.rescheduledCount) rescheduled events showed up this week."
        if let protocolID = seed.nextDueProtocolID {
            actions.append(
                AtlasWeeklyReviewActionItem(
                    id: "change-plan-\(protocolID)",
                    title: "Review the dose pattern",
                    detail: detail,
                    symbolName: "slider.horizontal.3",
                    destination: .protocolChange(protocolID)
                )
            )
        } else {
            actions.append(
                AtlasWeeklyReviewActionItem(
                    id: "review-today-pattern",
                    title: "Review the dose pattern",
                    detail: detail,
                    symbolName: "slider.horizontal.3",
                    destination: .today
                )
            )
        }
    }

    if seed.contextEntryCount < 2 && seed.symptomEntryCount == 0 {
        actions.append(
            AtlasWeeklyReviewActionItem(
                id: "capture-context",
                title: "Capture more context next week",
                detail: "More context next week will make the review clearer.",
                symbolName: "plus.circle.fill",
                destination: .insights
            )
        )
    }

    if let protocolChangeSummary = seed.protocolChangeSummary,
       let protocolID = protocolChangeSummary.latestProtocolID {
        actions.append(
            AtlasWeeklyReviewActionItem(
                id: "review-protocol-change-\(protocolID)",
                title: "Review the latest plan change",
                detail: protocolChangeSummary.supportingLogCount == 0 && protocolChangeSummary.supportingContextCount == 0
                    ? "The plan changed, but there is not much follow-through around it yet."
                    : "Check the updated plan against the week’s supporting records before the next cycle starts.",
                symbolName: "slider.horizontal.3",
                destination: .protocolChange(protocolID)
            )
        )
    }

    if rewardsSnapshot.settings.enabled, let unmetGoal = rewardsSnapshot.goals.first(where: { $0.isMet == false }) {
        actions.append(
            AtlasWeeklyReviewActionItem(
                id: "rewards-goal-\(unmetGoal.kind.rawValue)",
                title: "Close one weekly rewards target",
                detail: unmetGoal.progressLabel,
                symbolName: unmetGoal.symbolName,
                destination: .insights
            )
        )
    }

    if seed.summarySettingEnabled == false {
        actions.append(
            AtlasWeeklyReviewActionItem(
                id: "enable-summary",
                title: "Enable on-device weekly reads",
                detail: "Turn on on-device summaries in Settings.",
                symbolName: "text.badge.checkmark",
                destination: .settings
            )
        )
    }

    if retentionSnapshot.settings.progressEnabled && reviewCompleted == false {
        actions.append(
            AtlasWeeklyReviewActionItem(
                id: "mark-reviewed",
                title: "Mark this week reviewed",
                detail: "Use this after you finish reviewing the week.",
                symbolName: "calendar.badge.checkmark",
                destination: .markReviewComplete
            )
        )
    }

    if actions.count < 2, let protocolID = seed.nextDueProtocolID {
        actions.append(
            AtlasWeeklyReviewActionItem(
                id: "open-next-due-\(protocolID)",
                title: "Open the next scheduled plan",
                detail: seed.nextDueTitle.map { "\($0) is still the clearest anchor for the next step." }
                    ?? "Open the next visible protocol detail.",
                symbolName: "arrow.right.circle.fill",
                destination: .protocolDetail(protocolID)
            )
        )
    }

    if actions.isEmpty {
        actions.append(
            AtlasWeeklyReviewActionItem(
                id: "open-insights",
                title: "Open Insights",
                detail: "Use Insights to add more supporting context.",
                symbolName: "chart.line.uptrend.xyaxis",
                destination: .insights
            )
        )
    }

    return Array(actions.uniqued(on: \.id).prefix(4))
}

private func atlasWeeklyReviewRewardsSections(
    rewardsSnapshot: AtlasRewardsSnapshot,
    settingsSnapshot: AtlasSettingsSnapshot
) -> [AtlasSummarySourceSection] {
    guard rewardsSnapshot.settings.enabled else {
        return []
    }

    let activeStreak = rewardsSnapshot.streaks.filter(\.isActive).map(\.count).max() ?? 0
    return [
        atlasWeeklyReviewSection(
            "weekly_rewards",
            "Rewards momentum",
            [
                atlasWeeklyReviewFact("rewards_points", "Rewards points", String(rewardsSnapshot.totalPoints)),
                atlasWeeklyReviewFact("rewards_level", "Current level", String(rewardsSnapshot.level)),
                atlasWeeklyReviewFact("goals_met", "Goals met", String(rewardsSnapshot.goals.filter(\.isMet).count)),
                atlasWeeklyReviewFact("active_streak", "Active streak", activeStreak > 0 ? "\(activeStreak)" : "None")
            ]
        )
    ]
}

private func atlasWeeklyReviewMascotSections(
    rewardsSnapshot: AtlasRewardsSnapshot,
    settingsSnapshot: AtlasSettingsSnapshot,
    windowStart: Date
) -> [AtlasSummarySourceSection] {
    guard rewardsSnapshot.settings.enabled else {
        return []
    }

    let stage = AtlasMascotMilestone.stage(for: rewardsSnapshot.totalPoints)
    let latestMoment = settingsSnapshot.mascotMoments.first {
        atlasWeeklyReviewDate(from: $0.recordedAt) >= windowStart
    } ?? settingsSnapshot.mascotMoments.first

    return [
        atlasWeeklyReviewSection(
            "weekly_mascot",
            "Mascot",
            [
                atlasWeeklyReviewFact("mascot_form", "Current form", settingsSnapshot.mascotSelection.title(for: stage))
            ] + (latestMoment.map {
                [
                    atlasWeeklyReviewFact("mascot_moment", "Latest moment", $0.title),
                    atlasWeeklyReviewFact("mascot_moment_detail", "Moment detail", $0.detail)
                ]
            } ?? [])
        )
    ]
}

private func atlasWeeklyReviewReviewSections(
    retentionSnapshot: AtlasRetentionSnapshot,
    isMarkedReviewed: Bool
) -> [AtlasSummarySourceSection] {
    guard retentionSnapshot.settings.progressEnabled else {
        return []
    }

    return [
        atlasWeeklyReviewSection(
            "weekly_review_status",
            "Review status",
            [
                atlasWeeklyReviewFact("review_status", "This week", isMarkedReviewed ? "Marked reviewed" : "Not marked reviewed yet")
            ]
        )
    ]
}

private func atlasWeeklyReviewFact(
    _ id: String,
    _ label: String,
    _ value: String
) -> AtlasSummaryFact {
    AtlasSummaryFact(id: id, label: label, value: value)
}

private func atlasWeeklyReviewSection(
    _ id: String,
    _ title: String,
    _ facts: [AtlasSummaryFact]
) -> AtlasSummarySourceSection {
    AtlasSummarySourceSection(id: id, title: title, facts: facts)
}

private func atlasWeeklyReviewDate(from timestamp: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: timestamp) ?? .distantPast
}

private func atlasWeeklyReviewVisibleActionPlans(
    seed: AtlasWeeklyReviewSeed,
    plans: [AtlasWeeklyReviewActionPlan]
) -> [AtlasWeeklyReviewActionPlan] {
    let currentWindowStart = ISO8601DateFormatter.atlas.string(from: seed.windowStart)

    return plans
        .filter { plan in
            plan.reviewPeriodStart == currentWindowStart
                || plan.isPinnedForNextWeek
                || plan.isCompleted == false
        }
        .sorted { lhs, rhs in
            switch (lhs.isCompleted, rhs.isCompleted) {
            case (false, true):
                return true
            case (true, false):
                return false
            default:
                return lhs.createdAt > rhs.createdAt
            }
        }
}

private func atlasWeeklyReviewHistoryItems(
    currentSeed: AtlasWeeklyReviewSeed,
    historicalSeeds: [AtlasWeeklyReviewSeed]
) -> [AtlasWeeklyReviewHistoryItem] {
    historicalSeeds.map { seed in
        AtlasWeeklyReviewHistoryItem(
            id: ISO8601DateFormatter.atlas.string(from: seed.windowEnd),
            periodTitle: seed.periodTitle,
            summary: seed.plainLanguageSummary?.summary ?? seed.fallbackSummary,
            comparisonLabel: atlasWeeklyReviewComparisonLabel(current: currentSeed, historical: seed),
            seed: seed
        )
    }
}

private func atlasWeeklyReviewActionOutcomeSummary(
    currentSeed: AtlasWeeklyReviewSeed,
    plans: [AtlasWeeklyReviewActionPlan]
) -> AtlasWeeklyReviewActionOutcomeSummary? {
    let currentWindowStart = ISO8601DateFormatter.atlas.string(from: currentSeed.windowStart)
    guard let previousWindowStart = plans
        .map(\.reviewPeriodStart)
        .filter({ $0 < currentWindowStart })
        .max() else {
        return nil
    }

    let previousPlans = plans
        .filter { $0.reviewPeriodStart == previousWindowStart }
        .sorted { $0.createdAt > $1.createdAt }
    guard previousPlans.isEmpty == false else {
        return nil
    }

    let completedCount = previousPlans.filter(\.isCompleted).count
    let carriedCount = previousPlans.filter { $0.isCompleted == false && $0.isPinnedForNextWeek }.count
    let openCount = previousPlans.filter { $0.isCompleted == false && $0.isPinnedForNextWeek == false }.count
    let periodTitle = atlasWeeklyReviewPeriodTitle(
        start: previousPlans.first?.reviewPeriodStart,
        end: previousPlans.first?.reviewPeriodEnd
    )
    let summary = [
        completedCount > 0 ? "\(completedCount) completed" : nil,
        carriedCount > 0 ? "\(carriedCount) carried forward" : nil,
        openCount > 0 ? "\(openCount) left open" : nil
    ]
    .compactMap { $0 }
    .joined(separator: " • ")

    return AtlasWeeklyReviewActionOutcomeSummary(
        previousPeriodTitle: periodTitle,
        summary: summary.isEmpty
            ? "Your prior weekly focus stayed visible, but there were no marked outcomes yet."
            : "From \(periodTitle): \(summary).",
        items: previousPlans.prefix(4).map { plan in
            let statusLabel: String
            let statusDetail: String
            if plan.isCompleted {
                statusLabel = "Completed"
                statusDetail = "This saved focus was marked done after the review."
            } else if plan.isPinnedForNextWeek {
                statusLabel = "Carried"
                statusDetail = "This focus stayed visible into the new week."
            } else {
                statusLabel = "Open"
                statusDetail = "This focus was left open and is no longer pinned into the current week."
            }

            return AtlasWeeklyReviewActionOutcomeItem(
                id: plan.id,
                title: plan.title,
                detail: plan.detail,
                statusLabel: statusLabel,
                statusDetail: statusDetail,
                symbolName: plan.symbolName
            )
        }
    )
}

private func atlasWeeklyReviewComparisonSnapshot(
    currentSeed: AtlasWeeklyReviewSeed,
    historical: AtlasWeeklyReviewSeed
) -> AtlasWeeklyReviewComparisonSnapshot {
    let currentScheduleMovement = currentSeed.skippedCount + currentSeed.rescheduledCount + currentSeed.overdueCount
    let historicalScheduleMovement = historical.skippedCount + historical.rescheduledCount + historical.overdueCount
    let currentProtocolChanges = currentSeed.protocolChangeSummary?.changeCount ?? 0
    let historicalProtocolChanges = historical.protocolChangeSummary?.changeCount ?? 0

    return AtlasWeeklyReviewComparisonSnapshot(
        id: ISO8601DateFormatter.atlas.string(from: historical.windowEnd),
        historicalPeriodTitle: historical.periodTitle,
        headline: atlasWeeklyReviewComparisonLabel(current: currentSeed, historical: historical),
        summary: historical.plainLanguageSummary?.summary ?? historical.fallbackSummary,
        metrics: [
            AtlasWeeklyReviewComparisonMetric(
                id: "completed",
                label: "Completed logs",
                currentValue: String(currentSeed.completedCount),
                historicalValue: String(historical.completedCount),
                deltaLabel: atlasWeeklyReviewDeltaLabel(current: currentSeed.completedCount, historical: historical.completedCount)
            ),
            AtlasWeeklyReviewComparisonMetric(
                id: "schedule_movement",
                label: "Schedule movement",
                currentValue: String(currentScheduleMovement),
                historicalValue: String(historicalScheduleMovement),
                deltaLabel: atlasWeeklyReviewDeltaLabel(current: currentScheduleMovement, historical: historicalScheduleMovement)
            ),
            AtlasWeeklyReviewComparisonMetric(
                id: "context",
                label: "Context entries",
                currentValue: String(currentSeed.contextEntryCount),
                historicalValue: String(historical.contextEntryCount),
                deltaLabel: atlasWeeklyReviewDeltaLabel(current: currentSeed.contextEntryCount, historical: historical.contextEntryCount)
            ),
            AtlasWeeklyReviewComparisonMetric(
                id: "symptoms",
                label: "Symptom entries",
                currentValue: String(currentSeed.symptomEntryCount),
                historicalValue: String(historical.symptomEntryCount),
                deltaLabel: atlasWeeklyReviewDeltaLabel(current: currentSeed.symptomEntryCount, historical: historical.symptomEntryCount)
            ),
            AtlasWeeklyReviewComparisonMetric(
                id: "protocol_changes",
                label: "Protocol changes",
                currentValue: String(currentProtocolChanges),
                historicalValue: String(historicalProtocolChanges),
                deltaLabel: atlasWeeklyReviewDeltaLabel(current: currentProtocolChanges, historical: historicalProtocolChanges)
            )
        ]
    )
}

private func atlasWeeklyReviewComparisonLabel(
    current: AtlasWeeklyReviewSeed,
    historical: AtlasWeeklyReviewSeed
) -> String {
    let completedDelta = current.completedCount - historical.completedCount
    let contextDelta = current.contextEntryCount - historical.contextEntryCount

    var fragments: [String] = []
    if completedDelta != 0 {
        fragments.append(
            completedDelta > 0
                ? "\(completedDelta) more completed"
                : "\(abs(completedDelta)) fewer completed"
        )
    }
    if contextDelta != 0 {
        fragments.append(
            contextDelta > 0
                ? "\(contextDelta) more context entries"
                : "\(abs(contextDelta)) fewer context entries"
        )
    }

    if fragments.isEmpty {
        return "Very similar visible volume to this week."
    }

    return fragments.joined(separator: " • ")
}

private func atlasWeeklyReviewDeltaLabel(current: Int, historical: Int) -> String {
    let delta = current - historical
    if delta == 0 {
        return "No visible change"
    }
    return delta > 0 ? "+\(delta)" : "\(delta)"
}

private func atlasWeeklyReviewPeriodTitle(start: String?, end: String?) -> String {
    guard let start, let end else {
        return "Prior review"
    }
    return "\(atlasWeeklyReviewDate(from: start).formatted(date: .abbreviated, time: .omitted)) - \(atlasWeeklyReviewDate(from: end).formatted(date: .abbreviated, time: .omitted))"
}

private func atlasWeeklyReviewActionPlanID(
    for action: AtlasWeeklyReviewActionItem,
    seed: AtlasWeeklyReviewSeed
) -> String {
    "weekly-review-\(seed.windowStart.timeIntervalSince1970)-\(action.id)"
}

private func atlasWeeklyReviewRoute(
    for destination: AtlasWeeklyReviewActionDestination
) -> AtlasWeeklyReviewActionRoute? {
    switch destination {
    case .today:
        return .today
    case .insights:
        return .insights
    case .settings:
        return .settings
    case .protocolDetail(let id):
        return .protocolDetail(id)
    case .protocolChange(let id):
        return .protocolChange(id)
    case .markReviewComplete:
        return nil
    }
}

private func atlasWeeklyReviewOutcomeTint(_ statusLabel: String) -> Color {
    switch statusLabel {
    case "Completed":
        return AtlasPalette.success
    case "Carried":
        return AtlasPalette.primary
    default:
        return AtlasPalette.secondaryText
    }
}

private struct AtlasWeeklyReviewExportPayload: Codable {
    struct Section: Codable {
        var title: String
        var items: [String]
    }

    var title: String
    var generatedAt: String
    var summary: String
    var trustLabel: String
    var disclaimer: String
    var sections: [Section]
}

func atlasWeeklyReviewExportHTML(snapshot: AtlasWeeklyReviewPresentation) -> String {
    let dateLabel = snapshot.generatedAt.formatted(date: .abbreviated, time: .shortened)
    let highlights = snapshot.highlights.map { "<li><strong>\($0.title)</strong><span>\($0.detail)</span></li>" }.joined()
    let shifts = snapshot.shifts.map { "<li><strong>\($0.title)</strong><span>\($0.summary)</span></li>" }.joined()
    let actions = snapshot.actions.map { "<li><strong>\($0.title)</strong><span>\($0.detail)</span></li>" }.joined()
    let outcomes = snapshot.actionOutcomes?.items.map {
        "<li><strong>\($0.title)</strong><span>\($0.statusLabel) · \($0.statusDetail)</span></li>"
    }.joined() ?? ""
    let comparison = snapshot.comparison.map {
        """
        <section>
          <h2>Archive &amp; compare</h2>
          <p class="eyebrow">Compared with \($0.historicalPeriodTitle)</p>
          <p>\($0.headline)</p>
          <ul>\($0.metrics.map { "<li><strong>\($0.label)</strong><span>This week \($0.currentValue) · Archive week \($0.historicalValue) (\($0.deltaLabel))</span></li>" }.joined())</ul>
        </section>
        """
    } ?? ""
    let protocolFollowUp = snapshot.protocolFollowUp.map {
        """
        <section>
          <h2>Protocol follow-up</h2>
          <p class="eyebrow">\($0.title ?? "Atlas protocol")</p>
          <p>\($0.summary ?? "\($0.changeTypeTitle) is still inside Atlas's follow-up window.")</p>
          <ul>
            <li><strong>Changed</strong><span>\($0.changedAt.formatted(date: .abbreviated, time: .omitted))</span></li>
            <li><strong>Follow-up window</strong><span>\($0.windowDays) day(s)</span></li>
            <li><strong>Completed logs</strong><span>\($0.completedCount)</span></li>
            <li><strong>Context entries</strong><span>\($0.contextEntryCount)</span></li>
          </ul>
        </section>
        """
    } ?? ""
    let sourceFacts = snapshot.sourceSections.map { section in
        """
        <section>
          <h2>\(section.title)</h2>
          <ul>\(section.facts.map { "<li><strong>\($0.label)</strong><span>\($0.value)</span></li>" }.joined())</ul>
        </section>
        """
    }.joined()

    return """
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Atlas Weekly Review</title>
      <style>
        :root { color-scheme: light; --bg:#f4efe7; --surface:rgba(255,255,255,0.84); --text:#1f2423; --muted:#69716e; --accent:#6a7f78; --line:rgba(31,36,35,0.08); }
        * { box-sizing:border-box; }
        body { margin:0; font-family:-apple-system,BlinkMacSystemFont,\"SF Pro Text\",\"Helvetica Neue\",sans-serif; background:linear-gradient(180deg,#f8f4ec 0%,#efe7db 100%); color:var(--text); }
        main { max-width:860px; margin:0 auto; padding:40px 20px 72px; }
        section, header { background:var(--surface); border:1px solid var(--line); border-radius:24px; padding:24px; backdrop-filter:blur(18px); box-shadow:0 18px 40px rgba(44,51,49,0.08); margin-bottom:16px; }
        h1,h2,p,ul { margin:0; }
        h1 { font-size:34px; line-height:1.05; margin-bottom:10px; }
        h2 { font-size:15px; text-transform:uppercase; letter-spacing:0.08em; color:var(--accent); margin-bottom:14px; }
        .eyebrow { font-size:12px; font-weight:600; letter-spacing:0.08em; text-transform:uppercase; color:var(--accent); margin-bottom:8px; }
        .meta { color:var(--muted); font-size:13px; margin-bottom:14px; }
        .summary { font-size:22px; line-height:1.35; margin-bottom:18px; }
        .trust { padding:16px; border-radius:18px; background:rgba(255,255,255,0.72); border:1px solid rgba(31,36,35,0.06); }
        .trust strong { display:block; margin-bottom:6px; font-size:12px; letter-spacing:0.08em; text-transform:uppercase; color:var(--accent); }
        ul { list-style:none; padding:0; display:grid; gap:12px; }
        li { display:grid; grid-template-columns:minmax(0,1.2fr) minmax(0,1.8fr); gap:16px; padding-top:12px; border-top:1px solid var(--line); }
        li:first-child { border-top:0; padding-top:0; }
        li strong { font-size:14px; }
        li span { color:var(--muted); font-size:14px; line-height:1.45; }
      </style>
    </head>
    <body>
      <main>
        <header>
          <p class="eyebrow">Atlas Weekly Review</p>
          <h1>\(snapshot.periodTitle)</h1>
          <p class="meta">Generated \(dateLabel)</p>
          <p class="summary">\(snapshot.summaryText)</p>
          <div class="trust">
            <strong>\(snapshot.trustLabel)</strong>
            <p>\(snapshot.disclaimer)</p>
          </div>
        </header>
        <section><h2>Weekly highlights</h2><ul>\(highlights)</ul></section>
        <section><h2>What shifted</h2><ul>\(shifts)</ul></section>
        \(snapshot.actionOutcomes == nil ? "" : "<section><h2>Action follow-through</h2><p class=\"eyebrow\">\(snapshot.actionOutcomes?.previousPeriodTitle ?? "Prior review")</p><ul>\(outcomes)</ul></section>")
        \(protocolFollowUp)
        \(comparison)
        <section><h2>Next actions</h2><ul>\(actions)</ul></section>
        \(sourceFacts)
      </main>
    </body>
    </html>
    """
}

func atlasWriteWeeklyReviewExport(snapshot: AtlasWeeklyReviewPresentation) throws -> URL {
    let timestamp = ISO8601DateFormatter.atlas.string(from: snapshot.generatedAt)
        .replacingOccurrences(of: ":", with: "-")
    let baseURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("atlas-weekly-review-\(timestamp)", isDirectory: true)
    try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)

    let htmlURL = baseURL.appendingPathComponent("weekly-review.html")
    let jsonURL = baseURL.appendingPathComponent("weekly-review.json")
    try atlasWeeklyReviewExportHTML(snapshot: snapshot).write(to: htmlURL, atomically: true, encoding: .utf8)

    let payload = AtlasWeeklyReviewExportPayload(
        title: snapshot.periodTitle,
        generatedAt: ISO8601DateFormatter.atlas.string(from: snapshot.generatedAt),
        summary: snapshot.summaryText,
        trustLabel: snapshot.trustLabel,
        disclaimer: snapshot.disclaimer,
        sections: [
            .init(title: "Weekly highlights", items: snapshot.highlights.map { "\($0.title): \($0.detail)" }),
            .init(title: "What shifted", items: snapshot.shifts.map { "\($0.title): \($0.summary)" }),
            .init(title: "Next actions", items: snapshot.actions.map { "\($0.title): \($0.detail)" }),
            .init(title: "Source facts", items: snapshot.sourceSections.flatMap { section in
                section.facts.map { "\(section.title) — \($0.label): \($0.value)" }
            })
        ]
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(payload).write(to: jsonURL, options: [.atomic])
    return htmlURL
}

private extension Array {
    func uniqued<T: Hashable>(on keyPath: KeyPath<Element, T>) -> [Element] {
        var seen: Set<T> = []
        return filter { element in
            let key = element[keyPath: keyPath]
            return seen.insert(key).inserted
        }
    }
}
