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

App Store privacy questionnaire working answer:
- Data used for tracking: No.
- Third-party advertising: No.
- Developer analytics: No.
- Data linked to identity via an Arvectum account: No.
- No server-side Arvectum user profile exists.

Before submission, verify the App Store Connect questionnaire against the exact Apple wording then current in the portal.
