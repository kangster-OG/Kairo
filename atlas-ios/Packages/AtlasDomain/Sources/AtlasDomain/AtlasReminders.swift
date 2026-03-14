import Foundation

public enum AtlasNotificationAuthorizationStatus: String, Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral
}

public enum AtlasReminderNotificationAction: String, Equatable, Sendable {
    case markTaken = "atlas-mark-taken"
    case skip = "atlas-skip"
    case openApp = "atlas-open-app"
}

public struct AtlasReminderSettingsSnapshot: Equatable, Sendable {
    public var remindersEnabled: Bool
    public var privacyMode: AtlasReminderPrivacyMode
    public var leadTimeMinutes: Int

    public init(
        remindersEnabled: Bool = true,
        privacyMode: AtlasReminderPrivacyMode = .fullDetail,
        leadTimeMinutes: Int = 0
    ) {
        self.remindersEnabled = remindersEnabled
        self.privacyMode = privacyMode
        self.leadTimeMinutes = leadTimeMinutes
    }
}

public struct AtlasReminderPreferenceUpdate: Equatable, Sendable {
    public var remindersEnabled: Bool?
    public var privacyMode: AtlasReminderPrivacyMode?
    public var leadTimeMinutes: Int?

    public init(
        remindersEnabled: Bool? = nil,
        privacyMode: AtlasReminderPrivacyMode? = nil,
        leadTimeMinutes: Int? = nil
    ) {
        self.remindersEnabled = remindersEnabled
        self.privacyMode = privacyMode
        self.leadTimeMinutes = leadTimeMinutes
    }
}

public struct AtlasReminderPreview: Equatable, Sendable {
    public var title: String
    public var body: String
    public var isSilent: Bool
    public var effectiveMode: AtlasReminderPrivacyMode

    public init(
        title: String,
        body: String,
        isSilent: Bool,
        effectiveMode: AtlasReminderPrivacyMode
    ) {
        self.title = title
        self.body = body
        self.isSilent = isSilent
        self.effectiveMode = effectiveMode
    }
}

public struct AtlasReminderScheduleRequest: Equatable, Sendable {
    public var occurrenceID: String
    public var protocolID: String
    public var scheduledAt: Date
    public var triggerAt: Date
    public var title: String
    public var body: String
    public var isSilent: Bool

    public init(
        occurrenceID: String,
        protocolID: String,
        scheduledAt: Date,
        triggerAt: Date,
        title: String,
        body: String,
        isSilent: Bool
    ) {
        self.occurrenceID = occurrenceID
        self.protocolID = protocolID
        self.scheduledAt = scheduledAt
        self.triggerAt = triggerAt
        self.title = title
        self.body = body
        self.isSilent = isSilent
    }
}

public struct AtlasReminderNotificationResponse: Equatable, Sendable {
    public var action: AtlasReminderNotificationAction
    public var occurrenceID: String
    public var protocolID: String
    public var scheduledAt: Date

    public init(
        action: AtlasReminderNotificationAction,
        occurrenceID: String,
        protocolID: String,
        scheduledAt: Date
    ) {
        self.action = action
        self.occurrenceID = occurrenceID
        self.protocolID = protocolID
        self.scheduledAt = scheduledAt
    }
}
