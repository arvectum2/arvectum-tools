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
    @Query(sort: \CapturedNotification.capturedAt, order: .reverse)
    private var notifications: [CapturedNotification]

    var body: some View {
        NavigationStack {
            Group {
                if notifications.isEmpty {
                    ContentUnavailableView(
                        "No captured notifications yet",
                        systemImage: "bell.slash",
                        description: Text(
                            "Finish the Shortcuts setup, then wait for a real notification."
                        )
                    )
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
            .navigationTitle("Arvectum Notify")
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
        }
        .navigationTitle("Notification")
        .navigationBarTitleDisplayMode(.inline)
    }
}
