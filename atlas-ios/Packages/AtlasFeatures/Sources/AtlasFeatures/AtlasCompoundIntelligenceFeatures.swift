import AtlasDesignSystem
import AtlasDomain
import Foundation
import SwiftUI

public struct AtlasCompoundIntelligenceScreen: View {
    let model: AtlasAppModel
    let knowledgeSlug: String

    private var knowledge: AtlasCompoundKnowledge? {
        AtlasCompoundKnowledgeCatalog.knowledge(slug: knowledgeSlug)
    }

    private var activeProtocols: [ProtocolSummary] {
        model.libraryProtocols.filter { summary in
            summary.compoundKnowledge?.slug == knowledgeSlug
        }
    }

    private var compareCandidates: [AtlasCompoundKnowledge] {
        AtlasCompoundKnowledgeCatalog.compareCandidates(
            for: knowledge,
            kind: knowledge?.kind
        )
        .filter { $0.slug != knowledgeSlug }
    }

    public var body: some View {
        List {
            if let knowledge {
                Section {
                    AtlasSectionCard(style: .elevated) {
                        VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                                    Text(knowledge.displayName)
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(AtlasPalette.textPrimary)

                                    Text(knowledge.protocolSummary)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                                Spacer()
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AtlasSpacing.xSmall) {
                                    AtlasCompoundIntelligenceChip(label: knowledge.categoryLabel)
                                    AtlasCompoundIntelligenceChip(label: knowledge.routeLabel)
                                    AtlasCompoundIntelligenceChip(label: knowledge.typicalCadenceLabel)
                                }
                            }

                            Text("Atlas uses compound intelligence to explain what a protocol is generally for, how the saved schedule behaves, and what operational tradeoffs usually matter.")
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section {
                    AtlasSectionCard(title: "General role") {
                        ForEach(atlasCompoundUseCases(for: knowledge), id: \.self) { line in
                            AtlasCompoundBulletLine(text: line)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section {
                    AtlasSectionCard(title: "How Atlas reads it") {
                        ForEach(atlasCompoundModelFacts(for: knowledge), id: \.label) { fact in
                            AtlasCompoundFactRow(label: fact.label, value: fact.value)
                        }

                        if knowledge.operationalTags.isEmpty == false {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AtlasSpacing.xSmall) {
                                    ForEach(knowledge.operationalTags, id: \.self) { tag in
                                        AtlasCompoundIntelligenceChip(label: tag.title)
                                    }
                                }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                if knowledge.operationalCautions.isEmpty == false {
                    Section {
                        AtlasSectionCard(title: "Operational watchouts") {
                            ForEach(knowledge.operationalCautions, id: \.self) { caution in
                                AtlasCompoundBulletLine(text: caution)
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }

                if activeProtocols.isEmpty == false {
                    Section {
                        AtlasSectionCard(title: "Your protocols") {
                            ForEach(activeProtocols) { summary in
                                AtlasCompoundProtocolRow(model: model, summary: summary)
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }

                if compareCandidates.isEmpty == false {
                    Section {
                        AtlasSectionCard(title: "Compare nearby") {
                            ForEach(compareCandidates.prefix(4)) { candidate in
                                AtlasCompoundCandidateRow(model: model, knowledge: candidate)
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }

                Section {
                    AtlasSectionCard(style: .utility, title: "Trust note") {
                        Text("Atlas keeps this descriptive. Compound intelligence can explain general usage patterns, timing, and tracking burden from Atlas records, but it does not tell you what to take or replace provider guidance.")
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    AtlasSectionCard(style: .utility, title: "Compound not found") {
                        Text("Atlas does not have a strong catalog match for this compound yet. Protocol detail and Change Studio will still stay source-backed, but the dedicated intelligence view is only available for catalog matches.")
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AtlasPalette.canvas)
        .navigationTitle("Compound intelligence")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AtlasCompoundFact: Identifiable {
    let label: String
    let value: String

    var id: String { label }
}

private struct AtlasCompoundFactRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AtlasPalette.primary)
            Text(value)
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
    }
}

private struct AtlasCompoundBulletLine: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.small) {
            Circle()
                .fill(AtlasPalette.primary)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
    }
}

private struct AtlasCompoundProtocolRow: View {
    let model: AtlasAppModel
    let summary: ProtocolSummary

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            Text(model.renderedTitle(canonical: summary.canonicalTitle, alias: summary.aliasTitle))
                .font(.body.weight(.semibold))
                .foregroundStyle(AtlasPalette.textPrimary)

            Text("\(summary.kindLabel) • \(summary.cadenceLabel)")
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)

            if let doseLabel = summary.doseLabel {
                Text("Dose \(doseLabel)")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            HStack(spacing: AtlasSpacing.small) {
                Button("Open protocol") {
                    model.open(.protocolDetail(summary.id))
                }
                .buttonStyle(AtlasSecondaryButtonStyle())

                Button("Change plan") {
                    model.open(.protocolChange(summary.id))
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
            }
        }
        .padding(.vertical, AtlasSpacing.xSmall)
    }
}

private struct AtlasCompoundCandidateRow: View {
    let model: AtlasAppModel
    let knowledge: AtlasCompoundKnowledge

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            Text(knowledge.displayName)
                .font(.body.weight(.semibold))
                .foregroundStyle(AtlasPalette.textPrimary)

            Text(knowledge.protocolSummary)
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)

            HStack(spacing: AtlasSpacing.small) {
                AtlasCompoundIntelligenceChip(label: knowledge.categoryLabel)
                AtlasCompoundIntelligenceChip(label: knowledge.typicalCadenceLabel)
            }

            Button("Open \(knowledge.displayName)") {
                model.open(.compoundIntelligence(knowledge.slug))
            }
            .buttonStyle(AtlasSecondaryButtonStyle())
        }
        .padding(.vertical, AtlasSpacing.xSmall)
    }
}

private struct AtlasCompoundIntelligenceChip: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AtlasPalette.primary)
            .padding(.horizontal, AtlasSpacing.small)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(AtlasPalette.secondaryFill)
            )
    }
}

private func atlasCompoundUseCases(for knowledge: AtlasCompoundKnowledge) -> [String] {
    var useCases: [String] = []

    for tag in knowledge.operationalTags {
        switch tag {
        case .appetiteControl:
            useCases.append("Often tracked in routines where appetite control, meal timing, or metabolic consistency matter.")
        case .bloodSugarShift:
            useCases.append("Usually treated as a metabolic protocol where glucose-aware context and scale changes are worth watching.")
        case .recoverySupport:
            useCases.append("Commonly used in recovery-oriented or tissue-support stacks where consistency matters more than flashy scheduling.")
        case .ghAxis:
            useCases.append("Usually run in GH-axis or recovery routines where bedtime timing and stack clarity matter.")
        case .sleepSensitive:
            useCases.append("Timing often matters because users anchor it to sleep, recovery, or a narrow daily window.")
        case .androgenicLoad:
            useCases.append("Often part of TRT or androgen-focused plans where cadence, labs, and inventory continuity matter.")
        case .estrogenicSpillover:
            useCases.append("Usually logged alongside hormone support because estrogen-side context can change how the plan feels operationally.")
        case .sexualFunction:
            useCases.append("Sometimes used in routines where sexual-function changes are one of the tracked context signals.")
        case .skinHair:
            useCases.append("Often associated with skin, hair, or cosmetic-support routines that still benefit from structured tracking.")
        case .siteSensitive:
            useCases.append("Site planning can matter here, so Atlas treats placement and injection burden as part of the protocol shape.")
        case .dailyCadence, .weeklyCadence, .giLoad, .waterRetention:
            continue
        }
    }

    if knowledge.operationalTags.contains(.giLoad) {
        useCases.append("Users often watch GI tolerance or appetite shifts before they make any bigger interpretation about the plan.")
    }

    if knowledge.operationalTags.contains(.waterRetention) {
        useCases.append("Body-composition context can feel noisy here, so Atlas treats water or scale movement as descriptive rather than definitive.")
    }

    if useCases.isEmpty {
        useCases.append("Atlas treats this as a structured protocol where route, cadence, and tracking burden matter more than the name alone.")
    }

    return Array(useCases.prefix(3))
}

private func atlasCompoundModelFacts(for knowledge: AtlasCompoundKnowledge) -> [AtlasCompoundFact] {
    var facts: [AtlasCompoundFact] = [
        .init(label: "Category", value: knowledge.categoryLabel),
        .init(label: "Route", value: knowledge.routeLabel),
        .init(label: "Typical cadence", value: knowledge.typicalCadenceLabel),
        .init(label: "Availability", value: knowledge.availabilityLabel),
        .init(label: "Common dose units", value: knowledge.commonDoseUnits.joined(separator: ", "))
    ]

    if let kineticsProfile = knowledge.kineticsProfile {
        facts.append(
            .init(
                label: "Level modeling",
                value: "Atlas can shape a deterministic relative level curve here using a \(atlasCompoundHalfLifeLabel(hours: kineticsProfile.halfLifeHours)) half-life profile from saved schedules and logged doses."
            )
        )
        facts.append(
            .init(
                label: "Model note",
                value: kineticsProfile.notes
            )
        )
    } else {
        facts.append(
            .init(
                label: "Level modeling",
                value: "Atlas does not show a half-life visualization for this compound yet, so it stays descriptive about cadence and burden instead of implying a modeled curve."
            )
        )
    }

    return facts
}

func atlasCompoundHalfLifeLabel(hours: Double) -> String {
    if hours >= 48 {
        let days = hours / 24
        return String(format: "%.1f day", days) + (days >= 1.95 ? "s" : "")
    }

    let rounded = Int(hours.rounded())
    return "\(rounded) hour" + (rounded == 1 ? "" : "s")
}
