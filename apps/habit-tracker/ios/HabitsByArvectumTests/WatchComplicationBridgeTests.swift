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

    func testCurrentSnapshotRejectsPreviousCalendarDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(
            from: DateComponents(year: 2027, month: 1, day: 16, hour: 0, minute: 1)
        )!
        let stale = HabitSyncSnapshot(
            generatedAt: now.addingTimeInterval(-120),
            dayKey: "2027-01-15",
            completedCount: 1,
            skippedCount: 0,
            totalCount: 1,
            habits: []
        )
        WatchComplicationBridge.saveSnapshot(stale)

        XCTAssertEqual(
            WatchComplicationBridge.loadCurrentSnapshot(
                now: now,
                calendar: calendar
            ),
            .empty
        )
    }

    func testMissingSnapshotReturnsEmpty() {
        let result = WatchComplicationBridge.loadSnapshot()

        XCTAssertEqual(result, .empty)
        XCTAssertEqual(result.progress, 0)
    }
}
