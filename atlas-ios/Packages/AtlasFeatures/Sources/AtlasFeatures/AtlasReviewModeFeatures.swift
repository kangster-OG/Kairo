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
                setLoadErrorMessage("Live summary links need cloud configuration in this build.")
                return nil
            }
            guard cloudSession != nil else {
                setLoadErrorMessage("Sign in to Kairo cloud sync before creating a live summary link.")
                return nil
            }
        }

        let reason = request.deliveryKind == .liveSession ? "Create a live summary link" : "Create a share summary"
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
            if let error = model.loadErrorMessage {
                AtlasSectionCard {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            AtlasShareSummaryPrimaryCard(
                model: model,
                preset: selectedPreset,
                scopeKind: scopeKind,
                deliveryKind: deliveryKind
            ) {
                Task {
                    latestResult = await model.createReview(reviewRequest)
                    if let packURL = latestResult?.packURL {
                        reviewPackPath = packURL.isFileURL ? packURL.path : packURL.absoluteString
                    }
                }
            }

            AtlasSectionCard(style: .elevated, title: "Summary options") {
                AtlasReviewChipGroup(
                    title: "Purpose",
                    selection: $selectedPreset,
                    options: AtlasReviewPreset.allCases.map { ($0.reviewChipTitle, $0) }
                )

                Text(selectedPreset.subtitle)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)

                AtlasReviewChipGroup(
                    title: "Scope",
                    selection: $scopeKind,
                    options: AtlasReviewScopeKind.allCases.map { ($0.reviewChipTitle, $0) }
                )

                if needsSingleProtocolSelection {
                    AtlasReviewChipGroup(
                        title: "Protocol",
                        selection: $selectedProtocolID,
                        options: protocolOptions
                    )
                }

                if needsMultipleProtocolSelection {
                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                        Text("Protocols")
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(AtlasPalette.primary)

                        ForEach(model.libraryProtocols) { summary in
                            AtlasReviewSelectionRow(
                                title: model.renderedTitle(canonical: summary.canonicalTitle, alias: summary.aliasTitle),
                                isSelected: selectedProtocolIDs.contains(summary.id)
                            ) {
                                selectedProtocolIDs.formSymmetricDifference([summary.id])
                            }
                        }
                    }
                }

                AtlasReviewActionRow(
                    title: "Apply selected preset",
                    detail: "Use the selected purpose to set scope and labels.",
                    systemImage: "slider.horizontal.3"
                ) {
                    applyPreset(selectedPreset)
                }

                if deliveryKind == .liveSession {
                    AtlasReviewStatusRow(
                        title: model.canCreateLiveReviewSession ? "Cloud ready" : "Sign-in required",
                        detail: model.canCreateLiveReviewSession
                            ? "Live links can be revoked after sharing."
                            : "Sign in before creating a live summary link.",
                        systemImage: model.canCreateLiveReviewSession ? "checkmark.icloud.fill" : "exclamationmark.icloud.fill",
                        tint: model.canCreateLiveReviewSession ? AtlasPalette.success : AtlasPalette.warning
                    )
                }

                AtlasReviewBooleanRow(title: "Simple labels", detail: "Use simplified names.", isOn: $aliasModeEnabled)
                AtlasReviewBooleanRow(title: "Expiration", detail: "Add an end date for live links.", isOn: $includeExpiration)

                if includeExpiration {
                    AtlasReviewDateAdjusterRow(
                        title: "Expires",
                        detail: "Live links stop after this date.",
                        date: $expiresAt,
                        includesTime: true
                    )
                }

                AtlasReviewChipGroup(
                    title: "Delivery",
                    selection: $deliveryKind,
                    options: AtlasReviewDeliveryKind.allCases.map { ($0.reviewChipTitle, $0) }
                )
                if scopeKind == .customDateRange {
                    AtlasReviewDateAdjusterRow(
                        title: "Start",
                        detail: "First day included in the summary.",
                        date: $customRangeStart,
                        includesTime: false
                    )
                    AtlasReviewDateAdjusterRow(
                        title: "End",
                        detail: "Last day included in the summary.",
                        date: $customRangeEnd,
                        includesTime: false
                    )
                }
            }

            if let latestResult {
                AtlasSectionCard(title: "Latest Summary") {
                    AtlasShareSummaryResultRow(
                        title: latestResult.session.deliveryKind == .liveSession ? "Summary link ready" : "Summary file ready",
                        detail: latestResult.workspace.summary,
                        value: latestResult.session.deliveryKind == .liveSession ? "Live" : "File",
                        tint: AtlasPalette.primary
                    )
                    if latestResult.session.deliveryKind == .liveSession {
                        Text(latestResult.packURL.absoluteString)
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .lineLimit(2)
                            .textSelection(.enabled)
                    } else {
                        Text("File: \(latestResult.packURL.lastPathComponent)")
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                }
            }

            AtlasSectionCard(style: .utility, title: "Shared Summaries") {
                if model.reviewOwnerSnapshot.sessions.isEmpty {
                    Text("No summaries created yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(model.reviewOwnerSnapshot.sessions) { session in
                        AtlasShareSummarySessionRow(session: session)
                        if session.canRevoke, session.status == .active {
                            Button("Revoke live link") {
                                Task {
                                    await model.revokeReviewSession(id: session.id)
                                }
                            }
                            .buttonStyle(AtlasTertiaryButtonStyle())
                        }
                    }
                }
            }

            AtlasSectionCard(style: .utility, title: "Open Summary File") {
                AtlasReviewPathInputRow(path: $reviewPackPath) {
                    Task {
                        guard reviewPackPath.isEmpty == false else {
                            return
                        }
                        _ = await model.loadReviewWorkspace(from: URL(fileURLWithPath: reviewPackPath))
                    }
                }

                Text("Summary files are read-only.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            if let workspace = model.reviewWorkspace {
                AtlasSectionCard(title: "Summary File") {
                    Text(workspace.summary)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .lineLimit(3)

                    HStack(spacing: 8) {
                        AtlasStatusBadge(workspace.readOnly ? "Read-only" : "Editable", tint: workspace.readOnly ? AtlasPalette.primary : .orange)
                        AtlasStatusBadge(workspace.renderMode.rawValue.capitalized, tint: AtlasPalette.secondaryText)
                    }

                    ForEach(workspace.sections.prefix(3)) { section in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(section.title)
                                .atlasTextRole(.deckEyebrow)
                                .foregroundStyle(AtlasPalette.primary)
                            ForEach(section.lines.prefix(2), id: \.self) { line in
                                Text(line)
                                    .atlasTextRole(.supporting)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Share Summary")
        .tint(AtlasPalette.primary)
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

    private var protocolOptions: [(String, String?)] {
        [("Select protocol", String?.none)] + model.libraryProtocols.map { summary in
            (model.renderedTitle(canonical: summary.canonicalTitle, alias: summary.aliasTitle), String?.some(summary.id))
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

private struct AtlasShareSummaryPrimaryCard: View {
    let model: AtlasAppModel
    let preset: AtlasReviewPreset
    let scopeKind: AtlasReviewScopeKind
    let deliveryKind: AtlasReviewDeliveryKind
    let action: () -> Void

    var body: some View {
        AtlasSectionCard(style: .task, title: "Share Summary") {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AtlasPalette.primary.opacity(0.08))
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AtlasPalette.primary)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Protocol summary")
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text("Shots, check-ins, photos, and runway in one clean export.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                AtlasShareSummaryMiniMetric(title: "Purpose", value: preset.reviewChipTitle)
                AtlasShareSummaryMiniMetric(title: "Scope", value: scopeKind.reviewChipTitle)
                AtlasShareSummaryMiniMetric(title: "Output", value: deliveryKind.reviewChipTitle)
            }

            Button("Create Share Summary") {
                action()
            }
            .buttonStyle(AtlasPrimaryButtonStyle())
            .disabled(deliveryKind == .liveSession && model.canCreateLiveReviewSession == false)
        }
    }
}

private struct AtlasShareSummaryMiniMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .atlasTextRole(.metricLabel)
                .foregroundStyle(AtlasPalette.primary)
                .lineLimit(1)
            Text(value)
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.55), lineWidth: 1)
        )
    }
}

private struct AtlasShareSummaryResultRow: View {
    let title: String
    let detail: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            AtlasStatusBadge(value, tint: tint)
        }
        .padding(10)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AtlasShareSummarySessionRow: View {
    let session: AtlasReviewSessionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(session.title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(session.status.rawValue.capitalized)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(session.status == .active ? AtlasPalette.primary : .orange)
            }

            Text(session.summary)
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                AtlasStatusBadge(session.deliveryKind == .liveSession ? "Live link" : "File", tint: AtlasPalette.secondaryText)
                Text(session.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(1)
                if let expiresAt = session.expiresAt {
                    Text("Expires \(expiresAt.formatted(date: .abbreviated, time: .omitted))")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(10)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.45), lineWidth: 1)
        )
    }
}

@MainActor
private func reviewHeader(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
        AtlasStatusBadge("Share summary", tint: AtlasPalette.secondaryText)
        Text(title)
            .atlasTextRole(.screenTitle)
            .foregroundStyle(AtlasPalette.textPrimary)
        Text(subtitle)
            .atlasTextRole(.screenSubtitle)
            .foregroundStyle(AtlasPalette.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct AtlasReviewChipGroup<Value: Equatable>: View {
    let title: String
    @Binding var selection: Value
    let options: [(String, Value)]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .atlasTextRole(.deckEyebrow)
                .foregroundStyle(AtlasPalette.primary)

            AtlasReviewChipFlowLayout(spacing: 7) {
                ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                    Button {
                        AtlasFeedback.selection()
                        selection = option.1
                    } label: {
                        Text(option.0)
                            .atlasTextRole(.metricLabel)
                            .fontWeight(selection == option.1 ? .semibold : .regular)
                            .foregroundStyle(selection == option.1 ? .white : AtlasPalette.textPrimary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 12)
                            .frame(height: 30)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(selection == option.1 ? AtlasPalette.primary : AtlasPalette.surfaceSecondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(selection == option.1 ? AtlasPalette.primary.opacity(0.22) : AtlasPalette.border.opacity(0.55), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct AtlasReviewChipFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        guard maxWidth > 0 else {
            let size = subviews.reduce(CGSize.zero) { partial, subview in
                let next = subview.sizeThatFits(.unspecified)
                return CGSize(width: partial.width + next.width + spacing, height: max(partial.height, next.height))
            }
            return CGSize(width: max(0, size.width - spacing), height: size.height)
        }

        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var widestLine: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let proposedWidth = lineWidth == 0 ? size.width : lineWidth + spacing + size.width
            if proposedWidth > maxWidth, lineWidth > 0 {
                totalHeight += lineHeight + spacing
                widestLine = max(widestLine, lineWidth)
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth = proposedWidth
                lineHeight = max(lineHeight, size.height)
            }
        }

        totalHeight += lineHeight
        widestLine = max(widestLine, lineWidth)
        return CGSize(width: min(maxWidth, widestLine), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

private struct AtlasReviewSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? AtlasPalette.primary : AtlasPalette.secondaryText)
                    .frame(width: 24)

                Text(title)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? AtlasPalette.primary.opacity(0.08) : AtlasPalette.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? AtlasPalette.primary.opacity(0.28) : AtlasPalette.border.opacity(0.55), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AtlasReviewActionRow: View {
    let title: String
    let detail: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button {
            AtlasFeedback.selection()
            action()
        } label: {
            HStack(spacing: 12) {
                AtlasReviewControlIcon(systemImage: systemImage, tint: AtlasPalette.primary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(detail)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 10)

                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AtlasPalette.primary)
            }
            .padding(12)
            .background(AtlasPalette.surfacePrimary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AtlasPalette.border.opacity(0.55), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AtlasReviewStatusRow: View {
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            AtlasReviewControlIcon(systemImage: systemImage, tint: tint)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tint.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct AtlasReviewDateAdjusterRow: View {
    let title: String
    let detail: String
    @Binding var date: Date
    let includesTime: Bool

    var body: some View {
        HStack(spacing: 12) {
            AtlasReviewControlIcon(systemImage: "calendar", tint: AtlasPalette.primary)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                AtlasReviewStepButton(systemImage: "minus") {
                    shiftDate(by: -1)
                }

                VStack(spacing: 1) {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .atlasTextRole(.metricLabel)
                        .foregroundStyle(AtlasPalette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    if includesTime {
                        Text(date.formatted(date: .omitted, time: .shortened))
                            .atlasTextRole(.metricLabel)
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(width: includesTime ? 82 : 72, height: 34)
                .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AtlasPalette.border.opacity(0.55), lineWidth: 1)
                )

                AtlasReviewStepButton(systemImage: "plus") {
                    shiftDate(by: 1)
                }
            }
        }
        .padding(12)
        .background(AtlasPalette.surfacePrimary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.55), lineWidth: 1)
        )
    }

    private func shiftDate(by days: Int) {
        AtlasFeedback.selection()
        date = Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }
}

private struct AtlasReviewPathInputRow: View {
    @Binding var path: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                AtlasReviewControlIcon(systemImage: "doc.text.magnifyingglass", tint: AtlasPalette.primary)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Summary file")
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text("Open a Kairo summary JSON file.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                TextField("Paste atlas-summary.json path", text: $path)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.system(size: 13))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .padding(.horizontal, 10)
                    .frame(height: 38)
                    .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AtlasPalette.border.opacity(0.55), lineWidth: 1)
                    )

                Button {
                    AtlasFeedback.selection()
                    action()
                } label: {
                    Text("Open")
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 38)
                        .background(AtlasPalette.primary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
            }
        }
        .padding(12)
        .background(AtlasPalette.surfacePrimary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.55), lineWidth: 1)
        )
    }
}

private struct AtlasReviewControlIcon: View {
    let systemImage: String
    let tint: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(tint.opacity(0.09))
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: 34, height: 34)
    }
}

private struct AtlasReviewStepButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AtlasPalette.primary)
                .frame(width: 30, height: 34)
                .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AtlasPalette.border.opacity(0.55), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct AtlasReviewBooleanRow: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            AtlasFeedback.selection()
            isOn.toggle()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(detail)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 10)

                Text(isOn ? "On" : "Off")
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(isOn ? .white : AtlasPalette.secondaryText)
                    .frame(width: 54, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isOn ? AtlasPalette.primary : AtlasPalette.surfaceSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isOn ? AtlasPalette.primary.opacity(0.24) : AtlasPalette.border.opacity(0.55), lineWidth: 1)
                    )
            }
            .padding(12)
            .background(AtlasPalette.surfacePrimary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AtlasPalette.border.opacity(0.55), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private extension AtlasReviewScopeKind {
    var reviewChipTitle: String {
        switch self {
        case .currentProtocol: "Current"
        case .selectedProtocols: "Selected"
        case .last30Days: "30 days"
        case .symptomsOnly: "Check-ins"
        case .inventoryOnly: "Inventory"
        case .summaryOnly: "Summary"
        case .customDateRange: "Custom"
        }
    }
}

private extension AtlasReviewDeliveryKind {
    var reviewChipTitle: String {
        switch self {
        case .staticPack: "File"
        case .liveSession: "Live link"
        }
    }
}

private extension AtlasReviewPreset {
    var reviewChipTitle: String {
        switch self {
        case .clinicianSummary: "Clinician"
        case .coachSummary: "Coach"
        case .partnerReview: "Partner"
        case .selfArchive: "Archive"
        }
    }
}
