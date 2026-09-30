import SwiftUI
import UIKit

extension Color {
    static let arvectumMint = Color(red: 67 / 255, green: 229 / 255, blue: 197 / 255)
    static let arvectumNavy = Color(red: 4 / 255, green: 26 / 255, blue: 51 / 255)
    static let arvectumGraphite = Color(red: 36 / 255, green: 52 / 255, blue: 70 / 255)

    static let arvectumBackground = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 4/255, green: 26/255, blue: 51/255, alpha: 1)
                : UIColor(red: 243/255, green: 245/255, blue: 247/255, alpha: 1)
        }
    )

    static let arvectumSurface = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 22/255, green: 42/255, blue: 61/255, alpha: 1)
                : .white
        }
    )

    static let arvectumPrimaryText = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? .white
                : UIColor(red: 4/255, green: 26/255, blue: 51/255, alpha: 1)
        }
    )

    static let arvectumSecondaryText = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.68)
                : UIColor(red: 4/255, green: 26/255, blue: 51/255, alpha: 0.62)
        }
    )

    static let arvectumBorder = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.10)
                : UIColor(red: 4/255, green: 26/255, blue: 51/255, alpha: 0.09)
        }
    )
}

struct ArvectumPushkinHeader: View {
    var onAddApp: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Image("ArvectumWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 24)
                .accessibilityHidden(true)

            Capsule()
                .fill(Color.white.opacity(0.20))
                .frame(width: 1, height: 26)
                .accessibilityHidden(true)

            ZStack {
                Image("pushkin-mark")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .offset(y: 5)
            }
            .frame(width: 34, height: 34)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.arvectumMint.opacity(0.55), lineWidth: 1)
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("PUSHKIN")
                    .font(.custom("Baskerville-BoldItalic", size: 21))
                    .tracking(1.4)
                    .foregroundStyle(.white)

                Capsule()
                    .fill(Color.arvectumMint)
                    .frame(width: 58, height: 2)
                    .opacity(0.95)
            }

            Spacer(minLength: 0)

            if let onAddApp {
                Button(action: onAddApp) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.arvectumNavy)
                        .frame(width: 32, height: 32)
                        .background(Color.arvectumMint, in: Circle())
                }
                .buttonStyle(.plain)
                .frame(width: 44, height: 44)
                .accessibilityLabel("Add app")
                .accessibilityIdentifier("add-app")
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 52)
        .background(
            LinearGradient(
                colors: [.arvectumNavy, .arvectumGraphite],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 19, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .stroke(Color.arvectumMint.opacity(0.16), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }
}

struct ArvectumCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.arvectumSurface,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.arvectumBorder, lineWidth: 1)
            )
    }
}

enum PushkinFeatureFlags {
    static let adsEnabled = false
}

/// Reserved insertion point for the post-launch native ad.
/// Product rule: insert after the third history item so the ad is visible
/// without taking over the top of the feed. It renders nothing while ads
/// are disabled, so 1.0 remains genuinely ad-free with no dead space.
struct FutureNativeAdPlacement: View {
    var body: some View {
        if PushkinFeatureFlags.adsEnabled {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.arvectumSurface)
                .frame(height: 108)
                .overlay {
                    Text("Sponsored")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("future-native-ad-slot")
        }
    }
}
