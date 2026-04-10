import AtlasDesignSystem
import AtlasDomain
import SwiftUI

struct AtlasRetentionTodayCard: View {
    let model: AtlasAppModel
    let snapshot: AtlasRetentionSnapshot

    var body: some View {
        AtlasSectionCard {
            if let companion = snapshot.companion {
                AtlasRetentionCompanionView(companion: companion, emphasis: .featured)
            }

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    Text("Optional local progress")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text("\(snapshot.earnedMilestoneCount) of \(snapshot.milestones.count) calm signals are active.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                Spacer()

                AtlasStatusBadge(
                    "\(snapshot.earnedMilestoneCount) active",
                    tint: snapshot.earnedMilestoneCount > 0 ? AtlasPalette.success : AtlasPalette.primary
                )
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AtlasSpacing.small) {
                    ForEach(snapshot.milestones) { milestone in
                        AtlasRetentionMilestoneChip(milestone: milestone)
                    }
                }
                .padding(.vertical, 2)
            }

            Text(snapshot.note)
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
    }
}

struct AtlasRetentionInsightSection: View {
    let model: AtlasAppModel
    let snapshot: AtlasRetentionSnapshot

    var body: some View {
        if snapshot.settings.progressEnabled {
            Section("Calm progress") {
                AtlasSectionCard {
                    if let companion = snapshot.companion {
                        AtlasRetentionCompanionView(companion: companion, emphasis: .inline)
                    }

                    Text("These signals stay descriptive, local, and low-pressure. They never reward unsafe behavior and they never ask you to fill in logs that did not happen.")
                        .foregroundStyle(AtlasPalette.textSecondary)

                    ForEach(snapshot.milestones) { milestone in
                        AtlasRetentionMilestoneRow(milestone: milestone)
                    }

                    if weeklyReviewMilestone?.isEarned == false {
                        Button("Mark this week reviewed") {
                            Task { await model.markWeeklyReviewComplete() }
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                    }

                    Text(snapshot.note)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
        }
    }

    private var weeklyReviewMilestone: AtlasRetentionMilestoneSnapshot? {
        snapshot.milestones.first(where: { $0.kind == .weeklyReviewCompleted })
    }
}

struct AtlasRetentionCompanionPreview: View {
    let companion: AtlasRetentionCompanionSnapshot
    let title: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AtlasPalette.primary)
                .textCase(.uppercase)

            AtlasRetentionCompanionView(companion: companion, emphasis: .featured)

            Text(caption)
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
    }
}

private enum AtlasRetentionCompanionEmphasis {
    case featured
    case inline
}

private struct AtlasRetentionCompanionView: View {
    let companion: AtlasRetentionCompanionSnapshot
    let emphasis: AtlasRetentionCompanionEmphasis

    var body: some View {
        HStack(alignment: .center, spacing: AtlasSpacing.medium) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: mascotGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: emphasis == .featured ? 68 : 54, height: emphasis == .featured ? 68 : 54)

                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: emphasis == .featured ? 22 : 18, height: emphasis == .featured ? 22 : 18)
                    .offset(x: -6, y: -6)

                Image(systemName: companion.systemImage)
                    .font(.system(size: emphasis == .featured ? 24 : 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: companionTint.opacity(0.18), radius: 12, x: 0, y: 6)

            VStack(alignment: .leading, spacing: emphasis == .featured ? 6 : 4) {
                Text("Atlas companion")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(companionTint)
                    .textCase(.uppercase)
                Text(companion.title)
                    .font((emphasis == .featured ? Font.title3 : Font.body).weight(.bold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(companion.subtitle)
                    .font(emphasis == .featured ? .body : .callout)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(emphasis == .featured ? 18 : 0)
        .background(backgroundSurface)
    }

    private var companionTint: Color {
        switch companion.mood {
        case .quiet:
            return AtlasPalette.primary
        case .steady:
            return AtlasPalette.success
        case .settled:
            return AtlasPalette.primaryPressed
        }
    }

    private var mascotGradient: [Color] {
        switch companion.mood {
        case .quiet:
            return [AtlasPalette.primary.opacity(0.92), AtlasPalette.shellTopAccent]
        case .steady:
            return [AtlasPalette.success.opacity(0.92), AtlasPalette.primary]
        case .settled:
            return [AtlasPalette.primaryPressed, AtlasPalette.shellTop]
        }
    }

    @ViewBuilder
    private var backgroundSurface: some View {
        if emphasis == .featured {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.98), companionTint.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(companionTint.opacity(0.16), lineWidth: 1)
                )
        } else {
            Color.clear
        }
    }
}

private struct AtlasRetentionMilestoneChip: View {
    let milestone: AtlasRetentionMilestoneSnapshot

    var body: some View {
        HStack(spacing: AtlasSpacing.xSmall) {
            Image(systemName: milestone.symbolName)
            Text(milestone.title)
            if let streakCount = milestone.streakCount {
                Text("\(streakCount)")
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.12))
        )
    }

    private var tint: Color {
        switch milestone.tone {
        case .complete:
            return AtlasPalette.success
        case .inProgress:
            return AtlasPalette.primary
        case .neutral:
            return AtlasPalette.textSecondary
        }
    }
}

private struct AtlasRetentionMilestoneRow: View {
    let milestone: AtlasRetentionMilestoneSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            HStack(alignment: .firstTextBaseline, spacing: AtlasSpacing.small) {
                Image(systemName: milestone.symbolName)
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 4) {
                    Text(milestone.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(milestone.subtitle)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer()
                if let streakCount = milestone.streakCount {
                    AtlasStatusBadge(
                        "\(streakCount) streak",
                        tint: tint
                    )
                } else {
                    AtlasStatusBadge(
                        milestone.isEarned ? "Active" : "Optional",
                        tint: tint
                    )
                }
            }

            Text(milestone.helperText)
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
        .padding(.vertical, 2)
    }

    private var tint: Color {
        switch milestone.tone {
        case .complete:
            return AtlasPalette.success
        case .inProgress:
            return AtlasPalette.primary
        case .neutral:
            return AtlasPalette.textSecondary
        }
    }
}
