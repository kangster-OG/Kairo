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
        AtlasScreen {
            if let knowledge {
                AtlasCommandDeck(
                    eyebrow: "Compound intelligence",
                    title: knowledge.displayName,
                    detail: knowledge.protocolSummary,
                    metrics: [
                        AtlasMetricItem(id: "category", title: "Category", value: knowledge.categoryLabel, tint: AtlasPalette.primary),
                        AtlasMetricItem(id: "route", title: "Route", value: knowledge.routeLabel, tint: AtlasPalette.secondaryText),
                        AtlasMetricItem(id: "cadence", title: "Cadence", value: knowledge.typicalCadenceLabel, tint: AtlasPalette.success)
                    ],
                    tint: AtlasPalette.primary,
                    style: .hero
                ) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AtlasSpacing.xSmall) {
                            AtlasCompoundIntelligenceChip(label: knowledge.categoryLabel)
                            AtlasCompoundIntelligenceChip(label: knowledge.routeLabel)
                            AtlasCompoundIntelligenceChip(label: knowledge.typicalCadenceLabel)
                        }
                    }
                } footer: {
                    EmptyView()
                }

                AtlasCompoundSectionHeader(title: "General Role")
                AtlasSectionCard(title: "General role") {
                    ForEach(atlasCompoundUseCases(for: knowledge), id: \.self) { line in
                        AtlasCompoundBulletLine(text: line)
                    }
                }

                AtlasCompoundSectionHeader(title: "Model Facts")
                AtlasSectionCard(title: "Model facts") {
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

                if knowledge.operationalCautions.isEmpty == false {
                    AtlasCompoundSectionHeader(title: "Operational Watchouts")
                    AtlasSectionCard(title: "Operational watchouts") {
                        ForEach(knowledge.operationalCautions, id: \.self) { caution in
                            AtlasCompoundBulletLine(text: caution)
                        }
                    }
                }

                if activeProtocols.isEmpty == false {
                    AtlasCompoundSectionHeader(title: "Your Protocols")
                    AtlasSectionCard(title: "Your protocols") {
                        ForEach(activeProtocols) { summary in
                            AtlasCompoundProtocolRow(model: model, summary: summary)
                        }
                    }
                }

                if compareCandidates.isEmpty == false {
                    AtlasCompoundSectionHeader(title: "Compare Nearby")
                    AtlasSectionCard(title: "Compare nearby") {
                        ForEach(compareCandidates.prefix(4)) { candidate in
                            AtlasCompoundCandidateRow(model: model, knowledge: candidate)
                        }
                    }
                }

                AtlasCompoundSectionHeader(title: "Trust Note")
                AtlasSectionCard(style: .utility, title: "Trust note") {
                    Text("Descriptive reference only. No treatment guidance.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            } else {
                AtlasSectionCard(style: .utility, title: "Compound not found") {
                    Text("No strong catalog match yet. Protocol detail and Change Studio are still available.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
        }
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
                .atlasTextRole(.deckEyebrow)
                .foregroundStyle(AtlasPalette.primary)
            Text(value)
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
    }
}

private struct AtlasCompoundSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .atlasTextRole(.deckEyebrow)
            .foregroundStyle(AtlasPalette.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, AtlasSpacing.small)
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
                .atlasTextRole(.supporting)
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
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)

            Text("\(summary.kindLabel) • \(summary.cadenceLabel)")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)

            if let doseLabel = summary.doseLabel {
                Text("Dose \(doseLabel)")
                    .atlasTextRole(.supporting)
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
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)

            Text(knowledge.protocolSummary)
                .atlasTextRole(.supporting)
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
            .atlasTextRole(.deckEyebrow)
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
            useCases.append("Site placement and injection burden can matter here.")
        case .dailyCadence, .weeklyCadence, .giLoad, .waterRetention:
            continue
        }
    }

    if knowledge.operationalTags.contains(.giLoad) {
        useCases.append("Users often watch GI tolerance or appetite shifts before they make any bigger interpretation about the plan.")
    }

    if knowledge.operationalTags.contains(.waterRetention) {
        useCases.append("Water or scale movement can be noisy here.")
    }

    if useCases.isEmpty {
        useCases.append("Route, cadence, and tracking burden often matter more than the name alone.")
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
                    value: "A deterministic relative level curve is available using a \(atlasCompoundHalfLifeLabel(hours: kineticsProfile.halfLifeHours)) half-life profile."
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
                    value: "No modeled half-life curve is available for this compound yet."
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
