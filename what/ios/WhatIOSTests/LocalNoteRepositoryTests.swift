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

    func testUnifiedKindFiltersRespectFolderSearchAndKeepNoteIDs() throws {
        let now = Date()
        let audio = RecordingEnvelope(id: UUID(), createdAt: now.addingTimeInterval(-30),
                                      duration: 7, fileName: "watch.m4a")
        let text = LocalNote(id: UUID(), kind: .text, createdAt: now,
                             updatedAt: now, body: "Бирюзовый блокнот", fileName: nil,
                             duration: nil, archived: false, sourceDevice: "iPad")
        let video = LocalNote(id: UUID(), kind: .video,
                              createdAt: now.addingTimeInterval(-10), updatedAt: now,
                              body: "", fileName: "capture.mov", duration: 20,
                              archived: false, sourceDevice: "iPhone")
        let archivedVideo = LocalNote(id: UUID(), kind: .video,
                                      createdAt: now.addingTimeInterval(-60), updatedAt: now,
                                      body: "", fileName: "old.mov", duration: 11,
                                      archived: true, sourceDevice: "iPad")
        let inbox = UnifiedInbox.visible(
            recordings: [audio], localNotes: [text, video, archivedVideo],
            archivedAudioIDs: [], folder: .inbox, query: "", transcripts: [:]
        )
        XCTAssertEqual(UnifiedNoteKindFilter.all.count(in: inbox), 3)
        XCTAssertEqual(UnifiedNoteKindFilter.audio.notes(in: inbox).map(\.id), [audio.id])
        XCTAssertEqual(UnifiedNoteKindFilter.text.notes(in: inbox).map(\.id), [text.id])
        XCTAssertEqual(UnifiedNoteKindFilter.video.notes(in: inbox).map(\.id), [video.id])
        XCTAssertEqual(UnifiedNoteKindFilter.all.notes(in: inbox).map(\.id),
                       [text.id, video.id, audio.id])
        XCTAssertEqual(inbox.count, 3, "Filters must not mutate their input notes")

        let searching = UnifiedInbox.visible(
            recordings: [audio], localNotes: [text, video, archivedVideo],
            archivedAudioIDs: [], folder: .inbox, query: "Бирюзовый", transcripts: [:]
        )
        XCTAssertEqual(UnifiedNoteKindFilter.all.count(in: searching), 1)
        XCTAssertEqual(UnifiedNoteKindFilter.text.count(in: searching), 1)
        XCTAssertEqual(UnifiedNoteKindFilter.video.count(in: searching), 0)
        let archived = UnifiedInbox.visible(
            recordings: [audio], localNotes: [text, video, archivedVideo],
            archivedAudioIDs: [], folder: .archive, query: "", transcripts: [:]
        )
        XCTAssertEqual(UnifiedNoteKindFilter.video.notes(in: archived).map(\.id),
                       [archivedVideo.id])
        XCTAssertEqual(UnifiedNoteKindFilter.audio.count(in: archived), 0)
        XCTAssertEqual(Set(UnifiedNoteKindFilter.all.notes(in: archived).map(\.id)),
                       [archivedVideo.id])
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
