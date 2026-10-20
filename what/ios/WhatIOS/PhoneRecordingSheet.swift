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

                Text(recorder.isRecording
                    ? CaptureBrand.text("Идёт запись", "Recording on device")
                    : CaptureBrand.text("Голосовая заметка", "Voice note"))
                    .font(.title2.bold())

                if let date = recorder.startedAt {
                    TimelineView(.periodic(from: .now, by: 0.5)) { context in
                        VStack(spacing: 8) {
                            Text(formatDuration(context.date.timeIntervalSince(date)))
                                .font(.system(.title, design: .monospaced))
                                .accessibilityLabel(CaptureBrand.text("Длительность записи", "Recording duration"))
                            Text(
                                recorder.microphoneConnected
                                    ? (recorder.hasDetectedSignal
                                        ? CaptureBrand.text("Микрофон записывает звук", "Microphone is capturing sound")
                                        : CaptureBrand.text("Микрофон готов — говорите", "Microphone connected — speak now"))
                                    : (context.date.timeIntervalSince(date) > 2
                                        ? CaptureBrand.text("Нет звука — проверьте микрофон", "No microphone data yet — check audio input")
                                        : CaptureBrand.text("Подключаем микрофон…", "Connecting to microphone…"))
                            )
                            .font(.caption)
                            .foregroundStyle(recorder.microphoneConnected
                                ? Color.secondary : Color.orange)
                            Text(CaptureBrand.formatted("Вход: %@", "Input: %@", recorder.microphoneRoute))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .onChange(of: context.date) { _, _ in
                            recorder.refreshMicrophoneStatus()
                        }
                    }
                } else {
                    Text(CaptureBrand.text("Аудио сохранится на этом устройстве.", "Your original audio will be saved locally on this device."))
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
                        Label(CaptureBrand.text("Стоп и сохранить", "Stop and save"), systemImage: "stop.circle.fill")
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
                            recorder.requestingPermission
                                ? CaptureBrand.text("Ждём разрешения…", "Waiting for microphone…")
                                : CaptureBrand.text("Начать запись", "Start recording"),
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
            .navigationTitle(CaptureBrand.text("Новая запись", "New recording"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(recorder.isRecording
                        ? CaptureBrand.text("Удалить", "Discard")
                        : CaptureBrand.text("Закрыть", "Close"), role: recorder.isRecording ? .destructive : nil) {
                        recorder.discard()
                        dismiss()
                    }
                }
            }
            .interactiveDismissDisabled(recorder.isRecording)
            .alert(CaptureBrand.text("Запись", "Phone recording"), isPresented: Binding(
                get: { recorder.errorMessage != nil },
                set: { _ in /* OK handles dismissal; avoid publishing during SwiftUI updates. */ }
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
