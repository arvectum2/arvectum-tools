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
