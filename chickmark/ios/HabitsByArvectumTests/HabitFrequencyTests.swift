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

    func testCreationWeekTargetShrinksToAvailableDays() {
        let habit = Habit(
            name: "Gym",
            createdAt: date(2026, 10, 3),
            weeklyTarget: 5
        )

        XCTAssertEqual(
            HabitFrequency.effectiveWeeklyTarget(
                habit: habit,
                containing: date(2026, 10, 4),
                calendar: calendar
            ),
            2
        )

        let checkIns = [
            checkIn(habit, 2026, 10, 3),
            checkIn(habit, 2026, 10, 4)
        ]
        XCTAssertTrue(
            HabitFrequency.weekHasMetTarget(
                habit: habit,
                containing: date(2026, 10, 4),
                checkIns: checkIns,
                calendar: calendar
            )
        )
    }

    func testPartialPauseShrinksWeeklyTargetToActiveDays() {
        let habit = Habit(
            name: "Gym",
            createdAt: date(2026, 9, 28),
            weeklyTarget: 5
        )
        let pause = HabitPausePeriod(
            habitID: habit.id,
            startedAt: date(2026, 9, 29),
            endedAt: date(2026, 10, 3),
            calendar: calendar
        )

        XCTAssertEqual(
            HabitFrequency.effectiveWeeklyTarget(
                habit: habit,
                containing: date(2026, 10, 4),
                pausePeriods: [pause],
                calendar: calendar
            ),
            3
        )

        let checkIns = [
            checkIn(habit, 2026, 9, 28),
            checkIn(habit, 2026, 10, 3),
            checkIn(habit, 2026, 10, 4)
        ]
        XCTAssertTrue(
            HabitFrequency.weekHasMetTarget(
                habit: habit,
                containing: date(2026, 10, 4),
                checkIns: checkIns,
                pausePeriods: [pause],
                calendar: calendar
            )
        )
    }


    func testSkipsShrinkImpossibleFlexibleWeeklyTarget() {
        let habit = Habit(
            name: "Gym",
            createdAt: date(2026, 9, 28),
            weeklyTarget: 5
        )
        let skips = [
            HabitSkip(habitID: habit.id, day: date(2026, 9, 28), calendar: calendar),
            HabitSkip(habitID: habit.id, day: date(2026, 9, 29), calendar: calendar),
            HabitSkip(habitID: habit.id, day: date(2026, 9, 30), calendar: calendar)
        ]

        XCTAssertEqual(
            HabitFrequency.effectiveWeeklyTarget(
                habit: habit,
                containing: date(2026, 10, 4),
                skips: skips,
                calendar: calendar
            ),
            4
        )

        let checkIns = [
            checkIn(habit, 2026, 10, 1),
            checkIn(habit, 2026, 10, 2),
            checkIn(habit, 2026, 10, 3),
            checkIn(habit, 2026, 10, 4)
        ]

        XCTAssertTrue(
            HabitFrequency.weekHasMetTarget(
                habit: habit,
                containing: date(2026, 10, 4),
                checkIns: checkIns,
                skips: skips,
                calendar: calendar
            )
        )
    }


    func testSkipAwareWeeklyMetricsUseReducedTarget() {
        let habit = Habit(
            name: "Gym",
            createdAt: date(2026, 9, 28),
            weeklyTarget: 5
        )
        let skips = [
            skip(habit, 2026, 9, 28),
            skip(habit, 2026, 9, 29),
            skip(habit, 2026, 9, 30)
        ]
        let checkIns = [
            checkIn(habit, 2026, 10, 1),
            checkIn(habit, 2026, 10, 2),
            checkIn(habit, 2026, 10, 3),
            checkIn(habit, 2026, 10, 4)
        ]

        XCTAssertEqual(
            HabitMetrics.currentStreak(
                habit: habit,
                checkIns: checkIns,
                skips: skips,
                today: date(2026, 10, 7),
                calendar: calendar
            ),
            1
        )
        XCTAssertEqual(
            HabitMetrics.bestStreak(
                habit: habit,
                checkIns: checkIns,
                skips: skips,
                through: date(2026, 10, 7),
                calendar: calendar
            ),
            1
        )
        XCTAssertEqual(
            HabitMetrics.completionRate(
                habit: habit,
                checkIns: checkIns,
                skips: skips,
                through: date(2026, 10, 7),
                calendar: calendar
            ),
            1,
            accuracy: 0.0001
        )
    }

    func testFullySkippedFlexibleWeekIsNeutral() {
        let habit = Habit(
            name: "Gym",
            createdAt: date(2026, 9, 21),
            weeklyTarget: 2
        )
        let checkIns = [
            checkIn(habit, 2026, 9, 21),
            checkIn(habit, 2026, 9, 23)
        ]
        let skips = (0..<7).map { offset -> HabitSkip in
            let day = calendar.date(
                byAdding: .day,
                value: offset,
                to: date(2026, 9, 28)
            )!
            return HabitSkip(
                habitID: habit.id,
                day: day,
                calendar: calendar
            )
        }

        XCTAssertEqual(
            HabitFrequency.effectiveWeeklyTarget(
                habit: habit,
                containing: date(2026, 10, 4),
                skips: skips,
                calendar: calendar
            ),
            0
        )
        XCTAssertEqual(
            HabitMetrics.currentStreak(
                habit: habit,
                checkIns: checkIns,
                skips: skips,
                today: date(2026, 10, 7),
                calendar: calendar
            ),
            1
        )
        XCTAssertEqual(
            HabitMetrics.bestStreak(
                habit: habit,
                checkIns: checkIns,
                skips: skips,
                through: date(2026, 10, 7),
                calendar: calendar
            ),
            1
        )
        XCTAssertEqual(
            HabitMetrics.completionRate(
                habit: habit,
                checkIns: checkIns,
                skips: skips,
                through: date(2026, 10, 7),
                calendar: calendar
            ),
            1,
            accuracy: 0.0001
        )
    }

    func testCompletionIntervalHabitIsDueImmediatelyBeforeFirstCheckIn() {
        let habit = Habit(
            name: "Water filter",
            createdAt: date(2026, 10, 1)
        )
        habit.completionIntervalDays = 30

        XCTAssertTrue(habit.usesCompletionInterval)
        XCTAssertEqual(habit.weeklyTarget, -30)
        XCTAssertTrue(
            HabitFrequency.isDue(
                habit: habit,
                on: date(2026, 10, 1),
                checkIns: [],
                calendar: calendar
            )
        )
    }

    func testCompletionIntervalMovesFromActualCompletionDay() {
        let habit = Habit(
            name: "Maintenance",
            createdAt: date(2026, 10, 1)
        )
        habit.completionIntervalDays = 3
        let first = checkIn(habit, 2026, 10, 1)

        XCTAssertFalse(
            HabitFrequency.isDue(
                habit: habit,
                on: date(2026, 10, 3),
                checkIns: [first],
                calendar: calendar
            )
        )
        XCTAssertTrue(
            HabitFrequency.isDue(
                habit: habit,
                on: date(2026, 10, 4),
                checkIns: [first],
                calendar: calendar
            )
        )

        let late = checkIn(habit, 2026, 10, 6)
        XCTAssertTrue(
            HabitFrequency.isDue(
                habit: habit,
                on: date(2026, 10, 6),
                checkIns: [first, late],
                calendar: calendar
            )
        )
        XCTAssertFalse(
            HabitFrequency.isDue(
                habit: habit,
                on: date(2026, 10, 8),
                checkIns: [first, late],
                calendar: calendar
            )
        )
        XCTAssertTrue(
            HabitFrequency.isDue(
                habit: habit,
                on: date(2026, 10, 9),
                checkIns: [first, late],
                calendar: calendar
            )
        )
    }

    func testCompletionIntervalNextDueDateIgnoresFutureCheckIns() throws {
        let habit = Habit(
            name: "Service",
            createdAt: date(2026, 10, 1)
        )
        habit.completionIntervalDays = 5
        let first = checkIn(habit, 2026, 10, 1)
        let future = checkIn(habit, 2026, 10, 20)

        let due = try XCTUnwrap(
            HabitFrequency.nextCompletionIntervalDueDate(
                habit: habit,
                checkIns: [first, future],
                through: date(2026, 10, 3),
                calendar: calendar
            )
        )

        XCTAssertEqual(
            HabitDayKey.make(for: due, calendar: calendar),
            "2026-10-06"
        )
    }

    private func skip(
        _ habit: Habit,
        _ year: Int,
        _ month: Int,
        _ day: Int
    ) -> HabitSkip {
        HabitSkip(
            habitID: habit.id,
            day: date(year, month, day),
            calendar: calendar
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
