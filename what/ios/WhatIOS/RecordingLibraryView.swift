import SwiftUI

struct RecordingLibraryView: View {
    let openCaptureHome: () -> Void
    @EnvironmentObject private var store: PhoneStore
    @State private var recordingToDelete: RecordingEnvelope?
    @State private var recordingToEdit: RecordingEnvelope?
    @State private var recordingToRetranscribe: RecordingEnvelope?
    @State private var selectedFolder: InboxFolder = .inbox
    @State private var searchText = ""
    @State private var preparedExport: PreparedRecordingExport?
    @State private var showDiagnostics = false

    private var visibleRecordings: [RecordingEnvelope] {
        InboxOrganizer.recordings(
            store.recordings,
            archivedIDs: store.archivedIDs,
            folder: selectedFolder,
            query: searchText,
            transcripts: store.transcripts
        )
    }

    private var dayGroups: [InboxDayGroup] {
        InboxOrganizer.groups(visibleRecordings)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker(CaptureBrand.text("Папка", "Folder"), selection: $selectedFolder) {
                    ForEach(InboxFolder.allCases) { folder in
                        Text(folder == .inbox
                            ? CaptureBrand.text("Входящие", "Inbox")
                            : CaptureBrand.text("Архив", "Archive")).tag(folder)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                HStack(spacing: 5) {
                    Image(systemName: "iphone.gen3")
                    Text(CaptureBrand.text("Сохранено на iPhone", "Saved locally on iPhone"))
                    Spacer()
                    Text(CaptureBrand.text("Записей: \(visibleRecordings.count)", "\(visibleRecordings.count) recordings"))
                        .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)

                if store.recordings.isEmpty {
                    ContentUnavailableView(
                        CaptureBrand.text("Пока нет записей", "Nothing yet"),
                        systemImage: "waveform",
                        description: Text(CaptureBrand.text("Нажмите большую кнопку записи на iPhone или запишите мысль на Apple Watch. Все записи появятся здесь.", "Tap the large recording button on iPhone or record a thought on Apple Watch. Every saved note appears here."))
                    )
                } else if dayGroups.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty
                            ? (selectedFolder == .archive ? CaptureBrand.text("Архив пуст", "Archive is empty") : CaptureBrand.text("Входящие пусты", "Inbox is empty"))
                            : CaptureBrand.text("Записи не найдены", "No matching recordings"),
                        systemImage: searchText.isEmpty ? "tray" : "magnifyingglass",
                        description: Text(searchText.isEmpty
                            ? CaptureBrand.text("Записи в архиве остаются на iPhone.", "Archived recordings stay saved on this iPhone.")
                            : CaptureBrand.text("Поиск по текстам и датам.", "Search looks through saved transcripts and dates."))
                    )
                } else {
                    List {
                        ForEach(dayGroups) { group in
                            Section(CaptureBrand.isRussian
                                ? (group.day.rawValue == "Today" ? "Сегодня"
                                   : group.day.rawValue == "Yesterday" ? "Вчера" : "Ранее")
                                : group.day.rawValue) {
                                ForEach(group.recordings) { recording in
                                    recordingRow(recording)
                                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                            Button {
                                                store.setArchived(
                                                    recording,
                                                    archived: !store.archivedIDs.contains(recording.id)
                                                )
                                            } label: {
                                                Label(
                                                    selectedFolder == .archive ? "Restore" : CaptureBrand.text("Архив", "Archive"),
                                                    systemImage: selectedFolder == .archive
                                                        ? "tray.and.arrow.up" : "archivebox"
                                                )
                                            }
                                            .tint(.indigo)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                recordingToDelete = recording
                                            } label: {
                                                Label(CaptureBrand.text("Удалить", "Delete"), systemImage: "trash")
                                            }
                                        }
                                        .contextMenu {
                                            Button {
                                                store.setArchived(
                                                    recording,
                                                    archived: !store.archivedIDs.contains(recording.id)
                                                )
                                            } label: {
                                                Label(
                                                    selectedFolder == .archive ? CaptureBrand.text("Вернуть во входящие", "Restore to Inbox") : CaptureBrand.text("В архив", "Archive recording"),
                                                    systemImage: selectedFolder == .archive
                                                        ? "tray.and.arrow.up" : "archivebox"
                                                )
                                            }
                                            Button(role: .destructive) {
                                                recordingToDelete = recording
                                            } label: {
                                                Label(CaptureBrand.text("Удалить запись", "Delete recording"), systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { store.reload() }
                    .alert(
                        CaptureBrand.text("Удалить запись?", "Delete recording?"),
                        isPresented: Binding(
                            get: { recordingToDelete != nil },
                            set: { if !$0 { recordingToDelete = nil } }
                        ),
                        presenting: recordingToDelete
                    ) { recording in
                        Button(CaptureBrand.text("Удалить навсегда", "Delete permanently"), role: .destructive) {
                            store.delete(recording)
                            recordingToDelete = nil
                        }
                        Button(CaptureBrand.text("Отмена", "Cancel"), role: .cancel) {
                            recordingToDelete = nil
                        }
                    } message: { _ in
                        Text(CaptureBrand.text("Аудио и текст будут безвозвратно удалены с iPhone.", "The audio and transcript will be deleted from this iPhone. This cannot be undone."))
                    }
                }
            }
            .searchable(text: $searchText, prompt: CaptureBrand.text("Поиск по записям", "Search transcripts and dates"))
            .navigationTitle(CaptureBrand.name)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: openCaptureHome) {
                        Label(CaptureBrand.text("Записать", "Record"), systemImage: "mic.fill")
                    }
                    .accessibilityLabel(CaptureBrand.text("Вернуться к быстрой записи", "Back to quick recording"))
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Picker(CaptureBrand.text("Язык распознавания", "Speech language"), selection: $store.transcriptionLocale) {
                            Text("Русский").tag("ru-RU")
                            Text("English").tag("en-US")
                            Text("Español").tag("es-ES")
                        }
                        Button {
                            showDiagnostics = true
                        } label: {
                            Label(CaptureBrand.text("Диагностика синхронизации", "Sync diagnostics"), systemImage: "applewatch")
                        }
                        Link(
                            CaptureBrand.text("Конфиденциальность", "Privacy policy"),
                            destination: URL(string: "https://arvectum.com/privacy")!
                        )
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel(CaptureBrand.text("Настройки и диагностика", "App settings and diagnostics"))
                }
            }
            .tint(Color(red: 67 / 255, green: 229 / 255, blue: 197 / 255))
            .sheet(isPresented: $showDiagnostics) {
                SyncDiagnosticsView()
                    .environmentObject(store)
            }
            .sheet(item: $preparedExport, onDismiss: {
                preparedExport?.cleanUp()
            }) { export in
                RecordingShareSheet(export: export)
            }
            .sheet(item: $recordingToEdit) { recording in
                TranscriptEditorSheet(
                    recording: recording,
                    initialText: store.transcripts[recording.id] ?? "",
                    onSave: { editedText in
                        try store.updateTranscript(editedText, for: recording)
                    }
                )
            }
        }
    }

    private func recordingRow(_ recording: RecordingEnvelope) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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
            if store.isAudioComplete(recording) {
                Label(CaptureBrand.text("Аудио на iPhone", "Audio saved on iPhone"), systemImage: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Label(
                    store.isAudioAvailable(recording)
                        ? CaptureBrand.text("Неполное аудио — перезапишите", "Audio incomplete — please re-record")
                        : CaptureBrand.text("Нет аудио на iPhone", "Audio missing on iPhone"),
                    systemImage: "exclamationmark.triangle"
                )
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            // Only two primary actions and one fixed-size overflow control.
            // Keeping the long labels inside menus prevents even "Play" from
            // wrapping on narrow iPhones or with larger Dynamic Type.
            ViewThatFits(in: .horizontal) {
                recordingActions(recording, stacked: false)
                recordingActions(recording, stacked: true)
            }

            if let transcript = store.transcripts[recording.id] {
                Text(transcript).font(.body).textSelection(.enabled)
            }
        }
        .padding(.vertical, 5)
    }

    @ViewBuilder
    private func recordingActions(_ recording: RecordingEnvelope, stacked: Bool) -> some View {
        let hasTranscript = store.transcripts[recording.id] != nil

        Group {
            if stacked {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        playButton(recording)
                        Spacer(minLength: 4)
                        actionsMenu(recording)
                    }
                    textButton(recording, hasTranscript: hasTranscript)
                }
            } else {
                HStack(spacing: 12) {
                    playButton(recording)
                    textButton(recording, hasTranscript: hasTranscript)
                    Spacer(minLength: 0)
                    actionsMenu(recording)
                }
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.borderless)
    }

    private func playButton(_ recording: RecordingEnvelope) -> some View {
        Button {
            store.togglePlayback(recording)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: store.playingID == recording.id
                    ? "stop.circle.fill" : "play.circle.fill")
                Text(store.playingID == recording.id
                    ? CaptureBrand.text("Стоп", "Stop")
                    : CaptureBrand.text("Слушать", "Play"))
                    .lineLimit(1)
            }
            .font(.subheadline.weight(.semibold))
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.accentColor.opacity(0.12), in: Capsule())
        }
        .disabled(!store.isAudioAvailable(recording))
        .accessibilityLabel(store.playingID == recording.id ? CaptureBrand.text("Остановить аудио", "Stop audio")
            : CaptureBrand.text("Прослушать аудио", "Play audio"))
    }

    private func textButton(
        _ recording: RecordingEnvelope,
        hasTranscript: Bool
    ) -> some View {
        Button {
            if store.transcribingID == recording.id {
                store.cancelTranscription()
            } else if hasTranscript {
                recordingToEdit = recording
            } else {
                store.transcribe(recording)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: store.transcribingID == recording.id
                    ? "xmark.circle" : "text.bubble")
                Text(store.transcribingID == recording.id
                    ? CaptureBrand.text("Отмена", "Cancel")
                    : (hasTranscript
                        ? CaptureBrand.text("Править текст", "Edit text")
                        : CaptureBrand.text("Расшифровать", "Transcribe")))
                    .lineLimit(1)
            }
            .font(.subheadline)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.secondary.opacity(0.09), in: Capsule())
        }
        .disabled(store.transcribingID != nil
            && store.transcribingID != recording.id)
    }

    private func actionsMenu(_ recording: RecordingEnvelope) -> some View {
        Menu {
            Button {
                if store.transcribingID == recording.id {
                    store.cancelTranscription()
                }
                recordingToEdit = recording
            } label: {
                Label(
                    store.transcripts[recording.id] == nil ? CaptureBrand.text("Добавить текст", "Add text")
                        : CaptureBrand.text("Править текст", "Edit text"),
                    systemImage: "square.and.pencil"
                )
            }

            if store.transcripts[recording.id] != nil,
               store.isAudioAvailable(recording) {
                Button {
                    recordingToRetranscribe = recording
                } label: {
                    Label(CaptureBrand.text("Повторить расшифровку", "Retry transcription"), systemImage: "arrow.clockwise")
                }
                .disabled(store.transcribingID != nil)
            }

            Menu {
                if store.isAudioAvailable(recording) {
                    Button {
                        preparedExport = store.prepareExport(recording, selection: .audio)
                    } label: {
                        Label("Audio (.m4a)", systemImage: "waveform")
                    }
                }
                if store.transcripts[recording.id] != nil {
                    Button {
                        preparedExport = store.prepareExport(recording, selection: .transcript)
                    } label: {
                        Label("Transcript (.txt)", systemImage: "doc.plaintext")
                    }
                }
                if store.isAudioAvailable(recording),
                   store.transcripts[recording.id] != nil {
                    Button {
                        preparedExport = store.prepareExport(recording, selection: .audioAndTranscript)
                    } label: {
                        Label(CaptureBrand.text("Аудио и текст", "Audio + transcript"), systemImage: "square.on.square")
                    }
                }
            } label: {
                Label(CaptureBrand.text("Экспорт", "Export"), systemImage: "square.and.arrow.up")
            }

            Divider()

            Button {
                store.setArchived(
                    recording,
                    archived: !store.archivedIDs.contains(recording.id)
                )
            } label: {
                Label(
                    store.archivedIDs.contains(recording.id)
                        ? CaptureBrand.text("Вернуть во входящие", "Restore to Inbox") : CaptureBrand.text("В архив", "Archive recording"),
                    systemImage: store.archivedIDs.contains(recording.id)
                        ? "tray.and.arrow.up" : "archivebox"
                )
            }

            Button(role: .destructive) {
                recordingToDelete = recording
            } label: {
                Label(CaptureBrand.text("Удалить запись", "Delete recording"), systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(CaptureBrand.text("Другие действия с записью", "More recording actions"))
        .alert(CaptureBrand.text("Заменить расшифровку?", "Replace existing transcription?"), isPresented: Binding(
            get: { recordingToRetranscribe?.id == recording.id },
            set: { if !$0 { recordingToRetranscribe = nil } }
        )) {
            Button(CaptureBrand.text("Заменить текст", "Replace transcription"), role: .destructive) {
                store.transcribe(recording)
                recordingToRetranscribe = nil
            }
            Button(CaptureBrand.text("Отмена", "Cancel"), role: .cancel) {
                recordingToRetranscribe = nil
            }
        } message: {
            Text(CaptureBrand.text("Новая расшифровка заменит исправленный текст. Оригинальное аудио сохранится.", "A new transcription will replace your current text, including any manual corrections. The original audio will be kept."))
        }
    }

    private func duration(_ value: TimeInterval) -> String {
        let total = max(0, Int(value.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
