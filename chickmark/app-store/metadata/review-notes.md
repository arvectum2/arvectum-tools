App Review Notes — ChickMark 1.0.0 (Build 1)

1. PURPOSE / TARGET AUDIENCE
ChickMark is a simple local-first habit tracker for individual users who want to build and maintain everyday routines with minimal setup. Users create habits, check them off, review streaks/history, and can use reminders, widgets, Apple Watch, complications, Siri/Shortcuts actions, and WatchConnectivity sync.

2. REVIEW ACCESS / SETUP
No account, registration, login, demo credentials, subscription, purchase, or sample files are required. All user-facing features are immediately available.

Typical iPhone flow:
- Launch ChickMark.
- Tap + and create a habit.
- Mark the habit complete from Today.
- Tap the habit to view streak/history.
- Optionally configure a local reminder.
- Manage habits from the menu.

Apple Watch flow:
- Install/open the bundled ChickMark Watch app.
- Habits synchronize with the iPhone companion through Apple Watch WatchConnectivity.
- A habit can be checked off on either device and the state synchronizes to the paired device.
- The app also provides Watch complications and iPhone Home/Lock Screen widgets.

3. EXTERNAL SERVICES / APPLE FRAMEWORKS
There is no Arvectum backend and no third-party SDK in this build. Core functionality uses Apple frameworks only:
- SwiftUI / SwiftData for the app and local storage.
- The user's private Apple iCloud / CloudKit database for optional private sync across the user's Apple devices when iCloud is available.
- WatchConnectivity for paired iPhone/Apple Watch synchronization.
- UserNotifications for local habit reminders.
- WidgetKit / AppIntents for widgets, complications, Siri and Shortcuts.
Habit data is not sent to or stored on Arvectum servers.

4. PRIVACY / DATA HANDLING
LLC ARVECTUM does not collect user habit data, analytics, advertising identifiers, browsing data, location, contacts, health data, or tracking data in this build. There is no advertising SDK or analytics SDK. Privacy manifests declare no collected data and no tracking. Reminder notifications are local notifications.

5. BUSINESS MODEL
ChickMark 1.0 is free. There is no In-App Purchase, subscription, premium tier, paid unlock, external checkout, paid digital content, or previously purchased content accessible in the app.

6. REGIONAL DIFFERENCES
The app functions consistently in all App Store territories where it is offered. There are no region-specific accounts, pricing, features, content, or integrations.

7. REGULATED / THIRD-PARTY CONTENT
ChickMark is a general-purpose habit tracker, not a regulated medical device or medical service. It does not provide diagnosis or treatment. It contains no public user-generated content and no protected third-party content requiring authorization.

8. REVIEW MEDIA / QA
The attached App Review video is captured from a physical iPhone 13 running iOS 27.0.1 and demonstrates the exact submitted 1.0.0 build 1 core flow: launch, habit creation, check-in, and the Last 6 weeks history view. The Apple Watch companion and WatchConnectivity synchronization were additionally tested on a paired physical Apple Watch SE; the Apple Watch review steps are listed above.

Version: 1.0.0
Build: 1
Bundle ID: ru.arvectum.tools.habits
