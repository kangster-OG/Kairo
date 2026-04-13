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
        let progressIndex = sequence.filter { $0 != .splash }.firstIndex(of: step).map { $0 + 1 } ?? 0
        let totalSteps = sequence.filter { $0 != .splash }.count

        GeometryReader { proxy in
            ZStack {
                AtlasAppBackground()

                VStack(spacing: 0) {
                    AtlasOnboardingHeader(
                        step: step,
                        progressIndex: progressIndex,
                        totalSteps: totalSteps,
                        onBack: {
                            model.retreatOnboarding()
                        }
                    )

                    ScrollView {
                        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
                            if let error = model.loadErrorMessage {
                                AtlasSectionCard {
                                    Text(error)
                                        .foregroundStyle(.red)
                                }
                            }

                            content(for: step, draft: draft)
                        }
                        .padding(.horizontal, AtlasSpacing.large)
                        .padding(.top, step == .splash ? AtlasSpacing.large : 36)
                        .padding(.bottom, 132)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .scrollDismissesKeyboard(.interactively)

                    AtlasOnboardingFooter(
                        primaryTitle: primaryTitle(for: step),
                        secondaryTitle: secondaryTitle(for: step),
                        isPrimaryDisabled: primaryDisabled(for: step, draft: draft),
                        onPrimary: {
                            Task {
                                await handlePrimaryAction(for: step, draft: draft)
                            }
                        },
                        onSecondary: secondaryAction(for: step, draft: draft)
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
                Button("Done") {
                    AtlasKeyboard.dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private func content(for step: AtlasOnboardingStep, draft: AtlasOnboardingDraft) -> some View {
        switch step {
        case .splash:
            AtlasOnboardingSplash()
        case .intro:
            AtlasOnboardingIntro()
        case .accountMode:
            AtlasOnboardingAccountModeStep(model: model, draft: draft)
        case .privacyMode:
            AtlasOnboardingPrivacyStep(model: model, draft: draft)
        case .trackType:
            AtlasOnboardingTrackTypeStep(model: model, draft: draft)
        case .profile:
            AtlasOnboardingProfileStep(model: model, draft: draft)
        case .mascot:
            AtlasOnboardingMascotStep(model: model, draft: draft)
        case .glpSetup:
            AtlasOnboardingGlpStep(model: model, draft: draft)
        case .peptideSetup:
            AtlasOnboardingPeptideStep(model: model, draft: draft)
        case .connectApps:
            AtlasOnboardingConnectAppsStep(model: model)
        case .planReady:
            AtlasOnboardingPlanReadyStep(draft: draft)
        }
    }

    private func primaryTitle(for step: AtlasOnboardingStep) -> String {
        switch step {
        case .splash:
            "Continue"
        case .intro:
            "Get started"
        case .connectApps:
            "Connect later"
        case .planReady:
            "Open Atlas"
        default:
            "Continue"
        }
    }

    private func secondaryTitle(for step: AtlasOnboardingStep) -> String? {
        switch step {
        case .intro:
            "Sign in"
        case .profile, .mascot, .glpSetup, .peptideSetup:
            "Skip for now"
        case .connectApps:
            "Open later"
        default:
            nil
        }
    }

    private func secondaryAction(for step: AtlasOnboardingStep, draft: AtlasOnboardingDraft) -> (() -> Void)? {
        switch step {
        case .intro:
            return {
                Task {
                    await model.updateOnboardingDraft { current in
                        current.accountMode = .signIn
                    }
                    model.activeOnboardingStep = .accountMode
                }
            }
        case .profile, .mascot, .glpSetup, .peptideSetup:
            return {
                AtlasKeyboard.dismiss()
                model.advanceOnboarding()
            }
        case .connectApps:
            return {
                Task {
                    await model.updateOnboardingDraft { current in
                        current.healthConnectionPromptSeen = true
                    }
                }
            }
        default:
            return nil
        }
    }

    private func primaryDisabled(for step: AtlasOnboardingStep, draft: AtlasOnboardingDraft) -> Bool {
        switch step {
        case .accountMode:
            draft.accountMode == nil
        case .trackType:
            draft.trackType == nil
        case .planReady:
            draft.isComplete == false
        default:
            false
        }
    }

    private func handlePrimaryAction(for step: AtlasOnboardingStep, draft: AtlasOnboardingDraft) async {
        switch step {
        case .connectApps:
            AtlasKeyboard.dismiss()
            await model.updateOnboardingDraft { current in
                current.healthConnectionPromptSeen = true
            }
            model.advanceOnboarding()
        case .planReady:
            AtlasKeyboard.dismiss()
            await model.completeOnboarding()
        default:
            AtlasKeyboard.dismiss()
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
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(.white.opacity(0.14))
                                )
                        }
                        .accessibilityLabel("Go back")
                        .accessibilityHint("Returns to the previous onboarding step.")
                        Spacer()
                        Text("Atlas")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Color.clear.frame(width: 36, height: 36)
                    }

                    ProgressView(value: Double(progressIndex), total: Double(max(totalSteps, 1)))
                        .tint(.white)
                }
                .padding(.horizontal, AtlasSpacing.large)
                .padding(.top, AtlasSpacing.small)
                .padding(.bottom, AtlasSpacing.small)
                .background(
                    LinearGradient(
                        colors: [AtlasPalette.shellTop, AtlasPalette.shellTopAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(.white.opacity(0.08))
                        .frame(height: 1)
                }
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
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AtlasPalette.primary)
            }

            Button(primaryTitle, action: onPrimary)
                .buttonStyle(AtlasPrimaryButtonStyle())
                .disabled(isPrimaryDisabled)
                .opacity(isPrimaryDisabled ? 0.55 : 1)
        }
        .padding(.horizontal, AtlasSpacing.large)
        .padding(.top, AtlasSpacing.small)
        .padding(.bottom, 18)
        .background(AtlasPalette.surfaceStrong)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AtlasPalette.border.opacity(0.7))
                .frame(height: 1)
        }
    }
}

private struct AtlasOnboardingSplash: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                splashCopy(
                    subtitle: "Local-first tracker.",
                    titleSize: 34,
                    subtitleFont: .body.weight(.semibold)
                )
            } else {
                ViewThatFits(in: .vertical) {
                    splashCopy(
                        subtitle: "A local-first home for protocols, reminders, inventory, and privacy-forward tracking.",
                        titleSize: 42,
                        subtitleFont: .title3.weight(.medium)
                    )
                    splashCopy(
                        subtitle: "Local-first tracking for schedules, reminders, inventory, and privacy.",
                        titleSize: 40,
                        subtitleFont: .body.weight(.semibold)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func splashCopy(subtitle: String, titleSize: CGFloat, subtitleFont: Font) -> some View {
        VStack(alignment: .leading, spacing: dynamicTypeSize.isAccessibilitySize ? AtlasSpacing.medium : AtlasSpacing.large) {
            Color.clear
                .frame(height: dynamicTypeSize.isAccessibilitySize ? AtlasSpacing.small : 24)
            AtlasStatusBadge("Local-first", tint: .white)
            Text("Atlas")
                .font(.system(size: titleSize, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(subtitleFont)
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : nil)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 0.72 : 1)
                .allowsTightening(dynamicTypeSize.isAccessibilitySize)
                .fixedSize(horizontal: false, vertical: !dynamicTypeSize.isAccessibilitySize)
            AtlasSectionCard {
                VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                    Text("Built for private, serious daily use")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text("Schedules, reminders, inventory, and privacy controls stay on device first, with guest access intact.")
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
            Color.clear
                .frame(height: dynamicTypeSize.isAccessibilitySize ? AtlasSpacing.medium : 96)
        }
        .padding(.horizontal, AtlasSpacing.medium)
        .padding(.vertical, 28)
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
    }
}

private struct AtlasOnboardingIntro: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasSectionCard(style: .hero) {
                Text("All your tracking in one place")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text("Atlas keeps your schedule, logging, reminders, inventory, and privacy settings together without making a cloud account mandatory.")
                    .foregroundStyle(AtlasPalette.textSecondary)
                AtlasStatusBadge("Guest-first supported")
            }

            AtlasSectionCard(style: .utility, title: "Why Atlas feels different") {
                AtlasOnboardingValueRow(
                    title: "Private by default",
                    subtitle: "Core tracking, reminders, and review data stay local-first.",
                    symbol: "lock.shield"
                )
                AtlasOnboardingValueRow(
                    title: "Cloud is optional",
                    subtitle: "You can sign in later for backup and review workflows without giving up local control.",
                    symbol: "icloud"
                )
                AtlasOnboardingValueRow(
                    title: "Built for daily use",
                    subtitle: "Schedules, inventory, and context logging stay in one calm workflow.",
                    symbol: "checklist"
                )
            }
        }
    }
}

private struct AtlasOnboardingAccountModeStep: View {
    let model: AtlasAppModel
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "How do you want to start?",
                subtitle: "Guest mode is fully supported, and you can add an account later without losing local access."
            )

            ForEach(AtlasOnboardingAccountMode.allCases, id: \.self) { mode in
                AtlasOptionCard(
                    title: mode.title,
                    subtitle: subtitle(for: mode),
                    isSelected: draft.accountMode == mode
                ) {
                    Task {
                        await model.updateOnboardingDraft { current in
                            current.accountMode = mode
                        }
                    }
                }
            }
        }
    }

    private func subtitle(for mode: AtlasOnboardingAccountMode) -> String {
        switch mode {
        case .guest:
            "Stay local-first and fully usable on this device."
        case .create:
            "Create an account now so this profile is ready for sign-in and future sync."
        case .signIn:
            "Sign in and keep local tracking available even when cloud services are unavailable."
        }
    }
}

private struct AtlasOnboardingPrivacyStep: View {
    let model: AtlasAppModel
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Choose your privacy settings",
                subtitle: "Privacy appears before any health connection prompt."
            )

            AtlasSectionCard {
                AtlasToggleRow(title: "Discreet notifications", isOn: draft.privacy.discreetNotifications) {
                    Task {
                        await model.updateOnboardingDraft { current in
                            current.privacy.discreetNotifications.toggle()
                        }
                    }
                }
                AtlasToggleRow(title: "Hide sensitive labels", isOn: draft.privacy.hideSensitiveLabels) {
                    Task {
                        await model.updateOnboardingDraft { current in
                            current.privacy.hideSensitiveLabels.toggle()
                        }
                    }
                }
                AtlasToggleRow(title: "Set up biometric lock later", isOn: draft.privacy.biometricLater) {
                    Task {
                        await model.updateOnboardingDraft { current in
                            current.privacy.biometricLater.toggle()
                        }
                    }
                }
                AtlasToggleRow(title: "Share anonymous analytics", isOn: draft.privacy.analyticsOptIn) {
                    Task {
                        await model.updateOnboardingDraft { current in
                            current.privacy.analyticsOptIn.toggle()
                        }
                    }
                }
            }
        }
    }
}

private struct AtlasOnboardingTrackTypeStep: View {
    let model: AtlasAppModel
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "What are you tracking?",
                subtitle: "Choose the branch that fits today. You can refine everything later inside the app."
            )

            ForEach(AtlasTrackType.allCases, id: \.self) { type in
                AtlasOptionCard(
                    title: type.title,
                    subtitle: subtitle(for: type),
                    isSelected: draft.trackType == type
                ) {
                    Task {
                        await model.updateOnboardingDraft { current in
                            current.trackType = type
                        }
                    }
                }
            }
        }
    }

    private func subtitle(for type: AtlasTrackType) -> String {
        switch type {
        case .glp:
            "Walk through a GLP-focused setup path."
        case .peptide:
            "Walk through a peptide-focused setup path."
        case .both:
            "Complete GLP first, then peptide."
        case .later:
            "Skip branch-specific setup for now and explore the shell first."
        }
    }
}

private struct AtlasOnboardingProfileStep: View {
    let model: AtlasAppModel
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Optional profile details",
                subtitle: "These fields stay skippable and local. Add only what helps your future insights."
            )

            AtlasSectionCard(title: "Profile") {
                AtlasOnboardingDraftField(
                    title: "Gender",
                    initialValue: draft.profile.gender ?? ""
                ) { value in
                    await model.updateOnboardingDraft { current in
                        current.profile.gender = value.nilIfBlank
                    }
                }

                Text("Atlas will preview both mascot lines and let you pick and name one on the next step.")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)

                AtlasOnboardingStepperRow(
                    title: "Age",
                    subtitle: "Use the counter for a bounded value instead of typing freeform text.",
                    value: Binding(
                        get: { draft.profile.age ?? 30 },
                        set: { newValue in
                            Task {
                                await model.updateOnboardingDraft { current in
                                    current.profile.age = newValue
                                }
                            }
                        }
                    ),
                    isEnabled: draft.profile.age != nil,
                    onEnable: {
                        Task {
                            await model.updateOnboardingDraft { current in
                                current.profile.age = current.profile.age ?? 30
                            }
                        }
                    },
                    onDisable: {
                        Task {
                            await model.updateOnboardingDraft { current in
                                current.profile.age = nil
                            }
                        }
                    },
                    range: 13...100
                )

                Picker("Height unit", selection: Binding(
                    get: { draft.profile.heightUnit ?? .cm },
                    set: { newValue in
                        Task {
                            await model.updateOnboardingDraft { current in
                                current.profile.heightUnit = newValue
                            }
                        }
                    }
                )) {
                    Text("cm").tag(AtlasHeightUnit.cm)
                    Text("ft / in").tag(AtlasHeightUnit.ftIn)
                }
                .pickerStyle(.segmented)

                AtlasOnboardingDraftField(
                    title: "Current height",
                    initialValue: draft.profile.height.map { String($0) } ?? "",
                    keyboardType: .decimalPad
                ) { value in
                    await model.updateOnboardingDraft { current in
                        current.profile.height = Double(value)
                    }
                }

                Picker("Weight unit", selection: Binding(
                    get: { draft.profile.weightUnit ?? .lb },
                    set: { newValue in
                        Task {
                            await model.updateOnboardingDraft { current in
                                current.profile.weightUnit = newValue
                            }
                        }
                    }
                )) {
                    Text("lb").tag(AtlasWeightUnit.lb)
                    Text("kg").tag(AtlasWeightUnit.kg)
                }
                .pickerStyle(.segmented)

                AtlasOnboardingDecimalStepperRow(
                    title: "Current weight",
                    subtitle: "Use quick +/- controls so Atlas starts from a real number without trapping you in the keyboard.",
                    value: Binding(
                        get: { draft.profile.weight },
                        set: { newValue in
                            Task {
                                await model.updateOnboardingDraft { current in
                                    current.profile.weight = newValue
                                }
                            }
                        }
                    ),
                    defaultValue: draft.profile.weightUnit == .kg ? 80 : 180,
                    step: draft.profile.weightUnit == .kg ? 0.5 : 1,
                    range: draft.profile.weightUnit == .kg ? 30...250 : 70...550,
                    unitLabel: draft.profile.weightUnit == .kg ? "kg" : "lb"
                )

                AtlasOnboardingDecimalStepperRow(
                    title: "Goal weight",
                    subtitle: "Optional and editable later if you want lightweight goal context in Insights.",
                    value: Binding(
                        get: { draft.profile.goalWeight },
                        set: { newValue in
                            Task {
                                await model.updateOnboardingDraft { current in
                                    current.profile.goalWeight = newValue
                                }
                            }
                        }
                    ),
                    defaultValue: draft.profile.weightUnit == .kg ? 75 : 165,
                    step: draft.profile.weightUnit == .kg ? 0.5 : 1,
                    range: draft.profile.weightUnit == .kg ? 30...250 : 70...550,
                    unitLabel: draft.profile.weightUnit == .kg ? "kg" : "lb"
                )
            }
        }
    }
}

private struct AtlasOnboardingMascotStep: View {
    let model: AtlasAppModel
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Choose and name your mascot",
                subtitle: "Pick the guardian line Atlas should use across rewards, calm continuity, celebrations, and widgets. The nickname is optional and editable later."
            )

            AtlasSectionCard(style: .utility, title: "Nickname") {
                AtlasOnboardingDraftField(
                    title: "Mascot nickname",
                    initialValue: draft.profile.mascotNickname ?? ""
                ) { value in
                    await model.updateOnboardingDraft { current in
                        current.profile.mascotNickname = value.nilIfBlank
                    }
                }

                Text("Leave it empty if you want Atlas to use the current form name instead.")
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }

            VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                Text("Evolution lines")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasPalette.primary)
                    .textCase(.uppercase)

                VStack(spacing: AtlasSpacing.medium) {
                    ForEach(AtlasMascotSelection.allCases, id: \.self) { selection in
                        AtlasOnboardingMascotChoiceCard(
                            selection: selection,
                            nickname: draft.profile.mascotNickname,
                            isSelected: draft.profile.mascotSelection == selection
                        ) {
                            Task {
                                await model.updateOnboardingDraft { current in
                                    current.profile.mascotSelection = selection
                                }
                            }
                        }
                    }
                }
            }

            AtlasSectionCard(style: .utility, title: "How Atlas uses this") {
                Text("The chosen line shows up on Today, Insights, mascot milestones, and widgets. If you skip this step, Atlas can still choose a calm starting default and you can always change it later in Settings.")
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
        }
    }
}

private struct AtlasOnboardingMascotChoiceCard: View {
    let selection: AtlasMascotSelection
    let nickname: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                    VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                        HStack(spacing: AtlasSpacing.small) {
                            Text(selection.title)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AtlasPalette.textPrimary)

                            AtlasStatusBadge(
                                isSelected ? "Selected" : "Choose",
                                tint: isSelected ? AtlasPalette.success : AtlasPalette.primary
                            )
                        }

                        Text(selection.subtitle)
                            .font(.caption)
                            .foregroundStyle(AtlasPalette.textSecondary)

                        Text(nicknamePreview)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AtlasPalette.primary)
                    }

                    Spacer(minLength: 0)

                    AtlasMascotIllustration(
                        line: atlasMascotLine(for: selection),
                        stage: .stage3,
                        size: 108
                    )
                }

                HStack(spacing: AtlasSpacing.small) {
                    AtlasOnboardingMascotStagePreview(selection: selection, stage: .stage1)
                    AtlasOnboardingMascotStagePreview(selection: selection, stage: .stage2)
                    AtlasOnboardingMascotStagePreview(selection: selection, stage: .stage3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isSelected
                                ? [Color.white.opacity(0.98), AtlasPalette.secondaryFill]
                                : [Color.white.opacity(0.96), AtlasPalette.surfaceSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? AtlasPalette.primary.opacity(0.45) : Color.white.opacity(0.82), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var nicknamePreview: String {
        guard let nickname = atlasMascotSanitizedNickname(nickname) else {
            return "Default starter name: \(selection.stage1Title)"
        }
        return "Nickname preview: \(nickname)"
    }
}

private struct AtlasOnboardingMascotStagePreview: View {
    let selection: AtlasMascotSelection
    let stage: AtlasMascotStage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AtlasMascotSprite(
                line: atlasMascotLine(for: selection),
                stage: stage,
                pose: .idle,
                size: 52
            )

            Text(selection.title(for: stage))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AtlasPalette.textPrimary)

            Text(stageLabel)
                .font(.caption2)
                .foregroundStyle(AtlasPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AtlasPalette.border.opacity(0.8), lineWidth: 1)
        )
    }

    private var stageLabel: String {
        switch stage {
        case .stage1:
            return "Starter"
        case .stage2:
            return "Evolution"
        case .stage3:
            return "Final form"
        }
    }
}

private struct AtlasOnboardingGlpStep: View {
    let model: AtlasAppModel
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "GLP setup",
                subtitle: "Add starter notes now if you want them reflected later. You can skip this and fill it in from the shell."
            )

            AtlasSectionCard {
                ForEach(glpFields, id: \.title) { field in
                    AtlasOnboardingDraftField(
                        title: field.title,
                        initialValue: value(for: field.key)
                    ) { value in
                        await model.updateOnboardingDraft { current in
                            switch field.key {
                            case "medication": current.glp.medication = value.nilIfBlank
                            case "frequency": current.glp.frequency = value.nilIfBlank
                            case "injectionDay": current.glp.injectionDay = value.nilIfBlank
                            case "dose": current.glp.dose = value.nilIfBlank
                            case "duration": current.glp.duration = value.nilIfBlank
                            case "goal": current.glp.goal = value.nilIfBlank
                            default: current.glp.challenge = value.nilIfBlank
                            }
                        }
                    }
                }
            }
        }
    }

    private var glpFields: [(title: String, key: String)] {
        [
            ("Medication", "medication"),
            ("Frequency", "frequency"),
            ("Injection day", "injectionDay"),
            ("Current dose", "dose"),
            ("Duration", "duration"),
            ("Main goal", "goal"),
            ("Biggest challenge", "challenge")
        ]
    }

    private func value(for key: String) -> String {
        switch key {
        case "medication": draft.glp.medication ?? ""
        case "frequency": draft.glp.frequency ?? ""
        case "injectionDay": draft.glp.injectionDay ?? ""
        case "dose": draft.glp.dose ?? ""
        case "duration": draft.glp.duration ?? ""
        case "goal": draft.glp.goal ?? ""
        default: draft.glp.challenge ?? ""
        }
    }
}

private struct AtlasOnboardingPeptideStep: View {
    let model: AtlasAppModel
    let draft: AtlasOnboardingDraft

    private let peptideOptions = ["BPC-157", "TB-500", "Ipamorelin", "CJC-1295", "AOD-9604"]

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Peptide setup",
                subtitle: "Add current peptides if it helps. This remains optional and editable later from the shell."
            )

            AtlasSectionCard(title: "Selections") {
                ForEach(peptideOptions, id: \.self) { option in
                    AtlasToggleRow(
                        title: option,
                        isOn: draft.peptide.selections.contains(option)
                    ) {
                        Task {
                            await model.updateOnboardingDraft { current in
                                if current.peptide.selections.contains(option) {
                                    current.peptide.selections.removeAll { $0 == option }
                                } else {
                                    current.peptide.selections.append(option)
                                }
                            }
                        }
                    }
                }
            }

            AtlasSectionCard {
                AtlasOnboardingDraftField(
                    title: "Frequency",
                    initialValue: value(for: "frequency")
                ) { value in
                    await persist(value: value, for: "frequency")
                }
                AtlasOnboardingDraftField(
                    title: "Experience",
                    initialValue: value(for: "experience")
                ) { value in
                    await persist(value: value, for: "experience")
                }
                AtlasOnboardingDraftField(
                    title: "Usual time",
                    initialValue: value(for: "usualTime")
                ) { value in
                    await persist(value: value, for: "usualTime")
                }
                AtlasOnboardingDraftField(
                    title: "Current dose",
                    initialValue: value(for: "dose")
                ) { value in
                    await persist(value: value, for: "dose")
                }
                AtlasOnboardingDraftField(
                    title: "Main goal",
                    initialValue: value(for: "goal")
                ) { value in
                    await persist(value: value, for: "goal")
                }
            }
        }
    }

    private func value(for key: String) -> String {
        switch key {
        case "frequency": draft.peptide.frequency ?? ""
        case "experience": draft.peptide.experience ?? ""
        case "usualTime": draft.peptide.usualTime ?? ""
        case "dose": draft.peptide.dose ?? ""
        default: draft.peptide.goal ?? ""
        }
    }

    private func persist(value: String, for key: String) async {
        await model.updateOnboardingDraft { current in
            switch key {
            case "frequency": current.peptide.frequency = value.nilIfBlank
            case "experience": current.peptide.experience = value.nilIfBlank
            case "usualTime": current.peptide.usualTime = value.nilIfBlank
            case "dose": current.peptide.dose = value.nilIfBlank
            default: current.peptide.goal = value.nilIfBlank
            }
        }
    }
}

private struct AtlasOnboardingConnectAppsStep: View {
    let model: AtlasAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Connect your health apps",
                subtitle: "This remains optional and non-blocking. You can come back later from Settings."
            )

            AtlasSectionCard {
                Text(model.dependencies.healthKit.connectionDescription())
                    .foregroundStyle(AtlasPalette.textSecondary)
                let isConnected = model.settingsSnapshot.healthScaffold.connections.contains {
                    $0.providerKey == .appleHealth && $0.connected
                }
                AtlasStatusBadge(
                    isConnected ? "Connected" : (model.dependencies.healthKit.isAvailable() ? "Available" : "Unavailable"),
                    tint: isConnected || model.dependencies.healthKit.isAvailable() ? AtlasPalette.primary : .orange
                )
                if model.dependencies.healthKit.isAvailable() && isConnected == false {
                    Button("Connect Apple Health") {
                        Task {
                            await model.connectHealthKit()
                            await model.updateOnboardingDraft { current in
                                current.healthConnectionPromptSeen = true
                            }
                        }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                }
            }
        }
    }
}

private struct AtlasOnboardingPlanReadyStep: View {
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "Your tracking plan is ready",
                subtitle: "Atlas will route into the native shell with guest-first, local-first behavior intact."
            )

            AtlasSectionCard(title: "Summary") {
                Text("Start mode: \(draft.accountMode?.title ?? "Not set")")
                Text("Track type: \(draft.trackType?.title ?? "Not set")")
                Text("Privacy: \(draft.privacy.hideSensitiveLabels || draft.privacy.discreetNotifications ? "Discreet" : "Full")")
                Text(draft.healthConnectionPromptSeen ? "Health prompt handled" : "Health prompt pending")
            }
        }
    }
}

private struct AtlasOnboardingDraftField: View {
    let title: String
    let keyboardType: AtlasOnboardingKeyboardType
    let persist: @Sendable (String) async -> Void

    @State private var text: String
    @State private var persistTask: Task<Void, Never>?

    init(
        title: String,
        initialValue: String,
        keyboardType: AtlasOnboardingKeyboardType = .default,
        persist: @escaping @Sendable (String) async -> Void
    ) {
        self.title = title
        self.keyboardType = keyboardType
        self.persist = persist
        _text = State(initialValue: initialValue)
    }

    var body: some View {
        field
            .onChange(of: text) { _, newValue in
                persistTask?.cancel()
                persistTask = Task {
                    try? await Task.sleep(for: .milliseconds(250))
                    guard Task.isCancelled == false else {
                        return
                    }
                    await persist(newValue)
                }
            }
            .onSubmit {
                persistTask?.cancel()
                persistTask = Task {
                    await persist(text)
                }
            }
            .onDisappear {
                persistTask?.cancel()
                let finalValue = text
                Task {
                    await persist(finalValue)
                }
            }
    }

    @ViewBuilder
    private var field: some View {
        let base = TextField(title, text: $text)
            .atlasStandaloneInputSurface()

        #if canImport(UIKit)
        base.keyboardType(keyboardType.uiKeyboardType)
        #else
        base
        #endif
    }
}

private struct AtlasOnboardingStepperRow: View {
    let title: String
    let subtitle: String
    let value: Binding<Int>
    let isEnabled: Bool
    let onEnable: () -> Void
    let onDisable: () -> Void
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer()
                if isEnabled {
                    Button("Clear", action: onDisable)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.primary)
                } else {
                    Button("Add", action: onEnable)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AtlasPalette.primary)
                }
            }

            if isEnabled {
                Stepper(value: value, in: range) {
                    Text("\(value.wrappedValue)")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                }
            }
        }
        .padding(.vertical, AtlasSpacing.xSmall)
    }
}

private struct AtlasOnboardingDecimalStepperRow: View {
    let title: String
    let subtitle: String
    let value: Binding<Double?>
    let defaultValue: Double
    let step: Double
    let range: ClosedRange<Double>
    let unitLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer()
                Button(value.wrappedValue == nil ? "Add" : "Clear") {
                    value.wrappedValue = value.wrappedValue == nil ? defaultValue : nil
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AtlasPalette.primary)
            }

            if let currentValue = value.wrappedValue {
                HStack(spacing: AtlasSpacing.small) {
                    Button {
                        value.wrappedValue = max(range.lowerBound, currentValue - step)
                    } label: {
                        Image(systemName: "minus")
                            .font(.body.weight(.semibold))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AtlasPalette.surfaceSecondary)
                    )

                    VStack(spacing: 4) {
                        Text(formatted(currentValue))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(unitLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AtlasPalette.surfaceSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AtlasPalette.border.opacity(0.8), lineWidth: 1)
                    )

                    Button {
                        value.wrappedValue = min(range.upperBound, currentValue + step)
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AtlasPalette.surfaceSecondary)
                    )
                }
            }
        }
        .padding(.vertical, AtlasSpacing.xSmall)
    }

    private func formatted(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.001 {
            return String(Int(value.rounded()))
        }
        return String(format: "%.1f", value)
    }
}

private enum AtlasOnboardingKeyboardType {
    case `default`
    case numberPad
    case decimalPad

    #if canImport(UIKit)
    var uiKeyboardType: UIKeyboardType {
        switch self {
        case .default:
            .default
        case .numberPad:
            .numberPad
        case .decimalPad:
            .decimalPad
        }
    }
    #endif
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

private struct AtlasOnboardingTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(AtlasPalette.textPrimary)
            Text(subtitle)
                .font(.body.weight(.medium))
                .foregroundStyle(AtlasPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct AtlasOptionCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: AtlasSpacing.medium) {
                VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isSelected ? AtlasPalette.textPrimary : AtlasPalette.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(isSelected ? AtlasPalette.primary : AtlasPalette.surfaceMuted)
                        .frame(width: 28, height: 28)
                    Image(systemName: isSelected ? "checkmark" : "circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isSelected ? .white : AtlasPalette.border)
                }
            }
            .padding(AtlasSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isSelected
                                ? [Color.white, AtlasPalette.secondaryFill]
                                : [Color.white.opacity(0.98), AtlasPalette.surfaceSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? AtlasPalette.primary : AtlasPalette.border, lineWidth: 1.2)
            )
            .shadow(
                color: isSelected ? AtlasPalette.primary.opacity(0.14) : AtlasPalette.shadow.opacity(0.18),
                radius: isSelected ? 18 : 10,
                x: 0,
                y: isSelected ? 12 : 6
            )
            .scaleEffect(isSelected ? 1 : 0.995)
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

private struct AtlasToggleRow: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AtlasSpacing.medium) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Spacer()
                ZStack {
                    Capsule(style: .continuous)
                        .fill(isOn ? AtlasPalette.secondaryFill : AtlasPalette.surfaceMuted)
                        .frame(width: 54, height: 30)
                    Circle()
                        .fill(isOn ? AtlasPalette.primary : Color.white)
                        .frame(width: 22, height: 22)
                        .offset(x: isOn ? 12 : -12)
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal, AtlasSpacing.medium)
            .padding(.vertical, AtlasSpacing.small)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.98), AtlasPalette.surfaceSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.82), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .animation(.spring(response: 0.24, dampingFraction: 0.82), value: isOn)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint("Double tap to toggle.")
        .accessibilityAddTraits(.isButton)
    }
}

private struct AtlasOnboardingValueRow: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AtlasPalette.secondaryFill)
                    .frame(width: 42, height: 42)
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AtlasPalette.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
