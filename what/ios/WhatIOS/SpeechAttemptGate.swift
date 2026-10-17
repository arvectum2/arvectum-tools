import Foundation

/// Guards asynchronous Speech permission and recognition callbacks against
/// cancellation, deletion and a *new* recognition of the same recording UUID.
///
/// Recording identity alone is not enough: a cancelled recognition task may
/// finish after the user immediately retries that very same note.
struct SpeechAttemptGate {
    private(set) var recordingID: UUID?
    private(set) var attemptID: UUID?

    @discardableResult
    mutating func begin(for recording: UUID) -> UUID {
        let attempt = UUID()
        recordingID = recording
        attemptID = attempt
        return attempt
    }

    func accepts(recording: UUID, attempt: UUID) -> Bool {
        recordingID == recording && attemptID == attempt
    }

    mutating func invalidate() {
        recordingID = nil
        attemptID = nil
    }
}
