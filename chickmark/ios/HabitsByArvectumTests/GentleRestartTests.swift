import XCTest
@testable import HabitsByArvectum

final class GentleRestartTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    private func day(_ year: Int = 2026, _ month: Int = 10, _ value: Int) -> Date {
        calendar.date(from: DateComponents(
            year: year, month: month, day: value, hour: 12
        ))!
    }

    func testOptInCandidatesOnlyAfterQuietPeriod() {
        let habit = Habit(name: "Daily", createdAt: day(2026, 10, 1))
        let first = HabitCheckIn(habitID: habit.id, day: day(2026, 10, 7), calendar: calendar)
        let before = first.dayKey
        let candidates = GentleRestart.candidates(
            habits: [habit], checkIns: [first], skips: [],
            pausePeriods: [], today: day(2026, 10, 16),
            minimumQuietDays: 7, calendar: calendar
        )
        XCTAssertEqual(candidates, [.init(habitID: habit.id, quietDays: 8)])
        XCTAssertEqual(first.dayKey, before, "Never rewrite real history")
        XCTAssertFalse(habit.isPaused)
        XCTAssertEqual(GentleRestart.candidates(
            habits: [habit], checkIns: [first], skips: [],
            pausePeriods: [], today: day(2026, 10, 9),
            minimumQuietDays: 7, calendar: calendar
        ).count, 0)
    }

    func testNoHintForNewOrArchivedOrPausedOrCompletedToday() {
        let habit = Habit(name: "Walk", createdAt: day(2026, 10, 1))
        let previous = HabitCheckIn(habitID: habit.id, day: day(2026, 10, 1), calendar: calendar)
        func results(_ rows: [HabitCheckIn]) -> [GentleRestartCandidate] {
            GentleRestart.candidates(
                habits: [habit], checkIns: rows, skips: [],
                pausePeriods: [], today: day(2026, 10, 16),
                minimumQuietDays: 3, calendar: calendar
            )
        }
        XCTAssertTrue(results([]).isEmpty)
        habit.isArchived = true
        XCTAssertTrue(results([previous]).isEmpty)
        habit.isArchived = false
        habit.pausedAt = day(2026, 10, 10)
        XCTAssertTrue(results([previous]).isEmpty)
        habit.pausedAt = nil
        XCTAssertTrue(results([previous, HabitCheckIn(
            habitID: habit.id, day: day(2026, 10, 16), calendar: calendar
        )]).isEmpty)
    }

    func testSkippedAndPausedDaysAreNeutral() {
        let habit = Habit(name: "Learn", createdAt: day(2026, 10, 1))
        let previous = HabitCheckIn(
            habitID: habit.id, day: day(2026, 10, 1), calendar: calendar
        )
        let skips = (2...15).map {
            HabitSkip(habitID: habit.id, day: day(2026, 10, $0), calendar: calendar)
        }
        let none = GentleRestart.candidates(
            habits: [habit], checkIns: [previous], skips: skips,
            pausePeriods: [], today: day(2026, 10, 16),
            minimumQuietDays: 3, calendar: calendar
        )
        XCTAssertTrue(none.isEmpty)

        let paused = HabitPausePeriod(
            habitID: habit.id,
            startedAt: day(2026, 10, 2),
            endedAt: day(2026, 10, 16),
            calendar: calendar
        )
        XCTAssertTrue(GentleRestart.candidates(
            habits: [habit], checkIns: [previous], skips: [],
            pausePeriods: [paused], today: day(2026, 10, 16),
            minimumQuietDays: 3, calendar: calendar
        ).isEmpty)
    }

    func testRollingScheduleDoesNotSuggestRestartOnTimelyDueDate() {
        let habit = Habit(name: "Filter", createdAt: day(2026, 10, 1))
        habit.completionIntervalDays = 14
        let row = HabitCheckIn(
            habitID: habit.id, day: day(2026, 10, 1), calendar: calendar
        )
        func result(_ date: Date) -> [GentleRestartCandidate] {
            GentleRestart.candidates(
                habits: [habit], checkIns: [row], skips: [],
                pausePeriods: [], today: date,
                minimumQuietDays: 3, calendar: calendar
            )
        }
        XCTAssertTrue(result(day(2026, 10, 15)).isEmpty)
        XCTAssertTrue(result(day(2026, 10, 17)).isEmpty)
        XCTAssertEqual(result(day(2026, 10, 18)),
                       [.init(habitID: habit.id, quietDays: 3)])
    }

    func testPartialQuantityGoalCannotCountAsPastCompletion() {
        let habit = Habit(name: "Water", createdAt: day(2026, 10, 1))
        habit.goalMode = .multiCheck(times: 5)
        let partial = HabitCheckIn(
            habitID: habit.id, day: day(2026, 10, 1), calendar: calendar
        )
        XCTAssertTrue(GentleRestart.candidates(
            habits: [habit], checkIns: [partial], skips: [],
            pausePeriods: [], today: day(2026, 10, 16),
            minimumQuietDays: 3, calendar: calendar
        ).isEmpty)
    }

    func testDstBoundaryUsesCalendarDaysNotSeconds() {
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let habit = Habit(name: "Read", createdAt: day(2026, 10, 1))
        let row = HabitCheckIn(
            habitID: habit.id, day: day(2026, 10, 31), calendar: calendar
        )
        let candidates = GentleRestart.candidates(
            habits: [habit], checkIns: [row], skips: [],
            pausePeriods: [], today: day(2026, 11, 5),
            minimumQuietDays: 3, calendar: calendar
        )
        XCTAssertEqual(candidates, [.init(habitID: habit.id, quietDays: 4)])
    }
}
