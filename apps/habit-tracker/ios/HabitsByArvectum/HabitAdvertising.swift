import SwiftUI
import UIKit
@preconcurrency import YandexMobileAds

enum HabitAdUnitIDs {
    static var banner: String? {
#if DEBUG
        return "demo-banner-yandex"
#else
        return "R-M-20183085-1"
#endif
    }
}

enum HabitAdSDK {
    static func configure() {
        Task { @MainActor in
            YandexAds.setLocationTracking(false)
            YandexAds.setUserConsent(false)
#if DEBUG
            YandexAds.enableLogging()
#endif
            await YandexAds.initializeSDK()
        }
    }
}

struct HabitStickyBannerSlot: View {
    @State private var loaded = false
    @State private var contentHeight: CGFloat = 60

    var body: some View {
        GeometryReader { proxy in
            if let adUnitID = HabitAdUnitIDs.banner {
                HabitStickyBannerRepresentable(
                    availableWidth: max(proxy.size.width, 320),
                    adUnitID: adUnitID,
                    isLoaded: $loaded,
                    contentHeight: $contentHeight
                )
                .frame(
                    width: proxy.size.width,
                    height: max(contentHeight, 60)
                )
                .opacity(loaded ? 1 : 0)
            }
        }
        .frame(height: loaded ? contentHeight : 1)
        .background(loaded ? Color.habitsSurface : Color.clear)
        .clipped()
        .animation(.easeInOut(duration: 0.16), value: loaded)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today-sticky-ad-slot")
    }
}

private struct HabitStickyBannerRepresentable: UIViewRepresentable {
    let availableWidth: CGFloat
    let adUnitID: String
    @Binding var isLoaded: Bool
    @Binding var contentHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(
            isLoaded: $isLoaded,
            contentHeight: $contentHeight
        )
    }

    func makeUIView(context: Context) -> BannerAdView {
        let adSize = BannerAdSize.sticky(containerWidth: availableWidth)
        let view = BannerAdView(adSize: adSize)
        view.delegate = context.coordinator
        view.translatesAutoresizingMaskIntoConstraints = false
        view.loadAd(with: AdRequest(adUnitID: adUnitID))
        return view
    }

    func updateUIView(_ uiView: BannerAdView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, BannerAdViewDelegate {
        private var isLoaded: Binding<Bool>
        private var contentHeight: Binding<CGFloat>

        init(
            isLoaded: Binding<Bool>,
            contentHeight: Binding<CGFloat>
        ) {
            self.isLoaded = isLoaded
            self.contentHeight = contentHeight
        }

        func bannerAdViewDidLoad(_ bannerAdView: BannerAdView) {
            isLoaded.wrappedValue = true
            contentHeight.wrappedValue = max(
                1,
                bannerAdView.adContentSize().height
            )
#if DEBUG
            HabitDebugLog.emit("HABITS_AD_BANNER_LOADED")
#endif
        }

        func bannerAdViewDidFailLoading(
            _ bannerAdView: BannerAdView,
            error: Error
        ) {
            isLoaded.wrappedValue = false
            contentHeight.wrappedValue = 1
#if DEBUG
            HabitDebugLog.emit(
                "HABITS_AD_BANNER_FAILED reason=\(error.localizedDescription)"
            )
#endif
        }

        func bannerAdViewDidClick(_ bannerAdView: BannerAdView) {}

        func bannerAdView(
            _ bannerAdView: BannerAdView,
            didTrackImpression impressionData: ImpressionData?
        ) {}
    }
}
