# App Privacy — release-gated revision after user review, 26.10.2026

**DRAFT. Do not change App Store Connect or the public privacy policy without the owner's separate approval of the exact change.** This revision applies to the unshipped branch `feature/review-ux-photo-chickmark-20261026`, not today's public app.

## Verified application behavior
- Photo/PDF bytes are read from user-selected Photos/Files sources, processed on iPhone and exported via a user-initiated share/save. No app-level upload of photo/PDF content to Yandex or Arvectum.
- `YandexAds.setLocationTracking(false)`, `YandexAds.setUserConsent(false)` at startup. No ATT request, `ATTrackingManager` usage, or `NSUserTrackingUsageDescription` in the new build.
- Explicitly called `YandexAds.setAppAdAnalyticsReportingEnabled(false)` to avoid the automatically enabled anonymous AppMetrica reports; this setting is supported by the bundled `YandexMobileAds.framework` Swift interface.
- This **does not mean "no data collected"**. Yandex Mobile Ads and transitive AppMetrica dependencies can collect technical device/ad data while serving ads. The application displays a read-only disclosure plus the privacy-policy link instead of a misleading personalised-ad consent flow.

## Direct manifest audit (26 October, Debug iOS Simulator build)
- Own `PrivacyInfo.xcprivacy`: tracking=false; no collected data declared by first-party code.
- `YandexMobileAds.framework/PrivacyInfo.xcprivacy`: device identifier (unlinked, not marked tracking) + advertising data (unlinked, not marked tracking), third-party advertising purposes.
- **`AppMetrica_AppMetricaAdSupport.bundle/PrivacyInfo.xcprivacy`: tracking=true**, device identifier marked **linked and used for tracking**, analytics purpose, with tracking domains. This remains bundled despite runtime advertising consent being false. A manifest is a capability declaration, not proof that tracking took place, but App Store answers must not contradict the included SDK/data practices.

## Proposed conservative App Store answers — NOT changed live
- **Data Collected: Yes.** Device ID / Identifiers: third-party advertising + analytics. Until third-party verification resolves the AppMetrica manifest, mark linked and used for tracking conservatively rather than incorrectly claiming "not tracked". Advertising data: third-party advertising, as per current embedded SDK manifest.
- **Photos/Videos: not collected** by the app/ad service (image bytes remain on device). File contents are not uploaded for server processing.
- **Location: not collected by this app configuration** (SDK location tracking switched off, no location permission request); review other transitive SDK telemetry before actually removing an existing "Location" field from App Store Connect.
- **ATT prompt absent** is a runtime fact, not an unconditional proof of cross-app tracking absence. Confirm Yandex/AppMetrica implementation with vendor/privacy advisor before removing the "Used for Tracking" label.
- No first-launch advertising consent gate; the persistent `Ads & Privacy` footer opens a clear disclosure and public policy link.

## Blockers
- [ ] Verify network telemetry / SDK vendor's current documentation for all regions and whether the AdSupport tracking-capable module can be excluded or switched off; if not, **do not** label this app as tracking-free. User's alternatives: fully non-tracking ad delivery, or separate ad-free monetisation with clear disclosure (IAP design not implemented).
- [ ] Update the public policy URL `https://arvectum.com/photo-pod-razmer-privacy.html` to accurately reflect shipping functionality, with separate site deployment authorization.
- [ ] Reconcile live App Privacy Nutrition Label (especially Location and Identifier usage) against the *new release candidate*, only after owner explicitly authorizes precise ASC metadata changes.
- [ ] Complete native-speaker copy review and physical privacy/permission QA; signed IPA and version/build bump; separate ASC/TestFlight upload approval.

Source check: `photo-pdf-to-size/ios/PhotoPodRazmer/Advertising/AdService.swift`, bundled privacy manifests at `/Volumes/ArvectumSSD/Arvectum/qa/review-ux-20261026/derived-photo/Build/Products/Debug-iphonesimulator/PhotoPodRazmer.app`.

## 26.10.2026 direct dependency finding

The checked-out Yandex Mobile Ads Swift Package `yandex-ads-sdk-ios/Package.swift` directly includes `AppMetricaAdSupport` in the product dependencies (two variants). Simply removing `NSUserTrackingUsageDescription` or setting `setUserConsent(false)` cannot erase the bundled tracking manifest. The official AppMetrica guide confirms excluding `AppMetricaAdSupport` is the documented approach for disabling tracking, but the current Yandex SDK integration requires the module. Do **not** fork/vendor the SDK, silently remove required targets or change live privacy disclosures without testing Yandex ad filling and obtaining a supported upstream integration path. Vendor source: https://yandex.com/support/appmetrica-io/en/data-security/app-privacy-apple .
