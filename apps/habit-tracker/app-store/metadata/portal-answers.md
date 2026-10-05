# ChickMark 1.0.0 — App Store Connect portal answers

Prepared for build 1.0.0 (1).

## App information

- Name: ChickMark
- Primary locale: Russian
- Bundle ID: ru.arvectum.tools.habits
- SKU suggestion: chickmark-ios
- Primary category: Health & Fitness
- Price: Free
- In-App Purchases: None
- Support URL: https://arvectum.com/contact.html
- Privacy Policy URL: https://arvectum.com/privacy
- Review/support email: info@arvectum.com

## App Privacy

For V1 select:

- No, we do not collect data from this app.
- Data used for tracking: No.
- Tracking / ATT: Not used.
- Third-party analytics SDK: None.
- Advertising SDK: None.
- Developer account/sign-in: None.

Reasoning for the release record:
- habit/check-in data is local-first;
- optional sync uses the user's private CloudKit database;
- private CloudKit content is owned by the user and isn't visible in the developer portal;
- there is no Arvectum server profile, analytics pipeline, ad SDK or data broker integration in V1.

If ads, analytics, accounts or a server backend are added later, update App Privacy before that version ships.

### Next ad-enabled release

Do **not** reuse the V1 "Data Not Collected" answer for the first build that contains Yandex Mobile Ads.

For the current Yandex Mobile Ads 8.5.0 integration, the embedded privacy manifests in the built app declare the following categories across YandexMobileAds and its transitive AppMetrica/KSCrash components:

- Device ID;
- Advertising Data;
- Coarse Location;
- Product Interaction;
- Purchase History;
- Crash Data;
- Performance Data;
- Other Diagnostic Data;
- Other Data Types.

The exact App Store Connect answers for that release must be reconciled against the Xcode privacy report from the **exact archive being submitted** and the runtime configuration. Current ChickMark configuration disables Yandex precise-location tracking and does not request ATT/IDFA; habit names, check-ins and other user content are not supplied to the advertising SDK for targeting.

At minimum, before submitting the first ad-enabled build:
- change the App Privacy record away from "Data Not Collected";
- verify every category/purpose/linked/tracking flag shown by the final privacy report;
- keep Tracking/ATT set to No unless the runtime behavior is intentionally changed;
- keep Privacy Policy URL set to https://arvectum.com/privacy.

## Export compliance

- ITSAppUsesNonExemptEncryption = NO is already embedded in the iPhone and Watch app Info.plists.
- ChickMark contains no custom/proprietary cryptography.
- No export-compliance documentation upload is expected for this build.

## Age rating questionnaire

ChickMark is a general-purpose habit tracker with no social feed or user-generated public content.

Use None / No for content descriptors and capabilities that don't exist, including:
- violence;
- sexual content or nudity;
- profanity or crude humor;
- horror/fear themes;
- alcohol/tobacco/drugs;
- gambling, simulated gambling, loot boxes;
- contests/sweepstakes;
- unrestricted web access;
- public user-generated content;
- social-media capabilities / social feed;
- messaging/chat;
- parental controls;
- age assurance;
- medical/treatment advice.

There are no purchases, external content feeds or community features in V1. Let App Store Connect calculate the regional age rating from these answers.

## Content rights

- ChickMark does not stream, display or redistribute third-party media/content.
- Arvectum owns or has the rights to the app artwork, copy and software included in the binary.
- No third-party content-rights declaration is expected.

## App Review

- Sign-in required: No.
- Demo account: Not required.
- Hardware dependency: No; Apple Watch support is optional.
- Notifications: local habit reminders only.
- Review note: use review-notes.md.

## Screenshots

Canonical submission files:

Russian:
- ../screenshots/ru-RU/01-today.png — 1320×2868
- ../screenshots/ru-RU/02-progress.png — 1320×2868
- ../screenshots/ru-RU/03-manage.png — 1320×2868
- ../screenshots/ru-RU/04-watch.png — 416×496

English:
- ../screenshots/en-US/01-today.png — 1320×2868
- ../screenshots/en-US/02-progress.png — 1320×2868
- ../screenshots/en-US/03-manage.png — 1320×2868
- ../screenshots/en-US/04-watch.png — 416×496

## Binary

Canonical local release artifact:
- Archive: /Users/master/ChickMarkRelease/1.0.0-build1-final/ChickMark.xcarchive
- IPA: /Users/master/ChickMarkRelease/1.0.0-build1-final/export/HabitsByArvectum.ipa
