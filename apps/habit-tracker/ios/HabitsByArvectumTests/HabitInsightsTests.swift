import XCTest
@testable import HabitsByArvectum

final class HabitInsightsTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func day(_ number: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: number, hour: 12))!
    }

    func testMissedYesterdayButNotTodayAndSkipIsNeutral() {
        let habit = Habit(name: "Read", createdAt: day(5))
        let checkIns = [HabitCheckIn(habitID: habit.id, day: day(5), calendar: calendar),
                        HabitCheckIn(habitID: habit.id, day: day(8), calendar: calendar)]
        let skips = [HabitSkip(habitID: habit.id, day: day(7), calendar: calendar)]
        let result = HabitInsights.window(
            habit: habit, checkIns: checkIns, skips: skips,
            pausePeriods: [], days: 7, through: day(10), calendar: calendar
        )
        XCTAssertEqual(result.completed, 2)
        XCTAssertEqual(result.skipped, 1)
        XCTAssertEqual(result.missed, 2) // Oct 6 and 9, not unfinished Oct 10
        XCTAssertEqual(result.eligible, 4)
        XCTAssertEqual(result.percent, 50)
    }

    func testWeekdaysDoNotTreatWeekendAsMissed() {
        let habit = Habit(name: "Work", createdAt: day(8),
                          scheduleMask: HabitSchedule.weekdays.rawValue)
        let result = HabitInsights.window(
            habit: habit, checkIns: [], skips: [],
            pausePeriods: [], days: 7, through: day(12), calendar: calendar
        )
        XCTAssertEqual(result.missed, 2) // Oct 8, 9; Oct 10-11 weekend
    }

    func testCreationDateAndEmptyWindows() {
        let habit = Habit(name: "New", createdAt: day(10))
        let result = HabitInsights.window(
            habit: habit, checkIns: [], skips: [], pausePeriods: [],
            days: 30, through: day(10), calendar: calendar
        )
        XCTAssertEqual(result.eligible, 0)
        XCTAssertEqual(result.percent, 0)
    }

    func testWeeklyGoalDoesNotMisrepresentItsRateAsDaily() {
        let habit = Habit(name: "Run", createdAt: day(5), weeklyTarget: 3)
        let result = HabitInsights.window(
            habit: habit, checkIns: [], skips: [], pausePeriods: [],
            days: 7, through: day(10), calendar: calendar
        )
        XCTAssertEqual(result.eligible, 0)
    }
}
