import AtlasDomain
import Foundation
import GRDB

public struct GRDBRewardsRepository: RewardsRepository, Sendable {
    let stack: AtlasDatabaseStack

    init(stack: AtlasDatabaseStack) {
        self.stack = stack
    }

    public func fetchRewardsSnapshot(referenceDate: Date) async throws -> AtlasRewardsSnapshot {
        try await stack.canonical.read { db in
            try buildRewardsSnapshot(db: db, referenceDate: referenceDate)
        }
    }
}

func buildRewardsSnapshot(
    db: Database,
    referenceDate: Date
) throws -> AtlasRewardsSnapshot {
    let settings = try readRewardsSettings(db: db)
    guard settings.enabled else {
        return AtlasRewardsSnapshot(settings: settings)
    }

    let logEvents = try AtlasLogEventDBRecord.fetchAll(db).map(\.domain)
    let contextLogs = try AtlasContextLogDBRecord.fetchAll(db).map(\.domain)
    let symptomLogs = try AtlasSymptomLogDBRecord.fetchAll(db).map(\.domain)
    let weightLogs = try AtlasWeightLogDBRecord.fetchAll(db).map(\.domain)
    let customMetrics = try AtlasCustomMetricDBRecord.fetchAll(db).map(\.domain)
    let metricLogs = try AtlasMetricValueLogDBRecord.fetchAll(db).map(\.domain)
    let workoutLogs = try AtlasWorkoutLogDBRecord.fetchAll(db).map(\.domain)
    let onboardingDraft = try readRewardsOnboardingDraft(db: db)

    let streaks = buildRewardStreaks(
        referenceDate: referenceDate,
        settings: settings,
        logEvents: logEvents,
        contextLogs: contextLogs,
        symptomLogs: symptomLogs,
        weightLogs: weightLogs,
        customMetrics: customMetrics,
        metricLogs: metricLogs,
        workoutLogs: workoutLogs
    )
    let goals = buildRewardGoals(
        referenceDate: referenceDate,
        settings: settings,
        customMetrics: customMetrics,
        metricLogs: metricLogs,
        workoutLogs: workoutLogs,
        weightLogs: weightLogs,
        onboardingDraft: onboardingDraft
    )
    let badges = buildRewardBadges(streaks: streaks, goals: goals)
    let totalPoints = buildRewardPoints(streaks: streaks, goals: goals, badges: badges)
    let level = max((totalPoints / 250) + 1, 1)

    return AtlasRewardsSnapshot(
        settings: settings,
        totalPoints: totalPoints,
        level: level,
        nextLevelPoints: level * 250,
        streaks: streaks,
        goals: goals,
        badges: badges,
        note: "Rewards stay local to Atlas. Self-defined goals use Yes/No custom metrics, workouts reward completion, and weight milestones stay descriptive."
    )
}

private func buildRewardStreaks(
    referenceDate: Date,
    settings: AtlasRewardsSettingsSnapshot,
    logEvents: [AtlasLogEventRecord],
    contextLogs: [AtlasContextLogRecord],
    symptomLogs: [AtlasSymptomLogRecord],
    weightLogs: [AtlasWeightLogRecord],
    customMetrics: [AtlasCustomMetricRecord],
    metricLogs: [AtlasMetricValueLogRecord],
    workoutLogs: [AtlasWorkoutLogRecord]
) -> [AtlasRewardStreakSnapshot] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: referenceDate)
    let activityDays = Set(
        logEvents.map { calendar.startOfDay(for: atlasDate(from: $0.loggedAt)) }
            + contextLogs.map { calendar.startOfDay(for: atlasDate(from: $0.loggedAt)) }
            + symptomLogs.map { calendar.startOfDay(for: atlasDate(from: $0.loggedAt)) }
            + weightLogs.map { calendar.startOfDay(for: atlasDate(from: $0.loggedAt)) }
            + metricLogs.map { calendar.startOfDay(for: atlasDate(from: $0.loggedAt)) }
            + workoutLogs.map { calendar.startOfDay(for: atlasDate(from: $0.startedAt)) }
    )
    let activityStreak = atlasRewardsConsecutiveDayCount(days: activityDays, endingAt: today)
    let currentWeek = atlasRewardsWeekIdentifier(for: referenceDate)
    let activeBooleanMetrics = customMetrics
        .filter { $0.archivedAt == nil && $0.valueType == .boolean }
        .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }

    var weeklyWorkoutCounts: [String: Int] = [:]
    var weeklySelfGoalCompletions: [String: Set<String>] = [:]
    for workout in workoutLogs {
        let weekID = atlasRewardsWeekIdentifier(fromTimestamp: workout.startedAt)
        weeklyWorkoutCounts[weekID, default: 0] += 1
    }
    let activeGoalIDs = Set(activeBooleanMetrics.map(\.id))
    for log in metricLogs where log.booleanValue == true && activeGoalIDs.contains(log.metricId) {
        let weekID = atlasRewardsWeekIdentifier(fromTimestamp: log.loggedAt)
        weeklySelfGoalCompletions[weekID, default: []].insert(log.metricId)
    }

    let workoutGoalWeeks = Set(
        weeklyWorkoutCounts.compactMap { key, value in
            value >= settings.weeklyWorkoutGoal ? key : nil
        }
    )
    let selfGoalTarget = atlasRewardsEffectiveGoalTarget(
        configuredTarget: settings.weeklySelfGoalTarget,
        availableGoalCount: activeBooleanMetrics.count
    )
    let selfGoalWeeks = Set(
        weeklySelfGoalCompletions.compactMap { key, value in
            selfGoalTarget > 0 && value.count >= selfGoalTarget ? key : nil
        }
    )
    let workoutWeekStreak = atlasRewardsConsecutiveWeekCount(weeks: workoutGoalWeeks, endingAt: referenceDate)
    let selfGoalWeekStreak = atlasRewardsConsecutiveWeekCount(weeks: selfGoalWeeks, endingAt: referenceDate)
    let currentWeekSelfGoalCount = weeklySelfGoalCompletions[currentWeek, default: []].count

    return [
        AtlasRewardStreakSnapshot(
            kind: .activityDays,
            title: "Daily streak",
            valueLabel: "\(activityStreak) day\(activityStreak == 1 ? "" : "s")",
            helperText: activityStreak > 0
                ? "Any check-in, context entry, symptom, metric, workout, or weight log keeps this daily streak alive."
                : "Log something today to start your daily streak.",
            symbolName: "flame.fill",
            count: activityStreak,
            isActive: activityDays.contains(today)
        ),
        AtlasRewardStreakSnapshot(
            kind: .workoutWeeks,
            title: "Workout streak",
            valueLabel: "\(workoutWeekStreak) week\(workoutWeekStreak == 1 ? "" : "s")",
            helperText: weeklyWorkoutCounts[currentWeek, default: 0] >= settings.weeklyWorkoutGoal
                ? "This week already cleared your workout target of \(settings.weeklyWorkoutGoal)."
                : "Hit \(settings.weeklyWorkoutGoal) workouts this week to extend the workout streak.",
            symbolName: "figure.run.circle.fill",
            count: workoutWeekStreak,
            isActive: workoutGoalWeeks.contains(currentWeek)
        ),
        AtlasRewardStreakSnapshot(
            kind: .selfGoalWeeks,
            title: "Goal streak",
            valueLabel: "\(selfGoalWeekStreak) week\(selfGoalWeekStreak == 1 ? "" : "s")",
            helperText: activeBooleanMetrics.isEmpty
                ? "Create Yes/No custom metrics in Insights to turn personal goals into a weekly streak."
                : currentWeekSelfGoalCount >= selfGoalTarget && selfGoalTarget > 0
                    ? "This week already cleared your personal-goal target."
                    : "Check off \(max(selfGoalTarget, 1)) self-defined goal\(selfGoalTarget == 1 ? "" : "s") this week to extend the goal streak.",
            symbolName: "flag.checkered.2.crossed",
            count: selfGoalWeekStreak,
            isActive: selfGoalTarget > 0 && selfGoalWeeks.contains(currentWeek)
        )
    ]
}

private func buildRewardGoals(
    referenceDate: Date,
    settings: AtlasRewardsSettingsSnapshot,
    customMetrics: [AtlasCustomMetricRecord],
    metricLogs: [AtlasMetricValueLogRecord],
    workoutLogs: [AtlasWorkoutLogRecord],
    weightLogs: [AtlasWeightLogRecord],
    onboardingDraft: AtlasOnboardingDraft?
) -> [AtlasRewardGoalSnapshot] {
    let currentWeek = atlasRewardsWeekIdentifier(for: referenceDate)
    let weeklyWorkouts = workoutLogs.filter {
        atlasRewardsWeekIdentifier(fromTimestamp: $0.startedAt) == currentWeek
    }.count

    var goals: [AtlasRewardGoalSnapshot] = [
        AtlasRewardGoalSnapshot(
            kind: .weeklyWorkouts,
            title: "Weekly workout goal",
            progressLabel: "\(weeklyWorkouts) of \(settings.weeklyWorkoutGoal) workouts",
            helperText: weeklyWorkouts >= settings.weeklyWorkoutGoal
                ? "Workout reward unlocked for this week."
                : "Keep stacking workouts this week to unlock the badge.",
            symbolName: "dumbbell.fill",
            currentValue: Double(weeklyWorkouts),
            targetValue: Double(settings.weeklyWorkoutGoal),
            progress: min(Double(weeklyWorkouts) / Double(settings.weeklyWorkoutGoal), 1),
            isMet: weeklyWorkouts >= settings.weeklyWorkoutGoal
        )
    ]

    if let selfDefinedGoal = buildSelfDefinedRewardGoal(
        referenceDate: referenceDate,
        settings: settings,
        customMetrics: customMetrics,
        metricLogs: metricLogs,
        onboardingDraft: onboardingDraft
    ) {
        goals.append(selfDefinedGoal)
    }

    if let weightGoal = buildWeightRewardGoal(weightLogs: weightLogs, onboardingDraft: onboardingDraft) {
        goals.append(weightGoal)
    }

    return goals
}

private func buildSelfDefinedRewardGoal(
    referenceDate: Date,
    settings: AtlasRewardsSettingsSnapshot,
    customMetrics: [AtlasCustomMetricRecord],
    metricLogs: [AtlasMetricValueLogRecord],
    onboardingDraft: AtlasOnboardingDraft?
) -> AtlasRewardGoalSnapshot? {
    let focusText = atlasRewardsGoalFocus(from: onboardingDraft)
    let activeBooleanMetrics = customMetrics
        .filter { $0.archivedAt == nil && $0.valueType == .boolean }
        .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }

    guard activeBooleanMetrics.isEmpty == false || focusText != nil else {
        return nil
    }

    guard activeBooleanMetrics.isEmpty == false else {
        return AtlasRewardGoalSnapshot(
            kind: .selfDefinedGoals,
            title: "Goal focus",
            progressLabel: focusText ?? "No goal focus saved yet",
            helperText: "Create a Yes/No custom metric in Insights to turn this goal into a checkoff reward.",
            symbolName: "flag.fill",
            currentValue: 0,
            targetValue: 1,
            progress: 0,
            isMet: false
        )
    }

    let currentWeek = atlasRewardsWeekIdentifier(for: referenceDate)
    let activeGoalIDs = Set(activeBooleanMetrics.map(\.id))
    let completedGoalIDs = Set<String>(
        metricLogs.compactMap { log in
            guard log.booleanValue == true,
                  activeGoalIDs.contains(log.metricId),
                  atlasRewardsWeekIdentifier(fromTimestamp: log.loggedAt) == currentWeek else {
                return nil
            }
            return log.metricId
        }
    )
    let target = max(
        atlasRewardsEffectiveGoalTarget(
            configuredTarget: settings.weeklySelfGoalTarget,
            availableGoalCount: activeBooleanMetrics.count
        ),
        1
    )
    let completedCount = completedGoalIDs.count
    let title = activeBooleanMetrics.count == 1 ? activeBooleanMetrics[0].label : "Self-defined goals"
    let progressLabel: String
    if activeBooleanMetrics.count == 1 {
        progressLabel = completedCount > 0 ? "Checked off this week" : "Not checked off yet"
    } else {
        progressLabel = "\(completedCount) of \(activeBooleanMetrics.count) goals checked"
    }

    var helperParts: [String] = []
    if let focusText {
        helperParts.append("Goal focus: \(focusText).")
    }
    if completedCount >= target {
        helperParts.append("You already cleared this week's self-defined goal target.")
    } else if activeBooleanMetrics.count == 1 {
        helperParts.append("Log a Yes entry on this custom metric to count it for the week.")
    } else {
        helperParts.append("Yes/No custom metrics in Insights count toward your weekly personal-goal target of \(target).")
    }

    return AtlasRewardGoalSnapshot(
        kind: .selfDefinedGoals,
        title: title,
        progressLabel: progressLabel,
        helperText: helperParts.joined(separator: " "),
        symbolName: "flag.fill",
        currentValue: Double(min(completedCount, target)),
        targetValue: Double(target),
        progress: min(Double(completedCount) / Double(target), 1),
        isMet: completedCount >= target
    )
}

private func buildWeightRewardGoal(
    weightLogs: [AtlasWeightLogRecord],
    onboardingDraft: AtlasOnboardingDraft?
) -> AtlasRewardGoalSnapshot? {
    guard let profile = onboardingDraft?.profile,
          let goalWeight = profile.goalWeight,
          let unit = profile.weightUnit else {
        return nil
    }

    let matchingLogs = weightLogs
        .filter { $0.unit == unit }
        .sorted { $0.loggedAt < $1.loggedAt }

    let baselineWeight = matchingLogs.first?.value ?? profile.weight
    let latestWeight = matchingLogs.last?.value ?? profile.weight
    guard let baselineWeight, let latestWeight else {
        return nil
    }

    let baselineDistance = abs(baselineWeight - goalWeight)
    let latestDistance = abs(latestWeight - goalWeight)
    let improvement = max(baselineDistance - latestDistance, 0)
    let targetDistance = max(baselineDistance, 0.5)
    let isMet = latestDistance <= 0.5
    let progress = isMet ? 1 : min(improvement / targetDistance, 1)
    let movementLabel: String
    if isMet {
        movementLabel = "Goal range reached"
    } else {
        movementLabel = "\(atlasRewardsFormatNumber(latestDistance)) \(unit.rawValue) from goal"
    }

    return AtlasRewardGoalSnapshot(
        kind: .weightGoal,
        title: "Weight progress",
        progressLabel: movementLabel,
        helperText: isMet
            ? "Latest logged weight is inside your stored goal range."
            : improvement > 0
                ? "You are closer to your stored goal weight than where this trend started."
                : "Tracks distance to your stored goal weight without scoring each change.",
        symbolName: "target",
        currentValue: improvement,
        targetValue: targetDistance,
        progress: progress,
        isMet: isMet
    )
}

private func buildRewardBadges(
    streaks: [AtlasRewardStreakSnapshot],
    goals: [AtlasRewardGoalSnapshot]
) -> [AtlasRewardBadgeSnapshot] {
    let activityStreak = streaks.first(where: { $0.kind == .activityDays })?.count ?? 0
    let workoutStreak = streaks.first(where: { $0.kind == .workoutWeeks })?.count ?? 0
    let selfGoalStreak = streaks.first(where: { $0.kind == .selfGoalWeeks })?.count ?? 0
    let workoutGoalMet = goals.first(where: { $0.kind == .weeklyWorkouts })?.isMet == true
    let selfGoalMet = goals.first(where: { $0.kind == .selfDefinedGoals })?.isMet == true
    let weightGoal = goals.first(where: { $0.kind == .weightGoal })
    let weightGoalAligned = weightGoal?.isMet == true
    let weightCheckpoint = (weightGoal?.progress ?? 0) >= 0.25

    return [
        AtlasRewardBadgeSnapshot(
            kind: .activityStreak7,
            title: "7-day streak",
            subtitle: "Stay active for a full week.",
            symbolName: "7.circle.fill",
            isEarned: activityStreak >= 7
        ),
        AtlasRewardBadgeSnapshot(
            kind: .activityStreak30,
            title: "30-day streak",
            subtitle: "Hold daily consistency for a full month.",
            symbolName: "30.circle.fill",
            isEarned: activityStreak >= 30
        ),
        AtlasRewardBadgeSnapshot(
            kind: .workoutGoalMet,
            title: "Workout target",
            subtitle: workoutStreak > 1 ? "Stack multiple goal weeks in a row." : "Clear this week's workout target.",
            symbolName: "figure.strengthtraining.traditional",
            isEarned: workoutGoalMet
        ),
        AtlasRewardBadgeSnapshot(
            kind: .selfGoalTargetMet,
            title: "Personal goal target",
            subtitle: selfGoalStreak > 1 ? "Keep checking off self-defined goals week after week." : "Hit this week's self-defined goal target.",
            symbolName: "flag.badge.ellipsis.fill",
            isEarned: selfGoalMet
        ),
        AtlasRewardBadgeSnapshot(
            kind: .weightCheckpoint,
            title: "Weight checkpoint",
            subtitle: "Measurable progress toward the stored goal weight.",
            symbolName: "chart.line.uptrend.xyaxis.circle.fill",
            isEarned: weightCheckpoint
        ),
        AtlasRewardBadgeSnapshot(
            kind: .weightGoalAligned,
            title: "Goal alignment",
            subtitle: "Latest logged weight is sitting inside the stored goal range.",
            symbolName: "checkmark.seal.fill",
            isEarned: weightGoalAligned
        )
    ]
}

private func buildRewardPoints(
    streaks: [AtlasRewardStreakSnapshot],
    goals: [AtlasRewardGoalSnapshot],
    badges: [AtlasRewardBadgeSnapshot]
) -> Int {
    let activityStreak = streaks.first(where: { $0.kind == .activityDays })?.count ?? 0
    let workoutStreak = streaks.first(where: { $0.kind == .workoutWeeks })?.count ?? 0
    let selfGoalStreak = streaks.first(where: { $0.kind == .selfGoalWeeks })?.count ?? 0
    let earnedBadgeCount = badges.filter(\.isEarned).count
    let weeklyWorkoutGoalMet = goals.first(where: { $0.kind == .weeklyWorkouts })?.isMet == true
    let weeklySelfGoalMet = goals.first(where: { $0.kind == .selfDefinedGoals })?.isMet == true
    let weightGoal = goals.first(where: { $0.kind == .weightGoal })
    let weightCheckpoint = (weightGoal?.progress ?? 0) >= 0.25

    var points = 0
    points += activityStreak * 10
    points += workoutStreak * 40
    points += selfGoalStreak * 35
    points += earnedBadgeCount * 60
    points += weeklyWorkoutGoalMet ? 120 : 0
    points += weeklySelfGoalMet ? 110 : 0
    points += weightCheckpoint ? 40 : 0
    points += weightGoal?.isMet == true ? 90 : 0
    return points
}

private func readRewardsOnboardingDraft(db: Database) throws -> AtlasOnboardingDraft? {
    guard let json = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'onboarding_draft_json'"
    ) else {
        return nil
    }
    return try? JSONDecoder().decode(AtlasOnboardingDraft.self, from: Data(json.utf8))
}

private func atlasRewardsConsecutiveDayCount(days: Set<Date>, endingAt today: Date) -> Int {
    let calendar = Calendar.current
    var count = 0
    var cursor = today

    while days.contains(cursor) {
        count += 1
        guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
            break
        }
        cursor = calendar.startOfDay(for: previous)
    }

    return count
}

private func atlasRewardsWeekIdentifier(for date: Date) -> String {
    let calendar = Calendar(identifier: .gregorian)
    let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    return "\(components.yearForWeekOfYear ?? 0)-W\(components.weekOfYear ?? 0)"
}

private func atlasRewardsWeekIdentifier(fromTimestamp timestamp: String) -> String {
    atlasRewardsWeekIdentifier(for: atlasDate(from: timestamp))
}

private func atlasRewardsConsecutiveWeekCount(weeks: Set<String>, endingAt date: Date) -> Int {
    let calendar = Calendar(identifier: .gregorian)
    var count = 0
    var cursor = date

    while weeks.contains(atlasRewardsWeekIdentifier(for: cursor)) {
        count += 1
        guard let previousWeek = calendar.date(byAdding: .day, value: -7, to: cursor) else {
            break
        }
        cursor = previousWeek
    }

    return count
}

private func atlasRewardsEffectiveGoalTarget(
    configuredTarget: Int,
    availableGoalCount: Int
) -> Int {
    guard availableGoalCount > 0 else {
        return 0
    }
    return min(max(configuredTarget, 1), availableGoalCount)
}

private func atlasRewardsGoalFocus(from onboardingDraft: AtlasOnboardingDraft?) -> String? {
    let candidates = [
        onboardingDraft?.glp.goal,
        onboardingDraft?.peptide.goal
    ]
    return candidates
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .first(where: { $0.isEmpty == false })
}

private func atlasRewardsFormatNumber(_ value: Double) -> String {
    if value.rounded() == value {
        return String(Int(value))
    }
    return String(format: "%.1f", value)
}
