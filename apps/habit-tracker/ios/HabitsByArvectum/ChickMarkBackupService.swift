import Foundation
import SwiftData

@MainActor
enum ChickMarkBackupService {
    enum ImportMode { case merge, replace }

    static func capture(from context: ModelContext) throws -> ChickMarkBackup {
        let habits = try context.fetch(FetchDescriptor<Habit>())
        let ids = Set(habits.map(\.id))
        let checkIns = try context.fetch(FetchDescriptor<HabitCheckIn>())
            .filter { ids.contains($0.habitID) }
        let skips = try context.fetch(FetchDescriptor<HabitSkip>())
            .filter { ids.contains($0.habitID) }
        let pauses = try context.fetch(FetchDescriptor<HabitPausePeriod>())
            .filter { ids.contains($0.habitID) }
        let mutations = try context.fetch(FetchDescriptor<HabitDayMutation>())
            .filter { ids.contains($0.habitID) }
        let oneOffs = try context.fetch(FetchDescriptor<OneOffReminder>())
        return ChickMarkBackup(
            formatVersion: ChickMarkBackup.supportedVersion,
            createdAt: .now,
            habits: habits.map {
                .init(id: $0.id, name: $0.name, symbolName: $0.symbolName,
                      colorHex: $0.colorHex, createdAt: $0.createdAt,
                      isArchived: $0.isArchived, scheduleMask: $0.scheduleMask,
                      reminderEnabled: $0.reminderEnabled,
                      reminderHour: $0.reminderHour, reminderMinute: $0.reminderMinute,
                      pausedAt: $0.pausedAt, weeklyTarget: $0.weeklyTarget,
                      sortOrder: $0.sortOrder)
            },
            checkIns: checkIns.map {
                .init(id: $0.id, habitID: $0.habitID, day: $0.day,
                      dayKey: $0.dayKey, createdAt: $0.createdAt)
            },
            skips: skips.map {
                .init(id: $0.id, habitID: $0.habitID, day: $0.day,
                      dayKey: $0.dayKey, createdAt: $0.createdAt)
            },
            pauses: pauses.map {
                .init(id: $0.id, habitID: $0.habitID, startedAt: $0.startedAt,
                      startDayKey: $0.startDayKey, endedAt: $0.endedAt,
                      endDayKeyExclusive: $0.endDayKeyExclusive)
            },
            mutations: mutations.map {
                .init(id: $0.id, habitID: $0.habitID, dayKey: $0.dayKey,
                      updatedAt: $0.updatedAt, mutationID: $0.mutationID)
            },
            oneOffs: oneOffs.map {
                .init(id: $0.id, title: $0.title, dueAt: $0.dueAt,
                      createdAt: $0.createdAt, isCompleted: $0.isCompleted,
                      completedAt: $0.completedAt)
            },
            groups: ChickMarkGroups.load()
        )
    }

    static func restore(
        _ backup: ChickMarkBackup,
        to context: ModelContext,
        mode: ImportMode
    ) throws {
        // Validate the entire document before any mutation.
        try backup.validate()
        let existingHabits = try context.fetch(FetchDescriptor<Habit>())
        let existingCheckIns = try context.fetch(FetchDescriptor<HabitCheckIn>())
        let existingSkips = try context.fetch(FetchDescriptor<HabitSkip>())
        let existingPauses = try context.fetch(FetchDescriptor<HabitPausePeriod>())
        let existingMutations = try context.fetch(FetchDescriptor<HabitDayMutation>())
        let existingOneOffs = try context.fetch(FetchDescriptor<OneOffReminder>())
        if mode == .replace {
            for item in existingCheckIns { context.delete(item) }
            for item in existingSkips { context.delete(item) }
            for item in existingPauses { context.delete(item) }
            for item in existingMutations { context.delete(item) }
            for item in existingHabits { context.delete(item) }
            for item in existingOneOffs { context.delete(item) }
        }

        let priorHabitIDs = mode == .merge ? Set(existingHabits.map(\.id)) : []
        let priorCheckInIDs = mode == .merge ? Set(existingCheckIns.map(\.id)) : []
        let priorSkipIDs = mode == .merge ? Set(existingSkips.map(\.id)) : []
        let priorPauseIDs = mode == .merge ? Set(existingPauses.map(\.id)) : []
        let priorMutationIDs = mode == .merge ? Set(existingMutations.map(\.id)) : []
        let priorOneOffIDs = mode == .merge ? Set(existingOneOffs.map(\.id)) : []

        for item in backup.habits where !priorHabitIDs.contains(item.id) {
            let habit = Habit(
                id: item.id, name: item.name, symbolName: item.symbolName,
                colorHex: item.colorHex, createdAt: item.createdAt,
                isArchived: item.isArchived, scheduleMask: item.scheduleMask,
                reminderEnabled: item.reminderEnabled, reminderHour: item.reminderHour,
                reminderMinute: item.reminderMinute, pausedAt: item.pausedAt,
                weeklyTarget: item.weeklyTarget, sortOrder: item.sortOrder
            )
            context.insert(habit)
        }
        for item in backup.checkIns where !priorCheckInIDs.contains(item.id) {
            let checkIn = HabitCheckIn(
                id: item.id, habitID: item.habitID, day: item.day,
                createdAt: item.createdAt
            )
            checkIn.dayKey = item.dayKey
            context.insert(checkIn)
        }
        for item in backup.skips where !priorSkipIDs.contains(item.id) {
            let skip = HabitSkip(
                id: item.id, habitID: item.habitID, day: item.day,
                createdAt: item.createdAt
            )
            skip.dayKey = item.dayKey
            context.insert(skip)
        }
        for item in backup.pauses where !priorPauseIDs.contains(item.id) {
            let pause = HabitPausePeriod(
                id: item.id, habitID: item.habitID, startedAt: item.startedAt,
                endedAt: item.endedAt
            )
            pause.startDayKey = item.startDayKey
            pause.endDayKeyExclusive = item.endDayKeyExclusive
            context.insert(pause)
        }
        for item in backup.mutations where !priorMutationIDs.contains(item.id) {
            context.insert(HabitDayMutation(
                id: item.id, habitID: item.habitID, dayKey: item.dayKey,
                updatedAt: item.updatedAt, mutationID: item.mutationID
            ))
        }
        for item in backup.oneOffs where !priorOneOffIDs.contains(item.id) {
            context.insert(OneOffReminder(
                id: item.id, title: item.title, dueAt: item.dueAt,
                createdAt: item.createdAt, isCompleted: item.isCompleted,
                completedAt: item.completedAt
            ))
        }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        if let groups = backup.groups {
            if mode == .replace {
                ChickMarkGroups.save(groups)
            } else {
                ChickMarkGroups.merge(groups)
            }
        }
        HabitDataChangeNotifier.notify()
    }
}
