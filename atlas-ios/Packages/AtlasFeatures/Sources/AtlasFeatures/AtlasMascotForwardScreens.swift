import AtlasDesignSystem
import AtlasDomain
import Foundation
import SwiftUI

#if DEBUG
var atlasForwardMockupFidelityActive: Bool {
    let environment = ProcessInfo.processInfo.environment
    if ["1", "true", "yes"].contains(environment["ATLAS_QA_MOCKUP_FIDELITY"]?.lowercased() ?? "") {
        return true
    }
    let arguments = ProcessInfo.processInfo.arguments
    return arguments.contains("mockupToday")
        || arguments.contains("mockupLog")
        || arguments.contains("mockupCompanion")
        || arguments.contains("mockupProtocols")
        || arguments.contains("mockupProgress")
        || arguments.contains("mockupInventory")
        || arguments.contains("--atlas-qa-mockup-fidelity")
}
#else
let atlasForwardMockupFidelityActive = false
#endif

struct AtlasMascotForwardTodayScreen: View {
    let model: AtlasAppModel
    let state: AtlasTodayViewState

    var body: some View {
        AtlasRootScrollSurface {
            AtlasForwardTopBar(model: model)

            AtlasForwardMascotHero(
                selection: atlasForwardMockupFidelityActive ? .aetherion : model.settingsSnapshot.mascotSelection,
                nickname: model.settingsSnapshot.mascotNickname,
                rewardsSnapshot: state.rewardsSnapshot
            )

            AtlasForwardNextShotCard(
                model: model,
                occurrence: state.todaySnapshot.nextDue ?? state.todaySnapshot.overdue.first,
                medicationLevel: medicationLevel,
                renderMode: state.renderMode
            )

            AtlasForwardSupportRingGrid(model: model)

            AtlasForwardInventoryRunwayCard(model: model)
        }
    }

    private var medicationLevel: AtlasAmountEstimateItem? {
        guard let occurrence = state.todaySnapshot.nextDue ?? state.todaySnapshot.overdue.first else {
            return model.insightsSnapshot.amountInSystem.first
        }

        return model.insightsSnapshot.amountInSystem.first(where: { $0.protocolID == occurrence.protocolID })
            ?? model.protocolDetails[occurrence.protocolID]?.medicationLevel
            ?? model.insightsSnapshot.amountInSystem.first
    }
}

struct AtlasLogHomeScreen: View {
    let model: AtlasAppModel
    @State private var selectedKind: AtlasQuickCaptureKind = .shot

    init(model: AtlasAppModel) {
        self.model = model
        #if DEBUG
        let rawKind = ProcessInfo.processInfo.environment["ATLAS_QA_LOG_KIND"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let rawKind, let kind = AtlasQuickCaptureKind(rawValue: rawKind) {
            _selectedKind = State(initialValue: kind)
        }
        #endif
    }

    var body: some View {
        AtlasRootScrollSurface {
            AtlasForwardLogNavBar(
                title: headerTitle,
                isComplete: false
            )

            switch selectedKind {
            case .shot:
                AtlasForwardShotCaptureCard(model: model) { kind in
                    withAnimation(AtlasMotion.interactiveSpring) {
                        selectedKind = kind
                    }
                }
            case .weight:
                AtlasForwardWeightCaptureCard(model: model)
            case .symptom:
                AtlasForwardSymptomCaptureCard(model: model)
            case .context:
                AtlasForwardFoodCaptureCard(model: model)
                AtlasForwardWorkoutCaptureCard(model: model)
            case .hydration:
                AtlasForwardOneTapContextCard(
                    model: model,
                    title: "Hydration",
                    detail: "Add a fast hydration check-in for today.",
                    shortcut: .hydration,
                    primaryTitle: "Log Hydration"
                )
            case .protein:
                AtlasForwardOneTapContextCard(
                    model: model,
                    title: "Protein Meal",
                    detail: "Capture a protein-forward meal signal.",
                    shortcut: .proteinMeal,
                    primaryTitle: "Log Protein"
                )
            case .progressPhoto:
                AtlasForwardProgressPhotoCard(model: model)
            }

            if selectedKind != .shot {
                AtlasForwardLogShortcutGrid(model: model, selectedKind: selectedKind) { kind in
                    withAnimation(AtlasMotion.interactiveSpring) {
                        selectedKind = kind
                    }
                }
            }
        }
    }

    private var headerTitle: String {
        selectedKind == .shot ? "Log Shot" : selectedKind.title
    }
}

struct AtlasProgressHomeScreen: View {
    let model: AtlasAppModel
    let state: AtlasInsightsViewState

    var body: some View {
        AtlasRootScrollSurface {
            AtlasForwardHeaderRow(title: "Progress")

            AtlasForwardProgressHero(model: model, state: state)

            AtlasForwardProgressGrid(model: model, state: state)

            AtlasForwardProgressActions(model: model)

            AtlasForwardProgressMasteryCompactCard(model: model)
        }
    }
}

struct AtlasCompanionHomeScreen: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasRootScrollSurface {
            AtlasForwardCompanionHero(model: model)

            AtlasForwardQuestCard(model: model)

            AtlasForwardBadgeCollectibleCard(model: model)

            AtlasForwardWeeklyMasteryCard(model: model)
        }
    }
}

struct AtlasProtocolsHomeScreen: View {
    let model: AtlasAppModel
    let state: AtlasLibraryViewState

    var body: some View {
        AtlasRootScrollSurface {
            if protocols.isEmpty {
                AtlasForwardHeaderRow(
                    title: "Protocols",
                    trailingSystemImage: "plus",
                    trailingTint: AtlasPalette.primary
                ) {
                    model.open(.protocolCreate)
                }
                AtlasForwardProtocolEmptyState(model: model)
            } else {
                AtlasForwardMockupProtocolsScreen(model: model, protocols: protocols, renderMode: state.renderMode)
            }
        }
    }

    private var protocols: [ProtocolSummary] {
        state.protocols.isEmpty ? model.libraryProtocols : state.protocols
    }

    private var primaryProtocol: ProtocolSummary? {
        protocols.first(where: { $0.status == .active }) ?? protocols.first
    }

    private var primaryDetail: AtlasProtocolDetailSnapshot? {
        guard let id = primaryProtocol?.id else { return nil }
        return model.protocolDetails[id]
    }
}

private struct AtlasForwardMockupProtocolsScreen: View {
    let model: AtlasAppModel
    let protocols: [ProtocolSummary]
    let renderMode: AtlasPrivacyRenderMode

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text("Protocols")
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Spacer()
                Button {
                    model.open(.protocolCreate)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .foregroundStyle(AtlasPalette.primary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 3)

            AtlasForwardCard(padding: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Active (\(mockupRows.count))")
                            .atlasTextRole(.metricLabel)
                            .foregroundStyle(AtlasPalette.textSecondary)
                        Spacer()
                        Text("See all")
                            .atlasTextRole(.metricLabel)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    ForEach(mockupRows) { row in
                        AtlasForwardMockupProtocolListRow(model: model, row: row)
                    }
                }
            }

            AtlasForwardCard(padding: 11) {
                VStack(alignment: .leading, spacing: 9) {
                    Text("Schedule Summary")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(scheduleColumns) { column in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(column.day)
                                    .atlasTextRole(.metricLabel)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                ForEach(column.items, id: \.self) { item in
                                    Text(item)
                                        .atlasTextRole(.metricLabel)
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }

            Button {
                model.open(.protocolCreate)
            } label: {
                Label("Add Protocol", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AtlasPrimaryButtonStyle())
        }
    }

    private var mockupRows: [AtlasForwardMockupProtocolRowModel] {
        if atlasForwardMockupFidelityActive == false || protocols.count > 1 {
            return protocols.prefix(3).map { summary in
                AtlasForwardMockupProtocolRowModel(
                    id: summary.id,
                    title: renderedTitle(summary),
                    dose: summary.doseLabel ?? "Dose",
                    route: summary.kindLabel.localizedCaseInsensitiveContains("glp") ? "SubQ" : "SubQ",
                    cadence: summary.cadenceLabel,
                    days: summary.cadenceLabel.localizedCaseInsensitiveContains("daily") ? ["M", "T", "W", "T", "F", "S", "S"] : ["M"],
                    next: summary.nextDueLabel ?? "Today, 12:30 PM",
                    runway: "12 doses (~28 days)"
                )
            }
        }

        return [
            AtlasForwardMockupProtocolRowModel(id: protocols.first?.id ?? "mockup-tirzepatide", title: "Tirzepatide", dose: "5.0 mg", route: "SubQ", cadence: "Weekly", days: ["M"], next: "Today, 12:30 PM", runway: "12 doses (~28 days)"),
            AtlasForwardMockupProtocolRowModel(id: "mockup-bpc", title: "BPC-157", dose: "250 mcg", route: "SubQ", cadence: "Daily", days: ["M", "T", "W", "T", "F", "S", "S"], next: "Tomorrow, 8:00 AM", runway: "46 doses (~46 days)"),
            AtlasForwardMockupProtocolRowModel(id: "mockup-cjc", title: "CJC-1295", dose: "250 mcg", route: "SubQ", cadence: "Daily", days: ["M", "T", "W", "T", "F", "S", "S"], next: "Tomorrow, 8:00 AM", runway: "30 doses (~30 days)")
        ]
    }

    private var scheduleColumns: [AtlasForwardMockupScheduleColumn] {
        if atlasForwardMockupFidelityActive == false {
            let visible = Array(protocols.prefix(3))
            return visible.enumerated().map { index, summary in
                AtlasForwardMockupScheduleColumn(
                    day: index == 0 ? "Today" : "Next",
                    items: [
                        renderedTitle(summary),
                        summary.nextDueLabel ?? summary.cadenceLabel
                    ]
                )
            }
        }

        return [
            AtlasForwardMockupScheduleColumn(day: "Today", items: ["Tirzepatide", "12:30 PM"]),
            AtlasForwardMockupScheduleColumn(day: "Tomorrow", items: ["BPC-157", "CJC-1295"]),
            AtlasForwardMockupScheduleColumn(day: "1 shot", items: ["8:00 AM"])
        ]
    }

    private func renderedTitle(_ summary: ProtocolSummary) -> String {
        var title = model.renderedTitle(canonical: summary.canonicalTitle, alias: summary.aliasTitle, renderMode: renderMode)
        for suffix in [" Weekly", " Daily", " Monthly", " Protocol"] where title.hasSuffix(suffix) {
            title.removeLast(suffix.count)
            break
        }
        return title
    }
}

private struct AtlasForwardMockupProtocolRowModel: Identifiable {
    let id: String
    let title: String
    let dose: String
    let route: String
    let cadence: String
    let days: [String]
    let next: String
    let runway: String
}

private struct AtlasForwardMockupScheduleColumn: Identifiable {
    var id: String { day }
    let day: String
    let items: [String]
}

private struct AtlasForwardMockupProtocolListRow: View {
    let model: AtlasAppModel
    let row: AtlasForwardMockupProtocolRowModel

    var body: some View {
        Button {
            model.open(.protocolDetail(row.id))
        } label: {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "testtube.2")
                    .font(.system(size: 12, weight: .semibold, design: .default))
                    .foregroundStyle(AtlasPalette.primary)
                    .frame(width: 27, height: 27)
                    .background(AtlasPalette.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(row.title)
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Spacer(minLength: 8)
                        Text(row.cadence)
                            .atlasTextRole(.metricLabel)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .frame(height: 19)
                            .background(AtlasPalette.primary, in: Capsule())
                    }

                    Text("\(row.dose)  •  \(row.route)  •  \(row.cadence)")
                        .atlasTextRole(.metricLabel)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        ForEach(Array(row.days.enumerated()), id: \.offset) { _, day in
                            Text(day)
                                .atlasTextRole(.metricLabel)
                                .foregroundStyle(AtlasPalette.primary)
                                .frame(width: 18, height: 17)
                                .background(AtlasPalette.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                        }
                    }

                    HStack(alignment: .firstTextBaseline) {
                        Text("Next")
                            .foregroundStyle(AtlasPalette.textSecondary)
                        Text(row.next)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Spacer(minLength: 8)
                        Text(row.runway)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                    .atlasTextRole(.metricLabel)
                }
            }
            .padding(7)
            .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct AtlasForwardProtocolEmptyState: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "list.clipboard.fill")
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .foregroundStyle(AtlasPalette.primary)
                        .frame(width: 46, height: 46)
                        .background(AtlasPalette.secondaryFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Build your peptide protocol")
                            .atlasTextRole(.cardTitle)
                            .foregroundStyle(AtlasPalette.textPrimary)
                    }
                }

                Button {
                    model.open(.protocolCreate)
                } label: {
                    Label("Create Protocol", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
            }
        }
    }
}

private struct AtlasForwardProtocolHero: View {
    let model: AtlasAppModel
    let summary: ProtocolSummary?
    let detail: AtlasProtocolDetailSnapshot?
    let renderMode: AtlasPrivacyRenderMode

    var body: some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "testtube.2")
                        .foregroundStyle(AtlasPalette.primary)
                        .frame(width: 34, height: 34)
                        .background(AtlasPalette.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .atlasTextRole(.cardTitle)
                            .foregroundStyle(AtlasPalette.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Text(subtitle)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 8)

                    AtlasStatusBadge(statusLabel, tint: statusTint)
                }

                AtlasForwardMedicationMiniChart(item: medicationLevel, height: 48)

                HStack(spacing: 8) {
                    AtlasForwardProtocolHeroMetric(title: "Next", value: nextDueLabel, tint: AtlasPalette.primary)
                    AtlasForwardProtocolHeroMetric(title: "Supply", value: supplyLabel, tint: supplyTint)
                    AtlasForwardProtocolHeroMetric(title: "Route", value: routeLabel, tint: AtlasPalette.success)
                }

                Button {
                    model.activeTab = .timeline
                } label: {
                    Label("Log Shot", systemImage: "syringe.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let id = summary?.id {
                model.open(.protocolDetail(id))
            }
        }
    }

    private var title: String {
        guard let summary else { return "No Active Protocol" }
        if atlasForwardMockupFidelityActive {
            return "Tirzepatide"
        }
        var rendered = model.renderedTitle(canonical: summary.canonicalTitle, alias: summary.aliasTitle, renderMode: renderMode)
        for suffix in [" Weekly", " Daily", " Monthly", " Protocol"] where rendered.hasSuffix(suffix) {
            rendered.removeLast(suffix.count)
            break
        }
        return rendered
    }

    private var subtitle: String {
        let pieces = [
            summary?.doseLabel,
            routeLabel,
            summary?.cadenceLabel
        ].compactMap { value -> String? in
            guard let value, value.isEmpty == false else { return nil }
            return value
        }
        return pieces.joined(separator: "  •  ")
    }

    private var statusLabel: String {
        guard let summary else { return "Setup" }
        switch summary.status {
        case .active: return "Active"
        case .draft: return "Draft"
        case .paused: return "Paused"
        case .archived: return "Archived"
        }
    }

    private var statusTint: Color {
        summary?.status == .active ? AtlasPalette.success : AtlasPalette.textSecondary
    }

    private var medicationLevel: AtlasAmountEstimateItem? {
        guard let protocolID = summary?.id else {
            return model.insightsSnapshot.amountInSystem.first
        }
        return model.insightsSnapshot.amountInSystem.first(where: { $0.protocolID == protocolID })
            ?? detail?.medicationLevel
            ?? model.insightsSnapshot.amountInSystem.first
    }

    private var nextDueLabel: String {
        if atlasForwardMockupFidelityActive {
            return "Today"
        }
        return summary?.nextDueLabel ?? detail?.nextOccurrence?.scheduledAt.formatted(date: .abbreviated, time: .shortened) ?? "Planned"
    }

    private var routeLabel: String {
        if atlasForwardMockupFidelityActive {
            return "SubQ"
        }
        return detail?.administrationLabel
            ?? detail?.editableDraft.administrationRoute.forwardDisplayLabel
            ?? (summary?.kindLabel.localizedCaseInsensitiveContains("glp") == true ? "SubQ" : summary?.kindLabel)
            ?? "Route"
    }

    private var supplyLabel: String {
        if atlasForwardMockupFidelityActive {
            return "Vial"
        }
        return detail?.supplyLabel
            ?? detail?.editableDraft.supplyType?.forwardDisplayLabel
            ?? linkedVial?.quantityLabel
            ?? "Supply"
    }

    private var supplyTint: Color {
        linkedVial?.isLowStock == true ? AtlasPalette.warning : AtlasPalette.reward
    }

    private var linkedVial: AtlasVialSummary? {
        guard let id = summary?.id else {
            return model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil })
        }
        return model.inventorySnapshot.vials.first(where: { $0.linkedProtocolID == id && $0.archivedAt == nil })
            ?? model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil })
    }
}

private struct AtlasForwardProtocolHeroMetric: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .atlasTextRole(.metricLabel)
                .foregroundStyle(AtlasPalette.textSecondary)
            Text(value)
                .atlasTextRole(.deckEyebrow)
                .foregroundStyle(AtlasPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            AtlasForwardThinProgress(value: 0.72, tint: tint)
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .padding(8)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AtlasForwardProtocolSetupGrid: View {
    let model: AtlasAppModel
    let summary: ProtocolSummary?
    let detail: AtlasProtocolDetailSnapshot?

    var body: some View {
        HStack(spacing: 8) {
            AtlasForwardProtocolSetupTile(title: "Route", value: routeLabel, systemImage: routeIcon, tint: AtlasPalette.primary)
            AtlasForwardProtocolSetupTile(title: "Device", value: supplyLabel, systemImage: supplyIcon, tint: AtlasPalette.reward)
            AtlasForwardProtocolSetupTile(title: "Sites", value: sitesLabel, systemImage: "figure.arms.open", tint: AtlasPalette.success)
        }
    }

    private var routeLabel: String {
        detail?.administrationLabel
            ?? detail?.editableDraft.administrationRoute.forwardDisplayLabel
            ?? (summary?.kindLabel.localizedCaseInsensitiveContains("glp") == true ? "SubQ" : summary?.kindLabel)
            ?? "Route"
    }

    private var routeIcon: String {
        let route = detail?.editableDraft.administrationRoute ?? .injection
        switch route {
        case .injection: return "syringe.fill"
        case .oral, .sublingual: return "pills.fill"
        case .nasal: return "nose.fill"
        case .topical, .transdermal: return "hand.raised.fill"
        case .other: return "checklist"
        }
    }

    private var supplyLabel: String {
        detail?.supplyLabel
            ?? detail?.editableDraft.supplyType?.forwardDisplayLabel
            ?? linkedVial?.quantityLabel
            ?? "Supply"
    }

    private var supplyIcon: String {
        switch detail?.editableDraft.supplyType {
        case .pen: return "pencil.tip"
        case .bottle, .blisterPack: return "pills.fill"
        case .syringe: return "syringe.fill"
        case .vial, .none: return "testtube.2"
        case .other: return "shippingbox.fill"
        }
    }

    private var sitesLabel: String {
        guard let id = summary?.id,
              let setting = model.inventorySnapshot.protocolSettings.first(where: { $0.id == id }) else {
            let siteCount = model.inventorySnapshot.sites.filter { $0.archivedAt == nil }.count
            return siteCount == 0 ? "Off" : "\(siteCount)"
        }
        if setting.siteRotationEnabled {
            return "Rotation"
        }
        return setting.siteTrackingEnabled ? "Tracking" : "Off"
    }

    private var linkedVial: AtlasVialSummary? {
        guard let id = summary?.id else {
            return model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil })
        }
        return model.inventorySnapshot.vials.first(where: { $0.linkedProtocolID == id && $0.archivedAt == nil })
            ?? model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil })
    }
}

private struct AtlasForwardProtocolSetupTile: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        AtlasForwardCard(padding: 10) {
            VStack(alignment: .leading, spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundStyle(tint)
                Text(title)
                    .atlasTextRole(.metricLabel)
                    .foregroundStyle(AtlasPalette.textSecondary)
            Text(value)
                .atlasTextRole(.deckEyebrow)
                .foregroundStyle(AtlasPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
        }
    }
}

private struct AtlasForwardProtocolStackCard: View {
    let model: AtlasAppModel
    let protocols: [ProtocolSummary]
    let renderMode: AtlasPrivacyRenderMode

    var body: some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Protocol Stack")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Spacer()
                    Text("\(protocols.count) active")
                        .atlasTextRole(.metricLabel)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                VStack(spacing: 8) {
                    ForEach(protocols.prefix(4)) { summary in
                        AtlasForwardProtocolRow(model: model, summary: summary, detail: model.protocolDetails[summary.id], renderMode: renderMode)
                    }
                }
            }
        }
    }
}

private struct AtlasForwardProtocolRow: View {
    let model: AtlasAppModel
    let summary: ProtocolSummary
    let detail: AtlasProtocolDetailSnapshot?
    let renderMode: AtlasPrivacyRenderMode

    var body: some View {
        Button {
            model.open(.protocolDetail(summary.id))
        } label: {
            HStack(alignment: .center, spacing: 9) {
                Image(systemName: rowIcon)
                    .foregroundStyle(AtlasPalette.primary)
                    .frame(width: 30, height: 30)
                    .background(AtlasPalette.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(detailLine)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(summary.cadenceLabel)
                        .atlasTextRole(.metricLabel)
                        .foregroundStyle(AtlasPalette.success)
                        .lineLimit(1)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AtlasPalette.textTertiary)
                }
            }
            .padding(9)
            .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var title: String {
        var rendered = model.renderedTitle(canonical: summary.canonicalTitle, alias: summary.aliasTitle, renderMode: renderMode)
        for suffix in [" Weekly", " Daily", " Monthly", " Protocol"] where rendered.hasSuffix(suffix) {
            rendered.removeLast(suffix.count)
            break
        }
        return rendered
    }

    private var detailLine: String {
        [
            summary.doseLabel,
            detail?.administrationLabel ?? detail?.editableDraft.administrationRoute.forwardDisplayLabel,
            detail?.supplyLabel ?? detail?.editableDraft.supplyType?.forwardDisplayLabel,
            summary.nextDueLabel
        ].compactMap { value -> String? in
            guard let value, value.isEmpty == false else { return nil }
            return value
        }.joined(separator: "  •  ")
    }

    private var rowIcon: String {
        let route = detail?.editableDraft.administrationRoute ?? (summary.kindLabel.localizedCaseInsensitiveContains("glp") ? .injection : .other)
        switch route {
        case .injection: return "syringe.fill"
        case .oral, .sublingual: return "pills.fill"
        case .nasal: return "nose.fill"
        case .topical, .transdermal: return "hand.raised.fill"
        case .other: return "list.clipboard.fill"
        }
    }
}

private struct AtlasForwardPeptideToolkitCard: View {
    let model: AtlasAppModel
    let protocolID: String?

    var body: some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Peptide Toolkit")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Spacer()
                    Text("Reference")
                        .atlasTextRole(.metricLabel)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    toolkitButton(title: "Levels", detail: "Half-life chart", systemImage: "waveform.path.ecg", tint: AtlasPalette.primary) {
                        if let protocolID {
                            model.open(.medicationLevels(protocolID))
                        }
                    }
                    toolkitButton(title: "Calculator", detail: "Concentration", systemImage: "function", tint: AtlasPalette.reward) {
                        model.open(.calculator)
                    }
                    toolkitButton(title: "Inventory", detail: "Runway", systemImage: "testtube.2", tint: AtlasPalette.success) {
                        model.open(.inventory)
                    }
                    toolkitButton(title: "Compare", detail: "Protocol edits", systemImage: "arrow.triangle.branch", tint: AtlasPalette.primary) {
                        if let protocolID {
                            model.open(.protocolChange(protocolID))
                        }
                    }
                }
            }
        }
    }

    private func toolkitButton(
        title: String,
        detail: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            AtlasFeedback.selection()
            action()
        } label: {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)
                    .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.textPrimary)
                        .lineLimit(1)
                    Text(detail)
                        .atlasTextRole(.metricLabel)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 0)
            }
            .padding(9)
            .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled((title == "Levels" || title == "Compare") && protocolID == nil)
    }
}

private struct AtlasForwardProtocolSupportCard: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasForwardCard(padding: 9) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Support Signals")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Spacer()
                    Text("Optional")
                        .atlasTextRole(.metricLabel)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                HStack(spacing: 8) {
                    AtlasForwardMiniSignalTile(title: "Protein", value: proteinLabel, systemImage: "fork.knife", tint: AtlasPalette.success)
                    AtlasForwardMiniSignalTile(title: "Hydration", value: hydrationLabel, systemImage: "drop.fill", tint: Color(red: 0.15, green: 0.58, blue: 0.9))
                }
            }
        }
    }

    private var proteinLabel: String {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .proteinMeals })?.progressLabel ?? "0 / 1"
    }

    private var hydrationLabel: String {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .hydrationCheckins })?.progressLabel ?? "0 / 1"
    }
}

private struct AtlasForwardTopBar: View {
    let model: AtlasAppModel

    var body: some View {
        HStack(alignment: .center) {
            Text("Kairo")
                .font(AtlasTypography.brandFont(size: atlasForwardMockupFidelityActive ? 19 : 21, weight: .bold, relativeTo: .title))
                .foregroundStyle(AtlasPalette.textPrimary)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text(streakLabel)
            }
            .atlasTextRole(.deckEyebrow)
            .foregroundStyle(AtlasPalette.success)

            HStack(spacing: 6) {
                Image(systemName: "hexagon.fill")
                Text(pointsLabel)
            }
            .atlasTextRole(.deckEyebrow)
            .foregroundStyle(AtlasPalette.reward)
        }
        .padding(.top, 4)
    }

    private var streakLabel: String {
        if atlasForwardMockupFidelityActive {
            return "Streak 12"
        }
        let streak = model.rewardsSnapshot.streaks.filter(\.isActive).map(\.count).max() ?? 0
        return "Streak \(streak)"
    }

    private var pointsLabel: String {
        if atlasForwardMockupFidelityActive {
            return "1,250"
        }
        return model.rewardsSnapshot.totalPoints.formatted()
    }
}

private struct AtlasForwardLogNavBar: View {
    let title: String
    let isComplete: Bool

    var body: some View {
        ZStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .default))
                .foregroundStyle(AtlasPalette.textPrimary)

            HStack {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .frame(width: 34, height: 34)
                    .opacity(0.9)

                Spacer()

                Image(systemName: isComplete ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AtlasPalette.success)
                    .frame(width: 34, height: 34)
                    .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AtlasPalette.border.opacity(0.44), lineWidth: 1)
                    )
            }
        }
        .frame(height: 38)
    }
}

struct AtlasForwardHeaderRow: View {
    let title: String
    var trailingSystemImage: String?
    var trailingTint: Color = AtlasPalette.primary
    var trailingAction: (() -> Void)?

    init(
        title: String,
        trailingSystemImage: String? = nil,
        trailingTint: Color = AtlasPalette.primary,
        trailingAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.trailingSystemImage = trailingSystemImage
        self.trailingTint = trailingTint
        self.trailingAction = trailingAction
    }

    var body: some View {
        HStack {
            Text(title)
                .font(AtlasTypography.brandFont(size: 18, weight: .bold, relativeTo: .title2))
                .foregroundStyle(AtlasPalette.textPrimary)
            Spacer()
            if let trailingSystemImage {
                Button {
                    trailingAction?()
                } label: {
                    Image(systemName: trailingSystemImage)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(trailingTint)
                        .frame(width: 34, height: 34)
                        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(trailingAction == nil)
            }
        }
        .padding(.top, 4)
    }
}

private struct AtlasForwardMascotHero: View {
    let selection: AtlasMascotSelection
    let nickname: String?
    let rewardsSnapshot: AtlasRewardsSnapshot

    var body: some View {
        let evolution = atlasRewardsEvolutionProgress(for: rewardsSnapshot, selection: selection)
        let displayStage: AtlasMascotStage = atlasForwardMockupFidelityActive ? .stage1 : evolution.stage

        AtlasForwardCard(padding: atlasForwardMockupFidelityActive ? 7 : 10) {
            HStack(alignment: .center, spacing: atlasForwardMockupFidelityActive ? 7 : 14) {
                AtlasForwardMascotArt(selection: selection, stage: displayStage, size: atlasForwardMockupFidelityActive ? 142 : 146)
                    .frame(width: atlasForwardMockupFidelityActive ? 132 : 156, height: atlasForwardMockupFidelityActive ? 116 : 130)
                    .offset(x: atlasForwardMockupFidelityActive ? -1 : 0, y: atlasForwardMockupFidelityActive ? 1 : 0)

                VStack(alignment: .leading, spacing: atlasForwardMockupFidelityActive ? 5 : 7) {
                    Text("Good morning\(nicknameSuffix)")
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(Color(red: 0.06, green: 0.12, blue: 0.11))

                    HStack(alignment: .center, spacing: 8) {
                        Text("Lv. \(displayLevel)")
                            .font(.system(size: 11, weight: .bold, design: .default))
                            .foregroundStyle(Color(red: 0.04, green: 0.32, blue: 0.27))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.96), in: Capsule(style: .continuous))
                        VStack(alignment: .trailing, spacing: 3) {
                            AtlasForwardThinProgress(value: progressValue, tint: AtlasPalette.primary)
                                .background(Color(red: 0.04, green: 0.32, blue: 0.27).opacity(0.16), in: Capsule(style: .continuous))
                            Text(displayXPLabel)
                                .font(.system(size: 10.5, weight: .bold, design: .default))
                                .foregroundStyle(Color(red: 0.04, green: 0.32, blue: 0.27))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                    }
                }
                .padding(7)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.86))
                }
                .padding(.trailing, atlasForwardMockupFidelityActive ? 1 : 2)
            }
            .frame(minHeight: atlasForwardMockupFidelityActive ? 116 : 132)
        }
    }

    private var progressValue: Double {
        if atlasForwardMockupFidelityActive {
            return 1_240.0 / 2_000.0
        }
        guard rewardsSnapshot.nextLevelPoints > 0 else {
            return 1
        }
        return min(max(Double(rewardsSnapshot.totalPoints) / Double(rewardsSnapshot.nextLevelPoints), 0), 1)
    }

    private var displayLevel: Int {
        atlasForwardMockupFidelityActive ? 14 : rewardsSnapshot.level
    }

    private var displayXPLabel: String {
        atlasForwardMockupFidelityActive ? "1,240 / 2,000 XP" : "\(rewardsSnapshot.totalPoints.formatted()) / \(max(rewardsSnapshot.nextLevelPoints, rewardsSnapshot.totalPoints).formatted()) XP"
    }

    private var nicknameSuffix: String {
        if atlasForwardMockupFidelityActive {
            return ""
        }
        guard let nickname, nickname.isEmpty == false else {
            return ""
        }
        return ", \(nickname)"
    }
}

private struct AtlasForwardNextShotCard: View {
    let model: AtlasAppModel
    let occurrence: AtlasScheduledOccurrence?
    let medicationLevel: AtlasAmountEstimateItem?
    let renderMode: AtlasPrivacyRenderMode

    var body: some View {
        AtlasForwardCard(padding: atlasForwardMockupFidelityActive ? 8 : 10) {
            VStack(alignment: .leading, spacing: atlasForwardMockupFidelityActive ? 8 : 10) {
                HStack(alignment: .center) {
                    Text("Next Shot")
                        .atlasTextRole(atlasForwardMockupFidelityActive ? .supporting : .cardBody)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Spacer()
                    if let occurrence {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(occurrence.state == .overdue ? AtlasPalette.warning : AtlasPalette.success)
                                .frame(width: 6, height: 6)
                            Text(dueLabel(for: occurrence))
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                }

                if let occurrence {
                    HStack(alignment: .center, spacing: atlasForwardMockupFidelityActive ? 8 : 10) {
                        VStack(alignment: .leading, spacing: atlasForwardMockupFidelityActive ? 4 : 5) {
                            HStack(spacing: 7) {
                                Text(displayTitle(for: occurrence))
                                    .font(
                                        AtlasTypography.brandFont(
                                            size: atlasForwardMockupFidelityActive ? 16 : 18,
                                            weight: .bold,
                                            relativeTo: .title3
                                        )
                                    )
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.76)
                                if let cadence = cadenceBadge(for: occurrence) {
                                    AtlasStatusBadge(cadence, tint: AtlasPalette.success)
                                }
                            }
                            Text([shotDoseLabel(for: occurrence), routeLabel(for: occurrence), shotCardTimeLabel(for: occurrence)].compactMap { $0 }.joined(separator: "  •  "))
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(AtlasPalette.textTertiary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        model.open(.protocolDetail(occurrence.protocolID))
                    }

                    AtlasForwardMedicationMiniChart(item: medicationLevel, height: atlasForwardMockupFidelityActive ? 56 : 68)

                    Button {
                        AtlasFeedback.selection()
                        model.activeTab = .timeline
                    } label: {
                        Label("Log Shot", systemImage: "syringe.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                } else {
                    Text("Create your first active protocol to make Kairo feel alive.")
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Button("Create Protocol") {
                        model.open(.protocolCreate)
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                }
            }
        }
    }

    private func renderedTitle(for occurrence: AtlasScheduledOccurrence) -> String {
        model.renderedTitle(canonical: occurrence.canonicalTitle, alias: occurrence.aliasTitle, renderMode: renderMode)
    }

    private func displayTitle(for occurrence: AtlasScheduledOccurrence) -> String {
        if atlasForwardMockupFidelityActive {
            return "Tirzepatide"
        }
        var title = renderedTitle(for: occurrence)
        for suffix in [" Weekly", " Daily", " Monthly", " Protocol"] {
            if title.hasSuffix(suffix) {
                title.removeLast(suffix.count)
                break
            }
        }
        return title
    }

    private func cadenceBadge(for occurrence: AtlasScheduledOccurrence) -> String? {
        let title = renderedTitle(for: occurrence)
        if title.localizedCaseInsensitiveContains("weekly") {
            return "Weekly"
        }
        if title.localizedCaseInsensitiveContains("daily") {
            return "Daily"
        }
        return nil
    }

    private func routeLabel(for occurrence: AtlasScheduledOccurrence) -> String? {
        if occurrence.kindLabel.localizedCaseInsensitiveContains("glp") {
            return "SubQ"
        }
        return occurrence.kindLabel
    }

    private func shotDoseLabel(for occurrence: AtlasScheduledOccurrence) -> String? {
        atlasForwardMockupFidelityActive ? "5.0 mg" : occurrence.doseLabel
    }

    private func shotCardTimeLabel(for occurrence: AtlasScheduledOccurrence) -> String {
        atlasForwardMockupFidelityActive ? "Today, 12:30 PM" : occurrence.scheduledAt.formatted(date: .omitted, time: .shortened)
    }

    private func dueLabel(for occurrence: AtlasScheduledOccurrence) -> String {
        if atlasForwardMockupFidelityActive {
            return "Due in 2h 35m"
        }
        if occurrence.state == .overdue {
            return "Overdue"
        }
        let interval = occurrence.scheduledAt.timeIntervalSince(model.currentDate())
        if interval <= 0 {
            return "Due now"
        }
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        return hours > 0 ? "Due in \(hours)h \(minutes)m" : "Due in \(max(minutes, 1))m"
    }
}

private struct AtlasForwardMedicationMiniChart: View {
    let item: AtlasAmountEstimateItem?
    var height: CGFloat = 68

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Medication Level")
                    .atlasTextRole(.metricLabel)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textTertiary)
                Spacer()
            }

            GeometryReader { proxy in
                let points = chartPoints(in: proxy.size)
                ZStack(alignment: .leading) {
                    VStack(spacing: 0) {
                        Text("High")
                            .font(.system(size: 8, weight: .medium, design: .default))
                            .foregroundStyle(AtlasPalette.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer(minLength: 0)
                        Rectangle()
                            .fill(AtlasPalette.primary.opacity(0.36))
                            .frame(height: 0.7)
                            .overlay(alignment: .trailing) {
                                Text("Target")
                                    .font(.system(size: 8, weight: .medium, design: .default))
                                    .foregroundStyle(AtlasPalette.textTertiary)
                                    .offset(y: -7)
                            }
                        Spacer(minLength: 0)
                        Text("Low")
                            .font(.system(size: 8, weight: .medium, design: .default))
                            .foregroundStyle(AtlasPalette.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Path { path in
                        guard let first = points.first else { return }
                        path.move(to: first)
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(AtlasPalette.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    if let last = points.dropLast().last ?? points.last {
                        Circle()
                            .fill(AtlasPalette.success)
                            .frame(width: 9, height: 9)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                            .position(last)
                    }
                }
            }
            .frame(height: height)

            HStack {
                ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 9, weight: .medium, design: .default))
                        .foregroundStyle(AtlasPalette.textTertiary)
                    if day != "Sun" { Spacer(minLength: 0) }
                }
            }
        }
        .padding(10)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func chartPoints(in size: CGSize) -> [CGPoint] {
        let resolved: [Double]
        if atlasForwardMockupFidelityActive {
            resolved = [0.76, 0.75, 0.62, 0.68, 0.47, 0.34, 0.24]
        } else if let values = item?.points.suffix(7).map(\.estimatedQuantity), values.isEmpty == false {
            resolved = Array(values)
        } else {
            resolved = [0.76, 0.75, 0.62, 0.68, 0.47, 0.34, 0.24]
        }
        let minValue = resolved.min() ?? 0
        let maxValue = resolved.max() ?? 1
        let range = max(maxValue - minValue, 0.01)
        let step = size.width / CGFloat(max(resolved.count - 1, 1))
        return resolved.enumerated().map { index, value in
            let normalized = (value - minValue) / range
            return CGPoint(
                x: CGFloat(index) * step,
                y: size.height - (CGFloat(normalized) * (size.height * 0.62)) - (size.height * 0.2)
            )
        }
    }
}

private struct AtlasForwardSupportRingGrid: View {
    let model: AtlasAppModel

    var body: some View {
        HStack(spacing: 8) {
            AtlasForwardRingTile(
                title: "Protein",
                value: proteinProgress,
                center: proteinCenter,
                detail: proteinDetail,
                tint: AtlasPalette.success,
                systemImage: "leaf.fill"
            )
            AtlasForwardRingTile(
                title: "Hydration",
                value: hydrationProgress,
                center: hydrationCenter,
                detail: hydrationDetail,
                tint: Color(red: 0.15, green: 0.58, blue: 0.9),
                systemImage: "drop"
            )
            AtlasForwardRingTile(
                title: "Workout",
                value: workoutProgress,
                center: workoutCenter,
                detail: workoutDetail,
                tint: AtlasPalette.reward,
                systemImage: "dumbbell.fill"
            )
        }
    }

    private var proteinTarget: AtlasNutritionTargetSnapshot? {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .proteinMeals })
    }

    private var hydrationTarget: AtlasNutritionTargetSnapshot? {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .hydrationCheckins })
    }

    private var workoutGoal: AtlasRewardGoalSnapshot? {
        model.rewardsSnapshot.goals.first(where: { $0.kind == .weeklyWorkouts })
    }

    private var proteinProgress: Double { proteinTarget?.progress ?? 0 }
    private var hydrationProgress: Double { hydrationTarget?.progress ?? 0 }
    private var workoutProgress: Double {
        if let workoutGoal {
            return workoutGoal.progress
        }
        return model.insightsSnapshot.recentWorkoutEntries.isEmpty ? 0 : min(1, Double(model.insightsSnapshot.recentWorkoutEntries.count) / 3)
    }
    private var proteinCenter: String { "\(proteinGrams) g" }
    private var hydrationCenter: String { hydrationLiters.formatted(.number.precision(.fractionLength(1))) + " L" }
    private var workoutCenter: String { "\(workoutMinutes)" }
    private var proteinDetail: String { "of 120 g" }
    private var hydrationDetail: String { "of 2.5 L" }
    private var workoutDetail: String { "of 45 min" }

    private var proteinGrams: Int {
        let logged = proteinTarget?.currentValue ?? model.insightsSnapshot.nutritionSnapshot.recentMealCount
        return min(120, max(0, logged) * 42)
    }

    private var hydrationLiters: Double {
        let logged = hydrationTarget?.currentValue ?? 0
        return min(2.5, Double(max(0, logged)) * 0.8)
    }

    private var workoutMinutes: Int {
        let logged = workoutGoal.map { Int($0.currentValue) } ?? model.insightsSnapshot.recentWorkoutEntries.count
        return min(45, max(0, logged) * 15)
    }
}

private struct AtlasForwardRingTile: View {
    let title: String
    let value: Double
    let center: String
    let detail: String
    let tint: Color
    let systemImage: String

    var body: some View {
        AtlasForwardCard(padding: atlasForwardMockupFidelityActive ? 9 : 10) {
            VStack(spacing: 0) {
                HStack(spacing: 5) {
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(tint)
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Spacer(minLength: 0)
                }

                Spacer(minLength: 8)

                ZStack {
                    Circle()
                        .stroke(tint.opacity(0.14), lineWidth: atlasForwardMockupFidelityActive ? 6.5 : 7)
                    Circle()
                        .trim(from: 0, to: min(max(value, 0), 1))
                        .stroke(tint, style: StrokeStyle(lineWidth: atlasForwardMockupFidelityActive ? 6.5 : 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text(center)
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(AtlasPalette.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                        Text(detail)
                            .font(.system(size: 10.5, weight: .bold, design: .default))
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
                .frame(width: atlasForwardMockupFidelityActive ? 82 : 86, height: atlasForwardMockupFidelityActive ? 82 : 86)
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer(minLength: 2)
            }
            .frame(maxWidth: .infinity, minHeight: atlasForwardMockupFidelityActive ? 128 : 136, alignment: .center)
        }
    }
}

private struct AtlasForwardInventoryRunwayCard: View {
    let model: AtlasAppModel

    var body: some View {
        Button {
            model.open(.inventory)
        } label: {
            AtlasForwardCard(padding: atlasForwardMockupFidelityActive ? 10 : 12) {
                HStack(spacing: atlasForwardMockupFidelityActive ? 10 : 12) {
                    Image(systemName: "testtube.2")
                        .foregroundStyle(AtlasPalette.primary)
                        .frame(width: atlasForwardMockupFidelityActive ? 32 : 34, height: atlasForwardMockupFidelityActive ? 32 : 34)
                        .background(AtlasPalette.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Inventory Runway")
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(inventoryDetail)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(inventoryHeadline)
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(model.inventorySnapshot.lowStockCount > 0 ? AtlasPalette.warning : AtlasPalette.textPrimary)
                            .lineLimit(1)
                        Text(inventoryRunwayDetail)
                            .atlasTextRole(.metricLabel)
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .lineLimit(1)
                    }

                    Image(systemName: "chevron.right")
                        .foregroundStyle(AtlasPalette.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var inventoryHeadline: String {
        if atlasForwardMockupFidelityActive {
            return "12 doses"
        }
        if model.inventorySnapshot.lowStockCount > 0 {
            return "\(model.inventorySnapshot.lowStockCount) low"
        }
        if let vial = model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil }) {
            return vial.quantityLabel
        }
        return "Ready"
    }

    private var inventoryRunwayDetail: String {
        if atlasForwardMockupFidelityActive {
            return "~28 days left"
        }
        if let vial = model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil }) {
            return vial.projectedDepletionLabel ?? vial.autoDecrementLabel ?? "Runway ready"
        }
        return "Add inventory"
    }

    private var inventoryDetail: String {
        if atlasForwardMockupFidelityActive {
            return "Tirzepatide 10 mg"
        }
        if let vial = model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil }) {
            return vial.label
        }
        return "Track vials, supplies, and depletion."
    }
}

private struct AtlasForwardQuickToolsCard: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Protocol Tools")
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                HStack(spacing: 8) {
                    toolButton("Levels", "waveform.path.ecg") {
                        if let protocolID = model.todaySnapshot.nextDue?.protocolID ?? model.libraryProtocols.first?.id {
                            model.open(.medicationLevels(protocolID))
                        }
                    }
                    toolButton("Calculator", "function") {
                        model.open(.calculator)
                    }
                    toolButton("Library", "books.vertical.fill") {
                        model.activeTab = .library
                    }
                }
            }
        }
    }

    private func toolButton(_ title: String, _ systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .semibold))
                Text(title)
                    .atlasTextRole(.metricLabel)
            }
            .foregroundStyle(AtlasPalette.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AtlasPalette.secondaryFill.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct AtlasForwardCaptureFocusRail: View {
    let selectedKind: AtlasQuickCaptureKind
    let onSelect: (AtlasQuickCaptureKind) -> Void

    private let kinds: [AtlasQuickCaptureKind] = [.shot, .context, .protein, .hydration, .weight, .symptom, .progressPhoto]
    private let columns = [
        GridItem(.adaptive(minimum: 72), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(kinds) { kind in
                Button {
                    onSelect(kind)
                } label: {
                    Label(railTitle(for: kind), systemImage: kind.systemImage)
                        .atlasTextRole(.deckEyebrow)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .foregroundStyle(selectedKind == kind ? .white : AtlasPalette.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(selectedKind == kind ? AtlasPalette.primary : AtlasPalette.surfaceTop)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func railTitle(for kind: AtlasQuickCaptureKind) -> String {
        switch kind {
        case .hydration:
            return "Water"
        case .progressPhoto:
            return "Photo"
        default:
            return kind.title
        }
    }
}

private struct AtlasForwardShotCaptureCard: View {
    let model: AtlasAppModel
    var onSelectKind: (AtlasQuickCaptureKind) -> Void = { _ in }
    @State private var painLevel = 3.0
    @State private var selectedSideEffects: Set<String> = ["None"]
    @State private var note = ""
    @State private var selectedSiteID: String?
    @State private var siteOptions: AtlasProtocolSiteOptions?
    @State private var didLogShot = false
    @State private var isLoggingShot = false
    @State private var completedAftercare: Set<AtlasForwardAftercareKind> = []
    @State private var loggedShotSummary: AtlasForwardLoggedShotSummary?

    private let sideEffects = ["None", "Nausea", "Fatigue", "Headache", "Bloating", "GI Upset", "Injection Site", "Other"]

    var body: some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 9) {
                rewardBanner

                if didLogShot {
                    ritualProgress
                    shotConfirmationPanel
                    aftercareRewardCard
                } else if occurrence == nil {
                    caughtUpState
                } else {
                    shotHeader
                    Divider()
                    if isInjectionProtocol {
                        injectionSiteSection
                        Divider()
                        painSection
                    } else {
                        routeConfirmationSection
                    }
                    Divider()
                    sideEffectsSection
                    Divider()
                    notesSection
                    Divider()
                    supplyPreview
                    markTakenButton
                }
            }
        }
        .task(id: occurrence?.protocolID) {
            guard let protocolID = occurrence?.protocolID else {
                siteOptions = nil
                selectedSiteID = nil
                return
            }
            siteOptions = await model.siteOptions(for: protocolID)
            selectedSiteID = siteOptions?.suggestedSiteID
        }
        .onChange(of: occurrence?.id) { _, _ in
            guard loggedShotSummary == nil else { return }
            withAnimation(AtlasMotion.interactiveSpring) {
                didLogShot = false
                completedAftercare.removeAll()
            }
        }
    }

    private var occurrence: AtlasScheduledOccurrence? {
        model.todaySnapshot.nextDue ?? model.todaySnapshot.overdue.first
    }

    private var rewardBanner: some View {
        HStack(spacing: 8) {
            if let selection = rewardBannerSelection,
               let stage = rewardBannerStage {
                AtlasForwardMascotArt(selection: selection, stage: stage, size: 50)
                    .frame(width: 50, height: 32)
            }
            Text(didLogShot ? "Great consistency!" : "Great consistency!")
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)
            Spacer()
            Text("+12 XP")
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.reward)
            Image(systemName: "star.fill")
                .foregroundStyle(AtlasPalette.reward)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(AtlasPalette.reward.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var rewardBannerSelection: AtlasMascotSelection? {
        if atlasForwardMockupFidelityActive {
            return .aetherion
        }
        return atlasAmbientMascotSelection(settingsSnapshot: model.settingsSnapshot)
    }

    private var rewardBannerStage: AtlasMascotStage? {
        if atlasForwardMockupFidelityActive {
            return .stage1
        }
        return atlasAmbientMascotStage(settingsSnapshot: model.settingsSnapshot, rewardsSnapshot: model.rewardsSnapshot)
    }

    private var ritualProgress: some View {
        HStack(spacing: 8) {
            ritualStep("Shot", isActive: true, isComplete: didLogShot)
            ritualStep("Site", isActive: selectedSiteID != nil, isComplete: didLogShot && selectedSiteID != nil)
            ritualStep("Effects", isActive: selectedSideEffects != ["None"] || painLevel > 0, isComplete: didLogShot)
            ritualStep("Aftercare", isActive: didLogShot, isComplete: completedAftercare.isEmpty == false)
        }
    }

    private func ritualStep(_ title: String, isActive: Bool, isComplete: Bool) -> some View {
        VStack(spacing: 5) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(isComplete ? AtlasPalette.success : (isActive ? AtlasPalette.primary : AtlasPalette.textTertiary))
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .default))
                .foregroundStyle(isActive ? AtlasPalette.textPrimary : AtlasPalette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var shotHeader: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "testtube.2")
                .foregroundStyle(AtlasPalette.primary)
                .frame(width: 32, height: 32)
                .background(AtlasPalette.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(shotTitle)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(shotDetail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
            Spacer()
            Label(shotTime, systemImage: "clock")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textPrimary)
        }
    }

    private var beforeShotSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Before You Log")
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Spacer()
                AtlasStatusBadge("One minute", tint: AtlasPalette.primary)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                AtlasForwardMiniSignalTile(title: "Due", value: shotTime, systemImage: "clock.fill", tint: AtlasPalette.primary)
                AtlasForwardMiniSignalTile(title: "Site", value: selectedSiteName, systemImage: "figure.arms.open", tint: AtlasPalette.success)
                AtlasForwardMiniSignalTile(title: "Dose", value: occurrence?.doseLabel ?? "Dose saved", systemImage: "syringe.fill", tint: AtlasPalette.reward)
                AtlasForwardMiniSignalTile(title: "Vial after", value: vialAfterHeadline, systemImage: "testtube.2", tint: linkedVial?.isLowStock == true ? AtlasPalette.warning : AtlasPalette.success)
            }
        }
        .padding(12)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var injectionSiteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Injection Site")
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)
            HStack(alignment: .center, spacing: 8) {
                AtlasForwardBodySiteMap(selectedSiteID: displayedSelectedSiteID, sites: siteOptions?.sites ?? [])
                    .frame(maxWidth: .infinity)
                VStack(spacing: 5) {
                    ForEach(siteButtons, id: \.id) { site in
                        Button(site.name) {
                            selectedSiteID = site.id
                        }
                        .buttonStyle(AtlasForwardSiteButtonStyle(isSelected: isDisplayedSiteSelected(site)))
                    }
                }
                .frame(width: 108)
            }
        }
    }

    private var painSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pain Level")
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)
            HStack {
                Text("0")
                Slider(value: $painLevel, in: 0...10, step: 1)
                    .tint(AtlasPalette.primary)
                Text("10")
                Text("\(Int(painLevel.rounded()))")
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .frame(width: 48, height: 30)
                    .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .atlasTextRole(.supporting)
            .foregroundStyle(AtlasPalette.textSecondary)
        }
    }

    private var routeConfirmationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Protocol Check")
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)

            HStack(spacing: 8) {
                AtlasForwardMiniSignalTile(title: "Route", value: routeDisplayLabel, systemImage: routeSystemImage, tint: AtlasPalette.primary)
                AtlasForwardMiniSignalTile(title: "Supply", value: supplyDisplayLabel, systemImage: supplySystemImage, tint: AtlasPalette.reward)
            }

        }
        .padding(10)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var sideEffectsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text("Side Effects")
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text("(optional)")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 5)], spacing: 5) {
                ForEach(sideEffects, id: \.self) { effect in
                    Button(effect) {
                        toggleEffect(effect)
                    }
                    .buttonStyle(AtlasForwardChipButtonStyle(isSelected: selectedSideEffects.contains(effect)))
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text("Notes")
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text("(optional)")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
            TextField("How are you feeling?", text: $note, axis: .vertical)
                .atlasForwardCompactInput()
        }
    }

    private var supplyPreview: some View {
        HStack(spacing: 10) {
            Image(systemName: supplySystemImage)
                .foregroundStyle(AtlasPalette.primary)
            VStack(alignment: .leading, spacing: 3) {
                Text(supplyPreviewTitle)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(supplyDetail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(supplyHeadline)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(supplyAfterHeadline)
                    .atlasTextRole(.metricLabel)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
        }
        .padding(8)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var markTakenButton: some View {
        Button {
            guard let occurrence else { return }
            let summary = AtlasForwardLoggedShotSummary(
                occurrenceID: occurrence.id,
                protocolID: occurrence.protocolID,
                title: shotTitle,
                doseLabel: occurrence.doseLabel,
                timeLabel: shotTime,
                siteName: isInjectionProtocol ? selectedSiteName : routeDisplayLabel,
                vialBeforeLabel: supplyHeadline,
                vialAfterLabel: supplyAfterHeadline,
                painLabel: isInjectionProtocol ? "\(Int(painLevel.rounded()))/10" : "n/a"
            )
            AtlasFeedback.notify(.success)
            isLoggingShot = true
            Task {
                await model.logOccurrence(
                    AtlasOccurrenceLogRequest(
                        occurrenceID: occurrence.id,
                        protocolID: occurrence.protocolID,
                        action: .taken,
                        siteID: selectedSiteID,
                        note: logNote
                    )
                )
                await MainActor.run {
                    loggedShotSummary = summary
                    note = ""
                    selectedSideEffects = ["None"]
                    painLevel = 0
                    withAnimation(AtlasMotion.interactiveSpring) {
                        didLogShot = true
                    }
                    isLoggingShot = false
                }
            }
        } label: {
            Label(didLogShot ? "Shot Logged" : "Mark as Taken", systemImage: didLogShot ? "checkmark.circle.fill" : "syringe.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(AtlasPrimaryButtonStyle())
        .disabled(occurrence == nil || isLoggingShot || didLogShot)
    }

    private var shotConfirmationPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(AtlasPalette.success)
                    .frame(width: 32, height: 32)
                    .background(AtlasPalette.success.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Shot confirmed")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(loggedShotSummary?.confirmationDetail ?? confirmationDetail)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }

            HStack(spacing: 8) {
                AtlasForwardMiniSignalTile(title: isInjectionProtocol ? "Site" : "Route", value: loggedShotSummary?.siteName ?? selectedSiteName, systemImage: isInjectionProtocol ? "figure.arms.open" : routeSystemImage, tint: AtlasPalette.primary)
                AtlasForwardMiniSignalTile(title: supplyConfirmationTitle, value: loggedShotSummary?.vialAfterLabel ?? supplyAfterHeadline, systemImage: supplySystemImage, tint: linkedVial?.isLowStock == true ? AtlasPalette.warning : AtlasPalette.success)
            }

            HStack(spacing: 8) {
                Button("Next ritual") {
                    withAnimation(AtlasMotion.interactiveSpring) {
                        loggedShotSummary = nil
                        didLogShot = false
                        completedAftercare.removeAll()
                    }
                }
                .buttonStyle(AtlasSecondaryButtonStyle())

                Button("View plan") {
                    if let protocolID = loggedShotSummary?.protocolID ?? occurrence?.protocolID {
                        model.open(.protocolDetail(protocolID))
                    }
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
            }
        }
        .padding(10)
        .background(AtlasPalette.success.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var caughtUpState: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AtlasPalette.success)
                    .frame(width: 42, height: 42)
                    .background(AtlasPalette.success.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("No shot due")
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(AtlasPalette.textPrimary)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                aftercareButton(.protein)
                aftercareButton(.hydration)
                aftercareButton(.workout)
                aftercareButton(.companion)
            }
        }
        .padding(12)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var aftercareRewardCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AtlasPalette.reward)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Aftercare quests unlocked")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                aftercareButton(.protein)
                aftercareButton(.hydration)
                aftercareButton(.workout)
                aftercareButton(.companion)
            }
        }
        .padding(12)
        .background(AtlasPalette.reward.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func aftercareButton(_ kind: AtlasForwardAftercareKind) -> some View {
        Button {
            handleAftercare(kind)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: completedAftercare.contains(kind) ? "checkmark.circle.fill" : kind.systemImage)
                    .foregroundStyle(completedAftercare.contains(kind) ? AtlasPalette.success : kind.tint)
                Text(kind.title)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(AtlasPalette.surfaceTop.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var shotTitle: String {
        if atlasForwardMockupFidelityActive {
            return "Tirzepatide"
        }
        guard var title = occurrence?.canonicalTitle else {
            return "No due shot"
        }
        for suffix in [" Weekly", " Daily", " Monthly", " Protocol"] {
            if title.hasSuffix(suffix) {
                title.removeLast(suffix.count)
                break
            }
        }
        return title
    }

    private var shotDetail: String {
        guard let occurrence else {
            return "Your protocol schedule is caught up."
        }
        return [occurrence.doseLabel, routeDisplayLabel].compactMap { $0 }.joined(separator: "  •  ")
    }

    private var shotTime: String {
        if atlasForwardMockupFidelityActive {
            return "Today, 12:30 PM"
        }
        return occurrence?.scheduledAt.formatted(date: .omitted, time: .shortened) ?? "Today"
    }

    private var confirmationDetail: String {
        let site = selectedSiteName == "Choose site" ? "site not selected" : selectedSiteName
        let primary = isInjectionProtocol ? site : routeDisplayLabel
        return "\(primary) saved. \(supplyDetail)"
    }

    private var selectedSiteName: String {
        if let selectedSiteID,
           let site = siteButtons.first(where: { $0.id == selectedSiteID }) {
            return site.name
        }
        return "Choose site"
    }

    private var displayedSelectedSiteID: String? {
        atlasForwardMockupFidelityActive ? "abdomen" : selectedSiteID
    }

    private func isDisplayedSiteSelected(_ site: AtlasForwardSiteOption) -> Bool {
        if atlasForwardMockupFidelityActive {
            return site.name == "Abdomen"
        }
        return displayedSelectedSiteID == site.id
    }

    private var siteButtons: [AtlasForwardSiteOption] {
        let sites = siteOptions?.sites ?? []
        return [
            siteOption(named: "Abdomen", fallbackID: "abdomen", sites: sites),
            siteOption(named: "Right Thigh", fallbackID: "right-thigh", sites: sites),
            siteOption(named: "Left Thigh", fallbackID: "left-thigh", sites: sites),
            siteOption(named: "Right Arm", fallbackID: "right-arm", sites: sites),
            siteOption(named: "Left Arm", fallbackID: "left-arm", sites: sites),
            siteOption(named: "Other", fallbackID: "other", sites: sites)
        ]
    }

    private func siteOption(named name: String, fallbackID: String, sites: [AtlasSiteSummary]) -> AtlasForwardSiteOption {
        let normalizedName = normalizedSiteName(name)
        if let match = sites.first(where: { normalizedSiteName($0.name).contains(normalizedName) || normalizedName.contains(normalizedSiteName($0.name)) }) {
            return AtlasForwardSiteOption(id: match.id, name: name)
        }
        return AtlasForwardSiteOption(id: fallbackID, name: name)
    }

    private func normalizedSiteName(_ name: String) -> String {
        name.lowercased().replacingOccurrences(of: " ", with: "-")
    }

    private var linkedVial: AtlasVialSummary? {
        guard let protocolID = occurrence?.protocolID ?? loggedShotSummary?.protocolID else {
            return model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil })
        }
        return model.inventorySnapshot.vials.first(where: { $0.linkedProtocolID == protocolID && $0.archivedAt == nil })
            ?? model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil })
    }

    private var protocolDetail: AtlasProtocolDetailSnapshot? {
        guard let protocolID = occurrence?.protocolID ?? loggedShotSummary?.protocolID else {
            return nil
        }
        return model.protocolDetails[protocolID]
    }

    private var isInjectionProtocol: Bool {
        if atlasForwardMockupFidelityActive {
            return true
        }
        if let route = protocolDetail?.editableDraft.administrationRoute {
            return route == .injection
        }
        let routeLabel = protocolDetail?.administrationLabel ?? occurrence?.kindLabel ?? ""
        return routeLabel.localizedCaseInsensitiveContains("glp")
            || routeLabel.localizedCaseInsensitiveContains("inject")
            || routeLabel.localizedCaseInsensitiveContains("subq")
            || routeLabel.localizedCaseInsensitiveContains("subcutaneous")
    }

    private var routeDisplayLabel: String {
        if atlasForwardMockupFidelityActive {
            return "SubQ"
        }
        return protocolDetail?.administrationLabel
            ?? protocolDetail?.editableDraft.administrationRoute.forwardDisplayLabel
            ?? (occurrence?.kindLabel.localizedCaseInsensitiveContains("glp") == true ? "SubQ" : occurrence?.kindLabel)
            ?? "Route"
    }

    private var routeSystemImage: String {
        switch protocolDetail?.editableDraft.administrationRoute ?? (isInjectionProtocol ? .injection : .other) {
        case .injection: return "syringe.fill"
        case .oral, .sublingual: return "pills.fill"
        case .nasal: return "nose.fill"
        case .topical, .transdermal: return "hand.raised.fill"
        case .other: return "checklist"
        }
    }

    private var supplyDisplayLabel: String {
        if atlasForwardMockupFidelityActive {
            return "Vial"
        }
        return protocolDetail?.supplyLabel
            ?? protocolDetail?.editableDraft.supplyType?.forwardDisplayLabel
            ?? (linkedVial == nil ? "Supply" : "Vial")
    }

    private var supplySystemImage: String {
        switch protocolDetail?.editableDraft.supplyType {
        case .pen: return "pencil.tip"
        case .bottle, .blisterPack: return "pills.fill"
        case .syringe: return "syringe.fill"
        case .vial, .none: return "testtube.2"
        case .other: return "shippingbox.fill"
        }
    }

    private var supplyPreviewTitle: String {
        supplyDisplayLabel == "Vial" ? "Vial Remaining" : "\(supplyDisplayLabel) Remaining"
    }

    private var supplyConfirmationTitle: String {
        supplyDisplayLabel == "Vial" ? "Vial after" : "Supply after"
    }

    private var supplyHeadline: String {
        if supplyDisplayLabel == "Vial" || linkedVial != nil {
            return vialHeadline
        }
        if let doses = protocolDetail?.editableDraft.dosesPerSupply {
            return "\(doses) doses"
        }
        return "Tracked"
    }

    private var supplyDetail: String {
        if supplyDisplayLabel == "Vial" || linkedVial != nil {
            return vialDetail
        }
        return [shotTitle, supplyDisplayLabel].filter { $0.isEmpty == false }.joined(separator: "  •  ")
    }

    private var supplyAfterHeadline: String {
        if supplyDisplayLabel == "Vial" || linkedVial != nil {
            return vialAfterHeadline
        }
        return "Logged"
    }

    private var vialHeadline: String {
        if atlasForwardMockupFidelityActive {
            return "12 doses"
        }
        return linkedVial?.quantityLabel ?? "No vial"
    }

    private var vialDetail: String {
        if atlasForwardMockupFidelityActive {
            return "Tirzepatide 10 mg"
        }
        return linkedVial?.projectedDepletionLabel ?? linkedVial?.label ?? "Link inventory for dose countdowns."
    }

    private var vialAfterHeadline: String {
        if atlasForwardMockupFidelityActive {
            return "~28 days left"
        }
        guard let vial = linkedVial else {
            return "No vial"
        }
        guard let dose = occurrenceDoseAmount,
              dose > 0 else {
            return "Will update"
        }
        let nextRemaining = max(0, vial.remainingQuantity - dose)
        let formatted = nextRemaining.formatted(.number.precision(.fractionLength(0...2)))
        if vial.quantityUnit.isEmpty == false {
            return "\(formatted) \(vial.quantityUnit)"
        }
        return formatted
    }

    private var occurrenceDoseAmount: Double? {
        guard let doseLabel = occurrence?.doseLabel else { return nil }
        let scanner = Scanner(string: doseLabel)
        scanner.locale = Locale(identifier: "en_US_POSIX")
        return scanner.scanDouble()
    }

    private var logNote: String? {
        let effects = selectedSideEffects.sorted().joined(separator: ", ")
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let pieces = [
            isInjectionProtocol ? "Pain \(Int(painLevel.rounded()))/10" : "Route: \(routeDisplayLabel)",
            effects.isEmpty ? nil : "Effects: \(effects)",
            trimmed.isEmpty ? nil : trimmed
        ].compactMap { $0 }
        return pieces.isEmpty ? nil : pieces.joined(separator: "\n")
    }

    private func toggleEffect(_ effect: String) {
        if effect == "None" {
            selectedSideEffects = ["None"]
            return
        }
        selectedSideEffects.remove("None")
        if selectedSideEffects.contains(effect) {
            selectedSideEffects.remove(effect)
        } else {
            selectedSideEffects.insert(effect)
        }
        if selectedSideEffects.isEmpty {
            selectedSideEffects = ["None"]
        }
    }

    private func handleAftercare(_ kind: AtlasForwardAftercareKind) {
        AtlasFeedback.selection()
        switch kind {
        case .protein:
            Task {
                await model.saveContextEntry(
                    AtlasTodayContextShortcut.proteinMeal.makeDraft(
                        loggedAt: model.currentDate(),
                        protocolID: occurrence?.protocolID ?? loggedShotSummary?.protocolID
                    )
                )
                await MainActor.run {
                    completedAftercare.insert(kind)
                }
            }
        case .hydration:
            Task {
                await model.saveContextEntry(
                    AtlasTodayContextShortcut.hydration.makeDraft(
                        loggedAt: model.currentDate(),
                        protocolID: occurrence?.protocolID ?? loggedShotSummary?.protocolID
                    )
                )
                await MainActor.run {
                    completedAftercare.insert(kind)
                }
            }
        case .workout:
            completedAftercare.insert(kind)
            onSelectKind(.context)
        case .companion:
            completedAftercare.insert(kind)
            model.open(.mascot)
        }
    }
}

private enum AtlasForwardAftercareKind: Hashable {
    case protein
    case hydration
    case workout
    case companion

    var title: String {
        switch self {
        case .protein:
            return "Protein"
        case .hydration:
            return "Hydration"
        case .workout:
            return "Workout"
        case .companion:
            return "Reward"
        }
    }

    var systemImage: String {
        switch self {
        case .protein:
            return "bolt.heart.fill"
        case .hydration:
            return "drop.fill"
        case .workout:
            return "dumbbell.fill"
        case .companion:
            return "sparkles"
        }
    }

    var tint: Color {
        switch self {
        case .protein:
            return AtlasPalette.success
        case .hydration:
            return Color(red: 0.15, green: 0.58, blue: 0.9)
        case .workout:
            return AtlasPalette.reward
        case .companion:
            return AtlasPalette.primary
        }
    }
}

private struct AtlasForwardSiteOption: Identifiable {
    let id: String
    let name: String
}

private struct AtlasForwardLoggedShotSummary {
    let occurrenceID: String
    let protocolID: String
    let title: String
    let doseLabel: String?
    let timeLabel: String
    let siteName: String
    let vialBeforeLabel: String
    let vialAfterLabel: String
    let painLabel: String

    var confirmationDetail: String {
        let site = siteName == "Choose site" ? "Site not selected" : siteName
        let dose = doseLabel ?? "Dose"
        return "\(title) \(dose) saved at \(timeLabel). \(site). Vial \(vialBeforeLabel) to \(vialAfterLabel). Pain \(painLabel)."
    }
}

private struct AtlasForwardBodySiteMap: View {
    let selectedSiteID: String?
    let sites: [AtlasSiteSummary]

    var body: some View {
        HStack(spacing: 14) {
            anatomyFigure(surface: .front)
            anatomyFigure(surface: .back)
        }
        .frame(height: 156)
    }

    private func anatomyFigure(surface: AtlasForwardAnatomySurface) -> some View {
        ZStack {
            AtlasForwardAnatomyOutline(surface: surface)
                .stroke(AtlasPalette.textTertiary.opacity(0.48), lineWidth: 1)
                .frame(width: 84, height: 152)

            ForEach(zones(for: surface)) { zone in
                RoundedRectangle(cornerRadius: zone.cornerRadius, style: .continuous)
                    .fill(zone.isSelected ? AtlasPalette.primary.opacity(0.72) : AtlasPalette.success.opacity(0.42))
                    .frame(width: zone.size.width, height: zone.size.height)
                    .offset(zone.offset)
            }
        }
        .frame(width: 90, height: 156)
    }

    private func zones(for surface: AtlasForwardAnatomySurface) -> [AtlasForwardAnatomyZone] {
        switch surface {
        case .front:
            [
                .init(id: "abdomen", siteNames: ["abdomen"], size: CGSize(width: 35, height: 15), offset: CGSize(width: 0, height: -2), cornerRadius: 6, selectedSiteID: selectedSiteID, sites: sites),
                .init(id: "rightThighFront", siteNames: ["right thigh"], size: CGSize(width: 15, height: 35), offset: CGSize(width: -18, height: 47), cornerRadius: 8, selectedSiteID: selectedSiteID, sites: sites),
                .init(id: "leftThighFront", siteNames: ["left thigh"], size: CGSize(width: 15, height: 35), offset: CGSize(width: 18, height: 47), cornerRadius: 8, selectedSiteID: selectedSiteID, sites: sites)
            ]
        case .back:
            [
                .init(id: "rightArmBack", siteNames: ["right arm"], size: CGSize(width: 14, height: 35), offset: CGSize(width: -35, height: 18), cornerRadius: 8, selectedSiteID: selectedSiteID, sites: sites),
                .init(id: "leftArmBack", siteNames: ["left arm"], size: CGSize(width: 14, height: 35), offset: CGSize(width: 35, height: 18), cornerRadius: 8, selectedSiteID: selectedSiteID, sites: sites),
                .init(id: "rightThighBack", siteNames: ["right thigh"], size: CGSize(width: 15, height: 35), offset: CGSize(width: -17, height: 47), cornerRadius: 8, selectedSiteID: selectedSiteID, sites: sites),
                .init(id: "leftThighBack", siteNames: ["left thigh"], size: CGSize(width: 15, height: 35), offset: CGSize(width: 17, height: 47), cornerRadius: 8, selectedSiteID: selectedSiteID, sites: sites)
            ]
        }
    }
}

private enum AtlasForwardAnatomySurface {
    case front
    case back
}

private struct AtlasForwardAnatomyZone: Identifiable {
    let id: String
    let siteNames: [String]
    let size: CGSize
    let offset: CGSize
    let cornerRadius: CGFloat
    let isSelected: Bool

    init(
        id: String,
        siteNames: [String],
        size: CGSize,
        offset: CGSize,
        cornerRadius: CGFloat,
        selectedSiteID: String?,
        sites: [AtlasSiteSummary]
    ) {
        self.id = id
        self.siteNames = siteNames
        self.size = size
        self.offset = offset
        self.cornerRadius = cornerRadius

        guard let selectedSiteID,
              let site = sites.first(where: { $0.id == selectedSiteID }) else {
            self.isSelected = false
            return
        }

        let normalizedName = site.name.lowercased()
        self.isSelected = siteNames.contains { normalizedName.contains($0) }
    }
}

private struct AtlasForwardAnatomyOutline: Shape {
    let surface: AtlasForwardAnatomySurface

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let scaleX = rect.width / 72
        let scaleY = rect.height / 128

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * scaleX, y: rect.minY + y * scaleY)
        }

        func ellipse(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
            path.addEllipse(in: CGRect(x: rect.minX + x * scaleX, y: rect.minY + y * scaleY, width: width * scaleX, height: height * scaleY))
        }

        ellipse(27, 5, 18, 20)

        path.move(to: point(32, 25))
        path.addCurve(to: point(24, 31), control1: point(30, 26), control2: point(26, 28))
        path.addCurve(to: point(23, 58), control1: point(21, 40), control2: point(21, 50))
        path.addCurve(to: point(27, 72), control1: point(23, 65), control2: point(24, 69))
        path.addCurve(to: point(35, 80), control1: point(30, 74), control2: point(33, 77))

        path.move(to: point(40, 25))
        path.addCurve(to: point(48, 31), control1: point(42, 26), control2: point(46, 28))
        path.addCurve(to: point(49, 58), control1: point(51, 40), control2: point(51, 50))
        path.addCurve(to: point(45, 72), control1: point(49, 65), control2: point(48, 69))
        path.addCurve(to: point(37, 80), control1: point(42, 74), control2: point(39, 77))

        path.move(to: point(24, 31))
        path.addCurve(to: point(12, 45), control1: point(17, 34), control2: point(14, 39))
        path.addCurve(to: point(10, 82), control1: point(9, 58), control2: point(9, 72))
        path.addCurve(to: point(16, 85), control1: point(10, 86), control2: point(14, 87))
        path.addCurve(to: point(21, 58), control1: point(19, 76), control2: point(20, 66))

        path.move(to: point(48, 31))
        path.addCurve(to: point(60, 45), control1: point(55, 34), control2: point(58, 39))
        path.addCurve(to: point(62, 82), control1: point(63, 58), control2: point(63, 72))
        path.addCurve(to: point(56, 85), control1: point(62, 86), control2: point(58, 87))
        path.addCurve(to: point(51, 58), control1: point(53, 76), control2: point(52, 66))

        path.move(to: point(31, 77))
        path.addCurve(to: point(27, 104), control1: point(29, 86), control2: point(28, 96))
        path.addCurve(to: point(23, 122), control1: point(27, 112), control2: point(25, 118))
        path.addCurve(to: point(32, 124), control1: point(25, 126), control2: point(30, 126))
        path.addCurve(to: point(35, 82), control1: point(34, 111), control2: point(35, 96))

        path.move(to: point(41, 77))
        path.addCurve(to: point(45, 104), control1: point(43, 86), control2: point(44, 96))
        path.addCurve(to: point(49, 122), control1: point(45, 112), control2: point(47, 118))
        path.addCurve(to: point(40, 124), control1: point(47, 126), control2: point(42, 126))
        path.addCurve(to: point(37, 82), control1: point(38, 111), control2: point(37, 96))

        if surface == .back {
            path.move(to: point(31, 31))
            path.addCurve(to: point(41, 31), control1: point(34, 29), control2: point(38, 29))
            path.move(to: point(36, 37))
            path.addLine(to: point(36, 69))
            path.move(to: point(31, 47))
            path.addLine(to: point(41, 47))
        } else {
            path.move(to: point(31, 35))
            path.addCurve(to: point(41, 35), control1: point(34, 37), control2: point(38, 37))
            path.move(to: point(31, 58))
            path.addCurve(to: point(41, 58), control1: point(34, 60), control2: point(38, 60))
        }

        return path
    }
}

private struct AtlasForwardWeightCaptureCard: View {
    let model: AtlasAppModel
    @State private var value = ""
    @State private var unit: AtlasWeightUnit = .lb

    var body: some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Weight")
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(model.insightsSnapshot.weightTrend.latestLabel ?? "Add today as a clean trend anchor.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                HStack(spacing: 10) {
                    TextField("Weight", text: $value)
                        .keyboardType(.decimalPad)
                        .atlasStandaloneInputSurface()
                    Picker("Unit", selection: $unit) {
                        Text("lb").tag(AtlasWeightUnit.lb)
                        Text("kg").tag(AtlasWeightUnit.kg)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 132)
                }
                Button("Save Weight") {
                    guard let parsed = Double(value), parsed > 0 else { return }
                    Task {
                        await model.saveWeightEntry(AtlasWeightEntryDraft(loggedAt: model.currentDate(), value: parsed, unit: unit))
                        value = ""
                    }
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
                .disabled(Double(value) == nil)
            }
        }
    }
}

private struct AtlasForwardSymptomCaptureCard: View {
    let model: AtlasAppModel
    @State private var appetite: AtlasForwardCheckInAppetite = .typical
    @State private var energy: AtlasForwardCheckInSignal = .steady
    @State private var gi: AtlasForwardCheckInGI = .calm
    @State private var sleep: AtlasForwardCheckInSignal = .steady
    @State private var note = ""
    @State private var didSave = false

    var body: some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Protocol Check-in")
                            .atlasTextRole(.cardTitle)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Spacer()
                    Text("Between dose")
                        .atlasTextRole(.metricLabel)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }

                AtlasForwardCheckInSignalRow(title: "Appetite", value: appetite.title, systemImage: "fork.knife", tint: AtlasPalette.success) {
                    ForEach(AtlasForwardCheckInAppetite.allCases) { item in
                        Button(item.title) {
                            appetite = item
                            didSave = false
                        }
                        .buttonStyle(AtlasForwardChipButtonStyle(isSelected: appetite == item))
                    }
                }

                AtlasForwardCheckInSignalRow(title: "Energy", value: energy.title, systemImage: "bolt.heart.fill", tint: AtlasPalette.reward) {
                    ForEach(AtlasForwardCheckInSignal.allCases) { item in
                        Button(item.title) {
                            energy = item
                            didSave = false
                        }
                        .buttonStyle(AtlasForwardChipButtonStyle(isSelected: energy == item))
                    }
                }

                AtlasForwardCheckInSignalRow(title: "GI", value: gi.title, systemImage: "waveform.path.ecg", tint: gi == .calm ? AtlasPalette.success : AtlasPalette.warning) {
                    ForEach(AtlasForwardCheckInGI.allCases) { item in
                        Button(item.title) {
                            gi = item
                            didSave = false
                        }
                        .buttonStyle(AtlasForwardChipButtonStyle(isSelected: gi == item))
                    }
                }

                AtlasForwardCheckInSignalRow(title: "Sleep", value: sleep.title, systemImage: "moon.fill", tint: Color(red: 0.15, green: 0.58, blue: 0.9)) {
                    ForEach(AtlasForwardCheckInSignal.allCases) { item in
                        Button(item.title) {
                            sleep = item
                            didSave = false
                        }
                        .buttonStyle(AtlasForwardChipButtonStyle(isSelected: sleep == item))
                    }
                }

                TextField("Notes (optional)", text: $note, axis: .vertical)
                    .atlasStandaloneInputSurface()
                    .onChange(of: note) { _, _ in didSave = false }

                Button {
                    saveCheckIn()
                } label: {
                    Label(didSave ? "Check-in Saved" : "Save Check-in", systemImage: didSave ? "checkmark.circle.fill" : "waveform.path.ecg")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
            }
        }
    }

    private func saveCheckIn() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteValue = trimmedNote.isEmpty ? nil : trimmedNote
        let loggedAt = model.currentDate()

        Task {
            await model.saveContextEntry(
                AtlasContextEntryDraft(
                    loggedAt: loggedAt,
                    appetite: appetite.domainValue,
                    giTags: gi.domainTags,
                    note: noteValue,
                    tags: ["between-dose-check-in", "appetite", "gi"]
                )
            )
            await model.saveSymptomEntry(
                AtlasSymptomEntryDraft(
                    loggedAt: loggedAt,
                    symptomKey: "Energy",
                    severity: energy.severity,
                    notes: noteValue
                )
            )
            await model.saveSymptomEntry(
                AtlasSymptomEntryDraft(
                    loggedAt: loggedAt,
                    symptomKey: "Sleep",
                    severity: sleep.severity,
                    notes: noteValue
                )
            )
            await MainActor.run {
                didSave = true
            }
        }
    }
}

private struct AtlasForwardCheckInSignalRow<Options: View>: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
    @ViewBuilder let options: () -> Options

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold, design: .default))
                    .foregroundStyle(tint)
                    .frame(width: 26, height: 26)
                    .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Spacer()
                Text(value)
                    .atlasTextRole(.metricLabel)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
            HStack(spacing: 7) {
                options()
            }
        }
        .padding(8)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private enum AtlasForwardCheckInAppetite: String, CaseIterable, Identifiable {
    case low
    case typical
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: "Low"
        case .typical: "Typical"
        case .high: "High"
        }
    }

    var domainValue: AtlasContextAppetiteState {
        switch self {
        case .low: .low
        case .typical: .typical
        case .high: .high
        }
    }
}

private enum AtlasForwardCheckInGI: String, CaseIterable, Identifiable {
    case calm
    case nausea
    case bloating
    case reflux

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm: "Calm"
        case .nausea: "Nausea"
        case .bloating: "Bloating"
        case .reflux: "Reflux"
        }
    }

    var domainTags: [AtlasContextGITag] {
        switch self {
        case .calm: [.calm]
        case .nausea: [.nausea]
        case .bloating: [.bloating]
        case .reflux: [.reflux]
        }
    }
}

private enum AtlasForwardCheckInSignal: String, CaseIterable, Identifiable {
    case low
    case steady
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: "Low"
        case .steady: "Steady"
        case .high: "High"
        }
    }

    var severity: Int {
        switch self {
        case .low: 2
        case .steady: 3
        case .high: 4
        }
    }
}

private struct AtlasForwardFoodCaptureCard: View {
    let model: AtlasAppModel
    @State private var mealText = ""

    var body: some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Food")
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)
                AtlasForwardFoodScoreCard(model: model)
                AtlasForwardNutritionTargetsCard(model: model)
                TextField("Type or dictate a meal", text: $mealText, axis: .vertical)
                    .atlasStandaloneInputSurface()
                if let suggestion = model.nutritionQuickCaptureSuggestion(for: mealText, loggedAt: model.currentDate()) {
                    AtlasCalloutRow(
                        systemImage: suggestion.symbolName,
                        title: suggestion.title,
                        detail: suggestion.subtitle,
                        tint: AtlasPalette.success,
                        badge: "Matched"
                    )
                    Button("Log Parsed Meal") {
                        Task {
                            await model.saveContextEntry(suggestion.draft)
                            mealText = ""
                        }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                }
                HStack(spacing: 8) {
                    Button("Protein") {
                        Task { await model.saveContextEntry(AtlasTodayContextShortcut.proteinMeal.makeDraft(loggedAt: model.currentDate(), protocolID: nil)) }
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                    Button("Hydration") {
                        Task { await model.saveContextEntry(AtlasTodayContextShortcut.hydration.makeDraft(loggedAt: model.currentDate(), protocolID: nil)) }
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }

                if let latestMeal = model.insightsSnapshot.nutritionSnapshot.latestMealLabel {
                    AtlasCalloutRow(
                        systemImage: "clock",
                        title: "Recent meal",
                        detail: latestMeal,
                        tint: AtlasPalette.secondaryText
                    )
                }

                AtlasForwardNutritionRecentPanel(model: model)
            }
        }
    }
}

private struct AtlasForwardNutritionTargetsCard: View {
    let model: AtlasAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Support Plan")
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Spacer()
                AtlasStatusBadge(healthSyncLabel, tint: AtlasPalette.primary)
            }

            VStack(spacing: 8) {
                ForEach(targets) { target in
                    AtlasForwardNutritionTargetRow(target: target)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                Button {
                    Task { await model.saveContextEntry(AtlasTodayContextShortcut.lowAppetite.makeDraft(loggedAt: model.currentDate(), protocolID: nil)) }
                } label: {
                    Label("Low appetite", systemImage: "leaf.fill")
                }
                .buttonStyle(AtlasSecondaryButtonStyle())

                Button {
                    Task { await model.saveContextEntry(AtlasTodayContextShortcut.giCheckIn.makeDraft(loggedAt: model.currentDate(), protocolID: nil)) }
                } label: {
                    Label("GI check-in", systemImage: "waveform.path.ecg")
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
            }
        }
        .padding(12)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var targets: [AtlasNutritionTargetSnapshot] {
        if model.insightsSnapshot.nutritionSnapshot.dailyTargets.isEmpty == false {
            return model.insightsSnapshot.nutritionSnapshot.dailyTargets
        }
        return [
            AtlasNutritionTargetSnapshot(
                kind: .proteinMeals,
                title: "Protein meals",
                progressLabel: "0 / 2",
                helperText: "Anchor appetite and training context.",
                symbolName: "bolt.heart.fill",
                currentValue: 0,
                targetValue: 2,
                progress: 0,
                isMet: false
            ),
            AtlasNutritionTargetSnapshot(
                kind: .hydrationCheckins,
                title: "Hydration",
                progressLabel: "0 / 2",
                helperText: "Keep today’s protocol support visible.",
                symbolName: "drop.fill",
                currentValue: 0,
                targetValue: 2,
                progress: 0,
                isMet: false
            )
        ]
    }

    private var healthSyncLabel: String {
        model.settingsSnapshot.healthScaffold.connections.contains { $0.connected && $0.enabled } ? "Health on" : "Manual + Health"
    }
}

private struct AtlasForwardNutritionTargetRow: View {
    let target: AtlasNutritionTargetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 10) {
                Image(systemName: target.isMet ? "checkmark.circle.fill" : target.symbolName)
                    .foregroundStyle(target.isMet ? AtlasPalette.success : tint)
                    .frame(width: 32, height: 32)
                    .background((target.isMet ? AtlasPalette.success : tint).opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(target.title)
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(target.helperText)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Text(target.progressLabel)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.textPrimary)
            }
            AtlasForwardThinProgress(value: target.progress, tint: target.isMet ? AtlasPalette.success : tint)
        }
        .padding(10)
        .background(AtlasPalette.surfaceTop.opacity(0.78), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var tint: Color {
        switch target.kind {
        case .proteinMeals:
            return AtlasPalette.success
        case .fiberMeals:
            return AtlasPalette.reward
        case .hydrationCheckins:
            return Color(red: 0.15, green: 0.58, blue: 0.9)
        }
    }
}

private struct AtlasForwardFoodScoreCard: View {
    let model: AtlasAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Support Score")
                    .atlasTextRole(.metricLabel)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Spacer()
                Text("\(supportScore)")
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(scoreTint)
            }

            AtlasForwardThinProgress(value: Double(supportScore) / 100, tint: scoreTint)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                AtlasForwardMiniSignalTile(title: "Protein", value: proteinLabel, systemImage: "bolt.heart.fill", tint: AtlasPalette.success)
                AtlasForwardMiniSignalTile(title: "Hydration", value: hydrationLabel, systemImage: "drop.fill", tint: Color(red: 0.15, green: 0.58, blue: 0.9))
                AtlasForwardMiniSignalTile(title: "Workout", value: workoutLabel, systemImage: "dumbbell.fill", tint: AtlasPalette.reward)
                AtlasForwardMiniSignalTile(title: "Health", value: healthLabel, systemImage: "heart.text.square.fill", tint: AtlasPalette.primary)
            }

            Text(symptomPairingLine)
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var proteinTarget: AtlasNutritionTargetSnapshot? {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .proteinMeals })
    }

    private var hydrationTarget: AtlasNutritionTargetSnapshot? {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .hydrationCheckins })
    }

    private var supportScore: Int {
        let protein = Int((proteinTarget?.progress ?? 0) * 35)
        let hydration = Int((hydrationTarget?.progress ?? 0) * 25)
        let workout = model.insightsSnapshot.recentWorkoutEntries.isEmpty ? 0 : 20
        let health = healthConnected ? 20 : 10
        return min(100, max(10, protein + hydration + workout + health))
    }

    private var scoreTint: Color {
        supportScore >= 70 ? AtlasPalette.success : (supportScore >= 40 ? AtlasPalette.reward : AtlasPalette.warning)
    }

    private var proteinLabel: String {
        proteinTarget?.progressLabel ?? "\(model.insightsSnapshot.nutritionSnapshot.recentMealCount) meals"
    }

    private var hydrationLabel: String {
        hydrationTarget?.progressLabel ?? "Tap to log"
    }

    private var workoutLabel: String {
        let count = model.insightsSnapshot.recentWorkoutEntries.count
        return count == 0 ? "None yet" : "\(count) recent"
    }

    private var healthConnected: Bool {
        model.settingsSnapshot.healthScaffold.connections.contains { $0.connected && $0.enabled }
    }

    private var healthLabel: String {
        if healthConnected {
            return "Sync on"
        }
        return model.settingsSnapshot.healthScaffold.isAvailable ? "Available" : "Manual"
    }

    private var symptomPairingLine: String {
        if let symptom = model.insightsSnapshot.recentSymptomEntries.first {
            return "Latest symptom pair: \(symptom.symptomKey) \(symptom.severity)/5. Meals and hydration will help explain patterns over time."
        }
        return "No recent symptom pairing yet. Food, hydration, and workout logs will make protocol reviews clearer."
    }
}

struct AtlasForwardMiniSignalTile: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold, design: .default))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .atlasTextRole(.metricLabel)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text(value)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(7)
        .background(AtlasPalette.surfaceTop.opacity(0.78), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AtlasForwardWorkoutCaptureCard: View {
    let model: AtlasAppModel
    @State private var activityKind: AtlasWorkoutActivityKind = .strength
    @State private var durationMinutes = 30.0
    @State private var calories = ""

    var body: some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "dumbbell.fill")
                        .foregroundStyle(AtlasPalette.primary)
                        .frame(width: 40, height: 40)
                        .background(AtlasPalette.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Workout")
                            .atlasTextRole(.cardTitle)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(workoutSummary)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                }

                Picker("Workout type", selection: $activityKind) {
                    ForEach(AtlasWorkoutActivityKind.allCases, id: \.self) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.menu)

                Stepper(value: $durationMinutes, in: 5...180, step: 5) {
                    HStack {
                        Text("Duration")
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Spacer()
                        Text("\(Int(durationMinutes)) min")
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                }

                TextField("Calories optional", text: $calories)
                    .keyboardType(.decimalPad)
                    .atlasStandaloneInputSurface()

                HStack(spacing: AtlasSpacing.small) {
                    Button("Save Workout") {
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
                            calories = ""
                        }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())

                    Button("Health Sync") {
                        model.open(.settingsServices)
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }

                AtlasForwardWorkoutHistoryPanel(model: model)
            }
        }
    }

    private var workoutSummary: String {
        let count = model.insightsSnapshot.recentWorkoutEntries.count
        if let goal = model.rewardsSnapshot.goals.first(where: { $0.kind == .weeklyWorkouts }) {
            return "\(goal.progressLabel) this week. Manual logs and Health imports both count."
        }
        return count == 0 ? "Log training manually or sync Health workouts." : "\(count) recent workout\(count == 1 ? "" : "s") in Kairo."
    }
}

private struct AtlasForwardNutritionRecentPanel: View {
    let model: AtlasAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Support Logs")
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Spacer()
                AtlasStatusBadge(hydrationStreakLabel, tint: AtlasPalette.primary)
            }

            if recentEntries.isEmpty {
                AtlasCalloutRow(
                    systemImage: "fork.knife",
                    title: "No recent food context",
                    detail: "Protein, hydration, appetite, and GI notes will appear here after quick capture.",
                    tint: AtlasPalette.secondaryText
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(recentEntries.prefix(3)) { entry in
                        HStack(spacing: 10) {
                            Image(systemName: symbol(for: entry))
                                .foregroundStyle(tint(for: entry))
                                .frame(width: 32, height: 32)
                                .background(tint(for: entry).opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title(for: entry))
                                    .atlasTextRole(.cardBody)
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.76)
                                Text(detail(for: entry))
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(10)
                        .background(AtlasPalette.surfaceTop.opacity(0.78), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }

            if let coaching = model.insightsSnapshot.nutritionSnapshot.coachingCards.first {
                AtlasCalloutRow(
                    systemImage: coaching.symbolName,
                    title: coaching.title,
                    detail: coaching.summary,
                    tint: AtlasPalette.success
                )
            }
        }
        .padding(12)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var recentEntries: [AtlasContextEntrySummary] {
        model.insightsSnapshot.recentContextEntries.sorted { $0.loggedAt > $1.loggedAt }
    }

    private var hydrationStreakLabel: String {
        let hydratedDays = Set(
            recentEntries
                .filter { $0.hydration == .typical || $0.hydration == .high || $0.tags.contains("hydration") }
                .map { Calendar.current.startOfDay(for: $0.loggedAt) }
        ).count
        return hydratedDays == 0 ? "Hydration 0d" : "Hydration \(hydratedDays)d"
    }

    private func title(for entry: AtlasContextEntrySummary) -> String {
        if let composition = entry.mealComposition {
            return composition.title
        }
        if let hydration = entry.hydration {
            return hydration.title
        }
        if let appetite = entry.appetite {
            return appetite.title
        }
        return entry.note?.isEmpty == false ? "Context note" : "Support log"
    }

    private func detail(for entry: AtlasContextEntrySummary) -> String {
        let parts = [
            entry.mealTiming?.title,
            entry.mealSize?.title,
            entry.appetite?.title,
            entry.giTags.first?.title,
            entry.loggedAt.formatted(date: .omitted, time: .shortened)
        ].compactMap { $0 }
        return parts.joined(separator: " • ")
    }

    private func symbol(for entry: AtlasContextEntrySummary) -> String {
        if entry.hydration != nil || entry.tags.contains("hydration") {
            return "drop.fill"
        }
        if entry.mealComposition == .proteinHeavy || entry.tags.contains("protein") {
            return "bolt.heart.fill"
        }
        if entry.giTags.isEmpty == false {
            return "waveform.path.ecg"
        }
        return "fork.knife"
    }

    private func tint(for entry: AtlasContextEntrySummary) -> Color {
        if entry.hydration != nil || entry.tags.contains("hydration") {
            return Color(red: 0.15, green: 0.58, blue: 0.9)
        }
        if entry.giTags.isEmpty == false {
            return AtlasPalette.warning
        }
        if entry.mealComposition == .proteinHeavy || entry.tags.contains("protein") {
            return AtlasPalette.success
        }
        return AtlasPalette.primary
    }
}

private struct AtlasForwardWorkoutHistoryPanel: View {
    let model: AtlasAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Workout History")
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Spacer()
                AtlasStatusBadge(healthWorkoutLabel, tint: AtlasPalette.primary)
            }

            if workouts.isEmpty {
                AtlasCalloutRow(
                    systemImage: "dumbbell.fill",
                    title: "No workouts yet",
                    detail: "Manual workouts and Health imports will both count toward support score and companion quests.",
                    tint: AtlasPalette.secondaryText
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(workouts.prefix(3)) { workout in
                        HStack(spacing: 10) {
                            Image(systemName: workout.source == .health ? "heart.text.square.fill" : "dumbbell.fill")
                                .foregroundStyle(workout.source == .health ? AtlasPalette.primary : AtlasPalette.reward)
                                .frame(width: 32, height: 32)
                                .background((workout.source == .health ? AtlasPalette.primary : AtlasPalette.reward).opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(workout.activityKind.title)
                                    .atlasTextRole(.cardBody)
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Text([workout.durationLabel, workout.detailLabel, workout.startedAt.formatted(date: .abbreviated, time: .omitted)].compactMap { $0 }.joined(separator: " • "))
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(10)
                        .background(AtlasPalette.surfaceTop.opacity(0.78), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        }
        .padding(12)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var workouts: [AtlasWorkoutEntrySummary] {
        model.insightsSnapshot.recentWorkoutEntries.sorted { $0.startedAt > $1.startedAt }
    }

    private var healthWorkoutLabel: String {
        let healthCount = workouts.filter { $0.source == .health }.count
        if healthCount > 0 {
            return "\(healthCount) Health"
        }
        return model.settingsSnapshot.healthScaffold.connections.contains { $0.connected && $0.enabled } ? "Sync on" : "Manual"
    }
}

private struct AtlasForwardOneTapContextCard: View {
    let model: AtlasAppModel
    let title: String
    let detail: String
    let shortcut: AtlasTodayContextShortcut
    let primaryTitle: String

    var body: some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(title)
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Button(primaryTitle) {
                    Task {
                        await model.saveContextEntry(shortcut.makeDraft(loggedAt: model.currentDate(), protocolID: model.todaySnapshot.nextDue?.protocolID))
                    }
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
            }
        }
    }
}

private struct AtlasForwardProgressPhotoCard: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Progress Photo")
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(model.insightsSnapshot.progressEvidence.comparisonNote ?? "Open guided recapture and same-angle compare.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Button("Open Progress Photos") {
                    model.open(.progressEvidence)
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
            }
        }
    }
}

private struct AtlasForwardLogShortcutGrid: View {
    let model: AtlasAppModel
    let selectedKind: AtlasQuickCaptureKind
    let onSelect: (AtlasQuickCaptureKind) -> Void

    private let kinds: [AtlasQuickCaptureKind] = [.shot, .context, .weight, .symptom, .hydration, .protein, .progressPhoto]

    var body: some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("More to log")
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 8)], spacing: 8) {
                    ForEach(kinds.filter { $0 != selectedKind }) { kind in
                        Button {
                            onSelect(kind)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: kind.systemImage)
                                Text(kind.title)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(AtlasPalette.secondaryFill.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct AtlasForwardProgressHero: View {
    let model: AtlasAppModel
    let state: AtlasInsightsViewState

    var body: some View {
        AtlasForwardCard(padding: 9) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Protocol Progress")
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Spacer(minLength: 6)
                    AtlasStatusBadge(model.insightsSnapshot.adherenceTrend.completionRateLabel ?? "Building", tint: AtlasPalette.primary)
                }
                Text(progressSummary)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                AtlasForwardMedicationMiniChart(item: model.insightsSnapshot.amountInSystem.first, height: 42)
                if let latestWeight = model.insightsSnapshot.weightTrend.latestLabel {
                    AtlasStatusBadge(latestWeight, tint: AtlasPalette.success)
                }
            }
        }
    }

    private var progressSummary: String {
        if model.libraryProtocols.isEmpty {
            return "Create a protocol to turn progress into a visible trend."
        }
        return "Shots, weight, food, workouts, check-ins, and photos roll up here."
    }
}

private struct AtlasForwardProgressGrid: View {
    let model: AtlasAppModel
    let state: AtlasInsightsViewState

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            AtlasForwardStatCard(title: "Weight", value: model.insightsSnapshot.weightTrend.latestLabel ?? "No log", systemImage: "scalemass.fill", tint: AtlasPalette.primary)
            AtlasForwardStatCard(title: "Photos", value: "\(model.insightsSnapshot.progressEvidence.recentPhotos.count)", systemImage: "camera.fill", tint: AtlasPalette.reward)
            AtlasForwardStatCard(title: "Meals", value: "\(model.insightsSnapshot.nutritionSnapshot.recentMealCount)", systemImage: "fork.knife", tint: AtlasPalette.success)
            AtlasForwardStatCard(title: "Workouts", value: "\(model.insightsSnapshot.recentWorkoutEntries.count)", systemImage: "dumbbell.fill", tint: AtlasPalette.primary)
        }
    }
}

private struct AtlasForwardStatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        AtlasForwardCard(padding: 8) {
            VStack(alignment: .leading, spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundStyle(tint)
                Text(title)
                    .atlasTextRole(.metricLabel)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text(value)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        }
    }
}

private struct AtlasForwardProgressActions: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasForwardCard(padding: 7) {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("Review & Share")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Spacer()
                    Text("Export ready")
                        .atlasTextRole(.metricLabel)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 7), GridItem(.flexible(), spacing: 7)], spacing: 7) {
                    actionTile(title: "Logs", detail: "Signals", systemImage: "list.bullet.clipboard.fill", tint: AtlasPalette.primary) {
                        model.open(.insightsLogs)
                    }
                    actionTile(title: "Review", detail: "Weekly", systemImage: "calendar.badge.checkmark", tint: AtlasPalette.reward) {
                        model.open(.weeklyReview)
                    }
                    actionTile(title: "Evidence", detail: "Photos", systemImage: "camera.fill", tint: AtlasPalette.success) {
                        model.open(.progressEvidence)
                    }
                    actionTile(title: "Share", detail: "Summary", systemImage: "square.and.arrow.up.fill", tint: AtlasPalette.primary) {
                        model.open(.reviewMode)
                    }
                }
            }
        }
    }

    private func actionTile(
        title: String,
        detail: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            AtlasFeedback.selection()
            action()
        } label: {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                    .frame(width: 26, height: 26)
                    .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(detail)
                        .atlasTextRole(.metricLabel)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct AtlasForwardCompanionHero: View {
    let model: AtlasAppModel

    var body: some View {
        let selection: AtlasMascotSelection = atlasForwardMockupFidelityActive ? .aetherion : model.settingsSnapshot.mascotSelection
        let evolution = atlasRewardsEvolutionProgress(for: model.rewardsSnapshot, selection: selection)

        HStack(alignment: .center, spacing: atlasForwardMockupFidelityActive ? -2 : 0) {
                AtlasForwardLevelRing(
                    level: atlasForwardMockupFidelityActive ? 14 : model.rewardsSnapshot.level,
                    points: atlasForwardMockupFidelityActive ? 1_240 : model.rewardsSnapshot.totalPoints,
                    next: atlasForwardMockupFidelityActive ? 2_000 : model.rewardsSnapshot.nextLevelPoints
                )
                    .frame(width: atlasForwardMockupFidelityActive ? 94 : 100, height: atlasForwardMockupFidelityActive ? 94 : 100)
                AtlasForwardMascotStageArt(
                    selection: selection,
                    stage: evolution.stage,
                    size: atlasForwardMockupFidelityActive ? 164 : 164
                )
                    .frame(width: atlasForwardMockupFidelityActive ? 126 : 126)
                AtlasForwardNextFormPreview(
                    selection: selection,
                    currentStage: evolution.stage,
                    nextFormName: evolution.nextFormName
                )
                .frame(width: atlasForwardMockupFidelityActive ? 66 : 62)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.48), lineWidth: 1)
        )
    }
}

private struct AtlasForwardMascotStageArt: View {
    let selection: AtlasMascotSelection
    let stage: AtlasMascotStage
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            atlasMascotLineTint(for: selection).opacity(0.22),
                            AtlasPalette.reward.opacity(0.12),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.94, height: size * 0.24)
                .offset(y: 5)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AtlasPalette.textTertiary.opacity(0.18),
                            AtlasPalette.reward.opacity(0.12),
                            atlasMascotLineTint(for: selection).opacity(0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.58, height: size * 0.08)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.white.opacity(0.5), lineWidth: 0.7)
                )
                .offset(y: size * 0.035)

            HStack(spacing: 2) {
                ForEach(0..<6, id: \.self) { index in
                    Capsule()
                        .fill(atlasMascotLineTint(for: selection).opacity(index.isMultiple(of: 2) ? 0.38 : 0.22))
                        .frame(width: 3, height: CGFloat(5 + (index % 3) * 2))
                }
            }
            .offset(y: -size * 0.015)

            AtlasForwardMascotArt(selection: selection, stage: stage, size: size)
                .shadow(color: atlasMascotLineTint(for: selection).opacity(0.14), radius: 10, y: 5)
        }
        .frame(height: size * 0.92)
    }
}

private struct AtlasForwardNextFormPreview: View {
    let selection: AtlasMascotSelection
    let currentStage: AtlasMascotStage
    let nextFormName: String?

    var body: some View {
        VStack(spacing: atlasForwardMockupFidelityActive ? 2 : 4) {
            Text("Next Form")
                .font(.system(size: 9.5, weight: .bold, design: .default))
                .foregroundStyle(Color(red: 0.06, green: 0.12, blue: 0.11))
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.92), in: Capsule(style: .continuous))

            ZStack(alignment: .bottomTrailing) {
                AtlasForwardMascotArt(selection: selection, stage: nextStage, size: atlasForwardMockupFidelityActive ? 54 : 48)
                    .saturation(0)
                    .opacity(nextFormName == nil ? 0.62 : 0.24)
                    .brightness(nextFormName == nil ? 0 : -0.18)
                    .frame(width: atlasForwardMockupFidelityActive ? 58 : 54, height: atlasForwardMockupFidelityActive ? 42 : 40)

                if nextFormName != nil {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color(red: 0.06, green: 0.12, blue: 0.11))
                            .frame(width: 18, height: 18)
                            .background(Color.white.opacity(0.94), in: Circle())
                            .overlay(Circle().stroke(Color(red: 0.06, green: 0.12, blue: 0.11).opacity(0.16), lineWidth: 1))
                }
            }

            Text(nextFormLabel)
                .font(.system(size: 9.5, weight: .bold, design: .default))
                .foregroundStyle(Color(red: 0.06, green: 0.12, blue: 0.11))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.92), in: Capsule(style: .continuous))
        }
    }

    private var nextFormLabel: String {
        atlasForwardMockupFidelityActive && nextFormName != nil ? "Level 20" : (nextFormName ?? "Unlocked")
    }

    private var nextStage: AtlasMascotStage {
        switch currentStage {
        case .stage1:
            return .stage2
        case .stage2:
            return .stage3
        case .stage3:
            return .stage3
        }
    }
}

private struct AtlasForwardMascotArt: View {
    let selection: AtlasMascotSelection
    let stage: AtlasMascotStage
    let size: CGFloat

    var body: some View {
        AtlasMascotSticker(line: atlasMascotLine(for: selection), stage: stage, size: size)
    }
}

private struct AtlasForwardCompanionProgressMap: View {
    let model: AtlasAppModel

    var body: some View {
        let evolution = atlasRewardsEvolutionProgress(for: model.rewardsSnapshot, selection: model.settingsSnapshot.mascotSelection)

        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Evolution Path")
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                    }
                    Spacer(minLength: 8)
                    AtlasStatusBadge(stageTitle(evolution.stage), tint: AtlasPalette.reward)
                }

                HStack(spacing: 8) {
                    AtlasForwardCompanionMilestone(title: "Current", value: stageTitle(evolution.stage), systemImage: "sparkles", tint: AtlasPalette.reward)
                    AtlasForwardCompanionMilestone(title: "Next Form", value: evolution.nextFormName ?? "Mastered", systemImage: evolution.nextFormName == nil ? "crown.fill" : "lock.fill", tint: AtlasPalette.primary)
                    AtlasForwardCompanionMilestone(title: "Streak", value: "\(activeStreak)", systemImage: "chart.line.uptrend.xyaxis", tint: AtlasPalette.success)
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    AtlasForwardMiniSignalTile(title: "Shot mastery", value: shotMasteryLabel, systemImage: "syringe.fill", tint: AtlasPalette.primary)
                    AtlasForwardMiniSignalTile(title: "Site badges", value: siteBadgeLabel, systemImage: "figure.arms.open", tint: AtlasPalette.success)
                    AtlasForwardMiniSignalTile(title: "Protein quest", value: proteinLabel, systemImage: "bolt.heart.fill", tint: AtlasPalette.reward)
                    AtlasForwardMiniSignalTile(title: "Hydration quest", value: hydrationLabel, systemImage: "drop.fill", tint: Color(red: 0.15, green: 0.58, blue: 0.9))
                }
            }
        }
    }

    private var activeStreak: Int {
        model.rewardsSnapshot.streaks.filter(\.isActive).map(\.count).max() ?? 0
    }

    private var shotMasteryLabel: String {
        model.insightsSnapshot.adherenceTrend.completionRateLabel ?? "Building"
    }

    private var siteBadgeLabel: String {
        let tracked = model.inventorySnapshot.protocolSettings.filter { $0.siteRotationEnabled }.count
        return tracked == 0 ? "Add sites" : "\(tracked) active"
    }

    private var proteinLabel: String {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .proteinMeals })?.progressLabel ?? "0 / 1"
    }

    private var hydrationLabel: String {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .hydrationCheckins })?.progressLabel ?? "0 / 1"
    }

    private func stageTitle(_ stage: AtlasMascotStage) -> String {
        switch stage {
        case .stage1:
            return "Stage 1"
        case .stage2:
            return "Stage 2"
        case .stage3:
            return "Stage 3"
        }
    }
}

private struct AtlasForwardCompanionMilestone: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            Text(title)
                .atlasTextRole(.metricLabel)
                .foregroundStyle(AtlasPalette.textSecondary)
            Text(value)
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: 94, alignment: .topLeading)
        .padding(10)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AtlasForwardXPEconomyCard: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("XP Sources")
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                    }
                    Spacer(minLength: 8)
                    AtlasStatusBadge("\(model.rewardsSnapshot.totalPoints.formatted()) XP", tint: AtlasPalette.reward)
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    AtlasForwardXPSourceTile(title: "Shot logged", value: "+12", detail: shotDetail, systemImage: "syringe.fill", tint: AtlasPalette.primary, isActive: shotActive)
                    AtlasForwardXPSourceTile(title: "Protein", value: "+20", detail: proteinDetail, systemImage: "bolt.heart.fill", tint: AtlasPalette.success, isActive: proteinActive)
                    AtlasForwardXPSourceTile(title: "Hydration", value: "+15", detail: hydrationDetail, systemImage: "drop.fill", tint: Color(red: 0.15, green: 0.58, blue: 0.9), isActive: hydrationActive)
                    AtlasForwardXPSourceTile(title: "Workout", value: "+20", detail: workoutDetail, systemImage: "dumbbell.fill", tint: AtlasPalette.reward, isActive: workoutActive)
                }

                AtlasCalloutRow(
                    systemImage: "gift.fill",
                    title: nextUnlockTitle,
                    detail: "Badges, site streaks, support quests, and weekly reviews all feed the same visible companion progression.",
                    tint: AtlasPalette.reward
                )
            }
        }
    }

    private var shotActive: Bool {
        model.todaySnapshot.nextDue == nil && model.todaySnapshot.overdue.isEmpty
    }

    private var proteinTarget: AtlasNutritionTargetSnapshot? {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .proteinMeals })
    }

    private var hydrationTarget: AtlasNutritionTargetSnapshot? {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .hydrationCheckins })
    }

    private var proteinActive: Bool {
        proteinTarget?.isMet ?? false
    }

    private var hydrationActive: Bool {
        hydrationTarget?.isMet ?? false
    }

    private var workoutActive: Bool {
        model.insightsSnapshot.recentWorkoutEntries.isEmpty == false
    }

    private var shotDetail: String {
        shotActive ? "Complete today" : "Next shot ready"
    }

    private var proteinDetail: String {
        proteinTarget?.progressLabel ?? "0 / 2"
    }

    private var hydrationDetail: String {
        hydrationTarget?.progressLabel ?? "0 / 2"
    }

    private var workoutDetail: String {
        model.rewardsSnapshot.goals.first(where: { $0.kind == .weeklyWorkouts })?.progressLabel
            ?? "\(model.insightsSnapshot.recentWorkoutEntries.count) recent"
    }

    private var nextUnlockTitle: String {
        let evolution = atlasRewardsEvolutionProgress(for: model.rewardsSnapshot, selection: model.settingsSnapshot.mascotSelection)
        if let next = evolution.nextFormName {
            _ = next
            return "Next companion milestone"
        }
        return "Final form mastered"
    }
}

private struct AtlasForwardXPSourceTile: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let tint: Color
    let isActive: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isActive ? "checkmark.circle.fill" : systemImage)
                .foregroundStyle(isActive ? AtlasPalette.success : tint)
                .frame(width: 34, height: 34)
                .background((isActive ? AtlasPalette.success : tint).opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .atlasTextRole(.metricLabel)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text(detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            Spacer(minLength: 0)
            Text(value)
                .atlasTextRole(.deckEyebrow)
                .foregroundStyle(AtlasPalette.reward)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AtlasForwardLevelRing: View {
    let level: Int
    let points: Int
    let next: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(AtlasPalette.primary.opacity(0.14), lineWidth: atlasForwardMockupFidelityActive ? 5.5 : 6.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AtlasPalette.primary, style: StrokeStyle(lineWidth: atlasForwardMockupFidelityActive ? 5.5 : 6.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: atlasForwardMockupFidelityActive ? 2 : 3) {
                Text("Level")
                    .font(.system(size: 11, weight: .bold, design: .default))
                    .foregroundStyle(Color(red: 0.06, green: 0.12, blue: 0.11))
                Text("\(level)")
                    .font(AtlasTypography.brandFont(size: atlasForwardMockupFidelityActive ? 25 : 27, weight: .bold, relativeTo: .title))
                    .foregroundStyle(AtlasPalette.primary)
                Text("\(points.formatted()) / \(max(points, next).formatted()) XP")
                    .font(.system(size: atlasForwardMockupFidelityActive ? 8.8 : 9, weight: .bold, design: .default))
                    .foregroundStyle(Color(red: 0.04, green: 0.32, blue: 0.27))
            }
            .padding(7)
            .background(Color.white.opacity(0.96), in: Circle())
        }
    }

    private var progress: Double {
        guard next > 0 else { return 1 }
        return min(max(Double(points) / Double(next), 0), 1)
    }
}

private struct AtlasForwardQuestCard: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasForwardCard(padding: atlasForwardMockupFidelityActive ? 7 : 8) {
            VStack(alignment: .leading, spacing: atlasForwardMockupFidelityActive ? 5 : 6) {
                HStack {
                    Text("Quests")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Spacer()
                    Text(atlasForwardMockupFidelityActive ? "Resets in 10h" : "Resets tonight")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                AtlasForwardQuestRow(title: "Log shot", progress: shotComplete ? "1 / 1" : "0 / 1", systemImage: "syringe.fill", isComplete: shotComplete, xp: nil, showsProgressBar: false) {
                    model.activeTab = .timeline
                }
                AtlasForwardQuestRow(title: "Protein meal", progress: proteinProgress, systemImage: "fork.knife", isComplete: proteinComplete, xp: proteinComplete ? nil : "20 XP") {
                    model.activeTab = .timeline
                }
                AtlasForwardQuestRow(title: "Workout", progress: workoutProgress, systemImage: "dumbbell.fill", isComplete: workoutComplete, xp: workoutComplete ? nil : "20 XP") {
                    model.activeTab = .timeline
                }
                AtlasForwardQuestRow(title: "Progress photo", progress: "\(model.insightsSnapshot.progressEvidence.recentPhotos.isEmpty ? 0 : 1) / 1", systemImage: "camera.fill", isComplete: model.insightsSnapshot.progressEvidence.recentPhotos.isEmpty == false, xp: "15 XP") {
                    model.open(.progressEvidence)
                }
            }
        }
    }

    private var shotComplete: Bool {
        if atlasForwardMockupFidelityActive {
            return true
        }
        return model.todaySnapshot.nextDue == nil && model.todaySnapshot.overdue.isEmpty
    }

    private var proteinProgress: String {
        return model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .proteinMeals })?.progressLabel ?? "0 / 1"
    }

    private var proteinComplete: Bool {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .proteinMeals })?.isMet ?? false
    }

    private var hydrationProgress: String {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .hydrationCheckins })?.progressLabel ?? "0 / 1"
    }

    private var hydrationComplete: Bool {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .hydrationCheckins })?.isMet ?? false
    }

    private var workoutProgress: String {
        if atlasForwardMockupFidelityActive {
            return "0 / 1"
        }
        return model.rewardsSnapshot.goals.first(where: { $0.kind == .weeklyWorkouts })?.progressLabel ?? "\(model.insightsSnapshot.recentWorkoutEntries.count) / 1"
    }

    private var workoutComplete: Bool {
        if atlasForwardMockupFidelityActive {
            return false
        }
        return model.rewardsSnapshot.goals.first(where: { $0.kind == .weeklyWorkouts })?.isMet ?? (model.insightsSnapshot.recentWorkoutEntries.isEmpty == false)
    }
}

private struct AtlasForwardQuestRow: View {
    let title: String
    let progress: String
    let systemImage: String
    let isComplete: Bool
    let xp: String?
    var showsProgressBar = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: atlasForwardMockupFidelityActive ? 7 : 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(isComplete ? AtlasPalette.success : tint)
                    .frame(width: atlasForwardMockupFidelityActive ? 24 : 26, height: atlasForwardMockupFidelityActive ? 24 : 26)
                    .background((isComplete ? AtlasPalette.success : tint).opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: atlasForwardMockupFidelityActive ? 2 : 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Spacer()
                        Text(progress)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .lineLimit(1)
                        if let xp {
                            Text(xp)
                                .atlasTextRole(.metricLabel)
                                .foregroundStyle(AtlasPalette.reward)
                                .lineLimit(1)
                        }
                    }
                    if showsProgressBar && isComplete == false {
                        AtlasForwardThinProgress(value: progressValue, tint: tint)
                    }
                }
                Image(systemName: isComplete ? "checkmark.circle.fill" : "chevron.right")
                    .foregroundStyle(isComplete ? AtlasPalette.success : AtlasPalette.textTertiary)
            }
            .padding(.horizontal, atlasForwardMockupFidelityActive ? 5 : 6)
            .padding(.vertical, atlasForwardMockupFidelityActive ? 4 : 5)
            .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var tint: Color {
        if systemImage == "drop.fill" {
            return Color(red: 0.15, green: 0.58, blue: 0.9)
        }
        if systemImage == "dumbbell.fill" {
            return AtlasPalette.reward
        }
        return AtlasPalette.primary
    }

    private var progressValue: Double {
        let pieces = progress
            .replacingOccurrences(of: "today", with: "")
            .split(separator: "/")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard pieces.count == 2,
              let current = Double(pieces[0].components(separatedBy: " ").first ?? ""),
              let target = Double(pieces[1].components(separatedBy: " ").first ?? ""),
              target > 0 else {
            return isComplete ? 1 : 0
        }
        return min(max(current / target, 0), 1)
    }
}

private struct AtlasForwardCompanionMasteryShelf: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Mastery Badges")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Spacer()
                    Text("\(earnedCount) earned")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    AtlasForwardMasteryBadge(title: "Protocol", value: protocolMastery, systemImage: "syringe.fill", tint: AtlasPalette.primary, isEarned: model.todaySnapshot.hasProtocols)
                    AtlasForwardMasteryBadge(title: "Site rotation", value: siteMastery, systemImage: "figure.arms.open", tint: AtlasPalette.success, isEarned: model.inventorySnapshot.protocolSettings.contains { $0.siteRotationEnabled })
                    AtlasForwardMasteryBadge(title: "Protein", value: proteinMastery, systemImage: "bolt.heart.fill", tint: AtlasPalette.reward, isEarned: proteinEarned)
                    AtlasForwardMasteryBadge(title: "Hydration", value: hydrationMastery, systemImage: "drop.fill", tint: Color(red: 0.15, green: 0.58, blue: 0.9), isEarned: hydrationEarned)
                }
            }
        }
    }

    private var earnedCount: Int {
        [model.todaySnapshot.hasProtocols, model.inventorySnapshot.protocolSettings.contains { $0.siteRotationEnabled }, proteinEarned, hydrationEarned].filter { $0 }.count
    }

    private var protocolMastery: String {
        model.insightsSnapshot.adherenceTrend.completionRateLabel ?? (model.todaySnapshot.hasProtocols ? "Active" : "Setup")
    }

    private var siteMastery: String {
        let siteCount = model.inventorySnapshot.sites.filter { $0.archivedAt == nil }.count
        return siteCount == 0 ? "Add sites" : "\(siteCount) sites"
    }

    private var proteinEarned: Bool {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .proteinMeals })?.isMet ?? false
    }

    private var hydrationEarned: Bool {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .hydrationCheckins })?.isMet ?? false
    }

    private var proteinMastery: String {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .proteinMeals })?.progressLabel ?? "0 / 1"
    }

    private var hydrationMastery: String {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .hydrationCheckins })?.progressLabel ?? "0 / 1"
    }
}

private struct AtlasForwardMasteryBadge: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
    let isEarned: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isEarned ? "checkmark.seal.fill" : systemImage)
                .foregroundStyle(isEarned ? tint : AtlasPalette.textTertiary)
                .frame(width: 34, height: 34)
                .background((isEarned ? tint : AtlasPalette.textTertiary).opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .atlasTextRole(.metricLabel)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text(value)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AtlasForwardBadgeCollectibleCard: View {
    let model: AtlasAppModel

    var body: some View {
        HStack(spacing: atlasForwardMockupFidelityActive ? 7 : 8) {
            AtlasForwardCard(padding: atlasForwardMockupFidelityActive ? 7 : 8) {
                collection(title: "Badges", items: badgeSymbols, tint: AtlasPalette.reward)
            }
            AtlasForwardCard(padding: atlasForwardMockupFidelityActive ? 7 : 8) {
                collection(title: "Collectibles", items: collectibleSymbols, tint: AtlasPalette.success)
            }
        }
    }

    private var badgeSymbols: [String] {
        let earned = model.rewardsSnapshot.badges.filter(\.isEarned).map(\.symbolName)
        return earned.isEmpty ? ["star.fill", "drop.fill", "calendar", "heart.fill"] : Array(earned.prefix(4))
    }

    private var collectibleSymbols: [String] {
        ["leaf.fill", "book.closed.fill", "testtube.2", "scope"]
    }

    private func collection(title: String, items: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: atlasForwardMockupFidelityActive ? 6 : 7) {
            HStack {
                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Spacer()
                Text("View all")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
            HStack(spacing: atlasForwardMockupFidelityActive ? 6 : 8) {
                ForEach(items, id: \.self) { symbol in
                    AtlasForwardCollectionToken(systemImage: symbol, tint: tint)
                }
            }
        }
    }
}

private struct AtlasForwardCollectionToken: View {
    let systemImage: String
    let tint: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            tint.opacity(0.24),
                            AtlasPalette.surfaceSecondary,
                            tint.opacity(0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tint.opacity(0.34), lineWidth: 1)
            tokenGlyph
        }
        .frame(width: atlasForwardMockupFidelityActive ? 30 : 32, height: atlasForwardMockupFidelityActive ? 30 : 32)
        .shadow(color: tint.opacity(0.12), radius: 4, y: 2)
    }

    @ViewBuilder
    private var tokenGlyph: some View {
        switch systemImage {
        case "star.fill":
            ZStack {
                ShieldShape()
                    .fill(
                        LinearGradient(
                            colors: [AtlasPalette.reward.opacity(0.98), Color(red: 0.96, green: 0.48, blue: 0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 19, height: 22)
                    .overlay(ShieldShape().stroke(.white.opacity(0.55), lineWidth: 0.8))
                Image(systemName: "star.fill")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
            }
        case "drop.fill":
            Image(systemName: "drop.fill")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.72, green: 0.94, blue: 1), Color(red: 0.18, green: 0.58, blue: 0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(red: 0.18, green: 0.58, blue: 0.82).opacity(0.22), radius: 2, y: 1)
        case "calendar":
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(AtlasPalette.surfaceTop)
                    .frame(width: 18, height: 20)
                    .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(AtlasPalette.primary.opacity(0.55), lineWidth: 1))
                Rectangle()
                    .fill(AtlasPalette.primary.opacity(0.7))
                    .frame(width: 18, height: 5)
                    .offset(y: -7)
                Text("7")
                    .font(.system(size: 10, weight: .black, design: .default))
                    .foregroundStyle(AtlasPalette.primary)
                    .offset(y: 2)
            }
        case "heart.fill":
            ZStack {
                Circle()
                    .fill(AtlasPalette.reward.opacity(0.14))
                    .frame(width: 21, height: 21)
                Image(systemName: "heart.fill")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.94, green: 0.28, blue: 0.45), AtlasPalette.reward],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        case "leaf.fill":
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Diamond()
                        .fill(AtlasPalette.success.opacity(index == 1 ? 0.95 : 0.62))
                        .frame(width: 9, height: 18)
                        .rotationEffect(.degrees(Double(index - 1) * 24))
                        .offset(x: CGFloat(index - 1) * 5, y: CGFloat(abs(index - 1)) * 3)
                }
            }
        case "book.closed.fill":
            Image(systemName: "book.closed.fill")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.46, green: 0.33, blue: 0.18), AtlasPalette.reward],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        case "testtube.2":
            Image(systemName: "testtube.2")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AtlasPalette.primary.opacity(0.95), Color(red: 0.33, green: 0.82, blue: 0.73)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        default:
            ZStack {
                Circle()
                    .stroke(AtlasPalette.primary.opacity(0.65), lineWidth: 1.4)
                    .frame(width: 18, height: 18)
                Image(systemName: "scope")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(AtlasPalette.primary)
            }
        }
    }

    private struct ShieldShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.22))
            path.addLine(to: CGPoint(x: rect.maxX * 0.86, y: rect.maxY * 0.74))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.maxY * 0.74))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.22))
            path.closeSubpath()
            return path
        }
    }

    private struct Diamond: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
            return path
        }
    }
}

private struct AtlasForwardWeeklyMasteryCard: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasForwardCard(padding: atlasForwardMockupFidelityActive ? 8 : 10, background: AtlasPalette.surfaceInverse) {
            HStack(alignment: .center, spacing: atlasForwardMockupFidelityActive ? 9 : 12) {
                VStack(alignment: .leading, spacing: atlasForwardMockupFidelityActive ? 6 : 8) {
                    HStack {
                        Text("Weekly Protocol Mastery")
                            .atlasTextRole(.cardBody)
                        Spacer()
                        Text(weekRange)
                            .atlasTextRole(.supporting)
                    }
                    .foregroundStyle(.white.opacity(0.88))

                    Text("Consistency champion")
                        .font(
                            AtlasTypography.brandFont(
                                size: atlasForwardMockupFidelityActive ? 15 : 18,
                                weight: .bold,
                                relativeTo: .title3
                            )
                        )
                        .foregroundStyle(.white)
                    Text(masteryDetail)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(.white.opacity(0.78))

                    HStack(spacing: atlasForwardMockupFidelityActive ? 3 : 5) {
                        ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                            Text(day)
                                .font(.system(size: 11, weight: .bold, design: .default))
                                .foregroundStyle(.white)
                                .frame(width: atlasForwardMockupFidelityActive ? 19 : 22, height: atlasForwardMockupFidelityActive ? 19 : 22)
                                .background(AtlasPalette.success.opacity(0.85), in: Circle())
                        }
                    }
                }
                AtlasForwardMasteryGem()
                    .frame(width: atlasForwardMockupFidelityActive ? 72 : 82, height: atlasForwardMockupFidelityActive ? 72 : 82)
            }
        }
    }

    private var weekRange: String {
        if atlasForwardMockupFidelityActive {
            return "Apr 14 - Apr 20"
        }
        let now = model.currentDate()
        let start = Calendar.current.date(byAdding: .day, value: -6, to: now) ?? now
        return "\(start.formatted(.dateTime.month(.abbreviated).day())) - \(now.formatted(.dateTime.month(.abbreviated).day()))"
    }

    private var masteryDetail: String {
        atlasForwardMockupFidelityActive ? "6 of 7 days logged" : (model.insightsSnapshot.adherenceTrend.completionRateLabel ?? "Building rhythm")
    }
}

private struct AtlasForwardProgressMasteryCompactCard: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasForwardCard(background: AtlasPalette.surfaceInverse) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text("Weekly Protocol Mastery")
                            .atlasTextRole(.cardBody)
                        Spacer()
                        Text(weekRange)
                            .atlasTextRole(.supporting)
                    }
                    .foregroundStyle(.white.opacity(0.88))

                    Text("Consistency champion")
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Text(masteryDetail)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(.white.opacity(0.78))

                    HStack(spacing: 4) {
                        ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                            Text(day)
                                .font(.system(size: 10, weight: .bold, design: .default))
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(AtlasPalette.success.opacity(0.86), in: Circle())
                        }
                    }
                }

                Spacer(minLength: 6)

                AtlasForwardMasteryGem()
                    .frame(width: 66, height: 66)
            }
        }
    }

    private var weekRange: String {
        if atlasForwardMockupFidelityActive {
            return "Apr 14 - Apr 20"
        }
        let now = model.currentDate()
        let start = Calendar.current.date(byAdding: .day, value: -6, to: now) ?? now
        return "\(start.formatted(.dateTime.month(.abbreviated).day())) - \(now.formatted(.dateTime.month(.abbreviated).day()))"
    }

    private var masteryDetail: String {
        atlasForwardMockupFidelityActive ? "6 of 7 days logged" : (model.insightsSnapshot.adherenceTrend.completionRateLabel ?? "Building rhythm")
    }
}

private struct AtlasForwardDarkBadge: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .bold, design: .default))
            .foregroundStyle(.white.opacity(0.88))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.white.opacity(0.12), in: Capsule())
    }
}

private struct AtlasForwardMasteryGem: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 86, height: 86)
            Circle()
                .stroke(.white.opacity(0.15), lineWidth: 1)
                .frame(width: 78, height: 78)
            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(index.isMultiple(of: 2) ? 0.26 : 0.14))
                    .frame(width: 3, height: 18)
                    .offset(y: -39)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            Shield()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.76, green: 0.70, blue: 0.58),
                            Color(red: 0.34, green: 0.30, blue: 0.24),
                            Color(red: 0.82, green: 0.74, blue: 0.58)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 58, height: 66)
                .overlay(Shield().stroke(.white.opacity(0.38), lineWidth: 1))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 5)
            Diamond()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.54, green: 1.0, blue: 0.88),
                            Color(red: 0.02, green: 0.72, blue: 0.62),
                            AtlasPalette.primary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 38, height: 50)
                .overlay(
                    Diamond()
                        .stroke(.white.opacity(0.46), lineWidth: 1)
                )
                .shadow(color: AtlasPalette.primaryGlow.opacity(0.42), radius: 14, y: 6)
            Diamond()
                .fill(.white.opacity(0.28))
                .frame(width: 12, height: 38)
                .offset(x: -7, y: -3)
                .blendMode(.screen)
        }
    }

    private struct Diamond: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY * 0.92))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY * 0.92))
            path.closeSubpath()
            return path
        }
    }

    private struct Shield: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.22))
            path.addLine(to: CGPoint(x: rect.maxX * 0.88, y: rect.maxY * 0.72))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.maxY * 0.72))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.22))
            path.closeSubpath()
            return path
        }
    }
}

private struct AtlasForwardCompanionActions: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasForwardCard {
            VStack(spacing: 10) {
                Button("Open Mascot Detail") {
                    model.open(.mascot)
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
                Button("Rewards Board") {
                    model.open(.rewards)
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
                Button("Companion Settings") {
                    model.open(.settingsPersonalization)
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
            }
        }
    }
}

struct AtlasForwardCard<Content: View>: View {
    var padding: CGFloat = 10
    var background: Color = AtlasPalette.surfaceTop
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AtlasPalette.border.opacity(0.56), lineWidth: 1)
            )
            .shadow(color: AtlasPalette.shadow.opacity(0.08), radius: 5, x: 0, y: 2)
    }
}

private struct AtlasForwardCompactSecondaryActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: atlasForwardMockupFidelityActive ? 13.5 : 14, weight: .semibold, design: .default))
            .foregroundStyle(AtlasPalette.secondaryText)
            .frame(maxWidth: .infinity, minHeight: atlasForwardMockupFidelityActive ? 38 : 40)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.isPressed ? AtlasPalette.surfaceMuted : AtlasPalette.surfaceTop)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AtlasPalette.border.opacity(configuration.isPressed ? 0.92 : 0.78), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.84), value: configuration.isPressed)
    }
}

struct AtlasForwardThinProgress: View {
    let value: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(AtlasPalette.border.opacity(0.5))
                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: 4)
    }
}

struct AtlasForwardProtocolDetailScreen: View {
    let model: AtlasAppModel
    let protocolID: String
    @State private var loadedDetail: AtlasProtocolDetailSnapshot?
    @State private var isLoading = false

    var body: some View {
        AtlasRootScrollSurface {
            AtlasForwardDetailNavBar(title: "Protocol")

            if let detail {
                protocolHero(detail)
                protocolSignalGrid(detail)
                protocolSiteRotationCard(detail)
                protocolInventoryCard(detail)
                protocolSupportCard(detail)
                protocolHistoryCard(detail)
            } else {
                AtlasForwardLoadingCard(title: "Loading protocol", detail: "Kairo is opening the saved plan.")
            }
        }
        .task(id: protocolID) {
            guard loadedDetail?.id != protocolID, isLoading == false else { return }
            isLoading = true
            loadedDetail = await model.protocolDetail(id: protocolID)
            isLoading = false
        }
    }

    private var detail: AtlasProtocolDetailSnapshot? {
        loadedDetail ?? model.protocolDetails[protocolID]
    }

    private func protocolHero(_ detail: AtlasProtocolDetailSnapshot) -> some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: routeIcon(for: detail.editableDraft.administrationRoute))
                        .foregroundStyle(AtlasPalette.primary)
                        .frame(width: 34, height: 34)
                        .background(AtlasPalette.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cleanTitle(detail.canonicalTitle))
                            .atlasTextRole(.cardTitle)
                            .foregroundStyle(AtlasPalette.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Text([detail.doseLabel, detail.administrationLabel, detail.cadenceLabel].compactMap { $0 }.joined(separator: "  •  "))
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 8)
                    AtlasStatusBadge(statusLabel(detail.status), tint: detail.status == .active ? AtlasPalette.success : AtlasPalette.textSecondary)
                }

                AtlasForwardMedicationMiniChart(item: detail.medicationLevel ?? model.insightsSnapshot.amountInSystem.first(where: { $0.protocolID == detail.id }))

                HStack(spacing: 8) {
                    Button {
                        model.activeTab = .timeline
                    } label: {
                        Label("Log Shot", systemImage: "syringe.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())

                    Button("Edit") {
                        model.open(.protocolEdit(detail.id))
                    }
                    .buttonStyle(AtlasForwardCompactSecondaryActionStyle())
                }
            }
        }
    }

    private func protocolSignalGrid(_ detail: AtlasProtocolDetailSnapshot) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 7), GridItem(.flexible(), spacing: 7)], spacing: 7) {
            AtlasForwardMiniSignalTile(title: "Next", value: nextLabel(detail), systemImage: "clock.fill", tint: AtlasPalette.primary)
            AtlasForwardMiniSignalTile(title: "Route", value: detail.administrationLabel ?? detail.editableDraft.administrationRoute.forwardDisplayLabel, systemImage: routeIcon(for: detail.editableDraft.administrationRoute), tint: AtlasPalette.success)
            AtlasForwardMiniSignalTile(title: "Supply", value: detail.supplyLabel ?? detail.editableDraft.supplyType?.forwardDisplayLabel ?? "Supply", systemImage: supplyIcon(for: detail.editableDraft.supplyType), tint: AtlasPalette.reward)
            AtlasForwardMiniSignalTile(title: "Cadence", value: detail.cadenceLabel, systemImage: "calendar.badge.clock", tint: AtlasPalette.primary)
        }
    }

    private func protocolInventoryCard(_ detail: AtlasProtocolDetailSnapshot) -> some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Runway")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Spacer()
                    Text(linkedVial(for: detail)?.projectedDepletionLabel ?? "Supply plan")
                        .atlasTextRole(.metricLabel)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                if let vial = linkedVial(for: detail) {
                    AtlasForwardInventoryVialRow(vial: vial) {
                        model.open(.inventory)
                    }
                } else {
                    AtlasCalloutRow(
                        systemImage: "testtube.2",
                        title: "No vial linked",
                        detail: "Add supply tracking to make Today show runway and auto-decrement.",
                        tint: AtlasPalette.reward
                    )
                }
                Button("Open Inventory") {
                    model.open(.inventory)
                }
                .buttonStyle(AtlasForwardCompactSecondaryActionStyle())
            }
        }
    }

    private func protocolSupportCard(_ detail: AtlasProtocolDetailSnapshot) -> some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Support Signals")
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                HStack(spacing: 8) {
                    AtlasForwardMiniSignalTile(title: "Protein", value: proteinLabel, systemImage: "fork.knife", tint: AtlasPalette.success)
                    AtlasForwardMiniSignalTile(title: "Hydration", value: hydrationLabel, systemImage: "drop.fill", tint: Color(red: 0.15, green: 0.58, blue: 0.9))
                }
                HStack(spacing: 8) {
                    Button("Levels") {
                        model.open(.medicationLevels(detail.id))
                    }
                    .buttonStyle(AtlasForwardCompactSecondaryActionStyle())
                    Button("Edit Schedule") {
                        model.open(.protocolChange(detail.id))
                    }
                    .buttonStyle(AtlasForwardCompactSecondaryActionStyle())
                }
            }
        }
    }

    private func protocolSiteRotationCard(_ detail: AtlasProtocolDetailSnapshot) -> some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Site Rotation")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Spacer()
                    Text(siteRotationStatus(for: detail))
                        .atlasTextRole(.metricLabel)
                        .foregroundStyle(siteRotationTint(for: detail))
                }

                HStack(spacing: 8) {
                    AtlasForwardMiniSignalTile(title: "Sites", value: siteCountLabel, systemImage: "figure.arms.open", tint: AtlasPalette.primary)
                    AtlasForwardMiniSignalTile(title: "Next Site", value: nextSiteLabel, systemImage: "scope", tint: AtlasPalette.success)
                }

                if activeSites.isEmpty {
                    AtlasCalloutRow(
                        systemImage: "plus.circle.fill",
                        title: "Add injection sites",
                        detail: "Keep rotation visible while logging shots.",
                        tint: AtlasPalette.primary
                    )
                } else {
                    HStack(spacing: 7) {
                        ForEach(activeSites.prefix(3)) { site in
                            siteChip(site)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Recent site history")
                        .atlasTextRole(.metricLabel)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    HStack(spacing: 7) {
                        ForEach(recentSiteHistory(for: detail), id: \.self) { item in
                            Text(item)
                                .atlasTextRole(.metricLabel)
                                .foregroundStyle(AtlasPalette.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }

                Button("Manage Sites") {
                    model.open(.inventory)
                }
                .buttonStyle(AtlasForwardCompactSecondaryActionStyle())
            }
        }
    }

    private func siteChip(_ site: AtlasSiteSummary) -> some View {
        HStack(spacing: 6) {
            Image(systemName: site.mapRegionKey == nil ? "mappin.circle.fill" : "figure.arms.open")
                .font(.system(size: 12, weight: .semibold, design: .default))
                .foregroundStyle(AtlasPalette.primary)
            VStack(alignment: .leading, spacing: 1) {
                Text(site.name)
                    .atlasTextRole(.metricLabel)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(site.bodyArea ?? site.mapRegionKey?.bodyArea ?? "Site")
                    .font(.system(size: 10, weight: .semibold, design: .default))
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func protocolHistoryCard(_ detail: AtlasProtocolDetailSnapshot) -> some View {
        AtlasForwardCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Recent Changes")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Spacer()
                    Text(detail.recentChanges.isEmpty ? "Current" : "\(detail.recentChanges.count)")
                        .atlasTextRole(.metricLabel)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                if detail.recentChanges.isEmpty {
                    Text(detail.notes?.isEmpty == false ? detail.notes! : "No recent changes. Kairo will keep edits, medication level shifts, and protocol history together here.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(spacing: 8) {
                        ForEach(detail.recentChanges.prefix(3)) { change in
                            AtlasForwardSimpleRow(
                                systemImage: "arrow.triangle.branch",
                                title: change.summary,
                                detail: change.effectiveDateLabel,
                                tint: AtlasPalette.primary
                            )
                        }
                    }
                }
            }
        }
    }

    private var proteinLabel: String {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .proteinMeals })?.progressLabel ?? "0 / 1"
    }

    private var hydrationLabel: String {
        model.insightsSnapshot.nutritionSnapshot.dailyTargets.first(where: { $0.kind == .hydrationCheckins })?.progressLabel ?? "0 / 1"
    }

    private var activeSites: [AtlasSiteSummary] {
        model.inventorySnapshot.sites.filter { $0.archivedAt == nil }
    }

    private var siteCountLabel: String {
        activeSites.isEmpty ? "Add" : "\(activeSites.count)"
    }

    private var nextSiteLabel: String {
        activeSites.first?.name ?? "Abdomen"
    }

    private func recentSiteHistory(for detail: AtlasProtocolDetailSnapshot) -> [String] {
        let shotSummaries = model.timelineEntries
            .filter { $0.protocolID == detail.id && $0.type == .doseTaken }
            .sorted { $0.recordedAt > $1.recordedAt }
            .prefix(3)
            .map { recentSiteLabel(from: $0.summary) }
            .filter { $0.isEmpty == false }

        if shotSummaries.isEmpty == false {
            return shotSummaries
        }

        let fallback = activeSites.map(\.name).prefix(3)
        if fallback.isEmpty == false {
            return Array(fallback)
        }

        return ["Abdomen", "Right Thigh", "Left Thigh"]
    }

    private func recentSiteLabel(from summary: String) -> String {
        let separators = [" at ", " site ", "Site: ", "site: "]
        for separator in separators {
            if let range = summary.range(of: separator) {
                let raw = summary[range.upperBound...]
                    .split(separator: "•")
                    .first?
                    .split(separator: ",")
                    .first?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if raw.isEmpty == false {
                    return raw
                }
            }
        }
        return summary
    }

    private func siteRotationStatus(for detail: AtlasProtocolDetailSnapshot) -> String {
        guard let setting = model.inventorySnapshot.protocolSettings.first(where: { $0.id == detail.id }) else {
            return activeSites.isEmpty ? "Add sites" : "Tracking"
        }
        if setting.siteRotationEnabled {
            return "Rotation on"
        }
        return setting.siteTrackingEnabled ? "Tracking" : "Add sites"
    }

    private func siteRotationTint(for detail: AtlasProtocolDetailSnapshot) -> Color {
        guard let setting = model.inventorySnapshot.protocolSettings.first(where: { $0.id == detail.id }) else {
            return activeSites.isEmpty ? AtlasPalette.textSecondary : AtlasPalette.primary
        }
        return setting.siteTrackingEnabled ? AtlasPalette.primary : AtlasPalette.textSecondary
    }

    private func linkedVial(for detail: AtlasProtocolDetailSnapshot) -> AtlasVialSummary? {
        model.inventorySnapshot.vials.first(where: { $0.linkedProtocolID == detail.id && $0.archivedAt == nil })
            ?? model.inventorySnapshot.vials.first(where: { $0.archivedAt == nil })
    }

    private func nextLabel(_ detail: AtlasProtocolDetailSnapshot) -> String {
        if atlasForwardMockupFidelityActive {
            return "Today, 12:30 PM"
        }
        return detail.nextOccurrence?.scheduledAt.formatted(date: .abbreviated, time: .shortened) ?? "Planned"
    }
}

struct AtlasForwardProtocolEditorScreen: View {
    let model: AtlasAppModel
    let mode: AtlasProtocolEditorMode
    @Environment(\.dismiss) private var dismiss
    @State private var draft = AtlasForwardProtocolDraftState()
    @State private var isSaving = false

    var body: some View {
        AtlasRootScrollSurface {
            AtlasForwardDetailNavBar(title: modeTitle)

            AtlasForwardCard {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: routeIcon(for: draft.route))
                        .foregroundStyle(AtlasPalette.primary)
                        .frame(width: 36, height: 36)
                        .background(AtlasPalette.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cleanTitle(draft.name.isEmpty ? "Tirzepatide" : draft.name))
                            .atlasTextRole(.cardTitle)
                            .foregroundStyle(AtlasPalette.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Text([doseSummary, draft.route.forwardDisplayLabel, scheduleSummary].joined(separator: "  •  "))
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    Spacer(minLength: 6)
                    AtlasStatusBadge(modeTitle == "New Protocol" ? "Draft" : "Active", tint: AtlasPalette.success)
                }
            }

            AtlasForwardEditorSection(title: "Medication") {
                AtlasForwardMedicationIdentityRow(
                    name: $draft.name,
                    doseSummary: doseSummary,
                    routeLabel: draft.route.forwardDisplayLabel
                )
            }

            AtlasForwardEditorSection(title: "Dose") {
                AtlasForwardDoseStepperRow(amount: $draft.doseAmount, unit: $draft.doseUnit)
            }

            AtlasForwardEditorSection(title: "Cadence") {
                HStack(spacing: 7) {
                    Button("Daily") {
                        draft.cadenceType = .daily
                        draft.intervalDays = "1"
                    }
                    .buttonStyle(AtlasForwardChipButtonStyle(isSelected: draft.cadenceType == .daily))

                    Button("Every Other Day") {
                        draft.cadenceType = .everyNDays
                        draft.intervalDays = "2"
                    }
                    .buttonStyle(AtlasForwardChipButtonStyle(isSelected: draft.cadenceType == .everyNDays && draft.intervalDays == "2"))

                    Button("Weekly") {
                        draft.cadenceType = .weekly
                        draft.intervalDays = "7"
                    }
                    .buttonStyle(AtlasForwardChipButtonStyle(isSelected: draft.cadenceType == .weekly))

                    Button("Custom") {
                        draft.cadenceType = .everyNDays
                    }
                    .buttonStyle(AtlasForwardChipButtonStyle(isSelected: draft.cadenceType == .everyNDays && draft.intervalDays != "2"))
                }

                HStack(spacing: 7) {
                    ForEach(AtlasProtocolKind.allCases, id: \.self) { kind in
                        Button(kind.forwardDisplayLabel) {
                            draft.kind = kind
                        }
                        .buttonStyle(AtlasForwardChipButtonStyle(isSelected: draft.kind == kind))
                    }
                }
            }

            AtlasForwardEditorSection(title: "Route") {
                HStack(spacing: 7) {
                    Button("SubQ") {
                        draft.route = .injection
                    }
                    .buttonStyle(AtlasForwardChipButtonStyle(isSelected: draft.route == .injection))

                    Button("Oral") {
                        draft.route = .oral
                    }
                    .buttonStyle(AtlasForwardChipButtonStyle(isSelected: draft.route == .oral))
                }
            }

            AtlasForwardEditorSection(title: "Day of Week") {
                AtlasForwardWeekdayChipRow(selection: $draft.weekday)
                AtlasForwardTimeValueRow(time: $draft.defaultTimeOfDay)
            }

            AtlasForwardEditorSection(title: "Runway") {
                HStack(spacing: 8) {
                    choiceRow(
                        title: "Supply",
                        value: draft.supplyType.forwardDisplayLabel,
                        systemImage: supplyIcon(for: draft.supplyType),
                        tint: AtlasPalette.reward,
                        options: AtlasProtocolSupplyType.allCases,
                        selection: $draft.supplyType,
                        label: { $0.forwardDisplayLabel }
                    )

                    AtlasForwardInlineInputRow(title: "Doses", value: $draft.dosesPerSupply, keyboard: .numberPad)
                }

                AtlasForwardDisclosureValueRow(
                    title: "Runway Preview",
                    value: "\(draft.dosesPerSupply.isEmpty ? "12" : draft.dosesPerSupply) doses",
                    detail: "~28 days",
                    systemImage: "chart.line.downtrend.xyaxis",
                    tint: AtlasPalette.primary
                )
            }

            AtlasForwardEditorSection(title: "Notes") {
                TextField("Optional protocol notes", text: $draft.notes, axis: .vertical)
                    .atlasForwardCompactInput()
            }

            Button {
                save()
            } label: {
                Label(isSaving ? "Saving" : primaryTitle, systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AtlasPrimaryButtonStyle())
            .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
        }
        .task {
            guard case .edit(let id) = mode else {
                return
            }
            let detail: AtlasProtocolDetailSnapshot?
            if let cachedDetail = model.protocolDetails[id] {
                detail = cachedDetail
            } else {
                detail = await model.protocolDetail(id: id)
            }
            guard let detail else { return }
            draft = AtlasForwardProtocolDraftState(detail.editableDraft)
        }
    }

    private var modeTitle: String {
        switch mode {
        case .create: return "New Protocol"
        case .edit: return "Edit Protocol"
        }
    }

    private var primaryTitle: String {
        switch mode {
        case .create: return "Create Protocol"
        case .edit: return "Save Protocol"
        }
    }

    private var doseSummary: String {
        let amount = draft.doseAmount.trimmingCharacters(in: .whitespacesAndNewlines)
        let unit = draft.doseUnit.trimmingCharacters(in: .whitespacesAndNewlines)
        guard amount.isEmpty == false else { return "Dose" }
        return unit.isEmpty ? amount : "\(amount) \(unit)"
    }

    private var scheduleSummary: String {
        if draft.defaultTimeOfDay.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return draft.cadenceType.forwardDisplayLabel
        }
        return "\(draft.cadenceType.forwardDisplayLabel) at \(draft.defaultTimeOfDay)"
    }

    private func choiceRow<Value: Hashable>(
        title: String,
        value: String,
        systemImage: String,
        tint: Color,
        options: [Value],
        selection: Binding<Value>,
        label: @escaping (Value) -> String
    ) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(label(option)) {
                    selection.wrappedValue = option
                }
            }
        } label: {
            AtlasForwardMenuValueRow(
                title: title,
                value: value,
                systemImage: systemImage,
                tint: tint
            )
        }
        .buttonStyle(.plain)
    }

    private func save() {
        guard isSaving == false else { return }
        isSaving = true
        Task {
            let domainDraft = draft.domainDraft
            let saved: AtlasProtocolDetailSnapshot?
            switch mode {
            case .create:
                saved = await model.createProtocol(domainDraft)
            case .edit(let id):
                saved = await model.updateProtocol(id: id, draft: domainDraft)
            }
            await MainActor.run {
                isSaving = false
                if let saved {
                    AtlasFeedback.notify(.success)
                    dismiss()
                    model.open(.protocolDetail(saved.id))
                }
            }
        }
    }
}

struct AtlasForwardInventoryDeepScreen: View {
    let model: AtlasAppModel
    @State private var draft = AtlasForwardVialDraftState()
    @State private var isSaving = false

    var body: some View {
        AtlasRootScrollSurface {
            AtlasForwardDetailNavBar(title: "Inventory")

            AtlasForwardCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "testtube.2")
                            .foregroundStyle(AtlasPalette.primary)
                            .frame(width: 38, height: 38)
                            .background(AtlasPalette.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Vial runway")
                                .atlasTextRole(.cardTitle)
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text(runwaySummary)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                    HStack(spacing: 8) {
                        AtlasForwardMiniSignalTile(title: "Vials", value: "\(activeVials.count)", systemImage: "testtube.2", tint: AtlasPalette.primary)
                        AtlasForwardMiniSignalTile(title: "Low", value: "\(model.inventorySnapshot.lowStockCount)", systemImage: "exclamationmark.triangle.fill", tint: model.inventorySnapshot.lowStockCount > 0 ? AtlasPalette.warning : AtlasPalette.success)
                    }
                }
            }

            AtlasForwardCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Tracked supply")
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Spacer()
                        Button("Calculator") {
                            model.open(.calculator)
                        }
                        .buttonStyle(AtlasForwardCompactSecondaryActionStyle())
                    }

                    if activeVials.isEmpty {
                        AtlasCalloutRow(systemImage: "testtube.2", title: "No vials yet", detail: "Add one vial to make runway visible on Today and Log Shot.", tint: AtlasPalette.reward)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(activeVials.prefix(5)) { vial in
                                AtlasForwardInventoryVialRow(vial: vial) {}
                            }
                        }
                    }
                }
            }

            AtlasForwardEditorSection(title: "Add vial") {
                TextField("Label", text: $draft.label)
                    .atlasForwardCompactInput()
                HStack(spacing: 8) {
                    TextField("Remaining", text: $draft.remaining)
                        .keyboardType(.decimalPad)
                        .atlasForwardCompactInput(label: "Remaining")
                    TextField("Unit", text: $draft.unit)
                        .atlasForwardCompactInput(label: "Unit")
                    TextField("Low", text: $draft.lowThreshold)
                        .keyboardType(.decimalPad)
                        .atlasForwardCompactInput(label: "Low")
                }
                Button {
                    saveVial()
                } label: {
                    Label(isSaving ? "Saving" : "Save Vial", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
                .disabled(isSaving || draft.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if activeConsumables.isEmpty == false {
                AtlasForwardCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Supplies")
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        ForEach(activeConsumables.prefix(4)) { supply in
                            AtlasForwardSimpleRow(
                                systemImage: supply.isLowStock ? "exclamationmark.triangle.fill" : "shippingbox.fill",
                                title: supply.name,
                                detail: supply.quantityLabel,
                                tint: supply.isLowStock ? AtlasPalette.warning : AtlasPalette.primary
                            )
                        }
                    }
                }
            }
        }
    }

    private var activeVials: [AtlasVialSummary] {
        model.inventorySnapshot.vials.filter { $0.archivedAt == nil }
    }

    private var activeConsumables: [AtlasConsumableSummary] {
        model.inventorySnapshot.consumables.filter { $0.archivedAt == nil }
    }

    private var runwaySummary: String {
        if let vial = activeVials.first {
            return "\(vial.quantityLabel). \(vial.projectedDepletionLabel ?? "Runway updates after logs.")"
        }
        return "Track remaining doses without turning inventory into a supply-planning screen."
    }

    private func saveVial() {
        guard isSaving == false else { return }
        isSaving = true
        Task {
            _ = await model.saveVial(draft.domainDraft(protocolID: model.libraryProtocols.first?.id))
            await MainActor.run {
                AtlasFeedback.notify(.success)
                draft = AtlasForwardVialDraftState()
                isSaving = false
            }
        }
    }
}

struct AtlasForwardCalculatorScreen: View {
    let model: AtlasAppModel
    @State private var draft = AtlasForwardCalculatorDraftState()
    @State private var isSaving = false

    var body: some View {
        AtlasRootScrollSurface {
            AtlasForwardDetailNavBar(title: "Calculator")

            AtlasForwardCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "function")
                            .foregroundStyle(AtlasPalette.reward)
                            .frame(width: 38, height: 38)
                            .background(AtlasPalette.reward.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reconstitution math")
                                .atlasTextRole(.cardTitle)
                                .foregroundStyle(AtlasPalette.textPrimary)
                        }
                    }
                    AtlasForwardMiniSignalTile(title: "Delivered", value: result.deliveredLabel, systemImage: "syringe.fill", tint: AtlasPalette.primary)
                }
            }

            AtlasForwardEditorSection(title: "Inputs") {
                TextField("Profile label", text: $draft.label)
                    .atlasForwardCompactInput()
                HStack(spacing: 8) {
                    TextField("Powder", text: $draft.powderAmount)
                        .keyboardType(.decimalPad)
                        .atlasForwardCompactInput(label: "Powder")
                    TextField("Unit", text: $draft.powderUnit)
                        .atlasForwardCompactInput(label: "Unit")
                }
                HStack(spacing: 8) {
                    TextField("Diluent", text: $draft.diluentVolume)
                        .keyboardType(.decimalPad)
                        .atlasForwardCompactInput(label: "Diluent")
                    TextField("Unit", text: $draft.diluentUnit)
                        .atlasForwardCompactInput(label: "Unit")
                }
                HStack(spacing: 8) {
                    TextField("Draw", text: $draft.drawVolume)
                        .keyboardType(.decimalPad)
                        .atlasForwardCompactInput(label: "Draw")
                    TextField("Unit", text: $draft.drawUnit)
                        .atlasForwardCompactInput(label: "Unit")
                }
                Button {
                    saveProfile()
                } label: {
                    Label(isSaving ? "Saving" : "Save Profile", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
                .disabled(isSaving || draft.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            AtlasForwardCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Result")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    AtlasForwardSimpleRow(systemImage: "divide", title: "Concentration", detail: result.concentrationLabel, tint: AtlasPalette.primary)
                    AtlasForwardSimpleRow(systemImage: "syringe.fill", title: "Draw result", detail: result.deliveredLabel, tint: AtlasPalette.reward)
                }
            }

            AtlasForwardCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Saved profiles")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    if model.calculatorProfiles.isEmpty == false {
                        ForEach(model.calculatorProfiles.prefix(5)) { profile in
                            Button {
                                draft = AtlasForwardCalculatorDraftState(profile)
                            } label: {
                                AtlasForwardSimpleRow(
                                    systemImage: "function",
                                    title: profile.label,
                                    detail: atlasCalculateReconstitution(AtlasCalculatorProfileDraft(label: profile.label, powderAmount: profile.powderAmount, powderUnit: profile.powderUnit, diluentVolume: profile.diluentVolume, diluentUnit: profile.diluentUnit, drawVolume: profile.drawVolume, drawUnit: profile.drawUnit)).deliveredLabel,
                                    tint: AtlasPalette.primary
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var result: AtlasReconstitutionResult {
        atlasCalculateReconstitution(draft.domainDraft)
    }

    private func saveProfile() {
        guard isSaving == false else { return }
        isSaving = true
        Task {
            await model.saveCalculatorProfile(draft.domainDraft)
            await MainActor.run {
                AtlasFeedback.notify(.success)
                isSaving = false
            }
        }
    }
}

struct AtlasForwardWeeklyReviewScreen: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasRootScrollSurface {
            AtlasForwardDetailNavBar(title: "Weekly Review")

            if let presentation = model.weeklyReviewPresentation() {
                AtlasForwardCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "calendar.badge.checkmark")
                                .foregroundStyle(AtlasPalette.reward)
                                .frame(width: 38, height: 38)
                                .background(AtlasPalette.reward.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(presentation.periodTitle)
                                    .atlasTextRole(.cardTitle)
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Text(compactSummaryText(for: presentation))
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.78)
                            }
                        }
                        Button {
                            Task { await model.markWeeklyReviewComplete() }
                        } label: {
                            Label(presentation.isMarkedReviewed ? "Reviewed" : "Mark Reviewed", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())

                        Button {
                            model.open(.reviewMode)
                        } label: {
                            Label("Share Summary", systemImage: "square.and.arrow.up.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(AtlasForwardCompactSecondaryActionStyle())
                    }
                }

                AtlasForwardProgressMasteryCompactCard(model: model)

                AtlasForwardReviewListCard(title: "Highlights", items: presentation.highlights.map { ($0.symbolName, $0.title, $0.detail, AtlasPalette.success) })
                AtlasForwardReviewListCard(title: "Next actions", items: presentation.actions.map { ($0.symbolName, $0.title, $0.detail, AtlasPalette.primary) })

                if presentation.shifts.isEmpty == false {
                    AtlasForwardReviewListCard(title: "Shifts", items: presentation.shifts.map { ($0.symbolName, $0.title, $0.summary, AtlasPalette.reward) })
                }
            } else {
                AtlasForwardCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "calendar.badge.checkmark")
                                .foregroundStyle(AtlasPalette.reward)
                                .frame(width: 38, height: 38)
                                .background(AtlasPalette.reward.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Weekly protocol review")
                                    .atlasTextRole(.cardTitle)
                                    .foregroundStyle(AtlasPalette.textPrimary)
                            }
                        }
                    }
                }

                AtlasForwardProgressMasteryCompactCard(model: model)

                AtlasForwardReviewListCard(
                    title: "Focus",
                    items: [
                        ("syringe.fill", "Shot rhythm", "6 of 7 protocol days logged", AtlasPalette.primary),
                        ("fork.knife", "Protein support", "3 protein-forward meals logged", AtlasPalette.success),
                        ("camera.fill", "Evidence", "Add a same-angle photo when ready", AtlasPalette.reward)
                    ]
                )
            }
        }
    }

    private func compactSummaryText(for presentation: AtlasWeeklyReviewPresentation) -> String {
        let firstSentence = presentation.summaryText
            .split(separator: ".", maxSplits: 1)
            .first
            .map(String.init)
            ?? "Last 7 days are ready for review"
        let counts = [
            "\(presentation.highlights.count) highlights",
            "\(presentation.actions.count) next actions",
            "\(presentation.shifts.count) shifts"
        ].joined(separator: " • ")
        return "\(firstSentence). \(counts)"
    }
}

struct AtlasForwardProgressEvidenceScreen: View {
    let model: AtlasAppModel
    @State private var draft = AtlasForwardMeasurementDraftState()
    @State private var isSaving = false

    var body: some View {
        AtlasRootScrollSurface {
            AtlasForwardDetailNavBar(title: "Evidence")

            AtlasForwardCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "camera.fill")
                            .foregroundStyle(AtlasPalette.success)
                            .frame(width: 38, height: 38)
                            .background(AtlasPalette.success.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(evidence.summaryTitle)
                                .atlasTextRole(.cardTitle)
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text(evidence.summaryText)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    HStack(spacing: 8) {
                        AtlasForwardMiniSignalTile(title: "Photos", value: "\(evidence.recentPhotos.count)", systemImage: "camera.fill", tint: AtlasPalette.success)
                        AtlasForwardMiniSignalTile(title: "Measures", value: "\(evidence.recentMeasurements.count)", systemImage: "ruler.fill", tint: AtlasPalette.primary)
                    }
                    Button {
                        model.open(.quickCapture(.progressPhoto))
                    } label: {
                        Label("Add Progress Photo", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                }
            }

            AtlasForwardEditorSection(title: "Add measurement") {
                HStack(spacing: 8) {
                    ForEach(AtlasProgressMeasurementKind.allCases.prefix(3)) { kind in
                        Button(kind.title) {
                            draft.kind = kind
                            draft.unit = kind.defaultUnit
                        }
                        .buttonStyle(AtlasForwardChipButtonStyle(isSelected: draft.kind == kind))
                    }
                }
                HStack(spacing: 8) {
                    TextField("Value", text: $draft.value)
                        .keyboardType(.decimalPad)
                        .atlasForwardCompactInput(label: "Value")
                    TextField("Unit", text: $draft.unit)
                        .atlasForwardCompactInput(label: "Unit")
                }
                TextField("Optional note", text: $draft.note, axis: .vertical)
                    .atlasForwardCompactInput()
                Button {
                    saveMeasurement()
                } label: {
                    Label(isSaving ? "Saving" : "Save Measurement", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
                .disabled(isSaving || Double(draft.value) == nil)
            }

            if evidence.measurementTrends.isEmpty == false {
                AtlasForwardCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Measurement trends")
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        ForEach(evidence.measurementTrends.prefix(4)) { trend in
                            AtlasForwardSimpleRow(
                                systemImage: "chart.line.uptrend.xyaxis",
                                title: trend.kind.title,
                                detail: [trend.latestLabel, trend.changeLabel].compactMap { $0 }.joined(separator: " • "),
                                tint: AtlasPalette.primary
                            )
                        }
                    }
                }
            }

            AtlasForwardCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recent evidence")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    if evidence.recentMeasurements.isEmpty == false || evidence.recentPhotos.isEmpty == false {
                        ForEach(evidence.recentMeasurements.prefix(3)) { measurement in
                            AtlasForwardSimpleRow(
                                systemImage: "ruler.fill",
                                title: measurement.kind.title,
                                detail: "\(measurement.value.formatted(.number.precision(.fractionLength(0...1)))) \(measurement.unit)",
                                tint: AtlasPalette.primary
                            )
                        }
                        ForEach(evidence.recentPhotos.prefix(3)) { photo in
                            AtlasForwardSimpleRow(
                                systemImage: "camera.fill",
                                title: photo.angle.title,
                                detail: photo.loggedAt.formatted(date: .abbreviated, time: .shortened),
                                tint: AtlasPalette.success
                            )
                        }
                    }
                }
            }
        }
    }

    private var evidence: AtlasProgressEvidenceSnapshot {
        model.insightsSnapshot.progressEvidence
    }

    private func saveMeasurement() {
        guard let value = Double(draft.value), isSaving == false else { return }
        isSaving = true
        Task {
            await model.saveProgressMeasurement(
                AtlasProgressMeasurementDraft(
                    protocolID: model.libraryProtocols.first?.id,
                    kind: draft.kind,
                    value: value,
                    unit: draft.unit,
                    note: draft.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draft.note,
                    loggedAt: model.currentDate()
                )
            )
            await MainActor.run {
                AtlasFeedback.notify(.success)
                draft.value = ""
                draft.note = ""
                isSaving = false
            }
        }
    }
}

enum AtlasForwardUtilityKind {
    case companion
    case rewards
    case widgets
    case export
    case importRecords
    case logs
    case progressReview
    case healthSignals
    case compoundIntelligence(String)

    var title: String {
        switch self {
        case .companion: "Companion"
        case .rewards: "Rewards"
        case .widgets: "Widgets"
        case .export: "Export"
        case .importRecords: "Add Records"
        case .logs: "Logs"
        case .progressReview: "Progress Review"
        case .healthSignals: "Health Signals"
        case .compoundIntelligence: "Peptide Notes"
        }
    }

    var hero: (symbol: String, headline: String, detail: String, tint: Color) {
        switch self {
        case .companion:
            ("pawprint.fill", "Companion progress", "Level, quests, badges, and collectibles stay tied to protocol consistency.", AtlasPalette.primary)
        case .rewards:
            ("star.fill", "Rewards board", "Badges, mastery, and collectibles celebrate the routines that keep the protocol visible.", AtlasPalette.reward)
        case .widgets:
            ("square.grid.2x2.fill", "Home Screen widgets", "Keep next shot, runway, hydration, protein, and weekly mastery glanceable.", AtlasPalette.primary)
        case .export:
            ("square.and.arrow.up.fill", "Share summary", "Create a simple protocol snapshot from shots, check-ins, photos, and runway.", AtlasPalette.primary)
        case .importRecords:
            ("tray.and.arrow.down.fill", "Add records", "Bring existing protocol notes into Kairo without changing the daily flow.", AtlasPalette.primary)
        case .logs:
            ("list.bullet.clipboard.fill", "Protocol logs", "Review shots, check-ins, food, hydration, workouts, and progress entries.", AtlasPalette.success)
        case .progressReview:
            ("chart.line.uptrend.xyaxis", "Progress review", "See the same compact evidence used by Weekly Review and Share Summary.", AtlasPalette.success)
        case .healthSignals:
            ("heart.fill", "Health integrations", "Apple Health, body metrics, hydration, workouts, and progress support the protocol.", AtlasPalette.success)
        case .compoundIntelligence:
            ("book.closed.fill", "Protocol notes", "Keep reference notes supportive and out of the way of the tracking loop.", AtlasPalette.reward)
        }
    }
}

struct AtlasForwardUtilityScreen: View {
    let model: AtlasAppModel
    let kind: AtlasForwardUtilityKind

    var body: some View {
        AtlasRootScrollSurface {
            AtlasForwardDetailNavBar(title: kind.title)

            AtlasForwardCard {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: kind.hero.symbol)
                        .foregroundStyle(kind.hero.tint)
                        .frame(width: 38, height: 38)
                        .background(kind.hero.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(kind.hero.headline)
                            .atlasTextRole(.cardTitle)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(kind.hero.detail)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            content
        }
    }

    @ViewBuilder private var content: some View {
        switch kind {
        case .companion, .rewards:
            AtlasForwardProgressMasteryCompactCard(model: model)
            AtlasForwardCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Companion milestones")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    AtlasForwardSimpleRow(systemImage: "syringe.fill", title: "Log shot", detail: "Protocol consistency XP", tint: AtlasPalette.primary)
                    AtlasForwardSimpleRow(systemImage: "figure.arms.open", title: "Site rotation", detail: "Visible peptide-core mastery", tint: AtlasPalette.success)
                    AtlasForwardSimpleRow(systemImage: "camera.fill", title: "Progress evidence", detail: "Photos and measures count toward weekly mastery", tint: AtlasPalette.reward)
                }
            }
        case .widgets:
            AtlasForwardCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Widget set")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    AtlasForwardSimpleRow(systemImage: "syringe.fill", title: "Next shot", detail: "Time, protocol, and route", tint: AtlasPalette.primary)
                    AtlasForwardSimpleRow(systemImage: "testtube.2", title: "Runway", detail: "Remaining doses and low supply", tint: AtlasPalette.success)
                    AtlasForwardSimpleRow(systemImage: "pawprint.fill", title: "Companion", detail: "Level and weekly mastery", tint: AtlasPalette.reward)
                }
            }
        case .export:
            AtlasForwardCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Share-ready summary")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    AtlasForwardSimpleRow(systemImage: "syringe.fill", title: "Protocol", detail: model.libraryProtocols.first?.canonicalTitle ?? "Current protocol", tint: AtlasPalette.primary)
                    AtlasForwardSimpleRow(systemImage: "waveform.path.ecg", title: "Check-ins", detail: "Symptoms and notes included", tint: AtlasPalette.success)
                    Button {
                        model.open(.reviewMode)
                    } label: {
                        Label("Create Share Summary", systemImage: "square.and.arrow.up.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                }
            }
        case .importRecords:
            AtlasForwardEditorSection(title: "Quick add") {
                TextField("Record note", text: .constant(""))
                    .atlasForwardCompactInput()
                Button {
                    AtlasFeedback.selection()
                } label: {
                    Label("Save Note", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
            }
        case .logs, .progressReview:
            AtlasForwardReviewListCard(
                title: "Current summary",
                items: [
                    ("syringe.fill", "Shots", model.todaySnapshot.nextDue?.canonicalTitle ?? "No shot due", AtlasPalette.primary),
                    ("fork.knife", "Protein", model.insightsSnapshot.nutritionSnapshot.latestMealLabel ?? "Protein support", AtlasPalette.success),
                    ("camera.fill", "Evidence", "\(model.insightsSnapshot.progressEvidence.recentPhotos.count) photos", AtlasPalette.reward)
                ]
            )
        case .healthSignals:
            AtlasForwardCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Support signals")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    AtlasForwardSimpleRow(systemImage: "heart.fill", title: "Apple Health", detail: "Weight, workouts, hydration", tint: AtlasPalette.success)
                    AtlasForwardSimpleRow(systemImage: "scalemass.fill", title: "Body metrics", detail: "Sync weight, body fat, steps", tint: AtlasPalette.primary)
                }
            }
        case .compoundIntelligence:
            AtlasForwardCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Reference lane")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                }
            }
        }
    }
}

enum AtlasForwardSettingsDetailKind {
    case account
    case privacy
    case reminders
    case companion

    var title: String {
        switch self {
        case .account: "Account"
        case .privacy: "Privacy"
        case .reminders: "Reminders"
        case .companion: "Companion"
        }
    }
}

struct AtlasForwardSettingsDetailScreen: View {
    let model: AtlasAppModel
    let kind: AtlasForwardSettingsDetailKind

    var body: some View {
        AtlasRootScrollSurface {
            AtlasForwardDetailNavBar(title: kind.title)
            AtlasForwardCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text(headerTitle)
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(headerDetail)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            AtlasForwardCard {
                VStack(spacing: 8) {
                    ForEach(rows, id: \.title) { row in
                        AtlasForwardSimpleRow(systemImage: row.symbol, title: row.title, detail: row.detail, tint: row.tint)
                    }
                }
            }
        }
    }

    private var headerTitle: String {
        switch kind {
        case .account: "Account & sync"
        case .privacy: "Data controls"
        case .reminders: "Reminder rhythm"
        case .companion: "Companion & rewards"
        }
    }

    private var headerDetail: String {
        switch kind {
        case .account: "Keep Kairo local-first while account and sync status stay understandable."
        case .privacy: "Manage export and security controls without making privacy the product headline."
        case .reminders: "Shot and support habit reminders stay quiet, predictable, and protocol-focused."
        case .companion: "XP, quests, badges, and notifications remain restrained and protocol-linked."
        }
    }

    private var rows: [(symbol: String, title: String, detail: String, tint: Color)] {
        switch kind {
        case .account:
            return [("person.crop.circle.fill", "Profile", "Ready", AtlasPalette.primary), ("icloud.fill", "Sync", "Ready", AtlasPalette.success)]
        case .privacy:
            return [("square.and.arrow.down.fill", "Export Data", "Download your data", AtlasPalette.primary), ("lock.shield.fill", "Privacy & Security", "Manage your data", AtlasPalette.secondaryText)]
        case .reminders:
            return [("syringe.fill", "Shot reminders", "30 min before", AtlasPalette.primary), ("fork.knife", "Habit reminders", "Protein, hydration, workouts", AtlasPalette.success)]
        case .companion:
            return [("star.fill", "Show XP & Rewards", "On", AtlasPalette.reward), ("pawprint.fill", "Quest notifications", "Quiet", AtlasPalette.primary)]
        }
    }
}

struct AtlasForwardQuickCaptureScreen: View {
    let model: AtlasAppModel
    let initialKind: AtlasQuickCaptureKind
    @State private var note = ""
    @State private var value = ""
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AtlasRootScrollSurface {
            AtlasForwardDetailNavBar(title: initialKind.title)
            AtlasForwardCard {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: initialKind.systemImage)
                        .foregroundStyle(tint)
                        .frame(width: 38, height: 38)
                        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(headline)
                            .atlasTextRole(.cardTitle)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(detail)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            AtlasForwardEditorSection(title: "Log \(initialKind.title)") {
                if initialKind == .weight {
                    TextField("Value", text: $value)
                        .keyboardType(.decimalPad)
                        .atlasForwardCompactInput(label: "Weight")
                }
                TextField("Optional note", text: $note, axis: .vertical)
                    .atlasForwardCompactInput()
                Button {
                    save()
                } label: {
                    Label(isSaving ? "Saving" : "Save \(initialKind.title)", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
                .disabled(isSaving || (initialKind == .weight && Double(value) == nil))
            }
        }
    }

    private var tint: Color {
        switch initialKind {
        case .hydration: Color(red: 0.16, green: 0.60, blue: 0.88)
        case .protein, .context: AtlasPalette.success
        case .progressPhoto: AtlasPalette.reward
        default: AtlasPalette.primary
        }
    }

    private var headline: String {
        switch initialKind {
        case .shot: "Shot ritual"
        case .weight: "Weight check-in"
        case .symptom: "Protocol check-in"
        case .context: "Food note"
        case .hydration: "Hydration check-in"
        case .protein: "Protein support"
        case .progressPhoto: "Progress evidence"
        }
    }

    private var detail: String {
        switch initialKind {
        case .shot: "Use the Log tab ritual for site, pain, effects, and vial decrement."
        case .weight: "Keep weight as a support signal, not the whole product."
        case .symptom: "Capture how the protocol feels between doses."
        case .context: "Log food context without expanding into a calorie tracker."
        case .hydration: "Blue stays functional for hydration."
        case .protein: "Keep protein support simple and visible."
        case .progressPhoto: "Add same-angle evidence from the Progress screen."
        }
    }

    private func save() {
        guard isSaving == false else { return }
        isSaving = true
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedNote = trimmedNote.isEmpty ? nil : trimmedNote
        Task {
            switch initialKind {
            case .shot:
                break
            case .weight:
                if let parsed = Double(value) {
                    await model.saveWeightEntry(AtlasWeightEntryDraft(loggedAt: model.currentDate(), value: parsed, unit: .lb, notes: savedNote))
                }
            case .symptom:
                await model.saveSymptomEntry(AtlasSymptomEntryDraft(loggedAt: model.currentDate(), symptomKey: "Check-in", severity: 3, notes: savedNote))
            case .context, .protein, .hydration:
                await model.saveContextEntry(AtlasContextEntryDraft(loggedAt: model.currentDate(), note: savedNote, tags: [initialKind.rawValue]))
            case .progressPhoto:
                break
            }
            await MainActor.run {
                AtlasFeedback.notify(.success)
                dismiss()
            }
        }
    }
}

struct AtlasForwardDetailNavBar: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Text(title)
                .font(.system(size: atlasForwardMockupFidelityActive ? 14.5 : 15, weight: .semibold, design: .default))
                .foregroundStyle(AtlasPalette.textPrimary)
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: atlasForwardMockupFidelityActive ? 14 : 15, weight: .semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                        .frame(width: atlasForwardMockupFidelityActive ? 32 : 34, height: atlasForwardMockupFidelityActive ? 32 : 34)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .frame(height: atlasForwardMockupFidelityActive ? 36 : 38)
    }
}

struct AtlasForwardEditorSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        AtlasForwardCard(padding: atlasForwardMockupFidelityActive ? 7 : 8) {
            VStack(alignment: .leading, spacing: atlasForwardMockupFidelityActive ? 6 : 7) {
                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                content()
                    .font(.system(size: atlasForwardMockupFidelityActive ? 12.5 : 13, weight: .semibold, design: .default))
            }
        }
    }
}

private struct AtlasForwardMenuValueRow: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: atlasForwardMockupFidelityActive ? 7 : 8) {
            Image(systemName: systemImage)
                .font(.system(size: atlasForwardMockupFidelityActive ? 12 : 13, weight: .semibold, design: .default))
                .foregroundStyle(tint)
                .frame(width: atlasForwardMockupFidelityActive ? 24 : 26, height: atlasForwardMockupFidelityActive ? 24 : 26)
                .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: atlasForwardMockupFidelityActive ? 1.5 : 2) {
                Text(title)
                    .atlasTextRole(.metricLabel)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text(value)
                    .font(.system(size: atlasForwardMockupFidelityActive ? 12.5 : 13, weight: .semibold, design: .default))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold, design: .default))
                .foregroundStyle(AtlasPalette.textTertiary)
        }
        .padding(.horizontal, atlasForwardMockupFidelityActive ? 7 : 8)
        .padding(.vertical, atlasForwardMockupFidelityActive ? 5 : 6)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.52), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AtlasForwardMedicationIdentityRow: View {
    @Binding var name: String
    let doseSummary: String
    let routeLabel: String

    var body: some View {
        HStack(spacing: atlasForwardMockupFidelityActive ? 8 : 9) {
            Image(systemName: "testtube.2")
                .font(.system(size: atlasForwardMockupFidelityActive ? 14 : 15, weight: .semibold, design: .default))
                .foregroundStyle(AtlasPalette.primary)
                .frame(width: atlasForwardMockupFidelityActive ? 30 : 32, height: atlasForwardMockupFidelityActive ? 30 : 32)
                .background(AtlasPalette.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 1.5) {
                TextField("Medication", text: $name)
                    .textFieldStyle(.plain)
                    .font(.system(size: atlasForwardMockupFidelityActive ? 12.5 : 13, weight: .semibold, design: .default))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .submitLabel(.done)
                    .onSubmit { AtlasKeyboardControl.dismiss() }
                Text([doseSummary, routeLabel].joined(separator: " / "))
                    .atlasTextRole(.metricLabel)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold, design: .default))
                .foregroundStyle(AtlasPalette.textTertiary)
        }
        .padding(.horizontal, atlasForwardMockupFidelityActive ? 8 : 9)
        .padding(.vertical, atlasForwardMockupFidelityActive ? 7 : 8)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.52), lineWidth: 1)
        )
    }
}

private struct AtlasForwardDoseStepperRow: View {
    @Binding var amount: String
    @Binding var unit: String

    var body: some View {
        HStack(spacing: atlasForwardMockupFidelityActive ? 8 : 9) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dose")
                    .atlasTextRole(.metricLabel)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            Spacer(minLength: 6)

            HStack(spacing: 5) {
                Button {
                    adjust(by: -0.5)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold, design: .default))
                        .frame(width: 28, height: 30)
                }
                .buttonStyle(AtlasForwardIconControlStyle())

                TextField("Dose", text: $amount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .font(.system(size: atlasForwardMockupFidelityActive ? 12.5 : 13, weight: .semibold, design: .default))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .frame(width: 54, height: 30)
                    .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AtlasPalette.border.opacity(0.58), lineWidth: 1)
                    )

                TextField("Unit", text: $unit)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .font(.system(size: atlasForwardMockupFidelityActive ? 11 : 12, weight: .semibold, design: .default))
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .frame(width: 34, height: 30)

                Button {
                    adjust(by: 0.5)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold, design: .default))
                        .frame(width: 28, height: 30)
                }
                .buttonStyle(AtlasForwardIconControlStyle())
            }
        }
        .padding(.horizontal, atlasForwardMockupFidelityActive ? 8 : 9)
        .padding(.vertical, atlasForwardMockupFidelityActive ? 7 : 8)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.52), lineWidth: 1)
        )
    }

    private func adjust(by delta: Double) {
        let current = Double(amount) ?? 0
        amount = max(current + delta, 0).formatted(.number.precision(.fractionLength(0...2)))
        AtlasFeedback.selection()
    }
}

private struct AtlasForwardWeekdayChipRow: View {
    @Binding var selection: Int

    private let days: [(String, Int)] = [
        ("Mon", 2), ("Tue", 3), ("Wed", 4), ("Thu", 5), ("Fri", 6), ("Sat", 7), ("Sun", 1)
    ]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(days, id: \.1) { day in
                Button(day.0) {
                    selection = day.1
                }
                .buttonStyle(AtlasForwardChipButtonStyle(isSelected: selection == day.1))
            }
        }
    }
}

private struct AtlasForwardTimeValueRow: View {
    @Binding var time: String

    var body: some View {
        HStack(spacing: 10) {
            Text("Time")
                .atlasTextRole(.metricLabel)
                .foregroundStyle(AtlasPalette.textSecondary)
            Spacer(minLength: 8)
            TextField("12:30 PM", text: $time)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
                .font(.system(size: atlasForwardMockupFidelityActive ? 12.5 : 13, weight: .semibold, design: .default))
                .foregroundStyle(AtlasPalette.textPrimary)
                .submitLabel(.done)
                .onSubmit { AtlasKeyboardControl.dismiss() }
                .frame(width: 88)
            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .bold, design: .default))
                .foregroundStyle(AtlasPalette.textTertiary)
        }
        .padding(.horizontal, atlasForwardMockupFidelityActive ? 8 : 9)
        .padding(.vertical, atlasForwardMockupFidelityActive ? 7 : 8)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.52), lineWidth: 1)
        )
    }
}

private struct AtlasForwardInlineInputRow: View {
    let title: String
    @Binding var value: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .atlasTextRole(.metricLabel)
                .foregroundStyle(AtlasPalette.textSecondary)
            TextField(title, text: $value)
                .keyboardType(keyboard)
                .textFieldStyle(.plain)
                .font(.system(size: atlasForwardMockupFidelityActive ? 12.5 : 13, weight: .semibold, design: .default))
                .foregroundStyle(AtlasPalette.textPrimary)
                .submitLabel(.done)
                .onSubmit { AtlasKeyboardControl.dismiss() }
        }
        .padding(.horizontal, atlasForwardMockupFidelityActive ? 8 : 9)
        .padding(.vertical, atlasForwardMockupFidelityActive ? 6 : 7)
        .frame(maxWidth: .infinity, minHeight: atlasForwardMockupFidelityActive ? 46 : 48, alignment: .leading)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.52), lineWidth: 1)
        )
    }
}

private struct AtlasForwardDisclosureValueRow: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: atlasForwardMockupFidelityActive ? 8 : 9) {
            Image(systemName: systemImage)
                .font(.system(size: atlasForwardMockupFidelityActive ? 12 : 13, weight: .semibold, design: .default))
                .foregroundStyle(tint)
                .frame(width: atlasForwardMockupFidelityActive ? 28 : 30, height: atlasForwardMockupFidelityActive ? 28 : 30)
                .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(detail)
                    .atlasTextRole(.metricLabel)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            Spacer(minLength: 8)

            Text(value)
                .atlasTextRole(.metricLabel)
                .foregroundStyle(AtlasPalette.textSecondary)
                .lineLimit(1)

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold, design: .default))
                .foregroundStyle(AtlasPalette.textTertiary)
        }
        .padding(.horizontal, atlasForwardMockupFidelityActive ? 8 : 9)
        .padding(.vertical, atlasForwardMockupFidelityActive ? 7 : 8)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.52), lineWidth: 1)
        )
    }
}

private struct AtlasForwardIconControlStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(AtlasPalette.textSecondary)
            .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AtlasPalette.border.opacity(configuration.isPressed ? 0.86 : 0.56), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

private struct AtlasForwardCompactInputModifier: ViewModifier {
    var label: String?

    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: label == nil ? 0 : (atlasForwardMockupFidelityActive ? 2 : 3)) {
            if let label {
                Text(label)
                    .atlasTextRole(.metricLabel)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
            content
                .font(.system(size: atlasForwardMockupFidelityActive ? 12.5 : 13, weight: .semibold, design: .default))
                .foregroundStyle(AtlasPalette.textPrimary)
                .tint(AtlasPalette.primary)
                .submitLabel(.done)
                .onSubmit {
                    AtlasKeyboardControl.dismiss()
                }
                .padding(.horizontal, atlasForwardMockupFidelityActive ? 8 : 9)
                .padding(.vertical, atlasForwardMockupFidelityActive ? 5 : 6)
                .frame(minHeight: atlasForwardMockupFidelityActive ? 32 : 34, alignment: .center)
                .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AtlasPalette.border.opacity(0.62), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    func atlasForwardCompactInput(label: String? = nil) -> some View {
        modifier(AtlasForwardCompactInputModifier(label: label))
    }
}

private struct AtlasForwardLoadingCard: View {
    let title: String
    let detail: String

    var body: some View {
        AtlasForwardCard(padding: atlasForwardMockupFidelityActive ? 8 : 10) {
            HStack(spacing: atlasForwardMockupFidelityActive ? 8 : 10) {
                ProgressView()
                    .tint(AtlasPalette.primary)
                VStack(alignment: .leading, spacing: atlasForwardMockupFidelityActive ? 3 : 4) {
                    Text(title)
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(detail)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
        }
    }
}

private struct AtlasForwardInventoryVialRow: View {
    let vial: AtlasVialSummary
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(alignment: .leading, spacing: atlasForwardMockupFidelityActive ? 7 : 8) {
                HStack(spacing: atlasForwardMockupFidelityActive ? 8 : 9) {
                    Image(systemName: "testtube.2")
                        .foregroundStyle(vial.isLowStock ? AtlasPalette.warning : AtlasPalette.primary)
                        .frame(width: atlasForwardMockupFidelityActive ? 30 : 32, height: atlasForwardMockupFidelityActive ? 30 : 32)
                        .background((vial.isLowStock ? AtlasPalette.warning : AtlasPalette.primary).opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: atlasForwardMockupFidelityActive ? 2 : 3) {
                        Text(vial.label)
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Text(vial.linkedProtocolCanonicalTitle ?? vial.calculatorProfileLabel ?? "Supply")
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: atlasForwardMockupFidelityActive ? 2 : 3) {
                        Text(vial.quantityLabel)
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(vial.projectedDepletionLabel ?? "Runway")
                            .atlasTextRole(.metricLabel)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                }
                AtlasForwardThinProgress(value: vial.startingQuantity == 0 ? 0 : vial.remainingQuantity / max(vial.startingQuantity, 0.0001), tint: vial.isLowStock ? AtlasPalette.warning : AtlasPalette.primary)
            }
            .padding(atlasForwardMockupFidelityActive ? 8 : 9)
            .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct AtlasForwardSimpleRow: View {
    let systemImage: String
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        HStack(spacing: atlasForwardMockupFidelityActive ? 8 : 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: atlasForwardMockupFidelityActive ? 30 : 32, height: atlasForwardMockupFidelityActive ? 30 : 32)
                .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: atlasForwardMockupFidelityActive ? 2 : 3) {
                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(detail.isEmpty ? "No detail yet" : detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(atlasForwardMockupFidelityActive ? 8 : 9)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AtlasForwardReviewListCard: View {
    let title: String
    let items: [(String, String, String, Color)]

    var body: some View {
        AtlasForwardCard(padding: atlasForwardMockupFidelityActive ? 8 : 10) {
            VStack(alignment: .leading, spacing: atlasForwardMockupFidelityActive ? 8 : 10) {
                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                if items.isEmpty {
                    Text("No items yet.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        AtlasForwardSimpleRow(systemImage: item.0, title: item.1, detail: item.2, tint: item.3)
                    }
                }
            }
        }
    }
}

private struct AtlasForwardProtocolDraftState {
    var name = "Tirzepatide"
    var kind: AtlasProtocolKind = .peptide
    var route: AtlasProtocolAdministrationRoute = .injection
    var supplyType: AtlasProtocolSupplyType = .vial
    var cadenceType: AtlasProtocolRuleType = .weekly
    var intervalDays = "7"
    var weekday = 2
    var defaultTimeOfDay = "12:30 PM"
    var doseAmount = "5.0"
    var doseUnit = "mg"
    var dosesPerSupply = "12"
    var notes = ""

    init() {}

    init(_ draft: AtlasProtocolDraft) {
        name = draft.name
        kind = draft.kind
        route = draft.administrationRoute
        supplyType = draft.supplyType ?? .vial
        cadenceType = draft.cadenceType
        intervalDays = "\(draft.intervalDays)"
        weekday = draft.weekday ?? 2
        defaultTimeOfDay = draft.defaultTimeOfDay ?? "12:30 PM"
        doseAmount = draft.doseAmount.map { $0.formatted(.number.precision(.fractionLength(0...2))) } ?? ""
        doseUnit = draft.doseUnit ?? "mg"
        dosesPerSupply = draft.dosesPerSupply.map(String.init) ?? ""
        notes = draft.notes ?? ""
    }

    var domainDraft: AtlasProtocolDraft {
        AtlasProtocolDraft(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            kind: kind,
            administrationRoute: route,
            supplyType: supplyType,
            dosesPerSupply: Int(dosesPerSupply),
            cadenceType: cadenceType,
            intervalDays: max(Int(intervalDays) ?? (cadenceType == .weekly ? 7 : 1), 1),
            weekday: cadenceType == .weekly ? weekday : nil,
            defaultTimeOfDay: defaultTimeOfDay.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : defaultTimeOfDay,
            doseAmount: Double(doseAmount),
            doseUnit: doseUnit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : doseUnit,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        )
    }
}

private struct AtlasForwardVialDraftState {
    var label = "Tirzepatide vial"
    var remaining = "12"
    var unit = "dose"
    var lowThreshold = "3"

    func domainDraft(protocolID: String?) -> AtlasVialDraft {
        let remainingValue = max(Double(remaining) ?? 1, 0)
        return AtlasVialDraft(
            label: label.trimmingCharacters(in: .whitespacesAndNewlines),
            protocolID: protocolID,
            startingQuantity: remainingValue,
            remainingQuantity: remainingValue,
            quantityUnit: unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "dose" : unit,
            lowStockThreshold: Double(lowThreshold)
        )
    }
}

private struct AtlasForwardCalculatorDraftState {
    var label = "Tirzepatide 10 mg"
    var powderAmount = "10"
    var powderUnit = "mg"
    var diluentVolume = "2"
    var diluentUnit = "mL"
    var drawVolume = "0.5"
    var drawUnit = "mL"

    init() {}

    init(_ profile: AtlasCalculatorProfileRecord) {
        label = profile.label
        powderAmount = profile.powderAmount.formatted(.number.precision(.fractionLength(0...2)))
        powderUnit = profile.powderUnit
        diluentVolume = profile.diluentVolume.formatted(.number.precision(.fractionLength(0...2)))
        diluentUnit = profile.diluentUnit
        drawVolume = profile.drawVolume.formatted(.number.precision(.fractionLength(0...2)))
        drawUnit = profile.drawUnit
    }

    var domainDraft: AtlasCalculatorProfileDraft {
        AtlasCalculatorProfileDraft(
            label: label.trimmingCharacters(in: .whitespacesAndNewlines),
            powderAmount: Double(powderAmount) ?? 0,
            powderUnit: powderUnit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "mg" : powderUnit,
            diluentVolume: Double(diluentVolume) ?? 0,
            diluentUnit: diluentUnit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "mL" : diluentUnit,
            drawVolume: Double(drawVolume) ?? 0,
            drawUnit: drawUnit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "mL" : drawUnit
        )
    }
}

private struct AtlasForwardMeasurementDraftState {
    var kind: AtlasProgressMeasurementKind = .waist
    var value = ""
    var unit = AtlasProgressMeasurementKind.waist.defaultUnit
    var note = ""
}

private func cleanTitle(_ title: String) -> String {
    var rendered = title
    for suffix in [" Weekly", " Daily", " Monthly", " Protocol"] where rendered.hasSuffix(suffix) {
        rendered.removeLast(suffix.count)
        break
    }
    return rendered
}

private func statusLabel(_ status: AtlasProtocolStatus) -> String {
    switch status {
    case .active: return "Active"
    case .draft: return "Draft"
    case .paused: return "Paused"
    case .archived: return "Archived"
    }
}

private func routeIcon(for route: AtlasProtocolAdministrationRoute) -> String {
    switch route {
    case .injection: return "syringe.fill"
    case .oral, .sublingual: return "pills.fill"
    case .nasal: return "nose.fill"
    case .topical, .transdermal: return "hand.raised.fill"
    case .other: return "list.clipboard.fill"
    }
}

private func supplyIcon(for supply: AtlasProtocolSupplyType?) -> String {
    switch supply {
    case .pen: return "pencil.tip"
    case .bottle, .blisterPack: return "pills.fill"
    case .syringe: return "syringe.fill"
    case .vial, .none: return "testtube.2"
    case .other: return "shippingbox.fill"
    }
}

private extension AtlasProtocolKind {
    var forwardDisplayLabel: String {
        switch self {
        case .glp: return "GLP"
        case .peptide: return "Peptide"
        case .custom: return "Custom"
        }
    }
}

private extension AtlasProtocolRuleType {
    var forwardDisplayLabel: String {
        switch self {
        case .weekly: return "Weekly"
        case .daily: return "Daily"
        case .everyNDays: return "Every n days"
        }
    }
}

private extension AtlasProtocolAdministrationRoute {
    var forwardDisplayLabel: String {
        switch self {
        case .injection:
            return "SubQ"
        case .oral:
            return "Oral"
        case .sublingual:
            return "Sublingual"
        case .nasal:
            return "Nasal"
        case .topical:
            return "Topical"
        case .transdermal:
            return "Patch"
        case .other:
            return "Other"
        }
    }
}

private extension AtlasProtocolSupplyType {
    var forwardDisplayLabel: String {
        switch self {
        case .vial:
            return "Vial"
        case .pen:
            return "Pen"
        case .bottle:
            return "Bottle"
        case .blisterPack:
            return "Blister"
        case .syringe:
            return "Syringe"
        case .other:
            return "Supply"
        }
    }
}

private struct AtlasForwardSiteButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .atlasTextRole(.deckEyebrow)
            .foregroundStyle(isSelected ? .white : AtlasPalette.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .allowsTightening(true)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(isSelected ? AtlasPalette.primary : AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

private struct AtlasForwardChipButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .atlasTextRole(.deckEyebrow)
            .foregroundStyle(isSelected ? .white : AtlasPalette.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.58)
            .allowsTightening(true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, atlasForwardMockupFidelityActive ? 6 : 7)
            .padding(.vertical, atlasForwardMockupFidelityActive ? 3.5 : 4)
            .background(isSelected ? AtlasPalette.primary : AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.clear : AtlasPalette.border.opacity(0.52), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}
