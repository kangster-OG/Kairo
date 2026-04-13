import AtlasDomain
import Foundation

func buildMedicationLevelEstimateItem(
    protocolRecord: AtlasProtocolRecord,
    aliasTitle: String?,
    revisionSlices: [AtlasRevisionSlice],
    logEvents: [AtlasLogEventRecord],
    now: Date,
    chartWindowDays: Int = 14
) -> AtlasAmountEstimateItem {
    let activeSlice = effectiveRevisionSlice(revisionSlices, at: now)
    let activeRule = activeSlice.flatMap { activeRuleForDate(slice: $0, at: now) }
    let cadenceLabel = formatCadenceLabel(
        ruleType: activeRule?.ruleType,
        intervalCount: activeRule?.intervalCount,
        weekday: activeRule?.weekday,
        timeOfDay: activeRule?.timeOfDay ?? activeSlice?.revision.defaultTimeOfDay ?? protocolRecord.defaultTimeOfDay
    )
    let doseUnit = activeRule?.doseUnitOverride ?? activeSlice?.revision.doseUnit ?? protocolRecord.doseUnit
    let knowledge = AtlasCompoundKnowledgeCatalog.resolve(
        protocolName: protocolRecord.name,
        kind: protocolRecord.kind
    )
    let kineticsProfile = knowledge?.kineticsProfile
    let modelKind: AtlasMedicationLevelModelKind = kineticsProfile == nil ? .scheduleWindowEstimate : .halfLifeEstimate
    let modelLabel = kineticsProfile.map { "Half-life estimate • \($0.sourceLabel)" } ?? "Schedule window estimate"
    let halfLifeLabel = kineticsProfile.map { "\($0.halfLifeHours.cleanMedicationLevelNumber) hour half-life profile" }
    let intervalHours = atlasMedicationLevelRuleIntervalHours(activeRule)

    let completedLogs = logEvents
        .filter { event in
            event.protocolId == protocolRecord.id
                && event.eventType == .completed
                && event.quantity != nil
                && (doseUnit == nil || event.quantityUnit == nil || event.quantityUnit == doseUnit)
        }
        .sorted { atlasDate(from: $0.effectiveAt) < atlasDate(from: $1.effectiveAt) }

    let chartStart = Calendar.current.date(byAdding: .day, value: -chartWindowDays, to: now) ?? now
    let sampleStepHours: Double = (intervalHours ?? 24) <= 24 ? 6 : 12
    let points = atlasMedicationLevelSampleDates(
        start: chartStart,
        end: now,
        stepHours: sampleStepHours
    )
    .map { sampleDate in
        AtlasMedicationLevelPoint(
            timestamp: atlasTimestamp(from: sampleDate),
            recordedAt: sampleDate,
            estimatedQuantity: atlasEstimatedMedicationLevel(
                at: sampleDate,
                logs: completedLogs,
                modelKind: modelKind,
                intervalHours: intervalHours,
                halfLifeHours: kineticsProfile?.halfLifeHours
            )
        )
    }

    let currentEstimate = atlasEstimatedMedicationLevel(
        at: now,
        logs: completedLogs,
        modelKind: modelKind,
        intervalHours: intervalHours,
        halfLifeHours: kineticsProfile?.halfLifeHours
    )
    let priorEstimate = atlasEstimatedMedicationLevel(
        at: now.addingTimeInterval(-24 * 3600),
        logs: completedLogs,
        modelKind: modelKind,
        intervalHours: intervalHours,
        halfLifeHours: kineticsProfile?.halfLifeHours
    )

    let eventWindowStart = chartStart
    let doseEvents = completedLogs
        .filter { atlasDate(from: $0.effectiveAt) >= eventWindowStart }
        .suffix(8)
        .map { event in
            AtlasMedicationLevelDoseEvent(
                id: event.id,
                loggedAt: atlasDate(from: event.effectiveAt),
                quantityLabel: atlasMedicationLevelQuantityLabel(
                    value: event.quantity ?? 0,
                    unit: event.quantityUnit ?? doseUnit
                )
            )
        }

    let recentPeak = points
        .filter { $0.recordedAt >= now.addingTimeInterval(-72 * 3600) }
        .map { $0.estimatedQuantity }
        .max()

    let compareLabel: String?
    if completedLogs.isEmpty {
        compareLabel = nil
    } else {
        let difference = currentEstimate - priorEstimate
        if abs(difference) < 0.05 {
            compareLabel = "Shape is roughly steady vs yesterday."
        } else if let doseUnit {
            compareLabel = "\(atlasMedicationLevelSignedNumber(difference)) \(doseUnit) vs yesterday in the Atlas model."
        } else {
            compareLabel = "\(atlasMedicationLevelSignedNumber(difference)) vs yesterday in the Atlas model."
        }
    }

    let estimateLabel: String
    if completedLogs.isEmpty {
        estimateLabel = "No completed logged quantity yet"
    } else if let doseUnit {
        estimateLabel = "\(atlasMedicationLevelNumber(currentEstimate)) \(doseUnit) estimated active now"
    } else {
        estimateLabel = "\(atlasMedicationLevelNumber(currentEstimate)) estimated active now"
    }

    let notesLabel: String
    if completedLogs.isEmpty {
        notesLabel = "Atlas needs completed logs with saved quantities before it can shape a level view."
    } else if let kineticsProfile {
        notesLabel = "\(kineticsProfile.notes) Atlas still treats this as a planning estimate, not a serum measurement."
    } else {
        notesLabel = "Atlas does not have a half-life profile for this compound yet, so this view falls back to the saved schedule window."
    }

    var facts = [
        AtlasExplainerFact(label: "Model", value: modelLabel),
        AtlasExplainerFact(label: "Cadence", value: cadenceLabel),
        AtlasExplainerFact(label: "Completed logs", value: "\(completedLogs.count)")
    ]
    if let halfLifeLabel {
        facts.append(AtlasExplainerFact(label: "Profile", value: halfLifeLabel))
    }
    if let recentPeak, completedLogs.isEmpty == false {
        let peakValue = doseUnit.map { "\(atlasMedicationLevelNumber(recentPeak)) \($0)" } ?? atlasMedicationLevelNumber(recentPeak)
        facts.append(AtlasExplainerFact(label: "Peak (72h)", value: peakValue))
    }
    if let lastEvent = doseEvents.last {
        facts.append(
            AtlasExplainerFact(
                label: "Last logged",
                value: "\(lastEvent.quantityLabel) • \(lastEvent.loggedAt.formatted(date: .abbreviated, time: .shortened))"
            )
        )
    }

    return AtlasAmountEstimateItem(
        protocolID: protocolRecord.id,
        canonicalProtocolTitle: protocolRecord.name,
        aliasProtocolTitle: aliasTitle,
        cadenceLabel: cadenceLabel.isEmpty ? "No cadence saved yet" : cadenceLabel,
        estimateLabel: estimateLabel,
        notesLabel: notesLabel,
        modelKind: modelKind,
        modelLabel: modelLabel,
        halfLifeLabel: halfLifeLabel,
        compareLabel: compareLabel,
        peakWindowLabel: recentPeak.flatMap { recentPeak in
            doseUnit.map { "Peak in the last 72 hours: \(atlasMedicationLevelNumber(recentPeak)) \($0)." }
                ?? "Peak in the last 72 hours: \(atlasMedicationLevelNumber(recentPeak))."
        },
        currentEstimateValue: completedLogs.isEmpty ? nil : currentEstimate,
        estimateUnit: doseUnit,
        points: points,
        doseEvents: doseEvents,
        sourceFacts: facts
    )
}

private func atlasEstimatedMedicationLevel(
    at date: Date,
    logs: [AtlasLogEventRecord],
    modelKind: AtlasMedicationLevelModelKind,
    intervalHours: Double?,
    halfLifeHours: Double?
) -> Double {
    logs.reduce(0.0) { partialResult, event in
        let loggedAt = atlasDate(from: event.effectiveAt)
        guard loggedAt <= date else {
            return partialResult
        }

        let elapsedHours = date.timeIntervalSince(loggedAt) / 3600
        let quantity = event.quantity ?? 0
        let contribution: Double

        switch modelKind {
        case .halfLifeEstimate:
            let halfLifeHours = max(halfLifeHours ?? 0, 1)
            contribution = quantity * exp(-(Foundation.log(2) / halfLifeHours) * elapsedHours)
        case .scheduleWindowEstimate:
            let intervalHours = max(intervalHours ?? 24, 1)
            contribution = quantity * max(0, 1 - (elapsedHours / intervalHours))
        }

        return partialResult + contribution
    }
}

private func atlasMedicationLevelSampleDates(
    start: Date,
    end: Date,
    stepHours: Double
) -> [Date] {
    guard start < end else {
        return [end]
    }

    var dates: [Date] = []
    var current = start
    while current < end {
        dates.append(current)
        current = current.addingTimeInterval(stepHours * 3600)
    }
    dates.append(end)
    return dates
}

private func atlasMedicationLevelRuleIntervalHours(_ rule: AtlasProtocolRevisionRuleRecord?) -> Double? {
    guard let rule else {
        return nil
    }
    switch rule.ruleType {
    case .weekly:
        return 7 * 24
    case .daily:
        return 24
    case .everyNDays:
        return Double(rule.intervalCount * 24)
    }
}

private func atlasMedicationLevelNumber(_ value: Double) -> String {
    if value.rounded() == value {
        return String(Int(value))
    }
    return String(format: "%.1f", value)
}

private func atlasMedicationLevelSignedNumber(_ value: Double) -> String {
    value > 0 ? "+\(atlasMedicationLevelNumber(value))" : atlasMedicationLevelNumber(value)
}

private func atlasMedicationLevelQuantityLabel(value: Double, unit: String?) -> String {
    guard let unit else {
        return atlasMedicationLevelNumber(value)
    }
    return "\(atlasMedicationLevelNumber(value)) \(unit)"
}

private extension Double {
    var cleanMedicationLevelNumber: String {
        atlasMedicationLevelNumber(self)
    }
}
