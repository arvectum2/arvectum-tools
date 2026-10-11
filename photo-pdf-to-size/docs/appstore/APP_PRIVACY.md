# App Store — App Privacy for iOS 0.5.1

Prepared for 0.5.1 (7) with Yandex Mobile Ads SDK 8.5.0. Re-verify against the final release archive before submission.

## App Store Connect answers

**Does this app or its third-party partners collect data?** Yes.

Declare **Identifiers → Device ID**.

For Device ID:
- Purpose: **Third-Party Advertising** and **Analytics** (advertising attribution / measurement).
- Linked to the user: **Yes** (conservative answer matching the included AppMetrica AdSupport privacy manifest, which marks Device ID as linked).
- Used for tracking: **Yes**.

The advertising identifier is available to the SDK only when the user grants App Tracking Transparency permission. If ATT is denied, the app still shows ads but IDFA is unavailable.

Do **not** declare photos/videos as collected: selected images are processed locally and are not sent to Yandex or Arvectum for image processing.

Do **not** declare location for this build: `YandexAds.setLocationTracking(false)` is applied on every launch and the app does not request location permission for advertising.

Yandex's current App Store privacy guidance for the default Mobile Ads SDK configuration lists Device ID as collected only when the relevant permission is granted; it lists photos/videos, advertising data, product interaction, purchase history, diagnostics, and other categories as not collected by default. The bundled dependency privacy manifests describe SDK capabilities more broadly, so keep the final App Store answers synchronized with the actual runtime configuration and current Yandex documentation.

## Tracking / consent flow

- On the first launch, the app requires an explicit advertising-data choice before normal use.
- Both **Allow data processing** and **Do not allow data processing** keep result-screen ads enabled.
- The choice is stored locally and passed to `YandexAds.setUserConsent(_:)` on every launch.
- After positive advertising-data consent, iOS may show the system ATT prompt.
- ATT denial does not disable ads; it removes access to IDFA.
- Location forwarding is disabled.
- The user can reopen **Ads & Privacy / Реклама и конфиденциальность** from the app footer and change the Yandex consent choice.
- ATT permission itself can be changed in iOS Settings after the system prompt has been answered.

## Photos and files

The user explicitly selects an image using the system Photos or Files picker. Image processing is local on the device. Results are written only through an explicit save/export action or shared with the system share sheet.

EXIF/GPS stripping is enabled by default for supported output formats.

## Privacy URLs

App/privacy UI target URL: `https://arvectum.com/photo-pod-razmer-privacy.html`.

Before submission, the public page must explicitly cover Yandex Mobile Ads, the first-launch consent choice, ATT/IDFA, the fact that ads remain when consent/tracking is declined, location being disabled, and how to change privacy choices.

## Export compliance

The app sets `ITSAppUsesNonExemptEncryption = false`.
