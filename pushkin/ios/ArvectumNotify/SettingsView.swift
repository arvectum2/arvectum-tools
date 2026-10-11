import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CapturedNotification.capturedAt, order: .reverse)
    private var notifications: [CapturedNotification]

    @State private var showingDeleteAllConfirmation = false

    private let privacyURL = URL(
        string: "https://arvectum.com/privacy.html"
    )!
    private let supportURL = URL(string: "https://arvectum.com")!

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ArvectumBrandHeader(productName: "PUSHKIN")
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                List {
                    localSection
                    supportSection
                    aboutSection
#if DEBUG
                    debugSection
#endif
                }
                .scrollContentBackground(.hidden)
                .background(Color.arvectumBackground)
            }
            .background(Color.arvectumBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                "Delete all notification history?",
                isPresented: $showingDeleteAllConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    try? modelContext.delete(model: CapturedNotification.self)
                    try? modelContext.save()
                }
            } message: {
                Text("This cannot be undone. PUSHKIN setup and app coverage stay intact.")
            }
        }
    }

    private var localSection: some View {
        Section("On this iPhone") {
            LabeledContent(
                "Notifications saved",
                value: "\(notifications.count)"
            )

            Label(
                "Notification content stays on this device",
                systemImage: "lock.shield.fill"
            )
            Text(
                "Everything stays on this iPhone. No account, cloud sync, ads or analytics in version 1.0."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)

            Button(role: .destructive) {
                showingDeleteAllConfirmation = true
            } label: {
                Label("Delete all history", systemImage: "trash")
            }
            .disabled(notifications.isEmpty)
        }
    }

    private var supportSection: some View {
        Section("Help & feedback") {
            Link(destination: supportURL) {
                Label(
                    "Support and missing-app requests",
                    systemImage: "bubble.left.and.bubble.right"
                )
            }

            Text(
                "Missing an app? Send us its exact name. The most-requested apps move to the top of our update list."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
    private var aboutSection: some View {
        Section("About") {
            Link(destination: privacyURL) {
                Label("Privacy policy", systemImage: "hand.raised.fill")
            }

            LabeledContent("Product", value: "PUSHKIN")
            LabeledContent("Developer", value: "Arvectum")
            LabeledContent("Version", value: appVersion)

            Text("Never lose an important notification again.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

#if DEBUG
    private var debugSection: some View {
        Section("Developer") {
            NavigationLink {
                DiagnosticsView()
            } label: {
                Label("Diagnostics", systemImage: "waveform.path.ecg")
            }
        }
    }
#endif

    private var appVersion: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "—"
        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "—"
        return "\(version) (\(build))"
    }
}
