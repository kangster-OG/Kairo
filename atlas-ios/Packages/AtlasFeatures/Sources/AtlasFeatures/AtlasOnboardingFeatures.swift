import AtlasDesignSystem
import AtlasDomain
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct AtlasOnboardingFlowScreen: View {
    let model: AtlasAppModel

    public init(model: AtlasAppModel) {
        self.model = model
    }

    public var body: some View {
        let draft = model.bootstrapSnapshot.onboardingDraft
        let sequence = draft.sequence()
        let step = model.activeOnboardingStep
        let visibleSteps = sequence.filter { $0 != .splash }
        let progressIndex = visibleSteps.firstIndex(of: step).map { $0 + 1 } ?? 0

        GeometryReader { proxy in
            ZStack {
                AtlasAppBackground()

                VStack(spacing: 0) {
                    AtlasOnboardingHeader(
                        step: step,
                        progressIndex: progressIndex,
                        totalSteps: visibleSteps.count,
                        onBack: model.retreatOnboarding
                    )

                    ScrollView {
                        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
                            if let error = model.loadErrorMessage {
                                AtlasSectionCard {
                                    Text(error)
                                        .atlasTextRole(.supporting)
                                        .foregroundStyle(.red)
                                }
                            }

                            content(for: step, draft: draft)
                                .id(step)
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    )
                                )
                        }
                        .padding(.horizontal, AtlasSpacing.large)
                        .padding(.top, step == .splash ? AtlasSpacing.large : 44)
                        .padding(.bottom, 148)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .scrollDismissesKeyboard(.interactively)
                    .id(step)
                    .animation(.spring(response: 0.42, dampingFraction: 0.86), value: step)

                    AtlasOnboardingFooter(
                        primaryTitle: primaryTitle(for: step, draft: draft),
                        secondaryTitle: secondaryTitle(for: step),
                        isPrimaryDisabled: primaryDisabled(for: step, draft: draft),
                        onPrimary: {
                            Task {
                                await handlePrimaryAction(for: step)
                            }
                        },
                        onSecondary: secondaryAction(for: step)
                    )
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done", action: AtlasKeyboard.dismiss)
            }
        }
        .dynamicTypeSize(.xSmall ... .accessibility1)
    }

    @ViewBuilder
    private func content(for step: AtlasOnboardingStep, draft: AtlasOnboardingDraft) -> some View {
        switch step {
        case .splash:
            AtlasOnboardingSplash()
        case .trackType:
            AtlasOnboardingTrackTypeStep(model: model, draft: draft)
        case .journeyStatus:
            AtlasOnboardingJourneyStatusStep(model: model, draft: draft)
        case .protocolPreview:
            AtlasOnboardingProtocolPreviewStep(model: model, draft: draft)
        case .focus:
            AtlasOnboardingFocusStep(model: model, draft: draft)
        case .goalsProfile:
            AtlasOnboardingGoalsProfileStep(model: model, draft: draft)
        case .healthDisclaimer:
            AtlasOnboardingHealthDisclaimerStep(model: model, draft: draft)
        case .privacyPreset:
            AtlasOnboardingPrivacyPresetStep(model: model, draft: draft)
        case .premiumPreview:
            AtlasOnboardingPremiumPreviewStep(draft: draft)
        case .trustVaultReveal:
            AtlasOnboardingTrustVaultRevealStep(draft: draft)
        case .companionPreview:
            AtlasOnboardingCompanionPreviewStep(model: model, draft: draft)
        case .readinessLoop:
            AtlasOnboardingReadinessLoopStep(draft: draft)
        case .systemSurfaces:
            AtlasOnboardingSystemSurfacesStep(draft: draft)
        case .personalizedUnlock:
            AtlasOnboardingPersonalizedUnlockStep(draft: draft)
        case .todayCommandPreview:
            AtlasOnboardingTodayCommandPreviewStep(draft: draft)
        case .protocolChangeHistory:
            AtlasOnboardingProtocolChangeHistoryStep(draft: draft)
        case .reviewOutputPreview:
            AtlasOnboardingReviewOutputPreviewStep(draft: draft)
        case .migrationPreview:
            AtlasOnboardingMigrationPreviewStep(draft: draft)
        case .trialTimeline:
            AtlasOnboardingTrialTimelineStep(draft: draft)
        case .premiumPaywall:
            AtlasOnboardingPaywallStep(model: model, draft: draft)
        case .connectApps:
            AtlasOnboardingConnectAppsStep(model: model)
        case .planReady:
            AtlasOnboardingPlanReadyStep(draft: draft)
        }
    }

    private func primaryTitle(for step: AtlasOnboardingStep, draft: AtlasOnboardingDraft) -> String {
        switch step {
        case .splash:
            "Get started"
        case .premiumPaywall:
            draft.paywallChoice == .trialStarted ? "Continue" : "Start free trial"
        case .healthDisclaimer:
            "I understand"
        case .connectApps:
            "Continue"
        case .planReady:
            "Open Atlas"
        default:
            "Continue"
        }
    }

    private func secondaryTitle(for step: AtlasOnboardingStep) -> String? {
        switch step {
        case .premiumPaywall:
            "Continue with basic tracking"
        case .connectApps:
            model.dependencies.healthKit.isAvailable() ? "Connect Apple Health" : nil
        default:
            nil
        }
    }

    private func secondaryAction(for step: AtlasOnboardingStep) -> (() -> Void)? {
        switch step {
        case .premiumPaywall:
            return {
                Task {
                    await model.updateOnboardingDraft { current in
                        current.accountMode = .guest
                        current.paywallChoice = .basic
                    }
                    model.advanceOnboarding()
                }
            }
        case .connectApps:
            return {
                Task {
                    if model.dependencies.healthKit.isAvailable() {
                        await model.connectHealthKit()
                    }
                    await model.updateOnboardingDraft { current in
                        current.healthConnectionPromptSeen = true
                    }
                    model.advanceOnboarding()
                }
            }
        default:
            return nil
        }
    }

    private func primaryDisabled(for step: AtlasOnboardingStep, draft: AtlasOnboardingDraft) -> Bool {
        switch step {
        case .trackType:
            draft.trackType == nil
        case .journeyStatus:
            draft.journeyStatus == nil
        case .focus:
            draft.focus == nil
        case .privacyPreset:
            draft.privacyPreset == nil
        case .healthDisclaimer:
            draft.healthDisclaimerAccepted == false
        case .planReady:
            draft.isComplete == false
        default:
            false
        }
    }

    private func handlePrimaryAction(for step: AtlasOnboardingStep) async {
        AtlasKeyboard.dismiss()

        switch step {
        case .premiumPaywall:
            await model.updateOnboardingDraft { current in
                current.accountMode = .guest
                current.paywallChoice = .trialStarted
            }
            model.advanceOnboarding()
        case .connectApps:
            await model.updateOnboardingDraft { current in
                current.healthConnectionPromptSeen = true
            }
            model.advanceOnboarding()
        case .planReady:
            await model.completeOnboarding()
        default:
            model.advanceOnboarding()
        }
    }
}

private struct AtlasOnboardingHeader: View {
    let step: AtlasOnboardingStep
    let progressIndex: Int
    let totalSteps: Int
    let onBack: () -> Void

    var body: some View {
        Group {
            if step == .splash {
                Color.clear
                    .frame(height: AtlasSpacing.small)
            } else {
                VStack(spacing: AtlasSpacing.medium) {
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 13, height: 13)
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(.white.opacity(0.14))
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Go back")
                        .accessibilityHint("Returns to the previous onboarding step.")

                        Spacer()

                        Text("Atlas")
                            .font(AtlasTypography.brandFont(size: 25, weight: .bold, relativeTo: .title3))
                            .foregroundStyle(.white)

                        Spacer()

                        Color.clear.frame(width: 36, height: 36)
                    }

                    ProgressView(value: Double(progressIndex), total: Double(max(totalSteps, 1)))
                        .tint(.white)
                        .progressViewStyle(.linear)
                        .accessibilityLabel("Onboarding progress")
                        .accessibilityValue("\(progressIndex) of \(totalSteps)")
                }
                .padding(.horizontal, AtlasSpacing.large)
                .padding(.top, 18)
                .padding(.bottom, AtlasSpacing.medium)
                .background(
                    LinearGradient(
                        colors: [AtlasPalette.shellTop, AtlasPalette.shellTopAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea(edges: .top)
                )
            }
        }
    }
}

private struct AtlasOnboardingFooter: View {
    let primaryTitle: String
    let secondaryTitle: String?
    let isPrimaryDisabled: Bool
    let onPrimary: () -> Void
    let onSecondary: (() -> Void)?

    var body: some View {
        VStack(spacing: AtlasSpacing.small) {
            if let secondaryTitle, let onSecondary {
                Button(secondaryTitle, action: onSecondary)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.primary)
                    .frame(minHeight: 44)
            }

            Button(primaryTitle, action: onPrimary)
                .buttonStyle(AtlasPrimaryButtonStyle())
                .disabled(isPrimaryDisabled)
                .opacity(isPrimaryDisabled ? 0.48 : 1)
        }
        .padding(.horizontal, AtlasSpacing.large)
        .padding(.top, AtlasSpacing.medium)
        .padding(.bottom, 28)
        .background(
            LinearGradient(
                colors: [
                    AtlasPalette.background.opacity(0.88),
                    AtlasPalette.background.opacity(0.95),
                    AtlasPalette.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

private struct AtlasOnboardingSplash: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasArrived = false

    var body: some View {
        VStack(alignment: .leading, spacing: dynamicTypeSize.isAccessibilitySize ? AtlasSpacing.medium : AtlasSpacing.large) {
            AtlasStatusBadge("Private by default", tint: .white)

            Text("Atlas")
                .font(AtlasTypography.brandFont(size: dynamicTypeSize.isAccessibilitySize ? 36 : 46, weight: .bold, relativeTo: .largeTitle))
                .foregroundStyle(.white)

            Text("Start private, then build the protocol command center around your goal.")
                .font(dynamicTypeSize.isAccessibilitySize ? .body.weight(.semibold) : .title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)

            AtlasOnboardingHeroProofGrid()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AtlasSpacing.medium)
        .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 24 : 32)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AtlasPalette.shellTop, AtlasPalette.shellTopAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .opacity(hasArrived ? 1 : 0)
        .offset(y: hasArrived || reduceMotion ? 0 : 18)
        .onAppear {
            withAnimation(reduceMotion ? .linear(duration: 0.01) : .spring(response: 0.55, dampingFraction: 0.82)) {
                hasArrived = true
            }
        }
    }
}

private struct AtlasOnboardingHeroProofGrid: View {
    var body: some View {
        ViewThatFits(in: .vertical) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AtlasSpacing.small) {
                AtlasOnboardingProofTile(title: "Local-first", symbol: "lock.shield")
                AtlasOnboardingProofTile(title: "Sign-in optional", symbol: "person.crop.circle.badge.checkmark")
                AtlasOnboardingProofTile(title: "Review-ready", symbol: "doc.text.magnifyingglass")
                AtlasOnboardingProofTile(title: "Widgets", symbol: "rectangle.grid.2x2")
                AtlasOnboardingProofTile(title: "No sourcing", symbol: "checkmark.shield")
            }

            VStack(spacing: AtlasSpacing.small) {
                AtlasOnboardingProofTile(title: "Local-first", symbol: "lock.shield")
                AtlasOnboardingProofTile(title: "Sign-in optional", symbol: "person.crop.circle.badge.checkmark")
                AtlasOnboardingProofTile(title: "Review-ready", symbol: "doc.text.magnifyingglass")
                AtlasOnboardingProofTile(title: "No sourcing", symbol: "checkmark.shield")
            }
        }
        .padding(.top, AtlasSpacing.small)
    }
}

private struct AtlasOnboardingProofTile: View {
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: AtlasSpacing.small) {
            Image(systemName: symbol)
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(.white.opacity(0.14))
                )

            Text(title)
                .atlasTextRole(.supporting)
                .foregroundStyle(.white.opacity(0.86))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.1))
        )
    }
}

private struct AtlasOnboardingTrackTypeStep: View {
    let model: AtlasAppModel
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "What are you tracking?",
                subtitle: "Choose the setup path. Exact doses, supplies, and reminders come later."
            )

            VStack(spacing: AtlasSpacing.medium) {
                ForEach(AtlasTrackType.allCases, id: \.self) { type in
                    AtlasCompactOptionCard(
                        title: type.title,
                        subtitle: subtitle(for: type),
                        symbol: symbol(for: type),
                        isSelected: draft.trackType == type
                    ) {
                        Task {
                            await model.updateOnboardingDraft { current in
                                current.trackType = type
                                if type != .glp && type != .both {
                                    current.glp.medication = nil
                                }
                                if type != .peptide && type != .both {
                                    current.peptide.selections = []
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func subtitle(for type: AtlasTrackType) -> String {
        switch type {
        case .glp:
            "GLP schedule, reminders, logs, and review."
        case .peptide:
            "Inventory, calculator, rotation, and notes."
        case .both:
            "One command surface for multiple protocols."
        case .later:
            "Explore privately before choosing details."
        }
    }

    private func symbol(for type: AtlasTrackType) -> String {
        switch type {
        case .glp:
            "waveform.path.ecg"
        case .peptide:
            "syringe"
        case .both:
            "square.stack.3d.up"
        case .later:
            "sparkle.magnifyingglass"
        }
    }
}

private struct AtlasOnboardingJourneyStatusStep: View {
    let model: AtlasAppModel
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Where are you starting?",
                subtitle: "Atlas uses this to tune the preview without making recommendations."
            )

            VStack(spacing: AtlasSpacing.medium) {
                ForEach(AtlasOnboardingJourneyStatus.allCases, id: \.self) { status in
                    AtlasCompactOptionCard(
                        title: status.title,
                        subtitle: subtitle(for: status),
                        symbol: symbol(for: status),
                        isSelected: draft.journeyStatus == status
                    ) {
                        Task {
                            await model.updateOnboardingDraft { current in
                                current.journeyStatus = status
                            }
                        }
                    }
                }
            }
        }
    }

    private func subtitle(for status: AtlasOnboardingJourneyStatus) -> String {
        switch status {
        case .active:
            "Bring schedule, logs, and reminders together."
        case .startingSoon:
            "Set up before the first dose."
        case .changingPlan:
            "Separate current history from future changes."
        case .trackingHistory:
            "Organize past logs, exports, and context."
        case .exploring:
            "Start with the private shell."
        }
    }

    private func symbol(for status: AtlasOnboardingJourneyStatus) -> String {
        switch status {
        case .active:
            "checkmark.circle"
        case .startingSoon:
            "calendar.badge.clock"
        case .changingPlan:
            "arrow.triangle.2.circlepath"
        case .trackingHistory:
            "clock.arrow.circlepath"
        case .exploring:
            "map"
        }
    }
}

private struct AtlasOnboardingProtocolPreviewStep: View {
    let model: AtlasAppModel
    let draft: AtlasOnboardingDraft

    private let glpOptions = ["Semaglutide", "Tirzepatide", "Retatrutide", "Liraglutide", "Other GLP"]
    private let peptideOptions = ["BPC-157", "TB-500", "CJC-1295", "Ipamorelin", "GHK-Cu", "Other"]
    private let cadenceOptions = ["Weekly", "Daily", "Every few days", "Custom", "Not sure"]

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Shape the preview",
                subtitle: "Pick quick anchors now. Detailed setup happens inside Atlas."
            )

            if draft.needsGlpSetup {
                AtlasSectionCard(style: .task, title: "GLP anchor") {
                    AtlasOnboardingChipGroup(
                        options: glpOptions,
                        selected: draft.glp.medication,
                        title: "Medication family"
                    ) { value in
                        Task {
                            await model.updateOnboardingDraft { current in
                                current.glp.medication = value
                            }
                        }
                    }

                    AtlasOnboardingChipGroup(
                        options: cadenceOptions,
                        selected: draft.glp.frequency,
                        title: "Usual cadence"
                    ) { value in
                        Task {
                            await model.updateOnboardingDraft { current in
                                current.glp.frequency = value
                            }
                        }
                    }
                }
            }

            if draft.needsPeptideSetup {
                AtlasSectionCard(style: .task, title: "Peptide anchor") {
                    AtlasOnboardingMultiChipGroup(
                        options: peptideOptions,
                        selected: draft.peptide.selections,
                        title: "Current or likely peptides"
                    ) { value in
                        Task {
                            await model.updateOnboardingDraft { current in
                                if current.peptide.selections.contains(value) {
                                    current.peptide.selections.removeAll { $0 == value }
                                } else {
                                    current.peptide.selections.append(value)
                                }
                            }
                        }
                    }

                    AtlasOnboardingChipGroup(
                        options: cadenceOptions,
                        selected: draft.peptide.frequency,
                        title: "Usual cadence"
                    ) { value in
                        Task {
                            await model.updateOnboardingDraft { current in
                                current.peptide.frequency = value
                            }
                        }
                    }
                }
            }

            if draft.trackType == .later {
                AtlasSectionCard(style: .hero) {
                    Text("Start with a private shell")
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text("Atlas will open with Today, Library, Timeline, Insights, and Trust Vault ready for a first protocol when you are.")
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                    AtlasStatusBadge("No protocol required yet")
                }
            }

            AtlasOnboardingPreviewRail(draft: draft)
        }
    }
}

private struct AtlasOnboardingFocusStep: View {
    let model: AtlasAppModel
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "What should Atlas help with first?",
                subtitle: "This sets the preview and first-week emphasis. It is not medical guidance."
            )

            VStack(spacing: AtlasSpacing.medium) {
                ForEach(AtlasOnboardingFocus.allCases, id: \.self) { focus in
                    AtlasCompactOptionCard(
                        title: focus.title,
                        subtitle: subtitle(for: focus),
                        symbol: symbol(for: focus),
                        isSelected: draft.focus == focus
                    ) {
                        Task {
                            await model.updateOnboardingDraft { current in
                                current.focus = focus
                                current.glp.goal = focus.title
                                current.peptide.goal = focus.title
                            }
                        }
                    }
                }
            }
        }
    }

    private func subtitle(for focus: AtlasOnboardingFocus) -> String {
        switch focus {
        case .neverMiss:
            "Make the next action obvious."
        case .understandPatterns:
            "Connect logs, context, and trends."
        case .inventoryRunway:
            "Keep vial and supply runway visible."
        case .providerReview:
            "Prepare summaries and exports."
        case .manageStack:
            "Keep multiple protocols organized."
        case .privateRecords:
            "Use discreet labels and local-first history."
        }
    }

    private func symbol(for focus: AtlasOnboardingFocus) -> String {
        switch focus {
        case .neverMiss:
            "bell.badge"
        case .understandPatterns:
            "chart.xyaxis.line"
        case .inventoryRunway:
            "shippingbox"
        case .providerReview:
            "doc.text.magnifyingglass"
        case .manageStack:
            "square.stack.3d.up"
        case .privateRecords:
            "lock.shield"
        }
    }
}

private struct AtlasOnboardingGoalsProfileStep: View {
    let model: AtlasAppModel
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Set the goal signal",
                subtitle: "Optional, but personal. Atlas can keep goal weight, pace, and nutrition context visible without turning setup into homework."
            )

            AtlasSectionCard(style: .task, title: "Body context") {
                AtlasOnboardingNumberField(
                    title: "Current weight",
                    placeholder: "190",
                    suffix: draft.profile.weightUnit == .kg ? "kg" : "lb",
                    symbol: "scalemass",
                    text: profileNumberBinding(\.weight)
                )
                AtlasOnboardingNumberField(
                    title: "Goal weight",
                    placeholder: "165",
                    suffix: draft.profile.weightUnit == .kg ? "kg" : "lb",
                    symbol: "target",
                    text: profileNumberBinding(\.goalWeight)
                )
                AtlasOnboardingNumberField(
                    title: draft.profile.heightUnit == .cm ? "Height" : "Height in inches",
                    placeholder: draft.profile.heightUnit == .cm ? "178" : "70",
                    suffix: draft.profile.heightUnit == .cm ? "cm" : "in",
                    symbol: "ruler",
                    text: profileNumberBinding(\.height)
                )

                AtlasOnboardingChipGroup(
                    options: ["lb", "kg"],
                    selected: draft.profile.weightUnit == .kg ? "kg" : "lb",
                    title: "Weight unit"
                ) { value in
                    Task {
                        await model.updateOnboardingDraft { current in
                            current.profile.weightUnit = value == "kg" ? .kg : .lb
                        }
                    }
                }
            }

            AtlasSectionCard(style: .utility, title: "Goal rhythm") {
                AtlasOnboardingChipGroup(
                    options: ["0.5 lb/week", "1 lb/week", "1.5 lb/week", "2 lb/week"],
                    selected: paceSelection,
                    title: "Goal pace"
                ) { value in
                    Task {
                        await model.updateOnboardingDraft { current in
                            current.profile.goalPacePoundsPerWeek = paceValue(from: value)
                        }
                    }
                }

                Button {
                    AtlasFeedback.selection()
                    Task {
                        await model.updateOnboardingDraft { current in
                            current.profile.wantsNutritionTracking.toggle()
                        }
                    }
                } label: {
                    AtlasSelectableUtilityRow(
                        title: "Track calories or meals",
                        subtitle: "Use Atlas nutrition capture or connect a calorie app through Apple Health later.",
                        symbol: "fork.knife",
                        isSelected: draft.profile.wantsNutritionTracking
                    )
                }
                .buttonStyle(.plain)
            }

            AtlasSectionCard(style: .utility, title: "Why Atlas asks") {
                AtlasOnboardingValueRow(title: "Dosage context", subtitle: "Height and weight can help keep dose notes and review context organized. Atlas does not calculate medical dosing advice.", symbol: "cross.case")
                AtlasOnboardingValueRow(title: "Goal reminders", subtitle: "Goal weight and pace can power calmer progress copy, widgets, and streak context.", symbol: "flame")
            }
        }
    }

    private func profileNumberBinding(_ keyPath: WritableKeyPath<AtlasOnboardingProfile, Double?>) -> Binding<String> {
        Binding(
            get: {
                guard let value = draft.profile[keyPath: keyPath] else {
                    return ""
                }
                if value.rounded() == value {
                    return String(Int(value))
                }
                return String(value)
            },
            set: { newValue in
                let filtered = newValue.filter { $0.isNumber || $0 == "." }
                Task {
                    await model.updateOnboardingDraft { current in
                        current.profile[keyPath: keyPath] = Double(filtered)
                    }
                }
            }
        )
    }

    private var paceSelection: String? {
        guard let pace = draft.profile.goalPacePoundsPerWeek else {
            return nil
        }
        if pace.rounded() == pace {
            return "\(Int(pace)) lb/week"
        }
        return "\(pace) lb/week"
    }

    private func paceValue(from selection: String) -> Double? {
        Double(selection.replacingOccurrences(of: " lb/week", with: ""))
    }
}

private struct AtlasOnboardingHealthDisclaimerStep: View {
    let model: AtlasAppModel
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Health disclaimer",
                subtitle: "Atlas organizes your records. It does not prescribe, source, diagnose, or replace clinical judgment."
            )

            AtlasSectionCard(style: .hero) {
                AtlasOnboardingValueRow(title: "Not medical advice", subtitle: "Dose, compound, and timing decisions should come from you and a qualified clinician.", symbol: "checkmark.shield")
                AtlasOnboardingValueRow(title: "Review before acting", subtitle: "Summaries, estimates, reminders, and trends are for recordkeeping and discussion.", symbol: "doc.text.magnifyingglass")
                AtlasOnboardingValueRow(title: "You stay in control", subtitle: "You decide what to enter, connect, export, or share.", symbol: "person.crop.circle.badge.checkmark")
            }

            Button {
                AtlasFeedback.selection()
                Task {
                    await model.updateOnboardingDraft { current in
                        current.healthDisclaimerAccepted.toggle()
                    }
                }
            } label: {
                AtlasSelectableUtilityRow(
                    title: "I understand",
                    subtitle: "I will use Atlas as a tracking and review tool, not as medical advice.",
                    symbol: "checkmark.seal",
                    isSelected: draft.healthDisclaimerAccepted
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct AtlasOnboardingPrivacyPresetStep: View {
    let model: AtlasAppModel
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Choose a privacy preset",
                subtitle: "This controls labels and notification tone before any health connection prompt."
            )

            VStack(spacing: AtlasSpacing.medium) {
                ForEach(AtlasOnboardingPrivacyPreset.allCases, id: \.self) { preset in
                    AtlasCompactOptionCard(
                        title: preset.title,
                        subtitle: subtitle(for: preset),
                        symbol: symbol(for: preset),
                        isSelected: draft.privacyPreset == preset
                    ) {
                        Task {
                            await model.updateOnboardingDraft { current in
                                current.privacyPreset = preset
                                current.privacy.discreetNotifications = preset != .standard
                                current.privacy.hideSensitiveLabels = preset != .standard
                                current.privacy.biometricLater = preset == .alias
                            }
                        }
                    }
                }
            }
        }
    }

    private func subtitle(for preset: AtlasOnboardingPrivacyPreset) -> String {
        switch preset {
        case .standard:
            "Full labels in the app and straightforward reminders."
        case .discreet:
            "Sensitive labels hidden and reminders kept private by default."
        case .alias:
            "Use a different name for sensitive protocols in review and sharing surfaces."
        }
    }

    private func symbol(for preset: AtlasOnboardingPrivacyPreset) -> String {
        switch preset {
        case .standard:
            "checkmark.shield"
        case .discreet:
            "eye.slash"
        case .alias:
            "person.text.rectangle"
        }
    }
}

private struct AtlasOnboardingPremiumPreviewStep: View {
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Your private command center",
                subtitle: "A preview of the premium surfaces Atlas will unlock before you build the exact protocol."
            )

            AtlasSectionCard(style: .hero) {
                Text(previewTitle)
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text("Built around \(draft.focus?.title.lowercased() ?? "private protocol tracking"), with local-first records and bounded review outputs.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                AtlasStatusBadge("Preview only")
            }

            VStack(spacing: AtlasSpacing.medium) {
                ForEach(previewItems, id: \.title) { item in
                    AtlasPremiumPreviewCard(item: item)
                }
            }
        }
    }

    private var previewTitle: String {
        switch draft.trackType {
        case .glp:
            return "\(draft.glp.medication ?? "GLP") tracking, organized"
        case .peptide:
            return peptideTitle
        case .both:
            return "Stack-aware tracking, organized"
        case .later, .none:
            return "A private protocol system, organized"
        }
    }

    private var peptideTitle: String {
        if let first = draft.peptide.selections.first {
            return "\(first) tracking, organized"
        }
        return "Peptide tracking, organized"
    }

    private var previewItems: [AtlasPremiumPreviewItem] {
        [
            .init(
                title: "Today command surface",
                detail: "Next due, overdue, recovery, and one-thumb capture stay visible without turning the root into a feature pile.",
                symbol: "checklist.checked",
                badge: "Action"
            ),
            .init(
                title: "Medication-level estimates",
                detail: "Supported compounds can show planning estimates based on saved schedule data, not serum claims.",
                symbol: "waveform.path.ecg",
                badge: "Estimate"
            ),
            .init(
                title: "Inventory runway",
                detail: "Vials, photos, supplies, calculator profiles, and low-stock review live beside the protocol.",
                symbol: "shippingbox",
                badge: "Runway"
            ),
            .init(
                title: "Weekly review and exports",
                detail: "Generate bounded local summaries and provider-ready review outputs without sourcing or medical advice.",
                symbol: "doc.text.magnifyingglass",
                badge: "Review"
            ),
            .init(
                title: "Widgets and quick capture",
                detail: "Optional widgets, shortcuts, and privacy-aware capture keep the system useful outside the app.",
                symbol: "rectangle.grid.2x2",
                badge: "System"
            )
        ]
    }
}

private struct AtlasOnboardingTrustVaultRevealStep: View {
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Trust Vault protects the sensitive parts",
                subtitle: "Privacy is not a setting buried later. It shapes how Atlas labels, exports, and shares protocol context."
            )

            AtlasSectionCard(style: .hero) {
                HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                    AtlasOnboardingSymbol(symbol: "lock.shield")
                    VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                        Text(trustTitle)
                            .atlasTextRole(.cardTitle)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text("Use full labels, discreet labels, or aliases. Alias means Atlas can show a safer alternate name instead of the real protocol label.")
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                AtlasStatusBadge("Local-first control", tint: AtlasPalette.primary)
            }

            AtlasSectionCard(style: .utility, title: "Trust surfaces") {
                AtlasOnboardingValueRow(title: "Discreet rendering", subtitle: "Hide sensitive names in reminders and everyday surfaces.", symbol: "eye.slash")
                AtlasOnboardingValueRow(title: "Alias-safe sharing", subtitle: "Use alternate names in review and export outputs instead of exposing sensitive protocol labels.", symbol: "person.text.rectangle")
                AtlasOnboardingValueRow(title: "Deliberate unlocks", subtitle: "Sensitive actions can require an intentional Trust Vault gate.", symbol: "lock.open")
            }
        }
    }

    private var trustTitle: String {
        switch draft.privacyPreset {
        case .alias:
            "Alias mode is ready"
        case .discreet:
            "Discreet mode is ready"
        case .standard:
            "Full-label mode is ready"
        case .none:
            "Privacy posture is ready"
        }
    }
}

private struct AtlasOnboardingCompanionPreviewStep: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var companionNameText = ""

    let model: AtlasAppModel
    let draft: AtlasOnboardingDraft

    private let primarySelection: AtlasMascotSelection = .aetherion
    private let secondarySelection: AtlasMascotSelection = .aurielle

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "A companion, not a gimmick",
                subtitle: "Choose a color signal for companion, streak, and widget moments."
            )

            AtlasSectionCard(style: .reward) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: AtlasSpacing.medium) {
                        heroSticker
                        heroCopy
                    }

                    VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                        heroSticker
                        heroCopy
                    }
                }
            }

            AtlasSectionCard(style: .task, title: "Companion name") {
                HStack(alignment: .center, spacing: AtlasSpacing.medium) {
                    AtlasOnboardingSymbol(symbol: "tag")

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name your companion")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        TextField("Optional nickname", text: $companionNameText)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                            .padding(.horizontal, AtlasSpacing.medium)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(AtlasPalette.surfaceSecondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(AtlasPalette.border.opacity(0.78), lineWidth: 1)
                            )
                            .accessibilityLabel("Companion nickname")
                        Text("Leave it blank to use the default companion name.")
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AtlasSpacing.medium) {
                    colorChoice(for: primarySelection)
                    colorChoice(for: secondarySelection)
                }

                VStack(spacing: AtlasSpacing.medium) {
                    colorChoice(for: primarySelection)
                    colorChoice(for: secondarySelection)
                }
            }

            AtlasSectionCard(style: .utility, title: "Companion signals") {
                AtlasOnboardingValueRow(title: "Missed-action recovery", subtitle: "Helpful prompts when a protocol step needs attention.", symbol: "arrow.clockwise.circle")
                AtlasOnboardingValueRow(title: "Goal streaks", subtitle: "Progress can show beside the companion without pressure.", symbol: "flame")
                AtlasOnboardingValueRow(title: "Evolution moments", subtitle: "Milestones feel visible when the routine holds together.", symbol: "sparkles")
            }
        }
        .onAppear {
            companionNameText = draft.profile.mascotNickname ?? ""
        }
        .onChange(of: companionNameText) { _, newValue in
            let limited = String(newValue.prefix(24))
            if limited != newValue {
                companionNameText = limited
                return
            }

            Task {
                await model.updateOnboardingDraft { current in
                    let trimmed = limited.trimmingCharacters(in: .whitespacesAndNewlines)
                    current.profile.mascotNickname = trimmed.isEmpty ? nil : trimmed
                }
            }
        }
    }

    private var stickerSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 82 : 124
    }

    private var heroSticker: some View {
        AtlasMascotSticker(line: atlasMascotLine(for: selectedSelection), stage: .stage1, size: stickerSize)
            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : stickerSize, alignment: .leading)
    }

    private var heroCopy: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            Text(companionDisplayName)
                .atlasTextRole(.cardTitle)
                .foregroundStyle(AtlasPalette.textPrimary)
            Text("\(atlasCompanionColorTitle(for: selectedSelection)) carries through companion, goal, and evolution moments.")
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            AtlasStatusBadge("Goal streaks + evolutions", tint: atlasMascotLineTint(for: selectedSelection))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var selectedSelection: AtlasMascotSelection {
        draft.profile.mascotSelection ?? primarySelection
    }

    private var companionDisplayName: String {
        atlasMascotSanitizedNickname(draft.profile.mascotNickname)
            ?? selectedSelection.title(for: .stage1)
    }

    private func colorChoice(for selection: AtlasMascotSelection) -> some View {
        Button {
            AtlasFeedback.selection()
            Task {
                await model.updateOnboardingDraft { current in
                    current.profile.mascotSelection = selection
                }
            }
        } label: {
            AtlasMascotMiniCard(selection: selection, isSelected: selectedSelection == selection)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(atlasCompanionColorTitle(for: selection))
        .accessibilityValue(selectedSelection == selection ? "Selected" : "Not selected")
    }
}

private struct AtlasOnboardingReadinessLoopStep: View {
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Build consistency without noise",
                subtitle: "Atlas turns repeated care into calm readiness signals instead of coins, leaderboards, or pressure."
            )

            AtlasSectionCard(style: .reward) {
                Text("First-week readiness")
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text("The system tracks whether your protocol is prepared, protected, and review-ready.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AtlasSpacing.small) {
                    AtlasReadinessSignalTile(title: "Prepared", value: "Setup", symbol: "checkmark.seal", tint: AtlasPalette.success)
                    AtlasReadinessSignalTile(title: "Protected", value: draft.privacyPreset?.title ?? "Privacy", symbol: "lock.shield", tint: AtlasPalette.primary)
                    AtlasReadinessSignalTile(title: "Review-ready", value: "Weekly", symbol: "doc.text.magnifyingglass", tint: AtlasPalette.reward)
                    AtlasReadinessSignalTile(title: "Continuity", value: "Next action", symbol: "calendar.badge.clock", tint: AtlasPalette.success)
                }
            }

            AtlasSectionCard(style: .utility, title: "What counts") {
                AtlasOnboardingValueRow(title: "Dose and log continuity", subtitle: "See the next useful action without shame or streak loss.", symbol: "checklist.checked")
                AtlasOnboardingValueRow(title: "Inventory preparedness", subtitle: "Runway and supplies stay visible before they become urgent.", symbol: "shippingbox")
                AtlasOnboardingValueRow(title: "Review completion", subtitle: "Weekly closure becomes a calm milestone, not a chore.", symbol: "rosette")
            }
        }
    }
}

private struct AtlasOnboardingSystemSurfacesStep: View {
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Add Atlas to your Home Screen",
                subtitle: "A quick widget walkthrough keeps the companion, streak, and next action close."
            )

            VStack(spacing: AtlasSpacing.medium) {
                AtlasWidgetPreviewCard(
                    title: "Next action",
                    value: nextActionLine,
                    symbol: "calendar.badge.clock",
                    detail: "A compact glance for what needs attention."
                )
                AtlasWidgetPreviewCard(
                    title: "Inventory state",
                    value: "Runway visible",
                    symbol: "shippingbox",
                    detail: "Supplies and vial estimates stay connected to the protocol."
                )
                AtlasMascotWidgetPreviewCard()
            }

            AtlasSectionCard(style: .utility, title: "Widget setup") {
                AtlasOnboardingValueRow(title: "1. Long-press Home Screen", subtitle: "Tap the plus button when the icons start moving.", symbol: "hand.tap")
                AtlasOnboardingValueRow(title: "2. Search Atlas", subtitle: "Choose Next Action, Quick Capture, or Companion.", symbol: "magnifyingglass")
                AtlasOnboardingValueRow(title: "3. Keep the signal visible", subtitle: "Your streak, mascot, and next action can stay one glance away.", symbol: "flame")
            }
        }
    }

    private var nextActionLine: String {
        switch draft.trackType {
        case .glp:
            return "\(draft.glp.medication ?? "GLP") next due"
        case .peptide:
            return "\(draft.peptide.selections.first ?? "Peptide") next due"
        case .both:
            return "Stack next due"
        case .later, .none:
            return "Private setup"
        }
    }
}

private struct AtlasOnboardingPersonalizedUnlockStep: View {
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Your Atlas will include",
                subtitle: "This is the system you are about to unlock before building exact protocol details."
            )

            AtlasSectionCard(style: .hero) {
                Text(unlockTitle)
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text("Built around \(draft.focus?.title.lowercased() ?? "private protocol tracking"), \(draft.privacyPreset?.title.lowercased() ?? "privacy"), and visible goal progress.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            AtlasSectionCard(style: .utility, title: "Unlock summary") {
                ForEach(unlockItems, id: \.title) { item in
                    AtlasOnboardingValueRow(title: item.title, subtitle: item.subtitle, symbol: item.symbol)
                }
            }
        }
    }

    private var unlockTitle: String {
        switch draft.trackType {
        case .glp:
            return "\(draft.glp.medication ?? "GLP") command center"
        case .peptide:
            return "\(draft.peptide.selections.first ?? "Peptide") command center"
        case .both:
            return "Stack command center"
        case .later, .none:
            return "Private protocol command center"
        }
    }

    private var unlockItems: [AtlasUnlockPreviewItem] {
        [
            .init(title: "Today command surface", subtitle: "Next due, capture, recovery, and overdue states.", symbol: "checklist.checked"),
            .init(title: "Trust Vault", subtitle: "\(draft.privacyPreset?.title ?? "Privacy") posture carried into labels and exports.", symbol: "lock.shield"),
            .init(title: "Inventory runway", subtitle: "Vials, supplies, and low-stock review beside the protocol.", symbol: "shippingbox"),
            .init(title: "Goal streak", subtitle: "A visible continuity signal for the habit you chose.", symbol: "flame"),
            .init(title: "Companion color", subtitle: "A color signal carries into companion, streak, and widget moments.", symbol: "sparkles")
        ]
    }
}

private struct AtlasOnboardingTodayCommandPreviewStep: View {
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "See the daily operating loop",
                subtitle: "Today is where the protocol turns into clear next actions, recovery, inventory, privacy, and review."
            )

            AtlasSectionCard(style: .hero) {
                AtlasTodayCommandPreviewSurface(draft: draft)
            }

            AtlasSectionCard(style: .utility, title: "What stays visible") {
                AtlasOnboardingValueRow(title: "Next useful action", subtitle: "Due, overdue, and recovery states stay close without crowding the root.", symbol: "calendar.badge.clock")
                AtlasOnboardingValueRow(title: "Inventory runway", subtitle: "Protocol planning stays connected to supplies before they become urgent.", symbol: "shippingbox")
                AtlasOnboardingValueRow(title: "Trust state", subtitle: "Sensitive labels and review context respect the privacy posture you chose.", symbol: "lock.shield")
            }
        }
    }
}

private struct AtlasOnboardingProtocolChangeHistoryStep: View {
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Change plans without losing the story",
                subtitle: "Real protocols pause, shift, and restart. Atlas keeps those changes understandable for later review."
            )

            AtlasSectionCard(style: .hero) {
                Text("Protocol Change Studio")
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text("A change log can explain what happened without turning the app into a medical advice surface.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: AtlasSpacing.medium) {
                    AtlasProofTimelineRow(marker: "Start", title: "\(protocolLabel) schedule created", detail: "Track the initial cadence and setup context.", symbol: "plus.circle")
                    AtlasProofTimelineRow(marker: "Recover", title: "Missed action handled", detail: "Keep the next step clear without shame or streak pressure.", symbol: "arrow.clockwise.circle")
                    AtlasProofTimelineRow(marker: "Change", title: "Dose or cadence adjusted", detail: "Record why the plan changed and what should be reviewed.", symbol: "slider.horizontal.3")
                    AtlasProofTimelineRow(marker: "Review", title: "Context ready for handoff", detail: "Summarize changes with privacy-safe labels.", symbol: "doc.text.magnifyingglass")
                }
            }
        }
    }

    private var protocolLabel: String {
        switch draft.trackType {
        case .glp:
            return draft.glp.medication ?? "GLP"
        case .peptide:
            return draft.peptide.selections.first ?? "Peptide"
        case .both:
            return "Stack"
        case .later, .none:
            return "Protocol"
        }
    }
}

private struct AtlasOnboardingReviewOutputPreviewStep: View {
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Preview the review artifact",
                subtitle: "A plain-language summary of what you track, how long it has been active, and what changed before you share anything."
            )

            AtlasSectionCard(style: .hero) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Review summary")
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Spacer(minLength: AtlasSpacing.small)
                    AtlasStatusBadge(draft.privacyPreset?.title ?? "Private", tint: AtlasPalette.primary)
                }

                Text("Example output")
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.primary)

                VStack(spacing: AtlasSpacing.medium) {
                    AtlasReviewPreviewRow(title: "Protocol snapshot", detail: "\(protocolLabel), cadence, active duration, setup status, and current privacy mode.", symbol: "list.bullet.rectangle")
                    AtlasReviewPreviewRow(title: "Adherence context", detail: "Completed, delayed, missed, and recovered actions without moralizing language.", symbol: "checkmark.seal")
                    AtlasReviewPreviewRow(title: "Inventory runway", detail: "Supplies, vial context, and low-stock review stay beside the plan.", symbol: "shippingbox")
                    AtlasReviewPreviewRow(title: "Questions to review", detail: "A short local note area for topics to discuss with a clinician or keep for yourself.", symbol: "questionmark.bubble")
                }
            }

            AtlasSectionCard(style: .utility, title: "Boundaries") {
                AtlasOnboardingValueRow(title: "You inspect before sharing", subtitle: "Review output remains local until you intentionally export or present it.", symbol: "eye")
                AtlasOnboardingValueRow(title: "No diagnosis or sourcing", subtitle: "The artifact organizes records. It does not replace clinical judgment.", symbol: "checkmark.shield")
            }
        }
    }

    private var protocolLabel: String {
        switch draft.trackType {
        case .glp:
            return draft.glp.medication ?? "GLP"
        case .peptide:
            return draft.peptide.selections.first ?? "Peptide"
        case .both:
            return "Stack"
        case .later, .none:
            return "Private protocol"
        }
    }
}

private struct AtlasOnboardingMigrationPreviewStep: View {
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Start from where you are",
                subtitle: "Atlas does not need a perfect blank slate. You can bring current context in after the trial screen."
            )

            VStack(spacing: AtlasSpacing.medium) {
                AtlasMigrationPreviewCard(title: "Current protocol", detail: "Add the active schedule when you are ready.", symbol: "calendar")
                AtlasMigrationPreviewCard(title: "Vials and supplies", detail: "Keep supply context and inventory runway beside the protocol.", symbol: "shippingbox")
                AtlasMigrationPreviewCard(title: "History and notes", detail: "Capture prior changes, missed actions, and questions without overbuilding setup.", symbol: "clock.arrow.circlepath")
                AtlasMigrationPreviewCard(title: "Atlas data", detail: "Import or export when you need a local handoff path.", symbol: "square.and.arrow.down")
            }

            AtlasSectionCard(style: .utility, title: "Why this matters") {
                AtlasOnboardingValueRow(title: "No perfect-start pressure", subtitle: "Onboarding proves the system before asking for exact dosing details.", symbol: "checkmark.circle")
                AtlasOnboardingValueRow(title: "Progressive disclosure", subtitle: "\(draft.focus?.title ?? "Your focus") guides the first setup without stuffing every tool into the root.", symbol: "scope")
            }
        }
    }
}

private struct AtlasOnboardingTrialTimelineStep: View {
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Your 7-day trial is clear",
                subtitle: "Start premium now. The subscription renews automatically unless canceled in App Store settings before renewal."
            )

            AtlasSectionCard(style: .hero) {
                AtlasTrialTimelineRow(day: "Today", title: "Unlock Premium", detail: "Use the command surface, Trust Vault, widgets, companion signals, and review outputs.", symbol: "lock.open")
                AtlasTrialTimelineRow(day: "Day 3", title: "Check setup quality", detail: "Tune reminders, privacy posture, inventory, and the first protocol plan.", symbol: "slider.horizontal.3")
                AtlasTrialTimelineRow(day: "Day 6", title: "Review before renewal", detail: "Manage or cancel the trial from App Store subscription settings.", symbol: "calendar.badge.clock")
                AtlasTrialTimelineRow(day: "Day 7", title: renewalTitle, detail: "Annual and monthly plans both start with the same trial window.", symbol: "creditcard")
            }

            AtlasSectionCard(style: .utility, title: "What Atlas will not do") {
                AtlasOnboardingValueRow(title: "No sourcing", subtitle: "Atlas organizes your protocol. It does not source compounds.", symbol: "checkmark.shield")
                AtlasOnboardingValueRow(title: "No medical advice replacement", subtitle: "Review outputs stay bounded and do not replace clinician guidance.", symbol: "doc.text.magnifyingglass")
            }
        }
    }

    private var renewalTitle: String {
        switch draft.premiumPlan {
        case .annual:
            "Annual plan renews"
        case .monthly:
            "Monthly plan renews"
        }
    }
}

private struct AtlasUnlockPreviewItem {
    let title: String
    let subtitle: String
    let symbol: String
}

private struct AtlasPremiumPreviewItem {
    let title: String
    let detail: String
    let symbol: String
    let badge: String
}

private struct AtlasPremiumPreviewCard: View {
    let item: AtlasPremiumPreviewItem

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.medium) {
            AtlasOnboardingSymbol(symbol: item.symbol)

            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                HStack(spacing: AtlasSpacing.small) {
                    Text(item.title)
                        .atlasTextRole(.cardBody)
                        .foregroundStyle(AtlasPalette.textPrimary)
                    AtlasStatusBadge(item.badge, tint: AtlasPalette.primary)
                }

                Text(item.detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AtlasSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: AtlasPalette.shadow.opacity(0.14), radius: 10, x: 0, y: 6)
    }
}

private struct AtlasTodayCommandPreviewSurface: View {
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(AtlasPalette.primary)
                    Text(protocolLine)
                        .atlasTextRole(.cardTitle)
                        .foregroundStyle(AtlasPalette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AtlasSpacing.small)

                AtlasStatusBadge(draft.privacyPreset?.title ?? "Private", tint: AtlasPalette.primary)
            }

            VStack(spacing: AtlasSpacing.small) {
                AtlasCommandPreviewRow(title: "Next due", detail: nextDueLine, symbol: "calendar.badge.clock", tint: AtlasPalette.primary)
                AtlasCommandPreviewRow(title: "Recovery", detail: "If a step slips, Atlas shows the next useful action.", symbol: "arrow.clockwise.circle", tint: AtlasPalette.success)
                AtlasCommandPreviewRow(title: "Inventory", detail: "Runway and supplies stay connected to the protocol.", symbol: "shippingbox", tint: AtlasPalette.reward)
                AtlasCommandPreviewRow(title: "Review", detail: "Weekly context is ready without sourcing or advice claims.", symbol: "doc.text.magnifyingglass", tint: AtlasPalette.primary)
            }
        }
    }

    private var protocolLine: String {
        switch draft.trackType {
        case .glp:
            return "\(draft.glp.medication ?? "GLP") command surface"
        case .peptide:
            return "\(draft.peptide.selections.first ?? "Peptide") command surface"
        case .both:
            return "Stack command surface"
        case .later, .none:
            return "Private protocol command surface"
        }
    }

    private var nextDueLine: String {
        switch draft.trackType {
        case .glp:
            return "\(draft.glp.medication ?? "GLP") schedule ready after setup."
        case .peptide:
            return "\(draft.peptide.selections.first ?? "Peptide") schedule ready after setup."
        case .both:
            return "Multiple protocol schedules stay in one view."
        case .later, .none:
            return "Choose exact protocol details after the trial screen."
        }
    }
}

private struct AtlasCommandPreviewRow: View {
    let title: String
    let detail: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.medium) {
            Image(systemName: symbol)
                .resizable()
                .scaledToFit()
                .frame(width: 17, height: 17)
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(tint.opacity(0.14))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AtlasSpacing.small)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.65), lineWidth: 1)
        )
    }
}

private struct AtlasProofTimelineRow: View {
    let marker: String
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.medium) {
            VStack(spacing: 5) {
                AtlasOnboardingSymbol(symbol: symbol)
                Text(marker.uppercased())
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .frame(width: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AtlasSpacing.small)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.65), lineWidth: 1)
        )
    }
}

private struct AtlasReviewPreviewRow: View {
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.medium) {
            AtlasOnboardingSymbol(symbol: symbol)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct AtlasMigrationPreviewCard: View {
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.medium) {
            AtlasOnboardingSymbol(symbol: symbol)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AtlasSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: AtlasPalette.shadow.opacity(0.12), radius: 10, x: 0, y: 6)
    }
}

private struct AtlasMascotMiniCard: View {
    let selection: AtlasMascotSelection
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            AtlasMascotSticker(line: atlasMascotLine(for: selection), stage: .stage1, size: 70)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(atlasCompanionColorTitle(for: selection))
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                Text(atlasCompanionColorSubtitle(for: selection))
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                AtlasStatusBadge(isSelected ? "Selected" : "Color option", tint: atlasMascotLineTint(for: selection))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AtlasSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isSelected ? atlasMascotLineTint(for: selection).opacity(0.12) : Color.white.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(atlasMascotLineTint(for: selection).opacity(isSelected ? 0.72 : 0.34), lineWidth: isSelected ? 1.6 : 1.2)
        )
        .shadow(color: AtlasPalette.shadow.opacity(0.12), radius: 10, x: 0, y: 6)
    }
}

private func atlasCompanionColorTitle(for selection: AtlasMascotSelection) -> String {
    switch selection {
    case .aetherion:
        return "Storm blue"
    case .aurielle:
        return "Aurora cyan"
    }
}

private func atlasCompanionColorSubtitle(for selection: AtlasMascotSelection) -> String {
    switch selection {
    case .aetherion:
        return "Sharper contrast for action and streak states."
    case .aurielle:
        return "Softer glow for companion and recovery states."
    }
}

private struct AtlasReadinessSignalTile: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            Image(systemName: symbol)
                .resizable()
                .scaledToFit()
                .frame(width: 17, height: 17)
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.14))
                )

            Text(title)
                .atlasTextRole(.deckEyebrow)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Text(value)
                .atlasTextRole(.cardBody)
                .foregroundStyle(AtlasPalette.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .padding(AtlasSpacing.small)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.72), lineWidth: 1)
        )
    }
}

private struct AtlasWidgetPreviewCard: View {
    let title: String
    let value: String
    let symbol: String
    let detail: String

    var body: some View {
        HStack(alignment: .center, spacing: AtlasSpacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AtlasPalette.shellTop)
                    .frame(width: 74, height: 74)
                Image(systemName: symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(value)
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                Text(detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
        }
        .padding(AtlasSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: AtlasPalette.shadow.opacity(0.12), radius: 10, x: 0, y: 6)
    }
}

private struct AtlasMascotWidgetPreviewCard: View {
    var body: some View {
        HStack(alignment: .center, spacing: AtlasSpacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AtlasPalette.surfaceSecondary)
                    .frame(width: 74, height: 74)
                AtlasMascotSprite(line: .aetherion, stage: .stage1, pose: .happy, size: 58)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Companion state")
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text("Ready signal")
                    .atlasTextRole(.cardTitle)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                Text("Pixel art stays reserved for compact live-state surfaces.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
        }
        .padding(AtlasSpacing.medium)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AtlasPalette.reward.opacity(0.28), lineWidth: 1.2)
        )
        .shadow(color: AtlasPalette.shadow.opacity(0.12), radius: 10, x: 0, y: 6)
    }
}

private struct AtlasTrialTimelineRow: View {
    let day: String
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.medium) {
            AtlasOnboardingSymbol(symbol: symbol)

            VStack(alignment: .leading, spacing: 4) {
                Text(day)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(AtlasPalette.primary)
                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct AtlasOnboardingPaywallStep: View {
    let model: AtlasAppModel
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Start your free trial",
                subtitle: "Unlock Atlas Premium before building the exact protocol."
            )

            VStack(spacing: AtlasSpacing.medium) {
                ForEach(AtlasOnboardingPremiumPlan.allCases, id: \.self) { plan in
                    AtlasPaywallPlanCard(
                        plan: plan,
                        isSelected: draft.premiumPlan == plan
                    ) {
                        Task {
                            await model.updateOnboardingDraft { current in
                                current.premiumPlan = plan
                            }
                        }
                    }
                }
            }

            AtlasSectionCard(style: .utility, title: "Included in Premium") {
                AtlasOnboardingValueRow(title: "Unlimited active protocols", subtitle: "Run GLP, peptide, TRT, and custom protocols together.", symbol: "square.stack.3d.up")
                AtlasOnboardingValueRow(title: "Review-ready outputs", subtitle: "Weekly review, provider handoff, exports, and source-backed summaries.", symbol: "doc.text.magnifyingglass")
                AtlasOnboardingValueRow(title: "Advanced operating surfaces", subtitle: "Medication estimates, widgets, inventory runway, and command-surface controls.", symbol: "sparkles")
                AtlasOnboardingValueRow(title: "Trust Vault depth", subtitle: "Discreet and alias-safe rendering for sensitive workflows.", symbol: "lock.shield")
            }

            Text(subscriptionDisclosure)
                .atlasTextRole(.supporting)
                .foregroundStyle(AtlasPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(subscriptionDisclosure)

            HStack(spacing: AtlasSpacing.large) {
                Button("Restore Purchases") {}
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.primary)
                Button("Terms") {}
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.primary)
                Button("Privacy") {}
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.primary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var subscriptionDisclosure: String {
        switch draft.premiumPlan {
        case .annual:
            "Start with a 7-day free trial. After the trial, the annual subscription renews automatically unless canceled at least 24 hours before renewal in App Store settings."
        case .monthly:
            "Start with a 7-day free trial. After the trial, the monthly subscription renews automatically unless canceled at least 24 hours before renewal in App Store settings."
        }
    }
}

private struct AtlasPaywallPlanCard: View {
    let plan: AtlasOnboardingPremiumPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AtlasSpacing.medium) {
                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    HStack(spacing: AtlasSpacing.small) {
                        Text(plan.title)
                            .atlasTextRole(.cardBody)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        if plan == .annual {
                            AtlasStatusBadge("Best value", tint: AtlasPalette.success)
                        }
                    }

                    Text(priceLine)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(isSelected ? AtlasPalette.primary : AtlasPalette.surfaceMuted)
                        .frame(width: 28, height: 28)
                    Image(systemName: isSelected ? "checkmark" : "circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 11, height: 11)
                        .foregroundStyle(isSelected ? .white : AtlasPalette.border)
                }
            }
            .padding(AtlasSpacing.medium)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? AtlasPalette.secondaryFill : Color.white.opacity(0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? AtlasPalette.primary.opacity(0.6) : AtlasPalette.border, lineWidth: 1.2)
            )
            .shadow(color: isSelected ? AtlasPalette.primary.opacity(0.14) : AtlasPalette.shadow.opacity(0.12), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(plan.title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(priceLine)
    }

    private var priceLine: String {
        switch plan {
        case .annual:
            "7 days free, then annual billing unless canceled"
        case .monthly:
            "7 days free, then monthly billing unless canceled"
        }
    }
}

private struct AtlasOnboardingConnectAppsStep: View {
    let model: AtlasAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Connect Apple Health?",
                subtitle: "Optional. Skip now if you just want to finish setup."
            )

            AtlasSectionCard(style: .task) {
                Text("Apple Health can add weight, activity, sleep, heart, and nutrition context later. Atlas keeps working locally either way.")
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                let isConnected = model.settingsSnapshot.healthScaffold.connections.contains {
                    $0.providerKey == .appleHealth && $0.connected
                }

                AtlasStatusBadge(
                    isConnected ? "Connected" : (model.dependencies.healthKit.isAvailable() ? "Available" : "Unavailable"),
                    tint: isConnected || model.dependencies.healthKit.isAvailable() ? AtlasPalette.primary : .orange
                )
            }

            AtlasSectionCard(style: .utility, title: "What happens next") {
                AtlasOnboardingValueRow(title: "Continue", subtitle: "Finish setup without opening any system permission sheet.", symbol: "arrow.right.circle")
                AtlasOnboardingValueRow(title: "Connect Apple Health", subtitle: "Ask iOS for permission now; you can still change it later.", symbol: "heart")
                AtlasOnboardingValueRow(title: "Calories and meals", subtitle: "Atlas can use in-app nutrition capture, or import nutrition written to Apple Health by another calorie app.", symbol: "fork.knife")
            }
        }
    }
}

private struct AtlasOnboardingPlanReadyStep: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var welcomeVisible = true

    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: readyTitle,
                subtitle: "Your first setup is saved. This handoff opens Atlas with the pieces you chose instead of another wall of instructions."
            )

            AtlasSectionCard(style: .hero) {
                ZStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                        Text("Atlas is ready")
                            .atlasTextRole(.cardTitle)
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text("Atlas opens with Today, Library, Timeline, Insights, Trust Vault, widgets, and companion progress ready.")
                            .atlasTextRole(.supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .opacity(welcomeVisible ? 0 : 1)

                    if welcomeVisible {
                        Text("Welcome to your Atlas")
                            .atlasTextRole(.cardTitle)
                            .foregroundStyle(AtlasPalette.primary)
                            .transition(.opacity.combined(with: .scale(scale: reduceMotion ? 1 : 0.96)))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
                .onAppear {
                    guard welcomeVisible else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.2 : 1.25)) {
                        withAnimation(.easeInOut(duration: reduceMotion ? 0.01 : 0.45)) {
                            welcomeVisible = false
                        }
                    }
                }
            }

            AtlasSectionCard(style: .utility, title: "Setup summary") {
                AtlasOnboardingValueRow(title: "Tracking", subtitle: draft.trackType?.title ?? "Not set", symbol: "checklist")
                AtlasOnboardingValueRow(title: "Focus", subtitle: draft.focus?.title ?? "Not set", symbol: "scope")
                AtlasOnboardingValueRow(title: "Privacy", subtitle: draft.privacyPreset?.title ?? "Standard", symbol: "lock.shield")
                AtlasOnboardingValueRow(title: "Goal signal", subtitle: draft.focus?.title ?? "Choose inside Atlas", symbol: "flame")
                AtlasOnboardingValueRow(title: "Goal weight", subtitle: goalWeightLine, symbol: "target")
                AtlasOnboardingValueRow(title: "Nutrition", subtitle: draft.profile.wantsNutritionTracking ? "Calories and meals visible in setup" : "Can be enabled later", symbol: "fork.knife")
                AtlasOnboardingValueRow(title: "Companion name", subtitle: atlasMascotSanitizedNickname(draft.profile.mascotNickname) ?? "Default companion name", symbol: "tag")
                AtlasOnboardingValueRow(title: "Color", subtitle: atlasCompanionColorTitle(for: draft.profile.mascotSelection ?? .aetherion), symbol: "paintpalette")
                AtlasOnboardingValueRow(title: "Access", subtitle: accessLine, symbol: "creditcard")
            }
        }
    }

    private var readyTitle: String {
        draft.paywallChoice == .trialStarted ? "Premium is ready" : "Basic tracking is ready"
    }

    private var accessLine: String {
        switch draft.paywallChoice {
        case .trialStarted:
            return "\(draft.premiumPlan.title) trial selected"
        case .basic:
            return "Basic local tracking"
        case .none:
            return "Not set"
        }
    }

    private var goalWeightLine: String {
        guard let goalWeight = draft.profile.goalWeight else {
            return "Can be set later"
        }
        let unit = draft.profile.weightUnit?.rawValue ?? "lb"
        let weight = goalWeight.rounded() == goalWeight ? String(Int(goalWeight)) : String(goalWeight)
        if let pace = draft.profile.goalPacePoundsPerWeek {
            let paceLabel = pace.rounded() == pace ? String(Int(pace)) : String(pace)
            return "\(weight) \(unit), \(paceLabel) lb/week"
        }
        return "\(weight) \(unit)"
    }
}

private struct AtlasOnboardingPreviewRail: View {
    let draft: AtlasOnboardingDraft

    var body: some View {
        AtlasSectionCard(style: .utility, title: "Preview will include") {
            AtlasOnboardingValueRow(title: "Next action", subtitle: nextActionLine, symbol: "calendar.badge.clock")
            AtlasOnboardingValueRow(title: "Privacy mode", subtitle: draft.privacyPreset?.title ?? "Choose on next step", symbol: "lock.shield")
            AtlasOnboardingValueRow(title: "Review output", subtitle: "Weekly recap and provider-ready summaries remain bounded and source-backed.", symbol: "doc.text.magnifyingglass")
        }
    }

    private var nextActionLine: String {
        switch draft.trackType {
        case .glp:
            return "\(draft.glp.medication ?? "GLP") schedule preview"
        case .peptide:
            return "\(draft.peptide.selections.first ?? "Peptide") schedule preview"
        case .both:
            return "Stack dashboard preview"
        case .later, .none:
            return "Private shell preview"
        }
    }
}

private struct AtlasOnboardingChipGroup: View {
    let options: [String]
    let selected: String?
    let title: String
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(AtlasPalette.textPrimary)

            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(options, id: \.self) { option in
                    AtlasOnboardingChip(
                        title: option,
                        isSelected: selected == option
                    ) {
                        onSelect(option)
                    }
                }
            }
        }
    }
}

private struct AtlasOnboardingMultiChipGroup: View {
    let options: [String]
    let selected: [String]
    let title: String
    let onToggle: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(AtlasPalette.textPrimary)

            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(options, id: \.self) { option in
                    AtlasOnboardingChip(
                        title: option,
                        isSelected: selected.contains(option)
                    ) {
                        onToggle(option)
                    }
                }
            }
        }
    }
}

private struct AtlasOnboardingChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(isSelected ? .white : AtlasPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.86)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? AtlasPalette.primary : AtlasPalette.surfaceSecondary)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isSelected ? AtlasPalette.primary.opacity(0.65) : AtlasPalette.border.opacity(0.8), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

private struct AtlasOnboardingTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            Text(title)
                .atlasTextRole(.screenTitle)
                .foregroundStyle(AtlasPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .atlasTextRole(.screenSubtitle)
                .foregroundStyle(AtlasPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct AtlasOnboardingNumberField: View {
    let title: String
    let placeholder: String
    let suffix: String
    let symbol: String
    @Binding var text: String

    var body: some View {
        HStack(alignment: .center, spacing: AtlasSpacing.medium) {
            AtlasOnboardingSymbol(symbol: symbol)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                HStack(spacing: AtlasSpacing.small) {
                    TextField(placeholder, text: $text)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(suffix)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                .padding(.horizontal, AtlasSpacing.medium)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AtlasPalette.surfaceSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AtlasPalette.border.opacity(0.78), lineWidth: 1)
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct AtlasSelectableUtilityRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.medium) {
            AtlasOnboardingSymbol(symbol: symbol)

            VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(subtitle)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                AtlasStatusBadge(isSelected ? "Selected" : "Tap to select", tint: isSelected ? AtlasPalette.primary : AtlasPalette.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                Circle()
                    .fill(isSelected ? AtlasPalette.primary : AtlasPalette.surfaceMuted)
                    .frame(width: 28, height: 28)
                Image(systemName: isSelected ? "checkmark" : "circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 11, height: 11)
                    .foregroundStyle(isSelected ? .white : AtlasPalette.border)
            }
        }
        .padding(AtlasSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isSelected ? AtlasPalette.secondaryFill : Color.white.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? AtlasPalette.primary.opacity(0.58) : AtlasPalette.border, lineWidth: 1.2)
        )
        .shadow(color: isSelected ? AtlasPalette.primary.opacity(0.14) : AtlasPalette.shadow.opacity(0.12), radius: 10, x: 0, y: 6)
    }
}

private struct AtlasCompactOptionCard: View {
    let title: String
    let subtitle: String
    let symbol: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                AtlasOnboardingSymbol(symbol: symbol)

                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(subtitle)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(AtlasPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    AtlasStatusBadge(isSelected ? "Selected" : "Tap to choose", tint: isSelected ? AtlasPalette.primary : AtlasPalette.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

                ZStack {
                    Circle()
                        .fill(isSelected ? AtlasPalette.primary : AtlasPalette.surfaceMuted)
                        .frame(width: 28, height: 28)
                    Image(systemName: isSelected ? "checkmark" : "circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 11, height: 11)
                        .foregroundStyle(isSelected ? .white : AtlasPalette.border)
                }
            }
            .padding(AtlasSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? AtlasPalette.secondaryFill : Color.white.opacity(0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? AtlasPalette.primary.opacity(0.55) : AtlasPalette.border, lineWidth: 1.2)
            )
            .shadow(color: isSelected ? AtlasPalette.primary.opacity(0.14) : AtlasPalette.shadow.opacity(0.12), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(subtitle)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

private struct AtlasOnboardingSymbol: View {
    let symbol: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(AtlasPalette.secondaryFill)
                .frame(width: 46, height: 46)
            Image(systemName: symbol)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(AtlasPalette.primary)
        }
        .accessibilityHidden(true)
    }
}

private struct AtlasOnboardingValueRow: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.medium) {
            AtlasOnboardingSymbol(symbol: symbol)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(subtitle)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat
    var rowSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX > 0, currentX + size.width > width {
                currentX = 0
                currentY += rowHeight + rowSpacing
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: width, height: currentY + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX > bounds.minX, currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += rowHeight + rowSpacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

private enum AtlasKeyboard {
    static func dismiss() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
    }
}
