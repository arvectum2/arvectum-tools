import SwiftUI

struct SetupGuideView: View {
    private let shortcutsURL = URL(string: "shortcuts://")!

    var body: some View {
        NavigationStack {
            List {
                phaseSection
                .headerProminence(.increased)
                chooseAppSection
                notifyActionSection
                backgroundSection
                verifySection
                privacySection
            }
            .navigationTitle("Setup")
        }
    }

    private var phaseSection: some View {
        Section("Phase 0") {
            Label("Requires iOS 27 notification automations", systemImage: "iphone.gen3")
            secondaryText("The feasibility spike uses one notification automation per source app.")
        }
    }

    private var chooseAppSection: some View {
        Section("1. Choose an app") {
            Text("Open Shortcuts and add a Notification automation.")
            Text("Choose one important app. Start with 3–5 apps for the spike.")
        }
    }

    private var notifyActionSection: some View {
        Section("2. Add the Notify action") {
            Text("Add Arvectum Notify → Archive Notification.")
            Text("Set Source app once, then set Title to the Notification magic variable. Arvectum Notify normalizes the iOS 27 text fallback into title and body.")
            Link("Open Shortcuts", destination: shortcutsURL)
        }
    }

    private var backgroundSection: some View {
        Section("3. Allow background capture") {
            Text("In the shortcut privacy settings, allow the automation to run while the device is locked.")
            Text("Keep any confirmation prompts disabled when iOS offers that option.")
        }
    }

    private var verifySection: some View {
        Section("4. Verify") {
            Text("Wait for a real notification from the selected app and confirm it appears in Inbox.")
            Text("Repeat with the app open, backgrounded, terminated, locked, Focus enabled and Low Power Mode enabled.")
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            Label("Stored on this iPhone", systemImage: "lock.shield")
            secondaryText("This spike has no account, backend, cloud sync or notification-content analytics.")
        }
    }

    private func secondaryText(_ value: String) -> some View {
        Text(value).foregroundStyle(.secondary)
    }
}
