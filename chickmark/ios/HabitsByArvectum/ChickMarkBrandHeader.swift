import SwiftUI

/// Compact ChickMark product identity using the Arvectum brandbook's PT Sans Bold.
/// The corporate wordmark and version live on the Manage screen instead.
struct ChickMarkBrandHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var webPage: ChickMarkWebPage?

    var body: some View {
        Button {
            webPage = ChickMarkWebPage(url: ChickMarkProductLinks.localizedLandingPage)
        } label: {
            HStack(alignment: .center, spacing: 8) {
                Image("ChickMarkMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)

                Text("ChickMark")
                    .font(.custom(
                        "PTSans-Bold",
                        size: dynamicTypeSize.isAccessibilitySize ? 19 : 22,
                        relativeTo: .headline
                    ))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .allowsTightening(true)
                    .layoutPriority(1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ChickMark")
        .accessibilityIdentifier("chickmark.website")
        .sheet(item: $webPage) { page in
            ChickMarkWebSheet(page: page)
        }
    }
}
