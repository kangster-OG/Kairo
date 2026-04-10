import Foundation

public struct AtlasInventorySnapshot: Equatable, Sendable {
    public var protocolSettings: [AtlasProtocolInventorySetting]
    public var vials: [AtlasVialSummary]
    public var consumables: [AtlasConsumableSummary]
    public var sites: [AtlasSiteSummary]

    public init(
        protocolSettings: [AtlasProtocolInventorySetting] = [],
        vials: [AtlasVialSummary] = [],
        consumables: [AtlasConsumableSummary] = [],
        sites: [AtlasSiteSummary] = []
    ) {
        self.protocolSettings = protocolSettings
        self.vials = vials
        self.consumables = consumables
        self.sites = sites
    }

    public var lowStockCount: Int {
        vials.filter(\.isLowStock).count + consumables.filter(\.isLowStock).count
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

public struct AtlasConsumableSummary: Identifiable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var category: String?
    public var linkedProtocolID: String?
    public var linkedProtocolCanonicalTitle: String?
    public var linkedProtocolAliasTitle: String?
    public var vendorLabel: String?
    public var quantityLabel: String
    public var lowStockLabel: String?
    public var projectedDepletionLabel: String?
    public var usageLabel: String?
    public var reorderLeadTimeLabel: String?
    public var quantityOnHand: Double
    public var quantityUnit: String
    public var reorderThreshold: Double?
    public var isLowStock: Bool
    public var archivedAt: Date?

    public init(
        id: String,
        name: String,
        category: String?,
        linkedProtocolID: String?,
        linkedProtocolCanonicalTitle: String?,
        linkedProtocolAliasTitle: String?,
        vendorLabel: String?,
        quantityLabel: String,
        lowStockLabel: String?,
        projectedDepletionLabel: String?,
        usageLabel: String?,
        reorderLeadTimeLabel: String?,
        quantityOnHand: Double,
        quantityUnit: String,
        reorderThreshold: Double?,
        isLowStock: Bool,
        archivedAt: Date?
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.linkedProtocolID = linkedProtocolID
        self.linkedProtocolCanonicalTitle = linkedProtocolCanonicalTitle
        self.linkedProtocolAliasTitle = linkedProtocolAliasTitle
        self.vendorLabel = vendorLabel
        self.quantityLabel = quantityLabel
        self.lowStockLabel = lowStockLabel
        self.projectedDepletionLabel = projectedDepletionLabel
        self.usageLabel = usageLabel
        self.reorderLeadTimeLabel = reorderLeadTimeLabel
        self.quantityOnHand = quantityOnHand
        self.quantityUnit = quantityUnit
        self.reorderThreshold = reorderThreshold
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

public enum AtlasInventoryMovementKind: String, Equatable, Sendable {
    case created
    case takenLog = "taken_log"
    case manualCorrection = "manual_correction"
    case vialHandoff = "vial_handoff"
    case archived
}

public struct AtlasInventoryMovementEntry: Identifiable, Equatable, Sendable {
    public var id: String
    public var kind: AtlasInventoryMovementKind
    public var title: String
    public var detail: String
    public var deltaLabel: String?
    public var recordedAt: Date

    public init(
        id: String,
        kind: AtlasInventoryMovementKind,
        title: String,
        detail: String,
        deltaLabel: String? = nil,
        recordedAt: Date
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
        self.deltaLabel = deltaLabel
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
    public var movementHistory: [AtlasInventoryMovementEntry]

    public init(
        summary: AtlasVialSummary,
        editableDraft: AtlasVialDraft,
        correctionHistory: [AtlasInventoryCorrectionEntry],
        movementHistory: [AtlasInventoryMovementEntry] = []
    ) {
        self.summary = summary
        self.editableDraft = editableDraft
        self.correctionHistory = correctionHistory
        self.movementHistory = movementHistory
    }
}

public enum AtlasConsumableAdjustmentKind: String, Codable, Equatable, Sendable {
    case created
    case manualAdjustment = "manual_adjustment"
    case protocolUse = "protocol_use"
    case archived
    case unarchived
}

public struct AtlasConsumableAdjustmentEntry: Identifiable, Equatable, Sendable {
    public var id: String
    public var kind: AtlasConsumableAdjustmentKind
    public var title: String
    public var detail: String
    public var deltaLabel: String?
    public var resultingQuantityLabel: String
    public var recordedAt: Date

    public init(
        id: String,
        kind: AtlasConsumableAdjustmentKind,
        title: String,
        detail: String,
        deltaLabel: String?,
        resultingQuantityLabel: String,
        recordedAt: Date
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
        self.deltaLabel = deltaLabel
        self.resultingQuantityLabel = resultingQuantityLabel
        self.recordedAt = recordedAt
    }
}

public struct AtlasConsumableDraft: Equatable, Sendable {
    public var id: String?
    public var protocolID: String?
    public var name: String
    public var category: String?
    public var quantityOnHand: Double
    public var unit: String
    public var reorderThreshold: Double?
    public var reorderLeadTimeDays: Int?
    public var quantityPerUse: Double?
    public var lotNumber: String?
    public var sizeDescription: String?
    public var notes: String?
    public var vendorLabel: String?
    public var purchaseNotes: String?
    public var archivedAt: Date?

    public init(
        id: String? = nil,
        protocolID: String? = nil,
        name: String = "",
        category: String? = nil,
        quantityOnHand: Double = 0,
        unit: String = "item",
        reorderThreshold: Double? = nil,
        reorderLeadTimeDays: Int? = nil,
        quantityPerUse: Double? = nil,
        lotNumber: String? = nil,
        sizeDescription: String? = nil,
        notes: String? = nil,
        vendorLabel: String? = nil,
        purchaseNotes: String? = nil,
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.protocolID = protocolID
        self.name = name
        self.category = category
        self.quantityOnHand = quantityOnHand
        self.unit = unit
        self.reorderThreshold = reorderThreshold
        self.reorderLeadTimeDays = reorderLeadTimeDays
        self.quantityPerUse = quantityPerUse
        self.lotNumber = lotNumber
        self.sizeDescription = sizeDescription
        self.notes = notes
        self.vendorLabel = vendorLabel
        self.purchaseNotes = purchaseNotes
        self.archivedAt = archivedAt
    }
}

public struct AtlasConsumableDetailSnapshot: Equatable, Sendable {
    public var summary: AtlasConsumableSummary
    public var editableDraft: AtlasConsumableDraft
    public var adjustmentHistory: [AtlasConsumableAdjustmentEntry]

    public init(
        summary: AtlasConsumableSummary,
        editableDraft: AtlasConsumableDraft,
        adjustmentHistory: [AtlasConsumableAdjustmentEntry]
    ) {
        self.summary = summary
        self.editableDraft = editableDraft
        self.adjustmentHistory = adjustmentHistory
    }
}

public struct AtlasConsumableAdjustmentDraft: Equatable, Sendable {
    public var consumableID: String
    public var nextQuantityOnHand: Double
    public var note: String?

    public init(consumableID: String, nextQuantityOnHand: Double, note: String? = nil) {
        self.consumableID = consumableID
        self.nextQuantityOnHand = nextQuantityOnHand
        self.note = note
    }
}

public struct AtlasConsumableAdjustmentResult: Equatable, Sendable {
    public var consumable: AtlasConsumableDetailSnapshot

    public init(consumable: AtlasConsumableDetailSnapshot) {
        self.consumable = consumable
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

public struct AtlasConsumableCategorySuggestion: Identifiable, Equatable, Sendable {
    public var id: String { value }
    public var value: String

    public init(value: String) {
        self.value = value
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
