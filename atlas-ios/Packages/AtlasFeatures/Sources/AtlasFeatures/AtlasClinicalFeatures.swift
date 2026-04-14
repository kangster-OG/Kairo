import AtlasDesignSystem
import AtlasDomain
import SwiftUI

private struct AtlasLabMetricTemplate: Identifiable, Equatable {
    let id: String
    let label: String
    let unit: String
    let groupTitle: String
    let groupSubtitle: String
    let referenceRange: ClosedRange<Double>?
    let referenceRangeLabel: String?
}

private let atlasLabMetricTemplates: [AtlasLabMetricTemplate] = [
    .init(id: "fasting-glucose", label: "Fasting Glucose", unit: "mg/dL", groupTitle: "Metabolic panel", groupSubtitle: "Glucose, insulin response, and baseline tolerance.", referenceRange: 70...99, referenceRangeLabel: "70-99 mg/dL"),
    .init(id: "hba1c", label: "HbA1c", unit: "%", groupTitle: "Metabolic panel", groupSubtitle: "Glucose, insulin response, and baseline tolerance.", referenceRange: 4.0...5.6, referenceRangeLabel: "4.0-5.6%"),
    .init(id: "fasting-insulin", label: "Fasting Insulin", unit: "uIU/mL", groupTitle: "Metabolic panel", groupSubtitle: "Glucose, insulin response, and baseline tolerance.", referenceRange: 2...25, referenceRangeLabel: "2-25 uIU/mL"),
    .init(id: "ldl-c", label: "LDL-C", unit: "mg/dL", groupTitle: "Lipids", groupSubtitle: "Baseline lipids for longer protocol review.", referenceRange: 0...99, referenceRangeLabel: "<100 mg/dL"),
    .init(id: "hdl-c", label: "HDL-C", unit: "mg/dL", groupTitle: "Lipids", groupSubtitle: "Baseline lipids for longer protocol review.", referenceRange: 40...100, referenceRangeLabel: "40+ mg/dL"),
    .init(id: "triglycerides", label: "Triglycerides", unit: "mg/dL", groupTitle: "Lipids", groupSubtitle: "Baseline lipids for longer protocol review.", referenceRange: 0...149, referenceRangeLabel: "<150 mg/dL"),
    .init(id: "ast", label: "AST", unit: "U/L", groupTitle: "Liver", groupSubtitle: "Helpful when routines change appetite, recovery, or adjunct use.", referenceRange: 10...40, referenceRangeLabel: "10-40 U/L"),
    .init(id: "alt", label: "ALT", unit: "U/L", groupTitle: "Liver", groupSubtitle: "Helpful when routines change appetite, recovery, or adjunct use.", referenceRange: 7...56, referenceRangeLabel: "7-56 U/L"),
    .init(id: "total-testosterone", label: "Total Testosterone", unit: "ng/dL", groupTitle: "Hormones", groupSubtitle: "Optional support for advanced peptide or TRT-adjacent tracking.", referenceRange: 300...1000, referenceRangeLabel: "300-1000 ng/dL"),
    .init(id: "free-testosterone", label: "Free Testosterone", unit: "pg/mL", groupTitle: "Hormones", groupSubtitle: "Optional support for advanced peptide or TRT-adjacent tracking.", referenceRange: 35...155, referenceRangeLabel: "35-155 pg/mL")
]

public struct AtlasMedicationLevelsScreen: View {
    let model: AtlasAppModel
    let protocolID: String
    @State private var detail: AtlasProtocolDetailSnapshot?

    public init(model: AtlasAppModel, protocolID: String) {
        self.model = model
        self.protocolID = protocolID
    }

    public var body: some View {
        AtlasScreen {
            if let detail {
                AtlasTabHeader(
                    title: "Medication Level",
                    subtitle: model.renderedTitle(canonical: detail.canonicalTitle, alias: detail.aliasTitle)
                )

                if let item = detail.medicationLevel {
                    AtlasSectionCard(style: .hero) {
                        VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                            ViewThatFits(in: .horizontal) {
                                HStack {
                                    medicationHeroBadges(detail: detail)
                                    Spacer()
                                }

                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    medicationHeroBadges(detail: detail)
                                }
                            }

                            Text("Estimated relative amount in system")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AtlasPalette.primary)
                                .textCase(.uppercase)

                            Text(item.estimateLabel)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(AtlasPalette.textPrimary)

                            if let compareLabel = item.compareLabel {
                                Text(compareLabel)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }

                            Text(atlasMedicationNarrative(for: item))
                                .foregroundStyle(AtlasPalette.textSecondary)

                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: AtlasSpacing.small) {
                                    Button("Adjust plan") {
                                        model.open(.protocolChange(protocolID))
                                    }
                                    .buttonStyle(AtlasPrimaryButtonStyle())

                                    Button("Protocol detail") {
                                        model.open(.protocolDetail(protocolID))
                                    }
                                    .buttonStyle(AtlasSecondaryButtonStyle())
                                }

                                VStack(spacing: AtlasSpacing.small) {
                                    Button("Adjust plan") {
                                        model.open(.protocolChange(protocolID))
                                    }
                                    .buttonStyle(AtlasPrimaryButtonStyle())

                                    Button("Protocol detail") {
                                        model.open(.protocolDetail(protocolID))
                                    }
                                    .buttonStyle(AtlasSecondaryButtonStyle())
                                }
                            }
                        }
                    }

                    AtlasSectionCard(style: .utility, title: "Cycle snapshot") {
                        AtlasClinicalSnapshotGrid(
                            items: atlasMedicationSnapshotItems(detail: detail, item: item)
                        )
                    }

                    AtlasMedicationLevelCard(model: model, item: item)

                    AtlasSectionCard(title: "Cycle read") {
                        atlasFactStack(atlasMedicationFacts(detail: detail, item: item))
                    }

                    let contextLines = atlasMedicationContextLines(model: model, protocolID: protocolID)
                    if contextLines.isEmpty == false {
                        AtlasSectionCard(title: "Nearby anchors") {
                            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                                Text("Nearby logs are shown for timing context only. Atlas is not claiming causation or serum-level precision.")
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)

                                ForEach(contextLines, id: \.self) { line in
                                    Text(line)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                            }
                        }
                    }
                } else {
                    AtlasSectionCard(style: .hero) {
                        Text("This protocol does not have enough supported compound data yet for a relative level curve.")
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                }
            } else {
                AtlasSectionCard(style: .hero) {
                    Text("Loading protocol details...")
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
        }
        .navigationTitle("Medication Level")
        .task(id: protocolID) {
            detail = await model.protocolDetail(id: protocolID)
        }
    }
}

public struct AtlasLabsScreen: View {
    let model: AtlasAppModel
    @State private var metricSheet: AtlasLabMetricSheetMode?
    @State private var entrySheetMetric: AtlasMetricDefinitionSummary?

    public init(model: AtlasAppModel) {
        self.model = model
    }

    public var body: some View {
        let trackedMetrics = atlasTrackedLabMetrics(from: model.insightsSnapshot)
        let recentEntries = atlasRecentLabEntries(from: model.insightsSnapshot)
        let groupedTemplates = Dictionary(grouping: atlasLabMetricTemplates, by: \.groupTitle)
            .sorted { $0.key < $1.key }

        AtlasScreen {
            AtlasTabHeader(
                title: "Labs",
                subtitle: "Optional, clinician-friendly tracking for people who want more than casual peptide logging."
            )

            AtlasSectionCard(style: .hero) {
                VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                    HStack(spacing: AtlasSpacing.small) {
                        AtlasStatusBadge(
                            model.settingsSnapshot.labsEnabled ? "Opted in" : "Optional",
                            tint: model.settingsSnapshot.labsEnabled ? AtlasPalette.success : AtlasPalette.secondaryText
                        )
                        AtlasStatusBadge("Local-first", tint: AtlasPalette.primary)
                    }

                    Text("Labs stay out of the way unless you want them. Atlas can keep them alongside protocols, weekly review, and provider-facing exports without turning the whole app into a clinical dashboard.")
                        .foregroundStyle(AtlasPalette.textSecondary)

                    Toggle(
                        "Enable advanced lab tracking",
                        isOn: Binding(
                            get: { model.settingsSnapshot.labsEnabled },
                            set: { value in
                                Task { await model.updateLabsEnabled(value) }
                            }
                        )
                    )
                    .tint(AtlasPalette.primary)
                }
            }

            if model.settingsSnapshot.labsEnabled {
                AtlasSectionCard(style: .utility, title: "Coverage") {
                    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                        HStack(spacing: AtlasSpacing.small) {
                            AtlasStatusBadge(
                                "\(trackedMetrics.count) marker\(trackedMetrics.count == 1 ? "" : "s")",
                                tint: trackedMetrics.isEmpty ? AtlasPalette.secondaryText : AtlasPalette.primary
                            )
                            AtlasStatusBadge(
                                "\(recentEntries.count) recent entr\(recentEntries.count == 1 ? "y" : "ies")",
                                tint: recentEntries.isEmpty ? AtlasPalette.secondaryText : AtlasPalette.success
                            )
                        }

                        Text(
                            recentEntries.first.map {
                                "Latest lab entry: \($0.loggedAt.formatted(date: .abbreviated, time: .shortened))."
                            } ?? "No lab values logged yet. Start with a panel and Atlas will keep the recent entries here."
                        )
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)

                        Text("Starter markers include lightweight reference ranges so recent values read more like a review-ready report than a raw log list.")
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: AtlasSpacing.small) {
                                Button("Add custom marker") {
                                    metricSheet = .custom
                                }
                                .buttonStyle(AtlasSecondaryButtonStyle())

                                if let firstTrackedMetric = trackedMetrics.first {
                                    Button("Log latest panel") {
                                        entrySheetMetric = firstTrackedMetric
                                    }
                                    .buttonStyle(AtlasTertiaryButtonStyle())
                                }
                            }

                            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                                Button("Add custom marker") {
                                    metricSheet = .custom
                                }
                                .buttonStyle(AtlasSecondaryButtonStyle())

                                if let firstTrackedMetric = trackedMetrics.first {
                                    Button("Log latest panel") {
                                        entrySheetMetric = firstTrackedMetric
                                    }
                                    .buttonStyle(AtlasTertiaryButtonStyle())
                                }
                            }
                        }
                    }
                }

                AtlasSectionCard(title: "Starter panels") {
                    VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                        ForEach(groupedTemplates, id: \.key) { groupTitle, templates in
                            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                                Text(groupTitle)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(AtlasPalette.textPrimary)

                                if let subtitle = templates.first?.groupSubtitle {
                                    Text(subtitle)
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }

                                Text(templates.map(\.label).joined(separator: " • "))
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)

                                let rangeLabels = templates.compactMap(\.referenceRangeLabel)
                                if rangeLabels.isEmpty == false {
                                    Text("Reference ranges: \(rangeLabels.joined(separator: " • "))")
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }

                                Button("Add \(groupTitle)") {
                                    Task { await atlasEnsureLabMetrics(model: model, templates: templates) }
                                }
                                .buttonStyle(AtlasSecondaryButtonStyle())
                            }
                        }

                        Button("Add custom lab marker") {
                            metricSheet = .custom
                        }
                        .buttonStyle(AtlasTertiaryButtonStyle())
                    }
                }

                AtlasSectionCard(title: "Tracked markers") {
                    if trackedMetrics.isEmpty {
                        Text("No lab markers added yet. Start with a panel or add your own single marker.")
                            .foregroundStyle(AtlasPalette.textSecondary)
                    } else {
                        ForEach(Array(trackedMetrics.enumerated()), id: \.element.id) { index, metric in
                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                        Text(metric.label)
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(AtlasPalette.textPrimary)

                                        if let template = atlasLabTemplate(for: metric.label) {
                                            HStack(spacing: AtlasSpacing.xSmall) {
                                                AtlasStatusBadge(
                                                    atlasLabMetricStatus(
                                                        for: metric,
                                                        recentEntries: recentEntries,
                                                        template: template
                                                    ).title,
                                                    tint: atlasLabMetricStatus(
                                                        for: metric,
                                                        recentEntries: recentEntries,
                                                        template: template
                                                    ).tint
                                                )
                                                if let rangeLabel = template.referenceRangeLabel {
                                                    Text(rangeLabel)
                                                        .font(.caption)
                                                        .foregroundStyle(AtlasPalette.textSecondary)
                                                }
                                            }
                                        } else {
                                            Text(metric.unit ?? "Numeric marker")
                                                .font(.caption)
                                                .foregroundStyle(AtlasPalette.textSecondary)
                                        }

                                        if let latest = metric.latestEntryLabel {
                                            Text("Latest: \(latest)")
                                                .font(.caption)
                                                .foregroundStyle(AtlasPalette.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    Button("Log") {
                                        entrySheetMetric = metric
                                    }
                                    .buttonStyle(AtlasSecondaryButtonStyle())
                                }
                            }
                            if index < trackedMetrics.count - 1 {
                                Divider()
                            }
                        }
                    }
                }

                if recentEntries.isEmpty == false {
                    AtlasSectionCard(title: "Recent lab entries") {
                        ForEach(recentEntries) { entry in
                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                let template = atlasLabTemplate(for: entry.label)
                                let status = template.map { atlasLabEntryStatus(for: entry, template: $0) }

                                HStack(alignment: .top, spacing: AtlasSpacing.small) {
                                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                        Text("\(entry.label): \(entry.valueLabel)")
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(AtlasPalette.textPrimary)
                                        if let template,
                                           let rangeLabel = template.referenceRangeLabel {
                                            Text("Reference range: \(rangeLabel)")
                                                .font(.caption)
                                                .foregroundStyle(AtlasPalette.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    if let status {
                                        AtlasStatusBadge(status.title, tint: status.tint)
                                    }
                                }
                                Text(entry.loggedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Labs")
        .sheet(item: $metricSheet) { sheet in
            AtlasLabMetricDefinitionSheet(model: model, mode: sheet)
        }
        .sheet(item: $entrySheetMetric) { metric in
            AtlasLabMetricEntrySheet(model: model, metric: metric)
        }
    }
}

private struct AtlasLabStatusPresentation {
    let title: String
    let tint: Color
}

private func atlasLabTemplate(for label: String) -> AtlasLabMetricTemplate? {
    atlasLabMetricTemplates.first { $0.label.caseInsensitiveCompare(label) == .orderedSame }
}

private func atlasLabMetricStatus(
    for metric: AtlasMetricDefinitionSummary,
    recentEntries: [AtlasMetricValueEntrySummary],
    template: AtlasLabMetricTemplate
) -> AtlasLabStatusPresentation {
    guard let entry = recentEntries.first(where: { $0.metricID == metric.id }) else {
        return AtlasLabStatusPresentation(title: "No entry", tint: AtlasPalette.secondaryText)
    }
    return atlasLabEntryStatus(for: entry, template: template)
}

private func atlasLabEntryStatus(
    for entry: AtlasMetricValueEntrySummary,
    template: AtlasLabMetricTemplate
) -> AtlasLabStatusPresentation {
    guard let range = template.referenceRange,
          let value = atlasFirstNumericValue(in: entry.valueLabel) else {
        return AtlasLabStatusPresentation(title: "Logged", tint: AtlasPalette.primary)
    }

    if range.contains(value) {
        return AtlasLabStatusPresentation(title: "In range", tint: AtlasPalette.success)
    }
    return AtlasLabStatusPresentation(title: value < range.lowerBound ? "Below range" : "Above range", tint: .orange)
}

private func atlasFirstNumericValue(in label: String) -> Double? {
    let allowed = Set("0123456789.-")
    let filtered = label.map { allowed.contains($0) ? $0 : " " }
    return filtered
        .split(separator: " ")
        .compactMap { Double(String($0)) }
        .first
}

private enum AtlasLabMetricSheetMode: Identifiable {
    case custom

    var id: String { "custom" }
}

private struct AtlasLabMetricDefinitionSheet: View {
    let model: AtlasAppModel
    let mode: AtlasLabMetricSheetMode
    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var unit = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Marker label", text: $label)
                TextField("Unit", text: $unit)
            }
            .atlasFormSurface()
            .navigationTitle("New lab marker")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await model.saveMetricDefinition(
                                AtlasMetricDefinitionDraft(
                                    label: atlasLabMetricLabel(from: label),
                                    valueType: .number,
                                    unit: unit.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                                )
                            )
                            dismiss()
                        }
                    }
                    .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct AtlasLabMetricEntrySheet: View {
    let model: AtlasAppModel
    let metric: AtlasMetricDefinitionSummary
    @Environment(\.dismiss) private var dismiss
    @State private var loggedAt = Date()
    @State private var value = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Logged at", selection: $loggedAt)
                TextField(metric.unit.map { "Value (\($0))" } ?? "Value", text: $value)
                    .keyboardType(.decimalPad)
            }
            .atlasFormSurface()
            .navigationTitle(metric.label)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await model.saveMetricValueEntry(
                                AtlasMetricValueEntryDraft(
                                    metricID: metric.id,
                                    loggedAt: loggedAt,
                                    numberValue: Double(value)
                                )
                            )
                            dismiss()
                        }
                    }
                    .disabled(Double(value) == nil)
                }
            }
        }
    }
}

@ViewBuilder
private func medicationHeroBadges(detail: AtlasProtocolDetailSnapshot) -> some View {
    AtlasStatusBadge(detail.kindLabel, tint: AtlasPalette.secondaryText)
    if let administrationLabel = detail.administrationLabel {
        AtlasStatusBadge(administrationLabel, tint: AtlasPalette.primary)
    }
    if let supplyLabel = detail.supplyLabel {
        AtlasStatusBadge(supplyLabel, tint: AtlasPalette.secondaryText)
    }
}

@MainActor
private func atlasEnsureLabMetrics(model: AtlasAppModel, templates: [AtlasLabMetricTemplate]) async {
    let existingLabels = Set(
        atlasTrackedLabMetrics(from: model.insightsSnapshot).map { $0.label.lowercased() }
    )

    for template in templates where existingLabels.contains(template.label.lowercased()) == false {
        await model.saveMetricDefinition(
            AtlasMetricDefinitionDraft(
                label: atlasLabMetricLabel(from: template.label),
                valueType: .number,
                unit: template.unit
            )
        )
    }
}

private func atlasTrackedLabMetrics(from snapshot: AtlasInsightsSnapshot) -> [AtlasMetricDefinitionSummary] {
    let catalogLabels = Set(atlasLabMetricTemplates.map { $0.label.lowercased() })
    return snapshot.customMetricDefinitions.filter { metric in
        let normalized = metric.label.lowercased()
        return normalized.hasPrefix("lab:") || catalogLabels.contains(normalized)
    }
    .sorted { lhs, rhs in
        switch (lhs.latestEntryAt, rhs.latestEntryAt) {
        case let (left?, right?):
            return left > right
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return lhs.label < rhs.label
        }
    }
}

private func atlasRecentLabEntries(from snapshot: AtlasInsightsSnapshot) -> [AtlasMetricValueEntrySummary] {
    let metricIDs = Set(atlasTrackedLabMetrics(from: snapshot).map(\.id))
    return snapshot.recentMetricEntries
        .filter { metricIDs.contains($0.metricID) }
        .sorted { $0.loggedAt > $1.loggedAt }
}

private func atlasLabMetricLabel(from label: String) -> String {
    label.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func atlasMedicationNarrative(for item: AtlasAmountEstimateItem) -> String {
    if let compareLabel = item.compareLabel {
        return "\(compareLabel). \(item.notesLabel)"
    }
    return item.notesLabel
}

private func atlasMedicationSnapshotItems(
    detail: AtlasProtocolDetailSnapshot,
    item: AtlasAmountEstimateItem
) -> [AtlasClinicalSnapshotItem] {
    var items: [AtlasClinicalSnapshotItem] = [
        .init(title: "Current estimate", value: item.estimateLabel),
        .init(title: "Cadence", value: detail.cadenceLabel)
    ]

    if let doseLabel = detail.doseLabel {
        items.append(.init(title: "Planned dose", value: doseLabel))
    }

    if let nextDue = detail.nextOccurrence {
        items.append(
            .init(
                title: "Next due",
                value: nextDue.scheduledAt.formatted(date: .abbreviated, time: .shortened)
            )
        )
    }

    if let halfLifeLabel = item.halfLifeLabel {
        items.append(.init(title: "Model", value: halfLifeLabel))
    }

    return Array(items.prefix(4))
}

private func atlasMedicationFacts(
    detail: AtlasProtocolDetailSnapshot,
    item: AtlasAmountEstimateItem
) -> [AtlasExplainerFact] {
    var facts = item.sourceFacts
    if let supplyLabel = detail.supplyLabel {
        facts.append(.init(label: "Supply", value: supplyLabel))
    }
    if let nextDue = detail.nextOccurrence {
        facts.append(.init(label: "Next due", value: nextDue.scheduledAt.formatted(date: .abbreviated, time: .shortened)))
    }
    if let halfLifeLabel = item.halfLifeLabel {
        facts.append(.init(label: "Model", value: halfLifeLabel))
    }
    if let peakWindowLabel = item.peakWindowLabel {
        facts.append(.init(label: "Peak window", value: peakWindowLabel))
    }
    return facts
}

@MainActor
private func atlasMedicationContextLines(
    model: AtlasAppModel,
    protocolID: String
) -> [String] {
    var lines: [String] = []

    for symptom in model.insightsSnapshot.recentSymptomEntries.prefix(2) {
        lines.append("Symptom: \(symptom.symptomKey.capitalized) \(symptom.severity)/5 on \(symptom.loggedAt.formatted(date: .abbreviated, time: .shortened))")
    }

    for workout in model.insightsSnapshot.recentWorkoutEntries.prefix(2) {
        lines.append("Workout: \(workout.activityKind.rawValue.capitalized) for \(workout.durationLabel) on \(workout.startedAt.formatted(date: .abbreviated, time: .shortened))")
    }

    for entry in model.insightsSnapshot.recentContextEntries.filter({ $0.protocolID == nil || $0.protocolID == protocolID }).prefix(2) {
        let appetite = entry.appetite?.rawValue.capitalized ?? "No appetite note"
        let hydration = entry.hydration?.rawValue.capitalized ?? "No hydration note"
        lines.append("Context: \(appetite) appetite, \(hydration) hydration on \(entry.loggedAt.formatted(date: .abbreviated, time: .shortened))")
    }

    return Array(lines.prefix(4))
}

private func atlasFactStack(_ facts: [AtlasExplainerFact]) -> some View {
    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
        ForEach(facts) { fact in
            VStack(alignment: .leading, spacing: 2) {
                Text(fact.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasPalette.primary)
                Text(fact.value)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
        }
    }
}

private struct AtlasClinicalSnapshotItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

private struct AtlasClinicalSnapshotGrid: View {
    let items: [AtlasClinicalSnapshotItem]

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 120), spacing: AtlasSpacing.small),
                GridItem(.flexible(minimum: 120), spacing: AtlasSpacing.small)
            ],
            spacing: AtlasSpacing.small
        ) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.primary)
                        .textCase(.uppercase)
                    Text(item.value)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
