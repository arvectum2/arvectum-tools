import SwiftUI
import ArvectumCore

/// Manual corrections are an independent local text draft.
/// Dismissal discards the draft; Save persists atomically before closing.
struct TranscriptEditorSheet: View {
    let recording: RecordingEnvelope
    let initialText: String
    let onSave: (String) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var draft: String
    @State private var saveError: String?
    @FocusState private var isEditing: Bool

    init(
        recording: RecordingEnvelope,
        initialText: String,
        onSave: @escaping (String) throws -> Void
    ) {
        self.recording = recording
        self.initialText = initialText
        self.onSave = onSave
        _draft = State(initialValue: initialText)
    }

    private var canSave: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && draft != initialText
    }

    var body: some View {
        NavigationStack {
            ArvectumReadableColumn(maxWidth: 760) {
                VStack(alignment: .leading, spacing: 12) {
                Text(recording.createdAt, format: .dateTime.day().month().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $draft)
                    .font(.body)
                    .focused($isEditing)
                    .scrollContentBackground(.hidden)
                    .accessibilityLabel(CaptureBrand.text("Текст записи", "Recording transcription"))
                    .accessibilityIdentifier("what.transcript.editor")
                    .padding(8)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))

                Text(CaptureBrand.text("Исправление текста не меняет оригинальное аудио.", "Editing changes only the transcript. Your original audio is never modified."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            }
            .navigationTitle(initialText.isEmpty
                ? CaptureBrand.text("Добавить текст", "Add text")
                : CaptureBrand.text("Править расшифровку", "Edit transcription"))
            .navigationBarTitleDisplayMode(.inline)
            // UIKit limits nav-bar buttons to about 36 pt, even with
            // large Dynamic Type. Provide full-size controls at AX sizes.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if dynamicTypeSize.isAccessibilitySize {
                    HStack(spacing: 12) {
                        Button(CaptureBrand.text("Отмена", "Cancel")) { dismiss() }
                            .buttonStyle(.bordered)
                            .frame(minWidth: 88, minHeight: 52)
                            .contentShape(Rectangle())
                            .accessibilityIdentifier("what.transcript.cancel")
                        Spacer(minLength: 0)
                        Button(CaptureBrand.text("Сохранить", "Save")) { save() }
                            .buttonStyle(.borderedProminent)
                            .frame(minWidth: 88, minHeight: 52)
                            .contentShape(Rectangle())
                            .disabled(!canSave)
                            .accessibilityIdentifier("what.transcript.save")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.regularMaterial)
                }
            }
            .toolbar {
                if !dynamicTypeSize.isAccessibilitySize {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(CaptureBrand.text("Отмена", "Cancel")) { dismiss() }
                            .accessibilityIdentifier("what.transcript.cancel")
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(CaptureBrand.text("Сохранить", "Save")) { save() }
                            .disabled(!canSave)
                            .fontWeight(.semibold)
                            .accessibilityIdentifier("what.transcript.save")
                    }
                }
            }
            .alert(CaptureBrand.text("Не удалось сохранить", "Could not save changes"), isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    private func save() {
        guard canSave else { return }
        do {
            try onSave(draft)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}


#if DEBUG
/// Standalone synthetic transcript QA host. Its save closure does not
/// write to the recording repository, iCloud or original audio.
struct TranscriptEditorQAFixtureView: View {
    @State private var showEditor = false

    private var fixtureTypeSize: DynamicTypeSize {
        ProcessInfo.processInfo.arguments.contains("--qa-transcript-editor-synthetic-normal")
            ? .medium : .accessibility5
    }

    var body: some View {
        Button { showEditor = true } label: {
            Image(systemName: "square.and.pencil")
                .frame(minWidth: 88, minHeight: 52)
        }
            .accessibilityLabel(CaptureBrand.text("Править расшифровку", "Edit transcription"))
            .accessibilityIdentifier("what.qa.transcript.open")
            .sheet(isPresented: $showEditor) {
                TranscriptEditorSheet(
                    recording: RecordingEnvelope(
                        id: UUID(uuidString: "AAAA0000-0000-0000-0000-000000009301")!,
                        createdAt: Date(timeIntervalSince1970: 0),
                        duration: 1,
                        fileName: "synthetic-qa-not-a-file.m4a"
                    ),
                    initialText: "Texto de prueba",
                    onSave: { _ in
                        // Error UI QA path is in memory only; never write.
                        if ProcessInfo.processInfo.arguments.contains(
                            "--qa-transcript-editor-synthetic-error"
                        ) {
                            throw RecordingRepository.RepositoryError.transcriptStoreUnreadable
                        }
                    }
                )
                .environment(\.dynamicTypeSize, fixtureTypeSize)
            }
    }
}
#endif
