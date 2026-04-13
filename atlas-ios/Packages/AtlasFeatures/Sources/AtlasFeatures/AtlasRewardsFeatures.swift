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

        AtlasSectionCard {
            HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    HStack(alignment: .firstTextBaseline, spacing: AtlasSpacing.small) {
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            Text("Rewards board")
                                .font(.body.weight(.semibold))
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
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.primary)

                    Text(evolution.progressLabel)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    Text(profile.statusLine)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                AtlasMascotSprite(
                    line: atlasMascotLine(for: mascotSelection),
                    stage: evolution.stage,
                    pose: atlasRewardsMascotPose(for: snapshot),
                    size: 88
                )
            }

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
                Text("\(reaction.title) • \(reaction.detail)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasPalette.primary)
            }

            if let headlineBadge {
                Text(headlineBadge)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasPalette.primary)
            }

            Text(snapshot.note)
                .font(.caption)
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
                AtlasSectionCard {
                    HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    Text("Level \(snapshot.level)")
                                        .font(.title3.weight(.semibold))
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
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AtlasPalette.primary)

                            Text(evolution.progressLabel)
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)

                            Text(profile.statusLine)
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }

                        AtlasMascotSprite(
                            line: atlasMascotLine(for: mascotSelection),
                            stage: evolution.stage,
                            pose: atlasRewardsMascotPose(for: snapshot),
                            size: 96
                        )
                    }

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
                        Text("\(reaction.title) • \(reaction.detail)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AtlasPalette.primary)
                    }

                    Text(snapshot.note)
                        .font(.caption)
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
                Text(streak.valueLabel)
                    .font(.caption2.weight(.semibold))
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(streak.isActive ? AtlasPalette.success : AtlasPalette.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            Capsule(style: .continuous)
                .fill((streak.isActive ? AtlasPalette.success : AtlasPalette.primary).opacity(0.12))
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
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(goal.progressLabel)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer()
                AtlasStatusBadge(
                    goal.isMet ? "Met" : "\(Int(goal.progress * 100))%",
                    tint: goal.isMet ? AtlasPalette.success : AtlasPalette.primary
                )
            }

            ProgressView(value: goal.progress)
                .tint(goal.isMet ? AtlasPalette.success : AtlasPalette.primary)

            Text(goal.helperText)
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)
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
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(badge.isEarned ? AtlasPalette.success : AtlasPalette.textSecondary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(badge.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(badge.subtitle)
                    .font(.caption)
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
