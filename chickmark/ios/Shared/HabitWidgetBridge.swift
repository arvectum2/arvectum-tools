import Foundation

enum HabitWidgetBridge {
    static let appGroup = "group.ru.arvectum.tools.habits"
    static let snapshotKey = "habits.widget.snapshot"
    static let horizonKey = "habits.widget.horizon"
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

    static func loadCurrentSnapshot(
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> HabitWidgetSnapshot {
        let key = dayKey(for: now, calendar: calendar)
        let snapshot = loadSnapshot()
        let base = snapshot.dayKey == key ? snapshot
            : (loadHorizon().first(where: { $0.dayKey == key }) ?? .empty)
        return LocalHealthWidgetProjection.decorate(base)
    }

    static func loadHorizon() -> [HabitWidgetSnapshot] {
        guard
            let data = defaults?.data(forKey: horizonKey),
            let snapshots = try? JSONDecoder().decode(
                [HabitWidgetSnapshot].self,
                from: data
            )
        else {
            return []
        }
        return snapshots
    }

    static func dayKey(
        for date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    /// WidgetKit can display yesterday's timeline entry just after midnight.
    /// Never turn a stale button tap into a historical or future check-in.
    /// Check at intent execution time, not when the timeline is rendered.
    static func acceptsAction(
        dayKey actionDayKey: String,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        actionDayKey == dayKey(for: now, calendar: calendar)
    }

    static func saveSnapshot(_ snapshot: HabitWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: snapshotKey)
    }

    static func saveHorizon(_ snapshots: [HabitWidgetSnapshot]) {
        guard let data = try? JSONEncoder().encode(snapshots) else { return }
        defaults?.set(data, forKey: horizonKey)
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

        commands.removeAll {
            $0.habitID == command.habitID && $0.dayKey == command.dayKey
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
        if snapshot.dayKey != command.dayKey {
            guard let projected = loadHorizon().first(where: {
                $0.dayKey == command.dayKey
            }) else { return }
            snapshot = projected
        }
        guard let index = snapshot.habits.firstIndex(where: {
            $0.id == command.habitID
        }) else { return }

        snapshot.habits[index].completed = command.completed
        if let target = snapshot.habits[index].dailyTarget {
            snapshot.habits[index].dailyCount = min(
                max(command.desiredCount ?? (command.completed ? target : 0), 0),
                target
            )
            snapshot.habits[index].completed =
                snapshot.habits[index].dailyCount == target
        }
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


enum HabitWidgetPresentation {
    static func prioritized(
        _ habits: [HabitWidgetHabit]
    ) -> [HabitWidgetHabit] {
        let unresolved = habits.filter {
            !$0.completed && !$0.skipped
        }
        let resolved = habits.filter {
            $0.completed || $0.skipped
        }
        return unresolved + resolved
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
    var dailyTarget: Int? = nil
    var dailyCount: Int? = nil
    var durationStepMinutes: Int? = nil
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
    /// Optional partial-count target; absent in published 1.2 commands.
    let desiredCount: Int?

    init(
        id: UUID = UUID(),
        habitID: UUID,
        dayKey: String,
        completed: Bool,
        desiredCount: Int? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.habitID = habitID
        self.dayKey = dayKey
        self.completed = completed
        self.desiredCount = desiredCount
        self.createdAt = createdAt
    }
}


// Privacy boundary: the widget reads local-only ephemeral derived status from
// the app group Caches directory (never CloudKit, backed-up preferences or
// the public widget snapshot). The file is explicitly excluded from backup.
enum LocalHealthWidgetProjection {
    struct State: Codable {
        let dayKey: String
        let habitIDs: [UUID]
        let generatedAt: Date
    }

    static func url() -> URL? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: HabitWidgetBridge.appGroup
        ) else { return nil }
        return container.appendingPathComponent("Library/Caches/chickmark-health-widget-v1.json")
    }

    static func save(dayKey: String, habitIDs: [UUID]) {
        guard var url = url() else { return }
        var folder = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? folder.setResourceValues(values)
        let state = State(dayKey: dayKey, habitIDs: habitIDs, generatedAt: .now)
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: url, options: [.atomic])
        try? url.setResourceValues(values)
    }

    static func decorate(_ snapshot: HabitWidgetSnapshot,
                         now: Date = .now) -> HabitWidgetSnapshot {
        guard let url = url(), let data = try? Data(contentsOf: url),
              let state = try? JSONDecoder().decode(State.self, from: data),
              state.dayKey == snapshot.dayKey,
              now.timeIntervalSince(state.generatedAt) < 24 * 3600
        else { return snapshot }
        var result = snapshot
        let ids = Set(state.habitIDs)
        for index in result.habits.indices where ids.contains(result.habits[index].id) {
            if !result.habits[index].skipped && !result.habits[index].completed {
                result.habits[index].completed = true
            }
        }
        result.completedCount = result.habits.filter(\.completed).count
        return result
    }
}
