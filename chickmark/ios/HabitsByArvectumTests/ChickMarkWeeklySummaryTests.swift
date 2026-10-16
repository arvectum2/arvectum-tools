import XCTest
@testable import HabitsByArvectum

final class ChickMarkWeeklySummaryTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
    }

    private func day(_ month: Int = 10, _ number: Int, _ year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(
            year: year, month: month, day: number, hour: 12
        ))!
    }

    private func done(_ habit: Habit, _ month: Int = 10, _ date: Int) -> HabitCheckIn {
        HabitCheckIn(habitID: habit.id, day: day(month, date), calendar: calendar)
    }

    private func report(
        _ habits: [Habit], _ checkIns: [HabitCheckIn],
        skips: [HabitSkip] = [], pauses: [HabitPausePeriod] = [],
        today: Date? = nil
    ) -> ChickMarkWeeklyReport {
        ChickMarkWeeklySummary.report(
            habits: habits, checkIns: checkIns, skips: skips,
            pausePeriods: pauses, today: today ?? day(10, 16),
            calendar: calendar
        )
    }

    func testNoHistoryIsNotAZeroPercentAchievement() {
        let none = report([], [])
        XCTAssertEqual(none.lastWeek.scheduledEligible, 0)
        XCTAssertEqual(none.lastWeek.scheduledCompleted, 0)
        XCTAssertNil(none.lastWeek.bestDay)
        XCTAssertEqual(none.lastWeek.completionDays, 0)
        XCTAssertEqual(none.changeInCompletions, 0)
    }

    func testCompletedWeeksAndNeutralDaysExcludeCurrentUnfinishedWeek() {
        let habit = Habit(name: "Read", createdAt: day(9, 1))
        let rows = [
            done(habit, 9, 29),
            done(habit, 10, 5),
            done(habit, 10, 7),
            done(habit, 10, 8),
            done(habit, 10, 16) // current week, NEVER included
        ]
        let skip = HabitSkip(
            habitID: habit.id, day: day(10, 6), calendar: calendar
        )
        let pause = HabitPausePeriod(
            habitID: habit.id, startedAt: day(10, 9),
            endedAt: day(10, 12), calendar: calendar
        )
        let result = report([habit], rows, skips: [skip], pauses: [pause])
        XCTAssertEqual(result.lastWeek.scheduledCompleted, 3)
        XCTAssertEqual(result.lastWeek.scheduledEligible, 3)
        XCTAssertEqual(result.lastWeek.scheduledNeutral, 4)
        XCTAssertEqual(result.lastWeek.completionDays, 3)
        XCTAssertEqual(result.weekBefore.completionDays, 1)
        XCTAssertEqual(result.changeInCompletions, 2)
        XCTAssertEqual(
            HabitDayKey.make(for: result.lastWeek.bestDay!, calendar: calendar),
            HabitDayKey.make(for: day(10, 5), calendar: calendar)
        )
    }

    func testWeeklyFlexGoalsCountWholeWeeksNotSevenMissedDays() {
        let met = Habit(name: "Run", createdAt: day(9, 20), weeklyTarget: 3)
        let notMet = Habit(name: "Gym", createdAt: day(9, 20), weeklyTarget: 2)
        let rows = [
            done(met, 10, 5), done(met, 10, 7), done(met, 10, 11),
            done(notMet, 10, 7)
        ]
        let skip = HabitSkip(habitID: met.id, day: day(10, 6), calendar: calendar)
        let result = report([met, notMet], rows, skips: [skip])
        XCTAssertEqual(result.lastWeek.flexibleGoalsEligible, 2)
        XCTAssertEqual(result.lastWeek.flexibleGoalsMet, 1)
        XCTAssertEqual(result.lastWeek.scheduledEligible, 0)
        XCTAssertEqual(result.lastWeek.completionDays, 4)
        XCTAssertEqual(result.lastWeek.bestDayCompletions, 2)
    }

    func testRollingOccurrencesAreNotFalseMissedDays() {
        let habit = Habit(name: "Filter", createdAt: day(9, 1))
        habit.completionIntervalDays = 14
        let last = report(
            [habit],
            [done(habit, 10, 6), done(habit, 10, 11)]
        ).lastWeek
        XCTAssertEqual(last.intervalOccurrences, 2)
        XCTAssertEqual(last.scheduledEligible, 0)
        XCTAssertEqual(last.flexibleGoalsEligible, 0)
        XCTAssertEqual(last.completionDays, 2)
    }

    func testPartialMultiCheckNeedsFullGoalAndDeduplicatesActivity() {
        let habit = Habit(name: "Water", createdAt: day(9, 1))
        habit.goalMode = .multiCheck(times: 5)
        var rows = (0..<4).map { _ in done(habit, 10, 5) }
        rows += (0..<5).map { _ in done(habit, 10, 6) }
        let summary = report([habit], rows).lastWeek
        XCTAssertEqual(summary.scheduledCompleted, 1)
        XCTAssertEqual(summary.scheduledEligible, 7)
        XCTAssertEqual(summary.completionDays, 1)
        XCTAssertEqual(summary.bestDayCompletions, 1)
    }

    func testFutureOrArchivedHabitNotCounted() {
        let future = Habit(name: "Future", createdAt: day(10, 20))
        let archived = Habit(name: "Archived", createdAt: day(9, 1), isArchived: true)
        let result = report([future, archived], [done(archived, 10, 7)])
        XCTAssertEqual(result.lastWeek.scheduledEligible, 0)
        XCTAssertEqual(result.lastWeek.completionDays, 0)
    }

    func testDstFallBackWeekStaysSevenCalendarDays() {
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let habit = Habit(name: "Walk", createdAt: day(9, 1))
        let rows = [done(habit, 10, 26), done(habit, 11, 1)]
        let result = report([habit], rows, today: day(11, 3))
        XCTAssertEqual(result.lastWeek.scheduledEligible, 7)
        XCTAssertEqual(result.lastWeek.scheduledCompleted, 2)
        XCTAssertEqual(result.lastWeek.completionDays, 2)
        XCTAssertEqual(result.lastWeek.bestDayCompletions, 1)
    }

    func testAllPausedWeekAndSkippedWeekHaveNoWeeklyEligibleDays() {
        let habit = Habit(name: "Walk", createdAt: day(9, 1), weeklyTarget: 3)
        let pause = HabitPausePeriod(
            habitID: habit.id, startedAt: day(10, 5),
            endedAt: day(10, 12), calendar: calendar
        )
        let result = report([habit], [], pauses: [pause])
        XCTAssertEqual(result.lastWeek.flexibleGoalsEligible, 0)
        XCTAssertEqual(result.lastWeek.flexibleGoalsMet, 0)
    }
}
