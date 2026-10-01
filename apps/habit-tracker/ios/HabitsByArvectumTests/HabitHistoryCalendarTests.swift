import XCTest
@testable import HabitsByArvectum

final class HabitHistoryCalendarTests: XCTestCase {
    func testVisibleDaysAlignToWholeWeeks() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2

        let date = try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 10,
                    day: 1
                )
            )
        )

        let days = HabitHistoryCalendar.visibleDays(
            endingInWeekContaining: date,
            weeks: 6,
            calendar: calendar
        )

        XCTAssertEqual(days.count, 42)
        XCTAssertEqual(calendar.component(.weekday, from: days[0]), 2)
        XCTAssertEqual(calendar.component(.weekday, from: days[41]), 1)
        XCTAssertEqual(
            calendar.dateComponents(
                [.year, .month, .day],
                from: days[0]
            ),
            DateComponents(year: 2026, month: 8, day: 24)
        )
        XCTAssertEqual(
            calendar.dateComponents(
                [.year, .month, .day],
                from: days[41]
            ),
            DateComponents(year: 2026, month: 10, day: 4)
        )
    }

    func testWeekdaySymbolsRespectCalendarFirstWeekday() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2

        let symbols = HabitHistoryCalendar.weekdaySymbols(
            calendar: calendar,
            locale: Locale(identifier: "en_US_POSIX")
        )

        XCTAssertEqual(symbols.count, 7)
        XCTAssertEqual(symbols.first, "M")
        XCTAssertEqual(symbols.last, "S")
    }
}
