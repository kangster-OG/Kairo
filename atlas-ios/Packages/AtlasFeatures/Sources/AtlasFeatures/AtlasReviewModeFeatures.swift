import AtlasDesignSystem
import AtlasDomain
import SwiftUI

public extension AtlasAppModel {
    func refreshReviewMode() async {
        do {
            reviewOwnerSnapshot = try await dependencies.persistence.reviewMode.fetchOwnerSnapshot(now: Date())
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }

    func createReview(_ request: AtlasReviewRequest) async -> AtlasReviewCreationResult? {
        guard await unlockTrustVaultIfNeeded(reason: "Create a review pack") else {
            return nil
        }

        do {
            let result = try await dependencies.persistence.reviewMode.createReview(request, now: Date())
            reviewOwnerSnapshot = try await dependencies.persistence.reviewMode.fetchOwnerSnapshot(now: Date())
            await refreshTrustVaultSnapshot()
            reviewWorkspace = result.workspace
            return result
        } catch {
            loadErrorMessage = error.localizedDescription
            return nil
        }
    }

    func loadReviewWorkspace(from fileURL: URL) async -> AtlasReviewWorkspace? {
        do {
            let workspace = try await dependencies.persistence.reviewMode.loadWorkspace(from: fileURL, now: Date())
            reviewWorkspace = workspace
            return workspace
        } catch {
            loadErrorMessage = error.localizedDescription
            return nil
        }
    }
}

public struct AtlasReviewModeHomeScreen: View {
    let model: AtlasAppModel

    @State private var scopeKind: AtlasReviewScopeKind = .summaryOnly
    @State private var selectedProtocolID: String?
    @State private var selectedProtocolIDs: Set<String> = []
    @State private var aliasModeEnabled = true
    @State private var includeExpiration = false
    @State private var expiresAt: Date = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @State private var deliveryKind: AtlasReviewDeliveryKind = .staticPack
    @State private var customRangeStart: Date = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
    @State private var customRangeEnd: Date = Date()
    @State private var latestResult: AtlasReviewCreationResult?
    @State private var reviewPackPath = ""

    public var body: some View {
        AtlasScreen {
            reviewHeader(
                "Review Mode",
                subtitle: "Create a bounded read-only snapshot for review without opening a social or messaging surface."
            )

            if let error = model.loadErrorMessage {
                AtlasSectionCard {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            AtlasSectionCard(title: "Create review") {
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
                            .font(.caption.weight(.semibold))
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
                .disabled(model.reviewOwnerSnapshot.liveReviewEnabled == false)

                if model.reviewOwnerSnapshot.liveReviewEnabled == false {
                    Text("Live review sessions remain feature-flagged off in this build. Static packs are supported and guest-safe.")
                        .font(.caption)
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
                            reviewPackPath = packURL.path
                        }
                    }
                }
                .buttonStyle(AtlasPrimaryButtonStyle())

                Text("Static snapshots are labeled read-only and non-revocable after delivery.")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            if let latestResult {
                AtlasSectionCard(title: "Latest review pack") {
                    Text(latestResult.workspace.summary)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    Text("Pack: \(latestResult.packURL.lastPathComponent)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.primary)
                    Text("Summary: \(latestResult.summaryURL.lastPathComponent)")
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }

            AtlasSectionCard(title: "Owner review management") {
                if model.reviewOwnerSnapshot.sessions.isEmpty {
                    Text("No review packs created yet.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                } else {
                    ForEach(model.reviewOwnerSnapshot.sessions) { session in
                        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                            HStack {
                                Text(session.title)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(AtlasPalette.textPrimary)
                                Spacer()
                                Text(session.status.rawValue.capitalized)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(session.status == .active ? AtlasPalette.primary : .orange)
                            }
                            Text(session.summary)
                                .foregroundStyle(AtlasPalette.textSecondary)
                            Text("Created \(session.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(AtlasPalette.textSecondary)
                            if let expiresAt = session.expiresAt {
                                Text("Expires \(expiresAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                            if let packURL = session.packURL {
                                Text("Pack: \(packURL.lastPathComponent)")
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                            if session.canRevoke {
                                Text("Live session revocation will surface here when the feature flag is enabled.")
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            } else {
                                Text("Static review packs cannot be revoked after delivery.")
                                    .font(.caption)
                                    .foregroundStyle(AtlasPalette.textSecondary)
                            }
                        }
                    }
                }
            }

            AtlasSectionCard(title: "Open review pack") {
                TextField("Absolute path to atlas-review-pack.json", text: $reviewPackPath)
                    .autocorrectionDisabled()

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
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            if let workspace = model.reviewWorkspace {
                AtlasSectionCard(title: "Reviewer workspace") {
                    Text(workspace.summary)
                        .foregroundStyle(AtlasPalette.textSecondary)

                    HStack {
                        Text(workspace.readOnly ? "Read-only" : "Editable")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(workspace.readOnly ? AtlasPalette.primary : .orange)
                        Spacer()
                        Text(workspace.renderMode.rawValue.capitalized)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }

                    ForEach(workspace.sections) { section in
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
        }
        .navigationTitle("Review Mode")
        .task {
            await model.refreshReviewMode()
            if selectedProtocolID == nil {
                selectedProtocolID = model.libraryProtocols.first?.id
            }
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
}

private func reviewHeader(_ title: String, subtitle: String) -> some View {
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
