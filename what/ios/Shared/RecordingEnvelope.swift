import Foundation

struct RecordingEnvelope: Codable, Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    let duration: TimeInterval
    let fileName: String
}

enum TransferMetadataKey {
    static let type = "type"
    static let recording = "recording"
    static let acknowledgement = "ack"
    static let id = "id"
    static let createdAt = "createdAt"
    static let duration = "duration"
}
