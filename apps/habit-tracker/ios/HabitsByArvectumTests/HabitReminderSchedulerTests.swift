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

    func testReminderContentCarriesCompletionActionMetadata() {
        let habit = Habit(name: "Read")
        let content = HabitReminderScheduler.notificationContent(for: habit)

        XCTAssertEqual(
            content.categoryIdentifier,
            HabitNotificationActions.categoryIdentifier
        )
        XCTAssertEqual(
            content.userInfo[HabitNotificationActions.habitIDKey] as? String,
            habit.id.uuidString
        )
    }

    func testFixedScheduleReminderIsEligible() {
        let habit = Habit(
            name: "Reading",
            reminderEnabled: true
        )

        XCTAssertTrue(HabitReminderScheduler.shouldSchedule(habit: habit))
    }

    func testFlexibleWeeklyGoalDoesNotScheduleReminder() {
        let habit = Habit(
            name: "Workout",
            reminderEnabled: true,
            weeklyTarget: 3
        )

        XCTAssertFalse(HabitReminderScheduler.shouldSchedule(habit: habit))
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
