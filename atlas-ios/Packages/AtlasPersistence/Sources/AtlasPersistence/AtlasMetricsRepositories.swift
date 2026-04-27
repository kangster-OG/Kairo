import AtlasDomain
import AtlasPrivacy
import GRDB
import Foundation

private let atlasInsightsTrendWindowDays = 30
private let atlasInsightsSymptomWindowDays = 14
private let atlasInsightsExplainabilityContextWindowHours = 6.0
private let atlasInsightsExplainabilityWorkoutWindowHours = 24.0
private let atlasInsightsExplainabilityWeightWindowHours = 24.0
private let atlasInsightsExplainabilityMetricWindowHours = 24.0
private let atlasInsightsExplainabilityMinimumMatches = 2
private let atlasInsightsExplainabilityMinimumCoverage = 0.5
private let atlasInsightsExplainabilityMaxCards = 4
private let atlasWeeklyReviewWindowDays = 7
private let atlasWeeklyReviewArchiveWeeks = 8
private let atlasWeeklyReviewProtocolFollowUpDays = 14

enum AtlasMetricsRepositoryError: LocalizedError {
    case invalidContextEntry
    case invalidContextPreset
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
        case .invalidContextPreset:
            return "Choose at least one reusable context detail before saving a preset."
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

    public func importWorkoutSamples(_ samples: [AtlasHealthWorkoutSample], now: Date) async throws -> Int {
        try await stack.canonical.write { db in
            let timestamp = atlasTimestamp(from: now)
            var importedCount = 0

            for sample in samples {
                let existing = try AtlasWorkoutLogDBRecord
                    .filter(Column("external_source_id") == sample.id)
                    .fetchOne(db)
                if existing != nil {
                    continue
                }

                let record = AtlasWorkoutLogRecord.make(
                    id: "workout_\(sample.id.lowercased())",
                    activityKind: sample.activityKind,
                    startedAt: atlasTimestamp(from: sample.startedAt),
                    endedAt: atlasTimestamp(from: sample.endedAt),
                    durationMinutes: sample.durationMinutes,
                    energyBurnedKilocalories: sample.energyBurnedKilocalories,
                    distanceMeters: sample.distanceMeters,
                    source: .health,
                    externalSourceId: sample.id,
                    createdAt: timestamp,
                    updatedAt: timestamp
                )
                try AtlasWorkoutLogDBRecord(record: record).insert(db)
                importedCount += 1
            }

            return importedCount
        }
    }

    public func saveWorkoutEntry(_ draft: AtlasWorkoutEntryDraft, now: Date) async throws -> AtlasWorkoutLogRecord {
        try await stack.canonical.write { db in
            let timestamp = atlasTimestamp(from: now)
            let startedAt = draft.startedAt
            let endedAt = startedAt.addingTimeInterval(max(draft.durationMinutes, 1) * 60)
            let record = AtlasWorkoutLogRecord.make(
                id: draft.id ?? "workout_\(UUID().uuidString.lowercased())",
                activityKind: draft.activityKind,
                startedAt: atlasTimestamp(from: startedAt),
                endedAt: atlasTimestamp(from: endedAt),
                durationMinutes: max(draft.durationMinutes, 1),
                energyBurnedKilocalories: draft.energyBurnedKilocalories,
                distanceMeters: draft.distanceMeters,
                source: .manual,
                externalSourceId: nil,
                createdAt: timestamp,
                updatedAt: timestamp
            )
            try AtlasWorkoutLogDBRecord(record: record).save(db)
            return record
        }
    }

    public func importWeightSamples(_ samples: [AtlasHealthWeightSample], now: Date) async throws -> Int {
        try await stack.canonical.write { db in
            let timestamp = atlasTimestamp(from: now)
            var importedCount = 0

            for sample in samples {
                guard sample.value > 0 else {
                    continue
                }

                let existing = try AtlasWeightLogDBRecord.fetchOne(db, key: sample.id)?.domain
                let record = AtlasWeightLogRecord.make(
                    id: existing?.id ?? sample.id,
                    loggedAt: atlasTimestamp(from: sample.recordedAt),
                    value: sample.value,
                    unit: sample.unit,
                    source: .health,
                    notes: existing?.notes,
                    createdAt: existing?.createdAt ?? timestamp,
                    updatedAt: timestamp
                )
                try AtlasWeightLogDBRecord(record: record).save(db)
                if existing == nil {
                    importedCount += 1
                }
            }

            return importedCount
        }
    }

    public func importNutritionSamples(_ samples: [AtlasHealthNutritionSample], now: Date) async throws -> Int {
        try await stack.canonical.write { db in
            let timestamp = atlasTimestamp(from: now)
            var metricIDsByKind: [AtlasHealthNutritionMetricKind: String] = [:]
            var importedCount = 0

            for sample in samples where sample.value > 0 {
                let metricID: String
                if let existingID = metricIDsByKind[sample.kind] {
                    metricID = existingID
                } else {
                    let record = try ensureHealthNutritionMetric(kind: sample.kind, db: db, timestamp: timestamp)
                    metricIDsByKind[sample.kind] = record.id
                    metricID = record.id
                }

                let existing = try AtlasMetricValueLogDBRecord.fetchOne(db, key: "health_metric_\(sample.id.lowercased())")?.domain
                let record = AtlasMetricValueLogRecord.make(
                    id: existing?.id ?? "health_metric_\(sample.id.lowercased())",
                    metricId: metricID,
                    protocolId: nil,
                    loggedAt: atlasTimestamp(from: sample.recordedAt),
                    numberValue: sample.value,
                    textValue: nil,
                    booleanValue: nil,
                    source: .health,
                    createdAt: existing?.createdAt ?? timestamp,
                    updatedAt: timestamp
                )
                try AtlasMetricValueLogDBRecord(record: record).save(db)
                if existing == nil {
                    importedCount += 1
                }
            }

            return importedCount
        }
    }

    public func importHealthMetricSamples(_ samples: [AtlasHealthMetricSample], now: Date) async throws -> Int {
        try await stack.canonical.write { db in
            let timestamp = atlasTimestamp(from: now)
            var metricIDsByKind: [AtlasHealthMetricKind: String] = [:]
            var importedCount = 0

            for sample in samples where sample.value > 0 {
                if sample.kind == .bodyFatPercentage {
                    let existing = try AtlasProgressMeasurementDBRecord
                        .fetchOne(db, key: "health_progress_\(sample.id.lowercased())")?
                        .domain
                    let record = AtlasProgressMeasurementRecord(
                        id: existing?.id ?? "health_progress_\(sample.id.lowercased())",
                        protocolID: nil,
                        kind: .bodyFat,
                        value: sample.value,
                        unit: sample.kind.unit,
                        note: nil,
                        loggedAt: atlasTimestamp(from: sample.recordedAt),
                        createdAt: existing?.createdAt ?? timestamp,
                        updatedAt: timestamp
                    )
                    try AtlasProgressMeasurementDBRecord(record: record).save(db)
                    if existing == nil {
                        importedCount += 1
                    }
                    continue
                }

                let metricID: String
                if let existingID = metricIDsByKind[sample.kind] {
                    metricID = existingID
                } else {
                    let record = try ensureHealthMetric(kind: sample.kind, db: db, timestamp: timestamp)
                    metricIDsByKind[sample.kind] = record.id
                    metricID = record.id
                }

                let existing = try AtlasMetricValueLogDBRecord.fetchOne(db, key: "health_metric_\(sample.id.lowercased())")?.domain
                let record = AtlasMetricValueLogRecord.make(
                    id: existing?.id ?? "health_metric_\(sample.id.lowercased())",
                    metricId: metricID,
                    protocolId: nil,
                    loggedAt: atlasTimestamp(from: sample.recordedAt),
                    numberValue: sample.value,
                    textValue: nil,
                    booleanValue: nil,
                    source: .health,
                    createdAt: existing?.createdAt ?? timestamp,
                    updatedAt: timestamp
                )
                try AtlasMetricValueLogDBRecord(record: record).save(db)
                if existing == nil {
                    importedCount += 1
                }
            }

            return importedCount
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
                mealSize: normalized.mealSize,
                mealComposition: normalized.mealComposition,
                fedState: normalized.fedState,
                appetite: normalized.appetite,
                hydration: normalized.hydration,
                giTags: normalized.giTags,
                note: normalized.note.flatMap(stringNilIfEmpty),
                tags: normalized.tags,
                presetKey: normalized.presetKey.flatMap(stringNilIfEmpty),
                source: .manual,
                createdAt: existing?.createdAt ?? timestamp,
                updatedAt: timestamp
            )
            try AtlasContextLogDBRecord(record: record).save(db)
            if let presetID = normalized.presetKey,
               var preset = try AtlasContextPresetDBRecord.fetchOne(db, key: presetID)?.domain {
                preset.lastUsedAt = timestamp
                preset.updatedAt = timestamp
                try AtlasContextPresetDBRecord(record: preset).update(db)
            }
            return record
        }
    }

    public func saveContextPreset(_ draft: AtlasContextPresetDraft, now: Date) async throws -> AtlasContextPresetRecord {
        try await stack.canonical.write { db in
            let normalized = try normalize(contextPresetDraft: draft)
            let timestamp = atlasTimestamp(from: now)
            let existingByID = normalized.id.flatMap { try? AtlasContextPresetDBRecord.fetchOne(db, key: $0)?.domain }
            let existingByTitle = existingByID ?? {
                guard normalized.id == nil else {
                    return nil
                }
                return try? AtlasContextPresetDBRecord
                    .filter(sql: "lower(title) = lower(?)", arguments: [normalized.title])
                    .fetchOne(db)?
                    .domain
            }()

            let record = AtlasContextPresetRecord.make(
                id: existingByTitle?.id ?? normalized.id ?? "context_preset_\(UUID().uuidString.lowercased())",
                title: normalized.title,
                mealTiming: normalized.mealTiming,
                mealSize: normalized.mealSize,
                mealComposition: normalized.mealComposition,
                fedState: normalized.fedState,
                appetite: normalized.appetite,
                hydration: normalized.hydration,
                giTags: normalized.giTags,
                createdAt: existingByTitle?.createdAt ?? timestamp,
                updatedAt: timestamp,
                lastUsedAt: existingByTitle?.lastUsedAt
            )
            try AtlasContextPresetDBRecord(record: record).save(db)
            return record
        }
    }

    public func deleteContextPreset(id: String) async throws {
        try await stack.canonical.write { db in
            guard let preset = try AtlasContextPresetDBRecord.fetchOne(db, key: id) else {
                return
            }
            try preset.delete(db)
        }
    }

    public func deleteContextEntry(id: String) async throws {
        try await stack.canonical.write { db in
            _ = try AtlasContextLogDBRecord.deleteOne(db, key: id)
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

    public func deleteWeightEntry(id: String) async throws {
        try await stack.canonical.write { db in
            _ = try AtlasWeightLogDBRecord.deleteOne(db, key: id)
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

    public func deleteSymptomEntry(id: String) async throws {
        try await stack.canonical.write { db in
            _ = try AtlasSymptomLogDBRecord.deleteOne(db, key: id)
        }
    }

    public func saveProgressMeasurement(_ draft: AtlasProgressMeasurementDraft, now: Date) async throws -> AtlasProgressMeasurementRecord {
        try await stack.canonical.write { db in
            let timestamp = atlasTimestamp(from: now)
            let existing = draft.id.flatMap { try? AtlasProgressMeasurementDBRecord.fetchOne(db, key: $0)?.domain }
            let record = AtlasProgressMeasurementRecord(
                id: existing?.id ?? draft.id ?? "progress_measurement_\(UUID().uuidString.lowercased())",
                protocolID: draft.protocolID,
                kind: draft.kind,
                value: draft.value,
                unit: draft.unit,
                note: draft.note.flatMap(stringNilIfEmpty),
                loggedAt: atlasTimestamp(from: draft.loggedAt),
                createdAt: existing?.createdAt ?? timestamp,
                updatedAt: timestamp
            )
            try AtlasProgressMeasurementDBRecord(record: record).save(db)
            return record
        }
    }

    public func saveProgressPhoto(_ draft: AtlasProgressPhotoDraft, now: Date) async throws -> AtlasProgressPhotoRecord {
        try await stack.canonical.write { db in
            let timestamp = atlasTimestamp(from: now)
            let recordID = draft.id ?? "progress_photo_\(UUID().uuidString.lowercased())"
            let relativePath = try atlasWriteProgressPhoto(data: draft.jpegData, id: recordID)
            let existing = draft.id.flatMap { try? AtlasProgressPhotoDBRecord.fetchOne(db, key: $0)?.domain }
            let record = AtlasProgressPhotoRecord(
                id: existing?.id ?? recordID,
                protocolID: draft.protocolID,
                angle: draft.angle,
                note: draft.note.flatMap(stringNilIfEmpty),
                relativeAssetPath: relativePath,
                loggedAt: atlasTimestamp(from: draft.loggedAt),
                createdAt: existing?.createdAt ?? timestamp,
                updatedAt: timestamp
            )
            try AtlasProgressPhotoDBRecord(record: record).save(db)
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

    public func deleteMetricValueEntry(id: String) async throws {
        try await stack.canonical.write { db in
            _ = try AtlasMetricValueLogDBRecord.deleteOne(db, key: id)
        }
    }
}

private func ensureHealthNutritionMetric(
    kind: AtlasHealthNutritionMetricKind,
    db: Database,
    timestamp: String
) throws -> AtlasCustomMetricRecord {
    if let existing = try AtlasCustomMetricDBRecord
        .filter(Column("metric_key") == kind.metricKey)
        .fetchOne(db)?
        .domain {
        return existing
    }

    let record = AtlasCustomMetricRecord.make(
        id: "metric_\(kind.metricKey)",
        protocolId: nil,
        metricKey: kind.metricKey,
        label: kind.label,
        valueType: .number,
        unit: kind.unit,
        scaleMin: nil,
        scaleMax: nil,
        createdAt: timestamp,
        updatedAt: timestamp,
        archivedAt: nil
    )
    try AtlasCustomMetricDBRecord(record: record).insert(db)
    return record
}

private func ensureHealthMetric(
    kind: AtlasHealthMetricKind,
    db: Database,
    timestamp: String
) throws -> AtlasCustomMetricRecord {
    if let existing = try AtlasCustomMetricDBRecord
        .filter(Column("metric_key") == kind.metricKey)
        .fetchOne(db)?
        .domain {
        return existing
    }

    let record = AtlasCustomMetricRecord.make(
        id: "metric_\(kind.metricKey)",
        protocolId: nil,
        metricKey: kind.metricKey,
        label: kind.label,
        valueType: .number,
        unit: kind.unit,
        scaleMin: nil,
        scaleMax: nil,
        createdAt: timestamp,
        updatedAt: timestamp,
        archivedAt: nil
    )
    try AtlasCustomMetricDBRecord(record: record).insert(db)
    return record
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
        || contextDraft.mealSize != nil
        || contextDraft.mealComposition != nil
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
        mealSize: contextDraft.mealSize,
        mealComposition: contextDraft.mealComposition,
        fedState: contextDraft.fedState,
        appetite: contextDraft.appetite,
        hydration: contextDraft.hydration,
        giTags: giTags,
        note: note,
        tags: tags,
        presetKey: contextDraft.presetKey?.trimmingCharacters(in: .whitespacesAndNewlines)
    )
}

private func normalize(contextPresetDraft: AtlasContextPresetDraft) throws -> AtlasContextPresetDraft {
    let title = contextPresetDraft.title.trimmingCharacters(in: .whitespacesAndNewlines)
    var giTags = Array(Set(contextPresetDraft.giTags)).sorted { $0.rawValue < $1.rawValue }
    if giTags.contains(.calm), giTags.count > 1 {
        giTags.removeAll { $0 == .calm }
    }

    let hasMeaningfulContent =
        contextPresetDraft.mealTiming != nil
        || contextPresetDraft.mealSize != nil
        || contextPresetDraft.mealComposition != nil
        || contextPresetDraft.fedState != nil
        || contextPresetDraft.appetite != nil
        || contextPresetDraft.hydration != nil
        || giTags.isEmpty == false

    guard title.isEmpty == false, hasMeaningfulContent else {
        throw AtlasMetricsRepositoryError.invalidContextPreset
    }

    return AtlasContextPresetDraft(
        id: contextPresetDraft.id,
        title: title,
        mealTiming: contextPresetDraft.mealTiming,
        mealSize: contextPresetDraft.mealSize,
        mealComposition: contextPresetDraft.mealComposition,
        fedState: contextPresetDraft.fedState,
        appetite: contextPresetDraft.appetite,
        hydration: contextPresetDraft.hydration,
        giTags: giTags
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
    let onboardingDraft = try atlasReadNutritionOnboardingDraft(db: db)
    let customMetrics = try AtlasCustomMetricDBRecord.fetchAll(db).map(\.domain)
    let contextPresets = try AtlasContextPresetDBRecord
        .order(sql: "COALESCE(last_used_at, updated_at) DESC, title ASC")
        .fetchAll(db)
        .map(\.domain)
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
    let workoutLogs = try AtlasWorkoutLogDBRecord
        .order(Column("started_at").desc)
        .fetchAll(db)
        .map(\.domain)
    let progressMeasurements = try AtlasProgressMeasurementDBRecord
        .order(Column("logged_at").desc)
        .fetchAll(db)
        .map(\.domain)
    let progressPhotos = try AtlasProgressPhotoDBRecord
        .order(Column("logged_at").desc)
        .fetchAll(db)
        .map(\.domain)
    let protocolChangeAudits = try AtlasProtocolChangeAuditDBRecord
        .order(Column("created_at").desc)
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
    let surfacePreferences = try readSurfacePreferences(db: db)
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
    let savedContextPresets = contextPresets.map {
        AtlasContextPresetSummary(
            id: $0.id,
            title: $0.title,
            mealTiming: $0.mealTiming,
            mealSize: $0.mealSize,
            mealComposition: $0.mealComposition,
            fedState: $0.fedState,
            appetite: $0.appetite,
            hydration: $0.hydration,
            giTags: $0.giTags,
            createdAt: atlasDate(from: $0.createdAt),
            updatedAt: atlasDate(from: $0.updatedAt),
            lastUsedAt: $0.lastUsedAt.map { atlasDate(from: $0) }
        )
    }
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
                mealSize: log.mealSize,
                mealComposition: log.mealComposition,
                fedState: log.fedState,
                appetite: log.appetite,
                hydration: log.hydration,
                giTags: log.giTags,
                note: log.note,
                tags: log.tags,
                presetKey: log.presetKey
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
    let recentWorkoutEntries = workoutLogs
        .prefix(5)
        .map {
            AtlasWorkoutEntrySummary(
                id: $0.id,
                activityKind: $0.activityKind,
                startedAt: atlasDate(from: $0.startedAt),
                endedAt: atlasDate(from: $0.endedAt),
                durationLabel: formatWorkoutDuration($0.durationMinutes),
                detailLabel: formatWorkoutDetail($0),
                source: $0.source
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
    let deterministicExplanations = buildDeterministicExplanationCards(
        symptomLogs: symptomLogs,
        contextLogs: contextLogs,
        weightLogs: weightLogs,
        metricLogs: metricLogs,
        metricsByID: Dictionary(uniqueKeysWithValues: customMetrics.map { ($0.id, $0) }),
        workoutLogs: workoutLogs,
        now: referenceDate
    )
    let weightTrend = buildWeightTrend(weightLogs: weightLogs)
    let symptomTrend = buildSymptomTrend(symptomLogs: symptomLogs, now: referenceDate)
    let contextTrend = buildContextTrend(contextLogs: contextLogs, now: referenceDate)
    let stackDashboard = surfacePreferences.stackDashboardEnabled
        ? buildStackDashboardSnapshot(
            context: context,
            logEvents: logEvents,
            inventory: inventory,
            referenceDate: referenceDate,
            renderMode: renderMode,
            privacyFormatter: privacyFormatter
        )
        : nil
    let nutritionSnapshot = buildNutritionSnapshot(
        contextLogs: contextLogs,
        contextPresets: contextPresets,
        workoutLogs: workoutLogs,
        weightLogs: weightLogs,
        onboardingDraft: onboardingDraft,
        now: referenceDate
    )
    let biometricsOverlay = surfacePreferences.biometricsOverlayEnabled
        ? buildBiometricsOverlaySnapshot(
            customMetrics: customMetrics,
            metricLogs: metricLogs,
            weightLogs: weightLogs,
            protocolChangeAudits: protocolChangeAudits,
            referenceDate: referenceDate,
            includeProtocolChanges: surfacePreferences.biometricsOverlayShowsProtocolChanges
        )
        : nil
    let progressEvidence = buildProgressEvidenceSnapshot(
        measurements: progressMeasurements,
        photos: progressPhotos
    )
    let adherenceTrend = buildAdherenceTrend(context: context, logEvents: logEvents, now: referenceDate)
    let weeklyReviewSeed = buildWeeklyReviewSeed(
        context: context,
        logEvents: logEvents,
        contextLogs: contextLogs,
        symptomLogs: symptomLogs,
        weightLogs: weightLogs,
        workoutLogs: workoutLogs,
        protocolChangeAudits: protocolChangeAudits,
        referenceDate: referenceDate,
        renderMode: renderMode,
        privacyFormatter: privacyFormatter,
        summarySettings: summarySettings,
        surfacePreferences: surfacePreferences,
        inventorySnapshot: inventory,
        plainLanguageSummary: weeklyRecapSummary,
        periodTitle: atlasWeeklyReviewPeriodTitle(for: referenceDate),
        includeCurrentStateFacts: true
    )
    let weeklyReviewHistory = atlasHistoricalWeeklyReviewSeeds(
        context: context,
        logEvents: logEvents,
        contextLogs: contextLogs,
        symptomLogs: symptomLogs,
        weightLogs: weightLogs,
        workoutLogs: workoutLogs,
        protocolChangeAudits: protocolChangeAudits,
        referenceDate: referenceDate,
        renderMode: renderMode,
        privacyFormatter: privacyFormatter,
        summarySettings: summarySettings,
        surfacePreferences: surfacePreferences,
        inventorySnapshot: inventory
    )

    return AtlasInsightsSnapshot(
        weightTrend: weightTrend,
        symptomTrend: symptomTrend,
        contextTrend: contextTrend,
        nutritionSnapshot: nutritionSnapshot,
        deterministicExplanations: deterministicExplanations,
        stackDashboard: stackDashboard,
        biometricsOverlay: biometricsOverlay,
        savedContextPresets: savedContextPresets,
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
        adherenceTrend: adherenceTrend,
        amountInSystem: buildAmountEstimateItems(context: context, logEvents: logEvents, now: referenceDate),
        episodeIntelligence: episodeIntelligence,
        customMetricDefinitions: definitions,
        recentContextEntries: recentContextEntries,
        recentWeightEntries: recentWeightEntries,
        recentWorkoutEntries: recentWorkoutEntries,
        recentSymptomEntries: recentSymptomEntries,
        recentMetricEntries: recentMetricEntries,
        weeklyRecapSummary: weeklyRecapSummary,
        episodeRecapSummary: episodeRecapSummary,
        weeklyReviewSeed: weeklyReviewSeed,
        weeklyReviewHistory: weeklyReviewHistory,
        progressEvidence: progressEvidence,
        hasAnyInsightData: contextLogs.isEmpty == false
            || weightLogs.isEmpty == false
            || workoutLogs.isEmpty == false
            || symptomLogs.isEmpty == false
            || metricLogs.isEmpty == false
            || progressMeasurements.isEmpty == false
            || progressPhotos.isEmpty == false
            || episodeIntelligence.hasAnyEpisodeData
            || context.pendingOccurrences.isEmpty == false
    )
}

private func buildStackDashboardSnapshot(
    context: AtlasCoreLoopContext,
    logEvents: [AtlasLogEventRecord],
    inventory: AtlasInventorySnapshot,
    referenceDate: Date,
    renderMode: AtlasPrivacyRenderMode,
    privacyFormatter: AtlasPrivacyFormatter
) -> AtlasStackDashboardSnapshot? {
    let activeProtocols = context.protocols.values
        .filter { $0.status == .active }
        .sorted { $0.createdAt > $1.createdAt }

    guard activeProtocols.count > 1 else {
        return nil
    }

    let weeklyFloor = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: referenceDate))
        ?? referenceDate
    let recentLogs = logEvents.filter {
        let loggedAt = atlasDate(from: $0.loggedAt)
        return loggedAt >= weeklyFloor && loggedAt <= referenceDate
    }
    let completedCount = recentLogs.filter { $0.eventType == .completed }.count
    let rescheduledCount = recentLogs.filter { $0.eventType == .rescheduled }.count
    let pending = context.pendingOccurrences.values.flatMap { $0 }
        .map { buildScheduledOccurrence(occurrence: $0, context: context, now: referenceDate) }
    let actionableTodayCount = pending.filter {
        Calendar.current.isDate($0.scheduledAt, inSameDayAs: referenceDate)
            && ($0.state == .due || $0.state == .overdue || $0.state == .upcoming)
    }.count

    let activeProtocolItems = activeProtocols.map { protocolRecord in
        let summary = buildProtocolSummary(
            protocolRecord: protocolRecord,
            alias: context.aliases[protocolRecord.id],
            protocolRules: context.protocolRules[protocolRecord.id] ?? [],
            revisionSlices: context.revisionSlices[protocolRecord.id] ?? [],
            pendingOccurrences: context.pendingOccurrences[protocolRecord.id] ?? [],
            now: referenceDate
        )
        let lowStockLabel = inventory.vials.first(where: { $0.linkedProtocolID == protocolRecord.id && $0.isLowStock })?.quantityLabel
        return AtlasStackDashboardProtocolItem(
            id: protocolRecord.id,
            title: privacyFormatter.title(
                canonical: summary.canonicalTitle,
                alias: summary.aliasTitle,
                mode: renderMode
            ),
            kindLabel: summary.kindLabel,
            cadenceLabel: summary.cadenceLabel,
            doseLabel: summary.doseLabel,
            nextDueLabel: summary.nextDueLabel,
            lowStockLabel: lowStockLabel
        )
    }

    let scheduleLoads = atlasStackDashboardTimeLoads(occurrences: pending, referenceDate: referenceDate)
    let lowStockCount = inventory.lowStockCount
    let burdenFacts = [
        AtlasExplainerFact(label: "Active protocols", value: String(activeProtocols.count)),
        AtlasExplainerFact(label: "Taken this week", value: String(completedCount)),
        AtlasExplainerFact(label: "Moved this week", value: String(rescheduledCount)),
        AtlasExplainerFact(label: "Inventory risk", value: String(lowStockCount)),
        AtlasExplainerFact(label: "Scheduled today", value: String(actionableTodayCount))
    ]

    return AtlasStackDashboardSnapshot(
        activeProtocolCount: activeProtocols.count,
        summary: "\(countPhrase(activeProtocols.count, singular: "active protocol")) and \(countPhrase(actionableTodayCount, singular: "scheduled anchor")) are visible today. \(lowStockCount == 0 ? "Inventory is clear." : "\(countPhrase(lowStockCount, singular: "inventory item")) needs attention.")",
        burdenFacts: burdenFacts,
        activeProtocols: activeProtocolItems,
        scheduleLoads: scheduleLoads
    )
}

private func atlasStackDashboardTimeLoads(
    occurrences: [AtlasScheduledOccurrence],
    referenceDate: Date
) -> [AtlasStackDashboardTimeLoad] {
    let todayOccurrences = occurrences.filter { Calendar.current.isDate($0.scheduledAt, inSameDayAs: referenceDate) }
    let buckets: [(String, String, Range<Int>)] = [
        ("morning", "Morning", 5..<11),
        ("midday", "Midday", 11..<15),
        ("evening", "Evening", 15..<20),
        ("late", "Late", 20..<24)
    ]

    return buckets.map { id, title, hours in
        let matches = todayOccurrences.filter { hours.contains(Calendar.current.component(.hour, from: $0.scheduledAt)) }
        return AtlasStackDashboardTimeLoad(
            id: id,
            title: title,
            scheduledCount: matches.count,
            detail: matches.isEmpty ? "No scheduled items." : "\(countPhrase(matches.count, singular: "item")) staged."
        )
    }
}

private struct AtlasBiometricsOverlayDescriptor {
    let id: String
    let title: String
    let subtitle: String
    let referenceRangeLabel: String?
}

private func buildBiometricsOverlaySnapshot(
    customMetrics: [AtlasCustomMetricRecord],
    metricLogs: [AtlasMetricValueLogRecord],
    weightLogs: [AtlasWeightLogRecord],
    protocolChangeAudits: [AtlasProtocolChangeAuditRecord],
    referenceDate: Date,
    includeProtocolChanges: Bool
) -> AtlasBiometricsOverlaySnapshot? {
    let calendar = Calendar.current
    let floor = calendar.date(byAdding: .day, value: -89, to: calendar.startOfDay(for: referenceDate)) ?? referenceDate
    let metricsByID = Dictionary(uniqueKeysWithValues: customMetrics.map { ($0.id, $0) })
    let recentProtocolChanges = includeProtocolChanges
        ? protocolChangeAudits.filter {
            let changedAt = atlasDate(from: $0.createdAt)
            return changedAt >= floor && changedAt <= referenceDate
        }
        : []

    var groups: [String: AtlasBiometricOverlayGroup] = [:]

    let recentWeights = weightLogs
        .filter { atlasDate(from: $0.loggedAt) >= floor }
        .prefix(8)
        .reversed()
    if recentWeights.isEmpty == false {
        let points = recentWeights.map {
            AtlasBiometricOverlayPoint(
                id: $0.id,
                label: formatWeightValue($0),
                loggedAt: atlasDate(from: $0.loggedAt),
                value: $0.value
            )
        }
        let latest = recentWeights.last ?? recentWeights.first!
        let oldest = recentWeights.first!
        let delta = latest.value - oldest.value
        let series = AtlasBiometricOverlaySeries(
            id: "weight",
            title: "Weight",
            subtitle: "Body composition anchor",
            latestValueLabel: formatWeightValue(latest),
            trendLabel: points.count > 1 ? atlasBiometricsDeltaLabel(delta: delta, unit: latest.unit.rawValue) : nil,
            points: Array(points),
            protocolChangeMarkers: atlasProtocolChangeMarkers(recentProtocolChanges)
        )
        groups["metabolic"] = AtlasBiometricOverlayGroup(
            id: "metabolic",
            title: "Metabolic & body composition",
            subtitle: "Keep weight and metabolic markers close to protocol shifts.",
            series: [series]
        )
    }

    let numericMetricLogs = metricLogs.filter { $0.numberValue != nil && atlasDate(from: $0.loggedAt) >= floor }
    let groupedLogs = Dictionary(grouping: numericMetricLogs, by: \.metricId)

    for metric in customMetrics {
        guard let descriptor = atlasBiometricsDescriptor(for: metric),
              let logs = groupedLogs[metric.id],
              logs.isEmpty == false else {
            continue
        }

        let orderedLogs = logs.sorted { atlasDate(from: $0.loggedAt) < atlasDate(from: $1.loggedAt) }
        let points = orderedLogs.compactMap { log in
            log.numberValue.map {
                AtlasBiometricOverlayPoint(
                    id: log.id,
                    label: formatMetricValue(log: log, metric: metric),
                    loggedAt: atlasDate(from: log.loggedAt),
                    value: $0
                )
            }
        }
        guard let latestLog = orderedLogs.last else {
            continue
        }
        let firstValue = orderedLogs.first?.numberValue ?? latestLog.numberValue ?? 0
        let latestValue = latestLog.numberValue ?? firstValue
        let trendLabel = orderedLogs.count > 1 ? atlasBiometricsDeltaLabel(delta: latestValue - firstValue, unit: metric.unit) : nil
        let series = AtlasBiometricOverlaySeries(
            id: metric.id,
            title: metric.label,
            subtitle: metric.unit,
            latestValueLabel: formatMetricValue(log: latestLog, metric: metric),
            trendLabel: trendLabel,
            referenceRangeLabel: descriptor.referenceRangeLabel,
            points: points,
            protocolChangeMarkers: atlasProtocolChangeMarkers(recentProtocolChanges)
        )

        if var existing = groups[descriptor.id] {
            existing.series.append(series)
            existing.series.sort { $0.title < $1.title }
            groups[descriptor.id] = existing
        } else {
            groups[descriptor.id] = AtlasBiometricOverlayGroup(
                id: descriptor.id,
                title: descriptor.title,
                subtitle: descriptor.subtitle,
                series: [series]
            )
        }
    }

    let orderedGroups = ["metabolic", "recovery", "cardio", "hormones", "lipids", "liver"]
        .compactMap { groups[$0] }
        .filter { $0.series.isEmpty == false }

    guard orderedGroups.isEmpty == false else {
        return nil
    }

    return AtlasBiometricsOverlaySnapshot(
        summary: includeProtocolChanges
            ? "Biometrics are shown alongside recent protocol changes."
            : "Numeric biometrics and labs are grouped into reusable trend panels.",
        groups: orderedGroups
    )
}

private func atlasBiometricsDescriptor(for metric: AtlasCustomMetricRecord) -> AtlasBiometricsOverlayDescriptor? {
    let key = metric.metricKey.lowercased()
    let label = metric.label.lowercased()

    switch true {
    case key.contains("glucose") || label.contains("glucose") || key.contains("a1c") || label.contains("a1c") || label.contains("insulin"):
        return .init(id: "metabolic", title: "Metabolic & body composition", subtitle: "Glucose tolerance, insulin response, and body trend anchors.", referenceRangeLabel: atlasLabReferenceRangeLabel(for: metric.label))
    case label.contains("sleep") || label.contains("readiness") || label.contains("recovery") || label.contains("soreness"):
        return .init(id: "recovery", title: "Recovery", subtitle: "Recovery metrics sit best next to schedule intensity and protocol changes.", referenceRangeLabel: nil)
    case label.contains("blood pressure") || label.contains("resting heart rate") || label == "hrv" || label.contains("heart rate") || label.contains("waist"):
        return .init(id: "cardio", title: "Cardio & recovery load", subtitle: "Cardiovascular and body measurements that often move with stack stress.", referenceRangeLabel: nil)
    case label.contains("testosterone") || label.contains("estradiol") || label.contains("shbg"):
        return .init(id: "hormones", title: "Hormones", subtitle: "Optional hormone tracking for advanced users who want longer-cycle overlays.", referenceRangeLabel: atlasLabReferenceRangeLabel(for: metric.label))
    case label.contains("ldl") || label.contains("hdl") || label.contains("triglyceride"):
        return .init(id: "lipids", title: "Lipids", subtitle: "Longer-horizon markers that make sense in stack and refill reviews.", referenceRangeLabel: atlasLabReferenceRangeLabel(for: metric.label))
    case label == "ast" || label == "alt" || label.contains("liver"):
        return .init(id: "liver", title: "Liver", subtitle: "Helpful when appetite, recovery, or adjunct load changes around a protocol.", referenceRangeLabel: atlasLabReferenceRangeLabel(for: metric.label))
    default:
        return nil
    }
}

private func atlasProtocolChangeMarkers(
    _ audits: [AtlasProtocolChangeAuditRecord]
) -> [AtlasProtocolChangeOverlayMarker] {
    Array(audits.prefix(4)).map {
        AtlasProtocolChangeOverlayMarker(
            id: $0.id,
            title: $0.summary ?? "Protocol change",
            date: atlasDate(from: $0.createdAt),
            detail: $0.summary
        )
    }
}

private func atlasLabReferenceRangeLabel(for label: String) -> String? {
    switch label.lowercased() {
    case "fasting glucose":
        return "70-99 mg/dL"
    case "hba1c":
        return "4.0-5.6%"
    case "fasting insulin":
        return "2-25 uIU/mL"
    case "ldl-c":
        return "<100 mg/dL"
    case "hdl-c":
        return "40+ mg/dL"
    case "triglycerides":
        return "<150 mg/dL"
    case "ast":
        return "10-40 U/L"
    case "alt":
        return "7-56 U/L"
    case "total testosterone":
        return "300-1000 ng/dL"
    case "free testosterone":
        return "35-155 pg/mL"
    default:
        return nil
    }
}

private func atlasBiometricsDeltaLabel(delta: Double, unit: String?) -> String {
    let direction: String
    switch delta {
    case let value where value > 0.001:
        direction = "Up"
    case let value where value < -0.001:
        direction = "Down"
    default:
        direction = "Stable"
    }

    guard direction != "Stable" else {
        return "Stable across this window"
    }

    let unitSuffix = unit.map { " \($0)" } ?? ""
    let magnitude = abs(delta).formatted(.number.precision(.fractionLength(0...2)))
    return "\(direction) \(magnitude)\(unitSuffix) across this window"
}

private func buildWeeklyReviewSeed(
    context: AtlasCoreLoopContext,
    logEvents: [AtlasLogEventRecord],
    contextLogs: [AtlasContextLogRecord],
    symptomLogs: [AtlasSymptomLogRecord],
    weightLogs: [AtlasWeightLogRecord],
    workoutLogs: [AtlasWorkoutLogRecord],
    protocolChangeAudits: [AtlasProtocolChangeAuditRecord],
    referenceDate: Date,
    renderMode: AtlasPrivacyRenderMode,
    privacyFormatter: AtlasPrivacyFormatter,
    summarySettings: AtlasSummarySettingsSnapshot,
    surfacePreferences: AtlasSurfacePreferences,
    inventorySnapshot: AtlasInventorySnapshot,
    plainLanguageSummary: AtlasGeneratedSummary?,
    periodTitle: String,
    includeCurrentStateFacts: Bool
) -> AtlasWeeklyReviewSeed? {
    let calendar = Calendar.current
    let startOfToday = calendar.startOfDay(for: referenceDate)
    let windowStart = calendar.date(byAdding: .day, value: -(atlasWeeklyReviewWindowDays - 1), to: startOfToday) ?? startOfToday

    let weeklyLogs = logEvents.filter {
        let loggedAt = atlasDate(from: $0.loggedAt)
        return loggedAt >= windowStart && loggedAt <= referenceDate
    }
    let weeklyContext = contextLogs.filter {
        let loggedAt = atlasDate(from: $0.loggedAt)
        return loggedAt >= windowStart && loggedAt <= referenceDate
    }
    let weeklySymptoms = symptomLogs.filter {
        let loggedAt = atlasDate(from: $0.loggedAt)
        return loggedAt >= windowStart && loggedAt <= referenceDate
    }
    let weeklyWeights = weightLogs.filter {
        let loggedAt = atlasDate(from: $0.loggedAt)
        return loggedAt >= windowStart && loggedAt <= referenceDate
    }
    let weeklyWorkouts = workoutLogs.filter {
        let startedAt = atlasDate(from: $0.startedAt)
        return startedAt >= windowStart && startedAt <= referenceDate
    }
    let weeklyProtocolChanges = protocolChangeAudits.filter {
        let createdAt = atlasDate(from: $0.createdAt)
        return createdAt >= windowStart && createdAt <= referenceDate
    }

    let pendingOccurrences = context.pendingOccurrences.values
        .flatMap { $0 }
        .map { occurrence in
            buildScheduledOccurrence(
                occurrence: occurrence,
                context: context,
                now: referenceDate
            )
        }
        .sorted { $0.scheduledAt < $1.scheduledAt }
    let nextDue = pendingOccurrences.first(where: { $0.state == .due || $0.state == .upcoming })
    let overdueCount = pendingOccurrences.filter { $0.state == .due || $0.state == .overdue }.count

    let completedCount = weeklyLogs.filter { $0.eventType == .completed }.count
    let skippedCount = weeklyLogs.filter { $0.eventType == .skipped }.count
    let rescheduledCount = weeklyLogs.filter { $0.eventType == .rescheduled }.count
    let activeProtocolCount = context.protocols.values.filter { $0.status == .active }.count
    let latestWeight = weeklyWeights.first ?? weightLogs.first
    let latestProtocolChange = weeklyProtocolChanges.first
    let stackSummary = buildWeeklyReviewStackSummary(
        context: context,
        weeklyLogs: weeklyLogs,
        weeklyProtocolChanges: weeklyProtocolChanges,
        inventorySnapshot: inventorySnapshot,
        enabled: surfacePreferences.stackDashboardEnabled,
        referenceDate: referenceDate
    )
    let protocolChangeSummary = latestProtocolChange.map { audit in
        let title = context.protocols[audit.protocolId].map {
            privacyFormatter.title(
                canonical: $0.name,
                alias: context.aliases[audit.protocolId]?.aliasLabel,
                mode: renderMode
            )
        }
        return AtlasWeeklyReviewProtocolChangeSummary(
            changeCount: weeklyProtocolChanges.count,
            latestProtocolID: audit.protocolId,
            latestTitle: title,
            latestSummary: audit.summary,
            latestChangedAt: atlasDate(from: audit.createdAt),
            supportingLogCount: weeklyLogs.filter { $0.protocolId == audit.protocolId }.count,
            supportingContextCount: weeklyContext.filter { $0.protocolId == audit.protocolId }.count
        )
    } ?? (weeklyProtocolChanges.isEmpty ? nil : AtlasWeeklyReviewProtocolChangeSummary(changeCount: weeklyProtocolChanges.count))
    let protocolFollowUpSummary = buildWeeklyReviewProtocolFollowUpSummary(
        protocolChangeAudits: protocolChangeAudits,
        logEvents: logEvents,
        contextLogs: contextLogs,
        context: context,
        referenceDate: referenceDate,
        renderMode: renderMode,
        privacyFormatter: privacyFormatter
    )

    guard completedCount + skippedCount + rescheduledCount + overdueCount + weeklyContext.count + weeklySymptoms.count + weeklyWeights.count + weeklyWorkouts.count + weeklyProtocolChanges.count + activeProtocolCount > 0 else {
        return nil
    }

    let nextDueLabel = nextDue.map {
        privacyFormatter.title(canonical: $0.canonicalTitle, alias: $0.aliasTitle, mode: renderMode)
    }
    var sourceSections = [
        atlasSummarySection(
            "weekly_activity",
            "Protocol activity",
            [
                atlasSummaryFact("completed_logs", "Completed logs", String(completedCount)),
                atlasSummaryFact("skipped_logs", "Skipped logs", String(skippedCount)),
                atlasSummaryFact("rescheduled_logs", "Rescheduled logs", String(rescheduledCount)),
                atlasSummaryFact("open_due_items", "Open due items", String(overdueCount))
            ]
        ),
        atlasSummarySection(
            "weekly_supporting_records",
            "Supporting records",
            [
                atlasSummaryFact("context_entries", "Context entries", String(weeklyContext.count)),
                atlasSummaryFact("symptom_entries", "Symptom entries", String(weeklySymptoms.count)),
                atlasSummaryFact("weight_entries", "Weight entries", String(weeklyWeights.count)),
                atlasSummaryFact("workout_entries", "Workout entries", String(weeklyWorkouts.count))
            ]
        ),
    ]
    if let protocolChangeSummary {
        sourceSections.append(
            atlasSummarySection(
                "weekly_protocol_changes",
                "Protocol changes",
                [
                    atlasSummaryFact("protocol_change_count", "Changes this week", String(protocolChangeSummary.changeCount))
                ] + (protocolChangeSummary.latestTitle.map {
                    [atlasSummaryFact("protocol_change_latest_title", "Latest protocol", $0)]
                } ?? []) + (protocolChangeSummary.latestChangedAt.map {
                    [atlasSummaryFact(
                        "protocol_change_latest_date",
                        "Latest change",
                        $0.formatted(date: .abbreviated, time: .omitted)
                    )]
                } ?? []) + (protocolChangeSummary.latestSummary.map {
                    [atlasSummaryFact("protocol_change_latest_summary", "Latest summary", $0)]
                } ?? [])
            )
        )
    }
    if includeCurrentStateFacts {
        sourceSections.append(
            atlasSummarySection(
                "weekly_state",
                "Current state",
                [
                    atlasSummaryFact("active_protocols", "Active protocols", String(activeProtocolCount))
                ] + (latestWeight.map {
                    [atlasSummaryFact(
                        "latest_weight",
                        "Latest weight",
                        "\(atlasWeeklyReviewWeightLabel($0)) on \(atlasWeeklyReviewSummaryDateLabel($0.loggedAt))"
                    )]
                } ?? []) + (nextDue.map {
                    [atlasSummaryFact(
                        "next_due",
                        "Next due",
                        "\(privacyFormatter.title(canonical: $0.canonicalTitle, alias: $0.aliasTitle, mode: renderMode)) due \(relativeDueLabel(for: $0.scheduledAt))"
                    )]
                } ?? [])
            )
        )
    }
    if let protocolFollowUpSummary {
        sourceSections.append(
            atlasSummarySection(
                "weekly_protocol_follow_up",
                "Protocol follow-up",
                [
                    atlasSummaryFact("follow_up_protocol", "Latest changed protocol", protocolFollowUpSummary.title ?? "Atlas protocol"),
                    atlasSummaryFact("follow_up_change_type", "Change type", protocolFollowUpSummary.changeTypeTitle),
                    atlasSummaryFact("follow_up_window", "Follow-up window", "\(protocolFollowUpSummary.windowDays) day(s)"),
                    atlasSummaryFact("follow_up_completed", "Completed logs after change", String(protocolFollowUpSummary.completedCount)),
                    atlasSummaryFact("follow_up_context", "Context entries after change", String(protocolFollowUpSummary.contextEntryCount))
                ]
            )
        )
    }
    if let stackSummary {
        sourceSections.append(
            atlasSummarySection(
                "weekly_stack_view",
                "Stack view",
                [
                    atlasSummaryFact("stack_active_protocols", "Active stack items", String(stackSummary.activeProtocolCount)),
                    atlasSummaryFact("stack_protocol_changes", "Protocols changed", String(stackSummary.protocolsWithChanges)),
                    atlasSummaryFact("stack_completed", "Completed logs", String(stackSummary.weeklyCompletedCount)),
                    atlasSummaryFact("stack_rescheduled", "Moved logs", String(stackSummary.weeklyRescheduledCount)),
                    atlasSummaryFact("stack_inventory_risk", "Inventory risk", String(stackSummary.lowStockRiskCount))
                ]
            )
        )
    }

    return AtlasWeeklyReviewSeed(
        periodTitle: periodTitle,
        generatedAt: referenceDate,
        windowStart: windowStart,
        windowEnd: referenceDate,
        summarySettingEnabled: summarySettings.onDeviceEnabled,
        plainLanguageSummary: plainLanguageSummary,
        fallbackSummary: buildWeeklyReviewFallbackSummary(
            completedCount: completedCount,
            skippedCount: skippedCount,
            rescheduledCount: rescheduledCount,
            overdueCount: overdueCount,
            activeProtocolCount: activeProtocolCount,
            contextEntryCount: weeklyContext.count,
            symptomEntryCount: weeklySymptoms.count,
            workoutEntryCount: weeklyWorkouts.count,
            latestWeightLabel: latestWeight.map {
                "\(atlasWeeklyReviewWeightLabel($0)) on \(atlasWeeklyReviewSummaryDateLabel($0.loggedAt))"
            },
            nextDueTitle: nextDueLabel,
            protocolChangeSummary: protocolChangeSummary
        ),
        sourceSections: sourceSections,
        completedCount: completedCount,
        skippedCount: skippedCount,
        rescheduledCount: rescheduledCount,
        overdueCount: overdueCount,
        activeProtocolCount: activeProtocolCount,
        contextEntryCount: weeklyContext.count,
        symptomEntryCount: weeklySymptoms.count,
        weightEntryCount: weeklyWeights.count,
        workoutEntryCount: weeklyWorkouts.count,
        nextDueProtocolID: nextDue?.protocolID,
        nextDueTitle: nextDueLabel,
        stackSummary: stackSummary,
        protocolChangeSummary: protocolChangeSummary,
        protocolFollowUpSummary: protocolFollowUpSummary
    )
}

private func buildWeeklyReviewFallbackSummary(
    completedCount: Int,
    skippedCount: Int,
    rescheduledCount: Int,
    overdueCount: Int,
    activeProtocolCount: Int,
    contextEntryCount: Int,
    symptomEntryCount: Int,
    workoutEntryCount: Int,
    latestWeightLabel: String?,
    nextDueTitle: String?,
    protocolChangeSummary: AtlasWeeklyReviewProtocolChangeSummary?
) -> String {
    var parts = [
        "Last 7 days: \(countPhrase(completedCount, singular: "completed log")) across \(countPhrase(activeProtocolCount, singular: "active protocol"))."
    ]

    let schedulePhrases = [
        skippedCount > 0 ? countPhrase(skippedCount, singular: "skipped log") : nil,
        rescheduledCount > 0 ? countPhrase(rescheduledCount, singular: "rescheduled item") : nil,
        overdueCount > 0 ? countPhrase(overdueCount, singular: "open due item") : nil
    ].compactMap { $0 }
    if schedulePhrases.isEmpty == false {
        parts.append("Schedule movement also included \(naturalList(schedulePhrases)).")
    }

    let supportingPhrases = [
        contextEntryCount > 0 ? countPhrase(contextEntryCount, singular: "context entry", plural: "context entries") : nil,
        symptomEntryCount > 0 ? countPhrase(symptomEntryCount, singular: "symptom entry", plural: "symptom entries") : nil,
        workoutEntryCount > 0 ? countPhrase(workoutEntryCount, singular: "workout log") : nil
    ].compactMap { $0 }
    if supportingPhrases.isEmpty {
        parts.append("Supporting context was light this week.")
    } else {
        parts.append("Supporting records: \(naturalList(supportingPhrases)).")
    }

    if let latestWeightLabel {
        parts.append("Latest weight: \(latestWeightLabel).")
    }
    if let nextDueTitle {
        parts.append("Next due: \(nextDueTitle).")
    }
    if let protocolChangeSummary {
        var protocolChangeLine = "\(countPhrase(protocolChangeSummary.changeCount, singular: "protocol update")) landed during the review window."
        if let latestTitle = protocolChangeSummary.latestTitle {
            protocolChangeLine += " The latest was on \(latestTitle)"
            if let latestChangedAt = protocolChangeSummary.latestChangedAt {
                protocolChangeLine += " on \(latestChangedAt.formatted(date: .abbreviated, time: .omitted))"
            }
            protocolChangeLine += "."
        }
        parts.append(protocolChangeLine)
    }

    return parts.joined(separator: " ")
}

private func atlasHistoricalWeeklyReviewSeeds(
    context: AtlasCoreLoopContext,
    logEvents: [AtlasLogEventRecord],
    contextLogs: [AtlasContextLogRecord],
    symptomLogs: [AtlasSymptomLogRecord],
    weightLogs: [AtlasWeightLogRecord],
    workoutLogs: [AtlasWorkoutLogRecord],
    protocolChangeAudits: [AtlasProtocolChangeAuditRecord],
    referenceDate: Date,
    renderMode: AtlasPrivacyRenderMode,
    privacyFormatter: AtlasPrivacyFormatter,
    summarySettings: AtlasSummarySettingsSnapshot,
    surfacePreferences: AtlasSurfacePreferences,
    inventorySnapshot: AtlasInventorySnapshot
) -> [AtlasWeeklyReviewSeed] {
    let calendar = Calendar.current

    return (1...atlasWeeklyReviewArchiveWeeks).compactMap { offset in
        guard let historicalDate = calendar.date(byAdding: .day, value: -(offset * atlasWeeklyReviewWindowDays), to: referenceDate) else {
            return nil
        }

        return buildWeeklyReviewSeed(
            context: context,
            logEvents: logEvents,
            contextLogs: contextLogs,
            symptomLogs: symptomLogs,
            weightLogs: weightLogs,
            workoutLogs: workoutLogs,
            protocolChangeAudits: protocolChangeAudits,
            referenceDate: historicalDate,
            renderMode: renderMode,
            privacyFormatter: privacyFormatter,
            summarySettings: summarySettings,
            surfacePreferences: surfacePreferences,
            inventorySnapshot: inventorySnapshot,
            plainLanguageSummary: nil,
            periodTitle: atlasWeeklyReviewPeriodTitle(for: historicalDate),
            includeCurrentStateFacts: false
        )
    }
}

private func buildWeeklyReviewStackSummary(
    context: AtlasCoreLoopContext,
    weeklyLogs: [AtlasLogEventRecord],
    weeklyProtocolChanges: [AtlasProtocolChangeAuditRecord],
    inventorySnapshot: AtlasInventorySnapshot,
    enabled: Bool,
    referenceDate: Date
) -> AtlasWeeklyReviewStackSummary? {
    guard enabled else {
        return nil
    }

    let activeProtocolCount = context.protocols.values.filter { $0.status == .active }.count
    guard activeProtocolCount > 1 else {
        return nil
    }

    let changedProtocolCount = Set(weeklyProtocolChanges.map(\.protocolId)).count
    let completedCount = weeklyLogs.filter { $0.eventType == .completed }.count
    let rescheduledCount = weeklyLogs.filter { $0.eventType == .rescheduled }.count
    let lowStockCount = inventorySnapshot.lowStockCount
    let scheduleCount = context.pendingOccurrences.values
        .flatMap { $0 }
        .filter { Calendar.current.isDate(atlasDate(from: $0.scheduledAt), inSameDayAs: referenceDate) }
        .count

    return AtlasWeeklyReviewStackSummary(
        activeProtocolCount: activeProtocolCount,
        protocolsWithChanges: changedProtocolCount,
        weeklyCompletedCount: completedCount,
        weeklyRescheduledCount: rescheduledCount,
        lowStockRiskCount: lowStockCount,
        burdenSummary: "The current stack carried \(countPhrase(activeProtocolCount, singular: "active protocol")) with \(countPhrase(scheduleCount, singular: "visible schedule anchor")) on the current day and \(countPhrase(lowStockCount, singular: "inventory risk")) across the same window."
    )
}

private func buildWeeklyReviewProtocolFollowUpSummary(
    protocolChangeAudits: [AtlasProtocolChangeAuditRecord],
    logEvents: [AtlasLogEventRecord],
    contextLogs: [AtlasContextLogRecord],
    context: AtlasCoreLoopContext,
    referenceDate: Date,
    renderMode: AtlasPrivacyRenderMode,
    privacyFormatter: AtlasPrivacyFormatter
) -> AtlasWeeklyReviewProtocolFollowUpSummary? {
    let calendar = Calendar.current
    let followUpFloor = calendar.date(byAdding: .day, value: -(atlasWeeklyReviewProtocolFollowUpDays - 1), to: calendar.startOfDay(for: referenceDate))
        ?? referenceDate
    guard let latestAudit = protocolChangeAudits.first(where: {
        let changedAt = atlasDate(from: $0.createdAt)
        return changedAt >= followUpFloor && changedAt <= referenceDate
    }) else {
        return nil
    }

    let changedAt = atlasDate(from: latestAudit.createdAt)
    let protocolID = latestAudit.protocolId
    let logsSinceChange = logEvents.filter {
        $0.protocolId == protocolID && atlasDate(from: $0.loggedAt) >= changedAt && atlasDate(from: $0.loggedAt) <= referenceDate
    }
    let contextSinceChange = contextLogs.filter {
        $0.protocolId == protocolID && atlasDate(from: $0.loggedAt) >= changedAt && atlasDate(from: $0.loggedAt) <= referenceDate
    }
    let windowDays = max(1, calendar.dateComponents([.day], from: calendar.startOfDay(for: changedAt), to: calendar.startOfDay(for: referenceDate)).day.map { $0 + 1 } ?? 1)
    let title = context.protocols[protocolID].map {
        privacyFormatter.title(
            canonical: $0.name,
            alias: context.aliases[protocolID]?.aliasLabel,
            mode: renderMode
        )
    }

    return AtlasWeeklyReviewProtocolFollowUpSummary(
        protocolID: protocolID,
        title: title,
        changeTypeTitle: latestAudit.changeType.explanationTitle,
        summary: latestAudit.summary,
        changedAt: changedAt,
        windowDays: min(windowDays, atlasWeeklyReviewProtocolFollowUpDays),
        completedCount: logsSinceChange.filter { $0.eventType == .completed }.count,
        skippedCount: logsSinceChange.filter { $0.eventType == .skipped }.count,
        rescheduledCount: logsSinceChange.filter { $0.eventType == .rescheduled }.count,
        contextEntryCount: contextSinceChange.count
    )
}

private func atlasWeeklyReviewPeriodTitle(for referenceDate: Date) -> String {
    let calendar = Calendar.current
    let windowStart = calendar.date(byAdding: .day, value: -(atlasWeeklyReviewWindowDays - 1), to: calendar.startOfDay(for: referenceDate))
        ?? referenceDate
    return "\(windowStart.formatted(date: .abbreviated, time: .omitted)) - \(referenceDate.formatted(date: .abbreviated, time: .omitted))"
}

private func atlasWeeklyReviewWeightLabel(_ record: AtlasWeightLogRecord) -> String {
    let value = String(format: record.value.rounded() == record.value ? "%.0f" : "%.1f", record.value)
    return "\(value) \(record.unit.rawValue)"
}

private func atlasWeeklyReviewSummaryDateLabel(_ timestamp: String) -> String {
    atlasDate(from: timestamp).formatted(date: .abbreviated, time: .omitted)
}

private func countPhrase(_ count: Int, singular: String, plural: String? = nil) -> String {
    let pluralValue = plural ?? singular + "s"
    return "\(count) \(count == 1 ? singular : pluralValue)"
}

private func naturalList(_ items: [String]) -> String {
    switch items.count {
    case 0:
        return ""
    case 1:
        return items[0]
    case 2:
        return "\(items[0]) and \(items[1])"
    default:
        return items.dropLast().joined(separator: ", ") + ", and " + (items.last ?? "")
    }
}

private struct AtlasDeterministicExplanationCandidate {
    let symptomKey: String
    let kind: AtlasDeterministicInsightKind
    let card: AtlasDeterministicInsightCard
    let matchCount: Int
    let coverage: Double
    let latestMatchAt: Date
}

private struct AtlasRelationshipEvidenceAccumulator {
    let title: String
    var symptomIDs: Set<String>
    var relatedRecordIDs: Set<String>
    var latestMatchAt: Date
}

private struct AtlasContextRelationshipDescriptor {
    let id: String
    let title: String
}

private struct AtlasMetricRelationshipDescriptor {
    let id: String
    let title: String
}

private func buildDeterministicExplanationCards(
    symptomLogs: [AtlasSymptomLogRecord],
    contextLogs: [AtlasContextLogRecord],
    weightLogs: [AtlasWeightLogRecord],
    metricLogs: [AtlasMetricValueLogRecord],
    metricsByID: [String: AtlasCustomMetricRecord],
    workoutLogs: [AtlasWorkoutLogRecord],
    now: Date
) -> [AtlasDeterministicInsightCard] {
    let calendar = Calendar.current
    let windowStart = calendar.date(byAdding: .day, value: -atlasInsightsSymptomWindowDays, to: now) ?? now
    let contextCutoff = windowStart.addingTimeInterval(-(atlasInsightsExplainabilityContextWindowHours * 60 * 60))
    let weightCutoff = windowStart.addingTimeInterval(-(atlasInsightsExplainabilityWeightWindowHours * 60 * 60))
    let metricCutoff = windowStart.addingTimeInterval(-(atlasInsightsExplainabilityMetricWindowHours * 60 * 60))
    let workoutCutoff = windowStart.addingTimeInterval(-(atlasInsightsExplainabilityWorkoutWindowHours * 60 * 60))

    let recentSymptoms = symptomLogs.filter { atlasDate(from: $0.loggedAt) >= windowStart }
    let nearbyContexts = contextLogs.filter { atlasDate(from: $0.loggedAt) >= contextCutoff }
    let nearbyWeights = weightLogs.filter { atlasDate(from: $0.loggedAt) >= weightCutoff }
    let nearbyMetricLogs = metricLogs.filter { atlasDate(from: $0.loggedAt) >= metricCutoff }
    let nearbyWorkouts = workoutLogs.filter { atlasDate(from: $0.endedAt) >= workoutCutoff }

    let groupedSymptoms = Dictionary(grouping: recentSymptoms) {
        normalizedInsightSymptomKey($0.symptomKey)
    }

    let candidates = groupedSymptoms.keys.sorted().flatMap { key -> [AtlasDeterministicExplanationCandidate] in
        let entries = groupedSymptoms[key] ?? []
        guard entries.count >= atlasInsightsExplainabilityMinimumMatches else {
            return []
        }

        let displaySymptom = displayInsightSymptomTitle(from: entries.first?.symptomKey ?? key)
        return buildContextExplanationCandidates(
            symptomKey: key,
            symptomDisplay: displaySymptom,
            symptomLogs: entries,
            contextLogs: nearbyContexts
        ) + buildWeightExplanationCandidates(
            symptomKey: key,
            symptomDisplay: displaySymptom,
            symptomLogs: entries,
            weightLogs: nearbyWeights
        ) + buildMetricExplanationCandidates(
            symptomKey: key,
            symptomDisplay: displaySymptom,
            symptomLogs: entries,
            metricLogs: nearbyMetricLogs,
            metricsByID: metricsByID
        ) + buildWorkoutExplanationCandidates(
            symptomKey: key,
            symptomDisplay: displaySymptom,
            symptomLogs: entries,
            workoutLogs: nearbyWorkouts
        )
    }

    let sortedCandidates = candidates
        .sorted {
            if $0.matchCount != $1.matchCount {
                return $0.matchCount > $1.matchCount
            }
            if $0.coverage != $1.coverage {
                return $0.coverage > $1.coverage
            }
            if $0.latestMatchAt != $1.latestMatchAt {
                return $0.latestMatchAt > $1.latestMatchAt
            }
            return $0.card.title < $1.card.title
        }
    var selectedKeys: Set<String> = []
    var selectedCards: [AtlasDeterministicInsightCard] = []

    for candidate in sortedCandidates {
        let selectionKey = "\(candidate.symptomKey)::\(candidate.kind.rawValue)"
        guard selectedKeys.contains(selectionKey) == false else {
            continue
        }
        selectedKeys.insert(selectionKey)
        selectedCards.append(candidate.card)
        if selectedCards.count == atlasInsightsExplainabilityMaxCards {
            break
        }
    }

    return selectedCards
}

private func buildContextExplanationCandidates(
    symptomKey: String,
    symptomDisplay: String,
    symptomLogs: [AtlasSymptomLogRecord],
    contextLogs: [AtlasContextLogRecord]
) -> [AtlasDeterministicExplanationCandidate] {
    var accumulators: [String: AtlasRelationshipEvidenceAccumulator] = [:]

    for symptom in symptomLogs {
        let symptomDate = atlasDate(from: symptom.loggedAt)
        for context in contextLogs {
            let contextDate = atlasDate(from: context.loggedAt)
            let distance = abs(symptomDate.timeIntervalSince(contextDate))
            guard distance <= atlasInsightsExplainabilityContextWindowHours * 60 * 60 else {
                continue
            }

            for descriptor in contextRelationshipDescriptors(for: context, symptomKey: symptomKey) {
                var accumulator = accumulators[descriptor.id] ?? AtlasRelationshipEvidenceAccumulator(
                    title: descriptor.title,
                    symptomIDs: [],
                    relatedRecordIDs: [],
                    latestMatchAt: symptomDate
                )
                accumulator.symptomIDs.insert(symptom.id)
                accumulator.relatedRecordIDs.insert(context.id)
                accumulator.latestMatchAt = max(accumulator.latestMatchAt, symptomDate)
                accumulators[descriptor.id] = accumulator
            }
        }
    }

    return accumulators.compactMap { descriptorID, accumulator in
        let coverage = Double(accumulator.symptomIDs.count) / Double(symptomLogs.count)
        guard accumulator.symptomIDs.count >= atlasInsightsExplainabilityMinimumMatches,
              coverage >= atlasInsightsExplainabilityMinimumCoverage else {
            return nil
        }

        let descriptorTitle = accumulator.title.lowercased()
        let summary = "Recent \(symptomDisplay.lowercased()) entries showed up near \(descriptorTitle) context."
        let facts = [
            AtlasExplainerFact(
                label: "Observed",
                value: "\(accumulator.symptomIDs.count) of \(symptomLogs.count) recent \(symptomDisplay.lowercased()) entries landed within 6 hours of \(descriptorTitle) context."
            ),
            AtlasExplainerFact(
                label: "Window",
                value: "Last \(atlasInsightsSymptomWindowDays) days • nearby means within 6 hours."
            ),
            AtlasExplainerFact(
                label: "Records",
                value: "\(pluralizedInsightCount(accumulator.symptomIDs.count, singular: "symptom log", plural: "symptom logs")) and \(pluralizedInsightCount(accumulator.relatedRecordIDs.count, singular: "context log", plural: "context logs"))."
            ),
            AtlasExplainerFact(
                label: "Why this appears",
                value: "This appears because the same symptom-to-context timing rule matched at least twice in the current window, most recently on \(atlasExplanationDateLabel(accumulator.latestMatchAt))."
            )
        ]

        return AtlasDeterministicExplanationCandidate(
            symptomKey: symptomKey,
            kind: .symptomContext,
            card: AtlasDeterministicInsightCard(
                id: "symptom_context_\(symptomKey)_\(descriptorID)",
                kind: .symptomContext,
                title: "\(symptomDisplay) near \(descriptorTitle) context",
                summary: summary,
                facts: facts
            ),
            matchCount: accumulator.symptomIDs.count,
            coverage: coverage,
            latestMatchAt: accumulator.latestMatchAt
        )
    }
}

private func buildWeightExplanationCandidates(
    symptomKey: String,
    symptomDisplay: String,
    symptomLogs: [AtlasSymptomLogRecord],
    weightLogs: [AtlasWeightLogRecord]
) -> [AtlasDeterministicExplanationCandidate] {
    var accumulator = AtlasRelationshipEvidenceAccumulator(
        title: "Weight check-in",
        symptomIDs: [],
        relatedRecordIDs: [],
        latestMatchAt: .distantPast
    )

    for symptom in symptomLogs {
        let symptomDate = atlasDate(from: symptom.loggedAt)
        for weight in weightLogs {
            let weightDate = atlasDate(from: weight.loggedAt)
            let distance = abs(symptomDate.timeIntervalSince(weightDate))
            guard distance <= atlasInsightsExplainabilityWeightWindowHours * 60 * 60 else {
                continue
            }

            accumulator.symptomIDs.insert(symptom.id)
            accumulator.relatedRecordIDs.insert(weight.id)
            accumulator.latestMatchAt = max(accumulator.latestMatchAt, symptomDate)
        }
    }

    let coverage = Double(accumulator.symptomIDs.count) / Double(symptomLogs.count)
    guard accumulator.symptomIDs.count >= atlasInsightsExplainabilityMinimumMatches,
          coverage >= atlasInsightsExplainabilityMinimumCoverage else {
        return []
    }

    let summary = "Recent \(symptomDisplay.lowercased()) entries showed up within 24 hours of weight check-ins."
    let facts = [
        AtlasExplainerFact(
            label: "Observed",
            value: "\(accumulator.symptomIDs.count) of \(symptomLogs.count) recent \(symptomDisplay.lowercased()) entries landed within 24 hours of a weight check-in."
        ),
        AtlasExplainerFact(
            label: "Window",
            value: "Last \(atlasInsightsSymptomWindowDays) days • nearby means within 24 hours on either side of the weight entry."
        ),
        AtlasExplainerFact(
            label: "Records",
            value: "\(pluralizedInsightCount(accumulator.symptomIDs.count, singular: "symptom log", plural: "symptom logs")) and \(pluralizedInsightCount(accumulator.relatedRecordIDs.count, singular: "weight log", plural: "weight logs"))."
        ),
        AtlasExplainerFact(
            label: "Why this appears",
            value: "This appears because the same symptom-to-weight timing rule matched at least twice in the current window, most recently on \(atlasExplanationDateLabel(accumulator.latestMatchAt))."
        )
    ]

    return [
        AtlasDeterministicExplanationCandidate(
            symptomKey: symptomKey,
            kind: .symptomWeight,
            card: AtlasDeterministicInsightCard(
                id: "symptom_weight_\(symptomKey)",
                kind: .symptomWeight,
                title: "\(symptomDisplay) near weight check-ins",
                summary: summary,
                facts: facts
            ),
            matchCount: accumulator.symptomIDs.count,
            coverage: coverage,
            latestMatchAt: accumulator.latestMatchAt
        )
    ]
}

private func buildMetricExplanationCandidates(
    symptomKey: String,
    symptomDisplay: String,
    symptomLogs: [AtlasSymptomLogRecord],
    metricLogs: [AtlasMetricValueLogRecord],
    metricsByID: [String: AtlasCustomMetricRecord]
) -> [AtlasDeterministicExplanationCandidate] {
    var accumulators: [String: AtlasRelationshipEvidenceAccumulator] = [:]

    for symptom in symptomLogs {
        let symptomDate = atlasDate(from: symptom.loggedAt)
        for metricLog in metricLogs {
            let metricDate = atlasDate(from: metricLog.loggedAt)
            let distance = abs(symptomDate.timeIntervalSince(metricDate))
            guard distance <= atlasInsightsExplainabilityMetricWindowHours * 60 * 60 else {
                continue
            }

            guard let descriptor = metricRelationshipDescriptor(
                for: metricLog,
                metricsByID: metricsByID,
                symptomKey: symptomKey
            ) else {
                continue
            }

            var accumulator = accumulators[descriptor.id] ?? AtlasRelationshipEvidenceAccumulator(
                title: descriptor.title,
                symptomIDs: [],
                relatedRecordIDs: [],
                latestMatchAt: symptomDate
            )
            accumulator.symptomIDs.insert(symptom.id)
            accumulator.relatedRecordIDs.insert(metricLog.id)
            accumulator.latestMatchAt = max(accumulator.latestMatchAt, symptomDate)
            accumulators[descriptor.id] = accumulator
        }
    }

    return accumulators.compactMap { descriptorID, accumulator in
        let coverage = Double(accumulator.symptomIDs.count) / Double(symptomLogs.count)
        guard accumulator.symptomIDs.count >= atlasInsightsExplainabilityMinimumMatches,
              coverage >= atlasInsightsExplainabilityMinimumCoverage else {
            return nil
        }

        let metricTitle = accumulator.title.lowercased()
        let summary = "Recent \(symptomDisplay.lowercased()) entries showed up within 24 hours of \(metricTitle) check-ins."
        let facts = [
            AtlasExplainerFact(
                label: "Observed",
                value: "\(accumulator.symptomIDs.count) of \(symptomLogs.count) recent \(symptomDisplay.lowercased()) entries landed within 24 hours of \(metricTitle) check-ins."
            ),
            AtlasExplainerFact(
                label: "Window",
                value: "Last \(atlasInsightsSymptomWindowDays) days • nearby means within 24 hours on either side of the metric entry."
            ),
            AtlasExplainerFact(
                label: "Records",
                value: "\(pluralizedInsightCount(accumulator.symptomIDs.count, singular: "symptom log", plural: "symptom logs")) and \(pluralizedInsightCount(accumulator.relatedRecordIDs.count, singular: "metric log", plural: "metric logs"))."
            ),
            AtlasExplainerFact(
                label: "Why this appears",
                value: "This appears because the same symptom-to-metric timing rule matched at least twice in the current window, most recently on \(atlasExplanationDateLabel(accumulator.latestMatchAt))."
            )
        ]

        return AtlasDeterministicExplanationCandidate(
            symptomKey: symptomKey,
            kind: .symptomMetric,
            card: AtlasDeterministicInsightCard(
                id: "symptom_metric_\(symptomKey)_\(descriptorID)",
                kind: .symptomMetric,
                title: "\(symptomDisplay) near \(metricTitle) check-ins",
                summary: summary,
                facts: facts
            ),
            matchCount: accumulator.symptomIDs.count,
            coverage: coverage,
            latestMatchAt: accumulator.latestMatchAt
        )
    }
}

private func buildWorkoutExplanationCandidates(
    symptomKey: String,
    symptomDisplay: String,
    symptomLogs: [AtlasSymptomLogRecord],
    workoutLogs: [AtlasWorkoutLogRecord]
) -> [AtlasDeterministicExplanationCandidate] {
    var accumulators: [AtlasWorkoutActivityKind: AtlasRelationshipEvidenceAccumulator] = [:]

    for symptom in symptomLogs {
        let symptomDate = atlasDate(from: symptom.loggedAt)
        for workout in workoutLogs {
            let workoutEndedAt = atlasDate(from: workout.endedAt)
            let distance = symptomDate.timeIntervalSince(workoutEndedAt)
            guard distance >= 0, distance <= atlasInsightsExplainabilityWorkoutWindowHours * 60 * 60 else {
                continue
            }

            var accumulator = accumulators[workout.activityKind] ?? AtlasRelationshipEvidenceAccumulator(
                title: workout.activityKind.title,
                symptomIDs: [],
                relatedRecordIDs: [],
                latestMatchAt: symptomDate
            )
            accumulator.symptomIDs.insert(symptom.id)
            accumulator.relatedRecordIDs.insert(workout.id)
            accumulator.latestMatchAt = max(accumulator.latestMatchAt, symptomDate)
            accumulators[workout.activityKind] = accumulator
        }
    }

    return accumulators.compactMap { activityKind, accumulator in
        let coverage = Double(accumulator.symptomIDs.count) / Double(symptomLogs.count)
        guard accumulator.symptomIDs.count >= atlasInsightsExplainabilityMinimumMatches,
              coverage >= atlasInsightsExplainabilityMinimumCoverage else {
            return nil
        }

        let activityTitle = accumulator.title.lowercased()
        let summary = "Recent \(symptomDisplay.lowercased()) entries showed up within 24 hours after \(activityTitle) workouts."
        let facts = [
            AtlasExplainerFact(
                label: "Observed",
                value: "\(accumulator.symptomIDs.count) of \(symptomLogs.count) recent \(symptomDisplay.lowercased()) entries landed within 24 hours after \(activityTitle) workouts."
            ),
            AtlasExplainerFact(
                label: "Window",
                value: "Last \(atlasInsightsSymptomWindowDays) days • post-workout means within 24 hours after the workout ended."
            ),
            AtlasExplainerFact(
                label: "Records",
                value: "\(pluralizedInsightCount(accumulator.symptomIDs.count, singular: "symptom log", plural: "symptom logs")) and \(pluralizedInsightCount(accumulator.relatedRecordIDs.count, singular: "workout log", plural: "workout logs"))."
            ),
            AtlasExplainerFact(
                label: "Why this appears",
                value: "This appears because the same post-workout timing rule matched at least twice in the current window, most recently on \(atlasExplanationDateLabel(accumulator.latestMatchAt))."
            )
        ]

        return AtlasDeterministicExplanationCandidate(
            symptomKey: symptomKey,
            kind: .symptomWorkout,
            card: AtlasDeterministicInsightCard(
                id: "symptom_workout_\(symptomKey)_\(activityKind.rawValue)",
                kind: .symptomWorkout,
                title: "\(symptomDisplay) after \(activityTitle) workouts",
                summary: summary,
                facts: facts
            ),
            matchCount: accumulator.symptomIDs.count,
            coverage: coverage,
            latestMatchAt: accumulator.latestMatchAt
        )
    }
}

private func contextRelationshipDescriptors(
    for record: AtlasContextLogRecord,
    symptomKey: String
) -> [AtlasContextRelationshipDescriptor] {
    var descriptors: [AtlasContextRelationshipDescriptor] = []

    if let mealTiming = record.mealTiming {
        descriptors.append(.init(id: "meal_timing_\(mealTiming.rawValue)", title: mealTiming.title))
    }
    if let mealSize = record.mealSize {
        descriptors.append(.init(id: "meal_size_\(mealSize.rawValue)", title: mealSize.title))
    }
    if let mealComposition = record.mealComposition {
        descriptors.append(.init(id: "meal_composition_\(mealComposition.rawValue)", title: mealComposition.title))
    }
    if let fedState = record.fedState {
        descriptors.append(.init(id: "fed_state_\(fedState.rawValue)", title: fedState.title))
    }
    if let appetite = record.appetite {
        descriptors.append(.init(id: "appetite_\(appetite.rawValue)", title: appetite.title))
    }
    if let hydration = record.hydration {
        descriptors.append(.init(id: "hydration_\(hydration.rawValue)", title: hydration.title))
    }
    descriptors.append(
        contentsOf: record.giTags.map {
            AtlasContextRelationshipDescriptor(id: "gi_\($0.rawValue)", title: $0.title)
        }
    )

    let normalizedSymptom = normalizedInsightDescriptorKey(symptomKey)
    return descriptors.filter { descriptor in
        normalizedInsightDescriptorKey(descriptor.title) != normalizedSymptom
    }
}

private func metricRelationshipDescriptor(
    for record: AtlasMetricValueLogRecord,
    metricsByID: [String: AtlasCustomMetricRecord],
    symptomKey: String
) -> AtlasMetricRelationshipDescriptor? {
    guard let metric = metricsByID[record.metricId] else {
        return nil
    }

    switch metric.valueType {
    case .text:
        return nil
    case .number, .scale, .boolean:
        break
    }

    let title = metric.label.trimmingCharacters(in: .whitespacesAndNewlines)
    guard title.isEmpty == false else {
        return nil
    }
    guard normalizedInsightDescriptorKey(title) != normalizedInsightDescriptorKey(symptomKey) else {
        return nil
    }

    return AtlasMetricRelationshipDescriptor(
        id: "metric_\(metric.id)",
        title: title
    )
}

private func normalizedInsightSymptomKey(_ symptomKey: String) -> String {
    symptomKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

private func displayInsightSymptomTitle(from symptomKey: String) -> String {
    let trimmed = symptomKey.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.isEmpty == false else {
        return "Symptom"
    }
    return trimmed.capitalized
}

private func normalizedInsightDescriptorKey(_ value: String) -> String {
    value
        .lowercased()
        .replacingOccurrences(of: "_", with: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func pluralizedInsightCount(_ count: Int, singular: String, plural: String) -> String {
    count == 1 ? "1 \(singular)" : "\(count) \(plural)"
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

private let atlasNutritionProteinMealTarget = 2
private let atlasNutritionFiberMealTarget = 1
private let atlasNutritionHydrationTarget = 2
private let atlasNutritionRecentMealsWindowDays = 7
private let atlasNutritionWeeklyWindowDays = 7
private let atlasNutritionWorkoutWindowDays = 14
private let atlasNutritionWorkoutMealWindowHours = 6

private func buildNutritionSnapshot(
    contextLogs: [AtlasContextLogRecord],
    contextPresets: [AtlasContextPresetRecord],
    workoutLogs: [AtlasWorkoutLogRecord],
    weightLogs: [AtlasWeightLogRecord],
    onboardingDraft: AtlasOnboardingDraft?,
    now: Date
) -> AtlasNutritionSnapshot {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: now)
    let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
    let recentWindowStart = calendar.date(byAdding: .day, value: -atlasNutritionRecentMealsWindowDays, to: now) ?? now
    let weeklyWindowStart = calendar.date(byAdding: .day, value: -(atlasNutritionWeeklyWindowDays - 1), to: startOfDay) ?? startOfDay
    let workoutWindowStart = calendar.date(byAdding: .day, value: -atlasNutritionWorkoutWindowDays, to: now) ?? now

    let todayEntries = contextLogs.filter {
        let loggedAt = atlasDate(from: $0.loggedAt)
        return loggedAt >= startOfDay && loggedAt < nextDay
    }
    let recentMeals = contextLogs.filter {
        atlasDate(from: $0.loggedAt) >= recentWindowStart && atlasNutritionHasMealSignal(record: $0)
    }
    let latestMeal = contextLogs.first(where: atlasNutritionHasMealSignal(record:))
    let favoriteMealCount = contextPresets.filter(atlasNutritionHasMealSignal(record:)).count
    let weeklyEntries = contextLogs.filter {
        let loggedAt = atlasDate(from: $0.loggedAt)
        return loggedAt >= weeklyWindowStart && loggedAt < nextDay
    }
    let weeklyDayBuckets = Dictionary(grouping: weeklyEntries) {
        calendar.startOfDay(for: atlasDate(from: $0.loggedAt))
    }
    let weeklyProteinDays = weeklyDayBuckets.values.filter {
        $0.filter { $0.mealComposition == .proteinHeavy }.count >= atlasNutritionProteinMealTarget
    }.count
    let weeklyFiberDays = weeklyDayBuckets.values.filter {
        $0.contains { $0.mealComposition == .fiberForward }
    }.count
    let weeklyHydrationDays = weeklyDayBuckets.values.filter {
        $0.filter { $0.hydration == .high }.count >= atlasNutritionHydrationTarget
    }.count
    let recentWorkouts = workoutLogs.filter { atlasDate(from: $0.startedAt) >= workoutWindowStart }
    let fueledWorkoutCount = recentWorkouts.filter { workout in
        atlasNutritionHasMealNearWorkout(
            workout: workout,
            contextLogs: contextLogs,
            withinHours: atlasNutritionWorkoutMealWindowHours
        )
    }.count

    let proteinCount = todayEntries.filter { $0.mealComposition == .proteinHeavy }.count
    let fiberCount = todayEntries.filter { $0.mealComposition == .fiberForward }.count
    let hydrationCount = todayEntries.filter { $0.hydration == .high }.count

    let targets = [
        atlasNutritionTarget(
            kind: .proteinMeals,
            title: "Protein meals",
            symbolName: "fork.knife.circle.fill",
            currentValue: proteinCount,
            targetValue: atlasNutritionProteinMealTarget,
            helperText: proteinCount >= atlasNutritionProteinMealTarget
                ? "Today's protein-forward meal target is met."
                : "Meals marked protein-heavy count here."
        ),
        atlasNutritionTarget(
            kind: .fiberMeals,
            title: "Fiber-forward meal",
            symbolName: "leaf.fill",
            currentValue: fiberCount,
            targetValue: atlasNutritionFiberMealTarget,
            helperText: fiberCount >= atlasNutritionFiberMealTarget
                ? "Today's fiber-forward meal target is met."
                : "Use the Fiber meal preset or mark a meal as fiber-forward."
        ),
        atlasNutritionTarget(
            kind: .hydrationCheckins,
            title: "Hydration check-ins",
            symbolName: "drop.fill",
            currentValue: hydrationCount,
            targetValue: atlasNutritionHydrationTarget,
            helperText: hydrationCount >= atlasNutritionHydrationTarget
                ? "Today's hydration target is met."
                : "Hydrated check-ins count here."
        )
    ]
    let weeklySignals: [AtlasNutritionWeeklySignalSnapshot] = [
        AtlasNutritionWeeklySignalSnapshot(
            kind: .proteinDays,
            title: "Protein days",
            valueLabel: "\(weeklyProteinDays) of \(atlasNutritionWeeklyWindowDays) days",
            helperText: "A protein day counts when two protein-heavy meals are logged.",
            symbolName: "fork.knife.circle.fill",
            isOnTrack: weeklyProteinDays >= 4
        ),
        AtlasNutritionWeeklySignalSnapshot(
            kind: .fiberDays,
            title: "Fiber days",
            valueLabel: "\(weeklyFiberDays) of \(atlasNutritionWeeklyWindowDays) days",
            helperText: "One fiber-forward meal is enough to count a day here.",
            symbolName: "leaf.fill",
            isOnTrack: weeklyFiberDays >= 4
        ),
        AtlasNutritionWeeklySignalSnapshot(
            kind: .hydrationDays,
            title: "Hydration days",
            valueLabel: "\(weeklyHydrationDays) of \(atlasNutritionWeeklyWindowDays) days",
            helperText: "Hydration days need two hydrated check-ins to count.",
            symbolName: "drop.fill",
            isOnTrack: weeklyHydrationDays >= 4
        )
    ] + (recentWorkouts.isEmpty ? [] : [
        AtlasNutritionWeeklySignalSnapshot(
            kind: .workoutFueling,
            title: "Workout fueling",
            valueLabel: "\(fueledWorkoutCount) of \(recentWorkouts.count) workouts",
            helperText: "A workout counts when meal context is logged within six hours of the session.",
            symbolName: "figure.run.circle.fill",
            isOnTrack: recentWorkouts.isEmpty ? false : fueledWorkoutCount * 2 >= recentWorkouts.count
        )
    ])
    let coachingCards = buildNutritionCoachingCards(
        weeklyProteinDays: weeklyProteinDays,
        weeklyFiberDays: weeklyFiberDays,
        weeklyHydrationDays: weeklyHydrationDays,
        fueledWorkoutCount: fueledWorkoutCount,
        recentWorkoutCount: recentWorkouts.count,
        weightLogs: weightLogs,
        onboardingDraft: onboardingDraft
    )

    return AtlasNutritionSnapshot(
        dailyTargets: targets,
        favoriteMealCount: favoriteMealCount,
        recentMealCount: recentMeals.count,
        latestMealLabel: latestMeal.map(atlasNutritionLatestMealLabel(record:)),
        weeklySignals: weeklySignals,
        coachingCards: coachingCards,
        note: "Quick meals, repeated favorites, local food lookup, and simple coaching."
    )
}

private func atlasNutritionTarget(
    kind: AtlasNutritionTargetKind,
    title: String,
    symbolName: String,
    currentValue: Int,
    targetValue: Int,
    helperText: String
) -> AtlasNutritionTargetSnapshot {
    let boundedCurrent = min(currentValue, targetValue)
    return AtlasNutritionTargetSnapshot(
        kind: kind,
        title: title,
        progressLabel: "\(currentValue) of \(targetValue) today",
        helperText: helperText,
        symbolName: symbolName,
        currentValue: currentValue,
        targetValue: targetValue,
        progress: min(Double(boundedCurrent) / Double(targetValue), 1),
        isMet: currentValue >= targetValue
    )
}

private func atlasNutritionHasMealSignal(record: AtlasContextLogRecord) -> Bool {
    record.mealTiming != nil
        || record.mealSize != nil
        || record.mealComposition != nil
        || record.fedState != nil
}

private func atlasNutritionHasMealSignal(record: AtlasContextPresetRecord) -> Bool {
    record.mealTiming != nil
        || record.mealSize != nil
        || record.mealComposition != nil
        || record.fedState != nil
}

private func atlasNutritionHasMealNearWorkout(
    workout: AtlasWorkoutLogRecord,
    contextLogs: [AtlasContextLogRecord],
    withinHours: Int
) -> Bool {
    let workoutDate = atlasDate(from: workout.startedAt)
    let lowerBound = workoutDate.addingTimeInterval(TimeInterval(-withinHours * 60 * 60))
    let upperBound = workoutDate.addingTimeInterval(TimeInterval(withinHours * 60 * 60))
    return contextLogs.contains { log in
        guard atlasNutritionHasMealSignal(record: log) else {
            return false
        }
        let loggedAt = atlasDate(from: log.loggedAt)
        return loggedAt >= lowerBound && loggedAt <= upperBound
    }
}

private func atlasNutritionLatestMealLabel(record: AtlasContextLogRecord) -> String {
    var parts: [String] = []
    if let mealTiming = record.mealTiming {
        parts.append(mealTiming.title)
    }
    if let mealComposition = record.mealComposition {
        parts.append(mealComposition.title)
    }
    if let hydration = record.hydration {
        parts.append(hydration.title)
    }

    let descriptor = parts.isEmpty ? "Quick meal" : Array(parts.prefix(3)).joined(separator: " • ")
    return "Latest \(formatDateLabel(record.loggedAt)) • \(descriptor)"
}

private func buildNutritionCoachingCards(
    weeklyProteinDays: Int,
    weeklyFiberDays: Int,
    weeklyHydrationDays: Int,
    fueledWorkoutCount: Int,
    recentWorkoutCount: Int,
    weightLogs: [AtlasWeightLogRecord],
    onboardingDraft: AtlasOnboardingDraft?
) -> [AtlasNutritionCoachingCard] {
    var cards: [AtlasNutritionCoachingCard] = []

    if recentWorkoutCount > 0 && fueledWorkoutCount < recentWorkoutCount {
        cards.append(
            AtlasNutritionCoachingCard(
                id: "nutrition-workout-fueling",
                kind: .workoutFueling,
                title: "Fuel workouts more consistently",
                summary: "\(fueledWorkoutCount) of \(recentWorkoutCount) recent workouts had nearby meal logs.",
                helperText: "Log a meal or shake before or after training to keep the session paired with nutrition context.",
                symbolName: "figure.run.circle.fill"
            )
        )
    }

    if let weightCard = atlasNutritionWeightCoachingCard(weightLogs: weightLogs, onboardingDraft: onboardingDraft) {
        cards.append(weightCard)
    }

    if weeklyFiberDays < 4 {
        cards.append(
            AtlasNutritionCoachingCard(
                id: "nutrition-fiber-consistency",
                kind: .consistency,
                title: "Fiber is the easiest weekly win",
                summary: "Fiber-forward meals landed on \(weeklyFiberDays) of the last \(atlasNutritionWeeklyWindowDays) days.",
                helperText: "One fiber-forward meal per day is enough to move this signal. The built-in Fiber meal preset is the fastest way to log it.",
                symbolName: "leaf.fill"
            )
        )
    }

    if weeklyHydrationDays < 4 {
        cards.append(
            AtlasNutritionCoachingCard(
                id: "nutrition-hydration-rhythm",
                kind: .hydration,
                title: "Hydration rhythm can still tighten up",
                summary: "Hydration targets cleared on \(weeklyHydrationDays) of the last \(atlasNutritionWeeklyWindowDays) days.",
                helperText: "Two hydrated check-ins in the same day count as a hydrated day.",
                symbolName: "drop.fill"
            )
        )
    }

    if cards.isEmpty {
        cards.append(
            AtlasNutritionCoachingCard(
                id: "nutrition-steady-rhythm",
                kind: .consistency,
                title: "Nutrition rhythm looks steady",
                summary: "Protein, fiber, hydration, and workout fueling are all showing usable coverage.",
                helperText: "Keep using fast capture to preserve this signal without heavier logging.",
                symbolName: "checkmark.circle.fill"
            )
        )
    } else if weeklyProteinDays < 4 && cards.contains(where: { $0.kind == .consistency }) == false {
        cards.insert(
            AtlasNutritionCoachingCard(
                id: "nutrition-protein-consistency",
                kind: .consistency,
                title: "Protein consistency still has room",
                summary: "Protein targets cleared on \(weeklyProteinDays) of the last \(atlasNutritionWeeklyWindowDays) days.",
                helperText: "A protein day needs two protein-heavy meals, so repeated breakfasts and shakes move this quickly.",
                symbolName: "fork.knife.circle.fill"
            ),
            at: 0
        )
    }

    return Array(cards.prefix(4))
}

private func atlasNutritionWeightCoachingCard(
    weightLogs: [AtlasWeightLogRecord],
    onboardingDraft: AtlasOnboardingDraft?
) -> AtlasNutritionCoachingCard? {
    guard let profile = onboardingDraft?.profile,
          let goalWeight = profile.goalWeight,
          let unit = profile.weightUnit else {
        return nil
    }

    let matchingLogs = weightLogs
        .filter { $0.unit == unit }
        .sorted { $0.loggedAt < $1.loggedAt }
    let baselineWeight = matchingLogs.first?.value ?? profile.weight
    let latestWeight = matchingLogs.last?.value ?? profile.weight
    guard let baselineWeight, let latestWeight else {
        return nil
    }

    let baselineDistance = abs(baselineWeight - goalWeight)
    let latestDistance = abs(latestWeight - goalWeight)
    let improvement = baselineDistance - latestDistance

    if latestDistance <= 0.5 {
        return AtlasNutritionCoachingCard(
            id: "nutrition-weight-aligned",
            kind: .weight,
            title: "Weight trend is sitting inside your goal range",
            summary: "Latest logged weight is within about half a \(unit.rawValue) of your stored goal.",
            helperText: "This is a pattern check, not a judgment on every fluctuation.",
            symbolName: "target"
        )
    }

    guard improvement > 0 else {
        return nil
    }

    let improvementLabel = improvement.rounded() == improvement
        ? String(Int(improvement))
        : String(format: "%.1f", improvement)

    return AtlasNutritionCoachingCard(
        id: "nutrition-weight-progress",
        kind: .weight,
        title: "Recent nutrition rhythm is lining up with weight progress",
        summary: "You are \(improvementLabel) \(unit.rawValue) closer to your stored goal than where this run of logs started.",
        helperText: "This does not prove causality, but it is a useful checkpoint when meal and workout signals are also staying consistent.",
        symbolName: "chart.line.uptrend.xyaxis"
    )
}

private func atlasReadNutritionOnboardingDraft(db: Database) throws -> AtlasOnboardingDraft? {
    guard let json = try String.fetchOne(
        db,
        sql: "SELECT value FROM atlas_app_settings WHERE key = 'onboarding_draft_json'"
    ) else {
        return nil
    }
    return try? JSONDecoder().decode(AtlasOnboardingDraft.self, from: Data(json.utf8))
}

private func buildAdherenceTrend(
    context: AtlasCoreLoopContext,
    logEvents: [AtlasLogEventRecord],
    now: Date
) -> AtlasAdherenceTrendSummary {
    let calendar = Calendar.current
    let windowStart = calendar.date(byAdding: .day, value: -atlasInsightsTrendWindowDays, to: now) ?? now
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
    let startOfToday = calendar.startOfDay(for: now)
    let stripStart = calendar.date(byAdding: .day, value: -(atlasInsightsTrendWindowDays - 1), to: startOfToday) ?? startOfToday
    var dayBuckets: [Date: AtlasAdherenceTrendSummary.DaySummary] = [:]

    for dayOffset in 0..<atlasInsightsTrendWindowDays {
        guard let day = calendar.date(byAdding: .day, value: dayOffset, to: stripStart) else {
            continue
        }
        let dateKey = ISO8601DateFormatter.atlas.string(from: day)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        dayBuckets[day] = AtlasAdherenceTrendSummary.DaySummary(
            dateKey: dateKey,
            title: formatDateLabel(dateKey),
            shortTitle: String(formatter.string(from: day).prefix(1)),
            scheduledCount: 0,
            dominantStatus: .quiet
        )
    }

    for event in recentLogEvents {
        let day = calendar.startOfDay(for: atlasDate(from: event.loggedAt))
        guard var bucket = dayBuckets[day] else {
            continue
        }
        switch event.eventType {
        case .completed:
            bucket.completedCount += 1
        case .skipped:
            bucket.skippedCount += 1
        case .rescheduled:
            bucket.rescheduledCount += 1
        case .manualLog, .inventoryAdjustment:
            break
        }
        bucket.scheduledCount += 1
        dayBuckets[day] = bucket
    }

    for item in outstandingItems where item.state == .missed || item.state == .due {
        let day = calendar.startOfDay(for: atlasDate(from: item.scheduledAt))
        guard var bucket = dayBuckets[day] else {
            continue
        }
        bucket.overdueCount += 1
        bucket.scheduledCount += 1
        dayBuckets[day] = bucket
    }

    let dailySummaries = dayBuckets.keys.sorted().compactMap { day -> AtlasAdherenceTrendSummary.DaySummary? in
        guard var bucket = dayBuckets[day] else {
            return nil
        }

        if bucket.completedCount > 0 {
            bucket.dominantStatus = .completed
        } else if bucket.overdueCount > 0 {
            bucket.dominantStatus = .overdue
        } else if bucket.skippedCount > 0 {
            bucket.dominantStatus = .skipped
        } else if bucket.rescheduledCount > 0 {
            bucket.dominantStatus = .rescheduled
        } else {
            bucket.dominantStatus = .quiet
        }
        return bucket
    }

    return AtlasAdherenceTrendSummary(
        completionRateLabel: counted > 0 ? "\(Int(round((Double(completedCount) / Double(counted)) * 100)))% logged on time" : nil,
        completedCount: completedCount,
        overdueCount: overdueCount,
        rescheduledCount: rescheduledCount,
        skippedCount: skippedCount,
        dailySummaries: dailySummaries
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
            buildMedicationLevelEstimateItem(
                protocolRecord: protocolRecord,
                aliasTitle: context.aliases[protocolRecord.id]?.aliasLabel,
                revisionSlices: context.revisionSlices[protocolRecord.id] ?? [],
                logEvents: logEvents,
                now: now
            )
        }
}

private func buildProgressEvidenceSnapshot(
    measurements: [AtlasProgressMeasurementRecord],
    photos: [AtlasProgressPhotoRecord]
) -> AtlasProgressEvidenceSnapshot {
    let measurementTrends = AtlasProgressMeasurementKind.allCases.compactMap { kind -> AtlasProgressMeasurementTrend? in
        let items = measurements
            .filter { $0.kind == kind }
            .sorted { $0.loggedAt < $1.loggedAt }
        guard items.isEmpty == false else {
            return nil
        }

        let unit = items.last?.unit ?? kind.defaultUnit
        let latest = items.last
        let previous = items.dropLast().last
        let latestLabel = latest.map { "\(formatNumber($0.value)) \(unit) logged \(formatDateLabel($0.loggedAt))" }
        let changeLabel = previous.map {
            let delta = (latest?.value ?? 0) - $0.value
            let prefix = delta > 0 ? "+" : ""
            return "\(prefix)\(formatNumber(delta)) \(unit) vs prior check-in"
        }

        return AtlasProgressMeasurementTrend(
            kind: kind,
            unit: unit,
            latestLabel: latestLabel,
            changeLabel: changeLabel,
            points: items.map {
                AtlasProgressMeasurementTrendPoint(
                    timestamp: $0.loggedAt,
                    loggedAt: atlasDate(from: $0.loggedAt),
                    value: $0.value
                )
            }
        )
    }

    let recentPhotos = photos.prefix(8).compactMap { record -> AtlasProgressPhotoEntrySummary? in
        guard let fileURL = try? atlasProgressPhotoFileURL(relativePath: record.relativeAssetPath) else {
            return nil
        }
        return AtlasProgressPhotoEntrySummary(
            id: record.id,
            angle: record.angle,
            note: record.note,
            loggedAt: atlasDate(from: record.loggedAt),
            absolutePath: fileURL.path
        )
    }

    let comparisonNote: String?
    if let latestPhoto = recentPhotos.first,
       let previousPhoto = recentPhotos.dropFirst().first {
        comparisonNote = "Compare \(latestPhoto.angle.title.lowercased()) check-ins from \(latestPhoto.loggedAt.formatted(date: .abbreviated, time: .omitted)) and \(previousPhoto.loggedAt.formatted(date: .abbreviated, time: .omitted))."
    } else if let trend = measurementTrends.first(where: { $0.points.count >= 2 }) {
        comparisonNote = trend.changeLabel
    } else {
        comparisonNote = nil
    }

    let summaryTitle = "Progress evidence"
    let summaryText: String
    if measurements.isEmpty && recentPhotos.isEmpty {
        summaryText = "Add measurements and private photo check-ins to keep a calmer record of visible change over time."
    } else {
        summaryText = "\(measurements.count) measurement check-in(s) and \(recentPhotos.count) private photo check-in(s) are saved locally."
    }

    return AtlasProgressEvidenceSnapshot(
        summaryTitle: summaryTitle,
        summaryText: summaryText,
        measurementTrends: measurementTrends,
        recentMeasurements: Array(measurements.prefix(12)),
        recentPhotos: recentPhotos,
        comparisonNote: comparisonNote
    )
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

private func formatWorkoutDuration(_ durationMinutes: Double) -> String {
    let roundedMinutes = Int(durationMinutes.rounded())
    let hours = roundedMinutes / 60
    let minutes = roundedMinutes % 60
    if hours > 0, minutes > 0 {
        return "\(hours) hr \(minutes) min"
    }
    if hours > 0 {
        return hours == 1 ? "1 hr" : "\(hours) hr"
    }
    return "\(max(roundedMinutes, 1)) min"
}

private func formatWorkoutDetail(_ record: AtlasWorkoutLogRecord) -> String? {
    var parts: [String] = []
    if let distanceMeters = record.distanceMeters, distanceMeters > 0 {
        let kilometers = distanceMeters / 1_000
        parts.append("\(formatNumber(kilometers)) km")
    }
    if let energy = record.energyBurnedKilocalories, energy > 0 {
        parts.append("\(formatNumber(energy)) kcal")
    }
    return parts.isEmpty ? nil : parts.joined(separator: " • ")
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
