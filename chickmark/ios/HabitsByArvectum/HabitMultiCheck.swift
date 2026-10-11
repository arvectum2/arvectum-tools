import Foundation
import CryptoKit
import SwiftData

/// Persist each checked slot as a normal V1 HabitCheckIn with a deterministic
/// UUID. This preserves the published SwiftData / CloudKit schema and dayKey.
enum HabitMultiCheck {
    static func slotID(habitID: UUID, dayKey: String, slot: Int) -> UUID {
        let payload = Data("ChickMark|\(habitID.uuidString)|\(dayKey)|\(slot)".utf8)
        let digest = Array(SHA256.hash(data: payload).prefix(16))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        // Keep the exact V1-compatible UUID bytes, but make the formatting
        // explicit: Xcode 26.6's Swift compiler cannot reliably type-check
        // the nested prefix/dropFirst/array expression.
        var segments: [String] = []
        var cursor = hex.startIndex
        for width in [8, 4, 4, 4, 12] {
            let end = hex.index(cursor, offsetBy: width)
            segments.append(String(hex[cursor..<end]))
            cursor = end
        }
        let value = segments.joined(separator: "-")
        return UUID(uuidString: value)!
    }

    static func matching(
        habitID: UUID,
        dayKey: String,
        checkIns: [HabitCheckIn],
        calendar: Calendar = .autoupdatingCurrent
    ) -> [HabitCheckIn] {
        checkIns.filter {
            $0.habitID == habitID &&
            ($0.dayKey == dayKey ||
             ($0.dayKey == nil &&
              HabitDayKey.make(for: $0.day, calendar: calendar) == dayKey))
        }
    }

    static func slots(
        habitID: UUID,
        dayKey: String,
        target: Int,
        checkIns: [HabitCheckIn]
    ) -> [Int: HabitCheckIn] {
        let limit = max(1, min(target, 100))
        let matchingRows = matching(habitID: habitID, dayKey: dayKey, checkIns: checkIns)
        var result: [Int: HabitCheckIn] = [:]
        var unmatched: [HabitCheckIn] = []
        let byID = Dictionary(uniqueKeysWithValues: (1...limit).map {
            (slotID(habitID: habitID, dayKey: dayKey, slot: $0), $0)
        })
        for row in matchingRows {
            if let slot = byID[row.id] {
                if result[slot] == nil { result[slot] = row }
                // Duplicate CloudKit delivery of the same deterministic slot
                // must not be counted as another completed check.
            } else if !unmatched.contains(where: { $0.id == row.id }) {
                unmatched.append(row)
            }
        }
        // Legacy single-check rows keep their identity and count as slot 1.
        for row in unmatched.sorted(by: {
            $0.createdAt == $1.createdAt
                ? $0.id.uuidString < $1.id.uuidString
                : $0.createdAt < $1.createdAt
        }) {
            guard let free = (1...limit).first(where: { result[$0] == nil }) else {
                break
            }
            result[free] = row
        }
        return result
    }

    static func count(
        habitID: UUID, dayKey: String, target: Int,
        checkIns: [HabitCheckIn]
    ) -> Int {
        slots(habitID: habitID, dayKey: dayKey, target: target, checkIns: checkIns).count
    }

    static func date(from dayKey: String, calendar: Calendar) -> Date? {
        let parts = dayKey.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(
            calendar: calendar, timeZone: calendar.timeZone,
            year: parts[0], month: parts[1], day: parts[2], hour: 12
        ))
    }
}

enum HabitMultiCheckMutation {
    /// Desired slot state, not a blind toggle; newer mutations supersede delayed
    /// Watch/widget commands via the same day-level ledger as binary check-ins.
    @MainActor
    static func setSlot(
        habitID: UUID,
        dayKey: String,
        slot: Int,
        enabled: Bool,
        context: ModelContext,
        mutationAt: Date = .now,
        mutationID: UUID = UUID(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        guard let habit = habits.first(where: { $0.id == habitID }) else {
            return false
        }
        let target = habit.dailyTarget
        guard habit.supportsIncrementalGoal, (1...target).contains(slot),
              let date = HabitMultiCheck.date(from: dayKey, calendar: calendar),
              HabitDayMutationLedger.accept(
                habitID: habitID, dayKey: dayKey,
                updatedAt: mutationAt, mutationID: mutationID, context: context
              ) else { return false }

        let checkIns = (try? context.fetch(FetchDescriptor<HabitCheckIn>())) ?? []
        let slots = HabitMultiCheck.slots(
            habitID: habitID, dayKey: dayKey,
            target: target, checkIns: checkIns
        )
        if enabled, slots[slot] == nil {
            let row = HabitCheckIn(
                id: HabitMultiCheck.slotID(habitID: habitID, dayKey: dayKey, slot: slot),
                habitID: habitID, day: date, calendar: calendar
            )
            row.dayKey = dayKey
            context.insert(row)
        } else if !enabled, let row = slots[slot] {
            context.delete(row)
        } else {
            return false
        }
        let skips = (try? context.fetch(FetchDescriptor<HabitSkip>())) ?? []
        for skip in skips where skip.habitID == habitID && skip.dayKey == dayKey {
            context.delete(skip)
        }
        return true
    }
}
