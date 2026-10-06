import XCTest
@testable import WhatIOS

final class RecordingRepositoryTests: XCTestCase {
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
}
