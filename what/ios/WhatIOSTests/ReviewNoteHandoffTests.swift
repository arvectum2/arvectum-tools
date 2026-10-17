import XCTest
@testable import WhatIOS

final class ReviewNoteHandoffTests: XCTestCase {
    func testPrivateTranscriptNeverAppearsInURLAndPayloadRoundTrips() throws {
        let id = UUID()
        let transcript = "Бирюзовый маяк — не публиковать этот текст!"
        let payload = try ReviewNoteHandoff(noteID: id, kind: .audio,
            createdAt: Date().addingTimeInterval(-30), text: transcript)
        let link = payload.recipientURL
        XCTAssertEqual(link.scheme, "chickmark-review")
        XCTAssertFalse(link.absoluteString.contains(transcript))
        XCTAssertFalse(link.absoluteString.contains(id.uuidString))
        XCTAssertEqual(ReviewNoteHandoff.nonce(from: link), payload.nonce)
        let data = try JSONEncoder().encode(payload)
        let recovered = try ReviewNoteHandoff.decode(data, from: link)
        XCTAssertEqual(recovered, payload)
        XCTAssertEqual(try ReviewNoteHandoff.decodeClipboardString(
            payload.clipboardString(), from: link), payload)
        XCTAssertEqual(recovered.sourceURL.absoluteString,
                       "whatp2aqa://note/\(id.uuidString)")
    }

    func testWrongNonceExpiredAndExternalLinksAreRejected() throws {
        let payload = try ReviewNoteHandoff(noteID: UUID(), kind: .text,
            createdAt: Date().addingTimeInterval(-10), text: "Секрет")
        let data = try JSONEncoder().encode(payload)
        let wrong = URL(string: "chickmark-review://review-import/\(UUID().uuidString)")!
        XCTAssertThrowsError(try ReviewNoteHandoff.decode(data, from: wrong))
        XCTAssertNil(ReviewNoteHandoff.nonce(from: URL(string: "https://example.com")!))
        XCTAssertThrowsError(try ReviewNoteHandoff.decode(data, from: payload.recipientURL,
                now: Date().addingTimeInterval(360)))
        XCTAssertNil(ReviewNoteHandoff.nonce(from: URL(string:
            "chickmark-review://review-import/\(payload.nonce.uuidString)?text=secret")!))
    }

    func testFullUTF8TextIsRetainedAndOversizeIsRejected() throws {
        let text = String(repeating: "Привет 👋", count: 400)
        XCTAssertEqual(try ReviewNoteHandoff(noteID: UUID(), kind: .text,
                         createdAt: Date(), text: text).text, text)
        XCTAssertThrowsError(try ReviewNoteHandoff(noteID: UUID(), kind: .audio,
            createdAt: Date(), text: String(repeating: "й", count: 20_000)))
    }
}
