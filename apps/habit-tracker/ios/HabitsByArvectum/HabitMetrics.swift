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
        pausePeriods: [HabitPausePeriod] = [],
        today: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        if habit.usesFlexibleWeeklyTarget {
            return currentWeeklyStreak(
                habit: habit,
                checkIns: checkIns,
                pausePeriods: pausePeriods,
                today: today,
                calendar: calendar
            )
        }

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
        let todayPaused = isPaused(
            habitID: habit.id,
            dayKey: todayKey,
            pausePeriods: pausePeriods
        )

        if todayScheduled && !todayCompleted && !todaySkipped && !todayPaused,
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
                } else if skippedDays.contains(cursorKey) || isPaused(
                    habitID: habit.id,
                    dayKey: cursorKey,
                    pausePeriods: pausePeriods
                ) {
                    // Skipped and paused scheduled days are neutral: they
                    // neither grow nor break the chain.
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
        pausePeriods: [HabitPausePeriod] = [],
        through endDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        if habit.usesFlexibleWeeklyTarget {
            return bestWeeklyStreak(
                habit: habit,
                checkIns: checkIns,
                pausePeriods: pausePeriods,
                through: endDate,
                calendar: calendar
            )
        }

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
                } else if skippedDays.contains(key) || isPaused(
                    habitID: habit.id,
                    dayKey: key,
                    pausePeriods: pausePeriods
                ) {
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
        pausePeriods: [HabitPausePeriod] = [],
        through endDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Double {
        if habit.usesFlexibleWeeklyTarget {
            return weeklyCompletionRate(
                habit: habit,
                checkIns: checkIns,
                pausePeriods: pausePeriods,
                through: endDate,
                calendar: calendar
            )
        }

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
                let dayKey = HabitDayKey.make(
                    for: cursor,
                    calendar: calendar
                )
                let paused = isPaused(
                    habitID: habit.id,
                    dayKey: dayKey,
                    pausePeriods: pausePeriods
                )

                if !paused {
                    if completed {
                        eligibleDays += 1
                        completedDays += 1
                    } else if !skipped {
                        eligibleDays += 1
                    }
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

    static func isPaused(
        habitID: UUID,
        on date: Date,
        pausePeriods: [HabitPausePeriod],
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        isPaused(
            habitID: habitID,
            dayKey: HabitDayKey.make(for: date, calendar: calendar),
            pausePeriods: pausePeriods
        )
    }

    private static func isPaused(
        habitID: UUID,
        dayKey: String,
        pausePeriods: [HabitPausePeriod]
    ) -> Bool {
        pausePeriods.contains {
            $0.habitID == habitID && $0.contains(dayKey: dayKey)
        }
    }

    private static func currentWeeklyStreak(
        habit: Habit,
        checkIns: [HabitCheckIn],
        pausePeriods: [HabitPausePeriod],
        today: Date,
        calendar: Calendar
    ) -> Int {
        let creationWeek = HabitFrequency.startOfWeek(
            containing: habit.createdAt,
            calendar: calendar
        )
        var cursor = HabitFrequency.startOfWeek(
            containing: today,
            calendar: calendar
        )

        if !HabitFrequency.weekHasMetTarget(
            habit: habit,
            containing: cursor,
            checkIns: checkIns,
            pausePeriods: pausePeriods,
            calendar: calendar
        ), let previous = HabitFrequency.previousWeek(
            before: cursor,
            calendar: calendar
        ) {
            cursor = previous
        }

        var streak = 0
        for _ in 0..<520 {
            guard cursor >= creationWeek else { break }

            if weekIsFullyPaused(
                habitID: habit.id,
                weekStart: cursor,
                pausePeriods: pausePeriods,
                calendar: calendar
            ) {
                // A fully paused week is neutral.
            } else if HabitFrequency.weekHasMetTarget(
                habit: habit,
                containing: cursor,
                checkIns: checkIns,
                pausePeriods: pausePeriods,
                calendar: calendar
            ) {
                streak += 1
            } else {
                break
            }

            guard let previous = HabitFrequency.previousWeek(
                before: cursor,
                calendar: calendar
            ) else { break }
            cursor = previous
        }
        return streak
    }

    private static func bestWeeklyStreak(
        habit: Habit,
        checkIns: [HabitCheckIn],
        pausePeriods: [HabitPausePeriod],
        through endDate: Date,
        calendar: Calendar
    ) -> Int {
        var cursor = HabitFrequency.startOfWeek(
            containing: habit.createdAt,
            calendar: calendar
        )
        let endWeek = HabitFrequency.startOfWeek(
            containing: endDate,
            calendar: calendar
        )
        var best = 0
        var current = 0

        while cursor <= endWeek {
            if weekIsFullyPaused(
                habitID: habit.id,
                weekStart: cursor,
                pausePeriods: pausePeriods,
                calendar: calendar
            ) {
                // Preserve the chain without increasing it.
            } else if HabitFrequency.weekHasMetTarget(
                habit: habit,
                containing: cursor,
                checkIns: checkIns,
                pausePeriods: pausePeriods,
                calendar: calendar
            ) {
                current += 1
                best = max(best, current)
            } else if cursor < endWeek {
                current = 0
            }

            guard let next = HabitFrequency.nextWeek(
                after: cursor,
                calendar: calendar
            ) else { break }
            cursor = next
        }

        return best
    }

    private static func weeklyCompletionRate(
        habit: Habit,
        checkIns: [HabitCheckIn],
        pausePeriods: [HabitPausePeriod],
        through endDate: Date,
        calendar: Calendar
    ) -> Double {
        var cursor = HabitFrequency.startOfWeek(
            containing: habit.createdAt,
            calendar: calendar
        )
        let currentWeek = HabitFrequency.startOfWeek(
            containing: endDate,
            calendar: calendar
        )
        var eligibleWeeks = 0
        var completedWeeks = 0

        while cursor <= currentWeek {
            let fullyPaused = weekIsFullyPaused(
                habitID: habit.id,
                weekStart: cursor,
                pausePeriods: pausePeriods,
                calendar: calendar
            )
            let met = HabitFrequency.weekHasMetTarget(
                habit: habit,
                containing: cursor,
                checkIns: checkIns,
                pausePeriods: pausePeriods,
                calendar: calendar
            )

            if !fullyPaused {
                if cursor < currentWeek {
                    eligibleWeeks += 1
                    if met { completedWeeks += 1 }
                } else if met {
                    // Do not penalize an unfinished current week before it ends.
                    eligibleWeeks += 1
                    completedWeeks += 1
                }
            }

            guard let next = HabitFrequency.nextWeek(
                after: cursor,
                calendar: calendar
            ) else { break }
            cursor = next
        }

        guard eligibleWeeks > 0 else { return 0 }
        return Double(completedWeeks) / Double(eligibleWeeks)
    }

    private static func weekIsFullyPaused(
        habitID: UUID,
        weekStart: Date,
        pausePeriods: [HabitPausePeriod],
        calendar: Calendar
    ) -> Bool {
        for offset in 0..<7 {
            guard let day = calendar.date(
                byAdding: .day,
                value: offset,
                to: weekStart
            ) else { return false }
            let key = HabitDayKey.make(for: day, calendar: calendar)
            if !isPaused(
                habitID: habitID,
                dayKey: key,
                pausePeriods: pausePeriods
            ) {
                return false
            }
        }
        return true
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
