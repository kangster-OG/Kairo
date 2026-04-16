import AtlasDesignSystem
import AtlasDomain
import SwiftUI

public struct AtlasWatchCompanionScreen: View {
    let model: AtlasAppModel

    @State private var contextEditor = AtlasContextEditorState(referenceDate: .now)
    @State private var contextSheetPresented = false

    public var body: some View {
        let weeklyReview = model.weeklyReviewPresentation()
        let guidance = atlasTodayGuidancePresentation(
            todaySnapshot: model.todaySnapshot,
            weeklyReviewSeed: weeklyReview?.seed,
            actionPlans: weeklyReview?.actionPlans ?? []
        )
        let recovery = atlasTodayRecoveryPresentation(
            todaySnapshot: model.todaySnapshot,
            weeklyReviewSeed: weeklyReview?.seed,
            actionPlans: weeklyReview?.actionPlans ?? []
        )
        let currentOccurrence = model.todaySnapshot.overdue.first ?? model.todaySnapshot.nextDue ?? model.todaySnapshot.upcoming.first
        let shortcutPhrases = [
            "Mark Next Due Taken",
            "Skip Next Due",
            "Open Recovery Handling",
            "Log Hydration",
            "Log Low Appetite"
        ]

        AtlasScreen {
            AtlasCommandDeck(
                eyebrow: "Apple Watch",
                title: "Wrist-ready status",
                detail: guidance?.headline
                    ?? "Next due, recovery, and quick context.",
                metrics: [
                    AtlasMetricItem(id: "next", title: "Next", value: currentOccurrence?.scheduledAt.formatted(date: .omitted, time: .shortened) ?? "Idle", tint: currentOccurrence?.state == .overdue ? AtlasPalette.warning : AtlasPalette.primary),
                    AtlasMetricItem(id: "shortcuts", title: "Shortcuts", value: "\(shortcutPhrases.count)", tint: AtlasPalette.secondaryText)
                ],
                tint: AtlasPalette.primary,
                style: .hero
            ) {
                Text(
                    guidance?.summary
                    ?? "Keep the wrist view narrow."
                )
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)

                if let currentOccurrence {
                    HStack(spacing: AtlasSpacing.small) {
                        AtlasStatusBadge(
                            currentOccurrence.state.rawValue.capitalized,
                            tint: currentOccurrence.state == .overdue ? .orange : AtlasPalette.primary
                        )
                        AtlasStatusBadge(
                            currentOccurrence.scheduledAt.formatted(date: .omitted, time: .shortened),
                            tint: AtlasPalette.secondaryText
                        )
                    }

                    Text(atlasTodayActionTitle(for: currentOccurrence))
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(AtlasPalette.textPrimary)
                }
            } footer: {
                Text("Updated from local data at \(model.currentDate().formatted(date: .abbreviated, time: .shortened)).")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            if let currentOccurrence {
                AtlasWatchSectionHeader(title: "Next Due Actions")
                AtlasSectionCard(title: "Next due actions") {
                    Text("These are the same fast actions available through Apple Watch Shortcuts and Siri.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    HStack(spacing: AtlasSpacing.small) {
                        Button("Mark taken") {
                            Task {
                                await model.logOccurrence(
                                    AtlasOccurrenceLogRequest(
                                        occurrenceID: currentOccurrence.id,
                                        protocolID: currentOccurrence.protocolID,
                                        action: .taken
                                    )
                                )
                            }
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())

                        Button("Skip") {
                            Task {
                                await model.logOccurrence(
                                    AtlasOccurrenceLogRequest(
                                        occurrenceID: currentOccurrence.id,
                                        protocolID: currentOccurrence.protocolID,
                                        action: .skipped
                                    )
                                )
                            }
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }

                    Button("Open the next plan") {
                        model.open(.protocolDetail(currentOccurrence.protocolID))
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }

            if let weeklyReview {
                AtlasWatchSectionHeader(title: "Week On Wrist")
                AtlasSectionCard(title: "Week on wrist") {
                    Text(weeklyReview.summaryText)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    HStack(spacing: AtlasSpacing.small) {
                        AtlasStatusBadge(
                            "\(weeklyReview.seed.completedCount) completed",
                            tint: AtlasPalette.success
                        )
                        AtlasStatusBadge(
                            "\(weeklyReview.seed.overdueCount) open",
                            tint: weeklyReview.seed.overdueCount > 0 ? .orange : AtlasPalette.secondaryText
                        )
                        AtlasStatusBadge(
                            "\(weeklyReview.actionPlans.count) saved",
                            tint: weeklyReview.actionPlans.isEmpty ? AtlasPalette.secondaryText : AtlasPalette.primary
                        )
                    }

                    if let savedPlan = weeklyReview.actionPlans.first {
                        Text("Top carry-forward: \(savedPlan.title)")
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(savedPlan.detail)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    Button("Open weekly review") {
                        model.open(.weeklyReview)
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }

            if let recovery {
                AtlasWatchSectionHeader(title: "Recovery Handoff")
                AtlasSectionCard(title: "Recovery handoff") {
                    Text(recovery.summary)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    if recovery.facts.isEmpty == false {
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            ForEach(recovery.facts, id: \.label) { fact in
                                HStack(spacing: AtlasSpacing.small) {
                                    Text(fact.label)
                                        .atlasTextRole(.deckEyebrow)
                                        .foregroundStyle(AtlasPalette.primary)
                                    Spacer()
                                    Text(fact.value)
                                        .atlasTextRole(.supporting)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                            }
                        }
                    }

                    Button(recovery.primaryAction.title) {
                        performGuidanceAction(recovery.primaryAction)
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())

                    if let secondaryAction = recovery.secondaryAction {
                        Button(secondaryAction.title) {
                            performGuidanceAction(secondaryAction)
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                }
            }

            AtlasWatchSectionHeader(title: "Quick Context")
            AtlasSectionCard(title: "Quick context") {
                Text("Hydration and appetite are one-tap actions here. GI check-in opens the deeper handoff.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                VStack(spacing: AtlasSpacing.small) {
                    ForEach([AtlasTodayContextShortcut.hydration, .lowAppetite, .giCheckIn], id: \.self) { shortcut in
                        Button {
                            triggerShortcut(shortcut)
                        } label: {
                            HStack(spacing: AtlasSpacing.small) {
                                Image(systemName: shortcut.symbolName)
                                    .foregroundStyle(AtlasPalette.primary)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(shortcut.title)
                                        .atlasTextRole(.cardBody)
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                    Text(shortcut.subtitle)
                                        .atlasTextRole(.supporting)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                }
            }

            AtlasWatchSectionHeader(title: "Apple Watch Shortcuts")
            AtlasSectionCard(title: "Apple Watch shortcuts") {
                Text("Use the watch for next due, recovery, and quick context.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    ForEach(shortcutPhrases, id: \.self) { phrase in
                        HStack(spacing: AtlasSpacing.small) {
                            Image(systemName: "applewatch")
                                .foregroundStyle(AtlasPalette.primary)
                            Text(phrase)
                                .atlasTextRole(.deckEyebrow)
                                .foregroundStyle(AtlasPalette.textPrimary)
                        }
                    }
                }
                Text("This companion layer is sourced from local data and hands deeper work back to iPhone.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
        }
        .navigationTitle("Apple Watch")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await model.loadShellDataIfNeeded()
        }
        .sheet(isPresented: $contextSheetPresented) {
            AtlasContextEntrySheet(model: model, state: contextEditor)
        }
    }

    private func performGuidanceAction(_ action: AtlasTodayGuidanceAction) {
        switch action.destination {
        case .protocolDetail(let id):
            model.open(.protocolDetail(id))
        case .protocolChange(let id):
            model.open(.protocolChange(id))
        case .weeklyReview:
            model.open(.weeklyReview)
        case .library:
            model.activeTab = .library
        case .contextShortcut(let shortcut):
            triggerShortcut(shortcut)
        case .detailedContext(let shortcut):
            contextEditor = atlasTodayContextEditorState(
                shortcut: shortcut,
                referenceDate: model.currentDate(),
                protocolID: atlasTodayContextProtocolID(snapshot: model.todaySnapshot)
            )
            contextSheetPresented = true
        }
    }

    private func triggerShortcut(_ shortcut: AtlasTodayContextShortcut) {
        switch shortcut.delivery {
        case .saveNow:
            Task {
                await model.saveContextEntry(
                    shortcut.makeDraft(
                        loggedAt: model.currentDate(),
                        protocolID: atlasTodayContextProtocolID(snapshot: model.todaySnapshot)
                    )
                )
            }
        case .openEditor:
            contextEditor = atlasTodayContextEditorState(
                shortcut: shortcut,
                referenceDate: model.currentDate(),
                protocolID: atlasTodayContextProtocolID(snapshot: model.todaySnapshot)
            )
            contextSheetPresented = true
        }
    }
}

private struct AtlasWatchSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .atlasTextRole(.deckEyebrow)
            .foregroundStyle(AtlasPalette.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, AtlasSpacing.small)
    }
}
