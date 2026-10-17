import Foundation

/// Optional low-latency transport for short Watch recordings.
/// Original .m4a and queue remain on Watch until the iPhone confirms persistence.
struct ImmediateRecordingPayload: Codable {
    static let maximumAudioBytes = 768 * 1024

    let recording: RecordingEnvelope
    let audio: Data

    func encode() throws -> Data {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> Self {
        try PropertyListDecoder().decode(Self.self, from: data)
    }

    var metadata: [String: Any] {
        [
            TransferMetadataKey.id: recording.id.uuidString,
            TransferMetadataKey.createdAt: recording.createdAt.timeIntervalSince1970,
            TransferMetadataKey.duration: recording.duration
        ]
    }
}

struct ImmediateRecordingReply: Codable {
    let acknowledgedID: UUID

    func encode() throws -> Data {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> Self {
        try PropertyListDecoder().decode(Self.self, from: data)
    }
}
