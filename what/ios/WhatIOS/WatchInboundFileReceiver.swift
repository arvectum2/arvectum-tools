import Foundation

/// The durable storage gate used by WCSession's background didReceive(file:).
/// Returning nil means no recording delivery was recognized: do not ACK.
/// Throwing means the file cannot be safely decoded or committed: do not ACK.
/// An ACK is permitted only after the repository has committed the UUID,
/// including an already-delivered or previously-deleted UUID.
enum WatchInboundFileReceiver {
    static func accept(
        _ source: URL, metadata: [String: Any]?,
        into repository: RecordingRepository
    ) throws -> IncomingRecordingResult? {
        guard let metadata,
              metadata[TransferMetadataKey.type] as? String == TransferMetadataKey.recording,
              let expectedDuration = metadata[TransferMetadataKey.duration] as? Double
        else { return nil }

        // WCSession reports transfer completion before validating AAC or
        // committing the note. Never acknowledge this transport event alone.
        try WatchDeliveredAudioValidation.validate(
            source, expectedDuration: expectedDuration
        )
        return try repository.acceptTemporaryFile(source, metadata: metadata)
    }
}
