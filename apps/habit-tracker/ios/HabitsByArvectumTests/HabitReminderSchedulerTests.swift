import XCTest
@testable import HabitsByArvectum

final class HabitReminderSchedulerTests: XCTestCase {
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


    func testRequestIdentifierIsStableAndUniqueByDay() {
        let habitID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000123"
        )!

        XCTAssertEqual(
            HabitReminderScheduler.requestIdentifier(
                habitID: habitID,
                dayKey: "2026-10-01"
            ),
            "habit-reminder-00000000-0000-0000-0000-000000000123-2026-10-01"
        )
        XCTAssertNotEqual(
            HabitReminderScheduler.requestIdentifier(
                habitID: habitID,
                dayKey: "2026-10-01"
            ),
            HabitReminderScheduler.requestIdentifier(
                habitID: habitID,
                dayKey: "2026-10-02"
            )
        )
    }

    func testSingleDailyHabitUsesFullDefaultReminderHorizon() {
        let calendar = utcCalendar
        let reference = date(2026, 10, 1, hour: 8, calendar: calendar)
        let habit = Habit(
            name: "Read",
            reminderEnabled: true,
            reminderHour: 20,
            reminderMinute: 0
        )

        let plan = HabitReminderScheduler.reminderPlan(
            habits: [habit],
            from: reference,
            calendar: calendar
        )

        XCTAssertEqual(plan.count, 60)
        XCTAssertEqual(plan.first?.dayKey, "2026-10-01")
        XCTAssertEqual(plan.last?.dayKey, "2026-11-29")
    }

    func testLargeReminderPlanIsBoundedAndPrioritizesNearestDays() {
        let calendar = utcCalendar
        let reference = date(2026, 10, 1, hour: 8, calendar: calendar)
        let habits = (0..<10).map { index in
            Habit(
                name: "Habit " + String(index),
                createdAt: reference.addingTimeInterval(Double(index)),
                reminderEnabled: true,
                reminderHour: 20,
                reminderMinute: 0,
                sortOrder: index
            )
        }

        let plan = HabitReminderScheduler.reminderPlan(
            habits: habits,
            from: reference,
            daysAhead: 14,
            limit: 60,
            calendar: calendar
        )

        XCTAssertEqual(plan.count, 60)
        XCTAssertEqual(Set(plan.map(\.habitID)).count, 10)
        XCTAssertEqual(
            Set(plan.map(\.dayKey)),
            Set([
                "2026-10-01",
                "2026-10-02",
                "2026-10-03",
                "2026-10-04",
                "2026-10-05",
                "2026-10-06"
            ])
        )

        for habit in habits {
            XCTAssertEqual(
                plan.filter { $0.habitID == habit.id }.count,
                6
            )
        }
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
