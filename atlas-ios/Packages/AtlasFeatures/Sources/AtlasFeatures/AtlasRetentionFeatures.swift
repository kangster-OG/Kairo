import AtlasDesignSystem
import AtlasDomain
import SwiftUI

struct AtlasRetentionTodayCard: View {
    let model: AtlasAppModel
    let snapshot: AtlasRetentionSnapshot
    let mascotSelection: AtlasMascotSelection

    var body: some View {
        AtlasSectionCard {
            if let companion = snapshot.companion {
                AtlasRetentionCompanionView(companion: companion, mascotSelection: mascotSelection, emphasis: .featured)
            }

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    Text("Optional local continuity")
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
    let mascotSelection: AtlasMascotSelection

    var body: some View {
        if snapshot.settings.progressEnabled {
            Section("Calm continuity") {
                AtlasSectionCard {
                    if let companion = snapshot.companion {
                        AtlasRetentionCompanionView(companion: companion, mascotSelection: mascotSelection, emphasis: .inline)
                    }

                    Text("These signals stay descriptive, local, and low-pressure. They describe continuity rather than score it, and they never ask you to fill in logs that did not happen.")
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
    let mascotSelection: AtlasMascotSelection
    let title: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AtlasPalette.primary)
                .textCase(.uppercase)

            AtlasRetentionCompanionView(companion: companion, mascotSelection: mascotSelection, emphasis: .featured)

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
    let mascotSelection: AtlasMascotSelection
    let emphasis: AtlasRetentionCompanionEmphasis

    var body: some View {
        HStack(alignment: .center, spacing: AtlasSpacing.medium) {
            RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous)
                .fill(companionTint.opacity(emphasis == .featured ? 0.12 : 0.08))
                .frame(width: iconDimension, height: iconDimension)
                .overlay(
                    RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous)
                        .stroke(companionTint.opacity(0.18), lineWidth: 1)
                )
                .overlay(
                    AtlasMascotSprite(
                        line: atlasMascotLine(for: mascotSelection),
                        stage: atlasRetentionMascotStage(for: companion),
                        pose: atlasRetentionMascotPose(for: companion),
                        size: emphasis == .featured ? 76 : 58
                    )
                )
                .overlay(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.94))
                        .frame(width: emphasis == .featured ? 28 : 24, height: emphasis == .featured ? 28 : 24)
                        .overlay(
                            Image(systemName: companion.systemImage)
                                .font(.system(size: emphasis == .featured ? 11 : 10, weight: .semibold))
                                .foregroundStyle(companionTint)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(companionTint.opacity(0.16), lineWidth: 1)
                        )
                        .padding(emphasis == .featured ? 8 : 6)
                }

            VStack(alignment: .leading, spacing: emphasis == .featured ? 6 : 4) {
                Text("Companion")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(companionTint)
                    .textCase(.uppercase)
                Text(companion.title)
                    .font((emphasis == .featured ? Font.title3 : Font.body).weight(.semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(companion.subtitle)
                    .font(emphasis == .featured ? .body : .callout)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(emphasis == .featured ? 16 : 0)
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

    private var iconDimension: CGFloat {
        emphasis == .featured ? 88 : 68
    }

    private var iconCornerRadius: CGFloat {
        emphasis == .featured ? 24 : 18
    }

    @ViewBuilder
    private var backgroundSurface: some View {
        if emphasis == .featured {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.96), companionTint.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(companionTint.opacity(0.14), lineWidth: 1)
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
            if let continuityLabel = milestone.continuityLabel {
                Text(continuityLabel)
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
                if let continuityLabel = milestone.continuityLabel {
                    AtlasStatusBadge(
                        continuityLabel,
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
