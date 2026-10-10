import Foundation

/// Read-only trends based on scheduled calendar days. Skips and pauses are neutral.
/// The current, unfinished day is excluded from the denominator.
struct HabitInsightWindow: Equatable {
    let completed: Int
    let missed: Int
    let skipped: Int

    var eligible: Int { completed + missed }
    var percent: Int {
        guard eligible > 0 else { return 0 }
        return Int((100.0 * Double(completed) / Double(eligible)).rounded())
    }
}

enum HabitInsights {
    static func window(
        habit: Habit,
        checkIns: [HabitCheckIn],
        skips: [HabitSkip],
        pausePeriods: [HabitPausePeriod],
        days: Int,
        through today: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> HabitInsightWindow {
        guard days > 0 else {
            return HabitInsightWindow(completed: 0, missed: 0, skipped: 0)
        }
        // Weekly frequency and completion-relative intervals are measured by
        // different units (weeks / occurrences). Do not fabricate daily rates.
        guard !habit.usesFlexibleWeeklyTarget, !habit.usesCompletionInterval else {
            return HabitInsightWindow(completed: 0, missed: 0, skipped: 0)
        }

        let todayStart = calendar.startOfDay(for: today)
        let created = calendar.startOfDay(for: habit.createdAt)
        var completed = 0
        var missed = 0
        var skipped = 0

        for offset in 0..<min(days, 3660) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: todayStart),
                  day >= created, habit.schedule.includes(day, calendar: calendar)
            else { continue }

            if HabitMetrics.isPaused(
                habitID: habit.id, on: day,
                pausePeriods: pausePeriods, calendar: calendar
            ) {
                continue
            }
            if HabitMetrics.isSkipped(
                habitID: habit.id, on: day, skips: skips, calendar: calendar
            ) {
                skipped += 1
            } else if HabitMetrics.isCompleted(
                habitID: habit.id, on: day, checkIns: checkIns, calendar: calendar,
                target: habit.dailyTarget
            ) {
                completed += 1
            } else if offset > 0 {
                // Today is still in progress, so cannot count as missed yet.
                missed += 1
            }
        }
        return HabitInsightWindow(completed: completed, missed: missed, skipped: skipped)
    }
}


/// Whole weeks only. The current week cannot be declared missed before it ends.
struct HabitWeeklyInsight: Equatable {
    let achieved: Int
    let missed: Int
    let neutral: Int

    var eligible: Int { achieved + missed }
    var percent: Int {
        guard eligible > 0 else { return 0 }
        return Int((Double(achieved) / Double(eligible) * 100).rounded())
    }
}

/// Completion-relative goals have no fixed missed days. Report real occurrences
/// and the observed gap instead of inventing an artificial completion rate.
struct HabitIntervalInsight: Equatable {
    let occurrences: Int
    let averageGapDays: Int?
}

extension HabitInsights {
    static func weeklyWindow(
        habit: Habit,
        checkIns: [HabitCheckIn],
        skips: [HabitSkip],
        pausePeriods: [HabitPausePeriod],
        previousWeeks: Int,
        through today: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> HabitWeeklyInsight {
        guard habit.usesFlexibleWeeklyTarget, previousWeeks > 0 else {
            return HabitWeeklyInsight(achieved: 0, missed: 0, neutral: 0)
        }
        let currentWeek = HabitFrequency.startOfWeek(containing: today, calendar: calendar)
        let createdWeek = HabitFrequency.startOfWeek(
            containing: habit.createdAt, calendar: calendar
        )
        var achieved = 0
        var missed = 0
        var neutral = 0
        for offset in 1...min(previousWeeks, 520) {
            guard let week = calendar.date(
                byAdding: .weekOfYear, value: -offset, to: currentWeek
            ), week >= createdWeek else { continue }
            let target = HabitFrequency.effectiveWeeklyTarget(
                habit: habit, containing: week,
                skips: skips, pausePeriods: pausePeriods, calendar: calendar
            )
            if target == 0 {
                neutral += 1
            } else if HabitFrequency.weeklyCompletionCount(
                habit: habit, containing: week, checkIns: checkIns, calendar: calendar
            ) >= target {
                achieved += 1
            } else {
                missed += 1
            }
        }
        return HabitWeeklyInsight(achieved: achieved, missed: missed, neutral: neutral)
    }

    static func intervalWindow(
        habit: Habit,
        checkIns: [HabitCheckIn],
        days: Int,
        through today: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> HabitIntervalInsight {
        guard habit.usesCompletionInterval, days > 0 else {
            return HabitIntervalInsight(occurrences: 0, averageGapDays: nil)
        }
        let end = calendar.startOfDay(for: today)
        let startOfWindow = calendar.date(
            byAdding: .day, value: 1 - min(days, 3660), to: end
        ) ?? end
        let start = max(startOfWindow, calendar.startOfDay(for: habit.createdAt))
        let keys = Set(checkIns.filter { $0.habitID == habit.id }.map {
            $0.dayKey ?? HabitDayKey.make(for: $0.day, calendar: calendar)
        })
        let completionDays = keys.compactMap {
            HabitMultiCheck.date(from: $0, calendar: calendar)
        }.map { calendar.startOfDay(for: $0) }
            .filter { $0 >= start && $0 <= end }
            .sorted()
        guard completionDays.count >= 2 else {
            return HabitIntervalInsight(
                occurrences: completionDays.count, averageGapDays: nil
            )
        }
        let totalGaps = zip(
            completionDays.dropLast(), completionDays.dropFirst()
        ).reduce(0) { total, pair in
            total + (calendar.dateComponents([.day], from: pair.0, to: pair.1).day ?? 0)
        }
        return HabitIntervalInsight(
            occurrences: completionDays.count,
            averageGapDays: Int((
                Double(totalGaps) / Double(completionDays.count - 1)
            ).rounded())
        )
    }
}
