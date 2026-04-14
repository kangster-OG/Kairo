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

        List {
            Section {
                AtlasSectionCard(title: "Wrist-ready status") {
                    Text(
                        guidance?.headline
                        ?? "Atlas keeps the next due item, recovery handling, and quick context ready for Apple Watch Shortcuts."
                    )
                        .font(.headline)
                        .foregroundStyle(AtlasPalette.textPrimary)

                    Text(
                        guidance?.summary
                        ?? "When Atlas has a visible next step, the watch companion stays narrow so the wrist only carries what matters right now."
                    )
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
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                    }

                    Text("Updated from Atlas local data at \(model.currentDate().formatted(date: .abbreviated, time: .shortened)).")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            if let currentOccurrence {
                Section {
                    AtlasSectionCard(title: "Next due actions") {
                        Text("These are the same fast actions Atlas exposes to Apple Watch Shortcuts and Siri.")
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
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }

            if let weeklyReview {
                Section {
                    AtlasSectionCard(title: "Week on wrist") {
                        Text(weeklyReview.summaryText)
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
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text(savedPlan.detail)
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }

                        Button("Open weekly review") {
                            model.open(.weeklyReview)
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }

            if let recovery {
                Section {
                    AtlasSectionCard(title: "Recovery handoff") {
                        Text(recovery.summary)
                            .foregroundStyle(AtlasPalette.textSecondary)

                        if recovery.facts.isEmpty == false {
                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                ForEach(recovery.facts, id: \.label) { fact in
                                    HStack(spacing: AtlasSpacing.small) {
                                        Text(fact.label)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(AtlasPalette.primary)
                                        Spacer()
                                        Text(fact.value)
                                            .font(.caption)
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
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }

            Section {
                AtlasSectionCard(title: "Quick context") {
                    Text("Hydration and appetite can be captured as one-tap wrist actions. GI check-in stays available as a deeper handoff into Atlas.")
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
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(AtlasPalette.textPrimary)
                                        Text(shortcut.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(AtlasSecondaryButtonStyle())
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                AtlasSectionCard(title: "Apple Watch shortcuts") {
                    Text("Atlas keeps the first-pass watch experience intentionally small: act on the next due item, open recovery handling, or log a fast context signal.")
                        .foregroundStyle(AtlasPalette.textSecondary)

                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                        ForEach(shortcutPhrases, id: \.self) { phrase in
                            HStack(spacing: AtlasSpacing.small) {
                                Image(systemName: "applewatch")
                                    .foregroundStyle(AtlasPalette.primary)
                                Text(phrase)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AtlasPalette.textPrimary)
                            }
                        }
                    }

                    Text("This companion layer is source-backed by Atlas local data and intentionally hands deeper work back to iPhone.")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AtlasPalette.canvas)
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
