import AtlasDesignSystem
import AtlasDomain
import SwiftUI

public let atlasDreamOnboardingSceneCountForTesting = AtlasOnboardingDraft.empty().sequence().count

public let atlasDreamOnboardingChapterTitlesForTesting = [
    "Intro demo",
    "Profile setup",
    "Protocol branch",
    "Companion hatching",
    "Tracking permissions",
    "Plan generation",
    "Save progress",
    "Trial unlock"
]

public struct AtlasOnboardingFlowScreen: View {
    let model: AtlasAppModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draft: AtlasOnboardingDraft
    @State private var companionName: String

    public init(model: AtlasAppModel) {
        self.model = model
        let initialDraft = model.bootstrapSnapshot.onboardingDraft
        _draft = State(initialValue: initialDraft)
        _companionName = State(initialValue: initialDraft.profile.mascotNickname ?? "")
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            AtlasPalette.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    if step != .intro {
                        KairoOnboardingHeader(
                        currentIndex: currentIndex,
                        totalCount: sequence.count,
                        canGoBack: canGoBack,
                        onBack: goBack
                    )
                        .padding(.top, 8)
                    } else {
                        Color.clear.frame(height: 18)
                    }

                    stepContent
                        .id(step.rawValue)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))

                    Color.clear.frame(height: 108)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
            .scrollIndicators(.hidden)

            if showsFooter {
                KairoOnboardingFooter(
                    primaryTitle: primaryTitle,
                    secondaryTitle: secondaryTitle,
                    primaryAction: primaryAction,
                    secondaryAction: secondaryAction
                )
            }
        }
        .task {
            syncFromModel()
            repairActiveStepIfNeeded()
            model.recordOnboardingStepViewed(step)
        }
        .onChange(of: model.activeOnboardingStep) { _, newStep in
            syncFromModel()
            model.recordOnboardingStepViewed(newStep)
        }
        .onChange(of: draft.trackType) { _, _ in
            repairActiveStepIfNeeded()
        }
        .animation(AtlasMotion.screenEntry(reduceMotion: reduceMotion), value: step)
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: draft)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .intro:
            KairoIntroScreen()
        case .demoToday:
            KairoDemoTodayScreen(onComplete: primaryAction)
        case .demoProgress:
            KairoDemoProgressScreen(onComplete: primaryAction)
        case .gender:
            KairoOptionQuestion(
                title: "Select your gender",
                subtitle: "",
                options: ["Female", "Male", "Non-binary", "Prefer not to say"],
                selected: draft.profile.gender,
                allowsMultiple: false
            ) { value in
                updateDraft { $0.profile.gender = value }
            }
        case .age:
            KairoBirthdateQuestion(age: draft.profile.age ?? 31) { value in
                updateDraft { $0.profile.age = value }
            }
        case .goalWeight:
            KairoNumberQuestion(
                title: "What's your goal weight?",
                subtitle: "",
                value: Int(draft.profile.goalWeight ?? 165),
                range: 90...320,
                unit: "lb"
            ) { value in
                updateDraft {
                    $0.profile.goalWeight = Double(value)
                    $0.profile.weightUnit = .lb
                }
            }
        case .heightWeight:
            KairoHeightWeightScreen(
                height: Int(draft.profile.height ?? 69),
                weight: Int(draft.profile.weight ?? 175),
                onHeight: { value in updateDraft { $0.profile.height = Double(value); $0.profile.heightUnit = .ftIn } },
                onWeight: { value in updateDraft { $0.profile.weight = Double(value); $0.profile.weightUnit = .lb } }
            )
        case .trackType:
            KairoTrackTypeScreen(selection: draft.trackType) { track in
                updateDraft {
                    $0.trackType = track
                    if let track {
                        $0.journeyStatus = track == .later ? .exploring : .active
                        $0.focus = track == .glp ? .understandPatterns : .neverMiss
                        $0.privacyPreset = .discreet
                        $0.healthDisclaimerAccepted = true
                    }
                }
            }
        case .companionHatch, .companionChoice:
            KairoCompanionChoiceScreen(selection: draft.profile.mascotSelection ?? .aurielle) { selection in
                updateDraft {
                    $0.profile.mascotSelection = selection
                    if $0.profile.mascotNickname?.isEmpty ?? true {
                        $0.profile.mascotNickname = selection == .aurielle ? "Aurielle" : "Aetherion"
                    }
                }
                companionName = selection == .aurielle ? "Aurielle" : "Aetherion"
            }
        case .companionReveal:
            KairoCompanionRevealScreen(selection: draft.profile.mascotSelection ?? .aurielle) {
                Task {
                    model.advanceOnboarding()
                    syncFromModel()
                }
            }
        case .companionName:
            KairoCompanionNameScreen(
                selection: draft.profile.mascotSelection ?? .aurielle,
                name: companionNameBinding
            )
        case .companionJourney:
            KairoEvolutionScreen(selection: draft.profile.mascotSelection ?? .aurielle, name: resolvedCompanionName)
        case .usedApps:
            KairoOptionQuestion(
                title: "Have you tried other tracking apps?",
                subtitle: "",
                options: ["Yes", "No"],
                selected: draft.dreamAnswers["usedApps"],
                allowsMultiple: false
            ) { value in
                updateDraft { $0.dreamAnswers["usedApps"] = value }
            }
        case .longTermResults:
            KairoLongTermResultsScreen()
        case .branchPath:
            KairoBranchPathScreen(track: draft.trackType ?? .peptide) { track in
                updateDraft {
                    $0.trackType = track
                    $0.journeyStatus = .active
                    $0.focus = track == .glp ? .understandPatterns : .manageStack
                    $0.privacyPreset = .discreet
                    $0.healthDisclaimerAccepted = true
                }
            }
        case .glpMedication:
            KairoOptionQuestion(title: "Which GLP-1 are you currently taking?", subtitle: "Select one.", options: glpMedicationOptions, selected: draft.glp.medication, allowsMultiple: false) { value in updateDraft { $0.glp.medication = value } }
        case .glpFrequency:
            KairoOptionQuestion(title: "How often do you take it?", subtitle: "Select one.", options: ["Weekly injection", "Daily injection", "Other"], selected: draft.glp.frequency, allowsMultiple: false) { value in updateDraft { $0.glp.frequency = value } }
        case .glpInjectionDay:
            KairoOptionQuestion(title: "What day do you typically inject?", subtitle: "", options: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], selected: draft.glp.injectionDay, allowsMultiple: false, compact: true) { value in updateDraft { $0.glp.injectionDay = value } }
        case .glpInjectionTime:
            KairoOptionQuestion(title: "What time do you usually inject?", subtitle: "", options: ["Morning", "Midday", "Evening", "Bedtime"], selected: draft.glp.usualTime, allowsMultiple: false) { value in updateDraft { $0.glp.usualTime = value } }
        case .glpDose:
            KairoOptionQuestion(title: "What's your current dose?", subtitle: "", options: ["0.25 mg", "0.5 mg", "1 mg", "1.7 mg", "2.4 mg", "5 mg", "7.5 mg", "10 mg", "12.5 mg", "15 mg"], selected: draft.glp.dose, allowsMultiple: false) { value in updateDraft { $0.glp.dose = value } }
        case .glpDuration:
            KairoOptionQuestion(title: "How experienced are you?", subtitle: "Select one.", options: ["Just starting", "< 3 months", "3-12 months", "1+ years"], selected: draft.glp.duration, allowsMultiple: false) { value in updateDraft { $0.glp.duration = value } }
        case .glpGoal:
            KairoOptionQuestion(title: "What's your main goal?", subtitle: "Select one.", options: ["Lose weight", "Maintain weight", "Build muscle", "Metabolic health"], selected: draft.glp.goal, allowsMultiple: false) { value in updateDraft { $0.glp.goal = value; $0.focus = .understandPatterns } }
        case .glpChallenge:
            KairoOptionQuestion(title: "Biggest challenge right now?", subtitle: "Select one.", options: ["Cravings", "Side effects", "Forgetting doses", "Low energy", "Staying consistent"], selected: draft.glp.challenge, allowsMultiple: false) { value in updateDraft { $0.glp.challenge = value } }
        case .peptideSelection:
            KairoOptionQuestion(title: "Which peptides are you currently taking?", subtitle: "Select all that apply.", options: peptideOptions, selectedValues: Set(draft.peptide.selections), allowsMultiple: true) { values in updateDraft { $0.peptide.selections = Array(values).sorted() } }
        case .peptideFrequency:
            KairoOptionQuestion(title: "How often do you take it?", subtitle: "Select one.", options: ["Weekly injection", "2-3x a week", "Daily injection", "Other"], selected: draft.peptide.frequency, allowsMultiple: false) { value in updateDraft { $0.peptide.frequency = value } }
        case .peptideExperience:
            KairoOptionQuestion(title: "How experienced are you?", subtitle: "Select one.", options: ["Just starting", "< 3 months", "3-12 months", "1+ years"], selected: draft.peptide.experience, allowsMultiple: false) { value in updateDraft { $0.peptide.experience = value } }
        case .peptideInjectionTime:
            KairoOptionQuestion(title: "What time do you usually inject?", subtitle: "", options: ["Morning", "Midday", "Evening", "Bedtime"], selected: draft.peptide.usualTime, allowsMultiple: false) { value in updateDraft { $0.peptide.usualTime = value } }
        case .peptideDose:
            KairoOptionQuestion(title: "What's your current dose?", subtitle: "", options: ["0.25 mg", "0.5 mg", "1 mg", "2 mg", "5 mg", "Custom"], selected: draft.peptide.dose, allowsMultiple: false) { value in updateDraft { $0.peptide.dose = value } }
        case .peptideGoal:
            KairoOptionQuestion(title: "What's your main goal?", subtitle: "Select all that apply.", options: ["Fat loss", "Muscle growth", "Skin care", "Performance", "Injury / Recovery"], selected: draft.peptide.goal, allowsMultiple: false) { value in updateDraft { $0.peptide.goal = value; $0.focus = .manageStack } }
        case .connectApps:
            KairoConnectAppsScreen()
        case .ratingPrimer:
            KairoRatingPrimerScreen()
        case .trackingPermission:
            KairoTrackingPermissionScreen()
        case .planLoading:
            KairoPlanLoadingScreen {
                Task { @MainActor in
                    await model.saveOnboardingDraft(draft)
                    model.advanceOnboarding()
                    syncFromModel()
                }
            }
        case .planPreview:
            KairoPlanPreviewScreen(track: draft.trackType ?? .peptide)
        case .planReady:
            KairoPlanReadyScreen(
                track: draft.trackType ?? .peptide,
                glp: draft.glp,
                peptide: draft.peptide
            )
        case .saveProgress, .signInModal, .saveProgressAgain:
            KairoTrialIntroScreen()
        case .trialIntro:
            KairoTrialIntroScreen()
        case .trialReminder:
            KairoTrialReminderScreen()
        case .trialPaywall:
            KairoTrialPaywallScreen(plan: draft.premiumPlan) { plan in
                updateDraft { $0.premiumPlan = plan }
            }
        case .purchaseSuccess:
            KairoPurchaseSuccessScreen(
                track: draft.trackType ?? .peptide,
                glp: draft.glp,
                peptide: draft.peptide
            )
        case .homeEndpoint:
            KairoPurchaseSuccessScreen(
                track: draft.trackType ?? .peptide,
                glp: draft.glp,
                peptide: draft.peptide
            )
        }
    }

    private var step: AtlasOnboardingStep { model.activeOnboardingStep }
    private var sequence: [AtlasOnboardingStep] { draft.sequence() }
    private var currentIndex: Int { sequence.firstIndex(of: step) ?? 0 }
    private var progress: Double { sequence.isEmpty ? 0 : Double(currentIndex + 1) / Double(sequence.count) }
    private var canGoBack: Bool { currentIndex > 0 }
    private var showsFooter: Bool { step != .demoToday && step != .demoProgress && step != .planLoading && step != .companionReveal }
    private var resolvedCompanionName: String {
        let trimmed = companionName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty == false { return trimmed }
        return (draft.profile.mascotSelection ?? .aurielle) == .aurielle ? "Aurielle" : "Aetherion"
    }
    private var companionNameBinding: Binding<String> {
        Binding(
            get: { companionName },
            set: { value in
                companionName = value
                var next = draft
                next.profile.mascotNickname = value.trimmingCharacters(in: .whitespacesAndNewlines)
                draft = next
                Task { await model.saveOnboardingDraft(next) }
            }
        )
    }

    private var stepTitle: String {
        switch step {
        case .intro, .demoToday, .demoProgress: "Intro demo"
        case .gender, .age, .goalWeight, .heightWeight, .trackType: "Early setup"
        case .companionHatch, .companionChoice, .companionReveal, .companionName, .companionJourney: "Companion"
        case .usedApps, .longTermResults: "Tracking fit"
        case .branchPath: "Protocol path"
        case .glpMedication, .glpFrequency, .glpInjectionDay, .glpInjectionTime, .glpDose, .glpDuration, .glpGoal, .glpChallenge: "GLP setup"
        case .peptideSelection, .peptideFrequency, .peptideExperience, .peptideInjectionTime, .peptideDose, .peptideGoal: "Peptide setup"
        case .connectApps, .ratingPrimer, .trackingPermission: "Connections"
        case .planLoading, .planPreview, .planReady: "Your plan"
        case .saveProgress, .signInModal, .trialIntro, .trialReminder, .trialPaywall, .purchaseSuccess, .saveProgressAgain, .homeEndpoint: "Unlock Kairo"
        }
    }

    private var primaryTitle: String {
        switch step {
        case .intro: "Get started"
        case .planReady: "Let's get started"
        case .homeEndpoint: "Enter Kairo"
        case .trialPaywall: "Start 3-day free trial"
        case .purchaseSuccess: "Enter Kairo"
        default: "Next"
        }
    }

    private var secondaryTitle: String? {
        switch step {
        case .intro: "Already have an account? Sign in"
        case .connectApps: "Not now"
        case .trackingPermission: "Ask later"
        case .trialPaywall: "Continue with limited preview"
        case .signInModal: "Continue as guest"
        default: nil
        }
    }

    private var glpMedicationOptions: [String] {
        [
            "Semaglutide",
            "Tirzepatide",
            "Retatrutide",
            "Liraglutide",
            "Dulaglutide",
            "Exenatide",
            "Other"
        ]
    }

    private var peptideOptions: [String] {
        [
            "BPC-157",
            "TB-500",
            "CJC-1295 / Ipamorelin",
            "AOD-9604",
            "Retatrutide",
            "Sermorelin",
            "Tesamorelin",
            "GHK-Cu",
            "Thymosin Alpha-1",
            "Epitalon",
            "MOTS-c",
            "NAD+",
            "Other"
        ]
    }

    private func primaryAction() {
        persistDefaultsForStep()
        model.recordOnboardingFunnelEvent(.primaryTapped, step: step)

        if step == .homeEndpoint || step == .purchaseSuccess {
            Task {
                var completed = draft
                fillCompletionDefaults(&completed)
                await model.saveOnboardingDraft(completed)
                await model.completeOnboarding()
            }
            return
        }

        if step == .companionName {
            var next = draft
            next.profile.mascotNickname = resolvedCompanionName
            draft = next
        }

        if step == .trialPaywall {
            updateDraft { $0.paywallChoice = .trialStarted }
            model.recordOnboardingFunnelEvent(.trialStarted, step: step)
        }

        Task {
            await model.saveOnboardingDraft(draft)
            model.advanceOnboarding()
            syncFromModel()
        }
    }

    private func secondaryAction() {
        model.recordOnboardingFunnelEvent(.secondaryTapped, step: step)
        switch step {
        case .connectApps:
            updateDraft { $0.healthConnectionPromptSeen = true }
        case .trackingPermission:
            updateDraft {
                $0.privacy.analyticsOptIn = false
                $0.dreamAnswers["trackingPermission"] = "Later"
            }
        case .trialPaywall:
            updateDraft { $0.paywallChoice = .basic }
            model.recordOnboardingFunnelEvent(.basicSelected, step: step)
        case .signInModal:
            updateDraft { $0.accountMode = .guest }
        default:
            break
        }
        Task {
            await model.saveOnboardingDraft(draft)
            model.advanceOnboarding()
            syncFromModel()
        }
    }

    private func goBack() {
        model.recordOnboardingFunnelEvent(.backTapped, step: step)
        model.retreatOnboarding()
    }

    private func syncFromModel() {
        draft = model.bootstrapSnapshot.onboardingDraft
        companionName = draft.profile.mascotNickname ?? companionName
    }

    private func repairActiveStepIfNeeded() {
        guard sequence.contains(step) == false else { return }
        model.activeOnboardingStep = sequence.first ?? .intro
    }

    private func persistCompanionName() {
        updateDraft { $0.profile.mascotNickname = resolvedCompanionName }
    }

    private func updateDraft(_ update: (inout AtlasOnboardingDraft) -> Void) {
        var next = draft
        update(&next)
        draft = next
        Task { await model.saveOnboardingDraft(next) }
    }

    private func persistDefaultsForStep() {
        switch step {
        case .gender where draft.profile.gender == nil:
            updateDraft { $0.profile.gender = "Prefer not to say" }
        case .trackType where draft.trackType == nil:
            updateDraft { $0.trackType = .peptide; $0.journeyStatus = .active; $0.focus = .manageStack; $0.privacyPreset = .discreet; $0.healthDisclaimerAccepted = true }
        case .companionChoice where draft.profile.mascotSelection == nil:
            updateDraft { $0.profile.mascotSelection = .aurielle; $0.profile.mascotNickname = "Aurielle" }
        case .companionName:
            persistCompanionName()
        case .glpMedication where draft.glp.medication == nil:
            updateDraft { $0.glp.medication = glpMedicationOptions.first }
        case .glpFrequency where draft.glp.frequency == nil:
            updateDraft { $0.glp.frequency = "Weekly injection" }
        case .glpInjectionDay where draft.glp.injectionDay == nil:
            updateDraft { $0.glp.injectionDay = "Wed" }
        case .glpInjectionTime where draft.glp.usualTime == nil:
            updateDraft { $0.glp.usualTime = "Morning" }
        case .glpDose where draft.glp.dose == nil:
            updateDraft { $0.glp.dose = "0.5 mg" }
        case .glpDuration where draft.glp.duration == nil:
            updateDraft { $0.glp.duration = "< 3 months" }
        case .glpGoal where draft.glp.goal == nil:
            updateDraft { $0.glp.goal = "Metabolic health" }
        case .glpChallenge where draft.glp.challenge == nil:
            updateDraft { $0.glp.challenge = "Staying consistent" }
        case .peptideSelection where draft.peptide.selections.isEmpty:
            updateDraft { $0.peptide.selections = ["BPC-157"] }
        case .peptideFrequency where draft.peptide.frequency == nil:
            updateDraft { $0.peptide.frequency = "Weekly injection" }
        case .peptideExperience where draft.peptide.experience == nil:
            updateDraft { $0.peptide.experience = "Just starting" }
        case .peptideInjectionTime where draft.peptide.usualTime == nil:
            updateDraft { $0.peptide.usualTime = "Morning" }
        case .peptideDose where draft.peptide.dose == nil:
            updateDraft { $0.peptide.dose = "Custom" }
        case .peptideGoal where draft.peptide.goal == nil:
            updateDraft { $0.peptide.goal = "Performance" }
        case .connectApps:
            updateDraft { $0.healthConnectionPromptSeen = true }
            model.recordOnboardingFunnelEvent(.healthConnected, step: step)
        case .trackingPermission:
            updateDraft { $0.privacy.analyticsOptIn = true; $0.dreamAnswers["trackingPermission"] = "Allowed" }
        default:
            break
        }
    }

    private func fillCompletionDefaults(_ completed: inout AtlasOnboardingDraft) {
        completed.trackType = completed.trackType ?? .peptide
        completed.journeyStatus = completed.journeyStatus ?? .active
        completed.focus = completed.focus ?? .neverMiss
        completed.privacyPreset = completed.privacyPreset ?? .discreet
        completed.healthDisclaimerAccepted = true
        completed.healthConnectionPromptSeen = true
        completed.paywallChoice = completed.paywallChoice ?? .trialStarted
        completed.profile.mascotSelection = completed.profile.mascotSelection ?? .aurielle
        completed.profile.mascotNickname = completed.profile.mascotNickname ?? resolvedCompanionName
        completed.firstWeekPlanPreview = [
            "Confirm protocol schedule",
            "Add vial inventory",
            "Log first adherence check-in",
            "Review weekly pattern"
        ]
    }
}

private struct KairoOnboardingHeader: View {
    let currentIndex: Int
    let totalCount: Int
    let canGoBack: Bool
    let onBack: () -> Void

    var body: some View {
        ZStack {
            HStack(spacing: 6) {
                ForEach(0..<min(totalCount, 8), id: \.self) { index in
                    Capsule()
                        .fill(index == dotIndex ? AtlasPalette.primary : AtlasPalette.primary.opacity(0.18))
                        .frame(width: index == dotIndex ? 22 : 6, height: 6)
                }
            }

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(canGoBack ? AtlasPalette.primary : AtlasPalette.primary.opacity(0.28))
                        .frame(width: 30, height: 30)
                        .background(AtlasPalette.secondaryFill, in: Circle())
                }
                .disabled(canGoBack == false)
                Spacer()
            }
        }
        .frame(height: 34)
    }

    private var dotIndex: Int {
        guard totalCount > 0 else { return 0 }
        return min(7, Int((Double(currentIndex) / Double(max(1, totalCount - 1))) * 7.0))
    }
}

private struct KairoOnboardingFooter: View {
    let primaryTitle: String
    let secondaryTitle: String?
    let primaryAction: () -> Void
    let secondaryAction: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: primaryAction) {
                Text(primaryTitle)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AtlasPalette.primary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: AtlasPalette.primary.opacity(0.16), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            if let secondaryTitle {
                Button(secondaryTitle, action: secondaryAction)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AtlasPalette.secondaryText)
                    .padding(.bottom, 2)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .background(
            LinearGradient(
                colors: [AtlasPalette.background.opacity(0), AtlasPalette.background, AtlasPalette.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

private struct KairoIntroScreen: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                KairoLogoMark(size: 60)
                Text("Kairo")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(AtlasPalette.primary)
            }
            .padding(.top, 20)

            Spacer(minLength: 116)

            Text("Your unified\npeptide protocol")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AtlasPalette.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 9) {
                KairoChecklistRow("Track protocols and schedules")
                KairoChecklistRow("Monitor inventory runway")
                KairoChecklistRow("Log symptoms and adherence")
                KairoChecklistRow("Build weekly review rhythm")
            }
            .padding(.top, 22)

            Spacer(minLength: 128)
        }
        .frame(maxWidth: .infinity, minHeight: 610, alignment: .topLeading)
    }
}

private struct KairoDemoTodayScreen: View {
    let onComplete: () -> Void

    var body: some View {
        KairoAnimatedDemoScreen(
            mode: .today,
            headline: "Protocol tracking\nmade easy",
            onComplete: onComplete
        )
    }
}

private struct KairoDemoProgressScreen: View {
    let onComplete: () -> Void

    var body: some View {
        KairoAnimatedDemoScreen(
            mode: .progress,
            headline: "Progress\nmade easy",
            onComplete: onComplete
        )
    }
}

private struct KairoHeightWeightScreen: View {
    let height: Int
    let weight: Int
    let onHeight: (Int) -> Void
    let onWeight: (Int) -> Void

    var body: some View {
        KairoQuestionScaffold(title: "What's your current height and weight?", subtitle: "") {
            VStack(spacing: 12) {
                KairoStepperRow(title: "Height", value: height, range: 48...84, unit: "in", onChange: onHeight)
                KairoStepperRow(title: "Weight", value: weight, range: 90...360, unit: "lb", onChange: onWeight)
            }
        }
    }
}

private struct KairoTrackTypeScreen: View {
    let selection: AtlasTrackType?
    let onSelect: (AtlasTrackType?) -> Void

    var body: some View {
        KairoQuestionScaffold(title: "Are you currently taking any GLP-1s or peptides?", subtitle: "Select all that apply.") {
            VStack(spacing: 12) {
                KairoTrackButton(type: .glp, subtitle: "GLP protocols, adherence, side effects", selected: selection == .glp || selection == .both, action: { onSelect(toggled(.glp)) })
                KairoTrackButton(type: .peptide, subtitle: "Peptide stacks, schedules, inventory", selected: selection == .peptide || selection == .both, action: { onSelect(toggled(.peptide)) })
            }
        }
    }

    private func toggled(_ type: AtlasTrackType) -> AtlasTrackType? {
        switch (selection, type) {
        case (.none, .glp), (.later, .glp):
            .glp
        case (.none, .peptide), (.later, .peptide):
            .peptide
        case (.glp, .glp), (.peptide, .peptide):
            nil
        case (.glp, .peptide), (.peptide, .glp):
            .both
        case (.both, .glp):
            .peptide
        case (.both, .peptide):
            .glp
        case (_, .glp):
            .glp
        case (_, .peptide):
            .peptide
        default:
            type
        }
    }
}

private enum KairoCrystalVialPodPhase: Equatable {
    case dormant
    case activating
    case hatching
    case revealed
    case calibrating
    case idle

    var assetName: String {
        switch self {
        case .dormant:
            "KairoCrystalVialPodFrameDormant"
        case .activating:
            "KairoCrystalVialPodFrameAwakening"
        case .calibrating:
            "KairoCrystalVialPodFrameSwirl"
        case .hatching:
            "KairoCrystalVialPodFrameOpening"
        case .revealed, .idle:
            "KairoCrystalVialPodFrameOpened"
        }
    }

    var showsCompanion: Bool {
        switch self {
        case .hatching, .revealed, .idle:
            true
        case .dormant, .activating, .calibrating:
            false
        }
    }
}

private struct CrystalVialPodView: View {
    let phase: KairoCrystalVialPodPhase
    let companionImageName: String?
    var height: CGFloat = 320

    // Shipped native hatch animation driven by generated pod frames.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false
    @State private var particleDrift = false
    @State private var revealProgress = 0.0
    @State private var burstProgress = 0.0
    @State private var tremblePhase = false
    @State private var orbitRotation = 0.0

    var body: some View {
        ZStack {
            KairoPodAmbientGlow(active: phase != .dormant)
                .frame(width: height * 0.92, height: height * 0.92)
                .offset(y: -height * 0.02)

            if reduceMotion == false {
                KairoPodPressureAura(
                    active: phase == .activating || phase == .calibrating || phase == .hatching,
                    burstProgress: burstProgress,
                    pulse: pulse
                )
                .frame(width: height * 0.86, height: height * 0.86)
                .offset(y: -height * 0.02)
                .opacity(phase == .dormant ? 0 : 0.46)
            }

            podArtwork
                .rotationEffect(.degrees(trembleRotation))
                .offset(x: trembleOffsetX, y: trembleOffsetY)

            if reduceMotion == false {
                KairoPodLightSweep(active: phase != .dormant, pulse: pulse)
                    .frame(width: height * 0.70, height: height * 0.82)
                    .offset(y: -height * 0.02)
                    .opacity(phase == .dormant ? 0 : 1)

                KairoPodParticleField(active: phase != .dormant, drifting: particleDrift)
                    .opacity(phase == .dormant ? 0.10 : 0.38)
            }

            if phase == .hatching || phase == .revealed || phase == .idle {
                KairoPodRevealBloom(progress: max(revealProgress, burstProgress))
                    .frame(width: height * 0.82, height: height * 0.82)
                    .offset(y: height * 0.03)
                    .opacity(max(revealProgress, burstProgress))
            }

            if phase == .hatching && reduceMotion == false {
                KairoPodHatchBurst(progress: burstProgress)
                    .frame(width: height * 1.08, height: height * 1.08)
                    .offset(y: -height * 0.02)
                    .opacity(1 - min(1, burstProgress * 0.22))
            }

            if phase.showsCompanion, let companionImageName {
                ZStack {
                    Image(companionImageName)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundStyle(Color.white.opacity(0.86))
                        .frame(height: height * 0.45)
                        .blur(radius: max(0, 8 - (revealProgress * 8)))
                        .opacity(phase == .hatching ? max(0, 1 - revealProgress) : 0)

                    Image(companionImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: height * 0.45)
                        .opacity(companionOpacity)
                }
                .scaleEffect((0.66 + (0.34 * revealProgress)) * (phase == .idle && pulse ? 1.012 : 1))
                .offset(y: ((1 - revealProgress) * height * 0.24) - height * 0.12)
                .shadow(color: Color.white.opacity(0.42 * revealProgress), radius: 16, x: 0, y: 0)
                .shadow(color: AtlasPalette.primary.opacity(0.22 * revealProgress), radius: 18, x: 0, y: 8)
                .transition(.opacity.combined(with: .scale(scale: 0.84)))
            }

            if phase == .calibrating && reduceMotion == false {
                KairoPodOrbitRing()
                    .frame(width: height * 0.64, height: height * 0.64)
                    .offset(y: -height * 0.05)
                    .rotationEffect(.degrees(orbitRotation))
                    .opacity(0.56)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .onAppear {
            setRevealProgress(for: phase, animated: false)
            guard reduceMotion == false else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                particleDrift = true
            }
            withAnimation(.linear(duration: 4.2).repeatForever(autoreverses: false)) {
                orbitRotation = 360
            }
            withAnimation(.linear(duration: 0.085).repeatForever(autoreverses: true)) {
                tremblePhase = true
            }
        }
        .onChange(of: phase) { newPhase in
            setRevealProgress(for: newPhase, animated: true)
            setBurstProgress(for: newPhase, animated: true)
        }
    }

    private var companionOpacity: Double {
        switch phase {
        case .hatching:
            max(0, min(1, (revealProgress - 0.36) / 0.64))
        case .revealed, .idle:
            1
        case .dormant, .activating, .calibrating:
            0
        }
    }

    private var trembleAmount: CGFloat {
        guard reduceMotion == false else { return 0 }
        return switch phase {
        case .calibrating:
            1
        case .hatching:
            max(0, CGFloat(1 - revealProgress)) * 1.8
        case .dormant, .activating, .revealed, .idle:
            0
        }
    }

    private var trembleOffsetX: CGFloat {
        tremblePhase ? trembleAmount : -trembleAmount
    }

    private var trembleOffsetY: CGFloat {
        tremblePhase ? -trembleAmount * 0.32 : trembleAmount * 0.32
    }

    private var trembleRotation: Double {
        Double(tremblePhase ? trembleAmount * 0.22 : -trembleAmount * 0.22)
    }

    private var podArtwork: some View {
        Image("KairoCrystalVialPodFrameSwirl")
            .resizable()
            .scaledToFit()
            .frame(height: height * 0.78)
            .shadow(color: AtlasPalette.primaryGlow.opacity(phase == .dormant ? 0.12 : 0.26), radius: 20, x: 0, y: 12)
            .accessibilityHidden(true)
    }

    private func setRevealProgress(for phase: KairoCrystalVialPodPhase, animated: Bool) {
        let target: Double
        switch phase {
        case .hatching, .revealed, .idle:
            target = 1
        case .dormant, .activating, .calibrating:
            target = 0
        }

        if reduceMotion || animated == false {
            revealProgress = target
        } else {
            withAnimation(.easeInOut(duration: phase == .hatching ? 2.15 : 0.78)) {
                revealProgress = target
            }
        }
    }

    private func setBurstProgress(for phase: KairoCrystalVialPodPhase, animated: Bool) {
        let target: Double = phase == .hatching ? 1 : 0
        if reduceMotion || animated == false {
            burstProgress = target
        } else if phase == .hatching {
            burstProgress = 0
            withAnimation(.easeOut(duration: 0.72).delay(0.42)) {
                burstProgress = 1
            }
        } else {
            withAnimation(.easeOut(duration: 0.28)) {
                burstProgress = target
            }
        }
    }
}

private struct KairoCrystalVialPodInteractionView: View {
    let phase: KairoCrystalVialPodPhase
    let companionImageName: String?
    var height: CGFloat = 320

    var body: some View {
        CrystalVialPodView(phase: phase, companionImageName: companionImageName, height: height)
    }
}

private struct KairoRiggedCrystalVialPod: View {
    let phase: KairoCrystalVialPodPhase
    let pulse: Bool
    let revealProgress: Double
    let burstProgress: Double
    let height: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            KairoVialPetalBloom(progress: petalProgress)
                .frame(width: height * 0.70, height: height * 0.62)
                .offset(y: height * 0.13)
                .opacity(petalProgress)

            KairoVialGlassBody(
                energy: energy,
                liquidProgress: liquidProgress,
                wavePhase: wavePhase,
                isOpen: petalProgress > 0.18
            )
            .frame(width: height * 0.34, height: height * 0.70)
            .offset(y: height * 0.02)
            .scaleEffect(1 + (burstProgress * 0.035))
            .opacity(1 - (revealProgress * 0.22))

            KairoVialActivationRings(
                energy: energy,
                pulse: pulse,
                burstProgress: burstProgress
            )
            .frame(width: height * 0.82, height: height * 0.82)
            .offset(y: height * 0.02)

            KairoVialSeed(
                energy: energy,
                pulse: pulse,
                revealProgress: revealProgress
            )
            .frame(width: height * 0.20, height: height * 0.20)
            .offset(y: seedYOffset)
            .opacity(1 - min(1, revealProgress * 1.3))

            if reduceMotion == false {
                KairoVialMoleculeField(energy: energy, pulse: pulse)
                    .frame(width: height * 0.76, height: height * 0.76)
                    .offset(y: height * 0.02)
                    .opacity(phase == .dormant ? 0.16 : 0.74)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .accessibilityHidden(true)
    }

    private var energy: Double {
        switch phase {
        case .dormant:
            0.10
        case .activating:
            0.45
        case .calibrating:
            0.72
        case .hatching:
            0.92
        case .revealed, .idle:
            0.28
        }
    }

    private var liquidProgress: Double {
        switch phase {
        case .dormant:
            0.42
        case .activating:
            0.54
        case .calibrating:
            0.66
        case .hatching:
            0.78 - (revealProgress * 0.22)
        case .revealed, .idle:
            0.34
        }
    }

    private var petalProgress: Double {
        switch phase {
        case .hatching:
            max(0, min(1, (revealProgress - 0.18) / 0.82))
        case .revealed, .idle:
            1
        case .dormant, .activating, .calibrating:
            0
        }
    }

    private var wavePhase: Double {
        guard reduceMotion == false else { return 0 }
        return pulse ? 1 : 0
    }

    private var seedYOffset: CGFloat {
        switch phase {
        case .hatching:
            return CGFloat(-height * (0.02 + revealProgress * 0.22))
        case .revealed, .idle:
            return -height * 0.25
        case .dormant, .activating, .calibrating:
            return height * 0.15
        }
    }
}

private struct KairoVialGlassBody: View {
    let energy: Double
    let liquidProgress: Double
    let wavePhase: Double
    let isOpen: Bool

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let corner = width * 0.28

            ZStack {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(glassFill)
                    .overlay {
                        KairoLiquidWave(progress: liquidProgress, wavePhase: wavePhase)
                            .fill(liquidFill)
                            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
                            .padding(.horizontal, width * 0.12)
                            .padding(.vertical, height * 0.14)
                            .opacity(0.88)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .strokeBorder(glassStroke, lineWidth: 1.4)
                    }
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.34))
                            .frame(width: width * 0.10, height: height * 0.62)
                            .offset(x: width * 0.12, y: height * -0.02)
                            .blur(radius: 2.2)
                    }
                    .shadow(color: AtlasPalette.primaryGlow.opacity(0.18 + 0.20 * energy), radius: 18, x: 0, y: 8)

                KairoVialCap(isOpen: isOpen, energy: energy)
                    .frame(width: width * 1.15, height: height * 0.16)
                    .offset(y: -height * 0.43)

                KairoVialBase(energy: energy)
                    .frame(width: width * 1.18, height: height * 0.22)
                    .offset(y: height * 0.42)
            }
        }
    }

    private var glassFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.48),
                AtlasPalette.primaryGlow.opacity(0.16 + 0.12 * energy),
                Color.white.opacity(0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var liquidFill: LinearGradient {
        LinearGradient(
            colors: [
                AtlasPalette.primaryGlow.opacity(0.40 + 0.22 * energy),
                AtlasPalette.primary.opacity(0.78),
                Color(red: 0.10, green: 0.76, blue: 0.68).opacity(0.70)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var glassStroke: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.86),
                AtlasPalette.primaryGlow.opacity(0.46),
                AtlasPalette.primary.opacity(0.22),
                Color.white.opacity(0.58)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct KairoLiquidWave: Shape {
    let progress: Double
    let wavePhase: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let clamped = max(0.08, min(0.92, progress))
        let baseY = rect.maxY - (rect.height * CGFloat(clamped))
        let amplitude = rect.height * 0.035
        let phase = CGFloat(wavePhase * .pi * 2)
        let step = max(2, rect.width / 28)

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: baseY))

        var x = rect.minX
        while x <= rect.maxX {
            let normalized = (x - rect.minX) / rect.width
            let y = baseY + sin((normalized * .pi * 2.2) + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct KairoVialCap: View {
    let isOpen: Bool
    let energy: Double

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(metalFill)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.72), lineWidth: 1)
            }
            .overlay(alignment: .bottom) {
                Capsule()
                    .fill(AtlasPalette.primaryGlow.opacity(0.20 + 0.24 * energy))
                    .frame(height: 3)
                    .padding(.horizontal, 12)
                    .offset(y: -4)
            }
            .rotationEffect(.degrees(isOpen ? -4 : 0), anchor: .bottomLeading)
            .offset(y: isOpen ? -18 : 0)
            .opacity(isOpen ? 0.34 : 1)
    }

    private var metalFill: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.88, green: 0.83, blue: 0.74),
                Color(red: 0.68, green: 0.66, blue: 0.61),
                Color(red: 0.96, green: 0.93, blue: 0.86)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct KairoVialBase: View {
    let energy: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.82, green: 0.78, blue: 0.70),
                            Color(red: 0.62, green: 0.59, blue: 0.54),
                            Color(red: 0.94, green: 0.91, blue: 0.84)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            KairoDiamondShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.92),
                            AtlasPalette.primaryGlow.opacity(0.90),
                            AtlasPalette.primary.opacity(0.72)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 30, height: 42)
                .shadow(color: AtlasPalette.primaryGlow.opacity(0.32 + 0.28 * energy), radius: 10)
        }
    }
}

private struct KairoVialSeed: View {
    let energy: Double
    let pulse: Bool
    let revealProgress: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AtlasPalette.primaryGlow.opacity(0.34 + 0.26 * energy),
                            AtlasPalette.primaryGlow.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 54
                    )
                )
                .scaleEffect(pulse ? 1.18 : 0.92)

            KairoDiamondShape()
                .fill(seedFill)
                .overlay {
                    KairoDiamondShape()
                        .stroke(Color.white.opacity(0.82), lineWidth: 1.2)
                }
                .frame(width: 44, height: 66)
                .rotationEffect(.degrees(pulse ? 5 : -5))
                .scaleEffect((pulse ? 1.08 : 0.96) + (revealProgress * 0.18))
                .shadow(color: AtlasPalette.primaryGlow.opacity(0.58), radius: 14, x: 0, y: 0)
        }
    }

    private var seedFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.96),
                AtlasPalette.primaryGlow.opacity(0.92),
                AtlasPalette.primary.opacity(0.82)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct KairoDiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct KairoVialPetalBloom: View {
    let progress: Double

    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                KairoVialGlassPetal(index: index, progress: progress)
            }
        }
        .scaleEffect(0.78 + (0.22 * progress))
    }
}

private struct KairoVialGlassPetal: View {
    let index: Int
    let progress: Double

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.52),
                        AtlasPalette.primaryGlow.opacity(0.34),
                        Color.white.opacity(0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.58), lineWidth: 1)
            }
            .frame(width: 38, height: 126)
            .rotationEffect(.degrees(baseAngle + (openAngle * progress)), anchor: .bottom)
            .offset(y: -34 - (progress * CGFloat(index.isMultiple(of: 2) ? 6 : 14)))
            .blur(radius: 0.2)
            .opacity(0.18 + 0.58 * progress)
            .shadow(color: AtlasPalette.primaryGlow.opacity(0.16 * progress), radius: 10, x: 0, y: 0)
    }

    private var baseAngle: Double {
        [-24, -11, 0, 11, 24][index]
    }

    private var openAngle: Double {
        [-42, -24, 0, 24, 42][index]
    }
}

private struct KairoVialActivationRings: View {
    let energy: Double
    let pulse: Bool
    let burstProgress: Double

    var body: some View {
        ZStack {
            ForEach(0..<2, id: \.self) { index in
                Circle()
                    .trim(from: 0.08, to: 0.88)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AtlasPalette.primaryGlow.opacity(0.04),
                                AtlasPalette.primaryGlow.opacity(0.26 + energy * 0.24),
                                AtlasPalette.primary.opacity(0.10 + energy * 0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: index == 0 ? 2.4 : 1.2, lineCap: .round)
                    )
                    .scaleEffect((pulse ? 1.04 : 0.94) + CGFloat(index) * 0.12 + CGFloat(burstProgress) * 0.18)
                    .rotationEffect(.degrees(Double(index * 68) + (pulse ? 13 : -9)))
                    .opacity(0.18 + energy * 0.55)
            }
        }
    }
}

private struct KairoVialMoleculeField: View {
    let energy: Double
    let pulse: Bool

    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { index in
                Circle()
                    .fill(index.isMultiple(of: 3) ? AtlasPalette.reward.opacity(0.88) : AtlasPalette.primaryGlow.opacity(0.92))
                    .frame(width: dotSize(index), height: dotSize(index))
                    .offset(
                        x: xOffset(index),
                        y: yOffset(index)
                    )
                    .opacity(0.28 + energy * 0.58)
            }
        }
    }

    private func dotSize(_ index: Int) -> CGFloat {
        CGFloat(index.isMultiple(of: 3) ? 6 : 4)
    }

    private func xOffset(_ index: Int) -> CGFloat {
        let base = CGFloat([-84, -54, 58, 90, -98, 74, 14][index])
        let drift = CGFloat([8, -5, 7, -6, 5, -9, 4][index])
        return base + (pulse ? drift : -drift * 0.4)
    }

    private func yOffset(_ index: Int) -> CGFloat {
        let base = CGFloat([-92, -42, -78, 16, 66, 84, -116][index])
        let drift = CGFloat([-12, 8, -10, 7, -8, 10, -7][index])
        return base + (pulse ? drift : -drift * 0.4)
    }
}

private struct KairoPodAmbientGlow: View {
    let active: Bool

    var body: some View {
        RadialGradient(
            colors: [
                AtlasPalette.primaryGlow.opacity(active ? 0.24 : 0.10),
                AtlasPalette.primaryGlow.opacity(active ? 0.10 : 0.04),
                Color.clear
            ],
            center: .center,
            startRadius: 12,
            endRadius: 170
        )
        .blur(radius: 2)
        .accessibilityHidden(true)
    }
}

private struct KairoPodRevealBloom: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(AtlasPalette.primaryGlow.opacity(0.30), lineWidth: 2)
                .scaleEffect(0.44 + (0.22 * progress))
                .blur(radius: 0.6)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AtlasPalette.primaryGlow.opacity(0.24),
                            AtlasPalette.primaryGlow.opacity(0.05),
                            .clear
                        ],
                        center: .center,
                        startRadius: 4,
                        endRadius: 128
                    )
                )

            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.56),
                                AtlasPalette.primaryGlow.opacity(0.26),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 12, height: 74)
                    .rotationEffect(.degrees(Double(index) * 90 + (progress * 28)))
                    .offset(y: -58 - (progress * 22))
                    .opacity(0.24 + (0.28 * progress))
            }
        }
    }
}

private struct KairoPodPressureAura: View {
    let active: Bool
    let burstProgress: Double
    let pulse: Bool

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .trim(from: 0.04, to: 0.86)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AtlasPalette.primaryGlow.opacity(active ? 0.10 : 0),
                                AtlasPalette.primaryGlow.opacity(active ? 0.40 : 0),
                                AtlasPalette.primary.opacity(active ? 0.12 : 0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: index == 1 ? 2.4 : 1.2, lineCap: .round)
                    )
                    .scaleEffect((pulse ? 1.02 : 0.94) + CGFloat(index) * 0.11 + CGFloat(burstProgress) * 0.16)
                    .rotationEffect(.degrees(Double(index) * 78 + (pulse ? 16 : -8)))
                    .opacity((active ? 0.62 : 0) * (1 - min(0.74, burstProgress * 0.54)))
                    .blur(radius: index == 2 ? 1.6 : 0.3)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.12 * burstProgress),
                            AtlasPalette.primaryGlow.opacity(0.22 * burstProgress),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 178
                    )
                )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct KairoPodHatchBurst: View {
    let progress: Double

    var body: some View {
        ZStack {
            KairoPodBurstCore(progress: progress)

            ForEach(0..<12, id: \.self) { index in
                KairoPodBurstRay(index: index, progress: progress)
            }

            ForEach(0..<10, id: \.self) { index in
                KairoPodBurstSpark(index: index, progress: progress)
            }
        }
        .scaleEffect(0.78 + (progress * 0.22))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct KairoPodBurstCore: View {
    let progress: Double

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.92 * progress),
                        AtlasPalette.primaryGlow.opacity(0.42 * progress),
                        AtlasPalette.primaryGlow.opacity(0.08 * progress),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 1,
                    endRadius: 190
                )
            )
            .scaleEffect(0.34 + (progress * 0.70))
            .blur(radius: 2)
    }
}

private struct KairoPodBurstRay: View {
    let index: Int
    let progress: Double

    var body: some View {
        Capsule()
            .fill(rayGradient)
            .frame(width: width, height: height)
            .blur(radius: 0.4)
            .rotationEffect(.degrees(Double(index) * 30))
            .offset(y: -38 - (progress * CGFloat(46 + (index % 4) * 10)))
            .scaleEffect(y: 0.34 + (progress * 0.82), anchor: .bottom)
            .opacity(max(0, 0.76 - (progress * 0.30)))
    }

    private var rayGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.86),
                AtlasPalette.primaryGlow.opacity(0.46),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var width: CGFloat {
        index.isMultiple(of: 3) ? 7 : 4
    }

    private var height: CGFloat {
        CGFloat(index.isMultiple(of: 2) ? 126 : 88)
    }
}

private struct KairoPodBurstSpark: View {
    let index: Int
    let progress: Double

    var body: some View {
        Circle()
            .fill(index.isMultiple(of: 2) ? Color.white : AtlasPalette.primaryGlow)
            .frame(width: size, height: size)
            .offset(x: xOffset, y: yOffset)
            .opacity(max(0, 0.92 - progress * 0.48))
    }

    private var size: CGFloat {
        CGFloat(index.isMultiple(of: 3) ? 7 : 4)
    }

    private var angle: Double {
        Double(index) * Double.pi / 5
    }

    private var xOffset: CGFloat {
        CGFloat(cos(angle)) * (44 + progress * CGFloat(86 + index * 4))
    }

    private var yOffset: CGFloat {
        CGFloat(sin(angle)) * (38 + progress * CGFloat(76 + index * 3))
    }
}

private struct KairoPodLightSweep: View {
    let active: Bool
    let pulse: Bool

    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(active ? 0.28 : 0),
                            AtlasPalette.primaryGlow.opacity(active ? 0.20 : 0),
                            Color.white.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 22, height: 260)
                .rotationEffect(.degrees(19))
                .offset(x: pulse ? 42 : -48, y: pulse ? -10 : 18)
                .blur(radius: 7)

            Circle()
                .stroke(AtlasPalette.primaryGlow.opacity(active ? 0.22 : 0), lineWidth: 1.5)
                .scaleEffect(pulse ? 1.06 : 0.88)
                .blur(radius: 1)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct KairoPodParticleField: View {
    let active: Bool
    let drifting: Bool

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(index.isMultiple(of: 2) ? AtlasPalette.primaryGlow : AtlasPalette.reward.opacity(0.9))
                    .frame(width: active ? 5 : 3, height: active ? 5 : 3)
                    .offset(
                        x: CGFloat([-108, -72, 94, 126, -128, 74][index]) + (drifting ? CGFloat([7, -5, 9, -6, 4, -8][index]) : 0),
                        y: CGFloat([-92, -144, -126, -40, 44, 82][index]) + (drifting ? CGFloat([-16, -10, -18, -12, -8, -14][index]) : 0)
                    )
                    .blur(radius: active ? 0 : 0.3)
                    .opacity(active ? 0.95 : 0.42)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct KairoPodOrbitRing: View {
    var body: some View {
        Circle()
            .trim(from: 0.06, to: 0.78)
            .stroke(
                LinearGradient(
                    colors: [AtlasPalette.primaryGlow.opacity(0.08), AtlasPalette.primaryGlow.opacity(0.60), AtlasPalette.primary.opacity(0.12)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .rotationEffect(.degrees(18))
    }
}

private struct KairoCompanionChoiceScreen: View {
    let selection: AtlasMascotSelection
    let onSelect: (AtlasMascotSelection) -> Void

    var body: some View {
        KairoQuestionScaffold(title: "Choose your companion", subtitle: "") {
            HStack(spacing: 12) {
                KairoCompanionChoiceCard(name: "Aurielle", subtitle: "Crystal guardian", imageName: "KairoOnboardingAurielleStage1", selected: selection == .aurielle) {
                    onSelect(.aurielle)
                }
                KairoCompanionChoiceCard(name: "Aetherion", subtitle: "Storm dragon", imageName: "KairoOnboardingAetherionStage1", selected: selection == .aetherion) {
                    onSelect(.aetherion)
                }
            }
        }
    }
}

private struct KairoCompanionNameScreen: View {
    let selection: AtlasMascotSelection
    @Binding var name: String
    @FocusState private var isNameFocused: Bool

    var body: some View {
        KairoQuestionScaffold(title: "Congrats! Name your companion", subtitle: "") {
            VStack(spacing: 18) {
                KairoMascotPortrait(
                    imageName: selection == .aurielle ? "KairoOnboardingAurielleStage1" : "KairoOnboardingAetherionStage1",
                    height: 188
                )

                TextField(selection == .aurielle ? "Aurielle" : "Aetherion", text: $name)
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($isNameFocused)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 12)
                    .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(AtlasPalette.border, lineWidth: 1))
            }
        }
        .onAppear {
            isNameFocused = true
        }
    }
}

private struct KairoCompanionRevealScreen: View {
    let selection: AtlasMascotSelection
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress = 0.0
    @State private var didComplete = false

    var body: some View {
        KairoQuestionScaffold(title: "Your companion is waking up", subtitle: "") {
            VStack(spacing: 22) {
                KairoCrystalVialPodInteractionView(
                    phase: .calibrating,
                    companionImageName: selection == .aurielle ? "KairoOnboardingAurielleStage1" : "KairoOnboardingAetherionStage1",
                    height: 360
                )
                .accessibilityLabel("Your protocol companion capsule is activating")

                VStack(spacing: 10) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(AtlasPalette.textPrimary)

                    KairoGradientProgress(value: progress)
                        .frame(height: 10)
                        .animation(.linear(duration: 0.03), value: progress)
                }
                .padding(.horizontal, 8)
            }
        }
        .task {
            guard didComplete == false else { return }

            if reduceMotion {
                progress = 1
                didComplete = true
                try? await Task.sleep(nanoseconds: 350_000_000)
                await MainActor.run { onComplete() }
                return
            }

            for value in 0...100 {
                try? await Task.sleep(nanoseconds: 34_000_000)
                await MainActor.run {
                    progress = Double(value) / 100
                }
            }

            try? await Task.sleep(nanoseconds: 360_000_000)
            await MainActor.run {
                guard didComplete == false else { return }
                didComplete = true
                onComplete()
            }
        }
    }
}

private struct KairoMascotPortrait: View {
    let imageName: String
    let height: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AtlasPalette.primaryGlow.opacity(0.22),
                            AtlasPalette.secondaryFill.opacity(0.54),
                            AtlasPalette.surfaceTop.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: height * 0.58
                    )
                )
                .frame(width: height * 1.22, height: height * 1.22)
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: height)
                .shadow(color: AtlasPalette.primary.opacity(0.14), radius: 10, x: 0, y: 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height + 18)
    }
}

private struct KairoEvolutionScreen: View {
    let selection: AtlasMascotSelection
    let name: String

    var body: some View {
        KairoQuestionScaffold(title: "\(name) will grow with you", subtitle: "") {
            KairoOnboardingCard {
                if selection == .aetherion {
                    HStack(spacing: 10) {
                        KairoEvolutionStage(image: "KairoOnboardingAetherionStage1", title: "Lv. 1", detail: "Hatched", locked: false)
                        KairoEvolutionStage(image: "KairoOnboardingAetherionStage2", title: "Lv. 20", detail: "Locked", locked: true)
                        KairoEvolutionStage(image: "KairoOnboardingAetherionStage3", title: "Lv. 30", detail: "Locked", locked: true)
                    }
                } else {
                    HStack(spacing: 10) {
                        KairoEvolutionStage(image: "KairoOnboardingAurielleStage1", title: "Lv. 1", detail: "Hatched", locked: false)
                        KairoEvolutionStage(image: "AtlasMascotAurielleStage2Mockup", title: "Lv. 20", detail: "Locked", locked: true)
                        KairoEvolutionStage(image: "AtlasMascotAurielleStage3Mockup", title: "Lv. 30", detail: "Locked", locked: true)
                    }
                }
                KairoProgressBar(value: 0.04)
                HStack {
                    Text("Level 1")
                    Spacer()
                    Text("10 / 250 XP")
                }
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(AtlasPalette.textPrimary)
            }
            KairoInfoBanner(text: "Your companion grows as you build consistency, complete reviews, and care for your protocol.")
        }
    }
}

private struct KairoLongTermResultsScreen: View {
    var body: some View {
        KairoQuestionScaffold(title: "Kairo creates long-term protocol results", subtitle: "") {
            KairoOnboardingCard(spacing: 16) {
                KairoLongTermComparisonChart()
                Text("Review patterns over time.")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct KairoConnectAppsScreen: View {
    var body: some View {
        VStack(spacing: 32) {
            KairoHealthConnectDiagram()
                .padding(.top, 34)

            VStack(spacing: 14) {
                Text("Connect your\nhealth apps")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(1)

                Text("Sync weight, workouts, hydration,\nsleep, and steps into Kairo.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer(minLength: 150)
        }
        .frame(maxWidth: .infinity, minHeight: 620, alignment: .top)
    }
}

private struct KairoRatingPrimerScreen: View {
    var body: some View {
        KairoQuestionScaffold(title: "Give us a rating", subtitle: "") {
            VStack(spacing: 14) {
                Text("Enjoying the setup?")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(AtlasPalette.textPrimary)
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(AtlasPalette.reward)
                    }
                }
                Text("We will ask at the right moment after you have used Kairo.")
                    .font(.system(size: 14, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AtlasPalette.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
        }
    }
}

private struct KairoHealthConnectDiagram: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(AtlasPalette.primaryGlow.opacity(0.18))
                .frame(width: 150, height: 150)
                .position(x: 150, y: 150)

            Circle()
                .fill(AtlasPalette.textPrimary)
                .frame(width: 26, height: 26)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(AtlasPalette.background)
                }
                .position(x: 150, y: 150)

            KairoCleanArrow(
                points: [
                    CGPoint(x: 206, y: 75),
                    CGPoint(x: 162, y: 75),
                    CGPoint(x: 162, y: 123)
                ],
                head: .down
            )

            KairoCleanArrow(
                points: [
                    CGPoint(x: 92, y: 221),
                    CGPoint(x: 138, y: 221),
                    CGPoint(x: 138, y: 177)
                ],
                head: .up
            )

            KairoHealthAppBadge(title: "Apple Health") {
                KairoAppleFitnessIcon()
            }
            .position(x: 232, y: 62)

            KairoHealthAppBadge(title: "Kairo") {
                KairoAppIconTile()
            }
            .position(x: 68, y: 232)
        }
        .frame(width: 300, height: 286)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Apple Health and Kairo can sync health activity into Kairo")
    }
}

private struct KairoHealthAppBadge<Icon: View>: View {
    let title: String
    @ViewBuilder let icon: Icon

    var body: some View {
        VStack(spacing: 8) {
            icon
                .frame(width: 64, height: 64)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AtlasPalette.textPrimary)
                .fixedSize()
        }
    }
}

private struct KairoAppleFitnessIcon: View {
    var body: some View {
        Image("KairoAppleFitnessAppIcon")
            .resizable()
            .scaledToFill()
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .shadow(color: AtlasPalette.shadow.opacity(0.16), radius: 7, x: 0, y: 5)
    }
}

private struct KairoAppIconTile: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(AtlasPalette.surfaceTop)
            Image("KairoOnboardingLogoMark")
                .resizable()
                .scaledToFit()
                .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .shadow(color: AtlasPalette.shadow.opacity(0.16), radius: 7, x: 0, y: 5)
    }
}

private struct KairoCleanArrow: View {
    let points: [CGPoint]
    let head: ArrowHead

    var body: some View {
        Path { path in
            guard let first = points.first, let last = points.last else { return }
            path.move(to: first)
            points.dropFirst().forEach { path.addLine(to: $0) }
            switch head {
            case .down:
                path.move(to: last)
                path.addLine(to: CGPoint(x: last.x - 8, y: last.y - 9))
                path.move(to: last)
                path.addLine(to: CGPoint(x: last.x + 8, y: last.y - 9))
            case .up:
                path.move(to: last)
                path.addLine(to: CGPoint(x: last.x - 8, y: last.y + 9))
                path.move(to: last)
                path.addLine(to: CGPoint(x: last.x + 8, y: last.y + 9))
            }
        }
        .stroke(AtlasPalette.textPrimary, style: StrokeStyle(lineWidth: 2.2, lineCap: .square, lineJoin: .miter))
        .frame(width: 300, height: 286)
    }

    enum ArrowHead {
        case down
        case up
    }
}

private struct KairoTrackingPermissionScreen: View {
    var body: some View {
        KairoQuestionScaffold(title: "Allow tracking", subtitle: "") {
            VStack(spacing: 12) {
                KairoPermissionRow(icon: "lock.shield.fill", title: "No medical data sold", detail: "Kairo is not a marketplace or sourcing product.")
                KairoPermissionRow(icon: "bell.badge.fill", title: "Smarter nudges", detail: "Learn which setup moments create follow-through.")
                KairoPermissionRow(icon: "person.crop.circle.badge.checkmark", title: "You control it", detail: "Change preferences later from settings.")
            }
        }
    }
}

private struct KairoPlanLoadingScreen: View {
    let onComplete: () -> Void

    @State private var progress = 0.0
    @State private var completedChecks = 0
    @State private var didComplete = false

    var body: some View {
        KairoQuestionScaffold(title: "Calibrating your tracking plan...", subtitle: "") {
            VStack(spacing: 18) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 54, weight: .black))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .padding(.top, 54)

                KairoGradientProgress(value: progress)
                    .animation(.easeInOut(duration: 0.28), value: progress)

                VStack(spacing: 12) {
                    KairoLoadingChecklistRow(text: "Protocol schedule", isComplete: completedChecks >= 1)
                    KairoLoadingChecklistRow(text: "Inventory runway", isComplete: completedChecks >= 2)
                    KairoLoadingChecklistRow(text: "Review rhythm", isComplete: completedChecks >= 3)
                    KairoLoadingChecklistRow(text: "Weekly review", isComplete: completedChecks >= 4)
                }
                .padding(.top, 8)
            }
        }
        .task {
            guard didComplete == false else { return }
            for value in 0...100 {
                try? await Task.sleep(nanoseconds: 28_000_000)
                await MainActor.run {
                    withAnimation(.linear(duration: 0.028)) {
                        progress = Double(value) / 100
                        completedChecks = min(4, value / 25)
                    }
                }
            }
            try? await Task.sleep(nanoseconds: 420_000_000)
            await MainActor.run {
                guard didComplete == false else { return }
                didComplete = true
                onComplete()
            }
        }
    }
}

private struct KairoLoadingChecklistRow: View {
    let text: String
    let isComplete: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(isComplete ? AtlasPalette.primary : AtlasPalette.border)
                .scaleEffect(isComplete ? 1.05 : 1)
            Text(text)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isComplete ? AtlasPalette.textPrimary : AtlasPalette.textPrimary)
            Spacer()
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isComplete)
    }
}

private struct KairoPlanPreviewScreen: View {
    let track: AtlasTrackType

    var body: some View {
        KairoQuestionScaffold(title: "Your tracking plan is ready", subtitle: "Here's what Kairo will help you track.") {
            VStack(spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    KairoPlanTile(icon: "syringe.fill", title: track == .glp ? "GLP tracking" : "Peptide tracking", detail: "Schedules and logs", checked: true)
                    KairoPlanTile(icon: "shippingbox.fill", title: "Inventory", detail: "Runway and supplies", checked: true)
                    KairoPlanTile(icon: "waveform.path.ecg", title: "Symptoms", detail: "Pattern context", checked: true)
                KairoPlanTile(icon: "sparkles", title: "Weekly review", detail: "Progress and rhythm", checked: true)
                }
                KairoConsistencyScore()
            }
        }
    }
}

private struct KairoPlanReadyScreen: View {
    let track: AtlasTrackType
    let glp: AtlasOnboardingGlpSetup
    let peptide: AtlasOnboardingPeptideSetup

    var body: some View {
        KairoQuestionScaffold(title: "You're ready", subtitle: "") {
            VStack(spacing: 12) {
                KairoMiniTodayPreview(track: track, glp: glp, peptide: peptide)
                KairoInfoBanner(text: "Kairo is tracking \(track.title.lowercased()) rhythm, inventory, adherence, and weekly review.")
            }
        }
    }
}

private struct KairoSaveProgressScreen: View {
    var body: some View {
        KairoQuestionScaffold(title: "Save your progress", subtitle: "") {
            VStack(spacing: 12) {
                KairoInfoBanner(text: "Your protocol path, reminders, and generated plan stay linked to this account.")
                KairoAuthButton(icon: "apple.logo", title: "Sign in with Apple", filled: true)
                KairoAuthButton(icon: "g.circle.fill", title: "Continue with Google", filled: false)
                KairoAuthButton(icon: "envelope.fill", title: "Continue with email", filled: false)
            }
        }
    }
}

private struct KairoSignInScreen: View {
    var body: some View {
        KairoQuestionScaffold(title: "Almost there", subtitle: "") {
            VStack(spacing: 12) {
                KairoTextFieldPreview(label: "First name")
                KairoTextFieldPreview(label: "Email")
                KairoAuthButton(icon: "checkmark.seal.fill", title: "Create secure profile", filled: true)
            }
        }
    }
}

private struct KairoTrialIntroScreen: View {
    var body: some View {
        KairoQuestionScaffold(title: "Try Kairo Pro free", subtitle: "") {
            VStack(spacing: 12) {
                KairoTrialTimeline()
                KairoTrialChecklistRow("Unlimited protocol schedules")
                KairoTrialChecklistRow("Inventory and runway alerts")
                KairoTrialChecklistRow("Guided review exports")
                KairoTrialChecklistRow("Weekly review export")
            }
        }
    }
}

private struct KairoTrialChecklistRow: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AtlasPalette.primary)
            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AtlasPalette.textPrimary)
            Spacer()
        }
    }
}

private struct KairoTrialReminderScreen: View {
    var body: some View {
        KairoQuestionScaffold(title: "We'll send a reminder", subtitle: "") {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 76, weight: .bold))
                .foregroundStyle(AtlasPalette.reward)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
                KairoInfoBanner(text: "No payment due now!")
        }
    }
}

private struct KairoTrialPaywallScreen: View {
    let plan: AtlasOnboardingPremiumPlan
    let onPlan: (AtlasOnboardingPremiumPlan) -> Void

    var body: some View {
        KairoQuestionScaffold(title: "Start your 3-day free trial to continue", subtitle: "") {
            VStack(spacing: 12) {
                KairoTrialTimeline()
                KairoPlanPriceRow(title: "Annual", price: "$59.99 / year", selected: plan == .annual) { onPlan(.annual) }
                KairoPlanPriceRow(title: "Monthly", price: "$9.99 / month", selected: plan == .monthly) { onPlan(.monthly) }
                KairoInfoBanner(text: "Cancel anytime. Kairo does not provide dosing or medical advice.")
            }
        }
    }
}

private struct KairoPurchaseSuccessScreen: View {
    let track: AtlasTrackType
    let glp: AtlasOnboardingGlpSetup
    let peptide: AtlasOnboardingPeptideSetup

    var body: some View {
        KairoQuestionScaffold(title: "You're ready to go.", subtitle: "Your Kairo setup is saved and ready.") {
            VStack(spacing: 18) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 82, weight: .bold))
                    .foregroundStyle(AtlasPalette.primary)
                    .padding(.top, 56)

                KairoMiniTodayPreview(track: track, glp: glp, peptide: peptide)
            }
        }
    }
}

private struct KairoSaveProgressAgainScreen: View {
    var body: some View {
        KairoQuestionScaffold(title: "Save your progress", subtitle: "") {
            VStack(spacing: 12) {
                KairoAuthButton(icon: "apple.logo", title: "Sign in with Apple", filled: true)
                KairoAuthButton(icon: "envelope.fill", title: "Continue with email", filled: false)
            }
        }
    }
}

private struct KairoHomeEndpointScreen: View {
    var body: some View {
        KairoQuestionScaffold(title: "Welcome to Kairo", subtitle: "") {
            KairoMiniTodayPreview()
        }
    }
}

private struct KairoOptionQuestion: View {
    let title: String
    let subtitle: String
    let options: [String]
    var selected: String?
    var selectedValues: Set<String> = []
    let allowsMultiple: Bool
    var compact = false
    var onSelect: ((String) -> Void)?
    var onMultiSelect: ((Set<String>) -> Void)?

    init(title: String, subtitle: String, options: [String], selected: String?, allowsMultiple: Bool, compact: Bool = false, onSelect: @escaping (String) -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.options = options
        self.selected = selected
        self.allowsMultiple = allowsMultiple
        self.compact = compact
        self.onSelect = onSelect
    }

    init(title: String, subtitle: String, options: [String], selectedValues: Set<String>, allowsMultiple: Bool, compact: Bool = false, onMultiSelect: @escaping (Set<String>) -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.options = options
        self.selectedValues = selectedValues
        self.allowsMultiple = allowsMultiple
        self.compact = compact
        self.onMultiSelect = onMultiSelect
    }

    var body: some View {
        KairoQuestionScaffold(title: title, subtitle: subtitle) {
            VStack(spacing: compact ? 7 : 9) {
                ForEach(options, id: \.self) { option in
                    let isSelected = allowsMultiple ? selectedValues.contains(option) : selected == option
                    Button {
                        if allowsMultiple {
                            var next = selectedValues
                            if next.contains(option) { next.remove(option) } else { next.insert(option) }
                            onMultiSelect?(next)
                        } else {
                            onSelect?(option)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: iconName(for: option))
                                .font(.system(size: compact ? 12 : 14, weight: .bold))
                                .foregroundStyle(isSelected ? .white : AtlasPalette.primary)
                                .frame(width: compact ? 22 : 28, height: compact ? 22 : 28)
                                .background(isSelected ? .white.opacity(0.16) : AtlasPalette.secondaryFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                            Text(option)
                                .font(.system(size: compact ? 12 : 13, weight: .semibold))
                                .foregroundStyle(isSelected ? .white : AtlasPalette.textPrimary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.horizontal, 13)
                        .frame(minHeight: compact ? 38 : 44)
                        .background(isSelected ? AtlasPalette.primary : AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(isSelected ? AtlasPalette.primary : AtlasPalette.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func iconName(for option: String) -> String {
        let lower = option.lowercased()
        if ["female", "male", "non-binary", "prefer not to say"].contains(lower) {
            return "circle.fill"
        }
        if lower.contains("semaglutide") || lower.contains("tirzepatide") || lower.contains("retatrutide") || lower.contains("liraglutide") || lower.contains("dulaglutide") || lower.contains("exenatide") {
            return "pills.fill"
        }
        if lower.contains("weekly") || lower.contains("daily") || lower.contains("2-3") {
            return "calendar.badge.clock"
        }
        if lower.contains("mon") || lower.contains("tue") || lower.contains("wed") || lower.contains("thu") || lower.contains("fri") || lower.contains("sat") || lower.contains("sun") {
            return "calendar"
        }
        if lower.contains("mg") || lower.contains("custom") {
            return "syringe.fill"
        }
        if lower.contains("weight") || lower.contains("muscle") || lower.contains("metabolic") || lower.contains("performance") || lower.contains("recovery") || lower.contains("skin") || lower.contains("fat") {
            return "scope"
        }
        if lower.contains("cravings") || lower.contains("side effects") || lower.contains("energy") || lower.contains("consistent") || lower.contains("forgetting") {
            return "waveform.path.ecg"
        }
        if lower.contains("bpc") || lower.contains("tb-500") || lower.contains("cjc") || lower.contains("aod") || lower.contains("sermorelin") || lower.contains("tesamorelin") || lower.contains("ghk") || lower.contains("thymosin") || lower.contains("epitalon") || lower.contains("mots") || lower.contains("nad") {
            return "testtube.2"
        }
        if lower == "yes" {
            return "hand.thumbsup.fill"
        }
        if lower == "no" {
            return "hand.thumbsdown.fill"
        }
        return allowsMultiple ? "square.stack.3d.up.fill" : "circle.fill"
    }
}

private struct KairoNumberQuestion: View {
    let title: String
    let subtitle: String
    let value: Int
    let range: ClosedRange<Int>
    let unit: String
    let onChange: (Int) -> Void
    @State private var draftValue = ""

    var body: some View {
        KairoQuestionScaffold(title: title, subtitle: subtitle) {
            VStack(spacing: 18) {
                HStack(spacing: 8) {
                    TextField("", text: Binding(
                        get: { draftValue.isEmpty ? "\(value)" : draftValue },
                        set: { newValue in
                            let filtered = String(newValue.filter { $0.isNumber }.prefix(3))
                            draftValue = filtered
                            if let next = Int(filtered) {
                                onChange(min(range.upperBound, max(range.lowerBound, next)))
                            }
                        }
                    ))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .frame(width: 96)
                    .padding(.vertical, 8)
                    .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Text(unit)
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(AtlasPalette.textPrimary)
                }
                Slider(
                    value: Binding(
                        get: { Double(value) },
                        set: {
                            let next = Int($0.rounded())
                            draftValue = "\(next)"
                            onChange(next)
                        }
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound),
                    step: 1
                )
                .tint(AtlasPalette.primary)
                HStack {
                    Text("\(range.lowerBound)")
                    Spacer()
                    Text("\(range.upperBound)")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AtlasPalette.textPrimary)
            }
            .padding(.horizontal, 4)
        }
        .onAppear {
            draftValue = "\(value)"
        }
        .onChange(of: value) { _, newValue in
            draftValue = "\(newValue)"
        }
    }
}

private struct KairoBirthdateQuestion: View {
    let age: Int
    let onChange: (Int) -> Void

    @State private var selectedMonth = 6
    @State private var selectedDay = 15
    @State private var selectedYear = 1995

    private let months = Calendar.current.shortMonthSymbols
    private let years = Array(1940...2008)

    var body: some View {
        KairoQuestionScaffold(title: "What's your date of birth?", subtitle: "") {
            HStack(spacing: 0) {
                Picker("Month", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text(months[month - 1]).tag(month)
                    }
                }
                .pickerStyle(.wheel)

                Picker("Day", selection: $selectedDay) {
                    ForEach(1...31, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(.wheel)

                Picker("Year", selection: $selectedYear) {
                    ForEach(years, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.wheel)
            }
            .frame(height: 190)
            .clipped()
            .onAppear {
                selectedYear = Calendar.current.component(.year, from: Date()) - age
                updateAge()
            }
            .onChange(of: selectedMonth) { _, _ in updateAge() }
            .onChange(of: selectedDay) { _, _ in updateAge() }
            .onChange(of: selectedYear) { _, _ in updateAge() }
        }
    }

    private func updateAge() {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = selectedDay
        guard let date = Calendar.current.date(from: components) else { return }
        let computedAge = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? age
        onChange(min(85, max(18, computedAge)))
    }
}

private struct KairoEditableStepperValue: View {
    let value: Int
    let range: ClosedRange<Int>
    let unit: String
    let onChange: (Int) -> Void
    @State private var text = ""

    var body: some View {
        HStack(spacing: 4) {
            TextField("", text: Binding(
                get: { text.isEmpty ? "\(value)" : text },
                set: { newValue in
                    let filtered = String(newValue.filter { $0.isNumber }.prefix(3))
                    text = filtered
                    if let next = Int(filtered) {
                        onChange(min(range.upperBound, max(range.lowerBound, next)))
                    }
                }
            ))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .font(.system(size: 16, weight: .black))
            .foregroundStyle(AtlasPalette.textPrimary)
            .frame(width: 50)

            Text(unit)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(AtlasPalette.textPrimary)
        }
        .frame(width: 94)
        .onAppear { text = "\(value)" }
        .onChange(of: value) { _, newValue in text = "\(newValue)" }
    }
}

private struct KairoQuestionScaffold<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if subtitle.isEmpty == false {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(AtlasPalette.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 44)

            content
                .frame(maxWidth: .infinity)

            Spacer(minLength: 160)
        }
        .frame(maxWidth: .infinity, minHeight: 620, alignment: .top)
    }
}

private struct KairoOnboardingCard<Content: View>: View {
    var spacing: CGFloat = 14
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            AtlasPalette.surfaceTop,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AtlasPalette.border.opacity(0.9), lineWidth: 1))
        .shadow(color: AtlasPalette.shadow.opacity(0.12), radius: 8, x: 0, y: 3)
    }
}

private struct KairoLogoMark: View {
    let size: CGFloat

    var body: some View {
        Image("KairoOnboardingLogoMark")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

private struct KairoChecklistRow: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AtlasPalette.primary)
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AtlasPalette.textPrimary)
            Spacer()
        }
    }
}

private enum KairoDemoClipMode {
    case today
    case progress

    var stages: [KairoDemoClipScreen] {
        switch self {
        case .today:
            [.todayHome, .protocols, .protocolCreate, .logShot, .todayResult]
        case .progress:
            [.progressHome, .companion, .weeklyReview, .progressResult]
        }
    }

    var interval: TimeInterval {
        switch self {
        case .today:
            1.32
        case .progress:
            1.42
        }
    }
}

private struct KairoAnimatedDemoScreen: View {
    let mode: KairoDemoClipMode
    let headline: String
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = 0
    @State private var introZoom = true
    @State private var didComplete = false
    private let timer = Timer.publish(every: 0.66, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(Array(mode.stages.enumerated()), id: \.element) { index, screen in
                    KairoDemoClipPhone(screen: screen, isActive: index == phase)
                        .scaleEffect(scale(for: index))
                        .rotationEffect(.degrees(rotation(for: index)))
                        .rotation3DEffect(.degrees(rotation3D(for: index)), axis: (x: 0.0, y: 1.0, z: 0.0), perspective: 0.68)
                        .offset(x: offset(for: index).width, y: offset(for: index).height)
                        .opacity(opacity(for: index))
                        .blur(radius: blur(for: index))
                        .zIndex(zIndex(for: index))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 642)
            .clipped()
            .padding(.top, 2)

            Spacer(minLength: 18)

            Text(headline)
                .font(.system(size: 21, weight: .black))
                .foregroundStyle(AtlasPalette.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.bottom, 10)

            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, minHeight: 730, alignment: .top)
        .onAppear {
            phase = 0
            introZoom = true
            didComplete = false
            withAnimation(.easeOut(duration: 0.82)) {
                introZoom = false
            }
        }
        .onReceive(timer) { _ in
            tickDemo()
        }
    }

    private func scale(for index: Int) -> CGFloat {
        if index == phase {
            if phase == 0 {
                return introZoom ? 1.36 : 1.02
            }
            return 1.0
        }
        return 0.86
    }

    private func offset(for index: Int) -> CGSize {
        if index == phase {
            return phase == 0 ? CGSize(width: 0, height: introZoom ? 58 : -4) : .zero
        }
        if index < phase {
            return CGSize(width: -250, height: 16)
        }
        return CGSize(width: 250, height: 16)
    }

    private func opacity(for index: Int) -> Double {
        if index == phase { return 1 }
        return 0
    }

    private func rotation(for index: Int) -> Double {
        if index == phase { return 0 }
        return index < phase ? -8 : 8
    }

    private func rotation3D(for index: Int) -> Double {
        if index == phase { return 0 }
        return index < phase ? 18 : -18
    }

    private func blur(for index: Int) -> CGFloat {
        index == phase ? 0 : 1.5
    }

    private func zIndex(for index: Int) -> Double {
        index == phase ? 2 : 0
    }

    private func tickDemo() {
        guard didComplete == false else { return }
        advanceDemo()
    }

    private func advanceDemo() {
        if phase == mode.stages.indices.last {
            didComplete = true
            onComplete()
            return
        }
        let nextPhase = (phase + 1) % mode.stages.count
        if reduceMotion {
            phase = nextPhase
        } else {
            withAnimation(.spring(response: mode.interval * 0.34, dampingFraction: 0.84)) {
                phase = nextPhase
            }
        }
    }
}

private enum KairoDemoClipScreen: Hashable {
    case todayHome
    case protocols
    case protocolCreate
    case logShot
    case companion
    case todayResult
    case progressHome
    case weeklyReview
    case progressResult

    var title: String {
        switch self {
        case .todayHome, .todayResult:
            "Today"
        case .protocols:
            "Protocols"
        case .protocolCreate:
            "Add Protocol"
        case .logShot:
            "Log Shot"
        case .companion:
            "Companion"
        case .progressHome, .progressResult:
            "Progress"
        case .weeklyReview:
            "Weekly Review"
        }
    }

    var activeTab: String {
        switch self {
        case .todayHome, .todayResult:
            "Today"
        case .protocols, .protocolCreate:
            "Protocols"
        case .logShot:
            "Log"
        case .companion:
            "Companion"
        case .progressHome, .weeklyReview, .progressResult:
            "Progress"
        }
    }

    var assetName: String {
        switch self {
        case .todayHome, .todayResult:
            "KairoOnboardingDemoToday"
        case .protocols:
            "KairoOnboardingDemoProtocols"
        case .protocolCreate:
            "KairoOnboardingDemoProtocolCreate"
        case .logShot:
            "KairoOnboardingDemoLog"
        case .companion:
            "KairoOnboardingDemoCompanion"
        case .progressHome, .weeklyReview, .progressResult:
            "KairoOnboardingDemoProgress"
        }
    }

}

private struct KairoDemoClipPhone: View {
    let screen: KairoDemoClipScreen
    let isActive: Bool

    var body: some View {
        ZStack {
            KairoPhoneSideButtons()

            RoundedRectangle(cornerRadius: 43, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.09, blue: 0.09),
                            Color(red: 0.01, green: 0.015, blue: 0.016)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 43, style: .continuous)
                        .stroke(.white.opacity(0.22), lineWidth: 1)
                        .padding(1)
                )

            Image(screen.assetName)
                .resizable()
                .scaledToFill()
                .frame(width: 266, height: 576)
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                .overlay(alignment: .top) {
                    KairoDemoDynamicIsland()
                        .padding(.top, 9)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(.black.opacity(0.10), lineWidth: 1)
                )
                .padding(7)
        }
        .frame(width: 282, height: 592)
        .shadow(color: AtlasPalette.shadow.opacity(isActive ? 0.28 : 0.14), radius: isActive ? 22 : 12, x: 0, y: isActive ? 14 : 8)
        .accessibilityLabel("\(screen.title) demo in iPhone frame")
    }
}

private struct KairoPhoneSideButtons: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .fill(.black.opacity(0.42))
                .frame(width: 4, height: 58)
                .offset(x: -144, y: -164)
            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .fill(.black.opacity(0.42))
                .frame(width: 4, height: 86)
                .offset(x: 144, y: -106)
            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .fill(.black.opacity(0.42))
                .frame(width: 4, height: 44)
                .offset(x: -144, y: -72)
        }
    }
}

private struct KairoDemoDynamicIsland: View {
    var body: some View {
        Capsule(style: .continuous)
            .fill(.black)
            .frame(width: 70, height: 21)
            .overlay(alignment: .trailing) {
                Circle()
                    .fill(Color(red: 0.08, green: 0.08, blue: 0.09))
                    .frame(width: 8, height: 8)
                    .padding(.trailing, 8)
            }
    }
}

private struct KairoClipTodayContent: View {
    let result: Bool

    var body: some View {
        VStack(spacing: 8) {
            KairoClipCard {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(result ? "Logged today" : "Next shot")
                            .font(.system(size: 7, weight: .black))
                        Spacer()
                        Image(systemName: result ? "checkmark.circle.fill" : "chevron.down")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(result ? AtlasPalette.primary : AtlasPalette.textPrimary)
                    }
                    HStack(spacing: 5) {
                        Text("Tirzepatide")
                            .font(.system(size: 11, weight: .black))
                        Text("Weekly")
                            .font(.system(size: 6, weight: .black))
                            .foregroundStyle(AtlasPalette.primary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(AtlasPalette.primaryGlow.opacity(0.48), in: Capsule())
                    }
                    Text(result ? "5.0 mg • SubQ • completed" : "5.0 mg • SubQ • 12:30 PM")
                        .font(.system(size: 7, weight: .semibold))
                    Text(result ? "Next dose Apr 30" : "Due 12:30 PM")
                        .font(.system(size: 7, weight: .black))
                        .foregroundStyle(AtlasPalette.primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            KairoClipProtocolRow(title: "Protocol", detail: "Weekly • 5.0 mg", footnote: result ? "Week 5 of 12" : "Week 4 of 12")
            KairoClipProtocolRow(title: "Inventory runway", detail: result ? "11 doses left" : "12 doses left", footnote: result ? "+20 days" : "+21 days")
        }
    }
}

private struct KairoClipLogShotContent: View {
    var body: some View {
        VStack(spacing: 8) {
            KairoClipCard {
                HStack(spacing: 8) {
                    Image("KairoBoardVialIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 32)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Tirzepatide")
                            .font(.system(size: 11, weight: .black))
                        Text("5 mg • SubQ")
                            .font(.system(size: 8, weight: .bold))
                    }
                    Spacer()
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(AtlasPalette.primary)
                }
            }

            KairoClipCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm shot")
                        .font(.system(size: 11, weight: .black))
                    HStack {
                        Text("12:30 PM")
                        Spacer()
                        Text("Today")
                    }
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    Capsule()
                        .fill(AtlasPalette.primary)
                        .frame(height: 8)
                        .overlay(alignment: .trailing) {
                            Circle()
                                .fill(.white)
                                .frame(width: 14, height: 14)
                                .shadow(color: AtlasPalette.shadow.opacity(0.18), radius: 3, x: 0, y: 1)
                        }
                }
            }

            Text("Log shot")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(AtlasPalette.primary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.top, 4)
        }
    }
}

private struct KairoClipProgressContent: View {
    let result: Bool

    var body: some View {
        VStack(spacing: 8) {
            KairoClipCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text(result ? "Consistency potential" : "Adherence")
                        .font(.system(size: 9, weight: .black))
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(result ? "10/10" : "6 of 7")
                            .font(.system(size: 23, weight: .black))
                            .foregroundStyle(AtlasPalette.primary)
                        Text(result ? "ready" : "This week")
                            .font(.system(size: 8, weight: .black))
                    }
                    HStack(spacing: 4) {
                        ForEach(0..<8, id: \.self) { index in
                            Circle()
                                .fill(index < (result ? 8 : 7) ? AtlasPalette.primary : AtlasPalette.border)
                                .frame(width: 7, height: 7)
                        }
                    }
                }
            }

            KairoSymptomsPreviewCard()
                .scaleEffect(0.76, anchor: .topLeading)
                .frame(width: 202, height: 74, alignment: .topLeading)

            KairoClipCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly trend")
                        .font(.system(size: 9, weight: .black))
                    KairoClipSparkline(rising: result)
                        .frame(height: 46)
                    HStack {
                        ForEach(["Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                            Text(day)
                                .font(.system(size: 5, weight: .black))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
}

private struct KairoClipWeeklyReviewContent: View {
    var body: some View {
        VStack(spacing: 8) {
            KairoClipCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Wins")
                        .font(.system(size: 11, weight: .black))
                    KairoClipTinyCheck("Hit protocol most days")
                    KairoClipTinyCheck("Symptoms stayed mild")
                    KairoClipTinyCheck("Inventory updated")
                }
            }

            KairoClipCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Focus next week")
                        .font(.system(size: 11, weight: .black))
                    KairoClipTinyCheck("Keep hydration high")
                    KairoClipTinyCheck("Review Friday")
                }
            }
        }
    }
}

private struct KairoClipProtocolRow: View {
    let title: String
    let detail: String
    let footnote: String

    var body: some View {
        KairoClipCard {
            HStack(spacing: 8) {
                Image("KairoBoardVialIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 32)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 8, weight: .black))
                    Text(detail)
                        .font(.system(size: 9, weight: .black))
                    Text(footnote)
                        .font(.system(size: 7, weight: .black))
                        .foregroundStyle(AtlasPalette.primary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .black))
            }
        }
    }
}

private struct KairoClipTinyCheck: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 7, weight: .black))
                .foregroundStyle(AtlasPalette.primary)
            Text(text)
                .font(.system(size: 8, weight: .bold))
            Spacer()
        }
    }
}

private struct KairoClipSparkline: View {
    let rising: Bool

    var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(AtlasPalette.primaryGlow.opacity(0.28))
                .frame(height: proxy.size.height * 0.38)
                .position(x: proxy.size.width / 2, y: proxy.size.height * 0.80)
            Path { path in
                let points: [CGFloat] = rising ? [0.72, 0.58, 0.52, 0.42, 0.34, 0.24] : [0.66, 0.55, 0.60, 0.44, 0.61, 0.52]
                for index in points.indices {
                    let x = proxy.size.width * CGFloat(index) / CGFloat(points.count - 1)
                    let y = proxy.size.height * points[index]
                    if index == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(AtlasPalette.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

private struct KairoClipCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AtlasPalette.border, lineWidth: 0.8))
    }
}

private struct KairoClipTabBar: View {
    let active: String

    var body: some View {
        HStack(spacing: 0) {
            tab("Today", "sun.max.fill")
            tab("Log", "syringe.fill")
            tab("Protocols", "calendar")
            tab("Progress", "chart.line.uptrend.xyaxis")
            tab("Companion", "sparkles")
        }
        .padding(.vertical, 7)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AtlasPalette.border, lineWidth: 0.8))
    }

    private func tab(_ title: String, _ icon: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .black))
            Text(title)
                .font(.system(size: 5, weight: .black))
        }
        .foregroundStyle(active == title ? AtlasPalette.primary : AtlasPalette.textPrimary.opacity(0.58))
        .frame(maxWidth: .infinity)
    }
}

private struct KairoDemoPhoneFrame<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 9) {
            HStack {
                Text("9:41")
                    .font(.system(size: 8, weight: .black))
                Spacer()
                HStack(spacing: 2) {
                    Image(systemName: "cellularbars")
                    Image(systemName: "wifi")
                    Image(systemName: "battery.100")
                }
                .font(.system(size: 7, weight: .bold))
            }
            .foregroundStyle(AtlasPalette.textPrimary)

            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Spacer()
            }
            content
            HStack {
                KairoMiniTab(icon: "sun.max.fill", title: "Today", active: title == "Today")
                KairoMiniTab(icon: "syringe.fill", title: "Log", active: false)
                KairoMiniTab(icon: "calendar", title: "Protocols", active: false)
                KairoMiniTab(icon: "chart.line.uptrend.xyaxis", title: "Progress", active: title == "Progress")
                KairoMiniTab(icon: "sparkles", title: "Companion", active: false)
            }
            .padding(.top, 3)
        }
        .padding(12)
        .frame(width: 284)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(AtlasPalette.border, lineWidth: 1))
        .shadow(color: AtlasPalette.shadow.opacity(0.12), radius: 14, x: 0, y: 8)
    }
}

private struct KairoMiniTab: View {
    let icon: String
    let title: String
    let active: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(title)
                .font(.system(size: 8, weight: .black))
        }
        .foregroundStyle(active ? AtlasPalette.primary : AtlasPalette.textPrimary)
        .frame(maxWidth: .infinity)
    }
}

private struct KairoMiniTodayPreview: View {
    var track: AtlasTrackType = .peptide
    var glp: AtlasOnboardingGlpSetup = .init()
    var peptide: AtlasOnboardingPeptideSetup = .init()

    private var protocolName: String {
        switch track {
        case .glp, .both:
            glp.medication?.trimmedNonEmpty ?? "Tirzepatide"
        case .peptide:
            peptide.selections.first?.trimmedNonEmpty ?? "BPC-157"
        case .later:
            peptide.selections.first?.trimmedNonEmpty ?? "Peptide protocol"
        }
    }

    private var doseText: String {
        switch track {
        case .glp, .both:
            glp.dose?.trimmedNonEmpty ?? "5 mg"
        case .peptide, .later:
            peptide.dose?.trimmedNonEmpty ?? "Custom"
        }
    }

    private var frequencyText: String {
        switch track {
        case .glp, .both:
            glp.frequency?.trimmedNonEmpty?.frequencyBadgeText ?? "Weekly"
        case .peptide, .later:
            peptide.frequency?.trimmedNonEmpty?.frequencyBadgeText ?? "Weekly"
        }
    }

    private var detailText: String {
        switch track {
        case .glp, .both:
            "\(doseText) • SubQ • 12:30 PM"
        case .peptide, .later:
            "\(doseText) • \(peptide.usualTime?.trimmedNonEmpty ?? "Time not set")"
        }
    }

    private var runwayText: String {
        track == .glp || track == .both ? "12 doses left" : "Inventory ready"
    }

    var body: some View {
        VStack(spacing: 9) {
            KairoDemoCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Next shot")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(AtlasPalette.textPrimary)
                    }
                    HStack(spacing: 7) {
                        Text(protocolName)
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(frequencyText)
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(AtlasPalette.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AtlasPalette.primaryGlow.opacity(0.48), in: Capsule())
                    }
                    Text(detailText)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text("Due 12:30 PM")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(AtlasPalette.primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            KairoDemoCard {
                HStack(spacing: 10) {
                    Image("KairoBoardVialIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 42)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Protocol")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(protocolName)
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text("\(frequencyText) • \(doseText)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text("Week 4 of 12")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(AtlasPalette.textPrimary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(AtlasPalette.textPrimary)
                }
            }

            KairoDemoCard {
                HStack(spacing: 10) {
                    Image("KairoBoardVialIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 42)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Inventory runway")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text(runwayText)
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(AtlasPalette.textPrimary)
                        Text("+21 days")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(AtlasPalette.primary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(AtlasPalette.textPrimary)
                }
            }
        }
    }
}

private struct KairoMiniInventoryPreview: View {
    var body: some View {
        HStack(spacing: 12) {
            Image("KairoBoardVialIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text("Inventory runway")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text("12 doses left")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AtlasPalette.textPrimary)
            }
            Spacer()
            Text("+21 days")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(AtlasPalette.primary)
        }
        .padding(12)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(AtlasPalette.border, lineWidth: 1))
    }
}

private struct KairoDemoCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(AtlasPalette.border, lineWidth: 1))
    }
}

private struct KairoAdherencePreviewCard: View {
    var body: some View {
        KairoDemoCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Adherence")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(AtlasPalette.textPrimary)
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("6 of 7")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(AtlasPalette.textPrimary)
                    Text("This week")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(AtlasPalette.textPrimary)
                }
                HStack(spacing: 5) {
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .fill(index < 7 ? AtlasPalette.primary : AtlasPalette.border)
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
    }
}

private struct KairoSymptomsPreviewCard: View {
    private let rows = [("Nausea", "Mild"), ("Fatigue", "Mild"), ("Injection site", "None")]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Symptoms (7d)")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(AtlasPalette.textPrimary)
            ForEach(rows, id: \.0) { row in
                HStack {
                    Text(row.0)
                    Spacer()
                    Text(row.1)
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AtlasPalette.textPrimary)
            }
        }
        .padding(11)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(AtlasPalette.border, lineWidth: 1))
    }
}

private struct KairoStatsCard: View {
    let title: String
    let value: String
    let detail: String
    let tint: SwiftUI.Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(tint)
                    Text(detail)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AtlasPalette.textPrimary)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AtlasPalette.border, lineWidth: 1))
    }
}

private struct KairoLineChartCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly trend")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(AtlasPalette.textPrimary)
            GeometryReader { proxy in
                Rectangle()
                    .fill(AtlasPalette.primaryGlow.opacity(0.32))
                    .frame(height: proxy.size.height * 0.35)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.78)
                Path { path in
                    let points: [CGFloat] = [0.72, 0.62, 0.58, 0.48, 0.44, 0.36, 0.31]
                    for index in points.indices {
                        let x = proxy.size.width * CGFloat(index) / CGFloat(points.count - 1)
                        let y = proxy.size.height * points[index]
                        if index == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(AtlasPalette.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            .frame(height: 58)
            HStack {
                ForEach(["Tue", "Wed", "Thu", "Fri", "Sat", "Sun", "Mon"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 7, weight: .black))
                        .foregroundStyle(AtlasPalette.textPrimary.opacity(0.76))
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(11)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(AtlasPalette.border, lineWidth: 1))
    }
}

private struct KairoLongTermComparisonChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your weight")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(AtlasPalette.textPrimary)

            GeometryReader { proxy in
                let size = proxy.size
                ZStack(alignment: .bottomLeading) {
                    VStack(spacing: size.height / 4) {
                        ForEach(0..<3, id: \.self) { _ in
                            Rectangle()
                                .fill(AtlasPalette.border.opacity(0.9))
                                .frame(height: 1)
                        }
                    }

                    KairoComparisonLine(
                        points: [
                            CGPoint(x: 0.06, y: 0.50),
                            CGPoint(x: 0.23, y: 0.54),
                            CGPoint(x: 0.42, y: 0.58),
                            CGPoint(x: 0.62, y: 0.67),
                            CGPoint(x: 0.82, y: 0.76),
                            CGPoint(x: 0.96, y: 0.80)
                        ],
                        size: size,
                        color: AtlasPalette.primary,
                        width: 3.2
                    )

                    KairoComparisonLine(
                        points: [
                            CGPoint(x: 0.06, y: 0.50),
                            CGPoint(x: 0.25, y: 0.47),
                            CGPoint(x: 0.44, y: 0.34),
                            CGPoint(x: 0.62, y: 0.42),
                            CGPoint(x: 0.82, y: 0.36),
                            CGPoint(x: 0.96, y: 0.28)
                        ],
                        size: size,
                        color: AtlasPalette.warning,
                        width: 2.4
                    )

                    Circle()
                        .fill(AtlasPalette.surfaceTop)
                        .overlay(Circle().stroke(AtlasPalette.textPrimary, lineWidth: 2))
                        .frame(width: 16, height: 16)
                        .position(x: size.width * 0.06, y: size.height * 0.50)

                    Circle()
                        .fill(AtlasPalette.surfaceTop)
                        .overlay(Circle().stroke(AtlasPalette.primary, lineWidth: 2.4))
                        .frame(width: 17, height: 17)
                        .position(x: size.width * 0.96, y: size.height * 0.20)

                    Text("Kairo")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(AtlasPalette.primary, in: Capsule())
                        .position(x: size.width * 0.22, y: size.height * 0.74)

                    Text("Unstructured")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(AtlasPalette.textPrimary)
                        .padding(.horizontal, 3)
                        .background(AtlasPalette.surfaceTop.opacity(0.92), in: Capsule())
                        .position(x: size.width * 0.68, y: size.height * 0.30)
                }
            }
            .frame(height: 158)

            HStack {
                Text("Month 1")
                Spacer()
                Text("Month 6")
            }
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(AtlasPalette.textPrimary)
        }
    }
}

private struct KairoComparisonLine: View {
    let points: [CGPoint]
    let size: CGSize
    let color: SwiftUI.Color
    let width: CGFloat

    var body: some View {
        Path { path in
            for index in points.indices {
                let point = CGPoint(
                    x: points[index].x * size.width,
                    y: (1 - points[index].y) * size.height
                )
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addCurve(
                        to: point,
                        control1: CGPoint(x: point.x - 32, y: point.y),
                        control2: CGPoint(x: point.x - 18, y: point.y)
                    )
                }
            }
        }
        .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
}

private struct KairoStepperRow: View {
    let title: String
    let value: Int
    let range: ClosedRange<Int>
    let unit: String
    let onChange: (Int) -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AtlasPalette.textPrimary)
            Spacer()
            Button { onChange(max(range.lowerBound, value - 1)) } label: { Image(systemName: "minus") }
            KairoEditableStepperValue(value: value, range: range, unit: unit, onChange: onChange)
            Button { onChange(min(range.upperBound, value + 1)) } label: { Image(systemName: "plus") }
        }
        .buttonStyle(.bordered)
        .tint(AtlasPalette.primary)
        .padding(12)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(AtlasPalette.border, lineWidth: 1))
    }
}

private struct KairoTrackButton: View {
    let type: AtlasTrackType
    let subtitle: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(selected ? AtlasPalette.primary : AtlasPalette.primary)
                    .frame(width: 28, height: 28)
                    .background(selected ? .white : AtlasPalette.secondaryFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                Text(type.title)
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundStyle(selected ? .white : AtlasPalette.textPrimary)
            .padding(12)
            .background(selected ? AtlasPalette.primary : AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(selected ? AtlasPalette.primary : AtlasPalette.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(type.title)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    private var icon: String {
        switch type {
        case .glp: "drop.fill"
        case .peptide: "syringe.fill"
        case .both: "square.grid.2x2.fill"
        case .later: "eye.fill"
        }
    }
}

private struct KairoCompanionChoiceCard: View {
    let name: String
    let subtitle: String
    let imageName: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                KairoCompanionMysteryPortrait(imageName: imageName, selected: selected)
                    .frame(height: 148)
                Text(name)
                    .font(.system(size: 13, weight: .black))
                Text(subtitle)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(AtlasPalette.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(10)
            .frame(height: 214)
            .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(selected ? AtlasPalette.primary : AtlasPalette.border, lineWidth: selected ? 2 : 1))
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AtlasPalette.primary)
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct KairoCompanionMysteryPortrait: View {
    let imageName: String
    let selected: Bool

    var body: some View {
        ZStack {
            Image(imageName)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundStyle(AtlasPalette.primary.opacity(selected ? 0.16 : 0.11))
                .blur(radius: selected ? 8 : 10)
                .scaleEffect(1.07)

            Image(imageName)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundStyle(AtlasPalette.textPrimary.opacity(selected ? 0.24 : 0.16))
                .shadow(color: AtlasPalette.surfaceTop.opacity(0.92), radius: 0, x: 0, y: 1)
                .shadow(color: AtlasPalette.primary.opacity(selected ? 0.26 : 0.12), radius: selected ? 12 : 8)

            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AtlasPalette.primary.opacity(selected ? 0.42 : 0.25))
                .offset(x: 46, y: -54)
        }
        .scaleEffect(selected ? 1.03 : 1)
        .accessibilityHidden(true)
    }
}

private struct KairoEvolutionStage: View {
    let image: String
    let title: String
    let detail: String
    let locked: Bool

    var body: some View {
        VStack(spacing: 7) {
            ZStack(alignment: .bottomTrailing) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 88)
                    .saturation(locked ? 0.05 : 1)
                    .opacity(locked ? 0.34 : 1)
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(AtlasPalette.textPrimary, in: Circle())
                }
            }
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(AtlasPalette.textPrimary)
            Text(detail)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(AtlasPalette.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(AtlasPalette.border, lineWidth: 1))
    }
}

private struct KairoMascotHatchingReveal: View {
    let imageName: String
    let height: CGFloat

    @State private var glow = false
    @State private var cracked = false
    @State private var emerged = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AtlasPalette.primaryGlow.opacity(glow ? 0.34 : 0.16),
                            AtlasPalette.secondaryFill.opacity(0.82),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 126
                    )
                )
                .frame(width: height * 0.98, height: height * 0.98)
                .scaleEffect(glow ? 1.05 : 0.94)
                .offset(y: -14)

            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: height * 0.76)
                .scaleEffect(emerged ? 1 : 0.58)
                .opacity(emerged ? 1 : 0)
                .offset(y: emerged ? -20 : 36)
                .shadow(color: AtlasPalette.primary.opacity(0.18), radius: 12, x: 0, y: 8)

            ZStack {
                EggHalf(isTop: true)
                    .rotationEffect(.degrees(cracked ? -15 : 0), anchor: .bottomTrailing)
                    .offset(x: cracked ? -28 : 0, y: cracked ? 20 : 0)
                EggHalf(isTop: false)
                    .rotationEffect(.degrees(cracked ? 12 : 0), anchor: .topLeading)
                    .offset(x: cracked ? 24 : 0, y: cracked ? 36 : 0)

                ForEach(0..<7, id: \.self) { index in
                    Circle()
                        .fill(index.isMultiple(of: 2) ? AtlasPalette.reward : AtlasPalette.primaryGlow)
                        .frame(width: 4, height: 4)
                        .opacity(cracked ? 0.9 : 0)
                        .offset(
                            x: cracked ? CGFloat(index - 3) * 18 : 0,
                            y: cracked ? CGFloat([-52, -38, -66, -46, -58, -34, -62][index]) : -8
                        )
                }
            }
            .frame(width: height * 0.78, height: height * 0.58)
            .offset(y: 6)
            .opacity(emerged ? 0.84 : 1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .task {
            glow = true
            try? await Task.sleep(nanoseconds: 260_000_000)
            withAnimation(.spring(response: 0.52, dampingFraction: 0.72)) {
                cracked = true
            }
            try? await Task.sleep(nanoseconds: 260_000_000)
            withAnimation(.spring(response: 0.72, dampingFraction: 0.74)) {
                emerged = true
            }
        }
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glow)
    }
}

private struct EggHalf: View {
    let isTop: Bool

    var body: some View {
        ZStack {
            UnevenRoundedRectangle(
                topLeadingRadius: isTop ? 88 : 10,
                bottomLeadingRadius: isTop ? 10 : 88,
                bottomTrailingRadius: isTop ? 10 : 88,
                topTrailingRadius: isTop ? 88 : 10,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        AtlasPalette.surfaceTop,
                        AtlasPalette.secondaryFill,
                        AtlasPalette.primaryGlow.opacity(0.32)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: isTop ? 88 : 10,
                    bottomLeadingRadius: isTop ? 10 : 88,
                    bottomTrailingRadius: isTop ? 10 : 88,
                    topTrailingRadius: isTop ? 88 : 10,
                    style: .continuous
                )
                .stroke(AtlasPalette.primary.opacity(0.18), lineWidth: 1)
            )

            Path { path in
                if isTop {
                    path.move(to: CGPoint(x: 24, y: 78))
                    path.addLine(to: CGPoint(x: 42, y: 58))
                    path.addLine(to: CGPoint(x: 58, y: 78))
                    path.addLine(to: CGPoint(x: 76, y: 56))
                    path.addLine(to: CGPoint(x: 96, y: 78))
                } else {
                    path.move(to: CGPoint(x: 22, y: 18))
                    path.addLine(to: CGPoint(x: 40, y: 36))
                    path.addLine(to: CGPoint(x: 58, y: 18))
                    path.addLine(to: CGPoint(x: 76, y: 36))
                    path.addLine(to: CGPoint(x: 98, y: 18))
                }
            }
            .stroke(AtlasPalette.primary.opacity(0.26), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 122, height: 92)
        .offset(y: isTop ? -22 : 26)
    }
}

private struct KairoBranchPathScreen: View {
    let track: AtlasTrackType
    let onSelect: (AtlasTrackType) -> Void

    var body: some View {
        KairoQuestionScaffold(title: "Choose your protocol path", subtitle: "") {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 18) {
                    KairoPathLegend(icon: "pills.fill", title: "GLP Path", isActive: track == .glp || track == .both) {
                        onSelect(.glp)
                    }
                    Rectangle()
                        .fill(AtlasPalette.border)
                        .frame(width: 1, height: 86)
                    KairoPathLegend(icon: "testtube.2", title: "Peptide Path", isActive: track == .peptide || track == .both || track == .later) {
                        onSelect(.peptide)
                    }
                }

                KairoPathTimelineRow(icon: track == .glp ? "pills.fill" : "testtube.2", title: track == .glp ? "Medication details" : "Peptide stack", detail: "Compounds, cadence, and dose label")
                KairoPathTimelineRow(icon: "calendar.badge.clock", title: "Schedule rhythm", detail: "Injection day, frequency, and reminders")
                KairoPathTimelineRow(icon: "scope", title: "Goal focus", detail: "The first-week plan adapts to the path")
            }
            .padding(14)
            .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AtlasPalette.border, lineWidth: 1))
        }
    }
}

private struct KairoPathLegend: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(isActive ? AtlasPalette.primary : AtlasPalette.textPrimary.opacity(0.42))
                    .frame(width: 52, height: 52)
                    .background(AtlasPalette.secondaryFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                Text(title)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(isActive ? AtlasPalette.primary : AtlasPalette.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
    }
}

private struct KairoPathTimelineRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AtlasPalette.primary)
                .frame(width: 32, height: 32)
                .background(AtlasPalette.secondaryFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AtlasPalette.textPrimary)
                Text(detail)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AtlasPalette.textPrimary)
            }
            Spacer()
        }
    }
}

private struct KairoInfoBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .black))
            .foregroundStyle(AtlasPalette.textPrimary)
            .lineSpacing(2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct KairoSmallSystemCard: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AtlasPalette.primary)
            Text(title)
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(AtlasPalette.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct KairoPermissionRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(AtlasPalette.primary)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 15, weight: .black)).foregroundStyle(AtlasPalette.textPrimary)
                Text(detail).font(.system(size: 12, weight: .semibold)).foregroundStyle(AtlasPalette.textPrimary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

private struct KairoGradientProgress: View {
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(AtlasPalette.secondaryFill)
                Capsule()
                    .fill(LinearGradient(colors: [AtlasPalette.warning, AtlasPalette.primary], startPoint: .leading, endPoint: .trailing))
                    .frame(width: proxy.size.width * value)
            }
        }
        .frame(height: 8)
    }
}

private struct KairoPlanTile: View {
    let icon: String
    let title: String
    let detail: String
    var checked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(AtlasPalette.primary)
                Spacer()
                if checked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AtlasPalette.primary)
                }
            }
            Text(title)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(AtlasPalette.textPrimary)
            Text(detail)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AtlasPalette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AtlasPalette.secondaryFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct KairoConsistencyScore: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Health consistency score potential")
                Spacer()
                Text("10/10")
                    .foregroundStyle(AtlasPalette.primary)
            }
            .font(.system(size: 13, weight: .black))
            KairoProgressBar(value: 1.0)
        }
        .padding(12)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AtlasPalette.border, lineWidth: 1))
    }
}

private struct KairoTrialTimeline: View {
    var body: some View {
        HStack(spacing: 0) {
            KairoTrialTimelineItem(icon: "checkmark.circle.fill", title: "Today", detail: "Full access")
            Rectangle().fill(AtlasPalette.border).frame(height: 1)
            KairoTrialTimelineItem(icon: "bell.badge.fill", title: "Day 2", detail: "Reminder")
            Rectangle().fill(AtlasPalette.border).frame(height: 1)
            KairoTrialTimelineItem(icon: "crown.fill", title: "Day 3", detail: "Renewal")
        }
        .padding(12)
        .background(AtlasPalette.surfaceTop, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AtlasPalette.border, lineWidth: 1))
    }
}

private struct KairoTrialTimelineItem: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AtlasPalette.primary)
                .frame(width: 28, height: 28)
                .background(AtlasPalette.secondaryFill, in: Circle())
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(AtlasPalette.textPrimary)
            Text(detail)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(AtlasPalette.textPrimary)
        }
        .frame(width: 74)
    }
}

private struct KairoAuthButton: View {
    let icon: String
    let title: String
    let filled: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
            Spacer()
        }
        .font(.system(size: 15, weight: .heavy))
        .foregroundStyle(filled ? .white : AtlasPalette.textPrimary)
        .padding(15)
        .background(filled ? AtlasPalette.primary : AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(filled ? AtlasPalette.primary : AtlasPalette.border, lineWidth: 1))
    }
}

private struct KairoTextFieldPreview: View {
    let label: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(AtlasPalette.textPrimary)
            Spacer()
            Text("required")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AtlasPalette.textPrimary)
        }
        .padding(15)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct KairoPlanPriceRow: View {
    let title: String
    let price: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(size: 16, weight: .black))
                    Text(price).font(.system(size: 13, weight: .bold)).opacity(0.78)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
            }
            .foregroundStyle(selected ? .white : AtlasPalette.textPrimary)
            .padding(15)
            .background(selected ? AtlasPalette.primary : AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct KairoPreviewMetric: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(AtlasPalette.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 11, weight: .heavy)).foregroundStyle(AtlasPalette.textPrimary)
                Text(value).font(.system(size: 13, weight: .black)).foregroundStyle(AtlasPalette.textPrimary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(AtlasPalette.surfaceSecondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct KairoProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(AtlasPalette.secondaryFill)
                Capsule().fill(AtlasPalette.primary).frame(width: proxy.size.width * value)
            }
        }
        .frame(height: 7)
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var frequencyBadgeText: String {
        if localizedCaseInsensitiveContains("weekly") {
            return "Weekly"
        }
        if localizedCaseInsensitiveContains("daily") {
            return "Daily"
        }
        if localizedCaseInsensitiveContains("2-3") {
            return "2-3x"
        }
        return self
    }
}
