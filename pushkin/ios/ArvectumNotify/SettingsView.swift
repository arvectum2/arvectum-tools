import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CapturedNotification.capturedAt, order: .reverse)
    private var notifications: [CapturedNotification]

    @State private var showingDeleteAllConfirmation = false
    @State private var deleteError: String?

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
            .frame(maxWidth: 960)
            .frame(maxWidth: .infinity)
            .background(Color.arvectumBackground.ignoresSafeArea())
            .navigationTitle(pc("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                pc("Delete all notification history?"),
                isPresented: $showingDeleteAllConfirmation,
                titleVisibility: .visible
            ) {
                Button(pc("Delete All"), role: .destructive) {
                    do {
                        try NotificationHistoryDeletion.deleteAll(in: modelContext)
                    } catch {
                        deleteError = error.localizedDescription
                    }
                }
            } message: {
                Text(pc("This cannot be undone. PUSHKIN setup and app coverage stay intact."))
            }
            .alert(pc("Couldn’t clear history"), isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("OK", role: .cancel) { deleteError = nil }
            } message: {
                Text(deleteError ?? pc("Please try again."))
            }
        }
    }

    private var localSection: some View {
        Section(pc("On this iPhone")) {
            LabeledContent(
                pc("Notifications saved"),
                value: "\(notifications.count)"
            )

            Label(
                pc("Notification content stays on this device"),
                systemImage: "lock.shield.fill"
            )
            Text(
                pc("Everything stays on this iPhone. No account, cloud sync, ads or analytics in version 1.0.")
            )
            .font(.footnote)
            .foregroundStyle(.secondary)

            Button(role: .destructive) {
                showingDeleteAllConfirmation = true
            } label: {
                Label(pc("Delete all history"), systemImage: "trash")
            }
            .disabled(notifications.isEmpty)
        }
    }

    private var supportSection: some View {
        Section(pc("Help & feedback")) {
            Link(destination: supportURL) {
                Label(
                    pc("Support and missing-app requests"),
                    systemImage: "bubble.left.and.bubble.right"
                )
            }

            Text(
                pc("Missing an app? Send us its exact name. The most-requested apps move to the top of our update list.")
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
    private var aboutSection: some View {
        Section(pc("About")) {
            Link(destination: privacyURL) {
                Label(pc("Privacy policy"), systemImage: "hand.raised.fill")
            }

            LabeledContent(pc("Product"), value: "PUSHKIN")
            LabeledContent(pc("Developer"), value: "Arvectum")
            LabeledContent(pc("Version"), value: appVersion)

            Text(pc("Review notifications captured from apps you connected."))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

#if DEBUG
    private var debugSection: some View {
        Section(pc("Developer")) {
            NavigationLink {
                DiagnosticsView()
            } label: {
                Label(pc("Diagnostics"), systemImage: "waveform.path.ecg")
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
