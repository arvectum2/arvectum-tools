# App Review Notes — ChickMark 1.4.1 (public candidate build 15)

ChickMark is a local-first habit tracker. No account, login, purchase, subscription or reviewer credentials are needed.

New in 1.4.1:
- User may optionally link individual habits to Apple Health steps, walking/running distance, running workouts or sleep rules. Ask for read-only HealthKit consent only after user selects a metric and target.
- Today may show current/target Health progress and a derived completion checkmark. No raw HealthKit samples are sent to Arvectum, CloudKit, Yandex or analytics endpoints. Automatic completion is local and ephemeral, with Watch-side reads of already-authorized Health data.
- Apple Watch companion and face complications: open Watch ChickMark once, allow Health permissions, then add the ChickMark complication to a supported face. When the Watch Health step goal is exceeded, the Watch app and complication reflect the goal. Background delivery and WidgetKit display are OS-scheduled, NOT real-time guarantees.
- Habit creation/edit sheet includes a compact down-arrow on the numeric step target keyboard.
- Users can continue marking/checking habits manually and use widgets and reminders without granting Health permissions.

Advertising / third-party SDK:
- ChickMark uses Yandex Mobile Ads SDK for one unobtrusive Today banner only after three days from first launch, five cold launches and three completed check-offs. It does not interrupt habit check-offs or creation. No ads are shown to newly installed users.
- SDK configuration requests neither location tracking nor SDK user consent; debug ad logs are disabled in App Store releases.
- Yandex SDK and transitive AppMetrica/KSCrash components are included in the binary. Third-party SDK privacy manifest disclosures must be reflected accurately in App Store Connect App Privacy before review. Do not claim the binary is entirely Apple-framework-only or that no third-party SDK exists.

Privacy and data handling:
- Local habit data is saved in SwiftData and optionally synced through the user's private CloudKit; WatchConnectivity sync is used between the paired Watch and iPhone.
- Raw HealthKit readings are processed on-device only; step samples are never persisted in CloudKit, analytics, advertising requests or app-group widget caches. The Watch complication reads on-device HealthKit directly on WidgetKit refresh.
- Production CloudKit, production APNs, Apple Health entitlement and App Group are included; app has no Arvectum accounts or custom backend.
- Privacy policy: https://arvectum.com/privacy ; support: https://arvectum.com/contact.html

Manual tester protocol:
1. Create a regular habit, check it manually, view history and manage habits.
2. Optionally create a step-linked habit, allow Health read access, set a step goal below today's current count. Open ChickMark on Apple Watch; it should complete there, then the complication may update asynchronously.
3. Deny Health permission: manual check-ins and navigation continue working normally. No permissions are required to use the app.

Build 15 differs from owner-accepted internal TestFlight build 14 only by coordinated build numbers and public distribution eligibility, not the HealthKit behavior or persistence schema.
