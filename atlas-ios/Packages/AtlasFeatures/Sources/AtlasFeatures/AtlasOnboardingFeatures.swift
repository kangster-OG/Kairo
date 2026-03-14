import AtlasDesignSystem
import AtlasDomain
import SwiftUI

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

        ZStack {
            LinearGradient(
                colors: [AtlasPalette.background, AtlasPalette.canvas],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

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
                    .padding(.top, AtlasSpacing.large)
                    .padding(.bottom, 120)
                }

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
        case .connectApps:
            "View scaffold"
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
        VStack(spacing: AtlasSpacing.medium) {
            HStack {
                if step != .splash {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(.white.opacity(0.94))
                            )
                    }
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }
                Spacer()
                Text("Atlas")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }

            if step != .splash {
                ProgressView(value: Double(progressIndex), total: Double(max(totalSteps, 1)))
                    .tint(AtlasPalette.primary)
            }
        }
        .padding(.horizontal, AtlasSpacing.large)
        .padding(.top, AtlasSpacing.medium)
        .padding(.bottom, AtlasSpacing.small)
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
        .padding(.bottom, AtlasSpacing.large)
        .background(.white.opacity(0.96))
    }
}

private struct AtlasOnboardingSplash: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            Spacer(minLength: 60)
            Text("Atlas")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(AtlasPalette.textPrimary)
            Text("A local-first home for protocols, reminders, inventory, and privacy-forward tracking.")
                .font(.title3.weight(.medium))
                .foregroundStyle(AtlasPalette.textSecondary)
            Spacer(minLength: 180)
        }
    }
}

private struct AtlasOnboardingIntro: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasSectionCard {
                Text("All your tracking in one place")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text("Atlas keeps your schedule, logging, reminders, inventory, and privacy settings together without making a cloud account mandatory.")
                    .foregroundStyle(AtlasPalette.textSecondary)
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
                subtitle: "Guest mode is fully supported, and account scaffolding remains optional."
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
            "Set up the account boundary now. Sync stays optional and scaffold-only."
        case .signIn:
            "Use the account boundary path without blocking local access."
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

            AtlasSectionCard {
                TextField(
                    "Gender",
                    text: Binding(
                        get: { draft.profile.gender ?? "" },
                        set: { newValue in
                            Task {
                                await model.updateOnboardingDraft { current in
                                    current.profile.gender = newValue.nilIfBlank
                                }
                            }
                        }
                    )
                )
                .textFieldStyle(.roundedBorder)

                TextField(
                    "Age",
                    text: intBinding(draft.profile.age)
                )
                .textFieldStyle(.roundedBorder)

                TextField(
                    "Goal weight",
                    text: numericBinding(draft.profile.goalWeight) { current, newValue in
                        current.profile.goalWeight = newValue
                    }
                )
                .textFieldStyle(.roundedBorder)

                TextField(
                    "Current height",
                    text: numericBinding(draft.profile.height) { current, newValue in
                        current.profile.height = newValue
                    }
                )
                .textFieldStyle(.roundedBorder)

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

                TextField(
                    "Current weight",
                    text: numericBinding(draft.profile.weight) { current, newValue in
                        current.profile.weight = newValue
                    }
                )
                .textFieldStyle(.roundedBorder)

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
            }
        }
    }

    private func intBinding(_ value: Int?) -> Binding<String> {
        Binding(
            get: { value.map(String.init) ?? "" },
            set: { newValue in
                Task {
                    await model.updateOnboardingDraft { current in
                        current.profile.age = Int(newValue)
                    }
                }
            }
        )
    }

    private func numericBinding(
        _ value: Double?,
        update: @escaping (inout AtlasOnboardingDraft, Double?) -> Void
    ) -> Binding<String> {
        Binding(
            get: { value.map { String($0) } ?? "" },
            set: { newValue in
                Task {
                    await model.updateOnboardingDraft { current in
                        update(&current, Double(newValue))
                    }
                }
            }
        )
    }
}

private struct AtlasOnboardingGlpStep: View {
    let model: AtlasAppModel
    let draft: AtlasOnboardingDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.large) {
            AtlasOnboardingTitle(
                title: "GLP setup",
                subtitle: "Capture the core GLP details now. This stays editable later with native protocol flows."
            )

            AtlasSectionCard {
                ForEach(glpFields, id: \.title) { field in
                    TextField(
                        field.title,
                        text: binding(for: field.key)
                    )
                    .textFieldStyle(.roundedBorder)
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

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: {
                switch key {
                case "medication": draft.glp.medication ?? ""
                case "frequency": draft.glp.frequency ?? ""
                case "injectionDay": draft.glp.injectionDay ?? ""
                case "dose": draft.glp.dose ?? ""
                case "duration": draft.glp.duration ?? ""
                case "goal": draft.glp.goal ?? ""
                default: draft.glp.challenge ?? ""
                }
            },
            set: { newValue in
                Task {
                    await model.updateOnboardingDraft { current in
                        switch key {
                        case "medication": current.glp.medication = newValue.nilIfBlank
                        case "frequency": current.glp.frequency = newValue.nilIfBlank
                        case "injectionDay": current.glp.injectionDay = newValue.nilIfBlank
                        case "dose": current.glp.dose = newValue.nilIfBlank
                        case "duration": current.glp.duration = newValue.nilIfBlank
                        case "goal": current.glp.goal = newValue.nilIfBlank
                        default: current.glp.challenge = newValue.nilIfBlank
                        }
                    }
                }
            }
        )
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
                subtitle: "Choose your current peptides and the basics you want reflected in the native shell."
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
                TextField("Frequency", text: binding(for: "frequency"))
                    .textFieldStyle(.roundedBorder)
                TextField("Experience", text: binding(for: "experience"))
                    .textFieldStyle(.roundedBorder)
                TextField("Usual time", text: binding(for: "usualTime"))
                    .textFieldStyle(.roundedBorder)
                TextField("Current dose", text: binding(for: "dose"))
                    .textFieldStyle(.roundedBorder)
                TextField("Main goal", text: binding(for: "goal"))
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: {
                switch key {
                case "frequency": draft.peptide.frequency ?? ""
                case "experience": draft.peptide.experience ?? ""
                case "usualTime": draft.peptide.usualTime ?? ""
                case "dose": draft.peptide.dose ?? ""
                default: draft.peptide.goal ?? ""
                }
            },
            set: { newValue in
                Task {
                    await model.updateOnboardingDraft { current in
                        switch key {
                        case "frequency": current.peptide.frequency = newValue.nilIfBlank
                        case "experience": current.peptide.experience = newValue.nilIfBlank
                        case "usualTime": current.peptide.usualTime = newValue.nilIfBlank
                        case "dose": current.peptide.dose = newValue.nilIfBlank
                        default: current.peptide.goal = newValue.nilIfBlank
                        }
                    }
                }
            }
        )
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
                AtlasStatusBadge(
                    model.dependencies.healthKit.isAvailable() ? "Available later" : "Unavailable",
                    tint: model.dependencies.healthKit.isAvailable() ? AtlasPalette.primary : .orange
                )
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

private struct AtlasOnboardingTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(AtlasPalette.textPrimary)
            Text(subtitle)
                .foregroundStyle(AtlasPalette.textSecondary)
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
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AtlasPalette.primary : AtlasPalette.border)
            }
            .padding(AtlasSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white.opacity(0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? AtlasPalette.primary : AtlasPalette.border, lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AtlasToggleRow: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(AtlasPalette.textPrimary)
                Spacer()
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isOn ? AtlasPalette.primary : AtlasPalette.border)
            }
        }
        .buttonStyle(.plain)
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
