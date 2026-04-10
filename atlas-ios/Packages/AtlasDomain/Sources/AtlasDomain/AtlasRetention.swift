import Foundation

public struct AtlasRetentionSettingsSnapshot: Sendable, Equatable, Codable {
    public var progressEnabled: Bool
    public var companionEnabled: Bool

    public init(
        progressEnabled: Bool = false,
        companionEnabled: Bool = false
    ) {
        self.progressEnabled = progressEnabled
        self.companionEnabled = companionEnabled
    }
}

public struct AtlasRetentionSettingsUpdate: Sendable, Equatable {
    public var progressEnabled: Bool?
    public var companionEnabled: Bool?

    public init(
        progressEnabled: Bool? = nil,
        companionEnabled: Bool? = nil
    ) {
        self.progressEnabled = progressEnabled
        self.companionEnabled = companionEnabled
    }
}

public enum AtlasRetentionMilestoneKind: String, CaseIterable, Codable, Sendable, Identifiable {
    case checkedInToday = "checked_in_today"
    case weeklyReviewCompleted = "weekly_review_completed"
    case inventoryCurrent = "inventory_current"
    case contextConsistency = "context_consistency"

    public var id: String { rawValue }
}

public enum AtlasRetentionMilestoneTone: String, Codable, Sendable {
    case complete
    case inProgress = "in_progress"
    case neutral
}

public struct AtlasRetentionMilestoneSnapshot: Sendable, Equatable, Identifiable {
    public var id: AtlasRetentionMilestoneKind { kind }
    public var kind: AtlasRetentionMilestoneKind
    public var title: String
    public var subtitle: String
    public var helperText: String
    public var symbolName: String
    public var isEarned: Bool
    public var streakCount: Int?
    public var tone: AtlasRetentionMilestoneTone

    public init(
        kind: AtlasRetentionMilestoneKind,
        title: String,
        subtitle: String,
        helperText: String,
        symbolName: String,
        isEarned: Bool,
        streakCount: Int? = nil,
        tone: AtlasRetentionMilestoneTone
    ) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.helperText = helperText
        self.symbolName = symbolName
        self.isEarned = isEarned
        self.streakCount = streakCount
        self.tone = tone
    }
}

public enum AtlasCompanionMood: String, Codable, Sendable {
    case quiet
    case steady
    case settled
}

public struct AtlasRetentionCompanionSnapshot: Sendable, Equatable {
    public var mood: AtlasCompanionMood
    public var title: String
    public var subtitle: String
    public var systemImage: String

    public init(
        mood: AtlasCompanionMood,
        title: String,
        subtitle: String,
        systemImage: String
    ) {
        self.mood = mood
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }
}

public struct AtlasRetentionSnapshot: Sendable, Equatable {
    public var settings: AtlasRetentionSettingsSnapshot
    public var milestones: [AtlasRetentionMilestoneSnapshot]
    public var earnedMilestoneCount: Int
    public var companion: AtlasRetentionCompanionSnapshot?
    public var note: String

    public init(
        settings: AtlasRetentionSettingsSnapshot = .init(),
        milestones: [AtlasRetentionMilestoneSnapshot] = [],
        earnedMilestoneCount: Int = 0,
        companion: AtlasRetentionCompanionSnapshot? = nil,
        note: String = "Calm progress is optional, local only, and never changes Atlas history."
    ) {
        self.settings = settings
        self.milestones = milestones
        self.earnedMilestoneCount = earnedMilestoneCount
        self.companion = companion
        self.note = note
    }
}
