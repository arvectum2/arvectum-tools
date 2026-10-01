import Foundation

enum HabitTodayProjection {
    static func orderedDueHabits(
        habits: [Habit],
        on date: Date,
        checkIns: [HabitCheckIn],
        skips: [HabitSkip],
        pausePeriods: [HabitPausePeriod],
        calendar: Calendar = .autoupdatingCurrent
    ) -> [Habit] {
        HabitOrdering.sorted(
            habits.filter {
                !$0.isArchived &&
                !$0.isPaused &&
                HabitFrequency.isDue(
                    habit: $0,
                    on: date,
                    checkIns: checkIns,
                    skips: skips,
                    pausePeriods: pausePeriods,
                    calendar: calendar
                )
            }
        )
    }
}
