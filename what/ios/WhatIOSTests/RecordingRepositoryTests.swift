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

    func testTranscriptPersisted() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let id = UUID()
        try RecordingRepository(rootURL: root).saveTranscript("Test transcript", for: id)
        XCTAssertEqual(RecordingRepository(rootURL: root).transcripts()[id], "Test transcript")
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

}
