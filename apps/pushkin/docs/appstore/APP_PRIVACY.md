# PUSHKIN 1.0 — App Privacy

## Runtime data model

PUSHKIN 1.0 processes notification content locally on the iPhone.

The app has:
- no account system;
- no backend or cloud sync;
- no advertising SDK;
- no analytics SDK;
- no runtime App Store lookup;
- no remote notification-content processing.

Notification content is written to the app's local SwiftData store after the user configures Apple's Shortcuts automation.

## App Store Connect answers

For version 1.0:

- **Data collected:** No.
- **Data linked to the user:** No.
- **Data used to track the user:** No.
- **Tracking:** No.

The app privacy answers must be revisited before the second release if an advertising SDK is introduced.
## Privacy manifest

The app bundle contains `PrivacyInfo.xcprivacy` with:
- `NSPrivacyTracking = false`;
- no tracking domains;
- no collected data types;
- `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1` for PUSHKIN's own local preferences / `@AppStorage` state.

Before submission, generate/inspect the final Xcode privacy report from the exact archive. If the final binary or a new dependency reports a required-reason API, update the manifest before upload.

## Privacy policy

Public URL:

https://arvectum.com/privacy

The public policy must continue to state that PUSHKIN notification content is processed and stored locally.

## Version 1.1 advertising note

Advertising is deliberately excluded from 1.0.

When ads are added later:
1. reassess App Store privacy answers;
2. inspect the ad SDK privacy manifest;
3. keep notification text isolated from ad targeting and ad SDK inputs;
4. update the public privacy policy before release.
