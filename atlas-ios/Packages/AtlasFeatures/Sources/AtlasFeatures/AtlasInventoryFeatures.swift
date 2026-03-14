import AtlasDesignSystem
import AtlasDomain
import Foundation
import SwiftUI

public struct AtlasInventoryScreen: View {
    let model: AtlasAppModel
    @State private var selectedVialID: String?
    @State private var editingVialDraft: AtlasVialEditorState?
    @State private var editingSiteDraft: AtlasSiteEditorState?
    @State private var editingProtocolSettings: AtlasProtocolInventorySetting?

    public var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                    Text("Low-stock watch")
                        .font(.headline)
                    Text("\(model.inventorySnapshot.lowStockCount) vial(s) below threshold")
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Button("Open calculator") {
                        model.open(.calculator)
                    }
                }
                .padding(.vertical, AtlasSpacing.small)
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
                        Button {
                            editingProtocolSettings = item
                        } label: {
                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
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
                            }
                        }
                    }
                }
            }

            Section("Vials") {
                if model.inventorySnapshot.vials.isEmpty {
                    Text("No vials saved yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(model.inventorySnapshot.vials) { vial in
                        Button {
                            selectedVialID = vial.id
                        } label: {
                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
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
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Edit") {
                                Task {
                                    if let detail = await model.vialDetail(id: vial.id) {
                                        editingVialDraft = AtlasVialEditorState(draft: detail.editableDraft)
                                    }
                                }
                            }
                            .tint(.blue)

                            if vial.archivedAt == nil {
                                Button("Archive", role: .destructive) {
                                    Task { await model.archiveVial(id: vial.id) }
                                }
                            }
                        }
                    }
                }
            }

            Section("Sites") {
                if model.inventorySnapshot.sites.isEmpty {
                    Text("No injection sites saved yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(model.inventorySnapshot.sites) { site in
                        Button {
                            editingSiteDraft = AtlasSiteEditorState(
                                draft: AtlasSiteDraft(
                                    id: site.id,
                                    name: site.name,
                                    bodyArea: site.bodyArea,
                                    notes: site.notes,
                                    archivedAt: site.archivedAt
                                )
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                Text(site.name)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Text([site.bodyArea, site.notes].compactMap { $0 }.joined(separator: " • "))
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                    }
                }
            }
        }
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
        .sheet(item: $editingVialDraft) { item in
            AtlasVialEditorSheet(model: model, draft: item.draft)
        }
        .sheet(item: $editingSiteDraft) { item in
            AtlasSiteEditorSheet(model: model, draft: item.draft)
        }
        .sheet(item: $editingProtocolSettings) { item in
            AtlasProtocolInventorySettingsSheet(model: model, item: item)
        }
    }
}

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
        .scrollContentBackground(.hidden)
        .background(AtlasPalette.canvas)
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

                    Section("Correction history") {
                        if loadedDetail.correctionHistory.isEmpty {
                            Text("No manual corrections yet.")
                                .foregroundStyle(AtlasPalette.textSecondary)
                        } else {
                            ForEach(loadedDetail.correctionHistory) { item in
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    Text(item.deltaLabel)
                                        .font(.body.weight(.semibold))
                                    Text(item.recordedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                    if let note = item.note {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    ProgressView()
                }
            }
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
                        set: { draft.archivedAt = $0 ? Date() : nil }
                    ))
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
