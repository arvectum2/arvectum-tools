import XCTest
@testable import HabitsByArvectum

final class HabitFrequencyTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
    }

    func testFlexibleHabitRemainsDueUntilWeeklyTargetIsMet() {
        let habit = Habit(
            name: "Train",
            createdAt: date(2026, 9, 28),
            weeklyTarget: 3
        )
        let checkIns = [
            checkIn(habit, 2026, 9, 28),
            checkIn(habit, 2026, 9, 30)
        ]

        XCTAssertTrue(
            HabitFrequency.isDue(
                habit: habit,
                on: date(2026, 10, 1),
                checkIns: checkIns,
                calendar: calendar
            )
        )
    }

    func testFlexibleHabitStopsBeingDueAfterTargetButStaysVisibleOnCompletionDay() {
        let habit = Habit(
            name: "Train",
            createdAt: date(2026, 9, 28),
            weeklyTarget: 3
        )
        let checkIns = [
            checkIn(habit, 2026, 9, 28),
            checkIn(habit, 2026, 9, 30),
            checkIn(habit, 2026, 10, 1)
        ]

        XCTAssertTrue(
            HabitFrequency.isDue(
                habit: habit,
                on: date(2026, 10, 1),
                checkIns: checkIns,
                calendar: calendar
            )
        )
        XCTAssertFalse(
            HabitFrequency.isDue(
                habit: habit,
                on: date(2026, 10, 2),
                checkIns: checkIns,
                calendar: calendar
            )
        )
    }

    func testFlexibleHabitReturnsAtStartOfNextWeek() {
        let habit = Habit(
            name: "Train",
            createdAt: date(2026, 9, 28),
            weeklyTarget: 2
        )
        let checkIns = [
            checkIn(habit, 2026, 9, 28),
            checkIn(habit, 2026, 9, 30)
        ]

        XCTAssertTrue(
            HabitFrequency.isDue(
                habit: habit,
                on: date(2026, 10, 5),
                checkIns: checkIns,
                calendar: calendar
            )
        )
    }

    func testWeeklyStreakCountsCompletedWeeks() {
        let habit = Habit(
            name: "Gym",
            createdAt: date(2026, 9, 21),
            weeklyTarget: 2
        )
        let checkIns = [
            checkIn(habit, 2026, 9, 21),
            checkIn(habit, 2026, 9, 23),
            checkIn(habit, 2026, 9, 28),
            checkIn(habit, 2026, 9, 30),
            checkIn(habit, 2026, 10, 5)
        ]

        XCTAssertEqual(
            HabitMetrics.currentStreak(
                habit: habit,
                checkIns: checkIns,
                today: date(2026, 10, 7),
                calendar: calendar
            ),
            2
        )
    }

    func testWeeklyCompletionRateDoesNotPenalizeUnfinishedCurrentWeek() {
        let habit = Habit(
            name: "Gym",
            createdAt: date(2026, 9, 21),
            weeklyTarget: 2
        )
        let checkIns = [
            checkIn(habit, 2026, 9, 21),
            checkIn(habit, 2026, 9, 23),
            checkIn(habit, 2026, 9, 28),
            checkIn(habit, 2026, 9, 30),
            checkIn(habit, 2026, 10, 5)
        ]

        XCTAssertEqual(
            HabitMetrics.completionRate(
                habit: habit,
                checkIns: checkIns,
                through: date(2026, 10, 7),
                calendar: calendar
            ),
            1,
            accuracy: 0.0001
        )
    }

    private func checkIn(
        _ habit: Habit,
        _ year: Int,
        _ month: Int,
        _ day: Int
    ) -> HabitCheckIn {
        HabitCheckIn(
            habitID: habit.id,
            day: date(year, month, day),
            calendar: calendar
        )
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: 12
            )
        )!
    }
}

extension HabitFrequencyTests {
    func testWeeklyCountUsesStableDayKeysAcrossTimezoneChange() {
        let habit = Habit(
            name: "Read",
            createdAt: date(2026, 9, 28),
            weeklyTarget: 2
        )
        let checkIn = HabitCheckIn(
            habitID: habit.id,
            day: date(2026, 9, 28),
            calendar: calendar
        )

        var farEast = Calendar(identifier: .gregorian)
        farEast.timeZone = TimeZone(secondsFromGMT: 12 * 60 * 60)!
        farEast.firstWeekday = 2

        XCTAssertEqual(
            HabitFrequency.weeklyCompletionCount(
                habit: habit,
                containing: date(2026, 9, 30),
                checkIns: [checkIn],
                calendar: farEast
            ),
            1
        )
    }
}
