import AtlasDesignSystem
import AtlasDomain
import AtlasPersistence
import Foundation
import SwiftUI
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(UIKit)
import UIKit
#endif

public struct AtlasInventoryScreen: View {
    let model: AtlasAppModel
    @State private var selectedVialID: String?
    @State private var selectedConsumableID: String?
    @State private var selectedVialIDs: Set<String> = []
    @State private var selectedConsumableIDs: Set<String> = []
    @State private var editingVialDraft: AtlasVialEditorState?
    @State private var editingConsumableDraft: AtlasConsumableEditorState?
    @State private var editingSiteDraft: AtlasSiteEditorState?
    @State private var editingProtocolSettings: AtlasProtocolInventorySetting?

    public var body: some View {
        AtlasScreen {
            AtlasCommandDeck(
                eyebrow: "STOCK ROOM",
                title: inventoryDeckTitle,
                detail: inventoryDeckDetail,
                metrics: inventoryMetrics,
                style: .hero
            ) {
                VStack(spacing: AtlasSpacing.small) {
                    Button(inventoryPrimaryActionTitle, action: performPrimaryInventoryAction)
                        .buttonStyle(AtlasPrimaryButtonStyle())

                    HStack(spacing: AtlasSpacing.small) {
                        Button("Add vial", action: createVial)
                            .buttonStyle(AtlasSecondaryButtonStyle())
                        Button("Add supply", action: createConsumable)
                            .buttonStyle(AtlasSecondaryButtonStyle())
                    }

                    Button("Add site", action: createSite)
                        .buttonStyle(AtlasTertiaryButtonStyle())
                }
            } footer: {
                AtlasCalloutRow(
                    systemImage: model.inventorySnapshot.procurementReviewCount > 0 ? "shippingbox.fill" : "function",
                    title: model.inventorySnapshot.procurementReviewCount > 0 ? "Procurement review ready" : "Calculator",
                    detail: model.inventorySnapshot.procurementReviewCount > 0
                        ? "\(model.inventorySnapshot.procurementReviewCount) supply plan(s) are ready for procurement review."
                        : "Open the calculator for dilution or protocol math.",
                    tint: model.inventorySnapshot.procurementReviewCount > 0 ? AtlasPalette.warning : AtlasPalette.primary,
                    badge: model.inventorySnapshot.procurementReviewCount > 0 ? "Act" : "Tool"
                )
            }

            AtlasSectionCard(style: .utility, title: "Quick actions") {
                HStack(spacing: AtlasSpacing.small) {
                    AtlasInventoryActionTile(
                        title: "Calculator",
                        systemImage: "function",
                        tint: AtlasPalette.primary,
                        action: openCalculator
                    )
                    AtlasInventoryActionTile(
                        title: "Vials",
                        systemImage: "drop.fill",
                        tint: model.inventorySnapshot.lowStockCount > 0 ? AtlasPalette.warning : AtlasPalette.primary,
                        action: createVial
                    )
                    AtlasInventoryActionTile(
                        title: "Supplies",
                        systemImage: "shippingbox.fill",
                        tint: model.inventorySnapshot.procurementReviewCount > 0 ? AtlasPalette.warning : AtlasPalette.secondaryText,
                        action: createConsumable
                    )
                }
            }

            if let error = model.loadErrorMessage {
                AtlasSectionCard(style: .utility, title: "Attention") {
                    Text(error)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(.red)
                }
            }

            AtlasInventorySectionGroup(title: "Protocol links") {
                if model.inventorySnapshot.protocolSettings.isEmpty {
                    AtlasSectionCard(style: .task) {
                        AtlasCalloutRow(
                            systemImage: "square.stack.3d.up.slash",
                            title: "No active protocol links yet",
                            detail: "Create or import a protocol first to link depletion, site rotation, and vial assignment.",
                            tint: AtlasPalette.secondaryText
                        )
                    }
                } else {
                    ForEach(model.inventorySnapshot.protocolSettings) { item in
                        AtlasInventoryProtocolCard(model: model, item: item) {
                            editingProtocolSettings = item
                        }
                    }
                }
            }

            if selectedVialIDs.isEmpty == false {
                AtlasSectionCard(style: .utility, title: "Batch vial actions") {
                    AtlasMetricStrip(metrics: [
                        AtlasMetricItem(id: "selected_vials", title: "Selected", value: "\(selectedVialIDs.count)"),
                        AtlasMetricItem(id: "low_stock_vials", title: "Low stock", value: "\(model.inventorySnapshot.lowStockCount)", tint: AtlasPalette.warning)
                    ])

                    HStack(spacing: AtlasSpacing.small) {
                        Button("Archive selected") {
                            AtlasFeedback.impact(.medium)
                            Task {
                                for id in selectedVialIDs {
                                    await model.archiveVial(id: id)
                                }
                                selectedVialIDs.removeAll()
                            }
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())

                        Button("Clear selection") {
                            AtlasFeedback.selection()
                            selectedVialIDs.removeAll()
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                }
            }

            AtlasInventorySectionGroup(title: "Vials") {
                if model.inventorySnapshot.vials.isEmpty {
                    AtlasSectionCard(style: .task) {
                        AtlasCalloutRow(
                            systemImage: "drop.degreesign",
                            title: "No vials saved yet",
                            detail: "Add a vial to track quantity, depletion pace, linked protocols, and label context in one place.",
                            tint: AtlasPalette.primary
                        )
                    }
                } else {
                    ForEach(model.inventorySnapshot.vials) { vial in
                        AtlasVialSummaryCard(
                            model: model,
                            vial: vial,
                            onOpen: { selectedVialID = vial.id },
                            onEdit: {
                                Task {
                                    if let detail = await model.vialDetail(id: vial.id) {
                                        editingVialDraft = AtlasVialEditorState(draft: detail.editableDraft)
                                    }
                                }
                            },
                            onArchive: vial.archivedAt == nil ? {
                                Task { await model.archiveVial(id: vial.id) }
                            } : nil,
                            isSelected: selectedVialIDs.contains(vial.id),
                            onToggleSelection: {
                                atlasToggleSelection(id: vial.id, selected: &selectedVialIDs)
                            }
                        )
                    }
                }
            }

            if selectedConsumableIDs.isEmpty == false {
                AtlasSectionCard(style: .utility, title: "Batch supply actions") {
                    AtlasMetricStrip(metrics: [
                        AtlasMetricItem(id: "selected_supplies", title: "Selected", value: "\(selectedConsumableIDs.count)"),
                        AtlasMetricItem(id: "procurement_review", title: "Review", value: "\(model.inventorySnapshot.procurementReviewCount)", tint: AtlasPalette.warning)
                    ])

                    HStack(spacing: AtlasSpacing.small) {
                        Button("Archive selected") {
                            AtlasFeedback.impact(.medium)
                            Task {
                                for id in selectedConsumableIDs {
                                    await model.setConsumableArchived(id: id, isArchived: true)
                                }
                                selectedConsumableIDs.removeAll()
                            }
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())

                        Button("Restore selected") {
                            AtlasFeedback.selection()
                            Task {
                                for id in selectedConsumableIDs {
                                    await model.setConsumableArchived(id: id, isArchived: false)
                                }
                                selectedConsumableIDs.removeAll()
                            }
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                }
            }

            AtlasInventorySectionGroup(title: "Supplies") {
                if model.inventorySnapshot.consumables.isEmpty {
                    AtlasSectionCard(style: .task) {
                        AtlasCalloutRow(
                            systemImage: "shippingbox",
                            title: "No supplies saved yet",
                            detail: "Track syringes, alcohol pads, storage, and protocol-specific consumables before they become the blocker.",
                            tint: AtlasPalette.secondaryText
                        )
                    }
                } else {
                    ForEach(model.inventorySnapshot.consumables) { consumable in
                        AtlasConsumableSummaryCard(
                            model: model,
                            consumable: consumable,
                            onOpen: { selectedConsumableID = consumable.id },
                            onEdit: {
                                Task {
                                    if let detail = await model.consumableDetail(id: consumable.id) {
                                        editingConsumableDraft = AtlasConsumableEditorState(draft: detail.editableDraft)
                                    }
                                }
                            },
                            onArchiveToggle: {
                                Task {
                                    await model.setConsumableArchived(id: consumable.id, isArchived: consumable.archivedAt == nil)
                                }
                            },
                            isSelected: selectedConsumableIDs.contains(consumable.id),
                            onToggleSelection: {
                                atlasToggleSelection(id: consumable.id, selected: &selectedConsumableIDs)
                            }
                        )
                    }
                }
            }

            AtlasInventorySectionGroup(title: "Sites") {
                if model.inventorySnapshot.sites.isEmpty {
                    AtlasSectionCard(style: .task) {
                        AtlasCalloutRow(
                            systemImage: "figure.arms.open",
                            title: "No injection sites saved yet",
                            detail: "Add sites once for rotation tracking.",
                            tint: AtlasPalette.primary
                        )
                    }
                } else {
                    ForEach(model.inventorySnapshot.sites) { site in
                        AtlasSiteSummaryCard(site: site) {
                            editingSiteDraft = AtlasSiteEditorState(
                                draft: AtlasSiteDraft(
                                    id: site.id,
                                    name: site.name,
                                    bodyArea: site.bodyArea,
                                    mapRegionKey: site.mapRegionKey,
                                    notes: site.notes,
                                    archivedAt: site.archivedAt
                                )
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Inventory")
        .atlasInlineNavigationTitle()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: createSite) {
                    Image(systemName: "mappin.and.ellipse")
                }

                Button(action: createConsumable) {
                    Image(systemName: "shippingbox")
                }

                Button(action: createVial) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: Binding(
            get: { selectedVialID.map(AtlasIdentifiedString.init) },
            set: { selectedVialID = $0?.value }
        )) { item in
            AtlasVialDetailScreen(
                model: model,
                vialID: item.value,
                onEdit: { draft in editingVialDraft = AtlasVialEditorState(draft: draft) }
            )
        }
        .sheet(item: Binding(
            get: { selectedConsumableID.map(AtlasIdentifiedString.init) },
            set: { selectedConsumableID = $0?.value }
        )) { item in
            AtlasConsumableDetailScreen(
                model: model,
                consumableID: item.value,
                onEdit: { draft in editingConsumableDraft = AtlasConsumableEditorState(draft: draft) }
            )
        }
        .sheet(item: $editingVialDraft) { item in
            AtlasVialEditorSheet(model: model, draft: item.draft)
        }
        .sheet(item: $editingConsumableDraft) { item in
            AtlasConsumableEditorSheet(model: model, draft: item.draft)
        }
        .sheet(item: $editingSiteDraft) { item in
            AtlasSiteEditorSheet(model: model, draft: item.draft)
        }
        .sheet(item: $editingProtocolSettings) { item in
            AtlasProtocolInventorySettingsSheet(model: model, item: item)
        }
        #if DEBUG
        .task(id: model.inventorySnapshot.consumables.map(\.id)) {
            guard selectedConsumableID == nil,
                  let qaConsumableID = atlasQAConsumableAutoOpenID(),
                  model.inventorySnapshot.consumables.contains(where: { $0.id == qaConsumableID }) else {
                return
            }
            selectedConsumableID = qaConsumableID
        }
        #endif
    }

    private var inventoryMetrics: [AtlasMetricItem] {
        [
            AtlasMetricItem(
                id: "low_stock",
                title: "Low stock",
                value: "\(model.inventorySnapshot.lowStockCount)",
                tint: model.inventorySnapshot.lowStockCount > 0 ? AtlasPalette.warning : AtlasPalette.primary
            ),
            AtlasMetricItem(
                id: "vials",
                title: "Vials",
                value: "\(model.inventorySnapshot.vials.count)"
            ),
            AtlasMetricItem(
                id: "supplies",
                title: "Supplies",
                value: "\(model.inventorySnapshot.consumables.count)",
                tint: model.inventorySnapshot.procurementReviewCount > 0 ? AtlasPalette.warning : AtlasPalette.secondaryText
            ),
            AtlasMetricItem(
                id: "sites",
                title: "Sites",
                value: "\(model.inventorySnapshot.sites.count)",
                tint: AtlasPalette.secondaryText
            )
        ]
    }

    private var inventoryDeckTitle: String {
        if model.inventorySnapshot.lowStockCount > 0 {
            return "Inventory needs a quick sweep."
        }
        if model.inventorySnapshot.vials.isEmpty && model.inventorySnapshot.consumables.isEmpty {
            return "Build the inventory layer once."
        }
        return "Keep protocol operations visible."
    }

    private var inventoryDeckDetail: String {
        if model.inventorySnapshot.lowStockCount > 0 {
            return "\(model.inventorySnapshot.lowStockCount) item(s) are below threshold."
        }
        if model.inventorySnapshot.vials.isEmpty && model.inventorySnapshot.consumables.isEmpty {
            return "Track vials, supplies, and sites here."
        }
        return "Track vials, supplies, site rotation, and protocol links here."
    }

    private var inventoryPrimaryActionTitle: String {
        if model.inventorySnapshot.lowStockCount > 0 {
            return "Open calculator"
        }
        if model.inventorySnapshot.vials.isEmpty {
            return "Create first vial"
        }
        return "Review protocol links"
    }

    private func performPrimaryInventoryAction() {
        AtlasFeedback.selection()
        if model.inventorySnapshot.lowStockCount > 0 {
            openCalculator()
        } else if model.inventorySnapshot.vials.isEmpty {
            createVial()
        } else if let first = model.inventorySnapshot.protocolSettings.first {
            editingProtocolSettings = first
        } else {
            createVial()
        }
    }

    private func openCalculator() {
        AtlasFeedback.selection()
        model.open(.calculator)
    }

    private func createVial() {
        AtlasFeedback.selection()
        editingVialDraft = AtlasVialEditorState(draft: AtlasVialDraft())
    }

    private func createConsumable() {
        AtlasFeedback.selection()
        editingConsumableDraft = AtlasConsumableEditorState(draft: AtlasConsumableDraft())
    }

    private func createSite() {
        AtlasFeedback.selection()
        editingSiteDraft = AtlasSiteEditorState(draft: AtlasSiteDraft())
    }
}

private struct AtlasInventoryActionTile: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: AtlasSpacing.small) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AtlasPalette.surfaceTop, tint.opacity(0.14)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: systemImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(tint)
                    )

                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .allowsTightening(true)
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .top)
            .padding(AtlasSpacing.medium)
        }
        .buttonStyle(AtlasTactileTileButtonStyle(tint: tint))
    }
}

private struct AtlasInventorySectionGroup<Content: View>: View {
    let title: String
    private let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
            Text(title)
                .atlasTextRole(.deckEyebrow)
                .foregroundStyle(AtlasPalette.primary)

            content
        }
    }
}

private struct AtlasInventoryProtocolCard: View {
    let model: AtlasAppModel
    let item: AtlasProtocolInventorySetting
    let onOpen: () -> Void

    var body: some View {
        AtlasSectionCard(style: .task) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                Text(model.renderedTitle(canonical: item.canonicalTitle, alias: item.aliasTitle))
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text("\(item.kindLabel) • \(item.cadenceLabel)")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text(item.linkedVialLabel.map { "Active vial: \($0)" } ?? "No active vial linked")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text(item.siteTrackingEnabled ? (item.siteRotationEnabled ? "Site tracking with rotation" : "Site tracking enabled") : "Site tracking off")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Button("Edit link settings") {
                    AtlasFeedback.selection()
                    onOpen()
                }
                    .buttonStyle(AtlasSecondaryButtonStyle())
            }
        }
    }
}

private struct AtlasVialSummaryCard: View {
    let model: AtlasAppModel
    let vial: AtlasVialSummary
    let onOpen: () -> Void
    let onEdit: () -> Void
    let onArchive: (() -> Void)?
    let isSelected: Bool
    let onToggleSelection: () -> Void

    var body: some View {
        AtlasSectionCard(style: .task) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack {
                    Text(vial.label)
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Spacer()
                    if vial.isLowStock {
                        AtlasStatusBadge("Low stock", tint: .orange)
                    } else if vial.archivedAt != nil {
                        AtlasStatusBadge("Archived", tint: AtlasPalette.textSecondary)
                    }
                }
                Text(vial.quantityLabel)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                if let referencePhotoPath = vial.referencePhotoPath {
                    AtlasInventoryReferencePhoto(path: referencePhotoPath)
                        .frame(height: 132)
                }
                if let protocolTitle = vial.linkedProtocolCanonicalTitle {
                    Text("Linked to \(model.renderedTitle(canonical: protocolTitle, alias: vial.linkedProtocolAliasTitle))")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                if let projectedDepletionLabel = vial.projectedDepletionLabel {
                    Text(projectedDepletionLabel)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                if let lowStockLabel = vial.lowStockLabel {
                    Text(lowStockLabel)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(vial.isLowStock ? .orange : AtlasPalette.textSecondary)
                }
                if let autoDecrementLabel = vial.autoDecrementLabel {
                    Text(autoDecrementLabel)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                if let labelScanPreview = vial.labelScanPreview {
                    Text(labelScanPreview)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .lineLimit(3)
                }
                HStack(spacing: AtlasSpacing.small) {
                    Button("Open") {
                        AtlasFeedback.selection()
                        onOpen()
                    }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    Button("Edit") {
                        AtlasFeedback.selection()
                        onEdit()
                    }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                }
                if let onArchive {
                    Button("Archive") {
                        AtlasFeedback.selection()
                        onArchive()
                    }
                        .buttonStyle(AtlasChipButtonStyle(tint: .orange))
                }
                Button(isSelected ? "Selected for batch actions" : "Select for batch actions", action: onToggleSelection)
                    .buttonStyle(
                        AtlasChipButtonStyle(
                            tint: isSelected ? AtlasPalette.primary : AtlasPalette.textSecondary
                        )
                    )
            }
        }
    }
}

private struct AtlasConsumableSummaryCard: View {
    let model: AtlasAppModel
    let consumable: AtlasConsumableSummary
    let onOpen: () -> Void
    let onEdit: () -> Void
    let onArchiveToggle: () -> Void
    let isSelected: Bool
    let onToggleSelection: () -> Void

    var body: some View {
        AtlasSectionCard(style: .utility) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack {
                    Text(model.renderedConsumableTitle(canonical: consumable.name, category: consumable.category))
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Spacer()
                    if consumable.isLowStock {
                        AtlasStatusBadge("Low stock", tint: .orange)
                    } else if consumable.archivedAt != nil {
                        AtlasStatusBadge("Archived", tint: AtlasPalette.textSecondary)
                    }
                }
                if let category = consumable.category {
                    Text(category)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Text(consumable.quantityLabel)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                if let protocolTitle = consumable.linkedProtocolCanonicalTitle {
                    Text("Linked to \(model.renderedTitle(canonical: protocolTitle, alias: consumable.linkedProtocolAliasTitle))")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                if let usageLabel = consumable.usageLabel {
                    Text(usageLabel)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                if let projectedDepletionLabel = consumable.projectedDepletionLabel {
                    Text(projectedDepletionLabel)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                if let procurementStatusLabel = consumable.procurementStatusLabel {
                    Text(procurementStatusLabel)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(consumable.needsProcurementReview ? .orange : AtlasPalette.textSecondary)
                }
                if let lastProcurementLabel = consumable.lastProcurementLabel {
                    Text(lastProcurementLabel)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                if model.settingsSnapshot.trustVaultStatus.renderMode == .full,
                   let vendorLabel = consumable.vendorLabel {
                    Text("Vendor: \(vendorLabel)")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                HStack(spacing: AtlasSpacing.small) {
                    Button("Open") {
                        AtlasFeedback.selection()
                        onOpen()
                    }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    Button("Edit") {
                        AtlasFeedback.selection()
                        onEdit()
                    }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                }
                Button(consumable.archivedAt == nil ? "Archive" : "Unarchive") {
                    AtlasFeedback.selection()
                    onArchiveToggle()
                }
                    .buttonStyle(
                        AtlasChipButtonStyle(
                            tint: consumable.archivedAt == nil ? .orange : AtlasPalette.success
                        )
                    )
                Button(isSelected ? "Selected for batch actions" : "Select for batch actions", action: onToggleSelection)
                    .buttonStyle(
                        AtlasChipButtonStyle(
                            tint: isSelected ? AtlasPalette.primary : AtlasPalette.textSecondary
                        )
                    )
            }
        }
    }
}

private func atlasToggleSelection(id: String, selected: inout Set<String>) {
    AtlasFeedback.selection()
    if selected.contains(id) {
        selected.remove(id)
    } else {
        selected.insert(id)
    }
}

private struct AtlasSiteSummaryCard: View {
    let site: AtlasSiteSummary
    let onOpen: () -> Void

    var body: some View {
        AtlasSectionCard(style: .utility) {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                Text(site.name)
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text([
                    site.mapRegionKey?.title,
                    site.bodyArea,
                    site.notes
                ].compactMap { $0 }.joined(separator: " • "))
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Button("Edit site") {
                    AtlasFeedback.selection()
                    onOpen()
                }
                    .buttonStyle(AtlasSecondaryButtonStyle())
            }
        }
    }
}

private struct AtlasBodyMapPicker: View {
    @Binding var selection: AtlasBodyMapRegionKey?
    let highlightedRegions: Set<AtlasBodyMapRegionKey>
    @State private var surface: AtlasBodyMapSurface

    init(
        selection: Binding<AtlasBodyMapRegionKey?>,
        highlightedRegions: Set<AtlasBodyMapRegionKey> = []
    ) {
        _selection = selection
        self.highlightedRegions = highlightedRegions
        _surface = State(initialValue: selection.wrappedValue?.surface ?? .front)
    }

    private var visibleRegions: [AtlasBodyMapRegionKey] {
        AtlasBodyMapRegionKey.allCases.filter { $0.surface == surface }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            Picker("Surface", selection: $surface) {
                ForEach(AtlasBodyMapSurface.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)

            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height

                ZStack {
                    AtlasBodyMapSilhouette(surface: surface)
                        .fill(AtlasPalette.surfaceSecondary)
                        .overlay {
                            AtlasBodyMapSilhouette(surface: surface)
                                .stroke(AtlasPalette.border, lineWidth: 1)
                        }

                    ForEach(visibleRegions) { region in
                        Button {
                            AtlasFeedback.selection()
                            selection = region
                        } label: {
                            VStack(spacing: 2) {
                                Circle()
                                    .fill(selection == region ? AtlasPalette.primary : (highlightedRegions.contains(region) ? AtlasPalette.success : AtlasPalette.secondaryText))
                                    .frame(
                                        width: max(width * region.markerDiameter, 30),
                                        height: max(width * region.markerDiameter, 30)
                                    )
                                    .overlay {
                                        Circle()
                                            .stroke(Color.white.opacity(0.8), lineWidth: selection == region ? 2 : 1)
                                    }
                                Text(region.shortLabel)
                                    .atlasTextRole(.metricLabel)
                                    .foregroundStyle(AtlasPalette.textPrimary)
                            }
                        }
                        .buttonStyle(.plain)
                        .position(x: width * region.normalizedX, y: height * region.normalizedY)
                    }
                }
            }
            .frame(height: 320)
            .padding(.vertical, AtlasSpacing.xSmall)

            Text("Tap a hotspot to attach this saved site to a reusable body-map location.")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
        .onChange(of: selection) { _, newValue in
            guard let newValue else {
                return
            }
            surface = newValue.surface
        }
    }
}

private struct AtlasBodyMapSilhouette: Shape {
    let surface: AtlasBodyMapSurface

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let head = CGRect(
            x: rect.midX - rect.width * 0.09,
            y: rect.minY + rect.height * 0.03,
            width: rect.width * 0.18,
            height: rect.width * 0.18
        )
        path.addEllipse(in: head)

        let torso = CGRect(
            x: rect.midX - rect.width * 0.16,
            y: rect.minY + rect.height * 0.21,
            width: rect.width * 0.32,
            height: rect.height * 0.34
        )
        path.addRoundedRect(in: torso, cornerSize: CGSize(width: rect.width * 0.07, height: rect.width * 0.07))

        let leftArm = CGRect(
            x: rect.midX - rect.width * 0.33,
            y: rect.minY + rect.height * 0.23,
            width: rect.width * 0.12,
            height: rect.height * 0.30
        )
        let rightArm = CGRect(
            x: rect.midX + rect.width * 0.21,
            y: rect.minY + rect.height * 0.23,
            width: rect.width * 0.12,
            height: rect.height * 0.30
        )
        path.addRoundedRect(in: leftArm, cornerSize: CGSize(width: rect.width * 0.06, height: rect.width * 0.06))
        path.addRoundedRect(in: rightArm, cornerSize: CGSize(width: rect.width * 0.06, height: rect.width * 0.06))

        let hips = CGRect(
            x: rect.midX - rect.width * 0.18,
            y: rect.minY + rect.height * 0.50,
            width: rect.width * 0.36,
            height: rect.height * 0.11
        )
        path.addRoundedRect(in: hips, cornerSize: CGSize(width: rect.width * 0.08, height: rect.width * 0.08))

        let leftLeg = CGRect(
            x: rect.midX - rect.width * 0.16,
            y: rect.minY + rect.height * 0.58,
            width: rect.width * 0.12,
            height: rect.height * 0.29
        )
        let rightLeg = CGRect(
            x: rect.midX + rect.width * 0.04,
            y: rect.minY + rect.height * 0.58,
            width: rect.width * 0.12,
            height: rect.height * 0.29
        )
        path.addRoundedRect(in: leftLeg, cornerSize: CGSize(width: rect.width * 0.06, height: rect.width * 0.06))
        path.addRoundedRect(in: rightLeg, cornerSize: CGSize(width: rect.width * 0.06, height: rect.width * 0.06))

        if surface == .back {
            let spine = CGRect(
                x: rect.midX - rect.width * 0.015,
                y: rect.minY + rect.height * 0.25,
                width: rect.width * 0.03,
                height: rect.height * 0.28
            )
            path.addRoundedRect(in: spine, cornerSize: CGSize(width: rect.width * 0.015, height: rect.width * 0.015))
        }

        return path
    }
}

#if DEBUG
private func atlasQAConsumableAutoOpenID() -> String? {
    if let rawValue = ProcessInfo.processInfo.environment["ATLAS_QA_CONSUMABLE_ID"]?
        .trimmingCharacters(in: .whitespacesAndNewlines),
       rawValue.isEmpty == false {
        return rawValue
    }

    let arguments = ProcessInfo.processInfo.arguments
    guard let index = arguments.firstIndex(of: "--atlas-qa-consumable-id"),
          arguments.indices.contains(arguments.index(after: index)) else {
        return nil
    }

    let rawValue = arguments[arguments.index(after: index)].trimmingCharacters(in: .whitespacesAndNewlines)
    return rawValue.isEmpty ? nil : rawValue
}
#endif

public struct AtlasCalculatorScreen: View {
    let model: AtlasAppModel
    @State private var form = AtlasCalculatorFormState()

    public var body: some View {
        let result = atlasCalculateReconstitution(form.domainDraft)

        AtlasScreen {
            AtlasCommandDeck(
                eyebrow: "Neutral math",
                title: "Reconstitution calculator",
                detail: "Shows concentration and delivered amount, but never recommends what to take.",
                metrics: [
                    AtlasMetricItem(id: "profiles", title: "Saved", value: "\(model.calculatorProfiles.count)", tint: AtlasPalette.primary),
                    AtlasMetricItem(id: "concentration", title: "Concentration", value: result.concentrationLabel, tint: AtlasPalette.secondaryText),
                    AtlasMetricItem(id: "delivered", title: "Delivered", value: result.deliveredLabel, tint: AtlasPalette.success)
                ],
                tint: AtlasPalette.primary,
                style: .hero
            ) { } footer: { }

            AtlasSectionCard(style: .utility) {
                AtlasCalloutRow(
                    systemImage: "function",
                    title: "Neutral math only",
                    detail: "Shows powder, diluent, and draw-volume math. No dosing advice.",
                    tint: AtlasPalette.secondaryText
                )
            }

            AtlasSectionCard(title: "Profile") {
                TextField("Profile label", text: $form.label)
                    .atlasStandaloneInputSurface()
            }

            AtlasSectionCard(title: "Formula") {
                VStack(spacing: AtlasSpacing.small) {
                    HStack(spacing: AtlasSpacing.small) {
                        TextField("Powder amount", text: $form.powderAmount)
                            .atlasDecimalKeyboard()
                            .atlasStandaloneInputSurface()
                        TextField("Powder unit", text: $form.powderUnit)
                            .atlasStandaloneInputSurface()
                    }

                    HStack(spacing: AtlasSpacing.small) {
                        TextField("Diluent volume", text: $form.diluentVolume)
                            .atlasDecimalKeyboard()
                            .atlasStandaloneInputSurface()
                        TextField("Diluent unit", text: $form.diluentUnit)
                            .atlasStandaloneInputSurface()
                    }

                    HStack(spacing: AtlasSpacing.small) {
                        TextField("Draw volume", text: $form.drawVolume)
                            .atlasDecimalKeyboard()
                            .atlasStandaloneInputSurface()
                        TextField("Draw unit", text: $form.drawUnit)
                            .atlasStandaloneInputSurface()
                    }
                }

                Button("Save calculator profile") {
                    AtlasFeedback.selection()
                    Task { await model.saveCalculatorProfile(form.domainDraft) }
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
            }

            AtlasSectionCard(style: .task, title: "Result") {
                AtlasCalloutRow(
                    systemImage: "drop.degreesign",
                    title: result.concentrationLabel,
                    detail: result.deliveredLabel,
                    tint: AtlasPalette.primary
                )

                ForEach(result.explanation, id: \.self) { line in
                    Text(line)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }

            AtlasSectionCard(title: "Saved profiles") {
                if model.calculatorProfiles.isEmpty {
                    AtlasCalloutRow(
                        systemImage: "square.stack.3d.up.slash",
                        title: "No saved profiles yet",
                        detail: "Save one trusted baseline so the calculator becomes a fast reference tool instead of repeated manual entry.",
                        tint: AtlasPalette.secondaryText
                    )
                } else {
                    ForEach(model.calculatorProfiles) { profile in
                        let deliveredLabel = atlasCalculateReconstitution(
                            AtlasCalculatorProfileDraft(
                                id: profile.id,
                                label: profile.label,
                                powderAmount: profile.powderAmount,
                                powderUnit: profile.powderUnit,
                                diluentVolume: profile.diluentVolume,
                                diluentUnit: profile.diluentUnit,
                                drawVolume: profile.drawVolume,
                                drawUnit: profile.drawUnit
                            )
                        ).deliveredLabel

                        AtlasSectionCard(style: .task) {
                            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                                Text(profile.label)
                                    .atlasTextRole(.cardBody)
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Text(deliveredLabel)
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)

                                HStack(spacing: AtlasSpacing.small) {
                                    Button("Load") {
                                        AtlasFeedback.selection()
                                        form = AtlasCalculatorFormState(profile: profile)
                                    }
                                    .buttonStyle(AtlasSecondaryButtonStyle())

                                    Button("Delete") {
                                        AtlasFeedback.selection()
                                        Task { await model.deleteCalculatorProfile(id: profile.id) }
                                    }
                                    .buttonStyle(AtlasWarningButtonStyle())
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Calculator")
        .atlasInlineNavigationTitle()
    }
}

private struct AtlasVialDetailScreen: View {
    let model: AtlasAppModel
    let vialID: String
    let onEdit: (AtlasVialDraft) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var detail: AtlasVialDetailSnapshot?
    @State private var correctionQuantity: String = ""
    @State private var correctionNote: String = ""

    var body: some View {
        NavigationStack {
            AtlasScreen {
                if let loadedDetail = detail {
                    AtlasCommandDeck(
                        eyebrow: "Vial detail",
                        title: loadedDetail.summary.label,
                        detail: loadedDetail.summary.quantityLabel,
                        metrics: [
                            AtlasMetricItem(id: "remaining", title: "Remaining", value: loadedDetail.summary.remainingQuantity.cleanAtlasNumber, tint: AtlasPalette.primary),
                            AtlasMetricItem(id: "unit", title: "Unit", value: loadedDetail.summary.quantityUnit, tint: AtlasPalette.secondaryText),
                            AtlasMetricItem(id: "status", title: "Status", value: loadedDetail.summary.archivedAt == nil ? "Active" : "Archived", tint: loadedDetail.summary.archivedAt == nil ? AtlasPalette.success : AtlasPalette.secondaryText)
                        ],
                        tint: AtlasPalette.primary,
                        style: .hero
                    ) { } footer: { }

                    if let referencePhotoPath = loadedDetail.summary.referencePhotoPath {
                        AtlasSectionCard(style: .task, title: "Reference capture") {
                            AtlasInventoryReferencePhoto(path: referencePhotoPath)
                                .frame(height: 220)
                        }
                    }

                    AtlasSectionCard(title: "Specs") {
                        if let concentrationValue = loadedDetail.editableDraft.concentrationValue,
                           let concentrationUnit = loadedDetail.editableDraft.concentrationUnit {
                            AtlasCalloutRow(
                                systemImage: "drop.fill",
                                title: "Concentration",
                                detail: "\(concentrationValue.cleanAtlasNumber) \(concentrationUnit)/mL",
                                tint: AtlasPalette.primary
                            )
                        }
                        if let volumeML = loadedDetail.editableDraft.volumeML {
                            AtlasCalloutRow(
                                systemImage: "scalemass.fill",
                                title: "Diluent volume",
                                detail: "\(volumeML.cleanAtlasNumber) mL",
                                tint: AtlasPalette.secondaryText
                            )
                        }
                        if let openedAt = loadedDetail.editableDraft.openedAt {
                            AtlasCalloutRow(
                                systemImage: "calendar",
                                title: "Opened",
                                detail: openedAt.formatted(date: .abbreviated, time: .shortened),
                                tint: AtlasPalette.secondaryText
                            )
                        }
                        if let expiresAt = loadedDetail.editableDraft.expiresAt {
                            AtlasCalloutRow(
                                systemImage: "hourglass",
                                title: "Expires",
                                detail: expiresAt.formatted(date: .abbreviated, time: .shortened),
                                tint: expiresAt < model.currentDate() ? AtlasPalette.warning : AtlasPalette.secondaryText
                            )
                        }
                        if let linkedTitle = loadedDetail.summary.linkedProtocolCanonicalTitle {
                            AtlasCalloutRow(
                                systemImage: "square.stack.3d.up",
                                title: "Linked protocol",
                                detail: model.renderedTitle(canonical: linkedTitle, alias: loadedDetail.summary.linkedProtocolAliasTitle),
                                tint: AtlasPalette.primary
                            )
                        }
                        if let projectedDepletionLabel = loadedDetail.summary.projectedDepletionLabel {
                            AtlasCalloutRow(
                                systemImage: "chart.line.downtrend.xyaxis",
                                title: "Depletion pace",
                                detail: projectedDepletionLabel,
                                tint: AtlasPalette.secondaryText
                            )
                        }
                        if let labelScanText = loadedDetail.editableDraft.labelScanText {
                            Text(labelScanText)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }

                    AtlasSectionCard(style: .utility, title: "Correction") {
                        TextField("Next remaining quantity", text: $correctionQuantity)
                            .atlasDecimalKeyboard()
                            .atlasStandaloneInputSurface()
                        TextField("Correction note", text: $correctionNote)
                            .atlasStandaloneInputSurface()
                        Button("Apply correction") {
                            AtlasFeedback.selection()
                            Task {
                                guard let nextRemainingQuantity = Double(correctionQuantity) else {
                                    return
                                }
                                _ = await model.applyManualCorrection(
                                    AtlasInventoryCorrectionDraft(
                                        vialID: vialID,
                                        nextRemainingQuantity: nextRemainingQuantity,
                                        note: correctionNote.isEmpty ? nil : correctionNote
                                    )
                                )
                                detail = await model.vialDetail(id: vialID)
                            }
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                    }

                    AtlasSectionCard(title: "Inventory history") {
                        if loadedDetail.movementHistory.isEmpty {
                            AtlasCalloutRow(
                                systemImage: "clock.badge.xmark",
                                title: "No inventory movement yet",
                                detail: "Once depletion, corrections, or linked usage are recorded, the vial history appears here.",
                                tint: AtlasPalette.secondaryText
                            )
                        } else {
                            ForEach(loadedDetail.movementHistory) { item in
                                AtlasSectionCard(style: .task) {
                                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                        HStack(alignment: .firstTextBaseline) {
                                            Text(item.title)
                                                .atlasTextRole(.cardBody)
                                                .foregroundStyle(AtlasPalette.textPrimary)
                                            Spacer()
                                            if let deltaLabel = item.deltaLabel {
                                                AtlasStatusBadge(deltaLabel, tint: AtlasPalette.primary)
                                            }
                                        }
                                        Text(item.recordedAt.formatted(date: .abbreviated, time: .shortened))
                                            .atlasTextRole(.supporting)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                        Text(item.detail)
                                            .atlasTextRole(.supporting)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }
                                }
                            }
                        }
                    }

                    AtlasSectionCard(style: .utility, title: "Actions") {
                        HStack(spacing: AtlasSpacing.small) {
                            Button("Edit") {
                                AtlasFeedback.selection()
                                onEdit(loadedDetail.editableDraft)
                            }
                            .buttonStyle(AtlasSecondaryButtonStyle())

                            Button("Done") {
                                AtlasFeedback.selection()
                                dismiss()
                            }
                            .buttonStyle(AtlasPrimaryButtonStyle())
                        }
                    }
                } else {
                    AtlasSectionCard(style: .utility) {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Vial")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        AtlasFeedback.selection()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if let loadedDetail = detail {
                        Button("Edit") {
                            AtlasFeedback.selection()
                            onEdit(loadedDetail.editableDraft)
                        }
                    }
                }
            }
            .task {
                detail = await model.vialDetail(id: vialID)
                correctionQuantity = detail.map { $0.summary.remainingQuantity.cleanAtlasNumber } ?? ""
            }
        }
    }
}

private struct AtlasConsumableDetailScreen: View {
    let model: AtlasAppModel
    let consumableID: String
    let onEdit: (AtlasConsumableDraft) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var detail: AtlasConsumableDetailSnapshot?
    @State private var adjustmentQuantity: String = ""
    @State private var adjustmentNote: String = ""
    @State private var procurementState: AtlasConsumableProcurementState?

    var body: some View {
        NavigationStack {
            AtlasScreen {
                if let loadedDetail = detail {
                    AtlasCommandDeck(
                        eyebrow: "Supply detail",
                        title: model.renderedConsumableTitle(canonical: loadedDetail.summary.name, category: loadedDetail.summary.category),
                        detail: loadedDetail.summary.quantityLabel,
                        metrics: [
                            AtlasMetricItem(id: "stock", title: "On hand", value: loadedDetail.summary.quantityOnHand.cleanAtlasNumber, tint: AtlasPalette.primary),
                            AtlasMetricItem(id: "unit", title: "Unit", value: loadedDetail.summary.quantityUnit, tint: AtlasPalette.secondaryText),
                            AtlasMetricItem(id: "status", title: "Status", value: loadedDetail.summary.archivedAt == nil ? "Active" : "Archived", tint: loadedDetail.summary.archivedAt == nil ? AtlasPalette.success : AtlasPalette.secondaryText)
                        ],
                        tint: AtlasPalette.secondaryText,
                        style: .hero
                    ) { } footer: { }

                    AtlasSectionCard(title: "Planning") {
                        if let category = loadedDetail.summary.category {
                            AtlasCalloutRow(systemImage: "tag.fill", title: "Category", detail: category, tint: AtlasPalette.secondaryText)
                        }
                        if let linkedTitle = loadedDetail.summary.linkedProtocolCanonicalTitle {
                            AtlasCalloutRow(
                                systemImage: "square.stack.3d.up",
                                title: "Linked protocol",
                                detail: model.renderedTitle(canonical: linkedTitle, alias: loadedDetail.summary.linkedProtocolAliasTitle),
                                tint: AtlasPalette.primary
                            )
                        }
                        if let lowStockLabel = loadedDetail.summary.lowStockLabel {
                            AtlasCalloutRow(systemImage: "exclamationmark.triangle.fill", title: "Low-stock posture", detail: lowStockLabel, tint: AtlasPalette.warning)
                        }
                        if let projectedDepletionLabel = loadedDetail.summary.projectedDepletionLabel {
                            AtlasCalloutRow(systemImage: "chart.line.downtrend.xyaxis", title: "Projected depletion", detail: projectedDepletionLabel, tint: AtlasPalette.secondaryText)
                        }
                        if let reorderLeadTimeLabel = loadedDetail.summary.reorderLeadTimeLabel {
                            AtlasCalloutRow(systemImage: "calendar.badge.clock", title: "Lead time", detail: reorderLeadTimeLabel, tint: AtlasPalette.secondaryText)
                        }
                        if model.settingsSnapshot.trustVaultStatus.renderMode == .full,
                           let vendorLabel = loadedDetail.summary.vendorLabel {
                            AtlasCalloutRow(systemImage: "shippingbox.fill", title: "Vendor", detail: vendorLabel, tint: AtlasPalette.secondaryText)
                        }
                    }

                    AtlasSectionCard(style: .utility, title: "Procurement planning") {
                        if let procurementStatusLabel = loadedDetail.planning.procurementStatusLabel {
                            Text(procurementStatusLabel)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(
                                    loadedDetail.planning.needsProcurementReview ? .orange : AtlasPalette.textSecondary
                                )
                        }
                        if let reorderThresholdLabel = loadedDetail.planning.reorderThresholdLabel {
                            Text(reorderThresholdLabel)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                        if let projectedDepletionLabel = loadedDetail.planning.projectedDepletionLabel {
                            Text(projectedDepletionLabel)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                        if let reorderLeadTimeLabel = loadedDetail.planning.reorderLeadTimeLabel {
                            Text(reorderLeadTimeLabel)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                        if let usageLabel = loadedDetail.planning.usageLabel {
                            Text(usageLabel)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                        if let lastProcurementLabel = loadedDetail.planning.lastProcurementLabel {
                            Text(lastProcurementLabel)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                        if let vendorHistorySummary = loadedDetail.planning.vendorHistorySummary {
                            Text(vendorHistorySummary)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                        if loadedDetail.summary.archivedAt == nil {
                            Button("Record procurement") {
                                AtlasFeedback.selection()
                                procurementState = AtlasConsumableProcurementState(
                                    consumableID: consumableID,
                                    quantityUnit: loadedDetail.summary.quantityUnit,
                                    vendorLabel: loadedDetail.summary.vendorLabel,
                                    sourceDetail: nil
                                )
                            }
                            .buttonStyle(AtlasPrimaryButtonStyle())
                        }
                    }

                    AtlasSectionCard(style: .utility, title: "Adjustment") {
                        TextField("Next quantity on hand", text: $adjustmentQuantity)
                            .atlasDecimalKeyboard()
                            .atlasStandaloneInputSurface()
                        TextField("Adjustment note", text: $adjustmentNote)
                            .atlasStandaloneInputSurface()
                        Button("Apply adjustment") {
                            AtlasFeedback.selection()
                            Task {
                                guard let nextQuantityOnHand = Double(adjustmentQuantity) else {
                                    return
                                }
                                _ = await model.applyConsumableAdjustment(
                                    AtlasConsumableAdjustmentDraft(
                                        consumableID: consumableID,
                                        nextQuantityOnHand: nextQuantityOnHand,
                                        note: adjustmentNote.isEmpty ? nil : adjustmentNote
                                    )
                                )
                                detail = await model.consumableDetail(id: consumableID)
                            }
                        }
                        .buttonStyle(AtlasPrimaryButtonStyle())
                    }

                    AtlasSectionCard(title: "Procurement and source history") {
                        if loadedDetail.procurementHistory.isEmpty {
                            AtlasCalloutRow(
                                systemImage: "shippingbox.circle",
                                title: "No procurement history yet",
                                detail: "The first source record appears here after the first procurement entry.",
                                tint: AtlasPalette.secondaryText
                            )
                        } else {
                            ForEach(loadedDetail.procurementHistory) { item in
                                AtlasSectionCard(style: .task) {
                                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(item.title)
                                            .atlasTextRole(.cardBody)
                                            .foregroundStyle(AtlasPalette.textPrimary)
                                        Spacer()
                                        AtlasStatusBadge(item.quantityLabel, tint: AtlasPalette.primary)
                                    }
                                    Text(item.recordedAt.formatted(date: .abbreviated, time: .shortened))
                                        .atlasTextRole(.supporting)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                    if model.settingsSnapshot.trustVaultStatus.renderMode == .full,
                                       let vendorLabel = item.vendorLabel {
                                        Text("Source: \(vendorLabel)")
                                            .atlasTextRole(.supporting)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }
                                    if model.settingsSnapshot.trustVaultStatus.renderMode == .full,
                                       let sourceDetail = item.sourceDetail {
                                        Text(sourceDetail)
                                            .atlasTextRole(.supporting)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }
                                }
                                }
                            }
                        }
                    }

                    AtlasSectionCard(title: "History") {
                        if loadedDetail.adjustmentHistory.isEmpty {
                            AtlasCalloutRow(
                                systemImage: "clock.badge.xmark",
                                title: "No supply movement yet",
                                detail: "Adjustments and resulting stock changes appear here after the first update.",
                                tint: AtlasPalette.secondaryText
                            )
                        } else {
                            ForEach(loadedDetail.adjustmentHistory) { item in
                                AtlasSectionCard(style: .task) {
                                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(item.title)
                                            .atlasTextRole(.cardBody)
                                            .foregroundStyle(AtlasPalette.textPrimary)
                                        Spacer()
                                        if let deltaLabel = item.deltaLabel {
                                            AtlasStatusBadge(deltaLabel, tint: AtlasPalette.primary)
                                        }
                                    }
                                    Text(item.recordedAt.formatted(date: .abbreviated, time: .shortened))
                                        .atlasTextRole(.supporting)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                    Text(item.resultingQuantityLabel)
                                        .atlasTextRole(.supporting)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                    Text(item.detail)
                                        .atlasTextRole(.supporting)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                                }
                            }
                        }
                    }

                    AtlasSectionCard(style: .utility, title: "Actions") {
                        HStack(spacing: AtlasSpacing.small) {
                            Button("Edit") {
                                AtlasFeedback.selection()
                                onEdit(loadedDetail.editableDraft)
                            }
                            .buttonStyle(AtlasSecondaryButtonStyle())

                            Button("Done") {
                                AtlasFeedback.selection()
                                dismiss()
                            }
                            .buttonStyle(AtlasPrimaryButtonStyle())
                        }
                    }
                } else {
                    AtlasSectionCard(style: .utility) {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Supply")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        AtlasFeedback.selection()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if let loadedDetail = detail {
                        Button("Edit") {
                            AtlasFeedback.selection()
                            onEdit(loadedDetail.editableDraft)
                        }
                    }
                }
            }
            .task {
                detail = await model.consumableDetail(id: consumableID)
                adjustmentQuantity = detail.map { $0.summary.quantityOnHand.cleanAtlasNumber } ?? ""
            }
            .sheet(item: $procurementState) { item in
                AtlasConsumableProcurementSheet(
                    model: model,
                    state: item
                ) {
                    detail = await model.consumableDetail(id: consumableID)
                    adjustmentQuantity = detail.map { $0.summary.quantityOnHand.cleanAtlasNumber } ?? ""
                }
            }
        }
    }
}

private struct AtlasVialEditorSheet: View {
    let model: AtlasAppModel
    @State private var draft: AtlasVialDraft
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var referencePhotoData = Data()
    @State private var photoAnalysisState: AtlasImageAnalysisState = .idle
    @Environment(\.dismiss) private var dismiss

    init(model: AtlasAppModel, draft: AtlasVialDraft) {
        self.model = model
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            AtlasScreen {
                let photoAttached = referencePhotoData.isEmpty == false || draft.referencePhotoRelativePath != nil
                let stockProgress = draft.startingQuantity > 0 ? min(max(draft.remainingQuantity / draft.startingQuantity, 0), 1) : 0

                AtlasCommandDeck(
                    eyebrow: draft.id == nil ? "New vial" : "Edit vial",
                    title: draft.label.isEmpty ? "Build a vial record" : draft.label,
                    detail: "Track reference photo, concentration, and depletion.",
                    metrics: [
                        AtlasMetricItem(id: "linked", title: "Linked", value: draft.protocolID == nil ? "No" : "Yes", tint: draft.protocolID == nil ? AtlasPalette.secondaryText : AtlasPalette.success),
                        AtlasMetricItem(id: "photo", title: "Photo", value: photoAttached ? "Added" : "None", tint: photoAttached ? AtlasPalette.primary : AtlasPalette.secondaryText)
                    ],
                    tint: AtlasPalette.primary,
                    style: .hero
                ) {
                    AtlasCalloutRow(
                        systemImage: "shippingbox.fill",
                        title: "Tracking posture",
                        detail: draft.protocolID == nil ? "Keep this vial standalone until it is linked to a protocol." : "This vial is linked to protocol inventory tracking.",
                        tint: AtlasPalette.secondaryText
                    )
                    AtlasProgressMeter(
                        title: "Remaining runway",
                        detail: draft.startingQuantity > 0 ? "\(draft.remainingQuantity.cleanAtlasNumber) of \(draft.startingQuantity.cleanAtlasNumber) \(draft.quantityUnit) remaining." : "Add the starting quantity to show depletion.",
                        value: stockProgress,
                        tint: stockProgress <= 0.25 ? AtlasPalette.warning : AtlasPalette.primary
                    )
                } footer: { EmptyView() }

                AtlasSectionCard(style: .task, title: "Reference capture") {
                    Text("Attach a label photo to scan notes and keep a reference image.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        AtlasInventoryPhotoPickerLabel(title: photoAttached ? "Update vial photo" : "Choose vial photo")
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())

                    if referencePhotoData.isEmpty == false {
                        AtlasInlinePhotoPreview(data: referencePhotoData, height: 220)
                    } else if let referencePhotoRelativePath = draft.referencePhotoRelativePath,
                              let fileURL = try? atlasInventoryPhotoFileURL(relativePath: referencePhotoRelativePath) {
                        AtlasInventoryReferencePhoto(path: fileURL.path)
                            .frame(height: 220)
                    }

                    if case .loading = photoAnalysisState {
                        ProgressView("Scanning label")
                    } else if case let .ready(message) = photoAnalysisState {
                        Text(message)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    } else if case let .failed(message) = photoAnalysisState {
                        Text(message)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(.orange)
                    }

                    TextField("Scanned label notes", text: Binding(
                        get: { draft.labelScanText ?? "" },
                        set: { draft.labelScanText = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .atlasStandaloneInputSurface()
                }

                AtlasSectionCard(style: .task, title: "Vial profile") {
                    AtlasCalloutRow(
                        systemImage: "tag.fill",
                        title: "Inventory identity",
                        detail: "Name the vial clearly and set the quantity language used across depletion alerts and history.",
                        tint: AtlasPalette.primary
                    )
                    TextField("Label", text: Binding(
                        get: { draft.label },
                        set: { draft.label = $0 }
                    ))
                    .atlasStandaloneInputSurface()
                    Picker("Linked protocol", selection: Binding(
                        get: { draft.protocolID },
                        set: { draft.protocolID = $0 }
                    )) {
                        Text("Not linked").tag(Optional<String>.none)
                        ForEach(model.inventorySnapshot.protocolSettings) { item in
                            Text(model.renderedTitle(canonical: item.canonicalTitle, alias: item.aliasTitle))
                                .tag(Optional(item.id))
                        }
                    }
                    TextField("Starting quantity", text: Binding(
                        get: { String(draft.startingQuantity.cleanAtlasNumber) },
                        set: { draft.startingQuantity = Double($0) ?? draft.startingQuantity }
                    ))
                    .atlasDecimalKeyboard()
                    .atlasStandaloneInputSurface()
                    TextField("Current remaining quantity", text: Binding(
                        get: { String(draft.remainingQuantity.cleanAtlasNumber) },
                        set: { draft.remainingQuantity = Double($0) ?? draft.remainingQuantity }
                    ))
                    .atlasDecimalKeyboard()
                    .atlasStandaloneInputSurface()
                    TextField("Quantity unit", text: Binding(
                        get: { draft.quantityUnit },
                        set: { draft.quantityUnit = $0 }
                    ))
                    .atlasStandaloneInputSurface()
                    TextField("Low-stock threshold", text: Binding(
                        get: { draft.lowStockThreshold.map { String($0.cleanAtlasNumber) } ?? "" },
                        set: { draft.lowStockThreshold = Double($0) }
                    ))
                    .atlasDecimalKeyboard()
                    .atlasStandaloneInputSurface()
                }

                AtlasSectionCard(style: .utility, title: "Lifecycle") {
                    AtlasCalloutRow(
                        systemImage: "calendar.badge.clock",
                        title: "Shelf-life controls",
                        detail: "Track opened and expiration dates only when they materially help your protocol planning or safety review.",
                        tint: AtlasPalette.secondaryText
                    )
                    Toggle("Track opened date", isOn: Binding(
                        get: { draft.openedAt != nil },
                        set: { enabled in
                            draft.openedAt = enabled ? (draft.openedAt ?? model.currentDate()) : nil
                        }
                    ))
                    if draft.openedAt != nil {
                        DatePicker(
                            "Opened on",
                            selection: Binding(
                                get: { draft.openedAt ?? model.currentDate() },
                                set: { draft.openedAt = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                    Toggle("Track expiration", isOn: Binding(
                        get: { draft.expiresAt != nil },
                        set: { enabled in
                            draft.expiresAt = enabled ? (draft.expiresAt ?? model.currentDate()) : nil
                        }
                    ))
                    if draft.expiresAt != nil {
                        DatePicker(
                            "Expires on",
                            selection: Binding(
                                get: { draft.expiresAt ?? model.currentDate() },
                                set: { draft.expiresAt = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                AtlasSectionCard(style: .task, title: "Reconstitution link") {
                    AtlasCalloutRow(
                        systemImage: "function",
                        title: "Calculator connection",
                        detail: "Pull in a saved calculator profile to prefill concentration and volume.",
                        tint: AtlasPalette.success
                    )
                    Picker("Calculator profile", selection: Binding(
                        get: { draft.calculatorProfileID },
                        set: { newValue in
                            draft.calculatorProfileID = newValue
                            applyProfileValuesIfNeeded()
                        }
                    )) {
                        Text("None").tag(Optional<String>.none)
                        ForEach(model.calculatorProfiles) { profile in
                            Text(profile.label).tag(Optional(profile.id))
                        }
                    }
                    TextField("Concentration value", text: Binding(
                        get: { draft.concentrationValue.map { String($0.cleanAtlasNumber) } ?? "" },
                        set: { draft.concentrationValue = Double($0) }
                    ))
                    .atlasDecimalKeyboard()
                    .atlasStandaloneInputSurface()
                    TextField("Concentration unit", text: Binding(
                        get: { draft.concentrationUnit ?? "" },
                        set: { draft.concentrationUnit = $0.isEmpty ? nil : $0 }
                    ))
                    .atlasStandaloneInputSurface()
                    TextField("Volume mL", text: Binding(
                        get: { draft.volumeML.map { String($0.cleanAtlasNumber) } ?? "" },
                        set: { draft.volumeML = Double($0) }
                    ))
                    .atlasDecimalKeyboard()
                    .atlasStandaloneInputSurface()
                }

                AtlasSectionCard(style: .utility, title: "Commit") {
                    Text("Save when the photo, concentration, and depletion thresholds look right.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Button("Save") {
                        AtlasFeedback.selection()
                        Task {
                            var saveDraft = draft
                            if referencePhotoData.isEmpty == false {
                                let vialID = saveDraft.id ?? UUID().uuidString
                                saveDraft.id = vialID
                                saveDraft.referencePhotoRelativePath = try? atlasWriteInventoryPhoto(data: referencePhotoData, id: vialID)
                            }
                            if await model.saveVial(saveDraft) != nil {
                                dismiss()
                            }
                        }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())

                    Button("Cancel") {
                        AtlasFeedback.selection()
                        dismiss()
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
            .navigationTitle(draft.id == nil ? "New Vial" : "Edit Vial")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        AtlasFeedback.selection()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        AtlasFeedback.selection()
                        Task {
                            var saveDraft = draft
                            if referencePhotoData.isEmpty == false {
                                let vialID = saveDraft.id ?? UUID().uuidString
                                saveDraft.id = vialID
                                saveDraft.referencePhotoRelativePath = try? atlasWriteInventoryPhoto(data: referencePhotoData, id: vialID)
                            }
                            if await model.saveVial(saveDraft) != nil {
                                dismiss()
                            }
                        }
                    }
                }
            }
            .task(id: selectedPhoto) {
                guard let selectedPhoto else {
                    return
                }
                photoAnalysisState = .loading
                guard let data = try? await selectedPhoto.loadTransferable(type: Data.self),
                      let jpegData = atlasNormalizedJPEGData(from: data) else {
                    photoAnalysisState = .failed("Couldn't read that vial photo.")
                    return
                }
                referencePhotoData = jpegData
                if let scanText = await atlasInventoryLabelScanText(from: jpegData) {
                    draft.labelScanText = scanText
                    if draft.label.isEmpty {
                        draft.label = atlasInventorySuggestedLabel(from: scanText)
                    }
                    photoAnalysisState = .ready("Scanned the label and prefilled notes for review.")
                } else {
                    photoAnalysisState = .failed("Couldn't read a label from that image yet.")
                }
            }
        }
    }

    private func applyProfileValuesIfNeeded() {
        guard let profileID = draft.calculatorProfileID,
              let profile = model.calculatorProfiles.first(where: { $0.id == profileID }) else {
            return
        }

        let result = atlasCalculateReconstitution(
            AtlasCalculatorProfileDraft(
                id: profile.id,
                label: profile.label,
                powderAmount: profile.powderAmount,
                powderUnit: profile.powderUnit,
                diluentVolume: profile.diluentVolume,
                diluentUnit: profile.diluentUnit,
                drawVolume: profile.drawVolume,
                drawUnit: profile.drawUnit
            )
        )

        let concentrationValue = profile.powderAmount / profile.diluentVolume
        draft.concentrationValue = concentrationValue
        draft.concentrationUnit = profile.powderUnit
        draft.volumeML = profile.diluentVolume
        if draft.label.isEmpty {
            draft.label = result.deliveredLabel
        }
    }
}

@MainActor
private struct AtlasInventoryPhotoPickerLabel: View {
    let title: String

    var body: some View {
        HStack(spacing: AtlasSpacing.small) {
            Image(systemName: "camera")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text(title)
                .atlasTextRole(.cardBody)
        }
    }
}

private struct AtlasInventoryReferencePhoto: View {
    let path: String

    var body: some View {
        Group {
            #if canImport(UIKit)
            if let image = UIImage(contentsOfFile: path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AtlasPalette.surfaceSecondary)
            }
            #else
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AtlasPalette.surfaceSecondary)
            #endif
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.55), lineWidth: 1)
        )
    }
}

private func atlasInventorySuggestedLabel(from text: String) -> String {
    text
        .split(whereSeparator: \.isNewline)
        .map(String.init)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .first(where: { $0.isEmpty == false }) ?? "Scanned vial"
}

private struct AtlasConsumableEditorSheet: View {
    let model: AtlasAppModel
    @State private var draft: AtlasConsumableDraft
    @Environment(\.dismiss) private var dismiss

    init(model: AtlasAppModel, draft: AtlasConsumableDraft) {
        self.model = model
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            AtlasScreen {
                let archived = draft.archivedAt != nil
                let lowStock = draft.reorderThreshold.map { draft.quantityOnHand <= $0 } ?? false

                AtlasCommandDeck(
                    eyebrow: draft.id == nil ? "New supply" : "Edit supply",
                    title: draft.name.isEmpty ? "Build a supply record" : draft.name,
                    detail: "Keep units, reorder signals, and purchasing context inside one local workflow.",
                    metrics: [
                        AtlasMetricItem(id: "linked", title: "Linked", value: draft.protocolID == nil ? "No" : "Yes", tint: draft.protocolID == nil ? AtlasPalette.secondaryText : AtlasPalette.success),
                        AtlasMetricItem(id: "archived", title: "Archived", value: archived ? "Yes" : "No", tint: archived ? AtlasPalette.secondaryText : AtlasPalette.primary)
                    ],
                    tint: AtlasPalette.secondaryText,
                    style: .hero
                ) {
                    AtlasCalloutRow(
                        systemImage: "shippingbox.fill",
                        title: "Procurement posture",
                        detail: lowStock ? "Current quantity is at or below the reorder threshold." : "This supply will surface in procurement review once it crosses the threshold.",
                        tint: lowStock ? AtlasPalette.warning : AtlasPalette.secondaryText
                    )
                    AtlasProgressMeter(
                        title: "On-hand confidence",
                        detail: draft.reorderThreshold.map { "\(draft.quantityOnHand.cleanAtlasNumber) \(draft.unit) on hand vs a reorder threshold of \($0.cleanAtlasNumber)." } ?? "Add a reorder threshold to flag procurement risk automatically.",
                        value: draft.reorderThreshold.map { min(max($0 == 0 ? 1 : draft.quantityOnHand / max($0 * 2, 1), 0), 1) } ?? 0.65,
                        tint: lowStock ? AtlasPalette.warning : AtlasPalette.primary
                    )
                } footer: { EmptyView() }

                AtlasSectionCard(style: .task, title: "Supply identity") {
                    AtlasCalloutRow(
                        systemImage: "cube.box.fill",
                        title: "What this tracks",
                        detail: "Name the supply, set its unit, and optionally link it to a protocol.",
                        tint: AtlasPalette.primary
                    )
                    TextField("Name", text: Binding(
                        get: { draft.name },
                        set: { draft.name = $0 }
                    ))
                    .atlasStandaloneInputSurface()
                    TextField("Category", text: Binding(
                        get: { draft.category ?? "" },
                        set: { draft.category = $0.isEmpty ? nil : $0 }
                    ))
                    .atlasStandaloneInputSurface()
                    Picker("Linked protocol", selection: Binding(
                        get: { draft.protocolID },
                        set: { draft.protocolID = $0 }
                    )) {
                        Text("Not linked").tag(Optional<String>.none)
                        ForEach(model.inventorySnapshot.protocolSettings) { item in
                            Text(model.renderedTitle(canonical: item.canonicalTitle, alias: item.aliasTitle))
                                .tag(Optional(item.id))
                        }
                    }
                    TextField("Quantity on hand", text: Binding(
                        get: { draft.quantityOnHand.cleanAtlasNumber },
                        set: { draft.quantityOnHand = Double($0) ?? draft.quantityOnHand }
                    ))
                    .atlasDecimalKeyboard()
                    .atlasStandaloneInputSurface()
                    TextField("Unit", text: Binding(
                        get: { draft.unit },
                        set: { draft.unit = $0 }
                    ))
                    .atlasStandaloneInputSurface()
                    TextField("Use per taken log", text: Binding(
                        get: { draft.quantityPerUse.map(\.cleanAtlasNumber) ?? "" },
                        set: { draft.quantityPerUse = Double($0) }
                    ))
                    .atlasDecimalKeyboard()
                    .atlasStandaloneInputSurface()
                }

                AtlasSectionCard(style: .utility, title: "Reorder planning") {
                    AtlasCalloutRow(
                        systemImage: "cart.badge.plus",
                        title: "Restock timing",
                        detail: "Thresholds and lead time control early restock warnings.",
                        tint: AtlasPalette.warning
                    )
                    TextField("Reorder threshold", text: Binding(
                        get: { draft.reorderThreshold.map(\.cleanAtlasNumber) ?? "" },
                        set: { draft.reorderThreshold = Double($0) }
                    ))
                    .atlasDecimalKeyboard()
                    .atlasStandaloneInputSurface()
                    TextField("Lead time (days)", text: Binding(
                        get: { draft.reorderLeadTimeDays.map(String.init) ?? "" },
                        set: { draft.reorderLeadTimeDays = Int($0) }
                    ))
                    .atlasDecimalKeyboard()
                    .atlasStandaloneInputSurface()
                }

                AtlasSectionCard(style: .task, title: "Details") {
                    AtlasCalloutRow(
                        systemImage: "doc.text.magnifyingglass",
                        title: "Operational notes",
                        detail: "Capture sourcing and lot details for future review.",
                        tint: AtlasPalette.secondaryText
                    )
                    TextField("Lot", text: Binding(
                        get: { draft.lotNumber ?? "" },
                        set: { draft.lotNumber = $0.isEmpty ? nil : $0 }
                    ))
                    .atlasStandaloneInputSurface()
                    TextField("Size", text: Binding(
                        get: { draft.sizeDescription ?? "" },
                        set: { draft.sizeDescription = $0.isEmpty ? nil : $0 }
                    ))
                    .atlasStandaloneInputSurface()
                    TextField("Vendor or store", text: Binding(
                        get: { draft.vendorLabel ?? "" },
                        set: { draft.vendorLabel = $0.isEmpty ? nil : $0 }
                    ))
                    .atlasStandaloneInputSurface()
                    TextField("Purchase notes", text: Binding(
                        get: { draft.purchaseNotes ?? "" },
                        set: { draft.purchaseNotes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .atlasStandaloneInputSurface()
                    TextField("Notes", text: Binding(
                        get: { draft.notes ?? "" },
                        set: { draft.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .atlasStandaloneInputSurface()
                    Toggle("Archive supply", isOn: Binding(
                        get: { draft.archivedAt != nil },
                        set: { draft.archivedAt = $0 ? model.currentDate() : nil }
                    ))
                }

                AtlasSectionCard(style: .utility, title: "Commit") {
                    Text("Save when the quantity language, reorder posture, and sourcing notes look right.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Button("Save") {
                        AtlasFeedback.selection()
                        Task {
                            if await model.saveConsumable(draft) != nil {
                                dismiss()
                            }
                        }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())

                    Button("Cancel") {
                        AtlasFeedback.selection()
                        dismiss()
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
            .navigationTitle(draft.id == nil ? "New Supply" : "Edit Supply")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        AtlasFeedback.selection()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        AtlasFeedback.selection()
                        Task {
                            if await model.saveConsumable(draft) != nil {
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct AtlasProtocolInventorySettingsSheet: View {
    let model: AtlasAppModel
    let item: AtlasProtocolInventorySetting
    @Environment(\.dismiss) private var dismiss
    @State private var linkedVialID: String?
    @State private var siteTrackingEnabled: Bool
    @State private var siteRotationEnabled: Bool

    init(model: AtlasAppModel, item: AtlasProtocolInventorySetting) {
        self.model = model
        self.item = item
        _linkedVialID = State(initialValue: item.linkedVialID)
        _siteTrackingEnabled = State(initialValue: item.siteTrackingEnabled)
        _siteRotationEnabled = State(initialValue: item.siteRotationEnabled)
    }

    var body: some View {
        NavigationStack {
            AtlasScreen {
                AtlasCommandDeck(
                    eyebrow: "Protocol inventory",
                    title: model.renderedTitle(canonical: item.canonicalTitle, alias: item.aliasTitle),
                    detail: "\(item.kindLabel) • \(item.cadenceLabel)",
                    metrics: [
                        AtlasMetricItem(id: "tracking", title: "Site tracking", value: siteTrackingEnabled ? "On" : "Off", tint: siteTrackingEnabled ? AtlasPalette.success : AtlasPalette.secondaryText),
                        AtlasMetricItem(id: "rotation", title: "Rotation", value: siteRotationEnabled ? "On" : "Off", tint: siteRotationEnabled ? AtlasPalette.primary : AtlasPalette.secondaryText)
                    ],
                    tint: AtlasPalette.primary,
                    style: .hero
                ) { } footer: { }

                AtlasSectionCard(title: "Inventory") {
                    Picker("Active vial", selection: $linkedVialID) {
                        Text("None").tag(Optional<String>.none)
                        ForEach(model.inventorySnapshot.vials.filter { $0.archivedAt == nil }) { vial in
                            Text(vial.label).tag(Optional(vial.id))
                        }
                    }
                }

                AtlasSectionCard(title: "Site tracking") {
                    Toggle("Enable site tracking", isOn: $siteTrackingEnabled)
                    Toggle("Rotate suggested site", isOn: $siteRotationEnabled)
                        .disabled(siteTrackingEnabled == false)
                    Text("When rotation is enabled, the next saved site is suggested after the last completed log.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                AtlasSectionCard(style: .utility, title: "Commit") {
                    Button("Save") {
                        AtlasFeedback.selection()
                        Task {
                            await model.updateProtocolInventorySettings(
                                AtlasProtocolInventorySettingsUpdate(
                                    protocolID: item.id,
                                    linkedVialID: linkedVialID,
                                    siteTrackingEnabled: siteTrackingEnabled,
                                    siteRotationEnabled: siteTrackingEnabled ? siteRotationEnabled : false
                                )
                            )
                            dismiss()
                        }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())

                    Button("Cancel") {
                        AtlasFeedback.selection()
                        dismiss()
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
            .navigationTitle("Protocol settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        AtlasFeedback.selection()
                        Task {
                            await model.updateProtocolInventorySettings(
                                AtlasProtocolInventorySettingsUpdate(
                                    protocolID: item.id,
                                    linkedVialID: linkedVialID,
                                    siteTrackingEnabled: siteTrackingEnabled,
                                    siteRotationEnabled: siteTrackingEnabled ? siteRotationEnabled : false
                                )
                            )
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

private struct AtlasConsumableProcurementSheet: View {
    let model: AtlasAppModel
    let state: AtlasConsumableProcurementState
    let onSaved: () async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var quantityReceived: String
    @State private var vendorLabel: String
    @State private var sourceDetail: String
    @State private var receivedAt: Date = Date()

    init(
        model: AtlasAppModel,
        state: AtlasConsumableProcurementState,
        onSaved: @escaping () async -> Void
    ) {
        self.model = model
        self.state = state
        self.onSaved = onSaved
        _quantityReceived = State(initialValue: "")
        _vendorLabel = State(initialValue: state.vendorLabel ?? "")
        _sourceDetail = State(initialValue: state.sourceDetail ?? "")
        _receivedAt = State(initialValue: Date())
    }

    var body: some View {
        NavigationStack {
            AtlasScreen {
                AtlasCommandDeck(
                    eyebrow: "Procurement record",
                    title: "Capture a local source event",
                    detail: "Capture a local procurement record.",
                    metrics: [
                        AtlasMetricItem(id: "unit", title: "Unit", value: state.quantityUnit, tint: AtlasPalette.secondaryText)
                    ],
                    tint: AtlasPalette.secondaryText,
                    style: .hero
                ) { } footer: { }

                AtlasSectionCard(title: "Procurement") {
                    TextField("Quantity received", text: $quantityReceived)
                        .atlasDecimalKeyboard()
                        .atlasStandaloneInputSurface()
                    DatePicker("Received on", selection: $receivedAt, displayedComponents: [.date, .hourAndMinute])
                }

                AtlasSectionCard(title: "Source details") {
                    TextField("Vendor or source", text: $vendorLabel)
                        .atlasStandaloneInputSurface()
                    TextField("Source note", text: $sourceDetail, axis: .vertical)
                        .atlasStandaloneInputSurface()
                    Text("This is recorded locally for planning history only. It never turns into a buy-now flow.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                AtlasSectionCard(style: .utility, title: "Commit") {
                    Button("Save") {
                        AtlasFeedback.selection()
                        Task {
                            guard let quantity = Double(quantityReceived) else {
                                return
                            }
                            let result = await model.recordConsumableProcurement(
                                AtlasConsumableProcurementDraft(
                                    consumableID: state.consumableID,
                                    quantityReceived: quantity,
                                    vendorLabel: vendorLabel.isEmpty ? nil : vendorLabel,
                                    sourceDetail: sourceDetail.isEmpty ? nil : sourceDetail,
                                    receivedAt: receivedAt
                                )
                            )
                            guard result != nil else {
                                return
                            }
                            await onSaved()
                            dismiss()
                        }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())

                    Button("Cancel") {
                        AtlasFeedback.selection()
                        dismiss()
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
            .navigationTitle("Record Procurement")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            guard let quantity = Double(quantityReceived) else {
                                return
                            }
                            let result = await model.recordConsumableProcurement(
                                AtlasConsumableProcurementDraft(
                                    consumableID: state.consumableID,
                                    quantityReceived: quantity,
                                    vendorLabel: vendorLabel.isEmpty ? nil : vendorLabel,
                                    sourceDetail: sourceDetail.isEmpty ? nil : sourceDetail,
                                    receivedAt: receivedAt
                                )
                            )
                            guard result != nil else {
                                return
                            }
                            await onSaved()
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

private struct AtlasSiteEditorSheet: View {
    let model: AtlasAppModel
    @State private var draft: AtlasSiteDraft
    @Environment(\.dismiss) private var dismiss

    init(model: AtlasAppModel, draft: AtlasSiteDraft) {
        self.model = model
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            AtlasScreen {
                AtlasCommandDeck(
                    eyebrow: "Site editor",
                    title: draft.id == nil ? "Create a site" : "Update a site",
                    detail: "Saved hotspots support clearer tracking and calmer rotation suggestions.",
                    metrics: [
                        AtlasMetricItem(id: "mapped", title: "Mapped", value: draft.mapRegionKey == nil ? "No" : "Yes", tint: draft.mapRegionKey == nil ? AtlasPalette.secondaryText : AtlasPalette.success)
                    ],
                    tint: AtlasPalette.primary,
                    style: .hero
                ) { } footer: { }

                AtlasSectionCard(title: "Body map") {
                    AtlasBodyMapPicker(selection: Binding(
                        get: { draft.mapRegionKey },
                        set: { region in
                            draft.mapRegionKey = region
                            guard let region else {
                                return
                            }
                            if draft.bodyArea?.isEmpty != false {
                                draft.bodyArea = region.bodyArea
                            }
                            if draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                draft.name = region.title
                            }
                        }
                    ))

                    if let region = draft.mapRegionKey {
                        Text("Selected hotspot: \(region.title)")
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.textSecondary)
                        Button("Clear hotspot") {
                            AtlasFeedback.selection()
                            draft.mapRegionKey = nil
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                }

                AtlasSectionCard(title: "Site") {
                    TextField("Name", text: Binding(
                        get: { draft.name },
                        set: { draft.name = $0 }
                    ))
                    .atlasStandaloneInputSurface()
                    TextField("Body area", text: Binding(
                        get: { draft.bodyArea ?? "" },
                        set: { draft.bodyArea = $0.isEmpty ? nil : $0 }
                    ))
                    .atlasStandaloneInputSurface()
                    TextField("Notes", text: Binding(
                        get: { draft.notes ?? "" },
                        set: { draft.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .atlasStandaloneInputSurface()
                    Toggle("Archive site", isOn: Binding(
                        get: { draft.archivedAt != nil },
                        set: { draft.archivedAt = $0 ? model.currentDate() : nil }
                    ))
                }

                AtlasSectionCard(style: .utility, title: "Commit") {
                    Button("Save") {
                        AtlasFeedback.selection()
                        Task {
                            await model.saveSite(draft)
                            dismiss()
                        }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())

                    Button("Cancel") {
                        AtlasFeedback.selection()
                        dismiss()
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
            .navigationTitle(draft.id == nil ? "New Site" : "Edit Site")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await model.saveSite(draft)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

private struct AtlasCalculatorFormState {
    var label: String = "2 mg vial baseline"
    var powderAmount: String = "2"
    var powderUnit: String = "mg"
    var diluentVolume: String = "2"
    var diluentUnit: String = "mL"
    var drawVolume: String = "0.25"
    var drawUnit: String = "mL"

    init() {}

    init(profile: AtlasCalculatorProfileRecord) {
        label = profile.label
        powderAmount = String(profile.powderAmount.cleanAtlasNumber)
        powderUnit = profile.powderUnit
        diluentVolume = String(profile.diluentVolume.cleanAtlasNumber)
        diluentUnit = profile.diluentUnit
        drawVolume = String(profile.drawVolume.cleanAtlasNumber)
        drawUnit = profile.drawUnit
    }

    var domainDraft: AtlasCalculatorProfileDraft {
        AtlasCalculatorProfileDraft(
            label: label,
            powderAmount: Double(powderAmount) ?? 0,
            powderUnit: powderUnit,
            diluentVolume: Double(diluentVolume) ?? 0,
            diluentUnit: diluentUnit,
            drawVolume: Double(drawVolume) ?? 0,
            drawUnit: drawUnit
        )
    }
}

private struct AtlasIdentifiedString: Identifiable {
    let value: String
    var id: String { value }
}

private struct AtlasVialEditorState: Identifiable {
    let id: String
    let draft: AtlasVialDraft

    init(draft: AtlasVialDraft) {
        self.id = draft.id ?? UUID().uuidString
        self.draft = draft
    }
}

private struct AtlasConsumableEditorState: Identifiable {
    let id: String
    let draft: AtlasConsumableDraft

    init(draft: AtlasConsumableDraft) {
        self.id = draft.id ?? UUID().uuidString
        self.draft = draft
    }
}

private struct AtlasConsumableProcurementState: Identifiable {
    let id: String
    let consumableID: String
    let quantityUnit: String
    let vendorLabel: String?
    let sourceDetail: String?

    init(
        consumableID: String,
        quantityUnit: String,
        vendorLabel: String?,
        sourceDetail: String?
    ) {
        self.id = UUID().uuidString
        self.consumableID = consumableID
        self.quantityUnit = quantityUnit
        self.vendorLabel = vendorLabel
        self.sourceDetail = sourceDetail
    }
}

private struct AtlasSiteEditorState: Identifiable {
    let id: String
    let draft: AtlasSiteDraft

    init(draft: AtlasSiteDraft) {
        self.id = draft.id ?? UUID().uuidString
        self.draft = draft
    }
}

private extension Double {
    var cleanAtlasNumber: String {
        if abs(self - rounded()) < 0.0001 {
            return String(Int(rounded()))
        }

        return formatted(.number.precision(.fractionLength(0...2)))
    }
}

private extension View {
    @ViewBuilder
    func atlasInlineNavigationTitle() -> some View {
#if os(iOS)
        navigationBarTitleDisplayMode(.inline)
#else
        self
#endif
    }

    @ViewBuilder
    func atlasDecimalKeyboard() -> some View {
#if os(iOS)
        keyboardType(.decimalPad)
#else
        self
#endif
    }
}
