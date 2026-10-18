import SwiftUI

struct SyncDiagnosticsView: View {
    @EnvironmentObject private var store: PhoneStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(CaptureBrand.text("Сохранено на iPhone", "Saved on iPhone")) {
                    LabeledContent(CaptureBrand.text("Записей", "Recordings"), value: "\(store.recordings.count)")
                    LabeledContent(CaptureBrand.text("Аудиофайлов", "Audio files"), value:
                        "\(store.recordings.filter { store.isAudioAvailable($0) }.count)")
                    LabeledContent(CaptureBrand.text("С расшифровкой", "Transcribed notes"), value: "\(store.transcripts.count)")
                }
                Section(CaptureBrand.text("Запись на iPhone — скорость запуска", "iPhone capture responsiveness")) {
                    let samples = CaptureLatency.samples(for: "iphone")
                    LabeledContent(CaptureBrand.text("Запусков записи", "Captured starts"), value: "\(samples.count)")
                    if let latency = CaptureLatency.p95(milliseconds: samples) {
                        LabeledContent(CaptureBrand.text("До первого фрагмента звука (p95)", "Handler to first microphone buffer (p95)"),
                                       value: "\(Int(latency)) ms")
                    }
                    Text(CaptureBrand.text("Задержка от начала записи до первого звукового фрагмента. Не включает время запуска приложения. Данные хранятся только на этом iPhone.", "Measured after pressing Record and entering the app's recorder; excludes system launch time. Stored only on this iPhone."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section(CaptureBrand.text("Apple Watch — последний отчёт", "Apple Watch — last reported state")) {
                    if let snapshot = store.lastWatchQueueSnapshot {
                        LabeledContent(CaptureBrand.text("В очереди на часах", "Pending on Watch"), value: "\(snapshot.pendingCount)")
                        LabeledContent(CaptureBrand.text("Время отчёта часов", "Watch report timestamp"), value:
                            snapshot.updatedAt.formatted(date: .abbreviated, time: .standard))
                    } else {
                        Text(CaptureBrand.text("Отчёт об очереди с часов ещё не получен.", "No Watch queue report received yet."))
                            .foregroundStyle(.secondary)
                    }
                    Text(CaptureBrand.text("Это последний полученный отчёт часов, а не проверка соединения в реальном времени. Данные могут поступать с задержкой.", "This is the last message received from your Watch, not a real-time connection check. It can be delayed."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(CaptureBrand.text("Диагностика синхронизации", "Sync diagnostics"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(CaptureBrand.text("Готово", "Done")) {
                        dismiss()
                    }
                    .accessibilityIdentifier("syncDiagnosticsClose")
                }
            }
        }
    }
}
