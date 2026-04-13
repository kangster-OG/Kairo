import Foundation

public enum AtlasMedicationLevelModelKind: String, Codable, Equatable, Sendable {
    case halfLifeEstimate
    case scheduleWindowEstimate
}

public struct AtlasCompoundKineticsProfile: Codable, Equatable, Hashable, Sendable {
    public var halfLifeHours: Double
    public var sourceLabel: String
    public var notes: String

    public init(
        halfLifeHours: Double,
        sourceLabel: String,
        notes: String
    ) {
        self.halfLifeHours = halfLifeHours
        self.sourceLabel = sourceLabel
        self.notes = notes
    }
}

public struct AtlasMedicationLevelPoint: Identifiable, Equatable, Sendable {
    public var id: String { timestamp }
    public var timestamp: String
    public var recordedAt: Date
    public var estimatedQuantity: Double

    public init(
        timestamp: String,
        recordedAt: Date,
        estimatedQuantity: Double
    ) {
        self.timestamp = timestamp
        self.recordedAt = recordedAt
        self.estimatedQuantity = estimatedQuantity
    }
}

public struct AtlasMedicationLevelDoseEvent: Identifiable, Equatable, Sendable {
    public var id: String
    public var loggedAt: Date
    public var quantityLabel: String

    public init(
        id: String,
        loggedAt: Date,
        quantityLabel: String
    ) {
        self.id = id
        self.loggedAt = loggedAt
        self.quantityLabel = quantityLabel
    }
}
