import Foundation
import SwiftData

enum HabitSkipMutation {
    @MainActor
    static func setSkipped(
        habitID: UUID,
        dayKey: String,
        skipped: Bool,
        context: ModelContext,
        mutationAt: Date = .now,
        mutationID: UUID = UUID(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        guard HabitDayMutationLedger.accept(
            habitID: habitID,
            dayKey: dayKey,
            updatedAt: mutationAt,
            mutationID: mutationID,
            context: context
        ) else {
            return false
        }

        let allCheckIns = (try? context.fetch(
            FetchDescriptor<HabitCheckIn>()
        )) ?? []
        let allSkips = (try? context.fetch(
            FetchDescriptor<HabitSkip>()
        )) ?? []

        let matchingCheckIns = allCheckIns.filter {
            $0.habitID == habitID &&
            ($0.dayKey == dayKey ||
             ($0.dayKey == nil &&
              HabitDayKey.make(for: $0.day, calendar: calendar) == dayKey))
        }
        let matchingSkips = allSkips.filter {
            $0.habitID == habitID && $0.dayKey == dayKey
        }

        var changed = false

        if skipped {
            for checkIn in matchingCheckIns {
                context.delete(checkIn)
                changed = true
            }

            if matchingSkips.isEmpty,
               let date = date(from: dayKey, calendar: calendar) {
                let skip = HabitSkip(
                    habitID: habitID,
                    day: date,
                    calendar: calendar
                )
                skip.dayKey = dayKey
                context.insert(skip)
                changed = true
            }
        } else {
            for skip in matchingSkips {
                context.delete(skip)
                changed = true
            }
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
