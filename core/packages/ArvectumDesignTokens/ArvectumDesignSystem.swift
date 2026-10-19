import SwiftUI

/// Optional cross-product UI primitives.
/// Product flows and product-specific colors remain with their owning app.
/// Adding these tokens does not change any existing screen automatically.
public enum ArvectumDesignMetrics {
    /// Base spacing unit in points. Use multiples of four for regular rhythm.
    public static let unit: CGFloat = 4
    public static let spaceXS: CGFloat = 4
    public static let spaceS: CGFloat = 8
    public static let spaceM: CGFloat = 12
    public static let spaceL: CGFloat = 16
    public static let spaceXL: CGFloat = 24
    public static let spaceXXL: CGFloat = 32

    public static let compactHorizontalInset: CGFloat = 16
    public static let minimumTouchTarget: CGFloat = 44
    public static let preferredControlHeight: CGFloat = 48
    public static let controlCornerRadius: CGFloat = 14
    public static let cardCornerRadius: CGFloat = 20
}

/// Semantic *defaults*, not a mandate to apply the same background to all apps.
/// Pass ColorScheme from a view's environment; this works on iOS and watchOS.
public enum ArvectumSemanticColors {
    public static let actionBackground: Color = .arvectumMint
    public static let actionForeground: Color = .arvectumNavy

    /// White/mint is not contrast-safe for small text. Use this text accent instead.
    public static func accentText(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? .arvectumMint
            : Color(red: 0 / 255, green: 122 / 255, blue: 104 / 255)
    }

    public static func background(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? .arvectumNavy
            : Color(red: 243 / 255, green: 245 / 255, blue: 247 / 255)
    }

    public static func surface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .arvectumGraphite : .white
    }

    public static func primaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : .arvectumNavy
    }

    public static func secondaryText(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 200 / 255, green: 200 / 255, blue: 200 / 255)
            : .arvectumGraphite
    }

    public static func subtleBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.12)
            : Color.arvectumNavy.opacity(0.10)
    }
}
