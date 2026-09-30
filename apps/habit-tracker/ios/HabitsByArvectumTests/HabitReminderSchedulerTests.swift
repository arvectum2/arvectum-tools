import XCTest
@testable import HabitsByArvectum

final class HabitReminderSchedulerTests: XCTestCase {
    func testWeekdayScheduleMapsToCalendarWeekdays() {
        XCTAssertEqual(
            HabitReminderScheduler.weekdayNumbers(for: .weekdays),
            [2, 3, 4, 5, 6]
        )
    }

    func testEveryDayMapsToAllCalendarWeekdays() {
        XCTAssertEqual(
            HabitReminderScheduler.weekdayNumbers(for: .everyDay),
            [1, 2, 3, 4, 5, 6, 7]
        )
    }

    func testReminderComponentsPreserveSelectedTime() {
        let components = HabitReminderScheduler.notificationComponents(
            schedule: [.monday, .sunday],
            hour: 7,
            minute: 45
        )

        XCTAssertEqual(components.count, 2)
        XCTAssertEqual(components.map(\.weekday), [1, 2])
        XCTAssertTrue(
            components.allSatisfy {
                $0.hour == 7 && $0.minute == 45
            }
        )
    }
}
