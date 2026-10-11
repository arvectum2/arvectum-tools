import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var symbolName: String = "checkmark"
    var colorHex: String = "43E5C5"
    var createdAt: Date = Date.now
    var isArchived: Bool = false
    var scheduleMask: Int = HabitSchedule.everyDay.rawValue
    var reminderEnabled: Bool = false
    var reminderHour: Int = 20
    var reminderMinute: Int = 0
    var pausedAt: Date? = nil
    var weeklyTarget: Int = 0
    var sortOrder: Int = 0

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String = "checkmark",
        colorHex: String = "43E5C5",
        createdAt: Date = .now,
        isArchived: Bool = false,
        scheduleMask: Int = HabitSchedule.everyDay.rawValue,
        reminderEnabled: Bool = false,
        reminderHour: Int = 20,
        reminderMinute: Int = 0,
        pausedAt: Date? = nil,
        weeklyTarget: Int = 0,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.scheduleMask = scheduleMask
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.pausedAt = pausedAt
        self.weeklyTarget = weeklyTarget
        self.sortOrder = sortOrder
    }

    var schedule: HabitSchedule {
        get { HabitSchedule(rawValue: scheduleMask) }
        set { scheduleMask = newValue.rawValue }
    }

    var isPaused: Bool { pausedAt != nil }

    var goalMode: HabitGoalMode {
        get { HabitGoalMode(storedValue: weeklyTarget) }
        set { weeklyTarget = newValue.storedValue }
    }

    var usesFlexibleWeeklyTarget: Bool {
        if case .weekly = goalMode { return true }
        return false
    }

    var usesCompletionInterval: Bool {
        if case .afterCompletion = goalMode { return true }
        return false
    }

    var usesDailyMultiple: Bool {
        if case .multiCheck = goalMode { return true }
        return false
    }

    var usesQuantitativeGoal: Bool {
        if case .quantity = goalMode { return true }
        return false
    }

    var usesDurationGoal: Bool {
        if case .duration = goalMode { return true }
        return false
    }

    var supportsIncrementalGoal: Bool {
        usesDailyMultiple || usesQuantitativeGoal || usesDurationGoal
    }

    var dailyTarget: Int {
        get { goalMode.target }
        set { goalMode = newValue > 1 ? .multiCheck(times: newValue) : .scheduled }
    }

    var quantityTarget: Int {
        if case .quantity(let count) = goalMode { return count }
        return 10
    }

    var durationMinutes: Int {
        if case .duration(let minutes) = goalMode { return minutes }
        return 20
    }

    var completionIntervalDays: Int {
        get {
            if case .afterCompletion(let days) = goalMode { return days }
            return 0
        }
        set {
            goalMode = newValue > 0
                ? .afterCompletion(days: newValue)
                : .scheduled
        }
    }
}

enum HabitOrdering {
    static func sorted(_ habits: [Habit]) -> [Habit] {
        habits.sorted { lhs, rhs in
            if lhs.sortOrder != rhs.sortOrder {
                return lhs.sortOrder < rhs.sortOrder
            }
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    static func nextOrder(in habits: [Habit]) -> Int {
        (habits.map(\.sortOrder).max() ?? -1) + 1
    }
}

@Model
final class HabitCheckIn {
    var id: UUID = UUID()
    var habitID: UUID = UUID()
    var day: Date = Date.now
    var dayKey: String? = nil
    var createdAt: Date = Date.now

    init(
        id: UUID = UUID(),
        habitID: UUID,
        day: Date,
        createdAt: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.id = id
        self.habitID = habitID
        self.day = day
        self.dayKey = HabitDayKey.make(for: day, calendar: calendar)
        self.createdAt = createdAt
    }
}

@Model
final class HabitSkip {
    var id: UUID = UUID()
    var habitID: UUID = UUID()
    var day: Date = Date.now
    var dayKey: String = ""
    var createdAt: Date = Date.now

    init(
        id: UUID = UUID(),
        habitID: UUID,
        day: Date,
        createdAt: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.id = id
        self.habitID = habitID
        self.day = day
        self.dayKey = HabitDayKey.make(for: day, calendar: calendar)
        self.createdAt = createdAt
    }
}

@Model
final class HabitPausePeriod {
    var id: UUID = UUID()
    var habitID: UUID = UUID()
    var startedAt: Date = Date.now
    var startDayKey: String = ""
    var endedAt: Date? = nil
    var endDayKeyExclusive: String? = nil

    init(
        id: UUID = UUID(),
        habitID: UUID,
        startedAt: Date = .now,
        endedAt: Date? = nil,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.id = id
        self.habitID = habitID
        self.startedAt = startedAt
        self.startDayKey = HabitDayKey.make(
            for: startedAt,
            calendar: calendar
        )
        self.endedAt = endedAt
        self.endDayKeyExclusive = endedAt.map {
            HabitDayKey.make(for: $0, calendar: calendar)
        }
    }

    func contains(dayKey: String) -> Bool {
        guard dayKey >= startDayKey else { return false }
        guard let endDayKeyExclusive else { return true }
        return dayKey < endDayKeyExclusive
    }
}

@Model
final class OneOffReminder {
    var id: UUID = UUID()
    var title: String = ""
    var dueAt: Date = Date.now
    var createdAt: Date = Date.now
    var isCompleted: Bool = false
    var completedAt: Date? = nil

    init(
        id: UUID = UUID(),
        title: String,
        dueAt: Date,
        createdAt: Date = .now,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.dueAt = dueAt
        self.createdAt = createdAt
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}

struct HabitSchedule: OptionSet, Hashable {
    let rawValue: Int

    static let monday = HabitSchedule(rawValue: 1 << 0)
    static let tuesday = HabitSchedule(rawValue: 1 << 1)
    static let wednesday = HabitSchedule(rawValue: 1 << 2)
    static let thursday = HabitSchedule(rawValue: 1 << 3)
    static let friday = HabitSchedule(rawValue: 1 << 4)
    static let saturday = HabitSchedule(rawValue: 1 << 5)
    static let sunday = HabitSchedule(rawValue: 1 << 6)

    static let everyDay: HabitSchedule = [
        .monday, .tuesday, .wednesday, .thursday,
        .friday, .saturday, .sunday
    ]

    static let weekdays: HabitSchedule = [
        .monday, .tuesday, .wednesday, .thursday, .friday
    ]

    static func option(for weekday: Int) -> HabitSchedule {
        switch weekday {
        case 2: .monday
        case 3: .tuesday
        case 4: .wednesday
        case 5: .thursday
        case 6: .friday
        case 7: .saturday
        default: .sunday
        }
    }

    func includes(_ date: Date, calendar: Calendar = .autoupdatingCurrent) -> Bool {
        contains(Self.option(for: calendar.component(.weekday, from: date)))
    }
}

struct HabitDay: Identifiable, Hashable {
    let date: Date
    let scheduled: Bool
    let completed: Bool

    var id: Date { date }
}
