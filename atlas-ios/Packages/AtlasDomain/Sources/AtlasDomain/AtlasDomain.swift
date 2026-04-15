import Foundation

public enum AtlasTab: String, CaseIterable, Hashable, Identifiable, Sendable {
    case today
    case timeline
    case library
    case insights
    case settings

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .today: "Today"
        case .timeline: "Timeline"
        case .library: "Library"
        case .insights: "Insights"
        case .settings: "Settings"
        }
    }

    public var systemImage: String {
        switch self {
        case .today: "sparkles"
        case .timeline: "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .library: "books.vertical"
        case .insights: "chart.line.uptrend.xyaxis"
        case .settings: "gearshape"
        }
    }
}

public enum AtlasRoute: Hashable, Sendable {
    case protocolDetail(String)
    case protocolCreate
    case protocolEdit(String)
    case protocolChange(String)
    case medicationLevels(String)
    case compoundIntelligence(String)
    case rewards
    case inventory
    case labs
    case mascot
    case calculator
    case trustVault
    case importFlow
    case reviewMode
    case weeklyReview
    case progressEvidence
    case quickCapture(AtlasQuickCaptureKind)
    case watchCompanion
}

public enum AtlasQuickCaptureKind: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case shot
    case weight
    case symptom
    case context
    case hydration
    case protein
    case progressPhoto = "progress_photo"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .shot: "Shot"
        case .weight: "Weight"
        case .symptom: "Symptom"
        case .context: "Context"
        case .hydration: "Hydration"
        case .protein: "Protein"
        case .progressPhoto: "Progress Photo"
        }
    }

    public var systemImage: String {
        switch self {
        case .shot: "syringe.fill"
        case .weight: "scalemass.fill"
        case .symptom: "waveform.path.ecg"
        case .context: "fork.knife.circle.fill"
        case .hydration: "drop.fill"
        case .protein: "bolt.heart.fill"
        case .progressPhoto: "camera.fill"
        }
    }
}

public enum AtlasAccountMode: String, Codable, Sendable {
    case guest
    case account
}

public enum AtlasPrivacyRenderMode: String, Codable, CaseIterable, Sendable {
    case full
    case discreet
    case alias
}

public enum AtlasFeatureFlag: String, CaseIterable, Sendable {
    case nativeWidgets
    case nativeIntents
    case trustVaultShell
    case importShell
    case reviewMode
    case liveReviewSessions
    case boundedSummaries
    case externalSummaryProviders
    case calmRetention
    case companionSkin
}

public struct AtlasFeatureFlagState: Codable, Sendable, Equatable {
    public var nativeWidgets: Bool
    public var nativeIntents: Bool
    public var trustVaultShell: Bool
    public var importShell: Bool
    public var reviewMode: Bool
    public var liveReviewSessions: Bool
    public var boundedSummaries: Bool
    public var externalSummaryProviders: Bool
    public var calmRetention: Bool
    public var companionSkin: Bool

    public init(
        nativeWidgets: Bool = true,
        nativeIntents: Bool = true,
        trustVaultShell: Bool = true,
        importShell: Bool = true,
        reviewMode: Bool = true,
        liveReviewSessions: Bool = true,
        boundedSummaries: Bool = true,
        externalSummaryProviders: Bool = false,
        calmRetention: Bool = true,
        companionSkin: Bool = true
    ) {
        self.nativeWidgets = nativeWidgets
        self.nativeIntents = nativeIntents
        self.trustVaultShell = trustVaultShell
        self.importShell = importShell
        self.reviewMode = reviewMode
        self.liveReviewSessions = liveReviewSessions
        self.boundedSummaries = boundedSummaries
        self.externalSummaryProviders = externalSummaryProviders
        self.calmRetention = calmRetention
        self.companionSkin = companionSkin
    }

    public func isEnabled(_ flag: AtlasFeatureFlag) -> Bool {
        switch flag {
        case .nativeWidgets: nativeWidgets
        case .nativeIntents: nativeIntents
        case .trustVaultShell: trustVaultShell
        case .importShell: importShell
        case .reviewMode: reviewMode
        case .liveReviewSessions: liveReviewSessions
        case .boundedSummaries: boundedSummaries
        case .externalSummaryProviders: externalSummaryProviders
        case .calmRetention: calmRetention
        case .companionSkin: companionSkin
        }
    }
}

public enum AtlasProtocolKind: String, Codable, CaseIterable, Sendable {
    case glp
    case peptide
    case custom
}

public enum AtlasProtocolAdministrationRoute: String, Codable, CaseIterable, Sendable {
    case injection
    case oral
    case sublingual
    case nasal
    case topical
    case transdermal
    case other
}

public enum AtlasProtocolSupplyType: String, Codable, CaseIterable, Sendable {
    case vial
    case pen
    case bottle
    case blisterPack = "blister_pack"
    case syringe
    case other
}

public enum AtlasProtocolStatus: String, Codable, CaseIterable, Sendable {
    case draft
    case active
    case paused
    case archived
}

public enum AtlasProtocolRuleType: String, Codable, CaseIterable, Sendable {
    case weekly
    case daily
    case everyNDays = "every_n_days"
}

public enum AtlasProtocolRevisionLifecycle: String, Codable, CaseIterable, Sendable {
    case active
    case paused
    case resting
}

public enum AtlasProtocolRevisionPhaseType: String, Codable, CaseIterable, Sendable {
    case base
    case titration
    case rest
}

public enum AtlasProtocolTimezoneStrategy: String, Codable, CaseIterable, Sendable {
    case keepLocalClock = "keep_local_clock"
    case keepHomeTimezone = "keep_home_timezone"
}

public enum AtlasMissedDosePolicy: String, Codable, CaseIterable, Sendable {
    case skipAndContinue = "skip_and_continue"
    case takeNowKeepCadence = "take_now_keep_cadence"
    case takeNowShiftFuture = "take_now_shift_future"
}

public enum AtlasProtocolChangeAuditType: String, Codable, CaseIterable, Sendable {
    case futureDoseChanged = "future_dose_changed"
    case timeChanged = "time_changed"
    case cadenceChanged = "cadence_changed"
    case paused
    case resumed
    case titrationChanged = "titration_changed"
    case restPeriodChanged = "rest_period_changed"
    case missedDosePolicyChanged = "missed_dose_policy_changed"
    case timezoneChanged = "timezone_changed"
    case vialHandoffPlanned = "vial_handoff_planned"
    case revisionReverted = "revision_reverted"
}

public enum AtlasLogEventType: String, Codable, CaseIterable, Sendable {
    case completed
    case skipped
    case rescheduled
    case manualLog = "manual_log"
    case inventoryAdjustment = "inventory_adjustment"
}

public enum AtlasLogEventSource: String, Codable, CaseIterable, Sendable {
    case user
    case migration
    case system
}

public enum AtlasReminderChannel: String, Codable, CaseIterable, Sendable {
    case localNotification = "local_notification"
}

public enum AtlasReminderPrivacyMode: String, Codable, CaseIterable, Sendable {
    case fullDetail = "full_detail"
    case generic
    case silent
}

public enum AtlasReminderStatus: String, Codable, CaseIterable, Sendable {
    case scheduled
    case cancelled
}

public enum AtlasBiometricGateMode: String, Codable, CaseIterable, Sendable {
    case off
    case bestEffort = "best_effort"
    case requiredWhenAvailable = "required_when_available"
}

public enum AtlasSensitiveActionAuditEventType: String, Codable, CaseIterable, Sendable {
    case exportCreated = "export_created"
    case selectiveShareCreated = "selective_share_created"
    case providerHandoffCreated = "provider_handoff_created"
    case summaryGeneratedOffDevice = "summary_generated_off_device"
    case importCommitted = "import_committed"
    case restorePointCreated = "restore_point_created"
    case restoreCommitted = "restore_committed"
    case reviewPackCreated = "review_pack_created"
    case aliasChanged = "alias_changed"
    case privacyModeChanged = "privacy_mode_changed"
    case biometricLockChanged = "biometric_lock_changed"
    case vaultUnlocked = "vault_unlocked"
}

public enum AtlasCustomMetricValueType: String, Codable, CaseIterable, Sendable {
    case number
    case scale
    case text
    case boolean
}

public enum AtlasWeightUnit: String, Codable, CaseIterable, Sendable {
    case lb
    case kg
}

public enum AtlasContextMealTiming: String, Codable, CaseIterable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snack
    case lateNight = "late_night"
}

public enum AtlasContextFedState: String, Codable, CaseIterable, Sendable {
    case fasted
    case fed
    case unsure
}

public enum AtlasContextAppetiteState: String, Codable, CaseIterable, Sendable {
    case low
    case typical
    case high
}

public enum AtlasContextHydrationState: String, Codable, CaseIterable, Sendable {
    case low
    case typical
    case high
}

public enum AtlasContextMealSize: String, Codable, CaseIterable, Sendable {
    case light
    case standard
    case heavy
}

public enum AtlasContextMealComposition: String, Codable, CaseIterable, Sendable {
    case proteinHeavy = "protein_heavy"
    case fiberForward = "fiber_forward"
    case carbHeavy = "carb_heavy"
    case fatHeavy = "fat_heavy"
    case mixed
    case unsure
}

public enum AtlasContextGITag: String, Codable, CaseIterable, Sendable {
    case calm
    case nausea
    case bloating
    case cramping
    case reflux
    case bowelChange = "bowel_change"
}

public enum AtlasHealthDataSource: String, Codable, CaseIterable, Sendable {
    case manual
    case health
    case `import`
}

public enum AtlasWorkoutActivityKind: String, Codable, CaseIterable, Sendable {
    case walk
    case run
    case cycle
    case strength
    case yoga
    case swim
    case hike
    case mobility
    case cardio
    case sport
    case other
}

public extension AtlasWorkoutActivityKind {
    var title: String {
        switch self {
        case .walk:
            return "Walk"
        case .run:
            return "Run"
        case .cycle:
            return "Cycle"
        case .strength:
            return "Strength"
        case .yoga:
            return "Yoga"
        case .swim:
            return "Swim"
        case .hike:
            return "Hike"
        case .mobility:
            return "Mobility"
        case .cardio:
            return "Cardio"
        case .sport:
            return "Sport"
        case .other:
            return "Workout"
        }
    }
}

public extension AtlasProtocolRevisionLifecycle {
    var explanationTitle: String {
        switch self {
        case .active:
            return "Active"
        case .paused:
            return "Paused"
        case .resting:
            return "Resting"
        }
    }
}

public extension AtlasProtocolTimezoneStrategy {
    var explanationTitle: String {
        switch self {
        case .keepLocalClock:
            return "Keep local clock"
        case .keepHomeTimezone:
            return "Keep home timezone"
        }
    }
}

public extension AtlasMissedDosePolicy {
    var explanationTitle: String {
        switch self {
        case .skipAndContinue:
            return "Skip and continue"
        case .takeNowKeepCadence:
            return "Take now and keep cadence"
        case .takeNowShiftFuture:
            return "Take now and shift future doses"
        }
    }
}

public extension AtlasContextMealTiming {
    var title: String {
        switch self {
        case .breakfast:
            return "Breakfast"
        case .lunch:
            return "Lunch"
        case .dinner:
            return "Dinner"
        case .snack:
            return "Snack"
        case .lateNight:
            return "Late-night"
        }
    }
}

public extension AtlasContextFedState {
    var title: String {
        switch self {
        case .fasted:
            return "Fasted"
        case .fed:
            return "Fed"
        case .unsure:
            return "Not sure"
        }
    }
}

public extension AtlasContextAppetiteState {
    var title: String {
        switch self {
        case .low:
            return "Low appetite"
        case .typical:
            return "Typical appetite"
        case .high:
            return "High appetite"
        }
    }
}

public extension AtlasContextHydrationState {
    var title: String {
        switch self {
        case .low:
            return "Low hydration"
        case .typical:
            return "Hydration felt steady"
        case .high:
            return "Hydrated"
        }
    }
}

public extension AtlasContextMealSize {
    var title: String {
        switch self {
        case .light:
            return "Light meal"
        case .standard:
            return "Standard meal"
        case .heavy:
            return "Heavy meal"
        }
    }
}

public extension AtlasContextMealComposition {
    var title: String {
        switch self {
        case .proteinHeavy:
            return "Protein-heavy"
        case .fiberForward:
            return "Fiber-forward"
        case .carbHeavy:
            return "Carb-heavy"
        case .fatHeavy:
            return "Fat-heavy"
        case .mixed:
            return "Mixed meal"
        case .unsure:
            return "Composition unsure"
        }
    }
}

public extension AtlasContextGITag {
    var title: String {
        switch self {
        case .calm:
            return "GI calm"
        case .nausea:
            return "Nausea"
        case .bloating:
            return "Bloating"
        case .cramping:
            return "Cramping"
        case .reflux:
            return "Reflux"
        case .bowelChange:
            return "Bowel change"
        }
    }
}

public extension AtlasProtocolChangeAuditType {
    var explanationTitle: String {
        switch self {
        case .futureDoseChanged:
            return "Future dose changed"
        case .timeChanged:
            return "Future time changed"
        case .cadenceChanged:
            return "Cadence changed"
        case .paused:
            return "Future plan paused"
        case .resumed:
            return "Future plan resumed"
        case .titrationChanged:
            return "Titration updated"
        case .restPeriodChanged:
            return "Rest period updated"
        case .missedDosePolicyChanged:
            return "Missed-dose policy updated"
        case .timezoneChanged:
            return "Timezone handling updated"
        case .vialHandoffPlanned:
            return "Vial handoff planned"
        case .revisionReverted:
            return "Revision reverted"
        }
    }
}

public enum AtlasHealthProviderKey: String, Codable, CaseIterable, Sendable {
    case appleHealth = "apple_health"
    case healthConnect = "health_connect"
}

public enum AtlasOccurrenceState: String, Codable, CaseIterable, Sendable {
    case upcoming
    case due
    case completed
    case missed
    case skipped
    case superseded
}

public struct ProtocolSummary: Identifiable, Hashable, Sendable {
    public var id: String
    public var canonicalTitle: String
    public var aliasTitle: String?
    public var protocolKind: AtlasProtocolKind
    public var kindLabel: String
    public var cadenceLabel: String
    public var doseLabel: String?
    public var nextDueLabel: String?
    public var status: AtlasProtocolStatus
    public var compoundKnowledge: AtlasCompoundKnowledge?

    public init(
        id: String,
        canonicalTitle: String,
        aliasTitle: String?,
        protocolKind: AtlasProtocolKind,
        kindLabel: String,
        cadenceLabel: String,
        doseLabel: String? = nil,
        nextDueLabel: String? = nil,
        status: AtlasProtocolStatus,
        compoundKnowledge: AtlasCompoundKnowledge? = nil
    ) {
        self.id = id
        self.canonicalTitle = canonicalTitle
        self.aliasTitle = aliasTitle
        self.protocolKind = protocolKind
        self.kindLabel = kindLabel
        self.cadenceLabel = cadenceLabel
        self.doseLabel = doseLabel
        self.nextDueLabel = nextDueLabel
        self.status = status
        self.compoundKnowledge = compoundKnowledge
    }
}

public struct ImmutableLogEventSummary: Identifiable, Hashable, Sendable {
    public var id: String
    public var protocolID: String
    public var summary: String
    public var recordedAt: Date

    public init(id: String, protocolID: String, summary: String, recordedAt: Date) {
        self.id = id
        self.protocolID = protocolID
        self.summary = summary
        self.recordedAt = recordedAt
    }
}

public struct FutureOccurrenceSummary: Identifiable, Hashable, Sendable {
    public var id: String
    public var protocolID: String
    public var canonicalTitle: String
    public var aliasTitle: String?
    public var kindLabel: String
    public var dueLabel: String
    public var scheduledAt: Date

    public init(
        id: String,
        protocolID: String,
        canonicalTitle: String,
        aliasTitle: String?,
        kindLabel: String,
        dueLabel: String,
        scheduledAt: Date
    ) {
        self.id = id
        self.protocolID = protocolID
        self.canonicalTitle = canonicalTitle
        self.aliasTitle = aliasTitle
        self.kindLabel = kindLabel
        self.dueLabel = dueLabel
        self.scheduledAt = scheduledAt
    }
}

public struct TrustVaultStatus: Sendable, Equatable {
    public var renderMode: AtlasPrivacyRenderMode
    public var biometricLockEnabled: Bool

    public init(
        renderMode: AtlasPrivacyRenderMode = .full,
        biometricLockEnabled: Bool = false
    ) {
        self.renderMode = renderMode
        self.biometricLockEnabled = biometricLockEnabled
    }
}

public enum AtlasMascotSelection: String, Codable, CaseIterable, Sendable {
    case aetherion
    case aurielle

    public var title: String {
        switch self {
        case .aetherion:
            return "Aetherion"
        case .aurielle:
            return "Aurielle"
        }
    }

    public var subtitle: String {
        switch self {
        case .aetherion:
            return "Storm-forged drake guardian"
        case .aurielle:
            return "Aurora hare guardian"
        }
    }

    public var stage1Title: String {
        switch self {
        case .aetherion:
            return "Cindlet"
        case .aurielle:
            return "Moppet"
        }
    }

    public var stage2Title: String {
        switch self {
        case .aetherion:
            return "Voltflare"
        case .aurielle:
            return "Glisshare"
        }
    }

    public var stage3Title: String {
        switch self {
        case .aetherion:
            return "Aetherion"
        case .aurielle:
            return "Aurielle"
        }
    }

    public func title(for stage: AtlasMascotStage) -> String {
        switch stage {
        case .stage1:
            return stage1Title
        case .stage2:
            return stage2Title
        case .stage3:
            return stage3Title
        }
    }
}

public enum AtlasMascotStage: String, Codable, CaseIterable, Sendable {
    case stage1
    case stage2
    case stage3

    public var rank: Int {
        switch self {
        case .stage1:
            return 1
        case .stage2:
            return 2
        case .stage3:
            return 3
        }
    }
}

public enum AtlasMascotMilestone {
    public static let stage2Points = 500
    public static let stage3Points = 1_250

    public static func stage(for totalPoints: Int) -> AtlasMascotStage {
        switch totalPoints {
        case stage3Points...:
            return .stage3
        case stage2Points...:
            return .stage2
        default:
            return .stage1
        }
    }

    public static func nextThreshold(after stage: AtlasMascotStage) -> Int? {
        switch stage {
        case .stage1:
            return stage2Points
        case .stage2:
            return stage3Points
        case .stage3:
            return nil
        }
    }
}

public struct AtlasMascotUnlockSnapshot: Codable, Equatable, Sendable, Identifiable {
    public var id: AtlasMascotSelection { selection }
    public var selection: AtlasMascotSelection
    public var highestUnlockedStage: AtlasMascotStage

    public init(
        selection: AtlasMascotSelection,
        highestUnlockedStage: AtlasMascotStage = .stage1
    ) {
        self.selection = selection
        self.highestUnlockedStage = highestUnlockedStage
    }
}

public struct AtlasMascotEvolutionRecord: Codable, Equatable, Sendable, Identifiable {
    public var selection: AtlasMascotSelection
    public var stage: AtlasMascotStage
    public var earnedAt: String

    public var id: String { "\(selection.rawValue)-\(stage.rawValue)-\(earnedAt)" }

    public init(
        selection: AtlasMascotSelection,
        stage: AtlasMascotStage,
        earnedAt: String
    ) {
        self.selection = selection
        self.stage = stage
        self.earnedAt = earnedAt
    }
}

public enum AtlasMascotMomentKind: String, Codable, CaseIterable, Sendable {
    case interaction
    case evolution
    case badge
    case goal
    case streak
    case streakRescue = "streak_rescue"
    case nearEvolution = "near_evolution"
    case archiveMilestone = "archive_milestone"
    case focusCarryForward = "focus_carry_forward"
    case quietConsistency = "quiet_consistency"
    case shortcut
    case levelUp = "level_up"
    case weeklyCloseout = "weekly_closeout"
    case recapExport = "recap_export"
}

public enum AtlasMascotRecapAudience: String, Codable, CaseIterable, Sendable {
    case personal
    case coach
    case share

    public var title: String {
        switch self {
        case .personal:
            return "Personal"
        case .coach:
            return "Coach"
        case .share:
            return "Share"
        }
    }
}

public enum AtlasMascotRecapPrivacyMode: String, Codable, CaseIterable, Sendable {
    case fullDetail
    case privacySafe

    public var title: String {
        switch self {
        case .fullDetail:
            return "Full detail"
        case .privacySafe:
            return "Privacy-safe"
        }
    }
}

public struct AtlasMascotRecapNotificationSettings: Codable, Equatable, Sendable {
    public var dailyEnabled: Bool
    public var weeklyEnabled: Bool

    public init(
        dailyEnabled: Bool = false,
        weeklyEnabled: Bool = false
    ) {
        self.dailyEnabled = dailyEnabled
        self.weeklyEnabled = weeklyEnabled
    }
}

public struct AtlasMascotArchivedRecapRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var selection: AtlasMascotSelection
    public var stage: AtlasMascotStage
    public var kind: String
    public var audience: AtlasMascotRecapAudience
    public var privacyMode: AtlasMascotRecapPrivacyMode
    public var displayName: String
    public var currentFormName: String
    public var eyebrow: String
    public var headline: String
    public var detail: String
    public var secondaryDetail: String
    public var footer: String
    public var symbolName: String
    public var fileName: String
    public var createdAt: String
    public var sourceMomentEventKey: String?
    public var sourceMomentTitle: String?

    public init(
        id: String,
        selection: AtlasMascotSelection,
        stage: AtlasMascotStage,
        kind: String,
        audience: AtlasMascotRecapAudience,
        privacyMode: AtlasMascotRecapPrivacyMode,
        displayName: String,
        currentFormName: String,
        eyebrow: String,
        headline: String,
        detail: String,
        secondaryDetail: String,
        footer: String,
        symbolName: String,
        fileName: String,
        createdAt: String,
        sourceMomentEventKey: String? = nil,
        sourceMomentTitle: String? = nil
    ) {
        self.id = id
        self.selection = selection
        self.stage = stage
        self.kind = kind
        self.audience = audience
        self.privacyMode = privacyMode
        self.displayName = displayName
        self.currentFormName = currentFormName
        self.eyebrow = eyebrow
        self.headline = headline
        self.detail = detail
        self.secondaryDetail = secondaryDetail
        self.footer = footer
        self.symbolName = symbolName
        self.fileName = fileName
        self.createdAt = createdAt
        self.sourceMomentEventKey = sourceMomentEventKey
        self.sourceMomentTitle = sourceMomentTitle
    }
}

public struct AtlasMascotMomentRecord: Codable, Equatable, Sendable, Identifiable {
    public var selection: AtlasMascotSelection
    public var stage: AtlasMascotStage
    public var kind: AtlasMascotMomentKind
    public var title: String
    public var detail: String
    public var symbolName: String
    public var recordedAt: String
    public var eventKey: String?
    public var relatedRecapID: String?
    public var relatedRecapKind: String?
    public var recapHeadline: String?

    public var id: String {
        if let eventKey, eventKey.isEmpty == false {
            return "\(selection.rawValue)-\(eventKey)"
        }
        return "\(selection.rawValue)-\(kind.rawValue)-\(recordedAt)-\(title)"
    }

    public init(
        selection: AtlasMascotSelection,
        stage: AtlasMascotStage,
        kind: AtlasMascotMomentKind,
        title: String,
        detail: String,
        symbolName: String,
        recordedAt: String,
        eventKey: String? = nil,
        relatedRecapID: String? = nil,
        relatedRecapKind: String? = nil,
        recapHeadline: String? = nil
    ) {
        self.selection = selection
        self.stage = stage
        self.kind = kind
        self.title = title
        self.detail = detail
        self.symbolName = symbolName
        self.recordedAt = recordedAt
        self.eventKey = eventKey
        self.relatedRecapID = relatedRecapID
        self.relatedRecapKind = relatedRecapKind
        self.recapHeadline = recapHeadline
    }
}

public struct AtlasSettingsSnapshot: Sendable, Equatable {
    public var accountMode: AtlasAccountMode
    public var accountStartMode: AtlasOnboardingAccountMode?
    public var onboardingCompleted: Bool
    public var syncStatus: AtlasSyncScaffoldStatus
    public var healthScaffold: AtlasHealthScaffoldSnapshot
    public var externalCalendarSettings: AtlasExternalCalendarSettingsSnapshot
    public var labsEnabled: Bool
    public var surfacePreferences: AtlasSurfacePreferences
    public var trustVaultStatus: TrustVaultStatus
    public var mascotSelection: AtlasMascotSelection
    public var mascotNickname: String?
    public var mascotSelectionConfirmed: Bool
    public var mascotUnlocks: [AtlasMascotUnlockSnapshot]
    public var mascotEvolutionHistory: [AtlasMascotEvolutionRecord]
    public var mascotMoments: [AtlasMascotMomentRecord]
    public var mascotArchivedRecaps: [AtlasMascotArchivedRecapRecord]
    public var mascotRecapNotificationSettings: AtlasMascotRecapNotificationSettings
    public var weeklyReviewReminderSettings: AtlasWeeklyReviewReminderSettings
    public var weeklyReviewActionPlans: [AtlasWeeklyReviewActionPlan]
    public var summarySettings: AtlasSummarySettingsSnapshot
    public var retentionSettings: AtlasRetentionSettingsSnapshot
    public var rewardsSettings: AtlasRewardsSettingsSnapshot

    public init(
        accountMode: AtlasAccountMode = .guest,
        accountStartMode: AtlasOnboardingAccountMode? = nil,
        onboardingCompleted: Bool = false,
        syncStatus: AtlasSyncScaffoldStatus = .localOnly,
        healthScaffold: AtlasHealthScaffoldSnapshot = .init(),
        externalCalendarSettings: AtlasExternalCalendarSettingsSnapshot = .init(),
        labsEnabled: Bool = false,
        surfacePreferences: AtlasSurfacePreferences = .init(),
        trustVaultStatus: TrustVaultStatus = .init(),
        mascotSelection: AtlasMascotSelection = .aetherion,
        mascotNickname: String? = nil,
        mascotSelectionConfirmed: Bool = false,
        mascotUnlocks: [AtlasMascotUnlockSnapshot] = AtlasMascotSelection.allCases.map {
            AtlasMascotUnlockSnapshot(selection: $0, highestUnlockedStage: .stage1)
        },
        mascotEvolutionHistory: [AtlasMascotEvolutionRecord] = [],
        mascotMoments: [AtlasMascotMomentRecord] = [],
        mascotArchivedRecaps: [AtlasMascotArchivedRecapRecord] = [],
        mascotRecapNotificationSettings: AtlasMascotRecapNotificationSettings = .init(),
        weeklyReviewReminderSettings: AtlasWeeklyReviewReminderSettings = .init(),
        weeklyReviewActionPlans: [AtlasWeeklyReviewActionPlan] = [],
        summarySettings: AtlasSummarySettingsSnapshot = .init(),
        retentionSettings: AtlasRetentionSettingsSnapshot = .init(),
        rewardsSettings: AtlasRewardsSettingsSnapshot = .init()
    ) {
        self.accountMode = accountMode
        self.accountStartMode = accountStartMode
        self.onboardingCompleted = onboardingCompleted
        self.syncStatus = syncStatus
        self.healthScaffold = healthScaffold
        self.externalCalendarSettings = externalCalendarSettings
        self.labsEnabled = labsEnabled
        self.surfacePreferences = surfacePreferences
        self.trustVaultStatus = trustVaultStatus
        self.mascotSelection = mascotSelection
        self.mascotNickname = mascotNickname
        self.mascotSelectionConfirmed = mascotSelectionConfirmed
        self.mascotUnlocks = mascotUnlocks
        self.mascotEvolutionHistory = mascotEvolutionHistory
        self.mascotMoments = mascotMoments
        self.mascotArchivedRecaps = mascotArchivedRecaps
        self.mascotRecapNotificationSettings = mascotRecapNotificationSettings
        self.weeklyReviewReminderSettings = weeklyReviewReminderSettings
        self.weeklyReviewActionPlans = weeklyReviewActionPlans
        self.summarySettings = summarySettings
        self.retentionSettings = retentionSettings
        self.rewardsSettings = rewardsSettings
    }

    public func highestUnlockedStage(for selection: AtlasMascotSelection) -> AtlasMascotStage {
        mascotUnlocks.first(where: { $0.selection == selection })?.highestUnlockedStage ?? .stage1
    }
}

public enum AtlasTodayLandingCard: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case guidance
    case recovery
    case quickCapture = "quick_capture"
    case quickContext = "quick_context"
    case weeklyFocus = "weekly_focus"
    case watchCompanion = "watch_companion"
    case mascot
    case rewards
    case calmContinuity = "calm_continuity"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .guidance: "Today lens"
        case .recovery: "Recovery"
        case .quickCapture: "Quick capture"
        case .quickContext: "Quick context"
        case .weeklyFocus: "Weekly focus"
        case .watchCompanion: "Watch companion"
        case .mascot: "Mascot"
        case .rewards: "Rewards"
        case .calmContinuity: "Calm continuity"
        }
    }
}

public enum AtlasInsightsLandingCard: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case progressEvidence = "progress_evidence"
    case weeklyReview = "weekly_review"
    case stackDashboard = "stack_dashboard"
    case biometricsOverlay = "biometrics_overlay"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .progressEvidence: "Progress evidence"
        case .weeklyReview: "Weekly review"
        case .stackDashboard: "Stack dashboard"
        case .biometricsOverlay: "Biometrics overlays"
        }
    }
}

public struct AtlasSurfacePreferences: Codable, Equatable, Sendable {
    public var todayCardOrder: [AtlasTodayLandingCard]
    public var hiddenTodayCards: [AtlasTodayLandingCard]
    public var insightsCardOrder: [AtlasInsightsLandingCard]
    public var hiddenInsightsCards: [AtlasInsightsLandingCard]
    public var stackDashboardEnabled: Bool
    public var biometricsOverlayEnabled: Bool
    public var biometricsOverlayShowsProtocolChanges: Bool

    public init(
        todayCardOrder: [AtlasTodayLandingCard] = AtlasTodayLandingCard.allCases,
        hiddenTodayCards: [AtlasTodayLandingCard] = [],
        insightsCardOrder: [AtlasInsightsLandingCard] = AtlasInsightsLandingCard.allCases,
        hiddenInsightsCards: [AtlasInsightsLandingCard] = [],
        stackDashboardEnabled: Bool = false,
        biometricsOverlayEnabled: Bool = true,
        biometricsOverlayShowsProtocolChanges: Bool = true
    ) {
        self.todayCardOrder = todayCardOrder
        self.hiddenTodayCards = hiddenTodayCards
        self.insightsCardOrder = insightsCardOrder
        self.hiddenInsightsCards = hiddenInsightsCards
        self.stackDashboardEnabled = stackDashboardEnabled
        self.biometricsOverlayEnabled = biometricsOverlayEnabled
        self.biometricsOverlayShowsProtocolChanges = biometricsOverlayShowsProtocolChanges
    }

    public var visibleTodayCards: [AtlasTodayLandingCard] {
        AtlasTodayLandingCard.allCases.filter { hiddenTodayCards.contains($0) == false }
            .sorted { todayCardRank($0) < todayCardRank($1) }
    }

    public var visibleInsightsCards: [AtlasInsightsLandingCard] {
        AtlasInsightsLandingCard.allCases.filter { hiddenInsightsCards.contains($0) == false }
            .sorted { insightsCardRank($0) < insightsCardRank($1) }
    }

    public func isTodayCardVisible(_ card: AtlasTodayLandingCard) -> Bool {
        hiddenTodayCards.contains(card) == false
    }

    public func isInsightsCardVisible(_ card: AtlasInsightsLandingCard) -> Bool {
        hiddenInsightsCards.contains(card) == false
    }

    private func todayCardRank(_ card: AtlasTodayLandingCard) -> Int {
        todayCardOrder.firstIndex(of: card) ?? AtlasTodayLandingCard.allCases.count
    }

    private func insightsCardRank(_ card: AtlasInsightsLandingCard) -> Int {
        insightsCardOrder.firstIndex(of: card) ?? AtlasInsightsLandingCard.allCases.count
    }
}

public struct AtlasSharedNextDueSnapshot: Codable, Equatable, Sendable {
    public var occurrenceID: String
    public var protocolID: String
    public var displayTitle: String
    public var dueLabel: String
    public var scheduledAt: String
    public var state: AtlasOccurrenceDisplayState
    public var statusSummary: String
    public var overdueCount: Int

    public init(
        occurrenceID: String,
        protocolID: String,
        displayTitle: String,
        dueLabel: String,
        scheduledAt: String,
        state: AtlasOccurrenceDisplayState,
        statusSummary: String,
        overdueCount: Int = 0
    ) {
        self.occurrenceID = occurrenceID
        self.protocolID = protocolID
        self.displayTitle = displayTitle
        self.dueLabel = dueLabel
        self.scheduledAt = scheduledAt
        self.state = state
        self.statusSummary = statusSummary
        self.overdueCount = overdueCount
    }
}

public struct AtlasSharedTimelineSummary: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var protocolID: String
    public var displayTitle: String
    public var summary: String
    public var recordedAt: String

    public init(
        id: String,
        protocolID: String,
        displayTitle: String,
        summary: String,
        recordedAt: String
    ) {
        self.id = id
        self.protocolID = protocolID
        self.displayTitle = displayTitle
        self.summary = summary
        self.recordedAt = recordedAt
    }
}

public struct AtlasSharedLabelProjection: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var canonicalTitle: String
    public var aliasTitle: String?
    public var discreetTitle: String

    public init(
        id: String,
        canonicalTitle: String,
        aliasTitle: String?,
        discreetTitle: String
    ) {
        self.id = id
        self.canonicalTitle = canonicalTitle
        self.aliasTitle = aliasTitle
        self.discreetTitle = discreetTitle
    }
}

public struct AtlasSharedQuickAction: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var protocolID: String
    public var occurrenceID: String
    public var title: String
    public var dueLabel: String
    public var state: AtlasOccurrenceDisplayState

    public init(
        id: String,
        protocolID: String,
        occurrenceID: String,
        title: String,
        dueLabel: String,
        state: AtlasOccurrenceDisplayState
    ) {
        self.id = id
        self.protocolID = protocolID
        self.occurrenceID = occurrenceID
        self.title = title
        self.dueLabel = dueLabel
        self.state = state
    }
}

public enum AtlasSharedInventoryItemKind: String, Codable, Equatable, Sendable {
    case vial
    case consumable
}

public struct AtlasSharedLowStockItem: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var kind: AtlasSharedInventoryItemKind
    public var displayTitle: String
    public var detail: String

    public init(
        id: String,
        kind: AtlasSharedInventoryItemKind,
        displayTitle: String,
        detail: String
    ) {
        self.id = id
        self.kind = kind
        self.displayTitle = displayTitle
        self.detail = detail
    }
}

public struct AtlasSharedLowStockSnapshot: Codable, Equatable, Sendable {
    public var lowStockCount: Int
    public var procurementReviewCount: Int
    public var summary: String
    public var items: [AtlasSharedLowStockItem]
    public var updatedAt: String

    public init(
        lowStockCount: Int,
        procurementReviewCount: Int = 0,
        summary: String,
        items: [AtlasSharedLowStockItem],
        updatedAt: String
    ) {
        self.lowStockCount = lowStockCount
        self.procurementReviewCount = procurementReviewCount
        self.summary = summary
        self.items = items
        self.updatedAt = updatedAt
    }
}

public struct AtlasSharedFeatureFlagProjection: Codable, Equatable, Sendable {
    public var flags: AtlasFeatureFlagState

    public init(flags: AtlasFeatureFlagState) {
        self.flags = flags
    }
}

public enum AtlasSharedMascotPose: String, Codable, Equatable, Sendable {
    case idle
    case happy
    case recovery
    case evolutionReady
    case milestone
    case rest
}

public struct AtlasSharedMascotSnapshot: Codable, Equatable, Sendable {
    public var selection: AtlasMascotSelection
    public var nickname: String?
    public var displayName: String
    public var stage: AtlasMascotStage
    public var pose: AtlasSharedMascotPose
    public var currentFormName: String
    public var nextFormName: String?
    public var nextThresholdPoints: Int?
    public var totalPoints: Int
    public var milestoneHeadline: String
    public var progressLabel: String
    public var statusLine: String
    public var reactionTitle: String?
    public var reactionSymbolName: String?
    public var lastEvolution: AtlasMascotEvolutionRecord?
    public var latestMomentTitle: String?
    public var latestMomentDetail: String?
    public var latestMomentSymbolName: String?
    public var latestMomentRecordedAt: String?

    public init(
        selection: AtlasMascotSelection,
        nickname: String? = nil,
        displayName: String,
        stage: AtlasMascotStage,
        pose: AtlasSharedMascotPose,
        currentFormName: String,
        nextFormName: String?,
        nextThresholdPoints: Int?,
        totalPoints: Int,
        milestoneHeadline: String,
        progressLabel: String,
        statusLine: String,
        reactionTitle: String? = nil,
        reactionSymbolName: String? = nil,
        lastEvolution: AtlasMascotEvolutionRecord? = nil,
        latestMomentTitle: String? = nil,
        latestMomentDetail: String? = nil,
        latestMomentSymbolName: String? = nil,
        latestMomentRecordedAt: String? = nil
    ) {
        self.selection = selection
        self.nickname = nickname
        self.displayName = displayName
        self.stage = stage
        self.pose = pose
        self.currentFormName = currentFormName
        self.nextFormName = nextFormName
        self.nextThresholdPoints = nextThresholdPoints
        self.totalPoints = totalPoints
        self.milestoneHeadline = milestoneHeadline
        self.progressLabel = progressLabel
        self.statusLine = statusLine
        self.reactionTitle = reactionTitle
        self.reactionSymbolName = reactionSymbolName
        self.lastEvolution = lastEvolution
        self.latestMomentTitle = latestMomentTitle
        self.latestMomentDetail = latestMomentDetail
        self.latestMomentSymbolName = latestMomentSymbolName
        self.latestMomentRecordedAt = latestMomentRecordedAt
    }
}

public struct AtlasSharedExtensionProjectionSnapshot: Codable, Equatable, Sendable {
    public var generatedAt: String
    public var renderMode: AtlasPrivacyRenderMode
    public var nextDue: AtlasSharedNextDueSnapshot?
    public var quickActions: [AtlasSharedQuickAction]
    public var lowStock: AtlasSharedLowStockSnapshot
    public var mascot: AtlasSharedMascotSnapshot?
    public var watchCompanion: AtlasSharedWatchCompanionSnapshot?
    public var featureFlags: AtlasSharedFeatureFlagProjection

    public init(
        generatedAt: String,
        renderMode: AtlasPrivacyRenderMode,
        nextDue: AtlasSharedNextDueSnapshot?,
        quickActions: [AtlasSharedQuickAction],
        lowStock: AtlasSharedLowStockSnapshot,
        mascot: AtlasSharedMascotSnapshot? = nil,
        watchCompanion: AtlasSharedWatchCompanionSnapshot? = nil,
        featureFlags: AtlasSharedFeatureFlagProjection
    ) {
        self.generatedAt = generatedAt
        self.renderMode = renderMode
        self.nextDue = nextDue
        self.quickActions = quickActions
        self.lowStock = lowStock
        self.mascot = mascot
        self.watchCompanion = watchCompanion
        self.featureFlags = featureFlags
    }
}

public struct AtlasProjectionDebugState: Equatable, Sendable {
    public var nextDue: AtlasSharedNextDueSnapshot?
    public var timeline: [AtlasSharedTimelineSummary]
    public var labels: [AtlasSharedLabelProjection]
    public var quickActions: [AtlasSharedQuickAction]
    public var featureFlags: AtlasSharedFeatureFlagProjection
    public var extensionSnapshot: AtlasSharedExtensionProjectionSnapshot?

    public init(
        nextDue: AtlasSharedNextDueSnapshot?,
        timeline: [AtlasSharedTimelineSummary],
        labels: [AtlasSharedLabelProjection],
        quickActions: [AtlasSharedQuickAction],
        featureFlags: AtlasSharedFeatureFlagProjection,
        extensionSnapshot: AtlasSharedExtensionProjectionSnapshot? = nil
    ) {
        self.nextDue = nextDue
        self.timeline = timeline
        self.labels = labels
        self.quickActions = quickActions
        self.featureFlags = featureFlags
        self.extensionSnapshot = extensionSnapshot
    }
}

public struct AtlasExportManifest: Codable, Equatable, Sendable {
    public var format: String
    public var version: Int
    public var generatedAt: String
    public var source: String

    public init(
        format: String = "atlas_export",
        version: Int = 1,
        generatedAt: String,
        source: String = "atlas-ios-native"
    ) {
        self.format = format
        self.version = version
        self.generatedAt = generatedAt
        self.source = source
    }
}

public struct AtlasCalculatorProfileRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var label: String
    public var powderAmount: Double
    public var powderUnit: String
    public var diluentVolume: Double
    public var diluentUnit: String
    public var drawVolume: Double
    public var drawUnit: String
    public var createdAt: String
    public var updatedAt: String
}

public struct AtlasCompoundRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var slug: String
    public var displayName: String
    public var compoundType: String
    public var isUserDefined: Bool
    public var notes: String?
    public var createdAt: String
    public var updatedAt: String
}

public struct AtlasCustomMetricRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var protocolId: String?
    public var metricKey: String
    public var label: String
    public var valueType: AtlasCustomMetricValueType
    public var unit: String?
    public var scaleMin: Int?
    public var scaleMax: Int?
    public var createdAt: String
    public var updatedAt: String
    public var archivedAt: String?
}

public struct AtlasHealthConnectionRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String { providerKey.rawValue }
    public var providerKey: AtlasHealthProviderKey
    public var enabled: Bool
    public var connected: Bool
    public var lastSyncAt: String?
    public var lastError: String?
    public var createdAt: String
    public var updatedAt: String
}

public struct AtlasLogEventRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var protocolId: String
    public var vialId: String?
    public var siteId: String?
    public var occurrenceId: String?
    public var eventType: AtlasLogEventType
    public var effectiveAt: String
    public var loggedAt: String
    public var quantity: Double?
    public var quantityUnit: String?
    public var notes: String?
    public var source: AtlasLogEventSource
}

public struct AtlasMetricValueLogRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var metricId: String
    public var protocolId: String?
    public var loggedAt: String
    public var numberValue: Double?
    public var textValue: String?
    public var booleanValue: Bool?
    public var source: AtlasHealthDataSource
    public var createdAt: String
    public var updatedAt: String
}

public struct AtlasWorkoutLogRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var activityKind: AtlasWorkoutActivityKind
    public var startedAt: String
    public var endedAt: String
    public var durationMinutes: Double
    public var energyBurnedKilocalories: Double?
    public var distanceMeters: Double?
    public var source: AtlasHealthDataSource
    public var externalSourceId: String?
    public var createdAt: String
    public var updatedAt: String
}

public struct AtlasPrivacyProfileRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var renderMode: AtlasPrivacyRenderMode?
    public var aliasModeEnabled: Bool
    public var biometricLockEnabled: Bool
    public var biometricGateMode: AtlasBiometricGateMode
    public var shareAliasByDefault: Bool
    public var exportAliasByDefault: Bool
    public var createdAt: String
    public var updatedAt: String

    public static func `default`(timestamp: String = ISO8601DateFormatter.atlas.string(from: Date())) -> AtlasPrivacyProfileRecord {
        AtlasPrivacyProfileRecord(
            id: "default",
            renderMode: .full,
            aliasModeEnabled: false,
            biometricLockEnabled: false,
            biometricGateMode: .bestEffort,
            shareAliasByDefault: true,
            exportAliasByDefault: true,
            createdAt: timestamp,
            updatedAt: timestamp
        )
    }
}

public struct AtlasProtocolRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var compoundId: String?
    public var linkedVialId: String?
    public var name: String
    public var kind: AtlasProtocolKind
    public var administrationRoute: AtlasProtocolAdministrationRoute?
    public var supplyType: AtlasProtocolSupplyType?
    public var dosesPerSupply: Int?
    public var status: AtlasProtocolStatus
    public var timezone: String
    public var startDate: String
    public var defaultTimeOfDay: String?
    public var doseAmount: Double?
    public var doseUnit: String?
    public var siteTrackingEnabled: Bool
    public var siteRotationEnabled: Bool
    public var notes: String?
    public var createdAt: String
    public var updatedAt: String
}

public struct AtlasProtocolAliasRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var protocolId: String
    public var aliasLabel: String
    public var aliasCompoundLabel: String?
    public var createdAt: String
    public var updatedAt: String
    public var archivedAt: String?
}

public struct AtlasProtocolRuleRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var protocolId: String
    public var ruleType: AtlasProtocolRuleType
    public var intervalCount: Int
    public var weekday: Int?
    public var timeOfDay: String?
    public var anchorDate: String?
    public var isActive: Bool
    public var createdAt: String
    public var updatedAt: String
}

public struct AtlasProtocolRevisionRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var protocolId: String
    public var revisionNumber: Int
    public var previousRevisionId: String?
    public var effectiveFrom: String
    public var effectiveTo: String?
    public var lifecycleState: AtlasProtocolRevisionLifecycle
    public var timezone: String
    public var timezoneStrategy: AtlasProtocolTimezoneStrategy
    public var administrationRoute: AtlasProtocolAdministrationRoute?
    public var supplyType: AtlasProtocolSupplyType?
    public var dosesPerSupply: Int?
    public var defaultTimeOfDay: String?
    public var doseAmount: Double?
    public var doseUnit: String?
    public var linkedVialId: String?
    public var missedDosePolicy: AtlasMissedDosePolicy
    public var notes: String?
    public var createdAt: String
    public var updatedAt: String

    public init(
        id: String,
        protocolId: String,
        revisionNumber: Int,
        previousRevisionId: String?,
        effectiveFrom: String,
        effectiveTo: String?,
        lifecycleState: AtlasProtocolRevisionLifecycle,
        timezone: String,
        timezoneStrategy: AtlasProtocolTimezoneStrategy,
        administrationRoute: AtlasProtocolAdministrationRoute? = nil,
        supplyType: AtlasProtocolSupplyType? = nil,
        dosesPerSupply: Int? = nil,
        defaultTimeOfDay: String?,
        doseAmount: Double?,
        doseUnit: String?,
        linkedVialId: String?,
        missedDosePolicy: AtlasMissedDosePolicy,
        notes: String?,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.protocolId = protocolId
        self.revisionNumber = revisionNumber
        self.previousRevisionId = previousRevisionId
        self.effectiveFrom = effectiveFrom
        self.effectiveTo = effectiveTo
        self.lifecycleState = lifecycleState
        self.timezone = timezone
        self.timezoneStrategy = timezoneStrategy
        self.administrationRoute = administrationRoute
        self.supplyType = supplyType
        self.dosesPerSupply = dosesPerSupply
        self.defaultTimeOfDay = defaultTimeOfDay
        self.doseAmount = doseAmount
        self.doseUnit = doseUnit
        self.linkedVialId = linkedVialId
        self.missedDosePolicy = missedDosePolicy
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct AtlasProtocolRevisionRuleRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var revisionId: String
    public var phaseType: AtlasProtocolRevisionPhaseType
    public var phaseOrder: Int
    public var ruleType: AtlasProtocolRuleType
    public var intervalCount: Int
    public var weekday: Int?
    public var timeOfDay: String?
    public var anchorDate: String?
    public var phaseStartDayOffset: Int
    public var phaseLengthDays: Int?
    public var doseAmountOverride: Double?
    public var doseUnitOverride: String?
    public var createdAt: String
    public var updatedAt: String

    public init(
        id: String,
        revisionId: String,
        phaseType: AtlasProtocolRevisionPhaseType,
        phaseOrder: Int,
        ruleType: AtlasProtocolRuleType,
        intervalCount: Int,
        weekday: Int?,
        timeOfDay: String?,
        anchorDate: String?,
        phaseStartDayOffset: Int,
        phaseLengthDays: Int?,
        doseAmountOverride: Double?,
        doseUnitOverride: String?,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.revisionId = revisionId
        self.phaseType = phaseType
        self.phaseOrder = phaseOrder
        self.ruleType = ruleType
        self.intervalCount = intervalCount
        self.weekday = weekday
        self.timeOfDay = timeOfDay
        self.anchorDate = anchorDate
        self.phaseStartDayOffset = phaseStartDayOffset
        self.phaseLengthDays = phaseLengthDays
        self.doseAmountOverride = doseAmountOverride
        self.doseUnitOverride = doseUnitOverride
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct AtlasProtocolChangeAuditRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var protocolId: String
    public var revisionId: String
    public var previousRevisionId: String?
    public var changeType: AtlasProtocolChangeAuditType
    public var effectiveFrom: String
    public var summary: String
    public var payloadJson: String
    public var createdAt: String
}

public struct AtlasReminderRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var protocolId: String
    public var occurrenceId: String
    public var offsetMinutes: Int
    public var channel: AtlasReminderChannel
    public var isEnabled: Bool
    public var discreetCopyEnabled: Bool
    public var privacyMode: AtlasReminderPrivacyMode
    public var scheduledFor: String
    public var notificationId: String?
    public var title: String
    public var body: String
    public var status: AtlasReminderStatus
    public var createdAt: String
    public var updatedAt: String
}

public struct AtlasReminderPreferenceRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var remindersEnabled: Bool
    public var privacyMode: AtlasReminderPrivacyMode
    public var leadTimeMinutes: Int
    public var createdAt: String
    public var updatedAt: String

    public static func `default`(timestamp: String = ISO8601DateFormatter.atlas.string(from: Date())) -> AtlasReminderPreferenceRecord {
        AtlasReminderPreferenceRecord(
            id: "default",
            remindersEnabled: true,
            privacyMode: .fullDetail,
            leadTimeMinutes: 0,
            createdAt: timestamp,
            updatedAt: timestamp
        )
    }
}

public struct AtlasSensitiveActionAuditRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var eventType: AtlasSensitiveActionAuditEventType
    public var surface: String
    public var protocolId: String?
    public var scopeKind: String?
    public var renderMode: AtlasPrivacyRenderMode?
    public var manifestVersion: Int?
    public var payloadJson: String
    public var createdAt: String
}

public struct AtlasSiteRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var bodyArea: String?
    public var mapRegionKey: AtlasBodyMapRegionKey?
    public var notes: String?
    public var createdAt: String
    public var updatedAt: String
    public var archivedAt: String?
}

public struct AtlasConsumableRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var protocolId: String?
    public var name: String
    public var category: String?
    public var quantityOnHand: Double
    public var unit: String
    public var reorderThreshold: Double?
    public var reorderLeadTimeDays: Int?
    public var quantityPerUse: Double?
    public var lotNumber: String?
    public var sizeDescription: String?
    public var notes: String?
    public var vendorLabel: String?
    public var purchaseNotes: String?
    public var createdAt: String
    public var updatedAt: String
    public var archivedAt: String?
}

public struct AtlasConsumableAdjustmentRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var consumableId: String
    public var protocolId: String?
    public var occurrenceId: String?
    public var kind: AtlasConsumableAdjustmentKind
    public var deltaQuantity: Double
    public var resultingQuantity: Double
    public var quantityUnit: String
    public var note: String?
    public var vendorLabel: String?
    public var sourceDetail: String?
    public var recordedAt: String
    public var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case consumableId
        case protocolId
        case occurrenceId
        case kind
        case deltaQuantity
        case resultingQuantity
        case quantityUnit
        case note
        case vendorLabel
        case sourceDetail
        case recordedAt
        case createdAt
    }

    public init(
        id: String,
        consumableId: String,
        protocolId: String?,
        occurrenceId: String?,
        kind: AtlasConsumableAdjustmentKind,
        deltaQuantity: Double,
        resultingQuantity: Double,
        quantityUnit: String,
        note: String?,
        vendorLabel: String?,
        sourceDetail: String?,
        recordedAt: String,
        createdAt: String
    ) {
        self.id = id
        self.consumableId = consumableId
        self.protocolId = protocolId
        self.occurrenceId = occurrenceId
        self.kind = kind
        self.deltaQuantity = deltaQuantity
        self.resultingQuantity = resultingQuantity
        self.quantityUnit = quantityUnit
        self.note = note
        self.vendorLabel = vendorLabel
        self.sourceDetail = sourceDetail
        self.recordedAt = recordedAt
        self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            consumableId: try container.decode(String.self, forKey: .consumableId),
            protocolId: try container.decodeIfPresent(String.self, forKey: .protocolId),
            occurrenceId: try container.decodeIfPresent(String.self, forKey: .occurrenceId),
            kind: try container.decode(AtlasConsumableAdjustmentKind.self, forKey: .kind),
            deltaQuantity: try container.decode(Double.self, forKey: .deltaQuantity),
            resultingQuantity: try container.decode(Double.self, forKey: .resultingQuantity),
            quantityUnit: try container.decode(String.self, forKey: .quantityUnit),
            note: try container.decodeIfPresent(String.self, forKey: .note),
            vendorLabel: try container.decodeIfPresent(String.self, forKey: .vendorLabel),
            sourceDetail: try container.decodeIfPresent(String.self, forKey: .sourceDetail),
            recordedAt: try container.decode(String.self, forKey: .recordedAt),
            createdAt: try container.decode(String.self, forKey: .createdAt)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(consumableId, forKey: .consumableId)
        try container.encodeIfPresent(protocolId, forKey: .protocolId)
        try container.encodeIfPresent(occurrenceId, forKey: .occurrenceId)
        try container.encode(kind, forKey: .kind)
        try container.encode(deltaQuantity, forKey: .deltaQuantity)
        try container.encode(resultingQuantity, forKey: .resultingQuantity)
        try container.encode(quantityUnit, forKey: .quantityUnit)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encodeIfPresent(vendorLabel, forKey: .vendorLabel)
        try container.encodeIfPresent(sourceDetail, forKey: .sourceDetail)
        try container.encode(recordedAt, forKey: .recordedAt)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

public struct AtlasContextLogRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var protocolId: String?
    public var loggedAt: String
    public var mealTiming: AtlasContextMealTiming?
    public var mealSize: AtlasContextMealSize?
    public var mealComposition: AtlasContextMealComposition?
    public var fedState: AtlasContextFedState?
    public var appetite: AtlasContextAppetiteState?
    public var hydration: AtlasContextHydrationState?
    public var giTags: [AtlasContextGITag]
    public var note: String?
    public var tags: [String]
    public var presetKey: String?
    public var source: AtlasHealthDataSource
    public var createdAt: String
    public var updatedAt: String
}

public struct AtlasContextPresetRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var title: String
    public var mealTiming: AtlasContextMealTiming?
    public var mealSize: AtlasContextMealSize?
    public var mealComposition: AtlasContextMealComposition?
    public var fedState: AtlasContextFedState?
    public var appetite: AtlasContextAppetiteState?
    public var hydration: AtlasContextHydrationState?
    public var giTags: [AtlasContextGITag]
    public var createdAt: String
    public var updatedAt: String
    public var lastUsedAt: String?
}

public struct AtlasSymptomLogRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var loggedAt: String
    public var symptomKey: String
    public var severity: Int
    public var notes: String?
    public var source: AtlasHealthDataSource
    public var createdAt: String
    public var updatedAt: String
}

public struct AtlasVialRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var protocolId: String?
    public var compoundId: String?
    public var calculatorProfileId: String?
    public var label: String
    public var startingQuantity: Double
    public var concentrationValue: Double?
    public var concentrationUnit: String?
    public var volumeMl: Double?
    public var remainingQuantity: Double
    public var lowStockThreshold: Double?
    public var quantityUnit: String
    public var openedAt: String?
    public var expiresAt: String?
    public var referencePhotoRelativePath: String?
    public var labelScanText: String?
    public var createdAt: String
    public var updatedAt: String
    public var archivedAt: String?
}

public struct AtlasWeightLogRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var loggedAt: String
    public var value: Double
    public var unit: AtlasWeightUnit
    public var source: AtlasHealthDataSource
    public var notes: String?
    public var createdAt: String
    public var updatedAt: String
}

public struct AtlasHealthWeightSample: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var recordedAt: Date
    public var value: Double
    public var unit: AtlasWeightUnit

    public init(
        id: String,
        recordedAt: Date,
        value: Double,
        unit: AtlasWeightUnit
    ) {
        self.id = id
        self.recordedAt = recordedAt
        self.value = value
        self.unit = unit
    }
}

public struct AtlasHealthWorkoutSample: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var activityKind: AtlasWorkoutActivityKind
    public var startedAt: Date
    public var endedAt: Date
    public var durationMinutes: Double
    public var energyBurnedKilocalories: Double?
    public var distanceMeters: Double?

    public init(
        id: String,
        activityKind: AtlasWorkoutActivityKind,
        startedAt: Date,
        endedAt: Date,
        durationMinutes: Double,
        energyBurnedKilocalories: Double? = nil,
        distanceMeters: Double? = nil
    ) {
        self.id = id
        self.activityKind = activityKind
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationMinutes = durationMinutes
        self.energyBurnedKilocalories = energyBurnedKilocalories
        self.distanceMeters = distanceMeters
    }
}

public enum AtlasHealthMetricKind: String, Codable, CaseIterable, Equatable, Sendable, Identifiable {
    case steps
    case sleepHours
    case restingHeartRate
    case heartRateVariability
    case bloodPressureSystolic
    case bloodPressureDiastolic
    case bodyFatPercentage

    public var id: String { rawValue }

    public var metricKey: String {
        switch self {
        case .steps: "health_steps"
        case .sleepHours: "health_sleep"
        case .restingHeartRate: "health_resting_heart_rate"
        case .heartRateVariability: "health_hrv"
        case .bloodPressureSystolic: "health_blood_pressure_systolic"
        case .bloodPressureDiastolic: "health_blood_pressure_diastolic"
        case .bodyFatPercentage: "health_body_fat"
        }
    }

    public var label: String {
        switch self {
        case .steps: "Steps"
        case .sleepHours: "Sleep"
        case .restingHeartRate: "Resting heart rate"
        case .heartRateVariability: "HRV"
        case .bloodPressureSystolic: "Blood pressure systolic"
        case .bloodPressureDiastolic: "Blood pressure diastolic"
        case .bodyFatPercentage: "Body fat"
        }
    }

    public var unit: String {
        switch self {
        case .steps: "steps"
        case .sleepHours: "hr"
        case .restingHeartRate: "bpm"
        case .heartRateVariability: "ms"
        case .bloodPressureSystolic, .bloodPressureDiastolic: "mmHg"
        case .bodyFatPercentage: "%"
        }
    }

    public var aggregateSignalKind: AtlasHealthSignalKind {
        switch self {
        case .steps: .steps
        case .sleepHours: .sleep
        case .restingHeartRate: .restingHeartRate
        case .heartRateVariability: .heartRateVariability
        case .bloodPressureSystolic, .bloodPressureDiastolic: .bloodPressure
        case .bodyFatPercentage: .bodyFat
        }
    }
}

public struct AtlasHealthMetricSample: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var kind: AtlasHealthMetricKind
    public var recordedAt: Date
    public var value: Double

    public init(
        id: String,
        kind: AtlasHealthMetricKind,
        recordedAt: Date,
        value: Double
    ) {
        self.id = id
        self.kind = kind
        self.recordedAt = recordedAt
        self.value = value
    }
}

public enum AtlasHealthNutritionMetricKind: String, Codable, CaseIterable, Equatable, Sendable, Identifiable {
    case water
    case calories
    case protein

    public var id: String { rawValue }

    public var metricKey: String {
        switch self {
        case .water: "health_dietary_water"
        case .calories: "health_dietary_energy"
        case .protein: "health_dietary_protein"
        }
    }

    public var label: String {
        switch self {
        case .water: "Water"
        case .calories: "Calories"
        case .protein: "Protein"
        }
    }

    public var unit: String {
        switch self {
        case .water: "fl oz"
        case .calories: "kcal"
        case .protein: "g"
        }
    }
}

public struct AtlasHealthNutritionSample: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var kind: AtlasHealthNutritionMetricKind
    public var recordedAt: Date
    public var value: Double

    public init(
        id: String,
        kind: AtlasHealthNutritionMetricKind,
        recordedAt: Date,
        value: Double
    ) {
        self.id = id
        self.kind = kind
        self.recordedAt = recordedAt
        self.value = value
    }
}

public struct AtlasOccurrenceProjectionRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var protocolId: String
    public var reminderId: String?
    public var scheduledAt: String
    public var state: AtlasOccurrenceState
    public var createdAt: String
    public var updatedAt: String
}

public extension AtlasCalculatorProfileRecord {
    static func make(id: String, label: String, powderAmount: Double, powderUnit: String, diluentVolume: Double, diluentUnit: String, drawVolume: Double, drawUnit: String, createdAt: String, updatedAt: String) -> Self {
        .init(id: id, label: label, powderAmount: powderAmount, powderUnit: powderUnit, diluentVolume: diluentVolume, diluentUnit: diluentUnit, drawVolume: drawVolume, drawUnit: drawUnit, createdAt: createdAt, updatedAt: updatedAt)
    }
}

public extension AtlasCompoundRecord {
    static func make(id: String, slug: String, displayName: String, compoundType: String, isUserDefined: Bool, notes: String?, createdAt: String, updatedAt: String) -> Self {
        .init(id: id, slug: slug, displayName: displayName, compoundType: compoundType, isUserDefined: isUserDefined, notes: notes, createdAt: createdAt, updatedAt: updatedAt)
    }
}

public extension AtlasCustomMetricRecord {
    static func make(
        id: String,
        protocolId: String?,
        metricKey: String,
        label: String,
        valueType: AtlasCustomMetricValueType,
        unit: String?,
        scaleMin: Int? = nil,
        scaleMax: Int? = nil,
        createdAt: String,
        updatedAt: String,
        archivedAt: String? = nil
    ) -> Self {
        .init(
            id: id,
            protocolId: protocolId,
            metricKey: metricKey,
            label: label,
            valueType: valueType,
            unit: unit,
            scaleMin: scaleMin,
            scaleMax: scaleMax,
            createdAt: createdAt,
            updatedAt: updatedAt,
            archivedAt: archivedAt
        )
    }
}

public extension AtlasHealthConnectionRecord {
    static func make(providerKey: AtlasHealthProviderKey, enabled: Bool, connected: Bool, lastSyncAt: String?, lastError: String?, createdAt: String, updatedAt: String) -> Self {
        .init(providerKey: providerKey, enabled: enabled, connected: connected, lastSyncAt: lastSyncAt, lastError: lastError, createdAt: createdAt, updatedAt: updatedAt)
    }
}

public extension AtlasLogEventRecord {
    static func make(id: String, protocolId: String, vialId: String?, siteId: String?, occurrenceId: String?, eventType: AtlasLogEventType, effectiveAt: String, loggedAt: String, quantity: Double?, quantityUnit: String?, notes: String?, source: AtlasLogEventSource) -> Self {
        .init(id: id, protocolId: protocolId, vialId: vialId, siteId: siteId, occurrenceId: occurrenceId, eventType: eventType, effectiveAt: effectiveAt, loggedAt: loggedAt, quantity: quantity, quantityUnit: quantityUnit, notes: notes, source: source)
    }
}

public extension AtlasMetricValueLogRecord {
    static func make(id: String, metricId: String, protocolId: String?, loggedAt: String, numberValue: Double?, textValue: String?, booleanValue: Bool?, source: AtlasHealthDataSource, createdAt: String, updatedAt: String) -> Self {
        .init(id: id, metricId: metricId, protocolId: protocolId, loggedAt: loggedAt, numberValue: numberValue, textValue: textValue, booleanValue: booleanValue, source: source, createdAt: createdAt, updatedAt: updatedAt)
    }
}

public extension AtlasWorkoutLogRecord {
    static func make(
        id: String,
        activityKind: AtlasWorkoutActivityKind,
        startedAt: String,
        endedAt: String,
        durationMinutes: Double,
        energyBurnedKilocalories: Double?,
        distanceMeters: Double?,
        source: AtlasHealthDataSource,
        externalSourceId: String?,
        createdAt: String,
        updatedAt: String
    ) -> Self {
        .init(
            id: id,
            activityKind: activityKind,
            startedAt: startedAt,
            endedAt: endedAt,
            durationMinutes: durationMinutes,
            energyBurnedKilocalories: energyBurnedKilocalories,
            distanceMeters: distanceMeters,
            source: source,
            externalSourceId: externalSourceId,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

public extension AtlasPrivacyProfileRecord {
    static func make(id: String, renderMode: AtlasPrivacyRenderMode? = nil, aliasModeEnabled: Bool, biometricLockEnabled: Bool, biometricGateMode: AtlasBiometricGateMode, shareAliasByDefault: Bool, exportAliasByDefault: Bool, createdAt: String, updatedAt: String) -> Self {
        .init(id: id, renderMode: renderMode, aliasModeEnabled: aliasModeEnabled, biometricLockEnabled: biometricLockEnabled, biometricGateMode: biometricGateMode, shareAliasByDefault: shareAliasByDefault, exportAliasByDefault: exportAliasByDefault, createdAt: createdAt, updatedAt: updatedAt)
    }
}

public extension AtlasProtocolRecord {
    static func make(id: String, compoundId: String?, linkedVialId: String?, name: String, kind: AtlasProtocolKind, administrationRoute: AtlasProtocolAdministrationRoute? = nil, supplyType: AtlasProtocolSupplyType? = nil, dosesPerSupply: Int? = nil, status: AtlasProtocolStatus, timezone: String, startDate: String, defaultTimeOfDay: String?, doseAmount: Double?, doseUnit: String?, siteTrackingEnabled: Bool, siteRotationEnabled: Bool, notes: String?, createdAt: String, updatedAt: String) -> Self {
        .init(id: id, compoundId: compoundId, linkedVialId: linkedVialId, name: name, kind: kind, administrationRoute: administrationRoute, supplyType: supplyType, dosesPerSupply: dosesPerSupply, status: status, timezone: timezone, startDate: startDate, defaultTimeOfDay: defaultTimeOfDay, doseAmount: doseAmount, doseUnit: doseUnit, siteTrackingEnabled: siteTrackingEnabled, siteRotationEnabled: siteRotationEnabled, notes: notes, createdAt: createdAt, updatedAt: updatedAt)
    }
}

public extension AtlasProtocolAliasRecord {
    static func make(id: String, protocolId: String, aliasLabel: String, aliasCompoundLabel: String?, createdAt: String, updatedAt: String, archivedAt: String?) -> Self {
        .init(id: id, protocolId: protocolId, aliasLabel: aliasLabel, aliasCompoundLabel: aliasCompoundLabel, createdAt: createdAt, updatedAt: updatedAt, archivedAt: archivedAt)
    }
}

public extension AtlasProtocolRuleRecord {
    static func make(id: String, protocolId: String, ruleType: AtlasProtocolRuleType, intervalCount: Int, weekday: Int?, timeOfDay: String?, anchorDate: String?, isActive: Bool, createdAt: String, updatedAt: String) -> Self {
        .init(id: id, protocolId: protocolId, ruleType: ruleType, intervalCount: intervalCount, weekday: weekday, timeOfDay: timeOfDay, anchorDate: anchorDate, isActive: isActive, createdAt: createdAt, updatedAt: updatedAt)
    }
}

public extension AtlasProtocolChangeAuditRecord {
    static func make(id: String, protocolId: String, revisionId: String, previousRevisionId: String?, changeType: AtlasProtocolChangeAuditType, effectiveFrom: String, summary: String, payloadJson: String, createdAt: String) -> Self {
        .init(id: id, protocolId: protocolId, revisionId: revisionId, previousRevisionId: previousRevisionId, changeType: changeType, effectiveFrom: effectiveFrom, summary: summary, payloadJson: payloadJson, createdAt: createdAt)
    }
}

public extension AtlasReminderRecord {
    static func make(id: String, protocolId: String, occurrenceId: String, offsetMinutes: Int, channel: AtlasReminderChannel, isEnabled: Bool, discreetCopyEnabled: Bool, privacyMode: AtlasReminderPrivacyMode, scheduledFor: String, notificationId: String?, title: String, body: String, status: AtlasReminderStatus, createdAt: String, updatedAt: String) -> Self {
        .init(id: id, protocolId: protocolId, occurrenceId: occurrenceId, offsetMinutes: offsetMinutes, channel: channel, isEnabled: isEnabled, discreetCopyEnabled: discreetCopyEnabled, privacyMode: privacyMode, scheduledFor: scheduledFor, notificationId: notificationId, title: title, body: body, status: status, createdAt: createdAt, updatedAt: updatedAt)
    }
}

public extension AtlasReminderPreferenceRecord {
    static func make(id: String, remindersEnabled: Bool, privacyMode: AtlasReminderPrivacyMode, leadTimeMinutes: Int, createdAt: String, updatedAt: String) -> Self {
        .init(id: id, remindersEnabled: remindersEnabled, privacyMode: privacyMode, leadTimeMinutes: leadTimeMinutes, createdAt: createdAt, updatedAt: updatedAt)
    }
}

public extension AtlasSensitiveActionAuditRecord {
    static func make(id: String, eventType: AtlasSensitiveActionAuditEventType, surface: String, protocolId: String?, scopeKind: String?, renderMode: AtlasPrivacyRenderMode?, manifestVersion: Int?, payloadJson: String, createdAt: String) -> Self {
        .init(id: id, eventType: eventType, surface: surface, protocolId: protocolId, scopeKind: scopeKind, renderMode: renderMode, manifestVersion: manifestVersion, payloadJson: payloadJson, createdAt: createdAt)
    }
}

public extension AtlasSiteRecord {
    static func make(
        id: String,
        name: String,
        bodyArea: String?,
        mapRegionKey: AtlasBodyMapRegionKey? = nil,
        notes: String?,
        createdAt: String,
        updatedAt: String,
        archivedAt: String?
    ) -> Self {
        .init(
            id: id,
            name: name,
            bodyArea: bodyArea,
            mapRegionKey: mapRegionKey,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            archivedAt: archivedAt
        )
    }
}

public extension AtlasConsumableRecord {
    static func make(
        id: String,
        protocolId: String?,
        name: String,
        category: String?,
        quantityOnHand: Double,
        unit: String,
        reorderThreshold: Double?,
        reorderLeadTimeDays: Int?,
        quantityPerUse: Double?,
        lotNumber: String?,
        sizeDescription: String?,
        notes: String?,
        vendorLabel: String?,
        purchaseNotes: String?,
        createdAt: String,
        updatedAt: String,
        archivedAt: String? = nil
    ) -> Self {
        .init(
            id: id,
            protocolId: protocolId,
            name: name,
            category: category,
            quantityOnHand: quantityOnHand,
            unit: unit,
            reorderThreshold: reorderThreshold,
            reorderLeadTimeDays: reorderLeadTimeDays,
            quantityPerUse: quantityPerUse,
            lotNumber: lotNumber,
            sizeDescription: sizeDescription,
            notes: notes,
            vendorLabel: vendorLabel,
            purchaseNotes: purchaseNotes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            archivedAt: archivedAt
        )
    }
}

public extension AtlasConsumableAdjustmentRecord {
    static func make(
        id: String,
        consumableId: String,
        protocolId: String?,
        occurrenceId: String?,
        kind: AtlasConsumableAdjustmentKind,
        deltaQuantity: Double,
        resultingQuantity: Double,
        quantityUnit: String,
        note: String?,
        vendorLabel: String? = nil,
        sourceDetail: String? = nil,
        recordedAt: String,
        createdAt: String
    ) -> Self {
        .init(
            id: id,
            consumableId: consumableId,
            protocolId: protocolId,
            occurrenceId: occurrenceId,
            kind: kind,
            deltaQuantity: deltaQuantity,
            resultingQuantity: resultingQuantity,
            quantityUnit: quantityUnit,
            note: note,
            vendorLabel: vendorLabel,
            sourceDetail: sourceDetail,
            recordedAt: recordedAt,
            createdAt: createdAt
        )
    }
}

public extension AtlasContextLogRecord {
    static func make(
        id: String,
        protocolId: String?,
        loggedAt: String,
        mealTiming: AtlasContextMealTiming?,
        mealSize: AtlasContextMealSize?,
        mealComposition: AtlasContextMealComposition?,
        fedState: AtlasContextFedState?,
        appetite: AtlasContextAppetiteState?,
        hydration: AtlasContextHydrationState?,
        giTags: [AtlasContextGITag],
        note: String?,
        tags: [String],
        presetKey: String?,
        source: AtlasHealthDataSource,
        createdAt: String,
        updatedAt: String
    ) -> Self {
        .init(
            id: id,
            protocolId: protocolId,
            loggedAt: loggedAt,
            mealTiming: mealTiming,
            mealSize: mealSize,
            mealComposition: mealComposition,
            fedState: fedState,
            appetite: appetite,
            hydration: hydration,
            giTags: giTags,
            note: note,
            tags: tags,
            presetKey: presetKey,
            source: source,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

public extension AtlasContextPresetRecord {
    static func make(
        id: String,
        title: String,
        mealTiming: AtlasContextMealTiming?,
        mealSize: AtlasContextMealSize?,
        mealComposition: AtlasContextMealComposition?,
        fedState: AtlasContextFedState?,
        appetite: AtlasContextAppetiteState?,
        hydration: AtlasContextHydrationState?,
        giTags: [AtlasContextGITag],
        createdAt: String,
        updatedAt: String,
        lastUsedAt: String?
    ) -> Self {
        .init(
            id: id,
            title: title,
            mealTiming: mealTiming,
            mealSize: mealSize,
            mealComposition: mealComposition,
            fedState: fedState,
            appetite: appetite,
            hydration: hydration,
            giTags: giTags,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastUsedAt: lastUsedAt
        )
    }
}

public extension AtlasSymptomLogRecord {
    static func make(id: String, loggedAt: String, symptomKey: String, severity: Int, notes: String?, source: AtlasHealthDataSource, createdAt: String, updatedAt: String) -> Self {
        .init(id: id, loggedAt: loggedAt, symptomKey: symptomKey, severity: severity, notes: notes, source: source, createdAt: createdAt, updatedAt: updatedAt)
    }
}

public extension AtlasVialRecord {
    static func make(id: String, protocolId: String?, compoundId: String?, calculatorProfileId: String? = nil, label: String, startingQuantity: Double, concentrationValue: Double?, concentrationUnit: String?, volumeMl: Double?, remainingQuantity: Double, lowStockThreshold: Double?, quantityUnit: String, openedAt: String?, expiresAt: String?, referencePhotoRelativePath: String? = nil, labelScanText: String? = nil, createdAt: String, updatedAt: String, archivedAt: String? = nil) -> Self {
        .init(id: id, protocolId: protocolId, compoundId: compoundId, calculatorProfileId: calculatorProfileId, label: label, startingQuantity: startingQuantity, concentrationValue: concentrationValue, concentrationUnit: concentrationUnit, volumeMl: volumeMl, remainingQuantity: remainingQuantity, lowStockThreshold: lowStockThreshold, quantityUnit: quantityUnit, openedAt: openedAt, expiresAt: expiresAt, referencePhotoRelativePath: referencePhotoRelativePath, labelScanText: labelScanText, createdAt: createdAt, updatedAt: updatedAt, archivedAt: archivedAt)
    }
}

public extension AtlasWeightLogRecord {
    static func make(id: String, loggedAt: String, value: Double, unit: AtlasWeightUnit, source: AtlasHealthDataSource, notes: String?, createdAt: String, updatedAt: String) -> Self {
        .init(id: id, loggedAt: loggedAt, value: value, unit: unit, source: source, notes: notes, createdAt: createdAt, updatedAt: updatedAt)
    }
}

public extension AtlasOccurrenceProjectionRecord {
    static func make(id: String, protocolId: String, reminderId: String?, scheduledAt: String, state: AtlasOccurrenceState, createdAt: String, updatedAt: String) -> Self {
        .init(id: id, protocolId: protocolId, reminderId: reminderId, scheduledAt: scheduledAt, state: state, createdAt: createdAt, updatedAt: updatedAt)
    }
}

public struct AtlasExportSnapshot: Codable, Equatable, Sendable {
    public var calculatorProfiles: [AtlasCalculatorProfileRecord]
    public var compounds: [AtlasCompoundRecord]
    public var consumableAdjustments: [AtlasConsumableAdjustmentRecord]
    public var consumables: [AtlasConsumableRecord]
    public var contextPresets: [AtlasContextPresetRecord]
    public var contextLogs: [AtlasContextLogRecord]
    public var customMetrics: [AtlasCustomMetricRecord]
    public var healthConnections: [AtlasHealthConnectionRecord]
    public var logEvents: [AtlasLogEventRecord]
    public var metricValueLogs: [AtlasMetricValueLogRecord]
    public var privacyProfile: AtlasPrivacyProfileRecord
    public var protocolChangeAudits: [AtlasProtocolChangeAuditRecord]
    public var protocolAliases: [AtlasProtocolAliasRecord]
    public var protocolRevisionRules: [AtlasProtocolRevisionRuleRecord]
    public var protocolRevisions: [AtlasProtocolRevisionRecord]
    public var protocols: [AtlasProtocolRecord]
    public var protocolRules: [AtlasProtocolRuleRecord]
    public var reminderPreference: AtlasReminderPreferenceRecord
    public var reminders: [AtlasReminderRecord]
    public var sensitiveActionAudits: [AtlasSensitiveActionAuditRecord]
    public var sites: [AtlasSiteRecord]
    public var symptomLogs: [AtlasSymptomLogRecord]
    public var vials: [AtlasVialRecord]
    public var workoutLogs: [AtlasWorkoutLogRecord]
    public var weightLogs: [AtlasWeightLogRecord]

    public init(
        calculatorProfiles: [AtlasCalculatorProfileRecord] = [],
        compounds: [AtlasCompoundRecord] = [],
        consumableAdjustments: [AtlasConsumableAdjustmentRecord] = [],
        consumables: [AtlasConsumableRecord] = [],
        contextPresets: [AtlasContextPresetRecord] = [],
        contextLogs: [AtlasContextLogRecord] = [],
        customMetrics: [AtlasCustomMetricRecord] = [],
        healthConnections: [AtlasHealthConnectionRecord] = [],
        logEvents: [AtlasLogEventRecord] = [],
        metricValueLogs: [AtlasMetricValueLogRecord] = [],
        privacyProfile: AtlasPrivacyProfileRecord = .default(),
        protocolChangeAudits: [AtlasProtocolChangeAuditRecord] = [],
        protocolAliases: [AtlasProtocolAliasRecord] = [],
        protocolRevisionRules: [AtlasProtocolRevisionRuleRecord] = [],
        protocolRevisions: [AtlasProtocolRevisionRecord] = [],
        protocols: [AtlasProtocolRecord] = [],
        protocolRules: [AtlasProtocolRuleRecord] = [],
        reminderPreference: AtlasReminderPreferenceRecord = .default(),
        reminders: [AtlasReminderRecord] = [],
        sensitiveActionAudits: [AtlasSensitiveActionAuditRecord] = [],
        sites: [AtlasSiteRecord] = [],
        symptomLogs: [AtlasSymptomLogRecord] = [],
        vials: [AtlasVialRecord] = [],
        workoutLogs: [AtlasWorkoutLogRecord] = [],
        weightLogs: [AtlasWeightLogRecord] = []
    ) {
        self.calculatorProfiles = calculatorProfiles
        self.compounds = compounds
        self.consumableAdjustments = consumableAdjustments
        self.consumables = consumables
        self.contextPresets = contextPresets
        self.contextLogs = contextLogs
        self.customMetrics = customMetrics
        self.healthConnections = healthConnections
        self.logEvents = logEvents
        self.metricValueLogs = metricValueLogs
        self.privacyProfile = privacyProfile
        self.protocolChangeAudits = protocolChangeAudits
        self.protocolAliases = protocolAliases
        self.protocolRevisionRules = protocolRevisionRules
        self.protocolRevisions = protocolRevisions
        self.protocols = protocols
        self.protocolRules = protocolRules
        self.reminderPreference = reminderPreference
        self.reminders = reminders
        self.sensitiveActionAudits = sensitiveActionAudits
        self.sites = sites
        self.symptomLogs = symptomLogs
        self.vials = vials
        self.workoutLogs = workoutLogs
        self.weightLogs = weightLogs
    }

    enum CodingKeys: String, CodingKey {
        case calculatorProfiles
        case compounds
        case consumableAdjustments
        case consumables
        case contextPresets
        case contextLogs
        case customMetrics
        case healthConnections
        case logEvents
        case metricValueLogs
        case privacyProfile
        case protocolChangeAudits
        case protocolAliases
        case protocolRevisionRules
        case protocolRevisions
        case protocols
        case protocolRules
        case reminderPreference
        case reminders
        case sensitiveActionAudits
        case sites
        case symptomLogs
        case vials
        case workoutLogs
        case weightLogs
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            calculatorProfiles: try container.decodeIfPresent([AtlasCalculatorProfileRecord].self, forKey: .calculatorProfiles) ?? [],
            compounds: try container.decodeIfPresent([AtlasCompoundRecord].self, forKey: .compounds) ?? [],
            consumableAdjustments: try container.decodeIfPresent([AtlasConsumableAdjustmentRecord].self, forKey: .consumableAdjustments) ?? [],
            consumables: try container.decodeIfPresent([AtlasConsumableRecord].self, forKey: .consumables) ?? [],
            contextPresets: try container.decodeIfPresent([AtlasContextPresetRecord].self, forKey: .contextPresets) ?? [],
            contextLogs: try container.decodeIfPresent([AtlasContextLogRecord].self, forKey: .contextLogs) ?? [],
            customMetrics: try container.decodeIfPresent([AtlasCustomMetricRecord].self, forKey: .customMetrics) ?? [],
            healthConnections: try container.decodeIfPresent([AtlasHealthConnectionRecord].self, forKey: .healthConnections) ?? [],
            logEvents: try container.decodeIfPresent([AtlasLogEventRecord].self, forKey: .logEvents) ?? [],
            metricValueLogs: try container.decodeIfPresent([AtlasMetricValueLogRecord].self, forKey: .metricValueLogs) ?? [],
            privacyProfile: try container.decodeIfPresent(AtlasPrivacyProfileRecord.self, forKey: .privacyProfile) ?? .default(),
            protocolChangeAudits: try container.decodeIfPresent([AtlasProtocolChangeAuditRecord].self, forKey: .protocolChangeAudits) ?? [],
            protocolAliases: try container.decodeIfPresent([AtlasProtocolAliasRecord].self, forKey: .protocolAliases) ?? [],
            protocolRevisionRules: try container.decodeIfPresent([AtlasProtocolRevisionRuleRecord].self, forKey: .protocolRevisionRules) ?? [],
            protocolRevisions: try container.decodeIfPresent([AtlasProtocolRevisionRecord].self, forKey: .protocolRevisions) ?? [],
            protocols: try container.decodeIfPresent([AtlasProtocolRecord].self, forKey: .protocols) ?? [],
            protocolRules: try container.decodeIfPresent([AtlasProtocolRuleRecord].self, forKey: .protocolRules) ?? [],
            reminderPreference: try container.decodeIfPresent(AtlasReminderPreferenceRecord.self, forKey: .reminderPreference) ?? .default(),
            reminders: try container.decodeIfPresent([AtlasReminderRecord].self, forKey: .reminders) ?? [],
            sensitiveActionAudits: try container.decodeIfPresent([AtlasSensitiveActionAuditRecord].self, forKey: .sensitiveActionAudits) ?? [],
            sites: try container.decodeIfPresent([AtlasSiteRecord].self, forKey: .sites) ?? [],
            symptomLogs: try container.decodeIfPresent([AtlasSymptomLogRecord].self, forKey: .symptomLogs) ?? [],
            vials: try container.decodeIfPresent([AtlasVialRecord].self, forKey: .vials) ?? [],
            workoutLogs: try container.decodeIfPresent([AtlasWorkoutLogRecord].self, forKey: .workoutLogs) ?? [],
            weightLogs: try container.decodeIfPresent([AtlasWeightLogRecord].self, forKey: .weightLogs) ?? []
        )
    }
}

public struct AtlasExportBundle: Codable, Equatable, Sendable {
    public var manifest: AtlasExportManifest
    public var snapshot: AtlasExportSnapshot
    public var isLegacyEnvelope: Bool

    public init(
        manifest: AtlasExportManifest,
        snapshot: AtlasExportSnapshot,
        isLegacyEnvelope: Bool = false
    ) {
        self.manifest = manifest
        self.snapshot = snapshot
        self.isLegacyEnvelope = isLegacyEnvelope
    }

    enum CodingKeys: String, CodingKey {
        case manifest
        case generatedAt
        case snapshot
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let snapshot = try container.decode(AtlasExportSnapshot.self, forKey: .snapshot)

        if let manifest = try container.decodeIfPresent(AtlasExportManifest.self, forKey: .manifest) {
            self.init(manifest: manifest, snapshot: snapshot, isLegacyEnvelope: false)
        } else {
            let generatedAt = try container.decode(String.self, forKey: .generatedAt)
            self.init(
                manifest: AtlasExportManifest(generatedAt: generatedAt, source: "atlas-react-native-legacy"),
                snapshot: snapshot,
                isLegacyEnvelope: true
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(manifest, forKey: .manifest)
        try container.encode(snapshot, forKey: .snapshot)
    }
}

public enum AtlasImportMode: String, Codable, Sendable {
    case replaceExisting = "replace_existing"
}

public struct AtlasDatasetDiff: Equatable, Sendable, Identifiable {
    public var id: String { dataset }
    public var dataset: String
    public var creates: Int
    public var updates: Int

    public init(dataset: String, creates: Int, updates: Int) {
        self.dataset = dataset
        self.creates = creates
        self.updates = updates
    }
}

public struct AtlasImportValidationResult: Equatable, Sendable {
    public var manifest: AtlasExportManifest
    public var isLegacyBundle: Bool
    public var missingDatasets: [String]
    public var unsupportedDatasets: [String]

    public init(
        manifest: AtlasExportManifest,
        isLegacyBundle: Bool,
        missingDatasets: [String],
        unsupportedDatasets: [String]
    ) {
        self.manifest = manifest
        self.isLegacyBundle = isLegacyBundle
        self.missingDatasets = missingDatasets
        self.unsupportedDatasets = unsupportedDatasets
    }
}

public struct AtlasImportDryRunSummary: Equatable, Sendable {
    public var validation: AtlasImportValidationResult
    public var datasetDiffs: [AtlasDatasetDiff]
    public var recordsToCreate: Int
    public var recordsToUpdate: Int
    public var lintFindings: [AtlasImportLintItem]
    public var warnings: [String]
    public var privacyNotes: [String]
    public var backfillNotes: [String]
    public var plainLanguageSummary: AtlasGeneratedSummary?

    public init(
        validation: AtlasImportValidationResult,
        datasetDiffs: [AtlasDatasetDiff],
        recordsToCreate: Int,
        recordsToUpdate: Int,
        lintFindings: [AtlasImportLintItem],
        warnings: [String],
        privacyNotes: [String],
        backfillNotes: [String],
        plainLanguageSummary: AtlasGeneratedSummary? = nil
    ) {
        self.validation = validation
        self.datasetDiffs = datasetDiffs
        self.recordsToCreate = recordsToCreate
        self.recordsToUpdate = recordsToUpdate
        self.lintFindings = lintFindings
        self.warnings = warnings
        self.privacyNotes = privacyNotes
        self.backfillNotes = backfillNotes
        self.plainLanguageSummary = plainLanguageSummary
    }
}

public struct AtlasPreparedImport: Sendable {
    public var bundle: AtlasExportBundle
    public var stagedSnapshot: AtlasExportSnapshot
    public var dryRun: AtlasImportDryRunSummary

    public init(
        bundle: AtlasExportBundle,
        stagedSnapshot: AtlasExportSnapshot,
        dryRun: AtlasImportDryRunSummary
    ) {
        self.bundle = bundle
        self.stagedSnapshot = stagedSnapshot
        self.dryRun = dryRun
    }
}

public struct AtlasImportCommitResult: Equatable, Sendable {
    public var backupURL: URL?
    public var importedProtocolCount: Int
    public var importedLogEventCount: Int
    public var nextDue: AtlasSharedNextDueSnapshot?

    public init(
        backupURL: URL?,
        importedProtocolCount: Int,
        importedLogEventCount: Int,
        nextDue: AtlasSharedNextDueSnapshot?
    ) {
        self.backupURL = backupURL
        self.importedProtocolCount = importedProtocolCount
        self.importedLogEventCount = importedLogEventCount
        self.nextDue = nextDue
    }
}

public extension ISO8601DateFormatter {
    static var atlas: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
}
