import Foundation

enum HabitWidgetBridge {
    static let appGroup = "group.ru.arvectum.tools.habits"
    static let snapshotKey = "habits.widget.snapshot"
    static let commandsKey = "habits.widget.commands"

#if DEBUG
    static var defaultsOverride: UserDefaults?
#endif

    static var defaults: UserDefaults? {
#if DEBUG
        if let defaultsOverride {
            return defaultsOverride
        }
#endif
        return UserDefaults(suiteName: appGroup)
    }

    static func loadSnapshot() -> HabitWidgetSnapshot {
        guard
            let data = defaults?.data(forKey: snapshotKey),
            let snapshot = try? JSONDecoder().decode(
                HabitWidgetSnapshot.self,
                from: data
            )
        else {
            return .empty
        }
        return snapshot
    }

    static func saveSnapshot(_ snapshot: HabitWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: snapshotKey)
    }

    static func loadCommands() -> [HabitWidgetCommand] {
        guard
            let data = defaults?.data(forKey: commandsKey),
            let commands = try? JSONDecoder().decode(
                [HabitWidgetCommand].self,
                from: data
            )
        else {
            return []
        }
        return commands
    }

    static func appendCommand(_ command: HabitWidgetCommand) {
        var commands = loadCommands()
        guard !commands.contains(where: { $0.id == command.id }) else {
            return
        }
        commands.append(command)
        if commands.count > 100 {
            commands.removeFirst(commands.count - 100)
        }
        saveCommands(commands)
    }

    static func removeCommands(ids: Set<UUID>) {
        let remaining = loadCommands().filter { !ids.contains($0.id) }
        saveCommands(remaining)
    }

    static func saveCommands(_ commands: [HabitWidgetCommand]) {
        guard let data = try? JSONEncoder().encode(commands) else { return }
        defaults?.set(data, forKey: commandsKey)
    }

    static func applyOptimistic(_ command: HabitWidgetCommand) {
        var snapshot = loadSnapshot()
        guard snapshot.dayKey == command.dayKey else { return }
        guard let index = snapshot.habits.firstIndex(where: {
            $0.id == command.habitID
        }) else { return }

        snapshot.habits[index].completed = command.completed
        if command.completed {
            snapshot.habits[index].skipped = false
        }
        snapshot.completedCount = snapshot.habits.filter(\.completed).count
        snapshot.skippedCount = snapshot.habits.filter {
            !$0.completed && $0.skipped
        }.count
        snapshot.generatedAt = .now
        saveSnapshot(snapshot)
    }
}

struct HabitWidgetHabit: Codable, Hashable, Identifiable {
    let id: UUID
    var name: String
    var symbolName: String
    var colorHex: String
    var completed: Bool
    var skipped: Bool
    var streak: Int
    var weeklyTarget: Int? = nil
    var weeklyCount: Int? = nil
}

struct HabitWidgetSnapshot: Codable, Hashable {
    var generatedAt: Date
    var dayKey: String
    var completedCount: Int
    var skippedCount: Int
    var totalCount: Int
    var habits: [HabitWidgetHabit]

    static let empty = HabitWidgetSnapshot(
        generatedAt: .distantPast,
        dayKey: "",
        completedCount: 0,
        skippedCount: 0,
        totalCount: 0,
        habits: []
    )

    var resolvedCount: Int {
        completedCount + skippedCount
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(resolvedCount) / Double(totalCount)
    }
}

struct HabitWidgetCommand: Codable, Hashable, Identifiable {
    let id: UUID
    let habitID: UUID
    let dayKey: String
    let completed: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        habitID: UUID,
        dayKey: String,
        completed: Bool,
        createdAt: Date = .now
    ) {
        self.id = id
        self.habitID = habitID
        self.dayKey = dayKey
        self.completed = completed
        self.createdAt = createdAt
    }
}
