import Foundation

public struct AtlasWeightEntryDraft: Equatable, Sendable {
    public var id: String?
    public var loggedAt: Date
    public var value: Double
    public var unit: AtlasWeightUnit
    public var notes: String?

    public init(
        id: String? = nil,
        loggedAt: Date = Date(),
        value: Double = 0,
        unit: AtlasWeightUnit = .lb,
        notes: String? = nil
    ) {
        self.id = id
        self.loggedAt = loggedAt
        self.value = value
        self.unit = unit
        self.notes = notes
    }
}

public struct AtlasSymptomEntryDraft: Equatable, Sendable {
    public var id: String?
    public var loggedAt: Date
    public var symptomKey: String
    public var severity: Int
    public var notes: String?

    public init(
        id: String? = nil,
        loggedAt: Date = Date(),
        symptomKey: String = "",
        severity: Int = 3,
        notes: String? = nil
    ) {
        self.id = id
        self.loggedAt = loggedAt
        self.symptomKey = symptomKey
        self.severity = severity
        self.notes = notes
    }
}

public struct AtlasContextEntryDraft: Equatable, Sendable {
    public var id: String?
    public var protocolID: String?
    public var loggedAt: Date
    public var mealTiming: AtlasContextMealTiming?
    public var fedState: AtlasContextFedState?
    public var appetite: AtlasContextAppetiteState?
    public var hydration: AtlasContextHydrationState?
    public var giTags: [AtlasContextGITag]
    public var note: String?
    public var tags: [String]

    public init(
        id: String? = nil,
        protocolID: String? = nil,
        loggedAt: Date = Date(),
        mealTiming: AtlasContextMealTiming? = nil,
        fedState: AtlasContextFedState? = nil,
        appetite: AtlasContextAppetiteState? = nil,
        hydration: AtlasContextHydrationState? = nil,
        giTags: [AtlasContextGITag] = [],
        note: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.protocolID = protocolID
        self.loggedAt = loggedAt
        self.mealTiming = mealTiming
        self.fedState = fedState
        self.appetite = appetite
        self.hydration = hydration
        self.giTags = giTags
        self.note = note
        self.tags = tags
    }
}

public struct AtlasMetricDefinitionDraft: Equatable, Sendable {
    public var id: String?
    public var protocolID: String?
    public var metricKey: String?
    public var label: String
    public var valueType: AtlasCustomMetricValueType
    public var unit: String?
    public var scaleMin: Int?
    public var scaleMax: Int?

    public init(
        id: String? = nil,
        protocolID: String? = nil,
        metricKey: String? = nil,
        label: String = "",
        valueType: AtlasCustomMetricValueType = .number,
        unit: String? = nil,
        scaleMin: Int? = nil,
        scaleMax: Int? = nil
    ) {
        self.id = id
        self.protocolID = protocolID
        self.metricKey = metricKey
        self.label = label
        self.valueType = valueType
        self.unit = unit
        self.scaleMin = scaleMin
        self.scaleMax = scaleMax
    }
}

public struct AtlasMetricValueEntryDraft: Equatable, Sendable {
    public var id: String?
    public var metricID: String
    public var protocolID: String?
    public var loggedAt: Date
    public var numberValue: Double?
    public var textValue: String?
    public var booleanValue: Bool?

    public init(
        id: String? = nil,
        metricID: String,
        protocolID: String? = nil,
        loggedAt: Date = Date(),
        numberValue: Double? = nil,
        textValue: String? = nil,
        booleanValue: Bool? = nil
    ) {
        self.id = id
        self.metricID = metricID
        self.protocolID = protocolID
        self.loggedAt = loggedAt
        self.numberValue = numberValue
        self.textValue = textValue
        self.booleanValue = booleanValue
    }
}

public struct AtlasWeightEntrySummary: Identifiable, Equatable, Sendable {
    public var id: String
    public var loggedAt: Date
    public var valueLabel: String
    public var notes: String?

    public init(id: String, loggedAt: Date, valueLabel: String, notes: String?) {
        self.id = id
        self.loggedAt = loggedAt
        self.valueLabel = valueLabel
        self.notes = notes
    }
}

public struct AtlasSymptomEntrySummary: Identifiable, Equatable, Sendable {
    public var id: String
    public var loggedAt: Date
    public var symptomKey: String
    public var severity: Int
    public var notes: String?

    public init(id: String, loggedAt: Date, symptomKey: String, severity: Int, notes: String?) {
        self.id = id
        self.loggedAt = loggedAt
        self.symptomKey = symptomKey
        self.severity = severity
        self.notes = notes
    }
}

public struct AtlasContextEntrySummary: Identifiable, Equatable, Sendable {
    public var id: String
    public var protocolID: String?
    public var canonicalProtocolTitle: String?
    public var aliasProtocolTitle: String?
    public var loggedAt: Date
    public var mealTiming: AtlasContextMealTiming?
    public var fedState: AtlasContextFedState?
    public var appetite: AtlasContextAppetiteState?
    public var hydration: AtlasContextHydrationState?
    public var giTags: [AtlasContextGITag]
    public var note: String?
    public var tags: [String]

    public init(
        id: String,
        protocolID: String?,
        canonicalProtocolTitle: String?,
        aliasProtocolTitle: String?,
        loggedAt: Date,
        mealTiming: AtlasContextMealTiming?,
        fedState: AtlasContextFedState?,
        appetite: AtlasContextAppetiteState?,
        hydration: AtlasContextHydrationState?,
        giTags: [AtlasContextGITag],
        note: String?,
        tags: [String]
    ) {
        self.id = id
        self.protocolID = protocolID
        self.canonicalProtocolTitle = canonicalProtocolTitle
        self.aliasProtocolTitle = aliasProtocolTitle
        self.loggedAt = loggedAt
        self.mealTiming = mealTiming
        self.fedState = fedState
        self.appetite = appetite
        self.hydration = hydration
        self.giTags = giTags
        self.note = note
        self.tags = tags
    }
}

public struct AtlasMetricValueEntrySummary: Identifiable, Equatable, Sendable {
    public var id: String
    public var metricID: String
    public var protocolID: String?
    public var label: String
    public var canonicalProtocolTitle: String?
    public var aliasProtocolTitle: String?
    public var loggedAt: Date
    public var valueLabel: String

    public init(
        id: String,
        metricID: String,
        protocolID: String?,
        label: String,
        canonicalProtocolTitle: String?,
        aliasProtocolTitle: String?,
        loggedAt: Date,
        valueLabel: String
    ) {
        self.id = id
        self.metricID = metricID
        self.protocolID = protocolID
        self.label = label
        self.canonicalProtocolTitle = canonicalProtocolTitle
        self.aliasProtocolTitle = aliasProtocolTitle
        self.loggedAt = loggedAt
        self.valueLabel = valueLabel
    }
}

public struct AtlasMetricDefinitionSummary: Identifiable, Equatable, Sendable {
    public var id: String
    public var label: String
    public var valueType: AtlasCustomMetricValueType
    public var unit: String?
    public var scaleMin: Int?
    public var scaleMax: Int?
    public var protocolID: String?
    public var canonicalProtocolTitle: String?
    public var aliasProtocolTitle: String?
    public var latestEntryLabel: String?
    public var latestEntryAt: Date?
    public var logCount: Int
    public var archivedAt: Date?

    public init(
        id: String,
        label: String,
        valueType: AtlasCustomMetricValueType,
        unit: String?,
        scaleMin: Int?,
        scaleMax: Int?,
        protocolID: String?,
        canonicalProtocolTitle: String?,
        aliasProtocolTitle: String?,
        latestEntryLabel: String?,
        latestEntryAt: Date?,
        logCount: Int,
        archivedAt: Date?
    ) {
        self.id = id
        self.label = label
        self.valueType = valueType
        self.unit = unit
        self.scaleMin = scaleMin
        self.scaleMax = scaleMax
        self.protocolID = protocolID
        self.canonicalProtocolTitle = canonicalProtocolTitle
        self.aliasProtocolTitle = aliasProtocolTitle
        self.latestEntryLabel = latestEntryLabel
        self.latestEntryAt = latestEntryAt
        self.logCount = logCount
        self.archivedAt = archivedAt
    }
}

public struct AtlasWeightTrendPoint: Identifiable, Equatable, Sendable {
    public var id: String
    public var label: String
    public var loggedAt: Date
    public var value: Double

    public init(id: String, label: String, loggedAt: Date, value: Double) {
        self.id = id
        self.label = label
        self.loggedAt = loggedAt
        self.value = value
    }
}

public struct AtlasWeightTrendSummary: Equatable, Sendable {
    public var changeLabel: String?
    public var latestLabel: String?
    public var points: [AtlasWeightTrendPoint]

    public init(
        changeLabel: String? = nil,
        latestLabel: String? = nil,
        points: [AtlasWeightTrendPoint] = []
    ) {
        self.changeLabel = changeLabel
        self.latestLabel = latestLabel
        self.points = points
    }
}

public struct AtlasSymptomTrendItem: Identifiable, Equatable, Sendable {
    public var id: String { symptomKey }
    public var symptomKey: String
    public var averageSeverityLabel: String
    public var entryCount: Int
    public var latestLabel: String

    public init(
        symptomKey: String,
        averageSeverityLabel: String,
        entryCount: Int,
        latestLabel: String
    ) {
        self.symptomKey = symptomKey
        self.averageSeverityLabel = averageSeverityLabel
        self.entryCount = entryCount
        self.latestLabel = latestLabel
    }
}

public struct AtlasContextTrendSummary: Equatable, Sendable {
    public var recentEntryCount: Int
    public var latestLabel: String?
    public var fastedEntryCount: Int
    public var fedEntryCount: Int
    public var lowHydrationEntryCount: Int
    public var giEntryCount: Int

    public init(
        recentEntryCount: Int = 0,
        latestLabel: String? = nil,
        fastedEntryCount: Int = 0,
        fedEntryCount: Int = 0,
        lowHydrationEntryCount: Int = 0,
        giEntryCount: Int = 0
    ) {
        self.recentEntryCount = recentEntryCount
        self.latestLabel = latestLabel
        self.fastedEntryCount = fastedEntryCount
        self.fedEntryCount = fedEntryCount
        self.lowHydrationEntryCount = lowHydrationEntryCount
        self.giEntryCount = giEntryCount
    }
}

public struct AtlasInventoryBurnDownInsight: Identifiable, Equatable, Sendable {
    public var id: String
    public var label: String
    public var quantityLabel: String
    public var projectedDepletionLabel: String?
    public var isLowStock: Bool

    public init(
        id: String,
        label: String,
        quantityLabel: String,
        projectedDepletionLabel: String?,
        isLowStock: Bool
    ) {
        self.id = id
        self.label = label
        self.quantityLabel = quantityLabel
        self.projectedDepletionLabel = projectedDepletionLabel
        self.isLowStock = isLowStock
    }
}

public struct AtlasAdherenceTrendSummary: Equatable, Sendable {
    public var completionRateLabel: String?
    public var completedCount: Int
    public var overdueCount: Int
    public var rescheduledCount: Int
    public var skippedCount: Int

    public init(
        completionRateLabel: String? = nil,
        completedCount: Int = 0,
        overdueCount: Int = 0,
        rescheduledCount: Int = 0,
        skippedCount: Int = 0
    ) {
        self.completionRateLabel = completionRateLabel
        self.completedCount = completedCount
        self.overdueCount = overdueCount
        self.rescheduledCount = rescheduledCount
        self.skippedCount = skippedCount
    }
}

public struct AtlasAmountEstimateItem: Identifiable, Equatable, Sendable {
    public var id: String { protocolID }
    public var protocolID: String
    public var canonicalProtocolTitle: String
    public var aliasProtocolTitle: String?
    public var cadenceLabel: String
    public var estimateLabel: String
    public var notesLabel: String

    public init(
        protocolID: String,
        canonicalProtocolTitle: String,
        aliasProtocolTitle: String?,
        cadenceLabel: String,
        estimateLabel: String,
        notesLabel: String
    ) {
        self.protocolID = protocolID
        self.canonicalProtocolTitle = canonicalProtocolTitle
        self.aliasProtocolTitle = aliasProtocolTitle
        self.cadenceLabel = cadenceLabel
        self.estimateLabel = estimateLabel
        self.notesLabel = notesLabel
    }
}

public struct AtlasInsightsSnapshot: Equatable, Sendable {
    public var weightTrend: AtlasWeightTrendSummary
    public var symptomTrend: [AtlasSymptomTrendItem]
    public var contextTrend: AtlasContextTrendSummary
    public var inventoryBurnDown: [AtlasInventoryBurnDownInsight]
    public var adherenceTrend: AtlasAdherenceTrendSummary
    public var amountInSystemDisclaimer: String
    public var amountInSystem: [AtlasAmountEstimateItem]
    public var episodeIntelligence: AtlasEpisodeInsightsSnapshot
    public var customMetricDefinitions: [AtlasMetricDefinitionSummary]
    public var recentContextEntries: [AtlasContextEntrySummary]
    public var recentWeightEntries: [AtlasWeightEntrySummary]
    public var recentSymptomEntries: [AtlasSymptomEntrySummary]
    public var recentMetricEntries: [AtlasMetricValueEntrySummary]
    public var weeklyRecapSummary: AtlasGeneratedSummary?
    public var episodeRecapSummary: AtlasGeneratedSummary?
    public var hasAnyInsightData: Bool

    public init(
        weightTrend: AtlasWeightTrendSummary = .init(),
        symptomTrend: [AtlasSymptomTrendItem] = [],
        contextTrend: AtlasContextTrendSummary = .init(),
        inventoryBurnDown: [AtlasInventoryBurnDownInsight] = [],
        adherenceTrend: AtlasAdherenceTrendSummary = .init(),
        amountInSystemDisclaimer: String = "Estimate only. Atlas spreads logged quantities across each protocol interval as a scheduling model, not a medical or pharmacokinetic calculation.",
        amountInSystem: [AtlasAmountEstimateItem] = [],
        episodeIntelligence: AtlasEpisodeInsightsSnapshot = .init(),
        customMetricDefinitions: [AtlasMetricDefinitionSummary] = [],
        recentContextEntries: [AtlasContextEntrySummary] = [],
        recentWeightEntries: [AtlasWeightEntrySummary] = [],
        recentSymptomEntries: [AtlasSymptomEntrySummary] = [],
        recentMetricEntries: [AtlasMetricValueEntrySummary] = [],
        weeklyRecapSummary: AtlasGeneratedSummary? = nil,
        episodeRecapSummary: AtlasGeneratedSummary? = nil,
        hasAnyInsightData: Bool = false
    ) {
        self.weightTrend = weightTrend
        self.symptomTrend = symptomTrend
        self.contextTrend = contextTrend
        self.inventoryBurnDown = inventoryBurnDown
        self.adherenceTrend = adherenceTrend
        self.amountInSystemDisclaimer = amountInSystemDisclaimer
        self.amountInSystem = amountInSystem
        self.episodeIntelligence = episodeIntelligence
        self.customMetricDefinitions = customMetricDefinitions
        self.recentContextEntries = recentContextEntries
        self.recentWeightEntries = recentWeightEntries
        self.recentSymptomEntries = recentSymptomEntries
        self.recentMetricEntries = recentMetricEntries
        self.weeklyRecapSummary = weeklyRecapSummary
        self.episodeRecapSummary = episodeRecapSummary
        self.hasAnyInsightData = hasAnyInsightData
    }
}
