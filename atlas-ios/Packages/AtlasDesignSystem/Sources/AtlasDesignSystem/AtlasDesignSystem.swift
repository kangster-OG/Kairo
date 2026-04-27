import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public enum AtlasPalette {
    #if canImport(UIKit)
    private static func adaptive(
        light: (CGFloat, CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat, CGFloat)
    ) -> Color {
        Color(
            UIColor { traits in
                let values = traits.userInterfaceStyle == .dark ? dark : light
                return UIColor(
                    red: values.0 / 255,
                    green: values.1 / 255,
                    blue: values.2 / 255,
                    alpha: values.3
                )
            }
        )
    }
    #else
    private static func adaptive(
        light: (CGFloat, CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat, CGFloat)
    ) -> Color {
        Color(
            red: light.0 / 255,
            green: light.1 / 255,
            blue: light.2 / 255,
            opacity: light.3
        )
    }
    #endif

    public static let primary = adaptive(light: (31, 111, 91, 1), dark: (83, 193, 161, 1))
    public static let primaryPressed = adaptive(light: (20, 88, 72, 1), dark: (57, 164, 132, 1))
    public static let primaryGlow = adaptive(light: (118, 196, 171, 1), dark: (126, 224, 191, 1))
    public static let reward = adaptive(light: (192, 139, 39, 1), dark: (216, 170, 72, 1))
    public static let rewardPressed = adaptive(light: (164, 117, 28, 1), dark: (188, 145, 52, 1))
    public static let rewardGlow = adaptive(light: (231, 194, 110, 1), dark: (241, 205, 126, 1))
    public static let background = adaptive(light: (250, 248, 244, 1), dark: (10, 13, 14, 1))
    public static let canvas = adaptive(light: (244, 241, 236, 1), dark: (16, 22, 22, 1))
    public static let canvasAccent = adaptive(light: (238, 235, 228, 1), dark: (24, 35, 34, 1))
    public static let border = adaptive(light: (226, 220, 211, 1), dark: (82, 101, 96, 1))
    public static let textPrimary = adaptive(light: (24, 31, 30, 1), dark: (248, 251, 248, 1))
    public static let textSecondary = adaptive(light: (89, 94, 91, 1), dark: (209, 220, 215, 1))
    public static let textTertiary = adaptive(light: (126, 132, 128, 1), dark: (178, 196, 188, 1))
    public static let success = adaptive(light: (22, 128, 92, 1), dark: (62, 182, 132, 1))
    public static let warning = adaptive(light: (199, 102, 41, 1), dark: (232, 136, 72, 1))
    public static let shadow = adaptive(light: (14, 29, 58, 0.07), dark: (0, 0, 0, 0.42))
    public static let secondaryFill = adaptive(light: (237, 243, 239, 1), dark: (24, 45, 39, 1))
    public static let secondaryText = adaptive(light: (34, 96, 81, 1), dark: (171, 224, 204, 1))
    public static let shellTop = adaptive(light: (250, 248, 244, 1), dark: (8, 12, 12, 1))
    public static let shellTopAccent = adaptive(light: (246, 243, 237, 1), dark: (16, 26, 25, 1))
    public static let shellGlow = adaptive(light: (205, 222, 213, 1), dark: (69, 140, 119, 1))
    public static let shellMist = adaptive(light: (240, 237, 230, 1), dark: (40, 68, 61, 1))
    public static let surfacePrimary = adaptive(light: (255, 254, 251, 0.96), dark: (20, 29, 28, 0.96))
    public static let surfaceSecondary = adaptive(light: (247, 244, 239, 0.98), dark: (25, 37, 35, 0.98))
    public static let surfaceStrong = adaptive(light: (255, 255, 253, 0.99), dark: (31, 45, 42, 0.98))
    public static let surfaceMuted = adaptive(light: (241, 238, 232, 0.96), dark: (19, 31, 29, 0.96))
    public static let surfaceUtility = adaptive(light: (236, 232, 224, 0.92), dark: (16, 27, 25, 0.94))
    public static let surfaceInverse = adaptive(light: (45, 43, 37, 1), dark: (231, 238, 234, 1))
    public static let surfaceTop = adaptive(light: (255, 255, 253, 0.99), dark: (35, 52, 48, 0.98))
    public static let chromeStroke = adaptive(light: (255, 255, 255, 0.88), dark: (119, 145, 196, 0.22))
    public static let chromeStrokeSoft = adaptive(light: (255, 255, 255, 0.18), dark: (255, 255, 255, 0.06))
    public static let innerLift = adaptive(light: (255, 255, 255, 0.12), dark: (94, 126, 188, 0.12))
    public static let heroGlow = adaptive(light: (255, 255, 255, 0.32), dark: (120, 158, 230, 0.22))
    public static let elevatedGlow = adaptive(light: (255, 255, 255, 0.22), dark: (98, 126, 182, 0.16))
    public static let softGlow = adaptive(light: (255, 255, 255, 0.16), dark: (255, 255, 255, 0.05))
    public static let utilityGlow = adaptive(light: (255, 255, 255, 0.12), dark: (255, 255, 255, 0.04))
    public static let taskGlow = adaptive(light: (255, 255, 255, 0.24), dark: (126, 156, 220, 0.18))
    public static let glassFillStrong = adaptive(light: (255, 255, 255, 0.24), dark: (61, 85, 128, 0.42))
    public static let glassFillSoft = adaptive(light: (255, 255, 255, 0.12), dark: (27, 41, 68, 0.3))
    public static let controlKnob = adaptive(light: (255, 255, 255, 1), dark: (236, 242, 252, 1))
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
    case task
    case reward
}

public enum AtlasMotion {
    public static let interactiveSpring = Animation.spring(response: 0.24, dampingFraction: 0.84)
    public static let tabSwitch = Animation.spring(response: 0.32, dampingFraction: 0.88)

    public static func screenEntry(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.16) : .spring(response: 0.38, dampingFraction: 0.9)
    }

    public static func scrollToTop(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.14) : .spring(response: 0.28, dampingFraction: 0.9)
    }
}

public enum AtlasKeyboardControl {
    @MainActor
    public static func dismiss() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
    }
}

public struct AtlasScreen<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasEntered = false
    private let content: Content
    private let dismissKeyboardImmediately: Bool
    private let keyboardDoneAccessory: Bool

    public init(
        dismissKeyboardImmediately: Bool = false,
        keyboardDoneAccessory: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.dismissKeyboardImmediately = dismissKeyboardImmediately
        self.keyboardDoneAccessory = keyboardDoneAccessory
    }

    public var body: some View {
        ZStack {
            AtlasAppBackground()

            scrollContent
        }
        .opacity(hasEntered ? 1 : 0.01)
        .offset(y: hasEntered || reduceMotion ? 0 : 14)
        .scaleEffect(hasEntered || reduceMotion ? 1 : 0.994, anchor: .top)
        .onAppear {
            guard hasEntered == false else {
                return
            }
            withAnimation(AtlasMotion.screenEntry(reduceMotion: reduceMotion)) {
                hasEntered = true
            }
        }
        .atlasKeyboardDoneAccessory(enabled: keyboardDoneAccessory)
    }

    private var scrollContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AtlasSpacing.medium) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 44)
        }
        .scrollIndicators(.hidden)
        #if os(iOS)
        .scrollDismissesKeyboard(dismissKeyboardImmediately ? .immediately : .interactively)
        #else
        .scrollDismissesKeyboard(.interactively)
        #endif
    }
}

public extension View {
    @ViewBuilder
    func atlasKeyboardDoneAccessory(
        enabled: Bool = true,
        onDone: (() -> Void)? = nil
    ) -> some View {
        if enabled {
            modifier(
                AtlasKeyboardAccessoryModifier(
                    onCancel: nil,
                    onSave: nil,
                    onDone: onDone
                )
            )
        } else {
            self
        }
    }

    @ViewBuilder
    func atlasKeyboardCommitAccessory(
        enabled: Bool = true,
        onCancel: (() -> Void)? = nil,
        onSave: (() -> Void)? = nil,
        onDone: (() -> Void)? = nil
    ) -> some View {
        if enabled {
            modifier(
                AtlasKeyboardAccessoryModifier(
                    onCancel: onCancel,
                    onSave: onSave,
                    onDone: onDone
                )
            )
        } else {
            self
        }
    }
}

private struct AtlasKeyboardAccessoryModifier: ViewModifier {
    let onCancel: (() -> Void)?
    let onSave: (() -> Void)?
    let onDone: (() -> Void)?

    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if let onCancel {
                        Button("Cancel") {
                            onCancel()
                            AtlasKeyboardControl.dismiss()
                        }
                    }

                    Spacer()

                    if let onSave {
                        Button("Save") {
                            onSave()
                            AtlasKeyboardControl.dismiss()
                        }
                    }

                    Button("Done") {
                        onDone?()
                        AtlasKeyboardControl.dismiss()
                    }
                }
            }
        #else
        content
        #endif
    }
}

public struct AtlasAppBackground: View {
    public init() {}

    public var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [AtlasPalette.background, AtlasPalette.canvas, AtlasPalette.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [AtlasPalette.shellTop, AtlasPalette.shellTopAccent, AtlasPalette.background.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 118)
            .ignoresSafeArea(edges: .top)

            RadialGradient(
                colors: [AtlasPalette.shellGlow.opacity(0.14), .clear],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 190
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [AtlasPalette.shellMist.opacity(0.16), .clear],
                center: .bottomLeading,
                startRadius: 36,
                endRadius: 240
            )
            .ignoresSafeArea()
        }
    }
}

public struct AtlasSectionCard<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
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
        VStack(alignment: .leading, spacing: AtlasSpacing.small) {
            if let title {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasPalette.primary)
                    
            }

            content
        }
        .padding(14)
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
        .shadow(color: AtlasPalette.innerLift.opacity(style == .hero ? 1 : 0.75), radius: 2, x: 0, y: -1)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
    }

    private var backgroundStyle: AnyShapeStyle {
        if reduceTransparency || colorSchemeContrast == .increased {
            return AnyShapeStyle(accessibleSurfaceColor)
        }

        switch style {
        case .default:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [AtlasPalette.surfaceTop, AtlasPalette.surfaceSecondary],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        case .elevated:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [AtlasPalette.surfaceTop, AtlasPalette.surfacePrimary, AtlasPalette.surfaceMuted],
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
        case .task:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        AtlasPalette.surfaceTop,
                        AtlasPalette.surfacePrimary,
                        AtlasPalette.surfaceMuted.opacity(0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .reward:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        AtlasPalette.surfaceTop,
                        AtlasPalette.rewardGlow.opacity(0.18),
                        AtlasPalette.secondaryFill.opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private var strokeColor: Color {
        if colorSchemeContrast == .increased {
            return AtlasPalette.primary.opacity(style == .reward ? 0.42 : 0.28)
        }

        switch style {
        case .hero:
            return AtlasPalette.chromeStroke.opacity(1)
        case .elevated:
            return AtlasPalette.chromeStroke.opacity(0.94)
        case .utility:
            return AtlasPalette.border.opacity(0.82)
        case .default:
            return AtlasPalette.chromeStroke.opacity(0.88)
        case .task:
            return AtlasPalette.chromeStroke.opacity(0.96)
        case .reward:
            return AtlasPalette.reward.opacity(0.18)
        }
    }

    private var topGlow: Color {
        if reduceTransparency || colorSchemeContrast == .increased {
            return .clear
        }

        switch style {
        case .hero:
            return AtlasPalette.heroGlow
        case .elevated:
            return AtlasPalette.elevatedGlow
        case .utility:
            return AtlasPalette.utilityGlow
        case .default:
            return AtlasPalette.softGlow
        case .task:
            return AtlasPalette.taskGlow
        case .reward:
            return AtlasPalette.rewardGlow.opacity(0.38)
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
        case .task:
            return AtlasPalette.shadow.opacity(0.62)
        case .reward:
            return AtlasPalette.reward.opacity(0.16)
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .hero:
            return 7
        case .elevated:
            return 6
        case .utility:
            return 4
        case .default:
            return 5
        case .task:
            return 5
        case .reward:
            return 6
        }
    }

    private var shadowY: CGFloat {
        switch style {
        case .hero:
            return 4
        case .elevated:
            return 4
        case .utility:
            return 3
        case .default:
            return 3
        case .task:
            return 3
        case .reward:
            return 4
        }
    }

    private var accessibleSurfaceColor: Color {
        switch style {
        case .hero:
            return AtlasPalette.surfaceStrong
        case .elevated:
            return AtlasPalette.surfacePrimary
        case .utility:
            return AtlasPalette.surfaceUtility
        case .default:
            return AtlasPalette.surfaceSecondary
        case .task:
            return AtlasPalette.surfacePrimary
        case .reward:
            return AtlasPalette.surfaceTop
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
            .font(.system(size: 10, weight: .semibold, design: .default))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.18), tint.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: tint.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

public struct AtlasPrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .default))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.isPressed ? AtlasPalette.primaryPressed : AtlasPalette.primary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AtlasPalette.chromeStroke.opacity(configuration.isPressed ? 0.32 : 0.44), lineWidth: 1)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AtlasPalette.chromeStrokeSoft.opacity(configuration.isPressed ? 0.72 : 1), lineWidth: 1)
                    .mask(
                        LinearGradient(
                            colors: [.white, .white.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .shadow(
                color: AtlasPalette.primary.opacity(configuration.isPressed ? 0.14 : 0.22),
                radius: configuration.isPressed ? 3 : 5,
                x: 0,
                y: configuration.isPressed ? 1 : 2
            )
            .shadow(
                color: AtlasPalette.innerLift.opacity(configuration.isPressed ? 0.4 : 1),
                radius: 2,
                x: 0,
                y: -1
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
            .font(.system(size: 15, weight: .semibold, design: .default))
            .foregroundStyle(AtlasPalette.secondaryText)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed
                                ? [AtlasPalette.surfaceMuted, AtlasPalette.surfaceSecondary]
                                : [AtlasPalette.surfaceTop, AtlasPalette.surfaceSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(configuration.isPressed ? AtlasPalette.chromeStroke : AtlasPalette.border.opacity(0.78), lineWidth: 1)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AtlasPalette.chromeStrokeSoft.opacity(configuration.isPressed ? 0.72 : 1), lineWidth: 1)
                    .mask(
                        LinearGradient(
                            colors: [.white, .white.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .shadow(
                color: AtlasPalette.shadow.opacity(configuration.isPressed ? 0.18 : 0.26),
                radius: configuration.isPressed ? 3 : 6,
                x: 0,
                y: configuration.isPressed ? 2 : 3
            )
            .shadow(color: AtlasPalette.innerLift.opacity(0.72), radius: 2, x: 0, y: -1)
            .scaleEffect(configuration.isPressed ? 0.988 : 1)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

public struct AtlasTertiaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .default))
            .foregroundStyle(configuration.isPressed ? AtlasPalette.textPrimary : AtlasPalette.secondaryText)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.isPressed ? AtlasPalette.secondaryFill.opacity(0.62) : AtlasPalette.secondaryFill.opacity(0.42))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
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
            .font(.system(size: 15, weight: .semibold, design: .default))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
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
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AtlasPalette.chromeStroke.opacity(0.22), lineWidth: 1)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AtlasPalette.chromeStrokeSoft.opacity(0.92), lineWidth: 1)
                    .mask(
                        LinearGradient(
                            colors: [.white, .white.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .shadow(
                color: AtlasPalette.warning.opacity(configuration.isPressed ? 0.18 : 0.28),
                radius: configuration.isPressed ? 4 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 4
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
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed
                                ? [AtlasPalette.glassFillStrong.opacity(0.92), AtlasPalette.glassFillSoft.opacity(0.9)]
                                : [AtlasPalette.glassFillStrong, AtlasPalette.glassFillSoft],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AtlasPalette.chromeStroke.opacity(configuration.isPressed ? 0.24 : 0.36), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.06 : 0.12), radius: configuration.isPressed ? 4 : 8, x: 0, y: configuration.isPressed ? 2 : 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

public struct AtlasInverseSecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .default))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
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
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(configuration.isPressed ? 0.18 : 0.24), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.04 : 0.09), radius: configuration.isPressed ? 3 : 6, x: 0, y: configuration.isPressed ? 2 : 3)
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
            .font(.system(size: 11, weight: .semibold, design: .default))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(minHeight: 34)
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
            .shadow(color: tint.opacity(configuration.isPressed ? 0.03 : 0.05), radius: configuration.isPressed ? 2 : 4, x: 0, y: configuration.isPressed ? 1 : 2)
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
        #else
        self
        #endif
    }

    @ViewBuilder
    func atlasStandaloneInputSurface() -> some View {
        self.modifier(AtlasStandaloneInputSurfaceModifier())
    }
}

private struct AtlasStandaloneInputSurfaceModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    func body(content: Content) -> some View {
        content
            .foregroundStyle(AtlasPalette.textPrimary)
            .tint(AtlasPalette.primary)
            .submitLabel(.done)
            .onSubmit {
                AtlasKeyboardControl.dismiss()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(backgroundStyle)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(colorSchemeContrast == .increased ? AtlasPalette.primary.opacity(0.24) : AtlasPalette.border.opacity(0.8), lineWidth: 1)
            )
            .overlay(alignment: .top) {
                if reduceTransparency == false && colorSchemeContrast != .increased {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AtlasPalette.chromeStrokeSoft.opacity(1.2), lineWidth: 1)
                        .mask(
                            LinearGradient(
                                colors: [.white, .white.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .shadow(color: AtlasPalette.shadow.opacity(reduceTransparency ? 0.06 : 0.1), radius: 5, x: 0, y: 2)
    }

    private var backgroundStyle: AnyShapeStyle {
        if reduceTransparency || colorSchemeContrast == .increased {
            return AnyShapeStyle(AtlasPalette.surfacePrimary)
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [AtlasPalette.surfaceTop, AtlasPalette.surfaceSecondary, AtlasPalette.surfaceMuted.opacity(0.94)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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
