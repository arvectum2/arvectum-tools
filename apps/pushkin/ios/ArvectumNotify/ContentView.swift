import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            InboxView()
                .tabItem {
                    Label("Inbox", systemImage: "tray.full")
                }

            SetupGuideView()
                .tabItem {
                    Label("Setup", systemImage: "wand.and.stars")
                }

            DiagnosticsView()
                .tabItem {
                    Label("Diagnostics", systemImage: "waveform.path.ecg")
                }
        }
    }
}

private struct InboxView: View {
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

    @State private var showAppPicker = false
    @State private var pendingBasePackageURL: URL?

    private let automationsURL = URL(string: "shortcuts://automations")!

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !pendingCoverageTitle.isEmpty {
                    pendingCoverageCard
                }

                Group {
                    if notifications.isEmpty {
                    VStack(spacing: 18) {
                        ContentUnavailableView(
                            "Never lose a notification",
                            systemImage: "bell.badge",
                            description: Text(
                                "Set up PUSHKIN once, then incoming notifications can be archived automatically."
                            )
                        )

                        if let url = CoverageCatalog.basePackageURL {
                            Button {
                                if url.isFileURL {
                                    pendingBasePackageURL = url
                                } else {
                                    openURL(url)
                                }
                            } label: {
                                Label(
                                    "Set up PUSHKIN",
                                    systemImage: "wand.and.stars"
                                )
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("setup-pushkin")
                        }

                        Link(destination: automationsURL) {
                            Label(
                                "Enable PUSHKIN automation",
                                systemImage: "switch.2"
                            )
                        }
                        .font(.footnote)
                        .accessibilityIdentifier("enable-pushkin-automation")
                    }
                    .padding()
                    } else {
                        List(notifications) { item in
                            NavigationLink {
                                NotificationDetailView(item: item)
                            } label: {
                                NotificationRow(item: item)
                            }
                        }
                    }
                }
            }
            .navigationTitle("PUSHKIN")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAppPicker = true
                    } label: {
                        Label(
                            "Add app",
                            systemImage: "plus.app"
                        )
                    }
                    .accessibilityIdentifier("add-app")
                }
            }
            .sheet(isPresented: $showAppPicker) {
                CoverageAppPicker { app in
                    let now = Date().timeIntervalSince1970
                    lastQuickRefreshName = app.name
                    lastQuickRefreshAt = now
                    quickRefreshCount += 1
                    pendingCoverageName = app.name
                    pendingCoverageTitle = app.title
                    pendingCoverageStartedAt = now
                }
            }
            .background {
                ShortcutPackagePresenter(
                    packageURL: $pendingBasePackageURL
                ) {}
            }
        }
    }

    private var pendingCoverageVerified: Bool {
        guard pendingCoverageStartedAt > 0 else { return false }

        let candidates = [
            pendingCoverageTitle,
            pendingCoverageName
        ]
        .map(normalizedAppName)
        .filter { !$0.isEmpty }

        return notifications.contains { item in
            guard item.capturedAt.timeIntervalSince1970
                >= pendingCoverageStartedAt - 2
            else {
                return false
            }

            let source = normalizedAppName(item.sourceApp)
            guard !source.isEmpty else { return false }

            return candidates.contains { candidate in
                candidate == source
                    || candidate.contains(source)
                    || source.contains(candidate)
            }
        }
    }

    private var pendingCoverageCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                pendingCoverageVerified
                    ? "Coverage verified"
                    : "Finish adding \(pendingCoverageTitle)",
                systemImage: pendingCoverageVerified
                    ? "checkmark.seal.fill"
                    : "switch.2"
            )
            .font(.headline)

            if pendingCoverageVerified {
                Text(
                    "PUSHKIN has captured a notification from \(pendingCoverageTitle). Coverage is active."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Button("Done") {
                    clearPendingCoverage()
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("coverage-finish-done")
            } else {
                Text(
                    "In Shortcuts, tap Add for the PUSHKIN configuration, then turn on its new automation. PUSHKIN will verify coverage automatically after the first notification."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Link(destination: automationsURL) {
                    Label(
                        "Open Automations",
                        systemImage: "arrow.up.forward.app"
                    )
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("finish-coverage-automations")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 16)
        )
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .accessibilityIdentifier("coverage-finish-card")
    }

    private func clearPendingCoverage() {
        pendingCoverageName = ""
        pendingCoverageTitle = ""
        pendingCoverageStartedAt = 0
    }

    private func normalizedAppName(_ value: String) -> String {
        value.lowercased()
            .components(separatedBy: .alphanumerics.inverted)
            .joined()
    }
}

private struct NotificationRow: View {
    let item: CapturedNotification

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.sourceApp)
                    .font(.headline)
                Spacer()
                Text(item.receivedAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !item.titleText.isEmpty {
                Text(item.titleText)
                    .font(.subheadline.weight(.semibold))
            }

            Text(item.bodyText.isEmpty ? item.subtitleText : item.bodyText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if item.duplicateCandidate {
                Label("Possible duplicate", systemImage: "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct NotificationDetailView: View {
    let item: CapturedNotification

    var body: some View {
        List {
            Section("Source") {
                LabeledContent("App", value: item.sourceApp)
                if let bundleID = item.sourceBundleIdentifier {
                    LabeledContent("Bundle ID", value: bundleID)
                }
            }

            Section("Notification") {
                if !item.titleText.isEmpty {
                    Text(item.titleText)
                }
                if !item.subtitleText.isEmpty {
                    Text(item.subtitleText)
                }
                Text(item.bodyText.isEmpty ? "No message body" : item.bodyText)
                    .foregroundStyle(item.bodyText.isEmpty ? .secondary : .primary)
            }

            Section("Capture") {
                LabeledContent(
                    "Received",
                    value: item.receivedAt.formatted(date: .abbreviated, time: .standard)
                )
                LabeledContent(
                    "Captured",
                    value: item.capturedAt.formatted(date: .abbreviated, time: .standard)
                )
                LabeledContent(
                    "Channel",
                    value: item.captureChannel
                )
            }

            Section("Phase 0 diagnostics") {
                LabeledContent(
                    "Normalization",
                    value: item.normalizationMode ?? "legacy record"
                )
                LabeledContent(
                    "Timestamp source",
                    value: item.timestampSource ?? "legacy record"
                )

                if let rawTitle = item.rawTitleText {
                    DiagnosticPayloadRow(label: "Raw Title input", value: rawTitle)
                }
                if let rawSubtitle = item.rawSubtitleText {
                    DiagnosticPayloadRow(label: "Raw Subtitle input", value: rawSubtitle)
                }
                if let rawMessage = item.rawMessageText {
                    DiagnosticPayloadRow(label: "Raw Message input", value: rawMessage)
                }
            }
        }
        .navigationTitle("Notification")
        .navigationBarTitleDisplayMode(.inline)
    }
}


private struct DiagnosticPayloadRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "Empty" : value)
                .textSelection(.enabled)
        }
    }
}
