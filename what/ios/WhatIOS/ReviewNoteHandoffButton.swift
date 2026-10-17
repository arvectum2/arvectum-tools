import SwiftUI
import UIKit

/// Stable presentation state belongs to the Inbox, not to ephemeral Menu
/// children (a menu closes before its user's confirmation sheet opens).
struct ReviewNoteHandoffDraft: Identifiable {
    let id: UUID
    let kind: ReviewNoteHandoff.Kind
    let createdAt: Date
    let text: String
}

struct ReviewNoteHandoffConfirmation: View {
    @Environment(\.dismiss) private var dismiss
    let draft: ReviewNoteHandoffDraft
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(CaptureBrand.text(
                        "Создать разовое напоминание по этой заметке в ChickMark?",
                        "Create a one-time follow-up for this note in ChickMark?"
                    ))
                    if !draft.text.isEmpty {
                        Text(draft.text).lineLimit(8).textSelection(.enabled)
                    }
                }
                Section {
                    Text(CaptureBrand.text(
                        "Текст временно заменит буфер обмена на этом устройстве на срок до 5 минут. ChickMark запросит подтверждение перед сохранением. Данные не отправляются в интернет.",
                        "The full note temporarily replaces this device's clipboard for up to five minutes. ChickMark asks before saving. Nothing is uploaded."
                    ))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(CaptureBrand.text("Передать в ChickMark", "Send to ChickMark"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CaptureBrand.text("Отмена", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(CaptureBrand.text("Продолжить", "Continue")) { send() }
                        .accessibilityIdentifier("what.note.handoff.confirm")
                }
            }
            .alert(CaptureBrand.text("Передача заметки", "Note transfer"),
                   isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                   )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func send() {
        do {
            let payload = try ReviewNoteHandoff(
                noteID: draft.id, kind: draft.kind,
                createdAt: draft.createdAt, text: draft.text
            )
            let data = try JSONEncoder().encode(payload)
            // A native iOS PasteButton in ChickMark consumes the standard
            // text representation without private cross-app paste prompts.
            // The transfer body stays OUT of the URL, is short-lived and
            // only exists because the user confirmed this specific handoff.
            UIPasteboard.general.setItems(
                [[ReviewNoteHandoff.clipboardType: data,
                  "public.utf8-plain-text": try payload.clipboardString()]],
                options: [
                    .localOnly: true,
                    .expirationDate: Date().addingTimeInterval(ReviewNoteHandoff.validFor)
                ]
            )
            UIApplication.shared.open(payload.recipientURL, options: [:]) { opened in
                guard !opened else { return }
                Task { @MainActor in
                    errorMessage = CaptureBrand.text(
                        "ChickMark не найден или не поддерживает приём заметок. Обновите приложение и повторите передачу.",
                        "ChickMark is unavailable or cannot receive notes. Update the app and retry."
                    )
                }
            }
        } catch {
            errorMessage = CaptureBrand.text(
                "Не удалось подготовить заметку. Текст должен быть не длиннее 32 КБ.",
                "Could not prepare the note. Its text must fit within 32 KB."
            )
        }
    }
}
