# App Privacy Notes — ChickMark 1.0.0

Current V1 implementation:
- no Arvectum account or sign-in;
- no third-party analytics SDK;
- no advertising SDK in V1;
- no tracking;
- no sale of user data;
- habit data is stored local-first with SwiftData;
- private iCloud/CloudKit capability is used for Apple-device persistence/sync where available, with local fallback;
- iPhone ↔ Apple Watch sync uses WatchConnectivity;
- reminders are local notifications;
- Siri/Shortcuts and widgets use the same local/App Group state bridge.

App Store privacy questionnaire answer for V1:
- Data collection: **No, we do not collect data from this app.**
- Data used for tracking: No.
- Third-party advertising: No.
- Developer analytics: No.
- Data linked to identity via an Arvectum account: No.
- No server-side Arvectum user profile exists.

Private CloudKit data belongs to the user and is not visible in the developer portal. If ads, analytics, accounts or a server backend are added later, update the App Privacy answers before that version ships.
