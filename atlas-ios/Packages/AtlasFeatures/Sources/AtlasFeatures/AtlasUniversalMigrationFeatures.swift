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
            loadErrorMessage = error.localizedDescription
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
            loadErrorMessage = error.localizedDescription
            return nil
        }
    }

    func cancelUniversalImport(_ prepared: AtlasUniversalPreparedImport) async {
        await dependencies.importExport.cancelUniversalImport(prepared)
    }

    func previewProviderHandoff(
        _ request: AtlasProviderHandoffRequest
    ) async -> AtlasProviderHandoffPreview? {
        guard await unlockTrustVaultIfNeeded(reason: "Preview provider handoff") else {
            return nil
        }

        do {
            return try await dependencies.importExport.previewProviderHandoff(request, now: Date())
        } catch {
            loadErrorMessage = error.localizedDescription
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
            let result = try await dependencies.importExport.createProviderHandoff(request, now: Date())
            await refreshTrustVaultSnapshot()
            return result
        } catch {
            loadErrorMessage = error.localizedDescription
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
    @State private var prepared: AtlasUniversalPreparedImport?
    @State private var lastCommit: AtlasImportCommitResult?

    var body: some View {
        AtlasScreen {
            importCenterHeader("Import Center", subtitle: "Review Atlas JSON first, then Atlas CSV, mapped generic CSV, or simple manual text before you commit anything locally.")

            if let error = model.loadErrorMessage {
                AtlasSectionCard {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            AtlasSectionCard(title: "Importer") {
                Picker("Source", selection: $selectedImporter) {
                    ForEach(model.importerDescriptors()) { descriptor in
                        Text(descriptor.title).tag(descriptor.kind)
                    }
                }

                let descriptor = model.importerDescriptors().first(where: { $0.kind == selectedImporter })
                if let descriptor {
                    Text(descriptor.subtitle)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    if descriptor.isCanonical {
                        Text("Recommended migration path")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AtlasPalette.primary)
                    }
                }
            }

            AtlasSectionCard(title: "Source input") {
                if selectedImporter == .atlasJSON {
                    TextField("Absolute path to Atlas JSON export", text: $filePath)
                } else {
                    TextEditor(text: $rawText)
                        .frame(minHeight: 180)
                        .font(.system(.body, design: .monospaced))
                }

                if selectedImporter == .genericCSV {
                    AtlasGenericCsvMappingFields(mapping: $genericMapping)
                }

                if selectedImporter == .manualText {
                    Picker("Default kind", selection: $defaultKind) {
                        Text("Custom").tag(AtlasProtocolKind.custom)
                        Text("GLP").tag(AtlasProtocolKind.glp)
                        Text("Peptide").tag(AtlasProtocolKind.peptide)
                    }
                }

                Button("Preview import") {
                    Task {
                        prepared = await model.prepareUniversalImport(importRequest)
                    }
                }
                .buttonStyle(AtlasPrimaryButtonStyle())

                if let prepared {
                    Button("Replace local data with this import") {
                        Task {
                            lastCommit = await model.commitUniversalImport(prepared)
                        }
                    }
                    .buttonStyle(.bordered)

                    Button("Cancel preview") {
                        Task {
                            await model.cancelUniversalImport(prepared)
                            self.prepared = nil
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if let prepared {
                AtlasSectionCard(title: "Dry-run preview") {
                    Text(prepared.dryRun.sourceSummary)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Text("Create: \(prepared.dryRun.recordsToCreate) • Update: \(prepared.dryRun.recordsToUpdate)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.primary)

                    AtlasDryRunLineGroup(title: "Datasets", lines: prepared.dryRun.datasetDiffs.map {
                        "\($0.dataset): +\($0.creates) / ~\($0.updates)"
                    })
                    AtlasDryRunLineGroup(title: "Warnings", lines: prepared.dryRun.warnings)
                    AtlasDryRunLineGroup(title: "Conflicts", lines: prepared.dryRun.conflicts)
                    AtlasDryRunLineGroup(title: "Unsupported rows", lines: prepared.dryRun.unsupportedRows)
                    AtlasDryRunLineGroup(title: "Privacy notes", lines: prepared.dryRun.privacyNotes)
                    AtlasDryRunLineGroup(title: "Backfill notes", lines: prepared.dryRun.backfillNotes)
                }
            }

            if let lastCommit {
                AtlasSectionCard(title: "Last import") {
                    Text("Protocols imported: \(lastCommit.importedProtocolCount)")
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Text("History rows imported: \(lastCommit.importedLogEventCount)")
                        .foregroundStyle(AtlasPalette.textSecondary)
                    if let backupURL = lastCommit.backupURL {
                        Text("Backup created: \(backupURL.lastPathComponent)")
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                    if let nextDue = lastCommit.nextDue {
                        Text("Next due now surfaces as \(nextDue.displayTitle)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AtlasPalette.primary)
                    }
                }
            }
        }
        .navigationTitle("Import Center")
    }

    private var importRequest: AtlasUniversalImportRequest {
        AtlasUniversalImportRequest(
            importer: selectedImporter,
            fileURL: selectedImporter == .atlasJSON && filePath.isEmpty == false ? URL(fileURLWithPath: filePath) : nil,
            rawText: selectedImporter == .atlasJSON ? nil : rawText,
            genericCsvMapping: selectedImporter == .genericCSV ? genericMapping : nil,
            manualOptions: AtlasManualImportOptions(defaultKind: defaultKind)
        )
    }
}

struct AtlasProviderHandoffCard: View {
    let model: AtlasAppModel
    @State private var scopeKind: AtlasProviderHandoffScopeKind = .summaryOnly
    @State private var aliasModeEnabled = true
    @State private var selectedProtocolID: String?
    @State private var selectedProtocolIDs: Set<String> = []
    @State private var customRangeStart: Date = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
    @State private var customRangeEnd: Date = Date()
    @State private var preview: AtlasProviderHandoffPreview?
    @State private var latestResult: AtlasProviderHandoffResult?

    var body: some View {
        AtlasSectionCard(title: "Provider handoff") {
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
                        .font(.caption.weight(.semibold))
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
                ForEach(preview.sections) { section in
                    AtlasDryRunLineGroup(title: section.title, lines: section.lines)
                }
            }

            if let latestResult {
                Text("Summary ready at \(latestResult.summaryURL.lastPathComponent)")
                    .foregroundStyle(AtlasPalette.textSecondary)
                Text("Attachment ready at \(latestResult.attachmentURL.lastPathComponent)")
                    .font(.caption)
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
}

private struct AtlasGenericCsvMappingFields: View {
    @Binding var mapping: AtlasGenericCsvMapping

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            TextField("Name column", text: $mapping.nameColumn)
            TextField("Cadence column", text: $mapping.cadenceColumn)
            TextField("Kind column", text: binding(\.kindColumn))
            TextField("Weekday column", text: binding(\.weekdayColumn))
            TextField("Every-N-days column", text: binding(\.intervalDaysColumn))
            TextField("Time column", text: binding(\.timeColumn))
            TextField("Dose amount column", text: binding(\.doseAmountColumn))
            TextField("Dose unit column", text: binding(\.doseUnitColumn))
            TextField("Notes column", text: binding(\.notesColumn))
            TextField("Start date column", text: binding(\.startDateColumn))
        }
    }

    private func binding(_ keyPath: WritableKeyPath<AtlasGenericCsvMapping, String?>) -> Binding<String> {
        Binding(
            get: { mapping[keyPath: keyPath] ?? "" },
            set: { mapping[keyPath: keyPath] = $0.isEmpty ? nil : $0 }
        )
    }
}

private func importCenterHeader(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
        Text(title)
            .font(.largeTitle.weight(.semibold))
            .foregroundStyle(AtlasPalette.textPrimary)
        Text(subtitle)
            .foregroundStyle(AtlasPalette.textSecondary)
    }
}

private struct AtlasDryRunLineGroup: View {
    let title: String
    let lines: [String]

    var body: some View {
        if lines.isEmpty == false {
            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasPalette.primary)
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
        }
    }
}
