import Foundation

enum WatchComplicationBridge {
    static let appGroup = "group.ru.arvectum.tools.habits"
    static let snapshotKey = "habits.watch.complication.snapshot"

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

    static func loadSnapshot() -> HabitSyncSnapshot {
        guard
            let data = defaults?.data(forKey: snapshotKey),
            let snapshot = try? JSONDecoder().decode(
                HabitSyncSnapshot.self,
                from: data
            )
        else {
            return .empty
        }
        return snapshot
    }

    static func saveSnapshot(_ snapshot: HabitSyncSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }
        defaults?.set(data, forKey: snapshotKey)
    }
}
