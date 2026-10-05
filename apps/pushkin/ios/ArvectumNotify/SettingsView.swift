import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CapturedNotification.capturedAt, order: .reverse)
    private var notifications: [CapturedNotification]

    @State private var showingDeleteAllConfirmation = false

    private let privacyURL = URL(string: "https://arvectum.com/privacy")!
    private let supportURL = URL(
        string: "mailto:info@arvectum.com?subject=PUSHKIN%20support"
    )!

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                storageCard
                linksCard
                aboutLine
                Spacer(minLength: 0)

#if DEBUG
                if ProcessInfo.processInfo.environment[
                    "PUSHKIN_SHOW_DIAGNOSTICS"
                ] == "1" {
                    NavigationLink {
                        DiagnosticsView()
                    } label: {
                        Label("Diagnostics", systemImage: "waveform.path.ecg")
                            .font(.caption)
                    }
                }
#endif
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color.arvectumBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
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
                Text("This cannot be undone.")
            }
        }
    }

    private var storageCard: some View {
        ArvectumCard {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "iphone.and.arrow.forward")
                        .font(.title3)
                        .foregroundStyle(Color.arvectumMint)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("On this iPhone")
                            .font(.headline)
                        Text("\(notifications.count) notifications saved")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                Divider()

                Button(role: .destructive) {
                    showingDeleteAllConfirmation = true
                } label: {
                    HStack {
                        Label("Delete history", systemImage: "trash")
                        Spacer()
                    }
                    .frame(minHeight: 44)
                }
                .disabled(notifications.isEmpty)
                .accessibilityIdentifier("delete-all-history")
            }
        }
    }

    private var linksCard: some View {
        ArvectumCard {
            VStack(spacing: 0) {
                Link(destination: privacyURL) {
                    settingsRow(
                        "Privacy policy",
                        systemImage: "hand.raised.fill"
                    )
                }
                .accessibilityIdentifier("privacy-policy")

                Divider()
                    .padding(.vertical, 10)

                Link(destination: supportURL) {
                    settingsRow(
                        "Support / request an app",
                        systemImage: "bubble.left.and.bubble.right.fill"
                    )
                }
                .accessibilityIdentifier("support-link")
            }
        }
    }

    private var aboutLine: some View {
        Text("Version \(appVersion)")
            .foregroundStyle(.secondary)
            .font(.caption)
    }

    private func settingsRow(
        _ title: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .frame(width: 24)
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

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
