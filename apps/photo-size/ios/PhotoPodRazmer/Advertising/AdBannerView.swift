import AppTrackingTransparency
import SwiftUI
import UIKit
@preconcurrency import YandexMobileAds

struct AdaptiveInlineBannerSlot: View {
    @State private var loaded = false

    var body: some View {
        GeometryReader { proxy in
            AdaptiveInlineBannerRepresentable(
                availableWidth: proxy.size.width,
                isLoaded: $loaded
            )
        }
        .frame(height: loaded ? 180 : 1)
        .clipped()
        .animation(.easeInOut(duration: 0.2), value: loaded)
    }
}

private struct AdaptiveInlineBannerRepresentable: UIViewRepresentable {
    let availableWidth: CGFloat
    @Binding var isLoaded: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoaded: $isLoaded)
    }

    func makeUIView(context: Context) -> BannerAdView {
        let width = max(300, availableWidth)
        let size = BannerAdSize.inline(width: width, maxHeight: 180)
        let view = BannerAdView(adSize: size)
        view.delegate = context.coordinator
        view.translatesAutoresizingMaskIntoConstraints = false
        view.loadAd(with: AdRequest(adUnitID: AdUnitIDs.banner))
        return view
    }

    func updateUIView(_ uiView: BannerAdView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, BannerAdViewDelegate {
        private var isLoaded: Binding<Bool>

        init(isLoaded: Binding<Bool>) {
            self.isLoaded = isLoaded
        }

        func bannerAdViewDidLoad(_ bannerAdView: BannerAdView) {
            isLoaded.wrappedValue = true
        }

        func bannerAdViewDidFailLoading(_ bannerAdView: BannerAdView, error: Error) {
            isLoaded.wrappedValue = false
        }

        func bannerAdViewDidClick(_ bannerAdView: BannerAdView) {}

        func bannerAdView(
            _ bannerAdView: BannerAdView,
            didTrackImpression impressionData: ImpressionData?
        ) {}
    }
}
