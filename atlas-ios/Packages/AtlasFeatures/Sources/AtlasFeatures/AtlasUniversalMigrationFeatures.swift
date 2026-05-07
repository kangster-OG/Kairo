import AtlasDesignSystem
import AtlasDomain
import SwiftUI

public extension AtlasAppModel {
    func importerDescriptors() -> [AtlasImporterDescriptor] {
        dependencies.importExport.importerDescriptors()
    }

    func prepareUniversalImport(
        _ request: AtlasUniversalImportRequest
    ) async -> AtlasUniversalPreparedImport? {
        do {
            return try await dependencies.importExport.prepareUniversalImport(request)
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    func commitUniversalImport(
        _ prepared: AtlasUniversalPreparedImport
    ) async -> AtlasImportCommitResult? {
        do {
            let result = try await dependencies.importExport.commitUniversalImport(prepared, mode: .replaceExisting)
            await refreshBootstrap()
            await refreshShellData()
            await refreshTrustVaultSnapshot()
            return result
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    func cancelUniversalImport(_ prepared: AtlasUniversalPreparedImport) async {
        await dependencies.importExport.cancelUniversalImport(prepared)
    }

    func loadImportTemplates(importer: AtlasImporterKind?) async -> [AtlasSavedImportTemplate] {
        do {
            return try await dependencies.importExport.listImportTemplates(importer: importer)
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return []
        }
    }

    func saveImportTemplate(_ draft: AtlasImportTemplateDraft) async -> AtlasSavedImportTemplate? {
        do {
            return try await dependencies.importExport.saveImportTemplate(draft, now: currentDate())
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    func deleteImportTemplate(id: String) async -> Bool {
        do {
            try await dependencies.importExport.deleteImportTemplate(id: id)
            return true
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return false
        }
    }

    func loadRestorePoints() async -> [AtlasRestorePointSummary] {
        do {
            return try await dependencies.importExport.listRestorePoints()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return []
        }
    }

    func previewRestorePoint(id: String) async -> AtlasRestorePointPreview? {
        do {
            return try await dependencies.importExport.previewRestorePoint(id: id)
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    func restoreRestorePoint(id: String) async -> AtlasRestoreCommitResult? {
        do {
            let result = try await dependencies.importExport.restoreRestorePoint(id: id, now: currentDate())
            await refreshBootstrap()
            await refreshShellData()
            await refreshTrustVaultSnapshot()
            return result
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    func previewProviderHandoff(
        _ request: AtlasProviderHandoffRequest
    ) async -> AtlasProviderHandoffPreview? {
        guard await unlockTrustVaultIfNeeded(reason: "Preview provider handoff") else {
            return nil
        }

        do {
            return try await dependencies.importExport.previewProviderHandoff(request, now: currentDate())
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    func createProviderHandoff(
        _ request: AtlasProviderHandoffRequest
    ) async -> AtlasProviderHandoffResult? {
        guard await unlockTrustVaultIfNeeded(reason: "Create provider handoff") else {
            return nil
        }

        do {
            let result = try await dependencies.importExport.createProviderHandoff(request, now: currentDate())
            await refreshTrustVaultSnapshot()
            return result
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }
}

struct AtlasImportCenterScreen: View {
    let model: AtlasAppModel

    @State private var selectedImporter: AtlasImporterKind = .atlasJSON
    @State private var filePath = ""
    @State private var rawText = ""
    @State private var genericMapping = AtlasGenericCsvMapping(nameColumn: "name", cadenceColumn: "cadence")
    @State private var defaultKind: AtlasProtocolKind = .custom
    @State private var manualTimezone = TimeZone.current.identifier
    @State private var manualAnchorDate: Date
    @State private var templateName = ""
    @State private var templates: [AtlasSavedImportTemplate] = []
    @State private var restorePoints: [AtlasRestorePointSummary] = []
    @State private var prepared: AtlasUniversalPreparedImport?
    @State private var lastCommit: AtlasImportCommitResult?
    @State private var restorePreview: AtlasRestorePointPreview?
    @State private var lastRestore: AtlasRestoreCommitResult?

    init(model: AtlasAppModel) {
        self.model = model
        _manualAnchorDate = State(initialValue: model.currentDate())
    }

    var body: some View {
        AtlasScreen {
            importCenterHeader(
                "Import Center",
                subtitle: "Kairo JSON remains the canonical migration path. CSV and manual imports stay preview-first, deterministic, and local until you explicitly replace local data."
            )

            if let error = model.loadErrorMessage {
                AtlasSectionCard {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            AtlasSectionCard(style: .utility, title: "Importer") {
                Picker("Source", selection: $selectedImporter) {
                    ForEach(model.importerDescriptors()) { descriptor in
                        Text(descriptor.title).tag(descriptor.kind)
                    }
                }

                if let descriptor = model.importerDescriptors().first(where: { $0.kind == selectedImporter }) {
                    Text(descriptor.subtitle)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    if descriptor.isCanonical {
                        Text("Recommended migration path")
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.primary)
                    }
                }
            }

            AtlasSectionCard(style: .elevated, title: "Source input") {
                if selectedImporter == .atlasJSON {
                    TextField("Absolute path to Kairo JSON export", text: $filePath)
                        .autocorrectionDisabled()
                        .atlasStandaloneInputSurface()
                } else {
                    TextEditor(text: $rawText)
                        .frame(minHeight: 180)
                        .font(.system(.body, design: .monospaced))
                        .autocorrectionDisabled()
                        .atlasStandaloneInputSurface()
                }

                if selectedImporter == .genericCSV {
                    AtlasGenericCsvMappingFields(mapping: $genericMapping)
                }

                if selectedImporter == .manualText {
                    AtlasManualImportOptionsFields(
                        defaultKind: $defaultKind,
                        timezone: $manualTimezone,
                        anchorDate: $manualAnchorDate
                    )
                }

                Button("Preview import") {
                    Task {
                        lastCommit = nil
                        prepared = await model.prepareUniversalImport(importRequest)
                    }
                }
                .buttonStyle(AtlasPrimaryButtonStyle())

                if let prepared {
                    Button("Replace local data with this import") {
                        Task {
                            lastCommit = await model.commitUniversalImport(prepared)
                            if lastCommit != nil {
                                self.prepared = nil
                                restorePreview = nil
                                await reloadSafetyData()
                            }
                        }
                    }
                    .buttonStyle(AtlasWarningButtonStyle())

                    Button("Cancel preview") {
                        Task {
                            await model.cancelUniversalImport(prepared)
                            self.prepared = nil
                        }
                    }
                    .buttonStyle(.plain)
                }

                Text("Replacing local data creates a restore point first when Kairo already has local rows.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            if supportsTemplates {
                AtlasSectionCard(title: "Saved templates") {
                    Text("Templates store mapping and import options only. Kairo never saves pasted import content into these presets.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    TextField(templatePlaceholder, text: $templateName)
                        .autocorrectionDisabled()
                        .atlasStandaloneInputSurface()

                    Button("Save current template") {
                        Task {
                            guard let currentTemplateDraft else {
                                return
                            }
                            if let saved = await model.saveImportTemplate(currentTemplateDraft) {
                                templateName = saved.name
                                templates = await model.loadImportTemplates(importer: selectedImporter)
                            }
                        }
                    }
                    .buttonStyle(AtlasTertiaryButtonStyle())
                    .disabled(currentTemplateDraft == nil || templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if templates.isEmpty {
                        Text("No saved templates for this importer yet.")
                            .foregroundStyle(AtlasPalette.textSecondary)
                    } else {
                        ForEach(templates) { template in
                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                HStack {
                                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                        Text(template.name)
                                            .atlasTextRole(.cardBody)
                                            .foregroundStyle(AtlasPalette.textPrimary)
                                        Text(template.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                            .atlasTextRole(.supporting)
                                            .foregroundStyle(AtlasPalette.textSecondary)
                                    }
                                    Spacer()
                                    Button("Apply") {
                                        applyTemplate(template)
                                    }
                                    .buttonStyle(.bordered)
                                    Button("Delete") {
                                        Task {
                                            if await model.deleteImportTemplate(id: template.id) {
                                                templates = await model.loadImportTemplates(importer: selectedImporter)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }

                                AtlasDryRunLineGroup(title: "Template fields", lines: templateSummaryLines(template))
                            }
                        }
                    }
                }
            }

            if let prepared {
                AtlasSectionCard(title: "Dry-run preview") {
                    Text(prepared.dryRun.sourceSummary)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Text("Create: \(prepared.dryRun.recordsToCreate) • Update: \(prepared.dryRun.recordsToUpdate)")
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.primary)

                    if let summary = prepared.dryRun.plainLanguageSummary {
                        AtlasGeneratedSummaryCard(summary: summary, wrapInCard: false)
                    }

                    AtlasDryRunLineGroup(title: "Datasets", lines: prepared.dryRun.datasetDiffs.map {
                        "\($0.dataset): +\($0.creates) / ~\($0.updates)"
                    })
                    AtlasImportLintGroup(items: prepared.dryRun.lintFindings)
                    AtlasDryRunLineGroup(title: "Warnings", lines: prepared.dryRun.warnings)
                    AtlasDryRunLineGroup(title: "Conflicts", lines: prepared.dryRun.conflicts)
                    AtlasDryRunLineGroup(title: "Unsupported rows", lines: prepared.dryRun.unsupportedRows)
                    AtlasDryRunLineGroup(title: "Privacy notes", lines: prepared.dryRun.privacyNotes)
                    AtlasDryRunLineGroup(title: "Backfill notes", lines: prepared.dryRun.backfillNotes)
                }
            }

            AtlasSectionCard(title: "Restore points") {
                Text("Restore points preview the saved Kairo JSON snapshot before you commit a restore. Restores replace local data transactionally and append an audit entry.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                if restorePoints.isEmpty {
                    Text("No restore points available yet. Kairo creates them before destructive replace-import and restore actions.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(restorePoints) { restorePoint in
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    Text(restorePoint.title)
                                        .atlasTextRole(.cardBody)
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                    Text("\(restorePointActionLabel(restorePoint.actionKind)) • \(restorePoint.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                        .atlasTextRole(.supporting)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                    Text(restorePoint.sourceSummary)
                                        .atlasTextRole(.supporting)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                                Spacer()
                                Button("Preview restore") {
                                    Task {
                                        restorePreview = await model.previewRestorePoint(id: restorePoint.id)
                                        lastRestore = nil
                                    }
                                }
                                .buttonStyle(.bordered)
                            }

                            Text("\(restorePoint.rowCount) rows captured")
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                }
            }

            if let restorePreview {
                AtlasSectionCard(title: "Restore preview") {
                    Text(restorePreview.restorePoint.title)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text("Create: \(restorePreview.recordsToCreate) • Update: \(restorePreview.recordsToUpdate)")
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.primary)

                    AtlasDryRunLineGroup(title: "Datasets", lines: restorePreview.datasetDiffs.map {
                        "\($0.dataset): +\($0.creates) / ~\($0.updates)"
                    })
                    AtlasDryRunLineGroup(title: "Warnings", lines: restorePreview.warnings)
                    AtlasDryRunLineGroup(title: "Notes", lines: restorePreview.notes)

                    Button("Restore this snapshot") {
                        Task {
                            lastRestore = await model.restoreRestorePoint(id: restorePreview.restorePoint.id)
                            if lastRestore != nil {
                                prepared = nil
                                lastCommit = nil
                                self.restorePreview = nil
                                await reloadSafetyData()
                            }
                        }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                }
            }

            if let lastCommit {
                AtlasSectionCard(title: "Last import") {
                    Text("Protocols imported: \(lastCommit.importedProtocolCount)")
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Text("History rows imported: \(lastCommit.importedLogEventCount)")
                        .foregroundStyle(AtlasPalette.textSecondary)
                    if let backupURL = lastCommit.backupURL {
                        Text("Restore point created: \(backupURL.lastPathComponent)")
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                    if let nextDue = lastCommit.nextDue {
                        Text("Next due now surfaces as \(nextDue.displayTitle)")
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.primary)
                    }
                }
            }

            if let lastRestore {
                AtlasSectionCard(title: "Latest restore") {
                    Text("Protocols restored: \(lastRestore.restoredProtocolCount)")
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Text("Historical logs restored: \(lastRestore.restoredLogEventCount)")
                        .foregroundStyle(AtlasPalette.textSecondary)
                    if let backupURL = lastRestore.backupURL {
                        Text("Previous local state backed up as: \(backupURL.lastPathComponent)")
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                    if let nextDue = lastRestore.nextDue {
                        Text("Next due now surfaces as \(nextDue.displayTitle)")
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.primary)
                    }
                }
            }
        }
        .task {
            await reloadSafetyData()
        }
        .task(id: selectedImporter) {
            prepared = nil
            templates = await model.loadImportTemplates(importer: selectedImporter)
        }
    }

    private var importRequest: AtlasUniversalImportRequest {
        AtlasUniversalImportRequest(
            importer: selectedImporter,
            fileURL: selectedImporter == .atlasJSON && filePath.isEmpty == false ? URL(fileURLWithPath: filePath) : nil,
            rawText: selectedImporter == .atlasJSON ? nil : rawText,
            genericCsvMapping: selectedImporter == .genericCSV ? genericMapping : nil,
            manualOptions: manualOptions
        )
    }

    private var manualOptions: AtlasManualImportOptions {
        AtlasManualImportOptions(
            defaultKind: defaultKind,
            timezone: manualTimezone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? TimeZone.current.identifier : manualTimezone,
            anchorDate: manualAnchorDate
        )
    }

    private var supportsTemplates: Bool {
        selectedImporter == .genericCSV || selectedImporter == .manualText
    }

    private var templatePlaceholder: String {
        switch selectedImporter {
        case .genericCSV:
            return "Template name for this CSV mapping"
        case .manualText:
            return "Template name for this manual import setup"
        default:
            return "Template name"
        }
    }

    private var currentTemplateDraft: AtlasImportTemplateDraft? {
        guard supportsTemplates else {
            return nil
        }

        return AtlasImportTemplateDraft(
            name: templateName,
            importer: selectedImporter,
            genericCsvMapping: selectedImporter == .genericCSV ? genericMapping : nil,
            manualOptions: selectedImporter == .manualText ? manualOptions : nil
        )
    }

    @MainActor
    private func reloadSafetyData() async {
        templates = await model.loadImportTemplates(importer: selectedImporter)
        restorePoints = await model.loadRestorePoints()
    }

    private func applyTemplate(_ template: AtlasSavedImportTemplate) {
        templateName = template.name
        if let genericCsvMapping = template.genericCsvMapping {
            genericMapping = genericCsvMapping
        }
        if let manualOptions = template.manualOptions {
            defaultKind = manualOptions.defaultKind
            manualTimezone = manualOptions.timezone
            manualAnchorDate = manualOptions.anchorDate
        }
    }

    private func templateSummaryLines(_ template: AtlasSavedImportTemplate) -> [String] {
        switch template.importer {
        case .genericCSV:
            guard let mapping = template.genericCsvMapping else {
                return ["No mapping fields saved."]
            }
            return [
                "Name column: \(mapping.nameColumn)",
                "Cadence column: \(mapping.cadenceColumn)",
                mapping.kindColumn.map { "Kind column: \($0)" },
                mapping.timeColumn.map { "Time column: \($0)" },
                mapping.doseAmountColumn.map { "Dose amount column: \($0)" },
                mapping.doseUnitColumn.map { "Dose unit column: \($0)" },
                mapping.startDateColumn.map { "Start date column: \($0)" }
            ].compactMap { $0 }
        case .manualText:
            guard let manualOptions = template.manualOptions else {
                return ["No manual import options saved."]
            }
            return [
                "Default kind: \(manualOptions.defaultKind.rawValue.capitalized)",
                "Timezone: \(manualOptions.timezone)",
                "Anchor date: \(manualOptions.anchorDate.formatted(date: .abbreviated, time: .omitted))"
            ]
        default:
            return ["Templates are only available for generic CSV and manual text imports."]
        }
    }

    private func restorePointActionLabel(_ kind: AtlasRestorePointActionKind) -> String {
        switch kind {
        case .replaceImport:
            return "Before replace import"
        case .restoreCommit:
            return "Before restore"
        }
    }
}

struct AtlasProviderHandoffCard: View {
    let model: AtlasAppModel

    @State private var selectedPreset: AtlasProviderHandoffPreset = .clinicianSummary
    @State private var scopeKind: AtlasProviderHandoffScopeKind = .summaryOnly
    @State private var aliasModeEnabled = true
    @State private var selectedProtocolID: String?
    @State private var selectedProtocolIDs: Set<String> = []
    @State private var customRangeStart: Date
    @State private var customRangeEnd: Date
    @State private var preview: AtlasProviderHandoffPreview?
    @State private var latestResult: AtlasProviderHandoffResult?

    init(model: AtlasAppModel) {
        self.model = model
        let referenceDate = model.currentDate()
        _customRangeStart = State(initialValue: Calendar.current.date(byAdding: .day, value: -14, to: referenceDate) ?? referenceDate)
        _customRangeEnd = State(initialValue: referenceDate)
    }

    var body: some View {
        AtlasSectionCard(title: "Provider handoff") {
            Picker("Preset", selection: $selectedPreset) {
                ForEach(AtlasProviderHandoffPreset.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }

            Text(selectedPreset.subtitle)
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)

            Button("Apply preset") {
                applyPreset(selectedPreset)
            }
            .buttonStyle(.bordered)

            Picker("Scope", selection: $scopeKind) {
                Text("Current protocol").tag(AtlasProviderHandoffScopeKind.currentProtocolOnly)
                Text("Selected protocols").tag(AtlasProviderHandoffScopeKind.selectedProtocols)
                Text("Last 30 days").tag(AtlasProviderHandoffScopeKind.last30Days)
                Text("Symptoms only").tag(AtlasProviderHandoffScopeKind.symptomsOnly)
                Text("Inventory only").tag(AtlasProviderHandoffScopeKind.inventoryOnly)
                Text("Summary only").tag(AtlasProviderHandoffScopeKind.summaryOnly)
                Text("Custom date range").tag(AtlasProviderHandoffScopeKind.customDateRange)
            }

            if needsProtocolSelection {
                Picker("Protocol", selection: $selectedProtocolID) {
                    Text("Select a protocol").tag(String?.none)
                    ForEach(model.trustVaultSnapshot.aliases) { item in
                        Text(model.renderedTitle(canonical: item.canonicalTitle, alias: item.aliasLabel))
                            .tag(String?.some(item.protocolID))
                    }
                }
            }

            if needsMultipleProtocolSelection {
                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    Text("Protocols")
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.primary)

                    ForEach(model.libraryProtocols) { protocolSummary in
                        Toggle(
                            model.renderedTitle(
                                canonical: protocolSummary.canonicalTitle,
                                alias: protocolSummary.aliasTitle
                            ),
                            isOn: selectionBinding(for: protocolSummary.id)
                        )
                    }
                }
            }

            Toggle("Alias mode for handoff", isOn: $aliasModeEnabled)

            if scopeKind == .customDateRange {
                DatePicker("Start", selection: $customRangeStart, displayedComponents: .date)
                DatePicker("End", selection: $customRangeEnd, displayedComponents: .date)
            }

            Text("Presets remain static and bounded. Preview the pack before you create the handoff bundle.")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)

            Button("Preview handoff") {
                Task {
                    preview = await model.previewProviderHandoff(request)
                }
            }
            .buttonStyle(AtlasPrimaryButtonStyle())

            Button("Create handoff bundle") {
                Task {
                    latestResult = await model.createProviderHandoff(request)
                }
            }
            .buttonStyle(.bordered)

            if let preview {
                Text(preview.summary)
                    .foregroundStyle(AtlasPalette.textSecondary)
                if let summary = preview.plainLanguageSummary {
                    AtlasGeneratedSummaryCard(summary: summary, wrapInCard: false)
                }
                ForEach(preview.sections) { section in
                    AtlasDryRunLineGroup(title: section.title, lines: section.lines)
                }
            }

            if let latestResult {
                Text("Summary ready at \(latestResult.summaryURL.lastPathComponent)")
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text("Attachment ready at \(latestResult.attachmentURL.lastPathComponent)")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
        }
        .task {
            if selectedProtocolID == nil {
                selectedProtocolID = model.trustVaultSnapshot.aliases.first?.protocolID
            }
            if selectedProtocolIDs.isEmpty, let defaultProtocolID = selectedProtocolID ?? model.libraryProtocols.first?.id {
                selectedProtocolIDs = [defaultProtocolID]
            }
            applyPreset(selectedPreset)
        }
    }

    private var request: AtlasProviderHandoffRequest {
        let selectedIDs: [String]
        switch scopeKind {
        case .selectedProtocols:
            selectedIDs = selectedProtocolIDs.sorted()
        case .customDateRange:
            selectedIDs = selectedProtocolIDs.isEmpty ? model.libraryProtocols.map(\.id) : selectedProtocolIDs.sorted()
        default:
            selectedIDs = []
        }

        return AtlasProviderHandoffRequest(
            scopeKind: scopeKind,
            protocolID: selectedProtocolID,
            protocolIDs: selectedIDs,
            dateRange: scopeKind == .customDateRange ? AtlasDateRange(start: customRangeStart, end: customRangeEnd) : nil,
            aliasModeEnabled: aliasModeEnabled
        )
    }

    private var needsProtocolSelection: Bool {
        switch scopeKind {
        case .currentProtocolOnly, .inventoryOnly, .summaryOnly:
            return true
        default:
            return false
        }
    }

    private var needsMultipleProtocolSelection: Bool {
        switch scopeKind {
        case .selectedProtocols, .customDateRange:
            return model.libraryProtocols.isEmpty == false
        default:
            return false
        }
    }

    private func selectionBinding(for protocolID: String) -> Binding<Bool> {
        Binding(
            get: { selectedProtocolIDs.contains(protocolID) },
            set: { isSelected in
                if isSelected {
                    selectedProtocolIDs.insert(protocolID)
                } else {
                    selectedProtocolIDs.remove(protocolID)
                }
            }
        )
    }

    private func applyPreset(_ preset: AtlasProviderHandoffPreset) {
        let fallbackProtocolID = selectedProtocolID ?? model.libraryProtocols.first?.id
        let fallbackProtocolIDs = selectedProtocolIDs.isEmpty
            ? (fallbackProtocolID.map { [$0] } ?? model.libraryProtocols.map(\.id))
            : selectedProtocolIDs.sorted()
        let request = preset.makeRequest(
            protocolID: fallbackProtocolID,
            protocolIDs: fallbackProtocolIDs,
            dateRange: AtlasDateRange(start: customRangeStart, end: customRangeEnd),
            now: model.currentDate()
        )

        scopeKind = request.scopeKind
        selectedProtocolID = request.protocolID ?? fallbackProtocolID
        aliasModeEnabled = request.aliasModeEnabled
        if request.protocolIDs.isEmpty == false {
            selectedProtocolIDs = Set(request.protocolIDs)
        }
        if let dateRange = request.dateRange {
            customRangeStart = dateRange.start
            customRangeEnd = dateRange.end
        }
        preview = nil
        latestResult = nil
    }
}

private struct AtlasGenericCsvMappingFields: View {
    @Binding var mapping: AtlasGenericCsvMapping

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            TextField("Name column", text: $mapping.nameColumn)
                .atlasStandaloneInputSurface()
            TextField("Cadence column", text: $mapping.cadenceColumn)
                .atlasStandaloneInputSurface()
            TextField("Kind column", text: binding(\.kindColumn))
                .atlasStandaloneInputSurface()
            TextField("Weekday column", text: binding(\.weekdayColumn))
                .atlasStandaloneInputSurface()
            TextField("Every-N-days column", text: binding(\.intervalDaysColumn))
                .atlasStandaloneInputSurface()
            TextField("Time column", text: binding(\.timeColumn))
                .atlasStandaloneInputSurface()
            TextField("Dose amount column", text: binding(\.doseAmountColumn))
                .atlasStandaloneInputSurface()
            TextField("Dose unit column", text: binding(\.doseUnitColumn))
                .atlasStandaloneInputSurface()
            TextField("Notes column", text: binding(\.notesColumn))
                .atlasStandaloneInputSurface()
            TextField("Start date column", text: binding(\.startDateColumn))
                .atlasStandaloneInputSurface()
        }
    }

    private func binding(_ keyPath: WritableKeyPath<AtlasGenericCsvMapping, String?>) -> Binding<String> {
        Binding(
            get: { mapping[keyPath: keyPath] ?? "" },
            set: { mapping[keyPath: keyPath] = $0.isEmpty ? nil : $0 }
        )
    }
}

private struct AtlasManualImportOptionsFields: View {
    @Binding var defaultKind: AtlasProtocolKind
    @Binding var timezone: String
    @Binding var anchorDate: Date

    var body: some View {
        Picker("Default kind", selection: $defaultKind) {
            Text("Custom").tag(AtlasProtocolKind.custom)
            Text("GLP").tag(AtlasProtocolKind.glp)
            Text("Peptide").tag(AtlasProtocolKind.peptide)
        }

        TextField("Timezone identifier", text: $timezone)
            .autocorrectionDisabled()
            .atlasStandaloneInputSurface()

        DatePicker("Anchor date", selection: $anchorDate, displayedComponents: .date)
    }
}

@MainActor
private func importCenterHeader(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
        AtlasStatusBadge("Preview-first migration", tint: AtlasPalette.secondaryText)
        Text(title)
            .atlasTextRole(.screenTitle)
            .foregroundStyle(AtlasPalette.textPrimary)
        Text(subtitle)
            .atlasTextRole(.screenSubtitle)
            .foregroundStyle(AtlasPalette.textSecondary)
    }
}

private struct AtlasImportLintGroup: View {
    let items: [AtlasImportLintItem]

    var body: some View {
        if items.isEmpty == false {
            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                Text("Lint findings")
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.primary)

                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                        Text("\(severityLabel(item.severity)): \(item.summary)")
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(severityColor(item.severity))
                        Text(item.detail)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                }
            }
        }
    }

    private func severityLabel(_ severity: AtlasImportLintSeverity) -> String {
        switch severity {
        case .info:
            return "Info"
        case .warning:
            return "Warning"
        case .error:
            return "Needs review"
        }
    }

    private func severityColor(_ severity: AtlasImportLintSeverity) -> Color {
        switch severity {
        case .info:
            return AtlasPalette.primary
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}

private struct AtlasDryRunLineGroup: View {
    let title: String
    let lines: [String]

    var body: some View {
        if lines.isEmpty == false {
            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                Text(title)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.primary)
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
        }
    }
}
