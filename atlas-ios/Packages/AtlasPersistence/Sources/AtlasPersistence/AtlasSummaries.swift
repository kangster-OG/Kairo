import AtlasDomain
import AtlasPrivacy
import Foundation

public struct AtlasDeterministicSummaryEngine: AtlasSummaryEngine {
    public init() {}

    public func generateSummary(for request: AtlasSummaryRequest) throws -> AtlasGeneratedSummary {
        guard request.sourceSections.contains(where: { $0.facts.isEmpty == false }) else {
            throw AtlasSummaryGenerationError.unsupportedRequest
        }

        let summary: String
        switch request.kind {
        case .weeklyRecap:
            summary = weeklyRecapSummary(for: request)
        case .episodeRecap:
            summary = episodeRecapSummary(for: request)
        case .importDiffRecap:
            summary = importDiffRecapSummary(for: request)
        case .providerHandoffRecap:
            summary = providerHandoffRecapSummary(for: request)
        }

        let guardedSummary = try validate(summary: summary)
        return AtlasGeneratedSummary(
            kind: request.kind,
            title: request.title,
            summary: guardedSummary,
            disclaimer: request.disclaimer,
            sourceSections: request.sourceSections,
            executionMode: .deterministicLocal,
            generatedAt: request.generatedAt
        )
    }

    private func weeklyRecapSummary(for request: AtlasSummaryRequest) -> String {
        let completed = intValue("completed_logs", in: request) ?? 0
        let skipped = intValue("skipped_logs", in: request) ?? 0
        let context = intValue("context_entries", in: request) ?? 0
        let symptoms = intValue("symptom_entries", in: request) ?? 0
        let activeProtocols = intValue("active_protocols", in: request) ?? 0
        let weight = latestValue("latest_weight", in: request)
        let nextDue = latestValue("next_due", in: request)

        var parts = [
            "Over the last 7 days, Atlas captured \(countPhrase(completed, singular: "completed log")) and \(countPhrase(skipped, singular: "skipped log")) across \(countPhrase(activeProtocols, singular: "active protocol"))."
        ]
        let supportPhrases = [
            context > 0 ? countPhrase(context, singular: "context entry", plural: "context entries") : nil,
            symptoms > 0 ? countPhrase(symptoms, singular: "symptom entry", plural: "symptom entries") : nil
        ].compactMap { $0 }
        if supportPhrases.isEmpty {
            parts.append("No additional context or symptom entries were logged in the same window.")
        } else {
            parts.append("Recent supporting records included \(naturalList(supportPhrases)).")
        }
        if let weight {
            parts.append("The latest weight on file is \(weight).")
        }
        if let nextDue {
            parts.append("The next visible schedule anchor remains \(nextDue).")
        }
        return parts.joined(separator: " ")
    }

    private func episodeRecapSummary(for request: AtlasSummaryRequest) -> String {
        let episodeCount = intValue("episode_count", in: request) ?? 0
        let leadingWindow = latestValue("leading_window", in: request) ?? "recent comparison windows"
        let leadingWindowSummary = latestValue("leading_window_summary", in: request) ?? "show the strongest concentration of nearby entries"
        let leadingWindowEpisodeCount = intValue("leading_window_episode_count", in: request) ?? 0
        let leadingSignalCount = intValue("leading_signal_count", in: request) ?? 0
        let patternCount = intValue("pattern_count", in: request) ?? 0
        let pattern = latestValue("leading_pattern", in: request)

        var parts = [
            "Atlas reviewed \(countPhrase(episodeCount, singular: "recent dose episode")) using existing local records and nearby supporting signals."
        ]
        if leadingSignalCount > 0 {
            parts.append("\(leadingWindow) carried the busiest local comparison window with \(countPhrase(leadingSignalCount, singular: "supporting entry", plural: "supporting entries")) across \(countPhrase(leadingWindowEpisodeCount, singular: "episode")).")
        } else if leadingWindowEpisodeCount > 0 {
            parts.append("\(leadingWindow) remained the busiest compare window across \(countPhrase(leadingWindowEpisodeCount, singular: "episode")).")
        } else {
            parts.append("\(leadingWindow) remained the busiest compare window in the current local set.")
        }
        parts.append("Atlas currently shows \(leadingWindowSummary).")
        if let pattern {
            parts.append("The clearest recurring card right now is \(pattern).")
        } else if patternCount > 0 {
            parts.append("Atlas also surfaced \(countPhrase(patternCount, singular: "pattern card")).")
        }
        return parts.joined(separator: " ")
    }

    private func importDiffRecapSummary(for request: AtlasSummaryRequest) -> String {
        let sourceLabel = latestValue("source_label", in: request)
        let creates = intValue("records_to_create", in: request) ?? 0
        let updates = intValue("records_to_update", in: request) ?? 0
        let warningCount = intValue("warning_count", in: request) ?? 0
        let lintCount = intValue("lint_count", in: request) ?? 0
        let privacyNoteCount = intValue("privacy_note_count", in: request) ?? 0
        let backfillNoteCount = intValue("backfill_note_count", in: request) ?? 0
        let largestDataset = latestValue("largest_dataset", in: request)

        var parts: [String] = []
        if let sourceLabel {
            parts.append("From \(sourceLabel), this dry run would create \(countPhrase(creates, singular: "record")) and update \(countPhrase(updates, singular: "existing record")).")
        } else {
            parts.append("This dry run would create \(countPhrase(creates, singular: "record")) and update \(countPhrase(updates, singular: "existing record")).")
        }
        if creates > updates {
            parts.append("Most of the proposed movement is new local data rather than edits to records already on device.")
        } else if updates > creates {
            parts.append("Most of the proposed movement refines records already on device rather than adding entirely new rows.")
        }
        if let largestDataset {
            parts.append("The largest dataset change sits in \(largestDataset).")
        }
        if warningCount > 0 || lintCount > 0 {
            parts.append("Atlas surfaced \(countPhrase(warningCount, singular: "warning")) and \(countPhrase(lintCount, singular: "lint item")) to review before commit.")
        } else {
            parts.append("Atlas did not surface warnings or lint findings in this dry run.")
        }
        let operatorNotes = [
            privacyNoteCount > 0 ? countPhrase(privacyNoteCount, singular: "privacy note") : nil,
            backfillNoteCount > 0 ? countPhrase(backfillNoteCount, singular: "backfill note") : nil
        ].compactMap { $0 }
        if operatorNotes.isEmpty == false {
            parts.append("Supporting operator notes remain attached for \(naturalList(operatorNotes)).")
        }
        return parts.joined(separator: " ")
    }

    private func providerHandoffRecapSummary(for request: AtlasSummaryRequest) -> String {
        let scope = latestValue("scope", in: request) ?? "this selected scope"
        let rowCount = intValue("row_count", in: request) ?? 0
        let datasetCount = intValue("dataset_count", in: request) ?? 0
        let renderMode = latestValue("render_mode", in: request) ?? "full"
        let topDatasets = latestValue("top_datasets", in: request)
        let note = latestValue("episode_note", in: request)

        var parts = [
            "This handoff packages \(scope.lowercased()) as a static snapshot with \(countPhrase(rowCount, singular: "row")) across \(countPhrase(datasetCount, singular: "dataset")).",
            "The bundle is currently prepared in \(renderMode.lowercased()) mode."
        ]
        if let topDatasets {
            parts.append("The included material is centered on \(topDatasets).")
        }
        if let note {
            parts.append("Episode context also notes \(note).")
        }
        return parts.joined(separator: " ")
    }

    private func validate(summary: String) throws -> String {
        let normalized = summary.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let bannedFragments = [
            "diagnos",
            "treat",
            "therapy",
            "prescrib",
            "increase dose",
            "decrease dose",
            "change dose",
            "recommend",
            "should take",
            "buy",
            "purchase",
            "source"
        ]
        let lowered = normalized.lowercased()
        guard bannedFragments.allSatisfy({ lowered.contains($0) == false }) else {
            throw AtlasSummaryGenerationError.unsupportedRequest
        }
        return normalized
    }

    private func intValue(_ id: String, in request: AtlasSummaryRequest) -> Int? {
        request.sourceSections
            .flatMap(\.facts)
            .first(where: { $0.id == id })
            .flatMap { Int($0.value) }
    }

    private func latestValue(_ id: String, in request: AtlasSummaryRequest) -> String? {
        request.sourceSections
            .flatMap(\.facts)
            .first(where: { $0.id == id })?
            .value
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
}

public struct AtlasDeferredExternalSummaryEngine: AtlasSummaryEngine {
    public init() {}

    public func generateSummary(for request: AtlasSummaryRequest) throws -> AtlasGeneratedSummary {
        _ = request
        throw AtlasSummaryGenerationError.externalProcessingDeferred
    }
}

struct AtlasSummaryService {
    var featureFlags: AtlasFeatureFlagState
    var settings: AtlasSummarySettingsSnapshot
    var localEngine: any AtlasSummaryEngine
    var externalEngine: any AtlasSummaryEngine

    init(
        featureFlags: AtlasFeatureFlagState,
        settings: AtlasSummarySettingsSnapshot,
        localEngine: any AtlasSummaryEngine = AtlasDeterministicSummaryEngine(),
        externalEngine: any AtlasSummaryEngine = AtlasDeferredExternalSummaryEngine()
    ) {
        self.featureFlags = featureFlags
        self.settings = settings
        self.localEngine = localEngine
        self.externalEngine = externalEngine
    }

    func generate(_ request: AtlasSummaryRequest) -> AtlasGeneratedSummary? {
        guard featureFlags.boundedSummaries else {
            return nil
        }
        guard settings.onDeviceEnabled || settings.externalProviderEnabled else {
            return nil
        }

        if settings.externalProviderEnabled && featureFlags.externalSummaryProviders {
            if let externalSummary = try? externalEngine.generateSummary(for: request) {
                return externalSummary
            }
        }
        guard settings.onDeviceEnabled else {
            return nil
        }
        return try? localEngine.generateSummary(for: request)
    }
}

func atlasSummaryFact(
    _ id: String,
    _ label: String,
    _ value: String
) -> AtlasSummaryFact {
    AtlasSummaryFact(id: id, label: label, value: value)
}

func atlasSummarySection(
    _ id: String,
    _ title: String,
    _ facts: [AtlasSummaryFact]
) -> AtlasSummarySourceSection {
    AtlasSummarySourceSection(id: id, title: title, facts: facts)
}

func buildWeeklyRecapSummaryRequest(
    context: AtlasCoreLoopContext,
    logEvents: [AtlasLogEventRecord],
    contextLogs: [AtlasContextLogRecord],
    symptomLogs: [AtlasSymptomLogRecord],
    weightLogs: [AtlasWeightLogRecord],
    referenceDate: Date,
    renderMode: AtlasPrivacyRenderMode,
    privacyFormatter: AtlasPrivacyFormatter
) -> AtlasSummaryRequest? {
    let calendar = Calendar.current
    let windowStart = calendar.date(byAdding: .day, value: -7, to: referenceDate) ?? referenceDate
    let weeklyLogs = logEvents.filter { atlasDate(from: $0.loggedAt) >= windowStart }
    let weeklyContext = contextLogs.filter { atlasDate(from: $0.loggedAt) >= windowStart }
    let weeklySymptoms = symptomLogs.filter { atlasDate(from: $0.loggedAt) >= windowStart }
    let weeklyWeights = weightLogs.filter { atlasDate(from: $0.loggedAt) >= windowStart }
    let pendingOccurrences = context.pendingOccurrences.values.flatMap { $0 }
    let nextDue = pendingOccurrences
        .map { buildScheduledOccurrence(occurrence: $0, context: context, now: referenceDate) }
        .sorted { $0.scheduledAt < $1.scheduledAt }
        .first

    let completedCount = weeklyLogs.filter { $0.eventType == .completed }.count
    let skippedCount = weeklyLogs.filter { $0.eventType == .skipped }.count
    let latestWeight = weeklyWeights.first ?? weightLogs.first
    let activeProtocolCount = context.protocols.values.filter { $0.status == .active }.count

    guard completedCount + skippedCount + weeklyContext.count + weeklySymptoms.count + weeklyWeights.count + activeProtocolCount > 0 else {
        return nil
    }

    return AtlasSummaryRequest(
        kind: .weeklyRecap,
        title: AtlasSummaryKind.weeklyRecap.title,
        renderMode: renderMode,
        sourceSections: [
            atlasSummarySection(
                "weekly_activity",
                "Recent activity",
                [
                    atlasSummaryFact("completed_logs", "Completed logs", String(completedCount)),
                    atlasSummaryFact("skipped_logs", "Skipped logs", String(skippedCount)),
                    atlasSummaryFact("context_entries", "Context entries", String(weeklyContext.count)),
                    atlasSummaryFact("symptom_entries", "Symptom entries", String(weeklySymptoms.count))
                ]
            ),
            atlasSummarySection(
                "weekly_state",
                "Current state",
                [
                    atlasSummaryFact("active_protocols", "Active protocols", String(activeProtocolCount))
                ] + (latestWeight.map {
                    [atlasSummaryFact("latest_weight", "Latest weight", "\(formatWeightLabel($0)) on \(summaryDateLabel($0.loggedAt))")]
                } ?? []) + (nextDue.map {
                    [atlasSummaryFact(
                        "next_due",
                        "Next due",
                        "\(privacyFormatter.title(canonical: $0.canonicalTitle, alias: $0.aliasTitle, mode: renderMode)) due \(relativeDueLabel(for: $0.scheduledAt))"
                    )]
                } ?? [])
            )
        ],
        disclaimer: "Plain-language recap only. Atlas summarizes existing local logs and schedules without giving medical, dosing, or treatment advice.",
        generatedAt: referenceDate
    )
}

private func formatWeightLabel(_ record: AtlasWeightLogRecord) -> String {
    let value = String(format: record.value.rounded() == record.value ? "%.0f" : "%.1f", record.value)
    return "\(value) \(record.unit.rawValue)"
}

private func summaryDateLabel(_ timestamp: String) -> String {
    atlasDate(from: timestamp).formatted(date: .abbreviated, time: .omitted)
}

func buildEpisodeRecapSummaryRequest(
    snapshot: AtlasEpisodeInsightsSnapshot,
    referenceDate: Date,
    renderMode: AtlasPrivacyRenderMode
) -> AtlasSummaryRequest? {
    guard snapshot.hasAnyEpisodeData else {
        return nil
    }

    let leadWindow = snapshot.compareWindows.max { lhs, rhs in
        let leftScore = lhs.contextEntryCount + lhs.symptomEntryCount + lhs.weightEntryCount + lhs.metricEntryCount
        let rightScore = rhs.contextEntryCount + rhs.symptomEntryCount + rhs.weightEntryCount + rhs.metricEntryCount
        return leftScore < rightScore
    }
    let firstPattern = snapshot.patternCards.first
    let leadingSignalCount = leadWindow.map {
        $0.contextEntryCount + $0.symptomEntryCount + $0.weightEntryCount + $0.metricEntryCount
    }

    return AtlasSummaryRequest(
        kind: .episodeRecap,
        title: AtlasSummaryKind.episodeRecap.title,
        renderMode: renderMode,
        sourceSections: [
            atlasSummarySection(
                "episode_scope",
                "Episode coverage",
                [
                    atlasSummaryFact("episode_count", "Recent episodes", String(snapshot.recentEpisodes.count)),
                    atlasSummaryFact(
                        "leading_window",
                        "Most active window",
                        leadWindow?.windowKind.title ?? "Recent compare windows"
                    ),
                    atlasSummaryFact(
                        "leading_window_summary",
                        "Window detail",
                        leadWindow?.summaryLabel ?? "show the strongest concentration of nearby entries"
                    )
                ] + (leadWindow.map {
                    [
                        atlasSummaryFact(
                            "leading_window_episode_count",
                            "Episodes in that window",
                            String($0.episodeCount)
                        ),
                        atlasSummaryFact(
                            "leading_signal_count",
                            "Supporting entries in that window",
                            String(leadingSignalCount ?? 0)
                        )
                    ]
                } ?? [])
            ),
            atlasSummarySection(
                "episode_patterns",
                "Pattern cards",
                [
                    atlasSummaryFact("pattern_count", "Pattern cards surfaced", String(snapshot.patternCards.count))
                ] + (firstPattern.map {
                    [atlasSummaryFact("leading_pattern", "Leading pattern", "\($0.title): \($0.detail)")]
                } ?? [])
            )
        ],
        disclaimer: "Episode recap is descriptive only. Atlas is restating nearby timing and logged patterns from your local records, not explaining causes or recommending treatment.",
        generatedAt: referenceDate
    )
}

func buildImportDiffSummaryRequest(
    sourceLabel: String,
    datasetDiffs: [AtlasDatasetDiff],
    recordsToCreate: Int,
    recordsToUpdate: Int,
    lintFindings: [AtlasImportLintItem],
    warnings: [String],
    privacyNotes: [String],
    backfillNotes: [String],
    referenceDate: Date
) -> AtlasSummaryRequest? {
    guard recordsToCreate + recordsToUpdate > 0 || warnings.isEmpty == false || lintFindings.isEmpty == false else {
        return nil
    }

    let largestDataset = datasetDiffs
        .sorted { ($0.creates + $0.updates) > ($1.creates + $1.updates) }
        .first
        .map { "\($0.dataset) (+\($0.creates) / ~\($0.updates))" }

    return AtlasSummaryRequest(
        kind: .importDiffRecap,
        title: AtlasSummaryKind.importDiffRecap.title,
        renderMode: .full,
        sourceSections: [
            atlasSummarySection(
                "import_totals",
                "Import totals",
                [
                    atlasSummaryFact("source_label", "Source", sourceLabel),
                    atlasSummaryFact("records_to_create", "Records to create", String(recordsToCreate)),
                    atlasSummaryFact("records_to_update", "Records to update", String(recordsToUpdate)),
                    atlasSummaryFact("warning_count", "Warnings", String(warnings.count)),
                    atlasSummaryFact("lint_count", "Lint findings", String(lintFindings.count))
                ] + (largestDataset.map {
                    [atlasSummaryFact("largest_dataset", "Largest dataset change", $0)]
                } ?? [])
            ),
            atlasSummarySection(
                "import_notes",
                "Guardrails",
                [
                    atlasSummaryFact("privacy_note_count", "Privacy notes", String(privacyNotes.count)),
                    atlasSummaryFact("backfill_note_count", "Backfill notes", String(backfillNotes.count))
                ]
            )
        ],
        disclaimer: "This recap is generated locally from Atlas dry-run counts and notes. It does not replace reviewing dataset diffs, warnings, or privacy notes before commit.",
        generatedAt: referenceDate
    )
}

func buildProviderHandoffSummaryRequest(
    scopeSummary: String,
    renderMode: AtlasPrivacyRenderMode,
    rowCount: Int,
    datasets: [AtlasProviderHandoffDatasetSummary],
    episodeInsights: AtlasEpisodeInsightsSnapshot,
    referenceDate: Date
) -> AtlasSummaryRequest? {
    guard rowCount > 0 else {
        return nil
    }

    let topDatasets = datasets
        .sorted { $0.rowCount > $1.rowCount }
        .prefix(3)
        .map { "\($0.dataset) (\($0.rowCount))" }
        .joined(separator: ", ")

    let episodeNote = episodeInsights.hasAnyEpisodeData
        ? episodePreviewLines(from: episodeInsights).first
        : nil

    return AtlasSummaryRequest(
        kind: .providerHandoffRecap,
        title: AtlasSummaryKind.providerHandoffRecap.title,
        renderMode: renderMode,
        sourceSections: [
            atlasSummarySection(
                "handoff_scope",
                "Handoff scope",
                [
                    atlasSummaryFact("scope", "Scope", scopeSummary),
                    atlasSummaryFact("row_count", "Rows included", String(rowCount)),
                    atlasSummaryFact("dataset_count", "Datasets included", String(datasets.count)),
                    atlasSummaryFact("render_mode", "Render mode", renderMode.rawValue.capitalized)
                ] + (topDatasets.isEmpty ? [] : [
                    atlasSummaryFact("top_datasets", "Included datasets", topDatasets)
                ])
            ),
            atlasSummarySection(
                "handoff_episode",
                "Episode context",
                episodeNote.map { [atlasSummaryFact("episode_note", "Episode note", $0)] } ?? []
            )
        ],
        disclaimer: "This plain-language recap is generated locally from the selected handoff scope. It is descriptive only and should be reviewed alongside the included datasets.",
        generatedAt: referenceDate
    )
}
