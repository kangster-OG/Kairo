import Foundation

public struct AtlasMascotReactionSummary: Equatable, Sendable {
    public var title: String
    public var detail: String
    public var symbolName: String

    public init(title: String, detail: String, symbolName: String) {
        self.title = title
        self.detail = detail
        self.symbolName = symbolName
    }
}

public func atlasMascotSanitizedNickname(_ nickname: String?) -> String? {
    guard let nickname = nickname?.trimmingCharacters(in: .whitespacesAndNewlines),
          nickname.isEmpty == false else {
        return nil
    }
    return nickname
}

public func atlasMascotDisplayName(
    selection: AtlasMascotSelection,
    stage: AtlasMascotStage,
    nickname: String?
) -> String {
    atlasMascotSanitizedNickname(nickname) ?? selection.title(for: stage)
}

public func atlasMascotStatusLine(
    selection: AtlasMascotSelection,
    nickname: String?,
    rewardsSnapshot: AtlasRewardsSnapshot
) -> String {
    let stage = AtlasMascotMilestone.stage(for: rewardsSnapshot.totalPoints)
    let displayName = atlasMascotDisplayName(selection: selection, stage: stage, nickname: nickname)

    if stage == .stage3 {
        return "\(displayName) is settled into the final guardian form."
    }

    if let nextThreshold = AtlasMascotMilestone.nextThreshold(after: stage) {
        let remaining = max(nextThreshold - rewardsSnapshot.totalPoints, 0)
        if remaining <= 120 {
            let nextForm = stage == .stage1 ? selection.stage2Title : selection.stage3Title
            return "\(displayName) can feel \(nextForm) getting close."
        }
    }

    if let unmetGoal = rewardsSnapshot.goals.first(where: { $0.isMet == false }) {
        return "\(displayName) is growing with every step toward \(unmetGoal.title.lowercased())."
    }

    if let activeStreak = rewardsSnapshot.streaks.first(where: { $0.isActive }) {
        return "\(displayName) is keeping pace with your \(activeStreak.title.lowercased()) streak."
    }

    return "\(displayName) is growing quietly with every rewards milestone."
}

public func atlasMascotReactionSummary(
    selection: AtlasMascotSelection,
    nickname: String?,
    rewardsSnapshot: AtlasRewardsSnapshot,
    history: [AtlasMascotEvolutionRecord]
) -> AtlasMascotReactionSummary? {
    let stage = AtlasMascotMilestone.stage(for: rewardsSnapshot.totalPoints)
    let displayName = atlasMascotDisplayName(selection: selection, stage: stage, nickname: nickname)
    let selectionHistory = history.filter { $0.selection == selection }

    if let latestEvolution = selectionHistory.first, latestEvolution.stage == stage, stage != .stage1 {
        return AtlasMascotReactionSummary(
            title: "\(displayName) just evolved",
            detail: "\(selection.title(for: stage)) unlocked and is taking the lead.",
            symbolName: "sparkles"
        )
    }

    if let earnedBadge = rewardsSnapshot.badges.first(where: { $0.isEarned }) {
        return AtlasMascotReactionSummary(
            title: "\(displayName) is celebrating",
            detail: "The latest unlocked badge is \(earnedBadge.title).",
            symbolName: "rosette"
        )
    }

    if let metGoal = rewardsSnapshot.goals.first(where: { $0.isMet }) {
        return AtlasMascotReactionSummary(
            title: "\(displayName) is fired up",
            detail: "You closed \(metGoal.title), and the mascot noticed.",
            symbolName: "flag.checkered"
        )
    }

    if let activeStreak = rewardsSnapshot.streaks.first(where: { $0.isActive }) {
        return AtlasMascotReactionSummary(
            title: "\(displayName) is staying sharp",
            detail: "Your \(activeStreak.title.lowercased()) streak is keeping momentum alive.",
            symbolName: "flame"
        )
    }

    return nil
}

public func atlasMascotSharedPose(
    rewardsSnapshot: AtlasRewardsSnapshot,
    latestMoment: AtlasMascotMomentRecord? = nil
) -> AtlasSharedMascotPose {
    let stage = AtlasMascotMilestone.stage(for: rewardsSnapshot.totalPoints)

    if let latestMoment, latestMoment.stage == stage {
        switch latestMoment.kind {
        case .evolution, .badge, .goal, .levelUp:
            return .milestone
        case .streak:
            if latestMoment.eventKey?.hasSuffix("-1") == true {
                return .recovery
            }
            return .happy
        case .weeklyCloseout, .recapExport:
            return .happy
        case .interaction, .shortcut:
            break
        }
    }

    if let nextThreshold = AtlasMascotMilestone.nextThreshold(after: stage),
       max(nextThreshold - rewardsSnapshot.totalPoints, 0) <= 75 {
        return .evolutionReady
    }

    if rewardsSnapshot.badges.contains(where: \.isEarned) || rewardsSnapshot.goals.contains(where: \.isMet) {
        return .milestone
    }

    if rewardsSnapshot.streaks.contains(where: { $0.isActive && $0.count == 1 }) {
        return .recovery
    }

    if rewardsSnapshot.streaks.contains(where: \.isActive) {
        return .happy
    }

    if rewardsSnapshot.totalPoints < 80 {
        return .rest
    }

    return .idle
}
