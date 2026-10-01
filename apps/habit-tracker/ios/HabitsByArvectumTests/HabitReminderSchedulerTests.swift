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

    func testCompletedTodaySuppressesTodaysReminderButKeepsTomorrow() {
        let calendar = utcCalendar
        let habit = Habit(
            name: "Read",
            reminderEnabled: true,
            reminderHour: 20,
            reminderMinute: 0
        )
        let reference = date(2026, 10, 1, hour: 8, calendar: calendar)
        let checkIn = HabitCheckIn(
            habitID: habit.id,
            day: reference,
            calendar: calendar
        )

        let dates = HabitReminderScheduler.reminderDates(
            habit: habit,
            checkIns: [checkIn],
            from: reference,
            daysAhead: 3,
            calendar: calendar
        )

        XCTAssertEqual(dates.count, 2)
        XCTAssertEqual(calendar.component(.day, from: dates[0]), 2)
        XCTAssertEqual(calendar.component(.hour, from: dates[0]), 20)
    }

    func testSkippedTodaySuppressesTodaysReminder() {
        let calendar = utcCalendar
        let habit = Habit(
            name: "Walk",
            reminderEnabled: true,
            reminderHour: 18,
            reminderMinute: 30
        )
        let reference = date(2026, 10, 1, hour: 9, calendar: calendar)
        let skip = HabitSkip(
            habitID: habit.id,
            day: reference,
            calendar: calendar
        )

        let dates = HabitReminderScheduler.reminderDates(
            habit: habit,
            skips: [skip],
            from: reference,
            daysAhead: 2,
            calendar: calendar
        )

        XCTAssertEqual(dates.count, 1)
        XCTAssertEqual(calendar.component(.day, from: dates[0]), 2)
        XCTAssertEqual(calendar.component(.hour, from: dates[0]), 18)
        XCTAssertEqual(calendar.component(.minute, from: dates[0]), 30)
    }

    func testReminderAfterItsTimeStartsFromNextEligibleDay() {
        let calendar = utcCalendar
        let habit = Habit(
            name: "Read",
            reminderEnabled: true,
            reminderHour: 20,
            reminderMinute: 0
        )
        let reference = date(2026, 10, 1, hour: 21, calendar: calendar)

        let dates = HabitReminderScheduler.reminderDates(
            habit: habit,
            from: reference,
            daysAhead: 2,
            calendar: calendar
        )

        XCTAssertEqual(dates.count, 1)
        XCTAssertEqual(calendar.component(.day, from: dates[0]), 2)
        XCTAssertEqual(calendar.component(.hour, from: dates[0]), 20)
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        hour: Int,
        calendar: Calendar
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour
            )
        )!
    }
}
