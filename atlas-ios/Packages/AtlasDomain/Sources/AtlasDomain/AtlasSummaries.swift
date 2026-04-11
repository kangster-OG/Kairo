import Foundation

public enum AtlasSummaryKind: String, Codable, CaseIterable, Sendable {
    case weeklyRecap = "weekly_recap"
    case episodeRecap = "episode_recap"
    case importDiffRecap = "import_diff_recap"
    case providerHandoffRecap = "provider_handoff_recap"

    public var title: String {
        switch self {
        case .weeklyRecap:
            return "Weekly recap"
        case .episodeRecap:
            return "Episode recap"
        case .importDiffRecap:
            return "Import diff recap"
        case .providerHandoffRecap:
            return "Provider handoff recap"
        }
    }
}

public enum AtlasSummaryExecutionMode: String, Codable, Sendable {
    case deterministicLocal = "deterministic_local"
    case externalProvider = "external_provider"

    public var label: String {
        switch self {
        case .deterministicLocal:
            return "On-device recap"
        case .externalProvider:
            return "External recap"
        }
    }
}

public struct AtlasSummarySettingsSnapshot: Sendable, Equatable, Codable {
    public var onDeviceEnabled: Bool
    public var externalProviderEnabled: Bool
    public var externalProviderConsentRecordedAt: Date?

    public init(
        onDeviceEnabled: Bool = false,
        externalProviderEnabled: Bool = false,
        externalProviderConsentRecordedAt: Date? = nil
    ) {
        self.onDeviceEnabled = onDeviceEnabled
        self.externalProviderEnabled = externalProviderEnabled
        self.externalProviderConsentRecordedAt = externalProviderConsentRecordedAt
    }
}

public struct AtlasSummarySettingsUpdate: Sendable, Equatable {
    public var onDeviceEnabled: Bool?
    public var externalProviderEnabled: Bool?
    public var externalProviderConsentRecordedAt: Date?

    public init(
        onDeviceEnabled: Bool? = nil,
        externalProviderEnabled: Bool? = nil,
        externalProviderConsentRecordedAt: Date? = nil
    ) {
        self.onDeviceEnabled = onDeviceEnabled
        self.externalProviderEnabled = externalProviderEnabled
        self.externalProviderConsentRecordedAt = externalProviderConsentRecordedAt
    }
}

public struct AtlasSummaryFact: Sendable, Equatable, Identifiable, Codable {
    public var id: String
    public var label: String
    public var value: String

    public init(
        id: String,
        label: String,
        value: String
    ) {
        self.id = id
        self.label = label
        self.value = value
    }
}

public struct AtlasSummarySourceSection: Sendable, Equatable, Identifiable, Codable {
    public var id: String
    public var title: String
    public var facts: [AtlasSummaryFact]

    public init(
        id: String,
        title: String,
        facts: [AtlasSummaryFact]
    ) {
        self.id = id
        self.title = title
        self.facts = facts
    }
}

public struct AtlasSummaryRequest: Sendable, Equatable, Codable {
    public var kind: AtlasSummaryKind
    public var title: String
    public var renderMode: AtlasPrivacyRenderMode
    public var sourceSections: [AtlasSummarySourceSection]
    public var disclaimer: String
    public var generatedAt: Date

    public init(
        kind: AtlasSummaryKind,
        title: String,
        renderMode: AtlasPrivacyRenderMode,
        sourceSections: [AtlasSummarySourceSection],
        disclaimer: String,
        generatedAt: Date
    ) {
        self.kind = kind
        self.title = title
        self.renderMode = renderMode
        self.sourceSections = sourceSections
        self.disclaimer = disclaimer
        self.generatedAt = generatedAt
    }
}

public struct AtlasGeneratedSummary: Sendable, Equatable, Codable {
    public var kind: AtlasSummaryKind
    public var title: String
    public var summary: String
    public var disclaimer: String
    public var sourceSections: [AtlasSummarySourceSection]
    public var executionMode: AtlasSummaryExecutionMode
    public var generatedAt: Date

    public init(
        kind: AtlasSummaryKind,
        title: String,
        summary: String,
        disclaimer: String,
        sourceSections: [AtlasSummarySourceSection],
        executionMode: AtlasSummaryExecutionMode,
        generatedAt: Date
    ) {
        self.kind = kind
        self.title = title
        self.summary = summary
        self.disclaimer = disclaimer
        self.sourceSections = sourceSections
        self.executionMode = executionMode
        self.generatedAt = generatedAt
    }
}

public enum AtlasSummaryGenerationError: LocalizedError, Sendable {
    case externalProcessingDeferred
    case summariesDisabled
    case unsupportedRequest

    public var errorDescription: String? {
        switch self {
        case .externalProcessingDeferred:
            return "External provider summaries are deferred in this Atlas build."
        case .summariesDisabled:
            return "Plain-language summaries are turned off."
        case .unsupportedRequest:
            return "Atlas could not build a bounded summary from the available local data."
        }
    }
}

public protocol AtlasSummaryEngine: Sendable {
    func generateSummary(for request: AtlasSummaryRequest) throws -> AtlasGeneratedSummary
}
