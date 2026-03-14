import AtlasDesignSystem
import AtlasDomain
import SwiftUI

public extension AtlasAppModel {
    func refreshTrustVaultSnapshot() async {
        do {
            trustVaultSnapshot = try await dependencies.persistence.trustVault.fetchTrustVaultSnapshot()
            settingsSnapshot = try await dependencies.persistence.settings.currentSettingsSnapshot()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    func updateTrustVaultProfile(_ update: AtlasTrustVaultProfileUpdate) async {
        do {
            trustVaultSnapshot = try await dependencies.persistence.trustVault.updatePrivacyProfile(update, now: Date())
            settingsSnapshot = try await dependencies.persistence.settings.currentSettingsSnapshot()
            await refreshShellData()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    func saveProtocolAlias(_ draft: AtlasProtocolAliasDraft) async {
        do {
            trustVaultSnapshot = try await dependencies.persistence.trustVault.saveProtocolAlias(draft, now: Date())
            await refreshShellData()
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    func unlockTrustVaultIfNeeded(reason: String = "Unlock Trust Vault") async -> Bool {
        guard trustVaultSnapshot.privacyProfile.biometricLockEnabled else {
            return true
        }

        let granted = await dependencies.biometrics.authorize(reason: reason)
        guard granted else {
            return false
        }

        do {
            try await dependencies.persistence.trustVault.recordVaultUnlock(surface: "trust_vault", now: Date())
            trustVaultSnapshot = try await dependencies.persistence.trustVault.fetchTrustVaultSnapshot()
            return true
        } catch {
            loadErrorMessage = error.localizedDescription
            return false
        }
    }

    func createRawExport(_ request: AtlasRawExportRequest) async -> AtlasRawExportResult? {
        guard await unlockTrustVaultIfNeeded(reason: "Authorize Atlas export") else {
            return nil
        }

        do {
            let result = try await dependencies.importExport.createRawExport(request, now: Date())
            await refreshTrustVaultSnapshot()
            return result
        } catch {
            loadErrorMessage = error.localizedDescription
            return nil
        }
    }

    func previewSelectiveShare(_ request: AtlasSelectiveShareRequest) async -> AtlasSelectiveSharePreview? {
        guard await unlockTrustVaultIfNeeded(reason: "Preview a selective share") else {
            return nil
        }

        do {
            return try await dependencies.importExport.previewSelectiveShare(request, now: Date())
        } catch {
            loadErrorMessage = error.localizedDescription
            return nil
        }
    }

    func createSelectiveShare(_ request: AtlasSelectiveShareRequest) async -> AtlasSelectiveShareResult? {
        guard await unlockTrustVaultIfNeeded(reason: "Create a selective share") else {
            return nil
        }

        do {
            let result = try await dependencies.importExport.createSelectiveShare(request, now: Date())
            await refreshTrustVaultSnapshot()
            return result
        } catch {
            loadErrorMessage = error.localizedDescription
            return nil
        }
    }
}

public struct AtlasTrustVaultHomeScreen: View {
    let model: AtlasAppModel
    @State private var selectedAliasItem: AtlasTrustVaultAliasItem?
    @State private var latestExport: AtlasRawExportResult?
    @State private var latestShare: AtlasSelectiveShareResult?
    @State private var preview: AtlasSelectiveSharePreview?
    @State private var scopeKind: AtlasSelectiveShareScopeKind = .currentProtocolOnly
    @State private var selectedProtocolID: String?
    @State private var selectiveShareMode: AtlasPrivacyRenderMode = .alias
    @State private var customRangeStart: Date = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
    @State private var customRangeEnd: Date = Date()

    public var body: some View {
        AtlasScreen {
            header("Trust Vault", subtitle: "Privacy mode, bounded sharing, raw exports, and sensitive-action history now live natively.")

            if let error = model.loadErrorMessage {
                AtlasSectionCard {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            AtlasSectionCard(title: "Privacy state") {
                Text(model.dependencies.privacyFormatter.summary(mode: model.trustVaultSnapshot.privacyProfile.renderMode ?? .full))
                    .foregroundStyle(AtlasPalette.textSecondary)

                Picker(
                    "Render mode",
                    selection: Binding(
                        get: { model.trustVaultSnapshot.privacyProfile.renderMode ?? .full },
                        set: { value in
                            Task {
                                await model.updateTrustVaultProfile(
                                    AtlasTrustVaultProfileUpdate(renderMode: value)
                                )
                            }
                        }
                    )
                ) {
                    Text("Full").tag(AtlasPrivacyRenderMode.full)
                    Text("Discreet").tag(AtlasPrivacyRenderMode.discreet)
                    Text("Alias").tag(AtlasPrivacyRenderMode.alias)
                }

                Toggle(
                    "Alias by default for shares",
                    isOn: Binding(
                        get: { model.trustVaultSnapshot.privacyProfile.shareAliasByDefault },
                        set: { value in
                            Task {
                                await model.updateTrustVaultProfile(
                                    AtlasTrustVaultProfileUpdate(shareAliasByDefault: value)
                                )
                            }
                        }
                    )
                )

                Toggle(
                    "Alias by default for raw exports",
                    isOn: Binding(
                        get: { model.trustVaultSnapshot.privacyProfile.exportAliasByDefault },
                        set: { value in
                            Task {
                                await model.updateTrustVaultProfile(
                                    AtlasTrustVaultProfileUpdate(exportAliasByDefault: value)
                                )
                            }
                        }
                    )
                )
            }

            AtlasSectionCard(title: "Biometric gate") {
                Toggle(
                    "Require biometric gate for Trust Vault actions",
                    isOn: Binding(
                        get: { model.trustVaultSnapshot.privacyProfile.biometricLockEnabled },
                        set: { value in
                            Task {
                                await model.updateTrustVaultProfile(
                                    AtlasTrustVaultProfileUpdate(
                                        biometricLockEnabled: value,
                                        biometricGateMode: value ? .requiredWhenAvailable : .off
                                    )
                                )
                            }
                        }
                    )
                )

                Picker(
                    "Gate mode",
                    selection: Binding(
                        get: { model.trustVaultSnapshot.privacyProfile.biometricGateMode },
                        set: { value in
                            Task {
                                await model.updateTrustVaultProfile(
                                    AtlasTrustVaultProfileUpdate(biometricGateMode: value)
                                )
                            }
                        }
                    )
                ) {
                    Text("Off").tag(AtlasBiometricGateMode.off)
                    Text("Best effort").tag(AtlasBiometricGateMode.bestEffort)
                    Text("Required when available").tag(AtlasBiometricGateMode.requiredWhenAvailable)
                }
            }

            AtlasSectionCard(title: "Aliases") {
                if model.trustVaultSnapshot.aliases.isEmpty {
                    Text("No protocols are available for alias management yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(model.trustVaultSnapshot.aliases) { item in
                        Button {
                            selectedAliasItem = item
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    Text(model.renderedTitle(canonical: item.canonicalTitle, alias: item.aliasLabel))
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                    Text(item.aliasLabel?.isEmpty == false ? "Codename: \(item.aliasLabel!)" : "No alias set")
                                        .font(.caption)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            AtlasSectionCard(title: "Selective sharing") {
                Picker("Scope", selection: $scopeKind) {
                    Text("Current protocol").tag(AtlasSelectiveShareScopeKind.currentProtocolOnly)
                    Text("Protocol + timeline").tag(AtlasSelectiveShareScopeKind.protocolWithRecentTimeline)
                    Text("Last 30 days logs").tag(AtlasSelectiveShareScopeKind.last30DaysLogs)
                    Text("Symptoms only").tag(AtlasSelectiveShareScopeKind.symptomsOnly)
                    Text("Inventory only").tag(AtlasSelectiveShareScopeKind.inventoryOnly)
                    Text("Summary only").tag(AtlasSelectiveShareScopeKind.summaryOnly)
                    Text("Custom date range").tag(AtlasSelectiveShareScopeKind.customDateRange)
                }

                if needsProtocolSelection(scopeKind) {
                    Picker("Protocol", selection: $selectedProtocolID) {
                        Text("Select a protocol").tag(String?.none)
                        ForEach(model.trustVaultSnapshot.aliases) { item in
                            Text(model.renderedTitle(canonical: item.canonicalTitle, alias: item.aliasLabel))
                                .tag(String?.some(item.protocolID))
                        }
                    }
                }

                Picker("Share render mode", selection: $selectiveShareMode) {
                    Text("Full").tag(AtlasPrivacyRenderMode.full)
                    Text("Discreet").tag(AtlasPrivacyRenderMode.discreet)
                    Text("Alias").tag(AtlasPrivacyRenderMode.alias)
                }

                if scopeKind == .customDateRange {
                    DatePicker("Start", selection: $customRangeStart, displayedComponents: .date)
                    DatePicker("End", selection: $customRangeEnd, displayedComponents: .date)
                }

                Button("Preview share") {
                    Task {
                        preview = await model.previewSelectiveShare(selectiveShareRequest)
                    }
                }
                .buttonStyle(AtlasPrimaryButtonStyle())

                Button("Create encrypted snapshot") {
                    Task {
                        latestShare = await model.createSelectiveShare(selectiveShareRequest)
                    }
                }
                .buttonStyle(.bordered)

                if let preview {
                    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                        Text(preview.summary)
                            .foregroundStyle(AtlasPalette.textSecondary)
                        ForEach(preview.sections) { section in
                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                Text(section.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AtlasPalette.primary)
                                ForEach(section.lines, id: \.self) { line in
                                    Text(line)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                            }
                        }
                    }
                }

                if let latestShare {
                    Text("Encrypted snapshot ready at \(latestShare.fileURL.lastPathComponent)")
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Text("Share code: \(latestShare.shareCode)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.primary)
                }
            }

            AtlasSectionCard(title: "Raw exports") {
                Button("Create JSON export") {
                    Task {
                        latestExport = await model.createRawExport(
                            AtlasRawExportRequest(
                                format: .json,
                                renderMode: model.trustVaultSnapshot.privacyProfile.exportAliasByDefault ? .alias : .full
                            )
                        )
                    }
                }
                .buttonStyle(AtlasPrimaryButtonStyle())

                Button("Create CSV export") {
                    Task {
                        latestExport = await model.createRawExport(
                            AtlasRawExportRequest(
                                format: .csv,
                                renderMode: model.trustVaultSnapshot.privacyProfile.exportAliasByDefault ? .alias : .full
                            )
                        )
                    }
                }
                .buttonStyle(.bordered)

                if let latestExport {
                    Text("Latest \(latestExport.format.rawValue.uppercased()) export: \(latestExport.fileURL.lastPathComponent)")
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Text("Rows: \(latestExport.rowCount) • mode: \(latestExport.renderMode.rawValue)")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }

            AtlasProviderHandoffCard(model: model)

            AtlasSectionCard(title: "Review workspace") {
                Text("Create bounded read-only review packs without opening a social or chat surface.")
                    .foregroundStyle(AtlasPalette.textSecondary)
                Button("Open Review Mode") {
                    model.open(.reviewMode)
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
            }

            AtlasSectionCard(title: "Sensitive action audit") {
                if model.trustVaultSnapshot.audits.isEmpty {
                    Text("Sensitive actions will appear here as you change privacy settings, export, or share.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(model.trustVaultSnapshot.audits.prefix(12)) { item in
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            Text(item.summary)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AtlasPalette.textPrimary)
                            Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Trust Vault")
        .trustVaultInlineNavigationTitle()
        .task {
            await model.refreshTrustVaultSnapshot()
            if selectedProtocolID == nil {
                selectedProtocolID = model.trustVaultSnapshot.aliases.first?.protocolID
            }
            _ = await model.unlockTrustVaultIfNeeded()
        }
        .sheet(item: $selectedAliasItem) { item in
            AtlasAliasEditorSheet(item: item, model: model)
        }
    }

    private var selectiveShareRequest: AtlasSelectiveShareRequest {
        AtlasSelectiveShareRequest(
            scopeKind: scopeKind,
            renderMode: selectiveShareMode,
            protocolID: selectedProtocolID,
            protocolIDs: scopeKind == .customDateRange ? model.libraryProtocols.map(\.id) : [],
            dateRange: scopeKind == .customDateRange ? AtlasDateRange(start: customRangeStart, end: customRangeEnd) : nil,
            include: scopeKind == .customDateRange ? [.logs, .symptoms, .inventory, .summary] : []
        )
    }

    private func needsProtocolSelection(_ scope: AtlasSelectiveShareScopeKind) -> Bool {
        switch scope {
        case .currentProtocolOnly, .protocolWithRecentTimeline:
            return true
        default:
            return false
        }
    }
}

private struct AtlasAliasEditorSheet: View {
    let item: AtlasTrustVaultAliasItem
    let model: AtlasAppModel
    @State private var aliasLabel: String
    @State private var aliasCompoundLabel: String
    @Environment(\.dismiss) private var dismiss

    init(item: AtlasTrustVaultAliasItem, model: AtlasAppModel) {
        self.item = item
        self.model = model
        _aliasLabel = State(initialValue: item.aliasLabel ?? "")
        _aliasCompoundLabel = State(initialValue: item.aliasCompoundLabel ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Protocol") {
                    Text(model.renderedTitle(canonical: item.canonicalTitle, alias: item.aliasLabel))
                    Text("Codename is presentation only. Canonical labels remain stored locally.")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                Section("Alias") {
                    TextField("Codename", text: $aliasLabel)
                    TextField("Compound codename", text: $aliasCompoundLabel)
                }
            }
            .navigationTitle("Alias")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await model.saveProtocolAlias(
                                AtlasProtocolAliasDraft(
                                    protocolID: item.protocolID,
                                    aliasLabel: aliasLabel,
                                    aliasCompoundLabel: aliasCompoundLabel.isEmpty ? nil : aliasCompoundLabel
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

private extension View {
    @ViewBuilder
    func trustVaultInlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

private func header(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
        Text(title)
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .foregroundStyle(AtlasPalette.textPrimary)
        Text(subtitle)
            .font(.body)
            .foregroundStyle(AtlasPalette.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
