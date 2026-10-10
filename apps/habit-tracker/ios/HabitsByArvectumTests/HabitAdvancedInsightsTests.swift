import XCTest
@testable import HabitsByArvectum

final class HabitAdvancedInsightsTests: XCTestCase {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        return c
    }

    private func date(_ month: Int, _ day: Int, calendar: Calendar? = nil) -> Date {
        let c = calendar ?? self.calendar
        return c.date(from: DateComponents(
            year: 2026, month: month, day: day, hour: 12
        ))!
    }

    func testWeeklyHistoryIncludesOnlyFinishedWeeksAndNeutralFullPause() {
        let habit = Habit(name: "Train", createdAt: date(9, 14), weeklyTarget: 3)
        let checkIns = [
            14, 16, 18, // met the target during Sept 14–20
            22, // missed Sept 21–27
            5, 7, 9  // current week, must not affect rate
        ].map { day in
            HabitCheckIn(
                habitID: habit.id,
                day: day <= 9 ? date(10, day) : date(9, day),
                calendar: calendar
            )
        }
        let period = HabitPausePeriod(
            habitID: habit.id, startedAt: date(9, 28), calendar: calendar
        )
        period.endedAt = date(10, 5)
        period.endDayKeyExclusive = HabitDayKey.make(for: date(10, 5), calendar: calendar)
        let result = HabitInsights.weeklyWindow(
            habit: habit, checkIns: checkIns, skips: [],
            pausePeriods: [period], previousWeeks: 4,
            through: date(10, 10), calendar: calendar
        )
        XCTAssertEqual(result.achieved, 1)
        XCTAssertEqual(result.missed, 1)
        XCTAssertEqual(result.neutral, 1)
        XCTAssertEqual(result.percent, 50)
    }

    func testCurrentIncompleteWeekDoesNotCountAsMissed() {
        let habit = Habit(name: "Run", createdAt: date(10, 5), weeklyTarget: 3)
        let result = HabitInsights.weeklyWindow(
            habit: habit, checkIns: [], skips: [], pausePeriods: [],
            previousWeeks: 4, through: date(10, 10), calendar: calendar
        )
        XCTAssertEqual(result.eligible, 0)
        XCTAssertEqual(result.percent, 0)
    }

    func testIntervalUsesCalendarDaysAcrossDaylightSavingsAndDistinctDays() {
        var ny = Calendar(identifier: .gregorian)
        ny.timeZone = TimeZone(identifier: "America/New_York")!
        let habit = Habit(name: "Clean", createdAt: date(3, 1, calendar: ny),
                          weeklyTarget: -3)
        let checks = [7, 7, 9, 11].map {
            HabitCheckIn(habitID: habit.id, day: date(3, $0, calendar: ny), calendar: ny)
        }
        let result = HabitInsights.intervalWindow(
            habit: habit, checkIns: checks, days: 30,
            through: date(3, 10, calendar: ny), calendar: ny
        )
        XCTAssertEqual(result.occurrences, 2) // duplicate and future do not count
        XCTAssertEqual(result.averageGapDays, 2)
    }

    func testIntervalOneOccurrenceHasNoFakeAverage() {
        let habit = Habit(name: "Water plants", createdAt: date(9, 1),
                          weeklyTarget: -7)
        let result = HabitInsights.intervalWindow(
            habit: habit,
            checkIns: [HabitCheckIn(habitID: habit.id, day: date(10, 8),
                                   calendar: calendar)],
            days: 30, through: date(10, 10), calendar: calendar
        )
        XCTAssertEqual(result.occurrences, 1)
        XCTAssertNil(result.averageGapDays)
    }
}
