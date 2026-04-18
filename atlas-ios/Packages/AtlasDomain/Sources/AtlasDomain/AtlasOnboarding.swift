import Foundation

public enum AtlasOnboardingAccountMode: String, Codable, CaseIterable, Sendable {
    case guest
    case create
    case signIn

    public var title: String {
        switch self {
        case .guest:
            "Continue as guest"
        case .create:
            "Create account"
        case .signIn:
            "Sign in"
        }
    }
}

public enum AtlasTrackType: String, Codable, CaseIterable, Sendable {
    case glp
    case peptide
    case both
    case later

    public var title: String {
        switch self {
        case .glp:
            "GLP"
        case .peptide:
            "Peptide"
        case .both:
            "Both"
        case .later:
            "Explore first"
        }
    }
}

public enum AtlasOnboardingJourneyStatus: String, Codable, CaseIterable, Sendable {
    case active
    case startingSoon
    case changingPlan
    case trackingHistory
    case exploring

    public var title: String {
        switch self {
        case .active:
            "Already using"
        case .startingSoon:
            "Starting soon"
        case .changingPlan:
            "Changing plan"
        case .trackingHistory:
            "Tracking history"
        case .exploring:
            "Just exploring"
        }
    }
}

public enum AtlasOnboardingFocus: String, Codable, CaseIterable, Sendable {
    case neverMiss
    case understandPatterns
    case inventoryRunway
    case providerReview
    case manageStack
    case privateRecords

    public var title: String {
        switch self {
        case .neverMiss:
            "Never miss a dose"
        case .understandPatterns:
            "Understand patterns"
        case .inventoryRunway:
            "Track inventory"
        case .providerReview:
            "Prepare review summaries"
        case .manageStack:
            "Manage multiple protocols"
        case .privateRecords:
            "Keep private records"
        }
    }
}

public enum AtlasOnboardingPrivacyPreset: String, Codable, CaseIterable, Sendable {
    case standard
    case discreet
    case alias

    public var title: String {
        switch self {
        case .standard:
            "Standard"
        case .discreet:
            "Discreet"
        case .alias:
            "Alias"
        }
    }
}

public enum AtlasOnboardingPremiumPlan: String, Codable, CaseIterable, Sendable {
    case annual
    case monthly

    public var title: String {
        switch self {
        case .annual:
            "Annual"
        case .monthly:
            "Monthly"
        }
    }
}

public enum AtlasOnboardingPaywallChoice: String, Codable, Equatable, Sendable {
    case trialStarted
    case basic
}

public enum AtlasHeightUnit: String, Codable, CaseIterable, Sendable {
    case cm
    case ftIn = "ft_in"
}

public enum AtlasOnboardingStep: String, Codable, CaseIterable, Identifiable, Sendable {
    case splash
    case trackType
    case journeyStatus
    case protocolPreview
    case focus
    case goalsProfile
    case healthDisclaimer
    case privacyPreset
    case premiumPreview
    case trustVaultReveal
    case companionPreview
    case readinessLoop
    case systemSurfaces
    case personalizedUnlock
    case todayCommandPreview
    case protocolChangeHistory
    case reviewOutputPreview
    case migrationPreview
    case trialTimeline
    case premiumPaywall
    case connectApps
    case planReady

    public var id: String { rawValue }
}

public struct AtlasOnboardingPrivacy: Codable, Equatable, Sendable {
    public var discreetNotifications: Bool
    public var hideSensitiveLabels: Bool
    public var biometricLater: Bool
    public var analyticsOptIn: Bool

    public init(
        discreetNotifications: Bool = false,
        hideSensitiveLabels: Bool = false,
        biometricLater: Bool = false,
        analyticsOptIn: Bool = false
    ) {
        self.discreetNotifications = discreetNotifications
        self.hideSensitiveLabels = hideSensitiveLabels
        self.biometricLater = biometricLater
        self.analyticsOptIn = analyticsOptIn
    }
}

public struct AtlasOnboardingProfile: Codable, Equatable, Sendable {
    public var gender: String?
    public var mascotSelection: AtlasMascotSelection?
    public var mascotNickname: String?
    public var age: Int?
    public var goalWeight: Double?
    public var height: Double?
    public var heightUnit: AtlasHeightUnit?
    public var weight: Double?
    public var weightUnit: AtlasWeightUnit?
    public var goalPacePoundsPerWeek: Double?
    public var wantsNutritionTracking: Bool

    enum CodingKeys: String, CodingKey {
        case gender
        case mascotSelection
        case mascotNickname
        case age
        case goalWeight
        case height
        case heightUnit
        case weight
        case weightUnit
        case goalPacePoundsPerWeek
        case wantsNutritionTracking
    }

    public init(
        gender: String? = nil,
        mascotSelection: AtlasMascotSelection? = nil,
        mascotNickname: String? = nil,
        age: Int? = nil,
        goalWeight: Double? = nil,
        height: Double? = nil,
        heightUnit: AtlasHeightUnit? = nil,
        weight: Double? = nil,
        weightUnit: AtlasWeightUnit? = nil,
        goalPacePoundsPerWeek: Double? = nil,
        wantsNutritionTracking: Bool = false
    ) {
        self.gender = gender
        self.mascotSelection = mascotSelection
        self.mascotNickname = mascotNickname
        self.age = age
        self.goalWeight = goalWeight
        self.height = height
        self.heightUnit = heightUnit
        self.weight = weight
        self.weightUnit = weightUnit
        self.goalPacePoundsPerWeek = goalPacePoundsPerWeek
        self.wantsNutritionTracking = wantsNutritionTracking
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.gender = try container.decodeIfPresent(String.self, forKey: .gender)
        self.mascotSelection = try container.decodeIfPresent(AtlasMascotSelection.self, forKey: .mascotSelection)
        self.mascotNickname = try container.decodeIfPresent(String.self, forKey: .mascotNickname)
        self.age = try container.decodeIfPresent(Int.self, forKey: .age)
        self.goalWeight = try container.decodeIfPresent(Double.self, forKey: .goalWeight)
        self.height = try container.decodeIfPresent(Double.self, forKey: .height)
        self.heightUnit = try container.decodeIfPresent(AtlasHeightUnit.self, forKey: .heightUnit)
        self.weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        self.weightUnit = try container.decodeIfPresent(AtlasWeightUnit.self, forKey: .weightUnit)
        self.goalPacePoundsPerWeek = try container.decodeIfPresent(Double.self, forKey: .goalPacePoundsPerWeek)
        self.wantsNutritionTracking = try container.decodeIfPresent(Bool.self, forKey: .wantsNutritionTracking) ?? false
    }
}

public struct AtlasOnboardingGlpSetup: Codable, Equatable, Sendable {
    public var medication: String?
    public var frequency: String?
    public var injectionDay: String?
    public var dose: String?
    public var duration: String?
    public var goal: String?
    public var challenge: String?

    public init(
        medication: String? = nil,
        frequency: String? = nil,
        injectionDay: String? = nil,
        dose: String? = nil,
        duration: String? = nil,
        goal: String? = nil,
        challenge: String? = nil
    ) {
        self.medication = medication
        self.frequency = frequency
        self.injectionDay = injectionDay
        self.dose = dose
        self.duration = duration
        self.goal = goal
        self.challenge = challenge
    }
}

public struct AtlasOnboardingPeptideSetup: Codable, Equatable, Sendable {
    public var selections: [String]
    public var frequency: String?
    public var experience: String?
    public var usualTime: String?
    public var dose: String?
    public var goal: String?

    public init(
        selections: [String] = [],
        frequency: String? = nil,
        experience: String? = nil,
        usualTime: String? = nil,
        dose: String? = nil,
        goal: String? = nil
    ) {
        self.selections = selections
        self.frequency = frequency
        self.experience = experience
        self.usualTime = usualTime
        self.dose = dose
        self.goal = goal
    }
}

public struct AtlasOnboardingDraft: Codable, Equatable, Sendable {
    public var accountMode: AtlasOnboardingAccountMode?
    public var privacy: AtlasOnboardingPrivacy
    public var trackType: AtlasTrackType?
    public var journeyStatus: AtlasOnboardingJourneyStatus?
    public var focus: AtlasOnboardingFocus?
    public var privacyPreset: AtlasOnboardingPrivacyPreset?
    public var premiumPlan: AtlasOnboardingPremiumPlan
    public var paywallChoice: AtlasOnboardingPaywallChoice?
    public var profile: AtlasOnboardingProfile
    public var glp: AtlasOnboardingGlpSetup
    public var peptide: AtlasOnboardingPeptideSetup
    public var healthConnectionPromptSeen: Bool
    public var healthDisclaimerAccepted: Bool

    enum CodingKeys: String, CodingKey {
        case accountMode
        case privacy
        case trackType
        case journeyStatus
        case focus
        case privacyPreset
        case premiumPlan
        case paywallChoice
        case profile
        case glp
        case peptide
        case healthConnectionPromptSeen
        case healthDisclaimerAccepted
    }

    public init(
        accountMode: AtlasOnboardingAccountMode? = .guest,
        privacy: AtlasOnboardingPrivacy = .init(),
        trackType: AtlasTrackType? = nil,
        journeyStatus: AtlasOnboardingJourneyStatus? = nil,
        focus: AtlasOnboardingFocus? = nil,
        privacyPreset: AtlasOnboardingPrivacyPreset? = nil,
        premiumPlan: AtlasOnboardingPremiumPlan = .annual,
        paywallChoice: AtlasOnboardingPaywallChoice? = nil,
        profile: AtlasOnboardingProfile = .init(),
        glp: AtlasOnboardingGlpSetup = .init(),
        peptide: AtlasOnboardingPeptideSetup = .init(),
        healthConnectionPromptSeen: Bool = false,
        healthDisclaimerAccepted: Bool = false
    ) {
        self.accountMode = accountMode
        self.privacy = privacy
        self.trackType = trackType
        self.journeyStatus = journeyStatus
        self.focus = focus
        self.privacyPreset = privacyPreset
        self.premiumPlan = premiumPlan
        self.paywallChoice = paywallChoice
        self.profile = profile
        self.glp = glp
        self.peptide = peptide
        self.healthConnectionPromptSeen = healthConnectionPromptSeen
        self.healthDisclaimerAccepted = healthDisclaimerAccepted
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accountMode = try container.decodeIfPresent(AtlasOnboardingAccountMode.self, forKey: .accountMode) ?? .guest
        self.privacy = try container.decodeIfPresent(AtlasOnboardingPrivacy.self, forKey: .privacy) ?? .init()
        self.trackType = try container.decodeIfPresent(AtlasTrackType.self, forKey: .trackType)
        self.journeyStatus = try container.decodeIfPresent(AtlasOnboardingJourneyStatus.self, forKey: .journeyStatus)
        self.focus = try container.decodeIfPresent(AtlasOnboardingFocus.self, forKey: .focus)
        self.privacyPreset = try container.decodeIfPresent(AtlasOnboardingPrivacyPreset.self, forKey: .privacyPreset)
        self.premiumPlan = try container.decodeIfPresent(AtlasOnboardingPremiumPlan.self, forKey: .premiumPlan) ?? .annual
        self.paywallChoice = try container.decodeIfPresent(AtlasOnboardingPaywallChoice.self, forKey: .paywallChoice)
        self.profile = try container.decodeIfPresent(AtlasOnboardingProfile.self, forKey: .profile) ?? .init()
        self.glp = try container.decodeIfPresent(AtlasOnboardingGlpSetup.self, forKey: .glp) ?? .init()
        self.peptide = try container.decodeIfPresent(AtlasOnboardingPeptideSetup.self, forKey: .peptide) ?? .init()
        self.healthConnectionPromptSeen = try container.decodeIfPresent(Bool.self, forKey: .healthConnectionPromptSeen) ?? false
        self.healthDisclaimerAccepted = try container.decodeIfPresent(Bool.self, forKey: .healthDisclaimerAccepted) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(accountMode, forKey: .accountMode)
        try container.encode(privacy, forKey: .privacy)
        try container.encodeIfPresent(trackType, forKey: .trackType)
        try container.encodeIfPresent(journeyStatus, forKey: .journeyStatus)
        try container.encodeIfPresent(focus, forKey: .focus)
        try container.encodeIfPresent(privacyPreset, forKey: .privacyPreset)
        try container.encode(premiumPlan, forKey: .premiumPlan)
        try container.encodeIfPresent(paywallChoice, forKey: .paywallChoice)
        try container.encode(profile, forKey: .profile)
        try container.encode(glp, forKey: .glp)
        try container.encode(peptide, forKey: .peptide)
        try container.encode(healthConnectionPromptSeen, forKey: .healthConnectionPromptSeen)
        try container.encode(healthDisclaimerAccepted, forKey: .healthDisclaimerAccepted)
    }

    public static func empty() -> Self {
        Self()
    }

    public func requiredMissingFields() -> [String] {
        var missing: [String] = []

        if trackType == nil {
            missing.append("trackType")
        }
        if journeyStatus == nil {
            missing.append("journeyStatus")
        }
        if focus == nil {
            missing.append("focus")
        }
        if privacyPreset == nil {
            missing.append("privacyPreset")
        }
        if healthDisclaimerAccepted == false {
            missing.append("healthDisclaimerAccepted")
        }
        if paywallChoice == nil {
            missing.append("paywallChoice")
        }
        if healthConnectionPromptSeen == false {
            missing.append("healthConnectionPromptSeen")
        }

        return missing
    }

    public var isComplete: Bool {
        requiredMissingFields().isEmpty
    }

    public var needsGlpSetup: Bool {
        trackType == .glp || trackType == .both
    }

    public var needsPeptideSetup: Bool {
        trackType == .peptide || trackType == .both
    }

    public func sequence() -> [AtlasOnboardingStep] {
        [
            .splash,
            .trackType,
            .journeyStatus,
            .protocolPreview,
            .focus,
            .goalsProfile,
            .healthDisclaimer,
            .privacyPreset,
            .premiumPreview,
            .trustVaultReveal,
            .companionPreview,
            .readinessLoop,
            .systemSurfaces,
            .personalizedUnlock,
            .todayCommandPreview,
            .protocolChangeHistory,
            .reviewOutputPreview,
            .migrationPreview,
            .trialTimeline,
            .premiumPaywall,
            .connectApps,
            .planReady
        ]
    }
}

public enum AtlasBootstrapDestination: String, Codable, Sendable {
    case onboarding
    case app
}

public enum AtlasBootstrapReason: String, Codable, Sendable {
    case firstRun
    case resumedOnboarding
    case completedOnboarding
    case importedLocalUser
    case existingLocalUser
}

public enum AtlasSyncScaffoldStatus: String, Codable, Sendable {
    case localOnly
    case accountBoundary
    case syncDeferred
}

public enum AtlasHealthSignalKind: String, Codable, CaseIterable, Equatable, Sendable, Identifiable {
    case weight
    case workouts
    case water
    case calories
    case protein
    case steps
    case sleep
    case restingHeartRate
    case heartRateVariability
    case bloodPressure
    case bodyFat

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .weight: "Weight"
        case .workouts: "Workouts"
        case .water: "Water"
        case .calories: "Calories"
        case .protein: "Protein"
        case .steps: "Steps"
        case .sleep: "Sleep"
        case .restingHeartRate: "Resting HR"
        case .heartRateVariability: "HRV"
        case .bloodPressure: "Blood pressure"
        case .bodyFat: "Body fat"
        }
    }
}

public struct AtlasHealthSignalSummary: Codable, Equatable, Sendable, Identifiable {
    public var id: AtlasHealthSignalKind { kind }
    public var kind: AtlasHealthSignalKind
    public var importedEntryCount: Int
    public var lastEntryAt: String?

    public init(
        kind: AtlasHealthSignalKind,
        importedEntryCount: Int,
        lastEntryAt: String?
    ) {
        self.kind = kind
        self.importedEntryCount = importedEntryCount
        self.lastEntryAt = lastEntryAt
    }
}

public struct AtlasHealthScaffoldSnapshot: Codable, Equatable, Sendable {
    public var isAvailable: Bool
    public var connections: [AtlasHealthConnectionRecord]
    public var syncsWeight: Bool
    public var syncsWorkouts: Bool
    public var syncsNutrition: Bool
    public var syncsPassiveSignals: Bool
    public var syncedWeightEntryCount: Int
    public var lastWeightEntryAt: String?
    public var syncedWorkoutEntryCount: Int
    public var lastWorkoutEntryAt: String?
    public var signalSummaries: [AtlasHealthSignalSummary]

    public init(
        isAvailable: Bool = true,
        connections: [AtlasHealthConnectionRecord] = [],
        syncsWeight: Bool = true,
        syncsWorkouts: Bool = true,
        syncsNutrition: Bool = true,
        syncsPassiveSignals: Bool = true,
        syncedWeightEntryCount: Int = 0,
        lastWeightEntryAt: String? = nil,
        syncedWorkoutEntryCount: Int = 0,
        lastWorkoutEntryAt: String? = nil,
        signalSummaries: [AtlasHealthSignalSummary] = []
    ) {
        self.isAvailable = isAvailable
        self.connections = connections
        self.syncsWeight = syncsWeight
        self.syncsWorkouts = syncsWorkouts
        self.syncsNutrition = syncsNutrition
        self.syncsPassiveSignals = syncsPassiveSignals
        self.syncedWeightEntryCount = syncedWeightEntryCount
        self.lastWeightEntryAt = lastWeightEntryAt
        self.syncedWorkoutEntryCount = syncedWorkoutEntryCount
        self.lastWorkoutEntryAt = lastWorkoutEntryAt
        self.signalSummaries = signalSummaries
    }
}

public struct AtlasBootstrapSnapshot: Codable, Equatable, Sendable {
    public var destination: AtlasBootstrapDestination
    public var reason: AtlasBootstrapReason
    public var onboardingDraft: AtlasOnboardingDraft
    public var onboardingCompleted: Bool
    public var hasLocalData: Bool
    public var isImportedLocalUser: Bool

    public init(
        destination: AtlasBootstrapDestination,
        reason: AtlasBootstrapReason,
        onboardingDraft: AtlasOnboardingDraft,
        onboardingCompleted: Bool,
        hasLocalData: Bool,
        isImportedLocalUser: Bool
    ) {
        self.destination = destination
        self.reason = reason
        self.onboardingDraft = onboardingDraft
        self.onboardingCompleted = onboardingCompleted
        self.hasLocalData = hasLocalData
        self.isImportedLocalUser = isImportedLocalUser
    }
}
