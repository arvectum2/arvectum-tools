# App Store — App Privacy

State for iOS 0.4.2.

## Data collection

**Data collected:** None.

**Data linked to the user:** None.

**Data used to track the user:** None.

The app has no account system, analytics SDK, advertising SDK, backend, or network-dependent image-processing service.

## Photos and files

The user explicitly selects an image with the system iOS photo picker. Image processing is performed locally on the device.

The result is written only when the user invokes the system save/export flow, or shared using the system share sheet. Temporary working files may exist in the app's local temporary directory and can be removed by the operating system.

## Tracking

Tracking: **No**.

The privacy manifest declares no tracking, no tracking domains, and no collected data types.

## Privacy policy

Public URL:

https://github.com/arvectum2/arvectum-tools/blob/main/PRIVACY.md

The repository policy covers both Android and iOS and states that selected images are processed locally.

## Export compliance

The app does not implement its own cryptography and does not contain third-party encryption libraries. The iOS bundle sets `ITSAppUsesNonExemptEncryption = false`.


## Next monetized release — Yandex Mobile Ads

The next iOS release adds Yandex Mobile Ads SDK 8.5.0. The app itself still processes selected photos locally and does not send photo contents to the advertising SDK.

Runtime configuration:
- precise/location tracking is disabled with `YandexAds.setLocationTracking(false)`;
- the app does not request App Tracking Transparency permission and does not intentionally access IDFA;
- positive GDPR consent is not assumed; `YandexAds.setUserConsent(false)` is used until a dedicated consent flow is added.

The archived dependency privacy manifests are no longer equivalent to “Data collected: None”. In the current build they declare advertising/device data and AppMetrica-related analytics/diagnostic categories; the AppMetrica AdSupport component also contains a tracking declaration. Before this build is submitted, App Store Connect privacy answers must be reviewed against the final archive/privacy report and actual runtime configuration. Do not reuse the 0.4.2 “None” answers unchanged.
