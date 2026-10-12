import SwiftUI

/// Compact ChickMark product identity using the Arvectum brandbook's PT Sans Bold.
/// The corporate wordmark and version live on the Manage screen instead.
struct ChickMarkBrandHeader: View {
    var body: some View {
        Link(destination: ChickMarkProductLinks.localizedLandingPage) {
            HStack(alignment: .center, spacing: 8) {
                Image("ChickMarkMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)

                Text("ChickMark")
                    .font(.custom("PTSans-Bold", size: 22, relativeTo: .headline))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ChickMark")
        .accessibilityIdentifier("chickmark.website")
    }
}
