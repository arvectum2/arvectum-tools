import Foundation
import SwiftUI
import SwiftData
import UIKit

/// Separate, local-only metadata for imported notes. OneOffReminder remains
/// unchanged; no new SwiftData schema or migration of existing habits.
struct ReviewNoteAttachment: Codable, Equatable, Identifiable {
    let id: UUID             // Equal to source note UUID and OneOffReminder ID.
    let kind: ReviewNoteHandoff.Kind
    let createdAt: Date
    let text: String         // Complete note/transcription, never a push body.
    let sourceURL: URL       // uhwhat://note/<same-uuid>, local deep link.

    init(_ transfer: ReviewNoteHandoff) {
        id = transfer.noteID
        kind = transfer.kind
        createdAt = transfer.createdAt
        text = transfer.text
        sourceURL = transfer.sourceURL
    }
}

final class ReviewNoteAttachmentRepository {
    private let url: URL
    private let lock = NSLock()
    init(rootURL: URL? = nil) {
        let root = rootURL ?? FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!.appendingPathComponent("ChickMark", isDirectory: true)
        url = root.appendingPathComponent("note-review-attachments.json")
    }

    func all() throws -> [ReviewNoteAttachment] {
        lock.lock()
        defer { lock.unlock() }
        return try read()
    }

    func get(_ id: UUID) throws -> ReviewNoteAttachment? {
        try all().first { $0.id == id }
    }

    func put(_ item: ReviewNoteAttachment) throws {
        lock.lock()
        defer { lock.unlock() }
        var values = try read()
        values.removeAll { $0.id == item.id }
        values.append(item)
        try write(values)
    }

    func remove(_ id: UUID) throws {
        lock.lock()
        defer { lock.unlock() }
        try write(read().filter { $0.id != id })
    }

    func merge(_ items: [ReviewNoteAttachment], keepIDs: Set<UUID>,
               replace: Bool) throws {
        lock.lock()
        defer { lock.unlock() }
        var values = replace ? [] : try read().filter { keepIDs.contains($0.id) }
        for item in items where keepIDs.contains(item.id) {
            if !values.contains(where: { $0.id == item.id }) { values.append(item) }
        }
        try write(values)
    }

    private func read() throws -> [ReviewNoteAttachment] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        return try JSONDecoder().decode([ReviewNoteAttachment].self,
                                        from: Data(contentsOf: url))
    }

    private func write(_ items: [ReviewNoteAttachment]) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try JSONEncoder().encode(items).write(to: url, options: .atomic)
    }
}

/// Confirmation has already been given by the user. Keeps SwiftData one-off
/// insertion and the independent attachment ledger covered by unit tests.
@MainActor
enum ReviewNoteImportService {
    enum ImportError: Error { case duplicate, invalidDueDate }

    static func create(transfer: ReviewNoteHandoff, dueAt: Date,
                       context: ModelContext,
                       attachments: ReviewNoteAttachmentRepository) throws {
        try transfer.validate()
        guard dueAt > Date() else { throw ImportError.invalidDueDate }
        guard !(try context.fetch(FetchDescriptor<OneOffReminder>())
                    .contains { $0.id == transfer.noteID }) else {
            throw ImportError.duplicate
        }
        let firstLine = transfer.text.split(separator: "\n", maxSplits: 1)
            .first.map(String.init)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let heading = firstLine.isEmpty ? "Видео" : String(firstLine.prefix(84))
        let title = "Разобрать заметку: \(heading)"
        try attachments.put(ReviewNoteAttachment(transfer))
        do {
            context.insert(OneOffReminder(id: transfer.noteID,
                                          title: title, dueAt: dueAt))
            try context.save()
        } catch {
            context.rollback()
            try? attachments.remove(transfer.noteID)
            throw error
        }
    }
}

struct ReviewNotePasteRequest: Identifiable {
    let id = UUID()
    let url: URL
}

/// System PasteButton grants user-approved paste. No automatic cross-app
/// pasteboard read occurs during app launch or custom URL delivery.
struct ReviewNotePasteSheet: View {
    @Environment(\.dismiss) private var dismiss
    let request: ReviewNotePasteRequest
    let onReceived: (ReviewNoteHandoff) -> Void
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "doc.on.clipboard")
                    .font(.largeTitle)
                Text("Заметка из Ухвата")
                    .font(.title2.weight(.semibold))
                Text("Нажмите системную кнопку «Вставить», чтобы разрешить ChickMark прочитать только что переданную заметку. Ещё одно подтверждение потребуется перед созданием разового напоминания.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                PasteButton(payloadType: String.self) { strings in
                    guard let raw = strings.first,
                          let payload = try? ReviewNoteHandoff.decodeClipboardString(
                              raw, from: request.url
                          ) else {
                        errorMessage = "Буфер обмена изменился или ссылка истекла. Повторите передачу из Ухвата."
                        return
                    }
                    onReceived(payload)
                }
                .accessibilityLabel("Вставить заметку")
                .accessibilityIdentifier("chickmark.noteReview.paste")
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Получить заметку")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            .alert("Не удалось вставить заметку", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
}

/// One physical sheet for every stage of the local note import. Swapping
/// the content avoids presenting a second sheet while the first dismisses,
/// which caused intermittent failures on repeated iOS 27 handoffs.
struct ReviewNoteTransferFlowSheet: View {
    let request: ReviewNotePasteRequest
    let afterSave: () -> Void
    @State private var received: ReviewNoteHandoff?

    var body: some View {
        Group {
            if let received {
                ImportedReviewNoteSheet(transfer: received, afterSave: afterSave)
            } else {
                ReviewNotePasteSheet(request: request) { payload in
                    received = payload
                }
            }
        }
    }
}

struct ImportedReviewNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let transfer: ReviewNoteHandoff
    let afterSave: () -> Void
    @State private var dueAt = Date().addingTimeInterval(7200)
    @State private var saving = false
    @State private var error: String?
    @State private var duplicate = false

    var body: some View {
        NavigationStack {
            Form {
                if duplicate {
                    Section {
                        Label("Заметка уже передана", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                        Text("Для этой заметки уже существует разовая задача. Повторно создавать её не нужно.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityIdentifier("chickmark.noteReview.duplicate")
                }
                Section("Из Ухвата") {
                    Label(transfer.kind == .audio ? "Голосовая заметка" :
                          transfer.kind == .text ? "Текстовая заметка" : "Видеозаметка",
                          systemImage: "arrow.right.circle")
                    Text(transfer.createdAt, format: .dateTime.day().month().year().hour().minute())
                        .font(.caption).foregroundStyle(.secondary)
                    if !transfer.text.isEmpty {
                        Text(transfer.text)
                            .font(.body)
                            .textSelection(.enabled)
                    } else {
                        Text("Без текста. Оригинал остаётся в Ухвате.")
                            .foregroundStyle(.secondary)
                    }
                    Link("Открыть оригинал", destination: transfer.sourceURL)
                }
                Section("Напомнить") {
                    DatePicker("Когда вернуться", selection: $dueAt,
                               in: Date()..., displayedComponents: [.date, .hourAndMinute])
                }
                Section {
                    Text("Разовая задача, не привычка. Текст будет сохранён только в ChickMark после подтверждения. Уведомление не содержит расшифровку.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Добавить из Ухвата")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") { Task { await save() } }
                        .disabled(saving || dueAt <= Date() || duplicate)
                        .accessibilityIdentifier("chickmark.noteReview.confirm")
                }
            }
            .alert("Не удалось добавить", isPresented: Binding(
                get: { error != nil }, set: { if !$0 { error = nil } }
            )) {
                Button("OK") {}
            } message: {
                Text(error ?? "")
            }
            .onAppear { verifyNotAlreadyImported() }
        }
    }

    private func verifyNotAlreadyImported() {
        do {
            let existing = try modelContext.fetch(FetchDescriptor<OneOffReminder>())
            duplicate = existing.contains { $0.id == transfer.noteID }
        } catch { self.error = error.localizedDescription }
    }

    private func save() async {
        guard !saving, dueAt > Date() else { return }
        saving = true
        defer { saving = false }
        guard await HabitReminderScheduler.ensureAuthorization() else {
            error = "Разрешите уведомления ChickMark в настройках, чтобы создать напоминание."
            return
        }
        do {
            try ReviewNoteImportService.create(
                transfer: transfer, dueAt: dueAt, context: modelContext,
                attachments: ReviewNoteAttachmentRepository()
            )
            HabitReminderCoordinator.shared.dataDidChange()
            afterSave()
            dismiss()
        } catch ReviewNoteImportService.ImportError.duplicate {
            duplicate = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct ReviewNoteAttachmentSheet: View {
    let attachment: ReviewNoteAttachment
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(attachment.createdAt,
                         format: .dateTime.day().month().year().hour().minute())
                        .font(.caption).foregroundStyle(.secondary)
                    if !attachment.text.isEmpty {
                        Text(attachment.text).textSelection(.enabled)
                    } else {
                        Text("Транскрипции нет; откройте оригинал в Ухвате.")
                    }
                    Link("Открыть оригинал в Ухвате", destination: attachment.sourceURL)
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Заметка из Ухвата")
        }
    }
}
