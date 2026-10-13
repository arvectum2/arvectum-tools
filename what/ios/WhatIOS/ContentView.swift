import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PhoneStore
    @State private var recordingToDelete: RecordingEnvelope?
    @State private var recordingToEdit: RecordingEnvelope?
    @State private var recordingToRetranscribe: RecordingEnvelope?
    @State private var selectedFolder: InboxFolder = .inbox
    @State private var searchText = ""
    @State private var preparedExport: PreparedRecordingExport?
    @State private var showSmartSearch = false
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
                Picker("Folder", selection: $selectedFolder) {
                    ForEach(InboxFolder.allCases) { folder in
                        Text(folder.rawValue).tag(folder)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                HStack(spacing: 5) {
                    Image(systemName: "iphone.gen3")
                    Text("Saved locally on iPhone")
                    Spacer()
                    Text("\(visibleRecordings.count) recordings")
                        .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)

                if store.recordings.isEmpty {
                    ContentUnavailableView(
                        "Nothing yet",
                        systemImage: "waveform",
                        description: Text("Record a thought on Apple Watch. It will appear here after a safe transfer.")
                    )
                } else if dayGroups.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty
                            ? (selectedFolder == .archive ? "Archive is empty" : "Inbox is empty")
                            : "No matching recordings",
                        systemImage: searchText.isEmpty ? "tray" : "magnifyingglass",
                        description: Text(searchText.isEmpty
                            ? "Archived recordings stay saved on this iPhone."
                            : "Search looks through saved transcripts and dates.")
                    )
                } else {
                    List {
                        ForEach(dayGroups) { group in
                            Section(group.day.rawValue) {
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
                                                    selectedFolder == .archive ? "Restore" : "Archive",
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
                                                Label("Delete", systemImage: "trash")
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
                                                    selectedFolder == .archive ? "Restore to Inbox" : "Archive recording",
                                                    systemImage: selectedFolder == .archive
                                                        ? "tray.and.arrow.up" : "archivebox"
                                                )
                                            }
                                            Button(role: .destructive) {
                                                recordingToDelete = recording
                                            } label: {
                                                Label("Delete recording", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { store.reload() }
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
            .searchable(text: $searchText, prompt: "Search transcripts and dates")
            .navigationTitle("What?")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSmartSearch = true
                    } label: {
                        Image(systemName: "sparkle.magnifyingglass")
                    }
                    .accessibilityLabel("Smart search")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        store.showPhoneCapture = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Record on iPhone")
                    Menu {
                        Picker("Speech language", selection: $store.transcriptionLocale) {
                            Text("Русский").tag("ru-RU")
                            Text("English").tag("en-US")
                            Text("Español").tag("es-ES")
                        }
                        Button {
                            showDiagnostics = true
                        } label: {
                            Label("Sync diagnostics", systemImage: "applewatch")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("App settings and diagnostics")
                }
            }
            .tint(Color(red: 67 / 255, green: 229 / 255, blue: 197 / 255))
            .sheet(isPresented: $store.showPhoneCapture) {
                PhoneRecordingSheet(recorder: store.phoneRecorder)
            }
            .sheet(isPresented: $showSmartSearch) {
                SmartSearchView()
                    .environmentObject(store)
            }
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
            if store.isAudioAvailable(recording) {
                Label("Audio saved on iPhone", systemImage: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Label("Audio missing on iPhone", systemImage: "exclamationmark.triangle")
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
                Text(store.playingID == recording.id ? "Stop" : "Play")
                    .lineLimit(1)
            }
            .font(.subheadline.weight(.semibold))
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.accentColor.opacity(0.12), in: Capsule())
        }
        .disabled(!store.isAudioAvailable(recording))
        .accessibilityLabel(store.playingID == recording.id ? "Stop audio" : "Play audio")
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
                    ? "Cancel" : (hasTranscript ? "Edit text" : "Transcribe"))
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
                    store.transcripts[recording.id] == nil ? "Add text" : "Edit text",
                    systemImage: "square.and.pencil"
                )
            }

            if store.transcripts[recording.id] != nil,
               store.isAudioAvailable(recording) {
                Button {
                    recordingToRetranscribe = recording
                } label: {
                    Label("Retry transcription", systemImage: "arrow.clockwise")
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
                        Label("Audio + transcript", systemImage: "square.on.square")
                    }
                }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
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
                        ? "Restore to Inbox" : "Archive recording",
                    systemImage: store.archivedIDs.contains(recording.id)
                        ? "tray.and.arrow.up" : "archivebox"
                )
            }

            Button(role: .destructive) {
                recordingToDelete = recording
            } label: {
                Label("Delete recording", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("More recording actions")
        .alert("Replace existing transcription?", isPresented: Binding(
            get: { recordingToRetranscribe?.id == recording.id },
            set: { if !$0 { recordingToRetranscribe = nil } }
        )) {
            Button("Replace transcription", role: .destructive) {
                store.transcribe(recording)
                recordingToRetranscribe = nil
            }
            Button("Cancel", role: .cancel) {
                recordingToRetranscribe = nil
            }
        } message: {
            Text("A new transcription will replace your current text, including any manual corrections. The original audio will be kept.")
        }
    }

    private func duration(_ value: TimeInterval) -> String {
        let total = max(0, Int(value.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
