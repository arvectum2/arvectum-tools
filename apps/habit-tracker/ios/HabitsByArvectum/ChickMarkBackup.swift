import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// An explicit, user-controlled JSON backup. No data is sent to Arvectum servers.
/// Files are plaintext; the user chooses a secure destination.
struct ChickMarkBackup: Codable {
    static let supportedVersion = 1
    let formatVersion: Int
    let createdAt: Date
    let habits: [HabitRecord]
    let checkIns: [CheckInRecord]
    let skips: [SkipRecord]
    let pauses: [PauseRecord]
    let mutations: [MutationRecord]
    let oneOffs: [OneOffRecord]
    // Optional for backwards-compatible imports of backups made before groups.
    var groups: [ChickMarkGroup]?

    struct HabitRecord: Codable {
        let id: UUID
        let name: String
        let symbolName: String
        let colorHex: String
        let createdAt: Date
        let isArchived: Bool
        let scheduleMask: Int
        let reminderEnabled: Bool
        let reminderHour: Int
        let reminderMinute: Int
        let pausedAt: Date?
        let weeklyTarget: Int
        let sortOrder: Int
    }

    struct CheckInRecord: Codable {
        let id: UUID
        let habitID: UUID
        let day: Date
        let dayKey: String?
        let createdAt: Date
    }

    struct SkipRecord: Codable {
        let id: UUID
        let habitID: UUID
        let day: Date
        let dayKey: String
        let createdAt: Date
    }

    struct PauseRecord: Codable {
        let id: UUID
        let habitID: UUID
        let startedAt: Date
        let startDayKey: String
        let endedAt: Date?
        let endDayKeyExclusive: String?
    }

    struct MutationRecord: Codable {
        let id: UUID
        let habitID: UUID
        let dayKey: String
        let updatedAt: Date
        let mutationID: UUID
    }

    struct OneOffRecord: Codable {
        let id: UUID
        let title: String
        let dueAt: Date
        let createdAt: Date
        let isCompleted: Bool
        let completedAt: Date?
    }

    func validate() throws {
        guard formatVersion == Self.supportedVersion else {
            throw BackupError.unsupportedVersion
        }
        guard !habits.contains(where: { $0.name.isEmpty }),
              !oneOffs.contains(where: { $0.title.isEmpty })
        else { throw BackupError.invalidData }
        guard Set(habits.map(\.id)).count == habits.count,
              Set(checkIns.map(\.id)).count == checkIns.count,
              Set(skips.map(\.id)).count == skips.count,
              Set(pauses.map(\.id)).count == pauses.count,
              Set(mutations.map(\.id)).count == mutations.count,
              Set(oneOffs.map(\.id)).count == oneOffs.count
        else { throw BackupError.invalidData }
        let habitIDs = Set(habits.map(\.id))
        guard checkIns.allSatisfy({ habitIDs.contains($0.habitID) }),
              skips.allSatisfy({ habitIDs.contains($0.habitID) }),
              pauses.allSatisfy({ habitIDs.contains($0.habitID) }),
              mutations.allSatisfy({ habitIDs.contains($0.habitID) })
        else { throw BackupError.invalidData }
    }
}

enum BackupError: LocalizedError {
    case unsupportedVersion
    case invalidData
    case unreadableDocument

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion: L10n.string("backup.error.version")
        case .invalidData: L10n.string("backup.error.invalid")
        case .unreadableDocument: L10n.string("backup.error.unreadable")
        }
    }
}

struct ChickMarkBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var backup: ChickMarkBackup

    init(backup: ChickMarkBackup) {
        self.backup = backup
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw BackupError.unreadableDocument
        }
        backup = try JSONDecoder().decode(ChickMarkBackup.self, from: data)
        try backup.validate()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try backup.validate()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return FileWrapper(regularFileWithContents: try encoder.encode(backup))
    }
}

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
