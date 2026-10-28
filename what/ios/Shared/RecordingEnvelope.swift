import Foundation

struct RecordingEnvelope: Codable, Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    let duration: TimeInterval
    let fileName: String
    /// Optional so older Watch and iPhone JSON payloads remain decodable.
    /// Set only for user-selected Files imports; never a filesystem path.
    var displayName: String? = nil
}

enum TransferMetadataKey {
    static let type = "type"
    static let recording = "recording"
    static let acknowledgement = "ack"
    static let syncRequest = "sync-request"
    static let id = "id"
    static let createdAt = "createdAt"
    static let duration = "duration"
    static let displayName = "displayName"
}
