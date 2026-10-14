import SwiftUI

/// Manual corrections are an independent local text draft.
/// Dismissal discards the draft; Save persists atomically before closing.
struct TranscriptEditorSheet: View {
    let recording: RecordingEnvelope
    let initialText: String
    let onSave: (String) throws -> Void

    @Environment(\.dismiss) private var dismiss
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
            VStack(alignment: .leading, spacing: 12) {
                Text(recording.createdAt, format: .dateTime.day().month().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $draft)
                    .font(.body)
                    .focused($isEditing)
                    .scrollContentBackground(.hidden)
                    .accessibilityLabel(CaptureBrand.text("Текст записи", "Recording transcription"))
                    .padding(8)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))

                Text(CaptureBrand.text("Исправление текста не меняет оригинальное аудио.", "Editing changes only the transcript. Your original audio is never modified."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle(initialText.isEmpty
                ? CaptureBrand.text("Добавить текст", "Add text")
                : CaptureBrand.text("Править расшифровку", "Edit transcription"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CaptureBrand.text("Отмена", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(CaptureBrand.text("Сохранить", "Save")) { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
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
