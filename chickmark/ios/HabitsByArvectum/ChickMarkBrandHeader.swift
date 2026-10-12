import SwiftUI

/// Compact identity in the navigation bar. Uses the actual Arvectum lettering
/// extracted from the pre-existing brand wordmark image; never recreates AV.
struct ChickMarkBrandHeader: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    var body: some View {
        Link(destination: ChickMarkProductLinks.localizedLandingPage) {
            HStack(alignment: .center, spacing: 8) {
                Image("ChickMarkMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 0) {
                    Text("ChickMark")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(alignment: .center, spacing: 3) {
                        Text("by")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.habitsSecondaryText)
                        Image("ArvectumTypeOnly")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 23)
                            .accessibilityLabel("Arvectum")
                    }
                    .frame(height: 20, alignment: .leading)
                }
                .fixedSize(horizontal: true, vertical: false)

                Text("v" + version)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.habitsSecondaryText)
                    .lineLimit(1)
                    .accessibilityIdentifier("chickmark.version")
                    .padding(.leading, 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.format("brand.website.accessibility", version))
        .accessibilityIdentifier("chickmark.website")
    }
}
