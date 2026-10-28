import XCTest
@testable import ArvectumNotify

@MainActor
final class NotificationHistoryFilterTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int,
                      _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month,
                                           day: day, hour: hour))!
    }

    private func item(_ app: String, at time: Date, body: String = "Message")
        -> NotificationHistoryItem {
        NotificationHistoryItem(CapturedNotification(
            sourceApp: app, titleText: "Notification", subtitleText: "", bodyText: body,
            receivedAt: time, capturedAt: time
        ))
    }

    func testSourceDateAndSearchCombineWithoutMutatingHistory() {
        let now = date(2026, 10, 28)
        let values = [item("Telegram", at: date(2026, 10, 28), body: "Report"),
                      item("Mail", at: date(2026, 10, 27), body: "Report"),
                      item("Telegram", at: date(2026, 10, 10), body: "Old report")]
        let matches = NotificationHistoryFilter.apply(
            values, query: "  report  ", source: "Telegram", period: .last7Days,
            now: now, calendar: calendar
        )
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches[0].sourceApp, "Telegram")
        XCTAssertEqual(values.count, 3, "Filtering cannot delete or rewrite records")
        XCTAssertEqual(NotificationHistoryFilter.sources(in: values), ["Mail", "Telegram"])
    }

    func testTodayUsesLocalMidnightAcrossDaylightSavingTime() {
        // DST starts March 8, 2026 in New York. Yesterday must not leak into
        // Today even though the local midnight offset changes.
        let now = date(2026, 3, 8, 16)
        let values = [item("Yesterday", at: date(2026, 3, 7, 23)),
                      item("Today", at: date(2026, 3, 8, 0))]
        let found = NotificationHistoryFilter.apply(
            values, period: .today, now: now, calendar: calendar
        )
        XCTAssertEqual(found.map(\.sourceApp), ["Today"])
    }

    func testSevenAndThirtyCalendarDayBoundaries() {
        let now = date(2026, 3, 1)
        let values = [item("Seven", at: date(2026, 2, 22)),
                      item("Thirty", at: date(2026, 1, 30)),
                      item("Old", at: date(2026, 1, 29))]
        XCTAssertEqual(NotificationHistoryFilter.apply(
            values, period: .last7Days, now: now, calendar: calendar
        ).map(\.sourceApp), ["Seven"])
        XCTAssertEqual(NotificationHistoryFilter.apply(
            values, period: .last30Days, now: now, calendar: calendar
        ).map(\.sourceApp), ["Seven", "Thirty"])
    }

    func testDeletedLastSourceFallsBackToAllSources() {
        let values = [item("Mail", at: date(2026, 10, 27))]
        XCTAssertEqual(NotificationHistoryFilter.apply(
            values, source: "Telegram", now: date(2026, 10, 28)
        ).map(\.sourceApp), ["Mail"])
        XCTAssertTrue(NotificationHistoryFilter.apply([], source: "Telegram").isEmpty)
    }
}
