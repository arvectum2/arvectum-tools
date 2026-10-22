import AVFoundation
import Foundation
import XCTest
@testable import WhatIOS

/// Simulates a process dying after queue ACK commit but before audio deletion.
private final class AckAudioDeletionFailureFileManager: FileManager {
    override func removeItem(at URL: URL) throws {
        if URL.pathExtension == "m4a" {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteNoPermissionError)
        }
        try super.removeItem(at: URL)
    }
}

final class WatchA2ReliabilityTests: XCTestCase {
    private func envelope(_ id: UUID = UUID()) -> RecordingEnvelope {
        RecordingEnvelope(
            id: id, createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            duration: 1.5, fileName: "\(id.uuidString).m4a"
        )
    }

    private func temporaryDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("uhvat-a2-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: dir, withIntermediateDirectories: true
        )
        return dir
    }

    /// The same file importer called by WCSession.didReceive(file:) must
    /// commit playable AAC before acknowledging, survive a duplicate UUID,
    /// and honor a durable deletion marker. Real device filesystem/AVAudio
    /// APIs are exercised, but this does not simulate the Watch radio link.
    func testBackgroundReceiverStorageGateOnPhysicalDevice() throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let id = UUID()
        let original = root.appendingPathComponent("watch-original.m4a")
        let format = try XCTUnwrap(AVAudioFormat(
            standardFormatWithSampleRate: 48_000, channels: 1
        ))
        let pipeline = try MicrophoneCapturePipeline(url: original, inputFormat: format)
        for frame in 0..<110 {
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(
                pcmFormat: format, frameCapacity: 1_024
            ))
            buffer.frameLength = 1_024
            let data = try XCTUnwrap(buffer.floatChannelData)[0]
            for i in 0..<1_024 {
                data[i] = 0.04 * sin(Float((frame * 1_024 + i) % 32) * Float.pi / 16)
            }
            pipeline.append(buffer)
        }
        let result = pipeline.close()
        XCTAssertNil(result.writeError)
        let duration = try WatchDeliveredAudioValidation.validate(
            original, expectedDuration: result.audioSeconds
        )
        let repository = RecordingRepository(
            rootURL: root.appendingPathComponent("phone", isDirectory: true)
        )
        let metadata: [String: Any] = [
            TransferMetadataKey.type: TransferMetadataKey.recording,
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: duration
        ]
        // A non-recording userInfo or missing duration never yields an ACK.
        XCTAssertNil(try WatchInboundFileReceiver.accept(
            original, metadata: [:], into: repository
        ))
        var wrongType = metadata
        wrongType[TransferMetadataKey.type] = TransferMetadataKey.syncRequest
        XCTAssertNil(try WatchInboundFileReceiver.accept(
            original, metadata: wrongType, into: repository
        ))
        var wrongDuration = metadata
        wrongDuration[TransferMetadataKey.duration] = duration * 3
        XCTAssertThrowsError(try WatchInboundFileReceiver.accept(
            original, metadata: wrongDuration, into: repository
        ))
        let damaged = root.appendingPathComponent("bad-watch-original.m4a")
        try Data(repeating: 0, count: 4_096).write(to: damaged)
        XCTAssertThrowsError(try WatchInboundFileReceiver.accept(
            damaged, metadata: metadata, into: repository
        ))
        XCTAssertTrue(repository.allRecordings().isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: original.path))

        // A receiver ACK is now justified because the physical iPhone has
        // a playable, durably indexed AAC. The Watch original remains intact.
        let first = try XCTUnwrap(WatchInboundFileReceiver.accept(
            original, metadata: metadata, into: repository
        ))
        XCTAssertEqual(first.id, id)
        XCTAssertEqual(repository.allRecordings().map(\.id), [id])
        XCTAssertTrue(FileManager.default.fileExists(atPath: original.path))
        let second = try XCTUnwrap(WatchInboundFileReceiver.accept(
            original, metadata: metadata, into: repository
        ))
        XCTAssertEqual(second.id, id)
        XCTAssertEqual(repository.allRecordings().count, 1)
        let stored = try XCTUnwrap(repository.allRecordings().first)
        XCTAssertEqual(try Data(contentsOf: original),
                       try Data(contentsOf: repository.audioURL(for: stored)))

        // A queued retry after deletion receives an ACK but may never
        // resurrect that recording, even across a new repository instance.
        try repository.deleteRecording(id)
        let reopened = RecordingRepository(
            rootURL: root.appendingPathComponent("phone", isDirectory: true)
        )
        let late = try XCTUnwrap(WatchInboundFileReceiver.accept(
            original, metadata: metadata, into: reopened
        ))
        if case .previouslyDeleted(let excludedID) = late {
            XCTAssertEqual(excludedID, id)
        } else {
            XCTFail("Late Watch resend must not restore deleted data")
        }
        XCTAssertTrue(reopened.allRecordings().isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: original.path))
    }

    func testLostACKRealisticAACResendPreservesSameUUIDAndDeletesOnlyAfterACK() throws {
        let dir = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let outbound = dir.appendingPathComponent("outbound", isDirectory: true)
        let phone = dir.appendingPathComponent("phone", isDirectory: true)
        try FileManager.default.createDirectory(at: outbound,
                                                withIntermediateDirectories: true)
        let id = UUID()
        let original = outbound.appendingPathComponent("\(id.uuidString).m4a")
        let format = try XCTUnwrap(AVAudioFormat(
            standardFormatWithSampleRate: 48_000, channels: 1
        ))
        let pipeline = try MicrophoneCapturePipeline(url: original, inputFormat: format)
        for frame in 0..<110 {
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(
                pcmFormat: format, frameCapacity: 1024
            ))
            buffer.frameLength = 1024
            let samples = try XCTUnwrap(buffer.floatChannelData)[0]
            for i in 0..<1024 {
                samples[i] = 0.04 * sin(Float((frame * 1024 + i) % 32) * Float.pi / 16)
            }
            pipeline.append(buffer)
        }
        let result = pipeline.close()
        XCTAssertNil(result.writeError)
        let duration = try WatchDeliveredAudioValidation.validate(
            original, expectedDuration: result.audioSeconds
        )
        let entry = RecordingEnvelope(
            id: id, createdAt: Date(), duration: duration,
            fileName: "\(id.uuidString).m4a"
        )
        let index = outbound.appendingPathComponent("queue.json")
        var queue = [RecordingEnvelope]()
        try WatchDurableQueue.enqueue(entry, into: &queue, at: index)
        let repository = RecordingRepository(rootURL: phone)
        let metadata: [String: Any] = [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: entry.createdAt.timeIntervalSince1970,
            TransferMetadataKey.duration: duration
        ]
        let first = try repository.acceptTemporaryFile(original, metadata: metadata)
        XCTAssertEqual(first.id, id)
        // Suppress the first receiver ACK. The original MUST stay queued.
        XCTAssertEqual(queue.map(\.id), [id])
        XCTAssertTrue(FileManager.default.fileExists(atPath: original.path))
        XCTAssertEqual(try JSONDecoder().decode([RecordingEnvelope].self,
            from: Data(contentsOf: index)).map(\.id), [id])

        // Replay actual AAC bytes with unchanged UUID through the same phone
        // storage path; the second ACK must not create a second note.
        let second = try repository.acceptTemporaryFile(original, metadata: metadata)
        XCTAssertEqual(second.id, id)
        XCTAssertEqual(repository.allRecordings().map(\.id), [id])
        let stored = try XCTUnwrap(repository.allRecordings().first)
        XCTAssertEqual(try Data(contentsOf: original),
                       try Data(contentsOf: repository.audioURL(for: stored)))
        XCTAssertTrue(try WatchAcknowledgementJournal.acknowledge(
            id, in: &queue, at: index, outbound: outbound
        ))
        XCTAssertTrue(queue.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: original.path))
        XCTAssertEqual(repository.allRecordings().map(\.id), [id])
        XCTAssertFalse(try WatchAcknowledgementJournal.acknowledge(
            id, in: &queue, at: index, outbound: outbound
        ))
    }

    func testBatchQueueAndACKSurviveRelaunchWithoutDuplicates() throws {
        let dir = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let index = dir.appendingPathComponent("queue.json")
        let originals = (0..<3).map { _ in envelope() }
        var queue: [RecordingEnvelope] = []
        for entry in originals {
            try Data(repeating: 42, count: 2_048).write(
                to: dir.appendingPathComponent(entry.fileName)
            )
            try WatchDurableQueue.enqueue(entry, into: &queue, at: index)
        }
        try WatchDurableQueue.enqueue(originals[0], into: &queue, at: index)
        XCTAssertEqual(queue.count, 3)

        let acknowledged = try WatchDurableQueue.acknowledge(
            originals[1].id, in: &queue, at: index
        )
        XCTAssertEqual(acknowledged?.id, originals[1].id)
        // The disk-store operation does not delete audio; caller may only
        // remove its original file after the durable ACK commit.
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: dir.appendingPathComponent(originals[1].fileName).path
        ))
        let reloaded = try JSONDecoder().decode(
            [RecordingEnvelope].self, from: Data(contentsOf: index)
        )
        XCTAssertEqual(Set(reloaded.map(\.id)), Set([originals[0].id, originals[2].id]))
        XCTAssertEqual(reloaded.count, 2)
        XCTAssertNil(try WatchDurableQueue.acknowledge(
            originals[1].id, in: &queue, at: index
        ))
    }

    func testTwentyFourOfflineWatchQueueItemsSurviveRelaunchAndOutOfOrderACK() throws {
        // Bounded deterministic storage stress: 24 durable UUIDs, two
        // independent reloads, replayed ACKs, original audio retained until
        // each unique persisted ACK. No physical radio toggles.
        let dir = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let index = dir.appendingPathComponent("queue.json")
        let originals = (0..<24).map { _ in envelope() }
        var pending: [RecordingEnvelope] = []
        for (sequence, item) in originals.enumerated() {
            try Data(repeating: UInt8(sequence + 1), count: 4_096)
                .write(to: dir.appendingPathComponent(item.fileName))
            try WatchDurableQueue.enqueue(item, into: &pending, at: index)
        }
        XCTAssertEqual(pending.count, 24)
        // A second process reads the exact persisted order, and a duplicate
        // live callback cannot create another queue row for the same UUID.
        var reopened = try JSONDecoder().decode(
            [RecordingEnvelope].self, from: Data(contentsOf: index)
        )
        reopened = WatchDurableQueue.mergeRestored(
            disk: reopened, memory: [originals[2], originals[9]]
        )
        XCTAssertEqual(reopened.map(\.id), originals.map(\.id))
        // Simulate delayed ACKs for every other note arriving in reverse
        // order while all unacknowledged original files stay on disk.
        for i in stride(from: 22, through: 0, by: -2) {
            let entry = originals[i]
            XCTAssertTrue(try WatchAcknowledgementJournal.acknowledge(
                entry.id, in: &reopened, at: index, outbound: dir
            ))
            XCTAssertFalse(try WatchAcknowledgementJournal.acknowledge(
                entry.id, in: &reopened, at: index, outbound: dir
            ))
            XCTAssertFalse(FileManager.default.fileExists(
                atPath: dir.appendingPathComponent(entry.fileName).path
            ))
        }
        let rest = try JSONDecoder().decode(
            [RecordingEnvelope].self, from: Data(contentsOf: index)
        )
        XCTAssertEqual(rest.count, 12)
        XCTAssertEqual(Set(rest.map(\.id)),
                       Set(stride(from: 1, through: 23, by: 2).map { originals[$0].id }))
        for item in rest {
            XCTAssertTrue(FileManager.default.fileExists(
                atPath: dir.appendingPathComponent(item.fileName).path
            ))
        }
        // Simulated relaunch reconciles journal before orphan detection.
        var rebooted = rest
        try WatchAcknowledgementJournal.reconcile(
            queue: &rebooted, at: index, outbound: dir
        )
        XCTAssertEqual(rebooted.count, 12)
        for item in rebooted.reversed() {
            XCTAssertTrue(try WatchAcknowledgementJournal.acknowledge(
                item.id, in: &rebooted, at: index, outbound: dir
            ))
        }
        XCTAssertTrue(rebooted.isEmpty)
        XCTAssertTrue(try JSONDecoder().decode([RecordingEnvelope].self,
            from: Data(contentsOf: index)).isEmpty)
        XCTAssertTrue(WatchAcknowledgementJournal.pendingIDs(in: dir).isEmpty)
        for item in originals {
            XCTAssertFalse(FileManager.default.fileExists(
                atPath: dir.appendingPathComponent(item.fileName).path
            ))
        }
    }

    func testImmediateAndBackgroundACKOrderLeavesExactlyOnePendingNote() throws {
        let dir = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let index = dir.appendingPathComponent("queue.json")
        let first = envelope(), second = envelope()
        var queue: [RecordingEnvelope] = []
        for item in [first, second] {
            try Data(repeating: 0x55, count: 2_048).write(
                to: dir.appendingPathComponent(item.fileName)
            )
            try WatchDurableQueue.enqueue(item, into: &queue, at: index)
        }
        XCTAssertTrue(try WatchAcknowledgementJournal.acknowledge(
            first.id, in: &queue, at: index, outbound: dir
        ))
        // A background ACK for the same UUID arriving after the live reply
        // cannot touch a later recording's queue entry or source file.
        XCTAssertFalse(try WatchAcknowledgementJournal.acknowledge(
            first.id, in: &queue, at: index, outbound: dir
        ))
        XCTAssertEqual(queue.map(\.id), [second.id])
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: dir.appendingPathComponent(first.fileName).path
        ))
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: dir.appendingPathComponent(second.fileName).path
        ))
        XCTAssertTrue(WatchAcknowledgementJournal.pendingIDs(in: dir).isEmpty)
        XCTAssertEqual(try JSONDecoder().decode([RecordingEnvelope].self,
            from: Data(contentsOf: index)).map(\.id), [second.id])
    }

    func testCrashAfterACKQueueCommitBeforeAudioDeletionNeverResurrectsOrphan() throws {
        let dir = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let index = dir.appendingPathComponent("queue.json")
        let recording = envelope()
        let audio = dir.appendingPathComponent(recording.fileName)
        try Data(repeating: 0x55, count: 2_048).write(to: audio)
        var queue: [RecordingEnvelope] = []
        try WatchDurableQueue.enqueue(recording, into: &queue, at: index)
        XCTAssertTrue(try WatchAcknowledgementJournal.acknowledge(
            recording.id, in: &queue, at: index, outbound: dir,
            fileManager: AckAudioDeletionFailureFileManager()
        ))
        XCTAssertTrue(queue.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: audio.path))
        XCTAssertEqual(WatchAcknowledgementJournal.pendingIDs(in: dir), [recording.id])

        // Simulate reboot: a finalized source exists despite a persisted ACK.
        // Recovery scanner must not treat it as a new unsent recording.
        let known = WatchAcknowledgementJournal.pendingIDs(in: dir)
        let recovered = WatchQueueRecovery.recover(
            from: dir, knownIDs: known,
            decodedDuration: { _ in 1.5 }
        )
        XCTAssertTrue(recovered.isEmpty)
        var rebooted = try JSONDecoder().decode([RecordingEnvelope].self,
            from: Data(contentsOf: index))
        try WatchAcknowledgementJournal.reconcile(
            queue: &rebooted, at: index, outbound: dir
        )
        XCTAssertTrue(rebooted.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: audio.path))
        XCTAssertTrue(WatchAcknowledgementJournal.pendingIDs(in: dir).isEmpty)
    }

    func testACKIndexWriteFailurePreservesOriginalAndReconcilesAfterUnlock() throws {
        let dir = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let index = dir.appendingPathComponent("queue.json")
        let recording = envelope()
        let audio = dir.appendingPathComponent(recording.fileName)
        try Data(repeating: 0x33, count: 2_048).write(to: audio)
        var queue: [RecordingEnvelope] = []
        try WatchDurableQueue.enqueue(recording, into: &queue, at: index)

        // Block the index commit after the ACK marker has been persisted.
        try FileManager.default.removeItem(at: index)
        try FileManager.default.createDirectory(at: index, withIntermediateDirectories: true)
        XCTAssertThrowsError(try WatchAcknowledgementJournal.acknowledge(
            recording.id, in: &queue, at: index, outbound: dir
        ))
        XCTAssertEqual(queue.map(\.id), [recording.id])
        XCTAssertTrue(FileManager.default.fileExists(atPath: audio.path))
        XCTAssertEqual(WatchAcknowledgementJournal.pendingIDs(in: dir), [recording.id])
        // Once storage becomes writable, reload original pending queue and
        // complete the ACK before orphan discovery or another transfer.
        try FileManager.default.removeItem(at: index)
        try JSONEncoder().encode(queue).write(to: index, options: .atomic)
        var rebooted = try JSONDecoder().decode([RecordingEnvelope].self,
            from: Data(contentsOf: index))
        try WatchAcknowledgementJournal.reconcile(
            queue: &rebooted, at: index, outbound: dir
        )
        XCTAssertTrue(rebooted.isEmpty)
        XCTAssertTrue(WatchAcknowledgementJournal.pendingIDs(in: dir).isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: audio.path))
        XCTAssertTrue(try JSONDecoder().decode([RecordingEnvelope].self,
            from: Data(contentsOf: index)).isEmpty)
    }

    func testEnqueueFailureDoesNotChangeQueueOrEraseAudio() throws {
        let dir = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let blocked = dir.appendingPathComponent("queue.json", isDirectory: true)
        try FileManager.default.createDirectory(
            at: blocked, withIntermediateDirectories: true
        )
        let entry = envelope()
        let audio = dir.appendingPathComponent(entry.fileName)
        try Data(repeating: 32, count: 1_800).write(to: audio)
        var queue: [RecordingEnvelope] = []
        XCTAssertThrowsError(try WatchDurableQueue.enqueue(
            entry, into: &queue, at: blocked
        ))
        XCTAssertTrue(queue.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: audio.path))
    }

    func testACKIndexFailureKeepsQueueAndOriginalAudio() throws {
        let dir = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let index = dir.appendingPathComponent("queue.json")
        let entry = envelope()
        let audio = dir.appendingPathComponent(entry.fileName)
        try Data(repeating: 8, count: 2_048).write(to: audio)
        var queue: [RecordingEnvelope] = []
        try WatchDurableQueue.enqueue(entry, into: &queue, at: index)

        // Simulate a failed index write: no successful transition to an
        // acknowledged state is allowed even if an ACK was received.
        try FileManager.default.removeItem(at: index)
        try FileManager.default.createDirectory(
            at: index, withIntermediateDirectories: true
        )
        XCTAssertThrowsError(try WatchDurableQueue.acknowledge(
            entry.id, in: &queue, at: index
        ))
        XCTAssertEqual(queue.map(\.id), [entry.id])
        XCTAssertTrue(FileManager.default.fileExists(atPath: audio.path))
    }

    func testCrashRecoveryCommitsBeforeMakingOrphansAvailable() throws {
        let dir = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let index = dir.appendingPathComponent("queue.json")
        let first = envelope(), second = envelope()
        var queue = [first]
        let recovered = [first, second]
        try WatchDurableQueue.recover(recovered, into: &queue, at: index)
        XCTAssertEqual(queue.map(\.id), [first.id, second.id])
        XCTAssertEqual(try JSONDecoder().decode(
            [RecordingEnvelope].self, from: Data(contentsOf: index)
        ).map(\.id), [first.id, second.id])
        try WatchDurableQueue.recover(recovered, into: &queue, at: index)
        XCTAssertEqual(queue.count, 2)
    }

    func testInvalidWatchDeliveryIsRejectedBeforeACK() throws {
        let dir = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let fake = dir.appendingPathComponent("corrupt.m4a")
        try Data(repeating: 0, count: 4_096).write(to: fake)
        XCTAssertThrowsError(try WatchDeliveredAudioValidation.validate(
            fake, expectedDuration: 2
        ))
        XCTAssertThrowsError(try WatchDeliveredAudioValidation.validate(
            fake, expectedDuration: .nan
        ))
    }

    func testPlayableAACIsAcceptedAndGrosslyTruncatedTrackIsRejected() throws {
        let dir = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let audio = dir.appendingPathComponent("valid.m4a")
        let format = try XCTUnwrap(AVAudioFormat(
            standardFormatWithSampleRate: 48_000, channels: 1
        ))
        let pipeline = try MicrophoneCapturePipeline(
            url: audio, inputFormat: format
        )
        for frameIndex in 0..<70 {
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(
                pcmFormat: format, frameCapacity: 1_024
            ))
            buffer.frameLength = 1_024
            let samples = try XCTUnwrap(buffer.floatChannelData)[0]
            for i in 0..<1_024 {
                samples[i] = 0.08 * sin(
                    Float((frameIndex * 1_024 + i) % 32) * Float.pi / 16
                )
            }
            pipeline.append(buffer)
        }
        let state = pipeline.close()
        XCTAssertNil(state.writeError)
        let duration = try WatchDeliveredAudioValidation.validate(
            audio, expectedDuration: state.audioSeconds
        )
        XCTAssertGreaterThan(duration, 1.0)
        XCTAssertThrowsError(try WatchDeliveredAudioValidation.validate(
            audio, expectedDuration: duration * 3
        ))
    }

    func testLatencyPercentileIgnoresInvalidSamples() {
        XCTAssertNil(CaptureLatency.p95(milliseconds: [.nan, -.infinity]))
        XCTAssertEqual(CaptureLatency.p95(milliseconds: [120, 80, 250, 110]), 250)
    }
    func testWatchRecoveryRequestMetadataIsDistinctFromAudioAndAck() {
        XCTAssertNotEqual(TransferMetadataKey.syncRequest, TransferMetadataKey.recording)
        XCTAssertNotEqual(TransferMetadataKey.syncRequest, TransferMetadataKey.acknowledgement)
    }

    func testRestoringQueueAfterRebootDoesNotDuplicatePendingUUIDs() {
        let first = RecordingEnvelope(id: UUID(), createdAt: Date(), duration: 2, fileName: "a.m4a")
        let second = RecordingEnvelope(id: UUID(), createdAt: Date(), duration: 4, fileName: "b.m4a")
        let restored = WatchDurableQueue.mergeRestored(disk: [first], memory: [first, second])
        XCTAssertEqual(restored.map(\.id), [first.id, second.id])
    }

}
