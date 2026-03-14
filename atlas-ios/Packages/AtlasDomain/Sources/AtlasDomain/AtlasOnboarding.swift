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

public enum AtlasHeightUnit: String, Codable, CaseIterable, Sendable {
    case cm
    case ftIn = "ft_in"
}

public enum AtlasOnboardingStep: String, Codable, CaseIterable, Identifiable, Sendable {
    case splash
    case intro
    case accountMode
    case privacyMode
    case trackType
    case profile
    case glpSetup
    case peptideSetup
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
    public var age: Int?
    public var goalWeight: Double?
    public var height: Double?
    public var heightUnit: AtlasHeightUnit?
    public var weight: Double?
    public var weightUnit: AtlasWeightUnit?

    public init(
        gender: String? = nil,
        age: Int? = nil,
        goalWeight: Double? = nil,
        height: Double? = nil,
        heightUnit: AtlasHeightUnit? = nil,
        weight: Double? = nil,
        weightUnit: AtlasWeightUnit? = nil
    ) {
        self.gender = gender
        self.age = age
        self.goalWeight = goalWeight
        self.height = height
        self.heightUnit = heightUnit
        self.weight = weight
        self.weightUnit = weightUnit
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
    public var profile: AtlasOnboardingProfile
    public var glp: AtlasOnboardingGlpSetup
    public var peptide: AtlasOnboardingPeptideSetup
    public var healthConnectionPromptSeen: Bool

    public init(
        accountMode: AtlasOnboardingAccountMode? = nil,
        privacy: AtlasOnboardingPrivacy = .init(),
        trackType: AtlasTrackType? = nil,
        profile: AtlasOnboardingProfile = .init(),
        glp: AtlasOnboardingGlpSetup = .init(),
        peptide: AtlasOnboardingPeptideSetup = .init(),
        healthConnectionPromptSeen: Bool = false
    ) {
        self.accountMode = accountMode
        self.privacy = privacy
        self.trackType = trackType
        self.profile = profile
        self.glp = glp
        self.peptide = peptide
        self.healthConnectionPromptSeen = healthConnectionPromptSeen
    }

    public static func empty() -> Self {
        Self()
    }

    public func requiredMissingFields() -> [String] {
        var missing: [String] = []

        if accountMode == nil {
            missing.append("accountMode")
        }
        if trackType == nil {
            missing.append("trackType")
        }
        if healthConnectionPromptSeen == false {
            missing.append("healthConnectionPromptSeen")
        }
        if needsGlpSetup {
            if glp.medication?.isEmpty != false { missing.append("glp.medication") }
            if glp.frequency?.isEmpty != false { missing.append("glp.frequency") }
            if glp.injectionDay?.isEmpty != false { missing.append("glp.injectionDay") }
            if glp.dose?.isEmpty != false { missing.append("glp.dose") }
            if glp.duration?.isEmpty != false { missing.append("glp.duration") }
            if glp.goal?.isEmpty != false { missing.append("glp.goal") }
            if glp.challenge?.isEmpty != false { missing.append("glp.challenge") }
        }
        if needsPeptideSetup {
            if peptide.selections.isEmpty { missing.append("peptide.selections") }
            if peptide.frequency?.isEmpty != false { missing.append("peptide.frequency") }
            if peptide.experience?.isEmpty != false { missing.append("peptide.experience") }
            if peptide.usualTime?.isEmpty != false { missing.append("peptide.usualTime") }
            if peptide.dose?.isEmpty != false { missing.append("peptide.dose") }
            if peptide.goal?.isEmpty != false { missing.append("peptide.goal") }
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
        var steps: [AtlasOnboardingStep] = [
            .splash,
            .intro,
            .accountMode,
            .privacyMode,
            .trackType,
            .profile
        ]
        if needsGlpSetup {
            steps.append(.glpSetup)
        }
        if needsPeptideSetup {
            steps.append(.peptideSetup)
        }
        steps.append(.connectApps)
        steps.append(.planReady)
        return steps
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

public struct AtlasHealthScaffoldSnapshot: Codable, Equatable, Sendable {
    public var isAvailable: Bool
    public var connections: [AtlasHealthConnectionRecord]

    public init(
        isAvailable: Bool = true,
        connections: [AtlasHealthConnectionRecord] = []
    ) {
        self.isAvailable = isAvailable
        self.connections = connections
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
