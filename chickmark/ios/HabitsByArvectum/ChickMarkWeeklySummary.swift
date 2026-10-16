import Foundation

/// Finished calendar weeks only. This is a read-only report, not a new
/// completion engine or a source of truth for external HealthKit samples.
struct ChickMarkWeeklyRollup: Equatable {
    let weekStart: Date
    let scheduledCompleted: Int
    let scheduledEligible: Int
    let scheduledNeutral: Int
    let flexibleGoalsMet: Int
    let flexibleGoalsEligible: Int
    let intervalOccurrences: Int
    let completionDays: Int
    let bestDay: Date?
    let bestDayCompletions: Int
}

struct ChickMarkWeeklyReport: Equatable {
    let lastWeek: ChickMarkWeeklyRollup
    let weekBefore: ChickMarkWeeklyRollup
    var changeInCompletions: Int {
        lastWeek.completionDays - weekBefore.completionDays
    }
}

enum ChickMarkWeeklySummary {
    static func report(
        habits: [Habit],
        checkIns: [HabitCheckIn],
        skips: [HabitSkip],
        pausePeriods: [HabitPausePeriod],
        today: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> ChickMarkWeeklyReport {
        let start = HabitFrequency.startOfWeek(containing: today, calendar: calendar)
        let last = calendar.date(byAdding: .weekOfYear, value: -1, to: start) ?? start
        let prior = calendar.date(byAdding: .weekOfYear, value: -2, to: start) ?? last
        return ChickMarkWeeklyReport(
            lastWeek: rollup(
                weekStart: last, habits: habits, checkIns: checkIns,
                skips: skips, pausePeriods: pausePeriods, calendar: calendar
            ),
            weekBefore: rollup(
                weekStart: prior, habits: habits, checkIns: checkIns,
                skips: skips, pausePeriods: pausePeriods, calendar: calendar
            )
        )
    }

    static func rollup(
        weekStart: Date,
        habits: [Habit],
        checkIns: [HabitCheckIn],
        skips: [HabitSkip],
        pausePeriods: [HabitPausePeriod],
        calendar: Calendar = .autoupdatingCurrent
    ) -> ChickMarkWeeklyRollup {
        let start = calendar.startOfDay(for: weekStart)
        let days = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: start)
        }
        guard days.count == 7 else {
            return ChickMarkWeeklyRollup(
                weekStart: start, scheduledCompleted: 0, scheduledEligible: 0,
                scheduledNeutral: 0, flexibleGoalsMet: 0, flexibleGoalsEligible: 0,
                intervalOccurrences: 0, completionDays: 0,
                bestDay: nil, bestDayCompletions: 0
            )
        }

        var completed = 0
        var eligible = 0
        var neutral = 0
        var flexibleMet = 0
        var flexibleEligible = 0
        var intervalOccurrences = 0
        var activity = [Int](repeating: 0, count: 7)

        for habit in habits where !habit.isArchived {
            let created = calendar.startOfDay(for: habit.createdAt)
            let own = checkIns.filter { $0.habitID == habit.id }
            let isFlexible = habit.usesFlexibleWeeklyTarget
            let isInterval = habit.usesCompletionInterval

            if isFlexible {
                let target = HabitFrequency.effectiveWeeklyTarget(
                    habit: habit, containing: start, skips: skips,
                    pausePeriods: pausePeriods, calendar: calendar
                )
                if target > 0 {
                    flexibleEligible += 1
                    let effectiveCompletions = days.filter { day in
                        day >= created &&
                        !isNeutral(habitID: habit.id, on: day,
                                   skips: skips, pauses: pausePeriods, calendar: calendar) &&
                        HabitMetrics.isCompleted(
                            habitID: habit.id, on: day,
                            checkIns: own, calendar: calendar,
                            target: habit.dailyTarget
                        )
                    }.count
                    if effectiveCompletions >= target { flexibleMet += 1 }
                }
            }

            for (index, day) in days.enumerated() where day >= created {
                let neutralDay = isNeutral(
                    habitID: habit.id, on: day, skips: skips,
                    pauses: pausePeriods, calendar: calendar
                )
                let achieved = !neutralDay && HabitMetrics.isCompleted(
                    habitID: habit.id, on: day, checkIns: own,
                    calendar: calendar, target: habit.dailyTarget
                )
                if achieved { activity[index] += 1 }

                if isInterval {
                    if achieved { intervalOccurrences += 1 }
                } else if !isFlexible && habit.schedule.includes(day, calendar: calendar) {
                    if neutralDay {
                        neutral += 1
                    } else {
                        eligible += 1
                        if achieved { completed += 1 }
                    }
                }
            }
        }

        let best = activity.max() ?? 0
        // Earliest best day wins ties; an all-zero period has no best day.
        let bestIndex = best > 0 ? activity.firstIndex(of: best) : nil
        return ChickMarkWeeklyRollup(
            weekStart: start, scheduledCompleted: completed,
            scheduledEligible: eligible, scheduledNeutral: neutral,
            flexibleGoalsMet: flexibleMet, flexibleGoalsEligible: flexibleEligible,
            intervalOccurrences: intervalOccurrences,
            completionDays: activity.reduce(0, +),
            bestDay: bestIndex.map { days[$0] },
            bestDayCompletions: best
        )
    }

    private static func isNeutral(
        habitID: UUID, on date: Date,
        skips: [HabitSkip], pauses: [HabitPausePeriod],
        calendar: Calendar
    ) -> Bool {
        HabitMetrics.isSkipped(
            habitID: habitID, on: date, skips: skips, calendar: calendar
        ) || HabitMetrics.isPaused(
            habitID: habitID, on: date,
            pausePeriods: pauses, calendar: calendar
        )
    }
}
