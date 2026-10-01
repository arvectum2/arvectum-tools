import Foundation

enum HabitScheduleText {
    static func description(for habit: Habit) -> String {
        if habit.usesFlexibleWeeklyTarget {
            return L10n.format(
                "schedule.flexible.description.format",
                habit.weeklyTarget
            )
        }

        if habit.schedule == .everyDay {
            return L10n.string("schedule.everyday")
        }

        if habit.schedule == .weekdays {
            return L10n.string("schedule.weekdays.description")
        }

        return weekdayLabels
            .filter { habit.schedule.contains($0.option) }
            .map(\.label)
            .joined(separator: ", ")
    }

    private static var weekdayLabels: [
        (label: String, option: HabitSchedule)
    ] {
        [
            (L10n.string("weekday.mon.short"), .monday),
            (L10n.string("weekday.tue.short"), .tuesday),
            (L10n.string("weekday.wed.short"), .wednesday),
            (L10n.string("weekday.thu.short"), .thursday),
            (L10n.string("weekday.fri.short"), .friday),
            (L10n.string("weekday.sat.short"), .saturday),
            (L10n.string("weekday.sun.short"), .sunday)
        ]
    }
}
