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

    var body: some View {
        NavigationStack {
            List {
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

                Section("Spike protocol") {
                    Text(
                        "For each test condition, send a known number of notifications and compare that number with Captured."
                    )
                    Text(
                        "Possible duplicates are identical payloads captured within 10 seconds."
                    )
                    .foregroundStyle(.secondary)
                }

                Section {
                    Button("Reset spike data", role: .destructive) {
                        showingResetConfirmation = true
                    }
                }
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
}
