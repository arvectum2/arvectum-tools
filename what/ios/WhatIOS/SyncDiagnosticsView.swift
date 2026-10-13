import SwiftUI

struct SyncDiagnosticsView: View {
    @EnvironmentObject private var store: PhoneStore

    var body: some View {
        NavigationStack {
            List {
                Section("Saved on iPhone") {
                    LabeledContent("Recordings", value: "\(store.recordings.count)")
                    LabeledContent("Audio files", value:
                        "\(store.recordings.filter { store.isAudioAvailable($0) }.count)")
                    LabeledContent("Transcribed notes", value: "\(store.transcripts.count)")
                }
                Section("Apple Watch — last reported state") {
                    if let snapshot = store.lastWatchQueueSnapshot {
                        LabeledContent("Pending on Watch", value: "\(snapshot.pendingCount)")
                        LabeledContent("Watch report timestamp", value:
                            snapshot.updatedAt.formatted(date: .abbreviated, time: .standard))
                    } else {
                        Text("No Watch queue report received yet.")
                            .foregroundStyle(.secondary)
                    }
                    Text("This is the last message received from your Watch, not a real-time connection check. It can be delayed.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Sync diagnostics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
