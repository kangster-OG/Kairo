import AtlasDesignSystem
import AtlasDomain
import Foundation
import SwiftUI

public struct AtlasInventoryScreen: View {
    let model: AtlasAppModel
    @State private var selectedVialID: String?
    @State private var selectedConsumableID: String?
    @State private var editingVialDraft: AtlasVialEditorState?
    @State private var editingConsumableDraft: AtlasConsumableEditorState?
    @State private var editingSiteDraft: AtlasSiteEditorState?
    @State private var editingProtocolSettings: AtlasProtocolInventorySetting?

    public var body: some View {
        List {
            Section {
                AtlasSectionCard(title: "Low-stock watch") {
                    Text("\(model.inventorySnapshot.lowStockCount) inventory item(s) below threshold")
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Text(
                        model.inventorySnapshot.procurementReviewCount == 0
                            ? "No supply plans need procurement review right now."
                            : "\(model.inventorySnapshot.procurementReviewCount) supply plan(s) ready for procurement review."
                    )
                    .foregroundStyle(AtlasPalette.textSecondary)
                    Button("Open calculator") {
                        model.open(.calculator)
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            if let error = model.loadErrorMessage {
                Section {
                    Text(error)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }

            Section("Protocol links") {
                if model.inventorySnapshot.protocolSettings.isEmpty {
                    Text("Create or import a protocol first.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(model.inventorySnapshot.protocolSettings) { item in
                        AtlasInventoryProtocolCard(model: model, item: item) {
                            editingProtocolSettings = item
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }
            }

            Section("Vials") {
                if model.inventorySnapshot.vials.isEmpty {
                    Text("No vials saved yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(model.inventorySnapshot.vials) { vial in
                        AtlasVialSummaryCard(model: model, vial: vial, onOpen: {
                            selectedVialID = vial.id
                        }, onEdit: {
                            Task {
                                if let detail = await model.vialDetail(id: vial.id) {
                                    editingVialDraft = AtlasVialEditorState(draft: detail.editableDraft)
                                }
                            }
                        }, onArchive: vial.archivedAt == nil ? {
                            Task { await model.archiveVial(id: vial.id) }
                        } : nil)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }
            }

            Section("Supplies") {
                if model.inventorySnapshot.consumables.isEmpty {
                    Text("No supplies saved yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(model.inventorySnapshot.consumables) { consumable in
                        AtlasConsumableSummaryCard(model: model, consumable: consumable, onOpen: {
                            selectedConsumableID = consumable.id
                        }, onEdit: {
                            Task {
                                if let detail = await model.consumableDetail(id: consumable.id) {
                                    editingConsumableDraft = AtlasConsumableEditorState(draft: detail.editableDraft)
                                }
                            }
                        }, onArchiveToggle: {
                            Task { await model.setConsumableArchived(id: consumable.id, isArchived: consumable.archivedAt == nil) }
                        })
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }
            }

            Section("Sites") {
                if model.inventorySnapshot.sites.isEmpty {
                    Text("No injection sites saved yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(model.inventorySnapshot.sites) { site in
                        AtlasSiteSummaryCard(site: site) {
                            editingSiteDraft = AtlasSiteEditorState(
                                draft: AtlasSiteDraft(
                                    id: site.id,
                                    name: site.name,
                                    bodyArea: site.bodyArea,
                                    notes: site.notes,
                                    archivedAt: site.archivedAt
                                )
                            )
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AtlasPalette.canvas)
        .navigationTitle("Inventory")
        .atlasInlineNavigationTitle()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    editingSiteDraft = AtlasSiteEditorState(draft: AtlasSiteDraft())
                } label: {
                    Image(systemName: "mappin.and.ellipse")
                }

                Button {
                    editingConsumableDraft = AtlasConsumableEditorState(draft: AtlasConsumableDraft())
                } label: {
                    Image(systemName: "shippingbox")
                }

                Button {
                    editingVialDraft = AtlasVialEditorState(draft: AtlasVialDraft())
                } label: {
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
}

private struct AtlasInventoryProtocolCard: View {
    let model: AtlasAppModel
    let item: AtlasProtocolInventorySetting
    let onOpen: () -> Void

    var body: some View {
        AtlasSectionCard {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                Text(model.renderedTitle(canonical: item.canonicalTitle, alias: item.aliasTitle))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text("\(item.kindLabel) • \(item.cadenceLabel)")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text(item.linkedVialLabel.map { "Active vial: \($0)" } ?? "No active vial linked")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text(item.siteTrackingEnabled ? (item.siteRotationEnabled ? "Site tracking with rotation" : "Site tracking enabled") : "Site tracking off")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Button("Edit link settings", action: onOpen)
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

    var body: some View {
        AtlasSectionCard {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack {
                    Text(vial.label)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Spacer()
                    if vial.isLowStock {
                        AtlasStatusBadge("Low stock", tint: .orange)
                    } else if vial.archivedAt != nil {
                        AtlasStatusBadge("Archived", tint: AtlasPalette.textSecondary)
                    }
                }
                Text(vial.quantityLabel)
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
                if let protocolTitle = vial.linkedProtocolCanonicalTitle {
                    Text("Linked to \(model.renderedTitle(canonical: protocolTitle, alias: vial.linkedProtocolAliasTitle))")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                if let projectedDepletionLabel = vial.projectedDepletionLabel {
                    Text(projectedDepletionLabel)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                if let autoDecrementLabel = vial.autoDecrementLabel {
                    Text(autoDecrementLabel)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                HStack(spacing: AtlasSpacing.small) {
                    Button("Open", action: onOpen)
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    Button("Edit", action: onEdit)
                        .buttonStyle(AtlasSecondaryButtonStyle())
                }
                if let onArchive {
                    Button("Archive", action: onArchive)
                        .buttonStyle(AtlasChipButtonStyle(tint: .orange))
                }
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

    var body: some View {
        AtlasSectionCard {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                HStack {
                    Text(model.renderedConsumableTitle(canonical: consumable.name, category: consumable.category))
                        .font(.body.weight(.semibold))
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
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Text(consumable.quantityLabel)
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
                if let protocolTitle = consumable.linkedProtocolCanonicalTitle {
                    Text("Linked to \(model.renderedTitle(canonical: protocolTitle, alias: consumable.linkedProtocolAliasTitle))")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                if let usageLabel = consumable.usageLabel {
                    Text(usageLabel)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                if let projectedDepletionLabel = consumable.projectedDepletionLabel {
                    Text(projectedDepletionLabel)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                if let procurementStatusLabel = consumable.procurementStatusLabel {
                    Text(procurementStatusLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(consumable.needsProcurementReview ? .orange : AtlasPalette.textSecondary)
                }
                if let lastProcurementLabel = consumable.lastProcurementLabel {
                    Text(lastProcurementLabel)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                if model.settingsSnapshot.trustVaultStatus.renderMode == .full,
                   let vendorLabel = consumable.vendorLabel {
                    Text("Vendor: \(vendorLabel)")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                HStack(spacing: AtlasSpacing.small) {
                    Button("Open", action: onOpen)
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    Button("Edit", action: onEdit)
                        .buttonStyle(AtlasSecondaryButtonStyle())
                }
                Button(consumable.archivedAt == nil ? "Archive" : "Unarchive", action: onArchiveToggle)
                    .buttonStyle(
                        AtlasChipButtonStyle(
                            tint: consumable.archivedAt == nil ? .orange : AtlasPalette.success
                        )
                    )
            }
        }
    }
}

private struct AtlasSiteSummaryCard: View {
    let site: AtlasSiteSummary
    let onOpen: () -> Void

    var body: some View {
        AtlasSectionCard {
            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                Text(site.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text([site.bodyArea, site.notes].compactMap { $0 }.joined(separator: " • "))
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
                Button("Edit site", action: onOpen)
                    .buttonStyle(AtlasSecondaryButtonStyle())
            }
        }
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
        List {
            Section {
                Text("This is neutral math only. Atlas explains the calculation but never recommends what to take.")
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            Section("Calculator") {
                TextField("Profile label", text: $form.label)
                TextField("Powder amount", text: $form.powderAmount)
                    .atlasDecimalKeyboard()
                TextField("Powder unit", text: $form.powderUnit)
                TextField("Diluent volume", text: $form.diluentVolume)
                    .atlasDecimalKeyboard()
                TextField("Diluent unit", text: $form.diluentUnit)
                TextField("Draw volume", text: $form.drawVolume)
                    .atlasDecimalKeyboard()
                TextField("Draw unit", text: $form.drawUnit)

                Button("Save calculator profile") {
                    Task { await model.saveCalculatorProfile(form.domainDraft) }
                }
                .buttonStyle(.borderedProminent)
            }

            Section("Result") {
                let result = atlasCalculateReconstitution(form.domainDraft)
                Text(result.concentrationLabel)
                Text(result.deliveredLabel)
                ForEach(result.explanation, id: \.self) { line in
                    Text(line)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }

            Section("Saved profiles") {
                if model.calculatorProfiles.isEmpty {
                    Text("No saved profiles yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(model.calculatorProfiles) { profile in
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            Text(profile.label)
                                .font(.body.weight(.semibold))
                            Text(
                                atlasCalculateReconstitution(
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
                            )
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)

                            HStack {
                                Button("Load") {
                                    form = AtlasCalculatorFormState(profile: profile)
                                }
                                .buttonStyle(.bordered)
                                Button("Delete", role: .destructive) {
                                    Task { await model.deleteCalculatorProfile(id: profile.id) }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
        }
        .atlasFormSurface()
        .listStyle(.plain)
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
            List {
                if let loadedDetail = detail {
                    Section {
                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            Text(loadedDetail.summary.label)
                                .font(.title3.weight(.bold))
                            Text(loadedDetail.summary.quantityLabel)
                                .foregroundStyle(AtlasPalette.textSecondary)
                            if let linkedTitle = loadedDetail.summary.linkedProtocolCanonicalTitle {
                                Text("Linked to \(model.renderedTitle(canonical: linkedTitle, alias: loadedDetail.summary.linkedProtocolAliasTitle))")
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                            if let projectedDepletionLabel = loadedDetail.summary.projectedDepletionLabel {
                                Text(projectedDepletionLabel)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                    }

                    Section("Correction") {
                        TextField("Next remaining quantity", text: $correctionQuantity)
                            .atlasDecimalKeyboard()
                        TextField("Correction note", text: $correctionNote)
                        Button("Apply correction") {
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
                    }

                    Section("Inventory history") {
                        if loadedDetail.movementHistory.isEmpty {
                            Text("No inventory movement is recorded yet.")
                                .foregroundStyle(AtlasPalette.textSecondary)
                        } else {
                            ForEach(loadedDetail.movementHistory) { item in
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(item.title)
                                            .font(.body.weight(.semibold))
                                        Spacer()
                                        if let deltaLabel = item.deltaLabel {
                                            Text(deltaLabel)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(AtlasPalette.primary)
                                        }
                                    }
                                    Text(item.recordedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                    Text(item.detail)
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                            }
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .atlasFormSurface()
            .listStyle(.plain)
            .navigationTitle("Vial")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if let loadedDetail = detail {
                        Button("Edit") {
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
            List {
                if let loadedDetail = detail {
                    Section {
                        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                            Text(model.renderedConsumableTitle(canonical: loadedDetail.summary.name, category: loadedDetail.summary.category))
                                .font(.title3.weight(.bold))
                            if let category = loadedDetail.summary.category {
                                Text(category)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                            Text(loadedDetail.summary.quantityLabel)
                                .foregroundStyle(AtlasPalette.textSecondary)
                            if let linkedTitle = loadedDetail.summary.linkedProtocolCanonicalTitle {
                                Text("Linked to \(model.renderedTitle(canonical: linkedTitle, alias: loadedDetail.summary.linkedProtocolAliasTitle))")
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                            if let lowStockLabel = loadedDetail.summary.lowStockLabel {
                                Text(lowStockLabel)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                            if let projectedDepletionLabel = loadedDetail.summary.projectedDepletionLabel {
                                Text(projectedDepletionLabel)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                            if let reorderLeadTimeLabel = loadedDetail.summary.reorderLeadTimeLabel {
                                Text(reorderLeadTimeLabel)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                            if model.settingsSnapshot.trustVaultStatus.renderMode == .full,
                               let vendorLabel = loadedDetail.summary.vendorLabel {
                                Text("Vendor: \(vendorLabel)")
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                    }

                    Section("Planning") {
                        if let procurementStatusLabel = loadedDetail.planning.procurementStatusLabel {
                            Text(procurementStatusLabel)
                                .foregroundStyle(
                                    loadedDetail.planning.needsProcurementReview ? .orange : AtlasPalette.textSecondary
                                )
                        }
                        if let reorderThresholdLabel = loadedDetail.planning.reorderThresholdLabel {
                            Text(reorderThresholdLabel)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                        if let projectedDepletionLabel = loadedDetail.planning.projectedDepletionLabel {
                            Text(projectedDepletionLabel)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                        if let reorderLeadTimeLabel = loadedDetail.planning.reorderLeadTimeLabel {
                            Text(reorderLeadTimeLabel)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                        if let usageLabel = loadedDetail.planning.usageLabel {
                            Text(usageLabel)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                        if let lastProcurementLabel = loadedDetail.planning.lastProcurementLabel {
                            Text(lastProcurementLabel)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                        if let vendorHistorySummary = loadedDetail.planning.vendorHistorySummary {
                            Text(vendorHistorySummary)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                        if loadedDetail.summary.archivedAt == nil {
                            Button("Record procurement") {
                                procurementState = AtlasConsumableProcurementState(
                                    consumableID: consumableID,
                                    quantityUnit: loadedDetail.summary.quantityUnit,
                                    vendorLabel: loadedDetail.summary.vendorLabel,
                                    sourceDetail: nil
                                )
                            }
                        }
                    }

                    Section("Adjustment") {
                        TextField("Next quantity on hand", text: $adjustmentQuantity)
                            .atlasDecimalKeyboard()
                        TextField("Adjustment note", text: $adjustmentNote)
                        Button("Apply adjustment") {
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
                    }

                    Section("Procurement and source history") {
                        if loadedDetail.procurementHistory.isEmpty {
                            Text("No procurement history is recorded yet.")
                                .foregroundStyle(AtlasPalette.textSecondary)
                        } else {
                            ForEach(loadedDetail.procurementHistory) { item in
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(item.title)
                                            .font(.body.weight(.semibold))
                                        Spacer()
                                        Text(item.quantityLabel)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(AtlasPalette.primary)
                                    }
                                    Text(item.recordedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                    if model.settingsSnapshot.trustVaultStatus.renderMode == .full,
                                       let vendorLabel = item.vendorLabel {
                                        Text("Source: \(vendorLabel)")
                                            .font(.caption)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }
                                    if model.settingsSnapshot.trustVaultStatus.renderMode == .full,
                                       let sourceDetail = item.sourceDetail {
                                        Text(sourceDetail)
                                            .font(.caption)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }
                                }
                            }
                        }
                    }

                    Section("History") {
                        if loadedDetail.adjustmentHistory.isEmpty {
                            Text("No supply movement is recorded yet.")
                                .foregroundStyle(AtlasPalette.textSecondary)
                        } else {
                            ForEach(loadedDetail.adjustmentHistory) { item in
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(item.title)
                                            .font(.body.weight(.semibold))
                                        Spacer()
                                        if let deltaLabel = item.deltaLabel {
                                            Text(deltaLabel)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(AtlasPalette.primary)
                                        }
                                    }
                                    Text(item.recordedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                    Text(item.resultingQuantityLabel)
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                    Text(item.detail)
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                            }
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .atlasFormSurface()
            .listStyle(.plain)
            .navigationTitle("Supply")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if let loadedDetail = detail {
                        Button("Edit") {
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
    @Environment(\.dismiss) private var dismiss

    init(model: AtlasAppModel, draft: AtlasVialDraft) {
        self.model = model
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vial") {
                    TextField("Label", text: Binding(
                        get: { draft.label },
                        set: { draft.label = $0 }
                    ))
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
                    TextField("Current remaining quantity", text: Binding(
                        get: { String(draft.remainingQuantity.cleanAtlasNumber) },
                        set: { draft.remainingQuantity = Double($0) ?? draft.remainingQuantity }
                    ))
                    .atlasDecimalKeyboard()
                    TextField("Quantity unit", text: Binding(
                        get: { draft.quantityUnit },
                        set: { draft.quantityUnit = $0 }
                    ))
                    TextField("Low-stock threshold", text: Binding(
                        get: { draft.lowStockThreshold.map { String($0.cleanAtlasNumber) } ?? "" },
                        set: { draft.lowStockThreshold = Double($0) }
                    ))
                    .atlasDecimalKeyboard()
                }

                Section("Reconstitution link") {
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
                    TextField("Concentration unit", text: Binding(
                        get: { draft.concentrationUnit ?? "" },
                        set: { draft.concentrationUnit = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Volume mL", text: Binding(
                        get: { draft.volumeML.map { String($0.cleanAtlasNumber) } ?? "" },
                        set: { draft.volumeML = Double($0) }
                    ))
                    .atlasDecimalKeyboard()
                }
            }
            .atlasFormSurface()
            .navigationTitle(draft.id == nil ? "New Vial" : "Edit Vial")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await model.saveVial(draft) != nil {
                                dismiss()
                            }
                        }
                    }
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
            Form {
                Section("Supply") {
                    TextField("Name", text: Binding(
                        get: { draft.name },
                        set: { draft.name = $0 }
                    ))
                    TextField("Category", text: Binding(
                        get: { draft.category ?? "" },
                        set: { draft.category = $0.isEmpty ? nil : $0 }
                    ))
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
                    TextField("Unit", text: Binding(
                        get: { draft.unit },
                        set: { draft.unit = $0 }
                    ))
                    TextField("Use per taken log", text: Binding(
                        get: { draft.quantityPerUse.map(\.cleanAtlasNumber) ?? "" },
                        set: { draft.quantityPerUse = Double($0) }
                    ))
                    .atlasDecimalKeyboard()
                }

                Section("Reorder") {
                    TextField("Reorder threshold", text: Binding(
                        get: { draft.reorderThreshold.map(\.cleanAtlasNumber) ?? "" },
                        set: { draft.reorderThreshold = Double($0) }
                    ))
                    .atlasDecimalKeyboard()
                    TextField("Lead time (days)", text: Binding(
                        get: { draft.reorderLeadTimeDays.map(String.init) ?? "" },
                        set: { draft.reorderLeadTimeDays = Int($0) }
                    ))
                    .atlasDecimalKeyboard()
                }

                Section("Details") {
                    TextField("Lot", text: Binding(
                        get: { draft.lotNumber ?? "" },
                        set: { draft.lotNumber = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Size", text: Binding(
                        get: { draft.sizeDescription ?? "" },
                        set: { draft.sizeDescription = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Vendor or store", text: Binding(
                        get: { draft.vendorLabel ?? "" },
                        set: { draft.vendorLabel = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Purchase notes", text: Binding(
                        get: { draft.purchaseNotes ?? "" },
                        set: { draft.purchaseNotes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    TextField("Notes", text: Binding(
                        get: { draft.notes ?? "" },
                        set: { draft.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    Toggle("Archive supply", isOn: Binding(
                        get: { draft.archivedAt != nil },
                        set: { draft.archivedAt = $0 ? model.currentDate() : nil }
                    ))
                }
            }
            .atlasFormSurface()
            .navigationTitle(draft.id == nil ? "New Supply" : "Edit Supply")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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
            Form {
                Section {
                    Text(model.renderedTitle(canonical: item.canonicalTitle, alias: item.aliasTitle))
                        .font(.headline)
                    Text("\(item.kindLabel) • \(item.cadenceLabel)")
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                Section("Inventory") {
                    Picker("Active vial", selection: $linkedVialID) {
                        Text("None").tag(Optional<String>.none)
                        ForEach(model.inventorySnapshot.vials.filter { $0.archivedAt == nil }) { vial in
                            Text(vial.label).tag(Optional(vial.id))
                        }
                    }
                }

                Section("Site tracking") {
                    Toggle("Enable site tracking", isOn: $siteTrackingEnabled)
                    Toggle("Rotate suggested site", isOn: $siteRotationEnabled)
                        .disabled(siteTrackingEnabled == false)
                    Text("When rotation is enabled, Atlas suggests the next saved site after the last completed log.")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
            .atlasFormSurface()
            .navigationTitle("Protocol settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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
            Form {
                Section("Procurement") {
                    TextField("Quantity received", text: $quantityReceived)
                        .atlasDecimalKeyboard()
                    DatePicker("Received on", selection: $receivedAt, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Source details") {
                    TextField("Vendor or source", text: $vendorLabel)
                    TextField("Source note", text: $sourceDetail, axis: .vertical)
                    Text("Atlas records this locally for planning history only. It never turns into a buy-now flow.")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
            .atlasFormSurface()
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
            Form {
                Section("Site") {
                    TextField("Name", text: Binding(
                        get: { draft.name },
                        set: { draft.name = $0 }
                    ))
                    TextField("Body area", text: Binding(
                        get: { draft.bodyArea ?? "" },
                        set: { draft.bodyArea = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Notes", text: Binding(
                        get: { draft.notes ?? "" },
                        set: { draft.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    Toggle("Archive site", isOn: Binding(
                        get: { draft.archivedAt != nil },
                        set: { draft.archivedAt = $0 ? model.currentDate() : nil }
                    ))
                }
            }
            .atlasFormSurface()
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
