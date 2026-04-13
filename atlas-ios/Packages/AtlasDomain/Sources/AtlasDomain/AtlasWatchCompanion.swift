import Foundation

public enum AtlasWatchCompanionContextShortcut: String, Codable, CaseIterable, Sendable {
    case hydration
    case lowAppetite
    case giCheckIn

    public var title: String {
        switch self {
        case .hydration:
            return "Hydration"
        case .lowAppetite:
            return "Low appetite"
        case .giCheckIn:
            return "GI check-in"
        }
    }

    public var detail: String {
        switch self {
        case .hydration:
            return "Fast hydration signal"
        case .lowAppetite:
            return "Quick appetite signal"
        case .giCheckIn:
            return "Open a fuller recovery note"
        }
    }

    public var symbolName: String {
        switch self {
        case .hydration:
            return "drop.fill"
        case .lowAppetite:
            return "fork.knife"
        case .giCheckIn:
            return "waveform.path.ecg"
        }
    }
}

public struct AtlasSharedWatchCompanionSnapshot: Codable, Equatable, Sendable {
    public var generatedAt: String
    public var headline: String
    public var summary: String
    public var nextDueTitle: String?
    public var nextDueDetail: String?
    public var recoverySummary: String?
    public var quickContextShortcuts: [AtlasWatchCompanionContextShortcut]

    public init(
        generatedAt: String,
        headline: String,
        summary: String,
        nextDueTitle: String? = nil,
        nextDueDetail: String? = nil,
        recoverySummary: String? = nil,
        quickContextShortcuts: [AtlasWatchCompanionContextShortcut] = AtlasWatchCompanionContextShortcut.allCases
    ) {
        self.generatedAt = generatedAt
        self.headline = headline
        self.summary = summary
        self.nextDueTitle = nextDueTitle
        self.nextDueDetail = nextDueDetail
        self.recoverySummary = recoverySummary
        self.quickContextShortcuts = quickContextShortcuts
    }
}
