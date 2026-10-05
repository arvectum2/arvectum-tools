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
        pausePeriods: [HabitPausePeriod] = [],
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        if habit.usesCompletionInterval {
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

            // Keep a just-resolved occurrence visible for the rest of the day,
            // matching fixed and flexible schedules.
            if completedToday || skippedToday {
                return true
            }

            guard let dueDate = nextCompletionIntervalDueDate(
                habit: habit,
                checkIns: checkIns,
                through: date,
                calendar: calendar
            ) else {
                return false
            }

            return calendar.startOfDay(for: date) >= dueDate
        }

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
            ) < effectiveWeeklyTarget(
                habit: habit,
                containing: date,
                skips: skips,
                pausePeriods: pausePeriods,
                calendar: calendar
            )
        }

        return habit.schedule.includes(date, calendar: calendar)
    }

    static func nextCompletionIntervalDueDate(
        habit: Habit,
        checkIns: [HabitCheckIn],
        through referenceDate: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date? {
        guard habit.usesCompletionInterval else { return nil }

        let queryDay = calendar.startOfDay(for: referenceDate)
        let queryKey = HabitDayKey.make(for: queryDay, calendar: calendar)
        let completionKeys = checkIns
            .filter { $0.habitID == habit.id }
            .map {
                $0.dayKey ?? HabitDayKey.make(
                    for: $0.day,
                    calendar: calendar
                )
            }
            .filter { $0 <= queryKey }

        guard let latestKey = completionKeys.max() else {
            return calendar.startOfDay(for: habit.createdAt)
        }
        guard let latestCompletionDay = date(
            fromDayKey: latestKey,
            calendar: calendar
        ) else {
            return nil
        }

        return calendar.date(
            byAdding: .day,
            value: habit.completionIntervalDays,
            to: latestCompletionDay
        )
    }

    private static func date(
        fromDayKey dayKey: String,
        calendar: Calendar
    ) -> Date? {
        let parts = dayKey.split(separator: "-").compactMap {
            Int(String($0))
        }
        guard parts.count == 3 else { return nil }

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        components.hour = 12

        guard let date = components.date else { return nil }
        return calendar.startOfDay(for: date)
    }

    static func weekHasMetTarget(
        habit: Habit,
        containing date: Date,
        checkIns: [HabitCheckIn],
        skips: [HabitSkip] = [],
        pausePeriods: [HabitPausePeriod] = [],
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        guard habit.usesFlexibleWeeklyTarget else { return false }
        let target = effectiveWeeklyTarget(
            habit: habit,
            containing: date,
            skips: skips,
            pausePeriods: pausePeriods,
            calendar: calendar
        )
        guard target > 0 else { return false }
        return weeklyCompletionCount(
            habit: habit,
            containing: date,
            checkIns: checkIns,
            calendar: calendar
        ) >= target
    }

    static func effectiveWeeklyTarget(
        habit: Habit,
        containing date: Date,
        skips: [HabitSkip] = [],
        pausePeriods: [HabitPausePeriod] = [],
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        guard habit.usesFlexibleWeeklyTarget else { return 0 }

        let weekStart = startOfWeek(containing: date, calendar: calendar)
        let creationDay = calendar.startOfDay(for: habit.createdAt)
        var availableDays = 0

        for offset in 0..<7 {
            guard let day = calendar.date(
                byAdding: .day,
                value: offset,
                to: weekStart
            ) else { continue }
            guard day >= creationDay else { continue }
            guard !HabitMetrics.isPaused(
                habitID: habit.id,
                on: day,
                pausePeriods: pausePeriods,
                calendar: calendar
            ) else { continue }
            guard !HabitMetrics.isSkipped(
                habitID: habit.id,
                on: day,
                skips: skips,
                calendar: calendar
            ) else { continue }
            availableDays += 1
        }

        return min(habit.weeklyTarget, availableDays)
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
