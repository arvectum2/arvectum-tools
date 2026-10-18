import Foundation

/// A short-lived, same-device transfer between UhWhat? and ChickMark.
/// Note text is NEVER put into a custom URL, notification or remote request.
/// The URL carries only a random nonce; the complete payload travels via a
/// local-only expiring pasteboard entry, after a deliberate user action.
struct ReviewNoteHandoff: Codable, Equatable, Identifiable {
    enum Kind: String, Codable { case audio, text, video }

    static let clipboardType = "ru.arvectum.tools.what.review-note.v1"
    static let clipboardMarker = "uhwhat-review-v1:"
#if REVIEW_HANDOFF_QA
    static let targetScheme = "chickmark-review-qa"
#else
    static let targetScheme = "chickmark-review"
#endif
#if REVIEW_HANDOFF_QA
    static let sourceScheme = "whatreviewqa"
#else
    static let sourceScheme = "what"
#endif
    static let maximumTextBytes = 32_768
    static let validFor: TimeInterval = 300

    let version: Int
    let noteID: UUID
    let kind: Kind
    let createdAt: Date
    let text: String
    let sourceURL: URL
    let nonce: UUID
    let sentAt: Date
    var id: UUID { noteID }

    init(noteID: UUID, kind: Kind, createdAt: Date, text: String,
         sentAt: Date = Date(), nonce: UUID = UUID()) throws {
        version = 1
        self.noteID = noteID
        self.kind = kind
        self.createdAt = createdAt
        self.text = text
        self.nonce = nonce
        self.sentAt = sentAt
        guard let sourceURL = URL(string: "\(Self.sourceScheme)://note/\(noteID.uuidString)")
        else { throw TransferError.invalidPayload }
        self.sourceURL = sourceURL
        try validate(at: sentAt)
    }

    var recipientURL: URL {
        URL(string: "\(Self.targetScheme)://review-import/\(nonce.uuidString)")!
    }

    static func nonce(from link: URL) -> UUID? {
        guard link.scheme?.lowercased() == targetScheme,
              link.host?.lowercased() == "review-import",
              link.user == nil, link.password == nil, link.port == nil,
              link.query == nil, link.fragment == nil,
              link.pathComponents.count == 2,
              let nonce = UUID(uuidString: link.lastPathComponent)
        else { return nil }
        return nonce
    }

    func validate(at now: Date = Date()) throws {
        guard version == 1,
              !text.isEmpty || kind == .video,
              text.utf8.count <= Self.maximumTextBytes,
              createdAt <= now.addingTimeInterval(60),
              sentAt <= now.addingTimeInterval(60),
              sentAt >= now.addingTimeInterval(-Self.validFor),
              sourceURL.scheme == Self.sourceScheme,
              sourceURL.host == "note",
              sourceURL.query == nil, sourceURL.fragment == nil,
              sourceURL.path == "/\(noteID.uuidString)"
        else { throw TransferError.invalidPayload }
    }

    func clipboardString() throws -> String {
        let bytes = try JSONEncoder().encode(self)
        return Self.clipboardMarker + bytes.base64EncodedString()
    }

    static func decodeClipboardString(_ raw: String, from link: URL,
                                      now: Date = Date()) throws -> Self {
        guard raw.hasPrefix(clipboardMarker),
              let data = Data(base64Encoded: String(raw.dropFirst(clipboardMarker.count)))
        else { throw TransferError.invalidPayload }
        return try decode(data, from: link, now: now)
    }

    static func decode(_ data: Data, from link: URL, now: Date = Date()) throws -> Self {
        guard data.count <= Self.maximumTextBytes + 2048,
              let nonce = nonce(from: link),
              let payload = try? JSONDecoder().decode(Self.self, from: data),
              payload.nonce == nonce
        else { throw TransferError.invalidPayload }
        try payload.validate(at: now)
        return payload
    }

    enum TransferError: Error { case invalidPayload }
}
