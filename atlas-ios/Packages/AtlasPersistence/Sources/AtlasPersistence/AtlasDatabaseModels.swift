import AtlasDomain
import GRDB
import Foundation

private func atlasBasicFormatter() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}

func atlasDate(from timestamp: String) -> Date {
    if let parsed = ISO8601DateFormatter.atlas.date(from: timestamp) {
        return parsed
    }

    if let parsed = atlasBasicFormatter().date(from: timestamp) {
        return parsed
    }

    return Date(timeIntervalSince1970: 0)
}

func atlasTimestamp(from date: Date) -> String {
    ISO8601DateFormatter.atlas.string(from: date)
}

func relativeDueLabel(for date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: Date())
}

func atlasDayStartTimestamp(_ dateString: String) -> String {
    "\(dateString)T00:00:00.000Z"
}

func kindLabel(_ kind: AtlasProtocolKind) -> String {
    switch kind {
    case .glp: "GLP"
    case .peptide: "Peptide"
    case .custom: "Custom"
    }
}

private func cadenceLabel(from rule: AtlasProtocolRuleRecord?) -> String {
    guard let rule else {
        return "Cadence pending"
    }

    switch rule.ruleType {
    case .weekly:
        return "Weekly cadence"
    case .daily:
        return "Daily cadence"
    case .everyNDays:
        return "Every \(rule.intervalCount) days"
    }
}

struct AtlasCalculatorProfileDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "calculator_profiles"
    var id: String
    var label: String
    var powderAmount: Double
    var powderUnit: String
    var diluentVolume: Double
    var diluentUnit: String
    var drawVolume: Double
    var drawUnit: String
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case label
        case powderAmount = "powder_amount"
        case powderUnit = "powder_unit"
        case diluentVolume = "diluent_volume"
        case diluentUnit = "diluent_unit"
        case drawVolume = "draw_volume"
        case drawUnit = "draw_unit"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(record: AtlasCalculatorProfileRecord) {
        id = record.id
        label = record.label
        powderAmount = record.powderAmount
        powderUnit = record.powderUnit
        diluentVolume = record.diluentVolume
        diluentUnit = record.diluentUnit
        drawVolume = record.drawVolume
        drawUnit = record.drawUnit
        createdAt = record.createdAt
        updatedAt = record.updatedAt
    }

    var domain: AtlasCalculatorProfileRecord {
        AtlasCalculatorProfileRecord.make(
            id: id,
            label: label,
            powderAmount: powderAmount,
            powderUnit: powderUnit,
            diluentVolume: diluentVolume,
            diluentUnit: diluentUnit,
            drawVolume: drawVolume,
            drawUnit: drawUnit,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct AtlasCompoundDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "compounds"
    var id: String
    var slug: String
    var displayName: String
    var compoundType: String
    var isUserDefined: Bool
    var notes: String?
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case displayName = "display_name"
        case compoundType = "compound_type"
        case isUserDefined = "is_user_defined"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(record: AtlasCompoundRecord) {
        id = record.id
        slug = record.slug
        displayName = record.displayName
        compoundType = record.compoundType
        isUserDefined = record.isUserDefined
        notes = record.notes
        createdAt = record.createdAt
        updatedAt = record.updatedAt
    }

    var domain: AtlasCompoundRecord {
        AtlasCompoundRecord.make(
            id: id,
            slug: slug,
            displayName: displayName,
            compoundType: compoundType,
            isUserDefined: isUserDefined,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct AtlasCustomMetricDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "custom_metrics"
    var id: String
    var protocolId: String?
    var metricKey: String
    var label: String
    var valueType: AtlasCustomMetricValueType
    var unit: String?
    var scaleMin: Int?
    var scaleMax: Int?
    var createdAt: String
    var updatedAt: String
    var archivedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case metricKey = "metric_key"
        case label
        case valueType = "value_type"
        case unit
        case scaleMin = "scale_min"
        case scaleMax = "scale_max"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
    }

    init(record: AtlasCustomMetricRecord) {
        id = record.id
        protocolId = record.protocolId
        metricKey = record.metricKey
        label = record.label
        valueType = record.valueType
        unit = record.unit
        scaleMin = record.scaleMin
        scaleMax = record.scaleMax
        createdAt = record.createdAt
        updatedAt = record.updatedAt
        archivedAt = record.archivedAt
    }

    var domain: AtlasCustomMetricRecord {
        AtlasCustomMetricRecord.make(
            id: id,
            protocolId: protocolId,
            metricKey: metricKey,
            label: label,
            valueType: valueType,
            unit: unit,
            scaleMin: scaleMin,
            scaleMax: scaleMax,
            createdAt: createdAt,
            updatedAt: updatedAt,
            archivedAt: archivedAt
        )
    }
}

struct AtlasHealthConnectionDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "health_connections"
    var providerKey: AtlasHealthProviderKey
    var enabled: Bool
    var connected: Bool
    var lastSyncAt: String?
    var lastError: String?
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case providerKey = "provider_key"
        case enabled
        case connected
        case lastSyncAt = "last_sync_at"
        case lastError = "last_error"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(record: AtlasHealthConnectionRecord) {
        providerKey = record.providerKey
        enabled = record.enabled
        connected = record.connected
        lastSyncAt = record.lastSyncAt
        lastError = record.lastError
        createdAt = record.createdAt
        updatedAt = record.updatedAt
    }

    var domain: AtlasHealthConnectionRecord {
        AtlasHealthConnectionRecord.make(
            providerKey: providerKey,
            enabled: enabled,
            connected: connected,
            lastSyncAt: lastSyncAt,
            lastError: lastError,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct AtlasProtocolDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "protocols"
    var id: String
    var compoundId: String?
    var linkedVialId: String?
    var name: String
    var kind: AtlasProtocolKind
    var status: AtlasProtocolStatus
    var timezone: String
    var startDate: String
    var defaultTimeOfDay: String?
    var doseAmount: Double?
    var doseUnit: String?
    var siteTrackingEnabled: Bool
    var siteRotationEnabled: Bool
    var notes: String?
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case compoundId = "compound_id"
        case linkedVialId = "linked_vial_id"
        case name
        case kind
        case status
        case timezone
        case startDate = "start_date"
        case defaultTimeOfDay = "default_time_of_day"
        case doseAmount = "dose_amount"
        case doseUnit = "dose_unit"
        case siteTrackingEnabled = "site_tracking_enabled"
        case siteRotationEnabled = "site_rotation_enabled"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(record: AtlasProtocolRecord) {
        id = record.id
        compoundId = record.compoundId
        linkedVialId = record.linkedVialId
        name = record.name
        kind = record.kind
        status = record.status
        timezone = record.timezone
        startDate = record.startDate
        defaultTimeOfDay = record.defaultTimeOfDay
        doseAmount = record.doseAmount
        doseUnit = record.doseUnit
        siteTrackingEnabled = record.siteTrackingEnabled
        siteRotationEnabled = record.siteRotationEnabled
        notes = record.notes
        createdAt = record.createdAt
        updatedAt = record.updatedAt
    }

    var domain: AtlasProtocolRecord {
        AtlasProtocolRecord.make(
            id: id,
            compoundId: compoundId,
            linkedVialId: linkedVialId,
            name: name,
            kind: kind,
            status: status,
            timezone: timezone,
            startDate: startDate,
            defaultTimeOfDay: defaultTimeOfDay,
            doseAmount: doseAmount,
            doseUnit: doseUnit,
            siteTrackingEnabled: siteTrackingEnabled,
            siteRotationEnabled: siteRotationEnabled,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct AtlasProtocolRuleDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "protocol_rules"
    var id: String
    var protocolId: String
    var ruleType: AtlasProtocolRuleType
    var intervalCount: Int
    var weekday: Int?
    var timeOfDay: String?
    var anchorDate: String?
    var isActive: Bool
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case ruleType = "rule_type"
        case intervalCount = "interval_count"
        case weekday
        case timeOfDay = "time_of_day"
        case anchorDate = "anchor_date"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(record: AtlasProtocolRuleRecord) {
        id = record.id
        protocolId = record.protocolId
        ruleType = record.ruleType
        intervalCount = record.intervalCount
        weekday = record.weekday
        timeOfDay = record.timeOfDay
        anchorDate = record.anchorDate
        isActive = record.isActive
        createdAt = record.createdAt
        updatedAt = record.updatedAt
    }

    var domain: AtlasProtocolRuleRecord {
        AtlasProtocolRuleRecord.make(
            id: id,
            protocolId: protocolId,
            ruleType: ruleType,
            intervalCount: intervalCount,
            weekday: weekday,
            timeOfDay: timeOfDay,
            anchorDate: anchorDate,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct AtlasProtocolRevisionDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "protocol_revisions"
    var id: String
    var protocolId: String
    var revisionNumber: Int
    var previousRevisionId: String?
    var effectiveFrom: String
    var effectiveTo: String?
    var lifecycleState: AtlasProtocolRevisionLifecycle
    var timezone: String
    var timezoneStrategy: AtlasProtocolTimezoneStrategy
    var defaultTimeOfDay: String?
    var doseAmount: Double?
    var doseUnit: String?
    var linkedVialId: String?
    var missedDosePolicy: AtlasMissedDosePolicy
    var notes: String?
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case revisionNumber = "revision_number"
        case previousRevisionId = "previous_revision_id"
        case effectiveFrom = "effective_from"
        case effectiveTo = "effective_to"
        case lifecycleState = "lifecycle_state"
        case timezone
        case timezoneStrategy = "timezone_strategy"
        case defaultTimeOfDay = "default_time_of_day"
        case doseAmount = "dose_amount"
        case doseUnit = "dose_unit"
        case linkedVialId = "linked_vial_id"
        case missedDosePolicy = "missed_dose_policy"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(record: AtlasProtocolRevisionRecord) {
        id = record.id
        protocolId = record.protocolId
        revisionNumber = record.revisionNumber
        previousRevisionId = record.previousRevisionId
        effectiveFrom = record.effectiveFrom
        effectiveTo = record.effectiveTo
        lifecycleState = record.lifecycleState
        timezone = record.timezone
        timezoneStrategy = record.timezoneStrategy
        defaultTimeOfDay = record.defaultTimeOfDay
        doseAmount = record.doseAmount
        doseUnit = record.doseUnit
        linkedVialId = record.linkedVialId
        missedDosePolicy = record.missedDosePolicy
        notes = record.notes
        createdAt = record.createdAt
        updatedAt = record.updatedAt
    }

    var domain: AtlasProtocolRevisionRecord {
        AtlasProtocolRevisionRecord(
            id: id,
            protocolId: protocolId,
            revisionNumber: revisionNumber,
            previousRevisionId: previousRevisionId,
            effectiveFrom: effectiveFrom,
            effectiveTo: effectiveTo,
            lifecycleState: lifecycleState,
            timezone: timezone,
            timezoneStrategy: timezoneStrategy,
            defaultTimeOfDay: defaultTimeOfDay,
            doseAmount: doseAmount,
            doseUnit: doseUnit,
            linkedVialId: linkedVialId,
            missedDosePolicy: missedDosePolicy,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct AtlasProtocolRevisionRuleDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "protocol_revision_rules"
    var id: String
    var revisionId: String
    var phaseType: AtlasProtocolRevisionPhaseType
    var phaseOrder: Int
    var ruleType: AtlasProtocolRuleType
    var intervalCount: Int
    var weekday: Int?
    var timeOfDay: String?
    var anchorDate: String?
    var phaseStartDayOffset: Int
    var phaseLengthDays: Int?
    var doseAmountOverride: Double?
    var doseUnitOverride: String?
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case revisionId = "revision_id"
        case phaseType = "phase_type"
        case phaseOrder = "phase_order"
        case ruleType = "rule_type"
        case intervalCount = "interval_count"
        case weekday
        case timeOfDay = "time_of_day"
        case anchorDate = "anchor_date"
        case phaseStartDayOffset = "phase_start_day_offset"
        case phaseLengthDays = "phase_length_days"
        case doseAmountOverride = "dose_amount_override"
        case doseUnitOverride = "dose_unit_override"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(record: AtlasProtocolRevisionRuleRecord) {
        id = record.id
        revisionId = record.revisionId
        phaseType = record.phaseType
        phaseOrder = record.phaseOrder
        ruleType = record.ruleType
        intervalCount = record.intervalCount
        weekday = record.weekday
        timeOfDay = record.timeOfDay
        anchorDate = record.anchorDate
        phaseStartDayOffset = record.phaseStartDayOffset
        phaseLengthDays = record.phaseLengthDays
        doseAmountOverride = record.doseAmountOverride
        doseUnitOverride = record.doseUnitOverride
        createdAt = record.createdAt
        updatedAt = record.updatedAt
    }

    var domain: AtlasProtocolRevisionRuleRecord {
        AtlasProtocolRevisionRuleRecord(
            id: id,
            revisionId: revisionId,
            phaseType: phaseType,
            phaseOrder: phaseOrder,
            ruleType: ruleType,
            intervalCount: intervalCount,
            weekday: weekday,
            timeOfDay: timeOfDay,
            anchorDate: anchorDate,
            phaseStartDayOffset: phaseStartDayOffset,
            phaseLengthDays: phaseLengthDays,
            doseAmountOverride: doseAmountOverride,
            doseUnitOverride: doseUnitOverride,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct AtlasProtocolChangeAuditDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "protocol_change_audit_events"
    var id: String
    var protocolId: String
    var revisionId: String
    var previousRevisionId: String?
    var changeType: AtlasProtocolChangeAuditType
    var effectiveFrom: String
    var summary: String
    var payloadJson: String
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case revisionId = "revision_id"
        case previousRevisionId = "previous_revision_id"
        case changeType = "change_type"
        case effectiveFrom = "effective_from"
        case summary
        case payloadJson = "payload_json"
        case createdAt = "created_at"
    }

    init(record: AtlasProtocolChangeAuditRecord) {
        id = record.id
        protocolId = record.protocolId
        revisionId = record.revisionId
        previousRevisionId = record.previousRevisionId
        changeType = record.changeType
        effectiveFrom = record.effectiveFrom
        summary = record.summary
        payloadJson = record.payloadJson
        createdAt = record.createdAt
    }

    var domain: AtlasProtocolChangeAuditRecord {
        AtlasProtocolChangeAuditRecord.make(
            id: id,
            protocolId: protocolId,
            revisionId: revisionId,
            previousRevisionId: previousRevisionId,
            changeType: changeType,
            effectiveFrom: effectiveFrom,
            summary: summary,
            payloadJson: payloadJson,
            createdAt: createdAt
        )
    }
}

struct AtlasVialDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "vials"
    var id: String
    var protocolId: String?
    var compoundId: String?
    var calculatorProfileId: String?
    var label: String
    var startingQuantity: Double
    var concentrationValue: Double?
    var concentrationUnit: String?
    var volumeMl: Double?
    var remainingQuantity: Double
    var lowStockThreshold: Double?
    var quantityUnit: String
    var openedAt: String?
    var expiresAt: String?
    var createdAt: String
    var updatedAt: String
    var archivedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case compoundId = "compound_id"
        case calculatorProfileId = "calculator_profile_id"
        case label
        case startingQuantity = "starting_quantity"
        case concentrationValue = "concentration_value"
        case concentrationUnit = "concentration_unit"
        case volumeMl = "volume_ml"
        case remainingQuantity = "remaining_quantity"
        case lowStockThreshold = "low_stock_threshold"
        case quantityUnit = "quantity_unit"
        case openedAt = "opened_at"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
    }

    init(record: AtlasVialRecord) {
        id = record.id
        protocolId = record.protocolId
        compoundId = record.compoundId
        calculatorProfileId = record.calculatorProfileId
        label = record.label
        startingQuantity = record.startingQuantity
        concentrationValue = record.concentrationValue
        concentrationUnit = record.concentrationUnit
        volumeMl = record.volumeMl
        remainingQuantity = record.remainingQuantity
        lowStockThreshold = record.lowStockThreshold
        quantityUnit = record.quantityUnit
        openedAt = record.openedAt
        expiresAt = record.expiresAt
        createdAt = record.createdAt
        updatedAt = record.updatedAt
        archivedAt = record.archivedAt
    }

    var domain: AtlasVialRecord {
        AtlasVialRecord.make(
            id: id,
            protocolId: protocolId,
            compoundId: compoundId,
            calculatorProfileId: calculatorProfileId,
            label: label,
            startingQuantity: startingQuantity,
            concentrationValue: concentrationValue,
            concentrationUnit: concentrationUnit,
            volumeMl: volumeMl,
            remainingQuantity: remainingQuantity,
            lowStockThreshold: lowStockThreshold,
            quantityUnit: quantityUnit,
            openedAt: openedAt,
            expiresAt: expiresAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            archivedAt: archivedAt
        )
    }
}

struct AtlasSiteDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "sites"
    var id: String
    var name: String
    var bodyArea: String?
    var notes: String?
    var createdAt: String
    var updatedAt: String
    var archivedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case bodyArea = "body_area"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
    }

    init(record: AtlasSiteRecord) {
        id = record.id
        name = record.name
        bodyArea = record.bodyArea
        notes = record.notes
        createdAt = record.createdAt
        updatedAt = record.updatedAt
        archivedAt = record.archivedAt
    }

    var domain: AtlasSiteRecord {
        AtlasSiteRecord.make(
            id: id,
            name: name,
            bodyArea: bodyArea,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            archivedAt: archivedAt
        )
    }
}

struct AtlasConsumableDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "consumables"
    var id: String
    var protocolId: String?
    var name: String
    var category: String?
    var quantityOnHand: Double
    var unit: String
    var reorderThreshold: Double?
    var reorderLeadTimeDays: Int?
    var quantityPerUse: Double?
    var lotNumber: String?
    var sizeDescription: String?
    var notes: String?
    var vendorLabel: String?
    var purchaseNotes: String?
    var createdAt: String
    var updatedAt: String
    var archivedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case name
        case category
        case quantityOnHand = "quantity_on_hand"
        case unit
        case reorderThreshold = "reorder_threshold"
        case reorderLeadTimeDays = "reorder_lead_time_days"
        case quantityPerUse = "quantity_per_use"
        case lotNumber = "lot_number"
        case sizeDescription = "size_description"
        case notes
        case vendorLabel = "vendor_label"
        case purchaseNotes = "purchase_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
    }

    init(record: AtlasConsumableRecord) {
        id = record.id
        protocolId = record.protocolId
        name = record.name
        category = record.category
        quantityOnHand = record.quantityOnHand
        unit = record.unit
        reorderThreshold = record.reorderThreshold
        reorderLeadTimeDays = record.reorderLeadTimeDays
        quantityPerUse = record.quantityPerUse
        lotNumber = record.lotNumber
        sizeDescription = record.sizeDescription
        notes = record.notes
        vendorLabel = record.vendorLabel
        purchaseNotes = record.purchaseNotes
        createdAt = record.createdAt
        updatedAt = record.updatedAt
        archivedAt = record.archivedAt
    }

    var domain: AtlasConsumableRecord {
        AtlasConsumableRecord.make(
            id: id,
            protocolId: protocolId,
            name: name,
            category: category,
            quantityOnHand: quantityOnHand,
            unit: unit,
            reorderThreshold: reorderThreshold,
            reorderLeadTimeDays: reorderLeadTimeDays,
            quantityPerUse: quantityPerUse,
            lotNumber: lotNumber,
            sizeDescription: sizeDescription,
            notes: notes,
            vendorLabel: vendorLabel,
            purchaseNotes: purchaseNotes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            archivedAt: archivedAt
        )
    }
}

struct AtlasConsumableAdjustmentDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "consumable_adjustments"
    var id: String
    var consumableId: String
    var protocolId: String?
    var occurrenceId: String?
    var kind: AtlasConsumableAdjustmentKind
    var deltaQuantity: Double
    var resultingQuantity: Double
    var quantityUnit: String
    var note: String?
    var recordedAt: String
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case consumableId = "consumable_id"
        case protocolId = "protocol_id"
        case occurrenceId = "occurrence_id"
        case kind
        case deltaQuantity = "delta_quantity"
        case resultingQuantity = "resulting_quantity"
        case quantityUnit = "quantity_unit"
        case note
        case recordedAt = "recorded_at"
        case createdAt = "created_at"
    }

    init(record: AtlasConsumableAdjustmentRecord) {
        id = record.id
        consumableId = record.consumableId
        protocolId = record.protocolId
        occurrenceId = record.occurrenceId
        kind = record.kind
        deltaQuantity = record.deltaQuantity
        resultingQuantity = record.resultingQuantity
        quantityUnit = record.quantityUnit
        note = record.note
        recordedAt = record.recordedAt
        createdAt = record.createdAt
    }

    var domain: AtlasConsumableAdjustmentRecord {
        AtlasConsumableAdjustmentRecord.make(
            id: id,
            consumableId: consumableId,
            protocolId: protocolId,
            occurrenceId: occurrenceId,
            kind: kind,
            deltaQuantity: deltaQuantity,
            resultingQuantity: resultingQuantity,
            quantityUnit: quantityUnit,
            note: note,
            recordedAt: recordedAt,
            createdAt: createdAt
        )
    }
}

struct AtlasLogEventDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "log_events"
    var id: String
    var protocolId: String
    var vialId: String?
    var siteId: String?
    var occurrenceId: String?
    var eventType: AtlasLogEventType
    var effectiveAt: String
    var loggedAt: String
    var quantity: Double?
    var quantityUnit: String?
    var notes: String?
    var source: AtlasLogEventSource

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case vialId = "vial_id"
        case siteId = "site_id"
        case occurrenceId = "occurrence_id"
        case eventType = "event_type"
        case effectiveAt = "effective_at"
        case loggedAt = "logged_at"
        case quantity
        case quantityUnit = "quantity_unit"
        case notes
        case source
    }

    init(record: AtlasLogEventRecord) {
        id = record.id
        protocolId = record.protocolId
        vialId = record.vialId
        siteId = record.siteId
        occurrenceId = record.occurrenceId
        eventType = record.eventType
        effectiveAt = record.effectiveAt
        loggedAt = record.loggedAt
        quantity = record.quantity
        quantityUnit = record.quantityUnit
        notes = record.notes
        source = record.source
    }

    var domain: AtlasLogEventRecord {
        AtlasLogEventRecord.make(
            id: id,
            protocolId: protocolId,
            vialId: vialId,
            siteId: siteId,
            occurrenceId: occurrenceId,
            eventType: eventType,
            effectiveAt: effectiveAt,
            loggedAt: loggedAt,
            quantity: quantity,
            quantityUnit: quantityUnit,
            notes: notes,
            source: source
        )
    }
}

struct AtlasReminderPreferenceDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "reminder_preferences"
    var id: String
    var remindersEnabled: Bool
    var privacyMode: AtlasReminderPrivacyMode
    var leadTimeMinutes: Int
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case remindersEnabled = "reminders_enabled"
        case privacyMode = "privacy_mode"
        case leadTimeMinutes = "lead_time_minutes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(record: AtlasReminderPreferenceRecord) {
        id = record.id
        remindersEnabled = record.remindersEnabled
        privacyMode = record.privacyMode
        leadTimeMinutes = record.leadTimeMinutes
        createdAt = record.createdAt
        updatedAt = record.updatedAt
    }

    var domain: AtlasReminderPreferenceRecord {
        AtlasReminderPreferenceRecord.make(
            id: id,
            remindersEnabled: remindersEnabled,
            privacyMode: privacyMode,
            leadTimeMinutes: leadTimeMinutes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct AtlasReminderDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "reminders"
    var id: String
    var protocolId: String
    var occurrenceId: String
    var offsetMinutes: Int
    var channel: AtlasReminderChannel
    var isEnabled: Bool
    var discreetCopyEnabled: Bool
    var privacyMode: AtlasReminderPrivacyMode
    var scheduledFor: String
    var notificationId: String?
    var title: String
    var body: String
    var status: AtlasReminderStatus
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case occurrenceId = "occurrence_id"
        case offsetMinutes = "offset_minutes"
        case channel
        case isEnabled = "is_enabled"
        case discreetCopyEnabled = "discreet_copy_enabled"
        case privacyMode = "privacy_mode"
        case scheduledFor = "scheduled_for"
        case notificationId = "notification_id"
        case title
        case body
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(record: AtlasReminderRecord) {
        id = record.id
        protocolId = record.protocolId
        occurrenceId = record.occurrenceId
        offsetMinutes = record.offsetMinutes
        channel = record.channel
        isEnabled = record.isEnabled
        discreetCopyEnabled = record.discreetCopyEnabled
        privacyMode = record.privacyMode
        scheduledFor = record.scheduledFor
        notificationId = record.notificationId
        title = record.title
        body = record.body
        status = record.status
        createdAt = record.createdAt
        updatedAt = record.updatedAt
    }

    var domain: AtlasReminderRecord {
        AtlasReminderRecord.make(
            id: id,
            protocolId: protocolId,
            occurrenceId: occurrenceId,
            offsetMinutes: offsetMinutes,
            channel: channel,
            isEnabled: isEnabled,
            discreetCopyEnabled: discreetCopyEnabled,
            privacyMode: privacyMode,
            scheduledFor: scheduledFor,
            notificationId: notificationId,
            title: title,
            body: body,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct AtlasPrivacyProfileDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "privacy_profile"
    var id: String
    var renderMode: AtlasPrivacyRenderMode?
    var aliasModeEnabled: Bool
    var biometricLockEnabled: Bool
    var biometricGateMode: AtlasBiometricGateMode
    var shareAliasByDefault: Bool
    var exportAliasByDefault: Bool
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case renderMode = "render_mode"
        case aliasModeEnabled = "alias_mode_enabled"
        case biometricLockEnabled = "biometric_lock_enabled"
        case biometricGateMode = "biometric_gate_mode"
        case shareAliasByDefault = "share_alias_by_default"
        case exportAliasByDefault = "export_alias_by_default"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(record: AtlasPrivacyProfileRecord) {
        id = record.id
        renderMode = record.renderMode
        aliasModeEnabled = record.aliasModeEnabled
        biometricLockEnabled = record.biometricLockEnabled
        biometricGateMode = record.biometricGateMode
        shareAliasByDefault = record.shareAliasByDefault
        exportAliasByDefault = record.exportAliasByDefault
        createdAt = record.createdAt
        updatedAt = record.updatedAt
    }

    var domain: AtlasPrivacyProfileRecord {
        AtlasPrivacyProfileRecord.make(
            id: id,
            renderMode: renderMode,
            aliasModeEnabled: aliasModeEnabled,
            biometricLockEnabled: biometricLockEnabled,
            biometricGateMode: biometricGateMode,
            shareAliasByDefault: shareAliasByDefault,
            exportAliasByDefault: exportAliasByDefault,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct AtlasProtocolAliasDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "protocol_aliases"
    var id: String
    var protocolId: String
    var aliasLabel: String
    var aliasCompoundLabel: String?
    var createdAt: String
    var updatedAt: String
    var archivedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case aliasLabel = "alias_label"
        case aliasCompoundLabel = "alias_compound_label"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
    }

    init(record: AtlasProtocolAliasRecord) {
        id = record.id
        protocolId = record.protocolId
        aliasLabel = record.aliasLabel
        aliasCompoundLabel = record.aliasCompoundLabel
        createdAt = record.createdAt
        updatedAt = record.updatedAt
        archivedAt = record.archivedAt
    }

    var domain: AtlasProtocolAliasRecord {
        AtlasProtocolAliasRecord.make(
            id: id,
            protocolId: protocolId,
            aliasLabel: aliasLabel,
            aliasCompoundLabel: aliasCompoundLabel,
            createdAt: createdAt,
            updatedAt: updatedAt,
            archivedAt: archivedAt
        )
    }
}

struct AtlasSensitiveActionAuditDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "sensitive_action_audit_events"
    var id: String
    var eventType: AtlasSensitiveActionAuditEventType
    var surface: String
    var protocolId: String?
    var scopeKind: String?
    var renderMode: AtlasPrivacyRenderMode?
    var manifestVersion: Int?
    var payloadJson: String
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case eventType = "event_type"
        case surface
        case protocolId = "protocol_id"
        case scopeKind = "scope_kind"
        case renderMode = "render_mode"
        case manifestVersion = "manifest_version"
        case payloadJson = "payload_json"
        case createdAt = "created_at"
    }

    init(record: AtlasSensitiveActionAuditRecord) {
        id = record.id
        eventType = record.eventType
        surface = record.surface
        protocolId = record.protocolId
        scopeKind = record.scopeKind
        renderMode = record.renderMode
        manifestVersion = record.manifestVersion
        payloadJson = record.payloadJson
        createdAt = record.createdAt
    }

    var domain: AtlasSensitiveActionAuditRecord {
        AtlasSensitiveActionAuditRecord.make(
            id: id,
            eventType: eventType,
            surface: surface,
            protocolId: protocolId,
            scopeKind: scopeKind,
            renderMode: renderMode,
            manifestVersion: manifestVersion,
            payloadJson: payloadJson,
            createdAt: createdAt
        )
    }
}

struct AtlasMetricValueLogDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "metric_value_logs"
    var id: String
    var metricId: String
    var protocolId: String?
    var loggedAt: String
    var numberValue: Double?
    var textValue: String?
    var booleanValue: Bool?
    var source: AtlasHealthDataSource
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case metricId = "metric_id"
        case protocolId = "protocol_id"
        case loggedAt = "logged_at"
        case numberValue = "number_value"
        case textValue = "text_value"
        case booleanValue = "boolean_value"
        case source
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(record: AtlasMetricValueLogRecord) {
        id = record.id
        metricId = record.metricId
        protocolId = record.protocolId
        loggedAt = record.loggedAt
        numberValue = record.numberValue
        textValue = record.textValue
        booleanValue = record.booleanValue
        source = record.source
        createdAt = record.createdAt
        updatedAt = record.updatedAt
    }

    var domain: AtlasMetricValueLogRecord {
        AtlasMetricValueLogRecord.make(
            id: id,
            metricId: metricId,
            protocolId: protocolId,
            loggedAt: loggedAt,
            numberValue: numberValue,
            textValue: textValue,
            booleanValue: booleanValue,
            source: source,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private func atlasJSONString<T: Encodable>(for value: T, fallback: String) -> String {
    let encoder = JSONEncoder()
    guard let data = try? encoder.encode(value),
          let string = String(data: data, encoding: .utf8) else {
        return fallback
    }
    return string
}

private func atlasDecodeJSON<T: Decodable>(_ type: T.Type, from string: String, fallback: T) -> T {
    guard let data = string.data(using: .utf8),
          let decoded = try? JSONDecoder().decode(type, from: data) else {
        return fallback
    }
    return decoded
}

struct AtlasContextLogDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "context_logs"
    var id: String
    var protocolId: String?
    var loggedAt: String
    var mealTiming: AtlasContextMealTiming?
    var fedState: AtlasContextFedState?
    var appetite: AtlasContextAppetiteState?
    var hydration: AtlasContextHydrationState?
    var giContextJson: String
    var note: String?
    var tagsJson: String
    var source: AtlasHealthDataSource
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case loggedAt = "logged_at"
        case mealTiming = "meal_timing"
        case fedState = "fed_state"
        case appetite
        case hydration
        case giContextJson = "gi_context_json"
        case note
        case tagsJson = "tags_json"
        case source
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(record: AtlasContextLogRecord) {
        id = record.id
        protocolId = record.protocolId
        loggedAt = record.loggedAt
        mealTiming = record.mealTiming
        fedState = record.fedState
        appetite = record.appetite
        hydration = record.hydration
        giContextJson = atlasJSONString(for: record.giTags, fallback: "[]")
        note = record.note
        tagsJson = atlasJSONString(for: record.tags, fallback: "[]")
        source = record.source
        createdAt = record.createdAt
        updatedAt = record.updatedAt
    }

    var domain: AtlasContextLogRecord {
        AtlasContextLogRecord.make(
            id: id,
            protocolId: protocolId,
            loggedAt: loggedAt,
            mealTiming: mealTiming,
            fedState: fedState,
            appetite: appetite,
            hydration: hydration,
            giTags: atlasDecodeJSON([AtlasContextGITag].self, from: giContextJson, fallback: []),
            note: note,
            tags: atlasDecodeJSON([String].self, from: tagsJson, fallback: []),
            source: source,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct AtlasSymptomLogDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "symptom_logs"
    var id: String
    var loggedAt: String
    var symptomKey: String
    var severity: Int
    var notes: String?
    var source: AtlasHealthDataSource
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case loggedAt = "logged_at"
        case symptomKey = "symptom_key"
        case severity
        case notes
        case source
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(record: AtlasSymptomLogRecord) {
        id = record.id
        loggedAt = record.loggedAt
        symptomKey = record.symptomKey
        severity = record.severity
        notes = record.notes
        source = record.source
        createdAt = record.createdAt
        updatedAt = record.updatedAt
    }

    var domain: AtlasSymptomLogRecord {
        AtlasSymptomLogRecord.make(
            id: id,
            loggedAt: loggedAt,
            symptomKey: symptomKey,
            severity: severity,
            notes: notes,
            source: source,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct AtlasWeightLogDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "weight_logs"
    var id: String
    var loggedAt: String
    var value: Double
    var unit: AtlasWeightUnit
    var source: AtlasHealthDataSource
    var notes: String?
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case loggedAt = "logged_at"
        case value
        case unit
        case source
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(record: AtlasWeightLogRecord) {
        id = record.id
        loggedAt = record.loggedAt
        value = record.value
        unit = record.unit
        source = record.source
        notes = record.notes
        createdAt = record.createdAt
        updatedAt = record.updatedAt
    }

    var domain: AtlasWeightLogRecord {
        AtlasWeightLogRecord.make(
            id: id,
            loggedAt: loggedAt,
            value: value,
            unit: unit,
            source: source,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct AtlasOccurrenceProjectionDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "occurrence_projections"
    var id: String
    var protocolId: String
    var reminderId: String?
    var scheduledAt: String
    var state: AtlasOccurrenceState
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case reminderId = "reminder_id"
        case scheduledAt = "scheduled_at"
        case state
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(record: AtlasOccurrenceProjectionRecord) {
        id = record.id
        protocolId = record.protocolId
        reminderId = record.reminderId
        scheduledAt = record.scheduledAt
        state = record.state
        createdAt = record.createdAt
        updatedAt = record.updatedAt
    }

    var domain: AtlasOccurrenceProjectionRecord {
        AtlasOccurrenceProjectionRecord.make(
            id: id,
            protocolId: protocolId,
            reminderId: reminderId,
            scheduledAt: scheduledAt,
            state: state,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct AtlasNextDueProjectionDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "next_due_snapshot"
    var id: String
    var protocolId: String
    var displayTitle: String
    var dueLabel: String
    var scheduledAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case displayTitle = "display_title"
        case dueLabel = "due_label"
        case scheduledAt = "scheduled_at"
    }

    init(snapshot: AtlasSharedNextDueSnapshot) {
        id = snapshot.occurrenceID
        protocolId = snapshot.protocolID
        displayTitle = snapshot.displayTitle
        dueLabel = snapshot.dueLabel
        scheduledAt = snapshot.scheduledAt
    }

    var domain: AtlasSharedNextDueSnapshot {
        AtlasSharedNextDueSnapshot(
            occurrenceID: id,
            protocolID: protocolId,
            displayTitle: displayTitle,
            dueLabel: dueLabel,
            scheduledAt: scheduledAt,
            state: .upcoming,
            statusSummary: dueLabel
        )
    }
}

struct AtlasTimelineProjectionDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "widget_timeline_summary"
    var id: String
    var protocolId: String
    var displayTitle: String
    var summary: String
    var recordedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case displayTitle = "display_title"
        case summary
        case recordedAt = "recorded_at"
    }

    init(summary: AtlasSharedTimelineSummary) {
        id = summary.id
        protocolId = summary.protocolID
        displayTitle = summary.displayTitle
        self.summary = summary.summary
        recordedAt = summary.recordedAt
    }

    var domain: AtlasSharedTimelineSummary {
        AtlasSharedTimelineSummary(
            id: id,
            protocolID: protocolId,
            displayTitle: displayTitle,
            summary: summary,
            recordedAt: recordedAt
        )
    }
}

struct AtlasLabelProjectionDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "label_projection"
    var id: String
    var canonicalTitle: String
    var aliasTitle: String?
    var discreetTitle: String

    enum CodingKeys: String, CodingKey {
        case id
        case canonicalTitle = "canonical_title"
        case aliasTitle = "alias_title"
        case discreetTitle = "discreet_title"
    }

    init(projection: AtlasSharedLabelProjection) {
        id = projection.id
        canonicalTitle = projection.canonicalTitle
        aliasTitle = projection.aliasTitle
        discreetTitle = projection.discreetTitle
    }

    var domain: AtlasSharedLabelProjection {
        AtlasSharedLabelProjection(
            id: id,
            canonicalTitle: canonicalTitle,
            aliasTitle: aliasTitle,
            discreetTitle: discreetTitle
        )
    }
}

struct AtlasQuickActionProjectionDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "quick_action_projection"
    var id: String
    var protocolId: String
    var occurrenceId: String
    var title: String

    enum CodingKeys: String, CodingKey {
        case id
        case protocolId = "protocol_id"
        case occurrenceId = "occurrence_id"
        case title
    }

    init(projection: AtlasSharedQuickAction) {
        id = projection.id
        protocolId = projection.protocolID
        occurrenceId = projection.occurrenceID
        title = projection.title
    }

    var domain: AtlasSharedQuickAction {
        AtlasSharedQuickAction(
            id: id,
            protocolID: protocolId,
            occurrenceID: occurrenceId,
            title: title,
            dueLabel: "",
            state: .upcoming
        )
    }
}

struct AtlasFeatureFlagProjectionDBRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "feature_flag_projection"
    var flag: String
    var isEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case flag
        case isEnabled = "is_enabled"
    }
}

func canonicalSnapshot(from db: Database) throws -> AtlasExportSnapshot {
    AtlasExportSnapshot(
        calculatorProfiles: try AtlasCalculatorProfileDBRecord.fetchAll(db).map(\.domain),
        compounds: try AtlasCompoundDBRecord.fetchAll(db).map(\.domain),
        consumableAdjustments: try AtlasConsumableAdjustmentDBRecord.fetchAll(db).map(\.domain),
        consumables: try AtlasConsumableDBRecord.fetchAll(db).map(\.domain),
        contextLogs: try AtlasContextLogDBRecord.fetchAll(db).map(\.domain),
        customMetrics: try AtlasCustomMetricDBRecord.fetchAll(db).map(\.domain),
        healthConnections: try AtlasHealthConnectionDBRecord.fetchAll(db).map(\.domain),
        logEvents: try AtlasLogEventDBRecord.fetchAll(db).map(\.domain),
        metricValueLogs: try AtlasMetricValueLogDBRecord.fetchAll(db).map(\.domain),
        privacyProfile: try AtlasPrivacyProfileDBRecord.fetchOne(db)?.domain ?? .default(),
        protocolChangeAudits: try AtlasProtocolChangeAuditDBRecord.fetchAll(db).map(\.domain),
        protocolAliases: try AtlasProtocolAliasDBRecord.fetchAll(db).map(\.domain),
        protocolRevisionRules: try AtlasProtocolRevisionRuleDBRecord.fetchAll(db).map(\.domain),
        protocolRevisions: try AtlasProtocolRevisionDBRecord.fetchAll(db).map(\.domain),
        protocols: try AtlasProtocolDBRecord.fetchAll(db).map(\.domain),
        protocolRules: try AtlasProtocolRuleDBRecord.fetchAll(db).map(\.domain),
        reminderPreference: try AtlasReminderPreferenceDBRecord.fetchOne(db)?.domain ?? .default(),
        reminders: try AtlasReminderDBRecord.fetchAll(db).map(\.domain),
        sensitiveActionAudits: try AtlasSensitiveActionAuditDBRecord.fetchAll(db).map(\.domain),
        sites: try AtlasSiteDBRecord.fetchAll(db).map(\.domain),
        symptomLogs: try AtlasSymptomLogDBRecord.fetchAll(db).map(\.domain),
        vials: try AtlasVialDBRecord.fetchAll(db).map(\.domain),
        weightLogs: try AtlasWeightLogDBRecord.fetchAll(db).map(\.domain)
    )
}

func clearCanonicalTables(in db: Database) throws {
    let tables = [
        "occurrence_projections",
        "sensitive_action_audit_events",
        "protocol_aliases",
        "reminders",
        "reminder_preferences",
        "log_events",
        "consumable_adjustments",
        "consumables",
        "context_logs",
        "vials",
        "sites",
        "protocol_change_audit_events",
        "protocol_revision_rules",
        "protocol_revisions",
        "protocol_rules",
        "metric_value_logs",
        "custom_metrics",
        "weight_logs",
        "symptom_logs",
        "review_sessions",
        "health_connections",
        "calculator_profiles",
        "protocols",
        "compounds"
    ]

    for table in tables {
        try db.execute(sql: "DELETE FROM \(table)")
    }
}

func writeSnapshot(_ snapshot: AtlasExportSnapshot, to db: Database) throws {
    for record in snapshot.calculatorProfiles { try AtlasCalculatorProfileDBRecord(record: record).insert(db) }
    for record in snapshot.compounds { try AtlasCompoundDBRecord(record: record).insert(db) }
    for record in snapshot.protocols { try AtlasProtocolDBRecord(record: record).insert(db) }
    for record in snapshot.protocolRules { try AtlasProtocolRuleDBRecord(record: record).insert(db) }
    for record in snapshot.protocolRevisions { try AtlasProtocolRevisionDBRecord(record: record).insert(db) }
    for record in snapshot.protocolRevisionRules { try AtlasProtocolRevisionRuleDBRecord(record: record).insert(db) }
    for record in snapshot.protocolChangeAudits { try AtlasProtocolChangeAuditDBRecord(record: record).insert(db) }
    for record in snapshot.consumables { try AtlasConsumableDBRecord(record: record).insert(db) }
    for record in snapshot.consumableAdjustments { try AtlasConsumableAdjustmentDBRecord(record: record).insert(db) }
    for record in snapshot.contextLogs { try AtlasContextLogDBRecord(record: record).insert(db) }
    for record in snapshot.vials { try AtlasVialDBRecord(record: record).insert(db) }
    for record in snapshot.sites { try AtlasSiteDBRecord(record: record).insert(db) }
    for record in snapshot.logEvents { try AtlasLogEventDBRecord(record: record).insert(db) }
    try AtlasReminderPreferenceDBRecord(record: snapshot.reminderPreference).save(db)
    for record in snapshot.reminders { try AtlasReminderDBRecord(record: record).insert(db) }
    try AtlasPrivacyProfileDBRecord(record: snapshot.privacyProfile).save(db)
    for record in snapshot.protocolAliases { try AtlasProtocolAliasDBRecord(record: record).insert(db) }
    for record in snapshot.sensitiveActionAudits { try AtlasSensitiveActionAuditDBRecord(record: record).insert(db) }
    for record in snapshot.customMetrics { try AtlasCustomMetricDBRecord(record: record).insert(db) }
    for record in snapshot.metricValueLogs { try AtlasMetricValueLogDBRecord(record: record).insert(db) }
    for record in snapshot.healthConnections { try AtlasHealthConnectionDBRecord(record: record).save(db) }
    for record in snapshot.symptomLogs { try AtlasSymptomLogDBRecord(record: record).insert(db) }
    for record in snapshot.weightLogs { try AtlasWeightLogDBRecord(record: record).insert(db) }
}

func replaceOccurrenceProjections(
    _ projections: [AtlasOccurrenceProjectionRecord],
    in db: Database
) throws {
    try db.execute(sql: "DELETE FROM occurrence_projections")
    for projection in projections {
        try AtlasOccurrenceProjectionDBRecord(record: projection).insert(db)
    }
}

func countUserRows(in db: Database) throws -> Int {
    let protocolCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM protocols") ?? 0
    let logCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM log_events") ?? 0
    let vialCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM vials") ?? 0
    let consumableCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM consumables") ?? 0
    let consumableAdjustmentCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM consumable_adjustments") ?? 0
    let contextCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM context_logs") ?? 0
    return protocolCount + logCount + vialCount + consumableCount + consumableAdjustmentCount + contextCount
}

func existingIdentifiers(in db: Database, for dataset: AtlasImportDataset) throws -> Set<String> {
    switch dataset {
    case .calculatorProfiles:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM calculator_profiles"))
    case .compounds:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM compounds"))
    case .consumableAdjustments:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM consumable_adjustments"))
    case .consumables:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM consumables"))
    case .contextLogs:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM context_logs"))
    case .customMetrics:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM custom_metrics"))
    case .healthConnections:
        return Set(try String.fetchAll(db, sql: "SELECT provider_key FROM health_connections"))
    case .logEvents:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM log_events"))
    case .metricValueLogs:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM metric_value_logs"))
    case .privacyProfile:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM privacy_profile"))
    case .protocolChangeAudits:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM protocol_change_audit_events"))
    case .protocolAliases:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM protocol_aliases"))
    case .protocolRevisionRules:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM protocol_revision_rules"))
    case .protocolRevisions:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM protocol_revisions"))
    case .protocols:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM protocols"))
    case .protocolRules:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM protocol_rules"))
    case .reminderPreference:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM reminder_preferences"))
    case .reminders:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM reminders"))
    case .sensitiveActionAudits:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM sensitive_action_audit_events"))
    case .sites:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM sites"))
    case .symptomLogs:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM symptom_logs"))
    case .vials:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM vials"))
    case .weightLogs:
        return Set(try String.fetchAll(db, sql: "SELECT id FROM weight_logs"))
    }
}

func datasetIdentifiers(from snapshot: AtlasExportSnapshot, for dataset: AtlasImportDataset) -> [String] {
    switch dataset {
    case .calculatorProfiles:
        return snapshot.calculatorProfiles.map(\.id)
    case .compounds:
        return snapshot.compounds.map(\.id)
    case .consumableAdjustments:
        return snapshot.consumableAdjustments.map(\.id)
    case .consumables:
        return snapshot.consumables.map(\.id)
    case .contextLogs:
        return snapshot.contextLogs.map(\.id)
    case .customMetrics:
        return snapshot.customMetrics.map(\.id)
    case .healthConnections:
        return snapshot.healthConnections.map(\.providerKey.rawValue)
    case .logEvents:
        return snapshot.logEvents.map(\.id)
    case .metricValueLogs:
        return snapshot.metricValueLogs.map(\.id)
    case .privacyProfile:
        return [snapshot.privacyProfile.id]
    case .protocolChangeAudits:
        return snapshot.protocolChangeAudits.map(\.id)
    case .protocolAliases:
        return snapshot.protocolAliases.map(\.id)
    case .protocolRevisionRules:
        return snapshot.protocolRevisionRules.map(\.id)
    case .protocolRevisions:
        return snapshot.protocolRevisions.map(\.id)
    case .protocols:
        return snapshot.protocols.map(\.id)
    case .protocolRules:
        return snapshot.protocolRules.map(\.id)
    case .reminderPreference:
        return [snapshot.reminderPreference.id]
    case .reminders:
        return snapshot.reminders.map(\.id)
    case .sensitiveActionAudits:
        return snapshot.sensitiveActionAudits.map(\.id)
    case .sites:
        return snapshot.sites.map(\.id)
    case .symptomLogs:
        return snapshot.symptomLogs.map(\.id)
    case .vials:
        return snapshot.vials.map(\.id)
    case .weightLogs:
        return snapshot.weightLogs.map(\.id)
    }
}

func buildOccurrenceProjections(from snapshot: AtlasExportSnapshot) -> [AtlasOccurrenceProjectionRecord] {
    let reminderDriven = snapshot.reminders
        .filter { $0.status == .scheduled }
        .map {
            AtlasOccurrenceProjectionRecord.make(
                id: $0.occurrenceId,
                protocolId: $0.protocolId,
                reminderId: $0.id,
                scheduledAt: $0.scheduledFor,
                state: .upcoming,
                createdAt: $0.createdAt,
                updatedAt: $0.updatedAt
            )
        }
        .sorted { $0.scheduledAt < $1.scheduledAt }

    if reminderDriven.isEmpty == false {
        return reminderDriven
    }

    return snapshot.protocols.map { protocolRecord in
        let scheduledAt = protocolRecord.defaultTimeOfDay.map { "\(protocolRecord.startDate)T\($0):00.000Z" } ?? atlasDayStartTimestamp(protocolRecord.startDate)
        return AtlasOccurrenceProjectionRecord.make(
            id: "occ_\(protocolRecord.id)_bootstrap",
            protocolId: protocolRecord.id,
            reminderId: nil,
            scheduledAt: scheduledAt,
            state: .upcoming,
            createdAt: protocolRecord.createdAt,
            updatedAt: protocolRecord.updatedAt
        )
    }
    .sorted { $0.scheduledAt < $1.scheduledAt }
}

func buildProtocolSummaries(
    protocols: [AtlasProtocolRecord],
    aliases: [AtlasProtocolAliasRecord],
    rules: [AtlasProtocolRuleRecord]
) -> [ProtocolSummary] {
    let aliasLookup = Dictionary(uniqueKeysWithValues: aliases.map { ($0.protocolId, $0) })
    let firstRules = Dictionary(grouping: rules, by: \.protocolId)
        .compactMapValues { protocolRules in
            protocolRules.sorted { $0.createdAt < $1.createdAt }.first
        }

    return protocols
        .sorted { $0.createdAt < $1.createdAt }
        .map { record in
            ProtocolSummary(
                id: record.id,
                canonicalTitle: record.name,
                aliasTitle: aliasLookup[record.id]?.aliasLabel,
                kindLabel: kindLabel(record.kind),
                cadenceLabel: cadenceLabel(from: firstRules[record.id]),
                status: record.status
            )
        }
}
