import AtlasDesignSystem
import AtlasDomain
import SwiftUI

public extension AtlasAppModel {
    func refreshTrustVaultSnapshot() async {
        do {
            trustVaultSnapshot = try await dependencies.persistence.trustVault.fetchTrustVaultSnapshot()
            settingsSnapshot = try await dependencies.persistence.settings.currentSettingsSnapshot()
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    func updateTrustVaultProfile(_ update: AtlasTrustVaultProfileUpdate) async {
        do {
            trustVaultSnapshot = try await dependencies.persistence.trustVault.updatePrivacyProfile(update, now: currentDate())
            settingsSnapshot = try await dependencies.persistence.settings.currentSettingsSnapshot()
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    func saveProtocolAlias(_ draft: AtlasProtocolAliasDraft) async {
        do {
            trustVaultSnapshot = try await dependencies.persistence.trustVault.saveProtocolAlias(draft, now: currentDate())
            await refreshShellData()
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    func unlockTrustVaultIfNeeded(reason: String = "Confirm sharing controls") async -> Bool {
        let profile = trustVaultSnapshot.privacyProfile

        guard profile.biometricLockEnabled,
              profile.biometricGateMode != .off else {
            return true
        }

        guard await dependencies.biometrics.isAvailable() else {
            return true
        }

        let granted = await dependencies.biometrics.authorize(reason: reason)
        guard granted else {
            return false
        }

        do {
            try await dependencies.persistence.trustVault.recordVaultUnlock(surface: "trust_vault", now: currentDate())
            trustVaultSnapshot = try await dependencies.persistence.trustVault.fetchTrustVaultSnapshot()
            return true
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return false
        }
    }

    func createRawExport(_ request: AtlasRawExportRequest) async -> AtlasRawExportResult? {
        guard await unlockTrustVaultIfNeeded(reason: "Create a Kairo data export") else {
            return nil
        }

        do {
            let result = try await dependencies.importExport.createRawExport(request, now: currentDate())
            await refreshTrustVaultSnapshot()
            return result
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    func previewSelectiveShare(_ request: AtlasSelectiveShareRequest) async -> AtlasSelectiveSharePreview? {
        guard await unlockTrustVaultIfNeeded(reason: "Preview a share summary") else {
            return nil
        }

        do {
            return try await dependencies.importExport.previewSelectiveShare(request, now: currentDate())
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    func createSelectiveShare(_ request: AtlasSelectiveShareRequest) async -> AtlasSelectiveShareResult? {
        guard await unlockTrustVaultIfNeeded(reason: "Create a selective share") else {
            return nil
        }

        do {
            let result = try await dependencies.importExport.createSelectiveShare(request, now: currentDate())
            await refreshTrustVaultSnapshot()
            return result
        } catch {
            setLoadErrorMessage(error.localizedDescription)
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
    @State private var customRangeStart: Date
    @State private var customRangeEnd: Date

    public init(model: AtlasAppModel) {
        self.model = model
        let referenceDate = model.currentDate()
        _customRangeStart = State(initialValue: Calendar.current.date(byAdding: .day, value: -14, to: referenceDate) ?? referenceDate)
        _customRangeEnd = State(initialValue: referenceDate)
    }

    public var body: some View {
        AtlasScreen {
            AtlasCommandDeck(
                eyebrow: "Privacy controls",
                title: trustVaultDeckTitle,
                detail: trustVaultDeckDetail,
                metrics: trustVaultMetrics,
                style: .hero
            ) {
                VStack(spacing: AtlasSpacing.small) {
                    Button("Preview Share") {
                        AtlasFeedback.selection()
                        previewSelectiveShare()
                    }
                        .buttonStyle(AtlasPrimaryButtonStyle())

                    HStack(spacing: AtlasSpacing.small) {
                        Button("Create Share Summary") {
                            AtlasFeedback.selection()
                            createSelectiveShare()
                        }
                            .buttonStyle(AtlasSecondaryButtonStyle())
                        Button("Share Summary") {
                            AtlasFeedback.selection()
                            model.open(.reviewMode)
                        }
                        .buttonStyle(AtlasSecondaryButtonStyle())
                    }
                }
            } footer: {
                AtlasCalloutRow(
                    systemImage: model.trustVaultSnapshot.privacyProfile.biometricLockEnabled ? "lock.shield.fill" : "eye.slash",
                    title: model.trustVaultSnapshot.privacyProfile.biometricLockEnabled ? "Biometric gate is active" : "Biometric gate is optional",
                    detail: model.dependencies.privacyFormatter.summary(mode: model.trustVaultSnapshot.privacyProfile.renderMode ?? .full),
                    tint: model.trustVaultSnapshot.privacyProfile.biometricLockEnabled ? AtlasPalette.success : AtlasPalette.secondaryText,
                    badge: model.trustVaultSnapshot.privacyProfile.biometricLockEnabled ? "Protected" : "Visible"
                )
            }

            AtlasTrustVaultSignatureCard(model: model)

            if let error = model.loadErrorMessage {
                AtlasSectionCard(style: .utility, title: "Attention") {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            AtlasSectionCard(style: .task, title: "Display & sharing") {
                AtlasMetricStrip(metrics: [
                    AtlasMetricItem(
                        id: "render_mode",
                        title: "Display",
                        value: (model.trustVaultSnapshot.privacyProfile.renderMode ?? .full).rawValue.capitalized
                    ),
                    AtlasMetricItem(
                        id: "sharing_mode",
                        title: "Shares",
                        value: model.trustVaultSnapshot.privacyProfile.shareAliasByDefault ? "Alias" : "Canonical",
                        tint: AtlasPalette.secondaryText
                    ),
                    AtlasMetricItem(
                        id: "export_mode",
                        title: "Exports",
                        value: model.trustVaultSnapshot.privacyProfile.exportAliasByDefault ? "Alias" : "Full",
                        tint: AtlasPalette.secondaryText
                    )
                ])

                AtlasCalloutRow(
                    systemImage: "eye.slash",
                    title: "On-screen display",
                    detail: model.dependencies.privacyFormatter.summary(mode: model.trustVaultSnapshot.privacyProfile.renderMode ?? .full),
                    tint: AtlasPalette.primary
                )

                Picker(
                    "Render mode",
                    selection: Binding(
                        get: { model.trustVaultSnapshot.privacyProfile.renderMode ?? .full },
                        set: { value in
                            AtlasFeedback.selection()
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
                            AtlasFeedback.selection()
                            Task {
                                await model.updateTrustVaultProfile(
                                    AtlasTrustVaultProfileUpdate(shareAliasByDefault: value)
                                )
                            }
                        }
                    )
                )

                Toggle(
                    "Alias by default for data exports",
                    isOn: Binding(
                        get: { model.trustVaultSnapshot.privacyProfile.exportAliasByDefault },
                        set: { value in
                            AtlasFeedback.selection()
                            Task {
                                await model.updateTrustVaultProfile(
                                    AtlasTrustVaultProfileUpdate(exportAliasByDefault: value)
                                )
                            }
                        }
                    )
                )
            }

            AtlasSectionCard(style: .task, title: "Confirm before sharing") {
                AtlasMetricStrip(metrics: [
                    AtlasMetricItem(
                        id: "biometric_status",
                        title: "Gate",
                        value: model.trustVaultSnapshot.privacyProfile.biometricLockEnabled ? "On" : "Off",
                        tint: model.trustVaultSnapshot.privacyProfile.biometricLockEnabled ? AtlasPalette.success : AtlasPalette.secondaryText
                    ),
                    AtlasMetricItem(
                        id: "gate_mode",
                        title: "Mode",
                        value: biometricGateModeLabel(model.trustVaultSnapshot.privacyProfile.biometricGateMode),
                        tint: AtlasPalette.secondaryText
                    )
                ])

                AtlasCalloutRow(
                    systemImage: "lock.shield",
                    title: model.trustVaultSnapshot.privacyProfile.biometricLockEnabled ? "Sensitive actions require confirmation" : "Sensitive actions are ungated",
                    detail: "Exports, previews, and review actions use this device setting.",
                    tint: model.trustVaultSnapshot.privacyProfile.biometricLockEnabled ? AtlasPalette.success : AtlasPalette.secondaryText
                )
                Toggle(
                    "Require confirmation for sharing actions",
                    isOn: Binding(
                        get: { model.trustVaultSnapshot.privacyProfile.biometricLockEnabled },
                        set: { value in
                            AtlasFeedback.selection()
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
                            AtlasFeedback.selection()
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

            AtlasSectionCard(style: .utility, title: "Protocol aliases") {
                AtlasCalloutRow(
                    systemImage: "person.text.rectangle",
                    title: "Alias language is presentation-only",
                    detail: "Canonical labels stay local. Aliases only change what shared views and exports show.",
                    tint: AtlasPalette.secondaryText
                )

                if model.trustVaultSnapshot.aliases.isEmpty {
                    Text("No protocols are available for alias management yet.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(model.trustVaultSnapshot.aliases) { item in
                        Button {
                            AtlasFeedback.selection()
                            selectedAliasItem = item
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                    Text(model.renderedTitle(canonical: item.canonicalTitle, alias: item.aliasLabel))
                                        .atlasTextRole(.cardBody)
                                        .foregroundStyle(AtlasPalette.textPrimary)
                                    Text(item.aliasLabel?.isEmpty == false ? "Codename: \(item.aliasLabel!)" : "No alias set")
                                        .atlasTextRole(.supporting)
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

            AtlasSectionCard(style: .task, title: "Share summary") {
                AtlasCalloutRow(
                    systemImage: "square.and.arrow.up.on.square",
                    title: "Preview before sharing",
                    detail: "Choose the scope and display mode before creating a read-only summary.",
                    tint: AtlasPalette.primary
                )

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

                Picker("Display in summary", selection: $selectiveShareMode) {
                    Text("Full").tag(AtlasPrivacyRenderMode.full)
                    Text("Discreet").tag(AtlasPrivacyRenderMode.discreet)
                    Text("Alias").tag(AtlasPrivacyRenderMode.alias)
                }

                if scopeKind == .customDateRange {
                    DatePicker("Start", selection: $customRangeStart, displayedComponents: .date)
                    DatePicker("End", selection: $customRangeEnd, displayedComponents: .date)
                }

                Button("Preview Summary") {
                    AtlasFeedback.selection()
                    previewSelectiveShare()
                }
                .buttonStyle(AtlasPrimaryButtonStyle())

                Button("Create Share Summary") {
                    AtlasFeedback.selection()
                    createSelectiveShare()
                }
                .buttonStyle(AtlasSecondaryButtonStyle())

                if let preview {
                    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                        AtlasCalloutRow(
                            systemImage: "doc.text.magnifyingglass",
                            title: "Preview ready",
                            detail: preview.summary,
                            tint: AtlasPalette.success
                        )
                        ForEach(preview.sections) { section in
                            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                                Text(section.title)
                                    .atlasTextRole(.deckEyebrow)
                                    .foregroundStyle(AtlasPalette.primary)
                                ForEach(section.lines, id: \.self) { line in
                                    Text(line)
                                        .atlasTextRole(.supporting)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                            }
                        }
                    }
                }

                if let latestShare {
                    AtlasCalloutRow(
                        systemImage: "lock.doc",
                        title: "Share summary ready",
                        detail: "\(latestShare.fileURL.lastPathComponent) • Share code \(latestShare.shareCode)",
                        tint: AtlasPalette.success,
                        badge: "Ready"
                    )
                }
            }

            AtlasSectionCard(style: .utility, title: "Data export") {
                AtlasCalloutRow(
                    systemImage: "arrow.down.doc",
                    title: "Export data when needed",
                    detail: "JSON and CSV exports still respect your default display mode.",
                    tint: AtlasPalette.secondaryText
                )

                Button("Create JSON export") {
                    AtlasFeedback.selection()
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
                    AtlasFeedback.selection()
                    Task {
                        latestExport = await model.createRawExport(
                            AtlasRawExportRequest(
                                format: .csv,
                                renderMode: model.trustVaultSnapshot.privacyProfile.exportAliasByDefault ? .alias : .full
                            )
                        )
                    }
                }
                .buttonStyle(AtlasSecondaryButtonStyle())

                if let latestExport {
                    AtlasMetricStrip(metrics: [
                        AtlasMetricItem(id: "export_rows", title: "Rows", value: "\(latestExport.rowCount)"),
                        AtlasMetricItem(id: "export_mode", title: "Mode", value: latestExport.renderMode.rawValue.capitalized, tint: AtlasPalette.secondaryText)
                    ])

                    Text("Latest \(latestExport.format.rawValue.uppercased()) export: \(latestExport.fileURL.lastPathComponent)")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }

            AtlasProviderHandoffCard(model: model)

            AtlasSectionCard(style: .task, title: "Share summary") {
                AtlasCalloutRow(
                    systemImage: "rectangle.on.rectangle.angled",
                    title: "One clean review summary",
                    detail: "Create a read-only summary for progress or protocol review.",
                    tint: AtlasPalette.primary
                )
                Button("Share Summary") {
                    AtlasFeedback.selection()
                    model.open(.reviewMode)
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
            }

            AtlasSectionCard(style: .utility, title: "Sharing history") {
                if model.trustVaultSnapshot.audits.isEmpty {
                    AtlasCalloutRow(
                        systemImage: "clock.badge.shield.checkmark",
                        title: "History starts when actions happen",
                        detail: "Sharing, export, and privacy changes will appear here.",
                        tint: AtlasPalette.secondaryText
                    )
                } else {
                    ForEach(model.trustVaultSnapshot.audits.prefix(12)) { item in
                        AtlasCalloutRow(
                            systemImage: "shield.lefthalf.filled",
                            title: item.summary,
                            detail: item.createdAt.formatted(date: .abbreviated, time: .shortened),
                            tint: AtlasPalette.secondaryText
                        )
                    }
                }
            }
        }
        .tint(AtlasPalette.primary)
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

    private var trustVaultMetrics: [AtlasMetricItem] {
        [
            AtlasMetricItem(
                id: "aliases",
                title: "Aliases",
                value: "\(model.trustVaultSnapshot.aliases.count)"
            ),
            AtlasMetricItem(
                id: "audits",
                title: "Audit trail",
                value: "\(model.trustVaultSnapshot.audits.count)",
                tint: AtlasPalette.secondaryText
            ),
            AtlasMetricItem(
                id: "gate",
                title: "Gate",
                value: model.trustVaultSnapshot.privacyProfile.biometricLockEnabled ? "On" : "Off",
                tint: model.trustVaultSnapshot.privacyProfile.biometricLockEnabled ? AtlasPalette.success : AtlasPalette.secondaryText
            )
        ]
    }

    private var trustVaultDeckTitle: String {
        if preview != nil || latestShare != nil {
            return "Preview before you share."
        }
        return "Control what leaves Kairo."
    }

    private var trustVaultDeckDetail: String {
        if latestShare != nil {
            return "A share summary is ready. Share code and history are visible."
        }
        if preview != nil {
            return "The current preview uses the selected scope, display mode, and date range."
        }
        return "Set display defaults, aliases, sharing confirmation, exports, and history without making privacy the headline."
    }

    private func previewSelectiveShare() {
        AtlasFeedback.selection()
        Task {
            preview = await model.previewSelectiveShare(selectiveShareRequest)
        }
    }

    private func createSelectiveShare() {
        AtlasFeedback.impact(.medium)
        Task {
            latestShare = await model.createSelectiveShare(selectiveShareRequest)
        }
    }

    private func biometricGateModeLabel(_ mode: AtlasBiometricGateMode) -> String {
        switch mode {
        case .off:
            return "Off"
        case .bestEffort:
            return "Best effort"
        case .requiredWhenAvailable:
            return "Required"
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
            AtlasScreen {
                AtlasCommandDeck(
                    eyebrow: "Alias editor",
                    title: model.renderedTitle(canonical: item.canonicalTitle, alias: item.aliasLabel),
                    detail: "Aliases only change presentation. Canonical labels stay stored locally.",
                    metrics: [
                        AtlasMetricItem(id: "display", title: "Display", value: item.aliasLabel == nil ? "Canonical" : "Aliased", tint: AtlasPalette.secondaryText)
                    ],
                    tint: AtlasPalette.secondaryText,
                    style: .hero
                ) { } footer: { }

                AtlasSectionCard(style: .utility, title: "Protocol") {
                    Text("Codename is presentation only. Canonical labels remain stored locally.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                AtlasSectionCard(title: "Alias") {
                    TextField("Codename", text: $aliasLabel)
                        .atlasStandaloneInputSurface()
                    TextField("Compound codename", text: $aliasCompoundLabel)
                        .atlasStandaloneInputSurface()
                }

                AtlasSectionCard(style: .utility, title: "Commit") {
                    Button("Save") {
                        AtlasFeedback.selection()
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
                    .buttonStyle(AtlasPrimaryButtonStyle())

                    Button("Cancel") {
                        AtlasFeedback.selection()
                        dismiss()
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
            .navigationTitle("Alias")
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

@MainActor
private func header(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
        AtlasStatusBadge("Private controls", tint: AtlasPalette.secondaryText)
        Text(title)
            .atlasTextRole(.screenTitle)
            .foregroundStyle(AtlasPalette.textPrimary)
        Text(subtitle)
            .atlasTextRole(.screenSubtitle)
            .foregroundStyle(AtlasPalette.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
