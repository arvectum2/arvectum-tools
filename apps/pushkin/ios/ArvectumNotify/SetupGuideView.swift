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
            VStack(spacing: 0) {
                ArvectumBrandHeader(productName: "PUSHKIN")
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                List {
                    chooseAppsSection
                    coverageRefreshSection
                    backgroundSection
                    verifySection
                    privacySection
                }
                .scrollContentBackground(.hidden)
                .background(Color.arvectumBackground)
            }
            .background(Color.arvectumBackground.ignoresSafeArea())
            .navigationTitle("Apps & Setup")
            .navigationBarTitleDisplayMode(.inline)
            .background {
                ShortcutPackagePresenter(
                    packageURL: $pendingBasePackageURL
                ) {}
            }
        }
    }

    private var chooseAppsSection: some View {
        Section("Turn on PUSHKIN") {
            if let url = CoverageCatalog.basePackageURL {
                Button {
                    if url.isFileURL {
                        pendingBasePackageURL = url
                    } else {
                        openURL(url)
                    }
                } label: {
                    Label(
                        "Set up notification history",
                        systemImage: "wand.and.stars"
                    )
                }
            }

            secondaryText(
                "Add PUSHKIN in Shortcuts once, then enable the automation when iOS asks. You do not need to select apps one by one."
            )

            Link(destination: automationsURL) {
                Label(
                    "Open Shortcuts Automation",
                    systemImage: "switch.2"
                )
            }
        }
    }

    private var coverageRefreshSection: some View {
        Section("Add more apps") {
            NavigationLink {
                CoverageView()
            } label: {
                Label("Add or manage apps", systemImage: "square.stack.3d.up")
            }
            secondaryText(
                "Installed something new? Add it here. Most supported apps take only a few taps."
            )
        }
    }

    private var backgroundSection: some View {
        Section("If iOS asks") {
            Text(
                "Allow the PUSHKIN shortcut to run while the iPhone is locked."
            )
            secondaryText(
                "This is an iOS confirmation you should normally see only during setup."
            )
        }
    }

    private var verifySection: some View {
        Section("Status") {
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
                "No account, cloud sync, ads or analytics. Notification content stays on this iPhone."
            )
        }
    }

    private func secondaryText(_ value: String) -> some View {
        Text(value).foregroundStyle(.secondary)
    }
}
