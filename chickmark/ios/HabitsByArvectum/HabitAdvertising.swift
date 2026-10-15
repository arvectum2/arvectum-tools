import SwiftUI
import UIKit
@preconcurrency import YandexMobileAds

enum HabitAdUnitIDs {
    static let demoNative = "demo-native-app-yandex"

    /// Only an explicit DEBUG launch argument may use demo creatives.
    /// Production never accidentally falls back to test inventory.
    static var native: String? {
        resolvedNativeID(
            configured: Bundle.main.object(forInfoDictionaryKey: "YandexNativeAdUnitID")
                as? String,
            arguments: ProcessInfo.processInfo.arguments
        )
    }

    static func resolvedNativeID(configured: String?, arguments: [String]) -> String? {
#if DEBUG
        if arguments.contains("--chickmark-demo-ads") {
            return demoNative
        }
#endif
        guard let value = configured?.trimmingCharacters(in: .whitespacesAndNewlines),
              value.range(of: #"^R-M-[0-9]+-[0-9]+$"#, options: .regularExpression) != nil
        else {
            return nil
        }
        return value
    }
}

@MainActor
enum HabitAdSDK {
    private static var isInitialized = false

    static func initializeIfEligible() async {
        guard !isInitialized else { return }
        // Do not initialise third-party tracking services for new users.
        YandexAds.setLocationTracking(false)
        YandexAds.setUserConsent(false)
#if DEBUG
        YandexAds.enableLogging()
#endif
        await YandexAds.initializeSDK()
        isInitialized = true
    }
}

/// A dedicated bottom sibling of TodayView's ScrollView: habit rows scroll
/// above the native ad and can never be occluded by its dynamic height.
struct HabitStickyNativeSlot: View {
    let onUnavailable: () -> Void

    var body: some View {
        if let unitID = HabitAdUnitIDs.native {
            HabitNativeAdContent(adUnitID: unitID, onUnavailable: onUnavailable)
                .accessibilityIdentifier("today-sticky-ad-slot")
#if DEBUG
                .onAppear {
                    HabitAdDiagnosticStore.record("slot-mounted", unit: unitID)
                }
#endif
        }
    }
}

/// One screen = one NativeAdState = one native SDK impression lifecycle.
/// A no-fill/binding failure removes the entire reserved area. The ad is
/// never repeatedly requested because SwiftUI redraws the habit list.
private struct HabitNativeAdContent: View {
    @StateObject private var adState: NativeAdState
    @State private var loaded = false
    @State private var failed = false
    @State private var requested = false

    init(adUnitID: String, onUnavailable: @escaping () -> Void) {
        _adState = StateObject(wrappedValue: NativeAdState(
            request: AdRequest(adUnitID: adUnitID)
        ))
        self.adUnitID = adUnitID
        self.onUnavailable = onUnavailable
    }

    let adUnitID: String
    let onUnavailable: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            NativeAdContainer(state: adState) { layout in
                nativeCard(layout)
            } placeholder: {
                EmptyView()
            }
            .onAdLoad { _ in
                guard !failed else { return }
                loaded = true
#if DEBUG
                HabitDebugLog.emit("HABITS_AD_NATIVE_LOADED")
                HabitAdDiagnosticStore.record("loaded", unit: adUnitID)
#endif
            }
            .onAdFailure { error in
                hideOnError(error, kind: "failed")
            }
            .onAdBindingFailure { error in
                hideOnError(error, kind: "binding-failed")
            }
            .onAdClick {
#if DEBUG
                HabitDebugLog.emit("HABITS_AD_NATIVE_CLICKED")
#endif
            }
            .onAdImpression { _ in
#if DEBUG
                HabitAdDiagnosticStore.record("impression", unit: adUnitID)
#endif
            }
            // NativeAdContainer internally hosts UIKit ad assets. Give it
            // sufficient real layout space instead of measuring its own
            // frame via a SwiftUI preference-feedback loop (which can cause
            // unbounded relayout during SDK ad binding).
            .frame(height: loaded && !failed ? nil : 0)
            .background(loaded && !failed ? Color.habitsBackground : .clear)

            // A minimal render anchor ensures SwiftUI starts .task even
            // while the ad itself is not yet loaded. Otherwise a collapsed
            // conditional ad can never initiate its first request.
            Color.clear.frame(height: 1).accessibilityHidden(true)
        }
        .task {
            guard !requested else { return }
            requested = true
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--ui-testing") &&
                ProcessInfo.processInfo.arguments.contains("--chickmark-demo-ads") &&
                ProcessInfo.processInfo.arguments.contains("--chickmark-native-simulate-no-fill")
            {
                // Deterministic QA of a real empty SDK slot with eligibility
                // enabled. Do NOT initialise Yandex or generate ad traffic.
                failed = true
                HabitAdDiagnosticStore.record("simulated-no-fill", unit: adUnitID)
                onUnavailable()
                return
            }
#endif
            await HabitAdSDK.initializeIfEligible()
#if DEBUG
            HabitAdDiagnosticStore.record("request", unit: adUnitID)
#endif
            adState.loadAd()
        }
    }

    @MainActor
    private func hideOnError(_ error: Error, kind: String) {
        loaded = false
        failed = true
        onUnavailable()
#if DEBUG
        HabitDebugLog.emit("HABITS_AD_NATIVE_\(kind) reason=\(error.localizedDescription)")
        HabitAdDiagnosticStore.record(kind, unit: adUnitID,
                                      error: error.localizedDescription)
#endif
    }

    private func nativeCard(_ layout: NativeAdLayoutInfo) -> some View {
        // Video ads require at least 300x160dp visible media. On narrow phones
        // the gutters shrink so this requirement can still be satisfied.
        let narrow = UIScreen.main.bounds.width < 350
        let outerPadding: CGFloat = narrow ? 4 : 12
        let innerPadding: CGFloat = narrow ? 4 : 10
        return VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    if layout.has(.icon) {
                        NativeAdAsset.Icon()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        if layout.has(.title) {
                            NativeAdAsset.Title()
                                .font(.subheadline.weight(.semibold))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        HStack(spacing: 5) {
                            if layout.has(.domain) {
                                NativeAdAsset.Domain()
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            if layout.has(.sponsored) {
                                NativeAdAsset.Sponsored()
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            if layout.has(.age) {
                                NativeAdAsset.Age()
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            if layout.has(.favicon) {
                                NativeAdAsset.Favicon()
                                    .frame(width: 14, height: 14)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                    if layout.has(.feedback) {
                        NativeAdAsset.Feedback()
                            .frame(width: 24, height: 24)
                    }
                }
                if layout.has(.media) {
                    NativeAdAsset.Media()
                        // Video media must remain at least 300 x 160 points.
                        .frame(
                            minWidth: layout.media?.hasVideo == true ? 300 : nil,
                            minHeight: layout.media?.hasVideo == true ? 160 : nil
                        )
                        .frame(maxWidth: .infinity)
                } else if layout.has(.mainImage) {
                    NativeAdAsset.MainImage()
                        .frame(maxWidth: .infinity, minHeight: 120)
                }
                if layout.has(.body) {
                    NativeAdAsset.Body()
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if layout.has(.price) || layout.has(.rating) ||
                    layout.has(.reviewCount)
                {
                    HStack(spacing: 8) {
                        if layout.has(.rating) {
                            NativeAdAsset.Rating { value in
                                Text(String(format: "%.1f", value))
                                    .font(.caption)
                            }
                        }
                        if layout.has(.reviewCount) {
                            NativeAdAsset.ReviewCount().font(.caption2)
                        }
                        Spacer(minLength: 0)
                        if layout.has(.price) {
                            NativeAdAsset.Price().font(.caption.weight(.semibold))
                        }
                    }
                }
                if layout.has(.callToAction) {
                    NativeAdAsset.CallToAction { text in
                        Text(text)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.arvectumMint)
                            .foregroundStyle(Color.arvectumNavy)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                if layout.has(.warning) {
                    // Legal warning: never truncate or hide mandatory text.
                    NativeAdAsset.Warning()
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: layout.media?.hasVideo == true ? 55 : 35,
                            alignment: .leading
                        )
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(innerPadding)
            .frame(maxWidth: .infinity)
            .background(Color.habitsSurface,
                        in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, outerPadding)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .fixedSize(horizontal: false, vertical: true)
    }
}


#if DEBUG
/// Read-only developer diagnostics for checking a live ad unit's delivery
/// without bringing SDK/network traffic to Settings or About.
enum HabitAdDiagnosticStore {
    static let statusKey = "habits.ads.debug.status"
    static let unitKey = "habits.ads.debug.unit"
    static let errorKey = "habits.ads.debug.error"

    static func record(_ status: String, unit: String? = nil, error: String? = nil) {
        let defaults = UserDefaults.standard
        defaults.set(status, forKey: statusKey)
        if let unit { defaults.set(unit, forKey: unitKey) }
        defaults.set(error ?? "", forKey: errorKey)
    }
}
#endif
