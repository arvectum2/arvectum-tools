import SwiftUI

struct PhoneRecordingSheet: View {
    @ObservedObject var recorder: PhoneRecordingController
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Layout acceptance only: never ask for microphone permission or start
    /// recording. These flags are excluded from production behavior.
    private var isLayoutQA: Bool {
#if DEBUG
        let args = ProcessInfo.processInfo.arguments
        return args.contains("--qa-audio-controls-no-microphone")
            || args.contains("--qa-audio-controls-normal-no-microphone")
#else
        false
#endif
    }

    private func closeCapture() {
        if !isLayoutQA { recorder.discard() }
        dismiss()
    }

    private var closeLabel: String {
        recorder.isRecording
            ? CaptureBrand.text("Удалить", "Discard")
            : CaptureBrand.text("Закрыть", "Close")
    }

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
                    .frame(minHeight: 52)
                    .accessibilityIdentifier("what.audio.stop")
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
                    .frame(minHeight: 52)
                    .accessibilityIdentifier("what.audio.start")
                    .disabled(recorder.requestingPermission || isLayoutQA)
                }
                Spacer()
            }
            .padding(24)
            .navigationTitle(CaptureBrand.text("Новая запись", "New recording"))
            .navigationBarTitleDisplayMode(.inline)
            // The iOS nav bar constrains actions to 36 pt in AXXXL.
            // Keep the discard/close action fully tappable above the keyboard.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if dynamicTypeSize.isAccessibilitySize {
                    HStack {
                        Button(closeLabel, role: recorder.isRecording ? .destructive : nil) {
                            closeCapture()
                        }
                        .buttonStyle(.bordered)
                        .frame(minWidth: 88, minHeight: 52)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("what.audio.close")
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.regularMaterial)
                }
            }
            .toolbar {
                if !dynamicTypeSize.isAccessibilitySize {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(closeLabel, role: recorder.isRecording ? .destructive : nil) {
                            closeCapture()
                        }
                        .accessibilityIdentifier("what.audio.close")
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
                if !recorder.isRecording && !isLayoutQA {
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
