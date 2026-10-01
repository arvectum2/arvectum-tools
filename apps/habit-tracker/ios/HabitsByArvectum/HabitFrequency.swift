import Foundation

enum HabitFrequency {
    static func weeklyCompletionCount(
        habit: Habit,
        containing date: Date,
        checkIns: [HabitCheckIn],
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        let weekStart = startOfWeek(
            containing: date,
            calendar: calendar
        )
        var count = 0

        for offset in 0..<7 {
            guard let day = calendar.date(
                byAdding: .day,
                value: offset,
                to: weekStart
            ) else { continue }

            if HabitMetrics.isCompleted(
                habitID: habit.id,
                on: day,
                checkIns: checkIns,
                calendar: calendar
            ) {
                count += 1
            }
        }

        return count
    }

    static func isDue(
        habit: Habit,
        on date: Date,
        checkIns: [HabitCheckIn],
        skips: [HabitSkip] = [],
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        if habit.usesFlexibleWeeklyTarget {
            let completedToday = HabitMetrics.isCompleted(
                habitID: habit.id,
                on: date,
                checkIns: checkIns,
                calendar: calendar
            )
            let skippedToday = HabitMetrics.isSkipped(
                habitID: habit.id,
                on: date,
                skips: skips,
                calendar: calendar
            )

            if completedToday || skippedToday {
                return true
            }

            return weeklyCompletionCount(
                habit: habit,
                containing: date,
                checkIns: checkIns,
                calendar: calendar
            ) < habit.weeklyTarget
        }

        return habit.schedule.includes(date, calendar: calendar)
    }

    static func weekHasMetTarget(
        habit: Habit,
        containing date: Date,
        checkIns: [HabitCheckIn],
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        guard habit.usesFlexibleWeeklyTarget else { return false }
        return weeklyCompletionCount(
            habit: habit,
            containing: date,
            checkIns: checkIns,
            calendar: calendar
        ) >= habit.weeklyTarget
    }

    static func startOfWeek(
        containing date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start
            ?? calendar.startOfDay(for: date)
    }

    static func previousWeek(
        before date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date? {
        calendar.date(byAdding: .weekOfYear, value: -1, to: date)
    }

    static func nextWeek(
        after date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date? {
        calendar.date(byAdding: .weekOfYear, value: 1, to: date)
    }
}
