import Foundation

public func atlasMascotInteractionResponse(
    selection: AtlasMascotSelection,
    stage: AtlasMascotStage,
    nickname: String?
) -> AtlasMascotReactionSummary {
    let displayName = atlasMascotDisplayName(selection: selection, stage: stage, nickname: nickname)

    switch (selection, stage) {
    case (.aetherion, .stage1):
        return AtlasMascotReactionSummary(
            title: "\(displayName) sharpens up",
            detail: "Cindlet flares brighter when you check in.",
            symbolName: "bolt.fill"
        )
    case (.aetherion, .stage2):
        return AtlasMascotReactionSummary(
            title: "\(displayName) leans forward",
            detail: "Voltflare is ready to sprint into the next milestone.",
            symbolName: "flame.fill"
        )
    case (.aetherion, .stage3):
        return AtlasMascotReactionSummary(
            title: "\(displayName) steadies the storm",
            detail: "Aetherion answers with a calm pulse of power.",
            symbolName: "sparkles"
        )
    case (.aurielle, .stage1):
        return AtlasMascotReactionSummary(
            title: "\(displayName) perks up",
            detail: "Moppet brightens the moment when you stop by.",
            symbolName: "star.fill"
        )
    case (.aurielle, .stage2):
        return AtlasMascotReactionSummary(
            title: "\(displayName) glides closer",
            detail: "Glisshare mirrors your momentum with quiet focus.",
            symbolName: "wind"
        )
    case (.aurielle, .stage3):
        return AtlasMascotReactionSummary(
            title: "\(displayName) settles the room",
            detail: "Aurielle answers with a calm halo of light.",
            symbolName: "moon.stars.fill"
        )
    }
}

public func atlasMascotManualMoment(
    selection: AtlasMascotSelection,
    nickname: String?,
    stage: AtlasMascotStage,
    kind: AtlasMascotMomentKind,
    recordedAt: Date
) -> AtlasMascotMomentRecord {
    let response = atlasMascotInteractionResponse(
        selection: selection,
        stage: stage,
        nickname: nickname
    )

    return AtlasMascotMomentRecord(
        selection: selection,
        stage: stage,
        kind: kind,
        title: response.title,
        detail: response.detail,
        symbolName: response.symbolName,
        recordedAt: atlasMascotMomentTimestamp(from: recordedAt),
        eventKey: nil
    )
}

public func atlasMascotAutomaticMomentCandidates(
    selection: AtlasMascotSelection,
    nickname: String?,
    rewardsSnapshot: AtlasRewardsSnapshot,
    evolutionHistory: [AtlasMascotEvolutionRecord],
    existingMoments: [AtlasMascotMomentRecord],
    recordedAt: Date
) -> [AtlasMascotMomentRecord] {
    let stage = AtlasMascotMilestone.stage(for: rewardsSnapshot.totalPoints)
    let displayName = atlasMascotDisplayName(selection: selection, stage: stage, nickname: nickname)
    let existingKeys = Set(existingMoments.compactMap(\.eventKey))
    let selectionHistory = evolutionHistory.filter { $0.selection == selection }
    var candidates: [AtlasMascotMomentRecord] = []

    func appendCandidate(
        kind: AtlasMascotMomentKind,
        eventKey: String,
        title: String,
        detail: String,
        symbolName: String,
        stage: AtlasMascotStage = stage
    ) {
        guard existingKeys.contains(eventKey) == false else {
            return
        }
        candidates.append(
            AtlasMascotMomentRecord(
                selection: selection,
                stage: stage,
                kind: kind,
                title: title,
                detail: detail,
                symbolName: symbolName,
                recordedAt: atlasMascotMomentTimestamp(from: recordedAt),
                eventKey: eventKey
            )
        )
    }

    if let latestEvolution = selectionHistory.first, latestEvolution.stage == stage, stage != .stage1 {
        appendCandidate(
            kind: .evolution,
            eventKey: "evolution-\(selection.rawValue)-\(stage.rawValue)",
            title: "\(displayName) reached \(selection.title(for: stage))",
            detail: "A new evolution unlocked at \(rewardsSnapshot.totalPoints) rewards points.",
            symbolName: "sparkles",
            stage: stage
        )
    }

    for badge in rewardsSnapshot.badges where badge.isEarned {
        appendCandidate(
            kind: .badge,
            eventKey: "badge-\(selection.rawValue)-\(badge.kind.rawValue)",
            title: "\(displayName) celebrated \(badge.title)",
            detail: badge.subtitle,
            symbolName: badge.symbolName
        )
    }

    for goal in rewardsSnapshot.goals where goal.isMet {
        appendCandidate(
            kind: .goal,
            eventKey: "goal-\(selection.rawValue)-\(goal.kind.rawValue)",
            title: "\(displayName) noticed a goal closeout",
            detail: "\(goal.title) is complete. \(goal.progressLabel)",
            symbolName: goal.symbolName
        )
    }

    let streakMilestones = Set([1, 3, 7, 14, 30])
    for streak in rewardsSnapshot.streaks where streak.isActive && streakMilestones.contains(streak.count) {
        let title: String
        let detail: String
        let symbolName: String
        if streak.count == 1 {
            title = "\(displayName) restarted a streak"
            detail = "\(streak.title) is back on track."
            symbolName = "arrow.clockwise.circle.fill"
        } else {
            title = "\(displayName) kept a streak alive"
            detail = "\(streak.title) reached \(streak.valueLabel.lowercased())."
            symbolName = streak.symbolName
        }

        appendCandidate(
            kind: .streak,
            eventKey: "streak-\(selection.rawValue)-\(streak.kind.rawValue)-\(streak.count)",
            title: title,
            detail: detail,
            symbolName: symbolName
        )
    }

    return candidates
}

public func atlasMascotMomentTimestamp(from date: Date) -> String {
    ISO8601DateFormatter.atlas.string(from: date)
}

public func atlasMascotNotificationRequest(
    for moment: AtlasMascotMomentRecord,
    referenceDate: Date
) -> AtlasMascotNotificationRequest? {
    switch moment.kind {
    case .evolution:
        return AtlasMascotNotificationRequest(
            identifier: "atlas.mascot.\(moment.selection.rawValue).\(moment.eventKey ?? moment.id)",
            title: moment.title,
            body: moment.detail,
            triggerAt: referenceDate.addingTimeInterval(5)
        )
    case .streak:
        guard moment.eventKey?.hasSuffix("-1") == true else {
            return nil
        }
        return AtlasMascotNotificationRequest(
            identifier: "atlas.mascot.\(moment.selection.rawValue).\(moment.eventKey ?? moment.id)",
            title: moment.title,
            body: moment.detail,
            triggerAt: referenceDate.addingTimeInterval(5)
        )
    case .interaction, .badge, .goal, .shortcut:
        return nil
    }
}
