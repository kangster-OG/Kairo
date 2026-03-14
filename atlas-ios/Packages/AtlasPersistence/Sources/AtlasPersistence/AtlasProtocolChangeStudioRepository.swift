import AtlasDomain
import AtlasPrivacy
import GRDB
import Foundation

private enum AtlasProtocolChangeStudioError: LocalizedError {
    case protocolNotFound
    case missingRevisionState
    case invalidDose
    case invalidDoseUnit
    case invalidTime
    case invalidWeekday
    case invalidInterval
    case invalidRestLength
    case invalidTitrationAmount
    case invalidTitrationUnit
    case invalidTitrationLength
    case invalidTimezone
    case invalidVialSelection

    var errorDescription: String? {
        switch self {
        case .protocolNotFound:
            return "The requested protocol could not be found."
        case .missingRevisionState:
            return "Protocol revision state is unavailable."
        case .invalidDose:
            return "Add a future saved amount."
        case .invalidDoseUnit:
            return "Add a dose unit."
        case .invalidTime:
            return "Add a valid time of day."
        case .invalidWeekday:
            return "Select a weekday."
        case .invalidInterval:
            return "Interval must be at least 1 day."
        case .invalidRestLength:
            return "Rest length must be at least 1 day."
        case .invalidTitrationAmount:
            return "Add a titration amount."
        case .invalidTitrationUnit:
            return "Add a titration unit."
        case .invalidTitrationLength:
            return "Titration length must be at least 1 day."
        case .invalidTimezone:
            return "Add a timezone identifier."
        case .invalidVialSelection:
            return "Choose the vial to switch to."
        }
    }
}

private struct AtlasDraftRevisionInput {
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
    var rules: [AtlasDraftRevisionRuleInput]
}

private struct AtlasDraftRevisionRuleInput {
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
}

private struct AtlasProtocolChangePlan {
    var adherenceNote: String?
    var auditChangeType: AtlasProtocolChangeAuditType
    var draftRevisions: [AtlasDraftRevisionInput]
    var payload: [String: String]
    var siteWarnings: [String]
    var summary: String
}

private struct AtlasProtocolChangeState {
    var protocolRecord: AtlasProtocolRecord
    var aliasRecord: AtlasProtocolAliasRecord?
    var revisionSlices: [AtlasRevisionSlice]
    var vials: [AtlasVialRecord]
    var sites: [AtlasSiteRecord]
    var reminderPreference: AtlasReminderPreferenceRecord
    var privacyProfile: AtlasPrivacyProfileRecord
}

public struct GRDBProtocolChangeStudioRepository: ProtocolChangeStudioRepository, Sendable {
    let stack: AtlasDatabaseStack
    let privacyFormatter: AtlasPrivacyFormatter

    init(
        stack: AtlasDatabaseStack,
        privacyFormatter: AtlasPrivacyFormatter
    ) {
        self.stack = stack
        self.privacyFormatter = privacyFormatter
    }

    public func loadStudio(protocolID: String, referenceDate: Date) async throws -> AtlasProtocolChangeStudioContext {
        try await stack.canonical.read { db in
            let state = try loadStudioState(db: db, protocolID: protocolID)
            let activeSlice = effectiveRevisionSlice(state.revisionSlices, at: referenceDate)
                ?? state.revisionSlices.last
            let activeRule = activeSlice.flatMap { activeRuleForDate(slice: $0, at: referenceDate) }
                ?? firstNonRestRule(state.revisionSlices.last?.rules ?? [])
            let renderMode = privacyFormatter.renderMode(for: state.privacyProfile)

            return AtlasProtocolChangeStudioContext(
                protocolID: state.protocolRecord.id,
                canonicalTitle: state.protocolRecord.name,
                aliasTitle: state.aliasRecord?.aliasLabel,
                kindLabel: kindLabel(state.protocolRecord.kind),
                cadenceLabel: formatCadenceLabel(
                    ruleType: activeRule?.ruleType,
                    intervalCount: activeRule?.intervalCount,
                    weekday: activeRule?.weekday,
                    timeOfDay: activeRule?.timeOfDay ?? activeSlice?.revision.defaultTimeOfDay ?? state.protocolRecord.defaultTimeOfDay
                ),
                doseLabel: formatDoseLabel(
                    amount: activeRule?.doseAmountOverride ?? activeSlice?.revision.doseAmount ?? state.protocolRecord.doseAmount,
                    unit: activeRule?.doseUnitOverride ?? activeSlice?.revision.doseUnit ?? state.protocolRecord.doseUnit
                ),
                effectiveTimeOfDay: activeRule?.timeOfDay ?? activeSlice?.revision.defaultTimeOfDay ?? state.protocolRecord.defaultTimeOfDay,
                currentMissedDosePolicy: activeSlice?.revision.missedDosePolicy ?? .skipAndContinue,
                currentTimezone: activeSlice?.revision.timezone ?? state.protocolRecord.timezone,
                currentTimezoneStrategy: activeSlice?.revision.timezoneStrategy ?? .keepLocalClock,
                currentLinkedVialID: activeSlice?.revision.linkedVialId ?? state.protocolRecord.linkedVialId,
                availableVials: state.vials
                    .sorted(by: { $0.createdAt < $1.createdAt })
                    .map { vial in
                        AtlasProtocolChangeVialOption(
                            id: vial.id,
                            label: privacyFormatter.vialTitle(
                                canonical: vial.label,
                                mode: renderMode
                            ),
                            remainingLabel: "\(formatAtlasQuantity(vial.remainingQuantity, unit: vial.quantityUnit)) remaining",
                            isArchived: vial.archivedAt != nil
                        )
                    },
                siteWarnings: buildSiteWarnings(
                    siteTrackingEnabled: state.protocolRecord.siteTrackingEnabled,
                    siteRotationEnabled: state.protocolRecord.siteRotationEnabled,
                    sites: state.sites
                )
            )
        }
    }

    public func buildPreview(
        protocolID: String,
        draft: AtlasProtocolChangeDraft,
        referenceDate: Date
    ) async throws -> AtlasProtocolChangePreview {
        try await stack.canonical.read { db in
            let state = try loadStudioState(db: db, protocolID: protocolID)
            let normalizedDraft = try normalizeDraft(draft)
            let plan = try buildPlan(
                draft: normalizedDraft,
                state: state
            )

            let effectiveDate = normalizedDraft.effectiveDate
            let boundary = atlasDayStartTimestamp(atlasLocalDateString(effectiveDate))
            let previewSlices = applyDraftPlan(
                protocolID: protocolID,
                currentSlices: state.revisionSlices,
                plan: plan
            )
            let horizonEnd = Calendar.current.startOfDay(for: referenceDate)
                .addingTimeInterval(Double(normalizedDraft.previewWindow.days) * 24 * 60 * 60)

            let currentOccurrences = generateProjectedOccurrences(
                protocolRecord: state.protocolRecord,
                revisionSlices: state.revisionSlices,
                horizonStart: referenceDate,
                horizonEnd: horizonEnd,
                fallbackRules: []
            )
            let previewOccurrences = generateProjectedOccurrences(
                protocolRecord: state.protocolRecord,
                revisionSlices: previewSlices,
                horizonStart: referenceDate,
                horizonEnd: horizonEnd,
                fallbackRules: []
            )
            let diffStart = max(referenceDate, atlasDate(from: boundary))
            let currentFuture = currentOccurrences.filter { $0.scheduledAt >= diffStart }
            let previewFuture = previewOccurrences.filter { $0.scheduledAt >= diffStart }
            let renderMode = privacyFormatter.renderMode(for: state.privacyProfile)

            return AtlasProtocolChangePreview(
                protocolID: protocolID,
                changeType: normalizedDraft.changeType,
                effectiveDate: effectiveDate,
                previewWindow: normalizedDraft.previewWindow,
                summary: plan.summary,
                adherenceNote: plan.adherenceNote,
                nextDueBefore: occurrenceSnapshot(currentOccurrences.first),
                nextDueAfter: occurrenceSnapshot(previewOccurrences.first),
                currentReminderLabel: buildReminderImpactLabel(
                    occurrence: currentOccurrences.first,
                    preference: state.reminderPreference,
                    alias: state.aliasRecord?.aliasLabel,
                    canonicalTitle: state.protocolRecord.name,
                    renderMode: renderMode
                ),
                draftReminderLabel: buildReminderImpactLabel(
                    occurrence: previewOccurrences.first,
                    preference: state.reminderPreference,
                    alias: state.aliasRecord?.aliasLabel,
                    canonicalTitle: state.protocolRecord.name,
                    renderMode: renderMode
                ),
                inventoryForecastBefore: buildInventoryForecastLabel(
                    protocolRecord: state.protocolRecord,
                    revisionSlices: state.revisionSlices,
                    occurrences: currentOccurrences,
                    vials: state.vials,
                    renderMode: renderMode
                ),
                inventoryForecastAfter: buildInventoryForecastLabel(
                    protocolRecord: state.protocolRecord,
                    revisionSlices: previewSlices,
                    occurrences: previewOccurrences,
                    vials: state.vials,
                    renderMode: renderMode
                ),
                occurrenceChanges: buildOccurrenceDiffs(
                    before: currentFuture,
                    after: previewFuture
                ),
                siteWarnings: plan.siteWarnings
            )
        }
    }

    public func commitChange(
        protocolID: String,
        draft: AtlasProtocolChangeDraft,
        referenceDate: Date
    ) async throws -> AtlasProtocolChangeCommitResult {
        let preview = try await buildPreview(
            protocolID: protocolID,
            draft: draft,
            referenceDate: referenceDate
        )
        let normalizedDraft = try normalizeDraft(draft)
        let audit = try await stack.canonical.write { db in
            let state = try loadStudioState(db: db, protocolID: protocolID)
            let plan = try buildPlan(draft: normalizedDraft, state: state)
            let boundary = plan.draftRevisions.first?.effectiveFrom ?? atlasDayStartTimestamp(atlasLocalDateString(referenceDate))
            let boundaryDate = atlasDate(from: boundary)
            let timestamp = atlasTimestamp(from: referenceDate)

            let futureRevisionIDs = try AtlasProtocolRevisionDBRecord
                .filter(Column("protocol_id") == protocolID && Column("effective_from") >= boundary)
                .fetchAll(db)
                .map(\.id)

            if futureRevisionIDs.isEmpty == false {
                try db.execute(
                    sql: "DELETE FROM protocol_revision_rules WHERE revision_id IN \(futureRevisionIDs.sqlList)"
                )
                try db.execute(
                    sql: "DELETE FROM protocol_revisions WHERE id IN \(futureRevisionIDs.sqlList)"
                )
            }

            try AtlasProtocolChangeAuditDBRecord
                .filter(Column("protocol_id") == protocolID && Column("effective_from") >= boundary)
                .deleteAll(db)

            let surviving = try AtlasProtocolRevisionDBRecord
                .filter(Column("protocol_id") == protocolID)
                .order(Column("revision_number"))
                .fetchAll(db)
                .map(\.domain)

            var previousRevisionID: String?
            for revision in surviving {
                let revisionStart = atlasDate(from: revision.effectiveFrom)
                let revisionEnd = revision.effectiveTo.map(atlasDate) ?? .distantFuture

                if revisionStart < boundaryDate && boundaryDate < revisionEnd {
                    var trimmed = revision
                    trimmed.effectiveTo = boundary
                    trimmed.updatedAt = timestamp
                    try AtlasProtocolRevisionDBRecord(record: trimmed).update(db)
                    previousRevisionID = trimmed.id
                } else if revisionStart < boundaryDate {
                    previousRevisionID = revision.id
                }
            }

            let priorRevisionID = previousRevisionID
            var nextRevisionNumber = (surviving.map(\.revisionNumber).max() ?? 0) + 1
            var insertedRevisionIDs: [String] = []

            for draftRevision in plan.draftRevisions {
                let revisionID = UUID().uuidString
                let revision = AtlasProtocolRevisionRecord(
                    id: revisionID,
                    protocolId: protocolID,
                    revisionNumber: nextRevisionNumber,
                    previousRevisionId: previousRevisionID,
                    effectiveFrom: draftRevision.effectiveFrom,
                    effectiveTo: draftRevision.effectiveTo,
                    lifecycleState: draftRevision.lifecycleState,
                    timezone: draftRevision.timezone,
                    timezoneStrategy: draftRevision.timezoneStrategy,
                    defaultTimeOfDay: draftRevision.defaultTimeOfDay,
                    doseAmount: draftRevision.doseAmount,
                    doseUnit: draftRevision.doseUnit,
                    linkedVialId: draftRevision.linkedVialId,
                    missedDosePolicy: draftRevision.missedDosePolicy,
                    notes: draftRevision.notes,
                    createdAt: timestamp,
                    updatedAt: timestamp
                )
                try AtlasProtocolRevisionDBRecord(record: revision).insert(db)

                for rule in draftRevision.rules {
                    let ruleRecord = AtlasProtocolRevisionRuleRecord(
                        id: UUID().uuidString,
                        revisionId: revisionID,
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
                    try AtlasProtocolRevisionRuleDBRecord(record: ruleRecord).insert(db)
                }

                insertedRevisionIDs.append(revisionID)
                previousRevisionID = revisionID
                nextRevisionNumber += 1
            }

            let committedContext = try loadCoreLoopContext(db: db)
            let postCommitSlices = committedContext.revisionSlices[protocolID] ?? []
            if var protocolRow = try AtlasProtocolDBRecord.fetchOne(db, key: protocolID)?.domain {
                if let effectiveSlice = effectiveRevisionSlice(postCommitSlices, at: referenceDate) {
                    protocolRow.status = mapProtocolStatus(lifecycle: effectiveSlice.revision.lifecycleState)
                    protocolRow.linkedVialId = effectiveSlice.revision.linkedVialId
                    protocolRow.defaultTimeOfDay = effectiveSlice.revision.defaultTimeOfDay
                    protocolRow.doseAmount = effectiveSlice.revision.doseAmount
                    protocolRow.doseUnit = effectiveSlice.revision.doseUnit
                    protocolRow.notes = effectiveSlice.revision.notes
                }
                protocolRow.updatedAt = timestamp
                try AtlasProtocolDBRecord(record: protocolRow).update(db)
            }

            let audit = AtlasProtocolChangeAuditRecord.make(
                id: UUID().uuidString,
                protocolId: protocolID,
                revisionId: insertedRevisionIDs.first ?? previousRevisionID ?? UUID().uuidString,
                previousRevisionId: priorRevisionID,
                changeType: plan.auditChangeType,
                effectiveFrom: boundary,
                summary: plan.summary,
                payloadJson: encodePayload(plan.payload),
                createdAt: timestamp
            )
            try AtlasProtocolChangeAuditDBRecord(record: audit).insert(db)

            try regenerateFutureOccurrences(
                db: db,
                protocolIDs: [protocolID],
                referenceDate: referenceDate,
                preserveManualReschedules: false
            )

            return audit
        }

        guard let detail = try await GRDBProtocolRepository(stack: stack).fetchProtocolDetail(id: protocolID) else {
            throw AtlasProtocolChangeStudioError.protocolNotFound
        }

        return AtlasProtocolChangeCommitResult(
            detail: detail,
            preview: preview,
            auditRecord: audit
        )
    }
}

private func loadStudioState(
    db: Database,
    protocolID: String
) throws -> AtlasProtocolChangeState {
    let context = try loadCoreLoopContext(db: db)
    guard let protocolRecord = context.protocols[protocolID] else {
        throw AtlasProtocolChangeStudioError.protocolNotFound
    }

    let vials = try AtlasVialDBRecord
        .order(Column("created_at"))
        .fetchAll(db)
        .map(\.domain)
    let sites = try AtlasSiteDBRecord
        .filter(Column("archived_at") == nil)
        .order(Column("created_at"))
        .fetchAll(db)
        .map(\.domain)
    let reminderPreference = try AtlasReminderPreferenceDBRecord.fetchOne(db)?.domain ?? .default()
    let privacyProfile = try AtlasPrivacyProfileDBRecord.fetchOne(db)?.domain ?? .default()

    return AtlasProtocolChangeState(
        protocolRecord: protocolRecord,
        aliasRecord: context.aliases[protocolID],
        revisionSlices: context.revisionSlices[protocolID] ?? [],
        vials: vials,
        sites: sites,
        reminderPreference: reminderPreference,
        privacyProfile: privacyProfile
    )
}

private func normalizeDraft(_ draft: AtlasProtocolChangeDraft) throws -> AtlasProtocolChangeDraft {
    let trimmedDoseUnit = draft.doseUnit.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedTime = draft.timeOfDay.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedTimezone = draft.timezone.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedTitrationUnit = draft.titrationDoseUnit.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedNotes = draft.notes?.trimmingCharacters(in: .whitespacesAndNewlines)

    switch draft.changeType {
    case .futureDose:
        guard let amount = draft.doseAmount, amount > 0 else {
            throw AtlasProtocolChangeStudioError.invalidDose
        }
        guard trimmedDoseUnit.isEmpty == false else {
            throw AtlasProtocolChangeStudioError.invalidDoseUnit
        }
        _ = amount
    case .futureTime:
        guard atlasParseLocalDateTime(dateValue: atlasLocalDateString(draft.effectiveDate), timeOfDay: trimmedTime) != nil else {
            throw AtlasProtocolChangeStudioError.invalidTime
        }
    case .dayOfWeek:
        guard draft.weekday != nil else {
            throw AtlasProtocolChangeStudioError.invalidWeekday
        }
        guard atlasParseLocalDateTime(dateValue: atlasLocalDateString(draft.effectiveDate), timeOfDay: trimmedTime) != nil else {
            throw AtlasProtocolChangeStudioError.invalidTime
        }
    case .everyNDays:
        guard draft.intervalDays >= 1 else {
            throw AtlasProtocolChangeStudioError.invalidInterval
        }
        guard atlasParseLocalDateTime(dateValue: atlasLocalDateString(draft.effectiveDate), timeOfDay: trimmedTime) != nil else {
            throw AtlasProtocolChangeStudioError.invalidTime
        }
    case .titration:
        guard let titrationAmount = draft.titrationDoseAmount, titrationAmount > 0 else {
            throw AtlasProtocolChangeStudioError.invalidTitrationAmount
        }
        guard trimmedTitrationUnit.isEmpty == false else {
            throw AtlasProtocolChangeStudioError.invalidTitrationUnit
        }
        guard draft.titrationLengthDays >= 1 else {
            throw AtlasProtocolChangeStudioError.invalidTitrationLength
        }
        guard atlasParseLocalDateTime(dateValue: atlasLocalDateString(draft.effectiveDate), timeOfDay: trimmedTime) != nil else {
            throw AtlasProtocolChangeStudioError.invalidTime
        }
        _ = titrationAmount
    case .restPeriod:
        guard draft.restLengthDays >= 1 else {
            throw AtlasProtocolChangeStudioError.invalidRestLength
        }
    case .timezone:
        guard trimmedTimezone.count >= 2 else {
            throw AtlasProtocolChangeStudioError.invalidTimezone
        }
    case .vialSwitch:
        guard draft.linkedVialID != nil else {
            throw AtlasProtocolChangeStudioError.invalidVialSelection
        }
    case .pause, .resume, .missedDosePolicy:
        break
    }

    return AtlasProtocolChangeDraft(
        changeType: draft.changeType,
        effectiveDate: Calendar.current.startOfDay(for: draft.effectiveDate),
        doseAmount: draft.doseAmount,
        doseUnit: trimmedDoseUnit,
        timeOfDay: trimmedTime.isEmpty ? "08:00" : trimmedTime,
        weekday: draft.weekday,
        intervalDays: max(draft.intervalDays, 1),
        linkedVialID: draft.linkedVialID,
        missedDosePolicy: draft.missedDosePolicy,
        notes: trimmedNotes?.isEmpty == true ? nil : trimmedNotes,
        previewWindow: draft.previewWindow,
        restLengthDays: max(draft.restLengthDays, 1),
        titrationDoseAmount: draft.titrationDoseAmount,
        titrationDoseUnit: trimmedTitrationUnit,
        titrationLengthDays: max(draft.titrationLengthDays, 1),
        timezone: trimmedTimezone.isEmpty ? TimeZone.current.identifier : trimmedTimezone,
        timezoneStrategy: draft.timezoneStrategy
    )
}

private func buildPlan(
    draft: AtlasProtocolChangeDraft,
    state: AtlasProtocolChangeState
) throws -> AtlasProtocolChangePlan {
    let effectiveDateString = atlasLocalDateString(draft.effectiveDate)
    let effectiveFrom = atlasDayStartTimestamp(effectiveDateString)
    let referenceSlice = effectiveRevisionSlice(state.revisionSlices, at: draft.effectiveDate)
        ?? state.revisionSlices.last(where: { atlasDate(from: $0.revision.effectiveFrom) <= draft.effectiveDate })
        ?? state.revisionSlices.last
    let fallbackActiveSlice =
        findLatestActiveRevision(state.revisionSlices, effectiveFrom: effectiveFrom) ?? referenceSlice

    guard let referenceSlice, let fallbackActiveSlice else {
        throw AtlasProtocolChangeStudioError.missingRevisionState
    }

    let baseDraft = cloneRevision(referenceSlice, effectiveFrom: effectiveFrom)
    let activeRule = firstNonRestRule(fallbackActiveSlice.rules)
    let fallbackRule = createBaseRule(
        anchorDate: effectiveDateString,
        intervalCount: 7,
        ruleType: .weekly,
        timeOfDay: draft.timeOfDay,
        weekday: 1
    )
    let siteWarnings = buildSiteWarnings(
        siteTrackingEnabled: state.protocolRecord.siteTrackingEnabled,
        siteRotationEnabled: state.protocolRecord.siteRotationEnabled,
        sites: state.sites
    )

    switch draft.changeType {
    case .futureDose:
        return AtlasProtocolChangePlan(
            adherenceNote: "Future adherence uses the new saved amount from the effective date forward.",
            auditChangeType: .futureDoseChanged,
            draftRevisions: [
                AtlasDraftRevisionInput(
                    effectiveFrom: baseDraft.effectiveFrom,
                    effectiveTo: nil,
                    lifecycleState: baseDraft.lifecycleState,
                    timezone: baseDraft.timezone,
                    timezoneStrategy: baseDraft.timezoneStrategy,
                    defaultTimeOfDay: baseDraft.defaultTimeOfDay,
                    doseAmount: draft.doseAmount,
                    doseUnit: draft.doseUnit,
                    linkedVialId: baseDraft.linkedVialId,
                    missedDosePolicy: baseDraft.missedDosePolicy,
                    notes: draft.notes ?? baseDraft.notes,
                    rules: baseDraft.rules
                )
            ],
            payload: [
                "doseAmount": draft.doseAmount?.cleanAtlasNumber ?? "",
                "doseUnit": draft.doseUnit
            ],
            siteWarnings: siteWarnings,
            summary: "Future saved amount changes to \(draft.doseAmount?.cleanAtlasNumber ?? "") \(draft.doseUnit) starting \(effectiveDateString)."
        )
    case .futureTime:
        return AtlasProtocolChangePlan(
            adherenceNote: "Future adherence uses the updated scheduled time from the effective date forward.",
            auditChangeType: .timeChanged,
            draftRevisions: [
                AtlasDraftRevisionInput(
                    effectiveFrom: baseDraft.effectiveFrom,
                    effectiveTo: nil,
                    lifecycleState: baseDraft.lifecycleState,
                    timezone: baseDraft.timezone,
                    timezoneStrategy: baseDraft.timezoneStrategy,
                    defaultTimeOfDay: draft.timeOfDay,
                    doseAmount: baseDraft.doseAmount,
                    doseUnit: baseDraft.doseUnit,
                    linkedVialId: baseDraft.linkedVialId,
                    missedDosePolicy: baseDraft.missedDosePolicy,
                    notes: draft.notes ?? baseDraft.notes,
                    rules: baseDraft.rules.map { rule in
                        var next = rule
                        next.timeOfDay = draft.timeOfDay
                        return next
                    }
                )
            ],
            payload: ["timeOfDay": draft.timeOfDay],
            siteWarnings: siteWarnings,
            summary: "Future scheduled time changes to \(draft.timeOfDay) starting \(effectiveDateString)."
        )
    case .dayOfWeek:
        return AtlasProtocolChangePlan(
            adherenceNote: "Future adherence compares against the updated weekly plan only.",
            auditChangeType: .cadenceChanged,
            draftRevisions: [
                AtlasDraftRevisionInput(
                    effectiveFrom: baseDraft.effectiveFrom,
                    effectiveTo: nil,
                    lifecycleState: baseDraft.lifecycleState,
                    timezone: baseDraft.timezone,
                    timezoneStrategy: baseDraft.timezoneStrategy,
                    defaultTimeOfDay: draft.timeOfDay,
                    doseAmount: baseDraft.doseAmount,
                    doseUnit: baseDraft.doseUnit,
                    linkedVialId: baseDraft.linkedVialId,
                    missedDosePolicy: baseDraft.missedDosePolicy,
                    notes: draft.notes ?? baseDraft.notes,
                    rules: [createBaseRule(
                        anchorDate: effectiveDateString,
                        intervalCount: 1,
                        ruleType: .weekly,
                        timeOfDay: draft.timeOfDay,
                        weekday: draft.weekday
                    )]
                )
            ],
            payload: [
                "ruleType": AtlasProtocolRuleType.weekly.rawValue,
                "timeOfDay": draft.timeOfDay,
                "weekday": String(draft.weekday ?? 0)
            ],
            siteWarnings: siteWarnings,
            summary: "Future cadence moves to \(weekdayLabel(draft.weekday)) at \(draft.timeOfDay) starting \(effectiveDateString)."
        )
    case .everyNDays:
        return AtlasProtocolChangePlan(
            adherenceNote: "Future adherence compares against the updated interval only.",
            auditChangeType: .cadenceChanged,
            draftRevisions: [
                AtlasDraftRevisionInput(
                    effectiveFrom: baseDraft.effectiveFrom,
                    effectiveTo: nil,
                    lifecycleState: baseDraft.lifecycleState,
                    timezone: baseDraft.timezone,
                    timezoneStrategy: baseDraft.timezoneStrategy,
                    defaultTimeOfDay: draft.timeOfDay,
                    doseAmount: baseDraft.doseAmount,
                    doseUnit: baseDraft.doseUnit,
                    linkedVialId: baseDraft.linkedVialId,
                    missedDosePolicy: baseDraft.missedDosePolicy,
                    notes: draft.notes ?? baseDraft.notes,
                    rules: [createBaseRule(
                        anchorDate: effectiveDateString,
                        intervalCount: draft.intervalDays,
                        ruleType: .everyNDays,
                        timeOfDay: draft.timeOfDay,
                        weekday: nil
                    )]
                )
            ],
            payload: [
                "ruleType": AtlasProtocolRuleType.everyNDays.rawValue,
                "intervalDays": String(draft.intervalDays),
                "timeOfDay": draft.timeOfDay
            ],
            siteWarnings: siteWarnings,
            summary: "Future cadence changes to every \(draft.intervalDays) days at \(draft.timeOfDay) starting \(effectiveDateString)."
        )
    case .pause:
        return AtlasProtocolChangePlan(
            adherenceNote: "Future adherence pauses until the protocol is resumed with a later future revision.",
            auditChangeType: .paused,
            draftRevisions: [
                AtlasDraftRevisionInput(
                    effectiveFrom: baseDraft.effectiveFrom,
                    effectiveTo: nil,
                    lifecycleState: .paused,
                    timezone: baseDraft.timezone,
                    timezoneStrategy: baseDraft.timezoneStrategy,
                    defaultTimeOfDay: baseDraft.defaultTimeOfDay,
                    doseAmount: baseDraft.doseAmount,
                    doseUnit: baseDraft.doseUnit,
                    linkedVialId: baseDraft.linkedVialId,
                    missedDosePolicy: baseDraft.missedDosePolicy,
                    notes: draft.notes ?? baseDraft.notes,
                    rules: baseDraft.rules
                )
            ],
            payload: ["lifecycleState": AtlasProtocolRevisionLifecycle.paused.rawValue],
            siteWarnings: siteWarnings,
            summary: "Future schedule pauses starting \(effectiveDateString)."
        )
    case .resume:
        return AtlasProtocolChangePlan(
            adherenceNote: "Future adherence resumes against the restored plan from the selected date.",
            auditChangeType: .resumed,
            draftRevisions: [
                AtlasDraftRevisionInput(
                    effectiveFrom: effectiveFrom,
                    effectiveTo: nil,
                    lifecycleState: .active,
                    timezone: fallbackActiveSlice.revision.timezone,
                    timezoneStrategy: fallbackActiveSlice.revision.timezoneStrategy,
                    defaultTimeOfDay: fallbackActiveSlice.revision.defaultTimeOfDay,
                    doseAmount: fallbackActiveSlice.revision.doseAmount,
                    doseUnit: fallbackActiveSlice.revision.doseUnit,
                    linkedVialId: fallbackActiveSlice.revision.linkedVialId,
                    missedDosePolicy: fallbackActiveSlice.revision.missedDosePolicy,
                    notes: draft.notes ?? fallbackActiveSlice.revision.notes,
                    rules: cloneRules(fallbackActiveSlice.rules)
                )
            ],
            payload: ["lifecycleState": AtlasProtocolRevisionLifecycle.active.rawValue],
            siteWarnings: siteWarnings,
            summary: "Future schedule resumes starting \(effectiveDateString)."
        )
    case .titration:
        let fallbackTime = draft.timeOfDay
        let firstRule = AtlasDraftRevisionRuleInput(
            phaseType: .titration,
            phaseOrder: 0,
            ruleType: activeRule?.ruleType ?? fallbackRule.ruleType,
            intervalCount: activeRule?.intervalCount ?? fallbackRule.intervalCount,
            weekday: activeRule?.weekday ?? fallbackRule.weekday,
            timeOfDay: fallbackTime,
            anchorDate: effectiveDateString,
            phaseStartDayOffset: 0,
            phaseLengthDays: draft.titrationLengthDays,
            doseAmountOverride: draft.titrationDoseAmount,
            doseUnitOverride: draft.titrationDoseUnit
        )
        let secondRule = AtlasDraftRevisionRuleInput(
            phaseType: .base,
            phaseOrder: 1,
            ruleType: activeRule?.ruleType ?? fallbackRule.ruleType,
            intervalCount: activeRule?.intervalCount ?? fallbackRule.intervalCount,
            weekday: activeRule?.weekday ?? fallbackRule.weekday,
            timeOfDay: activeRule?.timeOfDay ?? fallbackTime,
            anchorDate: effectiveDateString,
            phaseStartDayOffset: draft.titrationLengthDays,
            phaseLengthDays: nil,
            doseAmountOverride: nil,
            doseUnitOverride: nil
        )
        return AtlasProtocolChangePlan(
            adherenceNote: "Future adherence compares against the staged titration plan from the effective date forward.",
            auditChangeType: .titrationChanged,
            draftRevisions: [
                AtlasDraftRevisionInput(
                    effectiveFrom: baseDraft.effectiveFrom,
                    effectiveTo: nil,
                    lifecycleState: baseDraft.lifecycleState,
                    timezone: baseDraft.timezone,
                    timezoneStrategy: baseDraft.timezoneStrategy,
                    defaultTimeOfDay: fallbackTime,
                    doseAmount: baseDraft.doseAmount,
                    doseUnit: baseDraft.doseUnit,
                    linkedVialId: baseDraft.linkedVialId,
                    missedDosePolicy: baseDraft.missedDosePolicy,
                    notes: draft.notes ?? baseDraft.notes,
                    rules: [firstRule, secondRule]
                )
            ],
            payload: [
                "titrationDoseAmount": draft.titrationDoseAmount?.cleanAtlasNumber ?? "",
                "titrationDoseUnit": draft.titrationDoseUnit,
                "titrationLengthDays": String(draft.titrationLengthDays)
            ],
            siteWarnings: siteWarnings,
            summary: "Future titration phase lasts \(draft.titrationLengthDays) days starting \(effectiveDateString)."
        )
    case .restPeriod:
        let resumeFrom = atlasDayStartTimestamp(
            atlasLocalDateString(
                Calendar.current.date(byAdding: .day, value: draft.restLengthDays, to: draft.effectiveDate) ?? draft.effectiveDate
            )
        )
        return AtlasProtocolChangePlan(
            adherenceNote: "Future adherence ignores the rest window and resumes against the restored plan afterward.",
            auditChangeType: .restPeriodChanged,
            draftRevisions: [
                AtlasDraftRevisionInput(
                    effectiveFrom: baseDraft.effectiveFrom,
                    effectiveTo: resumeFrom,
                    lifecycleState: .resting,
                    timezone: baseDraft.timezone,
                    timezoneStrategy: baseDraft.timezoneStrategy,
                    defaultTimeOfDay: baseDraft.defaultTimeOfDay,
                    doseAmount: baseDraft.doseAmount,
                    doseUnit: baseDraft.doseUnit,
                    linkedVialId: baseDraft.linkedVialId,
                    missedDosePolicy: baseDraft.missedDosePolicy,
                    notes: draft.notes ?? baseDraft.notes,
                    rules: []
                ),
                AtlasDraftRevisionInput(
                    effectiveFrom: resumeFrom,
                    effectiveTo: nil,
                    lifecycleState: .active,
                    timezone: fallbackActiveSlice.revision.timezone,
                    timezoneStrategy: fallbackActiveSlice.revision.timezoneStrategy,
                    defaultTimeOfDay: fallbackActiveSlice.revision.defaultTimeOfDay,
                    doseAmount: fallbackActiveSlice.revision.doseAmount,
                    doseUnit: fallbackActiveSlice.revision.doseUnit,
                    linkedVialId: fallbackActiveSlice.revision.linkedVialId,
                    missedDosePolicy: fallbackActiveSlice.revision.missedDosePolicy,
                    notes: draft.notes ?? fallbackActiveSlice.revision.notes,
                    rules: cloneRules(fallbackActiveSlice.rules)
                )
            ],
            payload: ["restLengthDays": String(draft.restLengthDays)],
            siteWarnings: siteWarnings,
            summary: "Future rest period lasts \(draft.restLengthDays) days starting \(effectiveDateString)."
        )
    case .missedDosePolicy:
        return AtlasProtocolChangePlan(
            adherenceNote: "Future missed-dose interpretation uses \"\(formatMissedDosePolicy(draft.missedDosePolicy))\".",
            auditChangeType: .missedDosePolicyChanged,
            draftRevisions: [
                AtlasDraftRevisionInput(
                    effectiveFrom: baseDraft.effectiveFrom,
                    effectiveTo: nil,
                    lifecycleState: baseDraft.lifecycleState,
                    timezone: baseDraft.timezone,
                    timezoneStrategy: baseDraft.timezoneStrategy,
                    defaultTimeOfDay: baseDraft.defaultTimeOfDay,
                    doseAmount: baseDraft.doseAmount,
                    doseUnit: baseDraft.doseUnit,
                    linkedVialId: baseDraft.linkedVialId,
                    missedDosePolicy: draft.missedDosePolicy,
                    notes: draft.notes ?? baseDraft.notes,
                    rules: baseDraft.rules
                )
            ],
            payload: ["missedDosePolicy": draft.missedDosePolicy.rawValue],
            siteWarnings: siteWarnings,
            summary: "Future missed-dose recovery changes to \(formatMissedDosePolicy(draft.missedDosePolicy)) starting \(effectiveDateString)."
        )
    case .timezone:
        return AtlasProtocolChangePlan(
            adherenceNote: draft.timezoneStrategy == .keepLocalClock
                ? "Future times keep the local clock after the timezone change."
                : "Future times stay anchored to the prior home timezone interpretation.",
            auditChangeType: .timezoneChanged,
            draftRevisions: [
                AtlasDraftRevisionInput(
                    effectiveFrom: baseDraft.effectiveFrom,
                    effectiveTo: nil,
                    lifecycleState: baseDraft.lifecycleState,
                    timezone: draft.timezone,
                    timezoneStrategy: draft.timezoneStrategy,
                    defaultTimeOfDay: baseDraft.defaultTimeOfDay,
                    doseAmount: baseDraft.doseAmount,
                    doseUnit: baseDraft.doseUnit,
                    linkedVialId: baseDraft.linkedVialId,
                    missedDosePolicy: baseDraft.missedDosePolicy,
                    notes: draft.notes ?? baseDraft.notes,
                    rules: baseDraft.rules
                )
            ],
            payload: [
                "timezone": draft.timezone,
                "timezoneStrategy": draft.timezoneStrategy.rawValue
            ],
            siteWarnings: siteWarnings,
            summary: "Future timezone behavior changes to \(draft.timezone) starting \(effectiveDateString)."
        )
    case .vialSwitch:
        return AtlasProtocolChangePlan(
            adherenceNote: "Future inventory forecast now follows the selected vial after the switch date.",
            auditChangeType: .vialHandoffPlanned,
            draftRevisions: [
                AtlasDraftRevisionInput(
                    effectiveFrom: baseDraft.effectiveFrom,
                    effectiveTo: nil,
                    lifecycleState: baseDraft.lifecycleState,
                    timezone: baseDraft.timezone,
                    timezoneStrategy: baseDraft.timezoneStrategy,
                    defaultTimeOfDay: baseDraft.defaultTimeOfDay,
                    doseAmount: baseDraft.doseAmount,
                    doseUnit: baseDraft.doseUnit,
                    linkedVialId: draft.linkedVialID,
                    missedDosePolicy: baseDraft.missedDosePolicy,
                    notes: draft.notes ?? baseDraft.notes,
                    rules: baseDraft.rules
                )
            ],
            payload: ["linkedVialId": draft.linkedVialID ?? ""],
            siteWarnings: siteWarnings,
            summary: "Future vial handoff switches inventory tracking starting \(effectiveDateString)."
        )
    }
}

private func applyDraftPlan(
    protocolID: String,
    currentSlices: [AtlasRevisionSlice],
    plan: AtlasProtocolChangePlan
) -> [AtlasRevisionSlice] {
    guard let boundary = plan.draftRevisions.first?.effectiveFrom else {
        return currentSlices
    }

    let nextSlices = currentSlices.compactMap { slice -> AtlasRevisionSlice? in
        if slice.revision.effectiveFrom >= boundary {
            return nil
        }

        if slice.revision.effectiveFrom < boundary,
           (slice.revision.effectiveTo == nil || slice.revision.effectiveTo! > boundary) {
            var revision = slice.revision
            revision.effectiveTo = boundary
            return AtlasRevisionSlice(revision: revision, rules: slice.rules)
        }

        return slice
    }

    let createdSlices = plan.draftRevisions.enumerated().map { index, revision in
        AtlasRevisionSlice(
            revision: AtlasProtocolRevisionRecord(
                id: "draft_revision_\(index)",
                protocolId: protocolID,
                revisionNumber: 10_000 + index,
                previousRevisionId: nil,
                effectiveFrom: revision.effectiveFrom,
                effectiveTo: revision.effectiveTo,
                lifecycleState: revision.lifecycleState,
                timezone: revision.timezone,
                timezoneStrategy: revision.timezoneStrategy,
                defaultTimeOfDay: revision.defaultTimeOfDay,
                doseAmount: revision.doseAmount,
                doseUnit: revision.doseUnit,
                linkedVialId: revision.linkedVialId,
                missedDosePolicy: revision.missedDosePolicy,
                notes: revision.notes,
                createdAt: revision.effectiveFrom,
                updatedAt: revision.effectiveFrom
            ),
            rules: revision.rules.enumerated().map { ruleIndex, rule in
                AtlasProtocolRevisionRuleRecord(
                    id: "draft_rule_\(index)_\(ruleIndex)",
                    revisionId: "draft_revision_\(index)",
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
                    createdAt: revision.effectiveFrom,
                    updatedAt: revision.effectiveFrom
                )
            }
        )
    }

    return (nextSlices + createdSlices).sorted {
        let leftDate = atlasDate(from: $0.revision.effectiveFrom)
        let rightDate = atlasDate(from: $1.revision.effectiveFrom)
        if leftDate == rightDate {
            return $0.revision.revisionNumber < $1.revision.revisionNumber
        }
        return leftDate < rightDate
    }
}

private func buildOccurrenceDiffs(
    before: [AtlasGeneratedOccurrence],
    after: [AtlasGeneratedOccurrence]
) -> [AtlasProtocolChangeOccurrenceDiff] {
    let maxLength = max(before.count, after.count)
    var changes: [AtlasProtocolChangeOccurrenceDiff] = []

    for index in 0..<maxLength {
        let beforeOccurrence = index < before.count ? before[index] : nil
        let afterOccurrence = index < after.count ? after[index] : nil

        switch (beforeOccurrence, afterOccurrence) {
        case let (.some(left), .some(right)):
            if left.scheduledAt == right.scheduledAt,
               left.doseLabel == right.doseLabel {
                continue
            }

            let kind: AtlasProtocolChangePreviewDiffKind =
                left.scheduledAt != right.scheduledAt ? .moved : .rewired
            changes.append(
                AtlasProtocolChangeOccurrenceDiff(
                    id: "change_\(index)",
                    kind: kind,
                    beforeLabel: describeOccurrence(left),
                    afterLabel: describeOccurrence(right)
                )
            )
        case let (.some(left), .none):
            changes.append(
                AtlasProtocolChangeOccurrenceDiff(
                    id: "change_\(index)",
                    kind: .removed,
                    beforeLabel: describeOccurrence(left),
                    afterLabel: nil
                )
            )
        case let (.none, .some(right)):
            changes.append(
                AtlasProtocolChangeOccurrenceDiff(
                    id: "change_\(index)",
                    kind: .added,
                    beforeLabel: nil,
                    afterLabel: describeOccurrence(right)
                )
            )
        case (.none, .none):
            break
        }
    }

    return Array(changes.prefix(8))
}

private func buildReminderImpactLabel(
    occurrence: AtlasGeneratedOccurrence?,
    preference: AtlasReminderPreferenceRecord,
    alias: String?,
    canonicalTitle: String,
    renderMode: AtlasPrivacyRenderMode
) -> String? {
    guard let occurrence else {
        return nil
    }

    let effectiveMode = AtlasPrivacyFormatter().effectiveReminderPrivacyMode(
        selectedMode: preference.privacyMode,
        renderMode: renderMode
    )
    let triggerDate = occurrence.scheduledAt.addingTimeInterval(TimeInterval(preference.leadTimeMinutes * -60))
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, h:mm a"

    let title: String
    switch effectiveMode {
    case .silent:
        title = "Silent reminder"
    case .generic:
        title = "Private routine"
    case .fullDetail:
        title = AtlasPrivacyFormatter().title(
            canonical: canonicalTitle,
            alias: alias,
            mode: renderMode
        )
    }

    return "\(formatter.string(from: triggerDate)) · \(title)"
}

private func buildInventoryForecastLabel(
    protocolRecord: AtlasProtocolRecord,
    revisionSlices: [AtlasRevisionSlice],
    occurrences: [AtlasGeneratedOccurrence],
    vials: [AtlasVialRecord],
    renderMode: AtlasPrivacyRenderMode
) -> String? {
    guard let nextDue = occurrences.first else {
        return nil
    }

    let activeSlice = effectiveRevisionSlice(revisionSlices, at: nextDue.scheduledAt)
    let linkedVialID = activeSlice?.revision.linkedVialId ?? protocolRecord.linkedVialId
    guard let linkedVialID,
          let vial = vials.first(where: { $0.id == linkedVialID }) else {
        return nil
    }

    let context = AtlasCoreLoopContext(
        protocols: [protocolRecord.id: protocolRecord],
        aliases: [:],
        protocolRules: [:],
        revisionSlices: [protocolRecord.id: revisionSlices],
        pendingOccurrences: [:]
    )

    var rollingVial = vial
    for occurrence in occurrences where occurrence.scheduledAt >= nextDue.scheduledAt {
        let occurrenceLinkedVialID = effectiveRevisionSlice(revisionSlices, at: occurrence.scheduledAt)?.revision.linkedVialId
            ?? protocolRecord.linkedVialId
        guard occurrenceLinkedVialID == vial.id else {
            continue
        }

        if let decrement = occurrenceVialDecrement(
            protocolRecord: protocolRecord,
            context: context,
            scheduledAt: occurrence.scheduledAt,
            vial: rollingVial
        ) {
            rollingVial.remainingQuantity = max(rollingVial.remainingQuantity - decrement.amount, 0)
            if rollingVial.remainingQuantity <= 0 {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                let vialLabel = renderMode == .full ? vial.label : "Linked vial"
                return "\(vialLabel) until \(formatter.string(from: occurrence.scheduledAt))"
            }
        }
    }

    return nil
}

private func occurrenceSnapshot(
    _ occurrence: AtlasGeneratedOccurrence?
) -> AtlasProtocolChangeOccurrenceSnapshot? {
    guard let occurrence else {
        return nil
    }

    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, h:mm a"
    return AtlasProtocolChangeOccurrenceSnapshot(
        occurrenceID: occurrence.id,
        whenLabel: formatter.string(from: occurrence.scheduledAt),
        doseLabel: occurrence.doseLabel
    )
}

private func describeOccurrence(_ occurrence: AtlasGeneratedOccurrence) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, h:mm a"
    let whenLabel = formatter.string(from: occurrence.scheduledAt)
    if let doseLabel = occurrence.doseLabel {
        return "\(whenLabel) · \(doseLabel)"
    }
    return whenLabel
}

private func cloneRevision(
    _ slice: AtlasRevisionSlice,
    effectiveFrom: String
) -> AtlasDraftRevisionInput {
    AtlasDraftRevisionInput(
        effectiveFrom: effectiveFrom,
        effectiveTo: nil,
        lifecycleState: slice.revision.lifecycleState,
        timezone: slice.revision.timezone,
        timezoneStrategy: slice.revision.timezoneStrategy,
        defaultTimeOfDay: slice.revision.defaultTimeOfDay,
        doseAmount: slice.revision.doseAmount,
        doseUnit: slice.revision.doseUnit,
        linkedVialId: slice.revision.linkedVialId,
        missedDosePolicy: slice.revision.missedDosePolicy,
        notes: slice.revision.notes,
        rules: cloneRules(slice.rules)
    )
}

private func cloneRules(_ rules: [AtlasProtocolRevisionRuleRecord]) -> [AtlasDraftRevisionRuleInput] {
    rules.map { rule in
        AtlasDraftRevisionRuleInput(
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
            doseUnitOverride: rule.doseUnitOverride
        )
    }
}

private func createBaseRule(
    anchorDate: String,
    intervalCount: Int,
    ruleType: AtlasProtocolRuleType,
    timeOfDay: String,
    weekday: Int?
) -> AtlasDraftRevisionRuleInput {
    AtlasDraftRevisionRuleInput(
        phaseType: .base,
        phaseOrder: 0,
        ruleType: ruleType,
        intervalCount: intervalCount,
        weekday: weekday,
        timeOfDay: timeOfDay,
        anchorDate: anchorDate,
        phaseStartDayOffset: 0,
        phaseLengthDays: nil,
        doseAmountOverride: nil,
        doseUnitOverride: nil
    )
}

private func firstNonRestRule(_ rules: [AtlasProtocolRevisionRuleRecord]) -> AtlasProtocolRevisionRuleRecord? {
    rules
        .sorted(by: { $0.phaseOrder < $1.phaseOrder })
        .first(where: { $0.phaseType != .rest })
}

private func findLatestActiveRevision(
    _ slices: [AtlasRevisionSlice],
    effectiveFrom: String
) -> AtlasRevisionSlice? {
    slices
        .filter { $0.revision.lifecycleState == .active }
        .sorted {
            let leftDate = atlasDate(from: $0.revision.effectiveFrom)
            let rightDate = atlasDate(from: $1.revision.effectiveFrom)
            if leftDate == rightDate {
                return $0.revision.revisionNumber > $1.revision.revisionNumber
            }
            return leftDate > rightDate
        }
        .first(where: { $0.revision.effectiveFrom <= effectiveFrom })
}

private func buildSiteWarnings(
    siteTrackingEnabled: Bool,
    siteRotationEnabled: Bool,
    sites: [AtlasSiteRecord]
) -> [String] {
    guard siteTrackingEnabled else {
        return []
    }

    if sites.isEmpty {
        return ["Site tracking is enabled, but no saved sites exist yet."]
    }

    if siteRotationEnabled, sites.count < 2 {
        return ["Site rotation is enabled, but only one saved site is available."]
    }

    return []
}

private func encodePayload(_ payload: [String: String]) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
          let string = String(data: data, encoding: .utf8) else {
        return "{}"
    }
    return string
}

private func formatDoseLabel(amount: Double?, unit: String?) -> String? {
    amount.flatMap { value in
        unit.map { "\(value.cleanAtlasNumber) \($0)" }
    }
}

private func formatMissedDosePolicy(_ value: AtlasMissedDosePolicy) -> String {
    switch value {
    case .skipAndContinue:
        return "skip and continue"
    case .takeNowKeepCadence:
        return "take now and keep cadence"
    case .takeNowShiftFuture:
        return "take now and shift future doses"
    }
}

private func mapProtocolStatus(lifecycle: AtlasProtocolRevisionLifecycle) -> AtlasProtocolStatus {
    switch lifecycle {
    case .active:
        return .active
    case .paused, .resting:
        return .paused
    }
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
