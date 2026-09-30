import XCTest
@testable import HabitsByArvectum

final class HabitMetricsTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testEveryDayIncludesAllWeekdays() throws {
        let start = date(2026, 9, 28)

        for offset in 0..<7 {
            let day = try XCTUnwrap(
                calendar.date(byAdding: .day, value: offset, to: start)
            )
            XCTAssertTrue(
                HabitSchedule.everyDay.includes(day, calendar: calendar)
            )
        }
    }

    func testWeekdayScheduleSkipsWeekend() {
        XCTAssertTrue(
            HabitSchedule.weekdays.includes(
                date(2026, 10, 2),
                calendar: calendar
            )
        )
        XCTAssertFalse(
            HabitSchedule.weekdays.includes(
                date(2026, 10, 3),
                calendar: calendar
            )
        )
    }

    func testCurrentStreakIgnoresUnscheduledWeekend() {
        let habit = Habit(
            name: "Read",
            createdAt: date(2026, 9, 25),
            scheduleMask: HabitSchedule.weekdays.rawValue
        )
        let checkIns = [
            HabitCheckIn(habitID: habit.id, day: date(2026, 9, 25)),
            HabitCheckIn(habitID: habit.id, day: date(2026, 9, 28)),
            HabitCheckIn(habitID: habit.id, day: date(2026, 9, 29)),
            HabitCheckIn(habitID: habit.id, day: date(2026, 9, 30))
        ]

        XCTAssertEqual(
            HabitMetrics.currentStreak(
                habit: habit,
                checkIns: checkIns,
                today: date(2026, 9, 30),
                calendar: calendar
            ),
            4
        )
    }

    func testIncompleteTodayPreservesYesterdayStreak() {
        let habit = Habit(
            name: "Walk",
            createdAt: date(2026, 9, 28)
        )
        let checkIns = [
            HabitCheckIn(habitID: habit.id, day: date(2026, 9, 28)),
            HabitCheckIn(habitID: habit.id, day: date(2026, 9, 29))
        ]

        XCTAssertEqual(
            HabitMetrics.currentStreak(
                habit: habit,
                checkIns: checkIns,
                today: date(2026, 9, 30),
                calendar: calendar
            ),
            2
        )
    }

    func testCompletionRateUsesScheduledDaysOnly() {
        let habit = Habit(
            name: "Train",
            createdAt: date(2026, 9, 28),
            scheduleMask: HabitSchedule.weekdays.rawValue
        )
        let checkIns = [
            HabitCheckIn(habitID: habit.id, day: date(2026, 9, 28)),
            HabitCheckIn(habitID: habit.id, day: date(2026, 9, 30))
        ]

        XCTAssertEqual(
            HabitMetrics.completionRate(
                habit: habit,
                checkIns: checkIns,
                through: date(2026, 10, 2),
                calendar: calendar
            ),
            0.4,
            accuracy: 0.0001
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(
            from: DateComponents(year: year, month: month, day: day)
        )!
    }
}
