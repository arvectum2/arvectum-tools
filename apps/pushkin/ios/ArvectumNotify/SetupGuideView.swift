import SwiftData
import SwiftUI

struct SetupGuideView: View {
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

    private var setupVerified: Bool {
        !notifications.isEmpty
    }

    private var sourceCount: Int {
        Set(notifications.map(\.sourceApp)).count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                statusCard
                appCard
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color.arvectumBackground.ignoresSafeArea())
            .navigationTitle("Apps")
            .navigationBarTitleDisplayMode(.inline)
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
        }
    }

    private var statusCard: some View {
        ArvectumCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(
                        systemName: setupVerified
                            ? "checkmark.seal.fill"
                            : "bolt.horizontal.circle"
                    )
                    .font(.title3)
                    .foregroundStyle(Color.arvectumMint)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(setupVerified ? "PUSHKIN is active" : "One-time setup")
                            .font(.headline)

                        Text(
                            setupVerified
                                ? "\(sourceCount) apps connected · \(notifications.count) saved"
                                : "Connect notification capture once."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                    .accessibilityIdentifier("setup-pushkin-apps")
                }
            }
        }
    }

    private var appCard: some View {
        ArvectumCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(CoverageCatalog.entries.count) apps built in")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Button {
                    showAppPicker = true
                } label: {
                    Label("Add app", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("add-app-from-apps-tab")
            }
        }
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
}
