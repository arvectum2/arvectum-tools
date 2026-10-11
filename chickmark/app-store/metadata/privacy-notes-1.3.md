# ChickMark 1.3 — signing, advertising and Apple App Privacy review

**Status:** reviewed on 2026-10-10; developer-side checks passed, physical network/paired-device acceptance is the LAST remaining technical step. No upload and no changes to published App Store privacy labels.

## Actual monetization and gate

- One Yandex Mobile Ads **sticky banner on Today** with Release Ad Unit `R-M-20183085-1` and separate debug demo unit. Already shipped with 1.2; NOT a new slot in 1.3.
- Eligibility strictly requires **3 elapsed days + 5 distinct app cold launches + 3 successful check-offs**; unit boundary checks verify no early display.
- In 1.3 the ad SDK is also **lazily initialized only when the eligible Today banner mounts**. Previously it was initialized in `App.init()` at every launch, regardless of eligibility. This prevents unnecessary SDK startup for new users but is not by itself proof of zero network collection after eligibility.
- Explicit Yandex runtime settings: `setLocationTracking(false)` and `setUserConsent(false)`. No ATT/IDFA request is implemented in ChickMark. No interstitial, App Open or extra native Progress ad.

## Signed binary, not just simulator

- Local signed archive `/tmp/chickmark-13-signed-final-r2.xcarchive` (iPhone + iOS widget + Watch + Watch widget) built without any upload.
- Local IPA `/tmp/chickmark-13-final-export-r2/HabitsByArvectum.ipa` exported with `destination=export`, **Apple Distribution: LLC ARVECTUM**; verified with `codesign --verify --deep --strict`.
- Bundle ID/versions and four first-party privacy manifests match 1.3.0 / build 5. Final SHA-256: `73523aeb9060631ab8c6ffaa711bfc2f5145c8d3905f56f6a6495da3560f7049`.

## Third-party disclosure needs precision

The Yandex Mobile Ads transitive dependencies embed multiple privacy manifests. Inspection of the signed local IPA found **28 privacy manifests** in total, including:

- `YandexMobileAds.framework`: possible `DeviceID` and `AdvertisingData` declarations.
- `AppMetricaAdSupport`: declares `NSPrivacyTracking = true`, a device ID and tracking domains; this describes **SDK capability**, not proof that the current app requests IDFA or actually transmits tracking data.
- Other AppMetrica/KSCrash components: declarations for diagnostics, device ID and optional usage data. Many such SDK capabilities may not be used at runtime.

Vendor guidance says device advertising ID collection in the default Mobile Ads SDK configuration requires the corresponding user permission; it also documents excluding `AppMetricaAdSupport` to remove tracking functionality. The product uses no ATT request and disables consent/location settings. However Apple asks developers to review *all* SDK practices; static manifest checks cannot establish the true runtime disclosures or certify the current **Data Not Collected / Tracking No** storefront answers.

**Release policy:** Do not change public privacy labels blindly. Before approving 1.3, verify network/ads behavior on the authorized physical iPhone, compare against the exact final signed IPA and reconcile App Store Privacy with Apple's definitions and vendor documentation. If observable collection differs from the 1.2 questionnaire, amend the answers and privacy text *before* submission. The existing published privacy labels were not changed.

## Evidence references

- https://ads.yandex.com/helpcenter/en/dev/ios/app-privacy-apple
- https://appmetrica.yandex.com/docs/en/new-users/data-security
- https://developer.apple.com/app-store/user-privacy-and-data-use/

Note: Nothing in this document is legal advice; the final binary must be verified against actual runtime and applicable region-specific policies.
