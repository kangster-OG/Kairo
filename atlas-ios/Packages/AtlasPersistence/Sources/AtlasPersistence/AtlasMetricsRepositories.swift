import AtlasDomain
import AtlasPrivacy
import GRDB
import Foundation

private let atlasInsightsTrendWindowDays = 30
private let atlasInsightsSymptomWindowDays = 14

enum AtlasMetricsRepositoryError: LocalizedError {
    case invalidContextEntry
    case invalidWeightValue
    case invalidSymptomKey
    case invalidSeverity
    case invalidMetricLabel
    case invalidScaleBounds
    case metricNotFound
    case metricArchived
    case metricStillHasLogs
    case invalidMetricValue

    var errorDescription: String? {
        switch self {
        case .invalidContextEntry:
            return "Add at least one context detail before saving."
        case .invalidWeightValue:
            return "Weight values must be greater than zero."
        case .invalidSymptomKey:
            return "Symptom name is required."
        case .invalidSeverity:
            return "Symptom severity must stay between 1 and 5."
        case .invalidMetricLabel:
            return "Metric label is required."
        case .invalidScaleBounds:
            return "Scale metrics need a valid minimum and maximum."
        case .metricNotFound:
            return "The selected metric could not be found."
        case .metricArchived:
            return "Archived metrics cannot accept new entries."
        case .metricStillHasLogs:
            return "Metrics with saved entries can be archived but not deleted."
        case .invalidMetricValue:
            return "The entry value does not match the selected metric type."
        }
    }
}

public struct GRDBMetricsRepository: MetricsRepository, Sendable {
    let stack: AtlasDatabaseStack
    let featureFlags: AtlasFeatureFlagState
    let privacyFormatter: AtlasPrivacyFormatter

    init(
        stack: AtlasDatabaseStack,
        featureFlags: AtlasFeatureFlagState,
        privacyFormatter: AtlasPrivacyFormatter
    ) {
        self.stack = stack
        self.featureFlags = featureFlags
        self.privacyFormatter = privacyFormatter
    }

    public func fetchInsightsSnapshot(referenceDate: Date) async throws -> AtlasInsightsSnapshot {
        try await stack.canonical.read { db in
            try buildInsightsSnapshot(
                db: db,
                referenceDate: referenceDate,
                featureFlags: featureFlags,
                privacyFormatter: privacyFormatter
            )
        }
    }

    public func saveContextEntry(_ draft: AtlasContextEntryDraft, now: Date) async throws -> AtlasContextLogRecord {
        try await stack.canonical.write { db in
            let normalized = try normalize(contextDraft: draft)
            let timestamp = atlasTimestamp(from: now)
            let existing = normalized.id.flatMap { try? AtlasContextLogDBRecord.fetchOne(db, key: $0)?.domain }
            let record = AtlasContextLogRecord.make(
                id: existing?.id ?? normalized.id ?? UUID().uuidString,
                protocolId: normalized.protocolID,
                loggedAt: atlasTimestamp(from: normalized.loggedAt),
                mealTiming: normalized.mealTiming,
                fedState: normalized.fedState,
                appetite: normalized.appetite,
                hydration: normalized.hydration,
                giTags: normalized.giTags,
                note: normalized.note.flatMap(stringNilIfEmpty),
                tags: normalized.tags,
                source: .manual,
                createdAt: existing?.createdAt ?? timestamp,
                updatedAt: timestamp
            )
            try AtlasContextLogDBRecord(record: record).save(db)
            return record
        }
    }

    public func saveWeightEntry(_ draft: AtlasWeightEntryDraft, now: Date) async throws -> AtlasWeightLogRecord {
        try await stack.canonical.write { db in
            let normalized = try normalize(weightDraft: draft)
            let timestamp = atlasTimestamp(from: now)
            let existing = normalized.id.flatMap { try? AtlasWeightLogDBRecord.fetchOne(db, key: $0)?.domain }
            let record = AtlasWeightLogRecord.make(
                id: existing?.id ?? normalized.id ?? UUID().uuidString,
                loggedAt: atlasTimestamp(from: normalized.loggedAt),
                value: normalized.value,
                unit: normalized.unit,
                source: .manual,
                notes: normalized.notes.flatMap(stringNilIfEmpty),
                createdAt: existing?.createdAt ?? timestamp,
                updatedAt: timestamp
            )
            try AtlasWeightLogDBRecord(record: record).save(db)
            return record
        }
    }

    public func saveSymptomEntry(_ draft: AtlasSymptomEntryDraft, now: Date) async throws -> AtlasSymptomLogRecord {
        try await stack.canonical.write { db in
            let normalized = try normalize(symptomDraft: draft)
            let timestamp = atlasTimestamp(from: now)
            let existing = normalized.id.flatMap { try? AtlasSymptomLogDBRecord.fetchOne(db, key: $0)?.domain }
            let record = AtlasSymptomLogRecord.make(
                id: existing?.id ?? normalized.id ?? UUID().uuidString,
                loggedAt: atlasTimestamp(from: normalized.loggedAt),
                symptomKey: normalized.symptomKey,
                severity: normalized.severity,
                notes: normalized.notes.flatMap(stringNilIfEmpty),
                source: .manual,
                createdAt: existing?.createdAt ?? timestamp,
                updatedAt: timestamp
            )
            try AtlasSymptomLogDBRecord(record: record).save(db)
            return record
        }
    }

    public func saveMetricDefinition(_ draft: AtlasMetricDefinitionDraft, now: Date) async throws -> AtlasCustomMetricRecord {
        try await stack.canonical.write { db in
            let normalized = try normalize(metricDefinitionDraft: draft)
            let timestamp = atlasTimestamp(from: now)
            let existing = normalized.id.flatMap { try? AtlasCustomMetricDBRecord.fetchOne(db, key: $0)?.domain }
            let record = AtlasCustomMetricRecord.make(
                id: existing?.id ?? normalized.id ?? UUID().uuidString,
                protocolId: normalized.protocolID,
                metricKey: normalized.metricKey ?? metricKey(from: normalized.label),
                label: normalized.label,
                valueType: normalized.valueType,
                unit: normalized.unit.flatMap(stringNilIfEmpty),
                scaleMin: normalized.valueType == .scale ? normalized.scaleMin : nil,
                scaleMax: normalized.valueType == .scale ? normalized.scaleMax : nil,
                createdAt: existing?.createdAt ?? timestamp,
                updatedAt: timestamp,
                archivedAt: existing?.archivedAt
            )
            try AtlasCustomMetricDBRecord(record: record).save(db)
            return record
        }
    }

    public func archiveMetricDefinition(id: String, now: Date) async throws {
        try await stack.canonical.write { db in
            guard var metric = try AtlasCustomMetricDBRecord.fetchOne(db, key: id)?.domain else {
                throw AtlasMetricsRepositoryError.metricNotFound
            }
            metric.archivedAt = atlasTimestamp(from: now)
            metric.updatedAt = atlasTimestamp(from: now)
            try AtlasCustomMetricDBRecord(record: metric).update(db)
        }
    }

    public func deleteMetricDefinition(id: String) async throws {
        try await stack.canonical.write { db in
            guard let metric = try AtlasCustomMetricDBRecord.fetchOne(db, key: id)?.domain else {
                throw AtlasMetricsRepositoryError.metricNotFound
            }
            let logCount = try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM metric_value_logs WHERE metric_id = ?",
                arguments: [id]
            ) ?? 0
            guard logCount == 0 else {
                throw AtlasMetricsRepositoryError.metricStillHasLogs
            }
            try AtlasCustomMetricDBRecord(record: metric).delete(db)
        }
    }

    public func saveMetricValueEntry(_ draft: AtlasMetricValueEntryDraft, now: Date) async throws -> AtlasMetricValueLogRecord {
        try await stack.canonical.write { db in
            guard let metric = try AtlasCustomMetricDBRecord.fetchOne(db, key: draft.metricID)?.domain else {
                throw AtlasMetricsRepositoryError.metricNotFound
            }
            guard metric.archivedAt == nil else {
                throw AtlasMetricsRepositoryError.metricArchived
            }
            let normalized = try normalize(metricValueDraft: draft, metric: metric)
            let timestamp = atlasTimestamp(from: now)
            let existing = normalized.id.flatMap { try? AtlasMetricValueLogDBRecord.fetchOne(db, key: $0)?.domain }
            let record = AtlasMetricValueLogRecord.make(
                id: existing?.id ?? normalized.id ?? UUID().uuidString,
                metricId: metric.id,
                protocolId: normalized.protocolID ?? metric.protocolId,
                loggedAt: atlasTimestamp(from: normalized.loggedAt),
                numberValue: normalized.numberValue,
                textValue: normalized.textValue.flatMap(stringNilIfEmpty),
                booleanValue: normalized.booleanValue,
                source: .manual,
                createdAt: existing?.createdAt ?? timestamp,
                updatedAt: timestamp
            )
            try AtlasMetricValueLogDBRecord(record: record).save(db)
            return record
        }
    }
}

private func normalize(contextDraft: AtlasContextEntryDraft) throws -> AtlasContextEntryDraft {
    let protocolID = contextDraft.protocolID?.trimmingCharacters(in: .whitespacesAndNewlines)
    let note = contextDraft.note?.trimmingCharacters(in: .whitespacesAndNewlines)
    let tags = Array(
        Set(
            contextDraft.tags
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { $0.isEmpty == false }
        )
    ).sorted()
    var giTags = Array(Set(contextDraft.giTags)).sorted { $0.rawValue < $1.rawValue }
    if giTags.contains(.calm), giTags.count > 1 {
        giTags.removeAll { $0 == .calm }
    }

    let hasMeaningfulContent =
        contextDraft.mealTiming != nil
        || contextDraft.fedState != nil
        || contextDraft.appetite != nil
        || contextDraft.hydration != nil
        || giTags.isEmpty == false
        || (note?.isEmpty == false)
        || tags.isEmpty == false

    guard hasMeaningfulContent else {
        throw AtlasMetricsRepositoryError.invalidContextEntry
    }

    return AtlasContextEntryDraft(
        id: contextDraft.id,
        protocolID: protocolID?.isEmpty == true ? nil : protocolID,
        loggedAt: contextDraft.loggedAt,
        mealTiming: contextDraft.mealTiming,
        fedState: contextDraft.fedState,
        appetite: contextDraft.appetite,
        hydration: contextDraft.hydration,
        giTags: giTags,
        note: note,
        tags: tags
    )
}

private func normalize(weightDraft: AtlasWeightEntryDraft) throws -> AtlasWeightEntryDraft {
    guard weightDraft.value > 0 else {
        throw AtlasMetricsRepositoryError.invalidWeightValue
    }
    return AtlasWeightEntryDraft(
        id: weightDraft.id,
        loggedAt: weightDraft.loggedAt,
        value: weightDraft.value,
        unit: weightDraft.unit,
        notes: weightDraft.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
    )
}

private func normalize(symptomDraft: AtlasSymptomEntryDraft) throws -> AtlasSymptomEntryDraft {
    let key = symptomDraft.symptomKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard key.isEmpty == false else {
        throw AtlasMetricsRepositoryError.invalidSymptomKey
    }
    guard (1...5).contains(symptomDraft.severity) else {
        throw AtlasMetricsRepositoryError.invalidSeverity
    }
    return AtlasSymptomEntryDraft(
        id: symptomDraft.id,
        loggedAt: symptomDraft.loggedAt,
        symptomKey: key,
        severity: symptomDraft.severity,
        notes: symptomDraft.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
    )
}

private func normalize(metricDefinitionDraft: AtlasMetricDefinitionDraft) throws -> AtlasMetricDefinitionDraft {
    let label = metricDefinitionDraft.label.trimmingCharacters(in: .whitespacesAndNewlines)
    guard label.isEmpty == false else {
        throw AtlasMetricsRepositoryError.invalidMetricLabel
    }
    if metricDefinitionDraft.valueType == .scale {
        guard let scaleMin = metricDefinitionDraft.scaleMin,
              let scaleMax = metricDefinitionDraft.scaleMax,
              scaleMax > scaleMin else {
            throw AtlasMetricsRepositoryError.invalidScaleBounds
        }
    }
    return AtlasMetricDefinitionDraft(
        id: metricDefinitionDraft.id,
        protocolID: metricDefinitionDraft.protocolID,
        metricKey: metricDefinitionDraft.metricKey?.trimmingCharacters(in: .whitespacesAndNewlines),
        label: label,
        valueType: metricDefinitionDraft.valueType,
        unit: metricDefinitionDraft.unit?.trimmingCharacters(in: .whitespacesAndNewlines),
        scaleMin: metricDefinitionDraft.scaleMin,
        scaleMax: metricDefinitionDraft.scaleMax
    )
}

private func normalize(
    metricValueDraft: AtlasMetricValueEntryDraft,
    metric: AtlasCustomMetricRecord
) throws -> AtlasMetricValueEntryDraft {
    switch metric.valueType {
    case .number:
        guard let numberValue = metricValueDraft.numberValue else {
            throw AtlasMetricsRepositoryError.invalidMetricValue
        }
        return AtlasMetricValueEntryDraft(
            id: metricValueDraft.id,
            metricID: metricValueDraft.metricID,
            protocolID: metricValueDraft.protocolID,
            loggedAt: metricValueDraft.loggedAt,
            numberValue: numberValue,
            textValue: nil,
            booleanValue: nil
        )
    case .scale:
        guard let numberValue = metricValueDraft.numberValue,
              let scaleMin = metric.scaleMin,
              let scaleMax = metric.scaleMax,
              numberValue >= Double(scaleMin),
              numberValue <= Double(scaleMax) else {
            throw AtlasMetricsRepositoryError.invalidMetricValue
        }
        return AtlasMetricValueEntryDraft(
            id: metricValueDraft.id,
            metricID: metricValueDraft.metricID,
            protocolID: metricValueDraft.protocolID,
            loggedAt: metricValueDraft.loggedAt,
            numberValue: numberValue,
            textValue: nil,
            booleanValue: nil
        )
    case .text:
        guard let textValue = metricValueDraft.textValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              textValue.isEmpty == false else {
            throw AtlasMetricsRepositoryError.invalidMetricValue
        }
        return AtlasMetricValueEntryDraft(
            id: metricValueDraft.id,
            metricID: metricValueDraft.metricID,
            protocolID: metricValueDraft.protocolID,
            loggedAt: metricValueDraft.loggedAt,
            numberValue: nil,
            textValue: textValue,
            booleanValue: nil
        )
    case .boolean:
        guard let booleanValue = metricValueDraft.booleanValue else {
            throw AtlasMetricsRepositoryError.invalidMetricValue
        }
        return AtlasMetricValueEntryDraft(
            id: metricValueDraft.id,
            metricID: metricValueDraft.metricID,
            protocolID: metricValueDraft.protocolID,
            loggedAt: metricValueDraft.loggedAt,
            numberValue: nil,
            textValue: nil,
            booleanValue: booleanValue
        )
    }
}

func buildInsightsSnapshot(
    db: Database,
    referenceDate: Date,
    featureFlags: AtlasFeatureFlagState = .init(),
    privacyFormatter: AtlasPrivacyFormatter = .init()
) throws -> AtlasInsightsSnapshot {
    let customMetrics = try AtlasCustomMetricDBRecord.fetchAll(db).map(\.domain)
    let metricLogs = try AtlasMetricValueLogDBRecord
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
    let weightLogs = try AtlasWeightLogDBRecord
        .order(Column("logged_at").desc)
        .fetchAll(db)
        .map(\.domain)
    let reminders = try AtlasReminderDBRecord
        .order(Column("scheduled_for").desc)
        .fetchAll(db)
        .map(\.domain)
    let reminderPreference = try AtlasReminderPreferenceDBRecord.fetchOne(db)?.domain ?? .default()
    let sites = try AtlasSiteDBRecord.fetchAll(db).map(\.domain)
    let logEvents = try AtlasLogEventDBRecord
        .order(Column("logged_at").desc)
        .fetchAll(db)
        .map(\.domain)
    let inventory = try buildInventorySnapshot(db: db, referenceDate: referenceDate)
    let context = try loadCoreLoopContext(db: db)
    let renderMode = privacyFormatter.renderMode(
        for: try AtlasPrivacyProfileDBRecord.fetchOne(db)?.domain ?? .default()
    )
    let summarySettings = try readSummarySettings(db: db, featureFlags: featureFlags)
    let summaryService = AtlasSummaryService(
        featureFlags: featureFlags,
        settings: summarySettings
    )
    let episodeIntelligence = buildEpisodeInsightsSnapshot(
        source: AtlasEpisodeSourceSnapshot(
            protocols: context.protocols,
            aliases: context.aliases,
            protocolRules: context.protocolRules,
            revisionSlices: context.revisionSlices,
            logEvents: logEvents,
            contextLogs: contextLogs,
            symptomLogs: symptomLogs,
            weightLogs: weightLogs,
            metricValueLogs: metricLogs,
            customMetrics: Dictionary(uniqueKeysWithValues: customMetrics.map { ($0.id, $0) }),
            reminders: reminders,
            sites: Dictionary(uniqueKeysWithValues: sites.map { ($0.id, $0) }),
            reminderPreference: reminderPreference
        ),
        now: referenceDate
    )

    let definitions = buildMetricDefinitionSummaries(
        metrics: customMetrics,
        metricLogs: metricLogs,
        context: context
    )
    let recentContextEntries = contextLogs
        .prefix(5)
        .map { log in
            let protocolRecord = log.protocolId.flatMap { context.protocols[$0] }
            let alias = log.protocolId.flatMap { context.aliases[$0]?.aliasLabel }
            return AtlasContextEntrySummary(
                id: log.id,
                protocolID: log.protocolId,
                canonicalProtocolTitle: protocolRecord?.name,
                aliasProtocolTitle: alias,
                loggedAt: atlasDate(from: log.loggedAt),
                mealTiming: log.mealTiming,
                fedState: log.fedState,
                appetite: log.appetite,
                hydration: log.hydration,
                giTags: log.giTags,
                note: log.note,
                tags: log.tags
            )
        }
    let recentWeightEntries = weightLogs
        .prefix(5)
        .map {
            AtlasWeightEntrySummary(
                id: $0.id,
                loggedAt: atlasDate(from: $0.loggedAt),
                valueLabel: formatWeightValue($0),
                notes: $0.notes
            )
        }
    let recentSymptomEntries = symptomLogs
        .prefix(5)
        .map {
            AtlasSymptomEntrySummary(
                id: $0.id,
                loggedAt: atlasDate(from: $0.loggedAt),
                symptomKey: $0.symptomKey,
                severity: $0.severity,
                notes: $0.notes
            )
        }
    let recentMetricEntries = try buildMetricEntrySummaries(
        metricLogs: Array(metricLogs.prefix(8)),
        metricsByID: Dictionary(uniqueKeysWithValues: customMetrics.map { ($0.id, $0) }),
        context: context
    )
    let weeklyRecapSummary = buildWeeklyRecapSummaryRequest(
        context: context,
        logEvents: logEvents,
        contextLogs: contextLogs,
        symptomLogs: symptomLogs,
        weightLogs: weightLogs,
        referenceDate: referenceDate,
        renderMode: renderMode,
        privacyFormatter: privacyFormatter
    ).flatMap(summaryService.generate)
    let episodeRecapSummary = buildEpisodeRecapSummaryRequest(
        snapshot: episodeIntelligence,
        referenceDate: referenceDate,
        renderMode: renderMode
    ).flatMap(summaryService.generate)

    return AtlasInsightsSnapshot(
        weightTrend: buildWeightTrend(weightLogs: weightLogs),
        symptomTrend: buildSymptomTrend(symptomLogs: symptomLogs, now: referenceDate),
        contextTrend: buildContextTrend(contextLogs: contextLogs, now: referenceDate),
        inventoryBurnDown: inventory.vials.map {
            AtlasInventoryBurnDownInsight(
                id: $0.id,
                label: $0.label,
                quantityLabel: $0.quantityLabel,
                projectedDepletionLabel: $0.projectedDepletionLabel,
                isLowStock: $0.isLowStock
            )
        } + inventory.consumables.map {
            AtlasInventoryBurnDownInsight(
                id: $0.id,
                label: $0.name,
                quantityLabel: $0.quantityLabel,
                projectedDepletionLabel: $0.projectedDepletionLabel,
                isLowStock: $0.isLowStock
            )
        },
        adherenceTrend: buildAdherenceTrend(context: context, logEvents: logEvents, now: referenceDate),
        amountInSystem: buildAmountEstimateItems(context: context, logEvents: logEvents, now: referenceDate),
        episodeIntelligence: episodeIntelligence,
        customMetricDefinitions: definitions,
        recentContextEntries: recentContextEntries,
        recentWeightEntries: recentWeightEntries,
        recentSymptomEntries: recentSymptomEntries,
        recentMetricEntries: recentMetricEntries,
        weeklyRecapSummary: weeklyRecapSummary,
        episodeRecapSummary: episodeRecapSummary,
        hasAnyInsightData: contextLogs.isEmpty == false
            || weightLogs.isEmpty == false
            || symptomLogs.isEmpty == false
            || metricLogs.isEmpty == false
            || episodeIntelligence.hasAnyEpisodeData
            || context.pendingOccurrences.isEmpty == false
    )
}

private func buildWeightTrend(weightLogs: [AtlasWeightLogRecord]) -> AtlasWeightTrendSummary {
    let ascending = weightLogs
        .sorted { $0.loggedAt < $1.loggedAt }
        .suffix(6)
    let latest = ascending.last
    let baseline = ascending.first

    return AtlasWeightTrendSummary(
        changeLabel: {
            guard let latest, let baseline, latest.id != baseline.id else {
                return nil
            }
            return "\(formatSigned(latest.value - baseline.value)) \(latest.unit.rawValue) over recent entries"
        }(),
        latestLabel: latest.map { "\(formatNumber($0.value)) \($0.unit.rawValue) logged \(formatDateLabel($0.loggedAt))" },
        points: ascending.map {
            AtlasWeightTrendPoint(
                id: $0.id,
                label: formatCompactDateLabel($0.loggedAt),
                loggedAt: atlasDate(from: $0.loggedAt),
                value: $0.value
            )
        }
    )
}

private func buildSymptomTrend(
    symptomLogs: [AtlasSymptomLogRecord],
    now: Date
) -> [AtlasSymptomTrendItem] {
    let windowStart = Calendar.current.date(byAdding: .day, value: -atlasInsightsSymptomWindowDays, to: now) ?? now
    let recent = symptomLogs.filter { atlasDate(from: $0.loggedAt) >= windowStart }
    let grouped = Dictionary(grouping: recent, by: \.symptomKey)

    return grouped.keys.sorted().compactMap { key in
        guard let entries = grouped[key], let latest = entries.max(by: { $0.loggedAt < $1.loggedAt }) else {
            return nil
        }
        let average = Double(entries.map(\.severity).reduce(0, +)) / Double(entries.count)
        return AtlasSymptomTrendItem(
            symptomKey: key,
            averageSeverityLabel: String(format: "%.1f", average),
            entryCount: entries.count,
            latestLabel: "Latest \(formatDateLabel(latest.loggedAt))"
        )
    }
    .sorted { Double($0.averageSeverityLabel) ?? 0 > Double($1.averageSeverityLabel) ?? 0 }
    .prefix(4)
    .map { $0 }
}

private func buildContextTrend(
    contextLogs: [AtlasContextLogRecord],
    now: Date
) -> AtlasContextTrendSummary {
    let windowStart = Calendar.current.date(byAdding: .day, value: -atlasInsightsSymptomWindowDays, to: now) ?? now
    let recent = contextLogs.filter { atlasDate(from: $0.loggedAt) >= windowStart }
    let latest = recent.first ?? contextLogs.first

    return AtlasContextTrendSummary(
        recentEntryCount: recent.count,
        latestLabel: latest.map { "Latest \(formatDateLabel($0.loggedAt))" },
        fastedEntryCount: recent.filter { $0.fedState == .fasted }.count,
        fedEntryCount: recent.filter { $0.fedState == .fed }.count,
        lowHydrationEntryCount: recent.filter { $0.hydration == .low }.count,
        giEntryCount: recent.filter { $0.giTags.isEmpty == false && $0.giTags != [.calm] }.count
    )
}

private func buildAdherenceTrend(
    context: AtlasCoreLoopContext,
    logEvents: [AtlasLogEventRecord],
    now: Date
) -> AtlasAdherenceTrendSummary {
    let windowStart = Calendar.current.date(byAdding: .day, value: -atlasInsightsTrendWindowDays, to: now) ?? now
    let outstandingItems = context.pendingOccurrences.values
        .flatMap { $0 }
        .filter {
            let date = atlasDate(from: $0.scheduledAt)
            return date >= windowStart && date <= now
        }

    let recentLogEvents = logEvents.filter {
        let date = atlasDate(from: $0.loggedAt)
        return date >= windowStart && date <= now
    }

    let completedCount = recentLogEvents.filter { $0.eventType == .completed }.count
    let skippedCount = recentLogEvents.filter { $0.eventType == .skipped }.count
    let rescheduledCount = recentLogEvents.filter { $0.eventType == .rescheduled }.count
    let overdueCount = outstandingItems.filter { $0.state == .missed || $0.state == .due }.count
    let counted = completedCount + skippedCount + overdueCount

    return AtlasAdherenceTrendSummary(
        completionRateLabel: counted > 0 ? "\(Int(round((Double(completedCount) / Double(counted)) * 100)))% logged on time" : nil,
        completedCount: completedCount,
        overdueCount: overdueCount,
        rescheduledCount: rescheduledCount,
        skippedCount: skippedCount
    )
}

private func buildAmountEstimateItems(
    context: AtlasCoreLoopContext,
    logEvents: [AtlasLogEventRecord],
    now: Date
) -> [AtlasAmountEstimateItem] {
    return context.protocols.values
        .filter { $0.status == .active }
        .compactMap { protocolRecord in
            let protocolLogs = logEvents.filter { $0.protocolId == protocolRecord.id }
            let slice = effectiveRevisionSlice(context.revisionSlices[protocolRecord.id] ?? [], at: now)
            let rule = slice.flatMap { activeRuleForDate(slice: $0, at: now) }
            let intervalHours = ruleIntervalHours(rule)
            let completedLogs = protocolLogs.filter {
                $0.eventType == .completed && $0.quantity != nil && $0.quantityUnit != nil && intervalHours != nil
            }

            let estimate = completedLogs.reduce(0.0) { partialResult, event in
                let elapsedHours = now.timeIntervalSince(atlasDate(from: event.effectiveAt)) / 3600
                let remainingFraction = max(0, 1 - (elapsedHours / (intervalHours ?? 1)))
                return partialResult + (event.quantity ?? 0) * remainingFraction
            }

            let doseUnit = rule?.doseUnitOverride ?? slice?.revision.doseUnit ?? protocolRecord.doseUnit
            let alias = context.aliases[protocolRecord.id]?.aliasLabel

            return AtlasAmountEstimateItem(
                protocolID: protocolRecord.id,
                canonicalProtocolTitle: protocolRecord.name,
                aliasProtocolTitle: alias,
                cadenceLabel: rule.map(describeRule) ?? "No cadence saved yet",
                estimateLabel: estimate > 0 && doseUnit != nil
                    ? "\(formatNumber(estimate)) \(doseUnit ?? "") in the current schedule window"
                    : "No recent logged quantity to estimate from",
                notesLabel: estimate > 0
                    ? "Built from completed logs over the current \(Int(intervalHours ?? 0))-hour interval window."
                    : "Atlas needs completed logs with saved quantities before it can show this estimate."
            )
        }
}

private func buildMetricDefinitionSummaries(
    metrics: [AtlasCustomMetricRecord],
    metricLogs: [AtlasMetricValueLogRecord],
    context: AtlasCoreLoopContext
) -> [AtlasMetricDefinitionSummary] {
    let groupedLogs = Dictionary(grouping: metricLogs, by: \.metricId)

    return metrics
        .map { metric in
            let logs = (groupedLogs[metric.id] ?? []).sorted { $0.loggedAt > $1.loggedAt }
            let latest = logs.first
            let protocolRecord = metric.protocolId.flatMap { context.protocols[$0] }
            let alias = metric.protocolId.flatMap { context.aliases[$0]?.aliasLabel }

            return AtlasMetricDefinitionSummary(
                id: metric.id,
                label: metric.label,
                valueType: metric.valueType,
                unit: metric.unit,
                scaleMin: metric.scaleMin,
                scaleMax: metric.scaleMax,
                protocolID: metric.protocolId,
                canonicalProtocolTitle: protocolRecord?.name,
                aliasProtocolTitle: alias,
                latestEntryLabel: latest.map { formatMetricValue(log: $0, metric: metric) },
                latestEntryAt: latest.map { atlasDate(from: $0.loggedAt) },
                logCount: logs.count,
                archivedAt: metric.archivedAt.map(atlasDate(from:))
            )
        }
        .sorted { left, right in
            switch (left.archivedAt, right.archivedAt) {
            case (nil, .some): return true
            case (.some, nil): return false
            default: return left.label.localizedCaseInsensitiveCompare(right.label) == .orderedAscending
            }
        }
}

private func buildMetricEntrySummaries(
    metricLogs: [AtlasMetricValueLogRecord],
    metricsByID: [String: AtlasCustomMetricRecord],
    context: AtlasCoreLoopContext
) throws -> [AtlasMetricValueEntrySummary] {
    metricLogs.compactMap { log in
        guard let metric = metricsByID[log.metricId] else {
            return nil
        }
        let protocolID = log.protocolId ?? metric.protocolId
        let protocolRecord = protocolID.flatMap { context.protocols[$0] }
        let alias = protocolID.flatMap { context.aliases[$0]?.aliasLabel }
        return AtlasMetricValueEntrySummary(
            id: log.id,
            metricID: metric.id,
            protocolID: protocolID,
            label: metric.label,
            canonicalProtocolTitle: protocolRecord?.name,
            aliasProtocolTitle: alias,
            loggedAt: atlasDate(from: log.loggedAt),
            valueLabel: formatMetricValue(log: log, metric: metric)
        )
    }
}

private func metricKey(from label: String) -> String {
    label
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
        .replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
        .replacingOccurrences(of: "^_+|_+$", with: "", options: .regularExpression)
}

private func stringNilIfEmpty(_ value: String) -> String? {
    value.isEmpty ? nil : value
}

private func formatWeightValue(_ record: AtlasWeightLogRecord) -> String {
    "\(formatNumber(record.value)) \(record.unit.rawValue)"
}

private func formatMetricValue(
    log: AtlasMetricValueLogRecord,
    metric: AtlasCustomMetricRecord
) -> String {
    switch metric.valueType {
    case .number:
        return metric.unit.map { "\(formatNumber(log.numberValue ?? 0)) \($0)" } ?? formatNumber(log.numberValue ?? 0)
    case .scale:
        let maxLabel = metric.scaleMax.map(String.init) ?? "?"
        return "\(Int((log.numberValue ?? 0).rounded())) / \(maxLabel)"
    case .text:
        return log.textValue ?? ""
    case .boolean:
        return (log.booleanValue ?? false) ? "Yes" : "No"
    }
}

private func formatDateLabel(_ timestamp: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter.string(from: atlasDate(from: timestamp))
}

private func formatCompactDateLabel(_ timestamp: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "M/d"
    return formatter.string(from: atlasDate(from: timestamp))
}

private func formatSigned(_ value: Double) -> String {
    value > 0 ? "+\(formatNumber(value))" : formatNumber(value)
}

private func formatNumber(_ value: Double) -> String {
    if value.rounded() == value {
        return String(Int(value))
    }
    return String(format: "%.1f", value)
}

private func ruleIntervalHours(_ rule: AtlasProtocolRevisionRuleRecord?) -> Double? {
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

private func describeRule(_ rule: AtlasProtocolRevisionRuleRecord) -> String {
    switch rule.ruleType {
    case .weekly:
        return "Weekly interval model"
    case .daily:
        return "Daily interval model"
    case .everyNDays:
        return "Every \(rule.intervalCount) days"
    }
}
