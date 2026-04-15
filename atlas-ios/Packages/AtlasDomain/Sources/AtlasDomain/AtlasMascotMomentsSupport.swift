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
    let displayName = atlasMascotDisplayName(selection: selection, stage: stage, nickname: nickname)
    let formName = selection.title(for: stage)
    let stageVoice = atlasMascotStageVoice(selection: selection, stage: stage)

    let title: String
    let detail: String
    let symbolName: String
    switch kind {
    case .interaction:
        title = response.title
        detail = response.detail
        symbolName = response.symbolName
    case .shortcut:
        title = "\(displayName) answered a shortcut check-in"
        detail = "\(stageVoice.shortcutLead) \(formName) logged a fast system touchpoint without breaking momentum."
        symbolName = selection == .aetherion ? "bolt.badge.checkmark.fill" : "star.bubble.fill"
    case .levelUp:
        title = "\(displayName) climbed into a new rewards tier"
        detail = stageVoice.levelUpDetail
        symbolName = selection == .aetherion ? "arrow.up.right.circle.fill" : "sparkles"
    case .streakRescue:
        title = stageVoice.streakRescueTitle(displayName: displayName)
        detail = stageVoice.streakRescueDetail
        symbolName = "arrow.clockwise.circle.fill"
    case .nearEvolution:
        title = stageVoice.nearEvolutionTitle(displayName: displayName)
        detail = stageVoice.nearEvolutionDetail
        symbolName = selection == .aetherion ? "sparkles" : "moon.stars.fill"
    case .archiveMilestone:
        title = stageVoice.archiveMilestoneTitle(displayName: displayName)
        detail = stageVoice.archiveMilestoneDetail
        symbolName = selection == .aetherion ? "photo.stack.fill" : "square.stack.3d.up.fill"
    case .focusCarryForward:
        title = stageVoice.focusCarryForwardTitle(displayName: displayName)
        detail = stageVoice.focusCarryForwardDetail
        symbolName = selection == .aetherion ? "scope" : "sparkle.magnifyingglass"
    case .quietConsistency:
        title = stageVoice.quietConsistencyTitle(displayName: displayName)
        detail = stageVoice.quietConsistencyDetail
        symbolName = selection == .aetherion ? "bolt.heart.fill" : "heart.text.square.fill"
    case .weeklyCloseout:
        title = "\(displayName) anchored the week"
        detail = stageVoice.weeklyCloseoutDetail
        symbolName = selection == .aetherion ? "checkmark.seal.fill" : "moon.stars.fill"
    case .recapExport:
        title = "\(displayName) published a recap poster"
        detail = stageVoice.recapExportDetail
        symbolName = selection == .aetherion ? "square.and.arrow.up.fill" : "photo.stack.fill"
    case .evolution:
        title = "\(displayName) settled into \(formName)"
        detail = stageVoice.evolutionDetail
        symbolName = "sparkles"
    case .badge:
        title = "\(displayName) marked a new badge"
        detail = stageVoice.badgeDetail
        symbolName = response.symbolName
    case .goal:
        title = "\(displayName) noticed a goal closeout"
        detail = stageVoice.goalDetail
        symbolName = "flag.checkered"
    case .streak:
        title = "\(displayName) kept the line in motion"
        detail = stageVoice.streakDetail
        symbolName = selection == .aetherion ? "flame.fill" : "wind"
    }

    return AtlasMascotMomentRecord(
        selection: selection,
        stage: stage,
        kind: kind,
        title: title,
        detail: detail,
        symbolName: symbolName,
        recordedAt: atlasMascotMomentTimestamp(from: recordedAt),
        eventKey: nil
    )
}

public func atlasMascotAutomaticMomentCandidates(
    selection: AtlasMascotSelection,
    nickname: String?,
    rewardsSnapshot: AtlasRewardsSnapshot,
    evolutionHistory: [AtlasMascotEvolutionRecord],
    archivedRecaps: [AtlasMascotArchivedRecapRecord],
    existingMoments: [AtlasMascotMomentRecord],
    recordedAt: Date
) -> [AtlasMascotMomentRecord] {
    let stage = AtlasMascotMilestone.stage(for: rewardsSnapshot.totalPoints)
    let displayName = atlasMascotDisplayName(selection: selection, stage: stage, nickname: nickname)
    let stageVoice = atlasMascotStageVoice(selection: selection, stage: stage)
    let existingKeys = Set(existingMoments.compactMap(\.eventKey))
    let selectionHistory = evolutionHistory.filter { $0.selection == selection }
    let selectionRecaps = archivedRecaps.filter { $0.selection == selection }
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

    if rewardsSnapshot.level > 1 {
        appendCandidate(
            kind: .levelUp,
            eventKey: "level-\(selection.rawValue)-\(rewardsSnapshot.level)",
            title: "\(displayName) reached level \(rewardsSnapshot.level)",
            detail: stageVoice.levelUpDetail,
            symbolName: selection == .aetherion ? "arrow.up.right.circle.fill" : "sparkles"
        )
    }

    for badge in rewardsSnapshot.badges where badge.isEarned {
        appendCandidate(
            kind: .badge,
            eventKey: "badge-\(selection.rawValue)-\(badge.kind.rawValue)",
            title: "\(displayName) celebrated \(badge.title)",
            detail: "\(stageVoice.badgeDetail) \(badge.subtitle)",
            symbolName: badge.symbolName
        )
    }

    for goal in rewardsSnapshot.goals where goal.isMet {
        appendCandidate(
            kind: .goal,
            eventKey: "goal-\(selection.rawValue)-\(goal.kind.rawValue)",
            title: "\(displayName) noticed a goal closeout",
            detail: "\(goal.title) is complete. \(goal.progressLabel) \(stageVoice.goalTail)",
            symbolName: goal.symbolName
        )
    }

    let streakMilestones = Set([1, 3, 7, 14, 30])
    for streak in rewardsSnapshot.streaks where streak.isActive && streakMilestones.contains(streak.count) {
        let title: String
        let detail: String
        let symbolName: String
        let kind: AtlasMascotMomentKind
        if streak.count == 1 {
            title = stageVoice.streakRescueTitle(displayName: displayName)
            detail = "\(streak.title) is back on track. \(stageVoice.streakRescueDetail)"
            symbolName = "arrow.clockwise.circle.fill"
            kind = .streakRescue
        } else {
            title = "\(displayName) kept a streak alive"
            detail = "\(streak.title) reached \(streak.valueLabel.lowercased()). \(stageVoice.streakDetail)"
            symbolName = streak.symbolName
            kind = .streak
        }

        appendCandidate(
            kind: kind,
            eventKey: "streak-\(selection.rawValue)-\(streak.kind.rawValue)-\(streak.count)",
            title: title,
            detail: detail,
            symbolName: symbolName
        )
    }

    if let nextThreshold = AtlasMascotMilestone.nextThreshold(after: stage), stage != .stage3 {
        let remaining = max(nextThreshold - rewardsSnapshot.totalPoints, 0)
        let progressFraction = min(max(Double(rewardsSnapshot.totalPoints - atlasMascotStageFloorPoints(for: stage)) / Double(max(nextThreshold - atlasMascotStageFloorPoints(for: stage), 1)), 0), 1)
        if remaining > 0, remaining <= 120 || progressFraction >= 0.82 {
            appendCandidate(
                kind: .nearEvolution,
                eventKey: "near-evolution-\(selection.rawValue)-\(stage.rawValue)-\(nextThreshold)",
                title: stageVoice.nearEvolutionTitle(displayName: displayName),
                detail: "\(stageVoice.nearEvolutionDetail) Only \(remaining) points remain.",
                symbolName: selection == .aetherion ? "sparkles" : "moon.stars.fill"
            )
        }
    }

    let archiveMilestones = Set([1, 3, 5, 10])
    if archiveMilestones.contains(selectionRecaps.count) {
        appendCandidate(
            kind: .archiveMilestone,
            eventKey: "archive-\(selection.rawValue)-\(selectionRecaps.count)",
            title: stageVoice.archiveMilestoneTitle(displayName: displayName),
            detail: "\(stageVoice.archiveMilestoneDetail) Gallery count: \(selectionRecaps.count).",
            symbolName: selection == .aetherion ? "photo.stack.fill" : "square.stack.3d.up.fill"
        )
    }

    let activeStreak = rewardsSnapshot.streaks.filter(\.isActive).map(\.count).max() ?? 0
    let metGoals = rewardsSnapshot.goals.filter(\.isMet).count
    if activeStreak >= 5, metGoals >= 1 {
        let consistencyBucket = activeStreak >= 21 ? 21 : activeStreak >= 10 ? 10 : 5
        appendCandidate(
            kind: .quietConsistency,
            eventKey: "consistency-\(selection.rawValue)-\(stage.rawValue)-\(consistencyBucket)",
            title: stageVoice.quietConsistencyTitle(displayName: displayName),
            detail: stageVoice.quietConsistencyDetail,
            symbolName: selection == .aetherion ? "bolt.heart.fill" : "heart.text.square.fill"
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
    case .streak, .streakRescue:
        guard moment.eventKey?.hasSuffix("-1") == true || moment.kind == .streakRescue else {
            return nil
        }
        return AtlasMascotNotificationRequest(
            identifier: "atlas.mascot.\(moment.selection.rawValue).\(moment.eventKey ?? moment.id)",
            title: moment.title,
            body: moment.detail,
            triggerAt: referenceDate.addingTimeInterval(5)
        )
    case .nearEvolution, .archiveMilestone, .focusCarryForward, .weeklyCloseout, .recapExport:
        return AtlasMascotNotificationRequest(
            identifier: "atlas.mascot.\(moment.selection.rawValue).\(moment.eventKey ?? moment.id)",
            title: moment.title,
            body: moment.detail,
            triggerAt: referenceDate.addingTimeInterval(5)
        )
    case .interaction, .badge, .goal, .quietConsistency, .shortcut, .levelUp:
        return nil
    }
}

private struct AtlasMascotStageVoice {
    let shortcutLead: String
    let levelUpDetail: String
    let evolutionDetail: String
    let badgeDetail: String
    let goalDetail: String
    let goalTail: String
    let streakDetail: String
    let streakRescueDetail: String
    let nearEvolutionDetail: String
    let archiveMilestoneDetail: String
    let focusCarryForwardDetail: String
    let quietConsistencyDetail: String
    let weeklyCloseoutDetail: String
    let recapExportDetail: String

    func streakRescueTitle(displayName: String) -> String {
        "\(displayName) recovered the line"
    }

    func nearEvolutionTitle(displayName: String) -> String {
        "\(displayName) can almost be seen in the next form"
    }

    func archiveMilestoneTitle(displayName: String) -> String {
        "\(displayName) added another collectible poster"
    }

    func focusCarryForwardTitle(displayName: String) -> String {
        "\(displayName) carried the weekly focus forward"
    }

    func quietConsistencyTitle(displayName: String) -> String {
        "\(displayName) kept the rhythm alive"
    }
}

private func atlasMascotStageVoice(
    selection: AtlasMascotSelection,
    stage: AtlasMascotStage
) -> AtlasMascotStageVoice {
    switch (selection, stage) {
    case (.aetherion, .stage1):
        return AtlasMascotStageVoice(
            shortcutLead: "Cindlet likes compact check-ins.",
            levelUpDetail: "Cindlet tightened its stance and started showing more contained power between milestones.",
            evolutionDetail: "Cindlet now carries enough stored charge to hint at Voltflare's faster silhouette.",
            badgeDetail: "Cindlet treats every badge like another shard of stormglass in the line.",
            goalDetail: "Cindlet read the closeout as proof that the line can keep its footing.",
            goalTail: "The little guardian is starting to trust the pattern.",
            streakDetail: "Cindlet is learning that repeated steps are how contained power becomes reliable force.",
            streakRescueDetail: "The line snapped back into place before the spark cooled.",
            nearEvolutionDetail: "Voltflare is starting to press through the edges of the current form.",
            archiveMilestoneDetail: "Even the earliest storm notes are starting to look collectible instead of incidental.",
            focusCarryForwardDetail: "Cindlet kept the target pinned instead of letting the week scatter.",
            quietConsistencyDetail: "The line stayed compact, repeatable, and harder to knock off course.",
            weeklyCloseoutDetail: "Weekly Review closed with a deliberate checkpoint, giving the next unlock a cleaner runway.",
            recapExportDetail: "A mascot recap left Atlas as a proper milestone artifact."
        )
    case (.aetherion, .stage2):
        return AtlasMascotStageVoice(
            shortcutLead: "Voltflare answers quickly and wants the momentum kept moving.",
            levelUpDetail: "Voltflare sharpened the storm arc and locked in a faster posture for the next unlock.",
            evolutionDetail: "Voltflare looks disciplined now, like the line learned how to turn charge into direction.",
            badgeDetail: "Voltflare treats badges like field marks proving the line can stay kinetic under load.",
            goalDetail: "Voltflare reads the closeout as another clean push toward Aetherion.",
            goalTail: "The line feels more deliberate, not just more active.",
            streakDetail: "Voltflare thrives when the line keeps a diagonal, forward-moving rhythm.",
            streakRescueDetail: "The line recovered without losing its edge.",
            nearEvolutionDetail: "Aetherion is starting to show through the storm in ceremonial flashes.",
            archiveMilestoneDetail: "The gallery is turning moving storm energy into a credible line history.",
            focusCarryForwardDetail: "Voltflare kept the next objective locked in front instead of letting it drift.",
            quietConsistencyDetail: "The storm stayed disciplined long enough to feel earned, not accidental.",
            weeklyCloseoutDetail: "Weekly Review closed with a sharper checkpoint, making the next reveal feel closer and more deserved.",
            recapExportDetail: "A mascot recap turned this stretch of kinetic progress into a collector-grade poster."
        )
    case (.aetherion, .stage3):
        return AtlasMascotStageVoice(
            shortcutLead: "Aetherion accepts a shortcut like a sealed ritual rather than a scramble.",
            levelUpDetail: "Aetherion widened its ceremonial halo and made the full line feel alive after final evolution.",
            evolutionDetail: "Aetherion now reads as a settled guardian, not merely a finished unlock.",
            badgeDetail: "Aetherion records badges like inscriptions on a completed guardian line.",
            goalDetail: "Aetherion treats each closeout like proof that the line can protect the pace it built.",
            goalTail: "The full form is now maintained by intention, not anticipation.",
            streakDetail: "Aetherion makes consistency feel stately, like the storm has learned how to hold shape.",
            streakRescueDetail: "Even a broken rhythm was brought back under the guardian's control.",
            nearEvolutionDetail: "The line is fully evolved, so the next tease is no longer about form but about collectible presence.",
            archiveMilestoneDetail: "The gallery is becoming a ceremonial history for the fully formed guardian.",
            focusCarryForwardDetail: "Aetherion carried the focus forward like an oath instead of a reminder.",
            quietConsistencyDetail: "The line now feels governed, protected, and quietly formidable.",
            weeklyCloseoutDetail: "Weekly Review closed like a formal seal, turning the week into part of the guardian record.",
            recapExportDetail: "A mascot recap turned final-form momentum into a polished ceremonial artifact."
        )
    case (.aurielle, .stage1):
        return AtlasMascotStageVoice(
            shortcutLead: "Moppet likes gentle check-ins that do not add friction.",
            levelUpDetail: "Moppet brightened and stood a little taller, like the first real rhythm finally arrived.",
            evolutionDetail: "Moppet now feels ready to stretch into Glisshare's longer, more skybound motion.",
            badgeDetail: "Moppet treats badges like tiny lights proving the line keeps finding its way back.",
            goalDetail: "Moppet reads the closeout as reassurance that the week can stay soft and steady.",
            goalTail: "The little guardian is learning to trust repetition.",
            streakDetail: "Moppet loves gentle repetition because it turns check-ins into familiarity instead of pressure.",
            streakRescueDetail: "The light came back before the week went dim.",
            nearEvolutionDetail: "Glisshare is beginning to show in the length and lift of the line.",
            archiveMilestoneDetail: "The gallery is starting to feel like a box of keepsakes instead of stray exports.",
            focusCarryForwardDetail: "Moppet kept the weekly focus visible so the next week starts with less fog.",
            quietConsistencyDetail: "The line stayed bright and reliable without needing a dramatic unlock.",
            weeklyCloseoutDetail: "Weekly Review closed with a calm handoff, turning the week into a collectible chapter instead of admin.",
            recapExportDetail: "A mascot recap turned the latest momentum into a shareable keepsake."
        )
    case (.aurielle, .stage2):
        return AtlasMascotStageVoice(
            shortcutLead: "Glisshare answers quietly, then keeps gliding.",
            levelUpDetail: "Glisshare widened the arc around the next unlock and settled into a more graceful, rising rhythm.",
            evolutionDetail: "Glisshare now looks fully skybound, like the line learned how to carry light without dropping it.",
            badgeDetail: "Glisshare treats badges like bright markers left along a clean flight path.",
            goalDetail: "Glisshare reads the closeout as another smooth step toward Aurielle.",
            goalTail: "The line looks calmer because it is more practiced.",
            streakDetail: "Glisshare makes streaks feel like glide paths instead of grind.",
            streakRescueDetail: "The line found the breeze again before losing altitude.",
            nearEvolutionDetail: "Aurielle is beginning to appear in the halo and the longer, guardian-like silhouette.",
            archiveMilestoneDetail: "The gallery is turning soft weekly progress into a collectible sky journal.",
            focusCarryForwardDetail: "Glisshare carried the focus into the next week without breaking the calm cadence.",
            quietConsistencyDetail: "The line kept lifting in quiet increments that still feel unmistakably earned.",
            weeklyCloseoutDetail: "Weekly Review closed with a skybound handoff, preserving the week as momentum instead of paperwork.",
            recapExportDetail: "A mascot recap turned the line's quiet ascent into a premium keepsake."
        )
    case (.aurielle, .stage3):
        return AtlasMascotStageVoice(
            shortcutLead: "Aurielle answers gently, like the room already knew where the next step belonged.",
            levelUpDetail: "Aurielle widened the halo and made the fully evolved line feel serene rather than static.",
            evolutionDetail: "Aurielle now reads like a true guardian presence, composed enough to make progress feel ceremonial.",
            badgeDetail: "Aurielle treats badges like stars woven into a finished night sky.",
            goalDetail: "Aurielle reads the closeout as proof that clarity can keep carrying the line forward.",
            goalTail: "The guardian presence now feels settled and intentional.",
            streakDetail: "Aurielle makes consistency feel luminous, like calm that chose to stay.",
            streakRescueDetail: "The line found its light again without drama.",
            nearEvolutionDetail: "The line is fully evolved now, so anticipation turns into preservation and collectible memory.",
            archiveMilestoneDetail: "The gallery is becoming a constellation of finished guardian moments.",
            focusCarryForwardDetail: "Aurielle carried the focus forward like a lantern instead of a task list.",
            quietConsistencyDetail: "The line stayed serene, visible, and deeply dependable.",
            weeklyCloseoutDetail: "Weekly Review closed like a soft seal, preserving the week as part of the guardian's story.",
            recapExportDetail: "A mascot recap turned the latest guardian moment into a polished celestial keepsake."
        )
    }
}

private func atlasMascotStageFloorPoints(for stage: AtlasMascotStage) -> Int {
    switch stage {
    case .stage1:
        return 0
    case .stage2:
        return AtlasMascotMilestone.stage2Points
    case .stage3:
        return AtlasMascotMilestone.stage3Points
    }
}
