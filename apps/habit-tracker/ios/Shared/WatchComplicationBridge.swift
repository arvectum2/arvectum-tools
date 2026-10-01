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

    static func loadCurrentSnapshot(
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> HabitSyncSnapshot {
        let snapshot = loadSnapshot()
        return currentSnapshot(
            snapshot,
            now: now,
            calendar: calendar
        )
    }

    static func currentSnapshot(
        _ snapshot: HabitSyncSnapshot,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> HabitSyncSnapshot {
        let key = dayKey(for: now, calendar: calendar)
        return snapshot.snapshot(forDayKey: key) ?? .empty
    }

    private static func dayKey(
        for date: Date,
        calendar: Calendar
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

    static func saveSnapshot(_ snapshot: HabitSyncSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }
        defaults?.set(data, forKey: snapshotKey)
    }
}
