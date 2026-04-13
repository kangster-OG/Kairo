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

struct AtlasWeeklyReviewPresentation: Equatable {
    let periodTitle: String
    let generatedAt: Date
    let summaryText: String
    let trustLabel: String
    let disclaimer: String
    let highlights: [AtlasWeeklyReviewHighlightItem]
    let shifts: [AtlasWeeklyReviewShiftItem]
    let actions: [AtlasWeeklyReviewActionItem]
    let sourceSections: [AtlasSummarySourceSection]
    let isMarkedReviewed: Bool
    let summarySettingEnabled: Bool
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
}

public struct AtlasWeeklyReviewScreen: View {
    @Bindable private var model: AtlasAppModel

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

                        Text(snapshot.summaryText)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)

                        AtlasWeeklyReviewTrustPanel(
                            trustLabel: snapshot.trustLabel,
                            disclaimer: snapshot.disclaimer
                        )

                        if let primaryAction = snapshot.actions.first {
                            Button(primaryAction.title) {
                                perform(primaryAction)
                            }
                            .buttonStyle(AtlasPrimaryButtonStyle())

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
                            AtlasWeeklyReviewShiftRow(item: shift)
                        }
                    }
                }

                if snapshot.actions.count > 1 {
                    AtlasSectionCard(style: .elevated, title: "Next actions") {
                        ForEach(Array(snapshot.actions.dropFirst().enumerated()), id: \.element.id) { index, action in
                            if index > 0 {
                                Divider()
                            }
                            AtlasWeeklyReviewActionRow(item: action) {
                                perform(action)
                            }
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
    let windowStart = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: seed.generatedAt)) ?? seed.generatedAt
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
            windowStart: windowStart
        )
        + atlasWeeklyReviewReviewSections(
            retentionSnapshot: retentionSnapshot,
            isMarkedReviewed: reviewCompleted
        )

    return AtlasWeeklyReviewPresentation(
        periodTitle: seed.periodTitle,
        generatedAt: seed.generatedAt,
        summaryText: summaryText,
        trustLabel: trustLabel,
        disclaimer: disclaimer,
        highlights: atlasWeeklyReviewHighlights(
            seed: seed,
            rewardsSnapshot: rewardsSnapshot,
            settingsSnapshot: settingsSnapshot,
            windowStart: windowStart
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
        sourceSections: sourceSections,
        isMarkedReviewed: reviewCompleted,
        summarySettingEnabled: seed.summarySettingEnabled
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

    var body: some View {
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
            }

            if item.facts.isEmpty == false {
                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    ForEach(item.facts) { fact in
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
}

private struct AtlasWeeklyReviewActionRow: View {
    let item: AtlasWeeklyReviewActionItem
    let action: () -> Void

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

            Button(item.title, action: action)
                .buttonStyle(AtlasSecondaryButtonStyle())
        }
        .padding(.vertical, AtlasSpacing.xSmall)
    }
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
    var items = insightsSnapshot.deterministicExplanations.prefix(2).map {
        AtlasWeeklyReviewShiftItem(
            id: $0.id,
            title: $0.title,
            summary: $0.summary,
            facts: $0.facts,
            symbolName: atlasWeeklyReviewShiftSymbol(for: $0.kind)
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

    return Array(items.prefix(3))
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

private extension Array {
    func uniqued<T: Hashable>(on keyPath: KeyPath<Element, T>) -> [Element] {
        var seen: Set<T> = []
        return filter { element in
            let key = element[keyPath: keyPath]
            return seen.insert(key).inserted
        }
    }
}
