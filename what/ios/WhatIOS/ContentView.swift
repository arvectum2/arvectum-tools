import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PhoneStore

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
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("What?")
            .tint(Color(red: 67 / 255, green: 229 / 255, blue: 197 / 255))
        }
    }

    private func recordingRow(_ recording: RecordingEnvelope) -> some View {
        Button {
            store.play(recording)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)

                VStack(alignment: .leading, spacing: 3) {
                    Text(recording.createdAt, style: .time)
                        .font(.headline)
                    Text(recording.createdAt, format: .dateTime.day().month().year())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(duration(recording.duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func duration(_ value: TimeInterval) -> String {
        let total = max(0, Int(value.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
