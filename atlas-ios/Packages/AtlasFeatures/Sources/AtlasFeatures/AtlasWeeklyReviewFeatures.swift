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
            return try atlasWriteWeeklyReviewExport(snapshot: snapshot)
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

    public init(model: AtlasAppModel) {
        self.model = model
    }

    public var body: some View {
        let snapshot = model.weeklyReviewPresentation()

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

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: AtlasSpacing.small) {
                                AtlasStatusBadge(snapshot.trustLabel, tint: AtlasPalette.secondaryText)
                                if snapshot.reminderEnabled {
                                    AtlasStatusBadge("Reminder on", tint: AtlasPalette.primary)
                                }
                            }

                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                AtlasStatusBadge(snapshot.trustLabel, tint: AtlasPalette.secondaryText)
                                if snapshot.reminderEnabled {
                                    AtlasStatusBadge("Reminder on", tint: AtlasPalette.primary)
                                }
                            }
                        }

                        Text(snapshot.summaryText)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)

                        AtlasWeeklyReviewSignalStrip(snapshot: snapshot)

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
                                    .buttonStyle(AtlasTertiaryButtonStyle())
                                }
                            }

                            Text(primaryAction.detail)
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                }

                AtlasWeeklyReviewCommandDeck(
                    model: model,
                    snapshot: snapshot
                )

                if snapshot.highlights.isEmpty == false {
                    AtlasSectionCard(style: .elevated, title: "Weekly highlights") {
                        ForEach(Array(snapshot.highlights.prefix(3).enumerated()), id: \.element.id) { index, highlight in
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

                if let actionOutcomes = snapshot.actionOutcomes {
                    AtlasSectionCard(style: .elevated, title: "Action follow-through") {
                        Text(actionOutcomes.summary)
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)

                        ForEach(Array(actionOutcomes.items.enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Divider()
                            }
                            AtlasWeeklyReviewActionOutcomeRow(item: item)
                        }
                    }
                }

                if let protocolFollowUp = snapshot.protocolFollowUp {
                    AtlasSectionCard(style: .elevated, title: "Since the latest plan change") {
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
                        Text("Prior weeks stay available here so the current review has memory, not just a moment-in-time snapshot.")
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)

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
                            archivePresented = true
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
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
            Task { await model.markWeeklyReviewComplete() }
        }
    }

    private func exportWeeklyReview(_ snapshot: AtlasWeeklyReviewPresentation) async {
        isExporting = true
        defer { isExporting = false }
        shareURL = await model.exportWeeklyReviewPack(snapshot)
    }
}

private struct AtlasWeeklyReviewCommandDeck: View {
    let model: AtlasAppModel
    let snapshot: AtlasWeeklyReviewPresentation

    var body: some View {
        AtlasSectionCard(style: .utility, title: "At a glance") {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                AtlasWeeklyReviewCommandCard(
                    title: "Primary focus",
                    value: snapshot.actions.first?.title ?? "No follow-through queued",
                    detail: snapshot.actions.first?.detail ?? "Atlas did not detect a high-priority follow-up for this review."
                )

                AtlasWeeklyReviewCommandCard(
                    title: "Continuity",
                    value: continuityTitle,
                    detail: continuityDetail
                )

                AtlasWeeklyReviewCommandCard(
                    title: "Carry forward",
                    value: snapshot.actionPlans.isEmpty ? "No saved plans" : "\(snapshot.actionPlans.count) saved plan\(snapshot.actionPlans.count == 1 ? "" : "s")",
                    detail: snapshot.actionPlans.isEmpty
                        ? "Save one action from this review to keep it visible in Today next week."
                        : "Saved follow-through items stay anchored in Weekly Review and Today until you clear them."
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
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AtlasPalette.primary)
                .textCase(.uppercase)
            Text(value)
                .font(.body.weight(.semibold))
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

private struct AtlasWeeklyReviewCommandCard: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AtlasPalette.primary)
                .textCase(.uppercase)
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(AtlasPalette.textPrimary)
            Text(detail)
                .font(.caption)
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

private struct AtlasWeeklyReviewComparisonCard: View {
    let snapshot: AtlasWeeklyReviewComparisonSnapshot
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack(alignment: .top, spacing: AtlasSpacing.small) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Compared with \(snapshot.historicalPeriodTitle)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AtlasPalette.primary)
                            .textCase(.uppercase)
                        Text(snapshot.headline)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                    }
                    Spacer()
                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                        .foregroundStyle(AtlasPalette.primary)
                }

                Text(snapshot.summary)
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)

                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    ForEach(snapshot.metrics.prefix(3)) { metric in
                        Text("\(metric.label): \(metric.deltaLabel)")
                            .font(.caption)
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
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(item.detail)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer()
                AtlasStatusBadge(item.statusLabel, tint: atlasWeeklyReviewOutcomeTint(item.statusLabel))
            }

            Text(item.statusDetail)
                .font(.caption)
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
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(summary.summary ?? "\(summary.changeTypeTitle) is still within Atlas's follow-up window.")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                Text("Changed \(summary.changedAt.formatted(date: .abbreviated, time: .omitted)) • \(summary.windowDays)-day follow-up")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasPalette.primary)
                Text("Completed logs: \(summary.completedCount) • Skipped: \(summary.skippedCount) • Rescheduled: \(summary.rescheduledCount) • Context: \(summary.contextEntryCount)")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text(summary.hasVisibleSupportingData
                    ? "Atlas has visible follow-through around the change and is keeping the read descriptive."
                    : "Atlas has the change audit, but very little follow-through around it yet.")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            Button("Open change follow-up", action: openAction)
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
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text("Comparing \(snapshot.periodTitle) with \(selectedHistory.periodTitle)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AtlasPalette.primary)
                                .textCase(.uppercase)
                            Text(comparison.headline)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text(comparison.summary)
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
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                    Spacer()
                                    Text(metric.deltaLabel)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AtlasPalette.primary)
                                }
                                Text("This week: \(metric.currentValue) • Archive week: \(metric.historicalValue)")
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                            .padding(.vertical, AtlasSpacing.xSmall)
                        }
                    }

                    AtlasSectionCard(style: .utility, title: "Archive weeks") {
                        ForEach(snapshot.history) { item in
                            Button {
                                selectedHistoryID = item.id
                            } label: {
                                HStack(alignment: .top, spacing: AtlasSpacing.small) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.periodTitle)
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(AtlasPalette.textPrimary)
                                        Text(item.comparisonLabel)
                                            .font(.caption)
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
            ? "Atlas kept your prior weekly focus visible, but there were no marked outcomes yet."
            : "From \(periodTitle): \(summary).",
        items: previousPlans.prefix(4).map { plan in
            let statusLabel: String
            let statusDetail: String
            if plan.isCompleted {
                statusLabel = "Completed"
                statusDetail = "This saved focus was marked done after the review."
            } else if plan.isPinnedForNextWeek {
                statusLabel = "Carried"
                statusDetail = "Atlas kept this focus visible into the new week."
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
