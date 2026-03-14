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
    case inventory
    case calculator
    case trustVault
    case importFlow
    case reviewMode
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
}

public struct AtlasFeatureFlagState: Codable, Sendable, Equatable {
    public var nativeWidgets: Bool
    public var nativeIntents: Bool
    public var trustVaultShell: Bool
    public var importShell: Bool
    public var reviewMode: Bool
    public var liveReviewSessions: Bool

    public init(
        nativeWidgets: Bool = true,
        nativeIntents: Bool = true,
        trustVaultShell: Bool = true,
        importShell: Bool = true,
        reviewMode: Bool = true,
        liveReviewSessions: Bool = false
    ) {
        self.nativeWidgets = nativeWidgets
        self.nativeIntents = nativeIntents
        self.trustVaultShell = trustVaultShell
        self.importShell = importShell
        self.reviewMode = reviewMode
        self.liveReviewSessions = liveReviewSessions
    }

    public func isEnabled(_ flag: AtlasFeatureFlag) -> Bool {
        switch flag {
        case .nativeWidgets: nativeWidgets
        case .nativeIntents: nativeIntents
        case .trustVaultShell: trustVaultShell
        case .importShell: importShell
        case .reviewMode: reviewMode
        case .liveReviewSessions: liveReviewSessions
        }
    }
}

public enum AtlasProtocolKind: String, Codable, CaseIterable, Sendable {
    case glp
    case peptide
    case custom
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
    case importCommitted = "import_committed"
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

public enum AtlasHealthDataSource: String, Codable, CaseIterable, Sendable {
    case manual
    case health
    case `import`
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
    public var kindLabel: String
    public var cadenceLabel: String
    public var doseLabel: String?
    public var nextDueLabel: String?
    public var status: AtlasProtocolStatus

    public init(
        id: String,
        canonicalTitle: String,
        aliasTitle: String?,
        kindLabel: String,
        cadenceLabel: String,
        doseLabel: String? = nil,
        nextDueLabel: String? = nil,
        status: AtlasProtocolStatus
    ) {
        self.id = id
        self.canonicalTitle = canonicalTitle
        self.aliasTitle = aliasTitle
        self.kindLabel = kindLabel
        self.cadenceLabel = cadenceLabel
        self.doseLabel = doseLabel
        self.nextDueLabel = nextDueLabel
        self.status = status
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

public struct AtlasSettingsSnapshot: Sendable, Equatable {
    public var accountMode: AtlasAccountMode
    public var accountStartMode: AtlasOnboardingAccountMode?
    public var onboardingCompleted: Bool
    public var syncStatus: AtlasSyncScaffoldStatus
    public var healthScaffold: AtlasHealthScaffoldSnapshot
    public var trustVaultStatus: TrustVaultStatus

    public init(
        accountMode: AtlasAccountMode = .guest,
        accountStartMode: AtlasOnboardingAccountMode? = nil,
        onboardingCompleted: Bool = false,
        syncStatus: AtlasSyncScaffoldStatus = .localOnly,
        healthScaffold: AtlasHealthScaffoldSnapshot = .init(),
        trustVaultStatus: TrustVaultStatus = .init()
    ) {
        self.accountMode = accountMode
        self.accountStartMode = accountStartMode
        self.onboardingCompleted = onboardingCompleted
        self.syncStatus = syncStatus
        self.healthScaffold = healthScaffold
        self.trustVaultStatus = trustVaultStatus
    }
}

public struct AtlasSharedNextDueSnapshot: Codable, Equatable, Sendable {
    public var occurrenceID: String
    public var protocolID: String
    public var displayTitle: String
    public var dueLabel: String
    public var scheduledAt: String

    public init(
        occurrenceID: String,
        protocolID: String,
        displayTitle: String,
        dueLabel: String,
        scheduledAt: String
    ) {
        self.occurrenceID = occurrenceID
        self.protocolID = protocolID
        self.displayTitle = displayTitle
        self.dueLabel = dueLabel
        self.scheduledAt = scheduledAt
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

    public init(id: String, protocolID: String, occurrenceID: String, title: String) {
        self.id = id
        self.protocolID = protocolID
        self.occurrenceID = occurrenceID
        self.title = title
    }
}

public struct AtlasSharedFeatureFlagProjection: Codable, Equatable, Sendable {
    public var flags: AtlasFeatureFlagState

    public init(flags: AtlasFeatureFlagState) {
        self.flags = flags
    }
}

public struct AtlasProjectionDebugState: Equatable, Sendable {
    public var nextDue: AtlasSharedNextDueSnapshot?
    public var timeline: [AtlasSharedTimelineSummary]
    public var labels: [AtlasSharedLabelProjection]
    public var quickActions: [AtlasSharedQuickAction]
    public var featureFlags: AtlasSharedFeatureFlagProjection

    public init(
        nextDue: AtlasSharedNextDueSnapshot?,
        timeline: [AtlasSharedTimelineSummary],
        labels: [AtlasSharedLabelProjection],
        quickActions: [AtlasSharedQuickAction],
        featureFlags: AtlasSharedFeatureFlagProjection
    ) {
        self.nextDue = nextDue
        self.timeline = timeline
        self.labels = labels
        self.quickActions = quickActions
        self.featureFlags = featureFlags
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
    public var notes: String?
    public var createdAt: String
    public var updatedAt: String
    public var archivedAt: String?
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

public extension AtlasPrivacyProfileRecord {
    static func make(id: String, renderMode: AtlasPrivacyRenderMode? = nil, aliasModeEnabled: Bool, biometricLockEnabled: Bool, biometricGateMode: AtlasBiometricGateMode, shareAliasByDefault: Bool, exportAliasByDefault: Bool, createdAt: String, updatedAt: String) -> Self {
        .init(id: id, renderMode: renderMode, aliasModeEnabled: aliasModeEnabled, biometricLockEnabled: biometricLockEnabled, biometricGateMode: biometricGateMode, shareAliasByDefault: shareAliasByDefault, exportAliasByDefault: exportAliasByDefault, createdAt: createdAt, updatedAt: updatedAt)
    }
}

public extension AtlasProtocolRecord {
    static func make(id: String, compoundId: String?, linkedVialId: String?, name: String, kind: AtlasProtocolKind, status: AtlasProtocolStatus, timezone: String, startDate: String, defaultTimeOfDay: String?, doseAmount: Double?, doseUnit: String?, siteTrackingEnabled: Bool, siteRotationEnabled: Bool, notes: String?, createdAt: String, updatedAt: String) -> Self {
        .init(id: id, compoundId: compoundId, linkedVialId: linkedVialId, name: name, kind: kind, status: status, timezone: timezone, startDate: startDate, defaultTimeOfDay: defaultTimeOfDay, doseAmount: doseAmount, doseUnit: doseUnit, siteTrackingEnabled: siteTrackingEnabled, siteRotationEnabled: siteRotationEnabled, notes: notes, createdAt: createdAt, updatedAt: updatedAt)
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
    static func make(id: String, name: String, bodyArea: String?, notes: String?, createdAt: String, updatedAt: String, archivedAt: String?) -> Self {
        .init(id: id, name: name, bodyArea: bodyArea, notes: notes, createdAt: createdAt, updatedAt: updatedAt, archivedAt: archivedAt)
    }
}

public extension AtlasSymptomLogRecord {
    static func make(id: String, loggedAt: String, symptomKey: String, severity: Int, notes: String?, source: AtlasHealthDataSource, createdAt: String, updatedAt: String) -> Self {
        .init(id: id, loggedAt: loggedAt, symptomKey: symptomKey, severity: severity, notes: notes, source: source, createdAt: createdAt, updatedAt: updatedAt)
    }
}

public extension AtlasVialRecord {
    static func make(id: String, protocolId: String?, compoundId: String?, calculatorProfileId: String? = nil, label: String, startingQuantity: Double, concentrationValue: Double?, concentrationUnit: String?, volumeMl: Double?, remainingQuantity: Double, lowStockThreshold: Double?, quantityUnit: String, openedAt: String?, expiresAt: String?, createdAt: String, updatedAt: String, archivedAt: String? = nil) -> Self {
        .init(id: id, protocolId: protocolId, compoundId: compoundId, calculatorProfileId: calculatorProfileId, label: label, startingQuantity: startingQuantity, concentrationValue: concentrationValue, concentrationUnit: concentrationUnit, volumeMl: volumeMl, remainingQuantity: remainingQuantity, lowStockThreshold: lowStockThreshold, quantityUnit: quantityUnit, openedAt: openedAt, expiresAt: expiresAt, createdAt: createdAt, updatedAt: updatedAt, archivedAt: archivedAt)
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
    public var weightLogs: [AtlasWeightLogRecord]

    public init(
        calculatorProfiles: [AtlasCalculatorProfileRecord] = [],
        compounds: [AtlasCompoundRecord] = [],
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
        weightLogs: [AtlasWeightLogRecord] = []
    ) {
        self.calculatorProfiles = calculatorProfiles
        self.compounds = compounds
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
        self.weightLogs = weightLogs
    }

    enum CodingKeys: String, CodingKey {
        case calculatorProfiles
        case compounds
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
        case weightLogs
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            calculatorProfiles: try container.decodeIfPresent([AtlasCalculatorProfileRecord].self, forKey: .calculatorProfiles) ?? [],
            compounds: try container.decodeIfPresent([AtlasCompoundRecord].self, forKey: .compounds) ?? [],
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
    public var warnings: [String]
    public var privacyNotes: [String]
    public var backfillNotes: [String]

    public init(
        validation: AtlasImportValidationResult,
        datasetDiffs: [AtlasDatasetDiff],
        recordsToCreate: Int,
        recordsToUpdate: Int,
        warnings: [String],
        privacyNotes: [String],
        backfillNotes: [String]
    ) {
        self.validation = validation
        self.datasetDiffs = datasetDiffs
        self.recordsToCreate = recordsToCreate
        self.recordsToUpdate = recordsToUpdate
        self.warnings = warnings
        self.privacyNotes = privacyNotes
        self.backfillNotes = backfillNotes
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
