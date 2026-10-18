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

    func testOneOffReminderContentCarriesCompletionActionMetadata() {
        let reminder = OneOffReminder(
            title: "Buy marathon slot",
            dueAt: .now.addingTimeInterval(3600)
        )
        let content = HabitReminderScheduler.oneOffNotificationContent(
            for: reminder
        )

        XCTAssertEqual(
            content.categoryIdentifier,
            OneOffReminderNotificationActions.categoryIdentifier
        )
        XCTAssertEqual(
            content.userInfo[
                OneOffReminderNotificationActions.reminderIDKey
            ] as? String,
            reminder.id.uuidString
        )
        XCTAssertEqual(
            HabitReminderScheduler.oneOffRequestIdentifier(
                reminderID: reminder.id
            ),
            "one-off-reminder-" + reminder.id.uuidString
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


    func testCompletionIntervalSchedulesOnlyNextRelativeReminder() {
        let calendar = utcCalendar
        let habit = Habit(
            name: "Replace filter",
            reminderEnabled: true,
            reminderHour: 9,
            reminderMinute: 30
        )
        habit.completionIntervalDays = 3
        let first = HabitCheckIn(
            habitID: habit.id,
            day: date(2026, 10, 1, hour: 12, calendar: calendar),
            calendar: calendar
        )
        let reference = date(2026, 10, 2, hour: 8, calendar: calendar)

        let dates = HabitReminderScheduler.reminderDates(
            habit: habit,
            checkIns: [first],
            from: reference,
            calendar: calendar
        )

        XCTAssertEqual(dates.count, 1)
        XCTAssertEqual(
            HabitDayKey.make(for: dates[0], calendar: calendar),
            "2026-10-04"
        )
        XCTAssertEqual(calendar.component(.hour, from: dates[0]), 9)
        XCTAssertEqual(calendar.component(.minute, from: dates[0]), 30)
    }

    func testCompletionIntervalCanScheduleBeyondRollingSixtyDayHorizon() {
        let calendar = utcCalendar
        let habit = Habit(
            name: "Long interval",
            reminderEnabled: true,
            reminderHour: 10,
            reminderMinute: 0
        )
        habit.completionIntervalDays = 90
        let first = HabitCheckIn(
            habitID: habit.id,
            day: date(2026, 10, 1, hour: 12, calendar: calendar),
            calendar: calendar
        )
        let reference = date(2026, 10, 2, hour: 8, calendar: calendar)

        let dates = HabitReminderScheduler.reminderDates(
            habit: habit,
            checkIns: [first],
            from: reference,
            calendar: calendar
        )

        XCTAssertEqual(dates.count, 1)
        let expected = calendar.date(
            byAdding: .day,
            value: 90,
            to: calendar.startOfDay(
                for: date(2026, 10, 1, hour: 12, calendar: calendar)
            )
        )!
        XCTAssertEqual(
            HabitDayKey.make(for: dates[0], calendar: calendar),
            HabitDayKey.make(for: expected, calendar: calendar)
        )
    }

    func testOverdueCompletionIntervalSchedulesNextAvailableReminder() {
        let calendar = utcCalendar
        let habit = Habit(
            name: "Overdue task",
            createdAt: date(2026, 10, 1, hour: 12, calendar: calendar),
            reminderEnabled: true,
            reminderHour: 8,
            reminderMinute: 0
        )
        habit.completionIntervalDays = 2
        let reference = date(2026, 10, 5, hour: 9, calendar: calendar)

        let dates = HabitReminderScheduler.reminderDates(
            habit: habit,
            from: reference,
            calendar: calendar
        )

        XCTAssertEqual(dates.count, 1)
        XCTAssertEqual(
            HabitDayKey.make(for: dates[0], calendar: calendar),
            "2026-10-06"
        )
        XCTAssertEqual(calendar.component(.hour, from: dates[0]), 8)
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

    // Reconciliation must never remove the active request just to immediately
    // recreate it. Background suspension during that old remove/add window
    // caused real iPhone notifications to disappear from the system queue.
    func testIdenticalSchedulesDoNotRemoveOrResubmitPendingRequests() {
        let due = date(2026, 10, 19, hour: 9, calendar: utcCalendar)
        let oneOff = makeRequest(id: "one-off-reminder-a", due: due)
        let recurring = makeRequest(id: "habit-reminder-b-2026-10-19", due: due)
        let result = HabitReminderScheduler.reconcile(
            existing: [oneOff, recurring], desired: [oneOff, recurring]
        )
        XCTAssertTrue(result.toAdd.isEmpty)
        XCTAssertTrue(result.toRemove.isEmpty)
    }

    func testChangedOneOffDueTimeReplacesWithoutRemovingIdentifier() {
        let start = date(2026, 10, 19, hour: 9, calendar: utcCalendar)
        let old = makeRequest(id: "one-off-reminder-a", due: start)
        let new = makeRequest(id: "one-off-reminder-a", due: start.addingTimeInterval(75))
        let changes = HabitReminderScheduler.reconcile(
            existing: [old], desired: [new]
        )
        XCTAssertEqual(changes.toAdd.map(\.identifier), [old.identifier])
        XCTAssertTrue(changes.toRemove.isEmpty)
    }

    func testCanceledOneOffOnlyRemovesStaleManagedIdentifier() {
        let due = date(2026, 10, 19, hour: 9, calendar: utcCalendar)
        let previous = makeRequest(id: "one-off-reminder-stale", due: due)
        let kept = makeRequest(id: "one-off-reminder-kept", due: due)
        let unrelated = makeRequest(id: "unrelated-app-request", due: due)
        let changes = HabitReminderScheduler.reconcile(
            existing: [previous, kept, unrelated], desired: [kept]
        )
        XCTAssertTrue(changes.toAdd.isEmpty)
        XCTAssertEqual(changes.toRemove, [previous.identifier])
    }

    func testNewOneOffKeepsPreviouslyScheduledHabitUntouched() {
        let due = date(2026, 10, 19, hour: 9, calendar: utcCalendar)
        let habit = makeRequest(id: "habit-reminder-123-2026-10-19", due: due)
        let oneOff = makeRequest(id: "one-off-reminder-456", due: due)
        let changes = HabitReminderScheduler.reconcile(
            existing: [habit], desired: [oneOff, habit]
        )
        XCTAssertEqual(changes.toAdd.map(\.identifier), [oneOff.identifier])
        XCTAssertTrue(changes.toRemove.isEmpty)
    }

    func testChangedNotificationBodyRequiresReplacementWithoutDelete() {
        let due = date(2026, 10, 19, hour: 9, calendar: utcCalendar)
        let old = makeRequest(id: "habit-reminder-a-2026-10-19", due: due)
        let new = makeRequest(id: old.identifier, due: due, title: "Updated habit")
        let changes = HabitReminderScheduler.reconcile(
            existing: [old], desired: [new]
        )
        XCTAssertEqual(changes.toAdd.count, 1)
        XCTAssertTrue(changes.toRemove.isEmpty)
    }

    private func makeRequest(
        id: String, due: Date, title: String = "Review"
    ) -> UNNotificationRequest {
        var components = utcCalendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: due
        )
        components.timeZone = utcCalendar.timeZone
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "Time to review"
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
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
