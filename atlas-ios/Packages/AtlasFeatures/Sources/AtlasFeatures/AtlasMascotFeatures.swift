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
        return ""
    case (.aetherion, .stage2):
        return ""
    case (.aetherion, .stage3):
        return ""
    case (.aurielle, .stage1):
        return ""
    case (.aurielle, .stage2):
        return ""
    case (.aurielle, .stage3):
        return ""
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
            stageHeadline: "",
            portraitNote: "",
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
            stageHeadline: "",
            portraitNote: "",
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
            stageHeadline: "",
            portraitNote: "",
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
            stageHeadline: "",
            portraitNote: "",
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
            stageHeadline: "",
            portraitNote: "",
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
            stageHeadline: "",
            portraitNote: "",
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
            return "Final form unlocked."
        }
        _ = nextThresholdPoints
        return "Next form: \(nextFormName)."
    }

    var progressLabel: String {
        guard let nextFormName, let nextThresholdPoints else {
            return "Final form unlocked."
        }

        let remainingPoints = max(nextThresholdPoints - totalPoints, 0)
        return "\(atlasMascotPointLabel(remainingPoints)) to \(nextFormName)."
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
            return "\(currentFormName) is now active and will evolve as rewards milestones are reached."
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

enum AtlasAmbientMascotPerchPlacement {
    case cardCorner
    case tabShelf
}

enum AtlasAmbientMascotReactionKind: String, Sendable {
    case logSuccess
    case reviewComplete
    case openedMascot
    case openedRewards
    case openedSurface
    case capturedMoment
    case noticedContent
    case inspectReveal
    case welcomeBack
    case milestone
    case artifactReady
}

struct AtlasAmbientMascotReactionSignal: Equatable, Sendable {
    let token: Int
    let kind: AtlasAmbientMascotReactionKind
}

enum AtlasAmbientMascotSuppression: Equatable, Sendable {
    case none
    case nearbyChrome
    case serious

    var hasNearbyChrome: Bool {
        self != .none
    }

    var suppressesAutonomousMotion: Bool {
        self != .none
    }

    var suppressesReactions: Bool {
        self == .serious
    }

    var hidesPerch: Bool {
        self == .serious
    }
}

func atlasAmbientMascotSuppression(
    hasNearbyChrome: Bool = false,
    presentingSheet: Bool = false,
    presentingExport: Bool = false,
    denseEntryActive: Bool = false,
    trustSensitiveFlow: Bool = false
) -> AtlasAmbientMascotSuppression {
    if presentingSheet || presentingExport || denseEntryActive || trustSensitiveFlow {
        return .serious
    }

    if hasNearbyChrome {
        return .nearbyChrome
    }

    return .none
}

func atlasAmbientMascotSelection(settingsSnapshot: AtlasSettingsSnapshot) -> AtlasMascotSelection? {
    guard settingsSnapshot.ambientMascotPresence != .off else {
        return nil
    }
    return settingsSnapshot.mascotSelection
}

func atlasAmbientMascotStage(
    settingsSnapshot: AtlasSettingsSnapshot,
    rewardsSnapshot: AtlasRewardsSnapshot
) -> AtlasMascotStage? {
    guard atlasAmbientMascotSelection(settingsSnapshot: settingsSnapshot) != nil else {
        return nil
    }
    return atlasRewardsMascotStage(for: rewardsSnapshot)
}

func atlasAmbientMascotMilestoneNearby(
    settingsSnapshot: AtlasSettingsSnapshot,
    rewardsSnapshot: AtlasRewardsSnapshot,
    pendingCelebration: AtlasMascotCelebrationState?
) -> Bool {
    guard let selection = atlasAmbientMascotSelection(settingsSnapshot: settingsSnapshot) else {
        return false
    }

    if pendingCelebration != nil {
        return true
    }

    guard rewardsSnapshot.settings.enabled else {
        return false
    }

    return (atlasRewardsEvolutionProgress(for: rewardsSnapshot, selection: selection).progressFraction ?? 0) >= 0.86
}

private struct AtlasAmbientMascotPolicy {
    let presence: AtlasAmbientMascotPresence
    let context: AtlasAmbientMascotPerchContext
    let suppression: AtlasAmbientMascotSuppression
    let idleLoopDelay: Duration
    let restDelay: Duration
    let milestoneLoopDelay: Duration?
    let notableCooldown: Duration
    let motionWindow: Duration
    let maxNotableMomentsPerWindow: Int

    var allowsAmbientPerch: Bool {
        presence != .off && suppression.hidesPerch == false
    }

    var allowsWakeBlink: Bool {
        allowsAmbientPerch && suppression.suppressesAutonomousMotion == false
    }

    var allowsAutonomousMotion: Bool {
        allowsAmbientPerch && suppression.suppressesAutonomousMotion == false
    }

    func allowsReaction(_ kind: AtlasAmbientMascotReactionKind) -> Bool {
        guard suppression.suppressesReactions == false else {
            return false
        }

        switch presence {
        case .off:
            return false
        case .subtle:
            switch kind {
            case .logSuccess,
                 .reviewComplete,
                 .openedMascot,
                 .openedRewards,
                 .capturedMoment,
                 .noticedContent,
                 .inspectReveal,
                 .welcomeBack,
                 .milestone,
                 .artifactReady:
                return true
            case .openedSurface:
                return false
            }
        case .moreAlive:
            return true
        }
    }

    func isNotable(_ kind: AtlasAmbientMascotReactionKind) -> Bool {
        switch kind {
        case .noticedContent, .inspectReveal, .openedSurface:
            return false
        case .logSuccess,
             .reviewComplete,
             .openedMascot,
             .openedRewards,
             .capturedMoment,
             .welcomeBack,
             .milestone,
             .artifactReady:
            return true
        }
    }
}

private func atlasAmbientMascotPolicy(
    presence: AtlasAmbientMascotPresence,
    context: AtlasAmbientMascotPerchContext,
    suppression: AtlasAmbientMascotSuppression
) -> AtlasAmbientMascotPolicy {
    let basePolicy: AtlasAmbientMascotPolicy

    switch presence {
    case .off:
        basePolicy = AtlasAmbientMascotPolicy(
            presence: presence,
            context: context,
            suppression: suppression,
            idleLoopDelay: .seconds(60),
            restDelay: .seconds(60),
            milestoneLoopDelay: nil,
            notableCooldown: .seconds(60),
            motionWindow: .seconds(60),
            maxNotableMomentsPerWindow: 0
        )
    case .subtle:
        let idleLoopDelay: Duration
        let restDelay: Duration
        let milestoneLoopDelay: Duration

        switch context {
        case .todayCommandDeck:
            idleLoopDelay = .seconds(6.3)
            restDelay = .seconds(12.2)
            milestoneLoopDelay = .seconds(15.4)
        case .weeklyReviewPayoff, .rewardsHero:
            idleLoopDelay = .seconds(6.7)
            restDelay = .seconds(12.8)
            milestoneLoopDelay = .seconds(14.8)
        case .progressEvidence, .insightsReviewLanes, .neutralCard, .mascotStudio:
            idleLoopDelay = .seconds(6.9)
            restDelay = .seconds(12.6)
            milestoneLoopDelay = .seconds(15.8)
        case .tabShelf(.library):
            idleLoopDelay = .seconds(7.4)
            restDelay = .seconds(13.2)
            milestoneLoopDelay = .seconds(16.2)
        case .tabShelf(.timeline):
            idleLoopDelay = .seconds(8.1)
            restDelay = .seconds(13.8)
            milestoneLoopDelay = .seconds(16.8)
        case .tabShelf(.settings):
            idleLoopDelay = .seconds(8.8)
            restDelay = .seconds(14.4)
            milestoneLoopDelay = .seconds(17.4)
        case .tabShelf(.today), .tabShelf(.insights):
            idleLoopDelay = .seconds(7.8)
            restDelay = .seconds(13.4)
            milestoneLoopDelay = .seconds(16.6)
        }

        basePolicy = AtlasAmbientMascotPolicy(
            presence: presence,
            context: context,
            suppression: suppression,
            idleLoopDelay: idleLoopDelay,
            restDelay: restDelay,
            milestoneLoopDelay: milestoneLoopDelay,
            notableCooldown: .seconds(11.5),
            motionWindow: .seconds(24),
            maxNotableMomentsPerWindow: 1
        )
    case .moreAlive:
        let idleLoopDelay: Duration
        let restDelay: Duration
        let maxNotableMomentsPerWindow: Int

        switch context {
        case .weeklyReviewPayoff, .rewardsHero, .mascotStudio:
            idleLoopDelay = .seconds(4.4)
            restDelay = .seconds(12.4)
            maxNotableMomentsPerWindow = 2
        case .tabShelf(.library):
            idleLoopDelay = .seconds(5)
            restDelay = .seconds(13)
            maxNotableMomentsPerWindow = 2
        case .todayCommandDeck:
            idleLoopDelay = .seconds(4.7)
            restDelay = .seconds(12.6)
            maxNotableMomentsPerWindow = 2
        case .progressEvidence, .insightsReviewLanes, .neutralCard:
            idleLoopDelay = .seconds(5.1)
            restDelay = .seconds(13)
            maxNotableMomentsPerWindow = 1
        case .tabShelf(.timeline):
            idleLoopDelay = .seconds(5.8)
            restDelay = .seconds(13.4)
            maxNotableMomentsPerWindow = 1
        case .tabShelf(.settings):
            idleLoopDelay = .seconds(6.4)
            restDelay = .seconds(14.2)
            maxNotableMomentsPerWindow = 1
        case .tabShelf(.today), .tabShelf(.insights):
            idleLoopDelay = .seconds(5.6)
            restDelay = .seconds(13.6)
            maxNotableMomentsPerWindow = 1
        }

        basePolicy = AtlasAmbientMascotPolicy(
            presence: presence,
            context: context,
            suppression: suppression,
            idleLoopDelay: idleLoopDelay,
            restDelay: restDelay,
            milestoneLoopDelay: .seconds(9.2),
            notableCooldown: .seconds(5.6),
            motionWindow: .seconds(18),
            maxNotableMomentsPerWindow: maxNotableMomentsPerWindow
        )
    }

    switch suppression {
    case .none:
        return basePolicy
    case .nearbyChrome:
        return AtlasAmbientMascotPolicy(
            presence: presence,
            context: context,
            suppression: suppression,
            idleLoopDelay: basePolicy.idleLoopDelay + .seconds(2.8),
            restDelay: basePolicy.restDelay + .seconds(1.8),
            milestoneLoopDelay: nil,
            notableCooldown: basePolicy.notableCooldown + .seconds(2.4),
            motionWindow: basePolicy.motionWindow + .seconds(8),
            maxNotableMomentsPerWindow: min(basePolicy.maxNotableMomentsPerWindow, 1)
        )
    case .serious:
        return AtlasAmbientMascotPolicy(
            presence: presence,
            context: context,
            suppression: suppression,
            idleLoopDelay: .seconds(60),
            restDelay: .seconds(60),
            milestoneLoopDelay: nil,
            notableCooldown: .seconds(60),
            motionWindow: .seconds(60),
            maxNotableMomentsPerWindow: 0
        )
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        let parts = self.components
        return TimeInterval(parts.seconds) + (TimeInterval(parts.attoseconds) / 1_000_000_000_000_000_000)
    }
}

struct AtlasAmbientMascotFlightState: Equatable {
    let selection: AtlasMascotSelection
    let stage: AtlasMascotStage
    let startPoint: CGPoint
    let endPoint: CGPoint
    let destinationPlacement: AtlasAmbientMascotPerchPlacement
}

enum AtlasAmbientMascotPerchContext: Equatable {
    case neutralCard
    case todayCommandDeck
    case insightsReviewLanes
    case weeklyReviewPayoff
    case progressEvidence
    case rewardsHero
    case mascotStudio
    case tabShelf(AtlasTab)

    var baseLift: CGFloat {
        switch self {
        case .todayCommandDeck:
            return -1.2
        case .insightsReviewLanes:
            return -0.4
        case .weeklyReviewPayoff:
            return -0.8
        case .progressEvidence:
            return -0.2
        case .rewardsHero:
            return -0.6
        case .mascotStudio:
            return -0.3
        case .neutralCard, .tabShelf:
            return 0
        }
    }

    var baseHorizontalOffset: CGFloat {
        switch self {
        case .todayCommandDeck:
            return -1
        case .insightsReviewLanes:
            return 1
        case .weeklyReviewPayoff:
            return -0.5
        case .progressEvidence:
            return 1.2
        case .rewardsHero:
            return -0.4
        case .mascotStudio:
            return 0.8
        case .neutralCard, .tabShelf:
            return 0
        }
    }

    var baseRotationOffset: Double {
        switch self {
        case .todayCommandDeck:
            return -1.8
        case .insightsReviewLanes:
            return 1.4
        case .weeklyReviewPayoff:
            return 0.8
        case .progressEvidence:
            return 2.1
        case .rewardsHero:
            return -0.7
        case .mascotStudio:
            return 1.1
        case .neutralCard, .tabShelf:
            return 0
        }
    }

    var settleLift: CGFloat {
        switch self {
        case .todayCommandDeck:
            return -6.8
        case .insightsReviewLanes:
            return -5.2
        case .weeklyReviewPayoff:
            return -7.2
        case .progressEvidence:
            return -5.4
        case .rewardsHero:
            return -6.2
        case .mascotStudio:
            return -5.8
        case .neutralCard:
            return -5.6
        case .tabShelf(.timeline):
            return -3.2
        case .tabShelf(.library):
            return -4.4
        case .tabShelf(.settings):
            return -2.8
        case .tabShelf(.today), .tabShelf(.insights):
            return -3.4
        }
    }

    var settleScale: CGFloat {
        switch self {
        case .weeklyReviewPayoff, .rewardsHero:
            return 1.045
        case .tabShelf(.library):
            return 1.04
        case .tabShelf:
            return 1.025
        case .neutralCard,
             .todayCommandDeck,
             .insightsReviewLanes,
             .progressEvidence,
             .mascotStudio:
            return 1.03
        }
    }

    var idleLiftAmplitude: CGFloat {
        switch self {
        case .todayCommandDeck:
            return -1.6
        case .insightsReviewLanes:
            return -1.2
        case .weeklyReviewPayoff:
            return -1.5
        case .progressEvidence:
            return -1.1
        case .rewardsHero:
            return -1.3
        case .mascotStudio:
            return -1.25
        case .neutralCard:
            return -1.2
        case .tabShelf(.library):
            return -1
        case .tabShelf(.timeline):
            return -0.7
        case .tabShelf(.settings):
            return -0.45
        case .tabShelf(.today), .tabShelf(.insights):
            return -0.8
        }
    }

    var idleRotationAmplitude: Double {
        switch self {
        case .todayCommandDeck:
            return 2.7
        case .insightsReviewLanes:
            return 1.8
        case .weeklyReviewPayoff:
            return 2.4
        case .progressEvidence:
            return 2
        case .rewardsHero:
            return 2.2
        case .mascotStudio:
            return 2.1
        case .neutralCard:
            return 2.2
        case .tabShelf(.library):
            return 1.35
        case .tabShelf(.timeline):
            return 0.9
        case .tabShelf(.settings):
            return 0.65
        case .tabShelf(.today), .tabShelf(.insights):
            return 1.1
        }
    }

    var restLift: CGFloat {
        switch self {
        case .todayCommandDeck:
            return 2
        case .insightsReviewLanes:
            return 1.5
        case .weeklyReviewPayoff:
            return 1.9
        case .progressEvidence:
            return 1.6
        case .rewardsHero:
            return 1.75
        case .mascotStudio:
            return 1.7
        case .neutralCard:
            return 1.6
        case .tabShelf(.settings):
            return 1.05
        case .tabShelf:
            return 0.75
        }
    }

    var restRotation: Double {
        switch self {
        case .todayCommandDeck:
            return -4.4
        case .insightsReviewLanes:
            return -3.2
        case .weeklyReviewPayoff:
            return -4
        case .progressEvidence:
            return -3.6
        case .rewardsHero:
            return -3.8
        case .mascotStudio:
            return -3.5
        case .neutralCard:
            return -3.7
        case .tabShelf(.settings):
            return -2.5
        case .tabShelf:
            return -1.8
        }
    }

    var restOffsetX: CGFloat {
        switch self {
        case .todayCommandDeck:
            return -1.8
        case .insightsReviewLanes:
            return -0.9
        case .weeklyReviewPayoff:
            return -1.4
        case .progressEvidence:
            return -1.1
        case .rewardsHero:
            return -1.2
        case .mascotStudio:
            return -1
        case .neutralCard:
            return -1.1
        case .tabShelf:
            return 0
        }
    }

    var restScale: CGFloat {
        switch self {
        case .weeklyReviewPayoff, .rewardsHero:
            return 0.97
        case .tabShelf:
            return 0.98
        case .neutralCard,
             .todayCommandDeck,
             .insightsReviewLanes,
             .progressEvidence,
             .mascotStudio:
            return 0.965
        }
    }

    var contentNoticeLift: CGFloat {
        switch self {
        case .tabShelf:
            return -1.4
        case .todayCommandDeck:
            return -3.8
        case .weeklyReviewPayoff, .rewardsHero:
            return -3.5
        case .insightsReviewLanes, .progressEvidence, .mascotStudio, .neutralCard:
            return -3
        }
    }

    var contentNoticeRotation: Double {
        switch self {
        case .tabShelf(.timeline):
            return -2.4
        case .tabShelf(.settings):
            return -1.6
        case .tabShelf:
            return 2.4
        case .todayCommandDeck:
            return 5.8
        case .insightsReviewLanes:
            return 4.6
        case .weeklyReviewPayoff:
            return 5.2
        case .progressEvidence:
            return 4.9
        case .rewardsHero:
            return 5.4
        case .mascotStudio:
            return 4.8
        case .neutralCard:
            return 4.5
        }
    }

    var peekLift: CGFloat {
        switch self {
        case .tabShelf:
            return -1.2
        case .todayCommandDeck, .weeklyReviewPayoff, .rewardsHero:
            return -3.6
        case .insightsReviewLanes, .progressEvidence, .mascotStudio, .neutralCard:
            return -3
        }
    }

    var peekOffsetX: CGFloat {
        switch self {
        case .tabShelf(.timeline):
            return -2
        case .tabShelf(.library):
            return 1.5
        case .tabShelf(.settings):
            return -1.5
        case .tabShelf(.today), .tabShelf(.insights):
            return 1
        case .neutralCard,
             .todayCommandDeck,
             .insightsReviewLanes,
             .weeklyReviewPayoff,
             .progressEvidence,
             .rewardsHero,
             .mascotStudio:
            return 6
        }
    }

    var peekRotation: Double {
        switch self {
        case .tabShelf(.timeline):
            return -4
        case .tabShelf(.settings):
            return -3
        case .tabShelf:
            return 4
        case .neutralCard,
             .todayCommandDeck,
             .insightsReviewLanes,
             .weeklyReviewPayoff,
             .progressEvidence,
             .rewardsHero,
             .mascotStudio:
            return 7
        }
    }

    var proudHoldLift: CGFloat {
        switch self {
        case .tabShelf:
            return -1.8
        case .weeklyReviewPayoff, .rewardsHero:
            return -3.2
        case .todayCommandDeck, .insightsReviewLanes, .progressEvidence, .mascotStudio, .neutralCard:
            return -2.6
        }
    }

    var proudHoldScale: CGFloat {
        switch self {
        case .tabShelf:
            return 1.015
        case .weeklyReviewPayoff, .rewardsHero:
            return 1.03
        case .neutralCard,
             .todayCommandDeck,
             .insightsReviewLanes,
             .progressEvidence,
             .mascotStudio:
            return 1.022
        }
    }

    var proudHoldRotation: Double {
        switch self {
        case .tabShelf(.timeline):
            return 1.4
        case .tabShelf(.settings):
            return -0.8
        case .tabShelf:
            return 1
        case .neutralCard,
             .todayCommandDeck,
             .insightsReviewLanes,
             .weeklyReviewPayoff,
             .progressEvidence,
             .rewardsHero,
             .mascotStudio:
            return 2.8
        }
    }

    var shelfPose: AtlasMascotPose {
        switch self {
        case .tabShelf(.timeline):
            return .recovery
        case .tabShelf(.library):
            return .happy
        case .tabShelf(.settings):
            return .rest
        case .neutralCard,
             .todayCommandDeck,
             .insightsReviewLanes,
             .weeklyReviewPayoff,
             .progressEvidence,
             .rewardsHero,
             .mascotStudio,
             .tabShelf(.today),
             .tabShelf(.insights):
            return .idle
        }
    }

    var constrainedChromeOffset: CGSize {
        switch self {
        case .tabShelf(.timeline):
            return CGSize(width: 8, height: -4)
        case .tabShelf(.library):
            return CGSize(width: 0, height: -5)
        case .tabShelf(.settings):
            return CGSize(width: -8, height: -4)
        case .todayCommandDeck,
             .weeklyReviewPayoff,
             .progressEvidence,
             .rewardsHero,
             .mascotStudio,
             .insightsReviewLanes,
             .neutralCard,
             .tabShelf(.today),
             .tabShelf(.insights):
            return CGSize(width: -6, height: -4)
        }
    }
}

struct AtlasAmbientMascotPerch: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let selection: AtlasMascotSelection
    let stage: AtlasMascotStage
    let presence: AtlasAmbientMascotPresence
    let placement: AtlasAmbientMascotPerchPlacement
    let context: AtlasAmbientMascotPerchContext
    let size: CGFloat
    let settleTrigger: Int
    let courtesySignal: Int
    let contentNoticeTrigger: Int
    let peekTrigger: Int
    let suppression: AtlasAmbientMascotSuppression
    let reactionSignal: AtlasAmbientMascotReactionSignal?
    let milestoneNearby: Bool

    @State private var isSettled = false
    @State private var hasAppearedOnce = false
    @State private var lastDisappearAt: Date?
    @State private var idleLift: CGFloat = 0
    @State private var idleRotation: Double = 0
    @State private var courtesyLift: CGFloat = 0
    @State private var courtesyRotation: Double = 0
    @State private var courtesyOffsetX: CGFloat = 0
    @State private var reactionLift: CGFloat = 0
    @State private var reactionScale: CGFloat = 1
    @State private var reactionRotation: Double = 0
    @State private var proudHoldLift: CGFloat = 0
    @State private var proudHoldScale: CGFloat = 1
    @State private var proudHoldRotation: Double = 0
    @State private var peekLift: CGFloat = 0
    @State private var peekRotation: Double = 0
    @State private var peekOffsetX: CGFloat = 0
    @State private var restLift: CGFloat = 0
    @State private var restRotation: Double = 0
    @State private var restOffsetX: CGFloat = 0
    @State private var restScale: CGFloat = 1
    @State private var isResting = false
    @State private var chromeLift: CGFloat = 0
    @State private var chromeOffsetX: CGFloat = 0
    @State private var blinkScaleY: CGFloat = 1
    @State private var motionWindowStartedAt: Date?
    @State private var notableMomentsInWindow = 0
    @State private var lastNotableMomentAt: Date?
    @State private var idleTask: Task<Void, Never>?
    @State private var courtesyTask: Task<Void, Never>?
    @State private var milestoneTask: Task<Void, Never>?
    @State private var restTask: Task<Void, Never>?
    @State private var blinkTask: Task<Void, Never>?
    @State private var peekTask: Task<Void, Never>?
    @State private var reactionTask: Task<Void, Never>?

    init(
        selection: AtlasMascotSelection,
        stage: AtlasMascotStage,
        presence: AtlasAmbientMascotPresence = .subtle,
        placement: AtlasAmbientMascotPerchPlacement = .cardCorner,
        context: AtlasAmbientMascotPerchContext = .neutralCard,
        size: CGFloat = 62,
        settleTrigger: Int = 0,
        courtesySignal: Int = 0,
        contentNoticeTrigger: Int = 0,
        peekTrigger: Int = 0,
        suppression: AtlasAmbientMascotSuppression = .none,
        reactionSignal: AtlasAmbientMascotReactionSignal? = nil,
        milestoneNearby: Bool = false
    ) {
        self.selection = selection
        self.stage = stage
        self.presence = presence
        self.placement = placement
        self.context = context
        self.size = size
        self.settleTrigger = settleTrigger
        self.courtesySignal = courtesySignal
        self.contentNoticeTrigger = contentNoticeTrigger
        self.peekTrigger = peekTrigger
        self.suppression = suppression
        self.reactionSignal = reactionSignal
        self.milestoneNearby = milestoneNearby
    }

    private var policy: AtlasAmbientMascotPolicy {
        atlasAmbientMascotPolicy(presence: presence, context: context, suppression: suppression)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(shadowTint.opacity(placement == .tabShelf ? 0.24 : 0.18))
                .frame(
                    width: placement == .tabShelf ? size * 0.7 : size * 0.82,
                    height: placement == .tabShelf ? 7 : 9
                )
                .blur(radius: placement == .tabShelf ? 1.6 : 2)
                .offset(y: placement == .tabShelf ? 3 : 5)

            mascotArt
                .rotationEffect(.degrees(rotationDegrees))
                .offset(x: horizontalOffset, y: verticalOffset)
                .scaleEffect(
                    x: reactionScale * proudHoldScale * restScale,
                    y: blinkScaleY * reactionScale * proudHoldScale * restScale
                )
        }
        .frame(
            width: placement == .tabShelf ? size * 1.2 : size * 1.34,
            height: placement == .tabShelf ? size * 0.92 : size * 1.18,
            alignment: .bottom
        )
        .opacity(policy.allowsAmbientPerch ? 1 : 0)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
        .onAppear {
            guard policy.allowsAmbientPerch else {
                resetAnimationState()
                return
            }
            let shouldWakeBlink = hasAppearedOnce
                && (lastDisappearAt.map { Date().timeIntervalSince($0) > 1.6 } ?? false)
            resetAnimationState()
            if shouldWakeBlink, policy.allowsWakeBlink {
                isSettled = true
                runWakeBlinkAnimation()
            } else {
                runSettleAnimation()
            }
            runChromeConstraintAnimation()
            configureIdleLoop()
            configureMilestoneLoop()
            scheduleRestLoop()
            hasAppearedOnce = true
        }
        .onDisappear {
            idleTask?.cancel()
            courtesyTask?.cancel()
            milestoneTask?.cancel()
            restTask?.cancel()
            blinkTask?.cancel()
            peekTask?.cancel()
            reactionTask?.cancel()
            lastDisappearAt = Date()
            resetAnimationState()
        }
        .onChange(of: settleTrigger) { _, _ in
            guard policy.allowsAmbientPerch else {
                return
            }
            runSettleAnimation()
        }
        .onChange(of: courtesySignal) { _, _ in
            guard policy.allowsAmbientPerch else {
                return
            }
            runCourtesyAnimation()
        }
        .onChange(of: contentNoticeTrigger) { _, _ in
            guard policy.allowsAmbientPerch else {
                return
            }
            runReactionAnimation(.noticedContent, includeHaptics: false)
        }
        .onChange(of: peekTrigger) { _, _ in
            guard policy.allowsAmbientPerch else {
                return
            }
            runPeekAnimation()
        }
        .onChange(of: reactionSignal?.token) { _, _ in
            guard let reactionSignal else {
                return
            }
            runReactionAnimation(reactionSignal.kind)
        }
        .onChange(of: milestoneNearby) { _, _ in
            guard policy.allowsAmbientPerch else {
                return
            }
            configureMilestoneLoop()
        }
        .onChange(of: presence) { _, _ in
            guard policy.allowsAmbientPerch else {
                resetAnimationState()
                return
            }
            refreshPolicyDrivenAnimationState()
        }
        .onChange(of: suppression) { _, _ in
            guard policy.allowsAmbientPerch else {
                resetAnimationState()
                return
            }
            refreshPolicyDrivenAnimationState()
        }
    }

    @ViewBuilder
    private var mascotArt: some View {
        switch placement {
        case .cardCorner:
            AtlasMascotSticker(
                line: atlasMascotLine(for: selection),
                stage: stage,
                size: size
            )
        case .tabShelf:
            AtlasMascotSprite(
                line: atlasMascotLine(for: selection),
                stage: stage,
                pose: context.shelfPose,
                size: size
            )
        }
    }

    private var rotationDegrees: Double {
        baseRotation + idleRotation + courtesyRotation + reactionRotation + proudHoldRotation + peekRotation + restRotation
    }

    private var verticalOffset: CGFloat {
        let settleOffset: CGFloat = isSettled ? 0 : 12
        return settleOffset
            + context.baseLift
            + idleLift
            + courtesyLift
            + reactionLift
            + proudHoldLift
            + peekLift
            + restLift
            + chromeLift
    }

    private var horizontalOffset: CGFloat {
        context.baseHorizontalOffset + courtesyOffsetX + peekOffsetX + restOffsetX + chromeOffsetX
    }

    private var shadowTint: Color {
        atlasMascotLineTint(for: selection)
    }

    private var baseRotation: Double {
        switch placement {
        case .cardCorner:
            return (reduceMotion ? -3 : -4) + context.baseRotationOffset
        case .tabShelf:
            return context.baseRotationOffset * 0.35
        }
    }

    private func resetAnimationState() {
        isSettled = reduceMotion
        idleLift = 0
        idleRotation = 0
        courtesyLift = 0
        courtesyRotation = 0
        courtesyOffsetX = 0
        reactionLift = 0
        reactionScale = 1
        reactionRotation = 0
        proudHoldLift = 0
        proudHoldScale = 1
        proudHoldRotation = 0
        peekLift = 0
        peekRotation = 0
        peekOffsetX = 0
        restLift = 0
        restRotation = 0
        restOffsetX = 0
        restScale = 1
        isResting = false
        chromeLift = 0
        chromeOffsetX = 0
        blinkScaleY = 1
    }

    private func runSettleAnimation() {
        guard policy.allowsAmbientPerch else {
            isSettled = true
            return
        }
        guard policy.allowsAutonomousMotion, reduceMotion == false else {
            isSettled = true
            reactionLift = 0
            reactionScale = 1
            return
        }

        idleTask?.cancel()
        courtesyTask?.cancel()
        milestoneTask?.cancel()
        restTask?.cancel()
        wakeFromRest(animated: false)
        isSettled = false

        withAnimation(.spring(response: 0.36, dampingFraction: 0.72)) {
            isSettled = true
            reactionLift = context.settleLift
            reactionScale = context.settleScale
        }

        Task {
            try? await Task.sleep(for: .milliseconds(180))
            await MainActor.run {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                    reactionLift = 0
                    reactionScale = 1
                }
                configureIdleLoop()
                configureMilestoneLoop()
                scheduleRestLoop()
            }
        }
    }

    private func configureIdleLoop() {
        idleTask?.cancel()
        guard policy.allowsAutonomousMotion, reduceMotion == false else {
            idleLift = 0
            idleRotation = 0
            return
        }

        idleTask = Task {
            while Task.isCancelled == false {
                try? await Task.sleep(for: policy.idleLoopDelay)
                guard Task.isCancelled == false else {
                    return
                }
                guard isResting == false else {
                    continue
                }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.42)) {
                        idleLift = context.idleLiftAmplitude
                        idleRotation = context.idleRotationAmplitude
                    }
                }

                try? await Task.sleep(for: .milliseconds(520))
                guard Task.isCancelled == false else {
                    return
                }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.36)) {
                        idleLift = 0
                        idleRotation = 0
                    }
                }
            }
        }
    }

    private func configureMilestoneLoop() {
        milestoneTask?.cancel()
        guard policy.allowsAutonomousMotion,
              reduceMotion == false,
              milestoneNearby,
              let loopDelay = policy.milestoneLoopDelay else {
            return
        }

        milestoneTask = Task {
            while Task.isCancelled == false {
                try? await Task.sleep(for: loopDelay)
                guard Task.isCancelled == false else {
                    return
                }
                await MainActor.run {
                    runReactionAnimation(.milestone, includeHaptics: false)
                }
            }
        }
    }

    private func runCourtesyAnimation() {
        guard policy.allowsAmbientPerch, reduceMotion == false else {
            return
        }

        wakeFromRest()
        courtesyTask?.cancel()
        let xOffset: CGFloat = placement == .tabShelf ? 0 : 4
        let lift: CGFloat = placement == .tabShelf ? -1 : 1.5
        let rotation: Double = placement == .tabShelf ? -3 : 5

        withAnimation(.easeInOut(duration: 0.18)) {
            courtesyLift = lift
            courtesyRotation = rotation
            courtesyOffsetX = xOffset
        }

        courtesyTask = Task {
            try? await Task.sleep(for: .milliseconds(420))
            guard Task.isCancelled == false else {
                return
            }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.24)) {
                    courtesyLift = 0
                    courtesyRotation = 0
                    courtesyOffsetX = 0
                }
                scheduleRestLoop()
            }
        }
    }

    private func scheduleRestLoop() {
        restTask?.cancel()
        guard policy.allowsAutonomousMotion, reduceMotion == false else {
            return
        }

        restTask = Task {
            try? await Task.sleep(for: policy.restDelay)
            guard Task.isCancelled == false else {
                return
            }
            await MainActor.run {
                guard isResting == false else {
                    return
                }
                isResting = true
                withAnimation(.easeInOut(duration: 0.42)) {
                    restLift = context.restLift
                    restRotation = context.restRotation
                    restOffsetX = context.restOffsetX
                    restScale = context.restScale
                }
            }
        }
    }

    private func wakeFromRest(animated: Bool = true) {
        restTask?.cancel()
        guard isResting else {
            if animated {
                scheduleRestLoop()
            }
            return
        }

        isResting = false
        let reset = {
            restLift = 0
            restRotation = 0
            restOffsetX = 0
            restScale = 1
        }
        if animated {
            withAnimation(.easeInOut(duration: 0.24)) {
                reset()
            }
        } else {
            reset()
        }
        if animated {
            scheduleRestLoop()
        }
    }

    private func runReactionAnimation(
        _ kind: AtlasAmbientMascotReactionKind,
        includeHaptics: Bool = true
    ) {
        guard policy.allowsAmbientPerch,
              policy.allowsReaction(kind),
              reduceMotion == false else {
            return
        }
        guard canRunReaction(kind) else {
            return
        }

        wakeFromRest()
        reactionTask?.cancel()
        let spec = reactionSpec(for: kind)
        if includeHaptics {
            switch kind {
            case .reviewComplete, .milestone:
                AtlasFeedback.mascotMoment()
            case .artifactReady:
                AtlasFeedback.levelUp()
            case .capturedMoment:
                AtlasFeedback.mascotMoment()
            case .noticedContent, .inspectReveal:
                break
            case .logSuccess, .openedMascot, .openedRewards, .openedSurface, .welcomeBack:
                AtlasFeedback.selection()
            }
        }

        withAnimation(.spring(response: spec.response, dampingFraction: spec.damping)) {
            proudHoldLift = 0
            proudHoldScale = 1
            proudHoldRotation = 0
            reactionLift = spec.lift
            reactionScale = spec.scale
            reactionRotation = spec.rotation
        }

        reactionTask = Task {
            try? await Task.sleep(for: .milliseconds(spec.holdMilliseconds))
            guard Task.isCancelled == false else {
                return
            }
            await MainActor.run {
                withAnimation(.spring(response: 0.26, dampingFraction: 0.88)) {
                    reactionLift = 0
                    reactionScale = 1
                    reactionRotation = 0
                }
            }

            if let hold = proudHoldSpec(for: kind) {
                try? await Task.sleep(for: .milliseconds(90))
                guard Task.isCancelled == false else {
                    return
                }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        proudHoldLift = hold.lift
                        proudHoldScale = hold.scale
                        proudHoldRotation = hold.rotation
                    }
                }

                try? await Task.sleep(for: .milliseconds(460))
                guard Task.isCancelled == false else {
                    return
                }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.24)) {
                        proudHoldLift = 0
                        proudHoldScale = 1
                        proudHoldRotation = 0
                    }
                    scheduleRestLoop()
                }
            } else {
                await MainActor.run {
                    scheduleRestLoop()
                }
            }
        }
    }

    private func reactionSpec(for kind: AtlasAmbientMascotReactionKind) -> (
        lift: CGFloat,
        scale: CGFloat,
        rotation: Double,
        response: Double,
        damping: Double,
        holdMilliseconds: UInt64
    ) {
        switch kind {
        case .logSuccess:
            return (placement == .tabShelf ? -5 : -7, 1.05, placement == .tabShelf ? 2 : 3.5, 0.22, 0.62, 220)
        case .reviewComplete:
            return (-9, 1.08, 4, 0.24, 0.6, 260)
        case .openedMascot:
            return (placement == .tabShelf ? -4 : -5, 1.04, -4, 0.24, 0.68, 180)
        case .openedRewards:
            return (placement == .tabShelf ? -4 : -5, 1.04, 4, 0.24, 0.68, 180)
        case .openedSurface:
            return (placement == .tabShelf ? -3.5 : -4.5, 1.03, placement == .tabShelf ? 1.5 : 2.5, 0.22, 0.7, 170)
        case .capturedMoment:
            return (-8, 1.08, -3.5, 0.22, 0.58, 240)
        case .noticedContent:
            return (context.contentNoticeLift, 1.02, context.contentNoticeRotation, 0.22, 0.72, 180)
        case .inspectReveal:
            return (placement == .tabShelf ? -1.8 : -2.8, 1.015, placement == .tabShelf ? 5 : 7, 0.2, 0.78, 170)
        case .welcomeBack:
            return (placement == .tabShelf ? -4 : -5.5, 1.04, placement == .tabShelf ? 1.5 : 3, 0.24, 0.7, 220)
        case .milestone:
            return (-8, 1.08, 3, 0.22, 0.58, 220)
        case .artifactReady:
            return (-10, 1.1, placement == .tabShelf ? 2.5 : 5, 0.24, 0.56, 280)
        }
    }

    private func proudHoldSpec(for kind: AtlasAmbientMascotReactionKind) -> (
        lift: CGFloat,
        scale: CGFloat,
        rotation: Double
    )? {
        switch kind {
        case .reviewComplete, .artifactReady:
            return (context.proudHoldLift, context.proudHoldScale, context.proudHoldRotation)
        case .logSuccess,
             .openedMascot,
             .openedRewards,
             .openedSurface,
             .capturedMoment,
             .noticedContent,
             .inspectReveal,
             .welcomeBack,
             .milestone:
            return nil
        }
    }

    private func canRunReaction(_ kind: AtlasAmbientMascotReactionKind) -> Bool {
        guard policy.isNotable(kind) else {
            return true
        }

        let now = Date()
        if let lastNotableMomentAt,
           now.timeIntervalSince(lastNotableMomentAt) < policy.notableCooldown.timeInterval {
            return false
        }

        if let motionWindowStartedAt,
           now.timeIntervalSince(motionWindowStartedAt) < policy.motionWindow.timeInterval {
            guard notableMomentsInWindow < policy.maxNotableMomentsPerWindow else {
                return false
            }
        } else {
            self.motionWindowStartedAt = now
            self.notableMomentsInWindow = 0
        }

        lastNotableMomentAt = now
        notableMomentsInWindow += 1
        return true
    }

    private func runWakeBlinkAnimation() {
        guard policy.allowsAmbientPerch,
              policy.allowsWakeBlink,
              reduceMotion == false else {
            return
        }

        blinkTask?.cancel()
        blinkTask = Task {
            try? await Task.sleep(for: .milliseconds(120))
            guard Task.isCancelled == false else {
                return
            }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.08)) {
                    blinkScaleY = 0.16
                }
            }

            try? await Task.sleep(for: .milliseconds(90))
            guard Task.isCancelled == false else {
                return
            }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.1)) {
                    blinkScaleY = 1
                }
            }
        }
    }

    private func runPeekAnimation() {
        guard policy.allowsAutonomousMotion, reduceMotion == false else {
            return
        }

        wakeFromRest()
        peekTask?.cancel()

        withAnimation(.easeOut(duration: 0.16)) {
            peekLift = context.peekLift
            peekOffsetX = context.peekOffsetX
            peekRotation = context.peekRotation
        }

        peekTask = Task {
            try? await Task.sleep(for: .milliseconds(210))
            guard Task.isCancelled == false else {
                return
            }
            await MainActor.run {
                withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                    peekLift = 0
                    peekOffsetX = 0
                    peekRotation = 0
                }
                scheduleRestLoop()
            }
        }
    }

    private func runChromeConstraintAnimation() {
        let offset = suppression.hasNearbyChrome ? context.constrainedChromeOffset : .zero

        guard reduceMotion == false else {
            chromeOffsetX = offset.width
            chromeLift = offset.height
            return
        }

        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
            chromeOffsetX = offset.width
            chromeLift = offset.height
        }
    }

    private func refreshPolicyDrivenAnimationState() {
        runChromeConstraintAnimation()
        if policy.allowsAutonomousMotion {
            configureIdleLoop()
            configureMilestoneLoop()
            scheduleRestLoop()
        } else {
            idleTask?.cancel()
            milestoneTask?.cancel()
            restTask?.cancel()
            wakeFromRest(animated: false)
            idleLift = 0
            idleRotation = 0
        }
    }
}

private struct AtlasAmbientMascotOpenReactionModifier: ViewModifier {
    let model: AtlasAppModel
    let kind: AtlasAmbientMascotReactionKind

    @State private var hasTriggeredOpenReaction = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard hasTriggeredOpenReaction == false else {
                    return
                }
                hasTriggeredOpenReaction = true
                model.triggerAmbientMascotReaction(kind)
            }
            .onDisappear {
                hasTriggeredOpenReaction = false
            }
    }
}

extension View {
    func atlasAmbientMascotOpenReaction(
        model: AtlasAppModel,
        kind: AtlasAmbientMascotReactionKind
    ) -> some View {
        modifier(AtlasAmbientMascotOpenReactionModifier(model: model, kind: kind))
    }
}

struct AtlasAmbientMascotFlightOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let flight: AtlasAmbientMascotFlightState
    let onFinished: () -> Void

    @State private var progress: CGFloat = 0

    var body: some View {
        AtlasMascotSticker(
            line: atlasMascotLine(for: flight.selection),
            stage: flight.stage,
            size: currentSize
        )
        .rotationEffect(.degrees(-6 + Double(progress * 8)))
        .position(currentPoint)
        .shadow(color: atlasMascotLineTint(for: flight.selection).opacity(0.16), radius: 12, y: 8)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard reduceMotion == false else {
                onFinished()
                return
            }

            withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                progress = 1
            }

            Task {
                try? await Task.sleep(for: .milliseconds(520))
                await MainActor.run {
                    onFinished()
                }
            }
        }
    }

    private var currentPoint: CGPoint {
        let x = flight.startPoint.x + ((flight.endPoint.x - flight.startPoint.x) * progress)
        let baseY = flight.startPoint.y + ((flight.endPoint.y - flight.startPoint.y) * progress)
        let arc = sin(progress * .pi) * (flight.destinationPlacement == .tabShelf ? 38 : 52)
        return CGPoint(x: x, y: baseY - arc)
    }

    private var currentSize: CGFloat {
        let start: CGFloat = 58
        let end: CGFloat = flight.destinationPlacement == .tabShelf ? 40 : 54
        return start + ((end - start) * progress)
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

                    if profile.nickname != nil {
                        Text(selection.title)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                }

                if compact == false {
                    Spacer(minLength: 0)

                    homeIllustration(
                        selection: selection,
                        line: line,
                        stage: evolution.stage
                    )
                }
            }

            if compact == false {
                AtlasMetricStrip(
                    metrics: atlasMascotMetrics(
                        rewardsSnapshot: rewardsSnapshot,
                        historyCount: filteredHistory.count,
                        momentsCount: moments.filter { $0.selection == selection }.count,
                        stageBadge: evolution.stageBadge
                    )
                )

                if let progressFraction = evolution.progressFraction {
                    AtlasProgressMeter(
                        title: "Evolution",
                        detail: nil,
                        value: progressFraction,
                        tint: AtlasPalette.reward
                    )
                } else {
                    Text("Final form unlocked.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
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
                    }

                    Spacer(minLength: 0)

                    AtlasStatusBadge(
                        displayedMoments.isEmpty ? "Empty" : "\(displayedMoments.count) saved",
                        tint: displayedMoments.isEmpty ? AtlasPalette.secondaryText : atlasMascotLineTint(for: selection)
                    )
                }

                if displayedMoments.isEmpty {
                    Text("No saved moments yet.")
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
            atlasMascotCollectibleKinds.contains($0.kind)
        }.count
        return [
            AtlasMetricItem(id: "saved", title: "Saved", value: "\(displayedMoments.count)", tint: atlasMascotLineTint(for: selection)),
            AtlasMetricItem(id: "collectible", title: "Collectible", value: "\(collectibleCount)", tint: AtlasPalette.reward),
            AtlasMetricItem(
                id: "latest",
                title: "Latest kind",
                value: displayedMoments.first.map { atlasMascotMomentPresentation($0).badge } ?? "None",
                tint: displayedMoments.first.map { atlasMascotMomentPresentation($0).tint } ?? AtlasPalette.secondaryText
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
            return "Imported local history was found, so a starting line was chosen automatically. Keep it or switch it now."
        case .existingLocalUser:
            return "An existing local setup was found, so a starting line was chosen automatically. Confirm it or switch it now."
        default:
            return "Pick the mascot line to use across rewards, continuity, and companion previews."
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
                                ? [AtlasPalette.surfaceTop, AtlasPalette.secondaryFill]
                                : [AtlasPalette.surfaceTop, AtlasPalette.surfaceSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(selection == currentSelection ? AtlasPalette.primary.opacity(0.45) : AtlasPalette.chromeStroke, lineWidth: 1)
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
                        Text("Each form unlocks permanently.")
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
                                    .fill(stage == currentStage ? AtlasPalette.secondaryFill : AtlasPalette.surfaceTop)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(stage == currentStage ? atlasMascotLineTint(for: selection).opacity(0.45) : AtlasPalette.chromeStroke, lineWidth: 1)
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
        atlasMascotStagePathCopy(selection: selection, stage: stage)
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
        .init(id: "history", title: "Unlocks", value: "\(historyCount)", tint: AtlasPalette.success)
    ]
}

public struct AtlasMascotDetailScreen: View {
    let model: AtlasAppModel
    @State private var shareArtifact: AtlasMascotExportArtifact?
    @State private var exportErrorMessage: String?
    @State private var recapAudience: AtlasMascotRecapAudience = .personal
    @State private var recapPrivacyMode: AtlasMascotRecapPrivacyMode = .fullDetail
    @State private var recapHandoffState: AtlasMascotRecapHandoffState?
    @State private var recapCourtesySignal = 0

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
                    subtitle: nil
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

                            Text(evolution.milestoneHeadline)
                                .atlasTextRole(.deckEyebrow)
                                .foregroundStyle(atlasMascotLineTint(for: selection))
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
                            }
                            .frame(maxWidth: .infinity)
                        }

                        AtlasMetricStrip(
                            metrics: atlasMascotMetrics(
                                rewardsSnapshot: rewardsSnapshot,
                                historyCount: history.filter { $0.selection == selection }.count,
                                momentsCount: moments.filter { $0.selection == selection }.count,
                                stageBadge: evolution.stageBadge
                            )
                        )

                        if let progressFraction = evolution.progressFraction {
                            AtlasProgressMeter(
                                title: "Evolution progress",
                                detail: nil,
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
                    eyebrow: "Archive",
                    title: "Mascot keepsakes",
                    detail: nil,
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
                } footer: { EmptyView() }

                AtlasSectionCard(style: .elevated, title: "Recap studio") {
                    VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            Text("Audience")
                                .atlasTextRole(.deckEyebrow)
                                .foregroundStyle(atlasMascotLineTint(for: selection))

                            HStack(spacing: AtlasSpacing.small) {
                                ForEach(AtlasMascotRecapAudience.allCases, id: \.self) { audience in
                                    Button {
                                        recapCourtesySignal &+= 1
                                        AtlasFeedback.selection()
                                        recapAudience = audience
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(audience.title)
                                                .atlasTextRole(.cardBody)
                                                .foregroundStyle(AtlasPalette.textPrimary)
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
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
                                        recapCourtesySignal &+= 1
                                        AtlasFeedback.selection()
                                        recapPrivacyMode = privacyMode
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(privacyMode.title)
                                                .atlasTextRole(.cardBody)
                                                .foregroundStyle(AtlasPalette.textPrimary)
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
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
                                    Text(kind.title)
                                        .atlasTextRole(.cardBody)
                                        .foregroundStyle(AtlasPalette.textPrimary)

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
                                            recapCourtesySignal &+= 1
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
                        Text("Exported mascot recap cards are saved here.")
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
                                            if let sourceMomentTitle = archivedRecap.sourceMomentTitle {
                                                Text("Built from journal moment: \(sourceMomentTitle)")
                                                    .atlasTextRole(.metricLabel)
                                                    .foregroundStyle(atlasMascotLineTint(for: archivedRecap.selection))
                                            }
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
        .atlasAmbientMascotOpenReaction(model: model, kind: .openedMascot)
        .onChange(of: shareArtifact?.archiveRecord.id) { oldValue, newValue in
            guard oldValue != newValue,
                  newValue != nil else {
                return
            }
            model.triggerAmbientMascotReaction(.inspectReveal)
        }
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
            title: "Preparing the \(descriptor.kind.title.lowercased()).",
            detail: "Rendering the current recap card.",
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
                detail: "Saved and ready to share.",
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
                detail: "Reopened from the archive and ready to share again.",
                tint: atlasMascotLineTint(for: recap.selection),
                badge: recap.audience.title,
                symbolName: "photo.stack.fill"
            )
            model.triggerAmbientMascotReaction(.artifactReady)
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
                Text(recommendation.title)
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)

                if recommendation.detail.isEmpty == false {
                    Text(recommendation.detail)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
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
                .fill(AtlasPalette.surfaceSecondary)
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
    case .streakRescue:
        return AtlasMascotMomentPresentation(badge: "Recovery", tint: AtlasPalette.success)
    case .nearEvolution:
        return AtlasMascotMomentPresentation(badge: "Near unlock", tint: AtlasPalette.reward)
    case .archiveMilestone:
        return AtlasMascotMomentPresentation(badge: "Archive", tint: atlasMascotLineHighlight(for: moment.selection))
    case .focusCarryForward:
        return AtlasMascotMomentPresentation(badge: "Carry forward", tint: AtlasPalette.primary)
    case .quietConsistency:
        return AtlasMascotMomentPresentation(badge: "Consistency", tint: atlasMascotLineTint(for: moment.selection))
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
    let stageVoice = atlasMascotStageProgressVoice(selection: selection, stage: evolution.stage)
    guard let nextFormName = evolution.nextFormName,
          let nextThresholdPoints = evolution.nextThresholdPoints else {
        return AtlasMascotProgressionSummary(
            title: stageVoice.finalFormTitle,
            detail: archivedRecapCount == 0 ? "Archive ready." : "Archive updated.",
            badge: "Final form",
            symbolName: "crown.fill",
            tint: AtlasPalette.success
        )
    }

    let remainingPoints = max(nextThresholdPoints - rewardsSnapshot.totalPoints, 0)
    if remainingPoints == 0 || (evolution.progressFraction ?? 0) >= 0.86 {
        return AtlasMascotProgressionSummary(
            title: stageVoice.nearUnlockTitle(nextFormName: nextFormName),
            detail: stageVoice.nearUnlockDetail,
            badge: "Near unlock",
            symbolName: "sparkles",
            tint: atlasMascotLineTint(for: selection)
        )
    }

    if let latestMoment {
        return AtlasMascotProgressionSummary(
            title: latestMoment.title,
            detail: stageVoice.liveJourneyDetail,
            badge: "Latest moment",
            symbolName: latestMoment.symbolName,
            tint: atlasMascotLineTint(for: selection)
        )
    }

    return AtlasMascotProgressionSummary(
        title: stageVoice.inMotionTitle(nextFormName: nextFormName),
        detail: stageVoice.inMotionDetail,
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
            detail: latestMoment.title,
            readinessDetail: "",
            readinessValue: 0.88,
            tint: atlasMascotLineHighlight(for: selection)
        )
    }

    if evolution.nextFormName == nil {
        return AtlasMascotRecapRecommendation(
            kind: .evolutionMilestone,
            title: "Milestone export is now a proper final-form poster",
            detail: "",
            readinessDetail: "",
            readinessValue: 1,
            tint: AtlasPalette.success
        )
    }

    return AtlasMascotRecapRecommendation(
        kind: .weeklyRecap,
        title: "Weekly poster is the best export right now",
        detail: "",
        readinessDetail: "",
        readinessValue: max(evolution.progressFraction ?? 0.22, 0.22),
        tint: atlasMascotLineTint(for: selection)
    )
}

private let atlasMascotCollectibleKinds: Set<AtlasMascotMomentKind> = [
    .evolution,
    .levelUp,
    .nearEvolution,
    .archiveMilestone,
    .focusCarryForward,
    .weeklyCloseout,
    .recapExport
]

private func atlasMascotJournalSubtitle(selection: AtlasMascotSelection) -> String {
    switch selection {
    case .aetherion:
        return "Saved moments."
    case .aurielle:
        return "Saved moments."
    }
}

private func atlasMascotMomentContinuityLine(_ moment: AtlasMascotMomentRecord) -> String? {
    if let recapHeadline = moment.recapHeadline {
        return "Archived as: \(recapHeadline)"
    }
    switch moment.kind {
    case .archiveMilestone:
        return "The poster gallery just grew."
    case .focusCarryForward:
        return "This carries forward into next week's focus."
    case .nearEvolution:
        return "This is the clearest tease before the next unlock."
    default:
        return nil
    }
}

private func atlasMascotStagePathCopy(
    selection: AtlasMascotSelection,
    stage: AtlasMascotStage
) -> String {
    switch (selection, stage) {
    case (.aetherion, .stage1):
        return "Scrappy starting form with compressed storm energy and oversized intent."
    case (.aetherion, .stage2):
        return "Kinetic mid-form where the line learns to turn charge into disciplined motion."
    case (.aetherion, .stage3):
        return "Ceremonial guardian form with atlas-ring presence and permanent unlock status."
    case (.aurielle, .stage1):
        return "Bright starting form with soft reassurance and immediate charm."
    case (.aurielle, .stage2):
        return "Skybound middle form where the line grows more graceful, longer, and calmer."
    case (.aurielle, .stage3):
        return "Serene celestial guardian form with full halo presence and permanent unlock status."
    }
}

private struct AtlasMascotStageProgressVoice {
    let finalFormTitle: String
    let finalFormNoArchiveDetail: String
    let finalFormArchiveDetail: String
    let liveJourneyTitle: String
    let liveJourneyDetail: String
    let nearUnlockDetail: String
    let inMotionDetail: String

    func nearUnlockTitle(nextFormName: String) -> String {
        "\(nextFormName) is close enough to feel real"
    }

    func inMotionTitle(nextFormName: String) -> String {
        "\(nextFormName) is still the next major leap"
    }
}

private func atlasMascotStageProgressVoice(
    selection: AtlasMascotSelection,
    stage: AtlasMascotStage
) -> AtlasMascotStageProgressVoice {
    switch (selection, stage) {
    case (.aetherion, .stage1):
        return AtlasMascotStageProgressVoice(
            finalFormTitle: "The full guardian line is unlocked",
            finalFormNoArchiveDetail: "Archive ready.",
            finalFormArchiveDetail: "Archive updated.",
            liveJourneyTitle: "Latest moment",
            liveJourneyDetail: "Saved in the journal.",
            nearUnlockDetail: "The next form is almost unlocked.",
            inMotionDetail: "Progress is tracked quietly."
        )
    case (.aetherion, .stage2):
        return AtlasMascotStageProgressVoice(
            finalFormTitle: "The full guardian line is unlocked",
            finalFormNoArchiveDetail: "Archive ready.",
            finalFormArchiveDetail: "Archive updated.",
            liveJourneyTitle: "Latest moment",
            liveJourneyDetail: "Saved in the journal.",
            nearUnlockDetail: "The next form is almost unlocked.",
            inMotionDetail: "Progress is tracked quietly."
        )
    case (.aetherion, .stage3):
        return AtlasMascotStageProgressVoice(
            finalFormTitle: "The guardian line now lives through collectible history",
            finalFormNoArchiveDetail: "Archive ready.",
            finalFormArchiveDetail: "Archive updated.",
            liveJourneyTitle: "Latest moment",
            liveJourneyDetail: "Saved in the journal.",
            nearUnlockDetail: "This line is fully evolved.",
            inMotionDetail: "Progress is tracked quietly."
        )
    case (.aurielle, .stage1):
        return AtlasMascotStageProgressVoice(
            finalFormTitle: "The full guardian line is unlocked",
            finalFormNoArchiveDetail: "Archive ready.",
            finalFormArchiveDetail: "Archive updated.",
            liveJourneyTitle: "Latest moment",
            liveJourneyDetail: "Saved in the journal.",
            nearUnlockDetail: "The next form is almost unlocked.",
            inMotionDetail: "Progress is tracked quietly."
        )
    case (.aurielle, .stage2):
        return AtlasMascotStageProgressVoice(
            finalFormTitle: "The full guardian line is unlocked",
            finalFormNoArchiveDetail: "Archive ready.",
            finalFormArchiveDetail: "Archive updated.",
            liveJourneyTitle: "Latest moment",
            liveJourneyDetail: "Saved in the journal.",
            nearUnlockDetail: "The next form is almost unlocked.",
            inMotionDetail: "Progress is tracked quietly."
        )
    case (.aurielle, .stage3):
        return AtlasMascotStageProgressVoice(
            finalFormTitle: "The guardian line now lives through keepsakes",
            finalFormNoArchiveDetail: "Archive ready.",
            finalFormArchiveDetail: "Archive updated.",
            liveJourneyTitle: "Latest moment",
            liveJourneyDetail: "Saved in the journal.",
            nearUnlockDetail: "This line is fully evolved.",
            inMotionDetail: "Progress is tracked quietly."
        )
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
