import Foundation

public struct AtlasWeeklyReviewSeed: Equatable, Sendable {
    public var periodTitle: String
    public var generatedAt: Date
    public var summarySettingEnabled: Bool
    public var plainLanguageSummary: AtlasGeneratedSummary?
    public var fallbackSummary: String
    public var sourceSections: [AtlasSummarySourceSection]
    public var completedCount: Int
    public var skippedCount: Int
    public var rescheduledCount: Int
    public var overdueCount: Int
    public var activeProtocolCount: Int
    public var contextEntryCount: Int
    public var symptomEntryCount: Int
    public var weightEntryCount: Int
    public var workoutEntryCount: Int
    public var nextDueProtocolID: String?
    public var nextDueTitle: String?

    public init(
        periodTitle: String,
        generatedAt: Date,
        summarySettingEnabled: Bool,
        plainLanguageSummary: AtlasGeneratedSummary? = nil,
        fallbackSummary: String,
        sourceSections: [AtlasSummarySourceSection],
        completedCount: Int,
        skippedCount: Int,
        rescheduledCount: Int,
        overdueCount: Int,
        activeProtocolCount: Int,
        contextEntryCount: Int,
        symptomEntryCount: Int,
        weightEntryCount: Int,
        workoutEntryCount: Int,
        nextDueProtocolID: String? = nil,
        nextDueTitle: String? = nil
    ) {
        self.periodTitle = periodTitle
        self.generatedAt = generatedAt
        self.summarySettingEnabled = summarySettingEnabled
        self.plainLanguageSummary = plainLanguageSummary
        self.fallbackSummary = fallbackSummary
        self.sourceSections = sourceSections
        self.completedCount = completedCount
        self.skippedCount = skippedCount
        self.rescheduledCount = rescheduledCount
        self.overdueCount = overdueCount
        self.activeProtocolCount = activeProtocolCount
        self.contextEntryCount = contextEntryCount
        self.symptomEntryCount = symptomEntryCount
        self.weightEntryCount = weightEntryCount
        self.workoutEntryCount = workoutEntryCount
        self.nextDueProtocolID = nextDueProtocolID
        self.nextDueTitle = nextDueTitle
    }
}
