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


    func testCurrentSnapshotUsesProjectedDayAfterMidnight() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(
            from: DateComponents(
                year: 2027,
                month: 1,
                day: 16,
                hour: 0,
                minute: 1
            )
        )!
        let habit = HabitSyncHabit(
            id: UUID(),
            name: "Reading",
            symbolName: "book.fill",
            colorHex: "8B5CF6",
            completed: false,
            skipped: false,
            streak: 5
        )
        let source = HabitSyncSnapshot(
            generatedAt: now.addingTimeInterval(-300),
            dayKey: "2027-01-15",
            completedCount: 1,
            skippedCount: 0,
            totalCount: 1,
            habits: [],
            projectedDays: [
                HabitSyncDayProjection(
                    dayKey: "2027-01-16",
                    habits: [habit]
                )
            ]
        )

        let result = WatchComplicationBridge.currentSnapshot(
            source,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(result.dayKey, "2027-01-16")
        XCTAssertEqual(result.totalCount, 1)
        XCTAssertEqual(result.habits.first, habit)
        XCTAssertEqual(result.projectedDays, source.projectedDays)
    }

    func testLocalWatchHealthCompletionProjectsWithoutMutatingBase() {
        let id = UUID()
        let other = UUID()
        let dayKey = "2027-01-15"
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let habit = HabitSyncHabit(
            id: id, name: "Steps", symbolName: "figure.walk",
            colorHex: "43E5C5", completed: false, streak: 1,
            healthRuleMetric: "steps", healthRuleTarget: 3000
        )
        // Total includes a trimmed habit not present in visible payload.
        let snapshot = HabitSyncSnapshot(
            generatedAt: now, dayKey: dayKey,
            completedCount: 1, skippedCount: 1, totalCount: 4,
            habits: [habit]
        )
        let state = WatchLocalHealthProjection.State(
            dayKey: dayKey, habitIDs: [id, other], generatedAt: now,
            rules: [id: .init(metric: "steps", target: 3000)]
        )
        let projected = WatchLocalHealthProjection.applying(snapshot, state: state, now: now)
        XCTAssertEqual(projected.completedCount, 2)
        XCTAssertEqual(projected.skippedCount, 1)
        XCTAssertEqual(projected.totalCount, 4)
        XCTAssertTrue(projected.habits[0].completed)
        XCTAssertFalse(snapshot.habits[0].completed)
        XCTAssertEqual(snapshot.completedCount, 1)
    }

    func testLocalHealthOverlayRespectsManualOverrideAndSkip() {
        let id = UUID()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let state = WatchLocalHealthProjection.State(
            dayKey: "2027-01-15", habitIDs: [id], generatedAt: now,
            rules: [id: .init(metric: "steps", target: 2000)]
        )
        func snapshot(skipped: Bool, overridden: Bool) -> HabitSyncSnapshot {
            HabitSyncSnapshot(
                generatedAt: now, dayKey: "2027-01-15",
                completedCount: 0, skippedCount: skipped ? 1 : 0, totalCount: 1,
                habits: [
                    HabitSyncHabit(
                        id: id, name: "Walk", symbolName: "figure.walk",
                        colorHex: "43E5C5", completed: false,
                        skipped: skipped, streak: 0,
                        healthRuleMetric: "steps", healthRuleTarget: 2000,
                        healthManualOverride: overridden
                    )
                ]
            )
        }
        let undone = WatchLocalHealthProjection.applying(
            snapshot(skipped: false, overridden: true), state: state, now: now
        )
        XCTAssertFalse(undone.habits[0].completed)
        XCTAssertEqual(undone.completedCount, 0)

        let skipped = WatchLocalHealthProjection.applying(
            snapshot(skipped: true, overridden: false), state: state, now: now
        )
        XCTAssertFalse(skipped.habits[0].completed)
        XCTAssertEqual(skipped.resolvedCount, 1)
    }

    func testLocalWatchHealthOverlayExpiresAndNeverCrossesMidnight() {
        let id = UUID()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let snapshot = HabitSyncSnapshot(
            generatedAt: now, dayKey: "2027-01-15",
            completedCount: 0, totalCount: 1,
            habits: [
                HabitSyncHabit(
                    id: id, name: "Walk", symbolName: "figure.walk",
                    colorHex: "43E5C5", completed: false, streak: 0,
                    healthRuleMetric: "steps", healthRuleTarget: 2000
                )
            ]
        )
        let yesterday = WatchLocalHealthProjection.State(
            dayKey: "2027-01-14", habitIDs: [id], generatedAt: now,
            rules: [id: .init(metric: "steps", target: 2000)]
        )
        XCTAssertEqual(
            WatchLocalHealthProjection.applying(snapshot, state: yesterday, now: now),
            snapshot
        )
        let expired = WatchLocalHealthProjection.State(
            dayKey: snapshot.dayKey, habitIDs: [id],
            generatedAt: now.addingTimeInterval(-24 * 3600),
            rules: [id: .init(metric: "steps", target: 2000)]
        )
        XCTAssertEqual(
            WatchLocalHealthProjection.applying(snapshot, state: expired, now: now),
            snapshot
        )
    }

    func testLocalWatchHealthDoesNotDoubleCountAuthoritativeCheckmark() {
        let id = UUID()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let base = HabitSyncSnapshot(
            generatedAt: now, dayKey: "2027-01-15",
            completedCount: 1, totalCount: 1,
            habits: [
                HabitSyncHabit(
                    id: id, name: "Steps", symbolName: "figure.walk",
                    colorHex: "43E5C5", completed: true, streak: 1,
                    healthRuleMetric: "steps", healthRuleTarget: 5000
                )
            ]
        )
        let state = WatchLocalHealthProjection.State(
            dayKey: base.dayKey, habitIDs: [id], generatedAt: now,
            rules: [id: .init(metric: "steps", target: 5000)]
        )
        XCTAssertEqual(
            WatchLocalHealthProjection.applying(base, state: state, now: now),
            base
        )
    }

    func testWatchFaceRejectsPriorAutomaticCheckoffAfterTargetEdit() {
        let id = UUID()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let formerlyReachedGoal = WatchLocalHealthProjection.State(
            dayKey: "2027-01-15", habitIDs: [id], generatedAt: now,
            rules: [id: .init(metric: "steps", target: 1_000)]
        )
        let updated = HabitSyncSnapshot(
            generatedAt: now, dayKey: "2027-01-15",
            completedCount: 0, totalCount: 1,
            habits: [
                HabitSyncHabit(
                    id: id, name: "Walk", symbolName: "figure.walk",
                    colorHex: "43E5C5", completed: false, streak: 0,
                    healthRuleMetric: "steps", healthRuleTarget: 2_000
                )
            ]
        )
        XCTAssertEqual(
            WatchLocalHealthProjection.applying(updated, state: formerlyReachedGoal, now: now),
            updated,
            "The old watchface checkmark must disappear when a goal increases"
        )
        var changedMetric = updated
        changedMetric.habits[0].healthRuleMetric = "walkingDistance"
        XCTAssertEqual(
            WatchLocalHealthProjection.applying(changedMetric,
                state: formerlyReachedGoal, now: now), changedMetric
        )
        let legacyWithoutGoalFingerprint = WatchLocalHealthProjection.State(
            dayKey: "2027-01-15", habitIDs: [id], generatedAt: now
        )
        XCTAssertEqual(
            WatchLocalHealthProjection.applying(updated,
                state: legacyWithoutGoalFingerprint, now: now), updated
        )
    }

    func testWatchHealthStepThresholdAndManualOverride() {
        let id = UUID()
        let base = HabitSyncHabit(
            id: id, name: "Walk", symbolName: "figure.walk",
            colorHex: "43E5C5", completed: false, streak: 0,
            healthRuleMetric: "steps", healthRuleTarget: 2_000
        )
        XCTAssertFalse(WatchLocalHealthProjection.qualifies(base, value: 1_999))
        XCTAssertTrue(WatchLocalHealthProjection.qualifies(base, value: 2_000))
        XCTAssertTrue(WatchLocalHealthProjection.qualifies(base, value: 3_100))
        XCTAssertFalse(WatchLocalHealthProjection.qualifies(base, value: .nan))
        var overwritten = base
        overwritten.healthManualOverride = true
        XCTAssertFalse(WatchLocalHealthProjection.qualifies(overwritten, value: 3_100))
        var alreadyCompleted = base
        alreadyCompleted.completed = true
        XCTAssertFalse(WatchLocalHealthProjection.qualifies(alreadyCompleted, value: 3_100))
        var skipped = base
        skipped.skipped = true
        XCTAssertFalse(WatchLocalHealthProjection.qualifies(skipped, value: 3_100))
    }

    func testMissingSnapshotReturnsEmpty() {
        let result = WatchComplicationBridge.loadSnapshot()

        XCTAssertEqual(result, .empty)
        XCTAssertEqual(result.progress, 0)
    }
}
