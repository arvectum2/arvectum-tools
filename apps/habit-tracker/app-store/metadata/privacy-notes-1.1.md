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

## Exact final artifact audit

Final binary source commit:
`594d8c10a2e4815bfd50f784cafcc77b711d61dc`

Final IPA:
`/Users/master/ChickMarkRelease/1.1.0-build3-final-594d8c1/export/HabitsByArvectum.ipa`

SHA-256:
`726c9599c982e387e76c0a1ab4b0e5d39cd55ca727056aa5c3b911017037d345`

Verified in the exported App Store bundle:
- version 1.1.0 / build 3 on iPhone, Watch and iOS widget;
- production APNs and Production CloudKit entitlements;
- App Group `group.ru.arvectum.tools.habits`;
- production Yandex banner ID `R-M-20183085-1`;
- 228 SKAdNetwork identifiers;
- no `NSUserTrackingUsageDescription`;
- aggregate embedded privacy-manifest rows saved to `PRIVACY_MANIFEST_SUMMARY.json` beside the release artifact.

The embedded dependency manifests advertise a wider set of *capabilities* than ChickMark enables at runtime, including AppMetrica diagnostic/analytics declarations. Yandex's SDK documentation for its default iOS configuration states that location is collected only if location is enabled and permission granted, and Device ID only if IDFA permission is granted; ChickMark explicitly disables location tracking and does not request ATT/IDFA. Therefore do not mechanically copy every dependency-manifest capability into the App Store privacy questionnaire without reconciling the Xcode aggregate report and runtime settings.

## App Store Privacy release gate

Do not reuse the 1.0 "Data Not Collected" answer without a fresh review of the 1.1 advertising SDK.

The final artifact and vendor/runtime configuration have now been reconciled.

Recommended App Store Connect answer for ChickMark 1.1:
- Data Collection: **No, we do not collect data from this app**;
- Tracking: **No**;
- Privacy Policy URL: **https://arvectum.com/privacy**.

Rationale:
- ChickMark has no Arvectum account, analytics backend or first-party telemetry pipeline;
- local habit/reminder content is not sent to Arvectum;
- the user's existing CloudKit habit store is private and not visible in the developer portal;
- Yandex documents all App Store data categories as not collected in the default iOS SDK configuration except location when location collection is enabled/authorized and Device ID when IDFA permission is granted;
- ChickMark explicitly disables Yandex location tracking, never requests ATT/IDFA, and passes advertising user consent as false;
- user-created habit/reminder content is never supplied to the ad SDK.

The dependency privacy manifests remain intentionally recorded in the release artifact because they describe capabilities bundled by Yandex/AppMetrica/KSCrash. They must not be mechanically treated as evidence that those optional collection paths run in ChickMark. Xcode's Organizer Privacy Report is an aggregate aid for preparing the label, not a separate App Store submission artifact; the exact embedded manifests have been audited directly from the final exported IPA.

If the advertising configuration changes later (ATT/IDFA, location, analytics, mediation, consent behavior, or a different SDK version), re-open the App Store Privacy questionnaire before that version ships.

Tracking / ATT remains No for 1.1.

Canonical Privacy Policy URL:
https://arvectum.com/privacy
