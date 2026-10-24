import AVFoundation
import XCTest
@testable import WhatIOS

private final class DenyPhoneCaptureProtection: FileManager {
    override func setAttributes(_ attributes: [FileAttributeKey: Any],
                                ofItemAtPath path: String) throws {
        if path.hasSuffix(".m4a") { throw CocoaError(.fileWriteNoPermission) }
        try super.setAttributes(attributes, ofItemAtPath: path)
    }
}
private struct PhonePendingFixture: Codable {
    let id: UUID
    let createdAt: Date
    let expectedElapsed: TimeInterval?
}
final class PhoneCaptureStorageTests: XCTestCase {
    private func root() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(
            "what-phone-physical-\(UUID())", isDirectory: true)
    }
    private func protected(_ path: URL, file: StaticString = #filePath,
                           line: UInt = #line) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: path.path)
        XCTAssertEqual(attributes[.protectionKey] as? FileProtectionType,
                       .completeUntilFirstUserAuthentication,
                       path.lastPathComponent, file: file, line: line)
    }
    private func writeRealAAC(to url: URL) throws -> Double {
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 48_000,
                                                 channels: 1))
        let pipeline = try MicrophoneCapturePipeline(url: url, inputFormat: format)
        for frame in 0..<110 {
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format,
                                                        frameCapacity: 1024))
            buffer.frameLength = 1024
            let channel = try XCTUnwrap(buffer.floatChannelData)[0]
            for i in 0..<1024 {
                channel[i] = 0.06 * sin(Float((frame * 1024 + i) % 32) * Float.pi / 16)
            }
            pipeline.append(buffer)
        }
        let result = pipeline.close()
        XCTAssertNil(result.writeError)
        return result.audioSeconds
    }

    func testPhysicalLegacyAACAndJSONMigrationIsBytePreserving() throws {
#if os(iOS) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator)
        let dir = root()
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let a = dir.appendingPathComponent("legacy.m4a")
        let j = dir.appendingPathComponent("legacy.json")
        let orphan = dir.appendingPathComponent(".incomplete.m4a")
        let entries = [(a, Data("private-original-audio".utf8)),
                       (j, Data(#"{"id":"legacy"}"#.utf8)),
                       (orphan, Data("incomplete-original".utf8))]
        for (url, bytes) in entries {
            try bytes.write(to: url)
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.none], ofItemAtPath: url.path)
        }
        let storage = PhoneCaptureStorage(directory: dir, files: .default)
        try storage.prepare()
        try protected(dir)
        try storage.prepare()
        for (url, bytes) in entries {
            try protected(url)
            XCTAssertEqual(try Data(contentsOf: url), bytes)
            XCTAssertNotEqual(try url.resourceValues(
                forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
        }
#else
        throw XCTSkip("Requires physical iPhone Data Protection")
#endif
    }

    func testPhysicalNewManifestAndRealAACProtectedBeforeRecording() throws {
#if os(iOS) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator)
        let dir = root()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storage = PhoneCaptureStorage(directory: dir, files: .default)
        try storage.prepare()
        let id = UUID()
        let json = dir.appendingPathComponent("\(id).json")
        let audio = dir.appendingPathComponent("\(id).m4a")
        try storage.writeManifest(
            PhonePendingFixture(id: id, createdAt: Date(), expectedElapsed: nil), to: json)
        try protected(json)
        try storage.writeManifest(
            PhonePendingFixture(id: id, createdAt: Date(), expectedElapsed: 2.35), to: json)
        try protected(json)
        let duration = try writeRealAAC(to: audio)
        try storage.protectAudioBeforeRecording(audio)
        try protected(audio)
        XCTAssertGreaterThan(duration, 2)
        XCTAssertEqual(try AVAudioPlayer(contentsOf: audio).duration, duration,
                       accuracy: 0.05)
#else
        throw XCTSkip("Requires physical iPhone Data Protection")
#endif
    }

    func testPhysicalProtectionFailureKeepsUncommittedSource() throws {
#if os(iOS) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator)
        let dir = root()
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let a = dir.appendingPathComponent("legacy.m4a")
        let bytes = Data("important-pending-source".utf8)
        try bytes.write(to: a)
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.none], ofItemAtPath: a.path)
        let storage = PhoneCaptureStorage(directory: dir, files: DenyPhoneCaptureProtection())
        XCTAssertThrowsError(try storage.prepare())
        XCTAssertThrowsError(try storage.protectAudioBeforeRecording(a))
        XCTAssertEqual(try Data(contentsOf: a), bytes)
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: dir.appendingPathComponent("unexpected.json").path))
#else
        throw XCTSkip("Requires physical iPhone Data Protection")
#endif
    }

    func testPhysicalAlreadyStrongerCompleteProtectionRemainsUntouched() throws {
#if os(iOS) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator)
        let dir = root()
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(
            at: dir, withIntermediateDirectories: true
        )
        let audio = dir.appendingPathComponent("previously-strong.m4a")
        let bytes = Data("never-rewrite-this-original".utf8)
        try bytes.write(to: audio)
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete], ofItemAtPath: audio.path
        )
        try PhoneCaptureStorage(directory: dir, files: .default).prepare()
        XCTAssertEqual(try Data(contentsOf: audio), bytes)
        let protection = try FileManager.default.attributesOfItem(atPath: audio.path)
        XCTAssertEqual(protection[.protectionKey] as? FileProtectionType, .complete)
#else
        throw XCTSkip("Requires physical iOS Data Protection")
#endif
    }

    @MainActor
    func testPhysicalRecoveryProtectionFailureKeepsOldAACAndRefusesImport() throws {
#if os(iOS) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator)
        let dir = root()
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(
            at: dir, withIntermediateDirectories: true
        )
        let id = UUID()
        let audio = dir.appendingPathComponent("\(id).m4a")
        let manifest = dir.appendingPathComponent("\(id).json")
        let original = Data("must-survive-failed-recovery".utf8)
        try original.write(to: audio)
        try JSONEncoder().encode(PhonePendingFixture(
            id: id, createdAt: Date(), expectedElapsed: nil
        )).write(to: manifest)
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.none], ofItemAtPath: audio.path
        )
        let repository = RecordingRepository(
            rootURL: dir.appendingPathComponent("repository")
        )
        let controller = PhoneRecordingController(
            repository: repository,
            fileManager: DenyPhoneCaptureProtection(),
            captureDirectory: dir
        )
        XCTAssertNotNil(controller.errorMessage)
        XCTAssertTrue(repository.allRecordings().isEmpty)
        XCTAssertEqual(try Data(contentsOf: audio), original)
        XCTAssertTrue(FileManager.default.fileExists(atPath: manifest.path))
#else
        throw XCTSkip("Requires physical iOS")
#endif
    }

    @MainActor
    func testPhysicalControllerRecoversExactlyOneAACWithoutMicrophone() throws {
#if os(iOS) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator)
        let dir = root()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storage = PhoneCaptureStorage(directory: dir, files: .default)
        try storage.prepare()
        let id = UUID()
        let a = dir.appendingPathComponent("\(id).m4a")
        let j = dir.appendingPathComponent("\(id).json")
        XCTAssertGreaterThan(try writeRealAAC(to: a), 2)
        try storage.writeManifest(
            PhonePendingFixture(id: id, createdAt: Date(), expectedElapsed: nil), to: j)
        for path in [a, j] {
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.none], ofItemAtPath: path.path)
        }
        let repo = RecordingRepository(
            rootURL: dir.appendingPathComponent("repository", isDirectory: true))
        _ = PhoneRecordingController(repository: repo, captureDirectory: dir)
        let saved = try XCTUnwrap(repo.allRecordings().first)
        XCTAssertEqual(saved.id, id)
        try protected(repo.audioURL(for: saved))
        XCTAssertFalse(FileManager.default.fileExists(atPath: a.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: j.path))
        _ = PhoneRecordingController(repository: repo, captureDirectory: dir)
        XCTAssertEqual(repo.allRecordings().map(\.id), [id])
#else
        throw XCTSkip("Requires physical iPhone")
#endif
    }

    @MainActor
    func testPhysicalUnreadableRecoveryPreservesAACAndManifest() throws {
#if os(iOS) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator) && !targetEnvironment(simulator)
        let dir = root()
        defer { try? FileManager.default.removeItem(at: dir) }
        let storage = PhoneCaptureStorage(directory: dir, files: .default)
        try storage.prepare()
        let id = UUID()
        let a = dir.appendingPathComponent("\(id).m4a")
        let j = dir.appendingPathComponent("\(id).json")
        let bytes = Data(repeating: 0x15, count: 4096)
        try bytes.write(to: a)
        try storage.writeManifest(
            PhonePendingFixture(id: id, createdAt: Date(), expectedElapsed: nil), to: j)
        let repo = RecordingRepository(
            rootURL: dir.appendingPathComponent("repository", isDirectory: true))
        _ = PhoneRecordingController(repository: repo, captureDirectory: dir)
        XCTAssertTrue(repo.allRecordings().isEmpty)
        XCTAssertEqual(try Data(contentsOf: a), bytes)
        try protected(a)
        try protected(j)
#else
        throw XCTSkip("Requires physical iPhone")
#endif
    }
}
