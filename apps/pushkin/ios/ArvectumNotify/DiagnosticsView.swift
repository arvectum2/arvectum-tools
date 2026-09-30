import SwiftData
import SwiftUI

struct DiagnosticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CapturedNotification.capturedAt, order: .reverse)
    private var notifications: [CapturedNotification]

    @State private var showingResetConfirmation = false

    private var duplicateCount: Int {
        notifications.lazy.filter(\.duplicateCandidate).count
    }

    private var missingBodyCount: Int {
        notifications.lazy.filter { $0.bodyText.isEmpty }.count
    }

    private var multilineFallbackCount: Int {
        notifications.lazy.filter {
            $0.normalizationMode == "multiline-title-body"
        }.count
    }

    private var sourceApps: [String] {
        Array(Set(notifications.map(\.sourceApp))).sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                captureCounters
                payloadDiagnostics
                sourceSummary
                protocolSection
                resetSection
            }
            .navigationTitle("Diagnostics")
            .confirmationDialog(
                "Delete every captured notification?",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    try? modelContext.delete(model: CapturedNotification.self)
                    try? modelContext.save()
                }
            }
        }
    }

    private var captureCounters: some View {
        Section("Capture counters") {
            LabeledContent("Captured", value: "\(notifications.count)")
            LabeledContent("Possible duplicates", value: "\(duplicateCount)")
            LabeledContent("Missing message body", value: "\(missingBodyCount)")

            if let last = notifications.first {
                LabeledContent(
                    "Last capture",
                    value: last.capturedAt.formatted(
                        date: .abbreviated,
                        time: .standard
                    )
                )
            }
        }
    }

    private var payloadDiagnostics: some View {
        Section("Payload diagnostics") {
            LabeledContent(
                "Multiline fallbacks",
                value: "\(multilineFallbackCount)"
            )

            if let last = notifications.first {
                LabeledContent(
                    "Last normalization",
                    value: last.normalizationMode ?? "legacy record"
                )
                LabeledContent(
                    "Timestamp source",
                    value: last.timestampSource ?? "legacy record"
                )
            }
        }
    }

    @ViewBuilder
    private var sourceSummary: some View {
        if !sourceApps.isEmpty {
            Section("Sources") {
                ForEach(sourceApps, id: \.self) { app in
                    LabeledContent(
                        app,
                        value: "\(notifications.lazy.filter { $0.sourceApp == app }.count)"
                    )
                }
            }
        }
    }

    private var protocolSection: some View {
        Section("Spike protocol") {
            Text(
                "Send a known number of notifications and compare it with Captured. Record delayed captures separately from missing captures."
            )
            Text(
                "Possible duplicates are identical normalized payloads captured within 10 seconds."
            )
            .foregroundStyle(.secondary)
        }
    }

    private var resetSection: some View {
        Section {
            Button("Reset spike data", role: .destructive) {
                showingResetConfirmation = true
            }
        }
    }
}
