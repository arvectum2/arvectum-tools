import SwiftUI

struct SyncDiagnosticsView: View {
    @EnvironmentObject private var store: PhoneStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var recoveryRequestFeedback: String?

    var body: some View {
        NavigationStack {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    accessibleReport
                } else {
                    List {
                        Section(CaptureBrand.text("Сохранено на iPhone", "Saved on iPhone")) {
                            savedMetrics
                        }
                        Section(CaptureBrand.text("Запись на iPhone — скорость запуска",
                                                  "iPhone capture responsiveness")) {
                            captureMetrics
                        }
                        Section(CaptureBrand.text("Apple Watch — последний отчёт",
                                                  "Apple Watch — last reported state")) {
                            watchMetrics
                        }
                    }
                    .navigationTitle(CaptureBrand.text("Диагностика синхронизации",
                                                       "Sync diagnostics"))
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
    }

    /// UIKit navigation titles and List rows can clip even short strings at
    /// AXXXL. Keep metrics scrollable at their natural height with a 64pt
    /// in-content dismissal action, while standard sizes retain native List.
    private var accessibleReport: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top, spacing: 12) {
                    Text(CaptureBrand.text("Диагностика синхронизации",
                                           "Sync diagnostics"))
                        .font(.title3.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

                    Spacer(minLength: 4)

                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .frame(minWidth: 64, minHeight: 64)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(CaptureBrand.text("Готово", "Done"))
                    .accessibilityIdentifier("syncDiagnosticsClose")
                }

                accessibleSection(
                    CaptureBrand.text("Сохранено на iPhone", "Saved on iPhone")
                ) {
                    savedMetrics
                }

                accessibleSection(
                    CaptureBrand.text("Запись на iPhone — скорость запуска",
                                      "iPhone capture responsiveness")
                ) {
                    captureMetrics
                }

                accessibleSection(
                    CaptureBrand.text("Apple Watch — последний отчёт",
                                      "Apple Watch — last reported state")
                ) {
                    watchMetrics
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .scrollIndicators(.hidden)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func accessibleSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    @ViewBuilder private var savedMetrics: some View {
        diagnosticMetric(CaptureBrand.text("Записей", "Recordings"),
                         value: "\(store.recordings.count)")
        diagnosticMetric(CaptureBrand.text("Аудиофайлов", "Audio files"),
                         value: "\(store.recordings.filter { store.isAudioAvailable($0) }.count)")
        diagnosticMetric(CaptureBrand.text("С расшифровкой", "Transcribed notes"),
                         value: "\(store.transcripts.count)")
    }

    @ViewBuilder private var captureMetrics: some View {
        let samples = CaptureLatency.samples(for: "iphone")
        diagnosticMetric(CaptureBrand.text("Запусков записи", "Captured starts"),
                         value: "\(samples.count)")
        if let latency = CaptureLatency.p95(milliseconds: samples) {
            diagnosticMetric(
                CaptureBrand.text("До первого фрагмента звука (p95)",
                                  "Handler to first microphone buffer (p95)"),
                value: "\(Int(latency)) ms"
            )
        }
        Text(CaptureBrand.text(
            "Задержка от начала записи до первого звукового фрагмента. Не включает время запуска приложения. Данные хранятся только на этом iPhone.",
            "Measured after pressing Record and entering the app's recorder; excludes system launch time. Stored only on this iPhone."
        ))
        .font(.footnote)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var watchMetrics: some View {
        if let snapshot = store.lastWatchQueueSnapshot {
            diagnosticMetric(CaptureBrand.text("В очереди на часах", "Pending on Watch"),
                             value: "\(snapshot.pendingCount)")
            diagnosticMetric(CaptureBrand.text("Время отчёта часов", "Watch report timestamp"),
                             value: snapshot.updatedAt.formatted(date: .abbreviated, time: .standard))
            Text(WatchQueueUserStatus.explanation(for: snapshot))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("watchQueueDeliveryExplanation")
        } else {
            Text(CaptureBrand.text("Отчёт об очереди с часов ещё не получен.",
                                   "No Watch queue report received yet."))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        Button {
            let outcome = PhoneConnectivityManager.shared.requestWatchQueueRecovery()
            switch outcome {
            case .queued:
                recoveryRequestFeedback = CaptureBrand.text(
                    "Запрос отправлен. Передача может занять время.",
                    "Request queued. Delivery may take some time."
                )
            case .alreadyPending:
                recoveryRequestFeedback = CaptureBrand.text(
                    "Запрос уже ожидает передачи.",
                    "A sync request is already pending."
                )
            case .rateLimited:
                recoveryRequestFeedback = CaptureBrand.text(
                    "Недавний запрос ещё обрабатывается. Повторите позже.",
                    "A recent request is still being processed. Try again later."
                )
            case .unavailable:
                recoveryRequestFeedback = CaptureBrand.text(
                    "Часы недоступны. Проверьте сопряжение и повторите попытку.",
                    "Watch unavailable. Check pairing and try again."
                )
            }
        } label: {
            Label(CaptureBrand.text("Запросить передачу с часов",
                                    "Request Watch transfer"),
                  systemImage: "arrow.clockwise")
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(.bordered)
        .frame(minHeight: 44, alignment: .leading)
        .accessibilityIdentifier("watchQueueRequestRecovery")
        if let recoveryRequestFeedback {
            Text(recoveryRequestFeedback)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("watchQueueRecoveryFeedback")
        }
        Text(CaptureBrand.text(
            "Это последний полученный отчёт часов, а не проверка соединения в реальном времени. Данные могут поступать с задержкой.",
            "This is the last message received from your Watch, not a real-time connection check. It can be delayed."
        ))
        .font(.footnote)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func diagnosticMetric(_ title: String, value: String) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .fixedSize(horizontal: false, vertical: true)
                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        } else {
            LabeledContent(title, value: value)
        }
    }
}
