# App Review response — Guideline 2.1 Information Needed

Status: **draft only — do not send without product-owner approval**

Submission: iOS 1.0 / build 1.0.0 (1)
Submission ID: cdfab018-5637-402a-a87f-3b8eb2c59beb

## Reply to App Review

Hello App Review Team,

Thank you for the request. PUSHKIN is ready for review. The requested information is below.

1. **Physical-device screen recording**
   We will attach a recording captured on a physical iPhone running iOS 27.0.1. It begins with launching PUSHKIN and demonstrates the normal flow: initial setup, Shortcuts handoff, enabling notification capture, receiving a real notification, viewing it in History, searching the history, and adding another supported app.

2. **Purpose, target audience, problem and value**
   PUSHKIN is a consumer utility for iPhone users who want a searchable local history of notifications they may otherwise dismiss or lose. Its main value is preserving selected notification content locally on the device so users can find important alerts later.

3. **Setup and access**
   No login, registration, subscription, purchase, credentials, or sample files are required.
   - Launch PUSHKIN.
   - Open the Apps tab and tap **Set up PUSHKIN**.
   - PUSHKIN opens Apple's Shortcuts app with the bundled signed configuration.
   - Add the shortcut/automation and allow it to run automatically when iOS asks.
   - Return to PUSHKIN. Matching notifications are archived locally and appear in History.
   - For a supported app installed later, tap **+** / **Add app** and select it.
   - If an app is not in the bundled catalog, PUSHKIN provides a manual Shortcuts setup guide.

4. **External services, tools and platforms**
   Core functionality uses only Apple platform technologies: Shortcuts / Automation, App Intents, SwiftData, and standard iOS APIs. PUSHKIN 1.0 has no backend, account service, cloud sync, payment processor, analytics SDK, advertising SDK, AI service, or third-party data provider. Notification content is not sent to Arvectum servers.

5. **Regional differences**
   PUSHKIN's core functionality is the same in all App Store regions. The bundled supported-app catalog is maintained across storefronts, and uncommon apps can be configured manually.

6. **Regulated industry / protected third-party material**
   PUSHKIN does not operate in a regulated industry and does not provide or resell protected third-party content. App names are used only to identify user-selected notification sources.

Thank you.
