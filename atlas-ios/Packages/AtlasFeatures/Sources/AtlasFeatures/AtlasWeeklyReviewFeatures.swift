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

struct AtlasWeeklyReviewHistoryItem: Identifiable, Equatable {
    let id: String
    let periodTitle: String
    let summary: String
    let comparisonLabel: String
    let seed: AtlasWeeklyReviewSeed
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

    func exportWeeklyReviewPack(for seed: AtlasWeeklyReviewSeed) async -> URL? {
        let result = await createReview(
            AtlasReviewRequest(
                scopeKind: .customDateRange,
                protocolIDs: libraryProtocols.map(\.id),
                dateRange: AtlasDateRange(start: seed.windowStart, end: seed.windowEnd),
                aliasModeEnabled: settingsSnapshot.trustVaultStatus.renderMode == .alias,
                deliveryKind: .staticPack
            )
        )
        return result?.packURL
    }
}

public struct AtlasWeeklyReviewScreen: View {
    @Bindable private var model: AtlasAppModel
    @State private var detailSheet: AtlasWeeklyReviewDetailSheet?
    @State private var shareURL: URL?
    @State private var isExporting = false

    public init(model: AtlasAppModel) {
        self.model = model
    }

    public var body: some View {
        let snapshot = atlasWeeklyReviewPresentation(
            insightsSnapshot: model.insightsSnapshot,
            retentionSnapshot: model.retentionSnapshot,
            rewardsSnapshot: model.rewardsSnapshot,
            settingsSnapshot: model.settingsSnapshot
        )

        AtlasScreen {
            if let snapshot {
                AtlasSectionCard(style: .hero) {
                    VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                        HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                Text("Weekly Review")
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Text(snapshot.periodTitle)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AtlasPalette.primary)
                                    .textCase(.uppercase)
                                Text(snapshot.generatedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }

                            Spacer()

                            AtlasStatusBadge(
                                snapshot.isMarkedReviewed ? "Reviewed" : "Ready",
                                tint: snapshot.isMarkedReviewed ? AtlasPalette.success : AtlasPalette.secondaryText
                            )
                        }

                        HStack(spacing: AtlasSpacing.small) {
                            AtlasStatusBadge(snapshot.trustLabel, tint: AtlasPalette.secondaryText)
                            if snapshot.reminderEnabled {
                                AtlasStatusBadge("Reminder on", tint: AtlasPalette.primary)
                            }
                        }

                        Text(snapshot.summaryText)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)

                        AtlasWeeklyReviewTrustPanel(
                            trustLabel: snapshot.trustLabel,
                            disclaimer: snapshot.disclaimer
                        )

                        if let primaryAction = snapshot.actions.first {
                            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                                Button(primaryAction.title) {
                                    perform(primaryAction)
                                }
                                .buttonStyle(AtlasPrimaryButtonStyle())

                                if atlasWeeklyReviewRoute(for: primaryAction.destination) != nil,
                                   snapshot.actionPlans.contains(where: { $0.id == atlasWeeklyReviewActionPlanID(for: primaryAction, seed: snapshot.seed) }) == false {
                                    Button("Save for next week") {
                                        Task {
                                            await model.saveWeeklyReviewActionPlan(primaryAction, seed: snapshot.seed)
                                        }
                                    }
                                    .buttonStyle(AtlasSecondaryButtonStyle())
                                }
                            }

                            Text(primaryAction.detail)
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                }

                if snapshot.highlights.isEmpty == false {
                    AtlasSectionCard(style: .elevated, title: "Weekly highlights") {
                        ForEach(Array(snapshot.highlights.enumerated()), id: \.element.id) { index, highlight in
                            if index > 0 {
                                Divider()
                            }
                            AtlasWeeklyReviewHighlightRow(item: highlight)
                        }
                    }
                }

                if snapshot.shifts.isEmpty == false {
                    AtlasSectionCard(title: "What shifted") {
                        Text("Atlas is keeping this descriptive. These notes restate visible patterns from your local records without claiming causes.")
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)

                        ForEach(Array(snapshot.shifts.enumerated()), id: \.element.id) { index, shift in
                            if index > 0 {
                                Divider()
                            }
                            AtlasWeeklyReviewShiftRow(item: shift) {
                                detailSheet = .shift(shift)
                            }
                        }
                    }
                }

                if snapshot.history.isEmpty == false {
                    AtlasSectionCard(style: .utility, title: "History") {
                        Text("Prior weeks stay available here so the current review has memory, not just a moment-in-time snapshot.")
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)

                        ForEach(Array(snapshot.history.enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Divider()
                            }
                            AtlasWeeklyReviewHistoryRow(item: item) {
                                detailSheet = .history(item)
                            }
                        }
                    }
                }

                if snapshot.actionPlans.isEmpty == false {
                    AtlasSectionCard(style: .elevated, title: "Weekly focus") {
                        Text("Saved follow-through items stay visible across Today and Weekly Review until you clear or carry them forward.")
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)

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
                    AtlasSectionCard(style: .elevated, title: "Next actions") {
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
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AtlasPalette.primary)
                                .textCase(.uppercase)

                            ForEach(section.facts) { fact in
                                HStack(alignment: .top, spacing: AtlasSpacing.small) {
                                    Text(fact.label)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                    Spacer(minLength: 12)
                                    Text(fact.value)
                                        .font(.caption)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                }
                            }
                        }
                    }
                }
            } else {
                AtlasSectionCard(style: .hero) {
                    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                        Text("Weekly Review")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text("Atlas needs a little more local activity before it can build a meaningful weekly review.")
                            .foregroundStyle(AtlasPalette.textSecondary)
                        Button("Open Insights") {
                            model.routePath.removeAll()
                            model.activeTab = .insights
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                    }
                }
            }
        }
        .navigationTitle("Weekly Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let snapshot {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await exportWeeklyReview(snapshot.seed)
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
            Task { await model.markWeeklyReviewComplete() }
        }
    }

    private func exportWeeklyReview(_ seed: AtlasWeeklyReviewSeed) async {
        isExporting = true
        defer { isExporting = false }
        shareURL = await model.exportWeeklyReviewPack(for: seed)
    }
}

struct AtlasWeeklyReviewEntrySection: View {
    @Bindable var model: AtlasAppModel

    var body: some View {
        let snapshot = atlasWeeklyReviewPresentation(
            insightsSnapshot: model.insightsSnapshot,
            retentionSnapshot: model.retentionSnapshot,
            rewardsSnapshot: model.rewardsSnapshot,
            settingsSnapshot: model.settingsSnapshot
        )

        if let snapshot {
            Section("Weekly review") {
                AtlasSectionCard(style: .elevated) {
                    HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            Text("Weekly Review")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text(snapshot.generatedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }

                        Spacer()

                        AtlasStatusBadge(
                            snapshot.isMarkedReviewed ? "Reviewed" : "Open",
                            tint: snapshot.isMarkedReviewed ? AtlasPalette.success : AtlasPalette.secondaryText
                        )
                    }

                    Text(snapshot.summaryText)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .lineLimit(4)

                    if let highlight = snapshot.highlights.first {
                        HStack(spacing: AtlasSpacing.small) {
                            Image(systemName: highlight.symbolName)
                                .foregroundStyle(AtlasPalette.primary)
                            Text(highlight.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Spacer()
                        }
                    }

                    Button("Open weekly review") {
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
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text(snapshot.periodTitle)
                                .font(.caption)
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
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(savedPlan.detail)
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)

                        HStack(spacing: AtlasSpacing.small) {
                            Button("Open focus") {
                                model.openWeeklyReviewRoute(savedPlan.route)
                            }
                            .buttonStyle(AtlasSecondaryButtonStyle())

                            Button(savedPlan.isCompleted ? "Mark active" : "Mark done") {
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
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(nextAction.detail)
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)

                        HStack(spacing: AtlasSpacing.small) {
                            Button("Open weekly review") {
                                model.open(.weeklyReview)
                            }
                            .buttonStyle(AtlasPrimaryButtonStyle())

                            if atlasWeeklyReviewRoute(for: nextAction.destination) != nil {
                                Button("Save focus") {
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
        ?? "Source-backed weekly view only. Atlas is showing local facts, descriptive highlights, and suggested next steps without making causal claims."
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
        history: atlasWeeklyReviewHistoryItems(
            currentSeed: seed,
            historicalSeeds: insightsSnapshot.weeklyReviewHistory
        ),
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
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            Label(trustLabel, systemImage: "lock.shield.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AtlasPalette.secondaryText)
            Text(disclaimer)
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
        .padding(AtlasSpacing.small)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.74))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.86), lineWidth: 1)
        )
    }
}

private struct AtlasWeeklyReviewHighlightRow: View {
    let item: AtlasWeeklyReviewHighlightItem

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.medium) {
            Image(systemName: item.symbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AtlasPalette.primary)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(item.detail)
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
        }
    }
}

private struct AtlasWeeklyReviewShiftRow: View {
    let item: AtlasWeeklyReviewShiftItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack(alignment: .top, spacing: AtlasSpacing.small) {
                    Image(systemName: item.symbolName)
                        .foregroundStyle(AtlasPalette.primary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(item.summary)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                if item.facts.isEmpty == false {
                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                        ForEach(item.facts.prefix(2)) { fact in
                            Text("\(fact.label): \(fact.value)")
                                .font(.caption)
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
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(item.detail)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }

            HStack(spacing: AtlasSpacing.small) {
                Button(item.title, action: action)
                    .buttonStyle(AtlasSecondaryButtonStyle())

                if let saveAction, isSaved == false {
                    Button("Save") {
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
        Button(action: action) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack(alignment: .top, spacing: AtlasSpacing.small) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.periodTitle)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(item.comparisonLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AtlasPalette.primary)
                    }
                    Spacer()
                    Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                Text(item.summary)
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(3)
            }
            .padding(.vertical, AtlasSpacing.xSmall)
        }
        .buttonStyle(.plain)
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
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(item.detail)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer()
                AtlasStatusBadge(
                    item.isCompleted ? "Done" : (item.isPinnedForNextWeek ? "Pinned" : "Active"),
                    tint: item.isCompleted ? AtlasPalette.success : AtlasPalette.secondaryText
                )
            }

            HStack(spacing: AtlasSpacing.small) {
                Button("Open", action: openAction)
                    .buttonStyle(AtlasSecondaryButtonStyle())
                Button(item.isCompleted ? "Mark active" : "Mark done", action: toggleCompleteAction)
                    .buttonStyle(AtlasTertiaryButtonStyle())
                Button(item.isPinnedForNextWeek ? "Unpin" : "Pin", action: togglePinnedAction)
                    .buttonStyle(AtlasTertiaryButtonStyle())
                Button("Remove", action: removeAction)
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
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text(shift.summary)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }

                    AtlasSectionCard(title: "Source facts") {
                        ForEach(shift.facts) { fact in
                            HStack(alignment: .top, spacing: AtlasSpacing.small) {
                                Text(fact.label)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                Spacer()
                                Text(fact.value)
                                    .font(.caption)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(AtlasPalette.textPrimary)
                            }
                        }
                    }
                case .history(let history):
                    AtlasSectionCard(style: .hero) {
                        VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                            Text(history.periodTitle)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text(history.comparisonLabel)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AtlasPalette.primary)
                            Text(history.summary)
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
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AtlasPalette.primary)
                                    .textCase(.uppercase)

                                ForEach(section.facts) { fact in
                                    HStack(alignment: .top, spacing: AtlasSpacing.small) {
                                        Text(fact.label)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                        Spacer()
                                        Text(fact.value)
                                            .font(.caption)
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
            ? "Atlas had little surrounding context to compare against the schedule this week."
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
        detail: detail.isEmpty ? "Atlas is surfacing the edits without claiming what they caused." : detail,
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
                    ?? "Atlas recorded \(protocolChangeSummary.changeCount) plan edits in this review window.",
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
                    ? "Atlas captured \(seed.contextEntryCount) context entries during the review window."
                    : "Atlas did not have much surrounding context to compare against the schedule this week.",
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
                detail: "A little more surrounding context will make the next review more informative without making logging heavy.",
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
                    ? "Atlas has the plan update, but not much follow-through around it yet."
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
                detail: "Turn on bounded summaries in Settings if you want the hero read written out each week.",
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
                detail: "Use this only when you have actually looked over the week. It stays local and never changes history.",
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
                    ?? "Review the next visible protocol detail from the weekly summary.",
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
                detail: "Use Insights to add supporting context and keep the next review source-rich.",
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

private extension Array {
    func uniqued<T: Hashable>(on keyPath: KeyPath<Element, T>) -> [Element] {
        var seen: Set<T> = []
        return filter { element in
            let key = element[keyPath: keyPath]
            return seen.insert(key).inserted
        }
    }
}
