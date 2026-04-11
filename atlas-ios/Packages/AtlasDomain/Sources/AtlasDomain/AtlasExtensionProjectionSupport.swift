import Foundation

public enum AtlasExtensionProjectionSurface: String, Equatable, Sendable {
    case nextDueWidget
    case lowStockWidget
    case nextDueIntent

    public var staleAfter: TimeInterval {
        switch self {
        case .nextDueWidget, .nextDueIntent:
            return 2 * 60 * 60
        case .lowStockWidget:
            return 12 * 60 * 60
        }
    }
}

public struct AtlasExtensionProjectionFreshness: Equatable, Sendable {
    public var surface: AtlasExtensionProjectionSurface
    public var generatedAt: Date?
    public var referenceDate: Date

    public init(
        surface: AtlasExtensionProjectionSurface,
        generatedAt: Date?,
        referenceDate: Date = Date()
    ) {
        self.surface = surface
        self.generatedAt = generatedAt
        self.referenceDate = referenceDate
    }

    public var age: TimeInterval? {
        guard let generatedAt else {
            return nil
        }
        return max(referenceDate.timeIntervalSince(generatedAt), 0)
    }

    public var isStale: Bool {
        guard let age else {
            return true
        }
        return age >= surface.staleAfter
    }
}

public extension AtlasSharedExtensionProjectionSnapshot {
    func freshness(
        for surface: AtlasExtensionProjectionSurface,
        referenceDate: Date = Date()
    ) -> AtlasExtensionProjectionFreshness {
        AtlasExtensionProjectionFreshness(
            surface: surface,
            generatedAt: ISO8601DateFormatter.atlas.date(from: generatedAt),
            referenceDate: referenceDate
        )
    }
}
