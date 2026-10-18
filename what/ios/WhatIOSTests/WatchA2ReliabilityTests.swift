import AVFoundation
import Foundation
import XCTest
@testable import WhatIOS

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
