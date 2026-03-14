import Foundation

public struct AtlasInventorySnapshot: Equatable, Sendable {
    public var protocolSettings: [AtlasProtocolInventorySetting]
    public var vials: [AtlasVialSummary]
    public var sites: [AtlasSiteSummary]

    public init(
        protocolSettings: [AtlasProtocolInventorySetting] = [],
        vials: [AtlasVialSummary] = [],
        sites: [AtlasSiteSummary] = []
    ) {
        self.protocolSettings = protocolSettings
        self.vials = vials
        self.sites = sites
    }

    public var lowStockCount: Int {
        vials.filter(\.isLowStock).count
    }
}

public struct AtlasProtocolInventorySetting: Identifiable, Hashable, Sendable {
    public var id: String
    public var canonicalTitle: String
    public var aliasTitle: String?
    public var kindLabel: String
    public var cadenceLabel: String
    public var doseLabel: String?
    public var linkedVialID: String?
    public var linkedVialLabel: String?
    public var siteTrackingEnabled: Bool
    public var siteRotationEnabled: Bool

    public init(
        id: String,
        canonicalTitle: String,
        aliasTitle: String?,
        kindLabel: String,
        cadenceLabel: String,
        doseLabel: String?,
        linkedVialID: String?,
        linkedVialLabel: String?,
        siteTrackingEnabled: Bool,
        siteRotationEnabled: Bool
    ) {
        self.id = id
        self.canonicalTitle = canonicalTitle
        self.aliasTitle = aliasTitle
        self.kindLabel = kindLabel
        self.cadenceLabel = cadenceLabel
        self.doseLabel = doseLabel
        self.linkedVialID = linkedVialID
        self.linkedVialLabel = linkedVialLabel
        self.siteTrackingEnabled = siteTrackingEnabled
        self.siteRotationEnabled = siteRotationEnabled
    }
}

public struct AtlasVialSummary: Identifiable, Hashable, Sendable {
    public var id: String
    public var label: String
    public var linkedProtocolID: String?
    public var linkedProtocolCanonicalTitle: String?
    public var linkedProtocolAliasTitle: String?
    public var calculatorProfileID: String?
    public var calculatorProfileLabel: String?
    public var quantityLabel: String
    public var lowStockLabel: String?
    public var projectedDepletionLabel: String?
    public var autoDecrementLabel: String?
    public var remainingQuantity: Double
    public var startingQuantity: Double
    public var quantityUnit: String
    public var isLowStock: Bool
    public var archivedAt: Date?

    public init(
        id: String,
        label: String,
        linkedProtocolID: String?,
        linkedProtocolCanonicalTitle: String?,
        linkedProtocolAliasTitle: String?,
        calculatorProfileID: String?,
        calculatorProfileLabel: String?,
        quantityLabel: String,
        lowStockLabel: String?,
        projectedDepletionLabel: String?,
        autoDecrementLabel: String?,
        remainingQuantity: Double,
        startingQuantity: Double,
        quantityUnit: String,
        isLowStock: Bool,
        archivedAt: Date?
    ) {
        self.id = id
        self.label = label
        self.linkedProtocolID = linkedProtocolID
        self.linkedProtocolCanonicalTitle = linkedProtocolCanonicalTitle
        self.linkedProtocolAliasTitle = linkedProtocolAliasTitle
        self.calculatorProfileID = calculatorProfileID
        self.calculatorProfileLabel = calculatorProfileLabel
        self.quantityLabel = quantityLabel
        self.lowStockLabel = lowStockLabel
        self.projectedDepletionLabel = projectedDepletionLabel
        self.autoDecrementLabel = autoDecrementLabel
        self.remainingQuantity = remainingQuantity
        self.startingQuantity = startingQuantity
        self.quantityUnit = quantityUnit
        self.isLowStock = isLowStock
        self.archivedAt = archivedAt
    }
}

public struct AtlasInventoryCorrectionEntry: Identifiable, Equatable, Sendable {
    public var id: String
    public var deltaLabel: String
    public var note: String?
    public var recordedAt: Date

    public init(
        id: String,
        deltaLabel: String,
        note: String?,
        recordedAt: Date
    ) {
        self.id = id
        self.deltaLabel = deltaLabel
        self.note = note
        self.recordedAt = recordedAt
    }
}

public struct AtlasVialDraft: Equatable, Sendable {
    public var id: String?
    public var label: String
    public var protocolID: String?
    public var startingQuantity: Double
    public var remainingQuantity: Double
    public var quantityUnit: String
    public var lowStockThreshold: Double?
    public var concentrationValue: Double?
    public var concentrationUnit: String?
    public var volumeML: Double?
    public var calculatorProfileID: String?
    public var openedAt: Date?
    public var expiresAt: Date?
    public var archivedAt: Date?

    public init(
        id: String? = nil,
        label: String = "",
        protocolID: String? = nil,
        startingQuantity: Double = 1,
        remainingQuantity: Double = 1,
        quantityUnit: String = "dose",
        lowStockThreshold: Double? = nil,
        concentrationValue: Double? = nil,
        concentrationUnit: String? = nil,
        volumeML: Double? = nil,
        calculatorProfileID: String? = nil,
        openedAt: Date? = nil,
        expiresAt: Date? = nil,
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.label = label
        self.protocolID = protocolID
        self.startingQuantity = startingQuantity
        self.remainingQuantity = remainingQuantity
        self.quantityUnit = quantityUnit
        self.lowStockThreshold = lowStockThreshold
        self.concentrationValue = concentrationValue
        self.concentrationUnit = concentrationUnit
        self.volumeML = volumeML
        self.calculatorProfileID = calculatorProfileID
        self.openedAt = openedAt
        self.expiresAt = expiresAt
        self.archivedAt = archivedAt
    }
}

public struct AtlasVialDetailSnapshot: Equatable, Sendable {
    public var summary: AtlasVialSummary
    public var editableDraft: AtlasVialDraft
    public var correctionHistory: [AtlasInventoryCorrectionEntry]

    public init(
        summary: AtlasVialSummary,
        editableDraft: AtlasVialDraft,
        correctionHistory: [AtlasInventoryCorrectionEntry]
    ) {
        self.summary = summary
        self.editableDraft = editableDraft
        self.correctionHistory = correctionHistory
    }
}

public struct AtlasInventoryCorrectionDraft: Equatable, Sendable {
    public var vialID: String
    public var nextRemainingQuantity: Double
    public var note: String?

    public init(vialID: String, nextRemainingQuantity: Double, note: String? = nil) {
        self.vialID = vialID
        self.nextRemainingQuantity = nextRemainingQuantity
        self.note = note
    }
}

public struct AtlasInventoryCorrectionResult: Equatable, Sendable {
    public var vial: AtlasVialDetailSnapshot
    public var eventID: String?

    public init(vial: AtlasVialDetailSnapshot, eventID: String?) {
        self.vial = vial
        self.eventID = eventID
    }
}

public struct AtlasProtocolInventorySettingsUpdate: Equatable, Sendable {
    public var protocolID: String
    public var linkedVialID: String?
    public var siteTrackingEnabled: Bool
    public var siteRotationEnabled: Bool

    public init(
        protocolID: String,
        linkedVialID: String?,
        siteTrackingEnabled: Bool,
        siteRotationEnabled: Bool
    ) {
        self.protocolID = protocolID
        self.linkedVialID = linkedVialID
        self.siteTrackingEnabled = siteTrackingEnabled
        self.siteRotationEnabled = siteRotationEnabled
    }
}

public struct AtlasSiteSummary: Identifiable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var bodyArea: String?
    public var notes: String?
    public var archivedAt: Date?

    public init(
        id: String,
        name: String,
        bodyArea: String?,
        notes: String?,
        archivedAt: Date?
    ) {
        self.id = id
        self.name = name
        self.bodyArea = bodyArea
        self.notes = notes
        self.archivedAt = archivedAt
    }
}

public struct AtlasSiteDraft: Equatable, Sendable {
    public var id: String?
    public var name: String
    public var bodyArea: String?
    public var notes: String?
    public var archivedAt: Date?

    public init(
        id: String? = nil,
        name: String = "",
        bodyArea: String? = nil,
        notes: String? = nil,
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.bodyArea = bodyArea
        self.notes = notes
        self.archivedAt = archivedAt
    }
}

public struct AtlasProtocolSiteOptions: Equatable, Sendable {
    public var protocolID: String
    public var siteTrackingEnabled: Bool
    public var siteRotationEnabled: Bool
    public var sites: [AtlasSiteSummary]
    public var suggestedSiteID: String?
    public var lastUsedSiteID: String?

    public init(
        protocolID: String,
        siteTrackingEnabled: Bool,
        siteRotationEnabled: Bool,
        sites: [AtlasSiteSummary],
        suggestedSiteID: String?,
        lastUsedSiteID: String?
    ) {
        self.protocolID = protocolID
        self.siteTrackingEnabled = siteTrackingEnabled
        self.siteRotationEnabled = siteRotationEnabled
        self.sites = sites
        self.suggestedSiteID = suggestedSiteID
        self.lastUsedSiteID = lastUsedSiteID
    }
}

public struct AtlasCalculatorProfileDraft: Equatable, Sendable {
    public var id: String?
    public var label: String
    public var powderAmount: Double
    public var powderUnit: String
    public var diluentVolume: Double
    public var diluentUnit: String
    public var drawVolume: Double
    public var drawUnit: String

    public init(
        id: String? = nil,
        label: String = "",
        powderAmount: Double = 0,
        powderUnit: String = "mg",
        diluentVolume: Double = 0,
        diluentUnit: String = "mL",
        drawVolume: Double = 0,
        drawUnit: String = "mL"
    ) {
        self.id = id
        self.label = label
        self.powderAmount = powderAmount
        self.powderUnit = powderUnit
        self.diluentVolume = diluentVolume
        self.diluentUnit = diluentUnit
        self.drawVolume = drawVolume
        self.drawUnit = drawUnit
    }
}

public struct AtlasReconstitutionResult: Equatable, Sendable {
    public var concentrationLabel: String
    public var deliveredAmount: Double
    public var deliveredLabel: String
    public var explanation: [String]

    public init(
        concentrationLabel: String,
        deliveredAmount: Double,
        deliveredLabel: String,
        explanation: [String]
    ) {
        self.concentrationLabel = concentrationLabel
        self.deliveredAmount = deliveredAmount
        self.deliveredLabel = deliveredLabel
        self.explanation = explanation
    }
}

public func atlasCalculateReconstitution(_ draft: AtlasCalculatorProfileDraft) -> AtlasReconstitutionResult {
    let concentration = draft.powderAmount / max(draft.diluentVolume, 0.0001)
    let deliveredAmount = concentration * draft.drawVolume
    let concentrationLabel =
        "\(formatAtlasValue(draft.powderAmount)) \(draft.powderUnit) / \(formatAtlasValue(draft.diluentVolume)) \(draft.diluentUnit) = \(formatAtlasValue(concentration)) \(draft.powderUnit) per \(draft.diluentUnit)"
    let deliveredLabel =
        "\(formatAtlasValue(draft.drawVolume)) \(draft.drawUnit) delivers about \(formatAtlasValue(deliveredAmount)) \(draft.powderUnit)"

    return AtlasReconstitutionResult(
        concentrationLabel: concentrationLabel,
        deliveredAmount: deliveredAmount,
        deliveredLabel: deliveredLabel,
        explanation: [
            "1. Divide \(formatAtlasValue(draft.powderAmount)) \(draft.powderUnit) by \(formatAtlasValue(draft.diluentVolume)) \(draft.diluentUnit) to get concentration.",
            "2. Multiply that concentration by \(formatAtlasValue(draft.drawVolume)) \(draft.drawUnit).",
            "This is a neutral math helper only. Atlas does not recommend what to take."
        ]
    )
}

public func formatAtlasQuantity(_ value: Double, unit: String?) -> String {
    let amount = formatAtlasValue(value)
    guard let unit, unit.isEmpty == false else {
        return amount
    }
    return "\(amount) \(unit)"
}

private func formatAtlasValue(_ value: Double) -> String {
    if abs(value - value.rounded()) < 0.0001 {
        return String(Int(value.rounded()))
    }

    return value.formatted(.number.precision(.fractionLength(0...2)))
}
