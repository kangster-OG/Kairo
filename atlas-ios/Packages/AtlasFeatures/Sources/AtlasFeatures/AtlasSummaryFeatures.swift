import AtlasDesignSystem
import AtlasDomain
import SwiftUI

struct AtlasGeneratedSummaryCard: View {
    let summary: AtlasGeneratedSummary
    var wrapInCard: Bool = true

    var body: some View {
        Group {
            if wrapInCard {
                AtlasSectionCard {
                    summaryBody
                }
            } else {
                summaryBody
            }
        }
    }

    @ViewBuilder
    private var summaryBody: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.title)
                        .font(.headline)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(summary.generatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer(minLength: 12)
                Text(summary.executionMode.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasPalette.primary)
            }

            Text(summary.summary)
                .foregroundStyle(AtlasPalette.textPrimary)

            Text(summary.disclaimer)
                .font(.caption)
                .foregroundStyle(AtlasPalette.textSecondary)

            ForEach(summary.sourceSections) { section in
                if section.facts.isEmpty == false {
                    Divider()
                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                        Text(section.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textSecondary)
                        ForEach(section.facts) { fact in
                            Text("\(fact.label): \(fact.value)")
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                }
            }
        }
    }
}
