import XCTest
import SwiftData
@testable import HabitsByArvectum

final class ReviewNoteImportTests: XCTestCase {
    func testSourceLinkHasOnlyNonceAndRejectsSwappedPayload() throws {
        let transfer = try ReviewNoteHandoff(noteID: UUID(), kind: .audio,
            createdAt: Date().addingTimeInterval(-20), text: "Saved transcript")
        let data = try JSONEncoder().encode(transfer)
        XCTAssertEqual(ReviewNoteHandoff.nonce(from: transfer.recipientURL), transfer.nonce)
        XCTAssertEqual(try ReviewNoteHandoff.decode(data, from: transfer.recipientURL), transfer)
        XCTAssertEqual(try ReviewNoteHandoff.decodeClipboardString(
            transfer.clipboardString(), from: transfer.recipientURL), transfer)
        let other = URL(string: "chickmark-review://review-import/\(UUID().uuidString)")!
        XCTAssertThrowsError(try ReviewNoteHandoff.decode(data, from: other))
    }

    func testAttachmentRepositoryPersistsFullTextWithoutChangingLegacyModels() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("review-attachment-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let repository = ReviewNoteAttachmentRepository(rootURL: dir)
        let id = UUID()
        let transcript = String(repeating: "Текст расшифровки", count: 350)
        let transfer = try ReviewNoteHandoff(noteID: id, kind: .audio,
            createdAt: Date().addingTimeInterval(-80), text: transcript)
        let attachment = ReviewNoteAttachment(transfer)
        try repository.put(attachment)
        try repository.put(attachment) // Retry must not duplicate.
        XCTAssertEqual(try repository.all().count, 1)
        XCTAssertEqual(try ReviewNoteAttachmentRepository(rootURL: dir).get(id), attachment)
        XCTAssertEqual(try repository.get(id)?.text, transcript)
        try repository.remove(id)
        XCTAssertTrue(try repository.all().isEmpty)
    }

    @MainActor
    func testConfirmedImportCreatesOneOffAndPersistsFullTranscriptNoHabit() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("review-import-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let container = try ModelContainer(for: OneOffReminder.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let ledger = ReviewNoteAttachmentRepository(rootURL: dir)
        let transfer = try ReviewNoteHandoff(noteID: UUID(), kind: .audio,
            createdAt: Date().addingTimeInterval(-20),
            text: String(repeating: "Review text. ", count: 450))
        try ReviewNoteImportService.create(transfer: transfer,
            dueAt: Date().addingTimeInterval(3600), context: context,
            attachments: ledger)
        let oneOffs = try context.fetch(FetchDescriptor<OneOffReminder>())
        XCTAssertEqual(oneOffs.count, 1)
        XCTAssertEqual(oneOffs[0].id, transfer.noteID)
        XCTAssertFalse(oneOffs[0].isCompleted)
        XCTAssertTrue(oneOffs[0].title.hasPrefix("Разобрать заметку"))
        XCTAssertEqual(try ledger.get(transfer.noteID)?.text, transfer.text)
        XCTAssertEqual(try ledger.get(transfer.noteID)?.sourceURL, transfer.sourceURL)
        XCTAssertThrowsError(try ReviewNoteImportService.create(
            transfer: transfer, dueAt: Date().addingTimeInterval(5400),
            context: context, attachments: ledger
        ))
        XCTAssertEqual(try context.fetch(FetchDescriptor<OneOffReminder>()).count, 1)
        XCTAssertEqual(try ledger.all().count, 1)
    }

    @MainActor
    func testImportedTranscriptNeverAppearsInLockScreenNotification() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("review-private-notification-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let repository = ReviewNoteAttachmentRepository(rootURL: dir)
        let id = UUID()
        let privateText = "Very private transcription should stay in the app"
        try repository.put(ReviewNoteAttachment(try ReviewNoteHandoff(
            noteID: id, kind: .audio, createdAt: Date(), text: privateText
        )))
        let imported = OneOffReminder(id: id,
            title: "Review: \(privateText)", dueAt: Date().addingTimeInterval(3600))
        let notification = HabitReminderScheduler.oneOffNotificationContent(
            for: imported, attachmentStore: repository
        )
        XCTAssertFalse(notification.title.contains(privateText))
        XCTAssertFalse(notification.body.contains(privateText))
        XCTAssertEqual(notification.userInfo[
            OneOffReminderNotificationActions.reminderIDKey] as? String,
            id.uuidString)
        try repository.remove(id)
        let afterMissingAttachment = HabitReminderScheduler.oneOffNotificationContent(
            for: OneOffReminder(id: id,
                                title: "Разобрать заметку: \(privateText)",
                                dueAt: Date().addingTimeInterval(3600)),
            attachmentStore: repository
        )
        XCTAssertFalse(afterMissingAttachment.title.contains(privateText),
            "Backup/missing attachment must fail closed on the lock screen")
        let ordinary = OneOffReminder(title: "Ordinary title", dueAt: Date().addingTimeInterval(3600))
        XCTAssertEqual(HabitReminderScheduler.oneOffNotificationContent(
            for: ordinary, attachmentStore: repository).title, ordinary.title)
    }

    func testImportedMetadataCodableBackupCompatibility() throws {
        let transfer = try ReviewNoteHandoff(noteID: UUID(), kind: .text,
            createdAt: Date(), text: "Unique Russian punctuation: поехать в Санкт-Петербург")
        let attachment = ReviewNoteAttachment(transfer)
        let encoded = try JSONEncoder().encode([attachment])
        let decoded = try JSONDecoder().decode([ReviewNoteAttachment].self, from: encoded)
        XCTAssertEqual(decoded, [attachment])
        XCTAssertTrue(attachment.sourceURL.absoluteString.hasPrefix("whatp2aqa://note/"))
    }

    @MainActor
    func testBackupRoundTripPreservesImportedTextWithoutDuplicateOneOffs() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("review-backup-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let sourceLedger = ReviewNoteAttachmentRepository(
            rootURL: root.appendingPathComponent("source"))
        let destLedger = ReviewNoteAttachmentRepository(
            rootURL: root.appendingPathComponent("destination"))
        let schema = HabitsSchema.current
        let configuration = ModelConfiguration("SourceReview", schema: schema,
            isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let sourceContainer = try ModelContainer(for: schema,
            configurations: [configuration])
        let sourceContext = ModelContext(sourceContainer)
        let sourceNote = try ReviewNoteHandoff(
            noteID: UUID(), kind: .text, createdAt: .now,
            text: "Сохранить именно полный текст и источник")
        sourceContext.insert(OneOffReminder(
            id: sourceNote.noteID, title: "Разобрать заметку: пример",
            dueAt: .now.addingTimeInterval(7200)))
        try sourceContext.save()
        try sourceLedger.put(ReviewNoteAttachment(sourceNote))

        let encoded = try JSONEncoder().encode(ChickMarkBackupService.capture(
            from: sourceContext, attachments: sourceLedger))
        let archive = try JSONDecoder().decode(ChickMarkBackup.self, from: encoded)
        try archive.validate()
        XCTAssertEqual(archive.reviewNotes?.count, 1)
        let destinationConfiguration = ModelConfiguration("DestinationReview", schema: schema,
            isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let destinationContainer = try ModelContainer(for: schema,
            configurations: [destinationConfiguration])
        let destinationContext = ModelContext(destinationContainer)
        let existing = OneOffReminder(title: "Keep an existing task",
                                      dueAt: .now.addingTimeInterval(1800))
        destinationContext.insert(existing)
        try destinationContext.save()

        for _ in 0..<2 {
            try ChickMarkBackupService.restore(archive, to: destinationContext,
                                               mode: .merge, attachments: destLedger)
        }
        let merged = try destinationContext.fetch(FetchDescriptor<OneOffReminder>())
        XCTAssertEqual(merged.count, 2)
        XCTAssertTrue(merged.contains { $0.id == existing.id })
        XCTAssertEqual(try destLedger.all().count, 1)
        XCTAssertEqual(try destLedger.get(sourceNote.noteID)?.text, sourceNote.text)
        XCTAssertEqual(try destLedger.get(sourceNote.noteID)?.sourceURL,
                       sourceNote.sourceURL)

        try ChickMarkBackupService.restore(archive, to: destinationContext,
                                           mode: .replace, attachments: destLedger)
        XCTAssertEqual(try destinationContext.fetch(FetchDescriptor<OneOffReminder>()).count, 1)
        XCTAssertEqual(try destLedger.all().count, 1)
        XCTAssertEqual(try destLedger.get(sourceNote.noteID)?.text, sourceNote.text)

        // Old backups have no reviewNotes; replacing from one intentionally
        // drops obsolete attached text but preserves the restored one-offs.
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json.removeValue(forKey: "reviewNotes")
        let oldBackup = try JSONDecoder().decode(ChickMarkBackup.self,
            from: JSONSerialization.data(withJSONObject: json))
        try ChickMarkBackupService.restore(oldBackup, to: destinationContext,
                                           mode: .replace, attachments: destLedger)
        XCTAssertTrue(try destLedger.all().isEmpty)
        XCTAssertEqual(try destinationContext.fetch(FetchDescriptor<OneOffReminder>()).count, 1)
    }

    @MainActor
    func testInvalidReviewMetadataCannotMutateExistingBackupDestination() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("review-backup-invalid-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let ledger = ReviewNoteAttachmentRepository(rootURL: root)
        let schema = HabitsSchema.current
        let config = ModelConfiguration("InvalidReview", schema: schema,
            isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        let oldTask = OneOffReminder(title: "Untouched", dueAt: .now)
        context.insert(oldTask)
        try context.save()
        let note = try ReviewNoteHandoff(noteID: oldTask.id, kind: .audio,
                                         createdAt: .now, text: "Source")
        let data = try JSONEncoder().encode(ReviewNoteAttachment(note))
        var dictionary = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        dictionary["sourceURL"] = "https://external.invalid/leak"
        // Use the normal backup codec, then inject an invalid attachment.
        let valid = try ChickMarkBackupService.capture(from: context, attachments: ledger)
        var backupJSON = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(valid)) as? [String: Any])
        backupJSON["reviewNotes"] = [dictionary]
        let invalid = try JSONDecoder().decode(ChickMarkBackup.self,
            from: JSONSerialization.data(withJSONObject: backupJSON))
        XCTAssertThrowsError(try ChickMarkBackupService.restore(invalid, to: context,
            mode: .replace, attachments: ledger))
        XCTAssertEqual(try context.fetch(FetchDescriptor<OneOffReminder>()).map(\.id),
                       [oldTask.id])
        XCTAssertTrue(try ledger.all().isEmpty)
    }

    func testAttachmentMergePrunesDeletedAndKeepsExisting() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("review-merge-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let repository = ReviewNoteAttachmentRepository(rootURL: dir)
        let one = ReviewNoteAttachment(try ReviewNoteHandoff(
            noteID: UUID(), kind: .text, createdAt: Date(), text: "One"))
        let two = ReviewNoteAttachment(try ReviewNoteHandoff(
            noteID: UUID(), kind: .video, createdAt: Date(), text: ""))
        try repository.put(one)
        try repository.merge([one, two], keepIDs: [one.id, two.id], replace: false)
        XCTAssertEqual(try repository.all().count, 2)
        try repository.merge([two], keepIDs: [two.id], replace: true)
        XCTAssertEqual(try repository.all(), [two])
    }
}
