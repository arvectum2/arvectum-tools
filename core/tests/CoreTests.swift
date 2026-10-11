import Foundation
import XCTest
import SwiftUI
@testable import ArvectumCore

final class ArvectumCoreTests: XCTestCase {
    private struct Item: Codable, Equatable { let id: UUID; let date: Date; let label: String }
    func testLegacyFoundationJSON() throws {
        let item = Item(id: UUID(), date: Date(timeIntervalSince1970: 1700000000), label: "Пример")
        let old = try JSONEncoder().encode(item)
        XCTAssertEqual(try ArvectumJSONCodec.decode(Item.self, from: old), item)
        let updated = try ArvectumJSONCodec.encode(item)
        XCTAssertEqual(try JSONDecoder().decode(Item.self, from: updated), item)
    }
    func testBadJSONThrows() {
        XCTAssertThrowsError(try ArvectumJSONCodec.decode(Item.self, from: Data("{".utf8)))
    }
    func testSharedColors() {
        XCTAssertNotNil(Color.arvectumMint)
        XCTAssertNotNil(Color.arvectumNavy)
        XCTAssertNotNil(Color.arvectumGraphite)
    }
    func testPrivateDiagnostics() {
        ArvectumDiagnostics.failure(subsystem: "ru.arvectum.tools.tests", category: "core", operation: "test", code: "synthetic")
    }
}
