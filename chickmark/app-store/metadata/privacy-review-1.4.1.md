# ChickMark 1.4.1 — published App Privacy disclosure

App Store Connect App Privacy was corrected and published on 2026-10-14, before version 1.4.1 (15) was submitted to App Review.

Archive inspected: physically tested internal 1.4.1 (14), exact YandexMobileAds dependency used by candidate (15). Its embedded privacy manifests include:
- Yandex Mobile Ads: Device ID and Advertising Data for third-party advertising; neither linked to user nor marked tracking in Yandex's own manifest.
- Transitive AppMetrica: Device ID (one component explicitly linked=true, tracking=true), Coarse Location, Product Interaction, Purchase History, Other Data, crash and other diagnostics. The AdSupport component declares tracking=true, requiring review of actual compiled/runtime behavior (including IDFA/ATT policy).
- Transitive KSCrash: Device ID, crash data, performance and other diagnostic types. Runtime collection may depend on SDK initialization/configuration.
- App/Watch code: local HealthKit sample processing; no raw Health measurements are intentionally uploaded. A HealthKit sample *read locally* is not inherently a developer-collected health data item.

Release code audits:
- Yandex SDK only initializes after existing 3-day / 5-launch / 3-checkoff gate and only when ad placement is eligible. Calls YandexAds.setLocationTracking(false), setUserConsent(false) before initialization; no app-level ATT request. But SDK is distributed in final binary and Apple's privacy responses must be based on actual SDK collection, not on wishful assumptions.
- App's first-party PrivacyInfo.xcprivacy says NSPrivacyTracking=false and NSPrivacyCollectedDataTypes empty. This is NOT a complete accounting of third-party manifests.

## Published App Privacy answers, 2026-10-14

| Category | Purpose | Linked | Tracking |
| --- | --- | --- | --- |
| Coarse Location | Analytics | No | No |
| Device ID | Third-Party Advertising, Analytics, App Functionality | No | No |
| Product Interaction | Analytics | No | No |
| Advertising Data | Third-Party Advertising | No | No |
| Crash Data | App Functionality | No | No |
| Performance Data | App Functionality | No | No |
| Other Diagnostic Data | Analytics, App Functionality | No | No |
| Other Data Types | Analytics, App Functionality | No | No |

The published Apple Product Page Preview showed Data Not Linked to You with the eight categories and no unfinished Set Up warnings. No Health/Fitness data was declared remotely collected: raw HealthKit measurements remain local.

Tracking caveat: the transitive AppMetricaAdSupport module in the signed SDK carries a tracking=true privacy manifest for an IDFA-based capability. ChickMark does not request App Tracking Transparency/IDFA, and invokes YandexAds.setLocationTracking(false) and YandexAds.setUserConsent(false) before eligible SDK initialization. Yandex documentation states the AdSupport tracking path operates if IDFA is available and requires the app to request permission. The published No Tracking answer pertains to this actual no-IDFA/no-ATT configuration; changing SDK composition, consent, data linkage, or IDFA access requires a fresh audit and may require ATT.

Sources:
- https://developer.apple.com/app-store/user-privacy-and-data-use/
- https://yandex.com/support/appmetrica-io/en/data-security/app-privacy-apple
- https://ads.yandex.com/helpcenter/en/dev/ios/app-privacy-apple
