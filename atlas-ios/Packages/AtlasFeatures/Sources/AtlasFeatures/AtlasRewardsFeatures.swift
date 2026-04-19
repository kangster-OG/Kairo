import AtlasDesignSystem
import AtlasDomain
import SwiftUI

struct AtlasRewardsTodayCard: View {
    let snapshot: AtlasRewardsSnapshot
    let mascotSelection: AtlasMascotSelection
    let mascotNickname: String?
    let mascotHistory: [AtlasMascotEvolutionRecord]

    var body: some View {
        let evolution = atlasRewardsEvolutionProgress(for: snapshot, selection: mascotSelection)

        AtlasSectionCard(style: .reward) {
            HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    HStack(alignment: .firstTextBaseline, spacing: AtlasSpacing.small) {
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            Text("Rewards board")
                                .atlasTextRole(.cardBody)
                                .foregroundStyle(AtlasPalette.textPrimary)
                        }

                        Spacer()

                        AtlasStatusBadge(
                            evolution.currentFormName,
                            tint: earnedBadgeCount > 0 ? AtlasPalette.success : AtlasPalette.primary
                        )
                    }
                }

                AtlasMascotSticker(
                    line: atlasMascotLine(for: mascotSelection),
                    stage: evolution.stage,
                    size: 96
                )
            }

            AtlasMetricStrip(metrics: atlasRewardsMetrics(snapshot: snapshot, earnedBadgeCount: earnedBadgeCount))

            AtlasProgressMeter(
                title: "Next unlock",
                detail: nil,
                value: atlasRewardsProgressValue(snapshot),
                tint: AtlasPalette.reward
            )

            AtlasRewardUnlockReadinessRow(
                snapshot: snapshot,
                evolution: evolution,
                selection: mascotSelection
            )

            if snapshot.streaks.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AtlasSpacing.small) {
                        ForEach(snapshot.streaks) { streak in
                            AtlasRewardStreakChip(streak: streak)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            if let headlineGoal {
                AtlasRewardGoalRow(goal: headlineGoal)
            }

            if let headlineBadge {
                AtlasCalloutRow(
                    systemImage: "star.circle.fill",
                    title: "Badge momentum",
                    detail: headlineBadge,
                    tint: AtlasPalette.reward
                )
            }
        }
    }

    private var earnedBadgeCount: Int {
        snapshot.badges.filter(\.isEarned).count
    }

    private var headlineGoal: AtlasRewardGoalSnapshot? {
        snapshot.goals.first(where: { $0.isMet == false }) ?? snapshot.goals.first
    }

    private var headlineBadge: String? {
        if let earned = snapshot.badges.first(where: { $0.isEarned }) {
            return "Latest unlocked: \(earned.title)."
        }
        return snapshot.badges.first.map { "Next badge: \($0.title)." }
    }

    private var milestoneReveal: AtlasRewardMilestoneReveal {
        atlasRewardMilestoneReveal(
            snapshot: snapshot,
            evolution: atlasRewardsEvolutionProgress(for: snapshot, selection: mascotSelection),
            selection: mascotSelection
        )
    }
}

struct AtlasRewardsInsightSection: View {
    let snapshot: AtlasRewardsSnapshot
    let mascotSelection: AtlasMascotSelection
    let mascotNickname: String?
    let mascotHistory: [AtlasMascotEvolutionRecord]

    var body: some View {
        if snapshot.settings.enabled {
            let evolution = atlasRewardsEvolutionProgress(for: snapshot, selection: mascotSelection)

            Section("Rewards") {
                AtlasSectionCard(style: .reward) {
                    HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    Text("Level \(snapshot.level)")
                                        .atlasTextRole(.cardTitle)
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                }

                                Spacer()
                            }
                        }
                    }

                    AtlasMetricStrip(
                        metrics: atlasRewardsMetrics(
                            snapshot: snapshot,
                            earnedBadgeCount: snapshot.badges.filter(\.isEarned).count
                        )
                    )

                    AtlasProgressMeter(
                        title: "Next unlock",
                        detail: nil,
                        value: atlasRewardsProgressValue(snapshot),
                        tint: AtlasPalette.reward
                    )

                    AtlasRewardUnlockReadinessRow(
                        snapshot: snapshot,
                        evolution: evolution,
                        selection: mascotSelection
                    )

                    VStack(spacing: AtlasSpacing.small) {
                        ForEach(snapshot.goals) { goal in
                            AtlasRewardGoalRow(goal: goal)
                        }
                    }

                    VStack(spacing: AtlasSpacing.small) {
                        ForEach(snapshot.badges) { badge in
                            AtlasRewardBadgeRow(badge: badge)
                        }
                    }

                }
            }
        }
    }
}

private struct AtlasRewardStreakChip: View {
    let streak: AtlasRewardStreakSnapshot

    var body: some View {
        HStack(spacing: AtlasSpacing.xSmall) {
            Image(systemName: streak.symbolName)
            VStack(alignment: .leading, spacing: 2) {
                Text(streak.title)
                    .atlasTextRole(.deckEyebrow)
                Text(streak.valueLabel)
                    .atlasTextRole(.metricLabel)
            }
        }
        .foregroundStyle(streak.isActive ? AtlasPalette.success : AtlasPalette.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            Capsule(style: .continuous)
                .fill((streak.isActive ? AtlasPalette.success : AtlasPalette.primary).opacity(0.12))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke((streak.isActive ? AtlasPalette.success : AtlasPalette.primary).opacity(0.18), lineWidth: 1)
        )
        .shadow(
            color: (streak.isActive ? AtlasPalette.success : AtlasPalette.primary).opacity(0.08),
            radius: 6,
            x: 0,
            y: 3
        )
    }
}

private struct AtlasRewardGoalRow: View {
    let goal: AtlasRewardGoalSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            HStack(alignment: .firstTextBaseline, spacing: AtlasSpacing.small) {
                Image(systemName: goal.symbolName)
                    .foregroundStyle(goal.isMet ? AtlasPalette.success : AtlasPalette.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(goal.progressLabel)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer()
                AtlasStatusBadge(
                    goal.isMet ? "Met" : "\(Int(goal.progress * 100))%",
                    tint: goal.isMet ? AtlasPalette.success : AtlasPalette.primary
                )
            }

            AtlasProgressMeter(
                detail: goal.helperText,
                value: goal.progress,
                tint: goal.isMet ? AtlasPalette.success : AtlasPalette.primary
            )
        }
    }
}

private struct AtlasRewardUnlockReadinessRow: View {
    let snapshot: AtlasRewardsSnapshot
    let evolution: AtlasMascotEvolutionProgress
    let selection: AtlasMascotSelection

    var body: some View {
        let summary = atlasRewardUnlockSummary(
            snapshot: snapshot,
            evolution: evolution,
            selection: selection
        )

        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            AtlasCalloutRow(
                systemImage: summary.symbolName,
                title: summary.title,
                detail: summary.detail,
                tint: summary.tint,
                badge: summary.badge
            )

            if let streak = snapshot.streaks.first(where: \.isActive) {
                AtlasStatusBadge("Active streak: \(streak.valueLabel)", tint: AtlasPalette.success)
            }
        }
    }
}

private struct AtlasRewardSignalTile: View {
    let title: String
    let value: String
    let detail: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .atlasTextRole(.metricLabel)
                .foregroundStyle(tint)
            Text(value)
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)
                .lineLimit(1)
            Text(detail)
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AtlasPalette.surfaceSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct AtlasRewardMilestoneReveal {
    let eyebrow: String
    let title: String
    let detail: String
    let tint: Color
    let badge: String?
    let symbolName: String
}

private struct AtlasRewardUnlockSummary {
    let title: String
    let detail: String
    let badge: String
    let symbolName: String
    let tint: Color
}

private func atlasRewardMilestoneReveal(
    snapshot: AtlasRewardsSnapshot,
    evolution: AtlasMascotEvolutionProgress,
    selection: AtlasMascotSelection
) -> AtlasRewardMilestoneReveal {
    let remainingLevelPoints = max(snapshot.nextLevelPoints - snapshot.totalPoints, 0)
    if remainingLevelPoints == 0 {
        return AtlasRewardMilestoneReveal(
            eyebrow: "Level ready",
            title: "Next level is ready.",
            detail: "Ready when you are.",
            tint: AtlasPalette.reward,
            badge: "Queued",
            symbolName: "bolt.fill"
        )
    }

    if let nextFormName = evolution.nextFormName,
       let nextThresholdPoints = evolution.nextThresholdPoints {
        let remainingFormPoints = max(nextThresholdPoints - snapshot.totalPoints, 0)
        if remainingFormPoints == 0 || (evolution.progressFraction ?? 0) >= 0.82 {
            return AtlasRewardMilestoneReveal(
                eyebrow: "Near unlock",
                title: "\(nextFormName) is close.",
                detail: "Almost ready.",
                tint: atlasMascotLineTint(for: selection),
                badge: evolution.stageBadge,
                symbolName: "sparkles"
            )
        }
    }

    if let activeStreak = snapshot.streaks.first(where: \.isActive) {
        return AtlasRewardMilestoneReveal(
            eyebrow: "Momentum",
            title: "\(activeStreak.title) is building momentum.",
            detail: "Current streak: \(activeStreak.valueLabel).",
            tint: AtlasPalette.success,
            badge: activeStreak.valueLabel,
            symbolName: activeStreak.symbolName
        )
    }

    return AtlasRewardMilestoneReveal(
        eyebrow: "Rewards loop",
        title: "Next unlock is visible.",
        detail: evolution.nextFormName == nil ? "The full line is unlocked." : "Progress is tracked quietly.",
        tint: AtlasPalette.reward,
        badge: evolution.stageBadge,
        symbolName: "star.circle.fill"
    )
}

private struct AtlasRewardBadgeRow: View {
    let badge: AtlasRewardBadgeSnapshot

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.small) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill((badge.isEarned ? AtlasPalette.success : AtlasPalette.textSecondary).opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: badge.symbolName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(badge.isEarned ? AtlasPalette.success : AtlasPalette.textSecondary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(badge.title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(badge.subtitle)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            Spacer()

            AtlasStatusBadge(
                badge.isEarned ? "Unlocked" : "Locked",
                tint: badge.isEarned ? AtlasPalette.success : AtlasPalette.textSecondary
            )
        }
    }
}

private func atlasRewardsMetrics(
    snapshot: AtlasRewardsSnapshot,
    earnedBadgeCount: Int
) -> [AtlasMetricItem] {
    return [
        .init(id: "level", title: "Level", value: "\(snapshot.level)", tint: AtlasPalette.reward),
        .init(id: "points", title: "Points", value: "\(snapshot.totalPoints)", tint: AtlasPalette.primary),
        .init(id: "badges", title: "Badges", value: "\(earnedBadgeCount)", tint: earnedBadgeCount == 0 ? AtlasPalette.secondaryText : AtlasPalette.reward)
    ]
}

private func atlasRewardsProgressValue(_ snapshot: AtlasRewardsSnapshot) -> Double {
    guard snapshot.nextLevelPoints > 0 else {
        return 1
    }
    return min(max(Double(snapshot.totalPoints) / Double(snapshot.nextLevelPoints), 0), 1)
}

private func atlasRewardUnlockSummary(
    snapshot: AtlasRewardsSnapshot,
    evolution: AtlasMascotEvolutionProgress,
    selection: AtlasMascotSelection
) -> AtlasRewardUnlockSummary {
    let remainingLevelPoints = max(snapshot.nextLevelPoints - snapshot.totalPoints, 0)

    guard let nextFormName = evolution.nextFormName,
          let nextThresholdPoints = evolution.nextThresholdPoints else {
        return AtlasRewardUnlockSummary(
            title: "Full line unlocked",
            detail: "Recaps and badges are available.",
            badge: "Final form",
            symbolName: "crown.fill",
            tint: AtlasPalette.success
        )
    }

    let remainingFormPoints = max(nextThresholdPoints - snapshot.totalPoints, 0)
    let progressFraction = evolution.progressFraction ?? 0

    if remainingFormPoints == 0 || progressFraction >= 0.86 {
        return AtlasRewardUnlockSummary(
            title: "\(nextFormName) is close",
            detail: "Almost ready.",
            badge: "Near unlock",
            symbolName: "sparkles",
            tint: atlasMascotLineTint(for: selection)
        )
    }

    if remainingLevelPoints == 0 {
        return AtlasRewardUnlockSummary(
            title: "Next level is ready",
            detail: "\(nextFormName) is next.",
            badge: "Level ready",
            symbolName: "arrow.up.circle.fill",
            tint: AtlasPalette.reward
        )
    }

    return AtlasRewardUnlockSummary(
        title: "Next unlock",
        detail: "\(nextFormName) is ahead.",
        badge: "In motion",
        symbolName: atlasMascotLineSymbol(for: selection),
        tint: atlasMascotLineTint(for: selection)
    )
}
