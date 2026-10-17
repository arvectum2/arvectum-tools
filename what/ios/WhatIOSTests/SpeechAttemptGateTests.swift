import XCTest
import Foundation
@testable import WhatIOS

/// Deterministic cancellation/permission-error tests without asking for real
/// Speech permission or touching user recordings on any paired device.
final class SpeechAttemptGateTests: XCTestCase {
    func testLateAuthorizationAfterCancellationIsRejected() {
        let note = UUID()
        var gate = SpeechAttemptGate()
        let pendingPermission = gate.begin(for: note)
        XCTAssertTrue(gate.accepts(recording: note, attempt: pendingPermission))
        gate.invalidate() // User tapped Cancel before the permission dialog returned.
        XCTAssertFalse(gate.accepts(recording: note, attempt: pendingPermission))
        XCTAssertNil(gate.recordingID)
    }

    func testOldSpeechResultCannotOverwriteSameRecordingAfterImmediateRetry() {
        let note = UUID()
        var gate = SpeechAttemptGate()
        let cancelled = gate.begin(for: note)
        gate.invalidate()
        let retry = gate.begin(for: note)
        XCTAssertNotEqual(cancelled, retry)
        XCTAssertFalse(gate.accepts(recording: note, attempt: cancelled))
        XCTAssertTrue(gate.accepts(recording: note, attempt: retry))
        gate.invalidate()
        XCTAssertFalse(gate.accepts(recording: note, attempt: retry))
    }

    func testStalePermissionDeniedCannotInterruptNewBatchAttempt() {
        let first = UUID()
        let second = UUID()
        var gate = SpeechAttemptGate()
        let oldPermission = gate.begin(for: first)
        gate.invalidate()
        let newPermission = gate.begin(for: second)
        XCTAssertFalse(gate.accepts(recording: first, attempt: oldPermission))
        XCTAssertFalse(gate.accepts(recording: first, attempt: newPermission))
        XCTAssertTrue(gate.accepts(recording: second, attempt: newPermission))
    }

    func testCancelledSpeechCannotMutatePreviouslyEditedTranscript() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-speech-race-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let note = UUID()
        let repository = RecordingRepository(rootURL: root)
        // Synthetic transcript: no real iPhone data or microphone access.
        try repository.saveTranscript("Исправленный текст", for: note)
        var gate = SpeechAttemptGate()
        let cancelled = gate.begin(for: note)
        gate.invalidate()
        let newAttempt = gate.begin(for: note)
        if gate.accepts(recording: note, attempt: cancelled) {
            try repository.saveTranscript("Поздний ответ старой задачи", for: note)
        }
        XCTAssertEqual(repository.transcripts()[note], "Исправленный текст")
        XCTAssertTrue(gate.accepts(recording: note, attempt: newAttempt))
        gate.invalidate()
    }

    func testDeniedPermissionInvalidatesAttemptWithoutDamagingSavedText() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-denied-speech-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let note = UUID()
        let repository = RecordingRepository(rootURL: root)
        try repository.saveTranscript("Original note", for: note)
        var gate = SpeechAttemptGate()
        let denied = gate.begin(for: note)
        gate.invalidate() // PhoneStore.finishTranscription() on denied permission.
        XCTAssertFalse(gate.accepts(recording: note, attempt: denied))
        XCTAssertEqual(repository.transcripts()[note], "Original note")
    }
}
