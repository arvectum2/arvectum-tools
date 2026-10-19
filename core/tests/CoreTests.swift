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
    func testUnifiedDesignMetrics() {
        XCTAssertEqual(ArvectumDesignMetrics.unit, 4)
        XCTAssertGreaterThanOrEqual(ArvectumDesignMetrics.minimumTouchTarget, 44)
        XCTAssertGreaterThanOrEqual(ArvectumDesignMetrics.preferredControlHeight,
                                    ArvectumDesignMetrics.minimumTouchTarget)
        XCTAssertEqual(ArvectumDesignMetrics.spaceL, 16)
        XCTAssertGreaterThan(ArvectumDesignMetrics.cardCornerRadius,
                             ArvectumDesignMetrics.controlCornerRadius)
    }

    func testSemanticColorRolesExistInBothAppearances() {
        for scheme in [ColorScheme.light, ColorScheme.dark] {
            XCTAssertNotNil(ArvectumSemanticColors.background(for: scheme))
            XCTAssertNotNil(ArvectumSemanticColors.surface(for: scheme))
            XCTAssertNotNil(ArvectumSemanticColors.primaryText(for: scheme))
            XCTAssertNotNil(ArvectumSemanticColors.secondaryText(for: scheme))
            XCTAssertNotNil(ArvectumSemanticColors.accentText(for: scheme))
            XCTAssertNotNil(ArvectumSemanticColors.subtleBorder(for: scheme))
        }
        XCTAssertNotNil(ArvectumSemanticColors.actionBackground)
        XCTAssertNotNil(ArvectumSemanticColors.actionForeground)
    }

    func testPrivateDiagnostics() {
        ArvectumDiagnostics.failure(subsystem: "ru.arvectum.tools.tests", category: "core", operation: "test", code: "synthetic")
    }

    /// A fixture from the previously persisted Foundation default JSON contract.
    /// This must keep decoding correctly across Core toolchain/refactor changes.
    func testPersistedWireFixtureRemainsCompatible() throws {
        let fixture = Data(#"{"id":"00000000-0000-0000-0000-000000000042","date":725846400,"label":"Пример"}"#.utf8)
        let decoded = try ArvectumJSONCodec.decode(Item.self, from: fixture)
        XCTAssertEqual(decoded.id.uuidString, "00000000-0000-0000-0000-000000000042")
        XCTAssertEqual(decoded.date.timeIntervalSinceReferenceDate, 725846400)
        XCTAssertEqual(decoded.label, "Пример")
        let reencoded = try ArvectumJSONCodec.encode(decoded)
        XCTAssertEqual(try JSONDecoder().decode(Item.self, from: reencoded), decoded)
    }

    func testInvalidPersistedShapeFailsClosed() {
        let fixture = Data(#"{"id":"00000000-0000-0000-0000-000000000042","date":"not-a-date","label":"Пример"}"#.utf8)
        XCTAssertThrowsError(try ArvectumJSONCodec.decode(Item.self, from: fixture))
    }
}
