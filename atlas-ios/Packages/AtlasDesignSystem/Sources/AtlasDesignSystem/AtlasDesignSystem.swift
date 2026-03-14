import SwiftUI

public enum AtlasPalette {
    public static let primary = Color(red: 78 / 255, green: 134 / 255, blue: 247 / 255)
    public static let primaryPressed = Color(red: 63 / 255, green: 118 / 255, blue: 232 / 255)
    public static let background = Color.white
    public static let canvas = Color(red: 245 / 255, green: 248 / 255, blue: 255 / 255)
    public static let border = Color(red: 230 / 255, green: 236 / 255, blue: 245 / 255)
    public static let textPrimary = Color(red: 17 / 255, green: 24 / 255, blue: 39 / 255)
    public static let textSecondary = Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255)
    public static let success = Color(red: 17 / 255, green: 132 / 255, blue: 92 / 255)
}

public enum AtlasSpacing {
    public static let xSmall: CGFloat = 8
    public static let small: CGFloat = 12
    public static let medium: CGFloat = 16
    public static let large: CGFloat = 24
    public static let xLarge: CGFloat = 32
}

public struct AtlasScreen<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [AtlasPalette.canvas, AtlasPalette.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AtlasSpacing.large) {
                    content
                }
                .padding(.horizontal, AtlasSpacing.large)
                .padding(.vertical, AtlasSpacing.large)
            }
        }
    }
}

public struct AtlasSectionCard<Content: View>: View {
    private let title: String?
    private let content: Content

    public init(title: String? = nil, @ViewBuilder content: () -> Content) {
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
        .padding(AtlasSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AtlasPalette.border, lineWidth: 1)
        )
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
    }
}

public struct AtlasPrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(configuration.isPressed ? AtlasPalette.primaryPressed : AtlasPalette.primary)
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}
