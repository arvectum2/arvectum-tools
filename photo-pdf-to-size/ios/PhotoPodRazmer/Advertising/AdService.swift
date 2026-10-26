import SwiftUI
import UIKit
@preconcurrency import YandexMobileAds

enum AdUnitIDs {
#if DEBUG
    static let native = "demo-native-app-yandex"
    static let banner = "demo-banner-yandex"
#else
    static let native = "R-M-20141949-1"
    static let banner = "R-M-20141949-2"
#endif
}


@MainActor
final class NativeAdSession: ObservableObject {
    private let loader = NativeAdLoader()
    private var cachedAd: NativeAd?
    private var isLoading = false
    private var waiters: [(Result<NativeAd, Error>) -> Void] = []

    func prefetch() {
        load { _ in }
    }

    func load(_ completion: @escaping (Result<NativeAd, Error>) -> Void) {
        if let cachedAd {
            completion(.success(cachedAd))
            return
        }

        waiters.append(completion)
        guard !isLoading else { return }
        isLoading = true

        let request = AdRequest(adUnitID: AdUnitIDs.native)
        let options = NativeAdOptions()
        loader.loadAd(with: request, options: options) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            if case .success(let ad) = result {
                self.cachedAd = ad
            }
            let callbacks = self.waiters
            self.waiters.removeAll()
            callbacks.forEach { $0(result) }
        }
    }
}

enum AdPrivacyPolicy {
    static let url = URL(string: "https://arvectum.com/photo-pod-razmer-privacy.html")!
}

@MainActor
enum AdSDK {
    static func configure() {
        // Contextual ad mode only; never request ATT/IDFA and never
        // opt in to personalised advertising. No location access.
        YandexAds.setLocationTracking(false)
        YandexAds.setUserConsent(false)
#if DEBUG
        YandexAds.enableLogging()
#endif
        Task { await YandexAds.initializeSDK() }
    }
}
