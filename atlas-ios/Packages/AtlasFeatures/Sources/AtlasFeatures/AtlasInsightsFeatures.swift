import AtlasDesignSystem
import AtlasDomain
import Charts
import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct AtlasInsightsScreen: View {
    let model: AtlasAppModel
    let state: AtlasInsightsViewState

    @State private var contextEditor: AtlasContextEditorState
    @State private var weightEditor: AtlasWeightEditorState
    @State private var symptomEditor: AtlasSymptomEditorState
    @State private var metricDefinitionEditor = AtlasMetricDefinitionEditorState()
    @State private var metricValueEditor: AtlasMetricValueEditorState
    @State private var contextSheetPresented = false
    @State private var weightSheetPresented = false
    @State private var symptomSheetPresented = false
    @State private var metricDefinitionSheetPresented = false
    @State private var metricValueSheetPresented = false

    public init(model: AtlasAppModel, state: AtlasInsightsViewState) {
        self.model = model
        self.state = state
        let referenceDate = model.currentDate()
        _contextEditor = State(initialValue: AtlasContextEditorState(referenceDate: referenceDate))
        _weightEditor = State(initialValue: AtlasWeightEditorState(referenceDate: referenceDate))
        _symptomEditor = State(initialValue: AtlasSymptomEditorState(referenceDate: referenceDate))
        _metricValueEditor = State(initialValue: AtlasMetricValueEditorState(referenceDate: referenceDate))
    }

    public var body: some View {
        List {
            AtlasTabHeader(
                title: "Insights",
                subtitle: "Signals, patterns, and restrained recaps grounded in Atlas data.",
                fullBleed: false
            )
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            if let error = state.loadErrorMessage {
                AtlasInsightsInlineMessage(text: error)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            AtlasSectionCard(title: "Signals") {
                Text("Track lightweight context, weight, symptoms, and custom signals without leaving the native shell.")
                    .foregroundStyle(AtlasPalette.textSecondary)

                AtlasQuickActionGrid(columns: 2) {
                    AtlasQuickActionTile(
                        title: "Log context",
                        subtitle: "Meal timing, meal shape, hydration, GI, and surrounding context",
                        symbol: "fork.knife.circle.fill",
                        prominence: .primary
                    ) {
                        contextEditor = AtlasContextEditorState(referenceDate: model.currentDate())
                        contextSheetPresented = true
                    }

                    AtlasQuickActionTile(
                        title: "Log weight",
                        subtitle: "Use a numeric entry with unit-aware tracking",
                        symbol: "scalemass.fill",
                        prominence: .secondary
                    ) {
                        weightEditor = AtlasWeightEditorState(referenceDate: model.currentDate())
                        weightSheetPresented = true
                    }

                    AtlasQuickActionTile(
                        title: "Log symptom",
                        subtitle: "Record severity with a bounded scale",
                        symbol: "waveform.path.ecg",
                        prominence: .secondary
                    ) {
                        symptomEditor = AtlasSymptomEditorState(referenceDate: model.currentDate())
                        symptomSheetPresented = true
                    }

                    AtlasQuickActionTile(
                        title: "Manage metrics",
                        subtitle: "Define restrained numeric, scale, boolean, or text signals",
                        symbol: "slider.horizontal.3",
                        prominence: .secondary
                    ) {
                        metricDefinitionEditor = AtlasMetricDefinitionEditorState()
                        metricDefinitionSheetPresented = true
                    }
                }

                AtlasQuickActionTile(
                    title: "Log custom metric",
                    subtitle: "Log a saved metric without leaving the insight surface",
                    symbol: "chart.xyaxis.line",
                    prominence: .secondary
                ) {
                    metricValueEditor = AtlasMetricValueEditorState(referenceDate: model.currentDate())
                    metricValueSheetPresented = true
                }
                .disabled(state.insightsSnapshot.customMetricDefinitions.filter { $0.archivedAt == nil }.isEmpty)

                let quickPresets = model.contextQuickPresets(limit: 4)
                let recentMeals = model.recentMealQuickItems(limit: 4)
                let featuredFoods = model.nutritionFeaturedLookupItems(limit: 4)
                if quickPresets.isEmpty == false {
                    Divider()

                    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                        Text("Quick reuse")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AtlasPalette.primary)
                            .textCase(.uppercase)

                        Text(
                            state.insightsSnapshot.savedContextPresets.isEmpty
                                ? "Curated starting points for meal and surrounding context."
                                : "Saved presets also surface here for one-tap context capture."
                        )
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)

                        AtlasContextQuickPresetRail(presets: quickPresets) { preset in
                            Task { await model.saveContextEntry(preset.makeDraft(loggedAt: model.currentDate())) }
                        }

                        if recentMeals.isEmpty == false {
                            AtlasRecentMealQuickRail(items: recentMeals) { item in
                                Task { await model.saveContextEntry(item.draft(loggedAt: model.currentDate())) }
                            }
                        }

                        AtlasNutritionLookupRail(title: "Common foods", items: featuredFoods) { item in
                            Task { await model.saveContextEntry(item.makeDraft(loggedAt: model.currentDate())) }
                        }
                    }
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            AtlasWeeklyReviewEntrySection(model: model)

            if state.rewardsSnapshot.settings.enabled {
                Section("Mascot") {
                    AtlasMascotHomeCard(
                        selection: model.settingsSnapshot.mascotSelection,
                        nickname: model.settingsSnapshot.mascotNickname,
                        rewardsSnapshot: state.rewardsSnapshot,
                        history: model.settingsSnapshot.mascotEvolutionHistory,
                        moments: model.settingsSnapshot.mascotMoments,
                        onOpenDetail: {
                            model.open(.mascot)
                        }
                    )
                }
            }

            AtlasRetentionInsightSection(
                model: model,
                snapshot: state.retentionSnapshot,
                mascotSelection: model.settingsSnapshot.mascotSelection
            )

            AtlasRewardsInsightSection(
                snapshot: state.rewardsSnapshot,
                mascotSelection: model.settingsSnapshot.mascotSelection,
                mascotNickname: model.settingsSnapshot.mascotNickname,
                mascotHistory: model.settingsSnapshot.mascotEvolutionHistory
            )

            AtlasNutritionInsightSection(snapshot: state.insightsSnapshot.nutritionSnapshot)

            if state.insightsSnapshot.hasAnyInsightData == false {
                AtlasInsightsEmptyStateCard(
                    title: "No insight data yet",
                    message: "Context, weight, symptom, custom metric, and episode views will start building restrained patterns here."
                ) { EmptyView() }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } else {
                AtlasSummaryInsightSection(
                    featureFlags: model.dependencies.featureFlags.flags,
                    summarySettings: state.summarySettings,
                    weeklyRecapSummary: state.insightsSnapshot.weeklyRecapSummary,
                    episodeRecapSummary: state.insightsSnapshot.episodeRecapSummary
                )

                AtlasDeterministicExplainabilitySection(snapshot: state.insightsSnapshot)

                AtlasContextInsightSection(
                    model: model,
                    snapshot: state.insightsSnapshot,
                    renderMode: state.renderMode,
                    onEdit: { entry in
                        contextEditor = AtlasContextEditorState(entry: entry, referenceDate: model.currentDate())
                        contextSheetPresented = true
                    }
                )

                AtlasWeightInsightSection(
                    snapshot: state.insightsSnapshot,
                    onEdit: { entry in
                        weightEditor = AtlasWeightEditorState(entry: entry, referenceDate: model.currentDate())
                        weightSheetPresented = true
                    }
                )

                AtlasWorkoutInsightSection(snapshot: state.insightsSnapshot)

                AtlasSymptomInsightSection(
                    snapshot: state.insightsSnapshot,
                    onEdit: { entry in
                        symptomEditor = AtlasSymptomEditorState(entry: entry, referenceDate: model.currentDate())
                        symptomSheetPresented = true
                    }
                )

                AtlasCustomMetricInsightSection(
                    model: model,
                    snapshot: state.insightsSnapshot,
                    renderMode: state.renderMode,
                    onEditMetric: { metric in
                        metricDefinitionEditor = AtlasMetricDefinitionEditorState(metric: metric)
                        metricDefinitionSheetPresented = true
                    },
                    onLogMetric: { metric in
                        metricValueEditor = AtlasMetricValueEditorState(metric: metric, referenceDate: model.currentDate())
                        metricValueSheetPresented = true
                    },
                    onEditMetricEntry: { entry in
                        metricValueEditor = AtlasMetricValueEditorState(
                            entry: entry,
                            availableMetrics: state.insightsSnapshot.customMetricDefinitions,
                            referenceDate: model.currentDate()
                        )
                        metricValueSheetPresented = true
                    }
                )

                AtlasInventoryBurnDownSection(snapshot: state.insightsSnapshot)
                AtlasAdherenceInsightSection(snapshot: state.insightsSnapshot)
                AtlasAmountEstimateSection(model: model, snapshot: state.insightsSnapshot, renderMode: state.renderMode)
                AtlasEpisodeIntelligenceSection(model: model, snapshot: state.insightsSnapshot, renderMode: state.renderMode)
            }
        }
        .atlasRootListSurface()
        .sheet(isPresented: $contextSheetPresented) {
            AtlasContextEntrySheet(model: model, state: contextEditor)
        }
        .sheet(isPresented: $weightSheetPresented) {
            AtlasWeightEntrySheet(model: model, state: weightEditor)
        }
        .sheet(isPresented: $symptomSheetPresented) {
            AtlasSymptomEntrySheet(model: model, state: symptomEditor)
        }
        .sheet(isPresented: $metricDefinitionSheetPresented) {
            AtlasMetricDefinitionSheet(model: model, state: metricDefinitionEditor)
        }
        .sheet(isPresented: $metricValueSheetPresented) {
            AtlasMetricValueSheet(model: model, state: metricValueEditor)
        }
    }
}

private struct AtlasSummaryInsightSection: View {
    let featureFlags: AtlasFeatureFlagState
    let summarySettings: AtlasSummarySettingsSnapshot
    let weeklyRecapSummary: AtlasGeneratedSummary?
    let episodeRecapSummary: AtlasGeneratedSummary?

    var body: some View {
        if featureFlags.boundedSummaries {
            Section("Plain-language recaps") {
                if summarySettings.onDeviceEnabled == false {
                    AtlasSectionCard {
                        Text("On-device summaries are off. Enable them in Settings to see bounded weekly and episode recaps with source facts.")
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                } else {
                    if let weeklyRecapSummary {
                        AtlasGeneratedSummaryCard(summary: weeklyRecapSummary)
                    }
                    if let episodeRecapSummary {
                        AtlasGeneratedSummaryCard(summary: episodeRecapSummary)
                    }
                }
            }
        }
    }
}

private struct AtlasDeterministicExplainabilitySection: View {
    let snapshot: AtlasInsightsSnapshot

    var body: some View {
        if snapshot.deterministicExplanations.isEmpty == false {
            Section("Why this appears") {
                AtlasSectionCard {
                    Text("Atlas is describing nearby timing patterns from local records only. These cards are descriptive, bounded, and do not claim cause or recommend changes.")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    ForEach(Array(snapshot.deterministicExplanations.enumerated()), id: \.element.id) { index, card in
                        if index > 0 {
                            Divider()
                        }

                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            Text(card.title)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AtlasPalette.textPrimary)

                            Text(card.summary)
                                .foregroundStyle(AtlasPalette.textSecondary)

                            AtlasDeterministicInsightFactList(facts: card.facts)
                        }
                        .padding(.vertical, AtlasSpacing.xSmall)
                    }
                }
            }
        }
    }
}

private struct AtlasDeterministicInsightFactList: View {
    let facts: [AtlasExplainerFact]

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            ForEach(facts) { fact in
                VStack(alignment: .leading, spacing: 2) {
                    Text(fact.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.primary)
                    Text(fact.value)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
        }
    }
}

private struct AtlasContextInsightSection: View {
    let model: AtlasAppModel
    let snapshot: AtlasInsightsSnapshot
    let renderMode: AtlasPrivacyRenderMode
    let onEdit: (AtlasContextEntrySummary) -> Void

    var body: some View {
        Section("Context") {
            AtlasSectionCard {
                if snapshot.contextTrend.recentEntryCount == 0 && snapshot.recentContextEntries.isEmpty {
                    Text("No context entries yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    Text("\(snapshot.contextTrend.recentEntryCount) context entr\(snapshot.contextTrend.recentEntryCount == 1 ? "y" : "ies") in the last two weeks")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)

                    if let latestLabel = snapshot.contextTrend.latestLabel {
                        Text(latestLabel)
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    let quickFacts = [
                        snapshot.contextTrend.fastedEntryCount > 0 ? "Fasted: \(snapshot.contextTrend.fastedEntryCount)" : nil,
                        snapshot.contextTrend.fedEntryCount > 0 ? "Fed: \(snapshot.contextTrend.fedEntryCount)" : nil,
                        snapshot.contextTrend.lowHydrationEntryCount > 0 ? "Low hydration: \(snapshot.contextTrend.lowHydrationEntryCount)" : nil,
                        snapshot.contextTrend.giEntryCount > 0 ? "GI context: \(snapshot.contextTrend.giEntryCount)" : nil
                    ]
                    .compactMap { $0 }

                    if quickFacts.isEmpty == false {
                        Text(quickFacts.joined(separator: " • "))
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    if snapshot.savedContextPresets.isEmpty == false {
                        Text("\(snapshot.savedContextPresets.count) saved preset\(snapshot.savedContextPresets.count == 1 ? "" : "s") ready for Today and quick capture")
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    ForEach(snapshot.recentContextEntries) { entry in
                        Button {
                            onEdit(entry)
                        } label: {
                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                        Text(model.renderedContextTitle(entry, renderMode: renderMode))
                                            .foregroundStyle(AtlasPalette.textPrimary)

                                        if let presetTitle = model.contextPresetTitle(for: entry.presetKey) {
                                            Text("Preset: \(presetTitle)")
                                                .font(.caption2)
                                                .foregroundStyle(AtlasPalette.textTertiary)
                                        }
                                    }
                                    Spacer(minLength: 12)
                                    Text(entry.loggedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                                if let detail = model.renderedContextDetail(entry, renderMode: renderMode) {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct AtlasWorkoutInsightSection: View {
    let snapshot: AtlasInsightsSnapshot

    var body: some View {
        Section("Activity") {
            AtlasSectionCard {
                if snapshot.recentWorkoutEntries.isEmpty {
                    Text("No imported workouts yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    Text("Recent workouts imported from Apple Health stay local to this Atlas timeline.")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    ForEach(snapshot.recentWorkoutEntries) { entry in
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(entry.activityKind.title)
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Spacer()
                                Text(entry.durationLabel)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }

                            Text(entry.startedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)

                            if let detailLabel = entry.detailLabel {
                                Text(detailLabel)
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct AtlasWeightInsightSection: View {
    let snapshot: AtlasInsightsSnapshot
    let onEdit: (AtlasWeightEntrySummary) -> Void

    var body: some View {
        Section("Weight trend") {
            AtlasSectionCard {
                if snapshot.weightTrend.points.isEmpty {
                    Text("No weight entries yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    Chart(snapshot.weightTrend.points) { point in
                        LineMark(
                            x: .value("Date", point.loggedAt),
                            y: .value("Weight", point.value)
                        )
                        .foregroundStyle(AtlasPalette.primary)
                        PointMark(
                            x: .value("Date", point.loggedAt),
                            y: .value("Weight", point.value)
                        )
                        .foregroundStyle(AtlasPalette.primary)
                    }
                    .frame(height: 180)
                    .accessibilityLabel("Weight trend chart")
                    .accessibilityValue(snapshot.weightTrend.latestLabel ?? "No recent weight summary")

                    if let latest = snapshot.weightTrend.latestLabel {
                        Text(latest)
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                    if let change = snapshot.weightTrend.changeLabel {
                        Text(change)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    ForEach(snapshot.recentWeightEntries) { entry in
                        Button {
                            onEdit(entry)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    Text(entry.valueLabel)
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                    Text(entry.loggedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                                Spacer()
                                if let notes = entry.notes, notes.isEmpty == false {
                                    Image(systemName: "note.text")
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct AtlasSymptomInsightSection: View {
    let snapshot: AtlasInsightsSnapshot
    let onEdit: (AtlasSymptomEntrySummary) -> Void

    var body: some View {
        Section("Symptoms") {
            AtlasSectionCard {
                if snapshot.symptomTrend.isEmpty && snapshot.recentSymptomEntries.isEmpty {
                    Text("No symptom entries yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    if snapshot.symptomTrend.isEmpty == false {
                        Chart(snapshot.symptomTrend) { item in
                            BarMark(
                                x: .value("Symptom", item.symptomKey),
                                y: .value("Average", Double(item.averageSeverityLabel) ?? 0)
                            )
                            .foregroundStyle(AtlasPalette.primary.opacity(0.8))
                        }
                        .frame(height: 180)
                        .accessibilityLabel("Symptom trend chart")
                        .accessibilityValue("Shows recent average severity by symptom")
                    }

                    ForEach(snapshot.symptomTrend) { item in
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            Text(item.symptomKey.capitalized)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text("\(item.averageSeverityLabel)/5 average • \(item.entryCount) entries • \(item.latestLabel)")
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }

                    if snapshot.recentSymptomEntries.isEmpty == false {
                        Divider()
                        ForEach(snapshot.recentSymptomEntries) { entry in
                            Button {
                                onEdit(entry)
                            } label: {
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    Text("\(entry.symptomKey.capitalized) • \(entry.severity)/5")
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                    Text(entry.loggedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

private struct AtlasCustomMetricInsightSection: View {
    let model: AtlasAppModel
    let snapshot: AtlasInsightsSnapshot
    let renderMode: AtlasPrivacyRenderMode
    let onEditMetric: (AtlasMetricDefinitionSummary) -> Void
    let onLogMetric: (AtlasMetricDefinitionSummary) -> Void
    let onEditMetricEntry: (AtlasMetricValueEntrySummary) -> Void

    var body: some View {
        Section("Custom metrics") {
            AtlasSectionCard {
                if snapshot.customMetricDefinitions.isEmpty {
                    Text("No custom metrics saved yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(snapshot.customMetricDefinitions) { metric in
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            HStack {
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    Text(model.renderedMetricLabel(canonical: metric.label, renderMode: renderMode))
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                    if let protocolTitle = metric.canonicalProtocolTitle {
                                        Text(model.renderedTitle(canonical: protocolTitle, alias: metric.aliasProtocolTitle, renderMode: renderMode))
                                            .font(.caption)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }
                                    Text(metricTypeLabel(metric))
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                    if let latestEntryLabel = metric.latestEntryLabel {
                                        Text("Latest: \(latestEntryLabel)")
                                            .font(.caption)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }
                                }
                                Spacer()
                                if metric.archivedAt != nil {
                                    AtlasStatusBadge("Archived", tint: AtlasPalette.textSecondary)
                                }
                            }

                            HStack {
                                Button("Edit") {
                                    onEditMetric(metric)
                                }
                                .buttonStyle(.bordered)

                                Button("Log entry") {
                                    onLogMetric(metric)
                                }
                                .buttonStyle(.bordered)
                                .disabled(metric.archivedAt != nil)

                                if metric.archivedAt == nil {
                                    Button("Archive", role: .destructive) {
                                        Task { await model.archiveMetricDefinition(id: metric.id) }
                                    }
                                } else if metric.logCount == 0 {
                                    Button("Delete", role: .destructive) {
                                        Task { await model.deleteMetricDefinition(id: metric.id) }
                                    }
                                }
                            }
                        }
                    }

                    if snapshot.recentMetricEntries.isEmpty == false {
                        Divider()
                        Text("Recent custom metric entries")
                            .font(.headline)
                            .foregroundStyle(AtlasPalette.textPrimary)

                        ForEach(snapshot.recentMetricEntries) { entry in
                            Button {
                                onEditMetricEntry(entry)
                            } label: {
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    Text("\(model.renderedMetricLabel(canonical: entry.label, renderMode: renderMode)): \(entry.valueLabel)")
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                    if let protocolTitle = entry.canonicalProtocolTitle {
                                        Text(model.renderedTitle(canonical: protocolTitle, alias: entry.aliasProtocolTitle, renderMode: renderMode))
                                            .font(.caption)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }
                                    Text(entry.loggedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func metricTypeLabel(_ metric: AtlasMetricDefinitionSummary) -> String {
        switch metric.valueType {
        case .number:
            return metric.unit.map { "Numeric • \($0)" } ?? "Numeric"
        case .scale:
            let min = metric.scaleMin ?? 0
            let max = metric.scaleMax ?? 5
            return "Scale • \(min)-\(max)"
        case .text:
            return "Text"
        case .boolean:
            return "Boolean"
        }
    }
}

private struct AtlasInventoryBurnDownSection: View {
    let snapshot: AtlasInsightsSnapshot

    var body: some View {
        Section("Inventory outlook") {
            AtlasSectionCard {
                if snapshot.inventoryBurnDown.isEmpty {
                    Text("No inventory data yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    Chart(snapshot.inventoryBurnDown.prefix(5)) { item in
                        BarMark(
                            x: .value("Item", item.label),
                            y: .value("Remaining", burnDownValue(from: item.quantityLabel))
                        )
                        .foregroundStyle(item.isLowStock ? .orange : AtlasPalette.primary)
                    }
                    .frame(height: 180)

                    ForEach(snapshot.inventoryBurnDown) { item in
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            HStack {
                                Text(item.label)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Spacer()
                                if item.isLowStock {
                                    AtlasStatusBadge("Low stock", tint: .orange)
                                }
                            }
                            Text(item.quantityLabel)
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)
                            if let projected = item.projectedDepletionLabel {
                                Text(projected)
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func burnDownValue(from quantityLabel: String) -> Double {
        Double(quantityLabel.split(separator: " ").first ?? "") ?? 0
    }
}

private struct AtlasAdherenceInsightSection: View {
    let snapshot: AtlasInsightsSnapshot

    var body: some View {
        Section("Adherence") {
            AtlasSectionCard {
                if snapshot.adherenceTrend.completedCount + snapshot.adherenceTrend.overdueCount + snapshot.adherenceTrend.skippedCount + snapshot.adherenceTrend.rescheduledCount == 0 {
                    Text("No due-history yet for this window.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    Chart {
                        BarMark(x: .value("State", "Taken"), y: .value("Count", snapshot.adherenceTrend.completedCount))
                            .foregroundStyle(AtlasPalette.success)
                        BarMark(x: .value("State", "Skipped"), y: .value("Count", snapshot.adherenceTrend.skippedCount))
                            .foregroundStyle(.orange)
                        BarMark(x: .value("State", "Overdue"), y: .value("Count", snapshot.adherenceTrend.overdueCount))
                            .foregroundStyle(.red)
                        BarMark(x: .value("State", "Moved"), y: .value("Count", snapshot.adherenceTrend.rescheduledCount))
                            .foregroundStyle(AtlasPalette.primary)
                    }
                    .frame(height: 180)

                    if let label = snapshot.adherenceTrend.completionRateLabel {
                        Text(label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                }
            }
        }
    }
}

private struct AtlasAmountEstimateSection: View {
    let model: AtlasAppModel
    let snapshot: AtlasInsightsSnapshot
    let renderMode: AtlasPrivacyRenderMode

    var body: some View {
        Section("Estimated amount in system") {
            AtlasSectionCard {
                Text(snapshot.amountInSystemDisclaimer)
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)

                if snapshot.amountInSystem.isEmpty {
                    Text("No active protocols with recent completed quantities yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(snapshot.amountInSystem) { item in
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            Text(model.renderedTitle(canonical: item.canonicalProtocolTitle, alias: item.aliasProtocolTitle, renderMode: renderMode))
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text(item.estimateLabel)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text(item.cadenceLabel)
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)
                            Text(item.notesLabel)
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

private struct AtlasEpisodeIntelligenceSection: View {
    let model: AtlasAppModel
    let snapshot: AtlasInsightsSnapshot
    let renderMode: AtlasPrivacyRenderMode

    var body: some View {
        Section("Episode patterns") {
            AtlasSectionCard {
                Text(snapshot.episodeIntelligence.disclaimer)
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)

                if snapshot.episodeIntelligence.hasAnyEpisodeData == false {
                    Text("Completed dose logs plus surrounding context, symptom, weight, or metric entries are needed before Atlas can describe episode timing.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    if snapshot.episodeIntelligence.compareWindows.isEmpty == false {
                        Text("Compare windows")
                            .font(.headline)
                            .foregroundStyle(AtlasPalette.textPrimary)

                        ForEach(snapshot.episodeIntelligence.compareWindows) { row in
                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                Text(row.windowKind.title)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Text(row.summaryLabel)
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                    }

                    if snapshot.episodeIntelligence.patternCards.isEmpty == false {
                        Divider()
                        Text("For you")
                            .font(.headline)
                            .foregroundStyle(AtlasPalette.textPrimary)

                        ForEach(snapshot.episodeIntelligence.patternCards) { card in
                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                if let canonicalTitle = card.canonicalProtocolTitle {
                                    Text(model.renderedTitle(canonical: canonicalTitle, alias: card.aliasProtocolTitle, renderMode: renderMode))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AtlasPalette.primary)
                                }
                                Text(card.title)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Text(card.detail)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                HStack {
                                    Text(card.confidence.label)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                    if let windowKind = card.windowKind {
                                        Text(windowKind.title)
                                            .font(.caption)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }
                                }
                            }
                            .padding(.vertical, AtlasSpacing.xSmall)
                        }
                    }

                    if snapshot.episodeIntelligence.recentEpisodes.isEmpty == false {
                        Divider()
                        Text("Recent dose episodes")
                            .font(.headline)
                            .foregroundStyle(AtlasPalette.textPrimary)

                        ForEach(snapshot.episodeIntelligence.recentEpisodes) { episode in
                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                Text(model.renderedTitle(canonical: episode.canonicalProtocolTitle, alias: episode.aliasProtocolTitle, renderMode: renderMode))
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Text(episode.doseAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                Text(episode.reminderTimingLabel)
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                Text(episode.adherenceLabel)
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                if let siteLabel = episode.siteLabel {
                                    Text("Site: \(siteLabel)")
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                                Text("\(episode.contextEntryCount) context entr\(episode.contextEntryCount == 1 ? "y" : "ies") • \(episode.symptomEntryCount) symptom entr\(episode.symptomEntryCount == 1 ? "y" : "ies") • \(episode.weightEntryCount) weight entr\(episode.weightEntryCount == 1 ? "y" : "ies") • \(episode.metricEntryCount) metric entr\(episode.metricEntryCount == 1 ? "y" : "ies")")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct AtlasContextEntrySheet: View {
    let model: AtlasAppModel
    @Environment(\.dismiss) private var dismiss
    @State private var state: AtlasContextEditorState

    init(model: AtlasAppModel, state: AtlasContextEditorState) {
        self.model = model
        _state = State(initialValue: state)
    }

    var body: some View {
        NavigationStack {
            AtlasScreen {
                AtlasSectionCard(style: .hero) {
                    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                        Text("Capture the context Atlas can actually use.")
                            .font(.headline)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text("Start with a preset, a recent meal, or a few quick taps. Notes stay optional.")
                            .foregroundStyle(AtlasPalette.textSecondary)

                        AtlasContextQuickPresetRail(
                            title: "Built-in presets",
                            presets: AtlasContextBuiltinPreset.allCases.map { AtlasContextQuickPreset($0) },
                            selectedPresetKey: state.presetKey
                        ) { preset in
                            state.applyQuickPreset(preset)
                        }

                        if model.insightsSnapshot.savedContextPresets.isEmpty == false {
                            AtlasContextQuickPresetRail(
                                title: "Saved presets",
                                presets: model.insightsSnapshot.savedContextPresets.map { AtlasContextQuickPreset(preset: $0) },
                                selectedPresetKey: state.presetKey
                            ) { preset in
                                state.applyQuickPreset(preset)
                            }
                        }
                    }
                }

                AtlasSectionCard(style: .utility, title: "Fast meal capture") {
                    let textSuggestion = model.nutritionQuickCaptureSuggestion(
                        for: state.quickCaptureText,
                        loggedAt: state.loggedAt
                    )
                    let codeSuggestion = model.nutritionPackageCodeSuggestion(
                        for: state.packageCode,
                        loggedAt: state.loggedAt
                    )
                    let lookupItems = model.nutritionLookupItems(query: state.quickCaptureText, limit: 5)
                    let railItems = lookupItems.isEmpty ? model.nutritionFeaturedLookupItems(limit: 5) : lookupItems

                    TextField("Type or dictate a meal", text: $state.quickCaptureText, axis: .vertical)
                        .atlasStandaloneInputSurface()

                    if let textSuggestion {
                        AtlasNutritionSuggestionButton(
                            suggestion: textSuggestion,
                            buttonTitle: "Apply parsed meal"
                        ) {
                            state.applyNutritionSuggestion(textSuggestion)
                        }
                    }

                    TextField("Package code", text: $state.packageCode)
                        .autocorrectionDisabled()
                        .atlasStandaloneInputSurface()

                    if let codeSuggestion {
                        AtlasNutritionSuggestionButton(
                            suggestion: codeSuggestion,
                            buttonTitle: "Apply code match"
                        ) {
                            state.applyNutritionSuggestion(codeSuggestion)
                            state.packageCode = ""
                        }
                    }

                    AtlasNutritionLookupRail(
                        title: lookupItems.isEmpty ? "Common foods" : "Lookup matches",
                        items: railItems
                    ) { item in
                        state.applyFoodLookupItem(item)
                    }

                    Text("Use keyboard dictation for voice-style capture. Atlas keeps this parsing local and deterministic.")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                AtlasSectionCard(style: .elevated, title: "Quick capture") {
                    DatePicker("Logged at", selection: $state.loggedAt)

                    AtlasContextSelectionSection(
                        title: "Meal timing",
                        options: AtlasContextMealTiming.allCases,
                        selected: state.mealTiming,
                        noneTitle: "Skip",
                        tint: AtlasPalette.primary
                    ) { state.setMealTiming($0) }

                    AtlasContextSelectionSection(
                        title: "Meal size",
                        options: AtlasContextMealSize.allCases,
                        selected: state.mealSize,
                        noneTitle: "Skip",
                        tint: AtlasPalette.secondaryText
                    ) { state.setMealSize($0) }

                    AtlasContextSelectionSection(
                        title: "Meal composition",
                        options: AtlasContextMealComposition.allCases,
                        selected: state.mealComposition,
                        noneTitle: "Skip",
                        tint: AtlasPalette.secondaryText
                    ) { state.setMealComposition($0) }

                    AtlasContextSelectionSection(
                        title: "Fed / fasted",
                        options: AtlasContextFedState.allCases,
                        selected: state.fedState,
                        noneTitle: "Skip",
                        tint: AtlasPalette.primary
                    ) { state.setFedState($0) }
                }

                AtlasSectionCard(style: .utility, title: "Reuse later") {
                    Text("Save the current quick-capture shape as a reusable preset. Notes stay per entry.")
                        .foregroundStyle(AtlasPalette.textSecondary)

                    TextField("Optional preset name", text: $state.presetTitle)
                        .atlasStandaloneInputSurface()

                    Text("Leave the name blank and Atlas will suggest one from the selected context.")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    Button("Save preset") {
                        let presetDraft = state.presetDraft
                        Task { @MainActor in
                            if let savedPreset = await model.saveContextPreset(presetDraft) {
                                state.presetKey = savedPreset.id
                                state.presetTitle = ""
                            }
                        }
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                    .disabled(state.canSavePreset == false)

                    if model.insightsSnapshot.savedContextPresets.isEmpty == false {
                        Divider()

                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            Text("Manage saved presets")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AtlasPalette.primary)
                                .textCase(.uppercase)

                            ForEach(model.insightsSnapshot.savedContextPresets) { preset in
                                AtlasSavedContextPresetRow(
                                    preset: preset,
                                    isSelected: state.presetKey == preset.id,
                                    onUse: { state.applyQuickPreset(AtlasContextQuickPreset(preset: preset)) },
                                    onDelete: {
                                        if state.presetKey == preset.id {
                                            state.presetKey = nil
                                        }
                                        Task { await model.deleteContextPreset(id: preset.id) }
                                    }
                                )
                            }
                        }
                    }
                }

                AtlasSectionCard(title: "More detail") {
                    Picker("Related protocol", selection: $state.protocolID) {
                        Text("None").tag(String?.none)
                        ForEach(model.libraryProtocols) { protocolSummary in
                            Text(model.renderedTitle(canonical: protocolSummary.canonicalTitle, alias: protocolSummary.aliasTitle))
                                .tag(String?.some(protocolSummary.id))
                        }
                    }

                    AtlasContextSelectionSection(
                        title: "Appetite",
                        options: AtlasContextAppetiteState.allCases,
                        selected: state.appetite,
                        noneTitle: "Skip",
                        tint: AtlasPalette.secondaryText
                    ) { state.setAppetite($0) }

                    AtlasContextSelectionSection(
                        title: "Hydration",
                        options: AtlasContextHydrationState.allCases,
                        selected: state.hydration,
                        noneTitle: "Skip",
                        tint: AtlasPalette.secondaryText
                    ) { state.setHydration($0) }

                    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                        Text("GI context")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AtlasPalette.primary)
                            .textCase(.uppercase)

                        AtlasChipFlowLayout(spacing: AtlasSpacing.small) {
                            ForEach(AtlasContextGITag.allCases, id: \.self) { tag in
                                Button(tag.title) {
                                    state.setGITag(tag, enabled: state.giTags.contains(tag) == false)
                                }
                                .buttonStyle(
                                    AtlasChipButtonStyle(
                                        tint: state.giTags.contains(tag) ? AtlasPalette.warning : AtlasPalette.textSecondary
                                    )
                                )
                            }
                        }
                    }

                    TextField("Tags (comma separated)", text: $state.tags)
                        .autocorrectionDisabled()
                    TextField("Optional note", text: $state.note, axis: .vertical)
                }
            }
            .atlasFormSurface()
            .atlasKeyboardDoneToolbar()
            .navigationTitle(state.id == nil ? "Log context" : "Edit context")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await model.saveContextEntry(state.domainDraft)
                            dismiss()
                        }
                    }
                    .disabled(state.canSave == false)
                }
            }
        }
    }
}

private struct AtlasWeightEntrySheet: View {
    let model: AtlasAppModel
    @Environment(\.dismiss) private var dismiss
    @State private var state: AtlasWeightEditorState

    init(model: AtlasAppModel, state: AtlasWeightEditorState) {
        self.model = model
        _state = State(initialValue: state)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Entry") {
                    DatePicker("Logged at", selection: $state.loggedAt)
                    Picker("Unit", selection: $state.unit) {
                        Text("lb").tag(AtlasWeightUnit.lb)
                        Text("kg").tag(AtlasWeightUnit.kg)
                    }
                    .pickerStyle(.segmented)

                    AtlasNumericEntryControl(
                        title: "Value",
                        unitLabel: state.unit.rawValue,
                        value: Binding(
                            get: { Double(state.value) ?? (state.unit == .kg ? 80 : 180) },
                            set: { state.value = AtlasNumericEntryControl.formattedValue($0) }
                        ),
                        range: state.unit == .kg ? 30...250 : 70...550,
                        step: state.unit == .kg ? 0.5 : 1
                    )
                }

                Section("Notes") {
                    TextField("Optional note", text: $state.notes, axis: .vertical)
                }
            }
            .atlasFormSurface()
            .navigationTitle(state.id == nil ? "Log weight" : "Edit weight")
            .atlasKeyboardDoneToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await model.saveWeightEntry(state.domainDraft)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

private struct AtlasSymptomEntrySheet: View {
    let model: AtlasAppModel
    @Environment(\.dismiss) private var dismiss
    @State private var state: AtlasSymptomEditorState

    init(model: AtlasAppModel, state: AtlasSymptomEditorState) {
        self.model = model
        _state = State(initialValue: state)
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Logged at", selection: $state.loggedAt)
                TextField("Symptom", text: $state.symptomKey)
                Stepper("Severity: \(state.severity)/5", value: $state.severity, in: 1...5)
                TextField("Notes", text: $state.notes, axis: .vertical)
            }
            .atlasFormSurface()
            .navigationTitle(state.id == nil ? "Log symptom" : "Edit symptom")
            .atlasKeyboardDoneToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await model.saveSymptomEntry(state.domainDraft)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

private struct AtlasMetricDefinitionSheet: View {
    let model: AtlasAppModel
    @Environment(\.dismiss) private var dismiss
    @State private var state: AtlasMetricDefinitionEditorState

    init(model: AtlasAppModel, state: AtlasMetricDefinitionEditorState) {
        self.model = model
        _state = State(initialValue: state)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Label", text: $state.label)
                Picker("Type", selection: $state.valueType) {
                    Text("Numeric").tag(AtlasCustomMetricValueType.number)
                    Text("Scale").tag(AtlasCustomMetricValueType.scale)
                    Text("Boolean").tag(AtlasCustomMetricValueType.boolean)
                    Text("Text").tag(AtlasCustomMetricValueType.text)
                }

                Picker("Protocol", selection: $state.protocolID) {
                    Text("None").tag(String?.none)
                    ForEach(model.libraryProtocols) { protocolSummary in
                        Text(model.renderedTitle(canonical: protocolSummary.canonicalTitle, alias: protocolSummary.aliasTitle))
                            .tag(String?.some(protocolSummary.id))
                    }
                }

                if state.valueType == .number {
                    TextField("Unit", text: $state.unit)
                }

                if state.valueType == .scale {
                    TextField("Scale minimum", text: $state.scaleMin)
                        .atlasDecimalKeyboard()
                    TextField("Scale maximum", text: $state.scaleMax)
                        .atlasDecimalKeyboard()
                }
            }
            .atlasFormSurface()
            .navigationTitle(state.id == nil ? "New metric" : "Edit metric")
            .atlasKeyboardDoneToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await model.saveMetricDefinition(state.domainDraft)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

private struct AtlasMetricValueSheet: View {
    let model: AtlasAppModel
    @Environment(\.dismiss) private var dismiss
    @State private var state: AtlasMetricValueEditorState

    init(model: AtlasAppModel, state: AtlasMetricValueEditorState) {
        self.model = model
        _state = State(initialValue: state)
    }

    var body: some View {
        let availableMetrics = model.insightsSnapshot.customMetricDefinitions.filter { $0.archivedAt == nil }
        let selectedMetric = availableMetrics.first(where: { $0.id == state.metricID })

        NavigationStack {
            Form {
                Picker("Metric", selection: $state.metricID) {
                    ForEach(availableMetrics) { metric in
                        Text(model.renderedMetricLabel(canonical: metric.label)).tag(metric.id)
                    }
                }

                DatePicker("Logged at", selection: $state.loggedAt)

                if let selectedMetric {
                    if selectedMetric.valueType == .number {
                        AtlasNumericEntryControl(
                            title: "Value",
                            unitLabel: selectedMetric.unit,
                            value: Binding(
                                get: { Double(state.numberValue) ?? 0 },
                                set: { state.numberValue = AtlasNumericEntryControl.formattedValue($0) }
                            ),
                            range: 0...500,
                            step: 0.5
                        )
                    } else if selectedMetric.valueType == .scale {
                        let min = Double(selectedMetric.scaleMin ?? 0)
                        let max = Double(selectedMetric.scaleMax ?? 5)
                        AtlasScaleValueControl(
                            value: Binding(
                                get: { Double(state.numberValue) ?? min },
                                set: { newValue in
                                    state.numberValue = AtlasScaleValueControl.formattedValue(newValue)
                                }
                            ),
                            range: min...max
                        )
                    } else if selectedMetric.valueType == .text {
                        TextField("Text value", text: $state.textValue, axis: .vertical)
                    } else {
                        Toggle("Value is true", isOn: Binding(
                            get: { state.booleanValue ?? false },
                            set: { state.booleanValue = $0 }
                        ))
                    }
                }
            }
            .atlasFormSurface()
            .navigationTitle(state.id == nil ? "Log metric" : "Edit metric entry")
            .atlasKeyboardDoneToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await model.saveMetricValueEntry(state.domainDraft)
                            dismiss()
                        }
                    }
                    .disabled(state.metricID.isEmpty)
                }
            }
        }
    }
}

struct AtlasContextEditorState {
    var id: String?
    var protocolID: String?
    var loggedAt: Date
    var quickCaptureText: String
    var packageCode: String
    var mealTiming: AtlasContextMealTiming?
    var mealSize: AtlasContextMealSize?
    var mealComposition: AtlasContextMealComposition?
    var fedState: AtlasContextFedState?
    var appetite: AtlasContextAppetiteState?
    var hydration: AtlasContextHydrationState?
    var giTags: Set<AtlasContextGITag>
    var note: String
    var tags: String
    var presetKey: String?
    var presetTitle: String

    init(entry: AtlasContextEntrySummary? = nil, referenceDate: Date) {
        id = entry?.id
        protocolID = entry?.protocolID
        loggedAt = entry?.loggedAt ?? referenceDate
        quickCaptureText = ""
        packageCode = ""
        mealTiming = entry?.mealTiming
        mealSize = entry?.mealSize
        mealComposition = entry?.mealComposition
        fedState = entry?.fedState
        appetite = entry?.appetite
        hydration = entry?.hydration
        giTags = Set(entry?.giTags ?? [])
        note = entry?.note ?? ""
        tags = (entry?.tags ?? []).joined(separator: ", ")
        presetKey = entry?.presetKey
        presetTitle = ""
    }

    mutating func setGITag(_ tag: AtlasContextGITag, enabled: Bool) {
        clearAppliedPreset()
        if enabled {
            if tag == .calm {
                giTags = [.calm]
            } else {
                giTags.remove(.calm)
                giTags.insert(tag)
            }
        } else {
            giTags.remove(tag)
        }
    }

    mutating func setMealTiming(_ value: AtlasContextMealTiming?) {
        clearAppliedPreset()
        mealTiming = value
    }

    mutating func setMealSize(_ value: AtlasContextMealSize?) {
        clearAppliedPreset()
        mealSize = value
    }

    mutating func setMealComposition(_ value: AtlasContextMealComposition?) {
        clearAppliedPreset()
        mealComposition = value
    }

    mutating func setFedState(_ value: AtlasContextFedState?) {
        clearAppliedPreset()
        fedState = value
    }

    mutating func setAppetite(_ value: AtlasContextAppetiteState?) {
        clearAppliedPreset()
        appetite = value
    }

    mutating func setHydration(_ value: AtlasContextHydrationState?) {
        clearAppliedPreset()
        hydration = value
    }

    mutating func applyQuickPreset(_ preset: AtlasContextQuickPreset) {
        presetKey = preset.presetKey
        mealTiming = preset.mealTiming
        mealSize = preset.mealSize
        mealComposition = preset.mealComposition
        fedState = preset.fedState
        appetite = preset.appetite
        hydration = preset.hydration
        giTags = Set(preset.giTags)
    }

    mutating func applyFoodLookupItem(_ item: AtlasNutritionFoodLookupItem) {
        applyNutritionSuggestion(
            item.makeSuggestion(
                loggedAt: loggedAt,
                source: .lookup,
                helperText: "Atlas applied this common-food profile to the current meal draft."
            )
        )
    }

    mutating func applyNutritionSuggestion(_ suggestion: AtlasNutritionQuickCaptureSuggestion) {
        clearAppliedPreset()
        mealTiming = suggestion.draft.mealTiming
        mealSize = suggestion.draft.mealSize
        mealComposition = suggestion.draft.mealComposition
        fedState = suggestion.draft.fedState
        appetite = suggestion.draft.appetite
        hydration = suggestion.draft.hydration
        giTags = Set(suggestion.draft.giTags)
        if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            note = suggestion.draft.note ?? ""
        }
        let existingTags = Set(
            tags
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.isEmpty == false }
        )
        let mergedTags = existingTags.union(suggestion.draft.tags)
        tags = mergedTags.sorted().joined(separator: ", ")
        quickCaptureText = ""
    }

    var canSave: Bool {
        mealTiming != nil
            || mealSize != nil
            || mealComposition != nil
            || fedState != nil
            || appetite != nil
            || hydration != nil
            || giTags.isEmpty == false
            || note.nilIfEmpty != nil
            || tags.split(separator: ",").isEmpty == false
    }

    var canSavePreset: Bool {
        mealTiming != nil
            || mealSize != nil
            || mealComposition != nil
            || fedState != nil
            || appetite != nil
            || hydration != nil
            || giTags.isEmpty == false
    }

    var presetDraft: AtlasContextPresetDraft {
        AtlasContextPresetDraft(
            title: resolvedPresetTitle,
            mealTiming: mealTiming,
            mealSize: mealSize,
            mealComposition: mealComposition,
            fedState: fedState,
            appetite: appetite,
            hydration: hydration,
            giTags: giTags.sorted { $0.rawValue < $1.rawValue }
        )
    }

    private var resolvedPresetTitle: String {
        let trimmed = presetTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? atlasSuggestedContextPresetTitle(from: self) : trimmed
    }

    private mutating func clearAppliedPreset() {
        presetKey = nil
    }

    var domainDraft: AtlasContextEntryDraft {
        AtlasContextEntryDraft(
            id: id,
            protocolID: protocolID,
            loggedAt: loggedAt,
            mealTiming: mealTiming,
            mealSize: mealSize,
            mealComposition: mealComposition,
            fedState: fedState,
            appetite: appetite,
            hydration: hydration,
            giTags: giTags.sorted { $0.rawValue < $1.rawValue },
            note: note.nilIfEmpty,
            tags: tags
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.isEmpty == false },
            presetKey: presetKey
        )
    }
}

enum AtlasContextBuiltinPreset: CaseIterable {
    case breakfastStandard
    case fastedMorning
    case proteinMeal
    case fiberMeal
    case heavyDinner
    case steadyHydration
    case giOff

    var id: String {
        switch self {
        case .breakfastStandard: "breakfast_standard"
        case .fastedMorning: "fasted_morning"
        case .proteinMeal: "protein_meal"
        case .fiberMeal: "fiber_meal"
        case .heavyDinner: "heavy_dinner"
        case .steadyHydration: "steady_hydration"
        case .giOff: "gi_off"
        }
    }

    var title: String {
        switch self {
        case .breakfastStandard: "Breakfast"
        case .fastedMorning: "Fasted morning"
        case .proteinMeal: "Protein meal"
        case .fiberMeal: "Fiber meal"
        case .heavyDinner: "Heavy dinner"
        case .steadyHydration: "Hydrated"
        case .giOff: "GI off"
        }
    }

    var subtitle: String {
        switch self {
        case .breakfastStandard: "Standard meal check-in"
        case .fastedMorning: "Quick baseline check-in"
        case .proteinMeal: "Simple meal context"
        case .fiberMeal: "A quick fiber-forward check-in"
        case .heavyDinner: "Useful for evening patterns"
        case .steadyHydration: "Capture hydration context"
        case .giOff: "When the gut feels off"
        }
    }

    var mealTiming: AtlasContextMealTiming? {
        switch self {
        case .breakfastStandard, .fastedMorning: .breakfast
        case .proteinMeal: .lunch
        case .fiberMeal: .dinner
        case .heavyDinner: .dinner
        case .steadyHydration, .giOff: nil
        }
    }

    var mealSize: AtlasContextMealSize? {
        switch self {
        case .breakfastStandard, .proteinMeal: .standard
        case .fiberMeal: .standard
        case .fastedMorning, .steadyHydration, .giOff: nil
        case .heavyDinner: .heavy
        }
    }

    var mealComposition: AtlasContextMealComposition? {
        switch self {
        case .proteinMeal: .proteinHeavy
        case .fiberMeal: .fiberForward
        case .heavyDinner: .mixed
        case .breakfastStandard, .fastedMorning, .steadyHydration, .giOff: nil
        }
    }

    var fedState: AtlasContextFedState? {
        switch self {
        case .breakfastStandard, .proteinMeal, .fiberMeal, .heavyDinner: .fed
        case .fastedMorning: .fasted
        case .steadyHydration, .giOff: nil
        }
    }

    var appetite: AtlasContextAppetiteState? {
        switch self {
        case .giOff: .low
        case .breakfastStandard, .fastedMorning, .proteinMeal, .fiberMeal, .heavyDinner, .steadyHydration: nil
        }
    }

    var hydration: AtlasContextHydrationState? {
        switch self {
        case .steadyHydration: .high
        case .breakfastStandard, .fastedMorning, .proteinMeal, .fiberMeal, .heavyDinner, .giOff: nil
        }
    }

    var giTags: [AtlasContextGITag] {
        switch self {
        case .giOff:
            return [.nausea]
        case .steadyHydration:
            return [.calm]
        case .breakfastStandard, .fastedMorning, .proteinMeal, .fiberMeal, .heavyDinner:
            return []
        }
    }
}

private struct AtlasNutritionInsightSection: View {
    let snapshot: AtlasNutritionSnapshot

    var body: some View {
        Section("Nutrition") {
            AtlasSectionCard {
                if snapshot.dailyTargets.isEmpty && snapshot.favoriteMealCount == 0 && snapshot.recentMealCount == 0 {
                    Text("No nutrition quick-capture data yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    Text("Lightweight nutrition tracking built from meal context, repeated favorites, and fast daily targets.")
                        .foregroundStyle(AtlasPalette.textSecondary)

                    if let latestMealLabel = snapshot.latestMealLabel {
                        Text(latestMealLabel)
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    let quickFacts = [
                        snapshot.favoriteMealCount > 0 ? "\(snapshot.favoriteMealCount) favorite\(snapshot.favoriteMealCount == 1 ? "" : "s")" : nil,
                        snapshot.recentMealCount > 0 ? "\(snapshot.recentMealCount) meal log\(snapshot.recentMealCount == 1 ? "" : "s") in the last 7 days" : nil
                    ].compactMap { $0 }

                    if quickFacts.isEmpty == false {
                        Text(quickFacts.joined(separator: " • "))
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    if snapshot.weeklySignals.isEmpty == false {
                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            Text("Weekly rhythm")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AtlasPalette.primary)
                                .textCase(.uppercase)

                            ForEach(snapshot.weeklySignals) { signal in
                                AtlasNutritionWeeklySignalRow(signal: signal)
                            }
                        }
                    }

                    VStack(spacing: AtlasSpacing.small) {
                        ForEach(snapshot.dailyTargets) { target in
                            AtlasNutritionTargetRow(target: target)
                        }
                    }

                    if snapshot.coachingCards.isEmpty == false {
                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            Text("Coaching")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AtlasPalette.primary)
                                .textCase(.uppercase)

                            ForEach(snapshot.coachingCards) { card in
                                AtlasNutritionCoachingCardView(card: card)
                            }
                        }
                    }

                    Text(snapshot.note)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
        }
    }
}

private struct AtlasNutritionWeeklySignalRow: View {
    let signal: AtlasNutritionWeeklySignalSnapshot

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.small) {
            Image(systemName: signal.symbolName)
                .foregroundStyle(signal.isOnTrack ? AtlasPalette.success : AtlasPalette.primary)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AtlasSpacing.xSmall) {
                    Text(signal.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    AtlasStatusBadge(
                        signal.valueLabel,
                        tint: signal.isOnTrack ? AtlasPalette.success : AtlasPalette.primary
                    )
                }
                Text(signal.helperText)
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct AtlasNutritionTargetRow: View {
    let target: AtlasNutritionTargetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            HStack(alignment: .firstTextBaseline, spacing: AtlasSpacing.small) {
                Image(systemName: target.symbolName)
                    .foregroundStyle(target.isMet ? AtlasPalette.success : AtlasPalette.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(target.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(target.progressLabel)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer()
                AtlasStatusBadge(
                    target.isMet ? "Met" : "\(Int(target.progress * 100))%",
                    tint: target.isMet ? AtlasPalette.success : AtlasPalette.primary
                )
            }

            ProgressView(value: target.progress)
                .tint(target.isMet ? AtlasPalette.success : AtlasPalette.primary)

            Text(target.helperText)
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
    }
}

private struct AtlasNutritionCoachingCardView: View {
    let card: AtlasNutritionCoachingCard

    var body: some View {
        AtlasSectionCard(style: .elevated) {
            HStack(alignment: .top, spacing: AtlasSpacing.small) {
                Image(systemName: card.symbolName)
                    .foregroundStyle(AtlasPalette.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(card.summary)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Text(card.helperText)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
        }
    }
}

private struct AtlasNutritionSuggestionButton: View {
    let suggestion: AtlasNutritionQuickCaptureSuggestion
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(alignment: .top, spacing: AtlasSpacing.small) {
                Image(systemName: suggestion.symbolName)
                    .foregroundStyle(AtlasPalette.primary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(suggestion.subtitle)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Text(suggestion.helperText)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Text(buttonTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.primary)
                }
                Spacer()
            }
            .padding(AtlasSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AtlasPalette.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct AtlasContextQuickPreset: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let tint: Color
    let presetKey: String
    let mealTiming: AtlasContextMealTiming?
    let mealSize: AtlasContextMealSize?
    let mealComposition: AtlasContextMealComposition?
    let fedState: AtlasContextFedState?
    let appetite: AtlasContextAppetiteState?
    let hydration: AtlasContextHydrationState?
    let giTags: [AtlasContextGITag]

    init(_ preset: AtlasContextBuiltinPreset) {
        self.init(
            id: preset.id,
            title: preset.title,
            subtitle: preset.subtitle,
            tint: atlasContextPresetTint(
                fedState: preset.fedState,
                hydration: preset.hydration,
                giTags: preset.giTags
            ),
            presetKey: preset.id,
            mealTiming: preset.mealTiming,
            mealSize: preset.mealSize,
            mealComposition: preset.mealComposition,
            fedState: preset.fedState,
            appetite: preset.appetite,
            hydration: preset.hydration,
            giTags: preset.giTags
        )
    }

    init(preset: AtlasContextPresetSummary) {
        self.init(
            id: preset.id,
            title: preset.title,
            subtitle: atlasContextPresetSubtitle(
                mealTiming: preset.mealTiming,
                mealSize: preset.mealSize,
                mealComposition: preset.mealComposition,
                fedState: preset.fedState,
                appetite: preset.appetite,
                hydration: preset.hydration,
                giTags: preset.giTags
            ),
            tint: atlasContextPresetTint(
                fedState: preset.fedState,
                hydration: preset.hydration,
                giTags: preset.giTags
            ),
            presetKey: preset.id,
            mealTiming: preset.mealTiming,
            mealSize: preset.mealSize,
            mealComposition: preset.mealComposition,
            fedState: preset.fedState,
            appetite: preset.appetite,
            hydration: preset.hydration,
            giTags: preset.giTags
        )
    }

    private init(
        id: String,
        title: String,
        subtitle: String?,
        tint: Color,
        presetKey: String,
        mealTiming: AtlasContextMealTiming?,
        mealSize: AtlasContextMealSize?,
        mealComposition: AtlasContextMealComposition?,
        fedState: AtlasContextFedState?,
        appetite: AtlasContextAppetiteState?,
        hydration: AtlasContextHydrationState?,
        giTags: [AtlasContextGITag]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self.presetKey = presetKey
        self.mealTiming = mealTiming
        self.mealSize = mealSize
        self.mealComposition = mealComposition
        self.fedState = fedState
        self.appetite = appetite
        self.hydration = hydration
        self.giTags = giTags
    }

    func makeDraft(loggedAt: Date) -> AtlasContextEntryDraft {
        AtlasContextEntryDraft(
            loggedAt: loggedAt,
            mealTiming: mealTiming,
            mealSize: mealSize,
            mealComposition: mealComposition,
            fedState: fedState,
            appetite: appetite,
            hydration: hydration,
            giTags: giTags,
            presetKey: presetKey
        )
    }
}

struct AtlasRecentMealQuickItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let tint: Color
    private let entry: AtlasContextEntrySummary

    init(entry: AtlasContextEntrySummary) {
        self.entry = entry
        id = entry.id
        title = atlasContextDescriptorTitles(
            mealTiming: entry.mealTiming,
            mealSize: entry.mealSize,
            mealComposition: entry.mealComposition,
            fedState: entry.fedState,
            appetite: entry.appetite,
            hydration: entry.hydration,
            giTags: entry.giTags
        ).first ?? "Recent meal"
        subtitle = atlasContextPresetSubtitle(
            mealTiming: entry.mealTiming,
            mealSize: entry.mealSize,
            mealComposition: entry.mealComposition,
            fedState: entry.fedState,
            appetite: entry.appetite,
            hydration: entry.hydration,
            giTags: entry.giTags
        )
        tint = atlasContextPresetTint(
            fedState: entry.fedState,
            hydration: entry.hydration,
            giTags: entry.giTags
        )
    }

    func draft(loggedAt: Date) -> AtlasContextEntryDraft {
        AtlasContextEntryDraft(
            protocolID: entry.protocolID,
            loggedAt: loggedAt,
            mealTiming: entry.mealTiming,
            mealSize: entry.mealSize,
            mealComposition: entry.mealComposition,
            fedState: entry.fedState,
            appetite: entry.appetite,
            hydration: entry.hydration,
            giTags: entry.giTags,
            tags: entry.tags,
            presetKey: entry.presetKey
        )
    }
}

struct AtlasContextQuickPresetRail: View {
    let title: String?
    let presets: [AtlasContextQuickPreset]
    let selectedPresetKey: String?
    let onSelect: (AtlasContextQuickPreset) -> Void

    init(
        title: String? = nil,
        presets: [AtlasContextQuickPreset],
        selectedPresetKey: String? = nil,
        onSelect: @escaping (AtlasContextQuickPreset) -> Void
    ) {
        self.title = title
        self.presets = presets
        self.selectedPresetKey = selectedPresetKey
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            if let title {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasPalette.primary)
                    .textCase(.uppercase)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AtlasSpacing.small) {
                    ForEach(presets) { preset in
                        Button {
                            onSelect(preset)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.title)
                                    .lineLimit(1)
                                if let subtitle = preset.subtitle {
                                    Text(subtitle)
                                        .font(.caption2)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                        .buttonStyle(
                            AtlasChipButtonStyle(
                                tint: selectedPresetKey == preset.presetKey ? preset.tint : AtlasPalette.secondaryText
                            )
                        )
                    }
                }
            }
        }
    }
}

struct AtlasRecentMealQuickRail: View {
    let items: [AtlasRecentMealQuickItem]
    let onSelect: (AtlasRecentMealQuickItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            Text("Recent meals")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AtlasPalette.primary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AtlasSpacing.small) {
                    ForEach(items) { item in
                        Button {
                            onSelect(item)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .lineLimit(1)
                                if let subtitle = item.subtitle {
                                    Text(subtitle)
                                        .font(.caption2)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                        .buttonStyle(AtlasChipButtonStyle(tint: item.tint))
                    }
                }
            }
        }
    }
}

struct AtlasNutritionLookupRail: View {
    let title: String
    let items: [AtlasNutritionFoodLookupItem]
    let onSelect: (AtlasNutritionFoodLookupItem) -> Void

    var body: some View {
        if items.isEmpty == false {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasPalette.primary)
                    .textCase(.uppercase)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AtlasSpacing.small) {
                        ForEach(items) { item in
                            Button {
                                onSelect(item)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .lineLimit(1)
                                    Text(item.subtitle)
                                        .font(.caption2)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                        .lineLimit(2)
                                }
                            }
                            .buttonStyle(AtlasChipButtonStyle(tint: AtlasPalette.primary))
                        }
                    }
                }
            }
        }
    }
}

private struct AtlasSavedContextPresetRow: View {
    let preset: AtlasContextPresetSummary
    let isSelected: Bool
    let onUse: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.small) {
            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                HStack(spacing: AtlasSpacing.xSmall) {
                    Text(preset.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    if isSelected {
                        AtlasStatusBadge("Selected", tint: AtlasPalette.secondaryText)
                    }
                }

                if let subtitle = atlasContextPresetSubtitle(
                    mealTiming: preset.mealTiming,
                    mealSize: preset.mealSize,
                    mealComposition: preset.mealComposition,
                    fedState: preset.fedState,
                    appetite: preset.appetite,
                    hydration: preset.hydration,
                    giTags: preset.giTags
                ) {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                if let lastUsedAt = preset.lastUsedAt {
                    Text("Used \(lastUsedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(AtlasPalette.textTertiary)
                }
            }

            Spacer(minLength: 12)

            Button("Use", action: onUse)
                .buttonStyle(AtlasChipButtonStyle(tint: AtlasPalette.primary))

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(AtlasPalette.textSecondary)
        }
    }
}

private func atlasContextPresetTint(
    fedState: AtlasContextFedState?,
    hydration: AtlasContextHydrationState?,
    giTags: [AtlasContextGITag]
) -> Color {
    let hasGiSignal = giTags.contains(where: { $0 != .calm })
    if hasGiSignal {
        return AtlasPalette.warning
    }
    if hydration == .high {
        return AtlasPalette.success
    }
    if fedState == .fasted {
        return AtlasPalette.secondaryText
    }
    return AtlasPalette.primary
}

private func atlasContextDescriptorTitles(
    mealTiming: AtlasContextMealTiming?,
    mealSize: AtlasContextMealSize?,
    mealComposition: AtlasContextMealComposition?,
    fedState: AtlasContextFedState?,
    appetite: AtlasContextAppetiteState?,
    hydration: AtlasContextHydrationState?,
    giTags: [AtlasContextGITag]
) -> [String] {
    var parts: [String] = []
    if let mealTiming {
        parts.append(mealTiming.title)
    }
    if let mealSize {
        parts.append(mealSize.title)
    }
    if let mealComposition {
        parts.append(mealComposition.title)
    }
    if let fedState {
        parts.append(fedState.title)
    }
    if let appetite {
        parts.append(appetite.title)
    }
    if let hydration {
        parts.append(hydration.title)
    }
    parts.append(contentsOf: giTags.map(\.title))
    return parts
}

private func atlasContextPresetSubtitle(
    mealTiming: AtlasContextMealTiming?,
    mealSize: AtlasContextMealSize?,
    mealComposition: AtlasContextMealComposition?,
    fedState: AtlasContextFedState?,
    appetite: AtlasContextAppetiteState?,
    hydration: AtlasContextHydrationState?,
    giTags: [AtlasContextGITag]
) -> String? {
    let parts = atlasContextDescriptorTitles(
        mealTiming: mealTiming,
        mealSize: mealSize,
        mealComposition: mealComposition,
        fedState: fedState,
        appetite: appetite,
        hydration: hydration,
        giTags: giTags
    )
    guard parts.isEmpty == false else {
        return nil
    }
    return Array(parts.prefix(3)).joined(separator: " • ")
}

private func atlasSuggestedContextPresetTitle(from state: AtlasContextEditorState) -> String {
    let parts = atlasContextDescriptorTitles(
        mealTiming: state.mealTiming,
        mealSize: state.mealSize,
        mealComposition: state.mealComposition,
        fedState: state.fedState,
        appetite: state.appetite,
        hydration: state.hydration,
        giTags: state.giTags.sorted { $0.rawValue < $1.rawValue }
    )

    guard parts.isEmpty == false else {
        return "Context preset"
    }

    return Array(parts.prefix(2)).joined(separator: " • ")
}

private struct AtlasContextSelectionSection<Option: Hashable & CaseIterable>: View where Option.AllCases: RandomAccessCollection, Option: AtlasContextSelectionOption {
    let title: String
    let options: Option.AllCases
    let selected: Option?
    let noneTitle: String
    let tint: Color
    let onSelect: (Option?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AtlasPalette.primary)
                .textCase(.uppercase)

            AtlasChipFlowLayout(spacing: AtlasSpacing.small) {
                Button(noneTitle) {
                    onSelect(nil)
                }
                .buttonStyle(AtlasChipButtonStyle(tint: selected == nil ? tint : AtlasPalette.textSecondary))

                ForEach(Array(options), id: \.self) { option in
                    Button(option.selectionTitle) {
                        onSelect(option)
                    }
                    .buttonStyle(
                        AtlasChipButtonStyle(
                            tint: selected == option ? tint : AtlasPalette.textSecondary
                        )
                    )
                }
            }
        }
    }
}

private protocol AtlasContextSelectionOption {
    var selectionTitle: String { get }
}

extension AtlasContextMealTiming: AtlasContextSelectionOption {
    var selectionTitle: String { title }
}

extension AtlasContextMealSize: AtlasContextSelectionOption {
    var selectionTitle: String { title }
}

extension AtlasContextMealComposition: AtlasContextSelectionOption {
    var selectionTitle: String { title }
}

extension AtlasContextFedState: AtlasContextSelectionOption {
    var selectionTitle: String { title }
}

extension AtlasContextAppetiteState: AtlasContextSelectionOption {
    var selectionTitle: String { title }
}

extension AtlasContextHydrationState: AtlasContextSelectionOption {
    var selectionTitle: String { title }
}

private struct AtlasChipFlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        AnyLayout(AtlasFlowLayout(spacing: spacing)) {
            content
        }
    }
}

private struct AtlasFlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = proposal.width ?? 320
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }

        return CGSize(width: width, height: currentY + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

private struct AtlasWeightEditorState {
    var id: String?
    var loggedAt: Date
    var value: String
    var unit: AtlasWeightUnit
    var notes: String

    init(entry: AtlasWeightEntrySummary? = nil, referenceDate: Date) {
        id = entry?.id
        loggedAt = entry?.loggedAt ?? referenceDate
        value = entry?.valueLabel.split(separator: " ").first.map(String.init) ?? ""
        unit = entry?.valueLabel.contains("kg") == true ? .kg : .lb
        notes = entry?.notes ?? ""
    }

    var domainDraft: AtlasWeightEntryDraft {
        AtlasWeightEntryDraft(
            id: id,
            loggedAt: loggedAt,
            value: Double(value) ?? 0,
            unit: unit,
            notes: notes.nilIfEmpty
        )
    }
}

private struct AtlasSymptomEditorState {
    var id: String?
    var loggedAt: Date
    var symptomKey: String
    var severity: Int
    var notes: String

    init(entry: AtlasSymptomEntrySummary? = nil, referenceDate: Date) {
        id = entry?.id
        loggedAt = entry?.loggedAt ?? referenceDate
        symptomKey = entry?.symptomKey ?? ""
        severity = entry?.severity ?? 3
        notes = entry?.notes ?? ""
    }

    var domainDraft: AtlasSymptomEntryDraft {
        AtlasSymptomEntryDraft(
            id: id,
            loggedAt: loggedAt,
            symptomKey: symptomKey,
            severity: severity,
            notes: notes.nilIfEmpty
        )
    }
}

private struct AtlasMetricDefinitionEditorState {
    var id: String?
    var protocolID: String?
    var label: String
    var valueType: AtlasCustomMetricValueType
    var unit: String
    var scaleMin: String
    var scaleMax: String

    init(metric: AtlasMetricDefinitionSummary? = nil) {
        id = metric?.id
        protocolID = metric?.protocolID
        label = metric?.label ?? ""
        valueType = metric?.valueType ?? .number
        unit = metric?.unit ?? ""
        scaleMin = metric?.scaleMin.map(String.init) ?? "1"
        scaleMax = metric?.scaleMax.map(String.init) ?? "5"
    }

    var domainDraft: AtlasMetricDefinitionDraft {
        AtlasMetricDefinitionDraft(
            id: id,
            protocolID: protocolID,
            label: label,
            valueType: valueType,
            unit: unit.nilIfEmpty,
            scaleMin: Int(scaleMin),
            scaleMax: Int(scaleMax)
        )
    }
}

private struct AtlasMetricValueEditorState {
    var id: String?
    var metricID: String
    var protocolID: String?
    var loggedAt: Date
    var numberValue: String
    var textValue: String
    var booleanValue: Bool?

    init(metric: AtlasMetricDefinitionSummary? = nil, referenceDate: Date) {
        id = nil
        metricID = metric?.id ?? ""
        protocolID = metric?.protocolID
        loggedAt = referenceDate
        numberValue = ""
        textValue = ""
        booleanValue = false
    }

    init(
        entry: AtlasMetricValueEntrySummary,
        availableMetrics: [AtlasMetricDefinitionSummary],
        referenceDate _: Date
    ) {
        id = entry.id
        metricID = entry.metricID
        protocolID = entry.protocolID
        loggedAt = entry.loggedAt
        let metric = availableMetrics.first(where: { $0.id == entry.metricID })
        switch metric?.valueType {
        case .text:
            numberValue = ""
            textValue = entry.valueLabel
            booleanValue = nil
        case .boolean:
            numberValue = ""
            textValue = ""
            booleanValue = entry.valueLabel == "Yes"
        default:
            numberValue = entry.valueLabel.split(separator: " ").first.map(String.init) ?? ""
            textValue = ""
            booleanValue = nil
        }
    }

    var domainDraft: AtlasMetricValueEntryDraft {
        AtlasMetricValueEntryDraft(
            id: id,
            metricID: metricID,
            protocolID: protocolID,
            loggedAt: loggedAt,
            numberValue: Double(numberValue),
            textValue: textValue.nilIfEmpty,
            booleanValue: booleanValue
        )
    }
}

private extension Optional where Wrapped == String {
    var nilIfEmpty: String? {
        guard let self, self.isEmpty == false else {
            return nil
        }
        return self
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private extension View {
    @ViewBuilder
    func atlasDecimalKeyboard() -> some View {
#if os(iOS)
        keyboardType(.decimalPad)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
#else
        self
#endif
    }

    @ViewBuilder
    func atlasKeyboardDoneToolbar() -> some View {
#if os(iOS)
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    AtlasInsightsKeyboard.dismiss()
                }
            }
        }
#else
        self
#endif
    }
}

private struct AtlasQuickActionGrid<Content: View>: View {
    let columns: Int
    let content: Content

    init(columns: Int, @ViewBuilder content: () -> Content) {
        self.columns = columns
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: AtlasSpacing.small), count: columns),
            spacing: AtlasSpacing.small
        ) {
            content
        }
    }
}

private struct AtlasQuickActionTile: View {
    enum Prominence {
        case primary
        case secondary
    }

    let title: String
    let subtitle: String
    let symbol: String
    let prominence: Prominence
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            prominence == .primary
                                ? .white.opacity(0.16)
                                : AtlasPalette.secondaryFill.opacity(0.85)
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: symbol)
                        .font(.title3.weight(.semibold))
                }
                Text(title)
                    .font(.body.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(prominence == .primary ? .white.opacity(0.9) : AtlasPalette.textSecondary)
            }
            .foregroundStyle(prominence == .primary ? .white : AtlasPalette.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
            .padding(AtlasSpacing.medium)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(prominence == .primary ? Color.white.opacity(0.18) : AtlasPalette.border, lineWidth: 1)
            )
            .shadow(
                color: prominence == .primary
                    ? AtlasPalette.primary.opacity(0.24)
                    : AtlasPalette.shadow.opacity(0.16),
                radius: prominence == .primary ? 18 : 12,
                x: 0,
                y: prominence == .primary ? 12 : 8
            )
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                prominence == .primary
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [AtlasPalette.primaryGlow, AtlasPalette.primary, AtlasPalette.primaryPressed],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    : AnyShapeStyle(
                        LinearGradient(
                            colors: [Color.white.opacity(0.985), AtlasPalette.surfaceSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }
}

private struct AtlasScaleValueControl: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        let step = AtlasScaleValueControl.step(for: range)
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            HStack {
                Text("Scale value")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Spacer()
                Text("\(AtlasScaleValueControl.formattedValue(value)) / \(AtlasScaleValueControl.formattedValue(range.upperBound))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasPalette.primary)
            }

            Slider(value: $value, in: range, step: step)

            HStack(spacing: AtlasSpacing.small) {
                Button("Lower") {
                    value = max(range.lowerBound, value - step)
                }
                .buttonStyle(AtlasSecondaryButtonStyle())

                Button("Raise") {
                    value = min(range.upperBound, value + step)
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
            }
        }
        .padding(.vertical, AtlasSpacing.xSmall)
    }

    static func step(for range: ClosedRange<Double>) -> Double {
        let lowerRounded = abs(range.lowerBound.rounded() - range.lowerBound) < 0.001
        let upperRounded = abs(range.upperBound.rounded() - range.upperBound) < 0.001
        return lowerRounded && upperRounded ? 1 : 0.5
    }

    static func formattedValue(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.001 {
            return String(Int(value.rounded()))
        }
        return String(format: "%.1f", value)
    }
}

private struct AtlasNumericEntryControl: View {
    let title: String
    let unitLabel: String?
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Spacer()
                Text(displayValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasPalette.primary)
            }

            Slider(value: $value, in: range, step: step)

            HStack(spacing: AtlasSpacing.small) {
                Button("Lower") {
                    value = max(range.lowerBound, value - step)
                }
                .buttonStyle(AtlasSecondaryButtonStyle())

                Button("Raise") {
                    value = min(range.upperBound, value + step)
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
            }
        }
        .padding(.vertical, AtlasSpacing.xSmall)
    }

    private var displayValue: String {
        if let unitLabel, unitLabel.isEmpty == false {
            return "\(Self.formattedValue(value)) \(unitLabel)"
        }
        return Self.formattedValue(value)
    }

    static func formattedValue(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.001 {
            return String(Int(value.rounded()))
        }
        return String(format: "%.1f", value)
    }
}

private enum AtlasInsightsKeyboard {
    static func dismiss() {
#if canImport(UIKit)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
#endif
    }
}

private struct AtlasInsightsInlineMessage: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.red)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.red.opacity(0.08))
            )
    }
}

private struct AtlasInsightsEmptyStateCard<Actions: View>: View {
    let title: String
    let message: String
    let actions: Actions

    init(title: String, message: String, @ViewBuilder actions: () -> Actions) {
        self.title = title
        self.message = message
        self.actions = actions()
    }

    var body: some View {
        AtlasSectionCard {
            VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(message)
                    .foregroundStyle(AtlasPalette.textSecondary)
                actions
            }
        }
    }
}
