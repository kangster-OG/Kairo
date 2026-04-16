import Foundation

public struct AtlasRewardsSettingsSnapshot: Sendable, Equatable, Codable {
    public var enabled: Bool
    public var weeklyWorkoutGoal: Int
    public var weeklySelfGoalTarget: Int

    public init(
        enabled: Bool = false,
        weeklyWorkoutGoal: Int = 3,
        weeklySelfGoalTarget: Int = 2
    ) {
        self.enabled = enabled
        self.weeklyWorkoutGoal = weeklyWorkoutGoal
        self.weeklySelfGoalTarget = weeklySelfGoalTarget
    }
}

public struct AtlasRewardsSettingsUpdate: Sendable, Equatable {
    public var enabled: Bool?
    public var weeklyWorkoutGoal: Int?
    public var weeklySelfGoalTarget: Int?

    public init(
        enabled: Bool? = nil,
        weeklyWorkoutGoal: Int? = nil,
        weeklySelfGoalTarget: Int? = nil
    ) {
        self.enabled = enabled
        self.weeklyWorkoutGoal = weeklyWorkoutGoal
        self.weeklySelfGoalTarget = weeklySelfGoalTarget
    }
}

public enum AtlasRewardStreakKind: String, CaseIterable, Codable, Sendable, Identifiable {
    case activityDays = "activity_days"
    case workoutWeeks = "workout_weeks"
    case selfGoalWeeks = "self_goal_weeks"

    public var id: String { rawValue }
}

public struct AtlasRewardStreakSnapshot: Sendable, Equatable, Identifiable {
    public var id: AtlasRewardStreakKind { kind }
    public var kind: AtlasRewardStreakKind
    public var title: String
    public var valueLabel: String
    public var helperText: String
    public var symbolName: String
    public var count: Int
    public var isActive: Bool

    public init(
        kind: AtlasRewardStreakKind,
        title: String,
        valueLabel: String,
        helperText: String,
        symbolName: String,
        count: Int,
        isActive: Bool
    ) {
        self.kind = kind
        self.title = title
        self.valueLabel = valueLabel
        self.helperText = helperText
        self.symbolName = symbolName
        self.count = count
        self.isActive = isActive
    }
}

public enum AtlasRewardGoalKind: String, CaseIterable, Codable, Sendable, Identifiable {
    case weeklyWorkouts = "weekly_workouts"
    case selfDefinedGoals = "self_defined_goals"
    case weightGoal = "weight_goal"

    public var id: String { rawValue }
}

public struct AtlasRewardGoalSnapshot: Sendable, Equatable, Identifiable {
    public var id: AtlasRewardGoalKind { kind }
    public var kind: AtlasRewardGoalKind
    public var title: String
    public var progressLabel: String
    public var helperText: String
    public var symbolName: String
    public var currentValue: Double
    public var targetValue: Double
    public var progress: Double
    public var isMet: Bool

    public init(
        kind: AtlasRewardGoalKind,
        title: String,
        progressLabel: String,
        helperText: String,
        symbolName: String,
        currentValue: Double,
        targetValue: Double,
        progress: Double,
        isMet: Bool
    ) {
        self.kind = kind
        self.title = title
        self.progressLabel = progressLabel
        self.helperText = helperText
        self.symbolName = symbolName
        self.currentValue = currentValue
        self.targetValue = targetValue
        self.progress = progress
        self.isMet = isMet
    }
}

public enum AtlasRewardBadgeKind: String, CaseIterable, Codable, Sendable, Identifiable {
    case activityStreak7 = "activity_streak_7"
    case activityStreak30 = "activity_streak_30"
    case workoutGoalMet = "workout_goal_met"
    case selfGoalTargetMet = "self_goal_target_met"
    case weightCheckpoint = "weight_checkpoint"
    case weightGoalAligned = "weight_goal_aligned"

    public var id: String { rawValue }
}

public struct AtlasRewardBadgeSnapshot: Sendable, Equatable, Identifiable {
    public var id: AtlasRewardBadgeKind { kind }
    public var kind: AtlasRewardBadgeKind
    public var title: String
    public var subtitle: String
    public var symbolName: String
    public var isEarned: Bool

    public init(
        kind: AtlasRewardBadgeKind,
        title: String,
        subtitle: String,
        symbolName: String,
        isEarned: Bool
    ) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.isEarned = isEarned
    }
}

public struct AtlasRewardsSnapshot: Sendable, Equatable {
    public var settings: AtlasRewardsSettingsSnapshot
    public var totalPoints: Int
    public var level: Int
    public var nextLevelPoints: Int
    public var streaks: [AtlasRewardStreakSnapshot]
    public var goals: [AtlasRewardGoalSnapshot]
    public var badges: [AtlasRewardBadgeSnapshot]
    public var note: String

    public init(
        settings: AtlasRewardsSettingsSnapshot = .init(),
        totalPoints: Int = 0,
        level: Int = 1,
        nextLevelPoints: Int = 250,
        streaks: [AtlasRewardStreakSnapshot] = [],
        goals: [AtlasRewardGoalSnapshot] = [],
        badges: [AtlasRewardBadgeSnapshot] = [],
        note: String = "Rewards stay local and update from consistency, workouts, self-defined goals, and milestones."
    ) {
        self.settings = settings
        self.totalPoints = totalPoints
        self.level = level
        self.nextLevelPoints = nextLevelPoints
        self.streaks = streaks
        self.goals = goals
        self.badges = badges
        self.note = note
    }
}
