App Review Notes — ChickMark 1.1.0 (Build 3)

1. PURPOSE / TARGET AUDIENCE
ChickMark is a simple local-first habit tracker for individual users. Version 1.1 adds one-time reminders for a specific date and time plus an optional completion-relative habit schedule (“N days after actual completion”). One-time reminders are intentionally separate from habits: they do not affect streaks, completion rate, calendar history, widgets, or Apple Watch habit synchronization. Completion-relative habits remain part of the existing Habit model and do not add fields to the published CloudKit schema.

2. REVIEW ACCESS / SETUP
No account, registration, login, demo credentials, subscription, purchase, or sample files are required.

Suggested iPhone review flow:
- Launch ChickMark.
- Tap + and choose New habit to create/check off a habit. Under Other schedule, “Repeat after completion” can be enabled and configured as an N-day interval.
- Tap + and choose One-time reminder.
- Enter a title and a future date/time, then save.
- Grant local notification permission if requested.
- The reminder appears in the Reminders section on Today.
- The reminder can be edited/deleted from its overflow menu or completed from Today.
- Its notification includes a Done action.

Apple Watch behavior is unchanged from version 1.0: habit state synchronizes through WatchConnectivity; one-time reminders are iPhone-local and are not part of the Watch habit model.

3. EXTERNAL SERVICES / APPLE FRAMEWORKS
Core habit/reminder functionality uses Apple frameworks:
- SwiftUI / SwiftData for UI and persistence.
- The user's private iCloud / CloudKit database for the existing habit model when iCloud is available, with local fallback.
- A separate local-only SwiftData store for one-time reminders. One-time reminders are not added to the CloudKit schema.
- WatchConnectivity for paired iPhone/Apple Watch habit synchronization.
- UserNotifications for local habit and one-time reminders.
- WidgetKit / AppIntents for widgets, complications, Siri and Shortcuts.

Version 1.1 also includes Yandex Mobile Ads SDK for a single sticky banner at the bottom of Today. There are no App Open Ads and no interstitial ads. Ads are delayed for new users and therefore may not be visible during a fresh review session.

4. ADVERTISING / PRIVACY CONFIGURATION
- Precise location sharing to Yandex Mobile Ads is disabled in the app configuration.
- ChickMark does not request App Tracking Transparency / IDFA in version 1.1.
- Habit names, check-ins, one-time reminder text, and other user-created content are not supplied to the advertising SDK for ad targeting.
- The ad is displayed in a dedicated bottom safe-area slot and does not appear between habits or cover the scrollable content.
- Privacy Policy URL: https://arvectum.com/privacy

The App Store Privacy questionnaire for this version was re-audited against the exact exported IPA, its embedded privacy manifests, Yandex Mobile Ads documentation, and ChickMark runtime settings.

5. BUSINESS MODEL
ChickMark remains free. There is no In-App Purchase, subscription, premium tier, paid unlock, external checkout, or paid digital content. Version 1.1 is monetized by the Today banner described above.

6. REGIONAL DIFFERENCES
Core app features are consistent across supported App Store territories. Advertising fill/content can vary by advertising provider and territory.

7. REGULATED / THIRD-PARTY CONTENT
ChickMark is a general-purpose habit tracker, not a regulated medical device or medical service. It does not provide diagnosis or treatment. It contains no public user-generated content.

Version: 1.1.0
Build: 3
Bundle ID: ru.arvectum.tools.habits
