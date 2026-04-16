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
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(summary.generatedAt.formatted(date: .abbreviated, time: .shortened))
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer(minLength: 12)
                Text(summary.executionMode.label)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.primary)
            }

            Text(summary.summary)
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textPrimary)

            ForEach(summary.sourceSections) { section in
                if section.facts.isEmpty == false {
                    Divider()
                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                        Text(section.title)
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.textSecondary)
                        ForEach(section.facts) { fact in
                            Text("\(fact.label): \(fact.value)")
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                }
            }
        }
    }
}
