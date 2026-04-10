import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public enum AtlasPalette {
    public static let primary = Color(red: 56 / 255, green: 108 / 255, blue: 215 / 255)
    public static let primaryPressed = Color(red: 42 / 255, green: 87 / 255, blue: 181 / 255)
    public static let primaryGlow = Color(red: 120 / 255, green: 156 / 255, blue: 238 / 255)
    public static let background = Color(red: 248 / 255, green: 250 / 255, blue: 254 / 255)
    public static let canvas = Color(red: 236 / 255, green: 241 / 255, blue: 249 / 255)
    public static let canvasAccent = Color(red: 220 / 255, green: 231 / 255, blue: 246 / 255)
    public static let border = Color(red: 209 / 255, green: 219 / 255, blue: 235 / 255)
    public static let textPrimary = Color(red: 18 / 255, green: 28 / 255, blue: 45 / 255)
    public static let textSecondary = Color(red: 85 / 255, green: 98 / 255, blue: 122 / 255)
    public static let textTertiary = Color(red: 123 / 255, green: 135 / 255, blue: 156 / 255)
    public static let success = Color(red: 22 / 255, green: 128 / 255, blue: 92 / 255)
    public static let warning = Color(red: 199 / 255, green: 102 / 255, blue: 41 / 255)
    public static let shadow = Color(red: 14 / 255, green: 29 / 255, blue: 58 / 255).opacity(0.07)
    public static let secondaryFill = Color(red: 229 / 255, green: 237 / 255, blue: 251 / 255)
    public static let secondaryText = Color(red: 42 / 255, green: 78 / 255, blue: 158 / 255)
    public static let shellTop = Color(red: 27 / 255, green: 45 / 255, blue: 79 / 255)
    public static let shellTopAccent = Color(red: 53 / 255, green: 88 / 255, blue: 148 / 255)
    public static let shellGlow = Color(red: 140 / 255, green: 172 / 255, blue: 232 / 255)
    public static let shellMist = Color(red: 214 / 255, green: 226 / 255, blue: 248 / 255)
    public static let surfacePrimary = Color(red: 252 / 255, green: 253 / 255, blue: 255 / 255).opacity(0.93)
    public static let surfaceSecondary = Color(red: 244 / 255, green: 248 / 255, blue: 253 / 255).opacity(0.98)
    public static let surfaceStrong = Color(red: 252 / 255, green: 253 / 255, blue: 255 / 255).opacity(0.99)
    public static let surfaceMuted = Color(red: 239 / 255, green: 244 / 255, blue: 251 / 255).opacity(0.94)
    public static let surfaceUtility = Color(red: 233 / 255, green: 240 / 255, blue: 250 / 255).opacity(0.9)
    public static let surfaceInverse = Color(red: 35 / 255, green: 55 / 255, blue: 89 / 255)
}

public enum AtlasSpacing {
    public static let xSmall: CGFloat = 8
    public static let small: CGFloat = 12
    public static let medium: CGFloat = 16
    public static let large: CGFloat = 24
    public static let xLarge: CGFloat = 32
}

public enum AtlasSurfaceStyle {
    case `default`
    case elevated
    case utility
    case hero
}

public struct AtlasScreen<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ZStack {
            AtlasAppBackground()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: AtlasSpacing.large) {
                    content
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 44)
            }
            .scrollIndicators(.hidden)
        }
    }
}

public struct AtlasAppBackground: View {
    public init() {}

    public var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [AtlasPalette.background, AtlasPalette.canvas],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [AtlasPalette.shellTop, AtlasPalette.shellTopAccent, AtlasPalette.canvasAccent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 212)
            .ignoresSafeArea(edges: .top)

            RadialGradient(
                colors: [AtlasPalette.shellGlow.opacity(0.22), .clear],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 210
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [AtlasPalette.shellMist.opacity(0.2), .clear],
                center: .bottomLeading,
                startRadius: 36,
                endRadius: 240
            )
            .ignoresSafeArea()
        }
    }
}

public struct AtlasSectionCard<Content: View>: View {
    private let style: AtlasSurfaceStyle
    private let title: String?
    private let content: Content

    public init(
        style: AtlasSurfaceStyle = .default,
        title: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.medium) {
            if let title {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasPalette.primary)
                    .textCase(.uppercase)
            }

            content
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            cardShape
                .fill(backgroundStyle)
        )
        .overlay(
            cardShape
                .strokeBorder(strokeColor, lineWidth: 1)
        )
        .overlay(alignment: .top) {
            cardShape
                .strokeBorder(topGlow, lineWidth: 0.75)
                .mask(
                    LinearGradient(
                        colors: [.white, .white.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
        .shadow(color: Color.white.opacity(style == .hero ? 0.14 : 0.08), radius: 2, x: 0, y: -1)
        .environment(\.colorScheme, .light)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: style == .hero ? 28 : 24, style: .continuous)
    }

    private var backgroundStyle: AnyShapeStyle {
        switch style {
        case .default:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.white.opacity(0.985), AtlasPalette.surfaceSecondary],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        case .elevated:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.white, AtlasPalette.surfacePrimary, AtlasPalette.surfaceMuted],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .utility:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [AtlasPalette.surfaceSecondary, AtlasPalette.surfaceUtility],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        case .hero:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        AtlasPalette.surfaceStrong,
                        AtlasPalette.surfacePrimary,
                        AtlasPalette.secondaryFill.opacity(0.82)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private var strokeColor: Color {
        switch style {
        case .hero:
            return Color.white.opacity(0.9)
        case .elevated:
            return Color.white.opacity(0.86)
        case .utility:
            return AtlasPalette.border.opacity(0.82)
        case .default:
            return Color.white.opacity(0.78)
        }
    }

    private var topGlow: Color {
        switch style {
        case .hero:
            return Color.white.opacity(0.32)
        case .elevated:
            return Color.white.opacity(0.22)
        case .utility:
            return Color.white.opacity(0.12)
        case .default:
            return Color.white.opacity(0.16)
        }
    }

    private var shadowColor: Color {
        switch style {
        case .hero:
            return AtlasPalette.shadow.opacity(0.85)
        case .elevated:
            return AtlasPalette.shadow.opacity(0.55)
        case .utility:
            return AtlasPalette.shadow.opacity(0.32)
        case .default:
            return AtlasPalette.shadow
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .hero:
            return 28
        case .elevated:
            return 24
        case .utility:
            return 16
        case .default:
            return 18
        }
    }

    private var shadowY: CGFloat {
        switch style {
        case .hero:
            return 18
        case .elevated:
            return 14
        case .utility:
            return 10
        case .default:
            return 10
        }
    }
}

public struct AtlasStatusBadge: View {
    private let title: String
    private let tint: Color

    public init(_ title: String, tint: Color = AtlasPalette.primary) {
        self.title = title
        self.tint = tint
    }

    public var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.12))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(tint.opacity(0.14), lineWidth: 1)
            )
    }
}

public struct AtlasPrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed
                                ? [AtlasPalette.primaryPressed, AtlasPalette.primary]
                                : [AtlasPalette.primaryGlow, AtlasPalette.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.16 : 0.22), lineWidth: 1)
            )
            .shadow(
                color: AtlasPalette.primary.opacity(configuration.isPressed ? 0.18 : 0.34),
                radius: configuration.isPressed ? 8 : 18,
                x: 0,
                y: configuration.isPressed ? 4 : 10
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

public struct AtlasSecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(AtlasPalette.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed
                                ? [AtlasPalette.surfaceMuted, AtlasPalette.surfaceSecondary]
                                : [Color.white.opacity(0.98), AtlasPalette.surfaceSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(configuration.isPressed ? Color.white.opacity(0.86) : AtlasPalette.border.opacity(0.78), lineWidth: 1)
            )
            .shadow(
                color: AtlasPalette.shadow.opacity(configuration.isPressed ? 0.18 : 0.26),
                radius: configuration.isPressed ? 6 : 14,
                x: 0,
                y: configuration.isPressed ? 3 : 8
            )
            .scaleEffect(configuration.isPressed ? 0.988 : 1)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

public struct AtlasTertiaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(configuration.isPressed ? AtlasPalette.textPrimary : AtlasPalette.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(configuration.isPressed ? AtlasPalette.secondaryFill.opacity(0.62) : AtlasPalette.secondaryFill.opacity(0.42))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AtlasPalette.border.opacity(0.72), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.84), value: configuration.isPressed)
    }
}

public struct AtlasWarningButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed
                                ? [AtlasPalette.warning, AtlasPalette.warning.opacity(0.9)]
                                : [AtlasPalette.warning.opacity(0.88), AtlasPalette.warning],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(
                color: AtlasPalette.warning.opacity(configuration.isPressed ? 0.18 : 0.28),
                radius: configuration.isPressed ? 8 : 16,
                x: 0,
                y: configuration.isPressed ? 4 : 10
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

public struct AtlasGlassButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .frame(width: 50, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed
                                ? [.white.opacity(0.2), .white.opacity(0.12)]
                                : [.white.opacity(0.24), .white.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(configuration.isPressed ? 0.2 : 0.28), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.08 : 0.18), radius: configuration.isPressed ? 8 : 18, x: 0, y: configuration.isPressed ? 4 : 10)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

public struct AtlasInverseSecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed
                                ? [.white.opacity(0.2), .white.opacity(0.1)]
                                : [.white.opacity(0.18), .white.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(configuration.isPressed ? 0.18 : 0.24), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.06 : 0.12), radius: configuration.isPressed ? 6 : 12, x: 0, y: configuration.isPressed ? 3 : 8)
            .scaleEffect(configuration.isPressed ? 0.988 : 1)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

public struct AtlasChipButtonStyle: ButtonStyle {
    private let tint: Color

    public init(tint: Color = AtlasPalette.primary) {
        self.tint = tint
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(configuration.isPressed ? 0.18 : 0.16),
                                tint.opacity(configuration.isPressed ? 0.11 : 0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(tint.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: tint.opacity(configuration.isPressed ? 0.04 : 0.08), radius: configuration.isPressed ? 3 : 8, x: 0, y: configuration.isPressed ? 1 : 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.18, dampingFraction: 0.84), value: configuration.isPressed)
    }
}

public extension View {
    @ViewBuilder
    func atlasFormSurface() -> some View {
        #if os(iOS)
        self
            .foregroundStyle(AtlasPalette.textPrimary)
            .tint(AtlasPalette.primary)
            .scrollContentBackground(.hidden)
            .background(AtlasPalette.canvas)
            .environment(\.colorScheme, .light)
        #else
        self
        #endif
    }

    @ViewBuilder
    func atlasStandaloneInputSurface() -> some View {
        self
            .foregroundStyle(AtlasPalette.textPrimary)
            .tint(AtlasPalette.primary)
            .padding(.horizontal, AtlasSpacing.medium)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.98), AtlasPalette.surfaceSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AtlasPalette.border.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: AtlasPalette.shadow.opacity(0.18), radius: 10, x: 0, y: 6)
            .environment(\.colorScheme, .light)
    }
}

public enum AtlasPlatformAppearance {
    public static func configure() {
        #if canImport(UIKit)
        let textColor = UIColor(AtlasPalette.textPrimary)
        let tintColor = UIColor(AtlasPalette.primary)
        let secondaryTextColor = UIColor(AtlasPalette.textSecondary)

        UITextField.appearance().textColor = textColor
        UITextField.appearance().tintColor = tintColor

        UITextView.appearance().textColor = textColor
        UITextView.appearance().tintColor = tintColor
        UITextView.appearance().backgroundColor = .clear

        UISegmentedControl.appearance().selectedSegmentTintColor = tintColor
        UISegmentedControl.appearance().backgroundColor = UIColor(AtlasPalette.surfaceMuted)
        UISegmentedControl.appearance().setTitleTextAttributes(
            [
                .foregroundColor: secondaryTextColor,
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
            ],
            for: .normal
        )
        UISegmentedControl.appearance().setTitleTextAttributes(
            [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 13, weight: .bold)
            ],
            for: .selected
        )

        UISwitch.appearance().onTintColor = tintColor
        UISlider.appearance().minimumTrackTintColor = tintColor
        UISlider.appearance().maximumTrackTintColor = UIColor(AtlasPalette.border)
        #endif
    }
}
