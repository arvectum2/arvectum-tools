import SwiftData
import SwiftUI

struct SetupGuideView: View {
    @Query(sort: \CapturedNotification.capturedAt, order: .reverse)
    private var notifications: [CapturedNotification]

    private let shortcutsURL = URL(string: "shortcuts://")!

    private var sourceCount: Int {
        Set(notifications.map(\.sourceApp)).count
    }

    var body: some View {
        NavigationStack {
            List {
                phaseSection
                    .headerProminence(.increased)
                chooseAppsSection
                mappingSection
                backgroundSection
                verifySection
                privacySection
            }
            .navigationTitle("Setup")
        }
    }

    private var phaseSection: some View {
        Section("Phase 0") {
            Label(
                "Requires iOS 27 notification automations",
                systemImage: "iphone.gen3"
            )
            secondaryText(
                "One Notification trigger can monitor several selected apps."
            )
        }
    }

    private var chooseAppsSection: some View {
        Section("1. Choose apps") {
            Text("Open Shortcuts and edit Archive Notification.")
            Text(
                "Add a Notification automation, choose one app, then use + to add more apps to the same trigger."
            )
            Link("Open Shortcuts", destination: shortcutsURL)
        }
    }

    private var mappingSection: some View {
        Section("2. Map notification fields") {
            mappingRow("Source app", "App")
            mappingRow("Title", "Title")
            mappingRow("Subtitle", "Subtitle")
            mappingRow("Message", "Text")

            secondaryText(
                "For each value, choose the Notification magic variable and then the property shown above."
            )
        }
    }

    private var backgroundSection: some View {
        Section("3. Allow background capture") {
            Text(
                "In the shortcut privacy settings, enable Allow Running When Locked."
            )
            Text(
                "Keep confirmation prompts disabled when iOS offers that option."
            )
        }
    }

    private var verifySection: some View {
        Section("4. Verify") {
            if let last = notifications.first {
                Label("Capture verified", systemImage: "checkmark.seal.fill")
                LabeledContent("Captured", value: "\(notifications.count)")
                LabeledContent("Source apps", value: "\(sourceCount)")
                LabeledContent(
                    "Latest",
                    value: last.capturedAt.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                secondaryText(
                    "Your automation has successfully written notification data to Arvectum Notify."
                )
            } else {
                Label(
                    "Waiting for the first capture",
                    systemImage: "hourglass"
                )
                Text(
                    "Send one real notification from a selected app. This screen will confirm setup automatically."
                )
            }
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            Label("Stored on this iPhone", systemImage: "lock.shield")
            secondaryText(
                "No account, backend, cloud sync or notification-content analytics."
            )
        }
    }

    private func mappingRow(
        _ parameter: String,
        _ property: String
    ) -> some View {
        LabeledContent(parameter) {
            Text("Notification → \(property)")
                .foregroundStyle(.secondary)
        }
    }

    private func secondaryText(_ value: String) -> some View {
        Text(value).foregroundStyle(.secondary)
    }
}
