import AppTrackingTransparency
import SwiftUI
import UIKit
@preconcurrency import YandexMobileAds

struct MainScreenNativeAdSlot: View {
    @ObservedObject var session: NativeAdSession

    var body: some View {
        NativeAdSlot(session: session)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("main-native-ad-slot")
    }
}

struct ResultScreenAdSlot: View {
    var body: some View {
        AdaptiveInlineBannerSlot()
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("result-ad-slot-banner")
    }
}
