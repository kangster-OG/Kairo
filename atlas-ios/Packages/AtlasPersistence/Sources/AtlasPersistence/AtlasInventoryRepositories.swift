import AtlasDomain
import GRDB
import Foundation

private let atlasInventoryCorrectionDefaultNote = "Manual inventory correction."
private let atlasConsumableAdjustmentDefaultNote = "Manual supply adjustment."

public struct GRDBInventoryRepository: InventoryRepository, Sendable {
    let stack: AtlasDatabaseStack

    init(stack: AtlasDatabaseStack) {
        self.stack = stack
    }

    public func fetchInventorySnapshot(referenceDate: Date) async throws -> AtlasInventorySnapshot {
        try await stack.canonical.read { db in
            try buildInventorySnapshot(db: db, referenceDate: referenceDate)
        }
    }

    public func fetchVialDetail(id: String, referenceDate: Date) async throws -> AtlasVialDetailSnapshot? {
        try await stack.canonical.read { db in
            try buildVialDetailSnapshot(db: db, vialID: id, referenceDate: referenceDate)
        }
    }

    public func fetchConsumableDetail(id: String, referenceDate: Date) async throws -> AtlasConsumableDetailSnapshot? {
        try await stack.canonical.read { db in
            try buildConsumableDetailSnapshot(db: db, consumableID: id, referenceDate: referenceDate)
        }
    }

    public func saveVial(_ draft: AtlasVialDraft, now: Date) async throws -> AtlasVialDetailSnapshot {
        try await stack.canonical.write { db in
            let normalized = try normalize(vialDraft: draft)
            let timestamp = atlasTimestamp(from: now)
            let existing: AtlasVialRecord?
            if let id = normalized.id {
                existing = try AtlasVialDBRecord.fetchOne(db, key: id)?.domain
            } else {
                existing = nil
            }
            let vialID = existing?.id ?? normalized.id ?? UUID().uuidString
            let previousProtocolID = existing?.protocolId

            var record = AtlasVialRecord.make(
                id: vialID,
                protocolId: normalized.protocolID,
                compoundId: existing?.compoundId,
                calculatorProfileId: normalized.calculatorProfileID,
                label: normalized.label,
                startingQuantity: normalized.startingQuantity,
                concentrationValue: normalized.concentrationValue,
                concentrationUnit: normalized.concentrationUnit,
                volumeMl: normalized.volumeML,
                remainingQuantity: normalized.remainingQuantity,
                lowStockThreshold: normalized.lowStockThreshold,
                quantityUnit: normalized.quantityUnit,
                openedAt: normalized.openedAt.map(atlasTimestamp(from:)),
                expiresAt: normalized.expiresAt.map(atlasTimestamp(from:)),
                createdAt: existing?.createdAt ?? timestamp,
                updatedAt: timestamp,
                archivedAt: normalized.archivedAt.map(atlasTimestamp(from:))
            )

            try AtlasVialDBRecord(record: record).save(db)
            try syncVialLinkage(
                db: db,
                vialID: vialID,
                previousProtocolID: previousProtocolID,
                nextProtocolID: normalized.protocolID,
                now: now
            )

            record.protocolId = normalized.protocolID
            guard let detail = try buildVialDetailSnapshot(db: db, vialID: vialID, referenceDate: now) else {
                throw AtlasInventoryRepositoryError.vialNotFound
            }
            return detail
        }
    }

    public func saveConsumable(_ draft: AtlasConsumableDraft, now: Date) async throws -> AtlasConsumableDetailSnapshot {
        try await stack.canonical.write { db in
            let normalized = try normalize(consumableDraft: draft)
            let timestamp = atlasTimestamp(from: now)
            let existing: AtlasConsumableRecord?
            if let id = normalized.id {
                existing = try AtlasConsumableDBRecord.fetchOne(db, key: id)?.domain
            } else {
                existing = nil
            }
            let record = AtlasConsumableRecord.make(
                id: existing?.id ?? normalized.id ?? UUID().uuidString,
                protocolId: normalized.protocolID,
                name: normalized.name,
                category: normalized.category,
                quantityOnHand: normalized.quantityOnHand,
                unit: normalized.unit,
                reorderThreshold: normalized.reorderThreshold,
                reorderLeadTimeDays: normalized.reorderLeadTimeDays,
                quantityPerUse: normalized.quantityPerUse,
                lotNumber: normalized.lotNumber,
                sizeDescription: normalized.sizeDescription,
                notes: normalized.notes,
                vendorLabel: normalized.vendorLabel,
                purchaseNotes: normalized.purchaseNotes,
                createdAt: existing?.createdAt ?? timestamp,
                updatedAt: timestamp,
                archivedAt: normalized.archivedAt.map(atlasTimestamp(from:))
            )
            try AtlasConsumableDBRecord(record: record).save(db)

            if existing == nil {
                try appendConsumableAdjustment(
                    db: db,
                    consumable: record,
                    protocolID: record.protocolId,
                    occurrenceID: nil,
                    kind: .created,
                    deltaQuantity: record.quantityOnHand,
                    note: "Atlas started tracking this supply locally.",
                    vendorLabel: record.vendorLabel,
                    sourceDetail: record.purchaseNotes,
                    recordedAt: timestamp
                )
            } else if existing?.archivedAt == nil, record.archivedAt != nil {
                try appendConsumableAdjustment(
                    db: db,
                    consumable: record,
                    protocolID: record.protocolId,
                    occurrenceID: nil,
                    kind: .archived,
                    deltaQuantity: 0,
                    note: "This supply is archived for future planning.",
                    recordedAt: timestamp
                )
            } else if existing?.archivedAt != nil, record.archivedAt == nil {
                try appendConsumableAdjustment(
                    db: db,
                    consumable: record,
                    protocolID: record.protocolId,
                    occurrenceID: nil,
                    kind: .unarchived,
                    deltaQuantity: 0,
                    note: "This supply returned to active planning.",
                    recordedAt: timestamp
                )
            }

            guard let detail = try buildConsumableDetailSnapshot(db: db, consumableID: record.id, referenceDate: now) else {
                throw AtlasInventoryRepositoryError.consumableNotFound
            }
            return detail
        }
    }

    public func archiveVial(id: String, now: Date) async throws {
        try await stack.canonical.write { db in
            guard var vial = try AtlasVialDBRecord.fetchOne(db, key: id)?.domain else {
                throw AtlasInventoryRepositoryError.vialNotFound
            }

            let timestamp = atlasTimestamp(from: now)
            let previousProtocolID = vial.protocolId
            vial.protocolId = nil
            vial.archivedAt = timestamp
            vial.updatedAt = timestamp
            try AtlasVialDBRecord(record: vial).update(db)

            try syncVialLinkage(
                db: db,
                vialID: id,
                previousProtocolID: previousProtocolID,
                nextProtocolID: nil,
                now: now
            )
        }
    }

    public func setConsumableArchived(id: String, isArchived: Bool, now: Date) async throws {
        try await stack.canonical.write { db in
            guard var consumable = try AtlasConsumableDBRecord.fetchOne(db, key: id)?.domain else {
                throw AtlasInventoryRepositoryError.consumableNotFound
            }

            let timestamp = atlasTimestamp(from: now)
            let previouslyArchived = consumable.archivedAt != nil
            consumable.archivedAt = isArchived ? timestamp : nil
            consumable.updatedAt = timestamp
            try AtlasConsumableDBRecord(record: consumable).update(db)

            if previouslyArchived != isArchived {
                try appendConsumableAdjustment(
                    db: db,
                    consumable: consumable,
                    protocolID: consumable.protocolId,
                    occurrenceID: nil,
                    kind: isArchived ? .archived : .unarchived,
                    deltaQuantity: 0,
                    note: isArchived
                        ? "This supply is archived for future planning."
                        : "This supply returned to active planning.",
                    recordedAt: timestamp
                )
            }
        }
    }

    public func updateProtocolInventorySettings(
        _ update: AtlasProtocolInventorySettingsUpdate,
        now: Date
    ) async throws -> AtlasProtocolInventorySetting {
        try await stack.canonical.write { db in
            guard var protocolRecord = try AtlasProtocolDBRecord.fetchOne(db, key: update.protocolID)?.domain else {
                throw AtlasInventoryRepositoryError.protocolNotFound
            }

            let timestamp = atlasTimestamp(from: now)
            let previousLinkedVialID = protocolRecord.linkedVialId

            if previousLinkedVialID != update.linkedVialID {
                if let previousLinkedVialID,
                   var previousVial = try AtlasVialDBRecord.fetchOne(db, key: previousLinkedVialID)?.domain,
                   previousVial.protocolId == protocolRecord.id {
                    previousVial.protocolId = nil
                    previousVial.updatedAt = timestamp
                    try AtlasVialDBRecord(record: previousVial).update(db)
                }

                if let linkedVialID = update.linkedVialID,
                   var nextVial = try AtlasVialDBRecord.fetchOne(db, key: linkedVialID)?.domain {
                    nextVial.protocolId = protocolRecord.id
                    nextVial.updatedAt = timestamp
                    nextVial.archivedAt = nil
                    try AtlasVialDBRecord(record: nextVial).update(db)
                }
            }

            protocolRecord.linkedVialId = update.linkedVialID
            protocolRecord.siteTrackingEnabled = update.siteTrackingEnabled
            protocolRecord.siteRotationEnabled = update.siteRotationEnabled
            protocolRecord.updatedAt = timestamp
            try AtlasProtocolDBRecord(record: protocolRecord).update(db)

            if previousLinkedVialID != update.linkedVialID {
                try createLinkedVialRevision(
                    db: db,
                    protocolRecord: protocolRecord,
                    linkedVialID: update.linkedVialID,
                    now: now
                )
            }

            let snapshot = try buildInventorySnapshot(db: db, referenceDate: now)
            guard let item = snapshot.protocolSettings.first(where: { $0.id == update.protocolID }) else {
                throw AtlasInventoryRepositoryError.protocolNotFound
            }
            return item
        }
    }

    public func applyManualCorrection(
        _ correction: AtlasInventoryCorrectionDraft,
        now: Date
    ) async throws -> AtlasInventoryCorrectionResult {
        try await stack.canonical.write { db in
            guard var vial = try AtlasVialDBRecord.fetchOne(db, key: correction.vialID)?.domain else {
                throw AtlasInventoryRepositoryError.vialNotFound
            }

            let timestamp = atlasTimestamp(from: now)
            let previousRemaining = vial.remainingQuantity
            vial.remainingQuantity = correction.nextRemainingQuantity
            vial.updatedAt = timestamp
            try AtlasVialDBRecord(record: vial).update(db)

            let linkedProtocolID: String?
            if let protocolId = vial.protocolId {
                linkedProtocolID = protocolId
            } else {
                linkedProtocolID = try AtlasProtocolDBRecord
                    .filter(Column("linked_vial_id") == vial.id)
                    .fetchOne(db)?
                    .domain
                    .id
            }
            var eventID: String?

            if let linkedProtocolID {
                let event = AtlasLogEventRecord.make(
                    id: UUID().uuidString,
                    protocolId: linkedProtocolID,
                    vialId: vial.id,
                    siteId: nil,
                    occurrenceId: nil,
                    eventType: .inventoryAdjustment,
                    effectiveAt: timestamp,
                    loggedAt: timestamp,
                    quantity: correction.nextRemainingQuantity - previousRemaining,
                    quantityUnit: vial.quantityUnit,
                    notes: correction.note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? atlasInventoryCorrectionDefaultNote,
                    source: .user
                )
                try AtlasLogEventDBRecord(record: event).insert(db)
                eventID = event.id
            }

            guard let detail = try buildVialDetailSnapshot(db: db, vialID: vial.id, referenceDate: now) else {
                throw AtlasInventoryRepositoryError.vialNotFound
            }

            return AtlasInventoryCorrectionResult(vial: detail, eventID: eventID)
        }
    }

    public func applyConsumableAdjustment(
        _ adjustment: AtlasConsumableAdjustmentDraft,
        now: Date
    ) async throws -> AtlasConsumableAdjustmentResult {
        try await stack.canonical.write { db in
            guard var consumable = try AtlasConsumableDBRecord.fetchOne(db, key: adjustment.consumableID)?.domain else {
                throw AtlasInventoryRepositoryError.consumableNotFound
            }

            let timestamp = atlasTimestamp(from: now)
            let previousQuantity = consumable.quantityOnHand
            consumable.quantityOnHand = max(adjustment.nextQuantityOnHand, 0)
            consumable.updatedAt = timestamp
            try AtlasConsumableDBRecord(record: consumable).update(db)

            try appendConsumableAdjustment(
                db: db,
                consumable: consumable,
                protocolID: consumable.protocolId,
                occurrenceID: nil,
                kind: .manualAdjustment,
                deltaQuantity: consumable.quantityOnHand - previousQuantity,
                note: adjustment.note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? atlasConsumableAdjustmentDefaultNote,
                recordedAt: timestamp
            )

            guard let detail = try buildConsumableDetailSnapshot(db: db, consumableID: consumable.id, referenceDate: now) else {
                throw AtlasInventoryRepositoryError.consumableNotFound
            }
            return AtlasConsumableAdjustmentResult(consumable: detail)
        }
    }

    public func recordConsumableProcurement(
        _ procurement: AtlasConsumableProcurementDraft,
        now: Date
    ) async throws -> AtlasConsumableAdjustmentResult {
        try await stack.canonical.write { db in
            let normalized = try normalize(procurementDraft: procurement)
            guard var consumable = try AtlasConsumableDBRecord.fetchOne(db, key: normalized.consumableID)?.domain else {
                throw AtlasInventoryRepositoryError.consumableNotFound
            }

            let timestamp = atlasTimestamp(from: now)
            let receivedAt = atlasTimestamp(from: normalized.receivedAt)
            consumable.quantityOnHand += normalized.quantityReceived
            consumable.updatedAt = timestamp
            if let vendorLabel = normalized.vendorLabel {
                consumable.vendorLabel = vendorLabel
            }
            if let sourceDetail = normalized.sourceDetail {
                consumable.purchaseNotes = sourceDetail
            }
            try AtlasConsumableDBRecord(record: consumable).update(db)

            try appendConsumableAdjustment(
                db: db,
                consumable: consumable,
                protocolID: consumable.protocolId,
                occurrenceID: nil,
                kind: .procurement,
                deltaQuantity: normalized.quantityReceived,
                note: "Procurement recorded locally.",
                vendorLabel: normalized.vendorLabel,
                sourceDetail: normalized.sourceDetail,
                recordedAt: receivedAt
            )

            guard let detail = try buildConsumableDetailSnapshot(db: db, consumableID: consumable.id, referenceDate: now) else {
                throw AtlasInventoryRepositoryError.consumableNotFound
            }
            return AtlasConsumableAdjustmentResult(consumable: detail)
        }
    }

    public func fetchProtocolSiteOptions(protocolID: String) async throws -> AtlasProtocolSiteOptions {
        try await stack.canonical.read { db in
            guard let protocolRecord = try AtlasProtocolDBRecord.fetchOne(db, key: protocolID)?.domain else {
                throw AtlasInventoryRepositoryError.protocolNotFound
            }

            let sites = try AtlasSiteDBRecord
                .filter(Column("archived_at") == nil)
                .order(Column("created_at"))
                .fetchAll(db)
                .map { site in
                    AtlasSiteSummary(
                        id: site.id,
                        name: site.name,
                        bodyArea: site.bodyArea,
                        notes: site.notes,
                        archivedAt: site.archivedAt.map(atlasDate(from:))
                    )
                }

            let lastUsedSiteID = try AtlasLogEventDBRecord
                .filter(Column("protocol_id") == protocolID && Column("event_type") == AtlasLogEventType.completed.rawValue)
                .filter(Column("site_id") != nil)
                .order(Column("logged_at").desc)
                .fetchOne(db)?
                .siteId

            var suggestedSiteID: String?
            if sites.isEmpty == false {
                if protocolRecord.siteRotationEnabled, let lastUsedSiteID, let lastIndex = sites.firstIndex(where: { $0.id == lastUsedSiteID }) {
                    suggestedSiteID = sites[(lastIndex + 1) % sites.count].id
                } else {
                    suggestedSiteID = lastUsedSiteID ?? sites.first?.id
                }
            }

            return AtlasProtocolSiteOptions(
                protocolID: protocolID,
                siteTrackingEnabled: protocolRecord.siteTrackingEnabled,
                siteRotationEnabled: protocolRecord.siteRotationEnabled,
                sites: sites,
                suggestedSiteID: suggestedSiteID,
                lastUsedSiteID: lastUsedSiteID
            )
        }
    }

    public func listSites() async throws -> [AtlasSiteSummary] {
        try await stack.canonical.read { db in
            try AtlasSiteDBRecord
                .fetchAll(db)
                .map {
                    AtlasSiteSummary(
                        id: $0.id,
                        name: $0.name,
                        bodyArea: $0.bodyArea,
                        notes: $0.notes,
                        archivedAt: $0.archivedAt.map(atlasDate(from:))
                    )
                }
                .sorted {
                    switch ($0.archivedAt, $1.archivedAt) {
                    case (nil, .some): return true
                    case (.some, nil): return false
                    default: return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    }
                }
        }
    }

    public func saveSite(_ draft: AtlasSiteDraft, now: Date) async throws -> AtlasSiteSummary {
        try await stack.canonical.write { db in
            let normalized = try normalize(siteDraft: draft)
            let timestamp = atlasTimestamp(from: now)
            let existing: AtlasSiteRecord?
            if let id = normalized.id {
                existing = try AtlasSiteDBRecord.fetchOne(db, key: id)?.domain
            } else {
                existing = nil
            }
            let record = AtlasSiteRecord.make(
                id: existing?.id ?? normalized.id ?? UUID().uuidString,
                name: normalized.name,
                bodyArea: normalized.bodyArea,
                notes: normalized.notes,
                createdAt: existing?.createdAt ?? timestamp,
                updatedAt: timestamp,
                archivedAt: normalized.archivedAt.map(atlasTimestamp(from:))
            )
            try AtlasSiteDBRecord(record: record).save(db)
            return AtlasSiteSummary(
                id: record.id,
                name: record.name,
                bodyArea: record.bodyArea,
                notes: record.notes,
                archivedAt: record.archivedAt.map(atlasDate(from:))
            )
        }
    }
}

public struct GRDBCalculatorRepository: CalculatorRepository, Sendable {
    let stack: AtlasDatabaseStack

    init(stack: AtlasDatabaseStack) {
        self.stack = stack
    }

    public func listProfiles() async throws -> [AtlasCalculatorProfileRecord] {
        try await stack.canonical.read { db in
            try AtlasCalculatorProfileDBRecord
                .order(Column("updated_at").desc)
                .fetchAll(db)
                .map(\.domain)
        }
    }

    public func saveProfile(_ draft: AtlasCalculatorProfileDraft, now: Date) async throws -> AtlasCalculatorProfileRecord {
        try await stack.canonical.write { db in
            let normalized = try normalize(calculatorDraft: draft)
            let timestamp = atlasTimestamp(from: now)
            let existing: AtlasCalculatorProfileRecord?
            if let id = normalized.id {
                existing = try AtlasCalculatorProfileDBRecord.fetchOne(db, key: id)?.domain
            } else {
                existing = nil
            }
            let record = AtlasCalculatorProfileRecord.make(
                id: existing?.id ?? normalized.id ?? UUID().uuidString,
                label: normalized.label,
                powderAmount: normalized.powderAmount,
                powderUnit: normalized.powderUnit,
                diluentVolume: normalized.diluentVolume,
                diluentUnit: normalized.diluentUnit,
                drawVolume: normalized.drawVolume,
                drawUnit: normalized.drawUnit,
                createdAt: existing?.createdAt ?? timestamp,
                updatedAt: timestamp
            )
            try AtlasCalculatorProfileDBRecord(record: record).save(db)
            return record
        }
    }

    public func deleteProfile(id: String) async throws {
        try await stack.canonical.write { db in
            try db.execute(
                sql: """
                UPDATE vials
                SET calculator_profile_id = NULL
                WHERE calculator_profile_id = ?
                """,
                arguments: [id]
            )
            _ = try AtlasCalculatorProfileDBRecord.deleteOne(db, key: id)
        }
    }
}

private enum AtlasInventoryRepositoryError: LocalizedError {
    case invalidVialLabel
    case invalidConsumableName
    case invalidProcurementQuantity
    case invalidSiteName
    case invalidCalculatorProfile
    case protocolNotFound
    case vialNotFound
    case consumableNotFound

    var errorDescription: String? {
        switch self {
        case .invalidVialLabel:
            return "A vial label is required."
        case .invalidConsumableName:
            return "A supply name is required."
        case .invalidProcurementQuantity:
            return "Record a received quantity greater than zero."
        case .invalidSiteName:
            return "A site name is required."
        case .invalidCalculatorProfile:
            return "Calculator values must be greater than zero."
        case .protocolNotFound:
            return "The protocol could not be found."
        case .vialNotFound:
            return "The vial could not be found."
        case .consumableNotFound:
            return "The supply item could not be found."
        }
    }
}

func buildInventorySnapshot(db: Database, referenceDate: Date) throws -> AtlasInventorySnapshot {
    let context = try loadCoreLoopContext(db: db)
    let protocols = context.protocols.values.sorted { $0.createdAt > $1.createdAt }
    let vials = try AtlasVialDBRecord.fetchAll(db).map(\.domain)
    let consumables = try AtlasConsumableDBRecord.fetchAll(db).map(\.domain)
    let consumableAdjustmentsByID = Dictionary(
        grouping: try AtlasConsumableAdjustmentDBRecord.fetchAll(db).map(\.domain),
        by: \.consumableId
    )
    let profiles = Dictionary(
        uniqueKeysWithValues: try AtlasCalculatorProfileDBRecord.fetchAll(db).map { ($0.id, $0.domain) }
    )

    let protocolSettings = protocols.map { protocolRecord -> AtlasProtocolInventorySetting in
        let activeSlice = inventoryEffectiveRevisionSlice(context.revisionSlices[protocolRecord.id] ?? [], at: referenceDate)
        let activeRule = activeSlice.flatMap { inventoryActiveRule(slice: $0, at: referenceDate) }
        let baseRule = (context.protocolRules[protocolRecord.id] ?? []).first(where: \.isActive) ?? context.protocolRules[protocolRecord.id]?.first
        let linkedVial = vials.first(where: { $0.id == protocolRecord.linkedVialId })

        return AtlasProtocolInventorySetting(
            id: protocolRecord.id,
            canonicalTitle: protocolRecord.name,
            aliasTitle: context.aliases[protocolRecord.id]?.aliasLabel,
            kindLabel: inventoryKindLabel(protocolRecord.kind),
            cadenceLabel: inventoryCadenceLabel(
                ruleType: activeRule?.ruleType ?? baseRule?.ruleType,
                intervalCount: activeRule?.intervalCount ?? baseRule?.intervalCount,
                weekday: activeRule?.weekday ?? baseRule?.weekday,
                timeOfDay: activeRule?.timeOfDay ?? activeSlice?.revision.defaultTimeOfDay ?? protocolRecord.defaultTimeOfDay
            ),
            doseLabel: inventoryDoseLabel(
                amount: activeRule?.doseAmountOverride ?? activeSlice?.revision.doseAmount ?? protocolRecord.doseAmount,
                unit: activeRule?.doseUnitOverride ?? activeSlice?.revision.doseUnit ?? protocolRecord.doseUnit
            ),
            linkedVialID: protocolRecord.linkedVialId,
            linkedVialLabel: linkedVial?.label,
            siteTrackingEnabled: protocolRecord.siteTrackingEnabled,
            siteRotationEnabled: protocolRecord.siteRotationEnabled
        )
    }

    let vialSummaries = try vials
        .map { vial in
            try buildVialSummary(
                db: db,
                vial: vial,
                context: context,
                calculatorProfiles: profiles,
                referenceDate: referenceDate
            )
        }
        .sorted {
            switch ($0.archivedAt, $1.archivedAt) {
            case (nil, .some): return true
            case (.some, nil): return false
            default: return $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending
            }
        }

    let sites = try AtlasSiteDBRecord
        .fetchAll(db)
        .map {
            AtlasSiteSummary(
                id: $0.id,
                name: $0.name,
                bodyArea: $0.bodyArea,
                notes: $0.notes,
                archivedAt: $0.archivedAt.map(atlasDate(from:))
            )
        }
        .sorted {
            switch ($0.archivedAt, $1.archivedAt) {
            case (nil, .some): return true
            case (.some, nil): return false
            default: return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }

    return AtlasInventorySnapshot(
        protocolSettings: protocolSettings,
        vials: vialSummaries,
        consumables: try consumables
            .map { consumable in
                try buildConsumableSummary(
                    consumable: consumable,
                    context: context,
                    referenceDate: referenceDate,
                    adjustments: consumableAdjustmentsByID[consumable.id] ?? []
                )
            }
            .sorted {
                switch ($0.archivedAt, $1.archivedAt) {
                case (nil, .some): return true
                case (.some, nil): return false
                default: return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
            },
        sites: sites
    )
}

private func buildVialDetailSnapshot(
    db: Database,
    vialID: String,
    referenceDate: Date
) throws -> AtlasVialDetailSnapshot? {
    guard let vial = try AtlasVialDBRecord.fetchOne(db, key: vialID)?.domain else {
        return nil
    }

    let context = try loadCoreLoopContext(db: db)
    let profiles = Dictionary(
        uniqueKeysWithValues: try AtlasCalculatorProfileDBRecord.fetchAll(db).map { ($0.id, $0.domain) }
    )
    let summary = try buildVialSummary(
        db: db,
        vial: vial,
        context: context,
        calculatorProfiles: profiles,
        referenceDate: referenceDate
    )
    let corrections = try AtlasLogEventDBRecord
        .filter(Column("vial_id") == vialID && Column("event_type") == AtlasLogEventType.inventoryAdjustment.rawValue)
        .order(Column("logged_at").desc)
        .fetchAll(db)
        .map(\.domain)
        .map {
            AtlasInventoryCorrectionEntry(
                id: $0.id,
                deltaLabel: formatInventoryCorrectionDelta($0.quantity, unit: $0.quantityUnit),
                note: $0.notes,
                recordedAt: atlasDate(from: $0.loggedAt)
            )
        }
    let movementHistory = try buildInventoryMovementHistory(
        db: db,
        vial: vial,
        context: context,
        referenceDate: referenceDate
    )

    return AtlasVialDetailSnapshot(
        summary: summary,
        editableDraft: AtlasVialDraft(
            id: vial.id,
            label: vial.label,
            protocolID: vial.protocolId ?? summary.linkedProtocolID,
            startingQuantity: vial.startingQuantity,
            remainingQuantity: vial.remainingQuantity,
            quantityUnit: vial.quantityUnit,
            lowStockThreshold: vial.lowStockThreshold,
            concentrationValue: vial.concentrationValue,
            concentrationUnit: vial.concentrationUnit,
            volumeML: vial.volumeMl,
            calculatorProfileID: vial.calculatorProfileId,
            openedAt: vial.openedAt.map(atlasDate(from:)),
            expiresAt: vial.expiresAt.map(atlasDate(from:)),
            archivedAt: vial.archivedAt.map(atlasDate(from:))
        ),
        correctionHistory: corrections,
        movementHistory: movementHistory
    )
}

private func buildConsumableDetailSnapshot(
    db: Database,
    consumableID: String,
    referenceDate: Date
) throws -> AtlasConsumableDetailSnapshot? {
    guard let consumable = try AtlasConsumableDBRecord.fetchOne(db, key: consumableID)?.domain else {
        return nil
    }

    let context = try loadCoreLoopContext(db: db)
    let rawAdjustments = try AtlasConsumableAdjustmentDBRecord
        .filter(Column("consumable_id") == consumableID)
        .order(Column("recorded_at").desc)
        .fetchAll(db)
        .map(\.domain)
    let summary = try buildConsumableSummary(
        consumable: consumable,
        context: context,
        referenceDate: referenceDate,
        adjustments: rawAdjustments
    )
    let adjustments = rawAdjustments.map { adjustment in
            AtlasConsumableAdjustmentEntry(
                id: adjustment.id,
                kind: adjustment.kind,
                title: consumableAdjustmentTitle(for: adjustment.kind),
                detail: adjustment.note ?? consumableAdjustmentFallbackDetail(for: adjustment.kind),
                deltaLabel: abs(adjustment.deltaQuantity) < 0.0001
                    ? nil
                    : formatInventoryCorrectionDelta(adjustment.deltaQuantity, unit: adjustment.quantityUnit),
                resultingQuantityLabel: "\(formatAtlasQuantity(adjustment.resultingQuantity, unit: adjustment.quantityUnit)) on hand",
                recordedAt: atlasDate(from: adjustment.recordedAt)
                )
        }
    let procurementHistory = buildConsumableProcurementHistory(adjustments: rawAdjustments)
    let planning = buildConsumablePlanningSnapshot(
        summary: summary,
        procurementHistory: procurementHistory
    )

    return AtlasConsumableDetailSnapshot(
        summary: summary,
        editableDraft: AtlasConsumableDraft(
            id: consumable.id,
            protocolID: consumable.protocolId,
            name: consumable.name,
            category: consumable.category,
            quantityOnHand: consumable.quantityOnHand,
            unit: consumable.unit,
            reorderThreshold: consumable.reorderThreshold,
            reorderLeadTimeDays: consumable.reorderLeadTimeDays,
            quantityPerUse: consumable.quantityPerUse,
            lotNumber: consumable.lotNumber,
            sizeDescription: consumable.sizeDescription,
            notes: consumable.notes,
            vendorLabel: consumable.vendorLabel,
            purchaseNotes: consumable.purchaseNotes,
            archivedAt: consumable.archivedAt.map(atlasDate(from:))
        ),
        planning: planning,
        procurementHistory: procurementHistory,
        adjustmentHistory: adjustments
    )
}

private func buildInventoryMovementHistory(
    db: Database,
    vial: AtlasVialRecord,
    context: AtlasCoreLoopContext,
    referenceDate: Date
) throws -> [AtlasInventoryMovementEntry] {
    var items: [AtlasInventoryMovementEntry] = [
        AtlasInventoryMovementEntry(
            id: "created:\(vial.id)",
            kind: .created,
            title: "Vial saved",
            detail: "Atlas started tracking this vial locally.",
            recordedAt: atlasDate(from: vial.createdAt)
        )
    ]

    if let archivedAt = vial.archivedAt {
        items.append(
            AtlasInventoryMovementEntry(
                id: "archived:\(vial.id)",
                kind: .archived,
                title: "Vial archived",
                detail: "This vial is no longer active for future inventory tracking.",
                recordedAt: atlasDate(from: archivedAt)
            )
        )
    }

    let logs = try AtlasLogEventDBRecord
        .filter(Column("vial_id") == vial.id)
        .order(Column("logged_at").desc)
        .fetchAll(db)
        .map(\.domain)

    for log in logs {
        switch log.eventType {
        case .completed, .manualLog:
            let protocolRecord = context.protocols[log.protocolId]
            let deltaLabel = protocolRecord.flatMap { protocolRecord in
                inventoryDoseDecrement(
                    protocolRecord: protocolRecord,
                    context: context,
                    scheduledAt: atlasDate(from: log.effectiveAt),
                    vial: vial
                )
                .map { decrement in
                    formatInventoryCorrectionDelta(-decrement.amount, unit: decrement.unit)
                }
            }
            items.append(
                AtlasInventoryMovementEntry(
                    id: "taken:\(log.id)",
                    kind: .takenLog,
                    title: "Taken log decrement",
                    detail: "Inventory moved after a taken log used this vial.",
                    deltaLabel: deltaLabel,
                    recordedAt: atlasDate(from: log.loggedAt)
                )
            )
        case .inventoryAdjustment:
            items.append(
                AtlasInventoryMovementEntry(
                    id: "correction:\(log.id)",
                    kind: .manualCorrection,
                    title: "Manual correction",
                    detail: log.notes ?? "Inventory was corrected manually.",
                    deltaLabel: formatInventoryCorrectionDelta(log.quantity, unit: log.quantityUnit),
                    recordedAt: atlasDate(from: log.loggedAt)
                )
            )
        case .skipped, .rescheduled:
            continue
        }
    }

    let audits = try AtlasProtocolChangeAuditDBRecord
        .order(Column("created_at").desc)
        .fetchAll(db)
        .map(\.domain)
    for audit in audits {
        if let movement = buildVialHandoffMovementEntry(
            audit: audit,
            vialID: vial.id,
            context: context
        ) {
            items.append(movement)
        }
    }

    return items.sorted {
        if $0.recordedAt == $1.recordedAt {
            return $0.id > $1.id
        }
        return $0.recordedAt > $1.recordedAt
    }
}

private func buildVialHandoffMovementEntry(
    audit: AtlasProtocolChangeAuditRecord,
    vialID: String,
    context: AtlasCoreLoopContext
) -> AtlasInventoryMovementEntry? {
    guard audit.changeType == .vialHandoffPlanned else {
        return nil
    }

    let nextLinkedVialID = findRevisionSlice(
        context.revisionSlices[audit.protocolId] ?? [],
        revisionID: audit.revisionId
    )?.revision.linkedVialId
    let previousLinkedVialID = audit.previousRevisionId.flatMap { previousRevisionID in
        findRevisionSlice(
            context.revisionSlices[audit.protocolId] ?? [],
            revisionID: previousRevisionID
        )?.revision.linkedVialId
    }

    guard nextLinkedVialID == vialID || previousLinkedVialID == vialID else {
        return nil
    }

    let detail: String
    if nextLinkedVialID == vialID, previousLinkedVialID != vialID {
        detail = "This vial became the linked future vial for upcoming taken logs."
    } else if previousLinkedVialID == vialID, nextLinkedVialID != vialID {
        detail = "Future taken logs switch away from this vial after the handoff date."
    } else {
        detail = "Linked future-vial assignment changed for this protocol."
    }

    return AtlasInventoryMovementEntry(
        id: "handoff:\(audit.id):\(vialID)",
        kind: .vialHandoff,
        title: "Future vial handoff",
        detail: detail,
        recordedAt: atlasDate(from: audit.createdAt)
    )
}

private func buildVialSummary(
    db: Database,
    vial: AtlasVialRecord,
    context: AtlasCoreLoopContext,
    calculatorProfiles: [String: AtlasCalculatorProfileRecord],
    referenceDate: Date
) throws -> AtlasVialSummary {
    let linkedProtocol = inventoryLinkedProtocol(for: vial, context: context, referenceDate: referenceDate)
    let nextOccurrence = linkedProtocol.flatMap { protocolRecord in
        let sorted = (context.pendingOccurrences[protocolRecord.id] ?? [])
            .sorted { atlasDate(from: $0.scheduledAt) < atlasDate(from: $1.scheduledAt) }
        return sorted.first(where: { atlasDate(from: $0.scheduledAt) >= referenceDate }) ?? sorted.first
    }
    let decrement = linkedProtocol.flatMap { protocolRecord in
        inventoryDoseDecrement(
            protocolRecord: protocolRecord,
            context: context,
            scheduledAt: nextOccurrence.map { atlasDate(from: $0.scheduledAt) } ?? referenceDate,
            vial: vial
        )
    }
    let depletionLabel = linkedProtocol.flatMap { protocolRecord in
        inventoryProjectedDepletionLabel(
            protocolRecord: protocolRecord,
            context: context,
            nextScheduledAt: nextOccurrence.map { atlasDate(from: $0.scheduledAt) },
            vial: vial
        )
    }
    let lowStockLabel = vial.lowStockThreshold.map { "Low stock at \(formatAtlasQuantity($0, unit: vial.quantityUnit))" }
    let isLowStock = vial.lowStockThreshold.map { vial.remainingQuantity <= $0 } ?? false

    return AtlasVialSummary(
        id: vial.id,
        label: vial.label,
        linkedProtocolID: linkedProtocol?.id,
        linkedProtocolCanonicalTitle: linkedProtocol?.name,
        linkedProtocolAliasTitle: linkedProtocol.flatMap { context.aliases[$0.id]?.aliasLabel },
        calculatorProfileID: vial.calculatorProfileId,
        calculatorProfileLabel: vial.calculatorProfileId.flatMap { calculatorProfiles[$0]?.label },
        quantityLabel: "\(formatAtlasQuantity(vial.remainingQuantity, unit: vial.quantityUnit)) remaining of \(formatAtlasQuantity(vial.startingQuantity, unit: vial.quantityUnit))",
        lowStockLabel: lowStockLabel,
        projectedDepletionLabel: depletionLabel,
        autoDecrementLabel: decrement.map { "Auto-decrements \(formatAtlasQuantity($0.amount, unit: $0.unit)) per taken log" },
        remainingQuantity: vial.remainingQuantity,
        startingQuantity: vial.startingQuantity,
        quantityUnit: vial.quantityUnit,
        isLowStock: isLowStock,
        archivedAt: vial.archivedAt.map(atlasDate(from:))
    )
}

private func buildConsumableSummary(
    consumable: AtlasConsumableRecord,
    context: AtlasCoreLoopContext,
    referenceDate: Date,
    adjustments: [AtlasConsumableAdjustmentRecord]
) throws -> AtlasConsumableSummary {
    let linkedProtocol = inventoryLinkedProtocol(
        protocolID: consumable.protocolId,
        context: context
    )
    let nextOccurrence = linkedProtocol.flatMap { protocolRecord in
        let sorted = (context.pendingOccurrences[protocolRecord.id] ?? [])
            .sorted { atlasDate(from: $0.scheduledAt) < atlasDate(from: $1.scheduledAt) }
        return sorted.first(where: { atlasDate(from: $0.scheduledAt) >= referenceDate }) ?? sorted.first
    }
    let projectedTargetDate = linkedProtocol.flatMap { protocolRecord in
        inventoryProjectedConsumableTargetDate(
            protocolRecord: protocolRecord,
            context: context,
            nextScheduledAt: nextOccurrence.map { atlasDate(from: $0.scheduledAt) },
            consumable: consumable
        )
    }
    let projectedDepletionLabel = projectedTargetDate.map { targetDate in
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        if consumable.reorderThreshold != nil {
            return "Projected reorder point \(formatter.string(from: targetDate))"
        }
        return "Projected depletion \(formatter.string(from: targetDate))"
    }
    let reorderLeadTimeLabel = consumable.reorderLeadTimeDays.flatMap { leadTime in
        leadTime > 0 ? "Lead time \(leadTime) day\(leadTime == 1 ? "" : "s")" : nil
    }
    let lowStockLabel = consumable.reorderThreshold.map {
        "Reorder at \(formatAtlasQuantity($0, unit: consumable.unit))"
    }
    let isLowStock = consumable.reorderThreshold.map { consumable.quantityOnHand <= $0 } ?? false
    let procurementHistory = buildConsumableProcurementHistory(adjustments: adjustments)
    let planning = buildConsumablePlanningSnapshot(
        consumable: consumable,
        lowStockLabel: lowStockLabel,
        projectedDepletionLabel: projectedDepletionLabel,
        usageLabel: consumable.quantityPerUse.map {
            "Planned use \(formatAtlasQuantity($0, unit: consumable.unit)) per taken log"
        },
        reorderLeadTimeLabel: reorderLeadTimeLabel,
        projectedTargetDate: projectedTargetDate,
        procurementHistory: procurementHistory,
        referenceDate: referenceDate
    )

    return AtlasConsumableSummary(
        id: consumable.id,
        name: consumable.name,
        category: consumable.category,
        linkedProtocolID: linkedProtocol?.id,
        linkedProtocolCanonicalTitle: linkedProtocol?.name,
        linkedProtocolAliasTitle: linkedProtocol.flatMap { context.aliases[$0.id]?.aliasLabel },
        vendorLabel: consumable.vendorLabel,
        quantityLabel: "\(formatAtlasQuantity(consumable.quantityOnHand, unit: consumable.unit)) on hand",
        lowStockLabel: lowStockLabel,
        projectedDepletionLabel: projectedDepletionLabel,
        usageLabel: planning.usageLabel,
        reorderLeadTimeLabel: reorderLeadTimeLabel,
        procurementStatusLabel: planning.procurementStatusLabel,
        lastProcurementLabel: planning.lastProcurementLabel,
        quantityOnHand: consumable.quantityOnHand,
        quantityUnit: consumable.unit,
        reorderThreshold: consumable.reorderThreshold,
        isLowStock: isLowStock,
        needsProcurementReview: planning.needsProcurementReview,
        archivedAt: consumable.archivedAt.map(atlasDate(from:))
    )
}

private func syncVialLinkage(
    db: Database,
    vialID: String,
    previousProtocolID: String?,
    nextProtocolID: String?,
    now: Date
) throws {
    let timestamp = atlasTimestamp(from: now)

    if let previousProtocolID, previousProtocolID != nextProtocolID,
       var previousProtocol = try AtlasProtocolDBRecord.fetchOne(db, key: previousProtocolID)?.domain,
       previousProtocol.linkedVialId == vialID {
        previousProtocol.linkedVialId = nil
        previousProtocol.updatedAt = timestamp
        try AtlasProtocolDBRecord(record: previousProtocol).update(db)
        try createLinkedVialRevision(
            db: db,
            protocolRecord: previousProtocol,
            linkedVialID: nil,
            now: now
        )
    }

    if let nextProtocolID,
       var protocolRecord = try AtlasProtocolDBRecord.fetchOne(db, key: nextProtocolID)?.domain {
        protocolRecord.linkedVialId = vialID
        protocolRecord.updatedAt = timestamp
        try AtlasProtocolDBRecord(record: protocolRecord).update(db)
        try createLinkedVialRevision(
            db: db,
            protocolRecord: protocolRecord,
            linkedVialID: vialID,
            now: now
        )
    }
}

private func createLinkedVialRevision(
    db: Database,
    protocolRecord: AtlasProtocolRecord,
    linkedVialID: String?,
    now: Date
) throws {
    let revisions = try AtlasProtocolRevisionDBRecord
        .filter(Column("protocol_id") == protocolRecord.id)
        .order(Column("revision_number").desc)
        .fetchAll(db)
        .map(\.domain)
    guard var currentRevision = revisions.first(where: { $0.effectiveTo == nil }) ?? revisions.first else {
        return
    }

    if currentRevision.linkedVialId == linkedVialID {
        return
    }

    let timestamp = atlasTimestamp(from: now)
    currentRevision.effectiveTo = timestamp
    currentRevision.updatedAt = timestamp
    try AtlasProtocolRevisionDBRecord(record: currentRevision).update(db)

    let nextRevision = AtlasProtocolRevisionRecord(
        id: UUID().uuidString,
        protocolId: protocolRecord.id,
        revisionNumber: currentRevision.revisionNumber + 1,
        previousRevisionId: currentRevision.id,
        effectiveFrom: timestamp,
        effectiveTo: nil,
        lifecycleState: .active,
        timezone: currentRevision.timezone,
        timezoneStrategy: currentRevision.timezoneStrategy,
        defaultTimeOfDay: currentRevision.defaultTimeOfDay,
        doseAmount: currentRevision.doseAmount,
        doseUnit: currentRevision.doseUnit,
        linkedVialId: linkedVialID,
        missedDosePolicy: currentRevision.missedDosePolicy,
        notes: currentRevision.notes,
        createdAt: timestamp,
        updatedAt: timestamp
    )
    try AtlasProtocolRevisionDBRecord(record: nextRevision).insert(db)

    let priorRules = try AtlasProtocolRevisionRuleDBRecord
        .filter(Column("revision_id") == currentRevision.id)
        .order(Column("phase_order"))
        .fetchAll(db)
        .map(\.domain)

    for rule in priorRules {
        let clonedRule = AtlasProtocolRevisionRuleRecord(
            id: UUID().uuidString,
            revisionId: nextRevision.id,
            phaseType: rule.phaseType,
            phaseOrder: rule.phaseOrder,
            ruleType: rule.ruleType,
            intervalCount: rule.intervalCount,
            weekday: rule.weekday,
            timeOfDay: rule.timeOfDay,
            anchorDate: rule.anchorDate,
            phaseStartDayOffset: rule.phaseStartDayOffset,
            phaseLengthDays: rule.phaseLengthDays,
            doseAmountOverride: rule.doseAmountOverride,
            doseUnitOverride: rule.doseUnitOverride,
            createdAt: timestamp,
            updatedAt: timestamp
        )
        try AtlasProtocolRevisionRuleDBRecord(record: clonedRule).insert(db)
    }

    let audit = AtlasProtocolChangeAuditRecord.make(
        id: UUID().uuidString,
        protocolId: protocolRecord.id,
        revisionId: nextRevision.id,
        previousRevisionId: currentRevision.id,
        changeType: .vialHandoffPlanned,
        effectiveFrom: timestamp,
        summary: linkedVialID == nil ? "Vial unlinked in native iOS" : "Active vial updated in native iOS",
        payloadJson: "{}",
        createdAt: timestamp
    )
    try AtlasProtocolChangeAuditDBRecord(record: audit).insert(db)
}

func appendConsumableAdjustment(
    db: Database,
    consumable: AtlasConsumableRecord,
    protocolID: String?,
    occurrenceID: String?,
    kind: AtlasConsumableAdjustmentKind,
    deltaQuantity: Double,
    note: String?,
    vendorLabel: String? = nil,
    sourceDetail: String? = nil,
    recordedAt: String
) throws {
    let adjustment = AtlasConsumableAdjustmentRecord.make(
        id: UUID().uuidString,
        consumableId: consumable.id,
        protocolId: protocolID,
        occurrenceId: occurrenceID,
        kind: kind,
        deltaQuantity: deltaQuantity,
        resultingQuantity: consumable.quantityOnHand,
        quantityUnit: consumable.unit,
        note: note,
        vendorLabel: vendorLabel,
        sourceDetail: sourceDetail,
        recordedAt: recordedAt,
        createdAt: recordedAt
    )
    try AtlasConsumableAdjustmentDBRecord(record: adjustment).insert(db)
}

private func normalize(vialDraft: AtlasVialDraft) throws -> AtlasVialDraft {
    let label = vialDraft.label.trimmingCharacters(in: .whitespacesAndNewlines)
    guard label.isEmpty == false else {
        throw AtlasInventoryRepositoryError.invalidVialLabel
    }

    return AtlasVialDraft(
        id: vialDraft.id,
        label: label,
        protocolID: vialDraft.protocolID,
        startingQuantity: max(vialDraft.startingQuantity, 0),
        remainingQuantity: max(vialDraft.remainingQuantity, 0),
        quantityUnit: vialDraft.quantityUnit.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "dose",
        lowStockThreshold: vialDraft.lowStockThreshold,
        concentrationValue: vialDraft.concentrationValue,
        concentrationUnit: vialDraft.concentrationUnit?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
        volumeML: vialDraft.volumeML,
        calculatorProfileID: vialDraft.calculatorProfileID,
        openedAt: vialDraft.openedAt,
        expiresAt: vialDraft.expiresAt,
        archivedAt: vialDraft.archivedAt
    )
}

private func normalize(consumableDraft: AtlasConsumableDraft) throws -> AtlasConsumableDraft {
    let name = consumableDraft.name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard name.isEmpty == false else {
        throw AtlasInventoryRepositoryError.invalidConsumableName
    }

    return AtlasConsumableDraft(
        id: consumableDraft.id,
        protocolID: consumableDraft.protocolID,
        name: name,
        category: consumableDraft.category?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
        quantityOnHand: max(consumableDraft.quantityOnHand, 0),
        unit: consumableDraft.unit.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "item",
        reorderThreshold: consumableDraft.reorderThreshold.map { max($0, 0) },
        reorderLeadTimeDays: consumableDraft.reorderLeadTimeDays.map { max($0, 0) },
        quantityPerUse: consumableDraft.quantityPerUse.map { max($0, 0) },
        lotNumber: consumableDraft.lotNumber?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
        sizeDescription: consumableDraft.sizeDescription?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
        notes: consumableDraft.notes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
        vendorLabel: consumableDraft.vendorLabel?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
        purchaseNotes: consumableDraft.purchaseNotes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
        archivedAt: consumableDraft.archivedAt
    )
}

private func normalize(procurementDraft: AtlasConsumableProcurementDraft) throws -> AtlasConsumableProcurementDraft {
    guard procurementDraft.quantityReceived > 0 else {
        throw AtlasInventoryRepositoryError.invalidProcurementQuantity
    }

    return AtlasConsumableProcurementDraft(
        consumableID: procurementDraft.consumableID,
        quantityReceived: procurementDraft.quantityReceived,
        vendorLabel: procurementDraft.vendorLabel?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
        sourceDetail: procurementDraft.sourceDetail?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
        receivedAt: procurementDraft.receivedAt
    )
}

private func normalize(siteDraft: AtlasSiteDraft) throws -> AtlasSiteDraft {
    let name = siteDraft.name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard name.isEmpty == false else {
        throw AtlasInventoryRepositoryError.invalidSiteName
    }

    return AtlasSiteDraft(
        id: siteDraft.id,
        name: name,
        bodyArea: siteDraft.bodyArea?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
        notes: siteDraft.notes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
        archivedAt: siteDraft.archivedAt
    )
}

private func normalize(calculatorDraft: AtlasCalculatorProfileDraft) throws -> AtlasCalculatorProfileDraft {
    guard calculatorDraft.powderAmount > 0, calculatorDraft.diluentVolume > 0, calculatorDraft.drawVolume > 0 else {
        throw AtlasInventoryRepositoryError.invalidCalculatorProfile
    }

    return AtlasCalculatorProfileDraft(
        id: calculatorDraft.id,
        label: calculatorDraft.label.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Saved calculator profile",
        powderAmount: calculatorDraft.powderAmount,
        powderUnit: calculatorDraft.powderUnit.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "mg",
        diluentVolume: calculatorDraft.diluentVolume,
        diluentUnit: calculatorDraft.diluentUnit.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "mL",
        drawVolume: calculatorDraft.drawVolume,
        drawUnit: calculatorDraft.drawUnit.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "mL"
    )
}

private func inventoryLinkedProtocol(
    for vial: AtlasVialRecord,
    context: AtlasCoreLoopContext,
    referenceDate: Date
) -> AtlasProtocolRecord? {
    if let protocolID = vial.protocolId, let direct = context.protocols[protocolID] {
        return direct
    }

    return context.protocols.values.first { protocolRecord in
        guard protocolRecord.linkedVialId == vial.id else {
            return false
        }
        let activeSlice = inventoryEffectiveRevisionSlice(context.revisionSlices[protocolRecord.id] ?? [], at: referenceDate)
        return activeSlice?.revision.linkedVialId == nil || activeSlice?.revision.linkedVialId == vial.id
    }
}

private func inventoryLinkedProtocol(
    protocolID: String?,
    context: AtlasCoreLoopContext
) -> AtlasProtocolRecord? {
    guard let protocolID else {
        return nil
    }
    return context.protocols[protocolID]
}

private func inventoryDoseDecrement(
    protocolRecord: AtlasProtocolRecord,
    context: AtlasCoreLoopContext,
    scheduledAt: Date,
    vial: AtlasVialRecord
) -> (amount: Double, unit: String)? {
    let slice = inventoryEffectiveRevisionSlice(context.revisionSlices[protocolRecord.id] ?? [], at: scheduledAt)
    let rule = slice.flatMap { inventoryActiveRule(slice: $0, at: scheduledAt) }
    let doseAmount = rule?.doseAmountOverride ?? slice?.revision.doseAmount ?? protocolRecord.doseAmount
    let doseUnit = rule?.doseUnitOverride ?? slice?.revision.doseUnit ?? protocolRecord.doseUnit
    guard let doseAmount, let doseUnit else {
        return nil
    }

    let vialUnit = normalizeInventoryUnit(vial.quantityUnit)
    let normalizedDoseUnit = normalizeInventoryUnit(doseUnit)

    if vialUnit == "dose" {
        return (1, vial.quantityUnit)
    }

    if vialUnit == normalizedDoseUnit {
        return (doseAmount, vial.quantityUnit)
    }

    if vialUnit == "ml",
       let concentrationValue = vial.concentrationValue,
       concentrationValue > 0,
       let concentrationUnit = vial.concentrationUnit,
       normalizeInventoryUnit(concentrationUnit) == normalizedDoseUnit {
        return (doseAmount / concentrationValue, vial.quantityUnit)
    }

    return nil
}

private func inventoryProjectedDepletionLabel(
    protocolRecord: AtlasProtocolRecord,
    context: AtlasCoreLoopContext,
    nextScheduledAt: Date?,
    vial: AtlasVialRecord
) -> String? {
    guard let nextScheduledAt else {
        return nil
    }
    guard let decrement = inventoryDoseDecrement(
        protocolRecord: protocolRecord,
        context: context,
        scheduledAt: nextScheduledAt,
        vial: vial
    ) else {
        return nil
    }

    let slice = inventoryEffectiveRevisionSlice(context.revisionSlices[protocolRecord.id] ?? [], at: nextScheduledAt)
    let rule = slice.flatMap { inventoryActiveRule(slice: $0, at: nextScheduledAt) }
    let cadenceDays = inventoryCadenceDays(ruleType: rule?.ruleType, intervalCount: rule?.intervalCount)
    guard let cadenceDays, decrement.amount > 0 else {
        return nil
    }

    let remainingEvents = Int(ceil(vial.remainingQuantity / decrement.amount))
    let depletion = nextScheduledAt.addingTimeInterval(TimeInterval(max(remainingEvents - 1, 0) * cadenceDays) * 86_400)
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return "Projected depletion \(formatter.string(from: depletion))"
}

private func inventoryProjectedConsumableTargetDate(
    protocolRecord: AtlasProtocolRecord,
    context: AtlasCoreLoopContext,
    nextScheduledAt: Date?,
    consumable: AtlasConsumableRecord
) -> Date? {
    guard let nextScheduledAt,
          let quantityPerUse = consumable.quantityPerUse,
          quantityPerUse > 0 else {
        return nil
    }

    let slice = inventoryEffectiveRevisionSlice(context.revisionSlices[protocolRecord.id] ?? [], at: nextScheduledAt)
    let rule = slice.flatMap { inventoryActiveRule(slice: $0, at: nextScheduledAt) }
    let cadenceDays = inventoryCadenceDays(ruleType: rule?.ruleType, intervalCount: rule?.intervalCount)
    guard let cadenceDays else {
        return nil
    }

    let targetQuantity = consumable.reorderThreshold ?? 0
    let remainingToTarget = max(consumable.quantityOnHand - targetQuantity, 0)
    let remainingEvents = Int(ceil(max(remainingToTarget, 0.0001) / quantityPerUse))
    return nextScheduledAt.addingTimeInterval(TimeInterval(max(remainingEvents - 1, 0) * cadenceDays) * 86_400)
}

private func consumableAdjustmentTitle(for kind: AtlasConsumableAdjustmentKind) -> String {
    switch kind {
    case .created:
        return "Supply saved"
    case .manualAdjustment:
        return "Manual adjustment"
    case .procurement:
        return "Procurement recorded"
    case .protocolUse:
        return "Taken-log decrement"
    case .archived:
        return "Supply archived"
    case .unarchived:
        return "Supply restored"
    }
}

private func consumableAdjustmentFallbackDetail(for kind: AtlasConsumableAdjustmentKind) -> String {
    switch kind {
    case .created:
        return "Atlas started tracking this supply locally."
    case .manualAdjustment:
        return "Supply count was corrected manually."
    case .procurement:
        return "Procurement was recorded for future supply planning."
    case .protocolUse:
        return "This supply moved after a taken log on the linked protocol."
    case .archived:
        return "This supply is archived for future planning."
    case .unarchived:
        return "This supply returned to active planning."
    }
}

private func buildConsumableProcurementHistory(
    adjustments: [AtlasConsumableAdjustmentRecord]
) -> [AtlasConsumableProcurementEntry] {
    adjustments
        .filter { $0.kind == .created || $0.kind == .procurement }
        .sorted {
            if $0.recordedAt == $1.recordedAt {
                return $0.id > $1.id
            }
            return $0.recordedAt > $1.recordedAt
        }
        .map { adjustment in
            AtlasConsumableProcurementEntry(
                id: adjustment.id,
                kind: adjustment.kind,
                title: adjustment.kind == .created ? "Opening stock" : "Procurement recorded",
                quantityLabel: formatInventoryCorrectionDelta(adjustment.deltaQuantity, unit: adjustment.quantityUnit),
                vendorLabel: adjustment.vendorLabel,
                sourceDetail: adjustment.sourceDetail,
                recordedAt: atlasDate(from: adjustment.recordedAt)
            )
        }
}

private func buildConsumablePlanningSnapshot(
    summary: AtlasConsumableSummary,
    procurementHistory: [AtlasConsumableProcurementEntry]
) -> AtlasConsumablePlanningSnapshot {
    AtlasConsumablePlanningSnapshot(
        procurementStatusLabel: summary.procurementStatusLabel,
        reorderThresholdLabel: summary.lowStockLabel,
        projectedDepletionLabel: summary.projectedDepletionLabel,
        reorderLeadTimeLabel: summary.reorderLeadTimeLabel,
        usageLabel: summary.usageLabel,
        lastProcurementLabel: summary.lastProcurementLabel,
        vendorHistorySummary: procurementVendorHistorySummary(procurementHistory: procurementHistory),
        needsProcurementReview: summary.needsProcurementReview
    )
}

private func buildConsumablePlanningSnapshot(
    consumable: AtlasConsumableRecord,
    lowStockLabel: String?,
    projectedDepletionLabel: String?,
    usageLabel: String?,
    reorderLeadTimeLabel: String?,
    projectedTargetDate: Date?,
    procurementHistory: [AtlasConsumableProcurementEntry],
    referenceDate: Date
) -> AtlasConsumablePlanningSnapshot {
    let reorderThresholdDate = projectedTargetDate
    let reviewDate: Date? = {
        guard let reorderThresholdDate,
              let leadTimeDays = consumable.reorderLeadTimeDays,
              leadTimeDays > 0 else {
            return nil
        }
        return Calendar.current.date(byAdding: .day, value: -leadTimeDays, to: reorderThresholdDate)
    }()
    let statusLabel: String?
    if consumable.archivedAt != nil {
        statusLabel = "Archived for future planning."
    } else if let reorderThresholdDate, reorderThresholdDate <= referenceDate || (consumable.reorderThreshold.map { consumable.quantityOnHand <= $0 } ?? false) {
        statusLabel = "Procurement review now."
    } else if let reviewDate {
        statusLabel = reviewDate <= referenceDate
            ? "Review procurement now."
            : "Review by \(inventoryMediumDateLabel(reviewDate))."
    } else if let reorderThresholdDate, consumable.reorderThreshold != nil {
        statusLabel = "Reorder point around \(inventoryMediumDateLabel(reorderThresholdDate))."
    } else {
        statusLabel = nil
    }

    let needsProcurementReview = consumable.archivedAt == nil && (
        (consumable.reorderThreshold.map { consumable.quantityOnHand <= $0 } ?? false)
        || ((reviewDate ?? reorderThresholdDate).map { $0 <= referenceDate } ?? false)
    )

    return AtlasConsumablePlanningSnapshot(
        procurementStatusLabel: statusLabel,
        reorderThresholdLabel: lowStockLabel,
        projectedDepletionLabel: projectedDepletionLabel,
        reorderLeadTimeLabel: reorderLeadTimeLabel,
        usageLabel: usageLabel,
        lastProcurementLabel: lastConsumableProcurementLabel(procurementHistory: procurementHistory),
        vendorHistorySummary: procurementVendorHistorySummary(procurementHistory: procurementHistory),
        needsProcurementReview: needsProcurementReview
    )
}

private func lastConsumableProcurementLabel(
    procurementHistory: [AtlasConsumableProcurementEntry]
) -> String? {
    guard let latest = procurementHistory.first else {
        return nil
    }
    let prefix = latest.kind == .created ? "Opening stock" : "Last procurement"
    return "\(prefix) \(inventoryMediumDateLabel(latest.recordedAt))"
}

private func procurementVendorHistorySummary(
    procurementHistory: [AtlasConsumableProcurementEntry]
) -> String? {
    guard procurementHistory.isEmpty == false else {
        return nil
    }

    let vendors = Set(
        procurementHistory
            .compactMap(\.vendorLabel)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    )
    if vendors.isEmpty {
        let count = procurementHistory.count
        return count == 1 ? "1 procurement entry recorded" : "\(count) procurement entries recorded"
    }
    let count = vendors.count
    return count == 1 ? "1 source recorded" : "\(count) sources recorded"
}

private func inventoryMediumDateLabel(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
}

private func inventoryCadenceDays(ruleType: AtlasProtocolRuleType?, intervalCount: Int?) -> Int? {
    guard let ruleType else {
        return nil
    }

    switch ruleType {
    case .weekly:
        return 7 * max(intervalCount ?? 1, 1)
    case .everyNDays:
        return max(intervalCount ?? 1, 1)
    case .daily:
        return 1
    }
}

private func inventoryDoseLabel(amount: Double?, unit: String?) -> String? {
    amount.flatMap { amount in
        unit.map { formatAtlasQuantity(amount, unit: $0) }
    }
}

private func inventoryKindLabel(_ kind: AtlasProtocolKind) -> String {
    switch kind {
    case .glp:
        return "GLP"
    case .peptide:
        return "Peptide"
    case .custom:
        return "Custom"
    }
}

private func inventoryCadenceLabel(
    ruleType: AtlasProtocolRuleType?,
    intervalCount: Int?,
    weekday: Int?,
    timeOfDay: String?
) -> String {
    guard let ruleType else {
        return "Cadence pending"
    }

    let timeLabel = inventoryTimeLabel(timeOfDay)
    switch ruleType {
    case .weekly:
        return "Every \(inventoryWeekdayLabel(weekday)) at \(timeLabel)"
    case .daily:
        return "Every day at \(timeLabel)"
    case .everyNDays:
        let interval = max(intervalCount ?? 1, 1)
        return "Every \(interval) day\(interval == 1 ? "" : "s") at \(timeLabel)"
    }
}

private func inventoryWeekdayLabel(_ weekday: Int?) -> String {
    let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    guard let weekday, days.indices.contains(weekday) else {
        return "day"
    }
    return days[weekday]
}

private func inventoryTimeLabel(_ value: String?) -> String {
    guard let value else {
        return "Time not set"
    }

    let components = value.split(separator: ":").compactMap { Int($0) }
    guard components.count >= 2 else {
        return value
    }

    var dateComponents = DateComponents()
    dateComponents.year = 2026
    dateComponents.month = 1
    dateComponents.day = 1
    dateComponents.hour = components[0]
    dateComponents.minute = components[1]
    let date = Calendar.current.date(from: dateComponents) ?? Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date)
}

private func inventoryEffectiveRevisionSlice(_ slices: [AtlasRevisionSlice], at date: Date) -> AtlasRevisionSlice? {
    slices.last(where: { slice in
        let start = atlasDate(from: slice.revision.effectiveFrom)
        let end = slice.revision.effectiveTo.map(atlasDate(from:))
        return start <= date && (end == nil || date < end!)
    }) ?? slices.last
}

private func findRevisionSlice(
    _ slices: [AtlasRevisionSlice],
    revisionID: String
) -> AtlasRevisionSlice? {
    slices.first(where: { $0.revision.id == revisionID })
}

private func inventoryActiveRule(slice: AtlasRevisionSlice, at date: Date) -> AtlasProtocolRevisionRuleRecord? {
    let anchorDate = atlasLocalDate(from: date)
    return slice.rules.first { rule in
        guard let start = rule.anchorDate else {
            return true
        }
        return start <= anchorDate
    } ?? slice.rules.first
}

private func atlasLocalDate(from date: Date) -> String {
    let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
    let year = components.year ?? 1970
    let month = components.month ?? 1
    let day = components.day ?? 1
    return String(format: "%04d-%02d-%02d", year, month, day)
}

private func normalizeInventoryUnit(_ value: String?) -> String {
    value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
}

private func formatInventoryCorrectionDelta(_ value: Double?, unit: String?) -> String {
    guard let value else {
        return "Inventory adjusted"
    }
    let prefix = value >= 0 ? "+" : ""
    return "\(prefix)\(formatAtlasQuantity(value, unit: unit))"
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
