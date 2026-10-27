import SwiftUI

/// First-install guidance; no permissions, advertisements or login.
struct ChickMarkOnboardingView: View {
    let onDone: () -> Void
    @State private var page = 0

    private let icons = ["checkmark.circle.fill", "calendar.badge.clock", "bell.badge"]
    private let titles = ["onboarding.first.title", "onboarding.second.title", "onboarding.third.title"]
    private let details = ["onboarding.first.body", "onboarding.second.body", "onboarding.third.body"]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Button(L10n.string("onboarding.skip")) { onDone() }
                    .accessibilityIdentifier("chickmark.onboarding.skip")
                    .padding(14)
            }
            TabView(selection: $page) {
                ForEach(0..<3, id: \.self) { index in
                    VStack(spacing: 20) {
                        Spacer(minLength: 8)
                        Image(systemName: icons[index])
                            .font(.system(size: 76, weight: .light))
                            .foregroundStyle(Color.arvectumMint)
                            .accessibilityHidden(true)
                        Text(L10n.string(titles[index]))
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("chickmark.onboarding.title")
                        Text(L10n.string(details[index]))
                            .font(.title3)
                            .foregroundStyle(Color.habitsSecondaryText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                    }
                    .padding(.horizontal, 26)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .accessibilityIdentifier("chickmark.onboarding.carousel")
            Button {
                if page == 2 { onDone() }
                else { withAnimation { page += 1 } }
            } label: {
                Text(L10n.string(page == 2 ? "onboarding.start" : "onboarding.next"))
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .accessibilityIdentifier(page == 2 ? "chickmark.onboarding.start" : "chickmark.onboarding.next")
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.habitsBackground.ignoresSafeArea())
        .interactiveDismissDisabled()
    }
}
