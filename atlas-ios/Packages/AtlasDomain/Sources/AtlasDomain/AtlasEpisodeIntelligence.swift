import Foundation

public enum AtlasEpisodeWindowKind: String, Codable, CaseIterable, Sendable {
    case postDose0To12Hours = "post_dose_0_12_hours"
    case postDose12To48Hours = "post_dose_12_48_hours"
    case day3To4 = "day_3_4"
    case preNextDose = "pre_next_dose"

    public var title: String {
        switch self {
        case .postDose0To12Hours:
            return "0-12 hours after dose"
        case .postDose12To48Hours:
            return "12-48 hours after dose"
        case .day3To4:
            return "Day 3-4 after dose"
        case .preNextDose:
            return "Pre-next-dose"
        }
    }
}

public enum AtlasEpisodePatternType: String, Codable, CaseIterable, Sendable {
    case symptomCluster = "symptom_cluster"
    case lateLogging = "late_logging"
    case weightShift = "weight_shift"
    case siteObservation = "site_observation"
    case contextCluster = "context_cluster"
}

public enum AtlasEpisodeConfidence: String, Codable, CaseIterable, Sendable {
    case medium
    case high

    public var label: String {
        switch self {
        case .medium:
            return "Medium confidence"
        case .high:
            return "High confidence"
        }
    }
}

public struct AtlasDoseEpisodeSummary: Identifiable, Equatable, Sendable {
    public var id: String
    public var protocolID: String
    public var canonicalProtocolTitle: String
    public var aliasProtocolTitle: String?
    public var doseAt: Date
    public var siteLabel: String?
    public var reminderTimingLabel: String
    public var adherenceLabel: String
    public var symptomEntryCount: Int
    public var weightEntryCount: Int
    public var contextEntryCount: Int
    public var metricEntryCount: Int

    public init(
        id: String,
        protocolID: String,
        canonicalProtocolTitle: String,
        aliasProtocolTitle: String?,
        doseAt: Date,
        siteLabel: String?,
        reminderTimingLabel: String,
        adherenceLabel: String,
        symptomEntryCount: Int,
        weightEntryCount: Int,
        contextEntryCount: Int,
        metricEntryCount: Int
    ) {
        self.id = id
        self.protocolID = protocolID
        self.canonicalProtocolTitle = canonicalProtocolTitle
        self.aliasProtocolTitle = aliasProtocolTitle
        self.doseAt = doseAt
        self.siteLabel = siteLabel
        self.reminderTimingLabel = reminderTimingLabel
        self.adherenceLabel = adherenceLabel
        self.symptomEntryCount = symptomEntryCount
        self.weightEntryCount = weightEntryCount
        self.contextEntryCount = contextEntryCount
        self.metricEntryCount = metricEntryCount
    }
}

public struct AtlasEpisodeWindowCompareRow: Identifiable, Equatable, Sendable {
    public var id: AtlasEpisodeWindowKind { windowKind }
    public var windowKind: AtlasEpisodeWindowKind
    public var episodeCount: Int
    public var symptomEntryCount: Int
    public var weightEntryCount: Int
    public var contextEntryCount: Int
    public var metricEntryCount: Int
    public var summaryLabel: String

    public init(
        windowKind: AtlasEpisodeWindowKind,
        episodeCount: Int,
        symptomEntryCount: Int,
        weightEntryCount: Int,
        contextEntryCount: Int,
        metricEntryCount: Int,
        summaryLabel: String
    ) {
        self.windowKind = windowKind
        self.episodeCount = episodeCount
        self.symptomEntryCount = symptomEntryCount
        self.weightEntryCount = weightEntryCount
        self.contextEntryCount = contextEntryCount
        self.metricEntryCount = metricEntryCount
        self.summaryLabel = summaryLabel
    }
}

public struct AtlasEpisodePatternCard: Identifiable, Equatable, Sendable {
    public var id: String
    public var protocolID: String?
    public var canonicalProtocolTitle: String?
    public var aliasProtocolTitle: String?
    public var type: AtlasEpisodePatternType
    public var windowKind: AtlasEpisodeWindowKind?
    public var confidence: AtlasEpisodeConfidence
    public var title: String
    public var detail: String
    public var supportingEpisodeCount: Int

    public init(
        id: String,
        protocolID: String?,
        canonicalProtocolTitle: String?,
        aliasProtocolTitle: String?,
        type: AtlasEpisodePatternType,
        windowKind: AtlasEpisodeWindowKind?,
        confidence: AtlasEpisodeConfidence,
        title: String,
        detail: String,
        supportingEpisodeCount: Int
    ) {
        self.id = id
        self.protocolID = protocolID
        self.canonicalProtocolTitle = canonicalProtocolTitle
        self.aliasProtocolTitle = aliasProtocolTitle
        self.type = type
        self.windowKind = windowKind
        self.confidence = confidence
        self.title = title
        self.detail = detail
        self.supportingEpisodeCount = supportingEpisodeCount
    }
}

public struct AtlasEpisodeInsightsSnapshot: Equatable, Sendable {
    public var disclaimer: String
    public var recentEpisodes: [AtlasDoseEpisodeSummary]
    public var compareWindows: [AtlasEpisodeWindowCompareRow]
    public var patternCards: [AtlasEpisodePatternCard]
    public var hasAnyEpisodeData: Bool

    public init(
        disclaimer: String = "Restates nearby timing and logged patterns from local records; descriptive only, with no medical guidance or dosing advice.",
        recentEpisodes: [AtlasDoseEpisodeSummary] = [],
        compareWindows: [AtlasEpisodeWindowCompareRow] = [],
        patternCards: [AtlasEpisodePatternCard] = [],
        hasAnyEpisodeData: Bool = false
    ) {
        self.disclaimer = disclaimer
        self.recentEpisodes = recentEpisodes
        self.compareWindows = compareWindows
        self.patternCards = patternCards
        self.hasAnyEpisodeData = hasAnyEpisodeData
    }
}
