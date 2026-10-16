import Foundation

/// Opt-in, read-only re-entry hints. This calculator MUST NOT create, delete,
/// shift or otherwise reconcile stored check-ins or day mutations.
struct GentleRestartCandidate: Identifiable, Equatable {
    let habitID: UUID
    let quietDays: Int

    var id: UUID { habitID }
}

enum GentleRestart {
    static let minimumOptions = [3, 7, 14]

    static func candidates(
        habits: [Habit],
        checkIns: [HabitCheckIn],
        skips: [HabitSkip],
        pausePeriods: [HabitPausePeriod],
        today: Date = .now,
        minimumQuietDays: Int = 7,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [GentleRestartCandidate] {
        let day = calendar.startOfDay(for: today)
        let todayKey = HabitDayKey.make(for: day, calendar: calendar)
        let threshold = max(1, minimumQuietDays)
        let byHabit = Dictionary(grouping: checkIns, by: \.habitID)

        return HabitOrdering.sorted(habits).compactMap { habit in
            guard !habit.isArchived, !habit.isPaused,
                  !HabitMetrics.isPaused(
                    habitID: habit.id, on: day,
                    pausePeriods: pausePeriods, calendar: calendar
                  ),
                  !HabitMetrics.isCompleted(
                    habitID: habit.id, on: day, checkIns: checkIns,
                    calendar: calendar, target: habit.dailyTarget
                  ),
                  !HabitMetrics.isSkipped(
                    habitID: habit.id, on: day, skips: skips, calendar: calendar
                  ),
                  HabitFrequency.isDue(
                    habit: habit, on: day, checkIns: checkIns,
                    skips: skips, pausePeriods: pausePeriods, calendar: calendar
                  )
            else { return nil }

            let own = byHabit[habit.id] ?? []
            let completedDays = Set(own.compactMap { checkIn -> String? in
                let key = checkIn.dayKey
                    ?? HabitDayKey.make(for: checkIn.day, calendar: calendar)
                return key < todayKey ? key : nil
            })
            let latestCompleted = completedDays.compactMap { key -> Date? in
                guard let candidateDay = HabitMultiCheck.date(
                    from: key, calendar: calendar
                ), HabitMetrics.isCompleted(
                    habitID: habit.id, on: candidateDay,
                    checkIns: own, calendar: calendar, target: habit.dailyTarget
                ) else { return nil }
                return calendar.startOfDay(for: candidateDay)
            }.max()
            guard let latestCompleted else { return nil }

            // For rolling schedules, being due right on time is not a lapse.
            // Suggest re-entry only after overdue days, not merely because
            // the configured interval was long.
            if habit.usesCompletionInterval {
                guard let due = HabitFrequency.nextCompletionIntervalDueDate(
                    habit: habit, checkIns: own,
                    through: day, calendar: calendar
                ), due < day else { return nil }
                let overdue = calendar.dateComponents(
                    [.day], from: due, to: day
                ).day ?? 0
                return overdue >= threshold
                    ? GentleRestartCandidate(habitID: habit.id, quietDays: overdue)
                    : nil
            }

            // An intentionally paused or skipped day is neutral. Never label
            // these days as "missed", and do not reset historical streaks.
            var cursor = calendar.date(
                byAdding: .day, value: 1, to: latestCompleted
            ) ?? day
            var quietDays = 0
            var examined = 0
            while cursor < day && examined < 3660 {
                if !HabitMetrics.isSkipped(
                    habitID: habit.id, on: cursor,
                    skips: skips, calendar: calendar
                ) && !HabitMetrics.isPaused(
                    habitID: habit.id, on: cursor,
                    pausePeriods: pausePeriods, calendar: calendar
                ) {
                    quietDays += 1
                }
                guard let next = calendar.date(
                    byAdding: .day, value: 1, to: cursor
                ) else { break }
                cursor = next
                examined += 1
            }
            return quietDays >= threshold
                ? GentleRestartCandidate(habitID: habit.id, quietDays: quietDays)
                : nil
        }
    }
}
