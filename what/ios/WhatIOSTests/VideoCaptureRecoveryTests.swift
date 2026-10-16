import AVFoundation
import XCTest
@testable import WhatIOS

final class VideoCaptureRecoveryTests: XCTestCase {
    private func temporaryRoot() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-recovery-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: url, withIntermediateDirectories: true
        )
        return url
    }

    private func fixture(_ name: String) throws -> URL {
        guard let url = Bundle(for: type(of: self)).url(
            forResource: name, withExtension: "mov"
        ) else {
            throw NSError(domain: "Missing video test fixture", code: 1)
        }
        return url
    }

    private func copyFixture(
        _ source: String, journal: VideoCaptureJournal,
        session: UUID, index: Int
    ) throws {
        try FileManager.default.copyItem(
            at: fixture(source),
            to: journal.segmentURL(for: session, index: index)
        )
    }

    func testLaunchRecoverySkipsAVFoundationSessionStillWriting() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let journal = VideoCaptureJournal(
            rootURL: root.appendingPathComponent("VideoCaptures")
        )
        let repository = LocalNoteRepository(rootURL: root.appendingPathComponent("What"))
        let id = try journal.begin()
        try copyFixture("back", journal: journal, session: id, index: 0)
        VideoCaptureJournal.setActive(id, active: true)
        defer { VideoCaptureJournal.setActive(id, active: false) }

        XCTAssertTrue(try journal.pendingSessions().isEmpty)
        let result = try await VideoCaptureRecovery.recover(
            journal: journal, repository: repository
        )
        XCTAssertEqual(result.recovered, 0)
        XCTAssertTrue(try repository.allNotes().isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: journal.segmentURL(for: id, index: 0).path
        ))
    }

    func testCrashAfterFirstClipRestoresNoteAndRemovesCommittedOriginals() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let journal = VideoCaptureJournal(rootURL: root.appendingPathComponent("VideoCaptures"))
        let repository = LocalNoteRepository(rootURL: root.appendingPathComponent("What"))
        let id = try journal.begin()
        try copyFixture("back", journal: journal, session: id, index: 0)

        let result = try await VideoCaptureRecovery.recover(
            journal: journal, repository: repository
        )
        XCTAssertEqual(result.recovered, 1)
        XCTAssertEqual(result.unresolved, 0)
        let note = try XCTUnwrap(repository.allNotes().first)
        XCTAssertEqual(note.id, id)
        XCTAssertEqual(note.kind, .video)
        XCTAssertNotNil(repository.videoURL(for: note))
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: repository.videoURL(for: note)!.path
        ))
        XCTAssertTrue(try journal.pendingSessions().isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: journal.segmentURL(for: id, index: 0).path
        ))
    }

    func testCrashAfterCameraFlipRestoresOneCombinedNote() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let journal = VideoCaptureJournal(rootURL: root.appendingPathComponent("VideoCaptures"))
        let repository = LocalNoteRepository(rootURL: root.appendingPathComponent("What"))
        let id = try journal.begin()
        try copyFixture("back", journal: journal, session: id, index: 0)
        try copyFixture("front", journal: journal, session: id, index: 1)

        let result = try await VideoCaptureRecovery.recover(
            journal: journal, repository: repository
        )
        XCTAssertEqual(result.recovered, 1)
        let note = try XCTUnwrap(repository.allNotes().first)
        let output = try XCTUnwrap(repository.videoURL(for: note))
        let movie = AVURLAsset(url: output)
        let duration = try await movie.load(.duration).seconds
        let audio = try await movie.loadTracks(withMediaType: .audio)
        XCTAssertGreaterThan(duration, 1.3)
        XCTAssertLessThan(duration, 2.1)
        XCTAssertFalse(audio.isEmpty)
        XCTAssertTrue(try journal.pendingSessions().isEmpty)
    }

    func testCrashAfterRepositoryCommitDoesNotDuplicateNote() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let journal = VideoCaptureJournal(rootURL: root.appendingPathComponent("VideoCaptures"))
        let repository = LocalNoteRepository(rootURL: root.appendingPathComponent("What"))
        let id = try journal.begin()
        let clip = journal.segmentURL(for: id, index: 0)
        try FileManager.default.copyItem(at: fixture("back"), to: clip)
        try repository.importVideo(from: clip, duration: 0.8, id: id)
        XCTAssertEqual(try repository.allNotes().count, 1)

        let result = try await VideoCaptureRecovery.recover(
            journal: journal, repository: repository
        )
        XCTAssertEqual(result.recovered, 0)
        XCTAssertEqual(result.unresolved, 0)
        XCTAssertEqual(try repository.allNotes().count, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: clip.path))
    }

    func testDamagedClipNeverDeletesOriginalAndSalvagesGoodClip() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let journal = VideoCaptureJournal(rootURL: root.appendingPathComponent("VideoCaptures"))
        let repository = LocalNoteRepository(rootURL: root.appendingPathComponent("What"))
        let id = try journal.begin()
        try copyFixture("back", journal: journal, session: id, index: 0)
        let broken = journal.segmentURL(for: id, index: 1)
        try Data("truncated".utf8).write(to: broken)

        let first = try await VideoCaptureRecovery.recover(
            journal: journal, repository: repository
        )
        XCTAssertEqual(first.recovered, 1)
        XCTAssertEqual(first.unresolved, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: broken.path))
        XCTAssertEqual(try repository.allNotes().count, 1)

        let second = try await VideoCaptureRecovery.recover(
            journal: journal, repository: repository
        )
        XCTAssertEqual(second.recovered, 0)
        XCTAssertEqual(second.unresolved, 1)
        XCTAssertEqual(try repository.allNotes().count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: broken.path))
    }

    func testOnlyTruncatedMediaIsRetainedWithoutImport() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let journal = VideoCaptureJournal(rootURL: root.appendingPathComponent("VideoCaptures"))
        let repository = LocalNoteRepository(rootURL: root.appendingPathComponent("What"))
        let id = try journal.begin()
        let bad = journal.segmentURL(for: id, index: 0)
        try Data([0, 1, 2]).write(to: bad)

        let result = try await VideoCaptureRecovery.recover(
            journal: journal, repository: repository
        )
        XCTAssertEqual(result.recovered, 0)
        XCTAssertEqual(result.unresolved, 1)
        XCTAssertTrue(try repository.allNotes().isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: bad.path))
    }

    func testDiscardedCaptureNeverReappearsEvenIfCleanupWasInterrupted() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let journal = VideoCaptureJournal(rootURL: root.appendingPathComponent("VideoCaptures"))
        let repository = LocalNoteRepository(rootURL: root.appendingPathComponent("What"))
        let id = try journal.begin()
        try copyFixture("back", journal: journal, session: id, index: 0)
        try journal.markDiscarded(id)

        XCTAssertTrue(try journal.pendingSessions().isEmpty)
        let result = try await VideoCaptureRecovery.recover(
            journal: journal, repository: repository
        )
        XCTAssertEqual(result.recovered, 0)
        XCTAssertTrue(try repository.allNotes().isEmpty)
    }

    func testRecoveryNeverMutatesLegacyAudioIndex() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let legacy = root.appendingPathComponent("What/recordings.json")
        try FileManager.default.createDirectory(
            at: legacy.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let bytes = Data("[{\"legacy\":\"untouched\"}]".utf8)
        try bytes.write(to: legacy)

        let journal = VideoCaptureJournal(rootURL: root.appendingPathComponent("VideoCaptures"))
        let repository = LocalNoteRepository(rootURL: root.appendingPathComponent("What"))
        let id = try journal.begin()
        try copyFixture("front", journal: journal, session: id, index: 0)
        let result = try await VideoCaptureRecovery.recover(
            journal: journal, repository: repository
        )
        XCTAssertEqual(result.recovered, 1)
        XCTAssertEqual(try Data(contentsOf: legacy), bytes)
    }

    func testRepairMissingAlreadyIndexedVideoWithoutCreatingDuplicate() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = LocalNoteRepository(rootURL: root.appendingPathComponent("What"))
        let source = try fixture("back")
        let id = UUID()
        let initial = try repository.importVideo(
            from: source, duration: 0.8, id: id
        )
        let target = try XCTUnwrap(repository.videoURL(for: initial))
        try FileManager.default.removeItem(at: target)
        XCTAssertFalse(try repository.hasVideo(id: id))

        let repaired = try repository.importVideo(
            from: source, duration: 0.8, id: id
        )
        XCTAssertEqual(repaired.id, id)
        XCTAssertEqual(try repository.allNotes().count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: target.path))
    }
}
