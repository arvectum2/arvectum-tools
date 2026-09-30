import Foundation

enum HabitMetrics {
    static func isCompleted(
        habitID: UUID,
        on date: Date,
        checkIns: [HabitCheckIn],
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        return checkIns.contains {
            $0.habitID == habitID &&
            HabitDayKey.matches(
                $0,
                on: date,
                calendar: calendar
            )
        }
    }

    static func currentStreak(
        habit: Habit,
        checkIns: [HabitCheckIn],
        today: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        let completedDays = Set(
            checkIns
                .filter { $0.habitID == habit.id }
                .map {
                    $0.dayKey ?? HabitDayKey.make(
                        for: $0.day,
                        calendar: calendar
                    )
                }
        )

        var streak = 0
        var cursor = calendar.startOfDay(for: today)
        let todayScheduled = habit.schedule.includes(cursor, calendar: calendar)
        let todayCompleted = completedDays.contains(
            HabitDayKey.make(for: cursor, calendar: calendar)
        )

        if todayScheduled && !todayCompleted,
           let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) {
            cursor = yesterday
        }

        for _ in 0..<3660 {
            if habit.schedule.includes(cursor, calendar: calendar) {
                let cursorKey = HabitDayKey.make(
                    for: cursor,
                    calendar: calendar
                )
                guard completedDays.contains(cursorKey) else { break }
                streak += 1
            }

            guard let previous = calendar.date(
                byAdding: .day,
                value: -1,
                to: cursor
            ) else {
                break
            }
            cursor = previous
        }

        return streak
    }

    static func completionRate(
        habit: Habit,
        checkIns: [HabitCheckIn],
        through endDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Double {
        let start = calendar.startOfDay(for: habit.createdAt)
        let end = calendar.startOfDay(for: endDate)
        guard start <= end else { return 0 }

        var scheduledDays = 0
        var completedDays = 0
        var cursor = start

        while cursor <= end {
            if habit.schedule.includes(cursor, calendar: calendar) {
                scheduledDays += 1
                if isCompleted(
                    habitID: habit.id,
                    on: cursor,
                    checkIns: checkIns,
                    calendar: calendar
                ) {
                    completedDays += 1
                }
            }

            guard let next = calendar.date(
                byAdding: .day,
                value: 1,
                to: cursor
            ) else {
                break
            }
            cursor = next
        }

        guard scheduledDays > 0 else { return 0 }
        return Double(completedDays) / Double(scheduledDays)
    }
}
