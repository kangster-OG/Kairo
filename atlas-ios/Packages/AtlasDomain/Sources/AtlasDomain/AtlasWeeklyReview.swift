import Foundation

public enum AtlasWeeklyReviewActionRoute: Codable, Equatable, Sendable {
    case today
    case insights
    case settings
    case protocolDetail(String)
    case protocolChange(String)
}

public struct AtlasWeeklyReviewActionPlan: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var title: String
    public var detail: String
    public var symbolName: String
    public var route: AtlasWeeklyReviewActionRoute
    public var reviewPeriodStart: String
    public var reviewPeriodEnd: String
    public var createdAt: String
    public var isPinnedForNextWeek: Bool
    public var isCompleted: Bool

    public init(
        id: String,
        title: String,
        detail: String,
        symbolName: String,
        route: AtlasWeeklyReviewActionRoute,
        reviewPeriodStart: String,
        reviewPeriodEnd: String,
        createdAt: String,
        isPinnedForNextWeek: Bool = true,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.symbolName = symbolName
        self.route = route
        self.reviewPeriodStart = reviewPeriodStart
        self.reviewPeriodEnd = reviewPeriodEnd
        self.createdAt = createdAt
        self.isPinnedForNextWeek = isPinnedForNextWeek
        self.isCompleted = isCompleted
    }
}

public struct AtlasWeeklyReviewReminderSettings: Codable, Equatable, Sendable {
    public var enabled: Bool

    public init(enabled: Bool = false) {
        self.enabled = enabled
    }
}

public struct AtlasWeeklyReviewProtocolChangeSummary: Equatable, Sendable {
    public var changeCount: Int
    public var latestProtocolID: String?
    public var latestTitle: String?
    public var latestSummary: String?
    public var latestChangedAt: Date?
    public var supportingLogCount: Int
    public var supportingContextCount: Int

    public init(
        changeCount: Int,
        latestProtocolID: String? = nil,
        latestTitle: String? = nil,
        latestSummary: String? = nil,
        latestChangedAt: Date? = nil,
        supportingLogCount: Int = 0,
        supportingContextCount: Int = 0
    ) {
        self.changeCount = changeCount
        self.latestProtocolID = latestProtocolID
        self.latestTitle = latestTitle
        self.latestSummary = latestSummary
        self.latestChangedAt = latestChangedAt
        self.supportingLogCount = supportingLogCount
        self.supportingContextCount = supportingContextCount
    }
}

public struct AtlasWeeklyReviewProtocolFollowUpSummary: Equatable, Sendable {
    public var protocolID: String
    public var title: String?
    public var changeTypeTitle: String
    public var summary: String?
    public var changedAt: Date
    public var windowDays: Int
    public var completedCount: Int
    public var skippedCount: Int
    public var rescheduledCount: Int
    public var contextEntryCount: Int
    public var hasVisibleSupportingData: Bool

    public init(
        protocolID: String,
        title: String? = nil,
        changeTypeTitle: String,
        summary: String? = nil,
        changedAt: Date,
        windowDays: Int,
        completedCount: Int,
        skippedCount: Int,
        rescheduledCount: Int,
        contextEntryCount: Int
    ) {
        self.protocolID = protocolID
        self.title = title
        self.changeTypeTitle = changeTypeTitle
        self.summary = summary
        self.changedAt = changedAt
        self.windowDays = windowDays
        self.completedCount = completedCount
        self.skippedCount = skippedCount
        self.rescheduledCount = rescheduledCount
        self.contextEntryCount = contextEntryCount
        self.hasVisibleSupportingData = completedCount + skippedCount + rescheduledCount + contextEntryCount > 0
    }
}

public struct AtlasWeeklyReviewStackSummary: Equatable, Sendable {
    public var activeProtocolCount: Int
    public var protocolsWithChanges: Int
    public var weeklyCompletedCount: Int
    public var weeklyRescheduledCount: Int
    public var lowStockRiskCount: Int
    public var burdenSummary: String

    public init(
        activeProtocolCount: Int,
        protocolsWithChanges: Int,
        weeklyCompletedCount: Int,
        weeklyRescheduledCount: Int,
        lowStockRiskCount: Int,
        burdenSummary: String
    ) {
        self.activeProtocolCount = activeProtocolCount
        self.protocolsWithChanges = protocolsWithChanges
        self.weeklyCompletedCount = weeklyCompletedCount
        self.weeklyRescheduledCount = weeklyRescheduledCount
        self.lowStockRiskCount = lowStockRiskCount
        self.burdenSummary = burdenSummary
    }
}

public struct AtlasWeeklyReviewSeed: Equatable, Sendable {
    public var periodTitle: String
    public var generatedAt: Date
    public var windowStart: Date
    public var windowEnd: Date
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
    public var stackSummary: AtlasWeeklyReviewStackSummary?
    public var protocolChangeSummary: AtlasWeeklyReviewProtocolChangeSummary?
    public var protocolFollowUpSummary: AtlasWeeklyReviewProtocolFollowUpSummary?

    public init(
        periodTitle: String,
        generatedAt: Date,
        windowStart: Date,
        windowEnd: Date,
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
        nextDueTitle: String? = nil,
        stackSummary: AtlasWeeklyReviewStackSummary? = nil,
        protocolChangeSummary: AtlasWeeklyReviewProtocolChangeSummary? = nil,
        protocolFollowUpSummary: AtlasWeeklyReviewProtocolFollowUpSummary? = nil
    ) {
        self.periodTitle = periodTitle
        self.generatedAt = generatedAt
        self.windowStart = windowStart
        self.windowEnd = windowEnd
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
        self.stackSummary = stackSummary
        self.protocolChangeSummary = protocolChangeSummary
        self.protocolFollowUpSummary = protocolFollowUpSummary
    }
}
