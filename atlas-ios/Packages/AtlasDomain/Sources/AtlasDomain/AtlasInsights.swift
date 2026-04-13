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
    public var mealSize: AtlasContextMealSize?
    public var mealComposition: AtlasContextMealComposition?
    public var fedState: AtlasContextFedState?
    public var appetite: AtlasContextAppetiteState?
    public var hydration: AtlasContextHydrationState?
    public var giTags: [AtlasContextGITag]
    public var note: String?
    public var tags: [String]
    public var presetKey: String?

    public init(
        id: String? = nil,
        protocolID: String? = nil,
        loggedAt: Date = Date(),
        mealTiming: AtlasContextMealTiming? = nil,
        mealSize: AtlasContextMealSize? = nil,
        mealComposition: AtlasContextMealComposition? = nil,
        fedState: AtlasContextFedState? = nil,
        appetite: AtlasContextAppetiteState? = nil,
        hydration: AtlasContextHydrationState? = nil,
        giTags: [AtlasContextGITag] = [],
        note: String? = nil,
        tags: [String] = [],
        presetKey: String? = nil
    ) {
        self.id = id
        self.protocolID = protocolID
        self.loggedAt = loggedAt
        self.mealTiming = mealTiming
        self.mealSize = mealSize
        self.mealComposition = mealComposition
        self.fedState = fedState
        self.appetite = appetite
        self.hydration = hydration
        self.giTags = giTags
        self.note = note
        self.tags = tags
        self.presetKey = presetKey
    }
}

public struct AtlasContextPresetDraft: Equatable, Sendable {
    public var id: String?
    public var title: String
    public var mealTiming: AtlasContextMealTiming?
    public var mealSize: AtlasContextMealSize?
    public var mealComposition: AtlasContextMealComposition?
    public var fedState: AtlasContextFedState?
    public var appetite: AtlasContextAppetiteState?
    public var hydration: AtlasContextHydrationState?
    public var giTags: [AtlasContextGITag]

    public init(
        id: String? = nil,
        title: String = "",
        mealTiming: AtlasContextMealTiming? = nil,
        mealSize: AtlasContextMealSize? = nil,
        mealComposition: AtlasContextMealComposition? = nil,
        fedState: AtlasContextFedState? = nil,
        appetite: AtlasContextAppetiteState? = nil,
        hydration: AtlasContextHydrationState? = nil,
        giTags: [AtlasContextGITag] = []
    ) {
        self.id = id
        self.title = title
        self.mealTiming = mealTiming
        self.mealSize = mealSize
        self.mealComposition = mealComposition
        self.fedState = fedState
        self.appetite = appetite
        self.hydration = hydration
        self.giTags = giTags
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

public struct AtlasWorkoutEntrySummary: Identifiable, Equatable, Sendable {
    public var id: String
    public var activityKind: AtlasWorkoutActivityKind
    public var startedAt: Date
    public var endedAt: Date
    public var durationLabel: String
    public var detailLabel: String?
    public var source: AtlasHealthDataSource

    public init(
        id: String,
        activityKind: AtlasWorkoutActivityKind,
        startedAt: Date,
        endedAt: Date,
        durationLabel: String,
        detailLabel: String?,
        source: AtlasHealthDataSource
    ) {
        self.id = id
        self.activityKind = activityKind
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationLabel = durationLabel
        self.detailLabel = detailLabel
        self.source = source
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
    public var mealSize: AtlasContextMealSize?
    public var mealComposition: AtlasContextMealComposition?
    public var fedState: AtlasContextFedState?
    public var appetite: AtlasContextAppetiteState?
    public var hydration: AtlasContextHydrationState?
    public var giTags: [AtlasContextGITag]
    public var note: String?
    public var tags: [String]
    public var presetKey: String?

    public init(
        id: String,
        protocolID: String?,
        canonicalProtocolTitle: String?,
        aliasProtocolTitle: String?,
        loggedAt: Date,
        mealTiming: AtlasContextMealTiming?,
        mealSize: AtlasContextMealSize?,
        mealComposition: AtlasContextMealComposition?,
        fedState: AtlasContextFedState?,
        appetite: AtlasContextAppetiteState?,
        hydration: AtlasContextHydrationState?,
        giTags: [AtlasContextGITag],
        note: String?,
        tags: [String],
        presetKey: String?
    ) {
        self.id = id
        self.protocolID = protocolID
        self.canonicalProtocolTitle = canonicalProtocolTitle
        self.aliasProtocolTitle = aliasProtocolTitle
        self.loggedAt = loggedAt
        self.mealTiming = mealTiming
        self.mealSize = mealSize
        self.mealComposition = mealComposition
        self.fedState = fedState
        self.appetite = appetite
        self.hydration = hydration
        self.giTags = giTags
        self.note = note
        self.tags = tags
        self.presetKey = presetKey
    }
}

public struct AtlasContextPresetSummary: Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var mealTiming: AtlasContextMealTiming?
    public var mealSize: AtlasContextMealSize?
    public var mealComposition: AtlasContextMealComposition?
    public var fedState: AtlasContextFedState?
    public var appetite: AtlasContextAppetiteState?
    public var hydration: AtlasContextHydrationState?
    public var giTags: [AtlasContextGITag]
    public var createdAt: Date
    public var updatedAt: Date
    public var lastUsedAt: Date?

    public init(
        id: String,
        title: String,
        mealTiming: AtlasContextMealTiming?,
        mealSize: AtlasContextMealSize?,
        mealComposition: AtlasContextMealComposition?,
        fedState: AtlasContextFedState?,
        appetite: AtlasContextAppetiteState?,
        hydration: AtlasContextHydrationState?,
        giTags: [AtlasContextGITag],
        createdAt: Date,
        updatedAt: Date,
        lastUsedAt: Date?
    ) {
        self.id = id
        self.title = title
        self.mealTiming = mealTiming
        self.mealSize = mealSize
        self.mealComposition = mealComposition
        self.fedState = fedState
        self.appetite = appetite
        self.hydration = hydration
        self.giTags = giTags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastUsedAt = lastUsedAt
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

public enum AtlasNutritionTargetKind: String, CaseIterable, Sendable, Identifiable {
    case proteinMeals = "protein_meals"
    case fiberMeals = "fiber_meals"
    case hydrationCheckins = "hydration_checkins"

    public var id: String { rawValue }
}

public struct AtlasNutritionTargetSnapshot: Equatable, Sendable, Identifiable {
    public var id: AtlasNutritionTargetKind { kind }
    public var kind: AtlasNutritionTargetKind
    public var title: String
    public var progressLabel: String
    public var helperText: String
    public var symbolName: String
    public var currentValue: Int
    public var targetValue: Int
    public var progress: Double
    public var isMet: Bool

    public init(
        kind: AtlasNutritionTargetKind,
        title: String,
        progressLabel: String,
        helperText: String,
        symbolName: String,
        currentValue: Int,
        targetValue: Int,
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

public enum AtlasNutritionCaptureSource: String, Sendable, Equatable, CaseIterable, Identifiable {
    case lookup
    case packageCode = "package_code"
    case freeform

    public var id: String { rawValue }
}

public struct AtlasNutritionFoodLookupItem: Sendable, Equatable, Identifiable {
    public var id: String
    public var title: String
    public var subtitle: String
    public var symbolName: String
    public var packageCodes: [String]
    public var keywords: [String]
    public var mealTiming: AtlasContextMealTiming?
    public var mealSize: AtlasContextMealSize?
    public var mealComposition: AtlasContextMealComposition?
    public var fedState: AtlasContextFedState?
    public var appetite: AtlasContextAppetiteState?
    public var hydration: AtlasContextHydrationState?
    public var giTags: [AtlasContextGITag]
    public var note: String?
    public var tags: [String]

    public init(
        id: String,
        title: String,
        subtitle: String,
        symbolName: String,
        packageCodes: [String] = [],
        keywords: [String] = [],
        mealTiming: AtlasContextMealTiming? = nil,
        mealSize: AtlasContextMealSize? = nil,
        mealComposition: AtlasContextMealComposition? = nil,
        fedState: AtlasContextFedState? = nil,
        appetite: AtlasContextAppetiteState? = nil,
        hydration: AtlasContextHydrationState? = nil,
        giTags: [AtlasContextGITag] = [],
        note: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.packageCodes = packageCodes
        self.keywords = keywords
        self.mealTiming = mealTiming
        self.mealSize = mealSize
        self.mealComposition = mealComposition
        self.fedState = fedState
        self.appetite = appetite
        self.hydration = hydration
        self.giTags = giTags
        self.note = note
        self.tags = tags
    }

    public func makeDraft(loggedAt: Date, note overrideNote: String? = nil) -> AtlasContextEntryDraft {
        AtlasContextEntryDraft(
            loggedAt: loggedAt,
            mealTiming: mealTiming,
            mealSize: mealSize,
            mealComposition: mealComposition,
            fedState: fedState,
            appetite: appetite,
            hydration: hydration,
            giTags: giTags,
            note: overrideNote ?? note,
            tags: tags
        )
    }

    public func makeSuggestion(
        loggedAt: Date,
        source: AtlasNutritionCaptureSource,
        helperText: String
    ) -> AtlasNutritionQuickCaptureSuggestion {
        AtlasNutritionQuickCaptureSuggestion(
            id: "\(source.rawValue)-\(id)",
            title: title,
            subtitle: subtitle,
            helperText: helperText,
            symbolName: symbolName,
            source: source,
            draft: makeDraft(loggedAt: loggedAt)
        )
    }
}

public struct AtlasNutritionQuickCaptureSuggestion: Sendable, Equatable, Identifiable {
    public var id: String
    public var title: String
    public var subtitle: String
    public var helperText: String
    public var symbolName: String
    public var source: AtlasNutritionCaptureSource
    public var draft: AtlasContextEntryDraft

    public init(
        id: String,
        title: String,
        subtitle: String,
        helperText: String,
        symbolName: String,
        source: AtlasNutritionCaptureSource,
        draft: AtlasContextEntryDraft
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.helperText = helperText
        self.symbolName = symbolName
        self.source = source
        self.draft = draft
    }
}

public func atlasDefaultNutritionFoodCatalog() -> [AtlasNutritionFoodLookupItem] {
    [
        AtlasNutritionFoodLookupItem(
            id: "greek-yogurt-berries",
            title: "Greek yogurt + berries",
            subtitle: "Protein-forward breakfast or snack",
            symbolName: "sun.max.fill",
            packageCodes: ["GYB-01", "860009001001"],
            keywords: ["greek", "yogurt", "berries", "breakfast", "snack", "protein"],
            mealTiming: .breakfast,
            mealSize: .light,
            mealComposition: .proteinHeavy,
            fedState: .fed,
            tags: ["greek-yogurt", "berries"]
        ),
        AtlasNutritionFoodLookupItem(
            id: "overnight-oats",
            title: "Overnight oats",
            subtitle: "Fiber-forward breakfast",
            symbolName: "sunrise.fill",
            packageCodes: ["OATS-01", "860009001002"],
            keywords: ["oats", "oatmeal", "overnight", "breakfast", "fiber"],
            mealTiming: .breakfast,
            mealSize: .standard,
            mealComposition: .fiberForward,
            fedState: .fed,
            tags: ["oats", "breakfast"]
        ),
        AtlasNutritionFoodLookupItem(
            id: "protein-shake",
            title: "Protein shake",
            subtitle: "Fast post-workout recovery option",
            symbolName: "figure.strengthtraining.traditional",
            packageCodes: ["SHAKE-01", "860009001003"],
            keywords: ["protein", "shake", "smoothie", "recovery", "post", "workout"],
            mealTiming: .snack,
            mealSize: .light,
            mealComposition: .proteinHeavy,
            fedState: .fed,
            note: "Logged from the quick protein shake matcher.",
            tags: ["protein-shake", "recovery"]
        ),
        AtlasNutritionFoodLookupItem(
            id: "chicken-rice-bowl",
            title: "Chicken rice bowl",
            subtitle: "Balanced lunch or dinner",
            symbolName: "fork.knife.circle.fill",
            packageCodes: ["BOWL-01", "860009001004"],
            keywords: ["chicken", "rice", "bowl", "lunch", "dinner", "meal"],
            mealTiming: .lunch,
            mealSize: .standard,
            mealComposition: .mixed,
            fedState: .fed,
            tags: ["chicken", "rice"]
        ),
        AtlasNutritionFoodLookupItem(
            id: "salmon-potatoes",
            title: "Salmon + potatoes",
            subtitle: "Steady dinner with recovery overlap",
            symbolName: "moon.stars.fill",
            packageCodes: ["SALMON-01", "860009001005"],
            keywords: ["salmon", "potatoes", "dinner", "recovery", "protein"],
            mealTiming: .dinner,
            mealSize: .standard,
            mealComposition: .proteinHeavy,
            fedState: .fed,
            tags: ["salmon", "potatoes"]
        ),
        AtlasNutritionFoodLookupItem(
            id: "beans-rice",
            title: "Beans + rice",
            subtitle: "Fiber-forward staple meal",
            symbolName: "leaf.circle.fill",
            packageCodes: ["BEANS-01", "860009001006"],
            keywords: ["beans", "rice", "fiber", "lunch", "dinner", "bowl"],
            mealTiming: .dinner,
            mealSize: .standard,
            mealComposition: .fiberForward,
            fedState: .fed,
            tags: ["beans", "rice", "fiber"]
        ),
        AtlasNutritionFoodLookupItem(
            id: "big-salad-bowl",
            title: "Big salad bowl",
            subtitle: "Fiber-forward meal with lighter size",
            symbolName: "leaf.fill",
            packageCodes: ["SALAD-01", "860009001007"],
            keywords: ["salad", "greens", "veggies", "fiber", "lunch", "dinner"],
            mealTiming: .lunch,
            mealSize: .light,
            mealComposition: .fiberForward,
            fedState: .fed,
            tags: ["salad", "greens", "fiber"]
        ),
        AtlasNutritionFoodLookupItem(
            id: "electrolyte-water",
            title: "Electrolyte water",
            subtitle: "Hydration check-in",
            symbolName: "drop.circle.fill",
            packageCodes: ["HYDRATE-01", "860009001008"],
            keywords: ["water", "electrolyte", "hydration", "drink"],
            hydration: .high,
            giTags: [.calm],
            note: "Logged from hydration quick capture.",
            tags: ["hydration", "electrolytes"]
        )
    ]
}

public func atlasNutritionLookupItems(
    matching query: String,
    limit: Int = 6
) -> [AtlasNutritionFoodLookupItem] {
    let normalizedQuery = atlasNormalizeNutritionSearchText(query)
    let catalog = atlasDefaultNutritionFoodCatalog()
    guard normalizedQuery.isEmpty == false else {
        return Array(catalog.prefix(limit))
    }

    let tokens = Set(normalizedQuery.split(separator: " ").map(String.init))
    var matches: [(AtlasNutritionFoodLookupItem, Int)] = []

    for item in catalog {
        let searchableValues = [item.title, item.subtitle] + item.keywords + item.packageCodes
        var haystack: Set<String> = []
        for value in searchableValues {
            let normalizedValue = atlasNormalizeNutritionSearchText(value)
            let pieces = normalizedValue.split(separator: " ").map(String.init)
            haystack.formUnion(pieces)
        }

        let score = tokens.intersection(haystack).count
        if score > 0 {
            matches.append((item, score))
        }
    }

    return matches
        .sorted {
            if $0.1 == $1.1 {
                return $0.0.title.localizedCaseInsensitiveCompare($1.0.title) == .orderedAscending
            }
            return $0.1 > $1.1
        }
        .prefix(limit)
        .map(\.0)
}

public func atlasNutritionPackageCodeSuggestion(
    for rawCode: String,
    loggedAt: Date
) -> AtlasNutritionQuickCaptureSuggestion? {
    let normalizedCode = atlasNormalizeNutritionSearchText(rawCode).replacingOccurrences(of: " ", with: "")
    guard normalizedCode.isEmpty == false else {
        return nil
    }

    guard let match = atlasDefaultNutritionFoodCatalog().first(where: { item in
        item.packageCodes.contains(where: {
            atlasNormalizeNutritionSearchText($0).replacingOccurrences(of: " ", with: "") == normalizedCode
        })
    }) else {
        return nil
    }

    return match.makeSuggestion(
        loggedAt: loggedAt,
        source: .packageCode,
        helperText: "Atlas matched this local package code to a common food profile."
    )
}

public func atlasNutritionQuickCaptureSuggestion(
    for text: String,
    loggedAt: Date
) -> AtlasNutritionQuickCaptureSuggestion? {
    let normalizedText = atlasNormalizeNutritionSearchText(text)
    guard normalizedText.isEmpty == false else {
        return nil
    }

    let lookupMatches = atlasNutritionLookupItems(matching: normalizedText, limit: 1)
    if let bestMatch = lookupMatches.first {
        return AtlasNutritionQuickCaptureSuggestion(
            id: "freeform-\(bestMatch.id)",
            title: bestMatch.title,
            subtitle: bestMatch.subtitle,
            helperText: "Atlas matched this typed or dictated meal to a local food profile.",
            symbolName: bestMatch.symbolName,
            source: .freeform,
            draft: bestMatch.makeDraft(
                loggedAt: loggedAt,
                note: text.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
    }

    let tokens = Set(normalizedText.split(separator: " ").map(String.init))
    let containsAny: (Set<String>) -> Bool = { candidates in
        tokens.isDisjoint(with: candidates) == false
    }

    let mealTiming: AtlasContextMealTiming? = {
        if containsAny(["breakfast", "am"]) { return .breakfast }
        if containsAny(["lunch", "midday"]) { return .lunch }
        if containsAny(["dinner", "evening"]) { return .dinner }
        if containsAny(["snack"]) { return .snack }
        if containsAny(["late", "night"]) { return .lateNight }
        return nil
    }()

    let mealComposition: AtlasContextMealComposition? = {
        if containsAny(["protein", "chicken", "steak", "turkey", "eggs", "yogurt", "shake"]) {
            return .proteinHeavy
        }
        if containsAny(["fiber", "beans", "lentils", "oats", "salad", "greens", "berries"]) {
            return .fiberForward
        }
        if containsAny(["pasta", "rice", "bread", "bagel"]) {
            return .carbHeavy
        }
        if containsAny(["fried", "pizza", "burger", "fatty"]) {
            return .fatHeavy
        }
        return nil
    }()

    let hydration: AtlasContextHydrationState? = containsAny(["water", "electrolyte", "hydration", "hydrated", "drink"]) ? .high : nil
    let mealSize: AtlasContextMealSize? = {
        if containsAny(["light", "small"]) { return .light }
        if containsAny(["heavy", "large", "big"]) { return .heavy }
        if mealTiming != nil || mealComposition != nil { return .standard }
        return nil
    }()
    let fedState: AtlasContextFedState? = (mealTiming != nil || mealComposition != nil) ? .fed : nil

    let tags = Array(
        Set(
            tokens.compactMap { token -> String? in
                switch token {
                case "post", "workout", "recovery": return "recovery"
                case "protein": return "protein"
                case "fiber": return "fiber"
                case "water", "electrolyte", "hydration": return "hydration"
                default: return nil
                }
            }
        )
    ).sorted()

    guard mealTiming != nil
        || mealComposition != nil
        || hydration != nil
        || tags.isEmpty == false else {
        return nil
    }

    let summaryParts = [
        mealTiming?.title,
        mealComposition?.title,
        hydration?.title
    ].compactMap { $0 }

    return AtlasNutritionQuickCaptureSuggestion(
        id: "freeform-\(normalizedText)",
        title: summaryParts.isEmpty ? "Quick meal capture" : summaryParts.joined(separator: " • "),
        subtitle: "Atlas parsed this from typed or dictated text.",
        helperText: "Review the prefilled meal context before saving if you want to refine the details.",
        symbolName: hydration == .high ? "drop.fill" : "text.badge.checkmark",
        source: .freeform,
        draft: AtlasContextEntryDraft(
            loggedAt: loggedAt,
            mealTiming: mealTiming,
            mealSize: mealSize,
            mealComposition: mealComposition,
            fedState: fedState,
            hydration: hydration,
            note: text.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: tags
        )
    )
}

private func atlasNormalizeNutritionSearchText(_ value: String) -> String {
    value
        .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        .replacingOccurrences(of: "[^a-zA-Z0-9]+", with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
}

public enum AtlasNutritionWeeklySignalKind: String, CaseIterable, Sendable, Identifiable {
    case proteinDays = "protein_days"
    case fiberDays = "fiber_days"
    case hydrationDays = "hydration_days"
    case workoutFueling = "workout_fueling"

    public var id: String { rawValue }
}

public struct AtlasNutritionWeeklySignalSnapshot: Equatable, Sendable, Identifiable {
    public var id: AtlasNutritionWeeklySignalKind { kind }
    public var kind: AtlasNutritionWeeklySignalKind
    public var title: String
    public var valueLabel: String
    public var helperText: String
    public var symbolName: String
    public var isOnTrack: Bool

    public init(
        kind: AtlasNutritionWeeklySignalKind,
        title: String,
        valueLabel: String,
        helperText: String,
        symbolName: String,
        isOnTrack: Bool
    ) {
        self.kind = kind
        self.title = title
        self.valueLabel = valueLabel
        self.helperText = helperText
        self.symbolName = symbolName
        self.isOnTrack = isOnTrack
    }
}

public enum AtlasNutritionCoachingCardKind: String, CaseIterable, Sendable, Identifiable {
    case consistency
    case workoutFueling = "workout_fueling"
    case hydration
    case weight

    public var id: String { rawValue }
}

public struct AtlasNutritionCoachingCard: Equatable, Sendable, Identifiable {
    public var id: String
    public var kind: AtlasNutritionCoachingCardKind
    public var title: String
    public var summary: String
    public var helperText: String
    public var symbolName: String

    public init(
        id: String,
        kind: AtlasNutritionCoachingCardKind,
        title: String,
        summary: String,
        helperText: String,
        symbolName: String
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.summary = summary
        self.helperText = helperText
        self.symbolName = symbolName
    }
}

public struct AtlasNutritionSnapshot: Equatable, Sendable {
    public var dailyTargets: [AtlasNutritionTargetSnapshot]
    public var favoriteMealCount: Int
    public var recentMealCount: Int
    public var latestMealLabel: String?
    public var weeklySignals: [AtlasNutritionWeeklySignalSnapshot]
    public var coachingCards: [AtlasNutritionCoachingCard]
    public var note: String

    public init(
        dailyTargets: [AtlasNutritionTargetSnapshot] = [],
        favoriteMealCount: Int = 0,
        recentMealCount: Int = 0,
        latestMealLabel: String? = nil,
        weeklySignals: [AtlasNutritionWeeklySignalSnapshot] = [],
        coachingCards: [AtlasNutritionCoachingCard] = [],
        note: String = "Atlas keeps nutrition lightweight here: quick meals, repeated favorites, and simple daily targets."
    ) {
        self.dailyTargets = dailyTargets
        self.favoriteMealCount = favoriteMealCount
        self.recentMealCount = recentMealCount
        self.latestMealLabel = latestMealLabel
        self.weeklySignals = weeklySignals
        self.coachingCards = coachingCards
        self.note = note
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

public enum AtlasDeterministicInsightKind: String, CaseIterable, Sendable {
    case symptomContext
    case symptomWorkout
    case symptomWeight
    case symptomMetric
}

public struct AtlasDeterministicInsightCard: Identifiable, Equatable, Sendable {
    public var id: String
    public var kind: AtlasDeterministicInsightKind
    public var title: String
    public var summary: String
    public var facts: [AtlasExplainerFact]

    public init(
        id: String,
        kind: AtlasDeterministicInsightKind,
        title: String,
        summary: String,
        facts: [AtlasExplainerFact]
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.summary = summary
        self.facts = facts
    }
}

public struct AtlasInsightsSnapshot: Equatable, Sendable {
    public var weightTrend: AtlasWeightTrendSummary
    public var symptomTrend: [AtlasSymptomTrendItem]
    public var contextTrend: AtlasContextTrendSummary
    public var nutritionSnapshot: AtlasNutritionSnapshot
    public var deterministicExplanations: [AtlasDeterministicInsightCard]
    public var savedContextPresets: [AtlasContextPresetSummary]
    public var inventoryBurnDown: [AtlasInventoryBurnDownInsight]
    public var adherenceTrend: AtlasAdherenceTrendSummary
    public var amountInSystemDisclaimer: String
    public var amountInSystem: [AtlasAmountEstimateItem]
    public var episodeIntelligence: AtlasEpisodeInsightsSnapshot
    public var customMetricDefinitions: [AtlasMetricDefinitionSummary]
    public var recentContextEntries: [AtlasContextEntrySummary]
    public var recentWeightEntries: [AtlasWeightEntrySummary]
    public var recentWorkoutEntries: [AtlasWorkoutEntrySummary]
    public var recentSymptomEntries: [AtlasSymptomEntrySummary]
    public var recentMetricEntries: [AtlasMetricValueEntrySummary]
    public var weeklyRecapSummary: AtlasGeneratedSummary?
    public var episodeRecapSummary: AtlasGeneratedSummary?
    public var weeklyReviewSeed: AtlasWeeklyReviewSeed?
    public var weeklyReviewHistory: [AtlasWeeklyReviewSeed]
    public var hasAnyInsightData: Bool

    public init(
        weightTrend: AtlasWeightTrendSummary = .init(),
        symptomTrend: [AtlasSymptomTrendItem] = [],
        contextTrend: AtlasContextTrendSummary = .init(),
        nutritionSnapshot: AtlasNutritionSnapshot = .init(),
        deterministicExplanations: [AtlasDeterministicInsightCard] = [],
        savedContextPresets: [AtlasContextPresetSummary] = [],
        inventoryBurnDown: [AtlasInventoryBurnDownInsight] = [],
        adherenceTrend: AtlasAdherenceTrendSummary = .init(),
        amountInSystemDisclaimer: String = "Estimate only. Atlas spreads logged quantities across each protocol interval as a scheduling model, not a medical or pharmacokinetic calculation.",
        amountInSystem: [AtlasAmountEstimateItem] = [],
        episodeIntelligence: AtlasEpisodeInsightsSnapshot = .init(),
        customMetricDefinitions: [AtlasMetricDefinitionSummary] = [],
        recentContextEntries: [AtlasContextEntrySummary] = [],
        recentWeightEntries: [AtlasWeightEntrySummary] = [],
        recentWorkoutEntries: [AtlasWorkoutEntrySummary] = [],
        recentSymptomEntries: [AtlasSymptomEntrySummary] = [],
        recentMetricEntries: [AtlasMetricValueEntrySummary] = [],
        weeklyRecapSummary: AtlasGeneratedSummary? = nil,
        episodeRecapSummary: AtlasGeneratedSummary? = nil,
        weeklyReviewSeed: AtlasWeeklyReviewSeed? = nil,
        weeklyReviewHistory: [AtlasWeeklyReviewSeed] = [],
        hasAnyInsightData: Bool = false
    ) {
        self.weightTrend = weightTrend
        self.symptomTrend = symptomTrend
        self.contextTrend = contextTrend
        self.nutritionSnapshot = nutritionSnapshot
        self.deterministicExplanations = deterministicExplanations
        self.savedContextPresets = savedContextPresets
        self.inventoryBurnDown = inventoryBurnDown
        self.adherenceTrend = adherenceTrend
        self.amountInSystemDisclaimer = amountInSystemDisclaimer
        self.amountInSystem = amountInSystem
        self.episodeIntelligence = episodeIntelligence
        self.customMetricDefinitions = customMetricDefinitions
        self.recentContextEntries = recentContextEntries
        self.recentWeightEntries = recentWeightEntries
        self.recentWorkoutEntries = recentWorkoutEntries
        self.recentSymptomEntries = recentSymptomEntries
        self.recentMetricEntries = recentMetricEntries
        self.weeklyRecapSummary = weeklyRecapSummary
        self.episodeRecapSummary = episodeRecapSummary
        self.weeklyReviewSeed = weeklyReviewSeed
        self.weeklyReviewHistory = weeklyReviewHistory
        self.hasAnyInsightData = hasAnyInsightData
    }
}
