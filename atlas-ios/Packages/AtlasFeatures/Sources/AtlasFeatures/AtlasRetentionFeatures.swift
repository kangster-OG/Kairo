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
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text("\(snapshot.earnedMilestoneCount) of \(snapshot.milestones.count) calm signals are active.")
                        .atlasTextRole(.supporting)
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
                .atlasTextRole(.supporting)
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

                    ForEach(snapshot.milestones) { milestone in
                        AtlasRetentionMilestoneRow(milestone: milestone)
                    }

                    if weeklyReviewMilestone?.isEarned == false {
                        Button("Mark this week reviewed") {
                            Task { await model.markWeeklyReviewComplete() }
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                    }
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
                .atlasTextRole(.deckEyebrow)
                .foregroundStyle(AtlasPalette.primary)

            AtlasRetentionCompanionView(companion: companion, mascotSelection: mascotSelection, emphasis: .featured)

            Text(caption)
                .atlasTextRole(.supporting)
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
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.white.opacity(0.94))
                        .frame(width: emphasis == .featured ? 28 : 24, height: emphasis == .featured ? 28 : 24)
                        .overlay(
                            Image(systemName: companion.systemImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: emphasis == .featured ? 11 : 10, height: emphasis == .featured ? 11 : 10)
                                .foregroundStyle(companionTint)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(companionTint.opacity(0.16), lineWidth: 1)
                        )
                        .padding(emphasis == .featured ? 8 : 6)
                }

            VStack(alignment: .leading, spacing: emphasis == .featured ? 6 : 4) {
                Text("Companion")
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(companionTint)
                Text(companion.title)
                    .atlasTextRole(emphasis == .featured ? .cardTitle : .cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(companion.subtitle)
                    .atlasTextRole(.supporting)
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
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AtlasPalette.surfaceTop, companionTint.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
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
        .atlasTextRole(.deckEyebrow)
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
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(milestone.subtitle)
                        .atlasTextRole(.supporting)
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
                .atlasTextRole(.supporting)
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
