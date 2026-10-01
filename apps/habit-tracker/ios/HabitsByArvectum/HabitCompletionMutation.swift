import Foundation
import SwiftData

enum HabitCompletionMutation {
    @MainActor
    static func setCompletion(
        habitID: UUID,
        dayKey: String,
        completed: Bool,
        context: ModelContext,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        let allCheckIns = (try? context.fetch(
            FetchDescriptor<HabitCheckIn>()
        )) ?? []
        let allSkips = (try? context.fetch(
            FetchDescriptor<HabitSkip>()
        )) ?? []

        let matching = allCheckIns.filter {
            $0.habitID == habitID &&
            ($0.dayKey == dayKey ||
             ($0.dayKey == nil &&
              HabitDayKey.make(for: $0.day, calendar: calendar) == dayKey))
        }
        let matchingSkips = allSkips.filter {
            $0.habitID == habitID && $0.dayKey == dayKey
        }

        var changed = false

        for skip in matchingSkips {
            context.delete(skip)
            changed = true
        }

        if completed {
            if matching.isEmpty, let date = date(
                from: dayKey,
                calendar: calendar
            ) {
                let checkIn = HabitCheckIn(
                    habitID: habitID,
                    day: date,
                    calendar: calendar
                )
                checkIn.dayKey = dayKey
                context.insert(checkIn)
                changed = true
            }
        } else if !matching.isEmpty {
            for checkIn in matching {
                context.delete(checkIn)
            }
            changed = true
        }

        return changed
    }

    private static func date(
        from dayKey: String,
        calendar: Calendar
    ) -> Date? {
        let parts = dayKey.split(separator: "-").compactMap {
            Int(String($0))
        }
        guard parts.count == 3 else { return nil }

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        components.hour = 12
        return components.date
    }
}
