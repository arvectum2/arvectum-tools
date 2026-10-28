import AVFoundation
import XCTest
@testable import WhatIOS

final class AudioFileImportTests: XCTestCase {
    private func disposableRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-files-import-test-\(UUID())", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func writeAudibleWAV(_ destination: URL) throws {
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1))
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true
        ]
        let file = try AVAudioFile(forWriting: destination, settings: settings)
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 88_200))
        buffer.frameLength = 88_200
        let channel = try XCTUnwrap(buffer.floatChannelData)[0]
        for i in 0..<Int(buffer.frameLength) {
            channel[i] = 0.05 * sin(Float(i) * 2 * Float.pi * 440 / 44_100)
        }
        try file.write(from: buffer)
    }

    func testWAVConvertsToPrivateM4AAndSourceIsNeverModified() async throws {
        let root = try disposableRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("voice-memo.wav")
        try writeAudibleWAV(source)
        let original = try Data(contentsOf: source)
        let prepared = try await AudioFileImportService.prepare(source)
        defer { prepared.cleanUp() }
        XCTAssertNotEqual(prepared.url, source)
        XCTAssertEqual(prepared.url.pathExtension.lowercased(), "m4a")
        XCTAssertGreaterThan(prepared.duration, 1.5)
        let repo = RecordingRepository(rootURL: root.appendingPathComponent("db"))
        let id = UUID()
        let result = try repo.acceptTemporaryFile(prepared.url, metadata: [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: prepared.duration
        ])
        guard case .stored(let recording) = result else { return XCTFail("Expected stored audio") }
        XCTAssertEqual(recording.id, id)
        XCTAssertEqual(repo.allRecordings().count, 1)
        XCTAssertTrue(repo.audioExists(for: recording))
        XCTAssertNoThrow(try AVAudioPlayer(contentsOf: repo.audioURL(for: recording)))
        XCTAssertEqual(try Data(contentsOf: source), original)
        prepared.cleanUp()
        XCTAssertFalse(FileManager.default.fileExists(atPath: prepared.url.path))
        XCTAssertTrue(repo.audioExists(for: recording))
    }

    func testExistingM4AIsCopiedByteForByteWithoutChangingSource() async throws {
        let root = try disposableRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("voice-from-files.m4a")
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1))
        let pipeline = try MicrophoneCapturePipeline(url: source, inputFormat: format)
        for frame in 0..<110 {
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024))
            buffer.frameLength = 1024
            let channel = try XCTUnwrap(buffer.floatChannelData)[0]
            for i in 0..<1024 {
                channel[i] = 0.06 * sin(Float(frame * 1024 + i) * Float.pi / 16)
            }
            pipeline.append(buffer)
        }
        let finished = pipeline.close()
        XCTAssertNil(finished.writeError)
        let original = try Data(contentsOf: source)
        let prepared = try await AudioFileImportService.prepare(source)
        XCTAssertEqual(prepared.url, source)
        XCTAssertNil(prepared.disposableURL)
        let repo = RecordingRepository(rootURL: root.appendingPathComponent("db"))
        let id = UUID()
        let accepted = try repo.acceptTemporaryFile(prepared.url, metadata: [
            TransferMetadataKey.id: id.uuidString,
            TransferMetadataKey.createdAt: Date().timeIntervalSince1970,
            TransferMetadataKey.duration: prepared.duration
        ])
        guard case .stored(let recording) = accepted else { return XCTFail("Missing recording") }
        XCTAssertEqual(try Data(contentsOf: repo.audioURL(for: recording)), original)
        XCTAssertEqual(try Data(contentsOf: source), original)
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
    }

    func testInvalidAudioNeverCreatesAnIndexedNoteAndKeepsSource() async throws {
        let root = try disposableRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let fake = root.appendingPathComponent("not-a-real-recording.m4a")
        let bytes = Data("this is not an audio stream".utf8)
        try bytes.write(to: fake)
        let repo = RecordingRepository(rootURL: root.appendingPathComponent("db"))
        do {
            _ = try await AudioFileImportService.prepare(fake)
            XCTFail("Corrupt audio must be rejected")
        } catch { }
        XCTAssertEqual(repo.allRecordings().count, 0)
        XCTAssertEqual(try Data(contentsOf: fake), bytes)
    }
}
