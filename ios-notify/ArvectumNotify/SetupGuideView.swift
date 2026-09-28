import AppIntents
import SwiftUI

struct SetupGuideView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label(
                        "Requires iOS 27 notification automations",
                        systemImage: "iphone.gen3"
                    )
                    Text(
                        "The feasibility spike uses one notification automation per source app."
                    )
                    .foregroundStyle(.secondary)
                } header: {
                    Text("Phase 0")
                }

                Section("1. Choose an app") {
                    Text("Open Shortcuts and add a Notification automation.")
                    Text("Choose one important app. Start with 3–5 apps for the spike.")
                }

                Section("2. Add the Notify action") {
                    Text("Add Arvectum Notify → Archive Notification.")
                    Text(
                        "Set Source app once, then map Title, Subtitle and Message from the notification trigger."
                    )
                    ShortcutsLink()
                }

                Section("3. Allow background capture") {
                    Text(
                        "In the shortcut privacy settings, allow the automation to run while the device is locked."
                    )
                    Text(
                        "Keep any confirmation prompts disabled when iOS offers that option."
                    )
                }

                Section("4. Verify") {
                    Text(
                        "Wait for a real notification from the selected app and confirm it appears in Inbox."
                    )
                    Text(
                        "Repeat with the app open, backgrounded, terminated, locked, Focus enabled and Low Power Mode enabled."
                    )
                }

                Section("Privacy") {
                    Label("Stored on this iPhone", systemImage: "lock.shield")
                    Text(
                        "This spike has no account, backend, cloud sync or notification-content analytics."
                    )
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Setup")
        }
    }
}
