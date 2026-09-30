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

    @State private var showAppPicker = false
    @State private var pendingBasePackageURL: URL?

    private let automationsURL = URL(string: "shortcuts://automations")!

    var body: some View {
        NavigationStack {
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
                    lastQuickRefreshName = app.name
                    lastQuickRefreshAt = Date().timeIntervalSince1970
                    quickRefreshCount += 1
                }
            }
            .background {
                ShortcutPackagePresenter(
                    packageURL: $pendingBasePackageURL
                ) {}
            }
        }
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
