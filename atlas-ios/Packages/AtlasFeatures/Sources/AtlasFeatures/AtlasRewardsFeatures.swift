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
        let profile = atlasMascotProfileSummary(
            selection: mascotSelection,
            nickname: mascotNickname,
            rewardsSnapshot: snapshot,
            history: mascotHistory
        )

        AtlasSectionCard(style: .reward) {
            HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    HStack(alignment: .firstTextBaseline, spacing: AtlasSpacing.small) {
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            Text("Rewards board")
                                .atlasTextRole(.cardBody)
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text("Level \(snapshot.level) with \(snapshot.totalPoints) points.")
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }

                        Spacer()

                        AtlasStatusBadge(
                            evolution.currentFormName,
                            tint: earnedBadgeCount > 0 ? AtlasPalette.success : AtlasPalette.primary
                        )
                    }

                    Text(evolution.milestoneHeadline)
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.primary)

                    Text(evolution.progressLabel)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    Text(profile.statusLine)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                VStack(spacing: AtlasSpacing.small) {
                    AtlasMascotIllustration(
                        line: atlasMascotLine(for: mascotSelection),
                        stage: evolution.stage,
                        size: 96
                    )

                    AtlasStatusBadge("Live guardian", tint: atlasMascotLineTint(for: mascotSelection))
                }
            }

            AtlasMetricStrip(metrics: atlasRewardsMetrics(snapshot: snapshot, earnedBadgeCount: earnedBadgeCount))

            AtlasProgressMeter(
                title: "Next unlock",
                detail: evolution.progressLabel,
                value: atlasRewardsProgressValue(snapshot),
                tint: AtlasPalette.reward
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

            if let reaction = profile.reaction {
                AtlasCalloutRow(
                    systemImage: reaction.symbolName,
                    title: reaction.title,
                    detail: reaction.detail,
                    tint: AtlasPalette.reward
                )
            }

            if let headlineBadge {
                AtlasCalloutRow(
                    systemImage: "star.circle.fill",
                    title: "Badge momentum",
                    detail: headlineBadge,
                    tint: AtlasPalette.reward
                )
            }

            Text(snapshot.note)
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
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
}

struct AtlasRewardsInsightSection: View {
    let snapshot: AtlasRewardsSnapshot
    let mascotSelection: AtlasMascotSelection
    let mascotNickname: String?
    let mascotHistory: [AtlasMascotEvolutionRecord]

    var body: some View {
        if snapshot.settings.enabled {
            let evolution = atlasRewardsEvolutionProgress(for: snapshot, selection: mascotSelection)
            let profile = atlasMascotProfileSummary(
                selection: mascotSelection,
                nickname: mascotNickname,
                rewardsSnapshot: snapshot,
                history: mascotHistory
            )

            Section("Rewards") {
                AtlasSectionCard(style: .reward) {
                    HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    Text("Level \(snapshot.level)")
                                        .atlasTextRole(.cardTitle)
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                    Text("\(snapshot.totalPoints) total points • \(snapshot.nextLevelPoints - snapshot.totalPoints) to next level")
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }

                                Spacer()

                                AtlasStatusBadge(
                                    evolution.currentFormName,
                                    tint: snapshot.badges.filter(\.isEarned).isEmpty ? AtlasPalette.primary : AtlasPalette.success
                                )
                            }

                            Text(evolution.milestoneHeadline)
                                .atlasTextRole(.deckEyebrow)
                                .foregroundStyle(AtlasPalette.primary)

                            Text(evolution.progressLabel)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)

                            Text(profile.statusLine)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }

                        VStack(spacing: AtlasSpacing.small) {
                            AtlasMascotIllustration(
                                line: atlasMascotLine(for: mascotSelection),
                                stage: evolution.stage,
                                size: 104
                            )

                            AtlasStatusBadge("Live guardian", tint: atlasMascotLineTint(for: mascotSelection))
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
                        detail: evolution.progressLabel,
                        value: atlasRewardsProgressValue(snapshot),
                        tint: AtlasPalette.reward
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

                    if let reaction = profile.reaction {
                        AtlasCalloutRow(
                            systemImage: reaction.symbolName,
                            title: reaction.title,
                            detail: reaction.detail,
                            tint: AtlasPalette.reward
                        )
                    }

                    Text(snapshot.note)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
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
    let activeStreak = snapshot.streaks.filter(\.isActive).map(\.count).max() ?? 0

    return [
        .init(id: "level", title: "Level", value: "\(snapshot.level)", tint: AtlasPalette.reward),
        .init(id: "points", title: "Points", value: "\(snapshot.totalPoints)", tint: AtlasPalette.primary),
        .init(id: "streak", title: "Best streak", value: activeStreak == 0 ? "None" : "\(activeStreak)", tint: AtlasPalette.success),
        .init(id: "badges", title: "Badges", value: "\(earnedBadgeCount)", tint: earnedBadgeCount == 0 ? AtlasPalette.secondaryText : AtlasPalette.reward)
    ]
}

private func atlasRewardsProgressValue(_ snapshot: AtlasRewardsSnapshot) -> Double {
    guard snapshot.nextLevelPoints > 0 else {
        return 1
    }
    return min(max(Double(snapshot.totalPoints) / Double(snapshot.nextLevelPoints), 0), 1)
}
