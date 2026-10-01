import Foundation

enum HabitMetrics {
    static func isCompleted(
        habitID: UUID,
        on date: Date,
        checkIns: [HabitCheckIn],
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        checkIns.contains {
            $0.habitID == habitID &&
            HabitDayKey.matches(
                $0,
                on: date,
                calendar: calendar
            )
        }
    }

    static func isSkipped(
        habitID: UUID,
        on date: Date,
        skips: [HabitSkip],
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        let key = HabitDayKey.make(for: date, calendar: calendar)
        return skips.contains {
            $0.habitID == habitID && $0.dayKey == key
        }
    }

    static func currentStreak(
        habit: Habit,
        checkIns: [HabitCheckIn],
        skips: [HabitSkip] = [],
        today: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        let completedDays = dayKeys(
            habitID: habit.id,
            checkIns: checkIns,
            calendar: calendar
        )
        let skippedDays = skipKeys(
            habitID: habit.id,
            skips: skips
        )

        var streak = 0
        var cursor = calendar.startOfDay(for: today)
        let todayKey = HabitDayKey.make(
            for: cursor,
            calendar: calendar
        )
        let todayScheduled = habit.schedule.includes(
            cursor,
            calendar: calendar
        )
        let todayCompleted = completedDays.contains(todayKey)
        let todaySkipped = skippedDays.contains(todayKey)

        if todayScheduled && !todayCompleted && !todaySkipped,
           let yesterday = calendar.date(
               byAdding: .day,
               value: -1,
               to: cursor
           ) {
            cursor = yesterday
        }

        for _ in 0..<3660 {
            if habit.schedule.includes(cursor, calendar: calendar) {
                let cursorKey = HabitDayKey.make(
                    for: cursor,
                    calendar: calendar
                )

                if completedDays.contains(cursorKey) {
                    streak += 1
                } else if skippedDays.contains(cursorKey) {
                    // A skipped scheduled day is neutral: it neither grows
                    // nor breaks the chain.
                } else {
                    break
                }
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

    static func bestStreak(
        habit: Habit,
        checkIns: [HabitCheckIn],
        skips: [HabitSkip] = [],
        through endDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        let completedDays = dayKeys(
            habitID: habit.id,
            checkIns: checkIns,
            calendar: calendar
        )
        let skippedDays = skipKeys(
            habitID: habit.id,
            skips: skips
        )
        let start = calendar.startOfDay(for: habit.createdAt)
        let end = calendar.startOfDay(for: endDate)
        guard start <= end else { return 0 }

        var best = 0
        var current = 0
        var cursor = start

        while cursor <= end {
            if habit.schedule.includes(cursor, calendar: calendar) {
                let key = HabitDayKey.make(
                    for: cursor,
                    calendar: calendar
                )

                if completedDays.contains(key) {
                    current += 1
                    best = max(best, current)
                } else if skippedDays.contains(key) {
                    // Preserve the chain without adding to its length.
                } else {
                    current = 0
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

        return best
    }

    static func completionRate(
        habit: Habit,
        checkIns: [HabitCheckIn],
        skips: [HabitSkip] = [],
        through endDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Double {
        let start = calendar.startOfDay(for: habit.createdAt)
        let end = calendar.startOfDay(for: endDate)
        guard start <= end else { return 0 }

        var eligibleDays = 0
        var completedDays = 0
        var cursor = start

        while cursor <= end {
            if habit.schedule.includes(cursor, calendar: calendar) {
                let completed = isCompleted(
                    habitID: habit.id,
                    on: cursor,
                    checkIns: checkIns,
                    calendar: calendar
                )
                let skipped = isSkipped(
                    habitID: habit.id,
                    on: cursor,
                    skips: skips,
                    calendar: calendar
                )

                if completed {
                    eligibleDays += 1
                    completedDays += 1
                } else if !skipped {
                    eligibleDays += 1
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

        guard eligibleDays > 0 else { return 0 }
        return Double(completedDays) / Double(eligibleDays)
    }

    private static func dayKeys(
        habitID: UUID,
        checkIns: [HabitCheckIn],
        calendar: Calendar
    ) -> Set<String> {
        Set(
            checkIns
                .filter { $0.habitID == habitID }
                .map {
                    $0.dayKey ?? HabitDayKey.make(
                        for: $0.day,
                        calendar: calendar
                    )
                }
        )
    }

    private static func skipKeys(
        habitID: UUID,
        skips: [HabitSkip]
    ) -> Set<String> {
        Set(
            skips
                .filter { $0.habitID == habitID }
                .map(\.dayKey)
        )
    }
}
