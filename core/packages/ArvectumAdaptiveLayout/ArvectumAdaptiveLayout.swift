import SwiftUI

/// Layout decisions based on the current window/container, never the
/// device model, orientation, UIScreen.main or hardcoded Duo pose.
public struct ArvectumAdaptiveMetrics: Equatable {
    public let availableWidth: CGFloat
    public let accessibilityText: Bool

    public init(availableWidth: CGFloat, accessibilityText: Bool = false) {
        self.availableWidth = availableWidth
        self.accessibilityText = accessibilityText
    }

    /// Two panes are opt-in, leaving navigation to the system. Minimum
    /// width varies per consumer (photo preview, editor, notification list).
    public func canShowTwoPanes(
        minimumPaneWidth: CGFloat = 320,
        spacing: CGFloat = 20,
        horizontalInset: CGFloat = 16
    ) -> Bool {
        guard availableWidth.isFinite, availableWidth > 0,
              minimumPaneWidth.isFinite, minimumPaneWidth > 0,
              spacing.isFinite, spacing >= 0,
              horizontalInset.isFinite, horizontalInset >= 0,
              !accessibilityText else { return false }
        return availableWidth >= minimumPaneWidth * 2 + spacing + horizontalInset * 2
    }

    /// A readable upper bound for centered copy, forms and long note text.
    public func readableWidth(maxWidth: CGFloat) -> CGFloat {
        guard availableWidth.isFinite, availableWidth > 0,
              maxWidth.isFinite, maxWidth > 0 else { return 0 }
        return min(availableWidth, maxWidth)
    }
}

/// Shared centered reading column. Caller owns scrolling, safe areas,
/// navigation and user input. The modifier limits line length only.
public struct ArvectumReadableColumn<Content: View>: View {
    private let maxWidth: CGFloat
    private let content: Content

    public init(
        maxWidth: CGFloat = 760,
        @ViewBuilder content: () -> Content
    ) {
        self.maxWidth = maxWidth
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

/// An opt-in generic two-region content layout. AnyLayout rather than
/// mutually exclusive branches preserves child identity across resizing.
/// For navigation / Duo reserved regions use native NavigationSplitView
/// or native iOS 27.1 arrangement views instead.
public struct ArvectumAdaptiveContentStack<Leading: View, Trailing: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var measuredWidth: CGFloat = 0

    private let minimumPaneWidth: CGFloat
    private let spacing: CGFloat
    private let leading: Leading
    private let trailing: Trailing

    public init(
        minimumPaneWidth: CGFloat = 320,
        spacing: CGFloat = 20,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.minimumPaneWidth = minimumPaneWidth
        self.spacing = spacing
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        let sideBySide = ArvectumAdaptiveMetrics(
            availableWidth: measuredWidth,
            accessibilityText: dynamicTypeSize.isAccessibilitySize
        ).canShowTwoPanes(
            minimumPaneWidth: minimumPaneWidth,
            spacing: spacing,
            horizontalInset: 0
        )
        let currentLayout = AnyLayout(
            sideBySide
                ? AnyLayout(HStackLayout(alignment: .top, spacing: spacing))
                : AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
        )
        currentLayout {
            leading
                .frame(maxWidth: .infinity)
            trailing
                .frame(maxWidth: .infinity)
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            measuredWidth = newWidth
        }
    }
}
