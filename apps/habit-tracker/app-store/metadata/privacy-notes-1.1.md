# App Privacy Notes — ChickMark 1.1.0

## First-party data model

- no Arvectum account or sign-in;
- habit/check-in data remains local-first;
- existing habit data can use the user's private iCloud/CloudKit database, with local fallback;
- one-time reminders use a separate local-only SwiftData store and are not part of the CloudKit schema;
- iPhone ↔ Apple Watch habit sync uses WatchConnectivity;
- reminders are local notifications;
- habit/reminder user content is not sent to Arvectum servers for analytics or advertising.

## Advertising

Version 1.1 includes Yandex Mobile Ads 8.5.0 for a sticky Today banner.

Runtime configuration:
- precise-location sharing to the advertising SDK is disabled;
- ATT/IDFA is not requested by ChickMark;
- user-created habit and one-time-reminder content is not supplied to the advertising SDK for targeting;
- no App Open Ads;
- no interstitials;
- banner eligibility is delayed after installation.

## App Store Privacy release gate

Do not reuse the 1.0 "Data Not Collected" answer.

Before submission, create the exact signed 1.1 archive and reconcile App Store Connect against:
1. the archive's Xcode Privacy Report;
2. embedded privacy manifests from YandexMobileAds and transitive dependencies;
3. the actual runtime configuration above.

Do not infer App Store categories solely from dependency manifests: they can describe capabilities of modules that are not active in the app's runtime configuration. Conversely, do not omit a category that the final privacy report and actual runtime behavior show as collected.

Tracking / ATT must remain No unless the implementation is intentionally changed before submission.

Canonical Privacy Policy URL:
https://arvectum.com/privacy
