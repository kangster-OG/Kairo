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
                        subtitle: "Meal timing, hydration, GI, and surrounding context",
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
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            AtlasRetentionInsightSection(
                model: model,
                snapshot: state.retentionSnapshot
            )

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

                    ForEach(snapshot.recentContextEntries) { entry in
                        Button {
                            onEdit(entry)
                        } label: {
                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                HStack(alignment: .top) {
                                    Text(model.renderedContextTitle(entry, renderMode: renderMode))
                                        .foregroundStyle(AtlasPalette.textPrimary)
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

private struct AtlasContextEntrySheet: View {
    let model: AtlasAppModel
    @Environment(\.dismiss) private var dismiss
    @State private var state: AtlasContextEditorState

    init(model: AtlasAppModel, state: AtlasContextEditorState) {
        self.model = model
        _state = State(initialValue: state)
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Logged at", selection: $state.loggedAt)

                Picker("Meal timing", selection: $state.mealTiming) {
                    Text("Not set").tag(AtlasContextMealTiming?.none)
                    ForEach(AtlasContextMealTiming.allCases, id: \.self) { timing in
                        Text(timing.title).tag(AtlasContextMealTiming?.some(timing))
                    }
                }

                Picker("Fed / fasted", selection: $state.fedState) {
                    Text("Not set").tag(AtlasContextFedState?.none)
                    ForEach(AtlasContextFedState.allCases, id: \.self) { state in
                        Text(state.title).tag(AtlasContextFedState?.some(state))
                    }
                }

                DisclosureGroup("More detail") {
                    Picker("Related protocol", selection: $state.protocolID) {
                        Text("None").tag(String?.none)
                        ForEach(model.libraryProtocols) { protocolSummary in
                            Text(model.renderedTitle(canonical: protocolSummary.canonicalTitle, alias: protocolSummary.aliasTitle))
                                .tag(String?.some(protocolSummary.id))
                        }
                    }

                    Picker("Appetite", selection: $state.appetite) {
                        Text("Not set").tag(AtlasContextAppetiteState?.none)
                        ForEach(AtlasContextAppetiteState.allCases, id: \.self) { appetite in
                            Text(appetite.title).tag(AtlasContextAppetiteState?.some(appetite))
                        }
                    }

                    Picker("Hydration", selection: $state.hydration) {
                        Text("Not set").tag(AtlasContextHydrationState?.none)
                        ForEach(AtlasContextHydrationState.allCases, id: \.self) { hydration in
                            Text(hydration.title).tag(AtlasContextHydrationState?.some(hydration))
                        }
                    }

                    Section("GI context") {
                        ForEach(AtlasContextGITag.allCases, id: \.self) { tag in
                            Toggle(
                                tag.title,
                                isOn: Binding(
                                    get: { state.giTags.contains(tag) },
                                    set: { isOn in
                                        state.setGITag(tag, enabled: isOn)
                                    }
                                )
                            )
                        }
                    }

                    TextField("Tags (comma separated)", text: $state.tags)
                        .autocorrectionDisabled()
                    TextField("Optional note", text: $state.note, axis: .vertical)
                }
            }
            .atlasFormSurface()
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

private struct AtlasContextEditorState {
    var id: String?
    var protocolID: String?
    var loggedAt: Date
    var mealTiming: AtlasContextMealTiming?
    var fedState: AtlasContextFedState?
    var appetite: AtlasContextAppetiteState?
    var hydration: AtlasContextHydrationState?
    var giTags: Set<AtlasContextGITag>
    var note: String
    var tags: String

    init(entry: AtlasContextEntrySummary? = nil, referenceDate: Date) {
        id = entry?.id
        protocolID = entry?.protocolID
        loggedAt = entry?.loggedAt ?? referenceDate
        mealTiming = entry?.mealTiming
        fedState = entry?.fedState
        appetite = entry?.appetite
        hydration = entry?.hydration
        giTags = Set(entry?.giTags ?? [])
        note = entry?.note ?? ""
        tags = (entry?.tags ?? []).joined(separator: ", ")
    }

    mutating func setGITag(_ tag: AtlasContextGITag, enabled: Bool) {
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

    var domainDraft: AtlasContextEntryDraft {
        AtlasContextEntryDraft(
            id: id,
            protocolID: protocolID,
            loggedAt: loggedAt,
            mealTiming: mealTiming,
            fedState: fedState,
            appetite: appetite,
            hydration: hydration,
            giTags: giTags.sorted { $0.rawValue < $1.rawValue },
            note: note.nilIfEmpty,
            tags: tags
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.isEmpty == false }
        )
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
