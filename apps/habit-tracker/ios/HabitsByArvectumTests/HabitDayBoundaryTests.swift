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
                    day: 28,
                    hour: 23,
                    minute: 30
                )
            )
        )

        XCTAssertEqual(
            HabitDayBoundary.delay(
                from: date,
                calendar: calendar
            ),
            1_800,
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
}
