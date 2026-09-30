import SwiftData
import SwiftUI

struct SetupGuideView: View {
    @Environment(\.openURL) private var openURL

    @Query(sort: \CapturedNotification.capturedAt, order: .reverse)
    private var notifications: [CapturedNotification]

    @State private var pendingBasePackageURL: URL?

    private let automationsURL = URL(string: "shortcuts://automations")!

    private var sourceCount: Int {
        Set(notifications.map(\.sourceApp)).count
    }

    var body: some View {
        NavigationStack {
            List {
                phaseSection
                    .headerProminence(.increased)
                chooseAppsSection
                coverageRefreshSection
                mappingSection
                backgroundSection
                verifySection
                privacySection
            }
            .navigationTitle("Setup")
            .background {
                ShortcutPackagePresenter(
                    packageURL: $pendingBasePackageURL
                ) {}
            }
        }
    }

    private var phaseSection: some View {
        Section("Compatibility") {
            Label(
                "iOS 27 or later",
                systemImage: "iphone.gen3"
            )
            secondaryText(
                "PUSHKIN uses the system Notification automation in Shortcuts."
            )
        }
    }

    private var chooseAppsSection: some View {
        Section("1. Turn on PUSHKIN") {
            if let url = CoverageCatalog.basePackageURL {
                Button {
                    if url.isFileURL {
                        pendingBasePackageURL = url
                    } else {
                        openURL(url)
                    }
                } label: {
                    Label(
                        "Install notification coverage",
                        systemImage: "wand.and.stars"
                    )
                }
            }

            secondaryText(
                "Add the signed PUSHKIN configuration once, then enable its automation. No app-by-app selection is required during onboarding."
            )

            Link(destination: automationsURL) {
                Label(
                    "Open Automation",
                    systemImage: "switch.2"
                )
            }
        }
    }

    private var coverageRefreshSection: some View {
        Section("App coverage") {
            NavigationLink {
                CoverageView()
            } label: {
                Label("Manage app coverage", systemImage: "square.stack.3d.up")
            }
            secondaryText(
                "New apps use one-app refresh configurations. PUSHKIN never rebuilds the whole catalog during normal use."
            )
        }
    }

    private var mappingSection: some View {
        Section("Configured automatically") {
            Label(
                "Notification fields are already mapped",
                systemImage: "checkmark.circle"
            )
            secondaryText(
                "The signed PUSHKIN configuration already passes the app, title, subtitle and message into the local archive."
            )
        }
    }

    private var backgroundSection: some View {
        Section("If iOS asks") {
            Text(
                "Allow the PUSHKIN shortcut to run while the iPhone is locked."
            )
            secondaryText(
                "This is a system privacy confirmation, not a recurring setup step."
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
                    "Your automation has successfully written notification data to PUSHKIN."
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
