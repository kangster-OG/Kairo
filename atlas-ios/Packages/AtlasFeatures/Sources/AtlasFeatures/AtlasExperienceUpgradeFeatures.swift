import AtlasDesignSystem
import AtlasDomain
import SwiftUI

struct AtlasTrustStatusBanner: View {
    let model: AtlasAppModel
    var compact = false

    var body: some View {
        AtlasSectionCard(style: .utility) {
            HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: compact ? 18 : 22, weight: .semibold))
                    .foregroundStyle(AtlasPalette.primary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                    HStack(spacing: AtlasSpacing.small) {
                        AtlasStatusBadge("Local first", tint: AtlasPalette.success)
                        AtlasStatusBadge(renderModeLabel, tint: AtlasPalette.primary)
                    }

                    Text(compact ? "Privacy rendering is active across surfaces." : "Kairo keeps your peptide protocol local-first, review-safe, and privacy-rendered before anything leaves the device.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AtlasSpacing.small)

                if compact == false {
                    Button("Privacy Controls") {
                        AtlasFeedback.selection()
                        model.open(.trustVault)
                    }
                    .buttonStyle(AtlasTertiaryButtonStyle())
                }
            }
        }
    }

    private var renderModeLabel: String {
        switch model.settingsSnapshot.trustVaultStatus.renderMode {
        case .full:
            "Full labels"
        case .discreet:
            "Discreet"
        case .alias:
            "Alias"
        }
    }
}

struct AtlasReadinessStripCard: View {
    let model: AtlasAppModel
    let todaySnapshot: AtlasTodaySnapshot

    var body: some View {
        AtlasSectionCard(style: .task, title: "Readiness map") {
            AtlasMetricStrip(metrics: metrics)

            VStack(spacing: AtlasSpacing.small) {
                ForEach(rows) { row in
                    AtlasReadinessRow(row: row)
                }
            }
        }
    }

    private var metrics: [AtlasMetricItem] {
        [
            AtlasMetricItem(
                id: "schedule",
                title: "Schedule",
                value: todaySnapshot.hasProtocols ? "Active" : "Setup",
                tint: todaySnapshot.hasProtocols ? AtlasPalette.success : AtlasPalette.primary
            ),
            AtlasMetricItem(
                id: "inventory",
                title: "Inventory",
                value: inventoryItemCount == 0 ? "Queued" : "\(inventoryItemCount)",
                tint: inventoryItemCount == 0 ? AtlasPalette.secondaryText : AtlasPalette.success
            ),
            AtlasMetricItem(
                id: "review",
                title: "Review",
                value: model.reviewOwnerSnapshot.sessions.isEmpty ? "Ready" : "\(model.reviewOwnerSnapshot.sessions.count)",
                tint: AtlasPalette.primary
            )
        ]
    }

    private var rows: [AtlasReadinessRowModel] {
        [
            AtlasReadinessRowModel(
                id: "schedule",
                symbol: "calendar.badge.clock",
                title: todaySnapshot.hasProtocols ? "Protocol schedule is live" : "Protocol schedule is next",
                detail: todaySnapshot.nextDue?.cadenceLabel ?? "Create or import a protocol to activate exact due actions.",
                tint: todaySnapshot.hasProtocols ? AtlasPalette.success : AtlasPalette.primary
            ),
            AtlasReadinessRowModel(
                id: "privacy",
                symbol: "eye.slash",
                title: "Privacy posture is set",
                detail: "Current rendering: \(model.settingsSnapshot.trustVaultStatus.renderMode.rawValue.capitalized).",
                tint: AtlasPalette.primary
            ),
            AtlasReadinessRowModel(
                id: "review",
                symbol: "doc.text.magnifyingglass",
                title: "Review output is available",
                detail: "Build a provider-safe or personal summary whenever you need it.",
                tint: AtlasPalette.secondaryText
            )
        ]
    }

    private var inventoryItemCount: Int {
        model.inventorySnapshot.vials.count + model.inventorySnapshot.consumables.count
    }
}

struct AtlasDayOneProtocolCard: View {
    let model: AtlasAppModel
    let todaySnapshot: AtlasTodaySnapshot

    var body: some View {
        AtlasCommandDeck(
            eyebrow: "DAY 1 PROTOCOL",
            title: title,
            detail: "Your first session is not empty. Kairo keeps a short activation path visible until the operating record is real.",
            metrics: metrics,
            style: .hero
        ) {
            VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                ForEach(dayOneItems) { item in
                    AtlasActivationChecklistRow(item: item)
                }

                HStack(spacing: AtlasSpacing.small) {
                    Button(primaryActionTitle) {
                        AtlasFeedback.selection()
                        model.open(todaySnapshot.hasProtocols ? .quickCapture(.context) : .protocolCreate)
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())

                    Button(secondaryActionTitle) {
                        AtlasFeedback.selection()
                        model.open(todaySnapshot.hasProtocols ? .reviewMode : .importFlow)
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
        } footer: {
            Text("The checklist adapts from onboarding answers, but every item remains optional and editable.")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var title: String {
        if todaySnapshot.hasProtocols {
            return "Run today's first useful action."
        }
        return "Activate Kairo with your current setup."
    }

    private var primaryActionTitle: String {
        todaySnapshot.hasProtocols ? "Log context" : "Create protocol"
    }

    private var secondaryActionTitle: String {
        todaySnapshot.hasProtocols ? "Build review" : "Import current setup"
    }

    private var metrics: [AtlasMetricItem] {
        [
            AtlasMetricItem(id: "plan", title: "Plan", value: "\(model.bootstrapSnapshot.onboardingDraft.firstWeekPlanPreview.isEmpty ? 5 : model.bootstrapSnapshot.onboardingDraft.firstWeekPlanPreview.count)d"),
            AtlasMetricItem(id: "privacy", title: "Trust", value: model.settingsSnapshot.trustVaultStatus.renderMode.rawValue.capitalized, tint: AtlasPalette.primary),
            AtlasMetricItem(id: "priority", title: "Priority", value: dayOnePriorityShort, tint: AtlasPalette.secondaryText)
        ]
    }

    private var dayOnePriorityShort: String {
        let value = model.bootstrapSnapshot.onboardingDraft.dayOnePriority ?? "setup"
        return value
            .split(separator: "_")
            .first
            .map(String.init)?
            .capitalized ?? "Setup"
    }

    private var dayOneItems: [AtlasActivationChecklistItem] {
        let plan = model.bootstrapSnapshot.onboardingDraft.firstWeekPlanPreview
        let generated = plan.prefix(3).enumerated().map { index, value in
            AtlasActivationChecklistItem(
                id: "generated_\(index)",
                title: value,
                detail: index == 0 ? "Recommended from onboarding." : "Queued for this week.",
                isComplete: false
            )
        }
        if generated.isEmpty == false {
            return generated
        }
        return [
            AtlasActivationChecklistItem(
                id: "protocol",
                title: todaySnapshot.hasProtocols ? "Confirm next protocol action" : "Add or import current protocol",
                detail: "This turns Kairo from a shell into an operating record.",
                isComplete: todaySnapshot.hasProtocols
            ),
            AtlasActivationChecklistItem(
                id: "privacy",
                title: "Confirm review privacy",
                detail: "Choose full, discreet, or alias rendering before sharing.",
                isComplete: model.settingsSnapshot.trustVaultStatus.renderMode != .full
            ),
            AtlasActivationChecklistItem(
                id: "context",
                title: "Capture one useful signal",
                detail: "Weight, context, symptom, nutrition, or a note.",
                isComplete: false
            )
        ]
    }
}

struct AtlasQuickActionDockCard: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasSectionCard(style: .utility, title: "Fast actions") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AtlasSpacing.small) {
                quickButton("Protocol", symbol: "plus.circle.fill") {
                    model.open(.protocolCreate)
                }
                quickButton("Import", symbol: "tray.and.arrow.down.fill") {
                    model.open(.importFlow)
                }
                quickButton("Context", symbol: "text.badge.plus") {
                    model.open(.quickCapture(.context))
                }
                quickButton("Review", symbol: "doc.text.magnifyingglass") {
                    model.open(.reviewMode)
                }
            }
        }
    }

    private func quickButton(
        _ title: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            AtlasFeedback.selection()
            action()
        } label: {
            HStack(spacing: AtlasSpacing.small) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .atlasTextRole(.cardBody)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 46)
        }
        .buttonStyle(AtlasTactileTileButtonStyle())
    }
}

struct AtlasProtocolInfrastructureCard: View {
    let model: AtlasAppModel
    let state: AtlasLibraryViewState

    var body: some View {
        AtlasCommandDeck(
            eyebrow: "PROTOCOL INFRASTRUCTURE",
            title: state.protocols.isEmpty ? "Start from a real setup." : "Every protocol has schedule, history, inventory, and review context.",
            detail: state.protocols.isEmpty ? "Create from scratch or migrate messy history without pretending you are starting clean." : "Kairo keeps current plans, changes, and review posture inspectable.",
            metrics: metrics,
            style: .task
        ) {
            VStack(spacing: AtlasSpacing.small) {
                if let first = state.protocols.first {
                    AtlasCalloutRow(
                        systemImage: "square.stack.3d.up.fill",
                        title: model.renderedTitle(
                            canonical: first.canonicalTitle,
                            alias: first.aliasTitle,
                            renderMode: state.renderMode
                        ),
                        detail: first.nextDueLabel ?? first.cadenceLabel,
                        tint: AtlasPalette.primary,
                        badge: first.status.rawValue.capitalized
                    )
                }

                HStack(spacing: AtlasSpacing.small) {
                    Button("Create") {
                        AtlasFeedback.selection()
                        model.open(.protocolCreate)
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())

                    Button(state.protocols.isEmpty ? "Import" : "Plan Editor") {
                        AtlasFeedback.selection()
                        if let first = state.protocols.first {
                            model.open(.protocolChange(first.id))
                        } else {
                            model.open(.importFlow)
                        }
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
        } footer: {
            EmptyView()
        }
    }

    private var metrics: [AtlasMetricItem] {
        [
            AtlasMetricItem(id: "protocols", title: "Protocols", value: "\(state.protocols.count)"),
            AtlasMetricItem(id: "privacy", title: "Privacy", value: state.renderMode.rawValue.capitalized, tint: AtlasPalette.secondaryText),
            AtlasMetricItem(id: "inventory", title: "Inventory", value: inventoryItemCount == 0 ? "Queued" : "\(inventoryItemCount)", tint: AtlasPalette.primary)
        ]
    }

    private var inventoryItemCount: Int {
        model.inventorySnapshot.vials.count + model.inventorySnapshot.consumables.count
    }
}

struct AtlasTimelineReviewDeltaCard: View {
    let model: AtlasAppModel
    let state: AtlasTimelineViewState

    var body: some View {
        AtlasSectionCard(style: .task, title: "Since last review") {
            AtlasMetricStrip(metrics: [
                AtlasMetricItem(id: "events", title: "Events", value: "\(state.entries.count)"),
                AtlasMetricItem(id: "filter", title: "Filter", value: state.filter.title, tint: AtlasPalette.secondaryText),
                AtlasMetricItem(id: "privacy", title: "View", value: state.renderMode.rawValue.capitalized, tint: AtlasPalette.primary)
            ])

            VStack(spacing: AtlasSpacing.small) {
                AtlasCalloutRow(
                    systemImage: "clock.arrow.circlepath",
                    title: state.entries.isEmpty ? "No source-backed history yet" : "History is grouped and source-backed",
                    detail: state.entries.isEmpty ? "Create or import a protocol and Kairo will keep immutable events here." : "Tap entries to inspect context, changes, and privacy rendering.",
                    tint: AtlasPalette.primary
                )
                Button(state.entries.isEmpty ? "Import history" : "Build review output") {
                    AtlasFeedback.selection()
                    model.open(state.entries.isEmpty ? .importFlow : .reviewMode)
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
            }
        }
    }
}

struct AtlasInsightsEvidenceCard: View {
    let model: AtlasAppModel
    let state: AtlasInsightsViewState

    var body: some View {
        AtlasCommandDeck(
            eyebrow: "EVIDENCE, NOT NOISE",
            title: title,
            detail: "Capture stays separate from interpretation so every insight can explain the source facts it used.",
            metrics: metrics,
            style: .task
        ) {
            VStack(spacing: AtlasSpacing.small) {
                AtlasCalloutRow(
                    systemImage: "camera.metering.matrix",
                    title: "Progress evidence",
                    detail: "Photos, weight, context, symptoms, and nutrition can become review-safe proof.",
                    tint: AtlasPalette.primary
                )
                HStack(spacing: AtlasSpacing.small) {
                    Button("Capture signal") {
                        AtlasFeedback.selection()
                        model.open(.quickCapture(.context))
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())

                    Button("Progress evidence") {
                        AtlasFeedback.selection()
                        model.open(.progressEvidence)
                    }
                    .buttonStyle(AtlasSecondaryButtonStyle())
                }
            }
        } footer: {
            EmptyView()
        }
    }

    private var title: String {
        if state.insightsSnapshot.customMetricDefinitions.isEmpty {
            return "Choose the first useful signal."
        }
        return "Review the strongest signal first."
    }

    private var metrics: [AtlasMetricItem] {
        [
            AtlasMetricItem(id: "metrics", title: "Metrics", value: "\(state.insightsSnapshot.customMetricDefinitions.count)"),
            AtlasMetricItem(id: "protocols", title: "Protocols", value: "\(state.libraryProtocols.count)", tint: AtlasPalette.secondaryText),
            AtlasMetricItem(id: "nutrition", title: "Nutrition", value: model.bootstrapSnapshot.onboardingDraft.profile.wantsNutritionTracking ? "On" : "Optional", tint: AtlasPalette.primary)
        ]
    }
}

struct AtlasTrustVaultSignatureCard: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasSectionCard(style: .hero, title: "Live privacy preview") {
            VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                HStack(spacing: AtlasSpacing.small) {
                    AtlasStatusBadge("Local", tint: AtlasPalette.success)
                    AtlasStatusBadge(model.trustVaultSnapshot.privacyProfile.renderMode?.rawValue.capitalized ?? "Full", tint: AtlasPalette.primary)
                    AtlasStatusBadge(model.trustVaultSnapshot.privacyProfile.shareAliasByDefault ? "Alias shares" : "Inspect first", tint: AtlasPalette.secondaryText)
                }

                VStack(spacing: AtlasSpacing.small) {
                    AtlasPrivacyPreviewLine(label: "Full", value: "Semaglutide weekly protocol", isActive: renderMode == .full)
                    AtlasPrivacyPreviewLine(label: "Discreet", value: "Weekly protocol", isActive: renderMode == .discreet)
                    AtlasPrivacyPreviewLine(label: "Alias", value: "Protocol A", isActive: renderMode == .alias)
                }

                Text("High-consequence actions stay explicit: preview, inspect, then export or share.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
        }
    }

    private var renderMode: AtlasPrivacyRenderMode {
        model.trustVaultSnapshot.privacyProfile.renderMode ?? .full
    }
}

struct AtlasReviewArtifactBuilderCard: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasSectionCard(style: .task, title: "Share summary") {
            AtlasMetricStrip(metrics: [
                AtlasMetricItem(id: "purpose", title: "Type", value: "Summary"),
                AtlasMetricItem(id: "scope", title: "Protocols", value: model.libraryProtocols.isEmpty ? "1" : "\(model.libraryProtocols.count)", tint: AtlasPalette.secondaryText),
                AtlasMetricItem(id: "detail", title: "Detail", value: model.settingsSnapshot.trustVaultStatus.renderMode.rawValue.capitalized, tint: AtlasPalette.primary)
            ])

            VStack(spacing: AtlasSpacing.small) {
                AtlasCalloutRow(
                    systemImage: "doc.richtext.fill",
                    title: "Protocol summary",
                    detail: "Build one clean snapshot from shots, check-ins, photos, and inventory.",
                    tint: AtlasPalette.primary
                )
                Button("Preview Summary") {
                    AtlasFeedback.selection()
                }
                .buttonStyle(AtlasSecondaryButtonStyle())
            }
        }
    }
}

struct AtlasCompanionContinuityCard: View {
    let model: AtlasAppModel

    var body: some View {
        AtlasSectionCard(style: .reward, title: "Continuity signal") {
            HStack(alignment: .center, spacing: AtlasSpacing.medium) {
                if model.settingsSnapshot.ambientMascotPresence != .off {
                    AtlasMascotSticker(
                        line: atlasMascotLine(for: model.settingsSnapshot.mascotSelection),
                        stage: .stage1,
                        size: 70
                    )
                }

                VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                    Text(displayName)
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text("Evolution is tied to meaningful Kairo milestones: first protocol, privacy mode, inventory, share summary, and weekly review.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: AtlasSpacing.small) {
                        AtlasStatusBadge(model.settingsSnapshot.ambientMascotPresence.title, tint: AtlasPalette.primary)
                        AtlasStatusBadge(model.bootstrapSnapshot.onboardingDraft.companionRole?.capitalized ?? "Steady", tint: AtlasPalette.secondaryText)
                    }
                }
            }
        }
    }

    private var displayName: String {
        let selection = model.settingsSnapshot.mascotSelection
        return model.settingsSnapshot.mascotNickname ?? selection.stage1Title
    }
}

private struct AtlasReadinessRowModel: Identifiable {
    let id: String
    let symbol: String
    let title: String
    let detail: String
    let tint: Color
}

private struct AtlasReadinessRow: View {
    let row: AtlasReadinessRowModel

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.small) {
            Image(systemName: row.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(row.tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(row.title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(row.detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AtlasActivationChecklistItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let isComplete: Bool
}

private struct AtlasActivationChecklistRow: View {
    let item: AtlasActivationChecklistItem

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.small) {
            Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(item.isComplete ? AtlasPalette.success : AtlasPalette.primary)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(item.detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct AtlasPrivacyPreviewLine: View {
    let label: String
    let value: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: AtlasSpacing.small) {
            Image(systemName: isActive ? "checkmark.seal.fill" : "circle")
                .foregroundStyle(isActive ? AtlasPalette.success : AtlasPalette.textTertiary)
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(isActive ? AtlasPalette.primary : AtlasPalette.textTertiary)
                Text(value)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .redacted(reason: isActive ? [] : .placeholder)
            }
            Spacer()
        }
        .padding(AtlasSpacing.small)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isActive ? AtlasPalette.primary.opacity(0.10) : AtlasPalette.surfaceTop.opacity(0.72))
        )
    }
}
