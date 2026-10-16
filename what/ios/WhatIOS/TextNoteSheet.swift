import SwiftUI

/// Every keystroke is saved atomically. A new empty note is not created until
/// the user types; closing or backgrounding never discards written content.
struct TextNoteSheet: View {
    @EnvironmentObject private var store: PhoneStore
    @Environment(\.dismiss) private var dismiss
    let note: LocalNote?
    @State private var id = UUID()
    @State private var bodyText = ""
    @State private var ready = false
    @FocusState private var editorFocused: Bool

    init(note: LocalNote? = nil) { self.note = note }

    var body: some View {
        NavigationStack {
            TextEditor(text: $bodyText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .frame(maxWidth: 860)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("what.text.editor")
                .focused($editorFocused)
                .navigationTitle(CaptureBrand.text("Текстовая заметка", "Text note"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(CaptureBrand.text("Готово", "Done")) { dismiss() }
                    }
                }
                .onAppear {
                    if let note {
                        id = note.id
                        bodyText = note.body
                    }
                    ready = true
                    editorFocused = true
                }
                .onChange(of: bodyText) { _, text in
                    guard ready else { return }
                    store.saveText(id: id, body: text)
                }
                .overlay(alignment: .topLeading) {
                    if bodyText.isEmpty {
                        Text(CaptureBrand.text("Запишите мысль…", "Catch a thought…"))
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 20)
                            .padding(.top, 10)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
}
