import AtlasDomain
import AtlasPrivacy
import GRDB
import Foundation

private let atlasDayInterval: TimeInterval = 24 * 60 * 60
private let atlasDueWindow: TimeInterval = 2 * 60 * 60
private let atlasProjectionLookbackDays = 7
private let atlasProjectionHorizonDays = 30

private enum AtlasCoreLoopError: LocalizedError {
    case invalidProtocolName
    case protocolNotFound
    case occurrenceNotFound
    case missingRescheduleDate
    case occurrenceAlreadyResolved

    var errorDescription: String? {
        switch self {
        case .invalidProtocolName:
            return "Protocol name is required."
        case .protocolNotFound:
            return "The requested protocol could not be found."
        case .occurrenceNotFound:
            return "The requested occurrence could not be found."
        case .missingRescheduleDate:
            return "A new time is required to reschedule an occurrence."
        case .occurrenceAlreadyResolved:
            return "This occurrence has already been resolved."
        }
    }
}

struct AtlasRevisionSlice {
    var revision: AtlasProtocolRevisionRecord
    var rules: [AtlasProtocolRevisionRuleRecord]
}

struct AtlasCoreLoopContext {
    var protocols: [String: AtlasProtocolRecord]
    var aliases: [String: AtlasProtocolAliasRecord]
    var protocolRules: [String: [AtlasProtocolRuleRecord]]
    var revisionSlices: [String: [AtlasRevisionSlice]]
    var occurrencesByID: [String: AtlasOccurrenceProjectionRecord]
    var pendingOccurrences: [String: [AtlasOccurrenceProjectionRecord]]
    var remindersByOccurrenceID: [String: [AtlasReminderRecord]]
}

struct AtlasGeneratedOccurrence {
    var id: String
    var protocolId: String
    var scheduledAt: Date
    var cadenceLabel: String
    var doseLabel: String?
}

extension GRDBProtocolRepository {
    public func fetchProtocolDetail(id: String) async throws -> AtlasProtocolDetailSnapshot? {
        try await stack.canonical.read { db in
            try buildProtocolDetailSnapshot(db: db, protocolID: id, now: Date())
        }
    }

    public func createProtocol(_ draft: AtlasProtocolDraft, now: Date) async throws -> AtlasProtocolDetailSnapshot {
        try await stack.canonical.write { db in
            let normalized = try normalize(draft: draft)
            let timestamp = atlasTimestamp(from: now)
            let startDate = atlasLocalDateString(now)
            let protocolID = UUID().uuidString
            let ruleID = UUID().uuidString
            let revisionID = UUID().uuidString

            let protocolRecord = AtlasProtocolRecord.make(
                id: protocolID,
                compoundId: nil,
                linkedVialId: nil,
                name: normalized.name,
                kind: normalized.kind,
                administrationRoute: normalized.administrationRoute,
                supplyType: normalized.supplyType,
                dosesPerSupply: normalized.dosesPerSupply,
                status: .active,
                timezone: TimeZone.current.identifier,
                startDate: startDate,
                defaultTimeOfDay: normalized.defaultTimeOfDay,
                doseAmount: normalized.doseAmount,
                doseUnit: normalized.doseUnit,
                siteTrackingEnabled: false,
                siteRotationEnabled: false,
                notes: normalized.notes,
                createdAt: timestamp,
                updatedAt: timestamp
            )
            try AtlasProtocolDBRecord(record: protocolRecord).insert(db)

            let baseRule = AtlasProtocolRuleRecord.make(
                id: ruleID,
                protocolId: protocolID,
                ruleType: normalized.cadenceType,
                intervalCount: normalized.cadenceType == .weekly ? 1 : normalized.intervalDays,
                weekday: normalized.cadenceType == .weekly ? normalized.weekday : nil,
                timeOfDay: normalized.defaultTimeOfDay,
                anchorDate: startDate,
                isActive: true,
                createdAt: timestamp,
                updatedAt: timestamp
            )
            try AtlasProtocolRuleDBRecord(record: baseRule).insert(db)

            let revision = AtlasProtocolRevisionRecord(
                id: revisionID,
                protocolId: protocolID,
                revisionNumber: 1,
                previousRevisionId: nil,
                effectiveFrom: atlasDayStartTimestamp(startDate),
                effectiveTo: nil,
                lifecycleState: .active,
                timezone: protocolRecord.timezone,
                timezoneStrategy: .keepLocalClock,
                administrationRoute: normalized.administrationRoute,
                supplyType: normalized.supplyType,
                dosesPerSupply: normalized.dosesPerSupply,
                defaultTimeOfDay: normalized.defaultTimeOfDay,
                doseAmount: normalized.doseAmount,
                doseUnit: normalized.doseUnit,
                linkedVialId: nil,
                missedDosePolicy: .skipAndContinue,
                notes: normalized.notes,
                createdAt: timestamp,
                updatedAt: timestamp
            )
            try AtlasProtocolRevisionDBRecord(record: revision).insert(db)

            let revisionRule = AtlasProtocolRevisionRuleRecord(
                id: UUID().uuidString,
                revisionId: revisionID,
                phaseType: .base,
                phaseOrder: 0,
                ruleType: normalized.cadenceType,
                intervalCount: normalized.cadenceType == .weekly ? 1 : normalized.intervalDays,
                weekday: normalized.cadenceType == .weekly ? normalized.weekday : nil,
                timeOfDay: normalized.defaultTimeOfDay,
                anchorDate: startDate,
                phaseStartDayOffset: 0,
                phaseLengthDays: nil,
                doseAmountOverride: nil,
                doseUnitOverride: nil,
                createdAt: timestamp,
                updatedAt: timestamp
            )
            try AtlasProtocolRevisionRuleDBRecord(record: revisionRule).insert(db)

            try regenerateFutureOccurrences(
                db: db,
                protocolIDs: [protocolID],
                referenceDate: now,
                preserveManualReschedules: false
            )

            guard let detail = try buildProtocolDetailSnapshot(db: db, protocolID: protocolID, now: now) else {
                throw AtlasCoreLoopError.protocolNotFound
            }
            return detail
        }
    }

    public func updateProtocol(id: String, draft: AtlasProtocolDraft, now: Date) async throws -> AtlasProtocolDetailSnapshot {
        try await stack.canonical.write { db in
            let normalized = try normalize(draft: draft)
            let timestamp = atlasTimestamp(from: now)

            guard var protocolRecord = try AtlasProtocolDBRecord.fetchOne(db, key: id)?.domain else {
                throw AtlasCoreLoopError.protocolNotFound
            }

            let currentRevisionRows = try AtlasProtocolRevisionDBRecord
                .filter(Column("protocol_id") == id)
                .order(Column("revision_number").desc)
                .fetchAll(db)
                .map(\.domain)
            let currentRevision = currentRevisionRows.first(where: { $0.effectiveTo == nil }) ?? currentRevisionRows.first
            let nextRevisionNumber = (currentRevisionRows.map(\.revisionNumber).max() ?? 0) + 1

            try db.execute(
                sql: "UPDATE protocol_rules SET is_active = 0, updated_at = ? WHERE protocol_id = ?",
                arguments: [timestamp, id]
            )

            let baseRule = AtlasProtocolRuleRecord.make(
                id: UUID().uuidString,
                protocolId: id,
                ruleType: normalized.cadenceType,
                intervalCount: normalized.cadenceType == .weekly ? 1 : normalized.intervalDays,
                weekday: normalized.cadenceType == .weekly ? normalized.weekday : nil,
                timeOfDay: normalized.defaultTimeOfDay,
                anchorDate: protocolRecord.startDate,
                isActive: true,
                createdAt: timestamp,
                updatedAt: timestamp
            )
            try AtlasProtocolRuleDBRecord(record: baseRule).insert(db)

            protocolRecord.name = normalized.name
            protocolRecord.kind = normalized.kind
            protocolRecord.administrationRoute = normalized.administrationRoute
            protocolRecord.supplyType = normalized.supplyType
            protocolRecord.dosesPerSupply = normalized.dosesPerSupply
            protocolRecord.defaultTimeOfDay = normalized.defaultTimeOfDay
            protocolRecord.doseAmount = normalized.doseAmount
            protocolRecord.doseUnit = normalized.doseUnit
            protocolRecord.notes = normalized.notes
            protocolRecord.updatedAt = timestamp
            try AtlasProtocolDBRecord(record: protocolRecord).update(db)

            if var currentRevision {
                currentRevision.effectiveTo = timestamp
                currentRevision.updatedAt = timestamp
                try AtlasProtocolRevisionDBRecord(record: currentRevision).update(db)
            }

            let newRevisionID = UUID().uuidString
            let newRevision = AtlasProtocolRevisionRecord(
                id: newRevisionID,
                protocolId: id,
                revisionNumber: nextRevisionNumber,
                previousRevisionId: currentRevision?.id,
                effectiveFrom: timestamp,
                effectiveTo: nil,
                lifecycleState: .active,
                timezone: protocolRecord.timezone,
                timezoneStrategy: .keepLocalClock,
                administrationRoute: normalized.administrationRoute,
                supplyType: normalized.supplyType,
                dosesPerSupply: normalized.dosesPerSupply,
                defaultTimeOfDay: normalized.defaultTimeOfDay,
                doseAmount: normalized.doseAmount,
                doseUnit: normalized.doseUnit,
                linkedVialId: protocolRecord.linkedVialId,
                missedDosePolicy: .skipAndContinue,
                notes: normalized.notes,
                createdAt: timestamp,
                updatedAt: timestamp
            )
            try AtlasProtocolRevisionDBRecord(record: newRevision).insert(db)

            let newRevisionRule = AtlasProtocolRevisionRuleRecord(
                id: UUID().uuidString,
                revisionId: newRevisionID,
                phaseType: .base,
                phaseOrder: 0,
                ruleType: normalized.cadenceType,
                intervalCount: normalized.cadenceType == .weekly ? 1 : normalized.intervalDays,
                weekday: normalized.cadenceType == .weekly ? normalized.weekday : nil,
                timeOfDay: normalized.defaultTimeOfDay,
                anchorDate: protocolRecord.startDate,
                phaseStartDayOffset: 0,
                phaseLengthDays: nil,
                doseAmountOverride: nil,
                doseUnitOverride: nil,
                createdAt: timestamp,
                updatedAt: timestamp
            )
            try AtlasProtocolRevisionRuleDBRecord(record: newRevisionRule).insert(db)

            let changeType = determineChangeType(previous: currentRevision, draft: normalized)
            let audit = AtlasProtocolChangeAuditRecord.make(
                id: UUID().uuidString,
                protocolId: id,
                revisionId: newRevisionID,
                previousRevisionId: currentRevision?.id,
                changeType: changeType,
                effectiveFrom: timestamp,
                summary: "Core fields updated in native iOS",
                payloadJson: "{}",
                createdAt: timestamp
            )
            try AtlasProtocolChangeAuditDBRecord(record: audit).insert(db)

            try regenerateFutureOccurrences(
                db: db,
                protocolIDs: [id],
                referenceDate: now,
                preserveManualReschedules: false
            )

            guard let detail = try buildProtocolDetailSnapshot(db: db, protocolID: id, now: now) else {
                throw AtlasCoreLoopError.protocolNotFound
            }
            return detail
        }
    }
}

extension GRDBTodayRepository {
    public func fetchTodaySnapshot(referenceDate: Date) async throws -> AtlasTodaySnapshot {
        try await stack.canonical.read { db in
            let context = try loadCoreLoopContext(db: db)
            let pending = context.pendingOccurrences.values
                .flatMap { $0 }
                .map { occurrence in
                    buildScheduledOccurrence(
                        occurrence: occurrence,
                        context: context,
                        now: referenceDate
                    )
                }
                .sorted { $0.scheduledAt < $1.scheduledAt }

            let overdue = pending.filter { $0.state == .overdue }
            let dueAndUpcoming = pending.filter { $0.state == .due || $0.state == .upcoming }
            let nextDue = dueAndUpcoming.first
            let upcoming = Array(dueAndUpcoming.dropFirst().prefix(8))

            return AtlasTodaySnapshot(
                hasProtocols: context.protocols.values.contains(where: { $0.status == .active }),
                nextDue: nextDue,
                overdue: overdue,
                upcoming: upcoming
            )
        }
    }
}

extension GRDBTimelineRepository {
    public func fetchTimeline(_ query: AtlasTimelineQuery) async throws -> [AtlasTimelineEntry] {
        try await stack.canonical.read { db in
            let context = try loadCoreLoopContext(db: db)
            let renderMode = privacyFormatter.renderMode(
                for: try AtlasPrivacyProfileDBRecord.fetchOne(db)?.domain ?? .default()
            )

            var entries: [AtlasTimelineEntry] = []
            let logs = try AtlasLogEventDBRecord
                .order(Column("logged_at").desc)
                .fetchAll(db)
                .map(\.domain)
            let weightLogs = try AtlasWeightLogDBRecord
                .order(Column("logged_at").desc)
                .fetchAll(db)
                .map(\.domain)
            let contextLogs = try AtlasContextLogDBRecord
                .order(Column("logged_at").desc)
                .fetchAll(db)
                .map(\.domain)
            let symptomLogs = try AtlasSymptomLogDBRecord
                .order(Column("logged_at").desc)
                .fetchAll(db)
                .map(\.domain)
            let metricLogs = try AtlasMetricValueLogDBRecord
                .order(Column("logged_at").desc)
                .fetchAll(db)
                .map(\.domain)
            let metricsByID = Dictionary(
                uniqueKeysWithValues: try AtlasCustomMetricDBRecord.fetchAll(db).map { ($0.id, $0.domain) }
            )
            let audits = try AtlasProtocolChangeAuditDBRecord
                .order(Column("created_at").desc)
                .fetchAll(db)
                .map(\.domain)

            for protocolRecord in context.protocols.values {
                guard query.protocolID == nil || query.protocolID == protocolRecord.id else {
                    continue
                }
                let alias = context.aliases[protocolRecord.id]?.aliasLabel
                entries.append(
                    AtlasTimelineEntry(
                        id: "created:\(protocolRecord.id)",
                        protocolID: protocolRecord.id,
                        canonicalTitle: protocolRecord.name,
                        aliasTitle: alias,
                        type: .protocolCreated,
                        summary: privacyFormatter.protocolCreatedSummary(
                            canonical: protocolRecord.name,
                            alias: alias,
                            mode: renderMode
                        ),
                        recordedAt: atlasDate(from: protocolRecord.createdAt)
                    )
                )
            }

            for audit in audits {
                guard query.protocolID == nil || query.protocolID == audit.protocolId else {
                    continue
                }
                guard let protocolRecord = context.protocols[audit.protocolId] else {
                    continue
                }
                let alias = context.aliases[audit.protocolId]?.aliasLabel
                entries.append(
                    AtlasTimelineEntry(
                        id: "edited:\(audit.id)",
                        protocolID: audit.protocolId,
                        canonicalTitle: protocolRecord.name,
                        aliasTitle: alias,
                        type: .protocolEdited,
                        summary: privacyFormatter.protocolChangeAuditSummary(
                            canonical: protocolRecord.name,
                            alias: alias,
                            auditSummary: audit.summary,
                            mode: renderMode
                        ),
                        recordedAt: atlasDate(from: audit.createdAt),
                        changeExplanation: buildProtocolChangeExplanation(
                            audit: audit,
                            context: context,
                            renderMode: renderMode,
                            privacyFormatter: privacyFormatter
                        )
                    )
                )
            }

            for log in logs {
                guard query.protocolID == nil || query.protocolID == log.protocolId else {
                    continue
                }
                guard let protocolRecord = context.protocols[log.protocolId] else {
                    continue
                }
                let alias = context.aliases[log.protocolId]?.aliasLabel
                let type: AtlasTimelineEntryType

                switch log.eventType {
                case .completed, .manualLog:
                    type = .doseTaken
                case .skipped:
                    type = .doseSkipped
                case .rescheduled:
                    type = .doseRescheduled
                case .inventoryAdjustment:
                    continue
                }

                entries.append(
                    AtlasTimelineEntry(
                        id: log.id,
                        protocolID: log.protocolId,
                        canonicalTitle: protocolRecord.name,
                        aliasTitle: alias,
                        type: type,
                        summary: privacyFormatter.timelineSummary(
                            eventType: log.eventType,
                            canonical: protocolRecord.name,
                            alias: alias,
                            mode: renderMode
                        ),
                        recordedAt: atlasDate(from: log.loggedAt),
                        occurrenceExplanation: log.occurrenceId.flatMap { occurrenceID in
                            context.occurrencesByID[occurrenceID].map { occurrence in
                                buildOccurrenceExplanation(
                                    occurrence: occurrence,
                                    protocolRecord: protocolRecord,
                                    context: context,
                                    now: atlasDate(from: log.loggedAt)
                                )
                            }
                        }
                    )
                )
            }

            for log in weightLogs {
                entries.append(
                    AtlasTimelineEntry(
                        id: "weight:\(log.id)",
                        protocolID: "insights",
                        canonicalTitle: "Weight",
                        aliasTitle: nil,
                        type: .weightLogged,
                        summary: privacyFormatter.weightTimelineSummary(mode: renderMode),
                        recordedAt: atlasDate(from: log.loggedAt)
                    )
                )
            }

            for log in contextLogs {
                guard query.protocolID == nil || query.protocolID == log.protocolId else {
                    continue
                }
                let protocolRecord = log.protocolId.flatMap { context.protocols[$0] }
                let alias = log.protocolId.flatMap { context.aliases[$0]?.aliasLabel }
                entries.append(
                    AtlasTimelineEntry(
                        id: "context:\(log.id)",
                        protocolID: log.protocolId ?? "insights",
                        canonicalTitle: protocolRecord?.name ?? "Context",
                        aliasTitle: alias,
                        type: .contextLogged,
                        summary: privacyFormatter.contextTimelineSummary(
                            mealTiming: log.mealTiming,
                            mealSize: log.mealSize,
                            mealComposition: log.mealComposition,
                            fedState: log.fedState,
                            appetite: log.appetite,
                            hydration: log.hydration,
                            giTags: log.giTags,
                            mode: renderMode
                        ),
                        recordedAt: atlasDate(from: log.loggedAt)
                    )
                )
            }

            for log in symptomLogs {
                entries.append(
                    AtlasTimelineEntry(
                        id: "symptom:\(log.id)",
                        protocolID: "insights",
                        canonicalTitle: log.symptomKey,
                        aliasTitle: nil,
                        type: .symptomLogged,
                        summary: privacyFormatter.symptomTimelineSummary(
                            symptomKey: log.symptomKey,
                            mode: renderMode
                        ),
                        recordedAt: atlasDate(from: log.loggedAt)
                    )
                )
            }

            for log in metricLogs {
                guard let metric = metricsByID[log.metricId] else {
                    continue
                }
                let protocolID = log.protocolId ?? metric.protocolId ?? "insights"
                let protocolRecord = context.protocols[protocolID]
                let alias = context.aliases[protocolID]?.aliasLabel
                entries.append(
                    AtlasTimelineEntry(
                        id: "metric:\(log.id)",
                        protocolID: protocolID,
                        canonicalTitle: metric.label,
                        aliasTitle: alias,
                        type: .customMetricLogged,
                        summary: privacyFormatter.metricTimelineSummary(
                            metricLabel: metric.label,
                            canonicalProtocol: protocolRecord?.name,
                            aliasProtocol: alias,
                            mode: renderMode
                        ),
                        recordedAt: atlasDate(from: log.loggedAt)
                    )
                )
            }

            return entries
                .filter { entry in
                    switch query.filter {
                    case .all:
                        return true
                    case .dosing:
                        return entry.type == .doseTaken || entry.type == .doseSkipped || entry.type == .doseRescheduled
                    case .changes:
                        return entry.type == .protocolCreated || entry.type == .protocolEdited
                    case .wellness:
                        return entry.type == .weightLogged
                            || entry.type == .contextLogged
                            || entry.type == .symptomLogged
                            || entry.type == .customMetricLogged
                    }
                }
                .sorted { $0.recordedAt > $1.recordedAt }
                .prefix(query.limit)
                .map { $0 }
        }
    }
}

public struct GRDBCoreLoopRepository: CoreLoopRepository, Sendable {
    let stack: AtlasDatabaseStack

    init(stack: AtlasDatabaseStack) {
        self.stack = stack
    }

    public func ensureProjectedOccurrences(referenceDate: Date) async throws {
        try await stack.canonical.write { db in
            let context = try loadCoreLoopContext(db: db)
            let activeProtocolIDs = Set(
                context.protocols.values.compactMap { protocolRecord in
                    hasSchedulableOccurrences(
                        protocolRecord: protocolRecord,
                        revisionSlices: context.revisionSlices[protocolRecord.id] ?? [],
                        fallbackRules: context.protocolRules[protocolRecord.id] ?? []
                    ) ? protocolRecord.id : nil
                }
            )
            guard activeProtocolIDs.isEmpty == false else {
                return
            }

            // Occurrence projections are a rebuildable cache. Always refresh them for the
            // requested reference date so imports/restores can't strand the app on a stale horizon.
            try regenerateFutureOccurrences(
                db: db,
                protocolIDs: Array(activeProtocolIDs),
                referenceDate: referenceDate,
                preserveManualReschedules: true
            )
        }
    }

    public func logOccurrence(_ request: AtlasOccurrenceLogRequest, now: Date) async throws {
        try await stack.canonical.write { db in
            guard var occurrence = try AtlasOccurrenceProjectionDBRecord.fetchOne(db, key: request.occurrenceID)?.domain else {
                throw AtlasCoreLoopError.occurrenceNotFound
            }
            guard occurrence.state == .upcoming || occurrence.state == .due || occurrence.state == .missed else {
                throw AtlasCoreLoopError.occurrenceAlreadyResolved
            }

            let timestamp = atlasTimestamp(from: now)
            let eventType: AtlasLogEventType
            let effectiveAt: String
            let context = try loadCoreLoopContext(db: db)
            let protocolRecord = try AtlasProtocolDBRecord.fetchOne(db, key: request.protocolID)?.domain

            switch request.action {
            case .taken:
                eventType = .completed
                occurrence.state = .completed
                effectiveAt = occurrence.scheduledAt
            case .skipped:
                eventType = .skipped
                occurrence.state = .skipped
                effectiveAt = occurrence.scheduledAt
            case .rescheduled:
                guard let rescheduledAt = request.rescheduledAt else {
                    throw AtlasCoreLoopError.missingRescheduleDate
                }
                eventType = .rescheduled
                occurrence.state = .superseded
                effectiveAt = atlasTimestamp(from: rescheduledAt)
            }

            occurrence.updatedAt = timestamp
            try AtlasOccurrenceProjectionDBRecord(record: occurrence).update(db)

            let linkedVialID = activeLinkedVialID(
                protocolID: request.protocolID,
                context: context,
                scheduledAt: atlasDate(from: effectiveAt),
                fallback: protocolRecord?.linkedVialId
            )
            let loggedSiteID = request.action == .taken ? request.siteID : nil
            let logEvent = AtlasLogEventRecord.make(
                id: UUID().uuidString,
                protocolId: request.protocolID,
                vialId: request.action == .taken ? linkedVialID : nil,
                siteId: loggedSiteID,
                occurrenceId: request.occurrenceID,
                eventType: eventType,
                effectiveAt: effectiveAt,
                loggedAt: timestamp,
                quantity: protocolRecord?.doseAmount,
                quantityUnit: protocolRecord?.doseUnit,
                notes: request.note,
                source: .user
            )
            try AtlasLogEventDBRecord(record: logEvent).insert(db)

            if request.action == .taken,
               let protocolRecord,
               let linkedVialID,
               var vial = try AtlasVialDBRecord.fetchOne(db, key: linkedVialID)?.domain,
               let decrement = occurrenceVialDecrement(
                    protocolRecord: protocolRecord,
                    context: context,
                    scheduledAt: atlasDate(from: effectiveAt),
                    vial: vial
               ) {
                vial.remainingQuantity = max(vial.remainingQuantity - decrement.amount, 0)
                vial.updatedAt = timestamp
                try AtlasVialDBRecord(record: vial).update(db)
            }

            if request.action == .taken {
                let consumables = try AtlasConsumableDBRecord
                    .filter(Column("protocol_id") == request.protocolID && Column("archived_at") == nil)
                    .fetchAll(db)
                    .map(\.domain)

                for var consumable in consumables {
                    guard let quantityPerUse = consumable.quantityPerUse, quantityPerUse > 0 else {
                        continue
                    }

                    consumable.quantityOnHand = max(consumable.quantityOnHand - quantityPerUse, 0)
                    consumable.updatedAt = timestamp
                    try AtlasConsumableDBRecord(record: consumable).update(db)
                    try appendConsumableAdjustment(
                        db: db,
                        consumable: consumable,
                        protocolID: request.protocolID,
                        occurrenceID: request.occurrenceID,
                        kind: .protocolUse,
                        deltaQuantity: -quantityPerUse,
                        note: "Linked taken log updated this supply count.",
                        recordedAt: timestamp
                    )
                }
            }

            if request.action == .rescheduled, let rescheduledAt = request.rescheduledAt {
                let replacement = AtlasOccurrenceProjectionRecord.make(
                    id: "manual:\(UUID().uuidString)",
                    protocolId: request.protocolID,
                    reminderId: nil,
                    scheduledAt: atlasTimestamp(from: rescheduledAt),
                    state: .upcoming,
                    createdAt: timestamp,
                    updatedAt: timestamp
                )
                try AtlasOccurrenceProjectionDBRecord(record: replacement).insert(db)
            }
        }
    }
}

func occurrenceVialDecrement(
    protocolRecord: AtlasProtocolRecord,
    context: AtlasCoreLoopContext,
    scheduledAt: Date,
    vial: AtlasVialRecord
) -> (amount: Double, unit: String)? {
    let slice = effectiveRevisionSlice(context.revisionSlices[protocolRecord.id] ?? [], at: scheduledAt)
    let rule = slice.flatMap { activeRuleForDate(slice: $0, at: scheduledAt) }
    let doseAmount = rule?.doseAmountOverride ?? slice?.revision.doseAmount ?? protocolRecord.doseAmount
    let doseUnit = rule?.doseUnitOverride ?? slice?.revision.doseUnit ?? protocolRecord.doseUnit
    guard let doseAmount, let doseUnit else {
        return nil
    }

    let vialUnit = (vial.quantityUnit).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let normalizedDoseUnit = doseUnit.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    if vialUnit == "dose" {
        return (1, vial.quantityUnit)
    }

    if vialUnit == normalizedDoseUnit {
        return (doseAmount, vial.quantityUnit)
    }

    if vialUnit == "ml",
       let concentrationValue = vial.concentrationValue,
       concentrationValue > 0,
       let concentrationUnit = vial.concentrationUnit?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
       concentrationUnit == normalizedDoseUnit {
        return (doseAmount / concentrationValue, vial.quantityUnit)
    }

    return nil
}

private func activeLinkedVialID(
    protocolID: String,
    context: AtlasCoreLoopContext,
    scheduledAt: Date,
    fallback: String?
) -> String? {
    let slice = effectiveRevisionSlice(context.revisionSlices[protocolID] ?? [], at: scheduledAt)
    return slice?.revision.linkedVialId ?? fallback
}

private func normalize(draft: AtlasProtocolDraft) throws -> AtlasProtocolDraft {
    let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard name.isEmpty == false else {
        throw AtlasCoreLoopError.invalidProtocolName
    }

    let doseUnit = draft.doseUnit?.trimmingCharacters(in: .whitespacesAndNewlines)
    let notes = draft.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
    let defaultTime = draft.defaultTimeOfDay?.trimmingCharacters(in: .whitespacesAndNewlines)
    let intervalDays = max(draft.intervalDays, 1)

    return AtlasProtocolDraft(
        name: name,
        kind: draft.kind,
        administrationRoute: draft.administrationRoute,
        supplyType: draft.supplyType,
        dosesPerSupply: draft.dosesPerSupply.flatMap { $0 > 0 ? $0 : nil },
        cadenceType: draft.cadenceType,
        intervalDays: intervalDays,
        weekday: draft.cadenceType == .weekly ? draft.weekday : nil,
        defaultTimeOfDay: defaultTime?.isEmpty == true ? nil : defaultTime,
        doseAmount: draft.doseAmount,
        doseUnit: doseUnit?.isEmpty == true ? nil : doseUnit,
        notes: notes?.isEmpty == true ? nil : notes
    )
}

private func determineChangeType(
    previous: AtlasProtocolRevisionRecord?,
    draft: AtlasProtocolDraft
) -> AtlasProtocolChangeAuditType {
    guard let previous else {
        return .futureDoseChanged
    }

    if previous.defaultTimeOfDay != draft.defaultTimeOfDay {
        return .timeChanged
    }

    if previous.doseAmount != draft.doseAmount || previous.doseUnit != draft.doseUnit {
        return .futureDoseChanged
    }

    return .cadenceChanged
}

func loadCoreLoopContext(db: Database) throws -> AtlasCoreLoopContext {
    let protocols = try AtlasProtocolDBRecord.fetchAll(db).map(\.domain)
    let aliases = try AtlasProtocolAliasDBRecord.fetchAll(db).map(\.domain)
    let rules = try AtlasProtocolRuleDBRecord.fetchAll(db).map(\.domain)
    let revisions = try AtlasProtocolRevisionDBRecord.fetchAll(db).map(\.domain)
    let revisionRules = try AtlasProtocolRevisionRuleDBRecord.fetchAll(db).map(\.domain)
    let reminders = try AtlasReminderDBRecord.fetchAll(db).map(\.domain)
    let allOccurrences = try AtlasOccurrenceProjectionDBRecord.fetchAll(db).map(\.domain)
    let pendingStates: [String] = [
        AtlasOccurrenceState.upcoming.rawValue,
        AtlasOccurrenceState.due.rawValue,
        AtlasOccurrenceState.missed.rawValue
    ]
    let pendingOccurrences = allOccurrences.filter { pendingStates.contains($0.state.rawValue) }

    let revisionRulesByRevisionID = Dictionary(grouping: revisionRules, by: \.revisionId)
    let revisionSlices = Dictionary(grouping: revisions, by: \.protocolId).mapValues { revisions in
        revisions
            .sorted { left, right in
                let leftDate = atlasDate(from: left.effectiveFrom)
                let rightDate = atlasDate(from: right.effectiveFrom)
                if leftDate == rightDate {
                    return left.revisionNumber < right.revisionNumber
                }
                return leftDate < rightDate
            }
            .map { revision in
                AtlasRevisionSlice(
                    revision: revision,
                    rules: (revisionRulesByRevisionID[revision.id] ?? [])
                        .sorted { $0.phaseOrder < $1.phaseOrder }
                )
            }
    }

    return AtlasCoreLoopContext(
        protocols: Dictionary(uniqueKeysWithValues: protocols.map { ($0.id, $0) }),
        aliases: Dictionary(uniqueKeysWithValues: aliases.map { ($0.protocolId, $0) }),
        protocolRules: Dictionary(grouping: rules, by: \.protocolId),
        revisionSlices: revisionSlices,
        occurrencesByID: Dictionary(uniqueKeysWithValues: allOccurrences.map { ($0.id, $0) }),
        pendingOccurrences: Dictionary(grouping: pendingOccurrences, by: \.protocolId),
        remindersByOccurrenceID: Dictionary(grouping: reminders, by: \.occurrenceId)
    )
}

func buildProtocolSummary(
    protocolRecord: AtlasProtocolRecord,
    alias: AtlasProtocolAliasRecord?,
    protocolRules: [AtlasProtocolRuleRecord],
    revisionSlices: [AtlasRevisionSlice],
    pendingOccurrences: [AtlasOccurrenceProjectionRecord],
    now: Date
) -> ProtocolSummary {
    let compoundKnowledge = AtlasCompoundKnowledgeCatalog.resolve(
        protocolName: protocolRecord.name,
        kind: protocolRecord.kind
    )
    let activeSlice = effectiveRevisionSlice(revisionSlices, at: now)
    let activeRule = activeSlice.flatMap { activeRuleForDate(slice: $0, at: now) }
    let baseRule = protocolRules.first(where: \.isActive) ?? protocolRules.first
    let cadence = formatCadenceLabel(
        ruleType: activeRule?.ruleType ?? baseRule?.ruleType,
        intervalCount: activeRule?.intervalCount ?? baseRule?.intervalCount,
        weekday: activeRule?.weekday ?? baseRule?.weekday,
        timeOfDay: activeRule?.timeOfDay ?? activeSlice?.revision.defaultTimeOfDay ?? protocolRecord.defaultTimeOfDay
    )
    let doseAmount = activeRule?.doseAmountOverride ?? activeSlice?.revision.doseAmount ?? protocolRecord.doseAmount
    let doseUnit = activeRule?.doseUnitOverride ?? activeSlice?.revision.doseUnit ?? protocolRecord.doseUnit
    let nextDueLabel = pendingOccurrences
        .sorted { atlasDate(from: $0.scheduledAt) < atlasDate(from: $1.scheduledAt) }
        .first
        .map { relativeDueLabel(for: atlasDate(from: $0.scheduledAt)) }

    return ProtocolSummary(
        id: protocolRecord.id,
        canonicalTitle: protocolRecord.name,
        aliasTitle: alias?.aliasLabel,
        protocolKind: protocolRecord.kind,
        kindLabel: kindLabel(protocolRecord.kind),
        cadenceLabel: cadence,
        doseLabel: doseAmount.flatMap { amount in doseUnit.map { "\(amount.cleanAtlasNumber) \($0)" } },
        nextDueLabel: nextDueLabel,
        status: protocolRecord.status,
        compoundKnowledge: compoundKnowledge
    )
}

private func buildProtocolDetailSnapshot(
    db: Database,
    protocolID: String,
    now: Date
) throws -> AtlasProtocolDetailSnapshot? {
    let context = try loadCoreLoopContext(db: db)
    let renderMode = AtlasPrivacyFormatter().renderMode(
        for: try AtlasPrivacyProfileDBRecord.fetchOne(db)?.domain ?? .default()
    )
    guard let protocolRecord = context.protocols[protocolID] else {
        return nil
    }

    let revisionSlices = context.revisionSlices[protocolID] ?? []
    let activeSlice = effectiveRevisionSlice(revisionSlices, at: now)
    let activeRule = activeSlice.flatMap { activeRuleForDate(slice: $0, at: now) }
    let baseRule = (context.protocolRules[protocolID] ?? []).first(where: \.isActive) ?? context.protocolRules[protocolID]?.first
    let cadence = formatCadenceLabel(
        ruleType: activeRule?.ruleType ?? baseRule?.ruleType,
        intervalCount: activeRule?.intervalCount ?? baseRule?.intervalCount,
        weekday: activeRule?.weekday ?? baseRule?.weekday,
        timeOfDay: activeRule?.timeOfDay ?? activeSlice?.revision.defaultTimeOfDay ?? protocolRecord.defaultTimeOfDay
    )
    let doseAmount = activeRule?.doseAmountOverride ?? activeSlice?.revision.doseAmount ?? protocolRecord.doseAmount
    let doseUnit = activeRule?.doseUnitOverride ?? activeSlice?.revision.doseUnit ?? protocolRecord.doseUnit
    let nextOccurrenceRecord = (context.pendingOccurrences[protocolID] ?? [])
        .sorted { atlasDate(from: $0.scheduledAt) < atlasDate(from: $1.scheduledAt) }
        .first
    let nextOccurrence = nextOccurrenceRecord.map {
        buildScheduledOccurrence(occurrence: $0, context: context, now: now)
    }
    let compoundKnowledge = AtlasCompoundKnowledgeCatalog.resolve(
        protocolName: protocolRecord.name,
        kind: protocolRecord.kind
    )
    let logEvents = try AtlasLogEventDBRecord
        .filter(Column("protocol_id") == protocolID)
        .order(Column("effective_at").asc)
        .fetchAll(db)
        .map(\.domain)
    let medicationLevel = buildMedicationLevelEstimateItem(
        protocolRecord: protocolRecord,
        aliasTitle: context.aliases[protocolID]?.aliasLabel,
        revisionSlices: revisionSlices,
        logEvents: logEvents,
        now: now
    )

    let draft = AtlasProtocolDraft(
        name: protocolRecord.name,
        kind: protocolRecord.kind,
        administrationRoute: activeSlice?.revision.administrationRoute ?? protocolRecord.administrationRoute ?? .injection,
        supplyType: activeSlice?.revision.supplyType ?? protocolRecord.supplyType,
        dosesPerSupply: activeSlice?.revision.dosesPerSupply ?? protocolRecord.dosesPerSupply,
        cadenceType: activeRule?.ruleType ?? baseRule?.ruleType ?? .weekly,
        intervalDays: activeRule?.intervalCount ?? baseRule?.intervalCount ?? 1,
        weekday: activeRule?.weekday ?? baseRule?.weekday,
        defaultTimeOfDay: activeRule?.timeOfDay ?? activeSlice?.revision.defaultTimeOfDay ?? protocolRecord.defaultTimeOfDay,
        doseAmount: doseAmount,
        doseUnit: doseUnit,
        notes: activeSlice?.revision.notes ?? protocolRecord.notes
    )

    return AtlasProtocolDetailSnapshot(
        id: protocolRecord.id,
        canonicalTitle: protocolRecord.name,
        aliasTitle: context.aliases[protocolID]?.aliasLabel,
        status: protocolRecord.status,
        protocolKind: protocolRecord.kind,
        kindLabel: kindLabel(protocolRecord.kind),
        administrationLabel: administrationRouteLabel(activeSlice?.revision.administrationRoute ?? protocolRecord.administrationRoute),
        supplyLabel: supplyTypeLabel(
            activeSlice?.revision.supplyType ?? protocolRecord.supplyType,
            dosesPerSupply: activeSlice?.revision.dosesPerSupply ?? protocolRecord.dosesPerSupply
        ),
        cadenceLabel: cadence,
        doseLabel: doseAmount.flatMap { amount in doseUnit.map { "\(amount.cleanAtlasNumber) \($0)" } },
        notes: activeSlice?.revision.notes ?? protocolRecord.notes,
        compoundKnowledge: compoundKnowledge,
        medicationLevel: medicationLevel,
        editableDraft: draft,
        nextOccurrence: nextOccurrence,
        recentChanges: try AtlasProtocolChangeAuditDBRecord
            .filter(Column("protocol_id") == protocolID)
            .order(Column("created_at").desc)
            .limit(6)
            .fetchAll(db)
            .map(\.domain)
            .map {
                buildProtocolChangeExplanation(
                    audit: $0,
                    context: context,
                    renderMode: renderMode,
                    privacyFormatter: AtlasPrivacyFormatter()
                )
            }
    )
}

func buildScheduledOccurrence(
    occurrence: AtlasOccurrenceProjectionRecord,
    context: AtlasCoreLoopContext,
    now: Date
) -> AtlasScheduledOccurrence {
    let protocolRecord = context.protocols[occurrence.protocolId] ?? AtlasProtocolRecord.make(
        id: occurrence.protocolId,
        compoundId: nil,
        linkedVialId: nil,
        name: "Atlas protocol",
        kind: .custom,
        status: .active,
        timezone: TimeZone.current.identifier,
        startDate: atlasLocalDateString(now),
        defaultTimeOfDay: nil,
        doseAmount: nil,
        doseUnit: nil,
        siteTrackingEnabled: false,
        siteRotationEnabled: false,
        notes: nil,
        createdAt: atlasTimestamp(from: now),
        updatedAt: atlasTimestamp(from: now)
    )
    let alias = context.aliases[occurrence.protocolId]?.aliasLabel
    let scheduledDate = atlasDate(from: occurrence.scheduledAt)
    let slice = effectiveRevisionSlice(context.revisionSlices[occurrence.protocolId] ?? [], at: scheduledDate)
    let rule = slice.flatMap { ruleForOccurrence(slice: $0, occurrenceID: occurrence.id, scheduledAt: scheduledDate) }
    let baseRule = (context.protocolRules[occurrence.protocolId] ?? []).first(where: \.isActive) ?? context.protocolRules[occurrence.protocolId]?.first
    let cadence = formatCadenceLabel(
        ruleType: rule?.ruleType ?? baseRule?.ruleType,
        intervalCount: rule?.intervalCount ?? baseRule?.intervalCount,
        weekday: rule?.weekday ?? baseRule?.weekday,
        timeOfDay: rule?.timeOfDay ?? slice?.revision.defaultTimeOfDay ?? protocolRecord.defaultTimeOfDay
    )
    let doseAmount = rule?.doseAmountOverride ?? slice?.revision.doseAmount ?? protocolRecord.doseAmount
    let doseUnit = rule?.doseUnitOverride ?? slice?.revision.doseUnit ?? protocolRecord.doseUnit

    return AtlasScheduledOccurrence(
        id: occurrence.id,
        protocolID: occurrence.protocolId,
        canonicalTitle: protocolRecord.name,
        aliasTitle: alias,
        kindLabel: kindLabel(protocolRecord.kind),
        cadenceLabel: cadence,
        doseLabel: doseAmount.flatMap { amount in doseUnit.map { "\(amount.cleanAtlasNumber) \($0)" } },
        scheduledAt: scheduledDate,
        state: displayState(for: occurrence, now: now),
        explanation: buildOccurrenceExplanation(
            occurrence: occurrence,
            protocolRecord: protocolRecord,
            context: context,
            now: now
        )
    )
}

func buildOccurrenceExplanation(
    occurrence: AtlasOccurrenceProjectionRecord,
    protocolRecord: AtlasProtocolRecord,
    context: AtlasCoreLoopContext,
    now: Date
) -> AtlasOccurrenceExplanation {
    let scheduledDate = atlasDate(from: occurrence.scheduledAt)
    let slice = effectiveRevisionSlice(context.revisionSlices[occurrence.protocolId] ?? [], at: scheduledDate)
    let rule = slice.flatMap { ruleForOccurrence(slice: $0, occurrenceID: occurrence.id, scheduledAt: scheduledDate) }
    let baseRule = (context.protocolRules[occurrence.protocolId] ?? []).first(where: \.isActive)
        ?? context.protocolRules[occurrence.protocolId]?.first
    let cadence = formatCadenceLabel(
        ruleType: rule?.ruleType ?? baseRule?.ruleType,
        intervalCount: rule?.intervalCount ?? baseRule?.intervalCount,
        weekday: rule?.weekday ?? baseRule?.weekday,
        timeOfDay: rule?.timeOfDay ?? slice?.revision.defaultTimeOfDay ?? protocolRecord.defaultTimeOfDay
    )
    let reminderRows = (context.remindersByOccurrenceID[occurrence.id] ?? [])
        .sorted { atlasDate(from: $0.scheduledFor) < atlasDate(from: $1.scheduledFor) }

    var facts: [AtlasExplainerFact] = []
    if let slice {
        facts.append(
            AtlasExplainerFact(
                label: "Revision",
                value: "Revision \(slice.revision.revisionNumber) effective \(atlasExplanationDateLabel(atlasDate(from: slice.revision.effectiveFrom)))"
            )
        )
        facts.append(
            AtlasExplainerFact(
                label: "Revision state",
                value: slice.revision.lifecycleState.explanationTitle
            )
        )
        facts.append(
            AtlasExplainerFact(
                label: "Timezone",
                value: "\(slice.revision.timezone) · \(slice.revision.timezoneStrategy.explanationTitle)"
            )
        )
        if let rule {
            facts.append(
                AtlasExplainerFact(
                    label: "Rule",
                    value: atlasRuleExplanationLabel(rule)
                )
            )
        }
    }
    facts.append(AtlasExplainerFact(label: "Cadence", value: cadence))
    facts.append(
        AtlasExplainerFact(
            label: "Occurrence",
            value: atlasOccurrenceStateExplanation(occurrence, now: now)
        )
    )
    if let reminder = reminderRows.first {
        facts.append(
            AtlasExplainerFact(
                label: "Reminder",
                value: "\(reminder.status == .scheduled ? "Scheduled" : "Cancelled") · \(atlasExplanationDateTimeLabel(atlasDate(from: reminder.scheduledFor)))"
            )
        )
    } else if occurrence.state == .upcoming || occurrence.state == .due || occurrence.state == .missed {
        facts.append(
            AtlasExplainerFact(
                label: "Reminder",
                value: "No reminder row is scheduled for this occurrence."
            )
        )
    }

    var notes: [String] = []
    if occurrence.id.hasPrefix("manual:") {
        notes.append("This occurrence was created after an earlier scheduled item was rescheduled.")
    }
    if occurrence.state == .superseded {
        notes.append("This original occurrence stayed in history and was superseded instead of being rewritten.")
    }

    let summary: String
    if occurrence.id.hasPrefix("manual:") {
        summary = "This occurrence comes from a manual reschedule and still uses the saved future plan that applies at the new time."
    } else {
        summary = "This occurrence comes from the saved future plan that was active at its scheduled time."
    }

    return AtlasOccurrenceExplanation(summary: summary, facts: facts, notes: notes)
}

private func atlasOccurrenceStateExplanation(
    _ occurrence: AtlasOccurrenceProjectionRecord,
    now: Date
) -> String {
    if occurrence.id.hasPrefix("manual:") {
        return "Manual reschedule"
    }

    switch displayState(for: occurrence, now: now) {
    case .overdue:
        return "Generated future occurrence that is now overdue"
    case .due:
        return "Generated future occurrence that is currently due"
    case .upcoming:
        return "Generated future occurrence"
    case .completed:
        return "Resolved as taken without rewriting history"
    case .skipped:
        return "Resolved as skipped without rewriting history"
    case .superseded:
        return "Superseded after a reschedule"
    }
}

func atlasRuleExplanationLabel(_ rule: AtlasProtocolRevisionRuleRecord) -> String {
    let phase: String
    switch rule.phaseType {
    case .base:
        phase = "Base phase"
    case .titration:
        phase = "Titration phase"
    case .rest:
        phase = "Rest phase"
    }

    let cadence = formatCadenceLabel(
        ruleType: rule.ruleType,
        intervalCount: rule.intervalCount,
        weekday: rule.weekday,
        timeOfDay: rule.timeOfDay
    )
    return "\(phase) · \(cadence)"
}

func atlasExplanationDateLabel(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
}

func atlasExplanationDateTimeLabel(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

func regenerateFutureOccurrences(
    db: Database,
    protocolIDs: [String],
    referenceDate: Date,
    preserveManualReschedules: Bool
) throws {
    let context = try loadCoreLoopContext(db: db)
    let allOccurrenceRecords = try AtlasOccurrenceProjectionDBRecord.fetchAll(db).map(\.domain)
    let preservedIDs = allOccurrenceRecords
        .filter { occurrence in
            occurrence.protocolId.isEmpty == false &&
            protocolIDs.contains(occurrence.protocolId) &&
            (occurrence.state == .completed || occurrence.state == .skipped || occurrence.state == .superseded)
        }
        .map(\.id)
    let timestampsToPreserve = Set(preservedIDs)
    let loggedOccurrenceIDs = Set(
        try AtlasLogEventDBRecord.fetchAll(db)
            .map(\.domain)
            .compactMap(\.occurrenceId)
    )

    if preserveManualReschedules {
        try db.execute(
            sql: """
            DELETE FROM occurrence_projections
            WHERE protocol_id IN \(protocolIDs.sqlList)
              AND state IN ('upcoming', 'due', 'missed')
              AND id NOT LIKE 'manual:%'
            """
        )
    } else {
        try db.execute(
            sql: """
            DELETE FROM occurrence_projections
            WHERE protocol_id IN \(protocolIDs.sqlList)
              AND state IN ('upcoming', 'due', 'missed')
            """
        )
    }

    let horizonStart = Calendar.current.startOfDay(for: referenceDate).addingTimeInterval(-Double(atlasProjectionLookbackDays) * atlasDayInterval)
    let horizonEnd = Calendar.current.startOfDay(for: referenceDate).addingTimeInterval(Double(atlasProjectionHorizonDays) * atlasDayInterval)
    let nowTimestamp = atlasTimestamp(from: referenceDate)

    for protocolID in protocolIDs {
        guard let protocolRecord = context.protocols[protocolID] else {
            continue
        }
        let revisionSlices = context.revisionSlices[protocolID] ?? []
        let fallbackRules = context.protocolRules[protocolID] ?? []
        guard hasSchedulableOccurrences(
            protocolRecord: protocolRecord,
            revisionSlices: revisionSlices,
            fallbackRules: fallbackRules
        ) else {
            continue
        }

        let generated = generateProjectedOccurrences(
            protocolRecord: protocolRecord,
            revisionSlices: revisionSlices,
            horizonStart: horizonStart,
            horizonEnd: horizonEnd,
            fallbackRules: fallbackRules
        )

        for occurrence in generated where timestampsToPreserve.contains(occurrence.id) == false && loggedOccurrenceIDs.contains(occurrence.id) == false {
            let record = AtlasOccurrenceProjectionRecord.make(
                id: occurrence.id,
                protocolId: occurrence.protocolId,
                reminderId: nil,
                scheduledAt: atlasTimestamp(from: occurrence.scheduledAt),
                state: .upcoming,
                createdAt: nowTimestamp,
                updatedAt: nowTimestamp
            )
            try AtlasOccurrenceProjectionDBRecord(record: record).insert(db, onConflict: .ignore)
        }
    }
}

func generateProjectedOccurrences(
    protocolRecord: AtlasProtocolRecord,
    revisionSlices: [AtlasRevisionSlice],
    horizonStart: Date,
    horizonEnd: Date,
    fallbackRules: [AtlasProtocolRuleRecord]
) -> [AtlasGeneratedOccurrence] {
    var occurrences: [AtlasGeneratedOccurrence] = []

    if revisionSlices.isEmpty {
        guard let rule = fallbackRules.first(where: \.isActive) ?? fallbackRules.first else {
            return []
        }
        occurrences.append(contentsOf: generateOccurrencesFromBaseRule(
            protocolRecord: protocolRecord,
            rule: rule,
            horizonStart: horizonStart,
            horizonEnd: horizonEnd
        ))
        return occurrences.sorted { $0.scheduledAt < $1.scheduledAt }
    }

    for slice in revisionSlices where slice.revision.lifecycleState == .active {
        let revisionStart = atlasDate(from: slice.revision.effectiveFrom)
        let revisionEnd = slice.revision.effectiveTo.map(atlasDate) ?? horizonEnd
        let windowStart = max(revisionStart, horizonStart)
        let windowEnd = min(revisionEnd, horizonEnd)

        guard windowStart < windowEnd else {
            continue
        }

        for rule in slice.rules.sorted(by: { $0.phaseOrder < $1.phaseOrder }) where rule.phaseType != .rest {
            let timeOfDay = rule.timeOfDay ?? slice.revision.defaultTimeOfDay
            guard let timeOfDay else {
                continue
            }

            let phaseStart = Calendar.current.startOfDay(for: revisionStart)
                .addingTimeInterval(Double(rule.phaseStartDayOffset) * atlasDayInterval)
            let phaseEnd = rule.phaseLengthDays.map { phaseStart.addingTimeInterval(Double($0) * atlasDayInterval) } ?? windowEnd
            let effectiveStart = max(phaseStart, windowStart)
            let effectiveEnd = min(phaseEnd, windowEnd)

            guard effectiveStart < effectiveEnd else {
                continue
            }

            let anchorDate = rule.anchorDate ?? atlasLocalDateString(phaseStart)
            let dates = generateDatesForRule(
                ruleType: rule.ruleType,
                intervalCount: max(rule.intervalCount, 1),
                weekday: rule.weekday,
                anchorDate: anchorDate,
                timeOfDay: timeOfDay,
                horizonStart: effectiveStart,
                horizonEnd: effectiveEnd
            )

            for date in dates {
                let doseAmount = rule.doseAmountOverride ?? slice.revision.doseAmount
                let doseUnit = rule.doseUnitOverride ?? slice.revision.doseUnit
                occurrences.append(
                    AtlasGeneratedOccurrence(
                        id: "\(protocolRecord.id):\(slice.revision.id):\(rule.id):\(atlasTimestamp(from: date))",
                        protocolId: protocolRecord.id,
                        scheduledAt: date,
                        cadenceLabel: formatCadenceLabel(
                            ruleType: rule.ruleType,
                            intervalCount: rule.intervalCount,
                            weekday: rule.weekday,
                            timeOfDay: timeOfDay
                        ),
                        doseLabel: doseAmount.flatMap { amount in doseUnit.map { "\(amount.cleanAtlasNumber) \($0)" } }
                    )
                )
            }
        }
    }

    return occurrences.sorted { $0.scheduledAt < $1.scheduledAt }
}

private func generateOccurrencesFromBaseRule(
    protocolRecord: AtlasProtocolRecord,
    rule: AtlasProtocolRuleRecord,
    horizonStart: Date,
    horizonEnd: Date
) -> [AtlasGeneratedOccurrence] {
    guard let timeOfDay = rule.timeOfDay ?? protocolRecord.defaultTimeOfDay else {
        return []
    }

    let dates = generateDatesForRule(
        ruleType: rule.ruleType,
        intervalCount: max(rule.intervalCount, 1),
        weekday: rule.weekday,
        anchorDate: rule.anchorDate ?? protocolRecord.startDate,
        timeOfDay: timeOfDay,
        horizonStart: horizonStart,
        horizonEnd: horizonEnd
    )

    return dates.map { date in
        AtlasGeneratedOccurrence(
            id: "\(protocolRecord.id):base:\(rule.id):\(atlasTimestamp(from: date))",
            protocolId: protocolRecord.id,
            scheduledAt: date,
            cadenceLabel: formatCadenceLabel(
                ruleType: rule.ruleType,
                intervalCount: rule.intervalCount,
                weekday: rule.weekday,
                timeOfDay: timeOfDay
            ),
            doseLabel: protocolRecord.doseAmount.flatMap { amount in protocolRecord.doseUnit.map { "\(amount.cleanAtlasNumber) \($0)" } }
        )
    }
}

func generateDatesForRule(
    ruleType: AtlasProtocolRuleType,
    intervalCount: Int,
    weekday: Int?,
    anchorDate: String,
    timeOfDay: String,
    horizonStart: Date,
    horizonEnd: Date
) -> [Date] {
    switch ruleType {
    case .weekly:
        return generateWeeklyDates(
            startDate: anchorDate,
            weekday: weekday,
            timeOfDay: timeOfDay,
            horizonStart: horizonStart,
            horizonEnd: horizonEnd
        )
    case .daily:
        return generateIntervalDates(
            anchorDate: anchorDate,
            intervalCount: 1,
            timeOfDay: timeOfDay,
            horizonStart: horizonStart,
            horizonEnd: horizonEnd
        )
    case .everyNDays:
        return generateIntervalDates(
            anchorDate: anchorDate,
            intervalCount: intervalCount,
            timeOfDay: timeOfDay,
            horizonStart: horizonStart,
            horizonEnd: horizonEnd
        )
    }
}

private func generateWeeklyDates(
    startDate: String,
    weekday: Int?,
    timeOfDay: String,
    horizonStart: Date,
    horizonEnd: Date
) -> [Date] {
    guard let weekday else {
        return []
    }
    guard var cursor = atlasParseLocalDateTime(dateValue: startDate, timeOfDay: timeOfDay) else {
        return []
    }

    while Calendar.current.component(.weekday, from: cursor) - 1 != weekday {
        cursor = cursor.addingTimeInterval(atlasDayInterval)
    }

    var results: [Date] = []
    while cursor < horizonEnd {
        if cursor >= horizonStart {
            results.append(cursor)
        }
        cursor = cursor.addingTimeInterval(7 * atlasDayInterval)
    }
    return results
}

private func generateIntervalDates(
    anchorDate: String,
    intervalCount: Int,
    timeOfDay: String,
    horizonStart: Date,
    horizonEnd: Date
) -> [Date] {
    guard var cursor = atlasParseLocalDateTime(dateValue: anchorDate, timeOfDay: timeOfDay) else {
        return []
    }

    let step = Double(max(intervalCount, 1)) * atlasDayInterval
    while cursor < horizonStart {
        cursor = cursor.addingTimeInterval(step)
    }

    var results: [Date] = []
    while cursor < horizonEnd {
        results.append(cursor)
        cursor = cursor.addingTimeInterval(step)
    }
    return results
}

func effectiveRevisionSlice(_ slices: [AtlasRevisionSlice], at date: Date) -> AtlasRevisionSlice? {
    let timestamp = date.timeIntervalSince1970
    return slices
        .sorted { left, right in
            let leftDate = atlasDate(from: left.revision.effectiveFrom)
            let rightDate = atlasDate(from: right.revision.effectiveFrom)
            if leftDate == rightDate {
                return left.revision.revisionNumber < right.revision.revisionNumber
            }
            return leftDate < rightDate
        }
        .last(where: { slice in
            let start = atlasDate(from: slice.revision.effectiveFrom).timeIntervalSince1970
            let end = slice.revision.effectiveTo.map { atlasDate(from: $0).timeIntervalSince1970 } ?? .greatestFiniteMagnitude
            return start <= timestamp && timestamp < end
        })
}

private func hasSchedulableOccurrences(
    protocolRecord: AtlasProtocolRecord,
    revisionSlices: [AtlasRevisionSlice],
    fallbackRules: [AtlasProtocolRuleRecord]
) -> Bool {
    if protocolRecord.status == .archived {
        return false
    }

    if revisionSlices.contains(where: { $0.revision.lifecycleState == .active && $0.rules.isEmpty == false }) {
        return true
    }

    return revisionSlices.isEmpty && protocolRecord.status == .active && fallbackRules.isEmpty == false
}

func activeRuleForDate(slice: AtlasRevisionSlice, at date: Date) -> AtlasProtocolRevisionRuleRecord? {
    guard slice.revision.lifecycleState == .active else {
        return nil
    }

    let revisionStart = Calendar.current.startOfDay(for: atlasDate(from: slice.revision.effectiveFrom))
    let targetDay = Calendar.current.startOfDay(for: date)

    return slice.rules
        .sorted(by: { $0.phaseOrder < $1.phaseOrder })
        .first(where: { rule in
            let phaseStart = revisionStart.addingTimeInterval(Double(rule.phaseStartDayOffset) * atlasDayInterval)
            let phaseEnd = rule.phaseLengthDays.map { phaseStart.addingTimeInterval(Double($0) * atlasDayInterval) } ?? .distantFuture
            return phaseStart <= targetDay && targetDay < phaseEnd
        })
}

func ruleForOccurrence(
    slice: AtlasRevisionSlice,
    occurrenceID: String,
    scheduledAt: Date
) -> AtlasProtocolRevisionRuleRecord? {
    if let ruleID = occurrenceID.split(separator: ":").dropFirst(2).first.map(String.init) {
        return slice.rules.first(where: { $0.id == ruleID })
    }
    return activeRuleForDate(slice: slice, at: scheduledAt)
}

private func displayState(for occurrence: AtlasOccurrenceProjectionRecord, now: Date) -> AtlasOccurrenceDisplayState {
    switch occurrence.state {
    case .completed:
        return .completed
    case .skipped:
        return .skipped
    case .superseded:
        return .superseded
    case .missed:
        return .overdue
    case .due, .upcoming:
        let scheduledAt = atlasDate(from: occurrence.scheduledAt)
        if scheduledAt < now.addingTimeInterval(-atlasDueWindow) {
            return .overdue
        }
        if scheduledAt <= now.addingTimeInterval(atlasDueWindow) {
            return .due
        }
        return .upcoming
    }
}

func formatCadenceLabel(
    ruleType: AtlasProtocolRuleType?,
    intervalCount: Int?,
    weekday: Int?,
    timeOfDay: String?
) -> String {
    guard let ruleType else {
        return "Cadence pending"
    }

    let timeLabel = formatTimeOfDay(timeOfDay)

    switch ruleType {
    case .weekly:
        return "Every \(weekdayLabel(weekday)) at \(timeLabel)"
    case .daily:
        return "Every day at \(timeLabel)"
    case .everyNDays:
        let interval = max(intervalCount ?? 1, 1)
        return "Every \(interval) day\(interval == 1 ? "" : "s") at \(timeLabel)"
    }
}

func formatTimeOfDay(_ value: String?) -> String {
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

func weekdayLabel(_ weekday: Int?) -> String {
    let labels = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    guard let weekday, labels.indices.contains(weekday) else {
        return "day"
    }
    return labels[weekday]
}

func atlasLocalDateString(_ date: Date) -> String {
    let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
    let year = components.year ?? 1970
    let month = String(format: "%02d", components.month ?? 1)
    let day = String(format: "%02d", components.day ?? 1)
    return "\(year)-\(month)-\(day)"
}

func atlasParseLocalDateTime(dateValue: String, timeOfDay: String) -> Date? {
    let dateParts = dateValue.prefix(10).split(separator: "-").compactMap { Int($0) }
    let timeParts = timeOfDay.split(separator: ":").compactMap { Int($0) }
    guard dateParts.count == 3, timeParts.count >= 2 else {
        return nil
    }

    var components = DateComponents()
    components.year = dateParts[0]
    components.month = dateParts[1]
    components.day = dateParts[2]
    components.hour = timeParts[0]
    components.minute = timeParts[1]
    components.second = 0

    return Calendar.current.date(from: components)
}

private extension Array where Element == String {
    var sqlList: String {
        let quoted = map { "'\($0.replacingOccurrences(of: "'", with: "''"))'" }
        return "(\(quoted.joined(separator: ",")))"
    }
}

private extension Double {
    var cleanAtlasNumber: String {
        if truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(self))
        }
        return String(self)
    }
}
