import Foundation

public enum AtlasImportDataset: String, CaseIterable, Sendable {
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
