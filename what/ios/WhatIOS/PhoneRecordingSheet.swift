import SwiftUI

struct PhoneRecordingSheet: View {
    @ObservedObject var recorder: PhoneRecordingController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 26) {
                Spacer()
                Image(systemName: recorder.isRecording ? "waveform.circle.fill" : "mic.circle")
                    .font(.system(size: 78))
                    .foregroundStyle(recorder.isRecording ? .red : .mint)
                    .accessibilityHidden(true)

                Text(recorder.isRecording ? "Recording on iPhone" : "Voice note")
                    .font(.title2.bold())

                if let date = recorder.startedAt {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(formatDuration(context.date.timeIntervalSince(date)))
                            .font(.system(.title, design: .monospaced))
                            .accessibilityLabel("Recording duration")
                    }
                } else {
                    Text("Your original audio will be saved locally on this iPhone.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                if recorder.isRecording {
                    Button {
                        if recorder.finish() != nil {
                            dismiss()
                        }
                    } label: {
                        Label("Stop and save", systemImage: "stop.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        recorder.start()
                    } label: {
                        Label(
                            recorder.requestingPermission ? "Waiting for microphone…" : "Start recording",
                            systemImage: "mic.fill"
                        )
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(recorder.requestingPermission)
                }
                Spacer()
            }
            .padding(24)
            .navigationTitle("New recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(recorder.isRecording ? "Discard" : "Close", role: recorder.isRecording ? .destructive : nil) {
                        recorder.discard()
                        dismiss()
                    }
                }
            }
            .interactiveDismissDisabled(recorder.isRecording)
            .alert("Phone recording", isPresented: Binding(
                get: { recorder.errorMessage != nil },
                set: { if !$0 { recorder.errorMessage = nil } }
            )) {
                Button("OK") { recorder.errorMessage = nil }
            } message: {
                Text(recorder.errorMessage ?? "")
            }
            .onAppear {
                if !recorder.isRecording {
                    recorder.start()
                }
            }
            .onDisappear {
                recorder.cancelPendingStart()
            }
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
