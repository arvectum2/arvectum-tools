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
