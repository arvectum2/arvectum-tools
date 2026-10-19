import SwiftData
import SwiftUI

/// Guided setup for the signed 1000-app base package and optional refreshes.
/// Apple Shortcuts remains the source of truth for automation enablement.
struct SetupGuideView: View {
    @Environment(\.openURL) private var openURL

    @Query(sort: \CapturedNotification.capturedAt, order: .reverse)
    private var notifications: [CapturedNotification]

    @State private var pendingBasePackageURL: URL?

    @AppStorage("pushkin.setup.lastBaseHandoffAt")
    private var lastBaseHandoffAt = 0.0

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

                NavigationLink {
                    CoverageView()
                } label: {
                    Label(pc("Add or manage apps"), systemImage: "plus.app")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                }
                .accessibilityIdentifier("setup-quick-add")
                .padding(.horizontal, 14)
                .padding(.bottom, 6)

                List {
                    overviewSection
                    basePackageSection
                    enableSection
                    verifySection
                    coverageRefreshSection
                    optionalGroupsSection
                    privacySection
                }
                .scrollContentBackground(.hidden)
                .background(Color.arvectumBackground)
            }
            .frame(maxWidth: 960)
            .frame(maxWidth: .infinity)
            .background(Color.arvectumBackground.ignoresSafeArea())
            .navigationTitle(pc("Apps & Setup"))
            .navigationBarTitleDisplayMode(.inline)
            .background {
                ShortcutPackagePresenter(
                    packageURL: $pendingBasePackageURL
                ) {
                    // Shortcuts opening is NOT evidence of installation,
                    // user approval or that the automation is enabled.
                    lastBaseHandoffAt = Date().timeIntervalSince1970
                }
            }
        }
    }

    private var overviewSection: some View {
        Section(pc("Before you start")) {
            Label(pc("PUSHKIN works through Apple Shortcuts"), systemImage: "switch.2")
            secondaryText(
                pc("iOS does not allow PUSHKIN to read every app's notifications or turn on automations itself. You control which apps are included.")
            )
            secondaryText(
                pc("The base shortcut includes 1,000 entries. Only apps recognized by Shortcuts when you configure the automation can send captures.")
            )
        }
    }

    private var basePackageSection: some View {
        Section(pc("1. Add PUSHKIN")) {
            if let url = CoverageCatalog.basePackageURL {
                Button {
                    if url.isFileURL {
                        pendingBasePackageURL = url
                    } else {
                        openURL(url)
                    }
                } label: {
                    Label(pc("Open base shortcut in Shortcuts"), systemImage: "wand.and.stars")
                }
                .accessibilityIdentifier("setup-base-automation")
            } else {
                Label(pc("Base shortcut is unavailable"), systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
            }

            if lastBaseHandoffAt > 0 {
                Label(pc("Shortcuts was opened — finish setup there"), systemImage: "arrow.up.right")
                    .foregroundStyle(.secondary)
                secondaryText(
                    pc("Opening the preview does not mean you tapped Add or enabled the automation.")
                )
            }

            secondaryText(
                pc("Review the app list and tap Add in Shortcuts. You do not have to manually select all 1,000 catalog apps.")
            )
        }
    }

    private var enableSection: some View {
        Section(pc("2. Enable the automation")) {
            Link(destination: automationsURL) {
                Label(pc("Open Shortcuts automations"), systemImage: "switch.2")
            }
            .accessibilityIdentifier("open-setup-automations")
            secondaryText(
                pc("Newly imported Notification automations are disabled. Find PUSHKIN, enable it and select the automatic/immediate option if Shortcuts offers it.")
            )
            secondaryText(
                pc("Only Shortcuts knows whether an automation is enabled. PUSHKIN cannot check or change that switch.")
            )
        }
    }

    private var verifySection: some View {
        Section(pc("3. Check a real notification")) {
            if let last = notifications.first {
                Label(pc("At least one capture received"), systemImage: "checkmark.seal.fill")
                LabeledContent(pc("Captured records"), value: "\(notifications.count)")
                LabeledContent(pc("Observed source apps"), value: "\(sourceCount)")
                LabeledContent(
                    pc("Latest"),
                    value: last.capturedAt.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .accessibilityIdentifier("setup-capture-observed")
                secondaryText(
                    pc("This proves PUSHKIN received a notification from at least one source. It does not prove that all selected apps are covered or that the automation is still enabled.")
                )
            } else {
                Label(pc("Waiting for first capture"), systemImage: "hourglass")
                secondaryText(
                    pc("Send one real notification from an app already installed and included in Shortcuts. Return to History to check the result.")
                )
            }
        }
    }

    private var coverageRefreshSection: some View {
        Section(pc("When you install another app")) {
            NavigationLink {
                CoverageView()
            } label: {
                Label(pc("Add or manage apps"), systemImage: "plus.app")
            }
            .accessibilityIdentifier("setup-add-app")
            secondaryText(
                pc("An app installed after the base shortcut was imported is not automatically connected, even if it is in the 1,000-app catalog. Import its signed one-app shortcut, enable it and verify a real notification.")
            )
        }
    }

    private var optionalGroupsSection: some View {
        Section(pc("Optional: smaller groups")) {
            NavigationLink {
                AutomationGroupPlannerView()
            } label: {
                Label(pc("Plan groups of apps"), systemImage: "square.stack.3d.up")
            }
            .accessibilityIdentifier("setup-optional-groups")
            secondaryText(
                pc("If you prefer multiple Notification automations, prepare a local checklist. Groups of 25 are a convenience, not an Apple limitation, and must be configured manually.")
            )
        }
    }

    private var privacySection: some View {
        Section(pc("Privacy")) {
            Label(pc("Stored on this iPhone"), systemImage: "lock.shield")
            secondaryText(
                pc("No account, cloud sync, ads or analytics. PUSHKIN stores your notification content on this iPhone only.")
            )
        }
    }

    private func secondaryText(_ value: String) -> some View {
        Text(value).foregroundStyle(.secondary)
    }
}
