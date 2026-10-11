import SwiftUI
import UIKit

extension Color {
    static let arvectumMint = Color(
        red: 67 / 255,
        green: 229 / 255,
        blue: 197 / 255
    )

    static let arvectumNavy = Color(
        red: 4 / 255,
        green: 26 / 255,
        blue: 51 / 255
    )

    static let arvectumGraphite = Color(
        red: 36 / 255,
        green: 52 / 255,
        blue: 70 / 255
    )

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
                ? UIColor(red: 36/255, green: 52/255, blue: 70/255, alpha: 1)
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
                ? UIColor.white.withAlphaComponent(0.12)
                : UIColor(red: 4/255, green: 26/255, blue: 51/255, alpha: 0.10)
        }
    )
}
struct ArvectumBrandHeader: View {
    let productName: String

    var body: some View {
        HStack(spacing: 12) {
            Image("ArvectumWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 104, height: 28)

            Spacer(minLength: 8)

            Text(productName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(
            Color.arvectumNavy,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }
}

struct ArvectumCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
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
