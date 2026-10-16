import XCTest
@testable import WhatIOS

final class LocalNoteRepositoryTests: XCTestCase {
    private func root() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("what-local-\(UUID().uuidString)")
    }

    func testTextAutosaveAndRelaunchDoesNotTouchOldAudioIndex() throws {
        let path = root()
        defer { try? FileManager.default.removeItem(at: path) }
        let repo = LocalNoteRepository(rootURL: path)
        let id = UUID()
        XCTAssertNil(try repo.saveText(id: id, body: "   "))
        XCTAssertEqual(try repo.allNotes().count, 0)
        try repo.saveText(id: id, body: "First")
        try repo.saveText(id: id, body: "Edited")
        let again = LocalNoteRepository(rootURL: path)
        XCTAssertEqual(try again.allNotes().count, 1)
        XCTAssertEqual(try again.allNotes().first?.body, "Edited")
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: path.appendingPathComponent("recordings.json").path
        ))
        try again.setArchived(id, archived: true)
        XCTAssertTrue(try repo.allNotes().first!.archived)
        try again.delete(id)
        XCTAssertTrue(try repo.allNotes().isEmpty)
    }

    func testVideoCopyAndDeletionDoesNotDeleteSource() throws {
        let path = root()
        defer { try? FileManager.default.removeItem(at: path) }
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        let source = path.appendingPathComponent("source.mov")
        try Data(repeating: 123, count: 4096).write(to: source)
        let repo = LocalNoteRepository(rootURL: path)
        let note = try repo.importVideo(from: source, duration: 4.2)
        XCTAssertEqual(note.kind, .video)
        XCTAssertEqual(try repo.allNotes().count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: repo.videoURL(for: note)!.path))
        try repo.delete(note.id)
        XCTAssertFalse(FileManager.default.fileExists(atPath: repo.videoURL(for: note)!.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
    }

    func testUnifiedInboxCombinesAndFiltersAudioTextVideo() throws {
        let now = Date()
        let audio = RecordingEnvelope(id: UUID(), createdAt: now,
                                      duration: 3, fileName: "x.m4a")
        let text = LocalNote(id: UUID(), kind: .text, createdAt: now,
                             updatedAt: now, body: "Идея проекта", fileName: nil,
                             duration: nil, archived: false, sourceDevice: "iOS")
        let video = LocalNote(id: UUID(), kind: .video, createdAt: now,
                              updatedAt: now, body: "", fileName: "v.mov",
                              duration: 3, archived: true, sourceDevice: "iOS")
        let inbox = UnifiedInbox.visible(
            recordings: [audio], localNotes: [text, video],
            archivedAudioIDs: [], folder: .inbox, query: "", transcripts: [:]
        )
        XCTAssertEqual(inbox.count, 2)
        XCTAssertEqual(UnifiedInbox.groups(inbox).first?.notes.count, 2)
        XCTAssertEqual(UnifiedInbox.visible(
            recordings: [audio], localNotes: [text, video],
            archivedAudioIDs: [], folder: .inbox, query: "проекта", transcripts: [:]
        ).map(\.id), [text.id])
        XCTAssertEqual(UnifiedInbox.visible(
            recordings: [audio], localNotes: [text, video],
            archivedAudioIDs: [], folder: .archive, query: "", transcripts: [:]
        ).map(\.id), [video.id])
    }
}
