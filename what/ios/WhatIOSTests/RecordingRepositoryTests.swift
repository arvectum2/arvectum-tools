import XCTest
import AVFoundation
@testable import WhatIOS

final class RecordingRepositoryTests: XCTestCase {
    func testSharedJSONCodecIsWireCompatibleWithFoundation() throws {
        let recording = RecordingEnvelope(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            duration: 5.5,
            fileName: "test.m4a"
        )
        let existing = try JSONEncoder().encode([recording])
        let shared = try ArvectumJSONCodec.encode([recording])
        XCTAssertEqual(
            try JSONSerialization.jsonObject(with: shared) as? NSArray,
            try JSONSerialization.jsonObject(with: existing) as? NSArray
        )
        let recovered = try ArvectumJSONCodec.decode([RecordingEnvelope].self, from: existing)
        XCTAssertEqual(recovered.count, 1)
        XCTAssertEqual(recovered[0].id, recording.id)
    }

    func testTranscriptPersisted() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let id = UUID()
        try RecordingRepository(rootURL: root).saveTranscript("Test transcript", for: id)
        XCTAssertEqual(RecordingRepository(rootURL: root).transcripts()[id], "Test transcript")
    }

    /// Disposable directories and synthetic bytes only, never the real app's
    /// Application Support or personal Watch transfers.
    private func makeEditableRecording(
        in root: URL, id: UUID = UUID()
    ) throws -> (RecordingRepository, RecordingEnvelope, Data) {
        let repo = RecordingRepository(rootURL: root)
        let source = root.appendingPathComponent("qa-source.m4a")
        let audio = Data("immutable-audio-\(id.uuidString)".utf8)
        try audio.write(to: source)
        let outcome = try repo.acceptTemporaryFile(source, metadata: [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: 1_700_000_000.0,
            TransferMetadataKey.duration: 3.0
        ])
        guard case .stored(let recording) = outcome else {
            throw RecordingRepository.RepositoryError.invalidMetadata
        }
        return (repo, recording, audio)
    }

    func testManualTranscriptEditPersistsAndKeepsOtherNotesAndAudioUnchanged() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-manual-persist-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, first, originalAudio) = try makeEditableRecording(in: root)
        let (_, second, _) = try makeEditableRecording(in: root)
        try repo.saveTranscript("first original", for: first.id)
        try repo.saveTranscript("second must remain", for: second.id)

        try repo.updateTranscript("first corrected", for: first.id)
        let relaunched = RecordingRepository(rootURL: root)
        XCTAssertEqual(relaunched.transcripts()[first.id], "first corrected")
        XCTAssertEqual(relaunched.transcripts()[second.id], "second must remain")
        XCTAssertEqual(try Data(contentsOf: relaunched.audioURL(for: first)),
                       originalAudio)
        XCTAssertEqual(Set(relaunched.allRecordings().map(\.id)),
                       Set([first.id, second.id]))
    }

    func testManualTranscriptRejectsBlankMissingAndDeletedNotes() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-manual-reject-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, recording, audio) = try makeEditableRecording(in: root)
        try repo.saveTranscript("keep me", for: recording.id)

        XCTAssertThrowsError(try repo.updateTranscript("  \n ", for: recording.id)) {
            XCTAssertEqual($0 as? RecordingRepository.RepositoryError,
                           .emptyTranscript)
        }
        XCTAssertThrowsError(try repo.updateTranscript("missing", for: UUID())) {
            XCTAssertEqual($0 as? RecordingRepository.RepositoryError,
                           .recordingUnavailable)
        }
        XCTAssertEqual(repo.transcripts()[recording.id], "keep me")
        XCTAssertEqual(try Data(contentsOf: repo.audioURL(for: recording)), audio)

        try repo.deleteRecording(recording.id)
        XCTAssertThrowsError(try repo.updateTranscript("resurrect", for: recording.id)) {
            XCTAssertEqual($0 as? RecordingRepository.RepositoryError,
                           .recordingUnavailable)
        }
        XCTAssertNil(RecordingRepository(rootURL: root).transcripts()[recording.id])
    }

    func testCorruptTranscriptCatalogFailsClosedAndPreservesOriginalBytes() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-corrupt-catalog-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, recording, audio) = try makeEditableRecording(in: root)
        try repo.saveTranscript("previous", for: recording.id)
        let catalog = root.appendingPathComponent("transcripts.json")
        let corrupted = Data("{broken-json: private transcripts".utf8)
        try corrupted.write(to: catalog)

        XCTAssertThrowsError(try repo.updateTranscript("must not overwrite", for: recording.id)) {
            XCTAssertEqual($0 as? RecordingRepository.RepositoryError,
                           .transcriptStoreUnreadable)
        }
        // The automatic speech path must also refuse to replace corrupt JSON.
        XCTAssertThrowsError(try repo.saveTranscript("late recognition", for: recording.id)) {
            XCTAssertEqual($0 as? RecordingRepository.RepositoryError,
                           .transcriptStoreUnreadable)
        }
        XCTAssertEqual(try Data(contentsOf: catalog), corrupted)
        XCTAssertEqual(try Data(contentsOf: repo.audioURL(for: recording)), audio)
        XCTAssertEqual(repo.allRecordings().map(\.id), [recording.id])
    }

    func testRepairingCorruptCatalogRestoresSafeEditingWithoutDataLoss() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-catalog-repair-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, first, originalAudio) = try makeEditableRecording(in: root)
        let (_, second, _) = try makeEditableRecording(in: root)
        try repo.saveTranscript("first original", for: first.id)
        try repo.saveTranscript("second private transcript", for: second.id)
        let catalog = root.appendingPathComponent("transcripts.json")
        let originalCatalog = try Data(contentsOf: catalog)
        let brokenCatalog = Data("{invalid".utf8)
        try brokenCatalog.write(to: catalog)

        XCTAssertThrowsError(try repo.updateTranscript("unsafe", for: first.id)) {
            XCTAssertEqual($0 as? RecordingRepository.RepositoryError,
                           .transcriptStoreUnreadable)
        }
        XCTAssertEqual(try Data(contentsOf: catalog), brokenCatalog)

        // Simulate restoring a known-good local backup. No auto-repair may
        // silently discard unknown records during a normal edit.
        try originalCatalog.write(to: catalog, options: .atomic)
        try repo.updateTranscript("first corrected after repair", for: first.id)
        let reopened = RecordingRepository(rootURL: root)
        XCTAssertEqual(reopened.transcripts()[first.id], "first corrected after repair")
        XCTAssertEqual(reopened.transcripts()[second.id], "second private transcript")
        XCTAssertEqual(try Data(contentsOf: reopened.audioURL(for: first)),
                       originalAudio)
    }

    func testUnreadableTranscriptDirectoryIsNotReplacedWithEmptyJSON() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-unreadable-catalog-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, recording, audio) = try makeEditableRecording(in: root)
        let catalog = root.appendingPathComponent("transcripts.json")
        try FileManager.default.createDirectory(at: catalog,
                                                withIntermediateDirectories: false)
        XCTAssertThrowsError(try repo.updateTranscript("do not write", for: recording.id)) {
            XCTAssertEqual($0 as? RecordingRepository.RepositoryError,
                           .transcriptStoreUnreadable)
        }
        XCTAssertTrue(try catalog.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true)
        XCTAssertEqual(try Data(contentsOf: repo.audioURL(for: recording)), audio)
    }

    private func assertPhysicalFileProtection(_ url: URL) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
#if targetEnvironment(simulator)
        // iOS Simulator does not expose NSFileProtectionKey. Do NOT infer
        // successful encryption at rest from an ordinary Simulator read.
        guard attributes[.protectionKey] != nil else {
            throw XCTSkip("NSFileProtectionKey requires a physical iPhone; Simulator omits it")
        }
#endif
        XCTAssertEqual(attributes[.protectionKey] as? FileProtectionType,
                       .completeUntilFirstUserAuthentication,
                       "The real device must report protected file metadata")
    }

    func testLegacyTranscriptAndDeletionFilesAreProtectedOnRepositoryOpen() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-protect-legacy-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let legacy: [String: Data] = [
            "transcripts.json": Data(#"{"old-id":"legacy text"}"#.utf8),
            "transcripts.backup.json": Data(#"{"old-id":"legacy text"}"#.utf8),
            "deleted-recordings.json": Data("[]".utf8)
        ]
        for (name, bytes) in legacy {
            try bytes.write(to: root.appendingPathComponent(name), options: .atomic)
        }
        let repo = RecordingRepository(rootURL: root)
        for (name, bytes) in legacy {
            let url = root.appendingPathComponent(name)
            XCTAssertEqual(try Data(contentsOf: url), bytes,
                           "File protection migration must not rewrite private data")
            try assertPhysicalFileProtection(url)
        }
        XCTAssertEqual(repo.transcripts().count, 0,
                       "Invalid synthetic UUID keys should not be displayed")
    }

    func testTranscriptAndBackupUseDeviceFileProtection() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-file-protection-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, recording, audio) = try makeEditableRecording(in: root)
        try repo.saveTranscript("private first", for: recording.id)
        try repo.updateTranscript("private edited", for: recording.id)
        for name in ["transcripts.json", "transcripts.backup.json"] {
            let url = root.appendingPathComponent(name)
            try assertPhysicalFileProtection(url)
        }
        XCTAssertEqual(try Data(contentsOf: repo.audioURL(for: recording)), audio)
    }

    func testDeletionMarkerUsesSameDeviceProtection() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-protected-deletion-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, recording, _) = try makeEditableRecording(in: root)
        try repo.saveTranscript("private to delete", for: recording.id)
        try repo.deleteRecording(recording.id)
        let marker = root.appendingPathComponent("deleted-recordings.json")
        try assertPhysicalFileProtection(marker)
    }

    /// These tests simulate a process interruption by throwing exactly at
    /// a storage checkpoint. They do not claim physical power-loss testing.
    private enum SyntheticWriteStop: Error {
        case interrupted
    }

    func testInterruptedBeforeShadowCommitKeepsOldCatalogAndAudio() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-stop-before-backup-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, first, audio) = try makeEditableRecording(in: root)
        let (_, second, _) = try makeEditableRecording(in: root)
        try repo.saveTranscript("first committed", for: first.id)
        try repo.saveTranscript("second committed", for: second.id)
        let primary = root.appendingPathComponent("transcripts.json")
        let shadow = root.appendingPathComponent("transcripts.backup.json")
        let originalPrimary = try Data(contentsOf: primary)
        let originalShadow = try Data(contentsOf: shadow)

        repo.testTranscriptWriteCheckpoint = { checkpoint in
            if case .beforeBackup = checkpoint {
                throw SyntheticWriteStop.interrupted
            }
        }
        XCTAssertThrowsError(try repo.updateTranscript("failed change", for: first.id))
        XCTAssertEqual(try Data(contentsOf: primary), originalPrimary)
        XCTAssertEqual(try Data(contentsOf: shadow), originalShadow)
        let reopened = RecordingRepository(rootURL: root)
        XCTAssertEqual(reopened.transcripts()[first.id], "first committed")
        XCTAssertEqual(reopened.transcripts()[second.id], "second committed")
        XCTAssertEqual(try Data(contentsOf: reopened.audioURL(for: first)), audio)
    }

    func testInterruptedAfterShadowCommitKeepsPrimaryReadableAndReconcilesNextWrite() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-stop-after-backup-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, first, audio) = try makeEditableRecording(in: root)
        let (_, second, _) = try makeEditableRecording(in: root)
        try repo.saveTranscript("first committed", for: first.id)
        try repo.saveTranscript("second committed", for: second.id)
        let primary = root.appendingPathComponent("transcripts.json")
        let shadow = root.appendingPathComponent("transcripts.backup.json")
        let committedBytes = try Data(contentsOf: primary)

        repo.testTranscriptWriteCheckpoint = { checkpoint in
            if case .afterBackup = checkpoint {
                throw SyntheticWriteStop.interrupted
            }
        }
        XCTAssertThrowsError(try repo.updateTranscript("pending uncommitted edit", for: first.id))
        XCTAssertEqual(try Data(contentsOf: primary), committedBytes)
        let shadowAfterStop = try ArvectumJSONCodec.decode(
            [String: String].self, from: Data(contentsOf: shadow)
        )
        XCTAssertEqual(shadowAfterStop[first.id.uuidString], "pending uncommitted edit")
        XCTAssertEqual(shadowAfterStop[second.id.uuidString], "second committed")

        let relaunched = RecordingRepository(rootURL: root)
        XCTAssertEqual(relaunched.transcripts()[first.id], "first committed")
        XCTAssertEqual(relaunched.transcripts()[second.id], "second committed")
        XCTAssertEqual(relaunched.transcriptRecoveryStatus(), .notNeeded,
                       "Never replace a readable primary with a newer shadow automatically")
        try relaunched.updateTranscript("next successfully committed", for: first.id)
        XCTAssertEqual(try Data(contentsOf: primary), try Data(contentsOf: shadow))
        XCTAssertEqual(relaunched.transcripts()[first.id], "next successfully committed")
        XCTAssertEqual(relaunched.transcripts()[second.id], "second committed")
        XCTAssertEqual(try Data(contentsOf: relaunched.audioURL(for: first)), audio)
    }

    func testAutoRecognitionInterruptedAfterBackupPreservesOtherTranscripts() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-speech-stop-after-backup-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, first, audio) = try makeEditableRecording(in: root)
        let (_, second, _) = try makeEditableRecording(in: root)
        try repo.saveTranscript("human reviewed", for: first.id)
        let primary = root.appendingPathComponent("transcripts.json")
        let committed = try Data(contentsOf: primary)
        repo.testTranscriptWriteCheckpoint = { checkpoint in
            if case .afterBackup = checkpoint {
                throw SyntheticWriteStop.interrupted
            }
        }
        XCTAssertThrowsError(try repo.saveTranscript("speech arrived", for: second.id))
        XCTAssertEqual(try Data(contentsOf: primary), committed)
        let relaunched = RecordingRepository(rootURL: root)
        XCTAssertEqual(relaunched.transcripts()[first.id], "human reviewed")
        XCTAssertNil(relaunched.transcripts()[second.id])
        XCTAssertEqual(try Data(contentsOf: relaunched.audioURL(for: first)), audio)
        // Speech can safely retry using the same UUID, without replacing the
        // other person's previous human-reviewed transcript.
        try relaunched.saveTranscript("speech arrived", for: second.id)
        XCTAssertEqual(relaunched.transcripts()[second.id], "speech arrived")
        XCTAssertEqual(relaunched.transcripts()[first.id], "human reviewed")
        XCTAssertEqual(
            try Data(contentsOf: root.appendingPathComponent("transcripts.json")),
            try Data(contentsOf: root.appendingPathComponent("transcripts.backup.json"))
        )
    }

    func testStopAfterMainCommitIsIdempotentlyVisibleOnReopen() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-stop-after-main-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, recording, audio) = try makeEditableRecording(in: root)
        try repo.saveTranscript("before", for: recording.id)
        repo.testTranscriptWriteCheckpoint = { checkpoint in
            if case .afterPrimary = checkpoint {
                throw SyntheticWriteStop.interrupted
            }
        }
        XCTAssertThrowsError(try repo.updateTranscript("already committed", for: recording.id))
        let relaunched = RecordingRepository(rootURL: root)
        XCTAssertEqual(relaunched.transcripts()[recording.id], "already committed")
        let primary = root.appendingPathComponent("transcripts.json")
        let shadow = root.appendingPathComponent("transcripts.backup.json")
        XCTAssertEqual(try Data(contentsOf: primary), try Data(contentsOf: shadow))
        try relaunched.updateTranscript("already committed", for: recording.id)
        XCTAssertEqual(relaunched.transcripts()[recording.id], "already committed")
        XCTAssertEqual(try Data(contentsOf: relaunched.audioURL(for: recording)), audio)
    }

    func testDeleteInterruptedAtEitherCheckpointCompletesWithoutResurrecting() throws {
        for stopBeforeBackup in [true, false] {
            let root = FileManager.default.temporaryDirectory
                .appendingPathComponent("what-delete-stopped-\(UUID().uuidString)")
            defer { try? FileManager.default.removeItem(at: root) }
            let (repo, removed, _) = try makeEditableRecording(in: root)
            let (_, kept, keeperAudio) = try makeEditableRecording(in: root)
            try repo.saveTranscript("must remain deleted", for: removed.id)
            try repo.saveTranscript("other owner's text", for: kept.id)

            repo.testTranscriptWriteCheckpoint = { checkpoint in
                if stopBeforeBackup {
                    if case .beforeBackup = checkpoint {
                        throw SyntheticWriteStop.interrupted
                    }
                } else {
                    if case .afterBackup = checkpoint {
                        throw SyntheticWriteStop.interrupted
                    }
                }
            }
            XCTAssertThrowsError(try repo.deleteRecording(removed.id))
            XCTAssertNil(repo.transcripts()[removed.id],
                         "Durable tombstone takes effect before cleanup")
            XCTAssertFalse(repo.allRecordings().contains(where: { $0.id == removed.id }))
            // Restarting with no fault injector completes pending cleanup.
            let reopened = RecordingRepository(rootURL: root)
            XCTAssertNil(reopened.transcripts()[removed.id])
            XCTAssertEqual(reopened.transcripts()[kept.id], "other owner's text")
            XCTAssertFalse(reopened.audioExists(for: removed))
            XCTAssertEqual(try Data(contentsOf: reopened.audioURL(for: kept)),
                           keeperAudio)
            let shadow = try ArvectumJSONCodec.decode(
                [String: String].self,
                from: Data(contentsOf: root.appendingPathComponent("transcripts.backup.json"))
            )
            XCTAssertNil(shadow[removed.id.uuidString])
            XCTAssertEqual(shadow[kept.id.uuidString], "other owner's text")
            let source = root.appendingPathComponent("late-watch-duplicate.m4a")
            try Data("late-watch-payload".utf8).write(to: source)
            let result = try reopened.acceptTemporaryFile(source, metadata: [
                TransferMetadataKey.id: removed.id.uuidString,
                TransferMetadataKey.createdAt: 1_700_000_000.0,
                TransferMetadataKey.duration: 3.0
            ])
            guard case .previouslyDeleted(let id) = result else {
                return XCTFail("Interrupted delete must reject late Watch delivery")
            }
            XCTAssertEqual(id, removed.id)
        }
    }

    func testTranscriptRecoveryCopyMatchesLatestSavedCatalog() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-shadow-recovery-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, first, audio) = try makeEditableRecording(in: root)
        let (_, second, _) = try makeEditableRecording(in: root)
        try repo.saveTranscript("original", for: first.id)
        try repo.saveTranscript("preserve", for: second.id)
        try repo.updateTranscript("corrected", for: first.id)

        let main = try Data(contentsOf: root.appendingPathComponent("transcripts.json"))
        let backup = try Data(contentsOf: root.appendingPathComponent("transcripts.backup.json"))
        XCTAssertEqual(main, backup)
        let decoded = try ArvectumJSONCodec.decode([String: String].self, from: backup)
        XCTAssertEqual(decoded[first.id.uuidString], "corrected")
        XCTAssertEqual(decoded[second.id.uuidString], "preserve")
        XCTAssertEqual(try Data(contentsOf: repo.audioURL(for: first)), audio)
    }

    func testExplicitRestoreRecoversValidShadowCopyOnlyWhenPrimaryCorrupt() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-restore-copy-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, first, audio) = try makeEditableRecording(in: root)
        let (_, second, _) = try makeEditableRecording(in: root)
        try repo.saveTranscript("one", for: first.id)
        try repo.saveTranscript("two", for: second.id)
        try repo.updateTranscript("one corrected", for: first.id)

        XCTAssertThrowsError(try repo.restoreTranscriptCatalogFromBackup()) {
            XCTAssertEqual($0 as? RecordingRepository.RepositoryError,
                           .transcriptRestoreNotNeeded)
        }
        let mainURL = root.appendingPathComponent("transcripts.json")
        try Data("broken syntax".utf8).write(to: mainURL)
        XCTAssertThrowsError(try repo.updateTranscript("unsafe", for: first.id))
        try repo.restoreTranscriptCatalogFromBackup()
        let reopened = RecordingRepository(rootURL: root)
        XCTAssertEqual(reopened.transcripts()[first.id], "one corrected")
        XCTAssertEqual(reopened.transcripts()[second.id], "two")
        XCTAssertEqual(try Data(contentsOf: reopened.audioURL(for: first)), audio)
        XCTAssertEqual(try Data(contentsOf: mainURL),
                       try Data(contentsOf: root.appendingPathComponent("transcripts.backup.json")))
    }

    func testRestoreRefusesCorruptBackupAndPreservesMainBytes() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-backup-unreadable-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, recording, audio) = try makeEditableRecording(in: root)
        try repo.saveTranscript("original", for: recording.id)
        let main = root.appendingPathComponent("transcripts.json")
        let backup = root.appendingPathComponent("transcripts.backup.json")
        let primaryBroken = Data("invalid primary".utf8)
        let backupBroken = Data("invalid backup".utf8)
        try primaryBroken.write(to: main)
        try backupBroken.write(to: backup)

        XCTAssertThrowsError(try repo.restoreTranscriptCatalogFromBackup()) {
            XCTAssertEqual($0 as? RecordingRepository.RepositoryError,
                           .transcriptBackupUnavailable)
        }
        XCTAssertEqual(try Data(contentsOf: main), primaryBroken)
        XCTAssertEqual(try Data(contentsOf: backup), backupBroken)
        XCTAssertEqual(try Data(contentsOf: repo.audioURL(for: recording)), audio)
    }

    func testRecoveryStatusIsReadOnlyAndRequiresCorruptPrimary() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-restore-status-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let repo = RecordingRepository(rootURL: root)
        XCTAssertEqual(repo.transcriptRecoveryStatus(), .notNeeded)
        let id = UUID()
        try repo.saveTranscript("safe backup", for: id)
        XCTAssertEqual(repo.transcriptRecoveryStatus(), .notNeeded)
        let main = root.appendingPathComponent("transcripts.json")
        let broken = Data("{bad-primary".utf8)
        try broken.write(to: main)
        XCTAssertEqual(repo.transcriptRecoveryStatus(), .ready(count: 1))
        XCTAssertEqual(try Data(contentsOf: main), broken,
                       "Previewing status must not write or repair the file")
        try repo.restoreTranscriptCatalogFromBackup()
        XCTAssertEqual(repo.transcriptRecoveryStatus(), .notNeeded)
        XCTAssertEqual(repo.transcripts()[id], "safe backup")
    }

    func testRecoveryStatusRefusesEmptyOrMissingBackup() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-recovery-unavailable-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let repo = RecordingRepository(rootURL: root)
        try repo.saveTranscript("safe", for: UUID())
        let primary = root.appendingPathComponent("transcripts.json")
        let backup = root.appendingPathComponent("transcripts.backup.json")
        let broken = Data("{broken-main".utf8)
        try broken.write(to: primary)
        try FileManager.default.removeItem(at: backup)
        XCTAssertEqual(repo.transcriptRecoveryStatus(), .unavailable)
        try ArvectumJSONCodec.encode([String: String]()).write(
            to: backup, options: .atomic
        )
        XCTAssertEqual(repo.transcriptRecoveryStatus(), .unavailable)
        XCTAssertThrowsError(try repo.restoreTranscriptCatalogFromBackup()) {
            XCTAssertEqual($0 as? RecordingRepository.RepositoryError,
                           .transcriptBackupUnavailable)
        }
        XCTAssertEqual(try Data(contentsOf: primary), broken)
    }

    func testMissingBackupCannotTriggerUnsafeRecovery() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-missing-backup-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, recording, audio) = try makeEditableRecording(in: root)
        try repo.saveTranscript("saved text", for: recording.id)
        let mainURL = root.appendingPathComponent("transcripts.json")
        try FileManager.default.removeItem(
            at: root.appendingPathComponent("transcripts.backup.json")
        )
        let corrupted = Data("{invalid".utf8)
        try corrupted.write(to: mainURL)
        XCTAssertThrowsError(try repo.restoreTranscriptCatalogFromBackup()) {
            XCTAssertEqual($0 as? RecordingRepository.RepositoryError,
                           .transcriptBackupUnavailable)
        }
        XCTAssertEqual(try Data(contentsOf: mainURL), corrupted)
        XCTAssertEqual(try Data(contentsOf: repo.audioURL(for: recording)), audio)
    }

    func testBackupWriteFailurePreservesValidPrimaryAndRecording() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-backup-write-fail-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, recording, audio) = try makeEditableRecording(in: root)
        try repo.saveTranscript("previous", for: recording.id)
        let main = root.appendingPathComponent("transcripts.json")
        let previousBytes = try Data(contentsOf: main)
        let backup = root.appendingPathComponent("transcripts.backup.json")
        try FileManager.default.removeItem(at: backup)
        try FileManager.default.createDirectory(at: backup,
                                                withIntermediateDirectories: false)
        XCTAssertThrowsError(try repo.updateTranscript("should fail", for: recording.id))
        XCTAssertEqual(try Data(contentsOf: main), previousBytes)
        XCTAssertEqual(try Data(contentsOf: repo.audioURL(for: recording)), audio)
    }

    func testDeletingTranscriptAlsoPurgesShadowCopyWithoutResurrection() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-backup-deletion-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, first, _) = try makeEditableRecording(in: root)
        let (_, second, audio) = try makeEditableRecording(in: root)
        try repo.saveTranscript("secret to erase", for: first.id)
        try repo.saveTranscript("keep", for: second.id)
        try repo.deleteRecording(first.id)
        let backup = try ArvectumJSONCodec.decode(
            [String: String].self,
            from: Data(contentsOf: root.appendingPathComponent("transcripts.backup.json"))
        )
        XCTAssertNil(backup[first.id.uuidString])
        XCTAssertEqual(backup[second.id.uuidString], "keep")
        XCTAssertFalse(repo.audioExists(for: first))
        XCTAssertEqual(try Data(contentsOf: repo.audioURL(for: second)), audio)
    }

    func testCorruptPrimaryInterruptedDeleteIsRecoveredWithoutResurrection() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-backup-deletion-recovery-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let (repo, removed, _) = try makeEditableRecording(in: root)
        let (_, kept, originalAudio) = try makeEditableRecording(in: root)
        try repo.saveTranscript("deleted secret", for: removed.id)
        try repo.saveTranscript("survivor", for: kept.id)
        let primaryURL = root.appendingPathComponent("transcripts.json")
        let broken = Data("{broken".utf8)
        try broken.write(to: primaryURL)
        // Marker is durable even though incomplete cleanup fails closed.
        XCTAssertThrowsError(try repo.deleteRecording(removed.id)) {
            XCTAssertEqual($0 as? RecordingRepository.RepositoryError,
                           .transcriptStoreUnreadable)
        }
        XCTAssertEqual(try Data(contentsOf: primaryURL), broken)
        XCTAssertNil(repo.transcripts()[removed.id])
        XCTAssertEqual(repo.allRecordings().map(\.id), [kept.id])

        // Explicit repair discards tombstoned text even if the shadow copy
        // predates deletion. It also completes deferred audio cleanup.
        let reopened = RecordingRepository(rootURL: root)
        try reopened.restoreTranscriptCatalogFromBackup()
        XCTAssertNil(reopened.transcripts()[removed.id])
        XCTAssertEqual(reopened.transcripts()[kept.id], "survivor")
        XCTAssertFalse(reopened.audioExists(for: removed))
        XCTAssertEqual(try Data(contentsOf: reopened.audioURL(for: kept)),
                       originalAudio)
        let shadow = try ArvectumJSONCodec.decode(
            [String: String].self,
            from: Data(contentsOf: root.appendingPathComponent("transcripts.backup.json"))
        )
        XCTAssertNil(shadow[removed.id.uuidString])
    }

    func testDuplicateDeliveryCreatesOneRecording() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let repository = RecordingRepository(rootURL: root)
        let source = root.appendingPathComponent("source.m4a")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("audio".utf8).write(to: source)

        let id = UUID()
        let metadata: [String: Any] = [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: 3.5
        ]

        _ = try repository.acceptTemporaryFile(source, metadata: metadata)
        _ = try repository.acceptTemporaryFile(source, metadata: metadata)

        let recordings = repository.allRecordings()
        XCTAssertEqual(recordings.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: repository.audioURL(for: recordings[0]).path
        ))
    }
    func testDeletionErasesAudioTranscriptAndMetadataAndSurvivesRelaunch() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-delete-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let repo = RecordingRepository(rootURL: root)
        let source = root.appendingPathComponent("source.m4a")
        try Data("audio".utf8).write(to: source)
        let id = UUID()
        let metadata: [String: Any] = [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: 2.5
        ]
        let outcome = try repo.acceptTemporaryFile(source, metadata: metadata)
        guard case .stored(let recording) = outcome else {
            return XCTFail("Initial transfer should be stored")
        }
        try repo.saveTranscript("Private words", for: id)
        XCTAssertEqual(repo.allRecordings().count, 1)
        XCTAssertTrue(repo.audioExists(for: recording))
        XCTAssertEqual(repo.transcripts()[id], "Private words")

        try repo.deleteRecording(id)

        let relaunched = RecordingRepository(rootURL: root)
        XCTAssertTrue(relaunched.allRecordings().isEmpty)
        XCTAssertFalse(relaunched.audioExists(for: recording))
        XCTAssertNil(relaunched.transcripts()[id])
        XCTAssertFalse(FileManager.default.fileExists(atPath:
            root.appendingPathComponent("Audio/\(id.uuidString).m4a").path))
    }

    func testLateWatchRedeliveryDoesNotRestoreDeletedRecording() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-retry-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = root.appendingPathComponent("source.m4a")
        try Data("audio".utf8).write(to: source)
        let id = UUID()
        let metadata: [String: Any] = [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: 4.0
        ]
        let repo = RecordingRepository(rootURL: root)
        _ = try repo.acceptTemporaryFile(source, metadata: metadata)
        try repo.deleteRecording(id)

        let relaunched = RecordingRepository(rootURL: root)
        let outcome = try relaunched.acceptTemporaryFile(source, metadata: metadata)
        guard case .previouslyDeleted(let skippedID) = outcome else {
            return XCTFail("Deleted UUID must be acknowledged without being restored")
        }
        XCTAssertEqual(skippedID, id)
        XCTAssertTrue(relaunched.allRecordings().isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath:
            root.appendingPathComponent("Audio/\(id.uuidString).m4a").path))
        try relaunched.saveTranscript("late", for: id)
        XCTAssertNil(relaunched.transcripts()[id])
    }

    func testDeletingOneRecordingPreservesTheOther() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-two-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let repo = RecordingRepository(rootURL: root)
        let source = root.appendingPathComponent("source.m4a")
        try Data("audio".utf8).write(to: source)
        let ids = [UUID(), UUID()]
        for id in ids {
            _ = try repo.acceptTemporaryFile(source, metadata: [
                TransferMetadataKey.id: id.uuidString,
                TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
                TransferMetadataKey.duration: 1.0
            ])
            try repo.saveTranscript("Keep \(id.uuidString)", for: id)
        }

        try repo.deleteRecording(ids[0])
        XCTAssertEqual(repo.allRecordings().map(\.id), [ids[1]])
        XCTAssertNotNil(repo.transcripts()[ids[1]])
        XCTAssertTrue(repo.audioExists(for: repo.allRecordings()[0]))
        XCTAssertNil(repo.transcripts()[ids[0]])
    }

    func testDeletedEntryIsCleanedUpOnRelaunchAfterInterruptedDeletion() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-recovery-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let repo = RecordingRepository(rootURL: root)
        let source = root.appendingPathComponent("source.m4a")
        try Data("audio".utf8).write(to: source)
        let id = UUID()
        let metadata: [String: Any] = [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: 1.0
        ]
        _ = try repo.acceptTemporaryFile(source, metadata: metadata)
        try repo.saveTranscript("Text", for: id)
        let savedIndex = try Data(contentsOf: root.appendingPathComponent("recordings.json"))
        let savedText = try Data(contentsOf: root.appendingPathComponent("transcripts.json"))
        try repo.deleteRecording(id)

        // Simulate interrupted cleanup leaving stale files after tombstone commit.
        try savedIndex.write(to: root.appendingPathComponent("recordings.json"))
        try savedText.write(to: root.appendingPathComponent("transcripts.json"))
        try Data("audio".utf8).write(
            to: root.appendingPathComponent("Audio/\(id.uuidString).m4a"))

        let reopened = RecordingRepository(rootURL: root)
        XCTAssertTrue(reopened.allRecordings().isEmpty)
        XCTAssertNil(reopened.transcripts()[id])
        XCTAssertFalse(FileManager.default.fileExists(atPath:
            root.appendingPathComponent("Audio/\(id.uuidString).m4a").path))
    }

    func testSeparateRepositoriesRespectTheSameDeletionLedger() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-instances-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let storeRepository = RecordingRepository(rootURL: root)
        let transferRepository = RecordingRepository(rootURL: root)
        let source = root.appendingPathComponent("source.m4a")
        try Data("audio".utf8).write(to: source)
        let id = UUID()
        let metadata: [String: Any] = [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: 1.0
        ]
        _ = try transferRepository.acceptTemporaryFile(source, metadata: metadata)
        try storeRepository.deleteRecording(id)
        let response = try transferRepository.acceptTemporaryFile(source, metadata: metadata)
        guard case .previouslyDeleted(let deletedID) = response else {
            return XCTFail("Shared storage deletion must be visible to transfer instance")
        }
        XCTAssertEqual(deletedID, id)
    }

    func testMultipleOfflineTransfersRetainDistinctAudioThroughReceiverRestart() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-offline-batch-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let ids = (0..<3).map { _ in UUID() }
        let metadata: [[String: Any]] = ids.enumerated().map { position, id in [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: 1_700_000_000.0 + Double(position),
            TransferMetadataKey.duration: Double(position + 1)
        ]}
        let sources: [URL] = try ids.enumerated().map { position, id in
            let source = root.appendingPathComponent("source-\(id.uuidString).m4a")
            try Data("unique-audio-\(position)".utf8).write(to: source)
            return source
        }

        let firstReceiver = RecordingRepository(rootURL: root)
        _ = try firstReceiver.acceptTemporaryFile(sources[0], metadata: metadata[0])

        // Transfer resumes after receiver relaunch: remaining files arrive later.
        let relaunchedReceiver = RecordingRepository(rootURL: root)
        for position in 1..<3 {
            _ = try relaunchedReceiver.acceptTemporaryFile(
                sources[position], metadata: metadata[position]
            )
        }

        // Watch can retry old deliveries if the ACK was delayed or lost.
        for position in 0..<3 {
            _ = try relaunchedReceiver.acceptTemporaryFile(
                sources[position], metadata: metadata[position]
            )
        }

        XCTAssertEqual(Set(relaunchedReceiver.allRecordings().map(\.id)), Set(ids))
        XCTAssertEqual(relaunchedReceiver.allRecordings().count, 3)
        for position in 0..<3 {
            let recording = try XCTUnwrap(relaunchedReceiver.allRecordings().first {
                $0.id == ids[position]
            })
            XCTAssertEqual(
                try Data(contentsOf: relaunchedReceiver.audioURL(for: recording)),
                try Data(contentsOf: sources[position])
            )
        }
    }

    func testInvalidTransferNeverCreatesARecordingOrAudioFile() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-invalid-transfer-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = root.appendingPathComponent("source.m4a")
        try Data("audio".utf8).write(to: source)
        let receiver = RecordingRepository(rootURL: root)
        XCTAssertThrowsError(try receiver.acceptTemporaryFile(source, metadata: [
            TransferMetadataKey.id: "not-a-uuid",
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: 2.0
        ]))
        XCTAssertTrue(receiver.allRecordings().isEmpty)
        XCTAssertTrue(
            (try FileManager.default.contentsOfDirectory(
                atPath: root.appendingPathComponent("Audio").path
            )).isEmpty
        )
    }

    func testWatchRetryWaitsForACKWithoutDuplicatingOutstandingTransfers() {
        var policy = WatchTransferRetryPolicy()
        let id = UUID()
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        XCTAssertTrue(policy.shouldSchedule(id, isOutstanding: false, at: now))
        policy.didSchedule(id, at: now)
        XCTAssertFalse(policy.shouldSchedule(id, isOutstanding: true, at: now.addingTimeInterval(200)))
        XCTAssertFalse(policy.shouldSchedule(id, isOutstanding: false, at: now.addingTimeInterval(89)))

        policy.didComplete(id, at: now.addingTimeInterval(10))
        XCTAssertFalse(policy.shouldSchedule(id, isOutstanding: false, at: now.addingTimeInterval(99)))
        XCTAssertTrue(policy.shouldSchedule(id, isOutstanding: false, at: now.addingTimeInterval(100)))
        policy.didAcknowledge(id)
        XCTAssertTrue(policy.shouldSchedule(id, isOutstanding: false, at: now))
    }

    func testWatchTransferFailureAllowsRetryAndOtherUUIDsAreIndependent() {
        var policy = WatchTransferRetryPolicy()
        let id = UUID(), otherID = UUID()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        policy.didSchedule(id, at: now)
        XCTAssertTrue(policy.shouldSchedule(otherID, isOutstanding: false, at: now))
        policy.didFail(id)
        XCTAssertTrue(policy.shouldSchedule(id, isOutstanding: false, at: now))
    }

    func testImmediatePayloadRoundTripAndDurableRecording() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-live-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let recording = RecordingEnvelope(
            id: UUID(),
            createdAt: Date(timeIntervalSince1970: 1_700_000_002),
            duration: 6.5,
            fileName: "capture.m4a"
        )
        let audio = Data("sample-audio-verified-on-device".utf8)
        let packet = ImmediateRecordingPayload(recording: recording, audio: audio)
        let decoded = try ImmediateRecordingPayload.decode(packet.encode())
        XCTAssertEqual(decoded.recording, recording)
        XCTAssertEqual(decoded.audio, audio)

        let source = root.appendingPathComponent("source.m4a")
        try decoded.audio.write(to: source)
        let repo = RecordingRepository(rootURL: root)
        let received = try repo.acceptTemporaryFile(
            source, metadata: decoded.metadata
        )
        XCTAssertEqual(received.id, recording.id)
        XCTAssertEqual(repo.allRecordings().count, 1)
        let stored = try XCTUnwrap(repo.allRecordings().first)
        XCTAssertEqual(try Data(contentsOf: repo.audioURL(for: stored)), audio)

        let ack = ImmediateRecordingReply(acknowledgedID: recording.id)
        XCTAssertEqual(try ImmediateRecordingReply.decode(ack.encode()).acknowledgedID,
                       recording.id)
    }

    func testLiveAndBackgroundDeliveryDeduplicateAndHonorDeletion() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-fast-duplicate-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let record = RecordingEnvelope(
            id: UUID(),
            createdAt: Date(timeIntervalSince1970: 1_700_000_004),
            duration: 1.3,
            fileName: "original.m4a"
        )
        let payload = try ImmediateRecordingPayload(
            recording: record, audio: Data("voice".utf8)
        ).encode()
        let decoded = try ImmediateRecordingPayload.decode(payload)
        let source = root.appendingPathComponent("source.m4a")
        try decoded.audio.write(to: source)
        let repo = RecordingRepository(rootURL: root)
        _ = try repo.acceptTemporaryFile(source, metadata: decoded.metadata)
        _ = try repo.acceptTemporaryFile(source, metadata: decoded.metadata)
        XCTAssertEqual(repo.allRecordings().map(\.id), [record.id])

        try repo.deleteRecording(record.id)
        let lateFile = try repo.acceptTemporaryFile(source, metadata: decoded.metadata)
        guard case .previouslyDeleted(record.id) = lateFile else {
            return XCTFail("A slow fallback must not revive a deleted live recording")
        }
        XCTAssertTrue(repo.allRecordings().isEmpty)
    }

    func testManualTranscriptCorrectionPersistsAfterRelaunchAndPreservesAudio() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-edit-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let id = UUID()
        let source = root.appendingPathComponent("source.m4a")
        let originalAudio = Data("original-voice-remains-untouched".utf8)
        try originalAudio.write(to: source)
        let repo = RecordingRepository(rootURL: root)
        _ = try repo.acceptTemporaryFile(source, metadata: [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: 2.2
        ])
        try repo.saveTranscript("Recognised text with an eror", for: id)
        try repo.updateTranscript("Recognised text with an error", for: id)

        let reopened = RecordingRepository(rootURL: root)
        XCTAssertEqual(reopened.transcripts()[id], "Recognised text with an error")
        let recording = try XCTUnwrap(reopened.allRecordings().first)
        XCTAssertEqual(try Data(contentsOf: reopened.audioURL(for: recording)), originalAudio)
        XCTAssertEqual(reopened.allRecordings().count, 1)
    }

    func testManualTranscriptEditDoesNotEraseOtherTranscripts() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-other-edits-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let repository = RecordingRepository(rootURL: root)
        let source = root.appendingPathComponent("source.m4a")
        try Data("audio".utf8).write(to: source)
        let ids = [UUID(), UUID()]
        for id in ids {
            _ = try repository.acceptTemporaryFile(source, metadata: [
                TransferMetadataKey.id: id.uuidString,
                TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
                TransferMetadataKey.duration: 1.0
            ])
            try repository.saveTranscript("Initial", for: id)
        }

        try repository.updateTranscript("Changed", for: ids[0])
        let saved = RecordingRepository(rootURL: root).transcripts()
        XCTAssertEqual(saved[ids[0]], "Changed")
        XCTAssertEqual(saved[ids[1]], "Initial")
    }

    func testManualTranscriptEditRejectsEmptyUnknownAndDeletedNotes() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-edit-invalid-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let repository = RecordingRepository(rootURL: root)
        let id = UUID()

        XCTAssertThrowsError(try repository.updateTranscript("Text", for: id))
        let source = root.appendingPathComponent("audio.m4a")
        try Data("audio".utf8).write(to: source)
        _ = try repository.acceptTemporaryFile(source, metadata: [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: 2.0
        ])
        XCTAssertThrowsError(try repository.updateTranscript("   ", for: id))
        try repository.deleteRecording(id)
        XCTAssertThrowsError(try repository.updateTranscript("Never restore", for: id))
        XCTAssertNil(RecordingRepository(rootURL: root).transcripts()[id])
    }

    func testArchivePersistsThroughRelaunchAndWatchRedeliveryWithoutTouchingAudio() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-archive-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let repo = RecordingRepository(rootURL: root)
        let source = root.appendingPathComponent("incoming.m4a")
        let audio = Data("original-audio".utf8)
        try audio.write(to: source)
        let id = UUID()
        let metadata: [String: Any] = [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: 1.25
        ]
        _ = try repo.acceptTemporaryFile(source, metadata: metadata)
        try repo.saveTranscript("A note I want later", for: id)
        try repo.setArchived(id, archived: true)

        // A retry from the Watch must not move the archived entry back to Inbox.
        _ = try RecordingRepository(rootURL: root)
            .acceptTemporaryFile(source, metadata: metadata)
        let reopened = RecordingRepository(rootURL: root)
        XCTAssertTrue(try reopened.archivedIDs().contains(id))
        XCTAssertEqual(reopened.allRecordings().count, 1)
        XCTAssertEqual(reopened.transcripts()[id], "A note I want later")
        let recording = try XCTUnwrap(reopened.allRecordings().first)
        XCTAssertEqual(try Data(contentsOf: reopened.audioURL(for: recording)), audio)

        try reopened.setArchived(id, archived: false)
        XCTAssertFalse(try RecordingRepository(rootURL: root).archivedIDs().contains(id))
        XCTAssertEqual(try Data(contentsOf: reopened.audioURL(for: recording)), audio)
    }

    func testDeletingArchivedRecordingErasesArchiveMarkerAndContent() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-archive-delete-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let repository = RecordingRepository(rootURL: root)
        let source = root.appendingPathComponent("source.m4a")
        try Data("recording".utf8).write(to: source)
        let id = UUID()
        _ = try repository.acceptTemporaryFile(source, metadata: [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: 3.0
        ])
        try repository.saveTranscript("Archivable transcript", for: id)
        try repository.setArchived(id, archived: true)
        try repository.deleteRecording(id)
        let reopened = RecordingRepository(rootURL: root)
        XCTAssertFalse(try reopened.archivedIDs().contains(id))
        XCTAssertNil(reopened.transcripts()[id])
        XCTAssertTrue(reopened.allRecordings().isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: root.appendingPathComponent("Audio/\(id.uuidString).m4a").path
        ))
        XCTAssertThrowsError(try reopened.setArchived(id, archived: false))
    }

    func testArchiveRejectsUnknownUUIDAndDoesNotCreateMarkers() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-archive-unknown-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let repo = RecordingRepository(rootURL: root)
        XCTAssertThrowsError(try repo.setArchived(UUID(), archived: true))
        XCTAssertTrue(try repo.archivedIDs().isEmpty)
    }

    func testInboxOrganizerFiltersTextCaseInsensitiveWithArchiveSegregation() {
        let first = UUID(), second = UUID(), third = UUID()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let items = [
            RecordingEnvelope(id: first, createdAt: now, duration: 1, fileName: "a.m4a"),
            RecordingEnvelope(id: second, createdAt: now.addingTimeInterval(-10),
                              duration: 2, fileName: "b.m4a"),
            RecordingEnvelope(id: third, createdAt: now.addingTimeInterval(-20),
                              duration: 3, fileName: "c.m4a")
        ]
        let transcripts = [first: "Купить МОЛОКО", second: "Meeting at noon", third: "Купить хлеб"]
        let ids: Set<UUID> = [third]
        let inbox = InboxOrganizer.recordings(
            items, archivedIDs: ids, folder: .inbox, query: "",
            transcripts: transcripts
        )
        XCTAssertEqual(inbox.map(\.id), [first, second])
        XCTAssertEqual(InboxOrganizer.recordings(
            items, archivedIDs: ids, folder: .inbox,
            query: "молоко", transcripts: transcripts
        ).map(\.id), [first])
        XCTAssertEqual(InboxOrganizer.recordings(
            items, archivedIDs: ids, folder: .archive,
            query: "КУПИТЬ", transcripts: transcripts
        ).map(\.id), [third])
        XCTAssertTrue(InboxOrganizer.recordings(
            items, archivedIDs: ids, folder: .inbox,
            query: "  nonexistent  ", transcripts: transcripts
        ).isEmpty)
    }

    func testInboxGroupingRespectsCalendarDaysAndOrdering() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 10, day: 13, hour: 10
        )))
        let today = UUID(), yesterday = UUID(), earlier = UUID()
        let items = [
            RecordingEnvelope(id: earlier, createdAt: now.addingTimeInterval(-180_000),
                              duration: 1, fileName: "earlier.m4a"),
            RecordingEnvelope(id: today, createdAt: now.addingTimeInterval(-60),
                              duration: 1, fileName: "today.m4a"),
            RecordingEnvelope(id: yesterday, createdAt: now.addingTimeInterval(-60_000),
                              duration: 1, fileName: "yesterday.m4a")
        ]
        let groups = InboxOrganizer.groups(items, now: now, calendar: calendar)
        XCTAssertEqual(groups.map(\.day), [.today, .yesterday, .earlier])
        XCTAssertEqual(groups.map { $0.recordings.first?.id }, [today, yesterday, earlier])
    }

    func testWatchQueueStatusSnapshotRoundTripAndValidation() {
        let original = WatchQueueSnapshot(
            pendingCount: 3,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let recovered = WatchQueueSnapshot(context: original.context)
        XCTAssertEqual(recovered, original)

        var bad = original.context
        bad["pendingCount"] = -1
        XCTAssertNil(WatchQueueSnapshot(context: bad))
        bad = original.context
        bad["updatedAt"] = Double.nan
        XCTAssertNil(WatchQueueSnapshot(context: bad))
        bad = original.context
        bad[TransferMetadataKey.type] = "something-else"
        XCTAssertNil(WatchQueueSnapshot(context: bad))
    }

    func testWatchQueueCacheRejectsOutOfOrderStatusAndPersists() throws {
        let suite = "what-queue-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let cache = WatchQueueStatusCache(defaults: defaults)
        XCTAssertNil(cache.latest)
        let newer = WatchQueueSnapshot(
            pendingCount: 2,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )
        let older = WatchQueueSnapshot(
            pendingCount: 19,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_090)
        )
        XCTAssertTrue(cache.accept(newer))
        XCTAssertFalse(cache.accept(older))
        XCTAssertEqual(WatchQueueStatusCache(defaults: defaults).latest, newer)
        XCTAssertTrue(cache.accept(WatchQueueSnapshot(
            pendingCount: 0,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_120)
        )))
        XCTAssertEqual(cache.latest?.pendingCount, 0)
    }

    func testAudioAndTranscriptExportContainsByteIdenticalOriginalAndText() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-export-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let audio = root.appendingPathComponent("original.m4a")
        let bytes = Data([0x41, 0x41, 0x43, 0x20, 0x01, 0x00, 0x5A])
        try bytes.write(to: audio)
        let recording = RecordingEnvelope(
            id: UUID(),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            duration: 2.5,
            fileName: "original.m4a"
        )
        let export = try RecordingExportService.prepare(
            recording: recording,
            audioURL: audio,
            transcript: "Исправленная запись\nВторая строка",
            selection: .audioAndTranscript
        )
        defer { export.cleanUp() }
        XCTAssertEqual(export.items.count, 2)
        let audioCopy = try XCTUnwrap(export.items.first(where: { $0.pathExtension == "m4a" }))
        let textCopy = try XCTUnwrap(export.items.first(where: { $0.pathExtension == "txt" }))
        XCTAssertEqual(try Data(contentsOf: audioCopy), bytes)
        XCTAssertEqual(try String(contentsOf: textCopy, encoding: .utf8),
                       "Исправленная запись\nВторая строка")
        XCTAssertEqual(try Data(contentsOf: audio), bytes)
        export.cleanUp()
        XCTAssertFalse(FileManager.default.fileExists(atPath: export.directory.path))
        XCTAssertEqual(try Data(contentsOf: audio), bytes)
    }

    func testExportRejectsMissingAssetsWithoutLeavingStagingData() throws {
        let missingAudio = FileManager.default.temporaryDirectory
            .appendingPathComponent("missing-\(UUID().uuidString).m4a")
        let recording = RecordingEnvelope(
            id: UUID(),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            duration: 1,
            fileName: "missing.m4a"
        )
        XCTAssertThrowsError(try RecordingExportService.prepare(
            recording: recording,
            audioURL: missingAudio,
            transcript: "test",
            selection: .audio
        ))
        XCTAssertThrowsError(try RecordingExportService.prepare(
            recording: recording,
            audioURL: missingAudio,
            transcript: nil,
            selection: .transcript
        ))
        let textOnly = try RecordingExportService.prepare(
            recording: recording,
            audioURL: missingAudio,
            transcript: "Only text",
            selection: .transcript
        )
        XCTAssertEqual(textOnly.items.count, 1)
        XCTAssertEqual(textOnly.items.first?.pathExtension, "txt")
        textOnly.cleanUp()
    }

    func testSemanticChunkingCoversLongTextAndCosine() {
        let note = "Купить продукты завтра. Записать идеи о встрече! " +
            String(repeating: "Очень важное напоминание о документах. ", count: 30)
        let chunks = LocalSemanticSearch.chunks(note, limit: 160)
        XCTAssertGreaterThan(chunks.count, 2)
        XCTAssertTrue(chunks.contains { $0.contains("продукты") })
        XCTAssertTrue(chunks.contains { $0.contains("документах") })
        XCTAssertLessThanOrEqual(chunks.map(\.count).max() ?? 0, 160)
        XCTAssertEqual(LocalSemanticSearch.cosine([1, 0], [1, 0]), 1)
        XCTAssertEqual(LocalSemanticSearch.cosine([1, 0], [0, 1]), 0)
        XCTAssertNil(LocalSemanticSearch.cosine([0, 0], [0, 1]))
    }

    func testSemanticSearchFindsMeaningWithoutSharedQueryWords() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-semantic-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let repo = RecordingRepository(rootURL: root)
        let audio = root.appendingPathComponent("source.m4a")
        try Data("fake".utf8).write(to: audio)
        let relevantID = UUID(), unrelatedID = UUID()
        for id in [relevantID, unrelatedID] {
            _ = try repo.acceptTemporaryFile(audio, metadata: [
                TransferMetadataKey.id: id.uuidString,
                TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
                TransferMetadataKey.duration: 3.0
            ])
        }
        try repo.updateTranscript("Кошку нужно отвести к ветеринару", for: relevantID)
        try repo.updateTranscript("В пятницу купить краску для забора", for: unrelatedID)
        let index = LocalSemanticSearch(
            cacheURL: root.appendingPathComponent("semantic-search-index.json")
        )
        // A deterministic stand-in for Apple's actual on-device model.
        let vectorizer: LocalSemanticSearch.Vectorizer = { text in
            if text.contains("питомц") || text.contains("Кошку") { return [1, 0] }
            return [0, 1]
        }
        let search = index.search(
            query: "домашние питомцы",
            recordings: repo.allRecordings(),
            transcripts: repo.transcripts(),
            vectorizer: vectorizer,
            modelKey: "test-embedding"
        )
        XCTAssertEqual(search.hits.map(\.id), [relevantID])
        XCTAssertEqual(search.hits.first?.match, .semantic)
        XCTAssertEqual(search.indexedCount, 2)
        XCTAssertTrue(search.semanticAvailable)

        // A cached vector from prior search must be usable after reopening.
        let reopened = LocalSemanticSearch(
            cacheURL: root.appendingPathComponent("semantic-search-index.json")
        )
        let reused = reopened.search(
            query: "домашние питомцы", recordings: repo.allRecordings(),
            transcripts: repo.transcripts(),
            vectorizer: { text in
                text.contains("питомц") ? [1, 0] : nil
            },
            modelKey: "test-embedding"
        )
        XCTAssertEqual(reused.hits.map(\.id), [relevantID])
    }

    func testSearchFallsBackToRussianTextAndEditsInvalidateCachedVectors() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-search-edit-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let repo = RecordingRepository(rootURL: root)
        let source = root.appendingPathComponent("source.m4a")
        try Data("audio".utf8).write(to: source)
        let id = UUID()
        _ = try repo.acceptTemporaryFile(source, metadata: [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: 5.0
        ])
        try repo.updateTranscript("Я оставил ключи под тумбочкой", for: id)
        let index = LocalSemanticSearch(
            cacheURL: root.appendingPathComponent("semantic-search-index.json")
        )
        let first = index.search(
            query: "ключи", recordings: repo.allRecordings(),
            transcripts: repo.transcripts(), vectorizer: nil
        )
        XCTAssertEqual(first.hits.map(\.id), [id])
        XCTAssertEqual(first.hits.first?.match, .text)
        XCTAssertFalse(first.semanticAvailable)

        try repo.updateTranscript("Купить молоко и хлеб", for: id)
        let stale = index.search(
            query: "ключи", recordings: repo.allRecordings(),
            transcripts: repo.transcripts(), vectorizer: nil
        )
        XCTAssertTrue(stale.hits.isEmpty)
        let updated = index.search(
            query: "молоко", recordings: repo.allRecordings(),
            transcripts: repo.transcripts(), vectorizer: nil
        )
        XCTAssertEqual(updated.hits.map(\.id), [id])
    }

    func testDeletingRecordingAlsoPurgesDerivedSemanticVectors() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-semantic-delete-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let repo = RecordingRepository(rootURL: root)
        let audio = root.appendingPathComponent("source.m4a")
        try Data("audio".utf8).write(to: audio)
        let id = UUID()
        _ = try repo.acceptTemporaryFile(audio, metadata: [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: 4.0
        ])
        try repo.updateTranscript("Конфиденциальное напоминание", for: id)
        let indexURL = root.appendingPathComponent("semantic-search-index.json")
        let index = LocalSemanticSearch(cacheURL: indexURL)
        _ = index.search(
            query: "напоминание", recordings: repo.allRecordings(),
            transcripts: repo.transcripts(), vectorizer: { _ in [1, 0] },
            modelKey: "test"
        )
        let before = try JSONDecoder().decode(
            LocalSemanticSearch.Cache.self,
            from: Data(contentsOf: indexURL)
        )
        XCTAssertNotNil(before.entries[id])
        XCTAssertFalse(
            try String(contentsOf: indexURL, encoding: .utf8)
                .contains("Конфиденциальное напоминание")
        )
        try repo.deleteRecording(id)
        let after = try JSONDecoder().decode(
            LocalSemanticSearch.Cache.self,
            from: Data(contentsOf: indexURL)
        )
        XCTAssertNil(after.entries[id])
        XCTAssertTrue(repo.transcripts().isEmpty)
    }

    func testOneWordExactLookupSuppressesSpuriousSemanticResults() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-rare-word-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let repo = RecordingRepository(rootURL: root)
        let source = root.appendingPathComponent("source.m4a")
        try Data("fixture".utf8).write(to: source)
        let id = UUID()
        _ = try repo.acceptTemporaryFile(source, metadata: [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: 2.2
        ])
        try repo.updateTranscript("Купить хлеб для завтрака", for: id)
        let index = LocalSemanticSearch(cacheURL: root.appendingPathComponent(
            "semantic-search-index.json"
        ))
        let perfectFalsePositive: LocalSemanticSearch.Vectorizer = { _ in [1, 0] }
        let noMatch = index.search(
            query: "эдельвейс",
            recordings: repo.allRecordings(),
            transcripts: repo.transcripts(),
            vectorizer: perfectFalsePositive,
            modelKey: "fake"
        )
        XCTAssertTrue(noMatch.hits.isEmpty)

        try repo.updateTranscript("раз два три четыре пять эдельвейс шесть семь", for: id)
        let found = index.search(
            query: "эдельвейс",
            recordings: repo.allRecordings(),
            transcripts: repo.transcripts(),
            vectorizer: perfectFalsePositive,
            modelKey: "fake"
        )
        XCTAssertEqual(found.hits.map(\.id), [id])
        XCTAssertEqual(found.hits.first?.match, .text)
    }

    func testPhoneCapturedRecordingUsesTheSameDurableRepositoryAsWatch() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-phone-intake-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let repo = RecordingRepository(rootURL: root)
        let source = root.appendingPathComponent("phone-recording.m4a")
        let original = Data("locally-recorded-original".utf8)
        try original.write(to: source)
        let id = UUID()
        _ = try repo.acceptTemporaryFile(source, metadata: [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: 3.8
        ])
        let reopened = RecordingRepository(rootURL: root)
        let note = try XCTUnwrap(reopened.allRecordings().first)
        XCTAssertEqual(note.id, id)
        XCTAssertEqual(try Data(contentsOf: reopened.audioURL(for: note)), original)
        XCTAssertTrue(reopened.transcripts().isEmpty)
        try reopened.updateTranscript("Эдельвейс", for: id)
        XCTAssertEqual(RecordingRepository(rootURL: root).transcripts()[id], "Эдельвейс")
    }

    func testPhoneRecorderRejectsThePhysicalSixSecondCaptureWithOnlySixtyMillisecondsOfAudio() {
        XCTAssertThrowsError(try PhoneCaptureValidation.validate(
            actualDuration: 0.06, elapsedTime: 6.261625
        )) { error in
            guard case PhoneCaptureValidation.CaptureError.incomplete = error else {
                return XCTFail("Tiny AAC file must be recognized as interrupted capture")
            }
        }
        XCTAssertThrowsError(try PhoneCaptureValidation.validate(
            actualDuration: 0, elapsedTime: 6.26
        ))
        XCTAssertThrowsError(try PhoneCaptureValidation.validate(
            actualDuration: 2, elapsedTime: 6.26
        ))
    }

    func testPhoneRecorderAcceptsRealAudioLengthAndRejectsUnreadableValues() throws {
        XCTAssertNoThrow(try PhoneCaptureValidation.validate(
            actualDuration: 6.18, elapsedTime: 6.26
        ))
        XCTAssertNoThrow(try PhoneCaptureValidation.validate(
            actualDuration: 1.88, elapsedTime: 2.0
        ))
        XCTAssertThrowsError(try PhoneCaptureValidation.validate(
            actualDuration: Double.nan, elapsedTime: 1
        ))
        XCTAssertThrowsError(try PhoneCaptureValidation.validate(
            actualDuration: .infinity, elapsedTime: 1
        ))
        XCTAssertThrowsError(try PhoneCaptureValidation.validate(
            actualDuration: 1, elapsedTime: 0
        ))
    }

    func testDirectMicrophoneBufferPipelineWritesPlayableAACWithRealFrameDuration() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "what-avaudioengine-test-\(UUID().uuidString).m4a"
        )
        defer { try? FileManager.default.removeItem(at: url) }
        let format = try XCTUnwrap(AVAudioFormat(
            standardFormatWithSampleRate: 48_000, channels: 1
        ))
        let pipeline = try MicrophoneCapturePipeline(
            url: url, inputFormat: format
        )
        for i in 0..<80 {
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(
                pcmFormat: format, frameCapacity: 1_024
            ))
            buffer.frameLength = 1_024
            let samples = try XCTUnwrap(buffer.floatChannelData)[0]
            for j in 0..<1_024 {
                samples[j] = 0.07 * sin(Float((i * 1_024 + j) % 32) * Float.pi / 16)
            }
            pipeline.append(buffer)
        }
        let status = pipeline.close()
        XCTAssertEqual(status.framesWritten, 80 * 1_024)
        XCTAssertGreaterThan(status.audioSeconds, 1.5)
        XCTAssertTrue(status.hasInputSignal)
        XCTAssertNil(status.writeError)
        let played = try AVAudioPlayer(contentsOf: url)
        XCTAssertEqual(played.duration, status.audioSeconds, accuracy: 0.05)
        XCTAssertNoThrow(try PhoneCaptureValidation.validateRecoveredFile(
            url, actualDuration: played.duration, expectedElapsed: nil
        ), "Audible crash recovery without Stop metadata must be possible")
        XCTAssertThrowsError(try PhoneCaptureValidation.validateRecoveredFile(
            url, actualDuration: played.duration, expectedElapsed: 12.0
        ), "Incomplete AAC duration must be rejected")
        XCTAssertNoThrow(try PhoneCaptureValidation.validate(
            actualDuration: played.duration,
            elapsedTime: status.audioSeconds + 0.1
        ))
    }

    func testEnginePipelineWithNoMicrophoneBuffersIsNotAcceptedAsRecording() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "what-empty-audio-engine-\(UUID().uuidString).m4a"
        )
        defer { try? FileManager.default.removeItem(at: url) }
        let format = try XCTUnwrap(AVAudioFormat(
            standardFormatWithSampleRate: 48_000, channels: 1
        ))
        let pipeline = try MicrophoneCapturePipeline(
            url: url, inputFormat: format
        )
        let state = pipeline.close()
        XCTAssertEqual(state.framesWritten, 0)
        XCTAssertThrowsError(try PhoneCaptureValidation.validate(
            actualDuration: state.audioSeconds, elapsedTime: 9.0
        ))
    }

    func testRealDurationWithAllZeroSamplesIsRejectedAsSilentMicrophone() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "what-zero-input-\(UUID().uuidString).m4a"
        )
        defer { try? FileManager.default.removeItem(at: url) }
        let format = try XCTUnwrap(AVAudioFormat(
            standardFormatWithSampleRate: 48_000, channels: 1
        ))
        let pipeline = try MicrophoneCapturePipeline(
            url: url, inputFormat: format
        )
        for _ in 0..<80 {
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(
                pcmFormat: format, frameCapacity: 1_024
            ))
            buffer.frameLength = 1_024
            for offset in 0..<1_024 {
                buffer.floatChannelData![0][offset] = 0
            }
            pipeline.append(buffer)
        }
        let status = pipeline.close()
        XCTAssertGreaterThan(status.audioSeconds, 1)
        XCTAssertFalse(status.containsActualSound)
        XCTAssertThrowsError(try PhoneCaptureValidation.validateSignal(
            peak: status.peak, audibleFrames: status.audibleFrames
        ))
        let player = try AVAudioPlayer(contentsOf: url)
        XCTAssertGreaterThan(player.duration, 1)
        XCTAssertThrowsError(try PhoneCaptureValidation.validateRecoveredFile(
            url, actualDuration: player.duration, expectedElapsed: nil
        ), "Process-killed silent audio must not become a valid voice note")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path),
                      "Invalid staged audio must remain untouched for diagnosis")
    }

    func testCaptureLatencyPercentileAndBoundedLocalHistory() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "uhwhat-test-\(UUID())"))
        defer {
            for key in defaults.dictionaryRepresentation().keys {
                defaults.removeObject(forKey: key)
            }
        }
        XCTAssertNil(CaptureLatency.p95(milliseconds: []))
        XCTAssertEqual(CaptureLatency.p95(milliseconds: [50, 120, 80, 60, 90]),
                       120)
        for i in 0..<40 {
            CaptureLatency.record(startedAt: 10, source: "test",
                                  now: 10 + Double(i) / 1000,
                                  defaults: defaults)
        }
        let samples = CaptureLatency.samples(for: "test", defaults: defaults)
        XCTAssertEqual(samples.count, 30)
        XCTAssertEqual(samples.first!, 10, accuracy: 0.01)
        XCTAssertEqual(samples.last!, 39, accuracy: 0.01)
        CaptureLatency.record(startedAt: 12, source: "test",
                              now: 10, defaults: defaults)
        XCTAssertEqual(CaptureLatency.samples(for: "test", defaults: defaults).count, 30)
    }

    func testActualSoundSamplesPassMicrophoneSignalGate() throws {
        XCTAssertThrowsError(try PhoneCaptureValidation.validateSignal(
            peak: 0, audibleFrames: 0
        ))
        XCTAssertNoThrow(try PhoneCaptureValidation.validateSignal(
            peak: 0.2, audibleFrames: 1_600
        ))
        XCTAssertNoThrow(try PhoneCaptureValidation.validateSignal(
            peak: 0.005, audibleFrames: 24
        ))
    }

    func testLexicalSearchCountShorthandAndNoFuzzyTextMatch() {
        let two = TranscriptLexicalMatcher.tokens("два")
        let fromNumbers = TranscriptLexicalMatcher.match(
            query: two, transcript: "раз 2345"
        )
        XCTAssertNotNil(fromNumbers)
        XCTAssertTrue(fromNumbers?.usedNumberAlias == true)
        XCTAssertNil(TranscriptLexicalMatcher.match(
            query: two, transcript: "договор номер 2345"
        ))
        XCTAssertNil(TranscriptLexicalMatcher.match(
            query: TranscriptLexicalMatcher.tokens("тест"),
            transcript: "это текст"
        ))
        XCTAssertNotNil(TranscriptLexicalMatcher.match(
            query: TranscriptLexicalMatcher.tokens("тест"),
            transcript: "тестовое сообщение"
        ))
        XCTAssertNotNil(TranscriptLexicalMatcher.match(
            query: TranscriptLexicalMatcher.tokens("тест"),
            transcript: "контрольный тест"
        ))
        XCTAssertNil(TranscriptLexicalMatcher.match(
            query: TranscriptLexicalMatcher.tokens("текст"),
            transcript: "тестовое сообщение"
        ))
    }

    func testCountingWordsAreExpandedOnlyInOrderedCountContext() {
        let phrase = TranscriptLexicalMatcher.tokens("раз два три четыре пять")
        let match = TranscriptLexicalMatcher.match(
            query: phrase, transcript: "раз 2345 шесть семь"
        )
        XCTAssertTrue(match?.usedNumberAlias == true)
        XCTAssertEqual(match?.score, 1.00)
        for word in ["два", "три", "четыре", "пять"] {
            XCTAssertNotNil(TranscriptLexicalMatcher.match(
                query: TranscriptLexicalMatcher.tokens(word),
                transcript: "раз 2345"
            ))
        }
        XCTAssertNil(TranscriptLexicalMatcher.match(
            query: TranscriptLexicalMatcher.tokens("четыре"),
            transcript: "номер 2345"
        ))
        XCTAssertNil(TranscriptLexicalMatcher.match(
            query: TranscriptLexicalMatcher.tokens("два"),
            transcript: "в 2026 году"
        ))
    }

    func testRussianPrefixMatchingRespectsWordBoundaries() {
        XCTAssertEqual(TranscriptLexicalMatcher.tokens("ТЁСТ, тест!"), ["тест", "тест"])
        XCTAssertNotNil(TranscriptLexicalMatcher.match(
            query: TranscriptLexicalMatcher.tokens("тест"),
            transcript: "Новая тестовая запись."
        ))
        XCTAssertNil(TranscriptLexicalMatcher.match(
            query: TranscriptLexicalMatcher.tokens("тест"),
            transcript: "проверка текста"
        ))
        XCTAssertNil(TranscriptLexicalMatcher.match(
            query: TranscriptLexicalMatcher.tokens("тест"),
            transcript: "нетестовая"
        ))
    }

    func testSearchIndexResolvesSpokenDigitsWithoutMatchingTextTypo() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-digits-retrieval-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = RecordingRepository(rootURL: root)
        try FileManager.default.createDirectory(
            at: root, withIntermediateDirectories: true
        )
        let audio = root.appendingPathComponent("source.m4a")
        try Data("fixture".utf8).write(to: audio)
        let countID = UUID(), textID = UUID(), testID = UUID()
        for id in [countID, textID, testID] {
            _ = try repository.acceptTemporaryFile(audio, metadata: [
                TransferMetadataKey.id: id.uuidString,
                TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
                TransferMetadataKey.duration: 4.0
            ])
        }
        try repository.updateTranscript("раз 2345", for: countID)
        try repository.updateTranscript("это обычный текст", for: textID)
        try repository.updateTranscript("тестовое сообщение", for: testID)
        let index = LocalSemanticSearch(
            cacheURL: root.appendingPathComponent("semantic-search-index.json")
        )
        let misleadingVector: LocalSemanticSearch.Vectorizer = { _ in [1, 0] }
        let recordings = repository.allRecordings()
        let transcripts = repository.transcripts()

        let two = index.search(
            query: "два", recordings: recordings, transcripts: transcripts,
            vectorizer: misleadingVector, modelKey: "test-vectors"
        )
        XCTAssertEqual(two.hits.map(\.id), [countID])
        XCTAssertEqual(two.hits.first?.match, .number)
        XCTAssertEqual(two.hits.first?.snippet, "раз 2345")

        let test = index.search(
            query: "тест", recordings: recordings, transcripts: transcripts,
            vectorizer: misleadingVector, modelKey: "test-vectors"
        )
        XCTAssertEqual(test.hits.map(\.id), [testID])
        XCTAssertEqual(test.hits.first?.match, .text)

        let text = index.search(
            query: "текст", recordings: recordings, transcripts: transcripts,
            vectorizer: misleadingVector, modelKey: "test-vectors"
        )
        XCTAssertEqual(text.hits.map(\.id), [textID])

        // A search index is derived; the user's original transcript remains
        // exactly as created by Speech recognition.
        XCTAssertEqual(repository.transcripts()[countID], "раз 2345")
    }

    func testAskMemoryRemovesQuestionFillerWithoutModifyingOriginalQuery() {
        XCTAssertEqual(
            GroundedMemoryAnswer.focusQuery("Где я оставил ключи?"),
            "ключи"
        )
        XCTAssertEqual(
            GroundedMemoryAnswer.focusQuery("Напомни, что я говорил про документы"),
            "документы"
        )
        XCTAssertEqual(
            GroundedMemoryAnswer.focusQuery("Что было про договор и счета?"),
            "договор счета"
        )
    }

    func testGroundedAnswerShowsOnlySavedTranscriptEvidenceAndCitesSources() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-ask-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = RecordingRepository(rootURL: root)
        let source = root.appendingPathComponent("source.m4a")
        try Data("audio".utf8).write(to: source)
        let knownID = UUID()
        let unrelatedID = UUID()
        for id in [knownID, unrelatedID] {
            _ = try repository.acceptTemporaryFile(source, metadata: [
                TransferMetadataKey.id: id.uuidString,
                TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
                TransferMetadataKey.duration: 3.0
            ])
        }
        try repository.updateTranscript("Ключи находятся на верхней полке", for: knownID)
        try repository.updateTranscript("Посмотреть фильм вечером", for: unrelatedID)
        let index = LocalSemanticSearch(
            cacheURL: root.appendingPathComponent("semantic-search-index.json")
        )

        let question = "Где я оставил ключи?"
        let answer = index.search(
            query: question,
            recordings: repository.allRecordings(),
            transcripts: repository.transcripts(),
            vectorizer: nil,
            lexicalQuery: GroundedMemoryAnswer.focusQuery(question)
        )
        let grounded = GroundedMemoryAnswer.extract(answer)
        XCTAssertEqual(grounded.evidence.count, 1)
        XCTAssertEqual(grounded.evidence.first?.recording.id, knownID)
        XCTAssertEqual(grounded.evidence.first?.snippet,
                       "Ключи находятся на верхней полке")
        XCTAssertEqual(grounded.evidence.first?.match, .text)

        let unsupported = index.search(
            query: "Мой паспорт",
            recordings: repository.allRecordings(),
            transcripts: repository.transcripts(),
            vectorizer: nil,
            lexicalQuery: GroundedMemoryAnswer.focusQuery("Где мой паспорт?")
        )
        XCTAssertFalse(GroundedMemoryAnswer.extract(unsupported).hasEvidence)
    }

    func testGroundedAnswerSuppressesWeakSemanticMatchesAndLimitsSources() {
        let recordings = (0..<5).map { idx in
            RecordingEnvelope(
                id: UUID(), createdAt: Date().addingTimeInterval(Double(idx)),
                duration: 3, fileName: "\(idx).m4a"
            )
        }
        let weakHits = recordings.map {
            SemanticSearchHit(
                recording: $0, snippet: "Weak resemblance",
                score: 0.52, match: .semantic
            )
        }
        let weakOutput = SemanticSearchOutput(
            hits: weakHits, semanticAvailable: true, indexedCount: 5
        )
        XCTAssertFalse(GroundedMemoryAnswer.extract(weakOutput).hasEvidence)
        let strongHits = recordings.map {
            SemanticSearchHit(
                recording: $0, snippet: "Original evidence",
                score: 0.88, match: .semantic
            )
        }
        let goodOutput = SemanticSearchOutput(
            hits: strongHits, semanticAvailable: true, indexedCount: 5
        )
        let ambiguous = GroundedMemoryAnswer.extract(goodOutput)
        XCTAssertFalse(ambiguous.hasEvidence,
                       "Equal semantic scores must not fabricate three answers")
        XCTAssertTrue({
            if case .ambiguousSimilarity = ambiguous.assessment { return true }
            return false
        }())
        let separatedHits = recordings.enumerated().map { index, recording in
            SemanticSearchHit(
                recording: recording, snippet: "Original evidence",
                score: [0.88, 0.77, 0.73, 0.72, 0.69][index],
                match: .semantic
            )
        }
        let separateOutput = SemanticSearchOutput(
            hits: separatedHits, semanticAvailable: true, indexedCount: 5
        )
        let answer = GroundedMemoryAnswer.extract(separateOutput)
        XCTAssertEqual(answer.evidence.count, 1)
        XCTAssertEqual(answer.evidence.first?.recording.id, recordings.first?.id)
        XCTAssertEqual(answer.assessment == .clearEvidence, true)
    }

    func testAskMemoryUsesSemanticOnOneWordButFindNotesRemainsStrict() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-ask-single-word-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let repo = RecordingRepository(rootURL: root)
        let source = root.appendingPathComponent("source.m4a")
        try Data("fixture".utf8).write(to: source)
        let id = UUID()
        _ = try repo.acceptTemporaryFile(source, metadata: [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: 4.0
        ])
        try repo.updateTranscript("Мне встретился эдельвейс", for: id)
        let search = LocalSemanticSearch(
            cacheURL: root.appendingPathComponent("semantic-search-index.json")
        )
        let embeddings: LocalSemanticSearch.Vectorizer = { text in
            if text == "цветок" { return [1.0, 0.0] }
            return [0.0, 1.0]
        }
        let termVectors: (String) -> [[Double]] = { text in
            text.contains("эдельвейс") ? [[0.96, 0.28]] : []
        }

        let find = search.search(
            query: "цветок", recordings: repo.allRecordings(),
            transcripts: repo.transcripts(), vectorizer: embeddings,
            modelKey: "synthetic-semantic", askMode: false,
            termVectorizer: termVectors
        )
        XCTAssertTrue(find.hits.isEmpty, "Find notes must stay lexical for one word")

        let ask = search.search(
            query: "цветок", recordings: repo.allRecordings(),
            transcripts: repo.transcripts(), vectorizer: embeddings,
            modelKey: "synthetic-semantic", askMode: true,
            termVectorizer: termVectors
        )
        XCTAssertEqual(ask.hits.count, 1)
        XCTAssertEqual(ask.hits.first?.recording.id, id)
        XCTAssertEqual(ask.hits.first?.match, .semantic)
        XCTAssertEqual(GroundedMemoryAnswer.extract(ask).evidence.count, 1)
    }

    func testAskMemorySemanticFindsJournalDiaryAndBeautyAestheticsPairs() throws {
        let pairs = [
            ("журнал", "дневник"),
            ("красота", "эстетика"),
            ("цветок", "эдельвейс")
        ]
        for (query, target) in pairs {
            let root = FileManager.default.temporaryDirectory
                .appendingPathComponent("what-ask-pair-\(UUID().uuidString)")
            defer { try? FileManager.default.removeItem(at: root) }
            let repository = RecordingRepository(rootURL: root)
            let source = root.appendingPathComponent("note.m4a")
            try Data("test".utf8).write(to: source)
            let id = UUID()
            _ = try repository.acceptTemporaryFile(source, metadata: [
                TransferMetadataKey.id: id.uuidString,
                TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
                TransferMetadataKey.duration: 2.5
            ])
            try repository.updateTranscript("Записать \(target)", for: id)
            let index = LocalSemanticSearch(
                cacheURL: root.appendingPathComponent("semantic-search-index.json")
            )
            let vectorizer: LocalSemanticSearch.Vectorizer = { text in
                text == query ? [1.0, 0.0] : [0.0, 1.0]
            }
            let found = index.search(
                query: query, recordings: repository.allRecordings(),
                transcripts: repository.transcripts(), vectorizer: vectorizer,
                modelKey: "synthetic-pairs", askMode: true,
                termVectorizer: { text in
                    text.contains(target) ? [[0.96, 0.28]] : []
                }
            )
            XCTAssertEqual(found.hits.map(\.id), [id])
            XCTAssertEqual(found.hits.first?.match, .semantic)
            XCTAssertEqual(GroundedMemoryAnswer.extract(found).evidence.count, 1)
        }
    }

    func testAskMemoryWithoutInstalledModelDoesNotInventSynonyms() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-ask-no-assets-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let repo = RecordingRepository(rootURL: root)
        try FileManager.default.createDirectory(
            at: root, withIntermediateDirectories: true
        )
        let source = root.appendingPathComponent("source.m4a")
        try Data("fixture".utf8).write(to: source)
        let id = UUID()
        _ = try repo.acceptTemporaryFile(source, metadata: [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: 2.0
        ])
        try repo.updateTranscript("Мой дневник", for: id)
        let out = LocalSemanticSearch(
            cacheURL: root.appendingPathComponent("semantic-search-index.json")
        ).search(
            query: "журнал", recordings: repo.allRecordings(),
            transcripts: repo.transcripts(), vectorizer: nil, askMode: true
        )
        XCTAssertFalse(out.semanticAvailable)
        XCTAssertFalse(GroundedMemoryAnswer.extract(out).hasEvidence)
    }

    func testPhysicalAppleRussianSemanticProbe() throws {
        let embedder = AppleLocalEmbedder(query: "цветок")
        guard embedder.isAvailable else {
            print("WHAT_RUSSIAN_MODEL_UNAVAILABLE")
            throw XCTSkip("Russian contextual embedding assets are not installed")
        }
        for (query, concept) in [
            ("цветок", "эдельвейс"),
            ("журнал", "дневник"),
            ("красота", "эстетика")
        ] {
            guard let q = embedder.vector(for: query) else {
                print("WHAT_VECTOR_UNAVAILABLE query=" + query)
                continue
            }
            let passage = embedder.vector(for: "Мне встретился " + concept)
            let mean = passage.flatMap {
                LocalSemanticSearch.cosine(q, $0)
            } ?? -1
            let terms = embedder.termVectors(for: "Мне встретился " + concept)
                .compactMap { LocalSemanticSearch.cosine(q, $0) }
            print(
                "WHAT_RUSSIAN_PAIR query=" + query +
                    " concept=" + concept +
                    " mean=" + String(format: "%.4f", mean) +
                    " tokenMax=" + String(format: "%.4f", terms.max() ?? -1)
            )
        }
    }


    func testBundledRussianGraphFindsConceptsAndRejectsControls() throws {
        guard let engine = RussianConceptSearch() else {
            throw XCTSkip("Release intentionally excludes the research-only RuWordNet corpus")
        }
        let examples: [(String, String, Double)] = [
            ("цветок", "Раз 2345 эдельвейс 6789 10", 0.8),
            ("журнал", "Мне нужен читательский дневник", 0.8),
            ("красота", "Упор на красоту и эстетику", 1.0),
            ("птица", "Сегодня увидел воробья", 0.8),
            ("рыба", "В пруду живёт карась", 0.8),
            ("мебель", "Купил диван", 0.8),
            ("музыкальный инструмент", "У меня есть скрипка", 0.8)
        ]
        for (query, transcript, expected) in examples {
            let actual = engine.score(query: query, passage: transcript)
            XCTAssertNotNil(actual, "\(query) should match its target")
            XCTAssertGreaterThanOrEqual(actual ?? 0, expected)
        }
        for term in [
            "парашют", "зубочистка", "динозавр", "извержение",
            "ракета", "метеорит", "картофель"
        ] {
            XCTAssertNil(
                engine.score(query: term, passage: "Новая тетрадочка"),
                "Concept graph should not match generic ancestor for \(term)"
            )
        }
        XCTAssertNil(
            engine.score(query: "тест", passage: "Только текст"),
            "Fuzzy typo matching must remain disabled"
        )
    }

    func testAskMemoryReturnsOfflineOntologySourcesNotAppleVectorNoise() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-ontology-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = RecordingRepository(rootURL: root)
        try FileManager.default.createDirectory(
            at: root, withIntermediateDirectories: true
        )
        let audio = root.appendingPathComponent("source.m4a")
        try Data("fixture".utf8).write(to: audio)
        let flowerID = UUID(), diaryID = UUID(), unrelatedID = UUID()
        for id in [flowerID, diaryID, unrelatedID] {
            _ = try repository.acceptTemporaryFile(audio, metadata: [
                TransferMetadataKey.id: id.uuidString,
                TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
                TransferMetadataKey.duration: 3.5
            ])
        }
        try repository.updateTranscript("Раз 2345 эдельвейс 6789", for: flowerID)
        try repository.updateTranscript("Читательский дневник", for: diaryID)
        try repository.updateTranscript("Завтра поеду на автобусе", for: unrelatedID)
        guard let ontology = RussianConceptSearch() else {
            throw XCTSkip("Release intentionally excludes the research-only RuWordNet corpus")
        }
        let index = LocalSemanticSearch(
            cacheURL: root.appendingPathComponent("semantic-search-index.json")
        )
        let recordings = repository.allRecordings()
        let transcripts = repository.transcripts()
        for (query, expected) in [("цветок", flowerID), ("журнал", diaryID)] {
            let output = index.search(
                query: query, recordings: recordings, transcripts: transcripts,
                vectorizer: nil, askMode: true,
                conceptMatcher: { q, passage in
                    ontology.score(query: q, passage: passage)
                }
            )
            XCTAssertTrue(
                output.hits.contains(where: {
                    $0.recording.id == expected && $0.match == .concept
                }), "Ask memory should retrieve source with offline concept graph"
            )
            XCTAssertTrue(GroundedMemoryAnswer.extract(output).evidence
                .contains(where: { $0.recording.id == expected }))
        }
        let strict = index.search(
            query: "цветок", recordings: recordings, transcripts: transcripts,
            vectorizer: nil, askMode: false,
            conceptMatcher: { q, passage in
                ontology.score(query: q, passage: passage)
            }
        )
        XCTAssertTrue(strict.hits.isEmpty, "Find notes must stay strict")
    }

    func testWatchCaptureNeverAcceptsHeaderOnlyOrTruncatedAudio() {
        XCTAssertFalse(WatchCaptureValidation.isPlausibleAudio(
            bytes: 12, decodedDuration: 0.06, expectedDuration: 6.26
        ))
        XCTAssertFalse(WatchCaptureValidation.isPlausibleAudio(
            bytes: 1_000, decodedDuration: 0.06, expectedDuration: 6.26
        ))
        XCTAssertFalse(WatchCaptureValidation.isPlausibleAudio(
            bytes: 10_000, decodedDuration: 1.0, expectedDuration: 8.0
        ))
        XCTAssertFalse(WatchCaptureValidation.isPlausibleAudio(
            bytes: 4_000, decodedDuration: .nan, expectedDuration: 3
        ))
        XCTAssertTrue(WatchCaptureValidation.isPlausibleAudio(
            bytes: 4_000, decodedDuration: 3.8, expectedDuration: 4.0
        ))
        XCTAssertTrue(WatchCaptureValidation.isPlausibleAudio(
            bytes: 1_500, decodedDuration: 0.40, expectedDuration: 0.45
        ))
    }

    func testPhysicalWatch124msTruncationIsRejectedEvenWhenFileIsLarge() {
        // Physical Watch SE QA 19.10.2026: AAC 25_247 bytes decodes to
        // 0.124s despite an intended ~7s capture. Size alone is insufficient.
        XCTAssertFalse(WatchCaptureValidation.isPlausibleAudio(
            bytes: 25_247, decodedDuration: 0.124, expectedDuration: 7.0
        ))
        // Do not regress valid AAC in the same physical environment.
        XCTAssertTrue(WatchCaptureValidation.isPlausibleAudio(
            bytes: 46_000, decodedDuration: 7.612, expectedDuration: 7.35
        ))
    }

    func testWatchCrashRecoveryRetainsOnlyDurableUnqueuedAudio() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-watch-recovery-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )
        let recoveredID = UUID()
        let knownID = UUID()
        let invalidID = UUID()
        for (id, byteCount) in [
            (recoveredID, 2_000), (knownID, 2_000), (invalidID, 10)
        ] {
            try Data(repeating: 42, count: byteCount).write(
                to: directory.appendingPathComponent("\(id.uuidString).m4a")
            )
        }
        try Data(repeating: 7, count: 5_000).write(
            to: directory.appendingPathComponent("queue.json")
        )
        let found = WatchQueueRecovery.recover(
            from: directory,
            knownIDs: [knownID],
            decodedDuration: { url in
                url.lastPathComponent.hasPrefix(invalidID.uuidString) ? 0.01 : 5.0
            }
        )
        XCTAssertEqual(found.map(\.id), [recoveredID])
        XCTAssertEqual(found.first?.duration, 5)
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: directory.appendingPathComponent("\(invalidID.uuidString).m4a").path
        ), "Recovery must never erase a potentially recoverable recording")
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: directory.appendingPathComponent("\(knownID.uuidString).m4a").path
        ), "Recovery must not touch already-queued original audio")
    }

}
