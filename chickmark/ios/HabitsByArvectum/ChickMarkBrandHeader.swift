import SwiftUI

/// Low-profile product identity; never competes with the daily check-in list.
struct ChickMarkBrandHeader: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            as? String ?? "—"
    }

    var body: some View {
        Link(destination: ChickMarkProductLinks.localizedLandingPage) {
            HStack(spacing: 10) {
                Image("ChickMarkMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("ChickMark")
                        .font(.headline.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Image("ArvectumWordmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 127, height: 30, alignment: .leading)
                            .accessibilityLabel("Arvectum")

                        Spacer(minLength: 0)

                        Text("v" + version)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(Color.habitsSecondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .accessibilityIdentifier("chickmark.version")
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Color.habitsSurface,
                in: RoundedRectangle(cornerRadius: 18)
            )
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            L10n.format("brand.website.accessibility", version)
        )
        .accessibilityIdentifier("chickmark.website")
    }
}
