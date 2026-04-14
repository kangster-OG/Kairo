import AtlasDesignSystem
import AtlasDomain
import SwiftUI

enum AtlasMascotLine {
    case aetherion
    case aurielle
}

func atlasMascotLine(for selection: AtlasMascotSelection) -> AtlasMascotLine {
    switch selection {
    case .aetherion:
        return .aetherion
    case .aurielle:
        return .aurielle
    }
}

enum AtlasMascotPose {
    case idle
    case happy
    case recovery
    case evolutionReady
    case milestone
    case rest

    init(sharedPose: AtlasSharedMascotPose) {
        switch sharedPose {
        case .idle:
            self = .idle
        case .happy:
            self = .happy
        case .recovery:
            self = .recovery
        case .evolutionReady:
            self = .evolutionReady
        case .milestone:
            self = .milestone
        case .rest:
            self = .rest
        }
    }

    var usesHappyAsset: Bool {
        switch self {
        case .happy, .evolutionReady, .milestone:
            return true
        case .idle, .recovery, .rest:
            return false
        }
    }
}

public struct AtlasMascotCelebrationState: Identifiable, Equatable, Sendable {
    let selection: AtlasMascotSelection
    let stage: AtlasMascotStage
    let totalPoints: Int
    let earnedAt: Date

    public var id: String {
        "\(selection.rawValue)-\(stage.rawValue)-\(earnedAt.timeIntervalSince1970)"
    }
}

struct AtlasMascotEvolutionProgress {
    let stage: AtlasMascotStage
    let currentFormName: String
    let nextFormName: String?
    let nextThresholdPoints: Int?
    let stageFloorPoints: Int
    fileprivate let totalPoints: Int
    fileprivate let selection: AtlasMascotSelection

    var milestoneHeadline: String {
        guard let nextFormName, let nextThresholdPoints else {
            return "\(currentFormName) has reached its final evolution."
        }
        return "\(currentFormName) evolves into \(nextFormName) at \(atlasMascotPointLabel(nextThresholdPoints))."
    }

    var progressLabel: String {
        guard let nextFormName, let nextThresholdPoints else {
            return "Final form unlocked."
        }

        let remainingPoints = max(nextThresholdPoints - totalPoints, 0)
        return "\(remainingPoints) points to \(nextFormName)."
    }

    var stageBadge: String {
        switch stage {
        case .stage1:
            return "Form 1"
        case .stage2:
            return "Form 2"
        case .stage3:
            return "Final form"
        }
    }

    var progressFraction: Double? {
        guard let nextThresholdPoints else {
            return nil
        }

        let span = max(nextThresholdPoints - stageFloorPoints, 1)
        let progressed = max(min(totalPoints - stageFloorPoints, span), 0)
        return Double(progressed) / Double(span)
    }

    var celebrationHeadline: String {
        switch stage {
        case .stage1:
            return "\(currentFormName) has joined Atlas."
        case .stage2:
            return "\(selection.stage1Title) evolved into \(currentFormName)."
        case .stage3:
            return "\(selection.stage2Title) evolved into \(currentFormName)."
        }
    }

    var celebrationBody: String {
        switch stage {
        case .stage1:
            return "\(currentFormName) now reflects your Atlas journey and will evolve as rewards milestones are reached."
        case .stage2:
            return "Rewards crossed \(atlasMascotPointLabel(AtlasMascotMilestone.stage2Points)), unlocking the second form."
        case .stage3:
            return "Rewards crossed \(atlasMascotPointLabel(AtlasMascotMilestone.stage3Points)), unlocking the final guardian form."
        }
    }
}

struct AtlasMascotProfileSummary {
    let displayName: String
    let currentFormName: String
    let nickname: String?
    let statusLine: String
    let reaction: AtlasMascotReactionSummary?
}

func atlasMascotProfileSummary(
    selection: AtlasMascotSelection,
    nickname: String?,
    rewardsSnapshot: AtlasRewardsSnapshot,
    history: [AtlasMascotEvolutionRecord]
) -> AtlasMascotProfileSummary {
    let stage = atlasRewardsMascotStage(for: rewardsSnapshot)
    let cleanNickname = atlasMascotSanitizedNickname(nickname)
    return AtlasMascotProfileSummary(
        displayName: atlasMascotDisplayName(selection: selection, stage: stage, nickname: cleanNickname),
        currentFormName: selection.title(for: stage),
        nickname: cleanNickname,
        statusLine: atlasMascotStatusLine(
            selection: selection,
            nickname: cleanNickname,
            rewardsSnapshot: rewardsSnapshot
        ),
        reaction: atlasMascotReactionSummary(
            selection: selection,
            nickname: cleanNickname,
            rewardsSnapshot: rewardsSnapshot,
            history: history
        )
    )
}

struct AtlasMascotSprite: View {
    let line: AtlasMascotLine
    let stage: AtlasMascotStage
    let pose: AtlasMascotPose
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(assetName)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .saturation(pose == .rest ? 0.72 : 1)
                .opacity(pose == .rest ? 0.9 : 1)
                .scaleEffect(scaleEffect)
                .offset(y: yOffset)
                .overlay(alignment: .center) {
                    poseHalo
                }
                .frame(width: size, height: size)

            if let badgeSymbol {
                Image(systemName: badgeSymbol)
                    .font(.system(size: max(size * 0.15, 12), weight: .bold))
                    .foregroundStyle(badgeTint)
                    .padding(max(size * 0.06, 6))
                    .background(
                        Circle()
                            .fill(.white.opacity(0.92))
                    )
                    .offset(x: max(size * 0.02, 2), y: min(-size * 0.04, -4))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var assetName: String {
        switch (line, stage, pose.usesHappyAsset) {
        case (.aetherion, .stage1, false):
            return "AtlasMascotAetherionStage1Idle"
        case (.aetherion, .stage1, true):
            return "AtlasMascotAetherionStage1Happy"
        case (.aetherion, .stage2, false):
            return "AtlasMascotAetherionStage2Idle"
        case (.aetherion, .stage2, true):
            return "AtlasMascotAetherionStage2Happy"
        case (.aetherion, .stage3, false):
            return "AtlasMascotAetherionStage3Idle"
        case (.aetherion, .stage3, true):
            return "AtlasMascotAetherionStage3Happy"
        case (.aurielle, .stage1, false):
            return "AtlasMascotAurielleStage1Idle"
        case (.aurielle, .stage1, true):
            return "AtlasMascotAurielleStage1Happy"
        case (.aurielle, .stage2, false):
            return "AtlasMascotAurielleStage2Idle"
        case (.aurielle, .stage2, true):
            return "AtlasMascotAurielleStage2Happy"
        case (.aurielle, .stage3, false):
            return "AtlasMascotAurielleStage3Idle"
        case (.aurielle, .stage3, true):
            return "AtlasMascotAurielleStage3Happy"
        }
    }

    private var yOffset: CGFloat {
        switch pose {
        case .happy, .milestone:
            return -2
        case .evolutionReady:
            return -3
        case .recovery:
            return 1
        case .rest, .idle:
            return 0
        }
    }

    private var scaleEffect: CGFloat {
        switch pose {
        case .milestone:
            return 1.04
        case .evolutionReady:
            return 1.03
        default:
            return 1
        }
    }

    @ViewBuilder
    private var poseHalo: some View {
        switch pose {
        case .milestone:
            Circle()
                .stroke(AtlasPalette.primary.opacity(0.24), lineWidth: max(size * 0.03, 2))
                .padding(size * 0.14)
        case .evolutionReady:
            Circle()
                .stroke(Color.yellow.opacity(0.28), style: StrokeStyle(lineWidth: max(size * 0.028, 2), dash: [6, 6]))
                .padding(size * 0.12)
        case .recovery:
            Circle()
                .fill(Color.clear)
        case .rest, .idle, .happy:
            EmptyView()
        }
    }

    private var badgeSymbol: String? {
        switch pose {
        case .recovery:
            return "arrow.clockwise.circle.fill"
        case .evolutionReady:
            return "sparkles"
        case .milestone:
            return "rosette"
        case .rest:
            return "moon.zzz.fill"
        case .idle, .happy:
            return nil
        }
    }

    private var badgeTint: Color {
        switch pose {
        case .recovery:
            return AtlasPalette.primary
        case .evolutionReady:
            return .yellow
        case .milestone:
            return .orange
        case .rest:
            return .indigo
        case .idle, .happy:
            return AtlasPalette.primary
        }
    }
}

struct AtlasMascotIllustration: View {
    let line: AtlasMascotLine
    let stage: AtlasMascotStage
    let size: CGFloat

    var body: some View {
        Image(assetName)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .shadow(color: Color.black.opacity(0.08), radius: max(size * 0.06, 4), y: max(size * 0.02, 2))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private var assetName: String {
        switch (line, stage) {
        case (.aetherion, .stage1):
            return "AtlasMascotAetherionStage1"
        case (.aetherion, .stage2):
            return "AtlasMascotAetherionStage2"
        case (.aetherion, .stage3):
            return "AtlasMascotAetherionStage3"
        case (.aurielle, .stage1):
            return "AtlasMascotAurielleStage1"
        case (.aurielle, .stage2):
            return "AtlasMascotAurielleStage2"
        case (.aurielle, .stage3):
            return "AtlasMascotAurielleStage3"
        }
    }
}

private struct AtlasInteractiveMascotIllustration: View {
    let selection: AtlasMascotSelection
    let nickname: String?
    let line: AtlasMascotLine
    let stage: AtlasMascotStage
    let size: CGFloat

    @State private var isPressed = false
    @State private var response: AtlasMascotReactionSummary?

    var body: some View {
        let liveResponse = atlasMascotInteractionResponse(
            selection: selection,
            stage: stage,
            nickname: nickname
        )

        VStack(spacing: AtlasSpacing.small) {
            Button {
                AtlasFeedback.impact(.light)
                response = liveResponse
                withAnimation(.spring(response: 0.24, dampingFraction: 0.58)) {
                    isPressed = true
                }

                Task {
                    try? await Task.sleep(for: .milliseconds(240))
                    await MainActor.run {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            isPressed = false
                        }
                    }
                }

                Task {
                    try? await Task.sleep(for: .seconds(2.4))
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.25)) {
                            response = nil
                        }
                    }
                }
            } label: {
                AtlasMascotIllustration(
                    line: line,
                    stage: stage,
                    size: size
                )
                .scaleEffect(isPressed ? 1.06 : 1)
                .rotationEffect(.degrees(isPressed ? -2 : 0))
                .shadow(color: AtlasPalette.primary.opacity(isPressed ? 0.22 : 0), radius: 18, y: 10)
            }
            .buttonStyle(.plain)

            if let response {
                Label(response.title, systemImage: response.symbolName)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(AtlasPalette.secondaryFill)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

struct AtlasMascotHomeCard: View {
    let selection: AtlasMascotSelection
    let nickname: String?
    let rewardsSnapshot: AtlasRewardsSnapshot
    let history: [AtlasMascotEvolutionRecord]
    let moments: [AtlasMascotMomentRecord]
    var historyLimit: Int? = 3
    var compact: Bool = false
    var onRecordMoment: (() -> Void)? = nil
    var onOpenDetail: (() -> Void)? = nil

    var body: some View {
        let evolution = atlasRewardsEvolutionProgress(for: rewardsSnapshot, selection: selection)
        let line = atlasMascotLine(for: selection)
        let profile = atlasMascotProfileSummary(
            selection: selection,
            nickname: nickname,
            rewardsSnapshot: rewardsSnapshot,
            history: history
        )

        AtlasSectionCard(style: .reward) {
            HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    HStack(spacing: AtlasSpacing.small) {
                        Text("\(selection.title) home")
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)

                        AtlasStatusBadge(evolution.stageBadge, tint: AtlasPalette.primary)
                    }

                    Text(profile.displayName)
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(AtlasPalette.textPrimary)

                    if profile.nickname != nil {
                        Text(profile.currentFormName)
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.primary)
                    }

                    Text(profile.statusLine)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    Text(evolution.milestoneHeadline)
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.primary)

                    Text(evolution.progressLabel)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                Spacer(minLength: 0)

                homeIllustration(
                    selection: selection,
                    line: line,
                    stage: evolution.stage
                )
            }

            AtlasMetricStrip(
                metrics: atlasMascotMetrics(
                    rewardsSnapshot: rewardsSnapshot,
                    historyCount: filteredHistory.count,
                    momentsCount: moments.filter { $0.selection == selection }.count,
                    stageBadge: evolution.stageBadge
                )
            )

            if compact == false, let reaction = profile.reaction {
                AtlasMascotReactionStrip(reaction: reaction)
            }

            if compact == false, let latestMoment {
                AtlasMascotMomentHighlight(moment: latestMoment)
            }

            if let progressFraction = evolution.progressFraction {
                AtlasProgressMeter(
                    title: "Evolution",
                    detail: "\(rewardsSnapshot.totalPoints) total points • \(evolution.progressLabel)",
                    value: progressFraction,
                    tint: AtlasPalette.reward
                )
            } else {
                Text("All mascot evolution milestones are now unlocked for this line.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            if compact {
                if let onOpenDetail {
                    Button("Open mascot detail") {
                        AtlasFeedback.selection()
                        onOpenDetail()
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            } else if let onRecordMoment {
                Button("Capture mascot moment") {
                    AtlasFeedback.selection()
                    onRecordMoment()
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
            }

            if compact == false {
                VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                    Text("Evolution history")
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.primary)

                    if displayedHistory.isEmpty {
                        Text("No evolution unlocks recorded yet. Keep stacking rewards to reach the next form.")
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    } else {
                        ForEach(displayedHistory) { entry in
                            HStack(alignment: .top, spacing: AtlasSpacing.small) {
                                AtlasStatusBadge(entry.selection.title(for: entry.stage), tint: AtlasPalette.success)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entryLabel(for: entry))
                                        .atlasTextRole(.deckEyebrow)
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                    Text(entryDateLabel(for: entry))
                                        .atlasTextRole(.metricLabel)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }

                                Spacer(minLength: 0)
                            }
                        }
                    }
                }

                if let onOpenDetail {
                    Button("Open mascot detail") {
                        AtlasFeedback.selection()
                        onOpenDetail()
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private func homeIllustration(
        selection: AtlasMascotSelection,
        line: AtlasMascotLine,
        stage: AtlasMascotStage
    ) -> some View {
        if compact, let onOpenDetail {
            Button {
                AtlasFeedback.selection()
                onOpenDetail()
            } label: {
                AtlasMascotIllustration(
                    line: line,
                    stage: stage,
                    size: 96
                )
                .padding(4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open mascot detail")
        } else {
            AtlasInteractiveMascotIllustration(
                selection: selection,
                nickname: nickname,
                line: line,
                stage: stage,
                size: compact ? 96 : 112
            )
        }
    }

    private var filteredHistory: [AtlasMascotEvolutionRecord] {
        history.filter { $0.selection == selection }
    }

    private var latestMoment: AtlasMascotMomentRecord? {
        moments.first(where: { $0.selection == selection })
    }

    private var displayedHistory: [AtlasMascotEvolutionRecord] {
        guard let historyLimit else {
            return filteredHistory
        }
        return Array(filteredHistory.prefix(historyLimit))
    }

    private func entryLabel(for entry: AtlasMascotEvolutionRecord) -> String {
        switch entry.stage {
        case .stage1:
            return "\(entry.selection.title(for: entry.stage)) joined Atlas"
        case .stage2:
            return "\(entry.selection.stage1Title) evolved into \(entry.selection.stage2Title)"
        case .stage3:
            return "\(entry.selection.stage2Title) evolved into \(entry.selection.stage3Title)"
        }
    }

    private func entryDateLabel(for entry: AtlasMascotEvolutionRecord) -> String {
        guard let date = atlasMascotHistoryDate(from: entry.earnedAt) else {
            return entry.earnedAt
        }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct AtlasMascotMomentHighlight: View {
    let moment: AtlasMascotMomentRecord

    var body: some View {
        AtlasCalloutRow(
            systemImage: moment.symbolName,
            title: "Latest moment",
            detail: "\(moment.title) • \(moment.detail)",
            tint: AtlasPalette.primary,
            badge: atlasMascotMomentDateLabel(moment.recordedAt)
        )
    }
}

private struct AtlasMascotReactionStrip: View {
    let reaction: AtlasMascotReactionSummary

    var body: some View {
        AtlasCalloutRow(
            systemImage: reaction.symbolName,
            title: reaction.title,
            detail: reaction.detail,
            tint: AtlasPalette.reward
        )
    }
}

private struct AtlasMascotMomentsJournalCard: View {
    let selection: AtlasMascotSelection
    let moments: [AtlasMascotMomentRecord]
    var limit: Int? = nil

    var body: some View {
        AtlasSectionCard {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                Text("Mascot moments")
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.primary)

                if displayedMoments.isEmpty {
                    Text("No mascot moments yet. Tap the mascot, close goals, or use the new shortcut check-ins to start filling the journal.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(displayedMoments) { moment in
                        HStack(alignment: .top, spacing: AtlasSpacing.small) {
                            Image(systemName: moment.symbolName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundStyle(AtlasPalette.primary)
                                .frame(width: 28, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(AtlasPalette.secondaryFill)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(moment.title)
                                    .atlasTextRole(.deckEyebrow)
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Text(moment.detail)
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                Text(atlasMascotMomentDateLabel(moment.recordedAt))
                                    .atlasTextRole(.metricLabel)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private var displayedMoments: [AtlasMascotMomentRecord] {
        let filtered = moments.filter { $0.selection == selection }
        guard let limit else {
            return filtered
        }
        return Array(filtered.prefix(limit))
    }
}

struct AtlasMascotCelebrationSheet: View {
    let celebration: AtlasMascotCelebrationState
    let onDismiss: () -> Void

    var body: some View {
        let evolution = atlasRewardsEvolutionProgress(
            for: AtlasRewardsSnapshot(totalPoints: celebration.totalPoints),
            selection: celebration.selection
        )
        let metrics = [
            AtlasMetricItem(id: "points", title: "Points", value: "\(celebration.totalPoints)", tint: AtlasPalette.reward),
            AtlasMetricItem(id: "form", title: "Form", value: celebration.selection.title(for: celebration.stage), tint: AtlasPalette.primary),
            AtlasMetricItem(
                id: "next",
                title: "Next unlock",
                value: evolution.nextFormName ?? "Final form",
                tint: evolution.nextFormName == nil ? AtlasPalette.success : AtlasPalette.secondaryText
            )
        ]

        VStack(spacing: AtlasSpacing.large) {
            Capsule(style: .continuous)
                .fill(AtlasPalette.surfaceSecondary)
                .frame(width: 42, height: 5)
                .padding(.top, 8)

            AtlasMascotIllustration(
                line: atlasMascotLine(for: celebration.selection),
                stage: celebration.stage,
                size: 184
            )

            AtlasCommandDeck(
                eyebrow: "Evolution unlocked",
                title: evolution.celebrationHeadline,
                detail: evolution.celebrationBody,
                metrics: metrics,
                tint: AtlasPalette.reward,
                style: .reward
            ) {
                Button("Continue") {
                    AtlasFeedback.notify(.success)
                    onDismiss()
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
            } footer: {
                if let nextFormName = evolution.nextFormName,
                   let nextThresholdPoints = evolution.nextThresholdPoints {
                    AtlasCalloutRow(
                        systemImage: "sparkles",
                        title: "Next milestone",
                        detail: "\(nextFormName) unlocks at \(atlasMascotPointLabel(nextThresholdPoints)).",
                        tint: AtlasPalette.reward
                    )
                } else {
                    AtlasCalloutRow(
                        systemImage: "crown.fill",
                        title: "Final guardian form",
                        detail: "This mascot line has reached its highest evolution stage.",
                        tint: AtlasPalette.success
                    )
                }
            }

            Spacer(minLength: 0)
        }
        .padding(AtlasSpacing.large)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .task {
            AtlasFeedback.notify(.success)
        }
    }
}

struct AtlasMascotConfirmationCard: View {
    let bootstrapReason: AtlasBootstrapReason
    let currentSelection: AtlasMascotSelection
    let onChoose: (AtlasMascotSelection) -> Void

    var body: some View {
        AtlasSectionCard(style: .utility, title: "Choose your Atlas mascot") {
            Text(detailText)
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)

            HStack(alignment: .top, spacing: AtlasSpacing.small) {
                ForEach(AtlasMascotSelection.allCases, id: \.self) { selection in
                    mascotChoice(for: selection)
                }
            }

            Text("This only needs to happen once. You can always switch lines later in Settings.")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
    }

    private var detailText: String {
        switch bootstrapReason {
        case .importedLocalUser:
            return "Atlas found imported local history and picked a starting line so the companion layer can begin in context. Keep it or switch it now."
        case .existingLocalUser:
            return "Atlas found an existing local setup and picked a starting line so the mascot layer has a calm default. Confirm it once or switch it now."
        default:
            return "Pick the mascot line you want Atlas to carry across rewards, calm continuity, and companion previews."
        }
    }

    private func mascotChoice(for selection: AtlasMascotSelection) -> some View {
        Button {
            AtlasFeedback.selection()
            onChoose(selection)
        } label: {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                AtlasMascotIllustration(
                    line: atlasMascotLine(for: selection),
                    stage: .stage3,
                    size: 84
                )

                Text(selection.title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)

                Text(selection.subtitle)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                AtlasStatusBadge(
                    selection == currentSelection ? "Current choice" : "Choose",
                    tint: selection == currentSelection ? AtlasPalette.success : AtlasPalette.primary
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: selection == currentSelection
                                ? [Color.white.opacity(0.98), AtlasPalette.secondaryFill]
                                : [Color.white.opacity(0.96), AtlasPalette.surfaceSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selection == currentSelection ? AtlasPalette.primary.opacity(0.45) : Color.white.opacity(0.82), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AtlasMascotEvolutionPathCard: View {
    let selection: AtlasMascotSelection
    let currentStage: AtlasMascotStage
    let unlockedStage: AtlasMascotStage

    var body: some View {
        AtlasSectionCard(style: .utility, title: "Evolution path") {
            Text("Rewards milestones permanently unlock each form, while Atlas keeps the same guardian identity across the entire line.")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AtlasSpacing.medium) {
                    ForEach(AtlasMascotStage.allCases, id: \.self) { stage in
                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            AtlasMascotIllustration(
                                line: atlasMascotLine(for: selection),
                                stage: stage,
                                size: 104
                            )

                            Text(selection.title(for: stage))
                                .atlasTextRole(.cardBody)
                                .foregroundStyle(AtlasPalette.textPrimary)

                            Text(stageCopy(for: stage))
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                                .lineLimit(2)

                            AtlasStatusBadge(stageBadge(for: stage), tint: stageTint(for: stage))
                        }
                        .frame(width: 180, alignment: .leading)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(stage == currentStage ? AtlasPalette.secondaryFill : Color.white.opacity(0.94))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(stage == currentStage ? AtlasPalette.primary.opacity(0.45) : Color.white.opacity(0.82), lineWidth: 1)
                        )
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func stageBadge(for stage: AtlasMascotStage) -> String {
        if stage == currentStage {
            return "Current form"
        }
        if stage.rank <= unlockedStage.rank {
            return "Unlocked"
        }
        switch stage {
        case .stage1:
            return "Starting form"
        case .stage2:
            return "Unlocks at \(atlasMascotPointLabel(AtlasMascotMilestone.stage2Points))"
        case .stage3:
            return "Unlocks at \(atlasMascotPointLabel(AtlasMascotMilestone.stage3Points))"
        }
    }

    private func stageTint(for stage: AtlasMascotStage) -> Color {
        if stage == currentStage {
            return AtlasPalette.primary
        }
        return stage.rank <= unlockedStage.rank ? AtlasPalette.success : AtlasPalette.secondaryText
    }

    private func stageCopy(for stage: AtlasMascotStage) -> String {
        switch stage {
        case .stage1:
            return "Starting form with clear potential and a compact identity."
        case .stage2:
            return "Mid-journey evolution that appears once rewards cross the second milestone."
        case .stage3:
            return "Final guardian form with the full premium portrait treatment and permanent unlock."
        }
    }
}

private func atlasMascotMetrics(
    rewardsSnapshot: AtlasRewardsSnapshot,
    historyCount: Int,
    momentsCount: Int,
    stageBadge: String
) -> [AtlasMetricItem] {
    [
        .init(id: "stage", title: "Stage", value: stageBadge, tint: AtlasPalette.reward),
        .init(id: "points", title: "Points", value: "\(rewardsSnapshot.totalPoints)", tint: AtlasPalette.primary),
        .init(id: "history", title: "Unlocks", value: "\(historyCount)", tint: AtlasPalette.success),
        .init(id: "moments", title: "Moments", value: "\(momentsCount)", tint: AtlasPalette.secondaryText)
    ]
}

public struct AtlasMascotDetailScreen: View {
    let model: AtlasAppModel
    @State private var shareArtifact: AtlasMascotExportArtifact?
    @State private var exportErrorMessage: String?
    @State private var recapAudience: AtlasMascotRecapAudience = .personal
    @State private var recapPrivacyMode: AtlasMascotRecapPrivacyMode = .fullDetail

    public init(model: AtlasAppModel) {
        self.model = model
    }

    public var body: some View {
        let selection = model.settingsSnapshot.mascotSelection
        let nickname = model.settingsSnapshot.mascotNickname
        let rewardsSnapshot = model.rewardsSnapshot
        let evolution = atlasRewardsEvolutionProgress(for: rewardsSnapshot, selection: selection)
        let unlockedStage = model.settingsSnapshot.highestUnlockedStage(for: selection)
        let history = model.settingsSnapshot.mascotEvolutionHistory
        let moments = model.settingsSnapshot.mascotMoments
        let archivedRecaps = model.settingsSnapshot.mascotArchivedRecaps.filter { $0.selection == selection }
        let profile = atlasMascotProfileSummary(
            selection: selection,
            nickname: nickname,
            rewardsSnapshot: rewardsSnapshot,
            history: history
        )

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                AtlasTabHeader(
                    title: profile.displayName,
                    subtitle: "See the active form, next target, larger portrait art, and the full recorded history for this mascot line."
                )

                AtlasSectionCard(style: .hero) {
                    VStack(alignment: .leading, spacing: AtlasSpacing.large) {
                        VStack(spacing: AtlasSpacing.small) {
                            AtlasInteractiveMascotIllustration(
                                selection: selection,
                                nickname: nickname,
                                line: atlasMascotLine(for: selection),
                                stage: evolution.stage,
                                size: 220
                            )
                            .frame(maxWidth: .infinity)
                        }

                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            AtlasStatusBadge(evolution.stageBadge, tint: AtlasPalette.primary)

                            Text(profile.displayName)
                                .atlasTextRole(.screenTitle)
                                .foregroundStyle(AtlasPalette.textPrimary)

                            if profile.nickname != nil {
                                Text(profile.currentFormName)
                                    .atlasTextRole(.cardBody)
                                    .foregroundStyle(AtlasPalette.primary)
                            } else {
                                Text(selection.subtitle)
                                    .atlasTextRole(.screenSubtitle)
                                    .foregroundStyle(AtlasPalette.primary)
                            }

                            Text(profile.statusLine)
                                .atlasTextRole(.screenSubtitle)
                                .foregroundStyle(AtlasPalette.textSecondary)

                            if profile.nickname != nil {
                                Text(selection.subtitle)
                                    .atlasTextRole(.deckEyebrow)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }

                            Text(evolution.milestoneHeadline)
                                .atlasTextRole(.screenSubtitle)
                                .foregroundStyle(AtlasPalette.textSecondary)

                            Text(evolution.progressLabel)
                                .atlasTextRole(.deckEyebrow)
                                .foregroundStyle(AtlasPalette.primary)

                            Text("\(rewardsSnapshot.totalPoints) total rewards points")
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }

                    if let reaction = profile.reaction {
                        AtlasMascotReactionStrip(reaction: reaction)
                    }

                    HStack(spacing: AtlasSpacing.medium) {
                        AtlasMascotSprite(
                            line: atlasMascotLine(for: selection),
                            stage: evolution.stage,
                            pose: atlasRewardsMascotPose(for: rewardsSnapshot),
                            size: 88
                        )

                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            Text("Pixel sprite state")
                                .atlasTextRole(.deckEyebrow)
                                .foregroundStyle(AtlasPalette.primary)
                            Text("The widget layer and compact surfaces use this live pixel state for the same current form.")
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }

                        Spacer(minLength: 0)
                    }
                }

                AtlasSectionCard(style: .elevated, title: "Shareable recap cards") {
                    VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                        Text("Create clean PNG recap cards for weekly momentum, evolution milestones, and the latest mascot moment.")
                            .atlasTextRole(.screenSubtitle)
                            .foregroundStyle(AtlasPalette.textSecondary)

                        Picker("Audience", selection: $recapAudience) {
                            ForEach(AtlasMascotRecapAudience.allCases, id: \.self) { audience in
                                Text(audience.title).tag(audience)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Privacy", selection: $recapPrivacyMode) {
                            ForEach(AtlasMascotRecapPrivacyMode.allCases, id: \.self) { privacyMode in
                                Text(privacyMode.title).tag(privacyMode)
                            }
                        }
                        .pickerStyle(.segmented)

                        ForEach(AtlasMascotRecapCardKind.allCases) { kind in
                            let descriptor = atlasMascotRecapDescriptor(
                                kind: kind,
                                audience: recapAudience,
                                privacyMode: recapPrivacyMode,
                                selection: selection,
                                nickname: nickname,
                                rewardsSnapshot: rewardsSnapshot,
                                evolutionHistory: history,
                                moments: moments
                            )

                            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                                AtlasMascotRecapPreviewCard(descriptor: descriptor)

                                HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                        Text(kind.title)
                                            .atlasTextRole(.cardBody)
                                            .foregroundStyle(AtlasPalette.textPrimary)
                                        Text(kind.subtitle)
                                            .atlasTextRole(.supporting)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }

                                    Spacer(minLength: 8)

                                    Button("Share PNG") {
                                        AtlasFeedback.selection()
                                        Task {
                                            await createMascotRecapExport(descriptor)
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(AtlasPalette.primary)
                                }
                            }
                        }
                    }
                }

                AtlasSectionCard(style: .elevated, title: "Archive gallery") {
                    VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                        Text("Every exported mascot recap stays collectible in Atlas so milestone posters and weekly cards can be re-shared later.")
                            .atlasTextRole(.screenSubtitle)
                            .foregroundStyle(AtlasPalette.textSecondary)

                        if archivedRecaps.isEmpty {
                            Text("No archived mascot recaps yet. Export a recap card above to start building the gallery.")
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        } else {
                            ForEach(archivedRecaps) { archivedRecap in
                                let archivedDescriptor = atlasMascotArchivedRecapDescriptor(archivedRecap)
                                VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                                    AtlasMascotRecapPreviewCard(descriptor: archivedDescriptor)

                                    HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                            Text(archivedDescriptor.headline)
                                                .atlasTextRole(.cardBody)
                                                .foregroundStyle(AtlasPalette.textPrimary)
                                                .lineLimit(2)
                                            Text(
                                                "\(archivedRecap.audience.title) • \(archivedRecap.privacyMode.title) • \(atlasMascotMomentDateLabel(archivedRecap.createdAt))"
                                            )
                                            .atlasTextRole(.supporting)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                        }

                                        Spacer(minLength: 8)

                                        Button("Share again") {
                                            AtlasFeedback.selection()
                                            Task {
                                                await shareArchivedRecap(archivedRecap)
                                            }
                                        }
                                        .buttonStyle(AtlasSecondaryButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                }

                AtlasMascotMomentsJournalCard(
                    selection: selection,
                    moments: moments
                )

                AtlasMascotEvolutionPathCard(
                    selection: selection,
                    currentStage: evolution.stage,
                    unlockedStage: unlockedStage
                )

                AtlasMascotHomeCard(
                    selection: selection,
                    nickname: nickname,
                    rewardsSnapshot: rewardsSnapshot,
                    history: history,
                    moments: moments,
                    historyLimit: nil,
                    onRecordMoment: {
                        Task {
                            await model.recordMascotInteractionMoment()
                        }
                    }
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 48)
        }
        .scrollIndicators(.hidden)
        .background(AtlasAppBackground())
        .navigationTitle(profile.displayName)
        .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
        .sheet(item: $shareArtifact) { artifact in
            AtlasMascotShareSheet(fileURL: artifact.fileURL)
        }
        .alert(
            "Mascot export unavailable",
            isPresented: Binding(
                get: { exportErrorMessage != nil },
                set: { isPresented in
                    if isPresented == false {
                        exportErrorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                AtlasFeedback.selection()
                exportErrorMessage = nil
            }
        } message: {
            Text(exportErrorMessage ?? "")
        }
    }

    @MainActor
    private func createMascotRecapExport(_ descriptor: AtlasMascotRecapDescriptor) async {
        do {
            shareArtifact = try await model.exportMascotRecapCard(descriptor)
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func shareArchivedRecap(_ recap: AtlasMascotArchivedRecapRecord) async {
        do {
            shareArtifact = AtlasMascotExportArtifact(
                descriptor: atlasMascotArchivedRecapDescriptor(recap),
                fileURL: try atlasMascotArchivedRecapFileURL(recap),
                archiveRecord: recap
            )
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }
}

func atlasShouldPromptForMascotConfirmation(
    bootstrapSnapshot: AtlasBootstrapSnapshot,
    settingsSnapshot: AtlasSettingsSnapshot
) -> Bool {
    guard bootstrapSnapshot.destination == .app,
          settingsSnapshot.onboardingCompleted,
          settingsSnapshot.mascotSelectionConfirmed == false else {
        return false
    }

    switch bootstrapSnapshot.reason {
    case .existingLocalUser, .importedLocalUser:
        return true
    case .firstRun, .resumedOnboarding, .completedOnboarding:
        return false
    }
}

func atlasRewardsEvolutionProgress(
    for snapshot: AtlasRewardsSnapshot,
    selection: AtlasMascotSelection
) -> AtlasMascotEvolutionProgress {
    let totalPoints = snapshot.totalPoints
    let stage = AtlasMascotMilestone.stage(for: totalPoints)

    if stage == .stage3 {
        return AtlasMascotEvolutionProgress(
            stage: .stage3,
            currentFormName: selection.stage3Title,
            nextFormName: nil,
            nextThresholdPoints: nil,
            stageFloorPoints: AtlasMascotMilestone.stage3Points,
            totalPoints: totalPoints,
            selection: selection
        )
    }

    if stage == .stage2 {
        return AtlasMascotEvolutionProgress(
            stage: .stage2,
            currentFormName: selection.stage2Title,
            nextFormName: selection.stage3Title,
            nextThresholdPoints: AtlasMascotMilestone.stage3Points,
            stageFloorPoints: AtlasMascotMilestone.stage2Points,
            totalPoints: totalPoints,
            selection: selection
        )
    }

    return AtlasMascotEvolutionProgress(
        stage: .stage1,
        currentFormName: selection.stage1Title,
        nextFormName: selection.stage2Title,
        nextThresholdPoints: AtlasMascotMilestone.stage2Points,
        stageFloorPoints: 0,
        totalPoints: totalPoints,
        selection: selection
    )
}

func atlasRewardsMascotStage(for snapshot: AtlasRewardsSnapshot) -> AtlasMascotStage {
    AtlasMascotMilestone.stage(for: snapshot.totalPoints)
}

func atlasRewardsMascotPose(for snapshot: AtlasRewardsSnapshot) -> AtlasMascotPose {
    AtlasMascotPose(sharedPose: atlasMascotSharedPose(rewardsSnapshot: snapshot))
}

func atlasRetentionMascotStage(for companion: AtlasRetentionCompanionSnapshot) -> AtlasMascotStage {
    switch companion.mood {
    case .quiet:
        return .stage1
    case .steady:
        return .stage2
    case .settled:
        return .stage3
    }
}

func atlasRetentionMascotPose(for companion: AtlasRetentionCompanionSnapshot) -> AtlasMascotPose {
    switch companion.mood {
    case .quiet:
        return .rest
    case .steady:
        return .happy
    case .settled:
        return .milestone
    }
}

private func atlasMascotPointLabel(_ points: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return "\(formatter.string(from: NSNumber(value: points)) ?? "\(points)") points"
}

private func atlasMascotHistoryDate(from timestamp: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: timestamp)
}

private func atlasMascotMomentDateLabel(_ timestamp: String) -> String {
    guard let date = atlasMascotHistoryDate(from: timestamp) else {
        return timestamp
    }
    return date.formatted(date: .abbreviated, time: .shortened)
}
