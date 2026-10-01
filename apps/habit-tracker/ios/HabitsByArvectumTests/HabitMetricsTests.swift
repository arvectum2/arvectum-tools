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
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 9, 25),
                calendar: calendar
            ),
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 9, 28),
                calendar: calendar
            ),
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 9, 29),
                calendar: calendar
            ),
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 9, 30),
                calendar: calendar
            )
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
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 9, 28),
                calendar: calendar
            ),
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 9, 29),
                calendar: calendar
            )
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
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 9, 28),
                calendar: calendar
            ),
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 9, 30),
                calendar: calendar
            )
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

    func testSkippedDayDoesNotBreakOrGrowCurrentStreak() {
        let habit = Habit(
            name: "Read",
            createdAt: date(2026, 9, 28)
        )
        let checkIns = [
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 9, 28),
                calendar: calendar
            ),
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 9, 30),
                calendar: calendar
            )
        ]
        let skips = [
            HabitSkip(
                habitID: habit.id,
                day: date(2026, 9, 29),
                calendar: calendar
            )
        ]

        XCTAssertEqual(
            HabitMetrics.currentStreak(
                habit: habit,
                checkIns: checkIns,
                skips: skips,
                today: date(2026, 9, 30),
                calendar: calendar
            ),
            2
        )
    }

    func testSkippedDayIsExcludedFromCompletionRate() {
        let habit = Habit(
            name: "Walk",
            createdAt: date(2026, 9, 28)
        )
        let checkIns = [
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 9, 28),
                calendar: calendar
            ),
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 9, 30),
                calendar: calendar
            )
        ]
        let skips = [
            HabitSkip(
                habitID: habit.id,
                day: date(2026, 9, 29),
                calendar: calendar
            )
        ]

        XCTAssertEqual(
            HabitMetrics.completionRate(
                habit: habit,
                checkIns: checkIns,
                skips: skips,
                through: date(2026, 9, 30),
                calendar: calendar
            ),
            1,
            accuracy: 0.0001
        )
    }

    func testBestStreakBridgesSkippedDayButResetsOnMiss() {
        let habit = Habit(
            name: "Train",
            createdAt: date(2026, 9, 27)
        )
        let checkIns = [
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 9, 27),
                calendar: calendar
            ),
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 9, 28),
                calendar: calendar
            ),
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 9, 30),
                calendar: calendar
            ),
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 10, 2),
                calendar: calendar
            )
        ]
        let skips = [
            HabitSkip(
                habitID: habit.id,
                day: date(2026, 9, 29),
                calendar: calendar
            )
        ]

        XCTAssertEqual(
            HabitMetrics.bestStreak(
                habit: habit,
                checkIns: checkIns,
                skips: skips,
                through: date(2026, 10, 2),
                calendar: calendar
            ),
            3
        )
    }

    func testCheckInKeepsOriginalLocalDayAfterTimezoneChange() {
        var losAngeles = Calendar(identifier: .gregorian)
        losAngeles.timeZone = TimeZone(identifier: "America/Los_Angeles")!

        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!

        let habit = Habit(name: "Read")
        let checkInDate = date(
            2026, 9, 30,
            hour: 23,
            minute: 30,
            calendar: losAngeles
        )
        let checkIn = HabitCheckIn(
            habitID: habit.id,
            day: checkInDate,
            calendar: losAngeles
        )

        XCTAssertEqual(checkIn.dayKey, "2026-09-30")

        XCTAssertTrue(
            HabitMetrics.isCompleted(
                habitID: habit.id,
                on: date(2026, 9, 30, hour: 12, calendar: tokyo),
                checkIns: [checkIn],
                calendar: tokyo
            )
        )
        XCTAssertFalse(
            HabitMetrics.isCompleted(
                habitID: habit.id,
                on: date(2026, 10, 1, hour: 12, calendar: tokyo),
                checkIns: [checkIn],
                calendar: tokyo
            )
        )
    }

    func testDailyStreakSurvivesDSTFallBack() {
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York")!

        let habit = Habit(
            name: "Walk",
            createdAt: date(2026, 10, 31, hour: 12, calendar: newYork)
        )
        let checkIns = [
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 10, 31, hour: 12, calendar: newYork),
                calendar: newYork
            ),
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 11, 1, hour: 12, calendar: newYork),
                calendar: newYork
            ),
            HabitCheckIn(
                habitID: habit.id,
                day: date(2026, 11, 2, hour: 12, calendar: newYork),
                calendar: newYork
            )
        ]

        XCTAssertEqual(
            HabitMetrics.currentStreak(
                habit: habit,
                checkIns: checkIns,
                today: date(2026, 11, 2, hour: 12, calendar: newYork),
                calendar: newYork
            ),
            3
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        date(year, month, day, calendar: calendar)
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        hour: Int = 0,
        minute: Int = 0,
        calendar: Calendar
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        )!
    }
}
