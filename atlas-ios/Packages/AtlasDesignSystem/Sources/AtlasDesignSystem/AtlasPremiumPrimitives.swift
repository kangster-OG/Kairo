import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(CoreText)
import CoreText
#endif

public enum AtlasTypographyCandidate: String, CaseIterable, Sendable {
    case system
    case avenir
    case plex

    static var current: AtlasTypographyCandidate {
        let environmentValue = ProcessInfo.processInfo.environment["ATLAS_TYPOGRAPHY_CANDIDATE"]
        let argumentValue = ProcessInfo.processInfo.arguments.adjacentValue(after: "-AtlasTypographyCandidate")
        return AtlasTypographyCandidate(rawValue: argumentValue ?? environmentValue ?? "") ?? .avenir
    }
}

public enum AtlasTypography {
    public static var currentCandidate: AtlasTypographyCandidate {
        AtlasTypographyCandidate.current
    }

    @MainActor
    public static func registerCustomFonts() {
        guard AtlasTypographyCandidate.current == .plex else {
            return
        }
        AtlasPlexFontRegistrar.registerIfNeeded()
    }

    public static func font(for role: AtlasTextRole) -> Font {
        switch AtlasTypographyCandidate.current {
        case .system:
            return role.systemFont
        case .avenir:
            return role.avenirFont
        case .plex:
            return role.plexFont
        }
    }

    public static func brandFont(
        size: CGFloat,
        weight: Font.Weight,
        relativeTo textStyle: Font.TextStyle = .title
    ) -> Font {
        switch AtlasTypographyCandidate.current {
        case .system:
            return .system(size: size, weight: weight, design: .rounded)
        case .avenir:
            return Font.custom(avenirName(for: weight), size: size, relativeTo: textStyle)
        case .plex:
            return Font.custom(plexName(for: weight), size: size, relativeTo: textStyle)
        }
    }

    fileprivate static func avenirName(for weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black:
            return "AvenirNext-Bold"
        case .medium:
            return "AvenirNext-Medium"
        default:
            return "AvenirNext-DemiBold"
        }
    }

    fileprivate static func plexName(for weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black:
            return "IBMPlexSans-Bold"
        case .medium:
            return "IBMPlexSans-Medm"
        case .semibold:
            return "IBMPlexSans-SmBld"
        default:
            return "IBMPlexSans"
        }
    }
}

public enum AtlasTextRole {
    case screenTitle
    case screenSubtitle
    case deckEyebrow
    case cardTitle
    case cardBody
    case supporting
    case metricValue
    case metricLabel

    fileprivate var systemFont: Font {
        switch self {
        case .screenTitle:
            return .system(size: 34, weight: .bold, design: .rounded)
        case .screenSubtitle:
            return .body.weight(.medium)
        case .deckEyebrow:
            return .caption.weight(.semibold)
        case .cardTitle:
            return .title3.weight(.bold)
        case .cardBody:
            return .body.weight(.semibold)
        case .supporting:
            return .caption.weight(.medium)
        case .metricValue:
            return .title3.weight(.bold)
        case .metricLabel:
            return .caption2.weight(.semibold)
        }
    }

    fileprivate var avenirFont: Font {
        switch self {
        case .screenTitle:
            return Font.custom("AvenirNext-Bold", size: 34, relativeTo: .largeTitle)
        case .screenSubtitle:
            return .body.weight(.medium)
        case .deckEyebrow:
            return Font.custom("AvenirNext-DemiBold", size: 12, relativeTo: .caption)
        case .cardTitle:
            return Font.custom("AvenirNext-Bold", size: 20, relativeTo: .title3)
        case .cardBody:
            return .body.weight(.semibold)
        case .supporting:
            return .caption.weight(.medium)
        case .metricValue:
            return Font.custom("AvenirNext-Bold", size: 20, relativeTo: .title3)
        case .metricLabel:
            return Font.custom("AvenirNext-DemiBold", size: 11, relativeTo: .caption2)
        }
    }

    fileprivate var plexFont: Font {
        switch self {
        case .screenTitle:
            return Font.custom("IBMPlexSans-Bold", size: 34, relativeTo: .largeTitle)
        case .screenSubtitle:
            return Font.custom("IBMPlexSans-Medm", size: 17, relativeTo: .body)
        case .deckEyebrow:
            return Font.custom("IBMPlexSans-SmBld", size: 12, relativeTo: .caption)
        case .cardTitle:
            return Font.custom("IBMPlexSans-Bold", size: 20, relativeTo: .title3)
        case .cardBody:
            return Font.custom("IBMPlexSans-SmBld", size: 17, relativeTo: .body)
        case .supporting:
            return Font.custom("IBMPlexSans-Medm", size: 12, relativeTo: .caption)
        case .metricValue:
            return Font.custom("IBMPlexSans-Bold", size: 20, relativeTo: .title3)
        case .metricLabel:
            return Font.custom("IBMPlexSans-SmBld", size: 11, relativeTo: .caption2)
        }
    }

    fileprivate var tracking: CGFloat {
        return 0
    }

    fileprivate var textCase: Text.Case? {
        switch self {
        case .deckEyebrow, .metricLabel:
            return .uppercase
        default:
            return nil
        }
    }
}

public extension View {
    func atlasTextRole(_ role: AtlasTextRole) -> some View {
        self
            .font(AtlasTypography.font(for: role))
            .tracking(role.tracking)
            .textCase(role.textCase)
    }
}

private extension [String] {
    func adjacentValue(after flag: String) -> String? {
        guard let index = firstIndex(of: flag) else {
            return nil
        }
        let valueIndex = self.index(after: index)
        guard indices.contains(valueIndex) else {
            return nil
        }
        return self[valueIndex]
    }
}

@MainActor
private enum AtlasPlexFontRegistrar {
    private static let fontResources = [
        "IBMPlexSans-Regular",
        "IBMPlexSans-Medium",
        "IBMPlexSans-SemiBold",
        "IBMPlexSans-Bold"
    ]
    private static var didRegister = false

    static func registerIfNeeded() {
        guard !didRegister else {
            return
        }
        didRegister = true

        #if canImport(CoreText)
        fontResources.forEach { resource in
            guard let url = Bundle.module.url(
                forResource: resource,
                withExtension: "ttf",
                subdirectory: "Fonts/IBMPlexSans"
            ) else {
                return
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        #endif
    }
}

public enum AtlasFeedback {
    public static func selection() {
        #if canImport(UIKit)
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        #endif
    }

    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    public static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
        #endif
    }

    public static func navigation() {
        #if canImport(UIKit)
        impact(.soft)
        #endif
    }

    public static func toggleChanged(isOn: Bool) {
        #if canImport(UIKit)
        impact(isOn ? .light : .soft)
        #endif
    }

    public static func caution() {
        #if canImport(UIKit)
        notify(.warning)
        #endif
    }

    public static func milestoneReveal() {
        #if canImport(UIKit)
        impact(.soft)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            impact(.rigid)
        }
        #endif
    }

    public static func levelUp() {
        #if canImport(UIKit)
        impact(.rigid)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            notify(.success)
        }
        #endif
    }

    public static func weeklyCloseout() {
        #if canImport(UIKit)
        impact(.medium)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            notify(.success)
        }
        #endif
    }

    public static func mascotMoment() {
        #if canImport(UIKit)
        impact(.light)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            selection()
        }
        #endif
    }
}

private struct AtlasAnimatedMetricValueText: View {
    let value: String
    let role: AtlasTextRole
    let foregroundStyle: Color

    @State private var displayedNumericValue: Double?

    var body: some View {
        Group {
            if let numericValue = parsedNumericValue {
                Text(formattedNumericValue(from: displayedNumericValue ?? numericValue))
                    .contentTransition(.numericText(value: displayedNumericValue ?? numericValue))
                    .monospacedDigit()
                    .task {
                        displayedNumericValue = numericValue
                    }
                    .onChange(of: numericValue) { _, newValue in
                        withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                            displayedNumericValue = newValue
                        }
                    }
            } else {
                Text(value)
            }
        }
        .atlasTextRole(role)
        .foregroundStyle(foregroundStyle)
    }

    private var parsedNumericValue: Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitized = trimmed.replacingOccurrences(of: ",", with: "")
        if let percentage = sanitized.dropLastIfPercent, let numeric = Double(percentage) {
            return numeric
        }
        return Double(sanitized)
    }

    private func formattedNumericValue(from numericValue: Double) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let isPercent = trimmed.hasSuffix("%")
        let usesIntegerFormatting = abs(numericValue.rounded() - numericValue) < 0.001
        let formatted: String
        if usesIntegerFormatting {
            formatted = String(Int(numericValue.rounded()))
        } else {
            formatted = numericValue.formatted(.number.precision(.fractionLength(1)))
        }
        return isPercent ? "\(formatted)%" : formatted
    }
}

private extension String {
    var dropLastIfPercent: String? {
        if hasSuffix("%") {
            return String(dropLast())
        }
        return self
    }
}

public struct AtlasMetricItem: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let value: String
    public let tint: Color

    public init(
        id: String,
        title: String,
        value: String,
        tint: Color = AtlasPalette.primary
    ) {
        self.id = id
        self.title = title
        self.value = value
        self.tint = tint
    }
}

public struct AtlasMetricStrip: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let metrics: [AtlasMetricItem]
    private let fittedMetricLimit = 3

    public init(metrics: [AtlasMetricItem]) {
        self.metrics = metrics
    }

    public var body: some View {
        if metrics.isEmpty == false {
            if metrics.count <= fittedMetricLimit {
                HStack(spacing: AtlasSpacing.small) {
                    metricCards(fitted: true)
                }
                .padding(.vertical, 2)
            } else if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: AtlasSpacing.small) {
                    metricCards(fitted: false)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AtlasSpacing.small) {
                        metricCards(fitted: false)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    @ViewBuilder
    private func metricCards(fitted: Bool) -> some View {
        ForEach(metrics) { metric in
            VStack(alignment: .leading, spacing: 4) {
                Text(metric.title)
                    .atlasTextRole(.metricLabel)
                    .foregroundStyle(metric.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(fitted ? 0.68 : 1)

                AtlasAnimatedMetricValueText(
                    value: metric.value,
                    role: .metricValue,
                    foregroundStyle: AtlasPalette.textPrimary
                )
                .lineLimit(1)
                .minimumScaleFactor(fitted ? 0.76 : 1)
            }
            .frame(
                minWidth: fitted ? 0 : 88,
                maxWidth: fitted || dynamicTypeSize.isAccessibilitySize ? .infinity : nil,
                alignment: .leading
            )
            .padding(.horizontal, fitted ? 10 : 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AtlasPalette.surfaceTop.opacity(0.95), metric.tint.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(metric.tint.opacity(0.14), lineWidth: 1)
            )
        }
    }
}

public struct AtlasProgressMeter: View {
    private let title: String?
    private let detail: String?
    private let value: Double
    private let tint: Color
    @State private var animatedValue: Double = 0

    public init(
        title: String? = nil,
        detail: String? = nil,
        value: Double,
        tint: Color = AtlasPalette.primary
    ) {
        self.title = title
        self.detail = detail
        self.value = value
        self.tint = tint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.xSmall) {
            if let title {
                Text(title)
                    .atlasTextRole(.deckEyebrow)
                    .foregroundStyle(tint)
            }

            GeometryReader { proxy in
                let clamped = min(max(animatedValue, 0), 1)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(AtlasPalette.border.opacity(0.45))

                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.68), tint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(proxy.size.width * clamped, clamped > 0 ? 10 : 0))
                }
            }
            .frame(height: 12)
            .task {
                animatedValue = min(max(value, 0), 1)
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.72, dampingFraction: 0.82)) {
                    animatedValue = min(max(newValue, 0), 1)
                }
            }

            if let detail {
                Text(detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
            }
        }
    }
}

public struct AtlasMilestoneRevealBanner: View {
    private let eyebrow: String
    private let title: String
    private let detail: String?
    private let tint: Color
    private let badge: String?
    private let symbolName: String

    @State private var revealed = false

    public init(
        eyebrow: String,
        title: String,
        detail: String? = nil,
        tint: Color = AtlasPalette.reward,
        badge: String? = nil,
        symbolName: String = "sparkles"
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.detail = detail
        self.tint = tint
        self.badge = badge
        self.symbolName = symbolName
    }

    public var body: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.24), AtlasPalette.surfaceTop.opacity(0.96)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: symbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .scaleEffect(revealed ? 1 : 0.82)
            }
            .frame(width: 48, height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: tint.opacity(revealed ? 0.2 : 0.08), radius: revealed ? 14 : 6, x: 0, y: revealed ? 10 : 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AtlasSpacing.small) {
                    Text(eyebrow)
                        .atlasTextRole(.deckEyebrow)
                        .foregroundStyle(tint)
                    if let badge {
                        AtlasStatusBadge(badge, tint: tint)
                    }
                }

                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)

                if let detail, detail.isEmpty == false {
                    Text(detail)
                        .atlasTextRole(.supporting)
                        .foregroundStyle(AtlasPalette.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AtlasPalette.surfaceTop.opacity(0.96), tint.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tint.opacity(0.14), lineWidth: 1)
        )
        .scaleEffect(revealed ? 1 : 0.96)
        .opacity(revealed ? 1 : 0.24)
        .offset(y: revealed ? 0 : 10)
        .task {
            guard revealed == false else { return }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.82).delay(0.05)) {
                revealed = true
            }
        }
    }
}

public struct AtlasCalloutRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let systemImage: String
    private let title: String
    private let detail: String?
    private let tint: Color
    private let badge: String?
    private let titleLineLimit: Int?

    public init(
        systemImage: String,
        title: String,
        detail: String? = nil,
        tint: Color = AtlasPalette.primary,
        badge: String? = nil,
        titleLineLimit: Int? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.detail = detail
        self.tint = tint
        self.badge = badge
        self.titleLineLimit = titleLineLimit
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                    iconBadge
                    textBlock
                }
            } else {
                HStack(alignment: .top, spacing: AtlasSpacing.small) {
                    iconBadge
                    textBlock
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var iconBadge: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [AtlasPalette.surfaceTop, tint.opacity(0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 42, height: 42)
            .overlay(
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AtlasPalette.chromeStroke, lineWidth: 1)
            )
    }

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: AtlasSpacing.small) {
                Text(title)
                    .atlasTextRole(.cardBody)
                    .foregroundStyle(AtlasPalette.textPrimary)
                    .lineLimit(titleLineLimit)
                    .minimumScaleFactor(titleLineLimit == nil ? 1 : 0.82)

                if let badge {
                    AtlasStatusBadge(badge, tint: tint)
                }
            }

            if let detail, detail.isEmpty == false {
                Text(detail)
                    .atlasTextRole(.supporting)
                    .foregroundStyle(AtlasPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

public struct AtlasCommandDeck<Actions: View, Footer: View>: View {
    private let eyebrow: String?
    private let title: String
    private let detail: String?
    private let metrics: [AtlasMetricItem]
    private let tint: Color
    private let style: AtlasSurfaceStyle
    private let actions: Actions
    private let footer: Footer

    public init(
        eyebrow: String? = nil,
        title: String,
        detail: String? = nil,
        metrics: [AtlasMetricItem] = [],
        tint: Color = AtlasPalette.primary,
        style: AtlasSurfaceStyle = .hero,
        @ViewBuilder actions: () -> Actions,
        @ViewBuilder footer: () -> Footer
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.detail = detail
        self.metrics = metrics
        self.tint = tint
        self.style = style
        self.actions = actions()
        self.footer = footer()
    }

    public var body: some View {
        AtlasSectionCard(style: style) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: AtlasSpacing.small) {
                    if let eyebrow {
                        Text(eyebrow)
                            .atlasTextRole(.deckEyebrow)
                            .foregroundStyle(tint)
                    }

                    Text(title)
                        .atlasTextRole(style == .hero ? .screenTitle : .cardTitle)
                        .foregroundStyle(AtlasPalette.textPrimary)

                    if let detail, detail.isEmpty == false {
                        Text(detail)
                            .atlasTextRole(style == .hero ? .screenSubtitle : .supporting)
                            .foregroundStyle(AtlasPalette.textSecondary)
                    }
                }

                AtlasMetricStrip(metrics: metrics)
                actions
                footer
            }
        }
    }
}

public struct AtlasTactileTileButtonStyle: ButtonStyle {
    private let tint: Color

    public init(tint: Color = AtlasPalette.primary) {
        self.tint = tint
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed
                                ? [AtlasPalette.surfaceTop.opacity(0.95), AtlasPalette.surfaceMuted]
                                : [AtlasPalette.surfaceTop, AtlasPalette.surfaceSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(tint.opacity(configuration.isPressed ? 0.12 : 0.18), lineWidth: 1)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AtlasPalette.chromeStrokeSoft.opacity(configuration.isPressed ? 0.72 : 1), lineWidth: 1)
                    .mask(
                        LinearGradient(
                            colors: [.white, .white.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .shadow(color: AtlasPalette.shadow.opacity(configuration.isPressed ? 0.12 : 0.22), radius: configuration.isPressed ? 8 : 14, x: 0, y: configuration.isPressed ? 5 : 10)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.82), value: configuration.isPressed)
    }
}
