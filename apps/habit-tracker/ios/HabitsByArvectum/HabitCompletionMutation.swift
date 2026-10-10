import Foundation
import SwiftData

enum HabitCompletionMutation {
    @MainActor
    static func setCompletion(
        habitID: UUID,
        dayKey: String,
        completed: Bool,
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
            let allHabits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
            let target = allHabits.first(where: { $0.id == habitID })?.dailyTarget ?? 1
            if let date = date(from: dayKey, calendar: calendar) {
                let occupied = HabitMultiCheck.slots(
                    habitID: habitID, dayKey: dayKey, target: target,
                    checkIns: matching
                )
                for slot in 1...target where occupied[slot] == nil {
                    let checkIn = HabitCheckIn(
                        id: HabitMultiCheck.slotID(
                            habitID: habitID, dayKey: dayKey, slot: slot
                        ),
                        habitID: habitID, day: date, calendar: calendar
                    )
                    checkIn.dayKey = dayKey
                    context.insert(checkIn)
                    changed = true
                }
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
