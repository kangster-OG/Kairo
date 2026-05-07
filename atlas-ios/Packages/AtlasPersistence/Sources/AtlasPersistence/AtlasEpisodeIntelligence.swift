import AtlasDomain
import Foundation

private let atlasEpisodeLookbackDays = 120
private let atlasEpisodeRecentLimit = 6
private let atlasLateLoggingThresholdMinutes = 90
private let atlasWeightShiftThreshold = 0.5

struct AtlasEpisodeSourceSnapshot {
    var protocols: [String: AtlasProtocolRecord]
    var aliases: [String: AtlasProtocolAliasRecord]
    var protocolRules: [String: [AtlasProtocolRuleRecord]]
    var revisionSlices: [String: [AtlasRevisionSlice]]
    var logEvents: [AtlasLogEventRecord]
    var contextLogs: [AtlasContextLogRecord]
    var symptomLogs: [AtlasSymptomLogRecord]
    var weightLogs: [AtlasWeightLogRecord]
    var metricValueLogs: [AtlasMetricValueLogRecord]
    var customMetrics: [String: AtlasCustomMetricRecord]
    var reminders: [AtlasReminderRecord]
    var sites: [String: AtlasSiteRecord]
    var reminderPreference: AtlasReminderPreferenceRecord
}

private struct AtlasEpisodeWindowObservation {
    var contexts: [AtlasContextLogRecord] = []
    var symptoms: [AtlasSymptomLogRecord] = []
    var weights: [AtlasWeightLogRecord] = []
    var metricLogs: [AtlasMetricValueLogRecord] = []
}

private struct AtlasEpisodeObservation {
    var id: String
    var protocolID: String
    var canonicalProtocolTitle: String
    var aliasProtocolTitle: String?
    var doseAt: Date
    var loggedAt: Date
    var siteLabel: String?
    var reminderLeadMinutes: Int?
    var loggedDelayMinutes: Int
    var windowObservations: [AtlasEpisodeWindowKind: AtlasEpisodeWindowObservation]
}

private struct AtlasEpisodeSymptomKey: Hashable {
    var protocolID: String
    var symptomKey: String
    var window: AtlasEpisodeWindowKind
}

private struct AtlasEpisodeContextPatternKey: Hashable {
    var protocolID: String
    var descriptor: String
    var window: AtlasEpisodeWindowKind
}

func buildEpisodeInsightsSnapshot(
    source: AtlasEpisodeSourceSnapshot,
    now: Date
) -> AtlasEpisodeInsightsSnapshot {
    let observations = buildEpisodeObservations(source: source, now: now)
    guard observations.isEmpty == false else {
        return AtlasEpisodeInsightsSnapshot()
    }

    let compareRows = AtlasEpisodeWindowKind.allCases.map { windowKind in
        let contextCount = observations.reduce(0) { $0 + ($1.windowObservations[windowKind]?.contexts.count ?? 0) }
        let symptomCount = observations.reduce(0) { $0 + ($1.windowObservations[windowKind]?.symptoms.count ?? 0) }
        let weightCount = observations.reduce(0) { $0 + ($1.windowObservations[windowKind]?.weights.count ?? 0) }
        let metricCount = observations.reduce(0) { $0 + ($1.windowObservations[windowKind]?.metricLogs.count ?? 0) }
        let episodeCount = observations.filter {
            let observation = $0.windowObservations[windowKind]
            return (observation?.contexts.isEmpty == false)
                || (observation?.symptoms.isEmpty == false)
                || (observation?.weights.isEmpty == false)
                || (observation?.metricLogs.isEmpty == false)
        }.count

        return AtlasEpisodeWindowCompareRow(
            windowKind: windowKind,
            episodeCount: episodeCount,
            symptomEntryCount: symptomCount,
            weightEntryCount: weightCount,
            contextEntryCount: contextCount,
            metricEntryCount: metricCount,
            summaryLabel: compareSummaryLabel(
                episodeCount: episodeCount,
                symptomCount: symptomCount,
                weightCount: weightCount,
                contextCount: contextCount,
                metricCount: metricCount
            )
        )
    }

    let recentEpisodes = observations
        .sorted { $0.doseAt > $1.doseAt }
        .prefix(atlasEpisodeRecentLimit)
        .map { observation in
            AtlasDoseEpisodeSummary(
                id: observation.id,
                protocolID: observation.protocolID,
                canonicalProtocolTitle: observation.canonicalProtocolTitle,
                aliasProtocolTitle: observation.aliasProtocolTitle,
                doseAt: observation.doseAt,
                siteLabel: observation.siteLabel,
                reminderTimingLabel: reminderTimingLabel(observation: observation),
                adherenceLabel: observation.loggedDelayMinutes <= 15
                    ? "Logged near the scheduled dose time"
                    : "Logged \(observation.loggedDelayMinutes) minute(s) after the scheduled dose time",
                symptomEntryCount: observation.windowObservations.values.reduce(0) { $0 + $1.symptoms.count },
                weightEntryCount: observation.windowObservations.values.reduce(0) { $0 + $1.weights.count },
                contextEntryCount: observation.windowObservations.values.reduce(0) { $0 + $1.contexts.count },
                metricEntryCount: observation.windowObservations.values.reduce(0) { $0 + $1.metricLogs.count }
            )
        }

    let patterns = detectEpisodePatterns(observations: observations, source: source)

    return AtlasEpisodeInsightsSnapshot(
        recentEpisodes: recentEpisodes,
        compareWindows: compareRows,
        patternCards: patterns,
        hasAnyEpisodeData: recentEpisodes.isEmpty == false || patterns.isEmpty == false
    )
}

func buildEpisodeInsightsSnapshot(
    snapshot: AtlasExportSnapshot,
    now: Date
) -> AtlasEpisodeInsightsSnapshot {
    let revisionSlices = buildRevisionSlices(
        protocols: snapshot.protocols,
        revisions: snapshot.protocolRevisions,
        revisionRules: snapshot.protocolRevisionRules,
        protocolRules: snapshot.protocolRules
    )
    let source = AtlasEpisodeSourceSnapshot(
        protocols: Dictionary(uniqueKeysWithValues: snapshot.protocols.map { ($0.id, $0) }),
        aliases: Dictionary(uniqueKeysWithValues: snapshot.protocolAliases.map { ($0.protocolId, $0) }),
        protocolRules: Dictionary(grouping: snapshot.protocolRules, by: \.protocolId),
        revisionSlices: revisionSlices,
        logEvents: snapshot.logEvents,
        contextLogs: snapshot.contextLogs,
        symptomLogs: snapshot.symptomLogs,
        weightLogs: snapshot.weightLogs,
        metricValueLogs: snapshot.metricValueLogs,
        customMetrics: Dictionary(uniqueKeysWithValues: snapshot.customMetrics.map { ($0.id, $0) }),
        reminders: snapshot.reminders,
        sites: Dictionary(uniqueKeysWithValues: snapshot.sites.map { ($0.id, $0) }),
        reminderPreference: snapshot.reminderPreference
    )
    return buildEpisodeInsightsSnapshot(source: source, now: now)
}

private func buildEpisodeObservations(
    source: AtlasEpisodeSourceSnapshot,
    now: Date
) -> [AtlasEpisodeObservation] {
    let lookbackStart = Calendar.current.date(byAdding: .day, value: -atlasEpisodeLookbackDays, to: now) ?? now
    let remindersByOccurrence = Dictionary(uniqueKeysWithValues: source.reminders.map { ($0.occurrenceId, $0) })

    return source.logEvents
        .filter { $0.eventType == .completed }
        .compactMap { event -> AtlasEpisodeObservation? in
            let doseAt = atlasDate(from: event.effectiveAt)
            guard doseAt >= lookbackStart else {
                return nil
            }
            guard let protocolRecord = source.protocols[event.protocolId] else {
                return nil
            }

            let loggedAt = atlasDate(from: event.loggedAt)
            let aliasTitle = source.aliases[event.protocolId]?.aliasLabel
            let siteLabel = event.siteId.flatMap { source.sites[$0]?.name }
            let intervalHours = episodeIntervalHours(
                protocolID: event.protocolId,
                doseAt: doseAt,
                source: source
            )
            let reminderLeadMinutes = event.occurrenceId.flatMap { occurrenceID in
                remindersByOccurrence[occurrenceID].map { Int(round(doseAt.timeIntervalSince(atlasDate(from: $0.scheduledFor)) / 60)) }
            } ?? (source.reminderPreference.remindersEnabled ? source.reminderPreference.leadTimeMinutes : nil)

            var windows = Dictionary(
                uniqueKeysWithValues: AtlasEpisodeWindowKind.allCases.map { ($0, AtlasEpisodeWindowObservation()) }
            )

            let episodeEnd = intervalHours.map { doseAt.addingTimeInterval($0 * 3600) } ?? doseAt.addingTimeInterval(7 * 24 * 3600)
            let symptomEntries = source.symptomLogs.filter { entry in
                let loggedAt = atlasDate(from: entry.loggedAt)
                return loggedAt >= doseAt && loggedAt <= episodeEnd
            }
            let contextEntries = source.contextLogs.filter { entry in
                let loggedAt = atlasDate(from: entry.loggedAt)
                let matchesProtocol = entry.protocolId == nil || entry.protocolId == event.protocolId
                return matchesProtocol && loggedAt >= doseAt && loggedAt <= episodeEnd
            }
            let weightEntries = source.weightLogs.filter { entry in
                let loggedAt = atlasDate(from: entry.loggedAt)
                return loggedAt >= doseAt && loggedAt <= episodeEnd
            }
            let metricEntries = source.metricValueLogs.filter { entry in
                guard metricProtocolID(for: entry, metrics: source.customMetrics) == event.protocolId else {
                    return false
                }
                let loggedAt = atlasDate(from: entry.loggedAt)
                return loggedAt >= doseAt && loggedAt <= episodeEnd
            }

            for entry in contextEntries {
                if let windowKind = classifyEpisodeWindow(
                    loggedAt: atlasDate(from: entry.loggedAt),
                    doseAt: doseAt,
                    intervalHours: intervalHours
                ) {
                    windows[windowKind, default: AtlasEpisodeWindowObservation()].contexts.append(entry)
                }
            }

            for entry in symptomEntries {
                if let windowKind = classifyEpisodeWindow(
                    loggedAt: atlasDate(from: entry.loggedAt),
                    doseAt: doseAt,
                    intervalHours: intervalHours
                ) {
                    windows[windowKind, default: AtlasEpisodeWindowObservation()].symptoms.append(entry)
                }
            }

            for entry in weightEntries {
                if let windowKind = classifyEpisodeWindow(
                    loggedAt: atlasDate(from: entry.loggedAt),
                    doseAt: doseAt,
                    intervalHours: intervalHours
                ) {
                    windows[windowKind, default: AtlasEpisodeWindowObservation()].weights.append(entry)
                }
            }

            for entry in metricEntries {
                if let windowKind = classifyEpisodeWindow(
                    loggedAt: atlasDate(from: entry.loggedAt),
                    doseAt: doseAt,
                    intervalHours: intervalHours
                ) {
                    windows[windowKind, default: AtlasEpisodeWindowObservation()].metricLogs.append(entry)
                }
            }

            return AtlasEpisodeObservation(
                id: event.id,
                protocolID: event.protocolId,
                canonicalProtocolTitle: protocolRecord.name,
                aliasProtocolTitle: aliasTitle,
                doseAt: doseAt,
                loggedAt: loggedAt,
                siteLabel: siteLabel,
                reminderLeadMinutes: reminderLeadMinutes,
                loggedDelayMinutes: max(0, Int(round(loggedAt.timeIntervalSince(doseAt) / 60))),
                windowObservations: windows
            )
        }
}

private func detectEpisodePatterns(
    observations: [AtlasEpisodeObservation],
    source: AtlasEpisodeSourceSnapshot
) -> [AtlasEpisodePatternCard] {
    var cards: [AtlasEpisodePatternCard] = []

    var symptomBuckets: [AtlasEpisodeSymptomKey: [AtlasEpisodeObservation]] = [:]
    for observation in observations {
        for windowKind in AtlasEpisodeWindowKind.allCases {
            let strongSymptoms = (observation.windowObservations[windowKind]?.symptoms ?? []).filter { $0.severity >= 4 }
            for entry in strongSymptoms {
                let key = AtlasEpisodeSymptomKey(
                    protocolID: observation.protocolID,
                    symptomKey: entry.symptomKey,
                    window: windowKind
                )
                symptomBuckets[key, default: []].append(observation)
            }
        }
    }

    for (key, supportingEpisodes) in symptomBuckets.sorted(by: { $0.key.protocolID < $1.key.protocolID }) {
        let uniqueEpisodeIDs = Set(supportingEpisodes.map(\.id))
        guard uniqueEpisodeIDs.count >= 3 else {
            continue
        }
        let protocolTitle = supportingEpisodes.first?.canonicalProtocolTitle
        let aliasTitle = supportingEpisodes.first?.aliasProtocolTitle
        cards.append(
            AtlasEpisodePatternCard(
                id: "symptom:\(key.protocolID):\(key.symptomKey):\(key.window.rawValue)",
                protocolID: key.protocolID,
                canonicalProtocolTitle: protocolTitle,
                aliasProtocolTitle: aliasTitle,
                type: .symptomCluster,
                windowKind: key.window,
                confidence: uniqueEpisodeIDs.count >= 4 ? .high : .medium,
                title: "\(key.symptomKey.capitalized) tended to cluster in \(key.window.title.lowercased())",
                detail: "This symptom appeared in \(uniqueEpisodeIDs.count) recent dose-centered episode(s). Timing only, not cause.",
                supportingEpisodeCount: uniqueEpisodeIDs.count
            )
        )
    }

    let protocolsGrouped = Dictionary(grouping: observations, by: \.protocolID)
    for (protocolID, protocolEpisodes) in protocolsGrouped {
        let lateEpisodes = protocolEpisodes.filter { observation in
            let delayFromReminder = observation.loggedDelayMinutes + (observation.reminderLeadMinutes ?? 0)
            return delayFromReminder >= atlasLateLoggingThresholdMinutes
        }
        if lateEpisodes.count >= 3 {
            let protocolTitle = protocolEpisodes.first?.canonicalProtocolTitle
            let aliasTitle = protocolEpisodes.first?.aliasProtocolTitle
            let averageMinutes = lateEpisodes.map { $0.loggedDelayMinutes + ($0.reminderLeadMinutes ?? 0) }.reduce(0, +) / lateEpisodes.count
            cards.append(
                AtlasEpisodePatternCard(
                    id: "late:\(protocolID)",
                    protocolID: protocolID,
                    canonicalProtocolTitle: protocolTitle,
                    aliasProtocolTitle: aliasTitle,
                    type: .lateLogging,
                    windowKind: .preNextDose,
                    confidence: lateEpisodes.count >= 4 ? .high : .medium,
                    title: "Logs often landed well after the reminder window",
                    detail: "Across \(lateEpisodes.count) recent dose episode(s), logs arrived about \(averageMinutes) minute(s) after the reminder time. This may help explain timeline timing without changing the plan.",
                    supportingEpisodeCount: lateEpisodes.count
                )
            )
        }
    }

    cards.append(contentsOf: detectWeightShiftPatterns(observations: observations, source: source))
    cards.append(contentsOf: detectSiteObservationPatterns(observations: observations))
    cards.append(contentsOf: detectContextPatterns(observations: observations))

    return cards
        .sorted {
            if $0.confidence != $1.confidence {
                return $0.confidence == .high
            }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
        .prefix(6)
        .map { $0 }
}

private func detectContextPatterns(
    observations: [AtlasEpisodeObservation]
) -> [AtlasEpisodePatternCard] {
    var buckets: [AtlasEpisodeContextPatternKey: [AtlasEpisodeObservation]] = [:]

    for observation in observations {
        for windowKind in AtlasEpisodeWindowKind.allCases {
            let contexts = observation.windowObservations[windowKind]?.contexts ?? []
            for context in contexts {
                if context.fedState == .fasted {
                    buckets[
                        AtlasEpisodeContextPatternKey(
                            protocolID: observation.protocolID,
                            descriptor: "Fasted context",
                            window: windowKind
                        ),
                        default: []
                    ].append(observation)
                }
                if context.hydration == .low {
                    buckets[
                        AtlasEpisodeContextPatternKey(
                            protocolID: observation.protocolID,
                            descriptor: "Low hydration context",
                            window: windowKind
                        ),
                        default: []
                    ].append(observation)
                }
                for tag in context.giTags where tag != .calm {
                    buckets[
                        AtlasEpisodeContextPatternKey(
                            protocolID: observation.protocolID,
                            descriptor: tag.title,
                            window: windowKind
                        ),
                        default: []
                    ].append(observation)
                }
            }
        }
    }

    return buckets.compactMap { key, supportingEpisodes in
        let uniqueEpisodeIDs = Set(supportingEpisodes.map(\.id))
        guard uniqueEpisodeIDs.count >= 3 else {
            return nil
        }
        let protocolTitle = supportingEpisodes.first?.canonicalProtocolTitle
        let aliasTitle = supportingEpisodes.first?.aliasProtocolTitle
        return AtlasEpisodePatternCard(
            id: "context:\(key.protocolID):\(key.window.rawValue):\(key.descriptor.lowercased().replacingOccurrences(of: " ", with: "_"))",
            protocolID: key.protocolID,
            canonicalProtocolTitle: protocolTitle,
            aliasProtocolTitle: aliasTitle,
            type: .contextCluster,
            windowKind: key.window,
            confidence: uniqueEpisodeIDs.count >= 4 ? .high : .medium,
            title: "\(key.descriptor) often appeared in \(key.window.title.lowercased())",
            detail: "\(key.descriptor) was logged in \(uniqueEpisodeIDs.count) recent dose-centered episode(s). Timing only, not cause.",
            supportingEpisodeCount: uniqueEpisodeIDs.count
        )
    }
}

private func detectWeightShiftPatterns(
    observations: [AtlasEpisodeObservation],
    source: AtlasEpisodeSourceSnapshot
) -> [AtlasEpisodePatternCard] {
    var grouped: [String: [(AtlasEpisodeObservation, AtlasEpisodeWindowKind, Double, AtlasWeightUnit)]] = [:]

    for observation in observations {
        let baselineCandidates = source.weightLogs
            .filter {
                let loggedAt = atlasDate(from: $0.loggedAt)
                return loggedAt <= observation.doseAt && loggedAt >= observation.doseAt.addingTimeInterval(-24 * 3600)
            }
            .sorted { $0.loggedAt > $1.loggedAt }
        guard let baseline = baselineCandidates.first else {
            continue
        }

        for windowKind in AtlasEpisodeWindowKind.allCases {
            guard let weight = (observation.windowObservations[windowKind]?.weights ?? [])
                .sorted(by: { $0.loggedAt < $1.loggedAt })
                .first,
                weight.unit == baseline.unit else {
                continue
            }
            let delta = weight.value - baseline.value
            grouped[observation.protocolID, default: []].append((observation, windowKind, delta, weight.unit))
        }
    }

    return grouped.compactMap { protocolID, rows in
        let significant = rows.filter { abs($0.2) >= atlasWeightShiftThreshold }
        guard significant.count >= 3 else {
            return nil
        }
        let positive = significant.filter { $0.2 > 0 }
        let negative = significant.filter { $0.2 < 0 }
        let dominant = positive.count >= negative.count ? positive : negative
        guard dominant.count >= 3 else {
            return nil
        }

        let averageDelta = dominant.map(\.2).reduce(0, +) / Double(dominant.count)
        let dominantWindow = Dictionary(grouping: dominant, by: \.1).max(by: { $0.value.count < $1.value.count })?.key
        let observation = dominant.first?.0
        let direction = averageDelta > 0 ? "up" : "down"
        let unit = dominant.first?.3.rawValue ?? ""
        return AtlasEpisodePatternCard(
            id: "weight:\(protocolID):\(dominantWindow?.rawValue ?? "mixed")",
            protocolID: protocolID,
            canonicalProtocolTitle: observation?.canonicalProtocolTitle,
            aliasProtocolTitle: observation?.aliasProtocolTitle,
            type: .weightShift,
            windowKind: dominantWindow,
            confidence: dominant.count >= 4 ? .high : .medium,
            title: "Weight entries tended to drift \(direction) around the same dose window",
            detail: "Across \(dominant.count) recent episode(s), weight changed about \(formatEpisodeNumber(abs(averageDelta))) \(unit) in \(dominantWindow?.title.lowercased() ?? "a repeated window"). Logged timing only.",
            supportingEpisodeCount: dominant.count
        )
    }
}

private func detectSiteObservationPatterns(
    observations: [AtlasEpisodeObservation]
) -> [AtlasEpisodePatternCard] {
    let grouped = Dictionary(grouping: observations.compactMap { observation -> (String, AtlasEpisodeObservation)? in
        guard let siteLabel = observation.siteLabel else {
            return nil
        }
        let symptomCount = (observation.windowObservations[.postDose0To12Hours]?.symptoms.count ?? 0)
            + (observation.windowObservations[.postDose12To48Hours]?.symptoms.count ?? 0)
        guard symptomCount > 0 else {
            return nil
        }
        return (siteLabel, observation)
    }, by: \.0)

    return grouped.compactMap { siteLabel, rows in
        let supporting = rows.map(\.1)
        guard supporting.count >= 3 else {
            return nil
        }
        let observation = supporting.first
        return AtlasEpisodePatternCard(
            id: "site:\(siteLabel)",
            protocolID: observation?.protocolID,
            canonicalProtocolTitle: observation?.canonicalProtocolTitle,
            aliasProtocolTitle: observation?.aliasProtocolTitle,
            type: .siteObservation,
            windowKind: .postDose12To48Hours,
            confidence: supporting.count >= 4 ? .high : .medium,
            title: "The same site appeared alongside symptom logs",
            detail: "\(siteLabel) was used in \(supporting.count) recent episode(s) that also had symptom entries in the first 48 hours. This is descriptive only.",
            supportingEpisodeCount: supporting.count
        )
    }
}

private func buildRevisionSlices(
    protocols: [AtlasProtocolRecord],
    revisions: [AtlasProtocolRevisionRecord],
    revisionRules: [AtlasProtocolRevisionRuleRecord],
    protocolRules: [AtlasProtocolRuleRecord]
) -> [String: [AtlasRevisionSlice]] {
    let rulesByRevisionID = Dictionary(grouping: revisionRules, by: \.revisionId)
    let groupedRevisions = Dictionary(grouping: revisions, by: \.protocolId)

    return Dictionary(uniqueKeysWithValues: protocols.map { record in
        let protocolRevisions = groupedRevisions[record.id]?.sorted { $0.revisionNumber < $1.revisionNumber } ?? []
        if protocolRevisions.isEmpty == false {
            let slices = protocolRevisions.map { revision in
                AtlasRevisionSlice(
                    revision: revision,
                    rules: rulesByRevisionID[revision.id] ?? []
                )
            }
            return (record.id, slices)
        }

        let fallbackRevision = AtlasProtocolRevisionRecord(
            id: "fallback:\(record.id)",
            protocolId: record.id,
            revisionNumber: 1,
            previousRevisionId: nil,
            effectiveFrom: atlasDayStartTimestamp(record.startDate),
            effectiveTo: nil,
            lifecycleState: record.status == .active ? .active : .paused,
            timezone: record.timezone,
            timezoneStrategy: .keepLocalClock,
            defaultTimeOfDay: record.defaultTimeOfDay,
            doseAmount: record.doseAmount,
            doseUnit: record.doseUnit,
            linkedVialId: record.linkedVialId,
            missedDosePolicy: .skipAndContinue,
            notes: record.notes,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
        let fallbackRules = protocolRules
            .filter { $0.protocolId == record.id && $0.isActive }
            .map {
                AtlasProtocolRevisionRuleRecord(
                    id: "fallback-rule:\($0.id)",
                    revisionId: fallbackRevision.id,
                    phaseType: .base,
                    phaseOrder: 0,
                    ruleType: $0.ruleType,
                    intervalCount: $0.intervalCount,
                    weekday: $0.weekday,
                    timeOfDay: $0.timeOfDay,
                    anchorDate: $0.anchorDate,
                    phaseStartDayOffset: 0,
                    phaseLengthDays: nil,
                    doseAmountOverride: nil,
                    doseUnitOverride: nil,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            }
        return (record.id, [AtlasRevisionSlice(revision: fallbackRevision, rules: fallbackRules)])
    })
}

private func episodeIntervalHours(
    protocolID: String,
    doseAt: Date,
    source: AtlasEpisodeSourceSnapshot
) -> Double? {
    let slices = source.revisionSlices[protocolID] ?? []
    let slice = effectiveRevisionSlice(slices, at: doseAt)
    let revisionRule = slice.flatMap { activeRuleForDate(slice: $0, at: doseAt) }
    if let revisionRule {
        return intervalHours(for: revisionRule)
    }
    let rule = source.protocolRules[protocolID]?.first(where: \.isActive)
    return rule.map(intervalHours(for:))
}

private func intervalHours(for rule: AtlasProtocolRevisionRuleRecord) -> Double {
    switch rule.ruleType {
    case .weekly:
        return 7 * 24
    case .daily:
        return 24
    case .everyNDays:
        return Double(rule.intervalCount * 24)
    }
}

private func intervalHours(for rule: AtlasProtocolRuleRecord) -> Double {
    switch rule.ruleType {
    case .weekly:
        return 7 * 24
    case .daily:
        return 24
    case .everyNDays:
        return Double(rule.intervalCount * 24)
    }
}

private func classifyEpisodeWindow(
    loggedAt: Date,
    doseAt: Date,
    intervalHours: Double?
) -> AtlasEpisodeWindowKind? {
    let elapsedHours = loggedAt.timeIntervalSince(doseAt) / 3600
    guard elapsedHours >= 0 else {
        return nil
    }
    if elapsedHours < 12 {
        return .postDose0To12Hours
    }
    if elapsedHours < 48 {
        return .postDose12To48Hours
    }
    if elapsedHours < 96 {
        return .day3To4
    }
    if let intervalHours {
        let remaining = intervalHours - elapsedHours
        let preWindow = min(12.0, max(intervalHours / 2, 4))
        if remaining >= 0 && remaining <= preWindow {
            return .preNextDose
        }
    }
    return nil
}

private func metricProtocolID(
    for log: AtlasMetricValueLogRecord,
    metrics: [String: AtlasCustomMetricRecord]
) -> String? {
    log.protocolId ?? metrics[log.metricId]?.protocolId
}

private func compareSummaryLabel(
    episodeCount: Int,
    symptomCount: Int,
    weightCount: Int,
    contextCount: Int,
    metricCount: Int
) -> String {
    "\(episodeCount) episode(s) • \(contextCount) context entr\(contextCount == 1 ? "y" : "ies") • \(symptomCount) symptom entr\(symptomCount == 1 ? "y" : "ies") • \(weightCount) weight entr\(weightCount == 1 ? "y" : "ies") • \(metricCount) metric entr\(metricCount == 1 ? "y" : "ies")"
}

private func reminderTimingLabel(observation: AtlasEpisodeObservation) -> String {
    guard let reminderLeadMinutes = observation.reminderLeadMinutes else {
        return observation.loggedDelayMinutes == 0
            ? "No reminder timing was available for this episode."
            : "Logged \(observation.loggedDelayMinutes) minute(s) after the scheduled dose time."
    }
    let afterReminderMinutes = observation.loggedDelayMinutes + reminderLeadMinutes
    return "Reminder window started \(reminderLeadMinutes) minute(s) before dose, and the log arrived \(afterReminderMinutes) minute(s) after that reminder time."
}

private func formatEpisodeNumber(_ value: Double) -> String {
    if value.rounded() == value {
        return String(Int(value))
    }
    return String(format: "%.1f", value)
}
