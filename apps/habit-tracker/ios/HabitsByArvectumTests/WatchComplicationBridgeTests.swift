import Foundation
import XCTest
@testable import HabitsByArvectum

final class WatchComplicationBridgeTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "WatchComplicationBridgeTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        WatchComplicationBridge.defaultsOverride = defaults
    }

    override func tearDown() {
        WatchComplicationBridge.defaultsOverride = nil
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testSnapshotRoundTripAndProgress() {
        let snapshot = HabitSyncSnapshot(
            generatedAt: Date(timeIntervalSince1970: 1_800_000_000),
            dayKey: "2027-01-15",
            completedCount: 2,
            skippedCount: 1,
            totalCount: 4,
            habits: [
                HabitSyncHabit(
                    id: UUID(),
                    name: "Walk",
                    symbolName: "figure.walk",
                    colorHex: "43E5C5",
                    completed: true,
                    skipped: false,
                    streak: 7
                )
            ]
        )

        WatchComplicationBridge.saveSnapshot(snapshot)

        let result = WatchComplicationBridge.loadSnapshot()
        XCTAssertEqual(result, snapshot)
        XCTAssertEqual(result.resolvedCount, 3)
        XCTAssertEqual(result.progress, 0.75, accuracy: 0.0001)
    }

    func testMissingSnapshotReturnsEmpty() {
        let result = WatchComplicationBridge.loadSnapshot()

        XCTAssertEqual(result, .empty)
        XCTAssertEqual(result.progress, 0)
    }
}
