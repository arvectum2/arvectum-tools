import XCTest
@testable import HabitsByArvectum

final class HabitDayBoundaryTests: XCTestCase {
    func testNextBoundaryIsNextLocalMidnight() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(
            TimeZone(identifier: "Europe/London")
        )

        let date = try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 10,
                    day: 1,
                    hour: 20,
                    minute: 30
                )
            )
        )
        let next = HabitDayBoundary.next(
            after: date,
            calendar: calendar
        )
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: next
        )

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 10)
        XCTAssertEqual(components.day, 2)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
    }

    func testDelayUsesCalendarDayAcrossSpringDST() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(
            TimeZone(identifier: "Europe/London")
        )

        let date = try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 3,
                    day: 29,
                    hour: 0,
                    minute: 30
                )
            )
        )

        XCTAssertEqual(
            HabitDayBoundary.delay(
                from: date,
                calendar: calendar
            ),
            22.5 * 60 * 60,
            accuracy: 0.1
        )
    }

    func testNextBoundaryHandlesAutumnDSTWithoutFixed86400Assumption() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(
            TimeZone(identifier: "Europe/London")
        )

        let date = try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 10,
                    day: 25,
                    hour: 0,
                    minute: 30
                )
            )
        )
        let next = HabitDayBoundary.next(
            after: date,
            calendar: calendar
        )
        let components = calendar.dateComponents(
            [.day, .hour, .minute],
            from: next
        )

        XCTAssertEqual(components.day, 26)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertGreaterThan(
            next.timeIntervalSince(date),
            23 * 60 * 60
        )
    }

    func testTimezoneTravelRecomputesUpcomingMidnightFromLocalCalendar() throws {
        // A3: same absolute moment is already Oct 14 in London but remains
        // Oct 13 in New York. A one-size-fits-all 86,400 second timer is wrong.
        let instant = try XCTUnwrap(
            ISO8601DateFormatter().date(from: "2026-10-14T00:30:00Z")
        )
        var london = Calendar(identifier: .gregorian)
        london.timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/London"))
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))

        XCTAssertEqual(HabitDayKey.make(for: instant, calendar: london), "2026-10-14")
        XCTAssertEqual(HabitDayKey.make(for: instant, calendar: newYork), "2026-10-13")
        XCTAssertEqual(
            HabitDayBoundary.delay(from: instant, calendar: london),
            22.5 * 3600, accuracy: 1
        )
        XCTAssertEqual(
            HabitDayBoundary.delay(from: instant, calendar: newYork),
            3.5 * 3600, accuracy: 1
        )
        let localCheckIn = HabitCheckIn(
            habitID: UUID(), day: instant, calendar: london
        )
        XCTAssertEqual(localCheckIn.dayKey, "2026-10-14")
        XCTAssertTrue(HabitDayKey.matches(localCheckIn, on: instant, calendar: london))
        XCTAssertFalse(HabitDayKey.matches(localCheckIn, on: instant, calendar: newYork))
    }

    func testNewYorkBothDSTTransitionsUseActualLocalMidnight() throws {
        // A3: EDT spring day has 23 hours, EST autumn day has 25.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(
            TimeZone(identifier: "America/New_York")
        )
        let spring = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 3, day: 8, hour: 0, minute: 30
        )))
        let autumn = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026, month: 11, day: 1, hour: 0, minute: 30
        )))
        XCTAssertEqual(
            HabitDayBoundary.delay(from: spring, calendar: calendar),
            22.5 * 3600, accuracy: 1
        )
        XCTAssertEqual(
            HabitDayBoundary.delay(from: autumn, calendar: calendar),
            24.5 * 3600, accuracy: 1
        )
        XCTAssertEqual(
            HabitDayKey.make(for: HabitDayBoundary.next(after: spring, calendar: calendar),
                             calendar: calendar),
            "2026-03-09"
        )
        XCTAssertEqual(
            HabitDayKey.make(for: HabitDayBoundary.next(after: autumn, calendar: calendar),
                             calendar: calendar),
            "2026-11-02"
        )
    }

}
