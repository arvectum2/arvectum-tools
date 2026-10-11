import XCTest
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
