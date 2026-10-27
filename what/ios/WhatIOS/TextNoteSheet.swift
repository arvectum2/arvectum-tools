import SwiftUI
import ArvectumCore

/// Every keystroke is saved atomically. A new empty note is not created until
/// the user types; closing or backgrounding never discards written content.
struct TextNoteSheet: View {
    @EnvironmentObject private var store: PhoneStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let note: LocalNote?
    @State private var id = UUID()
    @State private var bodyText = ""
    @State private var ready = false
    @FocusState private var editorFocused: Bool

    init(note: LocalNote? = nil) { self.note = note }

    var body: some View {
        NavigationStack {
            ArvectumReadableColumn(maxWidth: 860) {
                TextEditor(text: $bodyText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .accessibilityLabel(CaptureBrand.text("Текст заметки", "Note text"))
                    .accessibilityHint(CaptureBrand.text(
                        "Сохраняется автоматически по мере ввода",
                        "Saved automatically as you type"
                    ))
                    .padding(.horizontal, 12)
            }
                .accessibilityIdentifier("what.text.editor")
                .focused($editorFocused)
                .navigationTitle(CaptureBrand.text("Текстовая заметка", "Text note"))
                .navigationBarTitleDisplayMode(.inline)
                // UIKit's navigation toolbar clips its button to 36 pt even
                // if the label requests 44 pt. Give large-text users a
                // separate reachable action above the software keyboard.
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if dynamicTypeSize.isAccessibilitySize {
                        HStack {
                            Spacer()
                            Button(CaptureBrand.text("Готово", "Done")) {
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(minWidth: 88, minHeight: 52)
                            .contentShape(Rectangle())
                            .accessibilityIdentifier("what.text.done")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.regularMaterial)
                    }
                }
                .toolbar {
                    if !dynamicTypeSize.isAccessibilitySize {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(CaptureBrand.text("Готово", "Done")) {
                                dismiss()
                            }
                            .accessibilityIdentifier("what.text.done")
                        }
                    }
                }
                .onAppear {
                    if let note {
                        id = note.id
                        bodyText = note.body
                    }
#if DEBUG
                    // A text-editor marketing screenshot must show a real
                    // in-memory sample without writing to any repository.
                    if note == nil &&
                       ProcessInfo.processInfo.arguments.contains(
                        "--qa-aso-filled-library"
                       ) {
                        bodyText = store.localNotes.first?.body ?? ""
                        ready = true
                        editorFocused = false
                        return
                    }
#endif
                    ready = true
                    editorFocused = true
                }
                .onChange(of: bodyText) { _, text in
                    guard ready else { return }
#if DEBUG
                    if ProcessInfo.processInfo.arguments.contains(
                        "--qa-aso-filled-library"
                    ) { return }
#endif
                    store.saveText(id: id, body: text)
                }
                .onDisappear {
#if DEBUG
                    if ProcessInfo.processInfo.arguments.contains(
                        "--qa-aso-filled-library"
                    ) { return }
#endif
                    // Only newly created notes are eligible for automatic
                    // follow-up. Editing an old note must never reschedule it.
                    if note == nil { store.finishedNewTextNote(id: id) }
                }
                .overlay(alignment: .topLeading) {
                    // At AX sizes the editor already has an accessible title
                    // and hint; omit the decorative overlay entirely so it
                    // cannot become a duplicate focus target in XCTest/VO.
                    if bodyText.isEmpty && !dynamicTypeSize.isAccessibilitySize {
                        Text(CaptureBrand.text("Запишите мысль…", "Catch a thought…"))
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 20)
                            .padding(.top, 10)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
        }
    }
}
