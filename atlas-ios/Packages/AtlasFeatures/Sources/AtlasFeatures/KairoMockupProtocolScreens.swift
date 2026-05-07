import AtlasDesignSystem
import AtlasDomain
import Foundation
import PhotosUI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

private var kairoIsMockupFidelityLaunch: Bool {
    #if DEBUG
    if let rawValue = ProcessInfo.processInfo.environment["ATLAS_QA_MOCKUP_FIDELITY"]?.trimmingCharacters(in: .whitespacesAndNewlines) {
        return ["1", "true", "yes"].contains(rawValue.lowercased())
    }
    return ProcessInfo.processInfo.arguments.contains("--atlas-qa-mockup-fidelity")
    #else
    return false
    #endif
}

struct KairoTodayScreen: View {
    let model: AtlasAppModel
    let state: AtlasTodayViewState
    @State private var showingWorkoutCapture = false

    private var nextAction: AtlasScheduledOccurrence? {
        state.todaySnapshot.overdue.first ?? state.todaySnapshot.nextDue ?? state.todaySnapshot.upcoming.first
    }

    var body: some View {
        KairoScrollSurface {
            KairoTopBar(title: "Kairo", trailing: {
                HStack(spacing: 10) {
                    KairoInlineMetric(icon: "chart.line.uptrend.xyaxis", value: topStreakLabel, tint: AtlasPalette.primary)
                    KairoInlineMetric(icon: "hexagon.fill", value: kairoIsMockupFidelityLaunch ? "1,250" : "\(model.rewardsSnapshot.totalPoints.formatted())", tint: AtlasPalette.reward)
                }
            })

            KairoHeroMascotCard(
                model: model,
                title: "Good morning",
                subtitle: "You're building momentum.",
                footnote: "Lv. \(model.rewardsSnapshot.level)",
                progress: rewardProgress
            )

            KairoNextShotCard(
                model: model,
                occurrence: nextAction,
                primaryAction: {
                    if nextAction == nil {
                        model.open(.protocolCreate)
                    } else {
                        model.routePath.removeAll()
                        model.activeTab = .timeline
                    }
                },
                detailAction: {
                    if let nextAction {
                        model.open(.protocolDetail(nextAction.protocolID))
                    } else {
                        model.open(.protocolCreate)
                    }
                }
            )

            HStack(spacing: 8) {
                Button {
                    model.open(.quickCapture(.protein))
                } label: {
                    KairoSupportRing(title: "Protein", value: proteinLabel, caption: proteinCaption, progress: proteinProgress, tint: AtlasPalette.primary, icon: "leaf.fill")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log protein")

                Button {
                    model.open(.quickCapture(.hydration))
                } label: {
                    KairoSupportRing(title: "Hydration", value: hydrationLabel, caption: hydrationCaption, progress: hydrationProgress, tint: KairoColor.blue, icon: "drop.fill")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log hydration")

                Button {
                    showingWorkoutCapture = true
                } label: {
                    KairoSupportRing(title: "Workout", value: workoutLabel, caption: workoutCaption, progress: workoutProgress, tint: AtlasPalette.warning, icon: "figure.strengthtraining.traditional")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log workout")
            }
            .frame(height: 146)

            KairoInventoryRunwayCard(model: model) {
                model.open(.inventory)
            }
        }
        .sheet(isPresented: $showingWorkoutCapture) {
            KairoWorkoutCaptureSheet(model: model)
        }
    }

    private var topStreakLabel: String {
        guard let streak = model.rewardsSnapshot.streaks.first else { return "Streak 0" }
        return "Streak \(streak.count)"
    }

    private var rewardProgress: Double {
        let total = Double(max(model.rewardsSnapshot.nextLevelPoints, 1))
        return min(1, Double(model.rewardsSnapshot.totalPoints) / total)
    }

    private var proteinTarget: AtlasNutritionTargetSnapshot? {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first { $0.kind == .proteinMeals }
    }

    private var hydrationTarget: AtlasNutritionTargetSnapshot? {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first { $0.kind == .hydrationCheckins }
    }

    private var proteinProgress: Double { proteinTarget?.progress ?? 0 }
    private var hydrationProgress: Double { hydrationTarget?.progress ?? 0 }
    private var workoutProgress: Double { model.insightsSnapshot.recentWorkoutEntries.isEmpty ? 0 : 0.80 }
    private var proteinLabel: String { "\(Int((proteinProgress * 120).rounded())) g" }
    private var hydrationLabel: String { "\(formatHydrationLiters(hydrationProgress * 2.5)) L" }
    private var workoutLabel: String {
        model.insightsSnapshot.recentWorkoutEntries.first?.durationLabel.components(separatedBy: " ").first ?? "0"
    }
    private var proteinCaption: String { "of 120 g" }
    private var hydrationCaption: String { "of 2.5L" }
    private var workoutCaption: String { "of 45 min" }
}

struct KairoLogShotScreen: View {
    let model: AtlasAppModel

    @State private var siteOptions: AtlasProtocolSiteOptions?
    @State private var selectedSiteID: String?
    @State private var painLevel = 3.0
    @State private var selectedEffects: Set<String> = []
    @State private var note = ""
    @State private var isSaving = false
    @State private var showingSiteRotation = false
    @State private var showShotRewardBanner = false

    private var occurrence: AtlasScheduledOccurrence? {
        model.todaySnapshot.overdue.first ?? model.todaySnapshot.nextDue ?? model.todaySnapshot.upcoming.first
    }

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Log Shot", trailingSystemImage: "checkmark.circle", showsBackButton: false)

            if occurrence == nil {
                KairoSectionCard {
                    HStack(alignment: .top, spacing: 12) {
                        KairoTinyIcon(systemName: "syringe.fill", tint: AtlasPalette.primary)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Create your first protocol")
                                .kairoCardTitle()
                            Text("Log Shot becomes active after a real cadence, dose, and schedule exist.")
                                .kairoMeta()
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                Button {
                    model.open(.protocolCreate)
                } label: {
                    Label("Add Protocol", systemImage: "plus")
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
            } else {
                if showShotRewardBanner || kairoIsMockupFidelityLaunch {
                    KairoRewardBanner(model: model, title: "Great consistency!", amount: "+12 XP")
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                KairoCompactSectionCard {
                    HStack(spacing: 10) {
                        KairoVialIcon(fill: vialFill)
                            .frame(width: 32, height: 38)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(protocolTitle)
                                .kairoCardTitle()
                            Text(protocolDoseLine)
                                .kairoMeta()
                        }
                        Spacer()
                        KairoTinyIcon(systemName: "clock", tint: AtlasPalette.textSecondary)
                        Text(logShotTimeLabel)
                            .kairoMeta()
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("Injection Site")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                        .padding(.top, 10)
                        .padding(.horizontal, 10)

                    HStack(alignment: .top, spacing: 10) {
                        KairoBodyMap(sites: activeSites, selectedSiteID: selectedSiteID)
                            .frame(width: 250, height: 168)
                            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(spacing: 3) {
                            if activeSites.isEmpty {
                                KairoEmptyLine("No site rotation set up yet.")
                                Button("Set Up Sites") {
                                    showingSiteRotation = true
                                }
                                .buttonStyle(AtlasSecondaryButtonStyle())
                            } else {
                                ForEach(displaySiteChoices.prefix(6), id: \.id) { site in
                                    KairoChoicePill(
                                        title: site.title,
                                        isSelected: selectedSiteID == site.id,
                                        tint: AtlasPalette.primary,
                                        isCompact: true
                                    ) {
                                        AtlasFeedback.selection()
                                        selectedSiteID = site.id == "other-site" ? nil : site.id
                                    }
                                }
                            }
                        }
                        .padding(.trailing, 10)
                        .frame(width: 78)
                    }
                    .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AtlasPalette.border.opacity(0.72), lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: AtlasPalette.shadow.opacity(0.30), radius: 5, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Pain Level")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Spacer()
                        Text("\(Int(painLevel.rounded()))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                            .frame(width: 28, height: 24)
                            .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    Slider(value: $painLevel, in: 0...10, step: 1)
                        .tint(AtlasPalette.primary)
                        .frame(height: 16)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AtlasPalette.border.opacity(0.72), lineWidth: 1))
                .shadow(color: AtlasPalette.shadow.opacity(0.42), radius: 6, x: 0, y: 3)

                KairoCompactSectionCard(title: "Side Effects (optional)") {
                    KairoWrap(options: ["None", "Nausea", "Fatigue", "Headache", "Bloating", "GI Upset", "Injection Site", "Other"], selected: selectedEffects, isCompact: true) { effect in
                        if selectedEffects.contains(effect) {
                            selectedEffects.remove(effect)
                        } else {
                            if effect == "None" { selectedEffects.removeAll() }
                            selectedEffects.insert(effect)
                        }
                    }
                }

                KairoCompactSectionCard {
                    TextField("How are you feeling?", text: $note, axis: .vertical)
                        .lineLimit(1)
                        .font(.system(size: 11, weight: .medium))
                        .atlasStandaloneInputSurface()
                }

                KairoInventoryRunwayCard(model: model, compact: true) {
                    model.open(.inventory)
                }

                Button {
                    Task { await markTaken() }
                } label: {
                    Label(isSaving ? "Saving..." : "Mark as Taken", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(AtlasPalette.primary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(occurrence == nil || isSaving)
            }
        }
        .task(id: occurrence?.protocolID) {
            showShotRewardBanner = false
            await reloadSites()
        }
        .sheet(isPresented: $showingSiteRotation, onDismiss: {
            Task { await reloadSites() }
        }) {
            if let occurrence {
                KairoSiteRotationSheet(model: model, protocolID: occurrence.protocolID, protocolTitle: protocolTitle)
            }
        }
        .atlasKeyboardDoneAccessory()
    }

    private var activeSites: [AtlasSiteSummary] {
        (siteOptions?.sites ?? model.inventorySnapshot.sites).filter { $0.archivedAt == nil }
    }

    private var displaySiteChoices: [(id: String, title: String)] {
        var seen = Set<String>()
        var choices: [(id: String, title: String)] = []
        for site in activeSites {
            let title = siteDisplayTitle(site.name)
            if seen.insert(title).inserted {
                choices.append((id: site.id, title: title))
            }
        }
        if !seen.contains("Other") {
            choices.append((id: "other-site", title: "Other"))
        }
        return choices
    }

    private var protocolTitle: String {
        occurrence.map { $0.aliasTitle ?? $0.canonicalTitle } ?? "No shot due"
    }

    private var protocolDoseLine: String {
        guard let occurrence else { return "Create or schedule a protocol first." }
        return [occurrence.doseLabel, "SubQ"].compactMap { $0 }.joined(separator: " • ")
    }

    private var logShotTimeLabel: String {
        guard let occurrence else { return "No shot due" }
        if kairoIsMockupFidelityLaunch {
            return "Today, \(occurrence.scheduledAt.formatted(date: .omitted, time: .shortened))"
        }
        return occurrence.scheduledAt.formatted(date: .omitted, time: .shortened)
    }

    private var vialFill: Double {
        guard let vial = model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil }) else { return 0 }
        return min(1, max(0.05, vial.remainingQuantity / max(vial.startingQuantity, 0.01)))
    }

    private func siteDisplayTitle(_ name: String) -> String {
        let lowered = name.lowercased()
        if lowered.contains("abdomen") { return "Abdomen" }
        if lowered.contains("right thigh") { return "Right Thigh" }
        if lowered.contains("left thigh") { return "Left Thigh" }
        if lowered.contains("right arm") { return "Right Arm" }
        if lowered.contains("left arm") { return "Left Arm" }
        return name.replacingOccurrences(of: "Injection ", with: "")
    }

    private func reloadSites() async {
        guard let occurrence else { return }
        siteOptions = await model.siteOptions(for: occurrence.protocolID)
        selectedSiteID = siteOptions?.suggestedSiteID ?? activeSites.first?.id
    }

    private func markTaken() async {
        guard let occurrence else { return }
        isSaving = true
        defer { isSaving = false }
        let effectLine = selectedEffects.isEmpty ? nil : "Effects: \(selectedEffects.sorted().joined(separator: ", "))"
        let painLine = "Pain: \(Int(painLevel.rounded()))/10"
        let noteLines = [painLine, effectLine, note.nilIfBlank].compactMap { $0 }

        await model.logOccurrence(
            AtlasOccurrenceLogRequest(
                occurrenceID: occurrence.id,
                protocolID: occurrence.protocolID,
                action: .taken,
                siteID: selectedSiteID,
                note: noteLines.isEmpty ? nil : noteLines.joined(separator: " • ")
            )
        )

        for effect in selectedEffects where effect != "None" {
            await model.saveSymptomEntry(
                AtlasSymptomEntryDraft(
                    loggedAt: model.currentDate(),
                    symptomKey: effect,
                    severity: max(1, min(5, Int((painLevel / 2.0).rounded()))),
                    notes: note.nilIfBlank
                )
            )
        }

        AtlasFeedback.notify(.success)
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            showShotRewardBanner = true
        }
        try? await Task.sleep(nanoseconds: 900_000_000)
        model.routePath.removeAll()
        model.activeTab = .today
    }
}

struct KairoCompanionScreen: View {
    let model: AtlasAppModel
    let onOpenSettings: () -> Void
    @State private var showingWorkoutCapture = false
    @State private var selectedRewardArtifact: KairoRewardArtifact?

    var body: some View {
        KairoScrollSurface {
            KairoCompanionEvolutionHeader(model: model, progress: rewardProgress, onOpenSettings: onOpenSettings)

            KairoSectionCard(title: "Quests") {
                ForEach(questRows) { row in
                    Button {
                        openQuest(row)
                    } label: {
                        KairoQuestRow(row: row)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(row.title)
                }
            }

            HStack(alignment: .top, spacing: 8) {
                KairoCollectionCard(
                    title: "Badges",
                    artifacts: Array(kairoBadgeArtifacts(from: model).prefix(4)),
                    openCollection: { model.open(.rewards) },
                    openArtifact: { selectedRewardArtifact = $0 }
                )
                .frame(maxWidth: .infinity)

                KairoCollectionCard(
                    title: "Collectibles",
                    artifacts: Array(kairoCollectibleArtifacts().prefix(4)),
                    openCollection: { model.open(.rewards) },
                    openArtifact: { selectedRewardArtifact = $0 }
                )
                .frame(maxWidth: .infinity)
            }

            Button {
                model.open(.weeklyReview)
            } label: {
                KairoWeeklyMasteryCard(model: model)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Weekly Protocol Mastery")
        }
        .sheet(isPresented: $showingWorkoutCapture) {
            KairoWorkoutCaptureSheet(model: model)
        }
        .sheet(item: $selectedRewardArtifact) { artifact in
            KairoRewardArtifactDetailSheet(artifact: artifact)
        }
    }

    private var rewardProgress: Double {
        Double(model.rewardsSnapshot.totalPoints) / Double(max(model.rewardsSnapshot.nextLevelPoints, 1))
    }

    private var questRows: [KairoQuest] {
        let protein = proteinQuestProgress
        return [
            KairoQuest(icon: "syringe.fill", title: "Log shot", progress: shotDone ? "1 / 1" : "0 / 1", value: shotDone ? 1 : 0, reward: "20 XP"),
            KairoQuest(icon: "fork.knife", title: "Protein meal", progress: protein.label, value: protein.value, reward: "20 XP"),
            KairoQuest(icon: "figure.strengthtraining.traditional", title: "Workout", progress: "\(model.insightsSnapshot.recentWorkoutEntries.isEmpty ? 0 : 1) / 1", value: model.insightsSnapshot.recentWorkoutEntries.isEmpty ? 0 : 1, reward: "20 XP"),
            KairoQuest(icon: "camera.fill", title: "Progress photo", progress: "\(model.insightsSnapshot.progressEvidence.recentPhotos.isEmpty ? 0 : 1) / 1", value: model.insightsSnapshot.progressEvidence.recentPhotos.isEmpty ? 0 : 1, reward: "15 XP")
        ]
    }

    private var proteinQuestProgress: (label: String, value: Double) {
        guard let target = model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .proteinMeals }) else {
            return ("0 / 1", 0)
        }
        return ("\(target.currentValue) / \(target.targetValue)", target.progress)
    }

    private var shotDone: Bool {
        kairoIsMockupFidelityLaunch || model.timelineEntries.contains { $0.type == .doseTaken && Calendar.current.isDateInToday($0.recordedAt) }
    }

    private func openQuest(_ row: KairoQuest) {
        switch row.title {
        case "Log shot":
            model.routePath.removeAll()
            model.activeTab = .timeline
        case "Protein meal":
            model.open(.quickCapture(.protein))
        case "Workout":
            showingWorkoutCapture = true
        case "Progress photo":
            model.open(.progressEvidence)
        default:
            break
        }
    }
}

struct KairoProtocolsScreen: View {
    let model: AtlasAppModel
    let state: AtlasLibraryViewState

    var body: some View {
        KairoScrollSurface {
            KairoTopBar(title: "Protocols", trailing: {
                HStack(spacing: 6) {
                    KairoProtocolTopAction(title: "Inventory", systemImage: "testtube.2", tint: AtlasPalette.primary) {
                        model.open(.inventory)
                    }
                    KairoProtocolTopAction(title: "Calc", systemImage: "function", tint: AtlasPalette.reward) {
                        model.open(.calculator)
                    }
                }
            })

            HStack {
                Text("Active (\(min(activeProtocols.count, 3)))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AtlasPalette.textSecondary)
                Spacer()
                Text("See all")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
            .padding(.horizontal, 2)

            ForEach(activeProtocols.prefix(3)) { summary in
                KairoProtocolSummaryCard(model: model, summary: summary)
            }

            KairoProtocolToolsCard(model: model)

            KairoScheduleSummaryCard(model: model, protocols: Array(activeProtocols.prefix(3)))

            Button {
                model.open(.protocolCreate)
            } label: {
                Label("Add Protocol", systemImage: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .background(AtlasPalette.primary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var activeProtocols: [ProtocolSummary] {
        let active = state.protocols.filter { $0.status.rawValue.lowercased() == "active" }
        return active.isEmpty ? state.protocols : active
    }
}

private struct KairoProtocolTopAction: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button {
            AtlasFeedback.selection()
            action()
        } label: {
            Label(title, systemImage: systemImage)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .padding(.horizontal, 8)
                .frame(height: 28)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct KairoProtocolToolsCard: View {
    let model: AtlasAppModel

    var body: some View {
        KairoCompactSectionCard(title: "Protocol Tools") {
            KairoDisclosureRow(title: "Peptide Calculator", value: calculatorSummary) {
                model.open(.calculator)
            }
            KairoDisclosureRow(title: "Inventory", value: inventorySummary) {
                model.open(.inventory)
            }
        }
    }

    private var calculatorSummary: String {
        guard let vial = model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil }) else {
            return "Set up vial math"
        }
        return vial.calculatorProfileLabel ?? vial.quantityLabel
    }

    private var inventorySummary: String {
        model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil })?.projectedDepletionLabel
            ?? model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil })?.quantityLabel
            ?? "Add vial"
    }
}

struct KairoProtocolDetailScreen: View {
    let model: AtlasAppModel
    let protocolID: String
    @State private var detail: AtlasProtocolDetailSnapshot?
    @State private var siteOptions: AtlasProtocolSiteOptions?
    @State private var showingSiteRotation = false

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "")

            if let detail {
                KairoSectionCard {
                    HStack(alignment: .top, spacing: 12) {
                        KairoVialIcon(fill: vialFill)
                            .frame(width: 46, height: 54)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(detail.aliasTitle ?? detail.canonicalTitle)
                                    .kairoCardTitle()
                                Spacer()
                                KairoBadge("Active", tint: AtlasPalette.primary)
                            }
                            Text([detail.doseLabel, detail.kindLabel].compactMap { $0 }.joined(separator: " • "))
                                .kairoMeta()
                            Text("Next: \(detail.nextOccurrence?.scheduledAt.formatted(date: .omitted, time: .shortened) ?? "Caught up")")
                                .kairoMeta()
                        }
                    }
                }

                KairoMetricStrip(items: [
                    .init(title: "Cadence", value: compactCadenceLabel),
                    .init(title: "Route", value: detail.administrationLabel ?? "Injection"),
                    .init(title: "Day", value: weekdayShort),
                    .init(title: "Time", value: detail.nextOccurrence?.scheduledAt.formatted(date: .omitted, time: .shortened) ?? detail.editableDraft.defaultTimeOfDay ?? "12:30 PM")
                ])

                KairoSectionCard(title: "Schedule") {
                    KairoWeekDots(selected: detail.editableDraft.weekday)
                }

                KairoSectionCard(title: "Adherence (4 weeks)") {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(Int((adherenceValue * 100).rounded()))%")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(AtlasPalette.primary)
                        Spacer()
                        Text("\(recentDoseEntries.count) shots logged")
                            .kairoMeta()
                    }
                    KairoProgressLine(value: adherenceValue, tint: AtlasPalette.primary)
                }

                KairoSectionCard(title: "Medication Level") {
                    KairoMedicationCurve(tint: AtlasPalette.primary)
                        .frame(height: 78)
                }

                KairoSectionCard(title: "Recent Shots") {
                    let rows = recentDoseEntries.prefix(4)
                    if rows.isEmpty {
                        KairoEmptyLine("No recent shots logged.")
                    } else {
                        ForEach(Array(rows)) { entry in
                            KairoSimpleRow(icon: "checkmark.circle.fill", title: entry.recordedAt.formatted(date: .abbreviated, time: .shortened), value: detail.doseLabel ?? "Taken", tint: AtlasPalette.primary)
                        }
                    }
                }

                KairoInventoryRunwayCard(model: model, compact: true) {
                    model.open(.inventory)
                }

                Button {
                    model.open(.protocolEdit(protocolID))
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(AtlasSecondaryButtonStyle())

                Button(activeSites.isEmpty ? "Set Up Site Rotation" : "Edit Site Rotation") {
                    showingSiteRotation = true
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .task(id: protocolID) {
            await reload()
        }
        .sheet(isPresented: $showingSiteRotation, onDismiss: {
            Task { await reload() }
        }) {
            KairoSiteRotationSheet(model: model, protocolID: protocolID, protocolTitle: detail.map { model.renderedTitle(canonical: $0.canonicalTitle, alias: $0.aliasTitle) } ?? "Protocol")
        }
    }

    private var activeSites: [AtlasSiteSummary] {
        (siteOptions?.sites ?? model.inventorySnapshot.sites).filter { $0.archivedAt == nil }
    }

    private var inventorySetting: AtlasProtocolInventorySetting? {
        model.inventorySnapshot.protocolSettings.first { $0.id == protocolID }
    }

    private var siteTrackingEnabled: Bool {
        siteOptions?.siteTrackingEnabled ?? inventorySetting?.siteTrackingEnabled ?? false
    }

    private var siteRotationEnabled: Bool {
        siteOptions?.siteRotationEnabled ?? inventorySetting?.siteRotationEnabled ?? false
    }

    private var suggestedSiteName: String? {
        guard let suggestedID = siteOptions?.suggestedSiteID else { return nil }
        return activeSites.first(where: { $0.id == suggestedID })?.name
    }

    private var recentDoseEntries: [AtlasTimelineEntry] {
        model.timelineEntries
            .filter { $0.protocolID == protocolID && $0.type == .doseTaken }
            .sorted { $0.recordedAt > $1.recordedAt }
    }

    private var weekdayShort: String {
        guard let weekday = detail?.editableDraft.weekday else { return "Mon" }
        return KairoWeekday.shortLabel(forCalendarWeekday: weekday)
    }

    private var compactCadenceLabel: String {
        guard let detail else { return "Weekly" }
        switch detail.editableDraft.cadenceType {
        case .weekly:
            return "Weekly"
        case .daily:
            return "Daily"
        case .everyNDays:
            return detail.editableDraft.intervalDays <= 2 ? "Every Other Day" : "Every \(detail.editableDraft.intervalDays)d"
        }
    }

    private var adherenceValue: Double {
        let taken = recentDoseEntries.count
        let skipped = model.timelineEntries.filter { $0.protocolID == protocolID && $0.type == .doseSkipped }.count
        return Double(taken) / Double(max(taken + skipped, 1))
    }

    private var vialFill: Double {
        guard let vial = model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil && $0.linkedProtocolID == protocolID })
            ?? model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil }) else { return 0 }
        return vial.remainingQuantity / max(vial.startingQuantity, 0.01)
    }

    private func reload() async {
        async let detailLoad = model.protocolDetail(id: protocolID)
        async let siteLoad = model.siteOptions(for: protocolID)
        detail = await detailLoad
        siteOptions = await siteLoad
    }
}

struct KairoProtocolEditorScreen: View {
    let model: AtlasAppModel
    let mode: AtlasProtocolEditorMode

    @State private var form = KairoProtocolForm()
    @State private var didLoad = false
    @State private var isSaving = false

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: modeTitle, trailingSystemImage: "checkmark.circle")

            KairoCompactSectionCard(title: "Medication") {
                HStack(spacing: 9) {
                    KairoVialIcon(fill: 0.82)
                        .frame(width: 36, height: 43)
                    VStack(alignment: .leading, spacing: 4) {
                        KairoPeptideCatalogPicker(selection: $form.name)
                    }
                }
                KairoStepperRow(title: "Dose", value: "\(formatKairoNumber(form.doseAmount, digits: 1)) mg", decrement: { form.doseAmount = max(0.1, form.doseAmount - 0.5) }, increment: { form.doseAmount += 0.5 })
            }

            KairoCompactSectionCard(title: "Cadence") {
                KairoEditorFieldLabel("Cadence")
                KairoSegmentedOptions(options: ["Daily", "Every Other Day", "Weekly", "Custom"], selection: $form.cadenceLabel)
                KairoEditorFieldLabel("Route")
                KairoSegmentedOptions(options: ["SubQ", "Oral"], selection: $form.routeLabel)
                KairoEditorFieldLabel("Day of Week")
                KairoWeekSelector(selected: $form.weekday)
                DatePicker("Time", selection: $form.time, displayedComponents: .hourAndMinute)
                    .font(.system(size: 11, weight: .semibold))
                    .datePickerStyle(.compact)
            }

            KairoCompactSectionCard {
                KairoDisclosureRow(title: "Vial Concentration", value: concentrationLabel) {
                    model.open(.calculator)
                }
                KairoDisclosureRow(title: "Reminders", value: "On • \(form.time.formatted(date: .omitted, time: .shortened))") {
                    model.open(.settingsNotifications)
                }
                KairoDisclosureRow(title: "Runway Preview", value: runwayLabel) {
                    model.open(.inventory)
                }
            }

            KairoCompactSectionCard(title: "Notes (optional)") {
                TextField("Add a note for this protocol", text: $form.notes, axis: .vertical)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1...3)
                    .atlasStandaloneInputSurface()
            }

            Button(isSaving ? "Saving..." : "Save Protocol") {
                Task { await save() }
            }
            .buttonStyle(AtlasPrimaryButtonStyle())
            .disabled(form.name.nilIfBlank == nil || isSaving)
        }
        .task {
            guard didLoad == false else { return }
            didLoad = true
            if case .edit(let id) = mode, let detail = await model.protocolDetail(id: id) {
                form = KairoProtocolForm(detail: detail)
            }
        }
        .atlasKeyboardDoneAccessory()
    }

    private var modeTitle: String {
        switch mode {
        case .create: return "Add Protocol"
        case .edit: return "Edit Protocol"
        }
    }

    private var runwayLabel: String {
        model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil })?.projectedDepletionLabel ?? "12 doses • ~28 days"
    }

    private var concentrationLabel: String {
        guard let vial = model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil }) else {
            return "Add vial"
        }
        return vial.calculatorProfileLabel ?? vial.quantityLabel
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let draft = form.draft
        switch mode {
        case .create:
            if let detail = await model.createProtocol(draft) {
                model.routePath.removeAll()
                model.activeTab = .library
                model.open(.protocolDetail(detail.id))
            }
        case .edit(let id):
            if let detail = await model.updateProtocol(id: id, draft: draft) {
                model.routePath.removeAll()
                model.activeTab = .library
                model.open(.protocolDetail(detail.id))
            }
        }
    }
}

struct KairoProgressScreen: View {
    let model: AtlasAppModel
    let state: AtlasInsightsViewState
    @State private var selectedRange = "7d"
    @State private var showingWorkoutCapture = false
    @State private var showingMeasurementCapture = false

    var body: some View {
        KairoScrollSurface {
            KairoTopBar(title: "Progress", trailing: {
                KairoProgressRangeSelector(selection: $selectedRange)
            })

            KairoBodyTrendCard(
                weight: dashboardWeightLabel,
                weightChange: dashboardWeightChangeLabel,
                bodyFat: dashboardBodyFatLabel,
                bodyFatChange: dashboardBodyFatDetail,
                points: dashboardWeightPoints,
                onWeightTap: {
                    model.open(.quickCapture(.weight))
                },
                onBodyFatTap: {
                    showingMeasurementCapture = true
                }
            )

            HStack(spacing: 8) {
                KairoSectionCard(title: "Consistency", fixedHeight: 104) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(consistencyValue)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(AtlasPalette.primary)
                            Text("this week")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                        KairoMicroWeekProgress(completed: completedDays)
                        KairoProgressLine(value: adherenceValue, tint: AtlasPalette.primary)
                    }
                }
                KairoSectionCard(title: "Symptoms (\(selectedRange))", fixedHeight: 104) {
                    ForEach(symptomRows, id: \.0) { symptom, level in
                        HStack {
                            Text(symptom)
                                .kairoMeta()
                            Spacer()
                            Text(level)
                                .kairoMeta()
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                Button {
                    model.open(.quickCapture(.protein))
                } label: {
                    KairoSupportRing(
                        title: "Nutrition",
                        value: proteinPercent,
                        caption: "avg of goal",
                        progress: proteinProgress,
                        tint: AtlasPalette.primary,
                        icon: "fork.knife",
                        trend: nutritionTrend
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log protein")

                Button {
                    model.open(.quickCapture(.hydration))
                } label: {
                    KairoSupportRing(
                        title: "Hydration",
                        value: hydrationLabel,
                        caption: "avg of 2.5L",
                        progress: hydrationProgress,
                        tint: KairoColor.blue,
                        icon: "drop.fill",
                        trend: hydrationTrend
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log hydration")

                Button {
                    showingWorkoutCapture = true
                } label: {
                    KairoSupportRing(
                        title: "Workout",
                        value: workoutLabel,
                        caption: "of 5 days",
                        progress: workoutProgress,
                        tint: AtlasPalette.warning,
                        icon: "figure.run",
                        trend: workoutTrend
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log workout")
            }
            .frame(height: 158)

            HStack(spacing: 8) {
                Button {
                    model.open(.progressEvidence)
                } label: {
                    KairoMiniAction(title: "Progress Photos", detail: "Last: \(lastPhotoLabel)", icon: "camera.fill", tint: AtlasPalette.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Progress Photos")

                Button {
                    model.open(.settingsServices)
                } label: {
                    KairoMiniAction(title: "Health Integrations", detail: healthIntegrationLabel, icon: "heart.fill", tint: .red)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Health Integrations")
            }
            .frame(height: 74)

            KairoWeeklyReviewProgressCard(
                consistency: consistencyValue,
                photosLabel: weeklyReviewPhotoLabel,
                healthLabel: healthIntegrationLabel
            ) {
                model.open(.progressEvidence)
            }
        }
        .sheet(isPresented: $showingWorkoutCapture) {
            KairoWorkoutCaptureSheet(model: model)
        }
        .sheet(isPresented: $showingMeasurementCapture) {
            KairoMeasurementEditorSheet(model: model, initialKind: .bodyFat)
        }
    }

    private var proteinTarget: AtlasNutritionTargetSnapshot? {
        state.insightsSnapshot.nutritionSnapshot.dailyTargets.first { $0.kind == .proteinMeals }
    }

    private var hydrationTarget: AtlasNutritionTargetSnapshot? {
        state.insightsSnapshot.nutritionSnapshot.dailyTargets.first { $0.kind == .hydrationCheckins }
    }

    private var proteinProgress: Double { proteinTarget?.progress ?? 0 }
    private var hydrationProgress: Double { hydrationTarget?.progress ?? 0 }
    private var workoutProgress: Double { state.insightsSnapshot.recentWorkoutEntries.isEmpty ? 0 : 0.82 }
    private var proteinPercent: String { "\(Int((proteinProgress * 100).rounded()))%" }
    private var hydrationLabel: String {
        "\(formatHydrationLiters(hydrationProgress * 2.5)) L"
    }
    private var workoutLabel: String {
        "\(state.insightsSnapshot.recentWorkoutEntries.count)"
    }
    private var lastPhotoLabel: String { state.insightsSnapshot.progressEvidence.recentPhotos.first?.loggedAt.formatted(date: .abbreviated, time: .omitted) ?? "Add now" }
    private var dashboardWeightLabel: String {
        if let onboardingWeight = model.bootstrapSnapshot.onboardingDraft.profile.weight {
            return "\(formatDashboardNumber(onboardingWeight)) \(model.bootstrapSnapshot.onboardingDraft.profile.weightUnit?.rawValue ?? "lb")"
        }
        if let latest = state.insightsSnapshot.weightTrend.latestLabel?.nilIfBlank {
            return latest
        }
        return "Add weight"
    }
    private var dashboardWeightChangeLabel: String? {
        let profile = model.bootstrapSnapshot.onboardingDraft.profile
        if let weight = profile.weight, let goal = profile.goalWeight {
            let delta = abs(weight - goal)
            guard delta > 0.05 else { return "At goal" }
            return "\(formatDashboardNumber(delta)) \(profile.weightUnit?.rawValue ?? "lb") to goal"
        }
        return state.insightsSnapshot.weightTrend.changeLabel?.nilIfBlank
    }
    private var dashboardBodyFatLabel: String {
        bodyFatTrend?.latestLabel?.nilIfBlank ?? "Not set"
    }
    private var dashboardBodyFatDetail: String? {
        bodyFatTrend?.changeLabel?.nilIfBlank ?? "Optional"
    }
    private var bodyFatTrend: AtlasProgressMeasurementTrend? {
        state.insightsSnapshot.progressEvidence.measurementTrends.first { $0.kind == .bodyFat }
    }
    private var dashboardWeightPoints: [Double] {
        let livePoints = state.insightsSnapshot.weightTrend.points.map { $0.value }
        if livePoints.count > 1 {
            return normalizedDashboardPoints(livePoints)
        }
        let profile = model.bootstrapSnapshot.onboardingDraft.profile
        if let weight = profile.weight, let goal = profile.goalWeight {
            let values = stride(from: 0.0, through: 1.0, by: 1.0 / 6.0).map { progress in
                weight + ((goal - weight) * progress)
            }
            return normalizedDashboardPoints(values)
        }
        return [0.50, 0.50]
    }
    private var completedDays: Int {
        let label = state.insightsSnapshot.adherenceTrend.completionRateLabel ?? "6 of 7"
        return Int(label.split(separator: " ").first ?? "6") ?? 6
    }
    private var consistencyValue: String {
        if let label = state.insightsSnapshot.adherenceTrend.completionRateLabel,
           label.contains(" of ") {
            let parts = label.split(separator: " ")
            if parts.count >= 3 {
                return "\(parts[0]) \(parts[1]) \(parts[2])"
            }
            return label
        }
        return "\(completedDays) of 7"
    }
    private var adherenceValue: Double {
        min(1, Double(completedDays) / 7.0)
    }
    private var healthIntegrationLabel: String {
        let connected = model.settingsSnapshot.healthScaffold.connections.filter { $0.connected }.count
        return connected == 0 ? "Available" : "\(connected) connected"
    }
    private var weeklyReviewPhotoLabel: String {
        state.insightsSnapshot.progressEvidence.recentPhotos.isEmpty ? "Baseline needed" : "Photo added"
    }
    private var nutritionTrend: [Double] {
        let current = proteinProgress
        return [0.0, current > 0 ? 0.34 : 0.0, current > 0.45 ? 0.62 : 0.0, current, current > 0 ? 0.52 : 0.0, current > 0.7 ? 0.84 : 0.0, current]
    }
    private var hydrationTrend: [Double] {
        let current = hydrationProgress
        return [0.0, current > 0 ? 0.25 : 0.0, current > 0.4 ? 0.5 : 0.0, current > 0 ? 0.36 : 0.0, current, current > 0.7 ? 0.78 : 0.0, current]
    }
    private var workoutTrend: [Double] {
        let logged = state.insightsSnapshot.recentWorkoutEntries.count
        return (0..<7).map { index in
            index < logged ? 1.0 : 0.0
        }
    }
    private var symptomRows: [(String, String)] {
        let rows = state.insightsSnapshot.recentSymptomEntries.prefix(3).map { ($0.symptomKey, $0.severity <= 2 ? "Mild" : "Mod") }
        return rows.isEmpty ? [("Nausea", "Mild"), ("Fatigue", "Mild"), ("Injection Site", "None")] : rows
    }
    private func normalizedDashboardPoints(_ values: [Double]) -> [Double] {
        guard let minValue = values.min(), let maxValue = values.max(), maxValue > minValue else {
            return Array(repeating: 0.50, count: max(values.count, 2))
        }
        return values.map { value in
            0.18 + ((maxValue - value) / (maxValue - minValue)) * 0.64
        }
    }
    private func formatDashboardNumber(_ value: Double) -> String {
        let rounded = value.rounded()
        if abs(value - rounded) < 0.05 {
            return "\(Int(rounded))"
        }
        return String(format: "%.1f", value)
    }
}

struct KairoProgressPhotosScreen: View {
    let model: AtlasAppModel
    @State private var selectedMode = "Timeline"
    @State private var showMeasurementEditor = false
    @State private var showPhotoEditor = false

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Progress Photos")

            KairoSegmentedControl(labels: ["Timeline", "Compare"], selection: $selectedMode)

            let photos = model.insightsSnapshot.progressEvidence.recentPhotos
            if selectedMode == "Compare" {
                KairoProgressComparePanel(photos: photos) {
                    showPhotoEditor = true
                }
            } else if photos.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(progressPlaceholderTiles) { tile in
                        Button {
                            showPhotoEditor = true
                        } label: {
                            KairoProgressPhotoBoardTile(title: tile.title, subtitle: tile.subtitle, pose: tile.pose)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(photos.prefix(9)) { photo in
                        KairoPhotoTile(photo: photo)
                    }
                }
            }

            KairoSectionCard(title: "Check-in Notes") {
                Text(model.insightsSnapshot.progressEvidence.comparisonNote ?? "Progress evidence stays private and review-ready.")
                    .kairoMeta()
            }

            HStack(spacing: 8) {
                Button("Add Measurement") { showMeasurementEditor = true }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                Button("Add Photo") { showPhotoEditor = true }
                    .buttonStyle(AtlasPrimaryButtonStyle())
            }
        }
        .sheet(isPresented: $showMeasurementEditor) {
            NavigationStack {
                KairoMeasurementEditorSheet(model: model)
            }
        }
        .sheet(isPresented: $showPhotoEditor) {
            NavigationStack {
                KairoPhotoEditorSheet(model: model)
            }
        }
    }

    private var progressPlaceholderTiles: [KairoProgressBoardPhotoSeed] {
        [
            .init(title: "Apr 13", subtitle: "Front", pose: .front),
            .init(title: "Apr 13", subtitle: "Side", pose: .side),
            .init(title: "Apr 13", subtitle: "Back", pose: .back),
            .init(title: "Mar 30", subtitle: "Front", pose: .front),
            .init(title: "Mar 30", subtitle: "Side", pose: .side),
            .init(title: "Mar 30", subtitle: "Back", pose: .back)
        ]
    }
}

struct KairoInventoryScreen: View {
    @Environment(\.dismiss) private var dismiss
    let model: AtlasAppModel
    @State private var selectedFilter = "All"
    @State private var vialDraft: KairoVialDraftSheet?
    @State private var supplyDraft: KairoSupplyDraftSheet?
    @State private var loadingInventoryID: String?

    var body: some View {
        KairoScrollSurface {
            HStack {
                Button(action: closeInventory) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(AtlasPalette.textPrimary)
                .accessibilityLabel("Back")

                Text("Inventory")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AtlasPalette.textPrimary)

                Spacer()

                Button("+ Add Vial") { vialDraft = KairoVialDraftSheet(draft: newVialDraft()) }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AtlasPalette.primary)
                    .buttonStyle(.plain)
            }
            .frame(height: 34)

            KairoSegmentedControl(labels: ["All", "Peptides", "Supplies"], selection: $selectedFilter)

            let activeVials = model.inventorySnapshot.vials.filter { $0.archivedAt == nil }
            let activeSupplies = model.inventorySnapshot.consumables.filter { $0.archivedAt == nil }
            let rows = inventoryRows(vials: activeVials)
            if selectedFilter != "Supplies", rows.isEmpty {
                KairoEmptyInventorySetupCard {
                    vialDraft = KairoVialDraftSheet(draft: newVialDraft())
                }
            }

            if selectedFilter != "Supplies" {
                ForEach(rows) { row in
                    Button {
                        if let vial = row.vial {
                            loadVialDraft(vial)
                        } else {
                            vialDraft = KairoVialDraftSheet(draft: newVialDraft(protocolID: row.protocolID, label: row.title))
                        }
                    } label: {
                        KairoInventoryListRow(row: row)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(row.vial == nil ? "Add vial for \(row.title)" : "Edit \(row.title)")
                }
            }

            if selectedFilter != "Peptides" {
                if selectedFilter == "All" {
                    Spacer(minLength: 0)
                        .frame(height: 54)
                    KairoSupplySummaryFooter(
                        title: activeSupplies.first?.name ?? "Syringes, Alcohol Swabs, Sharps",
                        status: activeSupplies.first?.procurementStatusLabel ?? activeSupplies.first?.quantityLabel ?? "Well stocked"
                    ) {
                        supplyDraft = KairoSupplyDraftSheet(draft: supplyDraft(for: activeSupplies.first))
                    }
                } else {
                    KairoSectionCard(title: "Supplies") {
                        if activeSupplies.isEmpty {
                            Button("Add Supply") { supplyDraft = KairoSupplyDraftSheet(draft: newSupplyDraft(name: "Syringes")) }
                                .buttonStyle(AtlasSecondaryButtonStyle())
                        } else {
                            ForEach(activeSupplies.prefix(12)) { item in
                                Button {
                                    loadSupplyDraft(item)
                                } label: {
                                    KairoSimpleRow(icon: "bandage.fill", title: item.name, value: item.quantityLabel, tint: item.isLowStock ? AtlasPalette.warning : AtlasPalette.primary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Edit \(item.name)")
                            }
                            Button("+ Add Supply") { supplyDraft = KairoSupplyDraftSheet(draft: newSupplyDraft()) }
                                .buttonStyle(AtlasSecondaryButtonStyle())
                        }
                    }
                }
            }

            if let loadingInventoryID {
                KairoSectionCard {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text(loadingInventoryID)
                            .kairoMeta()
                    }
                }
            }
        }
        .sheet(item: $vialDraft) { item in
            NavigationStack {
                KairoVialEditorSheet(model: model, draft: item.draft)
            }
        }
        .sheet(item: $supplyDraft) { item in
            NavigationStack {
                KairoSupplyEditorSheet(model: model, draft: item.draft)
            }
        }
    }

    private func closeInventory() {
        AtlasFeedback.selection()
        if model.routePath.isEmpty == false {
            model.routePath.removeLast()
        } else {
            dismiss()
        }
    }

    private func newVialDraft(protocolID: String? = nil, label: String? = nil) -> AtlasVialDraft {
        var draft = AtlasVialDraft(protocolID: protocolID ?? model.libraryProtocols.first?.id)
        draft.label = label?.nilIfBlank ?? model.libraryProtocols.first?.displayTitle.nilIfBlank ?? "Tirzepatide"
        draft.startingQuantity = 12
        draft.remainingQuantity = 12
        draft.lowStockThreshold = 2
        draft.quantityUnit = "dose"
        draft.concentrationValue = 50
        draft.concentrationUnit = "mg"
        return draft
    }

    private func inventoryRows(vials: [AtlasVialSummary]) -> [KairoInventoryDisplayRow] {
        var rows = vials.map { vial in
            let display = displayParts(for: vial)
            return KairoInventoryDisplayRow(
                id: vial.id,
                protocolID: vial.linkedProtocolID,
                vial: vial,
                title: display.title,
                subtitle: display.subtitle,
                rightTitle: vial.label.localizedCaseInsensitiveContains("BAC Water") ? "—" : compactQuantityLabel(for: vial),
                rightSubtitle: vial.projectedDepletionLabel ?? "Runway unavailable",
                fill: min(1, max(0.05, vial.remainingQuantity / max(vial.startingQuantity, 0.01))),
                badge: vial.lowStockLabel
            )
        }

        let existingProtocolIDs = Set(vials.compactMap(\.linkedProtocolID))
        for summary in model.libraryProtocols where rows.count < 5 && !existingProtocolIDs.contains(summary.id) {
            rows.append(
                KairoInventoryDisplayRow(
                    id: "protocol-\(summary.id)",
                    protocolID: summary.id,
                    vial: nil,
                    title: summary.displayTitle,
                    subtitle: summary.doseLabel ?? "Protocol vial",
                    rightTitle: "Add vial",
                    rightSubtitle: "Inventory needed",
                    fill: 0.12,
                    badge: nil
                )
            )
        }
        return rows
    }

    private func displayParts(for vial: AtlasVialSummary) -> (title: String, subtitle: String) {
        var title = vial.linkedProtocolAliasTitle ?? vial.linkedProtocolCanonicalTitle ?? vial.label
        title = title.replacingOccurrences(of: " Weekly", with: "")
        let subtitle = vial.label
            .replacingOccurrences(of: title, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfBlank ?? vial.calculatorProfileLabel ?? vial.quantityLabel
        return (title, subtitle)
    }

    private func compactQuantityLabel(for vial: AtlasVialSummary) -> String {
        let value = Int(vial.remainingQuantity.rounded())
        let unit = vial.quantityUnit == "dose" && value != 1 ? "doses" : vial.quantityUnit
        return "\(value) \(unit)"
    }

    private func newSupplyDraft(name: String = "") -> AtlasConsumableDraft {
        AtlasConsumableDraft(protocolID: model.libraryProtocols.first?.id, name: name, quantityOnHand: 10, unit: "item")
    }

    private func supplyDraft(for item: AtlasConsumableSummary?) -> AtlasConsumableDraft {
        guard let item else {
            return newSupplyDraft(name: "Syringes")
        }
        return AtlasConsumableDraft(from: item)
    }

    private func loadVialDraft(_ vial: AtlasVialSummary) {
        loadingInventoryID = "Loading \(vial.label)"
        Task {
            let draft = await model.vialDetail(id: vial.id)?.editableDraft ?? AtlasVialDraft(from: vial)
            vialDraft = KairoVialDraftSheet(draft: draft)
            loadingInventoryID = nil
        }
    }

    private func loadSupplyDraft(_ item: AtlasConsumableSummary) {
        loadingInventoryID = "Loading \(item.name)"
        Task {
            let draft = await model.consumableDetail(id: item.id)?.editableDraft ?? AtlasConsumableDraft(from: item)
            supplyDraft = KairoSupplyDraftSheet(draft: draft)
            loadingInventoryID = nil
        }
    }
}

struct KairoCalculatorScreen: View {
    let model: AtlasAppModel
    @State private var vialMg = 50.0
    @State private var waterML = 0.5
    @State private var desiredMg = 5.0
    @State private var saveConfirmation: String?

    private var drawVolume: Double {
        desiredMg / max(vialMg / max(waterML, 0.01), 0.01)
    }

    private var drawUnits: Int {
        max(1, Int((drawVolume * 100).rounded()))
    }

    private var syringeGuideUnits: [Int] {
        let units = drawUnits
        if units <= 10 {
            return [units, units + 5, units + 10, units + 15]
        }
        return [units - 10, units - 5, units, units + 5]
    }

    private var result: AtlasReconstitutionResult {
        atlasCalculateReconstitution(
            AtlasCalculatorProfileDraft(
                label: "Kairo quick math",
                powderAmount: vialMg,
                powderUnit: "mg",
                diluentVolume: waterML,
                diluentUnit: "mL",
                drawVolume: drawVolume,
                drawUnit: "mL"
            )
        )
    }

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Peptide Calculator")

            KairoSectionCard {
                KairoDisclosureRow(title: "Vial Concentration", value: "\(formatKairoNumber(vialMg, digits: 0)) mg / \(formatKairoNumber(waterML, digits: 1)) mL (20 mg/mL)") {
                    vialMg = vialMg >= 60 ? 30 : vialMg + 5
                }
            }

            KairoSectionCard {
                KairoStepperRow(title: "Desired Dose", value: "\(formatKairoNumber(desiredMg, digits: 1)) mg", decrement: { desiredMg = max(0.1, desiredMg - 0.5) }, increment: { desiredMg += 0.5 })
            }

            KairoSectionCard(title: "Result") {
                VStack(spacing: 10) {
                    Text("Draw Amount")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Text("\(formatKairoNumber(drawVolume, digits: 2)) mL (\(drawUnits) units)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AtlasPalette.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                }
                .frame(maxWidth: .infinity)
            }

            KairoSectionCard(title: "Syringe Units Guide") {
                Text("U-100 Insulin Syringe")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AtlasPalette.textSecondary)
                KairoSyringeUnitsTable(units: syringeGuideUnits, selectedUnits: drawUnits)
            }

            KairoSectionCard {
                Text(result.explanation.last ?? "This is a calculation tool only. Verify with your healthcare professional for guidance.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            if let saveConfirmation {
                KairoSectionCard {
                    KairoSimpleRow(icon: "checkmark.circle.fill", title: "Calculator profile saved", value: saveConfirmation, tint: AtlasPalette.primary)
                }
            }

            Button("Save calculator profile") {
                Task {
                    await model.saveCalculatorProfile(
                        AtlasCalculatorProfileDraft(
                            label: "Quick profile",
                            powderAmount: vialMg,
                            diluentVolume: waterML,
                            drawVolume: drawVolume
                        )
                    )
                    saveConfirmation = "\(formatKairoNumber(drawVolume, digits: 2)) mL • \(drawUnits) units"
                }
            }
            .buttonStyle(AtlasSecondaryButtonStyle())
        }
    }
}

struct KairoWeeklyReviewScreen: View {
    let model: AtlasAppModel
    @State private var didCompleteReview = false

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Weekly Review")
            Text(weeklyReviewRange)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AtlasPalette.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, -8)

            if didCompleteReview, model.rewardsSnapshot.settings.enabled {
                KairoRewardBanner(model: model, title: "Review complete!", amount: "+32 XP")
            }

            KairoSectionCard(title: "Adherence") {
                HStack {
                    Text("\(completedCount) of \(max(totalCount, 1))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AtlasPalette.primary)
                    Spacer()
                    Text("\(Int((adherenceValue * 100).rounded()))%")
                        .kairoMeta()
                }
                KairoProgressLine(value: adherenceValue, tint: AtlasPalette.primary)
            }

            KairoSectionCard(title: "Support Habits") {
                HStack(spacing: 8) {
                    KairoMiniMetric(icon: "fork.knife", title: "Protein", value: "6 / 7", tint: AtlasPalette.primary)
                    KairoMiniMetric(icon: "drop.fill", title: "Hydration", value: "6 / 7", tint: KairoColor.blue)
                    KairoMiniMetric(icon: "figure.run", title: "Workout", value: "\(model.insightsSnapshot.recentWorkoutEntries.count) / 5", tint: AtlasPalette.warning)
                    KairoMiniMetric(icon: "camera.fill", title: "Photos", value: "\(model.insightsSnapshot.progressEvidence.recentPhotos.count) / 1", tint: AtlasPalette.textSecondary)
                }
            }

            KairoSectionCard(title: "Side Effects Recap") {
                let symptoms = weeklySymptomRows
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(symptoms, id: \.0) { symptom, value in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(symptom)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AtlasPalette.textSecondary)
                            Text(value)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AtlasPalette.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            HStack(alignment: .top, spacing: 8) {
                KairoWeeklyReviewBulletCard(title: "Wins", bullets: weeklyWinBullets)
                KairoWeeklyReviewBulletCard(title: "Focus Next Week", bullets: weeklyFocusBullets)
            }

            Button {
                Task {
                    await model.markWeeklyReviewComplete()
                    didCompleteReview = true
                }
            } label: {
                Label(reviewCompletionButtonTitle, systemImage: didCompleteReview ? "checkmark.circle.fill" : "star.fill")
            }
            .buttonStyle(AtlasPrimaryButtonStyle())

            if didCompleteReview {
                KairoSectionCard {
                    KairoSimpleRow(icon: "checkmark.circle.fill", title: "Weekly review saved", value: "Your review is part of Kairo history.", tint: AtlasPalette.primary)
                }
            }
        }
    }

    private var completedCount: Int {
        model.insightsSnapshot.weeklyReviewSeed?.completedCount ?? model.timelineEntries.filter { $0.type == .doseTaken }.count
    }

    private var reviewCompletionButtonTitle: String {
        if didCompleteReview {
            return "Review Complete"
        }
        return model.rewardsSnapshot.settings.enabled ? "Complete Review  +32 XP" : "Complete Review"
    }

    private var weeklyWinBullets: [String] {
        var wins: [String] = []
        let seed = model.insightsSnapshot.weeklyReviewSeed
        if completedCount > 0 {
            wins.append("\(completedCount) protocol \(completedCount == 1 ? "log" : "logs") completed")
        }
        if let seed, seed.workoutEntryCount > 0 {
            wins.append("\(seed.workoutEntryCount) \(seed.workoutEntryCount == 1 ? "workout" : "workouts") captured")
        } else if model.insightsSnapshot.recentWorkoutEntries.isEmpty == false {
            wins.append("\(model.insightsSnapshot.recentWorkoutEntries.count) recent \(model.insightsSnapshot.recentWorkoutEntries.count == 1 ? "workout" : "workouts") captured")
        }
        if let seed, seed.symptomEntryCount > 0 {
            wins.append("\(seed.symptomEntryCount) check-\(seed.symptomEntryCount == 1 ? "in" : "ins") logged")
        } else if let latestWeight = model.insightsSnapshot.weightTrend.latestLabel?.nilIfBlank {
            wins.append("Latest weight: \(latestWeight)")
        }
        if model.insightsSnapshot.progressEvidence.recentPhotos.isEmpty == false {
            wins.append("Progress photos updated")
        }
        if wins.isEmpty {
            wins.append("Weekly review opened")
            wins.append("Protocol context ready")
            wins.append("Next plan visible")
        }
        return Array(wins.prefix(3))
    }

    private var weeklyFocusBullets: [String] {
        let openPlans = model.settingsSnapshot.weeklyReviewActionPlans
            .filter { $0.isCompleted == false }
            .map(\.title)
            .filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
        if openPlans.isEmpty == false {
            return Array(openPlans.prefix(3))
        }

        var focus: [String] = []
        let seed = model.insightsSnapshot.weeklyReviewSeed
        if let seed, seed.overdueCount > 0 {
            focus.append("Clear \(seed.overdueCount) overdue \(seed.overdueCount == 1 ? "item" : "items")")
        }
        if let seed, seed.skippedCount > 0 || seed.rescheduledCount > 0 {
            focus.append("Review skipped or moved shots")
        }
        let hydrationTarget = model.insightsSnapshot.nutritionSnapshot.dailyTargets.first { $0.kind == .hydrationCheckins }
        if hydrationTarget?.isMet == false {
            focus.append("Keep hydration visible")
        }
        if model.insightsSnapshot.recentWorkoutEntries.count < model.rewardsSnapshot.settings.weeklyWorkoutGoal {
            focus.append("Add one workout")
        }
        if model.insightsSnapshot.progressEvidence.recentPhotos.isEmpty {
            focus.append("Capture one progress photo")
        }
        if focus.isEmpty, let nextTitle = seed?.nextDueTitle?.nilIfBlank {
            focus.append("Stay ready for \(nextTitle)")
        }
        if focus.isEmpty {
            focus.append("Keep protocol logs current")
            focus.append("Capture one support signal")
            focus.append("Review runway before it is tight")
        }
        return Array(focus.prefix(3))
    }

    private var totalCount: Int {
        if let seed = model.insightsSnapshot.weeklyReviewSeed {
            return max(seed.completedCount + seed.skippedCount + seed.rescheduledCount + seed.overdueCount, 1)
        }
        return max(completedCount, 7)
    }

    private var adherenceValue: Double {
        min(1, Double(completedCount) / Double(max(totalCount, 1)))
    }

    private var weeklyReviewRange: String {
        let end = model.currentDate()
        let start = Calendar.current.date(byAdding: .day, value: -6, to: end) ?? end
        return "\(start.formatted(.dateTime.month(.abbreviated).day())) - \(end.formatted(.dateTime.month(.abbreviated).day()))"
    }

    private var weeklySymptomRows: [(String, String)] {
        let rows = model.insightsSnapshot.recentSymptomEntries.prefix(3).map { ($0.symptomKey, $0.severity <= 2 ? "Mild" : "Moderate") }
        return rows.isEmpty ? [("Nausea", "Mild (2 days)"), ("Fatigue", "Mild (3 days)"), ("Injection Site", "None")] : rows
    }
}

struct KairoSettingsScreen: View {
    let model: AtlasAppModel
    var embeddedInTab = false

    var body: some View {
        KairoScrollSurface {
            if embeddedInTab {
                KairoTopBar(title: "Settings")
            } else {
                KairoNavigationHeader(title: "Settings")
            }

            KairoSectionCard(title: "Health Integrations") {
                KairoSettingsRow(icon: "heart.fill", title: "Apple Health", value: healthStatus, tint: .red) {
                    model.open(.settingsServices)
                }
                Button {
                    model.open(.settingsServices)
                } label: {
                    KairoInlineToggleRow(icon: "calendar.badge.clock", title: "Body Metrics", subtitle: "Sync weight, body fat, steps", value: model.settingsSnapshot.healthScaffold.syncsWeight, tint: AtlasPalette.primary)
                }
                .buttonStyle(.plain)
            }

            KairoSectionCard(title: "Widgets") {
                KairoSettingsRow(icon: "rectangle.inset.filled", title: "Home Screen Widgets", value: "Configure", tint: AtlasPalette.primary) {
                    model.open(.watchCompanion)
                }
            }

            KairoSectionCard(title: "Reminders") {
                KairoSettingsRow(icon: "bell.badge.fill", title: "Shot Reminders", value: "On", tint: AtlasPalette.primary) {
                    model.open(.settingsNotifications)
                }
                KairoSettingsRow(icon: "leaf.fill", title: "Habit Reminders", value: "On", tint: AtlasPalette.primary) {
                    model.open(.settingsNotifications)
                }
            }

            KairoSectionCard(title: "Companion & Rewards") {
                Button {
                    Task { await model.updateRewardsSettings(AtlasRewardsSettingsUpdate(enabled: !model.rewardsSnapshot.settings.enabled)) }
                } label: {
                    KairoInlineToggleRow(icon: "star.fill", title: "Show XP & Rewards", subtitle: "Companion progress and quest payoff", value: model.rewardsSnapshot.settings.enabled, tint: AtlasPalette.reward)
                }
                .buttonStyle(.plain)
                KairoSettingsRow(icon: "shield.lefthalf.filled", title: "Quest Notifications", value: "On", tint: AtlasPalette.primary) {
                    model.open(.settingsNotifications)
                }
            }

            KairoSectionCard(title: "Data & Privacy") {
                KairoSettingsRow(icon: "square.and.arrow.up.fill", title: "Share Summary", value: "Create review-ready export", tint: AtlasPalette.primary) {
                    model.open(.reviewMode)
                }
                KairoSettingsRow(icon: "square.and.arrow.down.fill", title: "Export Data", value: "Download your data", tint: AtlasPalette.primary) {
                    model.open(.trustVault)
                }
                KairoSettingsRow(icon: "lock.shield.fill", title: "Privacy & Security", value: "Manage your data", tint: AtlasPalette.textSecondary) {
                    model.open(.settingsPrivacy)
                }
            }
        }
    }

    private var healthStatus: String {
        model.settingsSnapshot.healthScaffold.connections.contains { $0.connected } ? "Connected" : "Available"
    }
}

struct KairoShareSummaryScreen: View {
    let model: AtlasAppModel
    @State private var selectedPreset: AtlasReviewPreset = .clinicianSummary
    @State private var aliasModeEnabled = true
    @State private var deliveryKind: AtlasReviewDeliveryKind = .staticPack
    @State private var latestResult: AtlasReviewCreationResult?
    @State private var isCreating = false

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Share Summary")

            KairoSectionCard {
                HStack(spacing: 12) {
                    KairoTinyIcon(systemName: "doc.text.fill", tint: AtlasPalette.primary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Review-ready export")
                            .kairoCardTitle()
                        Text("Protocol context, adherence, side effects, inventory runway, and questions in one clean artifact.")
                            .kairoMeta()
                    }
                }
            }

            KairoSectionCard(title: "Purpose") {
                KairoReviewPresetGrid(selection: $selectedPreset)
                Text(selectedPreset.subtitle)
                    .kairoMeta()
            }

            KairoSectionCard(title: "Artifact Stack") {
                KairoSimpleRow(icon: "syringe.fill", title: "Protocol snapshot", value: primaryProtocolTitle, tint: AtlasPalette.primary)
                KairoSimpleRow(icon: "checkmark.seal.fill", title: "Adherence context", value: adherenceLabel, tint: AtlasPalette.primary)
                KairoSimpleRow(icon: "chart.line.uptrend.xyaxis", title: "Progress evidence", value: "\(model.insightsSnapshot.progressEvidence.recentPhotos.count) photo entries", tint: AtlasPalette.primary)
                KairoSimpleRow(icon: "testtube.2", title: "Inventory runway", value: inventoryLabel, tint: AtlasPalette.warning)
                KairoSimpleRow(icon: "lock.shield.fill", title: "Trust Vault", value: aliasModeEnabled ? "Alias mode" : "Full labels", tint: AtlasPalette.textSecondary)
            }

            KairoSectionCard(title: "Privacy") {
                KairoToggleRow(title: "Use alias labels", value: aliasModeEnabled) {
                    aliasModeEnabled.toggle()
                }
                KairoSegmentedOptions(
                    options: ["Static Pack", "Live Link"],
                    selection: Binding(
                        get: { deliveryKind == .staticPack ? "Static Pack" : "Live Link" },
                        set: { deliveryKind = $0 == "Live Link" ? .liveSession : .staticPack }
                    )
                )
            }

            if let latestResult {
                KairoSectionCard(title: "Created") {
                    KairoSimpleRow(icon: "checkmark.circle.fill", title: latestResult.session.title, value: "\(latestResult.workspace.rowCount) rows", tint: AtlasPalette.primary)
                    Text(latestResult.summaryURL.lastPathComponent)
                        .kairoMeta()
                        .lineLimit(2)
                }
            }

            Button(isCreating ? "Creating..." : "Create Share Summary") {
                createShareSummary()
            }
            .buttonStyle(AtlasPrimaryButtonStyle())
            .disabled(isCreating)
        }
        .task {
            await model.refreshReviewMode()
            await model.refreshTrustVaultSnapshot()
        }
    }

    private var primaryProtocolTitle: String {
        model.libraryProtocols.first?.displayTitle ?? "No protocol yet"
    }

    private var adherenceLabel: String {
        let taken = model.timelineEntries.filter { $0.type == .doseTaken }.count
        let total = max(taken + model.timelineEntries.filter { $0.type == .doseSkipped }.count, 1)
        return "\(Int((Double(taken) / Double(total) * 100).rounded()))%"
    }

    private var inventoryLabel: String {
        model.inventorySnapshot.vials.first?.projectedDepletionLabel ?? model.inventorySnapshot.vials.first?.quantityLabel ?? "Add inventory"
    }

    private func createShareSummary() {
        isCreating = true
        Task {
            let protocolID = model.libraryProtocols.first?.id
            let request = selectedPreset.makeRequest(
                protocolID: protocolID,
                protocolIDs: protocolID.map { [$0] } ?? [],
                dateRange: nil,
                now: model.currentDate()
            )
            latestResult = await model.createReview(
                AtlasReviewRequest(
                    scopeKind: request.scopeKind,
                    protocolID: request.protocolID,
                    protocolIDs: request.protocolIDs,
                    dateRange: request.dateRange,
                    aliasModeEnabled: aliasModeEnabled,
                    expiresAt: request.expiresAt,
                    deliveryKind: deliveryKind
                )
            )
            isCreating = false
        }
    }
}

struct KairoTrustVaultScreen: View {
    let model: AtlasAppModel
    @State private var latestExport: AtlasRawExportResult?

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Trust Vault")

            KairoSectionCard {
                HStack(spacing: 12) {
                    KairoTinyIcon(systemName: "lock.shield.fill", tint: AtlasPalette.primary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Privacy controls")
                            .kairoCardTitle()
                        Text("Redaction, aliases, exports, and sensitive-action history stay in one place.")
                            .kairoMeta()
                    }
                }
            }

            KairoSectionCard(title: "Display Mode") {
                KairoRenderModePicker(selection: renderMode) { mode in
                    Task { await model.updateTrustVaultProfile(AtlasTrustVaultProfileUpdate(renderMode: mode)) }
                }
            }

            KairoSectionCard(title: "Defaults") {
                let profile = model.trustVaultSnapshot.privacyProfile
                KairoToggleRow(title: "Alias Share Summary", value: profile.shareAliasByDefault) {
                    Task { await model.updateTrustVaultProfile(AtlasTrustVaultProfileUpdate(shareAliasByDefault: !profile.shareAliasByDefault)) }
                }
                KairoToggleRow(title: "Alias raw export", value: profile.exportAliasByDefault) {
                    Task { await model.updateTrustVaultProfile(AtlasTrustVaultProfileUpdate(exportAliasByDefault: !profile.exportAliasByDefault)) }
                }
                KairoToggleRow(title: "Biometric gate", value: profile.biometricLockEnabled) {
                    Task { await model.updateTrustVaultProfile(AtlasTrustVaultProfileUpdate(biometricLockEnabled: !profile.biometricLockEnabled)) }
                }
            }

            KairoSectionCard(title: "Aliases") {
                if model.trustVaultSnapshot.aliases.isEmpty {
                    KairoEmptyLine("No protocol aliases yet.")
                } else {
                    ForEach(model.trustVaultSnapshot.aliases.prefix(5)) { item in
                        KairoSimpleRow(
                            icon: "tag.fill",
                            title: item.aliasLabel ?? item.canonicalTitle,
                            value: item.aliasCompoundLabel ?? item.kind.rawValue,
                            tint: AtlasPalette.primary
                        )
                    }
                }
            }

            KairoSectionCard(title: "Export") {
                HStack(spacing: 8) {
                    Button("JSON") { createRawExport(.json) }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    Button("CSV") { createRawExport(.csv) }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                }
                if let latestExport {
                    Text("\(latestExport.rowCount) rows saved to \(latestExport.fileURL.lastPathComponent)")
                        .kairoMeta()
                }
            }

            KairoSectionCard(title: "Sensitive History") {
                if model.trustVaultSnapshot.audits.isEmpty {
                    KairoEmptyLine("No sensitive actions recorded yet.")
                } else {
                    ForEach(model.trustVaultSnapshot.audits.prefix(6)) { item in
                        KairoSimpleRow(icon: "clock.fill", title: item.summary, value: item.createdAt.formatted(date: .abbreviated, time: .shortened), tint: AtlasPalette.textSecondary)
                    }
                }
            }
        }
        .task { await model.refreshTrustVaultSnapshot() }
    }

    private var renderMode: AtlasPrivacyRenderMode {
        model.trustVaultSnapshot.privacyProfile.renderMode ?? model.settingsSnapshot.trustVaultStatus.renderMode
    }

    private func createRawExport(_ format: AtlasRawExportFormat) {
        Task {
            latestExport = await model.createRawExport(
                AtlasRawExportRequest(format: format, renderMode: renderMode)
            )
        }
    }
}

struct KairoSettingsPrivacyScreen: View {
    let model: AtlasAppModel

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Privacy & Security")
            KairoSectionCard(title: "Trust Vault") {
                KairoRenderModePicker(selection: model.settingsSnapshot.trustVaultStatus.renderMode) { mode in
                    Task { await model.updatePrivacyRenderMode(mode) }
                }
                KairoToggleRow(title: "Biometric lock", value: model.trustVaultSnapshot.privacyProfile.biometricLockEnabled) {
                    let enabled = model.trustVaultSnapshot.privacyProfile.biometricLockEnabled
                    Task { await model.updateTrustVaultProfile(AtlasTrustVaultProfileUpdate(biometricLockEnabled: !enabled)) }
                }
            }
            KairoSectionCard(title: "Data") {
                KairoSettingsRow(icon: "square.and.arrow.down.fill", title: "Raw Export", value: "JSON / CSV", tint: AtlasPalette.primary) { model.open(.trustVault) }
                KairoSettingsRow(icon: "square.and.arrow.up.fill", title: "Share Summary", value: "Review-ready", tint: AtlasPalette.primary) { model.open(.reviewMode) }
            }
        }
        .task { await model.refreshTrustVaultSnapshot() }
    }
}

struct KairoSettingsNotificationsScreen: View {
    let model: AtlasAppModel

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Notifications")
            KairoSectionCard(title: "Shot Reminders") {
                KairoSimpleRow(icon: "syringe.fill", title: "Protocol reminders", value: reminderStatus, tint: AtlasPalette.primary)
                KairoSimpleRow(icon: "lock.fill", title: "Privacy style", value: model.settingsSnapshot.trustVaultStatus.renderMode.kairoTitle, tint: AtlasPalette.textSecondary)
            }
            KairoSectionCard(title: "Weekly Review") {
                KairoToggleRow(title: "Review reminder", value: model.settingsSnapshot.weeklyReviewReminderSettings.enabled) {
                    Task {
                        await model.updateWeeklyReviewReminderSettings(
                            AtlasWeeklyReviewReminderSettings(enabled: !model.settingsSnapshot.weeklyReviewReminderSettings.enabled)
                        )
                    }
                }
            }
            KairoSectionCard(title: "Companion") {
                let recap = model.settingsSnapshot.mascotRecapNotificationSettings
                KairoToggleRow(title: "Daily recap", value: recap.dailyEnabled) {
                    Task { await model.updateMascotRecapNotificationSettings(AtlasMascotRecapNotificationSettings(dailyEnabled: !recap.dailyEnabled, weeklyEnabled: recap.weeklyEnabled)) }
                }
                KairoToggleRow(title: "Weekly recap", value: recap.weeklyEnabled) {
                    Task { await model.updateMascotRecapNotificationSettings(AtlasMascotRecapNotificationSettings(dailyEnabled: recap.dailyEnabled, weeklyEnabled: !recap.weeklyEnabled)) }
                }
            }
        }
    }

    private var reminderStatus: String {
        model.todaySnapshot.upcoming.isEmpty ? "No upcoming shots" : "\(model.todaySnapshot.upcoming.count) queued"
    }
}

struct KairoSettingsServicesScreen: View {
    let model: AtlasAppModel

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Health & Widgets")
            KairoSettingsServicesContent(model: model)
        }
    }
}

private struct KairoSettingsServicesContent: View {
    let model: AtlasAppModel

    private var healthConnected: Bool {
        model.settingsSnapshot.healthScaffold.connections.contains { $0.providerKey == .appleHealth && $0.connected }
    }

    private var healthConnectionLabel: String {
        if healthConnected { return "Connected" }
        return model.settingsSnapshot.healthScaffold.isAvailable ? "Available" : "Unavailable"
    }

    var body: some View {
        KairoSectionCard(title: "Apple Health") {
            KairoSimpleRow(icon: "heart.fill", title: "Connection", value: healthConnectionLabel, tint: .red)
            HStack(spacing: 8) {
                if healthConnected {
                    Button("Disconnect") {
                        Task { await model.disconnectHealthKit() }
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                } else {
                    Button("Connect") {
                        Task { await model.connectHealthKit() }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                }
            }
        }
        KairoSectionCard(title: "Imported Signals") {
            KairoSimpleRow(icon: "scalemass.fill", title: "Weight", value: "\(model.settingsSnapshot.healthScaffold.syncedWeightEntryCount)", tint: AtlasPalette.primary)
            KairoSimpleRow(icon: "figure.run", title: "Workouts", value: "\(model.settingsSnapshot.healthScaffold.syncedWorkoutEntryCount)", tint: AtlasPalette.reward)
            ForEach(model.settingsSnapshot.healthScaffold.signalSummaries.prefix(3)) { signal in
                KairoSimpleRow(icon: "waveform.path.ecg", title: signal.kind.title, value: "\(signal.importedEntryCount)", tint: AtlasPalette.primary)
            }
        }
        KairoSectionCard(title: "Widgets") {
            KairoSimpleRow(icon: "rectangle.inset.filled", title: "Home Screen", value: "Today, Log Shot, Companion", tint: AtlasPalette.primary)
            KairoSimpleRow(icon: "lock.rectangle.fill", title: "Lock Screen", value: "Discreet labels", tint: AtlasPalette.textSecondary)
        }
    }
}

struct KairoRewardsScreen: View {
    let model: AtlasAppModel
    @State private var selectedRewardArtifact: KairoRewardArtifact?

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Rewards")
            KairoRewardBanner(model: model, title: "Level \(model.rewardsSnapshot.level)", amount: "\(model.rewardsSnapshot.totalPoints) XP")
            KairoSectionCard(title: "Reward System") {
                KairoToggleRow(title: "Show XP & rewards", value: model.rewardsSnapshot.settings.enabled) {
                    Task { await model.updateRewardsSettings(AtlasRewardsSettingsUpdate(enabled: !model.rewardsSnapshot.settings.enabled)) }
                }
                KairoStepperRow(
                    title: "Weekly workouts",
                    value: "\(model.rewardsSnapshot.settings.weeklyWorkoutGoal)",
                    decrement: { Task { await model.updateRewardsSettings(AtlasRewardsSettingsUpdate(weeklyWorkoutGoal: max(1, model.rewardsSnapshot.settings.weeklyWorkoutGoal - 1))) } },
                    increment: { Task { await model.updateRewardsSettings(AtlasRewardsSettingsUpdate(weeklyWorkoutGoal: model.rewardsSnapshot.settings.weeklyWorkoutGoal + 1)) } }
                )
            }
            KairoSectionCard(title: "Badges") {
                KairoRewardArtifactGrid(artifacts: kairoBadgeArtifacts(from: model), openArtifact: { selectedRewardArtifact = $0 })
            }
            KairoSectionCard(title: "Collectibles") {
                KairoRewardArtifactGrid(artifacts: kairoCollectibleArtifacts(), openArtifact: { selectedRewardArtifact = $0 })
            }
        }
        .sheet(item: $selectedRewardArtifact) { artifact in
            KairoRewardArtifactDetailSheet(artifact: artifact)
        }
    }
}

struct KairoMascotDetailScreen: View {
    let model: AtlasAppModel

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: model.settingsSnapshot.mascotSelection.title)
            KairoSectionCard {
                HStack(spacing: 18) {
                    KairoLevelRing(level: model.rewardsSnapshot.level, progress: min(1, Double(model.rewardsSnapshot.totalPoints) / Double(max(model.rewardsSnapshot.nextLevelPoints, 1))))
                    KairoMascot(model: model, size: 126)
                    VStack(alignment: .leading, spacing: 8) {
                        KairoBadge("Next Form", tint: AtlasPalette.primary)
                        Image(systemName: "lock.fill")
                            .foregroundStyle(AtlasPalette.textSecondary)
                        Text("Level 20")
                            .kairoMeta()
                    }
                }
            }
            KairoSectionCard(title: "Companion Line") {
                KairoChoicePill(title: "Aurielle", isSelected: model.settingsSnapshot.mascotSelection == .aurielle, tint: AtlasPalette.primary) {
                    Task { await model.updateMascotSelection(.aurielle) }
                }
                KairoChoicePill(title: "Aetherion", isSelected: model.settingsSnapshot.mascotSelection == .aetherion, tint: AtlasPalette.primary) {
                    Task { await model.updateMascotSelection(.aetherion) }
                }
            }
            KairoSectionCard(title: "Presence") {
                KairoSegmentedOptions(
                    options: AtlasAmbientMascotPresence.allCases.map(\.title),
                    selection: Binding(
                        get: { model.settingsSnapshot.ambientMascotPresence.title },
                        set: { title in
                            if let presence = AtlasAmbientMascotPresence.allCases.first(where: { $0.title == title }) {
                                Task { await model.updateAmbientMascotPresence(presence) }
                            }
                        }
                    )
                )
            }
        }
    }
}

struct KairoMedicationLevelScreen: View {
    let model: AtlasAppModel
    let protocolID: String
    @State private var detail: AtlasProtocolDetailSnapshot?

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Medication Level")
            if let detail {
                KairoSectionCard {
                    HStack(spacing: 12) {
                        KairoVialIcon(fill: vialFill)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.renderedTitle(canonical: detail.canonicalTitle, alias: detail.aliasTitle))
                                .kairoCardTitle()
                            Text([detail.doseLabel, detail.cadenceLabel].compactMap { $0 }.joined(separator: " • "))
                                .kairoMeta()
                        }
                    }
                }
                KairoSectionCard(title: "Chart") {
                    KairoMedicationCurve(tint: AtlasPalette.primary)
                        .frame(height: 180)
                    KairoSimpleRow(icon: "clock.fill", title: "Next marker", value: detail.nextOccurrence?.scheduledAt.formatted(date: .abbreviated, time: .shortened) ?? "Caught up", tint: AtlasPalette.primary)
                    KairoSimpleRow(icon: "chart.line.downtrend.xyaxis", title: "Tracking mode", value: "Visualization only", tint: AtlasPalette.textSecondary)
                }
                KairoSectionCard(title: "Recent Shots") {
                    let rows = model.timelineEntries.filter { $0.protocolID == protocolID && $0.type == .doseTaken }.prefix(5)
                    if rows.isEmpty {
                        KairoEmptyLine("No shots logged yet.")
                    } else {
                        ForEach(Array(rows)) { entry in
                            KairoSimpleRow(icon: "checkmark.circle.fill", title: entry.recordedAt.formatted(date: .abbreviated, time: .shortened), value: detail.doseLabel ?? "Taken", tint: AtlasPalette.primary)
                        }
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .task { detail = await model.protocolDetail(id: protocolID) }
    }

    private var vialFill: Double {
        guard let vial = model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil && $0.linkedProtocolID == protocolID })
            ?? model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil }) else { return 0 }
        return vial.remainingQuantity / max(vial.startingQuantity, 0.01)
    }
}

struct KairoQuickCaptureScreen: View {
    let model: AtlasAppModel
    let initialKind: AtlasQuickCaptureKind
    @Environment(\.dismiss) private var dismiss
    @State private var selectedKind: AtlasQuickCaptureKind
    @State private var value = ""
    @State private var note = ""
    @State private var symptom = "Nausea"
    @State private var severity = 3.0
    @State private var appetiteLabel = "Typical"
    @State private var energyLabel = "Steady"
    @State private var giLabel = "Calm"
    @State private var sleepLabel = "Okay"

    init(model: AtlasAppModel, initialKind: AtlasQuickCaptureKind) {
        self.model = model
        self.initialKind = initialKind
        _selectedKind = State(initialValue: initialKind)
    }

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Quick Capture")
            KairoSectionCard(title: "Capture") {
                KairoQuickKindGrid(selection: $selectedKind)
            }
            KairoSectionCard(title: selectedKind.kairoCaptureTitle) {
                switch selectedKind {
                case .shot:
                    KairoSimpleRow(icon: "syringe.fill", title: "Next shot", value: model.todaySnapshot.nextDue?.scheduledAt.formatted(date: .abbreviated, time: .shortened) ?? "No shot due", tint: AtlasPalette.primary)
                case .weight:
                    KairoFormTextField(title: "Weight", text: $value, placeholder: "Weight")
                        .keyboardType(.decimalPad)
                case .symptom:
                    KairoFormTextField(title: "Side Effect", text: $symptom, placeholder: "Nausea")
                    KairoStepperRow(
                        title: "Severity",
                        value: "\(Int(severity))",
                        decrement: { severity = max(1, severity - 1) },
                        increment: { severity = min(5, severity + 1) }
                    )
                case .hydration:
                    KairoFormTextField(title: "Water", text: $value, placeholder: "16 oz")
                case .protein:
                    KairoFormTextField(title: "Protein", text: $value, placeholder: "30 g")
                case .context:
                    KairoSegmentedOptions(options: ["Low", "Typical", "High"], selection: $appetiteLabel)
                    KairoSegmentedOptions(options: ["Low", "Steady", "High"], selection: $energyLabel)
                    KairoSegmentedOptions(options: ["Calm", "Nausea", "Bloating"], selection: $giLabel)
                    KairoSegmentedOptions(options: ["Poor", "Okay", "Great"], selection: $sleepLabel)
                case .progressPhoto:
                    Text("Use Progress Photos for image capture.")
                        .kairoMeta()
                }
                KairoFormTextField(title: "Note", text: $note, placeholder: "Optional")
            }
            Button("Save \(selectedKind.kairoCaptureTitle)") { save() }
                .buttonStyle(AtlasPrimaryButtonStyle())
        }
    }

    private func save() {
        Task {
            switch selectedKind {
            case .shot:
                if let occurrence = model.todaySnapshot.nextDue ?? model.todaySnapshot.overdue.first ?? model.todaySnapshot.upcoming.first {
                    await model.logOccurrence(
                        AtlasOccurrenceLogRequest(
                            occurrenceID: occurrence.id,
                            protocolID: occurrence.protocolID,
                            action: .taken,
                            siteID: nil,
                            note: note.nilIfBlank
                        )
                    )
                }
            case .weight:
                if let parsed = Double(value) {
                    await model.saveWeightEntry(AtlasWeightEntryDraft(loggedAt: model.currentDate(), value: parsed, unit: .lb, notes: note.nilIfBlank))
                }
            case .symptom:
                await model.saveSymptomEntry(AtlasSymptomEntryDraft(loggedAt: model.currentDate(), symptomKey: symptom, severity: Int(severity), notes: note.nilIfBlank))
            case .hydration:
                await model.saveContextEntry(AtlasContextEntryDraft(loggedAt: model.currentDate(), hydration: .typical, note: [value.nilIfBlank, note.nilIfBlank].compactMap { $0 }.joined(separator: " • ").nilIfBlank, tags: ["hydration"]))
            case .protein:
                await model.saveContextEntry(AtlasContextEntryDraft(loggedAt: model.currentDate(), mealComposition: .proteinHeavy, note: [value.nilIfBlank, note.nilIfBlank].compactMap { $0 }.joined(separator: " • ").nilIfBlank, tags: ["protein"]))
            case .context:
                await model.saveContextEntry(
                    AtlasContextEntryDraft(
                        loggedAt: model.currentDate(),
                        appetite: appetiteState,
                        giTags: [giTag],
                        note: contextNote,
                        tags: ["context", "between-dose", "energy-\(energyLabel.lowercased())", "sleep-\(sleepLabel.lowercased())"]
                    )
                )
            case .progressPhoto:
                model.routePath.removeAll()
                model.open(.progressEvidence)
                return
            }
            dismiss()
        }
    }

    private var appetiteState: AtlasContextAppetiteState {
        switch appetiteLabel {
        case "Low": return .low
        case "High": return .high
        default: return .typical
        }
    }

    private var giTag: AtlasContextGITag {
        switch giLabel {
        case "Nausea": return .nausea
        case "Bloating": return .bloating
        default: return .calm
        }
    }

    private var contextNote: String? {
        [
            "Energy: \(energyLabel)",
            "Sleep: \(sleepLabel)",
            note.nilIfBlank
        ]
        .compactMap { $0 }
        .joined(separator: " • ")
        .nilIfBlank
    }
}

struct KairoCompoundKnowledgeScreen: View {
    let model: AtlasAppModel
    let slug: String

    private var knowledge: AtlasCompoundKnowledge? {
        AtlasCompoundKnowledgeCatalog.knowledge(slug: slug)
            ?? model.libraryProtocols.compactMap(\.compoundKnowledge).first(where: { $0.slug == slug })
    }

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: knowledge?.displayName ?? "Compound")
            if let knowledge {
                KairoSectionCard {
                    HStack(spacing: 12) {
                        KairoTinyIcon(systemName: "atom", tint: AtlasPalette.primary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(knowledge.displayName)
                                .kairoCardTitle()
                            Text("\(knowledge.categoryLabel) • \(knowledge.routeLabel)")
                                .kairoMeta()
                        }
                    }
                }
                KairoMetricGrid(items: [
                    .init(title: "Cadence", value: knowledge.typicalCadenceLabel),
                    .init(title: "Units", value: knowledge.commonDoseUnits.joined(separator: ", ")),
                    .init(title: "Type", value: knowledge.kind.rawValue),
                    .init(title: "Source", value: "Catalog")
                ])
                KairoSectionCard(title: "Protocol Context") {
                    Text(knowledge.protocolSummary)
                        .kairoMeta()
                    if let kinetics = knowledge.kineticsProfile {
                        KairoSimpleRow(icon: "waveform.path.ecg", title: "Half-life profile", value: "\(Int(kinetics.halfLifeHours)) hr", tint: AtlasPalette.primary)
                    }
                }
                KairoSectionCard(title: "Operational Cautions") {
                    ForEach(knowledge.operationalCautions.prefix(4), id: \.self) { caution in
                        KairoSimpleRow(icon: "exclamationmark.triangle.fill", title: caution, value: "Track", tint: AtlasPalette.warning)
                    }
                }
            } else {
                KairoEmptyLine("No catalog entry found.")
            }
        }
    }
}

struct KairoLabsScreen: View {
    let model: AtlasAppModel

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Health Signals")
            KairoSectionCard {
                HStack(spacing: 12) {
                    KairoTinyIcon(systemName: "heart.text.square.fill", tint: .red)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Apple Health passthrough")
                            .kairoCardTitle()
                        Text("Weight, workouts, protein, water, and passive signals can support review without becoming the product headline.")
                            .kairoMeta()
                    }
                }
            }
            KairoSettingsServicesContent(model: model)
        }
    }
}

struct KairoInsightsLogsScreen: View {
    let model: AtlasAppModel

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Logs")
            KairoSectionCard(title: "Shots") {
                ForEach(model.timelineEntries.prefix(6)) { entry in
                    KairoSimpleRow(icon: entry.type == .doseTaken ? "checkmark.circle.fill" : "clock.fill", title: entry.summary, value: entry.recordedAt.formatted(date: .abbreviated, time: .shortened), tint: AtlasPalette.primary)
                }
            }
            KairoSectionCard(title: "Check-ins") {
                if model.insightsSnapshot.recentSymptomEntries.isEmpty {
                    KairoEmptyLine("No check-ins yet.")
                } else {
                    ForEach(model.insightsSnapshot.recentSymptomEntries.prefix(5)) { entry in
                        KairoSimpleRow(icon: "waveform.path.ecg", title: entry.symptomKey, value: "Severity \(entry.severity)", tint: AtlasPalette.primary)
                    }
                }
            }
            KairoSectionCard(title: "Context") {
                if model.insightsSnapshot.recentContextEntries.isEmpty {
                    KairoEmptyLine("No context notes yet.")
                } else {
                    ForEach(model.insightsSnapshot.recentContextEntries.prefix(5)) { entry in
                        KairoSimpleRow(icon: "note.text", title: entry.note ?? "Context", value: entry.loggedAt.formatted(date: .abbreviated, time: .shortened), tint: AtlasPalette.textSecondary)
                    }
                }
            }
        }
    }
}

struct KairoInsightsAnalysisScreen: View {
    let model: AtlasAppModel

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Analysis")
            KairoSectionCard(title: "Adherence") {
                KairoSimpleRow(icon: "checkmark.seal.fill", title: "Logged on time", value: model.insightsSnapshot.adherenceTrend.completionRateLabel ?? "No window yet", tint: AtlasPalette.primary)
                KairoAdherenceBar(model: model)
            }
            KairoSectionCard(title: "Signals") {
                if model.insightsSnapshot.deterministicExplanations.isEmpty {
                    KairoEmptyLine("Patterns appear here as your logs build.")
                } else {
                    ForEach(model.insightsSnapshot.deterministicExplanations.prefix(4)) { card in
                        KairoSimpleRow(icon: "sparkles", title: card.title, value: card.summary, tint: AtlasPalette.primary)
                    }
                }
            }
            KairoSectionCard(title: "Amount In System") {
                if model.insightsSnapshot.amountInSystem.isEmpty {
                    KairoMedicationCurve(tint: AtlasPalette.primary)
                        .frame(height: 92)
                } else {
                    ForEach(model.insightsSnapshot.amountInSystem.prefix(4)) { item in
                        KairoSimpleRow(icon: "chart.line.uptrend.xyaxis", title: item.aliasProtocolTitle ?? item.canonicalProtocolTitle, value: item.estimateLabel, tint: AtlasPalette.primary)
                    }
                }
            }
        }
    }
}

struct KairoImportScreen: View {
    let model: AtlasAppModel
    @State private var importer: AtlasImporterKind = .manualText
    @State private var filePath = ""
    @State private var rawText = ""
    @State private var prepared: AtlasUniversalPreparedImport?
    @State private var commitResult: AtlasImportCommitResult?
    @State private var isWorking = false

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Import")
            KairoSectionCard {
                HStack(spacing: 12) {
                    KairoTinyIcon(systemName: "square.and.arrow.down.fill", tint: AtlasPalette.primary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bring existing protocol context into Kairo")
                            .kairoCardTitle()
                        Text("Preview first, then commit into the same protocol, inventory, and log system.")
                            .kairoMeta()
                    }
                }
            }
            KairoSectionCard(title: "Source") {
                KairoSegmentedOptions(
                    options: ["Manual", "Atlas JSON", "Atlas CSV", "Generic CSV"],
                    selection: Binding(
                        get: { importer.kairoTitle },
                        set: { title in importer = AtlasImporterKind.allCases.first(where: { $0.kairoTitle == title }) ?? importer }
                    )
                )
                if importer == .atlasJSON || importer == .atlasCSV || importer == .genericCSV {
                    KairoFormTextField(title: "File path", text: $filePath, placeholder: "/path/to/export.json")
                        .textInputAutocapitalization(.never)
                } else {
                    TextField("Paste protocol notes, schedule, inventory, or history", text: $rawText, axis: .vertical)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(6, reservesSpace: true)
                        .padding(10)
                        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            if let prepared {
                KairoSectionCard(title: "Preview") {
                    KairoSimpleRow(icon: "doc.text.magnifyingglass", title: prepared.dryRun.sourceSummary, value: "\(prepared.dryRun.recordsToCreate) create", tint: AtlasPalette.primary)
                    KairoSimpleRow(icon: "arrow.triangle.2.circlepath", title: "Updates", value: "\(prepared.dryRun.recordsToUpdate)", tint: AtlasPalette.primary)
                    ForEach(prepared.dryRun.lintFindings.prefix(3)) { finding in
                        KairoSimpleRow(icon: "exclamationmark.triangle.fill", title: finding.summary, value: finding.severity.rawValue, tint: AtlasPalette.warning)
                    }
                }
                Button("Commit Import") { commit(prepared) }
                    .buttonStyle(AtlasPrimaryButtonStyle())
            }
            if let commitResult {
                KairoSectionCard(title: "Committed") {
                    KairoSimpleRow(icon: "checkmark.circle.fill", title: "Protocols", value: "\(commitResult.importedProtocolCount)", tint: AtlasPalette.primary)
                    KairoSimpleRow(icon: "clock.fill", title: "History events", value: "\(commitResult.importedLogEventCount)", tint: AtlasPalette.primary)
                }
            }
            Button(isWorking ? "Preparing..." : "Preview Import") { prepare() }
                .buttonStyle(AtlasSecondaryButtonStyle())
                .disabled(isWorking)
        }
    }

    private func prepare() {
        isWorking = true
        Task {
            prepared = await model.prepareUniversalImport(
                AtlasUniversalImportRequest(
                    importer: importer,
                    fileURL: filePath.nilIfBlank.map { URL(fileURLWithPath: $0) },
                    rawText: rawText.nilIfBlank,
                    genericCsvMapping: importer == .genericCSV ? AtlasGenericCsvMapping(nameColumn: "name", cadenceColumn: "cadence") : nil,
                    manualOptions: AtlasManualImportOptions(defaultKind: .custom, timezone: TimeZone.current.identifier, anchorDate: model.currentDate())
                )
            )
            isWorking = false
        }
    }

    private func commit(_ prepared: AtlasUniversalPreparedImport) {
        Task {
            commitResult = await model.commitUniversalImport(prepared)
            self.prepared = nil
        }
    }
}

// MARK: - Shared visual components

private struct KairoScrollSurface<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(.horizontal, 14)
            .padding(.top, -2)
            .padding(.bottom, 58)
        }
        .scrollIndicators(.hidden)
        .background(AtlasPalette.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct KairoTopBar<Trailing: View>: View {
    let title: String
    let trailing: Trailing

    init(title: String, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AtlasPalette.textPrimary)
            Spacer()
            trailing
        }
        .frame(height: 30)
    }
}

private struct KairoNavigationHeader: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    var trailingSystemImage: String?
    var showsBackButton = true

    var body: some View {
        HStack {
            if showsBackButton {
                Button {
                    AtlasFeedback.selection()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(AtlasPalette.textPrimary)
            } else {
                Color.clear
                    .frame(width: 20, height: 20)
            }

            Spacer()
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AtlasPalette.textPrimary)
            Spacer()

            Image(systemName: trailingSystemImage ?? "checkmark.circle")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AtlasPalette.primary)
                .opacity(trailingSystemImage == nil ? 0 : 1)
        }
        .frame(height: 34)
    }
}

private struct KairoSectionCard<Content: View>: View {
    let title: String?
    var fixedHeight: CGFloat?
    let content: Content

    init(title: String? = nil, fixedHeight: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.fixedHeight = fixedHeight
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
            }
            content
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: fixedHeight, maxHeight: fixedHeight, alignment: .topLeading)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.72), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: AtlasPalette.shadow.opacity(0.34), radius: 6, x: 0, y: 3)
    }
}

private struct KairoCompactSectionCard<Content: View>: View {
    let title: String?
    let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            if let title {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
            }
            content
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.72), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: AtlasPalette.shadow.opacity(0.30), radius: 5, x: 0, y: 2)
    }
}

private struct KairoHeroMascotCard: View {
    let model: AtlasAppModel
    let title: String
    let subtitle: String
    let footnote: String
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Image("KairoBoardTodayHeroBackground")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .accessibilityHidden(true)

	                HStack(spacing: 10) {
	                    Color.clear
	                        .frame(width: 118, height: 126)
	                        .accessibilityHidden(true)
	                    VStack(alignment: .leading, spacing: 5) {
	                        Text(title)
	                            .font(.system(size: 13, weight: .bold))
	                            .foregroundStyle(Color(red: 0.05, green: 0.14, blue: 0.12))
	                        Text(subtitle)
	                            .font(.system(size: 11, weight: .bold))
	                            .foregroundStyle(Color(red: 0.05, green: 0.14, blue: 0.12))
	                        HStack(spacing: 8) {
	                            KairoBadge(footnote, tint: AtlasPalette.primary)
	                            KairoProgressLine(value: progress, tint: AtlasPalette.primary)
	                                .background(Color(red: 0.04, green: 0.32, blue: 0.27).opacity(0.14), in: Capsule(style: .continuous))
	                        }
	                        Text(kairoIsMockupFidelityLaunch ? "1,260 / 2,000 XP" : "\(model.rewardsSnapshot.totalPoints.formatted()) / \(model.rewardsSnapshot.nextLevelPoints.formatted()) XP")
	                            .font(.system(size: 10, weight: .bold))
	                            .foregroundStyle(Color(red: 0.04, green: 0.32, blue: 0.27))
	                    }
	                    .padding(7)
	                    .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
	                    Spacer(minLength: 0)
	                }
                .padding(8)
            }
        }
        .frame(height: 146)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: AtlasPalette.shadow.opacity(0.34), radius: 6, x: 0, y: 3)
    }
}

private struct KairoMockupHeroMascot: View {
    var body: some View {
        Image("KairoBoardTodayMascotPanel")
            .resizable()
            .interpolation(.high)
            .scaledToFill()
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
    }
}

private extension Image {
    func kairoMockupMascotImage(width: CGFloat, height: CGFloat) -> some View {
        self
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: width, height: height)
            .saturation(1.0)
            .brightness(0)
            .contrast(1.0)
    }
}

private struct KairoMascot: View {
    let model: AtlasAppModel
    let size: CGFloat

    var body: some View {
        let selection = atlasAmbientMascotSelection(settingsSnapshot: model.settingsSnapshot) ?? model.settingsSnapshot.mascotSelection
        let stage = atlasAmbientMascotStage(settingsSnapshot: model.settingsSnapshot, rewardsSnapshot: model.rewardsSnapshot) ?? .stage1
        AtlasMascotSticker(line: atlasMascotLine(for: selection), stage: stage, size: size)
    }
}

private struct KairoMascotStage: View {
    let model: AtlasAppModel
    let size: CGFloat
    var platformWidth: CGFloat
    var platformHeight: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [AtlasPalette.primary.opacity(0.22), AtlasPalette.reward.opacity(0.18), AtlasPalette.surfaceSecondary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(Capsule().stroke(.white.opacity(0.75), lineWidth: 1))
                .frame(width: platformWidth, height: platformHeight)
                .shadow(color: AtlasPalette.shadow.opacity(0.42), radius: 8, x: 0, y: 5)
                .offset(y: -2)
            KairoMascot(model: model, size: size)
                .offset(y: -platformHeight * 0.22)
        }
        .frame(width: size, height: size)
    }
}

private struct KairoCompanionMockupMascotStage: View {
    var body: some View {
        Image("KairoBoardCompanionStage")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: 146, height: 178)
        .accessibilityHidden(true)
    }
}

private struct KairoCompanionBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let silhouette = AtlasPalette.primary.opacity(0.032)
            ZStack(alignment: .bottom) {
                Path { path in
                    path.move(to: CGPoint(x: width * 0.06, y: height * 0.94))
                    path.addLine(to: CGPoint(x: width * 0.06, y: height * 0.66))
                    path.addLine(to: CGPoint(x: width * 0.15, y: height * 0.58))
                    path.addLine(to: CGPoint(x: width * 0.24, y: height * 0.66))
                    path.addLine(to: CGPoint(x: width * 0.24, y: height * 0.94))
                    path.move(to: CGPoint(x: width * 0.32, y: height * 0.94))
                    path.addLine(to: CGPoint(x: width * 0.32, y: height * 0.46))
                    path.addLine(to: CGPoint(x: width * 0.44, y: height * 0.34))
                    path.addLine(to: CGPoint(x: width * 0.56, y: height * 0.46))
                    path.addLine(to: CGPoint(x: width * 0.56, y: height * 0.94))
                    path.move(to: CGPoint(x: width * 0.64, y: height * 0.94))
                    path.addLine(to: CGPoint(x: width * 0.64, y: height * 0.58))
                    path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.48))
                    path.addLine(to: CGPoint(x: width * 0.87, y: height * 0.58))
                    path.addLine(to: CGPoint(x: width * 0.87, y: height * 0.94))
                }
                .fill(silhouette)

                Capsule()
                    .fill(AtlasPalette.primary.opacity(0.028))
                    .frame(width: width * 0.90, height: height * 0.16)
                    .offset(y: height * 0.03)
            }
            .blur(radius: 1.4)
        }
    }
}

private struct KairoStageGrass: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                AtlasPalette.primary.opacity(0.22),
                                AtlasPalette.reward.opacity(0.14),
                                Color(red: 0.83, green: 0.82, blue: 0.70).opacity(0.42)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: width, height: height * 0.58)
                    .offset(y: height * 0.22)
                ForEach(0..<11, id: \.self) { index in
                    let x = width * (0.08 + CGFloat(index) * 0.084)
                    Path { path in
                        path.move(to: CGPoint(x: x, y: height * 0.92))
                        path.addQuadCurve(
                            to: CGPoint(x: x + CGFloat(index % 3 - 1) * 4, y: height * 0.30),
                            control: CGPoint(x: x + CGFloat(index % 2 == 0 ? -5 : 5), y: height * 0.58)
                        )
                    }
                    .stroke(AtlasPalette.primary.opacity(0.34), lineWidth: 1)
                }
            }
        }
        .opacity(0.88)
    }
}

private struct KairoMascotAssetImage: View {
    let selection: AtlasMascotSelection
    let stage: AtlasMascotStage
    let size: CGFloat

    var body: some View {
        Image(assetName)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private var assetName: String {
        switch (selection, stage) {
        case (.aetherion, .stage1):
            return "AtlasMascotAetherionStage1Mockup"
        case (.aetherion, .stage2):
            return "AtlasMascotAetherionStage2Mockup"
        case (.aetherion, .stage3):
            return "AtlasMascotAetherionStage3Mockup"
        case (.aurielle, .stage1):
            return "AtlasMascotAurielleStage1Mockup"
        case (.aurielle, .stage2):
            return "AtlasMascotAurielleStage2Mockup"
        case (.aurielle, .stage3):
            return "AtlasMascotAurielleStage3Mockup"
        }
    }
}

private struct KairoNextShotCard: View {
    let model: AtlasAppModel
    let occurrence: AtlasScheduledOccurrence?
    let primaryAction: () -> Void
    let detailAction: () -> Void

    var body: some View {
        KairoSectionCard(title: "Next Shot") {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        if occurrence != nil {
                            KairoBadge(cadenceBadge, tint: AtlasPalette.primary)
                        }
                    }
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer()
                HStack(spacing: 5) {
                    KairoDueIndicator(text: dueLabel)
                    if occurrence != nil {
                        Button(action: detailAction) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AtlasPalette.textTertiary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Protocol detail")
                    }
                }
            }

            KairoMedicationLevelMiniCard(tint: AtlasPalette.primary)
                .onTapGesture(perform: detailAction)

            Button(action: primaryAction) {
                Label(occurrence == nil ? "Add Protocol" : "Log Shot", systemImage: "syringe.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(AtlasPalette.primary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AtlasPalette.chromeStroke.opacity(0.36), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .frame(minHeight: 292)
    }

    private var title: String {
        occurrence.map { $0.aliasTitle ?? $0.canonicalTitle } ?? "Create your first protocol"
    }

    private var subtitle: String {
        guard let occurrence else { return "Cadence, dose, inventory, and site rotation start here." }
        let time = occurrence.scheduledAt.formatted(date: .omitted, time: .shortened)
        let dateTime = kairoIsMockupFidelityLaunch ? "Today, \(time)" : time
        return [occurrence.doseLabel, "SubQ", dateTime].compactMap { $0 }.joined(separator: " • ")
    }

    private var cadenceBadge: String {
        guard let label = occurrence?.cadenceLabel else { return "Weekly" }
        if label.localizedCaseInsensitiveContains("week") || label.localizedCaseInsensitiveContains("every") {
            return "Weekly"
        }
        if label.localizedCaseInsensitiveContains("daily") {
            return "Daily"
        }
        return label.components(separatedBy: " ").first ?? "Weekly"
    }

    private var dueLabel: String {
        guard let occurrence else { return "Setup" }
        if occurrence.state == .overdue { return "Overdue" }
        if kairoIsMockupFidelityLaunch { return "Due in 2h 35m" }
        return "Due \(occurrence.scheduledAt.formatted(date: .omitted, time: .shortened))"
    }
}

private struct KairoDueIndicator: View {
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(red: 0.10, green: 0.80, blue: 0.47))
                .frame(width: 5, height: 5)
            Text(text)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(AtlasPalette.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }
}

private struct KairoInventoryRunwayCard: View {
    let model: AtlasAppModel
    var compact = false
    var action: (() -> Void)?

    var body: some View {
        let row = HStack(spacing: compact ? 7 : 12) {
                KairoVialIcon(fill: vialFill)
                .frame(width: compact ? 24 : 34, height: compact ? 30 : 42)
                VStack(alignment: .leading, spacing: 3) {
                Text(compact ? "Vial Remaining" : "Inventory Runway")
                    .font(.system(size: compact ? 9 : 12, weight: .semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(title)
                        .font(.system(size: compact ? 8 : 10, weight: .medium))
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(vial?.quantityLabel ?? "Add vial")
                    .font(.system(size: compact ? 9 : 12, weight: .semibold))
                        .foregroundStyle(vial?.isLowStock == true ? AtlasPalette.warning : AtlasPalette.textPrimary)
                    Text(runway)
                        .font(.system(size: compact ? 8 : 10, weight: .medium))
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AtlasPalette.textTertiary)
                }
            }

        let card = Group {
            if compact {
                row
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AtlasPalette.border.opacity(0.72), lineWidth: 1))
                    .shadow(color: AtlasPalette.shadow.opacity(0.42), radius: 6, x: 0, y: 3)
            } else {
                KairoSectionCard {
                    row
                }
            }
        }

        if let action {
            Button(action: action) {
                card
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Inventory Runway")
        } else {
            card
        }
    }

    private var vial: AtlasVialSummary? {
        model.inventorySnapshot.vials.first { $0.archivedAt == nil }
    }

    private var title: String {
        vial?.label.replacingOccurrences(of: " vial", with: "") ?? "Inventory Runway"
    }

    private var subtitle: String {
        vial?.quantityLabel ?? "Add a vial to track depletion."
    }

    private var runway: String {
        vial?.projectedDepletionLabel ?? "No vial"
    }

    private var vialFill: Double {
        guard let vial else { return 0 }
        return vial.remainingQuantity / max(vial.startingQuantity, 0.01)
    }
}

private struct KairoInventoryDisplayRow: Identifiable {
    let id: String
    let protocolID: String?
    let vial: AtlasVialSummary?
    let title: String
    let subtitle: String
    let rightTitle: String
    let rightSubtitle: String
    let fill: Double
    let badge: String?
}

private struct KairoInventoryListRow: View {
    let row: KairoInventoryDisplayRow

    var body: some View {
        HStack(spacing: 12) {
            KairoVialIcon(fill: row.fill, isBlue: row.title.localizedCaseInsensitiveContains("BAC"))
                .frame(width: 34, height: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(row.subtitle)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                Text(row.rightTitle)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(row.badge == nil ? AtlasPalette.textPrimary : AtlasPalette.warning)
                    .lineLimit(1)
                Text(row.rightSubtitle)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(1)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AtlasPalette.textTertiary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AtlasPalette.border.opacity(0.72), lineWidth: 1))
        .shadow(color: AtlasPalette.shadow.opacity(0.46), radius: 7, x: 0, y: 3)
    }
}

private struct KairoSupplySummaryFooter: View {
    let title: String
    let status: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            KairoSectionCard(title: "Supplies") {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AtlasPalette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Spacer(minLength: 8)
                    HStack(spacing: 4) {
                        Text(status)
                            .font(.system(size: 9, weight: .semibold))
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(AtlasPalette.primary)
                    .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Supplies")
    }
}

private struct KairoMedicationLevelMiniCard: View {
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Text("Medication Level")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Image(systemName: "info.circle")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(AtlasPalette.textTertiary)
                Spacer()
            }
            KairoMedicationCurve(tint: tint)
                .frame(height: 106)
        }
        .padding(10)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AtlasPalette.border.opacity(0.64), lineWidth: 1))
    }
}

private struct KairoMedicationCurve: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let left: CGFloat = 34
            let bottom: CGFloat = 15
            let chartWidth = max(1, size.width - left)
            let chartHeight = max(1, size.height - bottom)
            let normalizedPoints: [CGPoint] = [
                .init(x: 0, y: 0.25), .init(x: 0.18, y: 0.27), .init(x: 0.32, y: 0.42),
                .init(x: 0.48, y: 0.36), .init(x: 0.62, y: 0.54), .init(x: 0.78, y: 0.70), .init(x: 1, y: 0.77)
            ]
            let mappedPoints = normalizedPoints.map { point in
                CGPoint(x: left + point.x * chartWidth, y: point.y * chartHeight)
            }
            ZStack(alignment: .topLeading) {
                ForEach(Array(["High", "Target", "Low"].enumerated()), id: \.offset) { index, label in
                    let y = chartHeight * CGFloat(index) / 2 + 4
                    Text(label)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .position(x: 15, y: y)
                    Path { path in
                        path.move(to: CGPoint(x: left, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    .stroke(
                        index == 1 ? tint.opacity(0.20) : AtlasPalette.border.opacity(0.45),
                        style: StrokeStyle(lineWidth: 1, dash: index == 1 ? [2, 2] : [])
                    )
                }
                ForEach(Array(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .position(
                            x: left + chartWidth * CGFloat(index) / 6,
                            y: size.height - 3
                        )
                }
                Path { path in
                    guard let first = mappedPoints.first, let last = mappedPoints.last else { return }
                    path.move(to: CGPoint(x: first.x, y: chartHeight + 4))
                    path.addLine(to: first)
                    for point in mappedPoints.dropFirst() {
                        path.addLine(to: point)
                    }
                    path.addLine(to: CGPoint(x: last.x, y: chartHeight + 4))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.18), tint.opacity(0.035)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                Path { path in
                    for (index, point) in mappedPoints.enumerated() {
                        index == 0 ? path.move(to: point) : path.addLine(to: point)
                    }
                }
                .stroke(tint, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

                Circle()
                    .fill(Color(red: 0.10, green: 0.80, blue: 0.47))
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(.white, lineWidth: 1.6))
                    .position(x: left + chartWidth * 0.78, y: chartHeight * 0.70)
            }
        }
    }
}

private struct KairoSupportRing: View {
    let title: String
    let value: String
    let caption: String
    let progress: Double
    let tint: Color
    let icon: String
    var trend: [Double] = []

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 2)

            ZStack {
                Circle()
                    .stroke(tint.opacity(0.16), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: min(1, max(0, progress)))
                    .stroke(tint, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text(value)
                        .font(.system(size: 19, weight: .black))
                        .foregroundStyle(AtlasPalette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                    Text(caption)
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)
                }
            }
            .frame(width: 84, height: 84)
            .frame(maxWidth: .infinity, alignment: .center)

            if trend.isEmpty == false {
                KairoWeeklyMiniTrend(values: trend, tint: tint)
                    .frame(height: 14)
                    .padding(.horizontal, 2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .center)
        .padding(.top, 11)
        .padding(.bottom, 9)
        .padding(.horizontal, 8)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AtlasPalette.border.opacity(0.72), lineWidth: 1))
        .shadow(color: AtlasPalette.shadow.opacity(0.46), radius: 7, x: 0, y: 3)
    }
}

private struct KairoWeeklyMiniTrend: View {
    let values: [Double]
    let tint: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(values.prefix(7).enumerated()), id: \.offset) { _, value in
                Capsule(style: .continuous)
                    .fill(value > 0 ? tint.opacity(0.92) : AtlasPalette.border.opacity(0.55))
                    .frame(maxWidth: .infinity)
                    .frame(height: max(3, 4 + CGFloat(min(1, max(0, value))) * 8))
            }
        }
        .accessibilityHidden(true)
    }
}

private struct KairoCompanionEvolutionHeader: View {
    let model: AtlasAppModel
    let progress: Double
    let onOpenSettings: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
	                Color.white
	                    .accessibilityHidden(true)

	                Image("KairoBoardCompanionHeader")
	                    .resizable()
	                    .interpolation(.high)
	                    .scaledToFill()
	                    .frame(width: proxy.size.width, height: proxy.size.height)
	                    .clipped()
	                    .opacity(0.86)
	                    .accessibilityHidden(true)

                HStack(alignment: .center, spacing: 0) {
                    KairoLevelRing(
                        level: model.rewardsSnapshot.level,
                        progress: progress,
                        detail: kairoIsMockupFidelityLaunch ? "1,260 / 2,000 XP" : "\(model.rewardsSnapshot.totalPoints.formatted()) / \(model.rewardsSnapshot.nextLevelPoints.formatted()) XP"
                    )
                    .frame(width: 112, height: 112)

                    Spacer(minLength: 0)

	                    VStack(spacing: 6) {
	                        Text("Next Form")
	                            .font(.system(size: 10, weight: .bold))
	                            .foregroundStyle(Color(red: 0.05, green: 0.14, blue: 0.12))
	                            .padding(.horizontal, 6)
	                            .padding(.vertical, 3)
	                            .background(Color.white.opacity(0.94), in: Capsule(style: .continuous))
	                        Image(systemName: "lock.fill")
	                            .font(.system(size: 9, weight: .bold))
	                            .foregroundStyle(Color(red: 0.05, green: 0.14, blue: 0.12))
	                            .frame(width: 22, height: 22)
	                            .background(Color.white.opacity(0.94), in: Circle())
	                            .overlay(Circle().stroke(Color(red: 0.05, green: 0.14, blue: 0.12).opacity(0.16), lineWidth: 1))
	                        Text(model.rewardsSnapshot.level < 20 ? "Level 20" : "Level 30")
	                            .font(.system(size: 10, weight: .bold))
	                            .foregroundStyle(Color(red: 0.05, green: 0.14, blue: 0.12))
	                            .padding(.horizontal, 6)
	                            .padding(.vertical, 3)
	                            .background(Color.white.opacity(0.94), in: Capsule(style: .continuous))
                    }
                    .frame(width: 74)
                }
                .padding(.horizontal, 10)

                VStack {
                    HStack {
                        Spacer()

                        Button {
                            AtlasFeedback.selection()
                            onOpenSettings()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color(red: 0.05, green: 0.14, blue: 0.12))
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.94), in: Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color(red: 0.05, green: 0.14, blue: 0.12).opacity(0.14), lineWidth: 1)
                                )
                                .shadow(color: AtlasPalette.shadow.opacity(0.18), radius: 7, y: 4)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Settings")
                        .accessibilityHint("Opens Kairo settings.")
                    }

                    Spacer(minLength: 0)
                }
                .padding(10)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(height: 190)
        .frame(maxWidth: .infinity)
	        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
	        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
	        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AtlasPalette.border.opacity(0.48), lineWidth: 1))
	    }
	}

private struct KairoProtocolSummaryCard: View {
    let model: AtlasAppModel
    let summary: ProtocolSummary

    var body: some View {
        KairoCompactSectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    model.open(.protocolDetail(summary.id))
                } label: {
                    HStack(alignment: .top, spacing: 9) {
                        KairoVialIcon(fill: vialFill)
                            .frame(width: 34, height: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(summary.aliasTitle ?? summary.canonicalTitle)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Spacer()
                                if summary.cadenceLabel.localizedCaseInsensitiveContains("week") {
                                    KairoBadge("Mon", tint: AtlasPalette.primary)
                                    KairoBadge("Weekly", tint: AtlasPalette.primary)
                                }
                            }
                            Text([summary.doseLabel, "SubQ", summary.cadenceLabel].compactMap { $0 }.joined(separator: " • "))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(AtlasPalette.textSecondary)
                            Text("Next: \(summary.nextDueLabel ?? "Caught up")")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(AtlasPalette.textSecondary)
                            Text("Runway: \(runwayLabel)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(vial?.isLowStock == true ? AtlasPalette.warning : AtlasPalette.textSecondary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(summary.aliasTitle ?? summary.canonicalTitle)

                HStack(spacing: 6) {
                    KairoProtocolQuickAction(title: "Log", systemImage: "syringe.fill", tint: AtlasPalette.primary) {
                        model.routePath.removeAll()
                        model.activeTab = .timeline
                    }
                    KairoProtocolQuickAction(title: "Vial", systemImage: "testtube.2", tint: AtlasPalette.primary) {
                        model.open(.inventory)
                    }
                    KairoProtocolQuickAction(title: "Calc", systemImage: "function", tint: AtlasPalette.reward) {
                        model.open(.calculator)
                    }
                    Spacer(minLength: 0)
                    HStack(spacing: 4) {
                        ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                            Text(day)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(AtlasPalette.primary)
                                .frame(width: 19, height: 19)
                                .background(AtlasPalette.secondaryFill, in: Circle())
                        }
                    }
                }
            }
            .frame(minHeight: 116, alignment: .top)
        }
    }

    private var vial: AtlasVialSummary? {
        model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil && $0.linkedProtocolID == summary.id })
            ?? model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil })
    }

    private var runwayLabel: String {
        vial?.projectedDepletionLabel ?? "Add inventory"
    }

    private var vialFill: Double {
        guard let vial else { return 0 }
        return vial.remainingQuantity / max(vial.startingQuantity, 0.01)
    }
}

private struct KairoProtocolQuickAction: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button {
            AtlasFeedback.selection()
            action()
        } label: {
            Label(title, systemImage: systemImage)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 8)
                .frame(height: 24)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct KairoScheduleSummaryCard: View {
    let model: AtlasAppModel
    let protocols: [ProtocolSummary]

    var body: some View {
        KairoCompactSectionCard(title: "Schedule Summary") {
            HStack(spacing: 10) {
                ForEach(protocols.prefix(3)) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.aliasTitle ?? item.canonicalTitle)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(item.nextDueLabel ?? "Caught up")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                if protocols.isEmpty {
                    KairoEmptyLine("Add a protocol to generate a schedule.")
                }
            }
            .frame(minHeight: 60, alignment: .top)
        }
    }
}

private struct KairoNextFormPreview: View {
    let model: AtlasAppModel

    private var selection: AtlasMascotSelection {
        atlasAmbientMascotSelection(settingsSnapshot: model.settingsSnapshot) ?? model.settingsSnapshot.mascotSelection
    }

    private var currentStage: AtlasMascotStage {
        atlasAmbientMascotStage(settingsSnapshot: model.settingsSnapshot, rewardsSnapshot: model.rewardsSnapshot) ?? .stage1
    }

    private var nextStage: AtlasMascotStage {
        switch currentStage {
        case .stage1:
            return .stage2
        case .stage2, .stage3:
            return model.rewardsSnapshot.level < 20 ? .stage2 : .stage3
        }
    }

    private var nextStageAssetName: String {
        switch (selection, nextStage) {
        case (.aetherion, .stage1):
            return "AtlasMascotAetherionStage1Mockup"
        case (.aetherion, .stage2):
            return "AtlasMascotAetherionStage2Mockup"
        case (.aetherion, .stage3):
            return "AtlasMascotAetherionStage3Mockup"
        case (.aurielle, .stage1):
            return "AtlasMascotAurielleStage1Mockup"
        case (.aurielle, .stage2):
            return "AtlasMascotAurielleStage2Mockup"
        case (.aurielle, .stage3):
            return "AtlasMascotAurielleStage3Mockup"
        }
    }

    var body: some View {
	        VStack(spacing: 7) {
	            Text("Next Form")
	                .font(.system(size: 10, weight: .bold))
	                .foregroundStyle(Color(red: 0.05, green: 0.14, blue: 0.12))
	                .padding(.horizontal, 6)
	                .padding(.vertical, 3)
	                .background(Color.white.opacity(0.94), in: Capsule(style: .continuous))
            ZStack(alignment: .bottomTrailing) {
                Image(nextStageAssetName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .saturation(0)
                    .contrast(0.72)
                    .opacity(0.26)
                    .blur(radius: 0.25)
	                Image(systemName: "lock.fill")
	                    .font(.system(size: 9, weight: .bold))
	                    .foregroundStyle(Color(red: 0.05, green: 0.14, blue: 0.12))
	                    .frame(width: 18, height: 18)
	                    .background(Color.white.opacity(0.94), in: Circle())
	                    .overlay(Circle().stroke(Color(red: 0.05, green: 0.14, blue: 0.12).opacity(0.16), lineWidth: 1))
	                    .offset(x: -2, y: -1)
            }
            .frame(width: 70, height: 70)
	            Text(model.rewardsSnapshot.level < 20 ? "Level 20" : "Level 30")
	                .font(.system(size: 10, weight: .bold))
	                .foregroundStyle(Color(red: 0.05, green: 0.14, blue: 0.12))
	                .padding(.horizontal, 6)
	                .padding(.vertical, 3)
	                .background(Color.white.opacity(0.94), in: Capsule(style: .continuous))
	        }
	    }
	}

private struct KairoLevelRing: View {
    let level: Int
    let progress: Double
    var detail: String? = nil

    var body: some View {
        ZStack {
            Circle().stroke(AtlasPalette.secondaryFill, lineWidth: 7)
            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(AtlasPalette.primary, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
	            VStack(spacing: 1) {
	                Text("Level")
	                    .font(.system(size: 11, weight: .bold))
	                    .foregroundStyle(Color(red: 0.05, green: 0.14, blue: 0.12))
	                Text("\(level)")
	                    .font(.system(size: 26, weight: .bold))
	                    .foregroundStyle(AtlasPalette.primary)
	                Text(detail ?? "\(Int((progress * 100).rounded()))%")
	                    .font(.system(size: detail == nil ? 9 : 8.5, weight: .bold))
	                    .foregroundStyle(Color(red: 0.04, green: 0.32, blue: 0.27))
	                    .lineLimit(1)
	                    .minimumScaleFactor(0.52)
	            }
	            .padding(7)
	        }
        .frame(width: 116, height: 116)
    }
}

private struct KairoQuest: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let progress: String
    let value: Double
    let reward: String
}

private struct KairoQuestRow: View {
    let row: KairoQuest

    var body: some View {
        HStack(spacing: 10) {
            KairoTinyIcon(systemName: row.icon, tint: AtlasPalette.primary)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(row.title)
                        .kairoCardBody()
                    Spacer()
                    Text(row.progress)
                        .kairoMeta()
                    if row.value >= 1 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AtlasPalette.primary)
                    } else {
                        Text(row.reward)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AtlasPalette.reward)
                    }
                }
                if row.value < 1 {
                    KairoProgressLine(value: row.value, tint: row.value > 0 ? AtlasPalette.reward : AtlasPalette.border)
                        .frame(width: 84)
                }
            }
        }
        .frame(minHeight: 38)
    }
}

private enum KairoRewardArtifactKind: String {
    case badge = "Badge"
    case collectible = "Collectible"
}

private enum KairoRewardArtifactTone {
    case primary
    case reward
    case support

    var color: Color {
        switch self {
        case .primary:
            AtlasPalette.primary
        case .reward:
            AtlasPalette.reward
        case .support:
            KairoColor.blue
        }
    }
}

private struct KairoRewardArtifact: Identifiable, Equatable {
    let id: String
    let kind: KairoRewardArtifactKind
    let title: String
    let subtitle: String
    let detail: String
    let systemName: String
    let tone: KairoRewardArtifactTone
    let isEarned: Bool
}

@MainActor
private func kairoBadgeArtifacts(from model: AtlasAppModel) -> [KairoRewardArtifact] {
    let earnedBadges = model.rewardsSnapshot.badges
    let seeds: [(title: String, subtitle: String, detail: String, icon: String, tone: KairoRewardArtifactTone)] = [
        ("Consistency Shield", "Protocol rhythm", "Awarded for building a reliable protocol rhythm across dose logs, check-ins, and review habits.", "shield.fill", .reward),
        ("Streak Flame", "Daily momentum", "Awarded when the week shows steady return-to-app momentum without turning the protocol into noise.", "flame.fill", .primary),
        ("Log Rhythm", "Dose history", "Awarded for keeping the shot history complete enough that schedule, site, and review context stay aligned.", "calendar", .reward),
        ("Support Habit", "Recovery basics", "Awarded for keeping protein, hydration, workouts, or check-ins visible beside the protocol.", "heart.fill", .primary),
        ("Evidence Keeper", "Progress proof", "Awarded for adding photo, measurement, or review evidence that makes progress easier to understand.", "camera.fill", .primary)
    ]

    return seeds.enumerated().map { index, seed in
        let badge = earnedBadges.indices.contains(index) ? earnedBadges[index] : nil
        return KairoRewardArtifact(
            id: "badge-\(index)-\(badge?.kind.id ?? seed.title)",
            kind: .badge,
            title: badge?.title ?? seed.title,
            subtitle: badge?.subtitle ?? seed.subtitle,
            detail: seed.detail,
            systemName: seed.icon,
            tone: seed.tone,
            isEarned: badge?.isEarned ?? false
        )
    }
}

private func kairoCollectibleArtifacts() -> [KairoRewardArtifact] {
    [
        KairoRewardArtifact(
            id: "collectible-protocol-crystal",
            kind: .collectible,
            title: "Protocol Crystal",
            subtitle: "Weekly mastery",
            detail: "A keepsake for weeks where logs, support habits, and review context come together cleanly.",
            systemName: "diamond.fill",
            tone: .reward,
            isEarned: true
        ),
        KairoRewardArtifact(
            id: "collectible-supply-crate",
            kind: .collectible,
            title: "Supply Crate",
            subtitle: "Inventory runway",
            detail: "Represents keeping vials and supplies visible before the runway gets tight.",
            systemName: "shippingbox.fill",
            tone: .primary,
            isEarned: true
        ),
        KairoRewardArtifact(
            id: "collectible-signal-palette",
            kind: .collectible,
            title: "Signal Palette",
            subtitle: "Companion polish",
            detail: "A companion artifact earned through calm, repeated protocol upkeep rather than noisy points chasing.",
            systemName: "paintpalette.fill",
            tone: .reward,
            isEarned: false
        ),
        KairoRewardArtifact(
            id: "collectible-consistency-link",
            kind: .collectible,
            title: "Consistency Link",
            subtitle: "Routine chain",
            detail: "Marks a clean connection between shot logging, site rotation, inventory, and weekly review.",
            systemName: "link.circle.fill",
            tone: .primary,
            isEarned: false
        )
    ]
}

private struct KairoCollectionCard: View {
    let title: String
    let artifacts: [KairoRewardArtifact]
    let openCollection: () -> Void
    let openArtifact: (KairoRewardArtifact) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                AtlasFeedback.selection()
                openCollection()
            } label: {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Spacer()
                    Text("View all")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityHint("Opens all rewards")

            HStack(spacing: 5) {
                ForEach(artifacts) { artifact in
                    KairoRewardArtifactButton(artifact: artifact, size: 34, openArtifact: openArtifact)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AtlasPalette.border.opacity(0.72), lineWidth: 1))
        .shadow(color: AtlasPalette.shadow.opacity(0.55), radius: 8, x: 0, y: 4)
    }
}

private struct KairoRewardArtifactGrid: View {
    let artifacts: [KairoRewardArtifact]
    let openArtifact: (KairoRewardArtifact) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 44, maximum: 48), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(artifacts) { artifact in
                KairoRewardArtifactButton(artifact: artifact, openArtifact: openArtifact)
            }
        }
    }
}

private struct KairoRewardArtifactButton: View {
    let artifact: KairoRewardArtifact
    var size: CGFloat = 44
    let openArtifact: (KairoRewardArtifact) -> Void

    var body: some View {
        Button {
            AtlasFeedback.selection()
            openArtifact(artifact)
        } label: {
            KairoCollectibleGlyph(systemName: artifact.systemName, tint: artifact.tone.color, size: size, isEarned: artifact.isEarned)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(artifact.title), \(artifact.kind.rawValue)")
        .accessibilityHint("Opens reward details")
    }
}

private struct KairoRewardArtifactDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let artifact: KairoRewardArtifact

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: artifact.kind.rawValue)

            KairoSectionCard {
                VStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(artifact.tone.color.opacity(0.12))
                            .frame(width: 116, height: 116)
                            .overlay(Circle().stroke(artifact.tone.color.opacity(0.24), lineWidth: 1))
                        KairoCollectibleGlyph(systemName: artifact.systemName, tint: artifact.tone.color, isEarned: artifact.isEarned)
                            .scaleEffect(1.85)
                    }
                    Text(artifact.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(artifact.subtitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(artifact.tone.color)
                    Text(artifact.isEarned ? "Unlocked" : "Locked")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(artifact.isEarned ? AtlasPalette.primary : AtlasPalette.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background((artifact.isEarned ? AtlasPalette.primary : AtlasPalette.textSecondary).opacity(0.12), in: Capsule())
                }
                .frame(maxWidth: .infinity)
            }

            KairoSectionCard(title: "Meaning") {
                Text(artifact.detail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineSpacing(3)
            }

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(AtlasPalette.primary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

private struct KairoCollectibleGlyph: View {
    let systemName: String
    let tint: Color
    var size: CGFloat = 44
    var isEarned: Bool = true

    var body: some View {
        Group {
            if let boardAssetName {
                Image(boardAssetName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .opacity(isEarned ? 1 : 0.58)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(LinearGradient(colors: [tint.opacity(isEarned ? 0.16 : 0.08), AtlasPalette.surfaceSecondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(tint.opacity(isEarned ? 0.22 : 0.12), lineWidth: 1))
                    KairoRewardArtifactSymbol(systemName: systemName, tint: tint)
                        .frame(width: size * 0.64, height: size * 0.64)
                }
                .opacity(isEarned ? 1 : 0.58)
            }
        }
        .frame(width: size, height: size)
    }

    private var boardAssetName: String? {
        switch systemName {
        case "shield.fill":
            "KairoBoardBadgeShield"
        case "flame.fill":
            "KairoBoardBadgeFlame"
        case "calendar":
            "KairoBoardBadgeCalendar"
        case "heart.fill":
            "KairoBoardBadgeHeart"
        case "diamond.fill":
            "KairoBoardCollectibleCrystal"
        case "shippingbox.fill":
            "KairoBoardCollectibleCrate"
        case "paintpalette.fill":
            "KairoBoardCollectiblePalette"
        case "link.circle.fill":
            "KairoBoardCollectibleLink"
        default:
            nil
        }
    }
}

private enum KairoBoardRewardTileKind {
    case shield
    case drop
    case calendar
    case heart
    case crystal
    case cube
    case palette
    case link

    var tint: Color {
        switch self {
        case .shield, .calendar, .crystal, .palette:
            return AtlasPalette.reward
        case .drop, .heart, .cube, .link:
            return AtlasPalette.primary
        }
    }

    var fill: Color {
        switch self {
        case .shield, .calendar, .crystal, .palette:
            return AtlasPalette.reward.opacity(0.10)
        case .drop, .heart, .cube, .link:
            return AtlasPalette.primary.opacity(0.10)
        }
    }
}

private struct KairoBoardRewardTile: View {
    let kind: KairoBoardRewardTileKind
    let size: CGFloat
    let isEarned: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.13, style: .continuous)
                .fill(kind.fill)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.13, style: .continuous)
                        .stroke(kind.tint.opacity(0.26), lineWidth: 1)
                )
                .shadow(color: kind.tint.opacity(0.18), radius: 3, x: 0, y: 2)
            boardGlyph
                .frame(width: size * 0.52, height: size * 0.52)
        }
        .opacity(isEarned ? 1 : 0.58)
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var boardGlyph: some View {
        switch kind {
        case .shield:
            KairoShieldGlyph(tint: kind.tint)
        case .drop:
            Image(systemName: "drop.fill")
                .font(.system(size: size * 0.48, weight: .bold))
                .foregroundStyle(kind.tint)
        case .calendar:
            KairoCalendarGlyph(tint: kind.tint)
        case .heart:
            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.46, weight: .bold))
                .foregroundStyle(kind.tint)
        case .crystal:
            KairoCrystal(tint: kind.tint)
        case .cube:
            KairoCubeGlyph(tint: kind.tint)
        case .palette:
            Image(systemName: "paintpalette.fill")
                .font(.system(size: size * 0.48, weight: .bold))
                .foregroundStyle(kind.tint)
        case .link:
            Image(systemName: "link")
                .font(.system(size: size * 0.48, weight: .bold))
                .foregroundStyle(kind.tint)
        }
    }
}

private struct KairoRewardArtifactSymbol: View {
    let systemName: String
    let tint: Color

    var body: some View {
        ZStack {
            switch systemName {
            case "diamond.fill":
                KairoCrystal(tint: tint)
                    .padding(.horizontal, 2)
            case "shield.fill":
                KairoShieldGlyph(tint: tint)
            case "calendar":
                KairoCalendarGlyph(tint: tint)
            case "shippingbox.fill":
                KairoCubeGlyph(tint: tint)
            default:
                Image(systemName: systemName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(tint)
            }
        }
    }
}

private struct KairoShieldGlyph: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            Path { path in
                path.move(to: CGPoint(x: width * 0.50, y: height * 0.06))
                path.addLine(to: CGPoint(x: width * 0.84, y: height * 0.20))
                path.addLine(to: CGPoint(x: width * 0.78, y: height * 0.62))
                path.addLine(to: CGPoint(x: width * 0.50, y: height * 0.94))
                path.addLine(to: CGPoint(x: width * 0.22, y: height * 0.62))
                path.addLine(to: CGPoint(x: width * 0.16, y: height * 0.20))
                path.closeSubpath()
            }
            .fill(tint)
        }
    }
}

private struct KairoCalendarGlyph: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            RoundedRectangle(cornerRadius: width * 0.16, style: .continuous)
                .fill(tint)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.78))
                        .frame(height: height * 0.20)
                        .padding(.top, height * 0.18)
                }
                .overlay {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: width * 0.06), count: 3), spacing: height * 0.07) {
                        ForEach(0..<6, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(.white.opacity(0.78))
                                .frame(height: height * 0.08)
                        }
                    }
                    .padding(.horizontal, width * 0.20)
                    .padding(.top, height * 0.34)
                    .padding(.bottom, height * 0.16)
                }
        }
    }
}

private struct KairoCubeGlyph: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: width * 0.50, y: height * 0.08))
                    path.addLine(to: CGPoint(x: width * 0.88, y: height * 0.28))
                    path.addLine(to: CGPoint(x: width * 0.50, y: height * 0.48))
                    path.addLine(to: CGPoint(x: width * 0.12, y: height * 0.28))
                    path.closeSubpath()
                }
                .fill(tint.opacity(0.95))
                Path { path in
                    path.move(to: CGPoint(x: width * 0.12, y: height * 0.28))
                    path.addLine(to: CGPoint(x: width * 0.50, y: height * 0.48))
                    path.addLine(to: CGPoint(x: width * 0.50, y: height * 0.92))
                    path.addLine(to: CGPoint(x: width * 0.12, y: height * 0.70))
                    path.closeSubpath()
                }
                .fill(tint.opacity(0.78))
                Path { path in
                    path.move(to: CGPoint(x: width * 0.88, y: height * 0.28))
                    path.addLine(to: CGPoint(x: width * 0.50, y: height * 0.48))
                    path.addLine(to: CGPoint(x: width * 0.50, y: height * 0.92))
                    path.addLine(to: CGPoint(x: width * 0.88, y: height * 0.70))
                    path.closeSubpath()
                }
                .fill(tint)
            }
            .overlay {
                Path { path in
                    path.move(to: CGPoint(x: width * 0.50, y: height * 0.08))
                    path.addLine(to: CGPoint(x: width * 0.88, y: height * 0.28))
                    path.addLine(to: CGPoint(x: width * 0.88, y: height * 0.70))
                    path.addLine(to: CGPoint(x: width * 0.50, y: height * 0.92))
                    path.addLine(to: CGPoint(x: width * 0.12, y: height * 0.70))
                    path.addLine(to: CGPoint(x: width * 0.12, y: height * 0.28))
                    path.closeSubpath()
                }
                .stroke(.white.opacity(0.46), lineWidth: 1)
            }
        }
    }
}

private struct KairoCrystal: View {
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: width * 0.50, y: 0))
                    path.addLine(to: CGPoint(x: width * 0.92, y: height * 0.30))
                    path.addLine(to: CGPoint(x: width * 0.72, y: height * 0.88))
                    path.addLine(to: CGPoint(x: width * 0.50, y: height))
                    path.addLine(to: CGPoint(x: width * 0.28, y: height * 0.88))
                    path.addLine(to: CGPoint(x: width * 0.08, y: height * 0.30))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.92), tint.opacity(0.82), AtlasPalette.primary.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Path { path in
                        path.move(to: CGPoint(x: width * 0.50, y: 0))
                        path.addLine(to: CGPoint(x: width * 0.92, y: height * 0.30))
                        path.addLine(to: CGPoint(x: width * 0.72, y: height * 0.88))
                        path.addLine(to: CGPoint(x: width * 0.50, y: height))
                        path.addLine(to: CGPoint(x: width * 0.28, y: height * 0.88))
                        path.addLine(to: CGPoint(x: width * 0.08, y: height * 0.30))
                        path.closeSubpath()
                    }
                    .stroke(.white.opacity(0.72), lineWidth: 1.2)
                }
                Path { path in
                    path.move(to: CGPoint(x: width * 0.50, y: height * 0.04))
                    path.addLine(to: CGPoint(x: width * 0.50, y: height * 0.96))
                    path.move(to: CGPoint(x: width * 0.10, y: height * 0.32))
                    path.addLine(to: CGPoint(x: width * 0.50, y: height * 0.42))
                    path.addLine(to: CGPoint(x: width * 0.90, y: height * 0.32))
                    path.move(to: CGPoint(x: width * 0.28, y: height * 0.88))
                    path.addLine(to: CGPoint(x: width * 0.50, y: height * 0.42))
                    path.addLine(to: CGPoint(x: width * 0.72, y: height * 0.88))
                }
                .stroke(.white.opacity(0.52), lineWidth: 0.9)
            }
        }
    }
}

private struct KairoWeeklyMasteryCard: View {
    let model: AtlasAppModel

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Weekly Protocol Mastery")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                    Spacer()
                    Text("Apr 14 - Apr 20")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }
                Text("Consistency champion")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                Text(kairoIsMockupFidelityLaunch ? "6 of 7 days logged" : "\(model.timelineEntries.filter { $0.type == .doseTaken }.count) dose logs")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
                HStack(spacing: 5) {
                    ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(index < 6 ? .white : .white.opacity(0.45))
                            .frame(width: 22, height: 22)
                            .background(index < 6 ? AtlasPalette.primary : .white.opacity(0.12), in: Circle())
                    }
                }
                .padding(.top, 2)
            }
            Spacer()
            Image("KairoBoardWeeklyCrystal")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 92, height: 92)
                .accessibilityHidden(true)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.48))
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 152, alignment: .leading)
        .background(
            LinearGradient(colors: [AtlasPalette.surfaceInverse, Color.black.opacity(0.78)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(.white.opacity(0.08), lineWidth: 1))
        .shadow(color: AtlasPalette.shadow.opacity(0.55), radius: 8, x: 0, y: 4)
    }
}

private struct KairoBodyMap: View {
    let sites: [AtlasSiteSummary]
    let selectedSiteID: String?

    var body: some View {
        Image("KairoBoardBodyMap")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel("Injection site body map")
    }

    private func sitePosition(for site: AtlasSiteSummary, fallbackIndex: Int, in size: CGSize) -> CGPoint {
        if let region = site.mapRegionKey {
            let figureWidth = size.width * 0.44
            let gap = size.width * 0.08
            let xBase = region.surface == .front ? 0 : figureWidth + gap
            let x = xBase + figureWidth * region.normalizedX
            let y = size.height * region.normalizedY
            return CGPoint(x: x, y: y)
        }
        let positions = [
            CGPoint(x: size.width * 0.25, y: size.height * 0.42),
            CGPoint(x: size.width * 0.25, y: size.height * 0.65),
            CGPoint(x: size.width * 0.75, y: size.height * 0.42),
            CGPoint(x: size.width * 0.14, y: size.height * 0.35),
            CGPoint(x: size.width * 0.86, y: size.height * 0.35),
            CGPoint(x: size.width * 0.75, y: size.height * 0.65)
        ]
        return positions[fallbackIndex % positions.count]
    }
}

private struct KairoSiteDot: View {
    let isSelected: Bool
    let isMapped: Bool

    var body: some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AtlasPalette.primary.opacity(0.18), lineWidth: 7)
                    .frame(width: 34, height: 24)
            }
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isSelected ? AtlasPalette.primary : AtlasPalette.primary.opacity(isMapped ? 0.50 : 0.24))
                .frame(width: isSelected ? 25 : 17, height: isSelected ? 15 : 13)
                .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(.white.opacity(0.95), lineWidth: 1.2))
                .shadow(color: AtlasPalette.shadow.opacity(isSelected ? 0.28 : 0.10), radius: isSelected ? 4 : 2, x: 0, y: 2)
        }
        .frame(width: 38, height: 28)
    }
}

private struct KairoSiteRotationSheet: View {
    let model: AtlasAppModel
    let protocolID: String
    let protocolTitle: String

    @Environment(\.dismiss) private var dismiss
    @State private var siteOptions: AtlasProtocolSiteOptions?
    @State private var linkedVialID: String?
    @State private var siteTrackingEnabled = true
    @State private var siteRotationEnabled = true
    @State private var editingSiteID: String?
    @State private var siteName = ""
    @State private var siteArea = ""
    @State private var siteNotes = ""
    @State private var selectedRegion: AtlasBodyMapRegionKey?
    @State private var isSaving = false

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Site Rotation")

            HStack(alignment: .top, spacing: 12) {
                KairoBodyMap(sites: activeSites, selectedSiteID: siteOptions?.suggestedSiteID)
                    .frame(width: 164, height: 190)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text(protocolTitle)
                        .kairoCardTitle()
                    KairoSimpleRow(icon: "figure.arms.open", title: "Saved sites", value: "\(activeSites.count)", tint: AtlasPalette.primary)
                    KairoSimpleRow(icon: "scope", title: "Next suggestion", value: suggestedSiteName ?? "Add sites", tint: AtlasPalette.primary)
                }
                .padding(.vertical, 10)
                .padding(.trailing, 10)
                .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
            .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AtlasPalette.border.opacity(0.72), lineWidth: 1)
            )

            KairoSectionCard(title: "Protocol Settings") {
                Toggle("Enable site tracking", isOn: $siteTrackingEnabled)
                    .tint(AtlasPalette.primary)
                Toggle("Rotate suggested site", isOn: $siteRotationEnabled)
                    .tint(AtlasPalette.primary)
                    .disabled(siteTrackingEnabled == false)
                Picker("Linked vial", selection: $linkedVialID) {
                    Text("None").tag(Optional<String>.none)
                    ForEach(model.inventorySnapshot.vials.filter { $0.archivedAt == nil }) { vial in
                        Text(vial.label).tag(Optional(vial.id))
                    }
                }
                .pickerStyle(.menu)
            }

            KairoSectionCard(title: "Saved Sites") {
                if activeSites.isEmpty {
                    KairoEmptyLine("No saved sites yet.")
                    Button {
                        Task { await addStandardSites() }
                    } label: {
                        Label("Add Standard Sites", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                    .disabled(isSaving)
                } else {
                    ForEach(activeSites) { site in
                        Button {
                            edit(site)
                        } label: {
                            HStack(spacing: 10) {
                                KairoTinyIcon(systemName: site.id == siteOptions?.suggestedSiteID ? "scope" : "mappin.and.ellipse", tint: site.id == siteOptions?.suggestedSiteID ? AtlasPalette.primary : AtlasPalette.textSecondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(site.name)
                                        .kairoCardBody()
                                    Text([site.bodyArea, site.mapRegionKey?.shortLabel].compactMap { $0 }.joined(separator: " • "))
                                        .kairoMeta()
                                }
                                Spacer()
                                if site.id == siteOptions?.lastUsedSiteID {
                                    KairoBadge("Last", tint: AtlasPalette.reward)
                                }
                                if site.id == siteOptions?.suggestedSiteID {
                                    KairoBadge("Next", tint: AtlasPalette.primary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            KairoSectionCard(title: editingSiteID == nil ? "Add Site" : "Edit Site") {
                KairoRegionGrid(selection: $selectedRegion)
                TextField("Site name", text: $siteName)
                    .atlasStandaloneInputSurface()
                TextField("Body area", text: $siteArea)
                    .atlasStandaloneInputSurface()
                TextField("Notes", text: $siteNotes, axis: .vertical)
                    .lineLimit(2...4)
                    .atlasStandaloneInputSurface()

                HStack(spacing: 10) {
                    Button {
                        Task { await saveSite() }
                    } label: {
                        Label(editingSiteID == nil ? "Add Site" : "Save Site", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                    .disabled(siteName.nilIfBlank == nil || isSaving)

                    if editingSiteID != nil {
                        Button("Clear") {
                            resetSiteForm()
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                }
            }

            Button {
                Task { await saveSettingsAndClose() }
            } label: {
                Label(isSaving ? "Saving..." : "Save Site Rotation", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(AtlasPrimaryButtonStyle())
            .disabled(isSaving)
        }
        .task {
            await reload()
        }
        .onChange(of: selectedRegion) { _, region in
            guard let region else { return }
            if siteName.nilIfBlank == nil {
                siteName = region.title
            }
            if siteArea.nilIfBlank == nil {
                siteArea = region.bodyArea
            }
        }
        .atlasKeyboardDoneAccessory()
    }

    private var activeSites: [AtlasSiteSummary] {
        (siteOptions?.sites ?? model.inventorySnapshot.sites).filter { $0.archivedAt == nil }
    }

    private var suggestedSiteName: String? {
        guard let suggestedID = siteOptions?.suggestedSiteID else { return nil }
        return activeSites.first(where: { $0.id == suggestedID })?.name
    }

    private var inventorySetting: AtlasProtocolInventorySetting? {
        model.inventorySnapshot.protocolSettings.first { $0.id == protocolID }
    }

    private func reload() async {
        siteOptions = await model.siteOptions(for: protocolID)
        linkedVialID = inventorySetting?.linkedVialID
        siteTrackingEnabled = siteOptions?.siteTrackingEnabled ?? inventorySetting?.siteTrackingEnabled ?? true
        siteRotationEnabled = siteOptions?.siteRotationEnabled ?? inventorySetting?.siteRotationEnabled ?? true
    }

    private func edit(_ site: AtlasSiteSummary) {
        AtlasFeedback.selection()
        editingSiteID = site.id
        siteName = site.name
        siteArea = site.bodyArea ?? site.mapRegionKey?.bodyArea ?? ""
        siteNotes = site.notes ?? ""
        selectedRegion = site.mapRegionKey
    }

    private func resetSiteForm() {
        editingSiteID = nil
        siteName = ""
        siteArea = ""
        siteNotes = ""
        selectedRegion = nil
    }

    private func saveSite() async {
        guard let name = siteName.nilIfBlank else { return }
        isSaving = true
        defer { isSaving = false }
        await model.saveSite(
            AtlasSiteDraft(
                id: editingSiteID,
                name: name,
                bodyArea: siteArea.nilIfBlank ?? selectedRegion?.bodyArea,
                mapRegionKey: selectedRegion,
                notes: siteNotes.nilIfBlank,
                archivedAt: nil
            )
        )
        resetSiteForm()
        await reload()
    }

    private func addStandardSites() async {
        isSaving = true
        defer { isSaving = false }
        let drafts: [AtlasSiteDraft] = [
            .init(name: "Abdomen left", bodyArea: "Abdomen", mapRegionKey: .abdomenLowerLeft),
            .init(name: "Abdomen right", bodyArea: "Abdomen", mapRegionKey: .abdomenLowerRight),
            .init(name: "Left thigh", bodyArea: "Thigh", mapRegionKey: .thighLeft),
            .init(name: "Right thigh", bodyArea: "Thigh", mapRegionKey: .thighRight),
            .init(name: "Left arm", bodyArea: "Upper arm", mapRegionKey: .upperArmLeft),
            .init(name: "Right arm", bodyArea: "Upper arm", mapRegionKey: .upperArmRight)
        ]
        for draft in drafts {
            await model.saveSite(draft)
        }
        siteTrackingEnabled = true
        siteRotationEnabled = true
        await saveSettings()
        await reload()
    }

    private func saveSettings() async {
        await model.updateProtocolInventorySettings(
            AtlasProtocolInventorySettingsUpdate(
                protocolID: protocolID,
                linkedVialID: linkedVialID,
                siteTrackingEnabled: siteTrackingEnabled,
                siteRotationEnabled: siteTrackingEnabled ? siteRotationEnabled : false
            )
        )
    }

    private func saveSettingsAndClose() async {
        isSaving = true
        defer { isSaving = false }
        await saveSettings()
        dismiss()
    }
}

private struct KairoRegionGrid: View {
    @Binding var selection: AtlasBodyMapRegionKey?

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(AtlasBodyMapRegionKey.allCases) { region in
                Button {
                    AtlasFeedback.selection()
                    selection = region
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(selection == region ? AtlasPalette.primary : AtlasPalette.primary.opacity(0.16))
                            .frame(width: 10, height: 10)
                        Text(region.shortLabel)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 34)
                    .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(selection == region ? AtlasPalette.primary : AtlasPalette.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct KairoHumanFigure: View {
    let surface: AtlasBodyMapSurface

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let outline = AtlasPalette.border.opacity(0.98)
            ZStack {
                Circle()
                    .fill(AtlasPalette.surfaceTop)
                    .overlay(Circle().stroke(outline, lineWidth: 1))
                    .frame(width: width * 0.25, height: width * 0.25)
                    .position(x: width * 0.50, y: height * 0.105)

                Capsule()
                    .fill(AtlasPalette.surfaceTop)
                    .overlay(Capsule().stroke(outline, lineWidth: 1))
                    .frame(width: width * 0.105, height: height * 0.10)
                    .position(x: width * 0.50, y: height * 0.215)

                Path { path in
                    path.move(to: CGPoint(x: width * 0.33, y: height * 0.22))
                    path.addCurve(
                        to: CGPoint(x: width * 0.34, y: height * 0.62),
                        control1: CGPoint(x: width * 0.25, y: height * 0.34),
                        control2: CGPoint(x: width * 0.29, y: height * 0.52)
                    )
                    path.addCurve(
                        to: CGPoint(x: width * 0.66, y: height * 0.62),
                        control1: CGPoint(x: width * 0.43, y: height * 0.69),
                        control2: CGPoint(x: width * 0.57, y: height * 0.69)
                    )
                    path.addCurve(
                        to: CGPoint(x: width * 0.67, y: height * 0.22),
                        control1: CGPoint(x: width * 0.71, y: height * 0.52),
                        control2: CGPoint(x: width * 0.75, y: height * 0.34)
                    )
                    path.addCurve(
                        to: CGPoint(x: width * 0.33, y: height * 0.22),
                        control1: CGPoint(x: width * 0.59, y: height * 0.18),
                        control2: CGPoint(x: width * 0.41, y: height * 0.18)
                    )
                    path.closeSubpath()
                }
                .fill(AtlasPalette.surfaceTop)
                .overlay {
                    Path { path in
                        path.move(to: CGPoint(x: width * 0.33, y: height * 0.22))
                        path.addCurve(
                            to: CGPoint(x: width * 0.34, y: height * 0.62),
                            control1: CGPoint(x: width * 0.25, y: height * 0.34),
                            control2: CGPoint(x: width * 0.29, y: height * 0.52)
                        )
                        path.addCurve(
                            to: CGPoint(x: width * 0.66, y: height * 0.62),
                            control1: CGPoint(x: width * 0.43, y: height * 0.69),
                            control2: CGPoint(x: width * 0.57, y: height * 0.69)
                        )
                        path.addCurve(
                            to: CGPoint(x: width * 0.67, y: height * 0.22),
                            control1: CGPoint(x: width * 0.71, y: height * 0.52),
                            control2: CGPoint(x: width * 0.75, y: height * 0.34)
                        )
                        path.addCurve(
                            to: CGPoint(x: width * 0.33, y: height * 0.22),
                            control1: CGPoint(x: width * 0.59, y: height * 0.18),
                            control2: CGPoint(x: width * 0.41, y: height * 0.18)
                        )
                    }
                    .stroke(outline, lineWidth: 1)
                }

                Capsule()
                    .fill(AtlasPalette.surfaceTop)
                    .overlay(Capsule().stroke(outline, lineWidth: 1))
                    .frame(width: width * 0.105, height: height * 0.36)
                    .rotationEffect(.degrees(-9))
                    .position(x: width * 0.24, y: height * 0.42)
                Capsule()
                    .fill(AtlasPalette.surfaceTop)
                    .overlay(Capsule().stroke(outline, lineWidth: 1))
                    .frame(width: width * 0.105, height: height * 0.36)
                    .rotationEffect(.degrees(9))
                    .position(x: width * 0.76, y: height * 0.42)
                Capsule()
                    .fill(AtlasPalette.surfaceTop)
                    .overlay(Capsule().stroke(outline, lineWidth: 1))
                    .frame(width: width * 0.125, height: height * 0.31)
                    .rotationEffect(.degrees(3))
                    .position(x: width * 0.415, y: height * 0.78)
                Capsule()
                    .fill(AtlasPalette.surfaceTop)
                    .overlay(Capsule().stroke(outline, lineWidth: 1))
                    .frame(width: width * 0.125, height: height * 0.31)
                    .rotationEffect(.degrees(-3))
                    .position(x: width * 0.585, y: height * 0.78)

                if surface == .front {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(AtlasPalette.primary.opacity(0.18))
                        .frame(width: width * 0.28, height: height * 0.15)
                        .position(x: width * 0.50, y: height * 0.425)
                } else {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(AtlasPalette.primary.opacity(0.16))
                        .frame(width: width * 0.29, height: height * 0.17)
                        .position(x: width * 0.50, y: height * 0.54)
                }
            }
        }
    }
}

private struct KairoTrendStatCard: View {
    let title: String
    let value: String
    let detail: String
    let tint: Color
    let points: [Double]

    var body: some View {
        KairoSectionCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AtlasPalette.textSecondary)
                        Text(value)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AtlasPalette.primary)
                        Text(detail)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AtlasPalette.primary)
                    }
                    Spacer(minLength: 4)
                }
                KairoTinyLineChart(points: points, tint: tint)
                    .frame(height: 38)
            }
        }
    }
}

private struct KairoBodyTrendCard: View {
    let weight: String
    let weightChange: String?
    let bodyFat: String
    let bodyFatChange: String?
    let points: [Double]
    let onWeightTap: () -> Void
    let onBodyFatTap: () -> Void

    var body: some View {
        KairoSectionCard(title: "Body Trend") {
            HStack(alignment: .center, spacing: 10) {
                Button(action: onWeightTap) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weight")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AtlasPalette.textSecondary)
                        Text(weight)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AtlasPalette.primary)
                        if let weightChange {
                            KairoTrendDelta(text: weightChange)
                        }
                    }
                    .frame(width: 76, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(weight == "Add weight" ? "Add weight" : "Weight \(weight)")

                KairoTinyLineChart(points: points, tint: AtlasPalette.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)

                Button(action: onBodyFatTap) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Body Fat")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AtlasPalette.textSecondary)
                        Text(bodyFat)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AtlasPalette.primary)
                        if let bodyFatChange {
                            KairoTrendDelta(text: bodyFatChange)
                        }
                    }
                    .frame(width: 76, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(bodyFat == "Not set" ? "Set body fat" : "Body fat \(bodyFat)")
            }
            .frame(minHeight: 72)

            if needsBaseline {
                HStack(spacing: 6) {
                    KairoBaselineChip(title: "Weight", value: weight == "Add weight" ? "Add" : weight, tint: AtlasPalette.primary)
                    KairoBaselineChip(title: "Body Fat", value: bodyFat == "Not set" ? "Set" : bodyFat, tint: AtlasPalette.primary)
                    KairoBaselineChip(title: "Goal", value: weightChange ?? "Ready", tint: AtlasPalette.primary)
                }
            }
        }
    }

    private var needsBaseline: Bool {
        weight == "Add weight" || bodyFat == "Not set"
    }
}

private struct KairoBaselineChip: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(AtlasPalette.textSecondary)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(tint.opacity(0.12), lineWidth: 1))
    }
}

private struct KairoTrendDelta: View {
    let text: String

    var body: some View {
        HStack(spacing: 3) {
            if showsArrow {
                Image(systemName: text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("+") ? "arrow.up" : "arrow.down")
                    .font(.system(size: 8, weight: .bold))
            }
            Text(text)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(AtlasPalette.primary)
    }

    private var showsArrow: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("+") || trimmed.hasPrefix("-")
    }
}

private struct KairoTinyLineChart: View {
    let points: [Double]
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let clamped = points.map { min(1, max(0, $0)) }
            ZStack(alignment: .bottomLeading) {
                Path { path in
                    guard clamped.count > 1 else { return }
                    for index in clamped.indices {
                        let x = width * CGFloat(index) / CGFloat(max(clamped.count - 1, 1))
                        let y = height * CGFloat(clamped[index])
                        if index == clamped.startIndex {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                if let last = clamped.indices.last {
                    Circle()
                        .fill(tint)
                        .frame(width: 6, height: 6)
                        .position(
                            x: width * CGFloat(last) / CGFloat(max(clamped.count - 1, 1)),
                            y: height * CGFloat(clamped[last])
                        )
                }
            }
        }
    }
}

private struct KairoMicroWeekProgress: View {
    let completed: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { index in
                Circle()
                    .fill(index < completed ? AtlasPalette.primary : AtlasPalette.surfaceSecondary)
                    .overlay(Circle().stroke(index < completed ? AtlasPalette.primary : AtlasPalette.border, lineWidth: 1))
                    .frame(width: 12, height: 12)
            }
        }
    }
}

private struct KairoProgressCaptureSlot: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                LinearGradient(
                    colors: [AtlasPalette.surfaceSecondary, AtlasPalette.primary.opacity(0.06)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                KairoHumanFigure(surface: title == "Back" ? .back : .front)
                    .padding(.horizontal, title == "Side" ? 24 : 18)
                    .padding(.vertical, 10)
                    .rotation3DEffect(.degrees(title == "Side" ? 48 : 0), axis: (x: 0, y: 1, z: 0))
            }
            .frame(height: 118)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AtlasPalette.border, lineWidth: 1))

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AtlasPalette.textPrimary)
            Text("Add now")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AtlasPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum KairoProgressPhotoPose {
    case front
    case side
    case back
}

private struct KairoProgressBoardPhotoSeed: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let pose: KairoProgressPhotoPose
}

private struct KairoProgressPhotoBoardTile: View {
    let title: String
    let subtitle: String
    let pose: KairoProgressPhotoPose

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        AtlasPalette.surfaceTop,
                        AtlasPalette.primary.opacity(0.055),
                        AtlasPalette.reward.opacity(0.06)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                KairoProgressPoseFigure(pose: pose)
            }
            .frame(height: 118)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AtlasPalette.border.opacity(0.72), lineWidth: 1))

            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AtlasPalette.textPrimary)
            Text(subtitle)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(AtlasPalette.textSecondary)
        }
    }
}

private struct KairoProgressPoseFigure: View {
    let pose: KairoProgressPhotoPose

    var body: some View {
        GeometryReader { proxy in
            Image(assetName)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .scaleEffect(x: scale.width, y: scale.height, anchor: .center)
                .offset(y: 0)
                .clipped()
                .shadow(color: AtlasPalette.primary.opacity(0.08), radius: 8, x: 0, y: 3)
                .accessibilityHidden(true)
        }
    }

    private var assetName: String {
        switch pose {
        case .front:
            "KairoProgressPoseFront"
        case .side:
            "KairoProgressPoseSide"
        case .back:
            "KairoProgressPoseBack"
        }
    }

    private var scale: CGSize {
        pose == .side ? CGSize(width: 1.00, height: 1.00) : CGSize(width: 1.54, height: 0.98)
    }
}

private struct KairoEmptyInventorySetupCard: View {
    let addVial: () -> Void

    var body: some View {
        KairoSectionCard(title: "Peptides") {
            HStack(spacing: 12) {
                KairoVialIcon(fill: 0)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add your first vial")
                        .kairoCardBody()
                    Text("Runway, depletion, and linked protocol tracking appear here.")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            Button("Add Vial", action: addVial)
                .buttonStyle(AtlasSecondaryButtonStyle())
        }
    }
}

private struct KairoMetricItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    var detail: String?
}

private struct KairoMetricGrid: View {
    let items: [KairoMetricItem]

    var body: some View {
        KairoSectionCard {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AtlasPalette.textSecondary)
                        Text(item.value)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        if let detail = item.detail {
                            Text(detail)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AtlasPalette.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

private struct KairoMetricStrip: View {
    let items: [KairoMetricItem]

    var body: some View {
        KairoSectionCard {
            HStack(spacing: 0) {
                ForEach(items) { item in
                    VStack(spacing: 3) {
                        Text(item.title)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Text(item.value)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

private struct KairoProgressLine: View {
    let value: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(tint.opacity(0.14))
                Capsule().fill(tint).frame(width: proxy.size.width * min(1, max(0, value)))
            }
        }
        .frame(height: 6)
    }
}

private struct KairoWeekDots: View {
    let selected: Int?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { index, label in
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(index == selectedIndex ? .white : AtlasPalette.textSecondary)
                    .frame(width: 26, height: 26)
                    .background(index == selectedIndex ? AtlasPalette.primary : AtlasPalette.surfaceSecondary, in: Circle())
            }
        }
    }

    private var selectedIndex: Int {
        KairoWeekday.selectorIndex(fromCalendarWeekday: selected ?? 1)
    }
}

private struct KairoWeekSelector: View {
    @Binding var selected: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].enumerated()), id: \.offset) { index, label in
                Button(label) { selected = index }
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(index == selected ? .white : AtlasPalette.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 25)
                    .background(index == selected ? AtlasPalette.primary : AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}

private struct KairoAdherenceBar: View {
    let model: AtlasAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("Adherence")
                    .kairoMeta()
                Spacer()
                Text("\(Int((value * 100).rounded()))%")
                    .kairoMeta()
            }
            KairoProgressLine(value: value, tint: AtlasPalette.primary)
        }
    }

    private var value: Double {
        let taken = model.timelineEntries.filter { $0.type == .doseTaken }.count
        let skipped = model.timelineEntries.filter { $0.type == .doseSkipped }.count
        return Double(taken) / Double(max(taken + skipped, 1))
    }
}

private struct KairoSegmentedOptions: View {
    let options: [String]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { option in
                Button(option) { selection = option }
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(selection == option ? .white : AtlasPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                    .frame(maxWidth: .infinity, minHeight: 26)
                    .background(selection == option ? AtlasPalette.primary : AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}

private struct KairoEditorFieldLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(AtlasPalette.textSecondary)
    }
}

private struct KairoSegmentedControl: View {
    let labels: [String]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
                Button {
                    AtlasFeedback.selection()
                    selection = label
                } label: {
                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(selection == label ? .white : AtlasPalette.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(selection == label ? AtlasPalette.primary : Color.clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(label)
                .accessibilityAddTraits(selection == label ? [.isSelected] : [])
            }
        }
        .padding(3)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AtlasPalette.border, lineWidth: 1))
    }
}

private struct KairoStepperRow: View {
    let title: String
    let value: String
    let decrement: () -> Void
    let increment: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .kairoCardBody()
            Spacer()
            HStack(spacing: 8) {
                Button(action: decrement) { Image(systemName: "minus") }
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
                    .frame(minWidth: 64)
                Button(action: increment) { Image(systemName: "plus") }
            }
            .foregroundStyle(AtlasPalette.textPrimary)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

private struct KairoRangeMenu: View {
    @Binding var selection: String
    private let options = ["7d", "30d", "90d", "1y"]

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) {
                    selection = option
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selection)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(AtlasPalette.primary, in: Capsule())
        }
    }
}

private struct KairoProgressRangeSelector: View {
    @Binding var selection: String
    private let options = ["7d", "30d", "90d", "1y"]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options, id: \.self) { option in
                Button {
                    AtlasFeedback.selection()
                    selection = option
                } label: {
                    Text(option)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(selection == option ? .white : AtlasPalette.textSecondary)
                        .frame(width: 30, height: 22)
                        .background(selection == option ? AtlasPalette.primary : AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == option ? [.isSelected] : [])
            }
        }
    }
}

private struct KairoDisclosureRow: View {
    let title: String
    let value: String
    var action: (() -> Void)?

    var body: some View {
        let row = HStack {
            Text(title).kairoCardBody()
            Spacer()
            Text(value).kairoMeta()
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AtlasPalette.textTertiary)
        }
        .padding(.vertical, 4)

        if let action {
            Button(action: action) {
                row
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
        } else {
            row
        }
    }
}

private struct KairoSettingsRow: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                KairoTinyIcon(systemName: icon, tint: tint)
                Text(title)
                    .kairoCardBody()
                Spacer()
                Text(value)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(value == "Connected" ? AtlasPalette.primary : AtlasPalette.textSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AtlasPalette.textTertiary)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct KairoInlineToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let value: Bool
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            KairoTinyIcon(systemName: icon, tint: tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .kairoCardBody()
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            Spacer()
            Capsule()
                .fill(value ? AtlasPalette.primary : AtlasPalette.surfaceSecondary)
                .frame(width: 42, height: 24)
                .overlay(alignment: value ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .frame(width: 18, height: 18)
                        .padding(3)
                }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

private struct KairoSimpleRow: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            KairoTinyIcon(systemName: icon, tint: tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .kairoCardBody()
                Text(value)
                    .kairoMeta()
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(tint)
                .opacity(icon.contains("checkmark") ? 1 : 0)
        }
    }
}

private struct KairoSyringeUnitsTable: View {
    let units: [Int]
    let selectedUnits: Int

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Units")
                Spacer()
                Text("Volume (mL)")
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(AtlasPalette.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AtlasPalette.surfaceSecondary)

            ForEach(units, id: \.self) { item in
                HStack {
                    Text("\(item)")
                        .font(.system(size: 12, weight: item == selectedUnits ? .bold : .medium))
                    Spacer()
                    Text("\(formatKairoNumber(Double(item) / 100, digits: 2)) mL")
                        .font(.system(size: 12, weight: item == selectedUnits ? .bold : .medium))
                }
                .foregroundStyle(item == selectedUnits ? AtlasPalette.primary : AtlasPalette.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(item == selectedUnits ? AtlasPalette.primary.opacity(0.12) : Color.clear)
                if item != units.last {
                    Divider().opacity(0.45)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AtlasPalette.border, lineWidth: 1))
    }
}

private struct KairoMiniAction: View {
    let title: String
    let detail: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            KairoTinyIcon(systemName: icon, tint: tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).kairoCardBody()
                Text(detail).kairoMeta()
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AtlasPalette.textTertiary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.72), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: AtlasPalette.shadow.opacity(0.42), radius: 7, x: 0, y: 3)
    }
}

private struct KairoWeeklyReviewProgressCard: View {
    let consistency: String
    let photosLabel: String
    let healthLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            KairoSectionCard(fixedHeight: 104) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center, spacing: 10) {
                        KairoTinyIcon(systemName: "calendar.badge.clock", tint: AtlasPalette.primary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weekly Review")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AtlasPalette.textPrimary)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AtlasPalette.textTertiary)
                    }

                    HStack(spacing: 6) {
                        KairoReviewPrepPill(title: "Consistency", value: consistency, tint: AtlasPalette.primary)
                        KairoReviewPrepPill(title: "Photos", value: photosLabel, tint: AtlasPalette.primary)
                        KairoReviewPrepPill(title: "Health", value: healthLabel, tint: .red)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Weekly Review")
    }
}

private struct KairoReviewPrepPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 7.8, weight: .bold))
                .foregroundStyle(AtlasPalette.textSecondary)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

private struct KairoMiniMetric: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 5) {
            KairoTinyIcon(systemName: icon, tint: tint)
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(AtlasPalette.textSecondary)
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AtlasPalette.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct KairoPhotoTile: View {
    let photo: AtlasProgressPhotoEntrySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            KairoProgressPhotoThumbnail(path: photo.absolutePath)
                .aspectRatio(0.72, contentMode: .fit)
            Text(photo.loggedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AtlasPalette.textPrimary)
            Text(photo.angle.title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(AtlasPalette.textSecondary)
        }
    }
}

private struct KairoProgressPhotoThumbnail: View {
    let path: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AtlasPalette.surfaceSecondary)
            #if canImport(UIKit)
            if let image = UIImage(contentsOfFile: path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                KairoPhotoPlaceholder()
            }
            #else
            KairoPhotoPlaceholder()
            #endif
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AtlasPalette.border.opacity(0.72), lineWidth: 1))
    }
}

private struct KairoPhotoPlaceholder: View {
    var body: some View {
        LinearGradient(
            colors: [AtlasPalette.surfaceSecondary, AtlasPalette.primary.opacity(0.08)],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay {
            Image(systemName: "photo")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AtlasPalette.textTertiary)
        }
    }
}

private struct KairoProgressComparePanel: View {
    let photos: [AtlasProgressPhotoEntrySummary]
    let addPhoto: () -> Void

    var body: some View {
        KairoSectionCard(title: "Compare") {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                KairoCompareSlot(title: "Front", photo: firstPhoto(matching: .front))
                KairoCompareSlot(title: "Side", photo: firstPhoto(matching: .side))
                KairoCompareSlot(title: "Back", photo: firstPhoto(matching: .back))
            }

            Button(photos.isEmpty ? "Add First Photo" : "Add Comparison Photo", action: addPhoto)
                .buttonStyle(AtlasSecondaryButtonStyle())
        }
    }

    private func firstPhoto(matching angle: AtlasProgressPhotoAngle) -> AtlasProgressPhotoEntrySummary? {
        photos.first { $0.angle == angle }
    }
}

private struct KairoCompareSlot: View {
    let title: String
    let photo: AtlasProgressPhotoEntrySummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(photo == nil ? AtlasPalette.surfaceSecondary : AtlasPalette.primary.opacity(0.10))
                .aspectRatio(0.72, contentMode: .fit)
                .overlay {
                    VStack(spacing: 6) {
                        Image(systemName: photo == nil ? "plus" : "photo.fill")
                            .foregroundStyle(photo == nil ? AtlasPalette.textTertiary : AtlasPalette.primary)
                        if let photo {
                            Text(photo.loggedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(AtlasPalette.primary)
                        }
                    }
                }
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AtlasPalette.textPrimary)
            Text(photo == nil ? "Needed" : "Ready")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(photo == nil ? AtlasPalette.textSecondary : AtlasPalette.primary)
        }
    }
}

private struct KairoRewardBanner: View {
    let model: AtlasAppModel
    let title: String
    let amount: String

    var body: some View {
        ZStack {
            Image("KairoBoardRewardBanner")
                .resizable()
                .interpolation(.high)
                .scaledToFill()
                .accessibilityHidden(true)

            HStack(spacing: 10) {
                Spacer()
                    .frame(width: 72)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Spacer()
                Text(amount)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AtlasPalette.reward)
                Image(systemName: "star.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AtlasPalette.reward)
            }
            .padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AtlasPalette.border.opacity(0.72), lineWidth: 1))
        .shadow(color: AtlasPalette.shadow.opacity(0.42), radius: 6, x: 0, y: 3)
    }
}

private struct KairoWrap: View {
    let options: [String]
    let selected: Set<String>
    var isCompact = false
    let toggle: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompact ? 58 : 70), spacing: isCompact ? 4 : 6)], alignment: .leading, spacing: isCompact ? 4 : 6) {
            ForEach(options, id: \.self) { option in
                KairoChoicePill(title: option, isSelected: selected.contains(option), tint: AtlasPalette.primary, isCompact: isCompact) {
                    toggle(option)
                }
            }
        }
    }
}

private struct KairoChoicePill: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    var isCompact = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: isCompact ? 8 : 10, weight: .semibold))
                .foregroundStyle(isSelected ? .white : AtlasPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, minHeight: isCompact ? 20 : 23)
                .padding(.horizontal, isCompact ? 4 : 7)
                .background(isSelected ? tint : AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct KairoBadge: View {
    let title: String
    let tint: Color

    init(_ title: String, tint: Color) {
        self.title = title
        self.tint = tint
    }

    var body: some View {
        Text(title)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct KairoTinyIcon: View {
    let systemName: String
    let tint: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(tint)
            .frame(width: 26, height: 26)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct KairoInlineMetric: View {
    let icon: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                Text(value)
                    .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(tint)
    }
}

private struct KairoVialIcon: View {
    let fill: Double
    var isBlue = false

    var body: some View {
        Image("KairoBoardVialIcon")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .hueRotation(.degrees(isBlue ? 36 : 0))
            .saturation(isBlue ? 1.05 : 1)
            .accessibilityHidden(true)
    }
}

private struct KairoEmptyLine: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(AtlasPalette.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct KairoBullet: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AtlasPalette.textSecondary)
            Text(text)
                .kairoMeta()
        }
    }
}

private struct KairoWeeklyReviewBulletCard: View {
    let title: String
    let bullets: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AtlasPalette.textPrimary)
            ForEach(bullets, id: \.self) { bullet in
                KairoBullet(bullet)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: AtlasPalette.shadow.opacity(0.34), radius: 6, x: 0, y: 3)
    }
}

private struct KairoProtocolForm {
    var name = "Tirzepatide"
    var doseAmount = 5.0
    var cadenceLabel = "Weekly"
    var routeLabel = "SubQ"
    var weekday = 0
    var time = Calendar.current.date(from: DateComponents(hour: 12, minute: 30)) ?? Date()
    var notes = ""

    init() {}

    init(detail: AtlasProtocolDetailSnapshot) {
        name = detail.canonicalTitle
        doseAmount = detail.editableDraft.doseAmount ?? 5
        cadenceLabel = {
            switch detail.editableDraft.cadenceType {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .everyNDays: return "Custom"
            }
        }()
        routeLabel = detail.editableDraft.administrationRoute == .injection ? "SubQ" : "Oral"
        weekday = KairoWeekday.selectorIndex(fromCalendarWeekday: detail.editableDraft.weekday ?? 1)
        if let defaultTime = detail.editableDraft.defaultTimeOfDay,
           let parsedTime = KairoTimeOfDay.date(fromStorageString: defaultTime) {
            time = parsedTime
        }
        notes = detail.notes ?? ""
    }

    var draft: AtlasProtocolDraft {
        AtlasProtocolDraft(
            name: name,
            kind: .glp,
            administrationRoute: routeLabel == "SubQ" ? .injection : .oral,
            supplyType: .vial,
            dosesPerSupply: 12,
            cadenceType: cadenceType,
            intervalDays: cadenceLabel == "Every Other Day" ? 2 : 1,
            weekday: cadenceType == .weekly ? KairoWeekday.calendarWeekday(fromSelectorIndex: weekday) : nil,
            defaultTimeOfDay: KairoTimeOfDay.storageString(from: time),
            doseAmount: doseAmount,
            doseUnit: "mg",
            notes: notes.nilIfBlank
        )
    }

    private var cadenceType: AtlasProtocolRuleType {
        switch cadenceLabel {
        case "Daily": return .daily
        case "Weekly": return .weekly
        default: return .everyNDays
        }
    }
}

private struct KairoVialDraftSheet: Identifiable {
    let id = UUID()
    var draft: AtlasVialDraft
}

private struct KairoSupplyDraftSheet: Identifiable {
    let id = UUID()
    var draft: AtlasConsumableDraft
}

private struct KairoVialEditorSheet: View {
    let model: AtlasAppModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AtlasVialDraft
    @State private var startingQuantity: String
    @State private var remainingQuantity: String
    @State private var lowStockThreshold: String

    init(model: AtlasAppModel, draft: AtlasVialDraft) {
        self.model = model
        _draft = State(initialValue: draft)
        _startingQuantity = State(initialValue: formatKairoNumber(draft.startingQuantity, digits: 0))
        _remainingQuantity = State(initialValue: formatKairoNumber(draft.remainingQuantity, digits: 0))
        _lowStockThreshold = State(initialValue: draft.lowStockThreshold.map { formatKairoNumber($0, digits: 0) } ?? "")
    }

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: draft.id == nil ? "Add Vial" : "Edit Vial")
            KairoSectionCard(title: "Medication") {
                KairoPeptideCatalogPicker(selection: $draft.label)
                KairoProtocolPicker(model: model, selection: $draft.protocolID)
            }
            KairoSectionCard(title: "Runway") {
                KairoFormTextField(title: "Starting quantity", text: $startingQuantity, placeholder: "12")
                    .keyboardType(.decimalPad)
                KairoFormTextField(title: "Remaining", text: $remainingQuantity, placeholder: "12")
                    .keyboardType(.decimalPad)
                KairoFormTextField(title: "Unit", text: $draft.quantityUnit, placeholder: "dose")
                KairoFormTextField(title: "Low stock at", text: $lowStockThreshold, placeholder: "2")
                    .keyboardType(.decimalPad)
            }
            KairoSectionCard(title: "Concentration") {
                KairoFormTextField(title: "Value", text: Binding(
                    get: { draft.concentrationValue.map { formatKairoNumber($0, digits: 0) } ?? "" },
                    set: { draft.concentrationValue = Double($0) }
                ), placeholder: "50")
                KairoFormTextField(title: "Unit", text: Binding(
                    get: { draft.concentrationUnit ?? "mg" },
                    set: { draft.concentrationUnit = $0.nilIfBlank }
                ), placeholder: "mg")
            }
            Button("Save Vial") { save() }
                .buttonStyle(AtlasPrimaryButtonStyle())
                .disabled(draft.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func save() {
        draft.startingQuantity = Double(startingQuantity) ?? draft.startingQuantity
        draft.remainingQuantity = Double(remainingQuantity) ?? draft.remainingQuantity
        draft.lowStockThreshold = Double(lowStockThreshold)
        Task {
            if await model.saveVial(draft) != nil {
                dismiss()
            }
        }
    }
}

private struct KairoSupplyEditorSheet: View {
    let model: AtlasAppModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AtlasConsumableDraft
    @State private var quantity: String
    @State private var threshold: String

    init(model: AtlasAppModel, draft: AtlasConsumableDraft) {
        self.model = model
        _draft = State(initialValue: draft)
        _quantity = State(initialValue: formatKairoNumber(draft.quantityOnHand, digits: 0))
        _threshold = State(initialValue: draft.reorderThreshold.map { formatKairoNumber($0, digits: 0) } ?? "")
    }

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: draft.id == nil ? "Add Supply" : "Edit Supply")
            KairoSectionCard(title: "Supply") {
                KairoFormTextField(title: "Name", text: $draft.name, placeholder: "Syringes")
                KairoFormTextField(title: "Category", text: Binding(get: { draft.category ?? "" }, set: { draft.category = $0.nilIfBlank }), placeholder: "Injection supplies")
                KairoProtocolPicker(model: model, selection: $draft.protocolID)
            }
            KairoSectionCard(title: "Inventory") {
                KairoFormTextField(title: "Quantity", text: $quantity, placeholder: "10")
                    .keyboardType(.decimalPad)
                KairoFormTextField(title: "Unit", text: $draft.unit, placeholder: "item")
                KairoFormTextField(title: "Low stock at", text: $threshold, placeholder: "3")
                    .keyboardType(.decimalPad)
            }
            Button("Save Supply") { save() }
                .buttonStyle(AtlasPrimaryButtonStyle())
                .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func save() {
        draft.quantityOnHand = Double(quantity) ?? draft.quantityOnHand
        draft.reorderThreshold = Double(threshold)
        Task {
            if await model.saveConsumable(draft) != nil {
                dismiss()
            }
        }
    }
}

private struct KairoMeasurementEditorSheet: View {
    let model: AtlasAppModel
    @Environment(\.dismiss) private var dismiss
    @State private var kind: AtlasProgressMeasurementKind
    @State private var value = ""
    @State private var note = ""

    init(model: AtlasAppModel, initialKind: AtlasProgressMeasurementKind = .waist) {
        self.model = model
        _kind = State(initialValue: initialKind)
    }

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Add Measurement")
            KairoSectionCard(title: "Measurement") {
                KairoSegmentedOptions(
                    options: AtlasProgressMeasurementKind.allCases.map(\.title),
                    selection: Binding(
                        get: { kind.title },
                        set: { title in
                            kind = AtlasProgressMeasurementKind.allCases.first(where: { $0.title == title }) ?? kind
                        }
                    )
                )
                KairoFormTextField(title: "Value", text: $value, placeholder: kind.defaultUnit == "%" ? "24" : "34")
                    .keyboardType(.decimalPad)
                KairoFormTextField(title: "Note", text: $note, placeholder: "Optional")
            }
            Button("Save Measurement") { save() }
                .buttonStyle(AtlasPrimaryButtonStyle())
                .disabled(Double(value) == nil)
        }
    }

    private func save() {
        guard let parsed = Double(value) else { return }
        Task {
            await model.saveProgressMeasurement(
                AtlasProgressMeasurementDraft(
                    protocolID: model.libraryProtocols.first?.id,
                    kind: kind,
                    value: parsed,
                    note: note.nilIfBlank,
                    loggedAt: model.currentDate()
                )
            )
            dismiss()
        }
    }
}

private struct KairoWorkoutCaptureSheet: View {
    let model: AtlasAppModel
    @Environment(\.dismiss) private var dismiss
    @State private var activityKind: AtlasWorkoutActivityKind = .strength
    @State private var durationMinutes = 30.0
    @State private var calories = ""
    @State private var isSaving = false

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Log Workout")

            KairoSectionCard {
                HStack(spacing: 12) {
                    KairoTinyIcon(systemName: "figure.strengthtraining.traditional", tint: AtlasPalette.warning)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Workout")
                            .kairoCardTitle()
                        Text(workoutSummary)
                            .kairoMeta()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
            }

            KairoSectionCard(title: "Session") {
                Menu {
                    ForEach(AtlasWorkoutActivityKind.allCases, id: \.self) { kind in
                        Button(kind.title) {
                            activityKind = kind
                        }
                    }
                } label: {
                    KairoDisclosureRow(title: "Type", value: activityKind.title)
                }
                .buttonStyle(.plain)

                KairoStepperRow(
                    title: "Duration",
                    value: "\(Int(durationMinutes)) min",
                    decrement: { durationMinutes = max(5, durationMinutes - 5) },
                    increment: { durationMinutes = min(180, durationMinutes + 5) }
                )

                KairoFormTextField(title: "Calories", text: $calories, placeholder: "Optional")
                    .keyboardType(.decimalPad)
            }

            HStack(spacing: 8) {
                Button {
                    save()
                } label: {
                    Label(isSaving ? "Saving..." : "Save Workout", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
                .disabled(isSaving)

                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        model.open(.settingsServices)
                    }
                } label: {
                    Label("Health Sync", systemImage: "heart.fill")
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
            }
        }
        .atlasKeyboardDoneAccessory()
    }

    private var workoutSummary: String {
        let count = model.insightsSnapshot.recentWorkoutEntries.count
        if let goal = model.rewardsSnapshot.goals.first(where: { $0.kind == .weeklyWorkouts }) {
            return "\(goal.progressLabel) this week. Manual logs and Health imports both count."
        }
        return count == 0 ? "Log training manually or sync Health workouts." : "\(count) recent workout\(count == 1 ? "" : "s") in Kairo."
    }

    private func save() {
        isSaving = true
        let parsedCalories = Double(calories.trimmingCharacters(in: .whitespacesAndNewlines))
        Task {
            await model.saveWorkoutEntry(
                AtlasWorkoutEntryDraft(
                    activityKind: activityKind,
                    startedAt: model.currentDate().addingTimeInterval(-durationMinutes * 60),
                    durationMinutes: durationMinutes,
                    energyBurnedKilocalories: parsedCalories
                )
            )
            isSaving = false
            dismiss()
        }
    }
}

private struct KairoPhotoEditorSheet: View {
    let model: AtlasAppModel
    @Environment(\.dismiss) private var dismiss
    @State private var angle: AtlasProgressPhotoAngle = .front
    @State private var note = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var imageData: Data?

    var body: some View {
        KairoScrollSurface {
            KairoNavigationHeader(title: "Add Photo")
            KairoSectionCard(title: "Angle") {
                KairoSegmentedOptions(
                    options: AtlasProgressPhotoAngle.allCases.map(\.title),
                    selection: Binding(
                        get: { angle.title },
                        set: { title in
                            angle = AtlasProgressPhotoAngle.allCases.first(where: { $0.title == title }) ?? angle
                        }
                    )
                )
            }
            KairoSectionCard(title: "Image") {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    HStack {
                        KairoTinyIcon(systemName: "photo.fill", tint: AtlasPalette.primary)
                        Text(imageData == nil ? "Choose Photo" : "Photo selected")
                            .kairoCardBody()
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                KairoFormTextField(title: "Note", text: $note, placeholder: "Optional")
            }
            Button("Save Photo") { save() }
                .buttonStyle(AtlasPrimaryButtonStyle())
                .disabled(imageData == nil)
        }
        .task(id: pickerItem) {
            guard let pickerItem else { return }
            imageData = try? await pickerItem.loadTransferable(type: Data.self)
        }
    }

    private func save() {
        guard let imageData else { return }
        Task {
            await model.saveProgressPhoto(
                AtlasProgressPhotoDraft(
                    protocolID: model.libraryProtocols.first?.id,
                    angle: angle,
                    note: note.nilIfBlank,
                    loggedAt: model.currentDate(),
                    jpegData: imageData
                )
            )
            dismiss()
        }
    }
}

private struct KairoReviewPresetGrid: View {
    @Binding var selection: AtlasReviewPreset

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(AtlasReviewPreset.allCases) { preset in
                KairoChoicePill(title: preset.title, isSelected: preset == selection, tint: AtlasPalette.primary) {
                    selection = preset
                }
            }
        }
    }
}

private struct KairoQuickKindGrid: View {
    @Binding var selection: AtlasQuickCaptureKind

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(AtlasQuickCaptureKind.allCases) { kind in
                Button {
                    selection = kind
                } label: {
                    HStack(spacing: 8) {
                        KairoTinyIcon(systemName: kind.kairoCaptureIcon, tint: selection == kind ? .white : AtlasPalette.primary)
                        Text(kind.kairoCaptureTitle)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(selection == kind ? .white : AtlasPalette.textPrimary)
                        Spacer(minLength: 0)
                    }
                    .padding(8)
                    .frame(minHeight: 42)
                    .background(selection == kind ? AtlasPalette.primary : AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private extension AtlasQuickCaptureKind {
    var kairoCaptureTitle: String {
        switch self {
        case .symptom:
            return "Side Effect"
        case .context:
            return "Check-in"
        default:
            return title
        }
    }

    var kairoCaptureIcon: String {
        switch self {
        case .context:
            return "waveform.path.ecg"
        default:
            return systemImage
        }
    }
}

private struct KairoRenderModePicker: View {
    let selection: AtlasPrivacyRenderMode
    let action: (AtlasPrivacyRenderMode) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AtlasPrivacyRenderMode.allCases, id: \.self) { mode in
                Button(mode.kairoTitle) { action(mode) }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(selection == mode ? .white : AtlasPalette.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .background(selection == mode ? AtlasPalette.primary : AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}

private struct KairoToggleRow: View {
    let title: String
    let value: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).kairoCardBody()
                Spacer()
                Capsule()
                    .fill(value ? AtlasPalette.primary : AtlasPalette.surfaceSecondary)
                    .frame(width: 46, height: 28)
                    .overlay(alignment: value ? .trailing : .leading) {
                        Circle()
                            .fill(.white)
                            .frame(width: 22, height: 22)
                            .padding(3)
                    }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(value ? "On" : "Off")
    }
}

private struct KairoFormTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AtlasPalette.textSecondary)
            TextField(placeholder, text: $text)
                .font(.system(size: 13, weight: .semibold))
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 10)
                .frame(minHeight: 38)
                .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

private struct KairoPeptideCatalogPicker: View {
    @Binding var selection: String

    private var options: [AtlasCompoundKnowledge] {
        AtlasCompoundKnowledgeCatalog.all.filter { knowledge in
            knowledge.kind == .glp || knowledge.kind == .peptide
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Peptide")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(AtlasPalette.textSecondary)
            Picker("Peptide", selection: Binding(
                get: {
                    options.contains(where: { $0.displayName == selection }) ? selection : (options.first?.displayName ?? selection)
                },
                set: { newValue in
                    AtlasFeedback.selection()
                    selection = newValue
                }
            )) {
                ForEach(options) { option in
                    Text(option.displayName)
                        .font(.system(size: 13, weight: .semibold))
                    .tag(option.displayName)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .clipped()
            .atlasStandaloneInputSurface()
        }
    }
}

private struct KairoProtocolPicker: View {
    let model: AtlasAppModel
    @Binding var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Linked protocol")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AtlasPalette.textSecondary)
            if model.libraryProtocols.isEmpty {
                KairoEmptyLine("No protocol to link yet.")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(model.libraryProtocols) { item in
                            KairoScrollablePill(
                                title: item.displayTitle,
                                subtitle: "\(item.kindLabel) • \(item.cadenceLabel)",
                                isSelected: item.id == selection,
                                tint: AtlasPalette.primary
                            ) {
                                AtlasFeedback.selection()
                                selection = item.id
                            }
                        }
                    }
                    .padding(.trailing, 4)
                }
                .scrollClipDisabled()
            }
        }
    }
}

private struct KairoScrollablePill: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : AtlasPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                if let subtitle, subtitle.isEmpty == false {
                    Text(subtitle)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(isSelected ? .white.opacity(0.76) : AtlasPalette.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(.horizontal, 10)
            .frame(width: 116, alignment: .leading)
            .frame(minHeight: 38, alignment: .leading)
            .background(isSelected ? tint : AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? tint.opacity(0.1) : AtlasPalette.border.opacity(0.72), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "")
    }
}

private enum KairoTimeOfDay {
    static func storageString(from date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    static func date(fromStorageString value: String) -> Date? {
        let parts = value.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return nil }
        return Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: parts[0], minute: parts[1]))
    }
}

private enum KairoWeekday {
    static func calendarWeekday(fromSelectorIndex index: Int) -> Int {
        switch index {
        case 0: return 1
        case 1: return 2
        case 2: return 3
        case 3: return 4
        case 4: return 5
        case 5: return 6
        default: return 0
        }
    }

    static func selectorIndex(fromCalendarWeekday weekday: Int) -> Int {
        switch weekday {
        case 1: return 0
        case 2: return 1
        case 3: return 2
        case 4: return 3
        case 5: return 4
        case 6: return 5
        default: return 6
        }
    }

    static func shortLabel(forCalendarWeekday weekday: Int) -> String {
        let labels = Calendar.current.shortWeekdaySymbols
        let index = max(0, min(6, weekday))
        return labels[index]
    }
}

private extension AtlasVialDraft {
    init(from summary: AtlasVialSummary) {
        self.init(
            id: summary.id,
            label: summary.label,
            protocolID: summary.linkedProtocolID,
            startingQuantity: summary.startingQuantity,
            remainingQuantity: summary.remainingQuantity,
            quantityUnit: summary.quantityUnit,
            lowStockThreshold: nil,
            calculatorProfileID: summary.calculatorProfileID,
            referencePhotoRelativePath: summary.referencePhotoPath,
            labelScanText: summary.labelScanPreview,
            archivedAt: summary.archivedAt
        )
    }
}

private extension AtlasConsumableDraft {
    init(from summary: AtlasConsumableSummary) {
        self.init(
            id: summary.id,
            protocolID: summary.linkedProtocolID,
            name: summary.name,
            category: summary.category,
            quantityOnHand: summary.quantityOnHand,
            unit: summary.quantityUnit,
            reorderThreshold: summary.reorderThreshold,
            vendorLabel: summary.vendorLabel,
            archivedAt: summary.archivedAt
        )
    }
}

private extension AtlasPrivacyRenderMode {
    var kairoTitle: String {
        switch self {
        case .full: return "Full"
        case .discreet: return "Discreet"
        case .alias: return "Alias"
        }
    }
}

private extension ProtocolSummary {
    var displayTitle: String {
        aliasTitle ?? canonicalTitle
    }
}

private extension AtlasImporterKind {
    var kairoTitle: String {
        switch self {
        case .atlasJSON: return "Atlas JSON"
        case .atlasCSV: return "Atlas CSV"
        case .genericCSV: return "Generic CSV"
        case .manualText: return "Manual"
        }
    }
}

private enum KairoColor {
    static let blue = Color(red: 0.18, green: 0.58, blue: 0.82)
}

private func formatKairoNumber(_ value: Double, digits: Int) -> String {
    String(format: "%.\(digits)f", value)
}

private func formatHydrationLiters(_ liters: Double) -> String {
    let rounded = (liters * 10).rounded() / 10
    if rounded == rounded.rounded() {
        return formatKairoNumber(rounded, digits: 0)
    }
    return formatKairoNumber(rounded, digits: 1)
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension Text {
    func kairoCardTitle() -> some View {
        font(.system(size: 13, weight: .bold))
            .foregroundStyle(AtlasPalette.textPrimary)
    }

    func kairoCardBody() -> some View {
        font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AtlasPalette.textPrimary)
    }

    func kairoMeta() -> some View {
        font(.system(size: 10, weight: .medium))
            .foregroundStyle(AtlasPalette.textSecondary)
    }
}
