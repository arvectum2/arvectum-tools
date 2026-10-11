import XCTest
@testable import HabitsByArvectum

final class HabitTodayProjectionTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testProjectionPreservesExplicitUserOrder() throws {
        let date = try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 10,
                    day: 1,
                    hour: 12
                )
            )
        )
        let first = Habit(
            name: "First",
            createdAt: date.addingTimeInterval(-300),
            sortOrder: 0
        )
        let second = Habit(
            name: "Second",
            createdAt: date.addingTimeInterval(-600),
            sortOrder: 1
        )
        let third = Habit(
            name: "Third",
            createdAt: date.addingTimeInterval(-900),
            sortOrder: 2
        )

        let result = HabitTodayProjection.orderedDueHabits(
            habits: [third, second, first],
            on: date,
            checkIns: [],
            skips: [],
            pausePeriods: [],
            calendar: calendar
        )

        XCTAssertEqual(
            result.map(\.name),
            ["First", "Second", "Third"]
        )
    }

    func testProjectionExcludesArchivedPausedAndNotDueHabits() throws {
        let thursday = try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 10,
                    day: 1,
                    hour: 12
                )
            )
        )
        let due = Habit(name: "Due", sortOrder: 4)
        let archived = Habit(
            name: "Archived",
            isArchived: true,
            sortOrder: 0
        )
        let paused = Habit(
            name: "Paused",
            pausedAt: thursday,
            sortOrder: 1
        )
        let mondayOnly = Habit(
            name: "Monday",
            scheduleMask: HabitSchedule.monday.rawValue,
            sortOrder: 2
        )

        let result = HabitTodayProjection.orderedDueHabits(
            habits: [archived, paused, mondayOnly, due],
            on: thursday,
            checkIns: [],
            skips: [],
            pausePeriods: [],
            calendar: calendar
        )

        XCTAssertEqual(result.map(\.name), ["Due"])
    }

    func testProjectionKeepsFlexibleHabitDueUntilWeeklyTargetIsMet() throws {
        let thursday = try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 10,
                    day: 1,
                    hour: 12
                )
            )
        )
        let habit = Habit(
            name: "Workout",
            createdAt: thursday.addingTimeInterval(-86_400 * 3),
            weeklyTarget: 2
        )
        let monday = try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 9,
                    day: 28,
                    hour: 12
                )
            )
        )

        XCTAssertEqual(
            HabitTodayProjection.orderedDueHabits(
                habits: [habit],
                on: thursday,
                checkIns: [
                    HabitCheckIn(
                        habitID: habit.id,
                        day: monday,
                        calendar: calendar
                    )
                ],
                skips: [],
                pausePeriods: [],
                calendar: calendar
            ).map(\.name),
            ["Workout"]
        )

        let tuesday = try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 9,
                    day: 29,
                    hour: 12
                )
            )
        )

        XCTAssertTrue(
            HabitTodayProjection.orderedDueHabits(
                habits: [habit],
                on: thursday,
                checkIns: [
                    HabitCheckIn(
                        habitID: habit.id,
                        day: monday,
                        calendar: calendar
                    ),
                    HabitCheckIn(
                        habitID: habit.id,
                        day: tuesday,
                        calendar: calendar
                    )
                ],
                skips: [],
                pausePeriods: [],
                calendar: calendar
            ).isEmpty
        )
    }
}
