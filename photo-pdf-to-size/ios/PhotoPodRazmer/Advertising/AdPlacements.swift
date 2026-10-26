import SwiftUI
import UIKit
@preconcurrency import YandexMobileAds

struct MainScreenNativeAdSlot: View {
    @ObservedObject var session: NativeAdSession

    var body: some View {
        if ProcessInfo.processInfo.arguments.contains("--store-screenshot-clean") {
            EmptyView()
        } else {
            NativeAdSlot(session: session)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("main-native-ad-slot")
        }
    }
}

struct ResultScreenAdSlot: View {
    var body: some View {
        Group {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--store-screenshot-clean") {
                EmptyView()
            } else {
            switch ProcessInfo.processInfo.environment["ARVECTUM_RESULT_AD_QA_FIXTURE"] {
            case "no-fill":
                // UI layout-only fixture: no network or ad SDK impression.
                Color.clear
                    .frame(height: 1)
                    .accessibilityLabel("QA: no ad available")
                    .accessibilityIdentifier("result-ad-no-fill")
            case "loaded":
                // Deliberately reserves a worst-case banner footprint.
                // It is NOT a substitute for a real Yandex ad test.
                VStack {
                    Text("Реклама · QA")
                        .font(.caption.weight(.semibold))
                    Spacer(minLength: 0)
                    Text("Тестовая область рекламы")
                        .font(.body)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(Color.arvectumSurface, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("result-ad-loaded-qa")
            default:
                AdaptiveInlineBannerSlot()
                    .accessibilityIdentifier("result-ad-slot-banner")
            }
            }
#else
            AdaptiveInlineBannerSlot()
                .accessibilityIdentifier("result-ad-slot-banner")
#endif
        }
        .frame(maxWidth: .infinity)
    }
}
