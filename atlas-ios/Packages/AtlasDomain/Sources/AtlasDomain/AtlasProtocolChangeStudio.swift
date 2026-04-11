import Foundation

public enum AtlasProtocolChangeType: String, CaseIterable, Sendable, Identifiable {
    case futureDose = "future_dose"
    case futureTime = "future_time"
    case dayOfWeek = "day_of_week"
    case everyNDays = "every_n_days"
    case pause
    case resume
    case titration
    case restPeriod = "rest_period"
    case missedDosePolicy = "missed_dose_policy"
    case timezone
    case vialSwitch = "vial_switch"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .futureDose: "Future dose"
        case .futureTime: "Future time"
        case .dayOfWeek: "Day of week"
        case .everyNDays: "Every N days"
        case .pause: "Pause"
        case .resume: "Resume"
        case .titration: "Titration phase"
        case .restPeriod: "Rest period"
        case .missedDosePolicy: "Missed-dose recovery"
        case .timezone: "Timezone / travel"
        case .vialSwitch: "Vial switch"
        }
    }

    public var description: String {
        switch self {
        case .futureDose:
            return "Change the saved amount from an effective date forward."
        case .futureTime:
            return "Change the saved time of day from an effective date forward."
        case .dayOfWeek:
            return "Move a weekly cadence to a new weekday."
        case .everyNDays:
            return "Move the plan to a fixed every-N-days cadence."
        case .pause:
            return "Pause future occurrences from the selected date."
        case .resume:
            return "Resume the saved future plan from the selected date."
        case .titration:
            return "Add a bounded titration phase before the base plan continues."
        case .restPeriod:
            return "Insert a no-dose rest window and then resume the saved plan."
        case .missedDosePolicy:
            return "Change how future missed doses are interpreted."
        case .timezone:
            return "Adjust timezone handling for future travel or schedule shifts."
        case .vialSwitch:
            return "Plan which vial should cover future logs from an effective date."
        }
    }
}

public enum AtlasProtocolChangePreviewWindow: Int, CaseIterable, Sendable, Identifiable {
    case seven = 7
    case fourteen = 14
    case thirty = 30

    public var id: Int { rawValue }
    public var days: Int { rawValue }
    public var title: String { "\(rawValue) days" }
}

public enum AtlasProtocolChangePreviewDiffKind: String, Sendable {
    case added
    case removed
    case moved
    case rewired
}

public struct AtlasProtocolChangeVialOption: Identifiable, Equatable, Sendable {
    public var id: String
    public var label: String
    public var remainingLabel: String
    public var isArchived: Bool

    public init(id: String, label: String, remainingLabel: String, isArchived: Bool) {
        self.id = id
        self.label = label
        self.remainingLabel = remainingLabel
        self.isArchived = isArchived
    }
}

public struct AtlasProtocolChangeOccurrenceSnapshot: Equatable, Sendable {
    public var occurrenceID: String
    public var whenLabel: String
    public var doseLabel: String?

    public init(occurrenceID: String, whenLabel: String, doseLabel: String?) {
        self.occurrenceID = occurrenceID
        self.whenLabel = whenLabel
        self.doseLabel = doseLabel
    }
}

public struct AtlasProtocolChangeOccurrenceDiff: Equatable, Sendable, Identifiable {
    public var id: String
    public var kind: AtlasProtocolChangePreviewDiffKind
    public var beforeLabel: String?
    public var afterLabel: String?

    public init(
        id: String,
        kind: AtlasProtocolChangePreviewDiffKind,
        beforeLabel: String?,
        afterLabel: String?
    ) {
        self.id = id
        self.kind = kind
        self.beforeLabel = beforeLabel
        self.afterLabel = afterLabel
    }
}

public struct AtlasProtocolChangeStudioContext: Identifiable, Equatable, Sendable {
    public var id: String { protocolID }
    public var protocolID: String
    public var canonicalTitle: String
    public var aliasTitle: String?
    public var protocolKind: AtlasProtocolKind
    public var kindLabel: String
    public var cadenceLabel: String
    public var doseLabel: String?
    public var effectiveTimeOfDay: String?
    public var currentMissedDosePolicy: AtlasMissedDosePolicy
    public var currentTimezone: String
    public var currentTimezoneStrategy: AtlasProtocolTimezoneStrategy
    public var currentLinkedVialID: String?
    public var availableVials: [AtlasProtocolChangeVialOption]
    public var compoundKnowledge: AtlasCompoundKnowledge?
    public var activeCompanions: [AtlasProtocolCompanionSummary]
    public var siteWarnings: [String]

    public init(
        protocolID: String,
        canonicalTitle: String,
        aliasTitle: String?,
        protocolKind: AtlasProtocolKind,
        kindLabel: String,
        cadenceLabel: String,
        doseLabel: String?,
        effectiveTimeOfDay: String?,
        currentMissedDosePolicy: AtlasMissedDosePolicy,
        currentTimezone: String,
        currentTimezoneStrategy: AtlasProtocolTimezoneStrategy,
        currentLinkedVialID: String?,
        availableVials: [AtlasProtocolChangeVialOption],
        compoundKnowledge: AtlasCompoundKnowledge? = nil,
        activeCompanions: [AtlasProtocolCompanionSummary] = [],
        siteWarnings: [String]
    ) {
        self.protocolID = protocolID
        self.canonicalTitle = canonicalTitle
        self.aliasTitle = aliasTitle
        self.protocolKind = protocolKind
        self.kindLabel = kindLabel
        self.cadenceLabel = cadenceLabel
        self.doseLabel = doseLabel
        self.effectiveTimeOfDay = effectiveTimeOfDay
        self.currentMissedDosePolicy = currentMissedDosePolicy
        self.currentTimezone = currentTimezone
        self.currentTimezoneStrategy = currentTimezoneStrategy
        self.currentLinkedVialID = currentLinkedVialID
        self.availableVials = availableVials
        self.compoundKnowledge = compoundKnowledge
        self.activeCompanions = activeCompanions
        self.siteWarnings = siteWarnings
    }
}

public struct AtlasProtocolCompanionSummary: Identifiable, Equatable, Sendable {
    public var id: String
    public var canonicalTitle: String
    public var aliasTitle: String?
    public var kindLabel: String
    public var cadenceLabel: String
    public var doseLabel: String?
    public var compoundKnowledge: AtlasCompoundKnowledge?

    public init(
        id: String,
        canonicalTitle: String,
        aliasTitle: String?,
        kindLabel: String,
        cadenceLabel: String,
        doseLabel: String?,
        compoundKnowledge: AtlasCompoundKnowledge? = nil
    ) {
        self.id = id
        self.canonicalTitle = canonicalTitle
        self.aliasTitle = aliasTitle
        self.kindLabel = kindLabel
        self.cadenceLabel = cadenceLabel
        self.doseLabel = doseLabel
        self.compoundKnowledge = compoundKnowledge
    }
}

public enum AtlasInteractionSeverity: String, CaseIterable, Sendable {
    case advisory
    case caution
    case elevated

    public var title: String {
        switch self {
        case .advisory: "Advisory"
        case .caution: "Caution"
        case .elevated: "Elevated"
        }
    }
}

public struct AtlasInteractionWarning: Identifiable, Equatable, Sendable {
    public var id: String
    public var severity: AtlasInteractionSeverity
    public var title: String
    public var detail: String

    public init(
        id: String,
        severity: AtlasInteractionSeverity,
        title: String,
        detail: String
    ) {
        self.id = id
        self.severity = severity
        self.title = title
        self.detail = detail
    }
}

public struct AtlasProtocolChangeDraft: Equatable, Sendable {
    public var changeType: AtlasProtocolChangeType
    public var effectiveDate: Date
    public var doseAmount: Double?
    public var doseUnit: String
    public var timeOfDay: String
    public var weekday: Int?
    public var intervalDays: Int
    public var linkedVialID: String?
    public var missedDosePolicy: AtlasMissedDosePolicy
    public var notes: String?
    public var previewWindow: AtlasProtocolChangePreviewWindow
    public var restLengthDays: Int
    public var titrationDoseAmount: Double?
    public var titrationDoseUnit: String
    public var titrationLengthDays: Int
    public var timezone: String
    public var timezoneStrategy: AtlasProtocolTimezoneStrategy

    public init(
        changeType: AtlasProtocolChangeType = .futureDose,
        effectiveDate: Date = Date(),
        doseAmount: Double? = nil,
        doseUnit: String = "",
        timeOfDay: String = "08:00",
        weekday: Int? = nil,
        intervalDays: Int = 1,
        linkedVialID: String? = nil,
        missedDosePolicy: AtlasMissedDosePolicy = .skipAndContinue,
        notes: String? = nil,
        previewWindow: AtlasProtocolChangePreviewWindow = .fourteen,
        restLengthDays: Int = 7,
        titrationDoseAmount: Double? = nil,
        titrationDoseUnit: String = "",
        titrationLengthDays: Int = 14,
        timezone: String = TimeZone.current.identifier,
        timezoneStrategy: AtlasProtocolTimezoneStrategy = .keepLocalClock
    ) {
        self.changeType = changeType
        self.effectiveDate = effectiveDate
        self.doseAmount = doseAmount
        self.doseUnit = doseUnit
        self.timeOfDay = timeOfDay
        self.weekday = weekday
        self.intervalDays = intervalDays
        self.linkedVialID = linkedVialID
        self.missedDosePolicy = missedDosePolicy
        self.notes = notes
        self.previewWindow = previewWindow
        self.restLengthDays = restLengthDays
        self.titrationDoseAmount = titrationDoseAmount
        self.titrationDoseUnit = titrationDoseUnit
        self.titrationLengthDays = titrationLengthDays
        self.timezone = timezone
        self.timezoneStrategy = timezoneStrategy
    }
}

public struct AtlasProtocolChangePreview: Equatable, Sendable {
    public var protocolID: String
    public var changeType: AtlasProtocolChangeType
    public var effectiveDate: Date
    public var previewWindow: AtlasProtocolChangePreviewWindow
    public var summary: String
    public var adherenceNote: String?
    public var nextDueBefore: AtlasProtocolChangeOccurrenceSnapshot?
    public var nextDueAfter: AtlasProtocolChangeOccurrenceSnapshot?
    public var currentReminderLabel: String?
    public var draftReminderLabel: String?
    public var inventoryForecastBefore: String?
    public var inventoryForecastAfter: String?
    public var occurrenceChanges: [AtlasProtocolChangeOccurrenceDiff]
    public var interactionWarnings: [AtlasInteractionWarning]
    public var siteWarnings: [String]

    public init(
        protocolID: String,
        changeType: AtlasProtocolChangeType,
        effectiveDate: Date,
        previewWindow: AtlasProtocolChangePreviewWindow,
        summary: String,
        adherenceNote: String?,
        nextDueBefore: AtlasProtocolChangeOccurrenceSnapshot?,
        nextDueAfter: AtlasProtocolChangeOccurrenceSnapshot?,
        currentReminderLabel: String?,
        draftReminderLabel: String?,
        inventoryForecastBefore: String?,
        inventoryForecastAfter: String?,
        occurrenceChanges: [AtlasProtocolChangeOccurrenceDiff],
        interactionWarnings: [AtlasInteractionWarning] = [],
        siteWarnings: [String]
    ) {
        self.protocolID = protocolID
        self.changeType = changeType
        self.effectiveDate = effectiveDate
        self.previewWindow = previewWindow
        self.summary = summary
        self.adherenceNote = adherenceNote
        self.nextDueBefore = nextDueBefore
        self.nextDueAfter = nextDueAfter
        self.currentReminderLabel = currentReminderLabel
        self.draftReminderLabel = draftReminderLabel
        self.inventoryForecastBefore = inventoryForecastBefore
        self.inventoryForecastAfter = inventoryForecastAfter
        self.occurrenceChanges = occurrenceChanges
        self.interactionWarnings = interactionWarnings
        self.siteWarnings = siteWarnings
    }
}

public struct AtlasProtocolChangeExplanation: Identifiable, Hashable, Sendable {
    public var id: String
    public var changeType: AtlasProtocolChangeAuditType
    public var summary: String
    public var effectiveDateLabel: String
    public var recordedAt: Date
    public var facts: [AtlasExplainerFact]
    public var notes: [String]

    public init(
        id: String,
        changeType: AtlasProtocolChangeAuditType,
        summary: String,
        effectiveDateLabel: String,
        recordedAt: Date,
        facts: [AtlasExplainerFact],
        notes: [String] = []
    ) {
        self.id = id
        self.changeType = changeType
        self.summary = summary
        self.effectiveDateLabel = effectiveDateLabel
        self.recordedAt = recordedAt
        self.facts = facts
        self.notes = notes
    }
}

public struct AtlasProtocolChangeImpactSummary: Equatable, Sendable {
    public var title: String
    public var facts: [AtlasExplainerFact]
    public var notes: [String]

    public init(
        title: String,
        facts: [AtlasExplainerFact],
        notes: [String] = []
    ) {
        self.title = title
        self.facts = facts
        self.notes = notes
    }
}

public struct AtlasProtocolChangeCommitResult: Equatable, Sendable {
    public var detail: AtlasProtocolDetailSnapshot
    public var preview: AtlasProtocolChangePreview
    public var auditRecord: AtlasProtocolChangeAuditRecord
    public var impactSummary: AtlasProtocolChangeImpactSummary

    public init(
        detail: AtlasProtocolDetailSnapshot,
        preview: AtlasProtocolChangePreview,
        auditRecord: AtlasProtocolChangeAuditRecord,
        impactSummary: AtlasProtocolChangeImpactSummary
    ) {
        self.detail = detail
        self.preview = preview
        self.auditRecord = auditRecord
        self.impactSummary = impactSummary
    }
}
