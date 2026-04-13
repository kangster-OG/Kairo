import AtlasDesignSystem
import AtlasDomain
import Charts
import SwiftUI

struct AtlasMedicationLevelCard: View {
    let model: AtlasAppModel
    let item: AtlasAmountEstimateItem
    var renderMode: AtlasPrivacyRenderMode? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        AtlasSectionCard {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack(alignment: .top, spacing: AtlasSpacing.small) {
                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                        Text(
                            model.renderedTitle(
                                canonical: item.canonicalProtocolTitle,
                                alias: item.aliasProtocolTitle,
                                renderMode: renderMode ?? model.settingsSnapshot.trustVaultStatus.renderMode
                            )
                        )
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)

                        Text(item.estimateLabel)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)

                        Text(item.cadenceLabel)
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    Spacer()

                    Text(item.modelKind == .halfLifeEstimate ? "Half-life" : "Schedule")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.primary)
                        .padding(.horizontal, AtlasSpacing.small)
                        .padding(.vertical, AtlasSpacing.xSmall)
                        .background(AtlasPalette.primary.opacity(0.12), in: Capsule())
                }

                if let compareLabel = item.compareLabel {
                    Text(compareLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                if item.points.isEmpty == false {
                    Chart {
                        ForEach(item.points) { point in
                            AreaMark(
                                x: .value("Date", point.recordedAt),
                                y: .value("Estimated quantity", point.estimatedQuantity)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AtlasPalette.primary.opacity(0.28), AtlasPalette.primary.opacity(0.04)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                            LineMark(
                                x: .value("Date", point.recordedAt),
                                y: .value("Estimated quantity", point.estimatedQuantity)
                            )
                            .foregroundStyle(AtlasPalette.primary)
                            .interpolationMethod(.catmullRom)
                        }

                        ForEach(item.doseEvents) { event in
                            PointMark(
                                x: .value("Dose", event.loggedAt),
                                y: .value("Estimated quantity", pointValue(for: event.loggedAt))
                            )
                            .symbolSize(24)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        }
                    }
                    .frame(height: 180)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                                .foregroundStyle(AtlasPalette.textSecondary.opacity(0.25))
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                    .accessibilityLabel("Medication level chart")
                    .accessibilityValue(item.estimateLabel)
                }

                if item.doseEvents.isEmpty == false {
                    let recentDoseEvents = Array(item.doseEvents.suffix(3).reversed())
                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                        Text("Recent logged doses")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .textCase(.uppercase)

                        ForEach(recentDoseEvents) { event in
                            Text("\(event.quantityLabel) • \(event.loggedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                }

                if let halfLifeLabel = item.halfLifeLabel {
                    Text(halfLifeLabel)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                if let peakWindowLabel = item.peakWindowLabel {
                    Text(peakWindowLabel)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                Text(item.notesLabel)
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)

                if item.sourceFacts.isEmpty == false {
                    Divider()

                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                        Text("Source facts")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .textCase(.uppercase)

                        ForEach(item.sourceFacts) { fact in
                            HStack(alignment: .top, spacing: AtlasSpacing.small) {
                                Text(fact.label)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                    .frame(width: 96, alignment: .leading)
                                Text(fact.value)
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }

                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
        }
    }

    private func pointValue(for date: Date) -> Double {
        item.points.last(where: { $0.recordedAt <= date })?.estimatedQuantity
            ?? item.points.first?.estimatedQuantity
            ?? 0
    }
}
