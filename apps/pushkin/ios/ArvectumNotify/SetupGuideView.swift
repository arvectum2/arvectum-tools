import SwiftData
import SwiftUI

struct SetupGuideView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @Query(sort: \CapturedNotification.capturedAt, order: .reverse)
    private var notifications: [CapturedNotification]

    @AppStorage("coverage.quickRefreshCount")
    private var quickRefreshCount = 0

    @AppStorage("coverage.lastQuickRefreshName")
    private var lastQuickRefreshName = ""

    @AppStorage("coverage.lastQuickRefreshAt")
    private var lastQuickRefreshAt = 0.0

    @AppStorage("coverage.pendingAppName")
    private var pendingCoverageName = ""

    @AppStorage("coverage.pendingAppTitle")
    private var pendingCoverageTitle = ""

    @AppStorage("coverage.pendingStartedAt")
    private var pendingCoverageStartedAt = 0.0

    @State private var pendingBasePackageURL: URL?
    @State private var showAppPicker = false
    @State private var showingDeleteAllConfirmation = false

    private let privacyURL = URL(string: "https://arvectum.com/privacy.html")!
    private let supportURL = URL(
        string: "mailto:info@arvectum.com?subject=PUSHKIN%20support"
    )!

    private var setupVerified: Bool {
        !notifications.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                ArvectumPushkinHeader()
                    .padding(.horizontal, 2)

                setupCard
                dataCard
                footer

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
            .padding(.horizontal, 14)
            .padding(.top, 4)
            .padding(.bottom, 6)
            .background(Color.arvectumBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAppPicker) {
                CoverageAppPicker { app in
                    recordQuickRefresh(app)
                }
            }
            .background {
                ShortcutPackagePresenter(
                    packageURL: $pendingBasePackageURL
                ) {}
            }
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

    private var setupCard: some View {
        ArvectumCard {
            VStack(spacing: 11) {
                HStack(spacing: 10) {
                    Image(
                        systemName: setupVerified
                            ? "checkmark.seal.fill"
                            : "bolt.horizontal.circle"
                    )
                    .font(.title3)
                    .foregroundStyle(Color.arvectumMint)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(setupVerified ? "Capture active" : "Set up PUSHKIN")
                            .font(.headline)

                        if !setupVerified {
                            Text("One-time setup")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }

                if !setupVerified, let url = CoverageCatalog.basePackageURL {
                    Button {
                        if url.isFileURL {
                            pendingBasePackageURL = url
                        } else {
                            openURL(url)
                        }
                    } label: {
                        Label("Set up PUSHKIN", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("setup-pushkin-settings")
                }

                Divider()

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apps")
                            .font(.subheadline.weight(.semibold))
                        Text("\(CoverageCatalog.entries.count) built in")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        showAppPicker = true
                    } label: {
                        Label("Add app", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("add-app-from-settings-tab")
                }
                .frame(minHeight: 44)
            }
        }
    }

    private var dataCard: some View {
        ArvectumCard {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "iphone.and.arrow.forward")
                        .foregroundStyle(Color.arvectumMint)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("On this iPhone")
                            .font(.subheadline.weight(.semibold))
                        Text("\(notifications.count) notifications saved")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(role: .destructive) {
                        showingDeleteAllConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.borderless)
                    .disabled(notifications.isEmpty)
                    .accessibilityLabel("Delete history")
                    .accessibilityIdentifier("delete-all-history")
                }
                .frame(minHeight: 52)

                Divider()
                    .padding(.vertical, 7)

                HStack(spacing: 0) {
                    Link(destination: privacyURL) {
                        compactLink(
                            "Privacy",
                            systemImage: "hand.raised.fill"
                        )
                    }
                    .accessibilityIdentifier("privacy-policy")

                    Divider()
                        .frame(height: 30)
                        .padding(.horizontal, 8)

                    Link(destination: supportURL) {
                        compactLink(
                            "Support",
                            systemImage: "bubble.left.and.bubble.right.fill"
                        )
                    }
                    .accessibilityIdentifier("support-link")
                }
                .frame(minHeight: 44)
            }
        }
    }

    private var footer: some View {
        Text("Version \(appVersion)")
            .foregroundStyle(.secondary)
            .font(.caption2)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func compactLink(
        _ title: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .frame(width: 20)
            Text(title)
                .font(.subheadline)
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private func recordQuickRefresh(_ app: CoverageCatalogEntry) {
        let now = Date().timeIntervalSince1970
        lastQuickRefreshName = app.name
        lastQuickRefreshAt = now
        quickRefreshCount += 1
        pendingCoverageName = app.name
        pendingCoverageTitle = app.title
        pendingCoverageStartedAt = now
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
