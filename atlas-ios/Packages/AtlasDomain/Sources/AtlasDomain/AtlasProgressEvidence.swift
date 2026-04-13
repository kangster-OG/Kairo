import Foundation

public enum AtlasProgressMeasurementKind: String, Codable, CaseIterable, Equatable, Sendable, Identifiable {
    case waist
    case hips
    case chest
    case thigh
    case arm
    case bodyFat

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .waist: "Waist"
        case .hips: "Hips"
        case .chest: "Chest"
        case .thigh: "Thigh"
        case .arm: "Arm"
        case .bodyFat: "Body fat"
        }
    }

    public var defaultUnit: String {
        switch self {
        case .bodyFat:
            return "%"
        default:
            return "in"
        }
    }
}

public enum AtlasProgressPhotoAngle: String, Codable, CaseIterable, Equatable, Sendable, Identifiable {
    case front
    case side
    case back
    case detail

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .front: "Front"
        case .side: "Side"
        case .back: "Back"
        case .detail: "Detail"
        }
    }
}

public struct AtlasProgressMeasurementDraft: Equatable, Sendable {
    public var id: String?
    public var protocolID: String?
    public var kind: AtlasProgressMeasurementKind
    public var value: Double
    public var unit: String
    public var note: String?
    public var loggedAt: Date

    public init(
        id: String? = nil,
        protocolID: String? = nil,
        kind: AtlasProgressMeasurementKind = .waist,
        value: Double = 0,
        unit: String? = nil,
        note: String? = nil,
        loggedAt: Date = Date()
    ) {
        self.id = id
        self.protocolID = protocolID
        self.kind = kind
        self.value = value
        self.unit = unit ?? kind.defaultUnit
        self.note = note
        self.loggedAt = loggedAt
    }
}

public struct AtlasProgressPhotoDraft: Equatable, Sendable {
    public var id: String?
    public var protocolID: String?
    public var angle: AtlasProgressPhotoAngle
    public var note: String?
    public var loggedAt: Date
    public var jpegData: Data

    public init(
        id: String? = nil,
        protocolID: String? = nil,
        angle: AtlasProgressPhotoAngle = .front,
        note: String? = nil,
        loggedAt: Date = Date(),
        jpegData: Data
    ) {
        self.id = id
        self.protocolID = protocolID
        self.angle = angle
        self.note = note
        self.loggedAt = loggedAt
        self.jpegData = jpegData
    }
}

public struct AtlasProgressMeasurementRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var protocolID: String?
    public var kind: AtlasProgressMeasurementKind
    public var value: Double
    public var unit: String
    public var note: String?
    public var loggedAt: String
    public var createdAt: String
    public var updatedAt: String

    public init(
        id: String,
        protocolID: String?,
        kind: AtlasProgressMeasurementKind,
        value: Double,
        unit: String,
        note: String?,
        loggedAt: String,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.protocolID = protocolID
        self.kind = kind
        self.value = value
        self.unit = unit
        self.note = note
        self.loggedAt = loggedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct AtlasProgressPhotoRecord: Codable, Equatable, Sendable, Identifiable {
    public var id: String
    public var protocolID: String?
    public var angle: AtlasProgressPhotoAngle
    public var note: String?
    public var relativeAssetPath: String
    public var loggedAt: String
    public var createdAt: String
    public var updatedAt: String

    public init(
        id: String,
        protocolID: String?,
        angle: AtlasProgressPhotoAngle,
        note: String?,
        relativeAssetPath: String,
        loggedAt: String,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.protocolID = protocolID
        self.angle = angle
        self.note = note
        self.relativeAssetPath = relativeAssetPath
        self.loggedAt = loggedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct AtlasProgressMeasurementTrendPoint: Identifiable, Equatable, Sendable {
    public var id: String { timestamp }
    public var timestamp: String
    public var loggedAt: Date
    public var value: Double

    public init(timestamp: String, loggedAt: Date, value: Double) {
        self.timestamp = timestamp
        self.loggedAt = loggedAt
        self.value = value
    }
}

public struct AtlasProgressMeasurementTrend: Identifiable, Equatable, Sendable {
    public var id: AtlasProgressMeasurementKind { kind }
    public var kind: AtlasProgressMeasurementKind
    public var unit: String
    public var latestLabel: String?
    public var changeLabel: String?
    public var points: [AtlasProgressMeasurementTrendPoint]

    public init(
        kind: AtlasProgressMeasurementKind,
        unit: String,
        latestLabel: String? = nil,
        changeLabel: String? = nil,
        points: [AtlasProgressMeasurementTrendPoint] = []
    ) {
        self.kind = kind
        self.unit = unit
        self.latestLabel = latestLabel
        self.changeLabel = changeLabel
        self.points = points
    }
}

public struct AtlasProgressPhotoEntrySummary: Identifiable, Equatable, Sendable {
    public var id: String
    public var angle: AtlasProgressPhotoAngle
    public var note: String?
    public var loggedAt: Date
    public var absolutePath: String

    public init(
        id: String,
        angle: AtlasProgressPhotoAngle,
        note: String?,
        loggedAt: Date,
        absolutePath: String
    ) {
        self.id = id
        self.angle = angle
        self.note = note
        self.loggedAt = loggedAt
        self.absolutePath = absolutePath
    }
}

public struct AtlasProgressEvidenceSnapshot: Equatable, Sendable {
    public var summaryTitle: String
    public var summaryText: String
    public var measurementTrends: [AtlasProgressMeasurementTrend]
    public var recentMeasurements: [AtlasProgressMeasurementRecord]
    public var recentPhotos: [AtlasProgressPhotoEntrySummary]
    public var comparisonNote: String?

    public init(
        summaryTitle: String = "Progress evidence",
        summaryText: String = "Add measurements and private photo check-ins to keep a calmer record of visible change over time.",
        measurementTrends: [AtlasProgressMeasurementTrend] = [],
        recentMeasurements: [AtlasProgressMeasurementRecord] = [],
        recentPhotos: [AtlasProgressPhotoEntrySummary] = [],
        comparisonNote: String? = nil
    ) {
        self.summaryTitle = summaryTitle
        self.summaryText = summaryText
        self.measurementTrends = measurementTrends
        self.recentMeasurements = recentMeasurements
        self.recentPhotos = recentPhotos
        self.comparisonNote = comparisonNote
    }
}
