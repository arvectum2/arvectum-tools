import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PhoneStore
    @State private var recordingToDelete: RecordingEnvelope?

    var body: some View {
        NavigationStack {
            Group {
                if store.recordings.isEmpty {
                    ContentUnavailableView(
                        "Nothing yet",
                        systemImage: "waveform",
                        description: Text("Record a thought on Apple Watch. It will appear here after a safe transfer.")
                    )
                } else {
                    List(store.recordings) { recording in
                        recordingRow(recording)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    recordingToDelete = recording
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    recordingToDelete = recording
                                } label: {
                                    Label("Delete recording", systemImage: "trash")
                                }
                            }
                    }
                    .listStyle(.plain)
                    // An alert shows an explicit Cancel button on iPhone.
                    // A confirmationDialog may allow dismissing by tapping outside
                    // without ever rendering its cancel action.
                    .alert(
                        "Delete recording?",
                        isPresented: Binding(
                            get: { recordingToDelete != nil },
                            set: { if !$0 { recordingToDelete = nil } }
                        ),
                        presenting: recordingToDelete
                    ) { recording in
                        Button("Delete permanently", role: .destructive) {
                            store.delete(recording)
                            recordingToDelete = nil
                        }
                        Button("Cancel", role: .cancel) {
                            recordingToDelete = nil
                        }
                    } message: { _ in
                        Text("The audio and transcript will be deleted from this iPhone. This cannot be undone.")
                    }
                }
            }
            .navigationTitle("What?")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Speech language", selection: $store.transcriptionLocale) {
                        Text("Русский").tag("ru-RU")
                        Text("English").tag("en-US")
                        Text("Español").tag("es-ES")
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Transcription language")
                }
            }
            .tint(Color(red: 67 / 255, green: 229 / 255, blue: 197 / 255))
            .alert("What?", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("OK") { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }

    private func recordingRow(_ recording: RecordingEnvelope) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(recording.createdAt, style: .time).font(.headline)
                    Text(recording.createdAt, format: .dateTime.day().month().year())
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(duration(recording.duration))
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                Button {
                    store.togglePlayback(recording)
                } label: {
                    Label(store.playingID == recording.id ? "Stop" : "Play",
                          systemImage: store.playingID == recording.id ? "stop.circle.fill" : "play.circle.fill")
                }
                .disabled(!store.isAudioAvailable(recording))

                Button {
                    store.transcribe(recording)
                } label: {
                    Label(store.transcribingID == recording.id ? "Transcribing…" : (store.transcripts[recording.id] == nil ? "Transcribe" : "Retry transcription"),
                          systemImage: "text.bubble")
                }
                .disabled(!store.isAudioAvailable(recording) || store.transcribingID != nil)
            }
            .buttonStyle(.borderless)
            if let transcript = store.transcripts[recording.id] {
                Text(transcript).font(.body).textSelection(.enabled)
            } else if !store.isAudioAvailable(recording) {
                Label("Audio missing on iPhone", systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 5)
    }

    private func duration(_ value: TimeInterval) -> String {
        let total = max(0, Int(value.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
