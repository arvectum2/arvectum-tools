import XCTest
@testable import WhatIOS

/// Forces failure after deletion intent + index commit, mimicking ENOSPC,
/// file protection, or a crash before removing the UUID-named video.
private final class FailOnceVideoDeleteFileManager: FileManager {
    var failVideoDelete = true

    override func removeItem(at url: URL) throws {
        if failVideoDelete, url.pathExtension == "mov",
           url.deletingLastPathComponent().lastPathComponent == "Videos" {
            failVideoDelete = false
            throw CocoaError(.fileWriteNoPermission)
        }
        try super.removeItem(at: url)
    }
}

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

    func testPendingVideoDeletionRecoversAfterFileRemovalFails() throws {
        let path = root()
        defer { try? FileManager.default.removeItem(at: path) }
        try FileManager.default.createDirectory(at: path,
                                                withIntermediateDirectories: true)
        let source = path.appendingPathComponent("original.mov")
        try Data(repeating: 0x7f, count: 8_192).write(to: source)
        let manager = FailOnceVideoDeleteFileManager()
        let repo = LocalNoteRepository(rootURL: path, fileManager: manager)
        let note = try repo.importVideo(from: source, duration: 11)
        let video = try XCTUnwrap(repo.videoURL(for: note))
        XCTAssertThrowsError(try repo.delete(note.id))
        XCTAssertTrue(FileManager.default.fileExists(atPath: video.path))
        XCTAssertTrue(try repo.allNotes().isEmpty)
        XCTAssertFalse(try repo.hasVideo(id: note.id))
        // A recovery retry cannot resurrect an already-deleted UUID, even
        // though its original MOV has not yet been physically removed.
        XCTAssertThrowsError(try repo.importVideo(
            from: source, duration: 11, id: note.id
        ))
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        let journal = path.appendingPathComponent("pending-local-video-deletions.json")
        XCTAssertEqual(try JSONDecoder().decode(
            [String].self, from: Data(contentsOf: journal)
        ), [note.id.uuidString])

        // New process reads persisted intent, removes ONLY the UUID.mov and
        // clears the intent marker without resurrecting the note.
        let relaunched = LocalNoteRepository(rootURL: path)
        XCTAssertTrue(try relaunched.allNotes().isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: video.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertEqual(try JSONDecoder().decode(
            [String].self, from: Data(contentsOf: journal)
        ), [])
    }

    func testJournalCommitFailureDoesNotDeleteVideoOrNote() throws {
        let path = root()
        defer { try? FileManager.default.removeItem(at: path) }
        try FileManager.default.createDirectory(at: path,
                                                withIntermediateDirectories: true)
        let source = path.appendingPathComponent("source.mov")
        try Data(repeating: 0x55, count: 4_096).write(to: source)
        let repo = LocalNoteRepository(rootURL: path)
        let note = try repo.importVideo(from: source, duration: 6)
        let video = try XCTUnwrap(repo.videoURL(for: note))
        let journal = path.appendingPathComponent("pending-local-video-deletions.json")
        try FileManager.default.createDirectory(at: journal,
                                                withIntermediateDirectories: true)
        XCTAssertThrowsError(try repo.delete(note.id))
        XCTAssertTrue(FileManager.default.fileExists(atPath: video.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertThrowsError(try repo.allNotes())
        try FileManager.default.removeItem(at: journal)
        XCTAssertEqual(try repo.allNotes().map(\.id), [note.id])
    }

    func testCrashImmediatelyAfterDurableDeletionIntentRecoversOnRelaunch() throws {
        let path = root()
        defer { try? FileManager.default.removeItem(at: path) }
        try FileManager.default.createDirectory(at: path,
                                                withIntermediateDirectories: true)
        let source = path.appendingPathComponent("source.mov")
        try Data(repeating: 0x66, count: 4_096).write(to: source)
        let repo = LocalNoteRepository(rootURL: path)
        let note = try repo.importVideo(from: source, duration: 6)
        let video = try XCTUnwrap(repo.videoURL(for: note))
        let journal = path.appendingPathComponent("pending-local-video-deletions.json")

        // Simulate a power failure after the UUID intent was atomically saved,
        // but BEFORE the note index was committed. No delete() call can make
        // this interruption deterministic without terminating XCTest itself.
        try JSONEncoder().encode([note.id.uuidString]).write(
            to: journal, options: .atomic
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: video.path))
        // The old index still contains the video at the crash checkpoint.
        let rawIndex = try Data(contentsOf: path.appendingPathComponent("local-notes.json"))
        XCTAssertEqual(try JSONDecoder().decode([LocalNote].self,
            from: rawIndex).map(\.id), [note.id])

        let relaunched = LocalNoteRepository(rootURL: path)
        XCTAssertTrue(try relaunched.allNotes().isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: video.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertEqual(try JSONDecoder().decode(
            [String].self, from: Data(contentsOf: journal)
        ), [])
    }

    func testExplicitVideoDeleteNeverSweepsUnknownOrUnfinishedMOVFiles() throws {
        let path = root()
        defer { try? FileManager.default.removeItem(at: path) }
        try FileManager.default.createDirectory(at: path,
                                                withIntermediateDirectories: true)
        let source = path.appendingPathComponent("source.mov")
        try Data(repeating: 0x41, count: 512).write(to: source)
        let repo = LocalNoteRepository(rootURL: path)
        let note = try repo.importVideo(from: source, duration: 3)
        let unknown = path.appendingPathComponent("Videos/orphan-but-not-consented.mov")
        try Data(repeating: 0x42, count: 512).write(to: unknown)
        try repo.delete(note.id)
        let reloaded = LocalNoteRepository(rootURL: path)
        XCTAssertTrue(try reloaded.allNotes().isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: unknown.path))
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
