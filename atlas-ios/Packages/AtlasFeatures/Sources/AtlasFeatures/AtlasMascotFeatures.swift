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

func atlasMascotLineTint(for selection: AtlasMascotSelection) -> Color {
    switch selection {
    case .aetherion:
        return Color(red: 0.16, green: 0.42, blue: 0.96)
    case .aurielle:
        return Color(red: 0.39, green: 0.69, blue: 0.96)
    }
}

func atlasMascotLineHighlight(for selection: AtlasMascotSelection) -> Color {
    switch selection {
    case .aetherion:
        return Color(red: 0.95, green: 0.74, blue: 0.34)
    case .aurielle:
        return Color(red: 0.87, green: 0.95, blue: 1.00)
    }
}

func atlasMascotLineSymbol(for selection: AtlasMascotSelection) -> String {
    switch selection {
    case .aetherion:
        return "bolt.circle.fill"
    case .aurielle:
        return "moon.stars.fill"
    }
}

func atlasMascotStageFlavor(
    for selection: AtlasMascotSelection,
    stage: AtlasMascotStage
) -> String {
    switch (selection, stage) {
    case (.aetherion, .stage1):
        return "Compressed storm energy, oversized forearms, and a scrappy guardian spark."
    case (.aetherion, .stage2):
        return "Faster wings, sharper lines, and a more disciplined kinetic stance."
    case (.aetherion, .stage3):
        return "Ceremonial wings, halo framing, and the full guardian silhouette."
    case (.aurielle, .stage1):
        return "Soft proportions, bright charm, and a first-light companion presence."
    case (.aurielle, .stage2):
        return "Longer rhythm, ribbon-like ears, and visible skybound motion."
    case (.aurielle, .stage3):
        return "Regal posture, celestial flow, and the complete sky guardian silhouette."
    }
}

struct AtlasMascotArtDirection {
    let lineTitle: String
    let lineMotto: String
    let stageLabel: String
    let stageHeadline: String
    let portraitNote: String
    let posterKicker: String
    let ornamentSymbol: String
    let portraitSize: CGFloat
    let portraitHaloSize: CGFloat
    let portraitOffsetY: CGFloat
    let portraitChipOffset: CGSize
    let posterArtSize: CGFloat
    let posterArtOffset: CGSize
    let posterHaloSize: CGFloat
    let posterFrameSize: CGSize
}

func atlasMascotArtDirection(
    for selection: AtlasMascotSelection,
    stage: AtlasMascotStage
) -> AtlasMascotArtDirection {
    switch (selection, stage) {
    case (.aetherion, .stage1):
        return AtlasMascotArtDirection(
            lineTitle: "Aetherion line",
            lineMotto: "Storm-forged drake guardian",
            stageLabel: "Stage I",
            stageHeadline: "Compressed potential",
            portraitNote: "Keep the portrait tight, low, and powerful so Cindlet reads as compact stored energy rather than a tiny pet.",
            posterKicker: "Low-angle starter silhouette with a bright chest core and compact storm aura.",
            ornamentSymbol: "bolt.badge.clock",
            portraitSize: 212,
            portraitHaloSize: 248,
            portraitOffsetY: 8,
            portraitChipOffset: CGSize(width: 0, height: 12),
            posterArtSize: 344,
            posterArtOffset: CGSize(width: 6, height: 20),
            posterHaloSize: 270,
            posterFrameSize: CGSize(width: 372, height: 360)
        )
    case (.aetherion, .stage2):
        return AtlasMascotArtDirection(
            lineTitle: "Aetherion line",
            lineMotto: "Storm-forged drake guardian",
            stageLabel: "Stage II",
            stageHeadline: "Kinetic discipline",
            portraitNote: "Let the wings and tail carve a strong diagonal so Voltflare feels athletic, faster, and more deliberate.",
            posterKicker: "Diagonal wing rhythm with a cleaner stride and brighter cobalt seam lighting.",
            ornamentSymbol: "bolt.horizontal.circle",
            portraitSize: 234,
            portraitHaloSize: 270,
            portraitOffsetY: 0,
            portraitChipOffset: CGSize(width: 8, height: 8),
            posterArtSize: 400,
            posterArtOffset: CGSize(width: 16, height: 6),
            posterHaloSize: 310,
            posterFrameSize: CGSize(width: 404, height: 392)
        )
    case (.aetherion, .stage3):
        return AtlasMascotArtDirection(
            lineTitle: "Aetherion line",
            lineMotto: "Storm-forged drake guardian",
            stageLabel: "Stage III",
            stageHeadline: "Ceremonial authority",
            portraitNote: "Give the final guardian extra air above the horns and ring so the silhouette reads as mythic rather than merely large.",
            posterKicker: "Ceremonial wing spread, halo framing, and anchored guardian posture.",
            ornamentSymbol: "sparkles.rectangle.stack",
            portraitSize: 248,
            portraitHaloSize: 292,
            portraitOffsetY: -6,
            portraitChipOffset: CGSize(width: 12, height: 0),
            posterArtSize: 462,
            posterArtOffset: CGSize(width: 12, height: -8),
            posterHaloSize: 350,
            posterFrameSize: CGSize(width: 430, height: 432)
        )
    case (.aurielle, .stage1):
        return AtlasMascotArtDirection(
            lineTitle: "Aurielle line",
            lineMotto: "Aurora hare guardian",
            stageLabel: "Stage I",
            stageHeadline: "Bright first light",
            portraitNote: "Keep Moppet centered and upright with lots of breathing room so the softness feels premium instead of overly cute.",
            posterKicker: "Rounded silhouette, pearl chest mark, and airy crescent framing.",
            ornamentSymbol: "moonphase.waning.crescent",
            portraitSize: 204,
            portraitHaloSize: 240,
            portraitOffsetY: 10,
            portraitChipOffset: CGSize(width: -4, height: 12),
            posterArtSize: 332,
            posterArtOffset: CGSize(width: -6, height: 18),
            posterHaloSize: 262,
            posterFrameSize: CGSize(width: 370, height: 354)
        )
    case (.aurielle, .stage2):
        return AtlasMascotArtDirection(
            lineTitle: "Aurielle line",
            lineMotto: "Aurora hare guardian",
            stageLabel: "Stage II",
            stageHeadline: "Skybound grace",
            portraitNote: "Keep the body tall and elegant while letting the ears and tail describe motion around the torso.",
            posterKicker: "Graceful vertical posture with ribbon-ear flow and visible tail sweep.",
            ornamentSymbol: "wind",
            portraitSize: 230,
            portraitHaloSize: 268,
            portraitOffsetY: 2,
            portraitChipOffset: CGSize(width: 4, height: 6),
            posterArtSize: 388,
            posterArtOffset: CGSize(width: 2, height: 8),
            posterHaloSize: 304,
            posterFrameSize: CGSize(width: 402, height: 388)
        )
    case (.aurielle, .stage3):
        return AtlasMascotArtDirection(
            lineTitle: "Aurielle line",
            lineMotto: "Aurora hare guardian",
            stageLabel: "Stage III",
            stageHeadline: "Celestial serenity",
            portraitNote: "Protect the long-ear arc and tail crescent with more vertical room so the final form feels regal and calm.",
            posterKicker: "Long-ear arc, crescent-tail sweep, and serene celestial posture.",
            ornamentSymbol: "moon.stars.circle",
            portraitSize: 244,
            portraitHaloSize: 286,
            portraitOffsetY: -4,
            portraitChipOffset: CGSize(width: 8, height: 2),
            posterArtSize: 438,
            posterArtOffset: CGSize(width: 4, height: -10),
            posterHaloSize: 340,
            posterFrameSize: CGSize(width: 426, height: 426)
        )
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

struct AtlasMascotSticker: View {
    let line: AtlasMascotLine
    let stage: AtlasMascotStage
    let size: CGFloat

    var body: some View {
        Image(assetName)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .shadow(color: Color.black.opacity(0.12), radius: max(size * 0.05, 4), y: max(size * 0.02, 2))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private var assetName: String {
        switch (line, stage) {
        case (.aetherion, .stage1):
            return "AtlasMascotAetherionStage1Sticker"
        case (.aetherion, .stage2):
            return "AtlasMascotAetherionStage2Sticker"
        case (.aetherion, .stage3):
            return "AtlasMascotAetherionStage3Sticker"
        case (.aurielle, .stage1):
            return "AtlasMascotAurielleStage1Sticker"
        case (.aurielle, .stage2):
            return "AtlasMascotAurielleStage2Sticker"
        case (.aurielle, .stage3):
            return "AtlasMascotAurielleStage3Sticker"
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
                AtlasMascotSticker(
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
        AtlasSectionCard(style: .task) {
            VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                HStack(alignment: .firstTextBaseline, spacing: AtlasSpacing.small) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Moments journal")
                            .atlasTextRole(.cardTitle)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text("A collectible record of mascot reactions, milestone notes, and companion check-ins.")
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    Spacer(minLength: 0)

                    AtlasStatusBadge(
                        displayedMoments.isEmpty ? "Empty" : "\(displayedMoments.count) saved",
                        tint: displayedMoments.isEmpty ? AtlasPalette.secondaryText : atlasMascotLineTint(for: selection)
                    )
                }

                if displayedMoments.isEmpty {
                    Text("No mascot moments yet. Tap the mascot, close goals, or use the new shortcut check-ins to start filling the journal.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    AtlasMetricStrip(metrics: journalMetrics)

                    ForEach(displayedMoments) { moment in
                        let presentation = atlasMascotMomentPresentation(moment)
                        HStack(alignment: .top, spacing: AtlasSpacing.small) {
                            Image(systemName: moment.symbolName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundStyle(AtlasPalette.primary)
                                .frame(width: 28, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(atlasMascotLineTint(for: selection).opacity(0.12))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(atlasMascotLineTint(for: selection).opacity(0.16), lineWidth: 1)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: AtlasSpacing.small) {
                                    Text(moment.title)
                                        .atlasTextRole(.deckEyebrow)
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                    AtlasStatusBadge(presentation.badge, tint: presentation.tint)
                                }
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

    private var journalMetrics: [AtlasMetricItem] {
        let collectibleCount = displayedMoments.filter {
            $0.kind == .levelUp || $0.kind == .weeklyCloseout || $0.kind == .recapExport || $0.kind == .evolution
        }.count
        return [
            AtlasMetricItem(id: "saved", title: "Saved", value: "\(displayedMoments.count)", tint: atlasMascotLineTint(for: selection)),
            AtlasMetricItem(id: "collectible", title: "Collectible", value: "\(collectibleCount)", tint: AtlasPalette.reward),
            AtlasMetricItem(
                id: "latest",
                title: "Latest kind",
                value: displayedMoments.first.map { atlasMascotMomentPresentation($0).badge } ?? "None",
                tint: AtlasPalette.secondaryText
            )
        ]
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

        ScrollView {
            VStack(spacing: AtlasSpacing.large) {
                Capsule(style: .continuous)
                    .fill(AtlasPalette.surfaceSecondary)
                    .frame(width: 42, height: 5)
                    .padding(.top, 8)

                AtlasSectionCard(style: .hero) {
                    VStack(alignment: .leading, spacing: AtlasSpacing.large) {
                        HStack(alignment: .top, spacing: AtlasSpacing.large) {
                            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                                AtlasStatusBadge("Evolution unlocked", tint: atlasMascotLineTint(for: celebration.selection))

                                Text(evolution.celebrationHeadline)
                                    .atlasTextRole(.screenTitle)
                                    .foregroundStyle(AtlasPalette.textPrimary)

                                Text(evolution.celebrationBody)
                                    .atlasTextRole(.screenSubtitle)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }

                            Spacer(minLength: 8)

                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                atlasMascotLineHighlight(for: celebration.selection).opacity(0.34),
                                                atlasMascotLineTint(for: celebration.selection).opacity(0.14),
                                                .clear
                                            ],
                                            center: .center,
                                            startRadius: 16,
                                            endRadius: 112
                                        )
                                    )
                                    .frame(width: 212, height: 212)

                                AtlasMascotIllustration(
                                    line: atlasMascotLine(for: celebration.selection),
                                    stage: celebration.stage,
                                    size: 192
                                )
                            }
                        }

                        AtlasMetricStrip(metrics: metrics)

                        Button("Continue") {
                            AtlasFeedback.notify(.success)
                            onDismiss()
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                    }
                }

                AtlasSectionCard(style: .reward) {
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
            }
            .padding(AtlasSpacing.large)
        }
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
                AtlasMascotSticker(
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
        AtlasSectionCard(style: .utility) {
            VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                HStack(alignment: .firstTextBaseline, spacing: AtlasSpacing.small) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Evolution path")
                            .atlasTextRole(.cardTitle)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text("Rewards milestones permanently unlock each form, while Atlas keeps the same guardian identity across the entire line.")
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    Spacer(minLength: 0)

                    AtlasStatusBadge(stageBadge(for: currentStage), tint: stageTint(for: currentStage))
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AtlasSpacing.medium) {
                        ForEach(AtlasMascotStage.allCases, id: \.self) { stage in
                            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                                AtlasMascotSticker(
                                    line: atlasMascotLine(for: selection),
                                    stage: stage,
                                    size: 112
                                )

                                Text(selection.title(for: stage))
                                    .atlasTextRole(.cardBody)
                                    .foregroundStyle(AtlasPalette.textPrimary)

                                Text(stageCopy(for: stage))
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                    .lineLimit(3)

                                AtlasStatusBadge(stageBadge(for: stage), tint: stageTint(for: stage))
                            }
                            .frame(width: 196, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(stage == currentStage ? AtlasPalette.secondaryFill : Color.white.opacity(0.94))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(stage == currentStage ? atlasMascotLineTint(for: selection).opacity(0.45) : Color.white.opacity(0.82), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
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
    @State private var recapHandoffState: AtlasMascotRecapHandoffState?

    public init(model: AtlasAppModel) {
        self.model = model
    }

    public var body: some View {
        let selection = model.settingsSnapshot.mascotSelection
        let nickname = model.settingsSnapshot.mascotNickname
        let rewardsSnapshot = model.rewardsSnapshot
        let evolution = atlasRewardsEvolutionProgress(for: rewardsSnapshot, selection: selection)
        let artDirection = atlasMascotArtDirection(for: selection, stage: evolution.stage)
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
        let latestMoment = moments.first { $0.selection == selection }
        let progressionSummary = atlasMascotProgressionSummary(
            selection: selection,
            rewardsSnapshot: rewardsSnapshot,
            evolution: evolution,
            latestMoment: latestMoment,
            archivedRecapCount: archivedRecaps.count
        )
        let weeklyDescriptor = recapDescriptor(
            kind: .weeklyRecap,
            selection: selection,
            nickname: nickname,
            rewardsSnapshot: rewardsSnapshot,
            history: history,
            moments: moments
        )
        let milestoneDescriptor = recapDescriptor(
            kind: .evolutionMilestone,
            selection: selection,
            nickname: nickname,
            rewardsSnapshot: rewardsSnapshot,
            history: history,
            moments: moments
        )

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                AtlasTabHeader(
                    title: profile.displayName,
                    subtitle: "See the live guardian form, share editorial recap cards, and follow the full momentum line without dropping back into utility UI."
                )

                if let recapHandoffState {
                    AtlasMilestoneRevealBanner(
                        eyebrow: recapHandoffState.eyebrow,
                        title: recapHandoffState.title,
                        detail: recapHandoffState.detail,
                        tint: recapHandoffState.tint,
                        badge: recapHandoffState.badge,
                        symbolName: recapHandoffState.symbolName
                    )
                }

                AtlasSectionCard(style: .hero) {
                    VStack(alignment: .leading, spacing: AtlasSpacing.large) {
                        HStack(alignment: .top, spacing: AtlasSpacing.small) {
                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                HStack(spacing: AtlasSpacing.small) {
                                    AtlasStatusBadge(artDirection.stageLabel, tint: atlasMascotLineTint(for: selection))
                                    AtlasStatusBadge(
                                        evolution.currentFormName,
                                        tint: atlasMascotLineHighlight(for: selection)
                                    )
                                }

                                Text(artDirection.lineTitle)
                                    .atlasTextRole(.deckEyebrow)
                                    .foregroundStyle(atlasMascotLineTint(for: selection))
                            }

                            Spacer(minLength: 0)

                            Label(artDirection.lineMotto, systemImage: artDirection.ornamentSymbol)
                                .atlasTextRole(.metricLabel)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            Text(profile.displayName)
                                .atlasTextRole(.screenTitle)
                                .foregroundStyle(AtlasPalette.textPrimary)

                            Text(profile.nickname != nil ? profile.currentFormName : selection.subtitle)
                                .atlasTextRole(.screenSubtitle)
                                .foregroundStyle(atlasMascotLineTint(for: selection))

                            Text(profile.statusLine)
                                .atlasTextRole(.screenSubtitle)
                                .foregroundStyle(AtlasPalette.textSecondary)

                            Text(evolution.milestoneHeadline)
                                .atlasTextRole(.deckEyebrow)
                                .foregroundStyle(atlasMascotLineTint(for: selection))

                            Text(artDirection.stageHeadline)
                                .atlasTextRole(.cardTitle)
                                .foregroundStyle(AtlasPalette.textPrimary)

                            Text(atlasMascotStageFlavor(for: selection, stage: evolution.stage))
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }

                        VStack(alignment: .center, spacing: AtlasSpacing.small) {
                            ZStack(alignment: .bottomTrailing) {
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                atlasMascotLineHighlight(for: selection).opacity(0.12),
                                                atlasMascotLineTint(for: selection).opacity(0.06),
                                                .clear
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: artDirection.portraitHaloSize + 36, height: artDirection.portraitHaloSize + 48)

                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                atlasMascotLineHighlight(for: selection).opacity(0.34),
                                                atlasMascotLineTint(for: selection).opacity(0.16),
                                                .clear
                                            ],
                                            center: .center,
                                            startRadius: 16,
                                            endRadius: artDirection.portraitHaloSize * 0.54
                                        )
                                    )
                                    .frame(width: artDirection.portraitHaloSize, height: artDirection.portraitHaloSize)

                                Image(systemName: artDirection.ornamentSymbol)
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(atlasMascotLineHighlight(for: selection).opacity(0.72))
                                    .offset(x: -artDirection.portraitHaloSize * 0.22, y: -artDirection.portraitHaloSize * 0.28)

                                AtlasInteractiveMascotIllustration(
                                    selection: selection,
                                    nickname: nickname,
                                    line: atlasMascotLine(for: selection),
                                    stage: evolution.stage,
                                    size: artDirection.portraitSize
                                )
                                .offset(y: artDirection.portraitOffsetY)

                                HStack(spacing: 10) {
                                    AtlasMascotSprite(
                                        line: atlasMascotLine(for: selection),
                                        stage: evolution.stage,
                                        pose: atlasRewardsMascotPose(for: rewardsSnapshot),
                                        size: 64
                                    )

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Live sprite")
                                            .atlasTextRole(.deckEyebrow)
                                            .foregroundStyle(atlasMascotLineTint(for: selection))
                                        Text("Widgets and compact surfaces stay synced to this state.")
                                            .atlasTextRole(.supporting)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(AtlasPalette.surfaceTop.opacity(0.96))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(AtlasPalette.chromeStroke, lineWidth: 1)
                                )
                                .offset(
                                    x: artDirection.portraitChipOffset.width,
                                    y: artDirection.portraitChipOffset.height
                                )
                            }
                            .frame(maxWidth: .infinity)

                            VStack(spacing: 4) {
                                Label(selection.title, systemImage: atlasMascotLineSymbol(for: selection))
                                    .atlasTextRole(.deckEyebrow)
                                    .foregroundStyle(atlasMascotLineTint(for: selection))

                                Text(artDirection.portraitNote)
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }

                        AtlasMetricStrip(
                            metrics: atlasMascotMetrics(
                                rewardsSnapshot: rewardsSnapshot,
                                historyCount: history.filter { $0.selection == selection }.count,
                                momentsCount: moments.filter { $0.selection == selection }.count,
                                stageBadge: evolution.stageBadge
                            )
                        )

                        AtlasMilestoneRevealBanner(
                            eyebrow: progressionSummary.badge,
                            title: progressionSummary.title,
                            detail: progressionSummary.detail,
                            tint: progressionSummary.tint,
                            badge: evolution.stageBadge,
                            symbolName: progressionSummary.symbolName
                        )

                        AtlasCalloutRow(
                            systemImage: artDirection.ornamentSymbol,
                            title: "Art direction",
                            detail: artDirection.posterKicker,
                            tint: atlasMascotLineTint(for: selection),
                            badge: artDirection.stageLabel
                        )

                        if let progressFraction = evolution.progressFraction {
                            AtlasProgressMeter(
                                title: "Evolution progress",
                                detail: evolution.progressLabel,
                                value: progressFraction,
                                tint: atlasMascotLineTint(for: selection)
                            )
                        } else {
                            AtlasCalloutRow(
                                systemImage: "crown.fill",
                                title: "Final guardian unlocked",
                                detail: "\(evolution.currentFormName) is the highest unlocked form in this line.",
                                tint: AtlasPalette.success
                            )
                        }

                        AtlasMascotUnlockReadinessRow(
                            selection: selection,
                            rewardsSnapshot: rewardsSnapshot,
                            evolution: evolution,
                            archivedRecapCount: archivedRecaps.count,
                            latestMoment: latestMoment
                        )

                        if let reaction = profile.reaction {
                            AtlasMascotReactionStrip(reaction: reaction)
                        }

                        if let latestMoment {
                            AtlasMascotMomentHighlight(moment: latestMoment)
                        }

                        HStack(spacing: AtlasSpacing.small) {
                            Button {
                                AtlasFeedback.selection()
                                Task {
                                    await recordMoment()
                                }
                            } label: {
                                Label("Capture mascot moment", systemImage: "sparkles")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(AtlasPrimaryButtonStyle())

                            Button {
                                AtlasFeedback.selection()
                                Task {
                                    await createMascotRecapExport(weeklyDescriptor)
                                }
                            } label: {
                                Label("Share weekly poster", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(AtlasSecondaryButtonStyle())
                        }
                    }
                }

                AtlasCommandDeck(
                    eyebrow: "Momentum loop",
                    title: "Keep the guardian line feeling alive",
                    detail: "Atlas should always make the next rewarding action obvious: capture a moment, export a recap, or push the next evolution threshold.",
                    metrics: [
                        .init(id: "points", title: "Points", value: "\(rewardsSnapshot.totalPoints)", tint: AtlasPalette.reward),
                        .init(
                            id: "next",
                            title: "Next form",
                            value: evolution.nextFormName ?? "Final form",
                            tint: evolution.nextFormName == nil ? AtlasPalette.success : atlasMascotLineTint(for: selection)
                        ),
                        .init(
                            id: "gallery",
                            title: "Gallery",
                            value: "\(archivedRecaps.count)",
                            tint: AtlasPalette.primary
                        )
                    ],
                    tint: atlasMascotLineTint(for: selection),
                    style: .reward
                ) {
                    HStack(spacing: AtlasSpacing.small) {
                        Button {
                            AtlasFeedback.selection()
                            Task {
                                await createMascotRecapExport(milestoneDescriptor)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Milestone card", systemImage: "sparkles")
                                    .atlasTextRole(.cardBody)
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Text("Export the current evolution line as a polished PNG.")
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                        }
                        .buttonStyle(AtlasTactileTileButtonStyle(tint: atlasMascotLineTint(for: selection)))

                        Button {
                            AtlasFeedback.selection()
                            Task {
                                await createMascotRecapExport(
                                    recapDescriptor(
                                        kind: .latestMoment,
                                        selection: selection,
                                        nickname: nickname,
                                        rewardsSnapshot: rewardsSnapshot,
                                        history: history,
                                        moments: moments
                                    )
                                )
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Latest moment", systemImage: "clock.arrow.circlepath")
                                    .atlasTextRole(.cardBody)
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Text("Turn the freshest mascot reaction into a shareable artifact.")
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                        }
                        .buttonStyle(AtlasTactileTileButtonStyle(tint: atlasMascotLineHighlight(for: selection)))
                    }
                } footer: {
                    if let latestMoment {
                        AtlasCalloutRow(
                            systemImage: latestMoment.symbolName,
                            title: "Most recent mascot moment",
                            detail: "\(latestMoment.title) • \(latestMoment.detail)",
                            tint: atlasMascotLineTint(for: selection),
                            badge: atlasMascotMomentDateLabel(latestMoment.recordedAt)
                        )
                    } else {
                        AtlasCalloutRow(
                            systemImage: "sparkles",
                            title: "Next unlock focus",
                            detail: evolution.nextFormName == nil
                                ? "This guardian line is fully evolved, so every new moment now builds the archive and recap gallery."
                                : "\(evolution.nextFormName ?? "Next form") is still ahead. Small milestones and check-ins keep the line feeling alive.",
                            tint: atlasMascotLineTint(for: selection)
                        )
                    }
                }

                AtlasSectionCard(style: .elevated, title: "Recap studio") {
                    VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                        Text("Choose the audience and privacy mode first, then export one of the editorial recap layouts below. These cards now use the portrait art family for large surfaces and keep the pixel layer only where compact readability matters.")
                            .atlasTextRole(.screenSubtitle)
                            .foregroundStyle(AtlasPalette.textSecondary)

                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            Text("Audience")
                                .atlasTextRole(.deckEyebrow)
                                .foregroundStyle(atlasMascotLineTint(for: selection))

                            HStack(spacing: AtlasSpacing.small) {
                                ForEach(AtlasMascotRecapAudience.allCases, id: \.self) { audience in
                                    Button {
                                        AtlasFeedback.selection()
                                        recapAudience = audience
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(audience.title)
                                                .atlasTextRole(.cardBody)
                                                .foregroundStyle(AtlasPalette.textPrimary)
                                            Text(audience == recapAudience ? "Current share lens" : "Switch audience lens")
                                                .atlasTextRole(.supporting)
                                                .foregroundStyle(AtlasPalette.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(14)
                                    }
                                    .buttonStyle(
                                        AtlasTactileTileButtonStyle(
                                            tint: audience == recapAudience
                                                ? atlasMascotLineTint(for: selection)
                                                : AtlasPalette.secondaryText
                                        )
                                    )
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            Text("Privacy")
                                .atlasTextRole(.deckEyebrow)
                                .foregroundStyle(atlasMascotLineTint(for: selection))

                            HStack(spacing: AtlasSpacing.small) {
                                ForEach(AtlasMascotRecapPrivacyMode.allCases, id: \.self) { privacyMode in
                                    Button {
                                        AtlasFeedback.selection()
                                        recapPrivacyMode = privacyMode
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(privacyMode.title)
                                                .atlasTextRole(.cardBody)
                                                .foregroundStyle(AtlasPalette.textPrimary)
                                            Text(privacyMode == recapPrivacyMode ? "Current privacy mode" : "Switch privacy mode")
                                                .atlasTextRole(.supporting)
                                                .foregroundStyle(AtlasPalette.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(14)
                                    }
                                    .buttonStyle(
                                        AtlasTactileTileButtonStyle(
                                            tint: privacyMode == recapPrivacyMode
                                                ? atlasMascotLineHighlight(for: selection)
                                                : AtlasPalette.secondaryText
                                        )
                                    )
                                }
                            }
                        }

                        AtlasMascotRecapRecommendationRow(
                            selection: selection,
                            rewardsSnapshot: rewardsSnapshot,
                            evolution: evolution,
                            latestMoment: latestMoment,
                            archivedRecapCount: archivedRecaps.count,
                            audience: recapAudience,
                            privacyMode: recapPrivacyMode
                        )

                        ForEach(AtlasMascotRecapCardKind.allCases) { kind in
                            let descriptor = recapDescriptor(
                                kind: kind,
                                selection: selection,
                                nickname: nickname,
                                rewardsSnapshot: rewardsSnapshot,
                                history: history,
                                moments: moments
                            )

                            AtlasSectionCard(style: .task) {
                                VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                                    HStack(spacing: AtlasSpacing.small) {
                                        AtlasStatusBadge(kind.title, tint: atlasMascotLineTint(for: selection))
                                        AtlasStatusBadge(recapAudience.title, tint: AtlasPalette.reward)
                                        AtlasStatusBadge(recapPrivacyMode.title, tint: AtlasPalette.secondaryText)
                                    }

                                    Text(kind.subtitle)
                                        .atlasTextRole(.supporting)
                                        .foregroundStyle(AtlasPalette.textSecondary)

                                    AtlasMascotRecapPreviewCard(descriptor: descriptor)

                                    HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                            Text(descriptor.headline)
                                                .atlasTextRole(.cardBody)
                                                .foregroundStyle(AtlasPalette.textPrimary)
                                                .lineLimit(2)
                                            Text(descriptor.detail)
                                                .atlasTextRole(.supporting)
                                                .foregroundStyle(AtlasPalette.textSecondary)
                                                .lineLimit(3)
                                        }

                                        Spacer(minLength: 8)

                                        Button("Share PNG") {
                                            AtlasFeedback.selection()
                                            Task {
                                                await createMascotRecapExport(descriptor)
                                            }
                                        }
                                        .buttonStyle(AtlasPrimaryButtonStyle())
                                        .frame(maxWidth: 180)
                                    }
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
        recapHandoffState = AtlasMascotRecapHandoffState(
            eyebrow: "Export staging",
            title: "Atlas is building the \(descriptor.kind.title.lowercased()) poster.",
            detail: "The recap is being rendered with the current guardian art, privacy mode, and audience treatment before it hands off to share.",
            tint: atlasMascotLineTint(for: descriptor.selection),
            badge: descriptor.audience.title,
            symbolName: descriptor.symbolName
        )
        AtlasFeedback.milestoneReveal()
        do {
            shareArtifact = try await model.exportMascotRecapCard(descriptor)
            recapHandoffState = AtlasMascotRecapHandoffState(
                eyebrow: "Poster ready",
                title: "\(descriptor.kind.title) is staged and ready to share.",
                detail: "Atlas archived the export and turned this milestone into a collectible handoff instead of a raw file dump.",
                tint: atlasMascotLineHighlight(for: descriptor.selection),
                badge: descriptor.privacyMode.title,
                symbolName: "square.and.arrow.up.fill"
            )
            AtlasFeedback.levelUp()
        } catch {
            exportErrorMessage = error.localizedDescription
            recapHandoffState = nil
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
            recapHandoffState = AtlasMascotRecapHandoffState(
                eyebrow: "Archive reopen",
                title: "A saved recap poster is back in hand.",
                detail: "Atlas reopened this collectible straight from the archive so it can be shared again without rebuilding it.",
                tint: atlasMascotLineTint(for: recap.selection),
                badge: recap.audience.title,
                symbolName: "photo.stack.fill"
            )
            AtlasFeedback.milestoneReveal()
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func recapDescriptor(
        kind: AtlasMascotRecapCardKind,
        selection: AtlasMascotSelection,
        nickname: String?,
        rewardsSnapshot: AtlasRewardsSnapshot,
        history: [AtlasMascotEvolutionRecord],
        moments: [AtlasMascotMomentRecord]
    ) -> AtlasMascotRecapDescriptor {
        atlasMascotRecapDescriptor(
            kind: kind,
            audience: recapAudience,
            privacyMode: recapPrivacyMode,
            selection: selection,
            nickname: nickname,
            rewardsSnapshot: rewardsSnapshot,
            evolutionHistory: history,
            moments: moments
        )
    }

    @MainActor
    private func recordMoment() async {
        await model.recordMascotInteractionMoment()
        AtlasFeedback.mascotMoment()
    }
}

private struct AtlasMascotRecapHandoffState {
    let eyebrow: String
    let title: String
    let detail: String
    let tint: Color
    let badge: String?
    let symbolName: String
}

private struct AtlasMascotUnlockReadinessRow: View {
    let selection: AtlasMascotSelection
    let rewardsSnapshot: AtlasRewardsSnapshot
    let evolution: AtlasMascotEvolutionProgress
    let archivedRecapCount: Int
    let latestMoment: AtlasMascotMomentRecord?

    var body: some View {
        let summary = atlasMascotProgressionSummary(
            selection: selection,
            rewardsSnapshot: rewardsSnapshot,
            evolution: evolution,
            latestMoment: latestMoment,
            archivedRecapCount: archivedRecapCount
        )

        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            AtlasMilestoneRevealBanner(
                eyebrow: summary.badge,
                title: summary.title,
                detail: summary.detail,
                tint: summary.tint,
                badge: evolution.stageBadge,
                symbolName: summary.symbolName
            )

            HStack(spacing: AtlasSpacing.small) {
                AtlasMascotMomentumTile(
                    title: "Next unlock",
                    value: evolution.nextFormName ?? "Final form",
                    detail: evolution.nextFormName == nil ? "Archive mode" : evolution.progressLabel,
                    tint: summary.tint
                )
                AtlasMascotMomentumTile(
                    title: "Recap gallery",
                    value: "\(archivedRecapCount)",
                    detail: archivedRecapCount == 0 ? "Nothing exported yet" : "collectible poster\(archivedRecapCount == 1 ? "" : "s")",
                    tint: AtlasPalette.primary
                )
            }

            AtlasCalloutRow(
                systemImage: summary.symbolName,
                title: summary.title,
                detail: summary.detail,
                tint: summary.tint,
                badge: summary.badge
            )
        }
    }
}

private struct AtlasMascotRecapRecommendationRow: View {
    let selection: AtlasMascotSelection
    let rewardsSnapshot: AtlasRewardsSnapshot
    let evolution: AtlasMascotEvolutionProgress
    let latestMoment: AtlasMascotMomentRecord?
    let archivedRecapCount: Int
    let audience: AtlasMascotRecapAudience
    let privacyMode: AtlasMascotRecapPrivacyMode

    var body: some View {
        let recommendation = atlasMascotRecapRecommendation(
            selection: selection,
            rewardsSnapshot: rewardsSnapshot,
            evolution: evolution,
            latestMoment: latestMoment,
            archivedRecapCount: archivedRecapCount
        )

        AtlasSectionCard(style: .reward) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack(spacing: AtlasSpacing.small) {
                    AtlasStatusBadge("Recommended export", tint: atlasMascotLineTint(for: selection))
                    AtlasStatusBadge(recommendation.kind.title, tint: AtlasPalette.reward)
                    AtlasStatusBadge(audience.title, tint: atlasMascotLineHighlight(for: selection))
                    AtlasStatusBadge(privacyMode.title, tint: AtlasPalette.secondaryText)
                }

                Text(recommendation.title)
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)

                Text(recommendation.detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                AtlasProgressMeter(
                    title: "Export payoff",
                    detail: recommendation.readinessDetail,
                    value: recommendation.readinessValue,
                    tint: recommendation.tint
                )
            }
        }
    }
}

private struct AtlasMascotMomentumTile: View {
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
                .fill(Color.white.opacity(0.62))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct AtlasMascotProgressionSummary {
    let title: String
    let detail: String
    let badge: String
    let symbolName: String
    let tint: Color
}

private struct AtlasMascotRecapRecommendation {
    let kind: AtlasMascotRecapCardKind
    let title: String
    let detail: String
    let readinessDetail: String
    let readinessValue: Double
    let tint: Color
}

private struct AtlasMascotMomentPresentation {
    let badge: String
    let tint: Color
}

private func atlasMascotMomentPresentation(_ moment: AtlasMascotMomentRecord) -> AtlasMascotMomentPresentation {
    switch moment.kind {
    case .interaction:
        return AtlasMascotMomentPresentation(badge: "Check-in", tint: AtlasPalette.primary)
    case .evolution:
        return AtlasMascotMomentPresentation(badge: "Evolved", tint: AtlasPalette.success)
    case .badge:
        return AtlasMascotMomentPresentation(badge: "Badge", tint: AtlasPalette.reward)
    case .goal:
        return AtlasMascotMomentPresentation(badge: "Goal", tint: AtlasPalette.primary)
    case .streak:
        return AtlasMascotMomentPresentation(badge: "Streak", tint: AtlasPalette.success)
    case .shortcut:
        return AtlasMascotMomentPresentation(badge: "Shortcut", tint: AtlasPalette.secondaryText)
    case .levelUp:
        return AtlasMascotMomentPresentation(badge: "Level up", tint: AtlasPalette.reward)
    case .weeklyCloseout:
        return AtlasMascotMomentPresentation(badge: "Week closed", tint: AtlasPalette.success)
    case .recapExport:
        return AtlasMascotMomentPresentation(badge: "Poster", tint: AtlasPalette.reward)
    }
}

private func atlasMascotProgressionSummary(
    selection: AtlasMascotSelection,
    rewardsSnapshot: AtlasRewardsSnapshot,
    evolution: AtlasMascotEvolutionProgress,
    latestMoment: AtlasMascotMomentRecord?,
    archivedRecapCount: Int
) -> AtlasMascotProgressionSummary {
    guard let nextFormName = evolution.nextFormName,
          let nextThresholdPoints = evolution.nextThresholdPoints else {
        return AtlasMascotProgressionSummary(
            title: "The full guardian line is unlocked",
            detail: archivedRecapCount == 0
                ? "The next layer of payoff is archival: capture fresh mascot moments and turn them into collectible recap cards."
                : "New moments now feed the recap gallery and keep the fully evolved guardian feeling alive instead of static.",
            badge: "Final form",
            symbolName: "crown.fill",
            tint: AtlasPalette.success
        )
    }

    let remainingPoints = max(nextThresholdPoints - rewardsSnapshot.totalPoints, 0)
    if remainingPoints == 0 || (evolution.progressFraction ?? 0) >= 0.86 {
        return AtlasMascotProgressionSummary(
            title: "\(nextFormName) is close enough to tease",
            detail: "Only \(remainingPoints) points remain. The right goal completion, streak extension, or weekly closure can turn this line into its next silhouette.",
            badge: "Near unlock",
            symbolName: "sparkles",
            tint: atlasMascotLineTint(for: selection)
        )
    }

    if let latestMoment {
        return AtlasMascotProgressionSummary(
            title: "Momentum is visible between unlocks",
            detail: "\(latestMoment.title) is already in the journal. Atlas can use moments like this to make the journey feel alive before the next stage lands.",
            badge: "Live journey",
            symbolName: latestMoment.symbolName,
            tint: atlasMascotLineTint(for: selection)
        )
    }

    return AtlasMascotProgressionSummary(
        title: "\(nextFormName) is still the next major leap",
        detail: "There are \(remainingPoints) points left before the next form. In the meantime, small mascot moments and recap exports keep the line feeling present.",
        badge: "In motion",
        symbolName: atlasMascotLineSymbol(for: selection),
        tint: atlasMascotLineTint(for: selection)
    )
}

private func atlasMascotRecapRecommendation(
    selection: AtlasMascotSelection,
    rewardsSnapshot: AtlasRewardsSnapshot,
    evolution: AtlasMascotEvolutionProgress,
    latestMoment: AtlasMascotMomentRecord?,
    archivedRecapCount: Int
) -> AtlasMascotRecapRecommendation {
    if let latestMoment {
        return AtlasMascotRecapRecommendation(
            kind: .latestMoment,
            title: "Latest moment is the strongest export right now",
            detail: "\(latestMoment.title) already gives the poster a clear emotional beat, so this export will feel more specific than a generic summary card.",
            readinessDetail: archivedRecapCount == 0
                ? "Start the gallery with a moment-driven card."
                : "Moment cards add personality between milestone posters.",
            readinessValue: 0.88,
            tint: atlasMascotLineHighlight(for: selection)
        )
    }

    if evolution.nextFormName == nil {
        return AtlasMascotRecapRecommendation(
            kind: .evolutionMilestone,
            title: "Milestone export is now a proper final-form poster",
            detail: "Because the line is fully evolved, the milestone layout reads like a finished collector card instead of a progress placeholder.",
            readinessDetail: "The full line is unlocked, so this export is ready to read like a capstone artifact.",
            readinessValue: 1,
            tint: AtlasPalette.success
        )
    }

    return AtlasMascotRecapRecommendation(
        kind: .weeklyRecap,
        title: "Weekly poster is the best way to make progress feel earned",
        detail: "There is still another form ahead, so the weekly export does the best job of showing movement and anticipation at the same time.",
        readinessDetail: "\(evolution.currentFormName) is moving toward \(evolution.nextFormName ?? "the next form").",
        readinessValue: max(evolution.progressFraction ?? 0.22, 0.22),
        tint: atlasMascotLineTint(for: selection)
    )
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
