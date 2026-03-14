import AtlasDesignSystem
import AtlasDomain
import Charts
import Foundation
import SwiftUI

public struct AtlasInsightsScreen: View {
    let model: AtlasAppModel

    @State private var weightEditor = AtlasWeightEditorState()
    @State private var symptomEditor = AtlasSymptomEditorState()
    @State private var metricDefinitionEditor = AtlasMetricDefinitionEditorState()
    @State private var metricValueEditor = AtlasMetricValueEditorState()
    @State private var weightSheetPresented = false
    @State private var symptomSheetPresented = false
    @State private var metricDefinitionSheetPresented = false
    @State private var metricValueSheetPresented = false

    public var body: some View {
        List {
            if let error = model.loadErrorMessage {
                AtlasInsightsInlineMessage(text: error)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            AtlasSectionCard(title: "Metrics") {
                Text("Track weight, symptoms, and custom signals without leaving the native shell.")
                    .foregroundStyle(AtlasPalette.textSecondary)

                HStack {
                    Button("Log weight") {
                        weightEditor = AtlasWeightEditorState()
                        weightSheetPresented = true
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())

                    Button("Log symptom") {
                        symptomEditor = AtlasSymptomEditorState()
                        symptomSheetPresented = true
                    }
                    .buttonStyle(.bordered)
                }

                HStack {
                    Button("Manage metrics") {
                        metricDefinitionEditor = AtlasMetricDefinitionEditorState()
                        metricDefinitionSheetPresented = true
                    }
                    .buttonStyle(.bordered)

                    Button("Log custom metric") {
                        metricValueEditor = AtlasMetricValueEditorState()
                        metricValueSheetPresented = true
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.insightsSnapshot.customMetricDefinitions.filter { $0.archivedAt == nil }.isEmpty)
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            if model.insightsSnapshot.hasAnyInsightData == false {
                AtlasInsightsEmptyStateCard(
                    title: "No insight data yet",
                    message: "Weight, symptom, custom metric, and episode views will start building restrained patterns here."
                ) { EmptyView() }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } else {
                AtlasWeightInsightSection(
                    snapshot: model.insightsSnapshot,
                    onEdit: { entry in
                        weightEditor = AtlasWeightEditorState(entry: entry)
                        weightSheetPresented = true
                    }
                )

                AtlasSymptomInsightSection(
                    snapshot: model.insightsSnapshot,
                    onEdit: { entry in
                        symptomEditor = AtlasSymptomEditorState(entry: entry)
                        symptomSheetPresented = true
                    }
                )

                AtlasCustomMetricInsightSection(
                    model: model,
                    snapshot: model.insightsSnapshot,
                    onEditMetric: { metric in
                        metricDefinitionEditor = AtlasMetricDefinitionEditorState(metric: metric)
                        metricDefinitionSheetPresented = true
                    },
                    onLogMetric: { metric in
                        metricValueEditor = AtlasMetricValueEditorState(metric: metric)
                        metricValueSheetPresented = true
                    },
                    onEditMetricEntry: { entry in
                        metricValueEditor = AtlasMetricValueEditorState(entry: entry, availableMetrics: model.insightsSnapshot.customMetricDefinitions)
                        metricValueSheetPresented = true
                    }
                )

                AtlasInventoryBurnDownSection(snapshot: model.insightsSnapshot)
                AtlasAdherenceInsightSection(snapshot: model.insightsSnapshot)
                AtlasAmountEstimateSection(model: model, snapshot: model.insightsSnapshot)
                AtlasEpisodeIntelligenceSection(model: model, snapshot: model.insightsSnapshot)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AtlasPalette.canvas)
        .navigationTitle("Insights")
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
                                    Text(model.renderedMetricLabel(canonical: metric.label))
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                    if let protocolTitle = metric.canonicalProtocolTitle {
                                        Text(model.renderedTitle(canonical: protocolTitle, alias: metric.aliasProtocolTitle))
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
                                    Text("\(model.renderedMetricLabel(canonical: entry.label)): \(entry.valueLabel)")
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                    if let protocolTitle = entry.canonicalProtocolTitle {
                                        Text(model.renderedTitle(canonical: protocolTitle, alias: entry.aliasProtocolTitle))
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
        Section("Inventory burn-down") {
            AtlasSectionCard {
                if snapshot.inventoryBurnDown.isEmpty {
                    Text("No vial data yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    Chart(snapshot.inventoryBurnDown.prefix(5)) { item in
                        BarMark(
                            x: .value("Vial", item.label),
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
                            Text(model.renderedTitle(canonical: item.canonicalProtocolTitle, alias: item.aliasProtocolTitle))
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

    var body: some View {
        Section("Episode patterns") {
            AtlasSectionCard {
                Text(snapshot.episodeIntelligence.disclaimer)
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)

                if snapshot.episodeIntelligence.hasAnyEpisodeData == false {
                    Text("Completed dose logs plus surrounding symptom, weight, or metric entries are needed before Atlas can describe episode timing.")
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
                                    Text(model.renderedTitle(canonical: canonicalTitle, alias: card.aliasProtocolTitle))
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
                                Text(model.renderedTitle(canonical: episode.canonicalProtocolTitle, alias: episode.aliasProtocolTitle))
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
                                Text("\(episode.symptomEntryCount) symptom entr\(episode.symptomEntryCount == 1 ? "y" : "ies") • \(episode.weightEntryCount) weight entr\(episode.weightEntryCount == 1 ? "y" : "ies") • \(episode.metricEntryCount) metric entr\(episode.metricEntryCount == 1 ? "y" : "ies")")
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
                DatePicker("Logged at", selection: $state.loggedAt)
                TextField("Value", text: $state.value)
                    .atlasDecimalKeyboard()
                Picker("Unit", selection: $state.unit) {
                    Text("lb").tag(AtlasWeightUnit.lb)
                    Text("kg").tag(AtlasWeightUnit.kg)
                }
                TextField("Notes", text: $state.notes, axis: .vertical)
            }
            .navigationTitle(state.id == nil ? "Log weight" : "Edit weight")
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
            .navigationTitle(state.id == nil ? "Log symptom" : "Edit symptom")
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
            .navigationTitle(state.id == nil ? "New metric" : "Edit metric")
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
                        TextField(selectedMetric.unit.map { "Value (\($0))" } ?? "Value", text: $state.numberValue)
                            .atlasDecimalKeyboard()
                    } else if selectedMetric.valueType == .scale {
                        let min = selectedMetric.scaleMin ?? 0
                        let max = selectedMetric.scaleMax ?? 5
                        TextField("Scale value (\(min)-\(max))", text: $state.numberValue)
                            .atlasDecimalKeyboard()
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
            .navigationTitle(state.id == nil ? "Log metric" : "Edit metric entry")
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

private struct AtlasWeightEditorState {
    var id: String?
    var loggedAt: Date
    var value: String
    var unit: AtlasWeightUnit
    var notes: String

    init(entry: AtlasWeightEntrySummary? = nil) {
        id = entry?.id
        loggedAt = entry?.loggedAt ?? Date()
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

    init(entry: AtlasSymptomEntrySummary? = nil) {
        id = entry?.id
        loggedAt = entry?.loggedAt ?? Date()
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

    init(metric: AtlasMetricDefinitionSummary? = nil) {
        id = nil
        metricID = metric?.id ?? ""
        protocolID = metric?.protocolID
        loggedAt = Date()
        numberValue = ""
        textValue = ""
        booleanValue = false
    }

    init(entry: AtlasMetricValueEntrySummary, availableMetrics: [AtlasMetricDefinitionSummary]) {
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
#else
        self
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
