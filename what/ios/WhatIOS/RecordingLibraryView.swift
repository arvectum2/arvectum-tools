import SwiftUI
import UIKit
import UniformTypeIdentifiers
import ArvectumCore

struct RecordingLibraryView: View {
    let openCaptureHome: () -> Void
    @EnvironmentObject private var store: PhoneStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var recordingToDelete: RecordingEnvelope?
    @State private var localNoteToDelete: LocalNote?
    @State private var localNoteToEdit: LocalNote?
    @State private var localVideoToPlay: LocalNote?
    @State private var typeFilter: UnifiedNoteKindFilter = .all
    @State private var recordingToEdit: RecordingEnvelope?
    @State private var recordingToRetranscribe: RecordingEnvelope?
    @State private var selectedFolder: InboxFolder = .inbox
    @State private var searchText = ""
    @State private var preparedExport: PreparedRecordingExport?
    @State private var importingAudio = false
    @State private var importInProgress = false
    @State private var showDiagnostics = false
    @State private var showTranscriptRecovery = false
    @State private var reviewNoteToSend: ReviewNoteHandoffDraft?

    private var notesMatchingFolderAndSearch: [UnifiedNote] {
        UnifiedInbox.visible(
            recordings: store.recordings,
            localNotes: store.localNotes,
            archivedAudioIDs: store.archivedIDs,
            folder: selectedFolder,
            query: searchText,
            transcripts: store.transcripts
        )
    }

    private var visibleNotes: [UnifiedNote] {
        typeFilter.notes(in: notesMatchingFolderAndSearch)
    }

    private func filterTitle(_ filter: UnifiedNoteKindFilter) -> String {
        switch filter {
        case .all: return CaptureBrand.text("Все", "All")
        case .audio: return CaptureBrand.text("Аудио", "Audio")
        case .text: return CaptureBrand.text("Текст", "Text")
        case .video: return CaptureBrand.text("Видео", "Video")
        }
    }

    private func filterSymbol(_ filter: UnifiedNoteKindFilter) -> String {
        switch filter {
        case .all: return "square.grid.2x2"
        case .audio: return "waveform"
        case .text: return "note.text"
        case .video: return "video.fill"
        }
    }

    /// On physical iPhone 13 the horizontal strip clips at accessibility5.
    /// A 2x2 grid pushed the entire note list out of the viewport. A single
    /// full-width Menu leaves the real library scrollable without truncation.
    private var visibleTypeFilters: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                Menu {
                    ForEach(UnifiedNoteKindFilter.allCases) { filter in
                        let total = filter.count(in: notesMatchingFolderAndSearch)
                        Button {
                            typeFilter = filter
                        } label: {
                            Label(CaptureBrand.formatted(
                                "Фильтр %@, %@", "Filter %@, %@",
                                filterTitle(filter), CaptureBrand.noteCount(total)
                            ), systemImage: filterSymbol(filter))
                        }
                        .accessibilityIdentifier("what.filter.\(filter.rawValue)")
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .accessibilityHidden(true)
                        Text(filterTitle(typeFilter))
                            .lineLimit(1)
                        Text(typeFilter.count(in: notesMatchingFolderAndSearch).formatted())
                            .monospacedDigit()
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .accessibilityHidden(true)
                    }
                    // A full descriptive AX label remains available while
                    // the visible control stays within one accessible row.
                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(CaptureBrand.formatted(
                    "Фильтр %@, %@", "Filter %@, %@",
                    filterTitle(typeFilter),
                    CaptureBrand.noteCount(typeFilter.count(in: notesMatchingFolderAndSearch))
                ))
                .accessibilityIdentifier("what.library.filterMenu")
                .padding(.horizontal)
                .padding(.vertical, 5)
            } else {
                standardTypeFilters
            }
        }
    }

    private var standardTypeFilters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(UnifiedNoteKindFilter.allCases) { filter in
                    let selected = typeFilter == filter
                    let total = filter.count(in: notesMatchingFolderAndSearch)
                    Button {
                        typeFilter = filter
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: filterSymbol(filter))
                            Text(filterTitle(filter)).lineLimit(1)
                            Text(total.formatted())
                                .monospacedDigit()
                                .foregroundStyle(selected ? Color.primary : Color.secondary)
                        }
                        .font(.subheadline.weight(selected ? .semibold : .regular))
                        .padding(.horizontal, 11)
                        .frame(minHeight: 48)
                        .contentShape(Rectangle())
                        .background(
                            selected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08),
                            in: Capsule()
                        )
                        .overlay(Capsule().strokeBorder(
                            selected ? Color.accentColor : Color.clear,
                            lineWidth: 1
                        ))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("what.filter.\(filter.rawValue)")
                    .accessibilityLabel(CaptureBrand.formatted("Фильтр %@, %@", "Filter %@, %@", filterTitle(filter), CaptureBrand.noteCount(total)))
                    .accessibilityAddTraits(selected ? [.isSelected] : [])
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("what.library.typeFilters")
    }

    private var emptyFolderMessage: String {
        guard typeFilter != .all else {
            return selectedFolder == .archive
                ? CaptureBrand.text("Архив пуст", "Archive is empty")
                : CaptureBrand.text("Входящие пусты", "Inbox is empty")
        }
        return CaptureBrand.text("Заметок этого типа нет", "No notes of this type")
    }

    private var dayGroups: [UnifiedNoteGroup] {
        UnifiedInbox.groups(visibleNotes)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if dynamicTypeSize.isAccessibilitySize {
                    // UIKit navigation-bar items stay 36–40pt even when their
                    // SwiftUI labels request 48pt. Render accessible actions
                    // in content, hiding the native bar only at AX sizes.
                    accessibleLibraryActions
                }

                Picker(CaptureBrand.text("Папка", "Folder"), selection: $selectedFolder) {
                    ForEach(InboxFolder.allCases) { folder in
                        Text(folder == .inbox
                            ? CaptureBrand.text("Входящие", "Inbox")
                            : CaptureBrand.text("Архив", "Archive")).tag(folder)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .frame(minHeight: 48)
                .padding(.horizontal)
                .padding(.top, 8)

                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        // On iPhone 13 the original two-line storage caption
                        // plus an additional count consumed over 150pt, leaving
                        // too little room for any real note at accessibility5.
                        Label(CaptureBrand.noteCount(visibleNotes.count),
                              systemImage: "internaldrive")
                            .monospacedDigit()
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel(
                                CaptureBrand.text("Сохранено на устройстве", "Saved on this device")
                                + ". " + CaptureBrand.noteCount(visibleNotes.count)
                            )
                    } else {
                        HStack(spacing: 5) {
                            Image(systemName: "internaldrive")
                            Text(CaptureBrand.text("Сохранено на устройстве", "Saved on this device"))
                            Spacer()
                            Text(CaptureBrand.noteCount(visibleNotes.count))
                                .monospacedDigit()
                        }
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)

                visibleTypeFilters

                if let noteID = store.reminderTargetID {
                    reminderTargetPanel(noteID)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }

                if store.recordings.isEmpty && store.localNotes.isEmpty {
                    // ContentUnavailableView truncates its description under
                    // large accessibility fonts, even with short localized
                    // copy. Keep the message fully readable and scrollable.
                    ScrollView {
                        VStack(spacing: 14) {
                            Image(systemName: "waveform")
                                .font(.system(size: 44))
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                            Text(CaptureBrand.text("Пока нет записей", "Nothing yet"))
                                .font(.title2.weight(.semibold))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(CaptureBrand.text(
                                "Нажмите «+» для текста или вернитесь к записи.",
                                "Use + for text, or go back to record."
                            ))
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            Button {
                                importingAudio = true
                            } label: {
                                Label(CaptureBrand.text("Импорт аудио из «Файлов»", "Import audio from Files"),
                                      systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("what.library.importAudio.empty")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .frame(minHeight: 260)
                    }
                    .scrollIndicators(.hidden)
                    .accessibilityIdentifier("what.library.empty")
                } else if dayGroups.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty
                            ? emptyFolderMessage
                            : CaptureBrand.text("Записи не найдены", "No matching recordings"),
                        systemImage: searchText.isEmpty ? "tray" : "magnifyingglass",
                        description: Text(searchText.isEmpty
                            ? CaptureBrand.text("Заметки в архиве остаются на устройстве.", "Archived notes stay on this device.")
                            : CaptureBrand.text("Поиск по текстам и датам.", "Search looks through saved transcripts and dates."))
                    )
                    if typeFilter != .all {
                        Button(CaptureBrand.text("Показать все типы", "Show all types")) {
                            typeFilter = .all
                        }
                        .accessibilityIdentifier("what.filter.reset")
                        .padding(.top, 6)
                    }
                } else {
                    List {
                        ForEach(dayGroups) { group in
                            Section(localizedDayTitle(group.day.rawValue)) {
                                ForEach(group.notes) { item in
                                    switch item {
                                    case .audio(let recording):

                                    recordingRow(recording)
                                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                            Button {
                                                store.setArchived(
                                                    recording,
                                                    archived: !store.archivedIDs.contains(recording.id)
                                                )
                                            } label: {
                                                Label(
                                                    selectedFolder == .archive ? CaptureBrand.text("Вернуть", "Restore") : CaptureBrand.text("Архив", "Archive"),
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
                                    case .local(let note):
                                        localNoteRow(note)
                                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                                Button {
                                                    store.setArchived(note, archived: !note.archived)
                                                } label: {
                                                    Label(note.archived
                                                              ? CaptureBrand.text("Вернуть", "Restore")
                                                              : CaptureBrand.text("В архив", "Archive"),
                                                          systemImage: note.archived ? "tray.and.arrow.up" : "archivebox")
                                                }
                                                .tint(.indigo)
                                            }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button(role: .destructive) {
                                                    localNoteToDelete = note
                                                } label: {
                                                    Label(CaptureBrand.text("Удалить", "Delete"), systemImage: "trash")
                                                }
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
            .fileImporter(isPresented: $importingAudio, allowedContentTypes: [.audio]) { result in
                guard !importInProgress else { return }
                guard case .success(let url) = result else {
                    // Closing the Files picker is normal; other provider errors
                    // must not vanish silently.
                    if case .failure(let error) = result,
                       (error as NSError).code != NSUserCancelledError {
                        store.errorMessage = error.localizedDescription
                    }
                    return
                }
                importInProgress = true
                Task {
                    defer { importInProgress = false }
                    do {
                        _ = try await store.importAudioFromFiles(url)
                        selectedFolder = .inbox
                        typeFilter = .audio
                        searchText = ""
                    } catch {
                        store.errorMessage = error.localizedDescription
                    }
                }
            }
            .navigationTitle(CaptureBrand.name)
            .toolbar(dynamicTypeSize.isAccessibilitySize ? .hidden : .visible,
                     for: .navigationBar)
            .toolbar {
                if !dynamicTypeSize.isAccessibilitySize {
                    ToolbarItem(placement: .topBarLeading) {
                        libraryRecordAction
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        libraryTextAction
                        librarySettingsAction
                    }
                }
            }
            .frame(maxWidth: 960)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemGroupedBackground))
            .tint(ArvectumSemanticColors.actionBackground)
            .sheet(isPresented: $showDiagnostics, onDismiss: {
                showTranscriptRecovery = false
            }) {
                settingsSheet
            }
            .sheet(item: $preparedExport, onDismiss: {
                preparedExport?.cleanUp()
            }) { export in
                RecordingShareSheet(export: export)
            }
            .sheet(item: $localNoteToEdit) { note in
                TextNoteSheet(note: note).environmentObject(store)
            }
            .sheet(item: $reviewNoteToSend) { draft in
                ReviewNoteHandoffConfirmation(draft: draft)
            }
            .sheet(item: $localVideoToPlay) { note in
                if let url = store.videoURL(for: note) {
                    VideoPlaybackSheet(url: url)
                }
            }
            .alert(
                CaptureBrand.text("Удалить заметку?", "Delete note?"),
                isPresented: Binding(
                    get: { localNoteToDelete != nil },
                    set: { if !$0 { localNoteToDelete = nil } }
                ),
                presenting: localNoteToDelete
            ) { note in
                Button(CaptureBrand.text("Удалить навсегда", "Delete permanently"),
                       role: .destructive) {
                    store.delete(note)
                    localNoteToDelete = nil
                }
                Button(CaptureBrand.text("Отмена", "Cancel"), role: .cancel) {
                    localNoteToDelete = nil
                }
            } message: { _ in
                Text(CaptureBrand.text("Заметка и видео будут удалены с устройства.",
                                       "This note and its video will be deleted from this device."))
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

    /// At Accessibility Dynamic Type, toolbar actions must occupy native
    /// content rather than UIKit's compact, inaccessible navigation items.
    private var accessibleLibraryActions: some View {
        HStack(spacing: 12) {
            libraryRecordAction
            Spacer(minLength: 8)
            libraryTextAction
            librarySettingsAction
        }
        .padding(.horizontal, ArvectumDesignMetrics.compactHorizontalInset)
        .padding(.vertical, ArvectumDesignMetrics.spaceS)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    private var libraryRecordAction: some View {
        Button(action: openCaptureHome) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    // Icon-only at AXXXL; the full action remains in the
                    // accessibility label and is spoken by VoiceOver.
                    Image(systemName: "mic.fill")
                        .font(.title2)
                        .frame(
                            minWidth: ArvectumDesignMetrics.accessibilityActionSize,
                            minHeight: ArvectumDesignMetrics.accessibilityActionSize
                        )
                } else {
                    Label(CaptureBrand.text("Записать", "Record"), systemImage: "mic.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 64)
                        .padding(.horizontal, 8)
                }
            }
            .contentShape(Rectangle())
        }
        .accessibilityLabel(CaptureBrand.text("Вернуться к быстрой записи",
                                              "Back to quick recording"))
        .accessibilityIdentifier("what.library.backToRecord")
    }

    private var libraryTextAction: some View {
        Button {
            store.showTextCapture = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.medium))
                .frame(
                    minWidth: ArvectumDesignMetrics.accessibilityActionSize,
                    minHeight: ArvectumDesignMetrics.accessibilityActionSize
                )
                .contentShape(Rectangle())
        }
        .accessibilityLabel(CaptureBrand.text("Создать текстовую заметку",
                                              "New text note"))
        .accessibilityIdentifier("what.library.newText")
    }

    @ViewBuilder
    private var settingsSheet: some View {
        if showTranscriptRecovery {
            TranscriptRecoveryView(
                statusProvider: { store.transcriptRecoveryStatus() },
                restore: { try store.restoreTranscriptCatalogFromBackup() }
            )
        } else {
            SyncDiagnosticsView().environmentObject(store)
        }
    }

    private func localizedDayTitle(_ value: String) -> String {
        switch value {
        case "Today": return CaptureBrand.text("Сегодня", "Today")
        case "Yesterday": return CaptureBrand.text("Вчера", "Yesterday")
        case "Earlier": return CaptureBrand.text("Ранее", "Earlier")
        default: return value
        }
    }

    private var librarySettingsAction: some View {
        Menu {
            Button {
                importingAudio = true
            } label: {
                Label(CaptureBrand.text("Импорт аудио из «Файлов»", "Import audio from Files"),
                      systemImage: "square.and.arrow.down")
            }
            .disabled(importInProgress)
            .accessibilityIdentifier("what.library.importAudio")
            Divider()
            AutoFollowUpSettingsMenu(manager: store.reminderManager)
            Picker(CaptureBrand.text("Язык распознавания речи",
                                     "Speech recognition language"),
                   selection: $store.transcriptionLocale) {
                Text("Русский").tag("ru-RU")
                Text("English").tag("en-US")
                Text("Español").tag("es-ES")
                Text("Français").tag("fr-FR")
            }
            Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                Label(
                    CaptureBrand.text(
                        "Язык интерфейса — в настройках iOS",
                        "Interface language: iOS Settings"
                    ),
                    systemImage: "globe"
                )
            }
            Button {
                showDiagnostics = true
            } label: {
                Label(CaptureBrand.text("Диагностика синхронизации", "Sync diagnostics"),
                      systemImage: "applewatch")
            }
            Button {
                showTranscriptRecovery = true
                showDiagnostics = true
            } label: {
                Label(CaptureBrand.text("Восстановление расшифровок", "Transcript recovery"),
                      systemImage: "externaldrive.badge.timemachine")
            }
            .accessibilityIdentifier("what.library.recovery")
            Link(CaptureBrand.text("Конфиденциальность", "Privacy policy"),
                 destination: URL(string: "https://arvectum.com/privacy")!)
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
                .frame(
                    minWidth: ArvectumDesignMetrics.accessibilityActionSize,
                    minHeight: ArvectumDesignMetrics.accessibilityActionSize
                )
                .contentShape(Rectangle())
        }
        .accessibilityLabel(CaptureBrand.text("Настройки и диагностика",
                                              "App settings and diagnostics"))
        .accessibilityIdentifier("what.library.settings")
    }

    private func noteKindLabel(_ note: LocalNote) -> some View {
        Label(note.kind == .text
              ? CaptureBrand.text("Текст", "Text")
              : CaptureBrand.text("Видео", "Video"),
              systemImage: note.kind == .text ? "note.text" : "video.fill")
            .font(.headline)
    }

    private func localNoteRow(_ note: LocalNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    // Keep the type metadata readable on narrow physical
                    // iPhones while preserving the full VoiceOver label.
                    VStack(alignment: .leading, spacing: 4) {
                        // Cap metadata only; body text continues to follow
                        // the user's complete Dynamic Type selection.
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: note.kind == .text
                                  ? "note.text" : "video.fill")
                                .accessibilityHidden(true)
                            Text(note.kind == .text
                                 ? CaptureBrand.text("Текст", "Text")
                                 : CaptureBrand.text("Видео", "Video"))
                                .fixedSize(horizontal: false, vertical: true)
                                .layoutPriority(1)
                        }
                        .font(.headline)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                        Text(note.createdAt, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack {
                        noteKindLabel(note)
                        Spacer()
                        Text(note.createdAt, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if note.kind == .text {
                Text(note.body)
                    // AXXXL may need 10+ visual lines even for a short note.
                    // Do not clip the body: the containing List scrolls.
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 4)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                Button(CaptureBrand.text("Редактировать", "Edit")) {
                    localNoteToEdit = note
                }
                .font(.subheadline.bold())
                .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 64 : 48, alignment: .leading)
                .contentShape(Rectangle())
            } else {
                if let url = store.videoURL(for: note),
                   FileManager.default.fileExists(atPath: url.path) {
                    HStack {
                        VideoPoster(url: url)
                            .frame(width: 76, height: 68)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                            .accessibilityHidden(true)
                        Button {
                            localVideoToPlay = note
                        } label: {
                            Label(CaptureBrand.text("Смотреть", "Play video"),
                                  systemImage: "play.rectangle.fill")
                        }
                        ShareLink(item: url) {
                            Label(CaptureBrand.text("Экспорт", "Export"),
                                  systemImage: "square.and.arrow.up")
                        }
                    }
                    if let duration = note.duration {
                        Text(self.duration(duration))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Label(CaptureBrand.text("Видео недоступно", "Video missing"),
                          systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
            (dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                : AnyLayout(HStackLayout(spacing: 8))) {
                reminderMenu(note.id)
                    .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 64 : 52)
                    .contentShape(Rectangle())
                Button {
                    reviewNoteToSend = ReviewNoteHandoffDraft(
                        id: note.id,
                        kind: note.kind == .text ? .text : .video,
                        createdAt: note.createdAt,
                        text: note.body.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                } label: {
                    Label(CaptureBrand.text("В ChickMark", "To ChickMark"),
                          systemImage: "arrowshape.turn.up.right")
                }
                .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 64 : 48)
                .contentShape(Rectangle())
                .accessibilityIdentifier("what.note.sendToChickMark")
                Button {
                    store.setArchived(note, archived: !note.archived)
                } label: {
                    Label(note.archived ? CaptureBrand.text("Вернуть", "Restore") :
                          CaptureBrand.text("В архив", "Archive"),
                          systemImage: note.archived ? "tray.and.arrow.up" : "archivebox")
                }
                .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 64 : 48)
                .contentShape(Rectangle())
                if !dynamicTypeSize.isAccessibilitySize {
                    Spacer(minLength: 0)
                }
                Button(role: .destructive) {
                    localNoteToDelete = note
                } label: {
                    Image(systemName: "trash")
                        .frame(minWidth: 48, minHeight: dynamicTypeSize.isAccessibilitySize ? 64 : 48)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(CaptureBrand.text("Удалить заметку", "Delete note"))
                .accessibilityIdentifier("what.note.delete")
            }
            .font(.caption)
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 5)
    }

    @ViewBuilder
    private func reminderTargetPanel(_ noteID: UUID) -> some View {
        if let audio = store.recordings.first(where: { $0.id == noteID }) {
            reminderPanel(
                id: noteID,
                summary: store.transcripts[noteID]?.prefix(90).description
                    ?? CaptureBrand.text("Голосовая заметка", "Voice note")
            ) {
                store.togglePlayback(audio)
            }
        } else if let note = store.localNotes.first(where: { $0.id == noteID }) {
            reminderPanel(
                id: noteID,
                summary: note.kind == .text
                    ? String(note.body.prefix(90))
                    : CaptureBrand.text("Видеозаметка", "Video note")
            ) {
                if note.kind == .text {
                    localNoteToEdit = note
                } else {
                    localVideoToPlay = note
                }
            }
        }
    }

    private func reminderPanel(
        id: UUID, summary: String, open: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(CaptureBrand.text("Исходная заметка", "Original note"),
                      systemImage: "doc.text.magnifyingglass")
                    .font(.headline)
                    .accessibilityIdentifier("what.note.deepLinkResolved")
                Spacer()
                Button {
                    store.reminderTargetID = nil
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel(CaptureBrand.text("Скрыть", "Dismiss"))
            }
            Text(summary)
                .font(.subheadline)
                .lineLimit(3)
            HStack {
                Button(action: open) {
                    Label(CaptureBrand.text("Открыть", "Open"), systemImage: "arrow.up.right")
                }
                Button {
                    store.reminderManager.markReviewed(id)
                    store.reminderTargetID = nil
                } label: {
                    Label(CaptureBrand.text("Просмотрено", "Reviewed"),
                          systemImage: "checkmark.circle")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityIdentifier("what.reminder.target")
    }

    private func reminderMenu(_ noteID: UUID) -> some View {
        let existing = store.reminderManager.reminder(for: noteID)
        return Menu {
            Button(CaptureBrand.text("Через 1 час", "In 1 hour")) {
                Task { await store.reminderManager.schedule(noteID: noteID, afterHours: 1) }
            }
            Button(CaptureBrand.text("Через 2 часа", "In 2 hours")) {
                Task { await store.reminderManager.schedule(noteID: noteID, afterHours: 2) }
            }
            Button(CaptureBrand.text("Через 3 часа", "In 3 hours")) {
                Task { await store.reminderManager.schedule(noteID: noteID, afterHours: 3) }
            }
            if let existing, existing.status == .scheduled {
                Divider()
                Text(existing.remindAt, format: .dateTime.day().month().hour().minute())
                Button(CaptureBrand.text("Отменить напоминание", "Cancel reminder"),
                       role: .destructive) {
                    store.reminderManager.cancel(noteID)
                }
            }
            if let existing, existing.status != .reviewed {
                Button(CaptureBrand.text("Отметить просмотренной", "Mark reviewed")) {
                    store.reminderManager.markReviewed(noteID)
                }
            }
        } label: {
            Label(CaptureBrand.text("Напомнить", "Remind"), systemImage: "bell")
                .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 64 : 52, alignment: .leading)
                .contentShape(Rectangle())
        }
        .accessibilityIdentifier("what.reminder.menu")
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
            } else if store.isAudioComplete(recording),
                      store.transcribingID != recording.id {
                // Reviewers mistook the global "Text 0" filter for a failed
                // transcript. Explain the explicitly opt-in conversion here.
                Text(CaptureBrand.text(
                    "Текста пока нет. Нажмите «Расшифровать», чтобы получить его из аудио.",
                    "No text yet. Tap Transcribe to turn this audio into text."
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("what.recording.transcriptionHint")
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
            reminderMenu(recording.id)
            if let transcript = store.transcripts[recording.id],
               !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    reviewNoteToSend = ReviewNoteHandoffDraft(
                        id: recording.id, kind: .audio,
                        createdAt: recording.createdAt, text: transcript
                    )
                } label: {
                    Label(CaptureBrand.text("Передать в ChickMark", "Send to ChickMark"),
                          systemImage: "arrowshape.turn.up.right")
                }
                .accessibilityIdentifier("what.note.sendToChickMark")
            }
            Divider()
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


/// An explicit, discoverable opt-in. Editing an old recording or reopening
/// the Inbox never triggers automatic reminders or prompts for permission.
private struct AutoFollowUpSettingsMenu: View {
    @ObservedObject var manager: NoteReminderManager

    private func title(for hours: Int) -> String {
        switch hours {
        case 1: return CaptureBrand.text("Через 1 час", "After 1 hour")
        case 2: return CaptureBrand.text("Через 2 часа", "After 2 hours")
        case 3: return CaptureBrand.text("Через 3 часа", "After 3 hours")
        default: return CaptureBrand.text("Выключено", "Off")
        }
    }

    var body: some View {
        Menu {
            ForEach([0, 1, 2, 3], id: \.self) { hours in
                Button {
                    Task { await manager.configureAutomaticFollowUp(hours: hours) }
                } label: {
                    if manager.automaticDelayHours == hours {
                        Label(title(for: hours), systemImage: "checkmark")
                    } else {
                        Text(title(for: hours))
                    }
                }
            }
            Divider()
            Text(CaptureBrand.text(
                "Только новые заметки, с разрешения пользователя",
                "New notes only, with your permission"
            ))
        } label: {
            Label(CaptureBrand.text("Автоматически напоминать о новых заметках",
                                    "Automatically remind about new notes"),
                  systemImage: "bell.badge")
        }
        .accessibilityIdentifier("what.settings.autoFollowUp")
    }
}


// MARK: - Explicit, fail-closed transcript recovery

/// Only user-confirmed restoration is permitted. The screen does not read
/// personal transcript text into SwiftUI and never invokes restore on appear.
struct TranscriptRecoveryView: View {
    let statusProvider: () -> RecordingRepository.TranscriptRecoveryStatus
    let restore: () throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var status: RecordingRepository.TranscriptRecoveryStatus = .notNeeded
    @State private var showConfirmation = false
    @State private var showResult = false
    @State private var resultMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(systemName: "externaldrive.badge.timemachine")
                        .font(.largeTitle)
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    Text(CaptureBrand.text(
                        "Восстанавливайте расшифровки только если их файл повреждён.",
                        "Restore transcripts only when their storage is damaged."
                    ))
                    .fixedSize(horizontal: false, vertical: true)

                    Group {
                        switch status {
                        case .notNeeded:
                            Text(CaptureBrand.text(
                                "Хранилище исправно. Восстановление не требуется.",
                                "Transcript storage is healthy. No recovery is needed."
                            ))
                            .accessibilityIdentifier("what.recovery.healthy")
                        case .unavailable:
                            Text(CaptureBrand.text(
                                "Исправная резервная копия недоступна. Данные не изменены.",
                                "No usable backup was found. Your data was not changed."
                            ))
                            .accessibilityIdentifier("what.recovery.unavailable")
                        case .ready(let count):
                            Text(CaptureBrand.formatted(
                                "В резервной копии расшифровок: %d",
                                "Transcripts available in the backup: %d", count
                            ))
                            .accessibilityIdentifier("what.recovery.ready")
                        }
                    }
                    .font(.body.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)

                    if case .ready = status {
                        Button(role: .destructive) {
                            showConfirmation = true
                        } label: {
                            Label(CaptureBrand.text(
                                "Восстановить из копии",
                                "Restore from backup"
                            ), systemImage: "arrow.counterclockwise")
                                // Keep the destructive action fully tappable above
                                // the persistent Done bar at accessibility sizes.
                                // VoiceOver still reads the complete unabridged label.
                                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                                .frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("what.recovery.restore")
                    }
                }
                .frame(maxWidth: 680, alignment: .leading)
                .padding(20)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle(CaptureBrand.text(
                "Восстановление расшифровок", "Transcript recovery"
            ))
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HStack {
                    Spacer()
                    Button(CaptureBrand.text("Готово", "Done")) { dismiss() }
                        .buttonStyle(.bordered)
                        .frame(minWidth: 88, minHeight: 52)
                        .accessibilityIdentifier("what.recovery.done")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.regularMaterial)
            }
            .onAppear { status = statusProvider() }
            .alert(
                CaptureBrand.text("Восстановить расшифровки из копии?",
                                  "Restore transcripts from the backup?"),
                isPresented: $showConfirmation
            ) {
                Button(CaptureBrand.text("Восстановить", "Restore"),
                       role: .destructive) {
                    do {
                        try restore()
                        status = statusProvider()
                        resultMessage = CaptureBrand.text(
                            "Расшифровки восстановлены из резервной копии.",
                            "Transcripts were restored from the backup."
                        )
                    } catch {
                        status = statusProvider()
                        resultMessage = CaptureBrand.formatted(
                            "Не удалось восстановить расшифровки: %@",
                            "Could not restore transcripts: %@",
                            error.localizedDescription
                        )
                    }
                    showResult = true
                }
                .accessibilityIdentifier("what.recovery.confirm")
                Button(CaptureBrand.text("Отмена", "Cancel"), role: .cancel) { }
            } message: {
                Text(CaptureBrand.text(
                    "Будет использована последняя исправная копия. Недавние изменения текста могут отсутствовать. Удалённые заметки не восстанавливаются.",
                    "The last valid backup will be used. Recent text edits may be missing. Deleted notes will not be restored."
                ))
            }
            .alert(
                CaptureBrand.text("Восстановление расшифровок", "Transcript recovery"),
                isPresented: $showResult
            ) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(resultMessage)
            }
        }
    }
}


#if DEBUG
/// Disposable recovery-only UI data. No personal recordings, microphone,
/// Watch queue or app storage is read or changed by this fixture.
struct TranscriptRecoveryQAFixtureView: View {
    private let repository: RecordingRepository

    init() {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-recovery-ui-\(UUID().uuidString)")
        let repo = RecordingRepository(rootURL: root)
        // A unique disposable root for every UI launch. Only this root is mutated.
        // Scenarios must exercise the real recovery gate, not a mocked status.
        try? repo.saveTranscript("synthetic QA-only transcript", for: UUID())
        try? repo.saveTranscript("second QA-only transcript", for: UUID())
        let args = ProcessInfo.processInfo.arguments
        let backup = root.appendingPathComponent("transcripts.backup.json")
        if args.contains("--qa-transcript-recovery-missing-backup") {
            try? FileManager.default.removeItem(at: backup)
        } else if args.contains("--qa-transcript-recovery-corrupt-backup") {
            try? Data("{damaged-backup".utf8).write(to: backup, options: .atomic)
        } else if args.contains("--qa-transcript-recovery-empty-backup") {
            try? Data("{}".utf8).write(to: backup, options: .atomic)
        }
        if !args.contains("--qa-transcript-recovery-healthy") {
            try? Data("{corrupt-for-ui-qa".utf8)
                .write(to: root.appendingPathComponent("transcripts.json"), options: .atomic)
        }
        repository = repo
    }

    var body: some View {
        TranscriptRecoveryView(
            statusProvider: { repository.transcriptRecoveryStatus() },
            restore: { try repository.restoreTranscriptCatalogFromBackup() }
        )
        .environment(\.dynamicTypeSize, .accessibility5)
    }
}
#endif
