import AtlasDesignSystem
import AtlasDomain
import SwiftUI

public extension AtlasAppModel {
    func refreshReviewMode() async {
        do {
            reviewOwnerSnapshot = decorateReviewOwnerSnapshot(
                try await dependencies.persistence.reviewMode.fetchOwnerSnapshot(now: currentDate())
            )
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    func createReview(_ request: AtlasReviewRequest) async -> AtlasReviewCreationResult? {
        if request.deliveryKind == .liveSession {
            guard dependencies.cloudSync.isConfigured() else {
                setLoadErrorMessage("Live review sessions need cloud configuration in this build.")
                return nil
            }
            guard cloudSession != nil else {
                setLoadErrorMessage("Sign in to Atlas cloud sync before creating a live review session.")
                return nil
            }
        }

        let reason = request.deliveryKind == .liveSession ? "Create a live review session" : "Create a review pack"
        guard await unlockTrustVaultIfNeeded(reason: reason) else {
            return nil
        }

        do {
            let now = currentDate()
            let result = try await dependencies.persistence.reviewMode.createReview(request, now: now)
            let decoratedResult: AtlasReviewCreationResult
            if request.deliveryKind == .liveSession {
                let remoteSession = try await dependencies.cloudSync.createLiveReviewSession(
                    title: result.session.title,
                    request: request,
                    workspace: result.workspace
                )
                AtlasLiveReviewSessionStore.save(
                    localID: result.session.id,
                    remoteID: remoteSession.id,
                    shareURL: remoteSession.shareURL,
                    expiresAt: remoteSession.expiresAt
                )
                decoratedResult = decorateReviewCreationResult(result)
            } else {
                decoratedResult = result
            }
            reviewOwnerSnapshot = decorateReviewOwnerSnapshot(
                try await dependencies.persistence.reviewMode.fetchOwnerSnapshot(now: now)
            )
            await refreshTrustVaultSnapshot()
            reviewWorkspace = decoratedResult.workspace
            return decoratedResult
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    func loadReviewWorkspace(from fileURL: URL) async -> AtlasReviewWorkspace? {
        do {
            let workspace = try await dependencies.persistence.reviewMode.loadWorkspace(from: fileURL, now: currentDate())
            reviewWorkspace = workspace
            return workspace
        } catch {
            setLoadErrorMessage(error.localizedDescription)
            return nil
        }
    }

    func revokeReviewSession(id: String) async {
        do {
            if let remoteSession = AtlasLiveReviewSessionStore.record(localID: id) {
                try await dependencies.cloudSync.revokeLiveReviewSession(id: remoteSession.remoteID)
                AtlasLiveReviewSessionStore.remove(localID: id)
            }
            reviewOwnerSnapshot = decorateReviewOwnerSnapshot(
                try await dependencies.persistence.reviewMode.revokeReviewSession(id: id, now: currentDate())
            )
        } catch {
            setLoadErrorMessage(error.localizedDescription)
        }
    }

    func decorateReviewOwnerSnapshot(_ snapshot: AtlasReviewOwnerSnapshot) -> AtlasReviewOwnerSnapshot {
        AtlasReviewOwnerSnapshot(
            sessions: snapshot.sessions.map { session in
                guard let remoteSession = AtlasLiveReviewSessionStore.record(localID: session.id) else {
                    return session
                }
                return AtlasReviewSessionSummary(
                    id: session.id,
                    title: session.title,
                    scopeKind: session.scopeKind,
                    deliveryKind: session.deliveryKind,
                    renderMode: session.renderMode,
                    rowCount: session.rowCount,
                    createdAt: session.createdAt,
                    expiresAt: remoteSession.expiresAt ?? session.expiresAt,
                    status: session.status,
                    canRevoke: session.canRevoke,
                    summaryURL: session.summaryURL,
                    packURL: remoteSession.shareURL,
                    summary: session.summary
                )
            },
            liveReviewEnabled: snapshot.liveReviewEnabled
        )
    }

    func decorateReviewCreationResult(_ result: AtlasReviewCreationResult) -> AtlasReviewCreationResult {
        guard let remoteSession = AtlasLiveReviewSessionStore.record(localID: result.session.id) else {
            return result
        }
        return AtlasReviewCreationResult(
            session: AtlasReviewSessionSummary(
                id: result.session.id,
                title: result.session.title,
                scopeKind: result.session.scopeKind,
                deliveryKind: result.session.deliveryKind,
                renderMode: result.session.renderMode,
                rowCount: result.session.rowCount,
                createdAt: result.session.createdAt,
                expiresAt: remoteSession.expiresAt ?? result.session.expiresAt,
                status: result.session.status,
                canRevoke: result.session.canRevoke,
                summaryURL: result.session.summaryURL,
                packURL: remoteSession.shareURL,
                summary: result.session.summary
            ),
            workspace: result.workspace,
            summaryURL: result.summaryURL,
            packURL: remoteSession.shareURL,
            manifestVersion: result.manifestVersion
        )
    }
}

private enum AtlasLiveReviewSessionStore {
    private static let storageKey = "atlas.liveReview.remoteSessions"

    struct Record: Codable {
        var localID: String
        var remoteID: String
        var shareURL: URL
        var expiresAt: Date?
    }

    static func record(localID: String) -> Record? {
        records()[localID]
    }

    static func save(localID: String, remoteID: String, shareURL: URL, expiresAt: Date?) {
        var current = records()
        current[localID] = Record(
            localID: localID,
            remoteID: remoteID,
            shareURL: shareURL,
            expiresAt: expiresAt
        )
        persist(current)
    }

    static func remove(localID: String) {
        var current = records()
        current.removeValue(forKey: localID)
        persist(current)
    }

    private static func records() -> [String: Record] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: Record].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private static func persist(_ records: [String: Record]) {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

public struct AtlasReviewModeHomeScreen: View {
    let model: AtlasAppModel

    @State private var selectedPreset: AtlasReviewPreset = .clinicianSummary
    @State private var scopeKind: AtlasReviewScopeKind = .summaryOnly
    @State private var selectedProtocolID: String?
    @State private var selectedProtocolIDs: Set<String> = []
    @State private var aliasModeEnabled = true
    @State private var includeExpiration = false
    @State private var expiresAt: Date
    @State private var deliveryKind: AtlasReviewDeliveryKind = .staticPack
    @State private var customRangeStart: Date
    @State private var customRangeEnd: Date
    @State private var latestResult: AtlasReviewCreationResult?
    @State private var reviewPackPath = ""

    public init(model: AtlasAppModel) {
        self.model = model
        let referenceDate = model.currentDate()
        _expiresAt = State(initialValue: Calendar.current.date(byAdding: .day, value: 14, to: referenceDate) ?? referenceDate)
        _customRangeStart = State(initialValue: Calendar.current.date(byAdding: .day, value: -14, to: referenceDate) ?? referenceDate)
        _customRangeEnd = State(initialValue: referenceDate)
    }

    public var body: some View {
        AtlasScreen {
            reviewHeader(
                "Review Mode",
                subtitle: "Create a read-only review snapshot."
            )

            if let error = model.loadErrorMessage {
                AtlasSectionCard {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            AtlasSectionCard(style: .elevated, title: "Create review") {
                HStack(spacing: AtlasSpacing.small) {
                    AtlasStatusBadge(selectedPreset.title)
                    AtlasStatusBadge(deliveryKind == .liveSession ? "Live session" : "Static pack", tint: AtlasPalette.secondaryText)
                }
                Picker("Preset", selection: $selectedPreset) {
                    ForEach(AtlasReviewPreset.allCases) { preset in
                        Text(preset.title).tag(preset)
                    }
                }

                Text(selectedPreset.subtitle)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                HStack(spacing: AtlasSpacing.small) {
                    Button("Apply preset") {
                        applyPreset(selectedPreset)
                    }
                    .buttonStyle(AtlasTertiaryButtonStyle())

                    if deliveryKind == .liveSession {
                        AtlasStatusBadge(
                            model.canCreateLiveReviewSession ? "Cloud ready" : "Sign-in required",
                            tint: model.canCreateLiveReviewSession ? AtlasPalette.success : AtlasPalette.warning
                        )
                    }
                }

                Picker("Scope", selection: $scopeKind) {
                    Text("Current protocol").tag(AtlasReviewScopeKind.currentProtocol)
                    Text("Selected protocols").tag(AtlasReviewScopeKind.selectedProtocols)
                    Text("Last 30 days").tag(AtlasReviewScopeKind.last30Days)
                    Text("Symptoms only").tag(AtlasReviewScopeKind.symptomsOnly)
                    Text("Inventory only").tag(AtlasReviewScopeKind.inventoryOnly)
                    Text("Summary only").tag(AtlasReviewScopeKind.summaryOnly)
                    Text("Custom date range").tag(AtlasReviewScopeKind.customDateRange)
                }

                if needsSingleProtocolSelection {
                    Picker("Protocol", selection: $selectedProtocolID) {
                        Text("Select a protocol").tag(String?.none)
                        ForEach(model.libraryProtocols) { summary in
                            Text(model.renderedTitle(canonical: summary.canonicalTitle, alias: summary.aliasTitle))
                                .tag(String?.some(summary.id))
                        }
                    }
                }

                if needsMultipleProtocolSelection {
                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                        Text("Protocols")
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.primary)

                        ForEach(model.libraryProtocols) { summary in
                            Toggle(
                                model.renderedTitle(canonical: summary.canonicalTitle, alias: summary.aliasTitle),
                                isOn: selectionBinding(for: summary.id)
                            )
                        }
                    }
                }

                Toggle("Alias mode", isOn: $aliasModeEnabled)
                Toggle("Add expiration", isOn: $includeExpiration)

                if includeExpiration {
                    DatePicker("Expires", selection: $expiresAt, displayedComponents: [.date, .hourAndMinute])
                }

                Picker("Delivery", selection: $deliveryKind) {
                    Text("Static review pack").tag(AtlasReviewDeliveryKind.staticPack)
                    Text("Live review session").tag(AtlasReviewDeliveryKind.liveSession)
                }
                if deliveryKind == .liveSession {
                    Text(model.canCreateLiveReviewSession
                        ? "Live sessions are cloud-backed and revocable."
                        : "Sign in to Atlas cloud sync before creating a live review session.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                if scopeKind == .customDateRange {
                    DatePicker("Start", selection: $customRangeStart, displayedComponents: .date)
                    DatePicker("End", selection: $customRangeEnd, displayedComponents: .date)
                }

                Button("Create read-only review") {
                    Task {
                        latestResult = await model.createReview(reviewRequest)
                        if let packURL = latestResult?.packURL {
                            reviewPackPath = packURL.isFileURL ? packURL.path : packURL.absoluteString
                        }
                    }
                }
                .buttonStyle(AtlasPrimaryButtonStyle())
                .disabled(deliveryKind == .liveSession && model.canCreateLiveReviewSession == false)

                Text("Static review packs cannot be revoked after delivery.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            if let latestResult {
                AtlasSectionCard(title: "Latest review pack") {
                    Text(latestResult.workspace.summary)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    if latestResult.session.deliveryKind == .liveSession {
                        Text("Session link ready")
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.primary)
                        Text(latestResult.packURL.absoluteString)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .textSelection(.enabled)
                    } else {
                        Text("Pack: \(latestResult.packURL.lastPathComponent)")
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.primary)
                    }
                    Text("Summary: \(latestResult.summaryURL.lastPathComponent)")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }

            AtlasSectionCard(style: .utility, title: "Owner review management") {
                if model.reviewOwnerSnapshot.sessions.isEmpty {
                    Text("No review packs created yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(model.reviewOwnerSnapshot.sessions) { session in
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            HStack {
                                Text(session.title)
                                    .atlasTextRole(.cardBody)
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Spacer()
                                Text(session.status.rawValue.capitalized)
                                    .atlasTextRole(.deckEyebrow)
                                    .foregroundStyle(session.status == .active ? AtlasPalette.primary : .orange)
                            }
                            Text(session.summary)
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                            Text("Created \(session.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                            if let expiresAt = session.expiresAt {
                                Text("Expires \(expiresAt.formatted(date: .abbreviated, time: .shortened))")
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                            if let packURL = session.packURL {
                                Text(
                                    session.deliveryKind == .liveSession
                                        ? "Session link ready"
                                        : "Pack: \(packURL.lastPathComponent)"
                                )
                                .atlasTextRole(.supporting)
                                .foregroundStyle(AtlasPalette.textSecondary)
                            }
                            if session.canRevoke {
                                if session.status == .active {
                                    Button("Revoke session") {
                                        Task {
                                            await model.revokeReviewSession(id: session.id)
                                        }
                                    }
                                    .buttonStyle(AtlasTertiaryButtonStyle())
                                } else {
                                    Text("This live session has been revoked or expired.")
                                        .atlasTextRole(.supporting)
                                        .foregroundStyle(AtlasPalette.textSecondary)
                                }
                            } else {
                                Text("Static review packs cannot be revoked after delivery.")
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                    }
                }
            }

            AtlasSectionCard(style: .utility, title: "Open review pack") {
                TextField("Absolute path to atlas-review-pack.json", text: $reviewPackPath)
                    .autocorrectionDisabled()
                    .atlasStandaloneInputSurface()

                Button("Open read-only workspace") {
                    Task {
                        guard reviewPackPath.isEmpty == false else {
                            return
                        }
                        _ = await model.loadReviewWorkspace(from: URL(fileURLWithPath: reviewPackPath))
                    }
                }
                .buttonStyle(AtlasPrimaryButtonStyle())

                Text("Review workspaces are read-only. There is no owner-data mutation path here.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            if let workspace = model.reviewWorkspace {
                AtlasSectionCard(title: "Reviewer workspace") {
                    Text(workspace.summary)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    HStack {
                        Text(workspace.readOnly ? "Read-only" : "Editable")
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(workspace.readOnly ? AtlasPalette.primary : .orange)
                        Spacer()
                        Text(workspace.renderMode.rawValue.capitalized)
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    ForEach(workspace.sections) { section in
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
        }
        .task {
            await model.refreshReviewMode()
            if selectedProtocolID == nil {
                selectedProtocolID = model.libraryProtocols.first?.id
            }
            if selectedProtocolIDs.isEmpty, let selectedProtocolID {
                selectedProtocolIDs = [selectedProtocolID]
            }
            applyPreset(selectedPreset)
        }
    }

    private var needsSingleProtocolSelection: Bool {
        switch scopeKind {
        case .currentProtocol, .inventoryOnly, .summaryOnly:
            return true
        default:
            return false
        }
    }

    private var needsMultipleProtocolSelection: Bool {
        switch scopeKind {
        case .selectedProtocols, .customDateRange:
            return true
        default:
            return false
        }
    }

    private var reviewRequest: AtlasReviewRequest {
        AtlasReviewRequest(
            scopeKind: scopeKind,
            protocolID: needsSingleProtocolSelection ? selectedProtocolID : nil,
            protocolIDs: needsMultipleProtocolSelection ? Array(selectedProtocolIDs).sorted() : [],
            dateRange: scopeKind == .customDateRange ? AtlasDateRange(start: customRangeStart, end: customRangeEnd) : nil,
            aliasModeEnabled: aliasModeEnabled,
            expiresAt: includeExpiration ? expiresAt : nil,
            deliveryKind: model.reviewOwnerSnapshot.liveReviewEnabled ? deliveryKind : .staticPack
        )
    }

    private func selectionBinding(for protocolID: String) -> Binding<Bool> {
        Binding(
            get: { selectedProtocolIDs.contains(protocolID) },
            set: { enabled in
                if enabled {
                    selectedProtocolIDs.insert(protocolID)
                } else {
                    selectedProtocolIDs.remove(protocolID)
                }
            }
        )
    }

    private func applyPreset(_ preset: AtlasReviewPreset) {
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
        if request.protocolIDs.isEmpty == false {
            selectedProtocolIDs = Set(request.protocolIDs)
        }
        aliasModeEnabled = request.aliasModeEnabled
        includeExpiration = request.expiresAt != nil
        if let expiresAt = request.expiresAt {
            self.expiresAt = expiresAt
        }
        deliveryKind = .staticPack
        if let dateRange = request.dateRange {
            customRangeStart = dateRange.start
            customRangeEnd = dateRange.end
        }
        latestResult = nil
    }
}

@MainActor
private func reviewHeader(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
        AtlasStatusBadge("Read-only handoffs", tint: AtlasPalette.secondaryText)
        Text(title)
            .atlasTextRole(.screenTitle)
            .foregroundStyle(AtlasPalette.textPrimary)
        Text(subtitle)
            .atlasTextRole(.screenSubtitle)
            .foregroundStyle(AtlasPalette.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
