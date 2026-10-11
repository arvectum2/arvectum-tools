import Foundation
import SwiftData

@Model
final class HabitDayMutation {
    var id: UUID = UUID()
    var habitID: UUID = UUID()
    var dayKey: String = ""
    var updatedAt: Date = Date.distantPast
    var mutationID: UUID = UUID()

    init(
        id: UUID = UUID(),
        habitID: UUID,
        dayKey: String,
        updatedAt: Date,
        mutationID: UUID
    ) {
        self.id = id
        self.habitID = habitID
        self.dayKey = dayKey
        self.updatedAt = updatedAt
        self.mutationID = mutationID
    }
}

enum HabitDayMutationLedger {
    @MainActor
    static func accept(
        habitID: UUID,
        dayKey: String,
        updatedAt: Date,
        mutationID: UUID,
        context: ModelContext
    ) -> Bool {
        let stamps = ((try? context.fetch(
            FetchDescriptor<HabitDayMutation>()
        )) ?? []).filter {
            $0.habitID == habitID && $0.dayKey == dayKey
        }

        if let newest = stamps.max(by: isOlder) {
            guard isNewer(
                updatedAt: updatedAt,
                mutationID: mutationID,
                than: newest
            ) else {
                return false
            }

            newest.updatedAt = updatedAt
            newest.mutationID = mutationID
            for duplicate in stamps where duplicate.id != newest.id {
                context.delete(duplicate)
            }
            return true
        }

        context.insert(
            HabitDayMutation(
                habitID: habitID,
                dayKey: dayKey,
                updatedAt: updatedAt,
                mutationID: mutationID
            )
        )
        return true
    }

    private static func isOlder(
        _ lhs: HabitDayMutation,
        _ rhs: HabitDayMutation
    ) -> Bool {
        if lhs.updatedAt != rhs.updatedAt {
            return lhs.updatedAt < rhs.updatedAt
        }
        return lhs.mutationID.uuidString < rhs.mutationID.uuidString
    }

    private static func isNewer(
        updatedAt: Date,
        mutationID: UUID,
        than existing: HabitDayMutation
    ) -> Bool {
        if updatedAt != existing.updatedAt {
            return updatedAt > existing.updatedAt
        }
        return mutationID.uuidString > existing.mutationID.uuidString
    }
}
