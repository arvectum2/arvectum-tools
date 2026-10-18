import AVFoundation
import XCTest
@testable import WhatIOS

/// Deterministic simulated ENOSPC. No real simulator or iPhone storage is filled.
private final class SimulatedOutOfSpaceFileManager: FileManager {
    override func copyItem(at srcURL: URL, to dstURL: URL) throws {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteOutOfSpaceError,
                      userInfo: [NSLocalizedDescriptionKey: "Simulated disk full during media import"])
    }
}

/// Simulates a copy that leaves a partially written destination on ENOSPC.
private final class PartialCopyOutOfSpaceFileManager: FileManager {
    override func copyItem(at srcURL: URL, to dstURL: URL) throws {
        try Data([0, 1, 2, 3]).write(to: dstURL)
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteOutOfSpaceError,
                      userInfo: [NSLocalizedDescriptionKey: "Simulated partial ENOSPC copy"])
    }
}

final class VideoCaptureRecoveryTests: XCTestCase {
    func testSimulatedDiskFullPreservesOriginalAndRetryRecoversExactlyOnce() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let journal = VideoCaptureJournal(rootURL: root.appendingPathComponent("VideoCaptures"))
        let id = try journal.begin()
        try copyFixture("back", journal: journal, session: id, index: 0)
        let original = journal.segmentURL(for: id, index: 0)
        let beforeBytes = try Data(contentsOf: original)
        let notesRoot = root.appendingPathComponent("What")

        // The original segment is never imported or deleted on an ENOSPC copy.
        let failingRepository = LocalNoteRepository(
            rootURL: notesRoot, fileManager: SimulatedOutOfSpaceFileManager()
        )
        let failure = try await VideoCaptureRecovery.recover(
            journal: journal, repository: failingRepository
        )
        XCTAssertEqual(failure.recovered, 0)
        XCTAssertEqual(failure.unresolved, 1)
        XCTAssertTrue(try failingRepository.allNotes().isEmpty)
        XCTAssertEqual(try Data(contentsOf: original), beforeBytes)
        XCTAssertEqual(try journal.pendingSessions().count, 1)

        // The retry must use the same UUID and add exactly one note.
        let healthyRepository = LocalNoteRepository(rootURL: notesRoot)
        let retried = try await VideoCaptureRecovery.recover(
            journal: journal, repository: healthyRepository
        )
        XCTAssertEqual(retried.recovered, 1)
        XCTAssertEqual(retried.unresolved, 0)
        XCTAssertEqual(try healthyRepository.allNotes().map(\.id), [id])
        let onceMore = try await VideoCaptureRecovery.recover(
            journal: journal, repository: healthyRepository
        )
        XCTAssertEqual(onceMore.recovered, 0)
        XCTAssertEqual(try healthyRepository.allNotes().count, 1)
        XCTAssertTrue(try journal.pendingSessions().isEmpty)
        let saved = try XCTUnwrap(healthyRepository.allNotes().first)
        let url = try XCTUnwrap(healthyRepository.videoURL(for: saved))
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }
    func testPartialENOSPCImportRemovesStagingAndRetriesWithSameUUID() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let journal = VideoCaptureJournal(rootURL: root.appendingPathComponent("VideoCaptures"))
        let id = try journal.begin()
        try copyFixture("back", journal: journal, session: id, index: 0)
        let original = journal.segmentURL(for: id, index: 0)
        let originalBytes = try Data(contentsOf: original)
        let notesRoot = root.appendingPathComponent("What")
        let partialRepository = LocalNoteRepository(
            rootURL: notesRoot, fileManager: PartialCopyOutOfSpaceFileManager()
        )
        let failed = try await VideoCaptureRecovery.recover(
            journal: journal, repository: partialRepository
        )
        XCTAssertEqual(failed.recovered, 0)
        XCTAssertEqual(failed.unresolved, 1)
        let incoming = notesRoot.appendingPathComponent(
            "Videos/.\(id.uuidString).mov.incoming"
        )
        XCTAssertFalse(FileManager.default.fileExists(atPath: incoming.path),
                       "Failed copy must clean its partial target")
        XCTAssertEqual(try Data(contentsOf: original), originalBytes)
        XCTAssertTrue(try partialRepository.allNotes().isEmpty)

        // Also handle an orphan left by an older app version before upgrade.
        try Data([9, 9]).write(to: incoming)
        let healthy = LocalNoteRepository(rootURL: notesRoot)
        let recovered = try await VideoCaptureRecovery.recover(
            journal: journal, repository: healthy
        )
        XCTAssertEqual(recovered.recovered, 1)
        XCTAssertEqual(recovered.unresolved, 0)
        XCTAssertEqual(try healthy.allNotes().map(\.id), [id])
        XCTAssertFalse(FileManager.default.fileExists(atPath: incoming.path))
        XCTAssertTrue(try journal.pendingSessions().isEmpty)
    }

    func testPartialENOSPCRepairDoesNotBlockSubsequentRepair() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let notesRoot = root.appendingPathComponent("What")
        let original = LocalNoteRepository(rootURL: notesRoot)
        let id = UUID()
        let source = try fixture("back")
        let first = try original.importVideo(from: source, duration: 0.8, id: id)
        let media = try XCTUnwrap(original.videoURL(for: first))
        try FileManager.default.removeItem(at: media)
        XCTAssertFalse(try original.hasVideo(id: id))
        let failing = LocalNoteRepository(
            rootURL: notesRoot, fileManager: PartialCopyOutOfSpaceFileManager()
        )
        XCTAssertThrowsError(try failing.importVideo(from: source, duration: 0.8, id: id))
        let repair = notesRoot.appendingPathComponent("Videos/.\(id.uuidString).repair")
        XCTAssertFalse(FileManager.default.fileExists(atPath: repair.path))
        XCTAssertEqual(try original.allNotes().map(\.id), [id])
        XCTAssertFalse(FileManager.default.fileExists(atPath: media.path))
        try Data([8, 8]).write(to: repair) // orphan left from an older version
        let fixed = try original.importVideo(from: source, duration: 0.8, id: id)
        XCTAssertEqual(fixed.id, id)
        XCTAssertEqual(try original.allNotes().count, 1)
        XCTAssertTrue(try original.hasVideo(id: id))
        XCTAssertFalse(FileManager.default.fileExists(atPath: repair.path))
    }

    func testCrashBeforeFirstSegmentReportsUnresolvedWithoutInventingNote() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let journal = VideoCaptureJournal(rootURL: root.appendingPathComponent("VideoCaptures"))
        let repository = LocalNoteRepository(rootURL: root.appendingPathComponent("What"))
        let id = try journal.begin()
        let manifest = root.appendingPathComponent(
            "VideoCaptures/\(id.uuidString)/session.json"
        )
        let originalManifest = try Data(contentsOf: manifest)
        XCTAssertEqual(try journal.pendingSessions().map(\.id), [id])
        let first = try await VideoCaptureRecovery.recover(
            journal: journal, repository: repository
        )
        XCTAssertEqual(first.recovered, 0)
        XCTAssertEqual(first.unresolved, 1)
        XCTAssertTrue(try repository.allNotes().isEmpty)
        XCTAssertEqual(try Data(contentsOf: manifest), originalManifest)
        // Next-launch retry must stay idempotent and show the warning.
        let again = try await VideoCaptureRecovery.recover(
            journal: journal, repository: repository
        )
        XCTAssertEqual(again.unresolved, 1)
        XCTAssertTrue(try repository.allNotes().isEmpty)

        // The same manifest can recover when a finalized clip later appears.
        try copyFixture("front", journal: journal, session: id, index: 0)
        let recovered = try await VideoCaptureRecovery.recover(
            journal: journal, repository: repository
        )
        XCTAssertEqual(recovered.recovered, 1)
        XCTAssertEqual(recovered.unresolved, 0)
        XCTAssertEqual(try repository.allNotes().map(\.id), [id])
        XCTAssertTrue(try journal.pendingSessions().isEmpty)
    }

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
