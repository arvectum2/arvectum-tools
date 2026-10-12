import SwiftUI

/// Compact identity in the navigation bar. Uses the actual Arvectum lettering
/// extracted from the pre-existing brand wordmark image; never recreates AV.
struct ChickMarkBrandHeader: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    var body: some View {
        Link(destination: ChickMarkProductLinks.localizedLandingPage) {
            HStack(spacing: 7) {
                Image("ChickMarkMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 0) {
                    Text("ChickMark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(alignment: .center, spacing: 3) {
                        Text("by")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.habitsSecondaryText)
                        Image("ArvectumTypeOnly")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 15)
                            .accessibilityLabel("Arvectum")
                    }
                    .frame(height: 14, alignment: .leading)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.format("brand.website.accessibility", version))
        .accessibilityIdentifier("chickmark.website")
    }
}
