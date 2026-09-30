import Foundation
import SwiftData

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var name: String
    var symbolName: String
    var colorHex: String
    var createdAt: Date
    var isArchived: Bool
    var scheduleMask: Int

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String = "checkmark",
        colorHex: String = "43E5C5",
        createdAt: Date = .now,
        isArchived: Bool = false,
        scheduleMask: Int = HabitSchedule.everyDay.rawValue
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.scheduleMask = scheduleMask
    }

    var schedule: HabitSchedule {
        get { HabitSchedule(rawValue: scheduleMask) }
        set { scheduleMask = newValue.rawValue }
    }
}

@Model
final class HabitCheckIn {
    @Attribute(.unique) var id: UUID
    var habitID: UUID
    var day: Date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        habitID: UUID,
        day: Date,
        createdAt: Date = .now
    ) {
        self.id = id
        self.habitID = habitID
        self.day = Calendar.autoupdatingCurrent.startOfDay(for: day)
        self.createdAt = createdAt
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
