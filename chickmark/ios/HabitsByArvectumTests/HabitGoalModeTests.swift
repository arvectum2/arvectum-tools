import XCTest
@testable import HabitsByArvectum

final class HabitGoalModeTests: XCTestCase {
    func testAllModesRoundTripThroughPublishedIntegerField() {
        let modes: [HabitGoalMode] = [
            .scheduled, .weekly(times: 3),
            .afterCompletion(days: 14), .multiCheck(times: 5),
            .quantity(count: 100), .duration(minutes: 120)
        ]
        for mode in modes {
            XCTAssertEqual(HabitGoalMode(storedValue: mode.storedValue), mode)
        }
    }

    func testUnknownLegacyValuesFallBackSafely() {
        XCTAssertEqual(HabitGoalMode(storedValue: 999), .scheduled)
        XCTAssertEqual(HabitGoalMode(storedValue: 3000), .scheduled)
        XCTAssertEqual(HabitGoalMode(storedValue: 5010), .duration(minutes: 50))
    }

    func testHabitModeControlsDomainFlags() {
        let habit = Habit(name: "Read")
        habit.goalMode = .duration(minutes: 35)
        XCTAssertEqual(habit.dailyTarget, 7)
        XCTAssertTrue(habit.supportsIncrementalGoal)
        XCTAssertFalse(habit.usesCompletionInterval)
        habit.goalMode = .weekly(times: 3)
        XCTAssertTrue(habit.usesFlexibleWeeklyTarget)
        XCTAssertEqual(habit.dailyTarget, 1)
    }
}
