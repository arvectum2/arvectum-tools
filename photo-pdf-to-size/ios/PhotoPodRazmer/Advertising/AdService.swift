import AppTrackingTransparency
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

enum AdConsentStore {
    private static let key = "arvectum.ads.user-consent"
    static let privacyPolicyURL = URL(string: "https://arvectum.com/photo-pod-razmer-privacy.html")!

    static var storedConsent: Bool? {
        guard UserDefaults.standard.object(forKey: key) != nil else { return nil }
        return UserDefaults.standard.bool(forKey: key)
    }

    static func save(_ consent: Bool) {
        UserDefaults.standard.set(consent, forKey: key)
    }
}

@MainActor
enum AdSDK {
    static func configure() {
        // Privacy-conservative defaults:
        // - no precise location;
        // - no positive GDPR consent until the user explicitly grants it;
        // - ATT is requested only after positive advertising-data consent.
        YandexAds.setLocationTracking(false)
        YandexAds.setUserConsent(AdConsentStore.storedConsent ?? false)
#if DEBUG
        YandexAds.enableLogging()
#endif
        Task {
            await YandexAds.initializeSDK()
        }
    }

    static func setUserConsent(_ consent: Bool) {
        AdConsentStore.save(consent)
        YandexAds.setUserConsent(consent)

        if consent {
            requestTrackingAuthorizationIfNeeded()
        }
    }

    private static func requestTrackingAuthorizationIfNeeded() {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }

        // Let the SwiftUI consent sheet finish dismissing before the system ATT prompt.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}
