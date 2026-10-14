import Foundation

/// Watch-only derived Boolean completion for complications. Raw step counts
/// never leave HealthKit and this cache is excluded from iCloud backup.
enum WatchLocalHealthProjection {
    struct Rule: Codable, Equatable {
        let metric: String
        let target: Double
    }

    struct State: Codable, Equatable {
        let dayKey: String
        let habitIDs: [UUID]
        let generatedAt: Date
        /// Local threshold used for this decision. Reject old completions
        /// after the phone changes a target before the Watch can re-read HK.
        let rules: [UUID: Rule]?

        init(dayKey: String, habitIDs: [UUID], generatedAt: Date,
             rules: [UUID: Rule]? = nil) {
            self.dayKey = dayKey
            self.habitIDs = habitIDs
            self.generatedAt = generatedAt
            self.rules = rules
        }
    }

    /// The same deterministic threshold rule drives Watch UI and face,
    /// including a real manual override and skipped day.
    static func qualifies(_ habit: HabitSyncHabit, value: Double) -> Bool {
        guard let target = habit.healthRuleTarget,
              target.isFinite, target > 0,
              habit.healthRuleMetric != nil, value.isFinite
        else { return false }
        return value >= target && !habit.completed
            && !habit.skipped && !habit.healthManualOverride
    }

    private static func rules(for habits: [HabitSyncHabit],
                              qualifyingIDs: Set<UUID>) -> [UUID: Rule] {
        Dictionary(uniqueKeysWithValues: habits.compactMap { habit in
            guard qualifyingIDs.contains(habit.id),
                  let metric = habit.healthRuleMetric,
                  let target = habit.healthRuleTarget,
                  target.isFinite, target > 0 else { return nil }
            return (habit.id, Rule(metric: metric, target: target))
        })
    }

    private static func cacheURL() -> URL? {
        guard let group = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: WatchComplicationBridge.appGroup
        ) else { return nil }
        return group.appendingPathComponent(
            "Library/Caches/chickmark-watch-health-complication-v1.json"
        )
    }

    @discardableResult
    static func save(dayKey: String, habitIDs: Set<UUID>,
                     habits: [HabitSyncHabit], at now: Date = .now) -> Bool {
        guard var url = cacheURL(), !dayKey.isEmpty else { return false }
        let currentRules = rules(for: habits, qualifyingIDs: habitIDs)
        let sortedIDs = currentRules.keys.sorted { $0.uuidString < $1.uuidString }
        if let prior = load(), prior.dayKey == dayKey &&
            prior.habitIDs == sortedIDs && prior.rules == currentRules {
            return false
        }
        let state = State(dayKey: dayKey, habitIDs: sortedIDs,
                          generatedAt: now, rules: currentRules)
        guard let encoded = try? JSONEncoder().encode(state) else { return false }
        var folder = url.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try? folder.setResourceValues(resourceValues)
            try encoded.write(to: url, options: [.atomic])
            try? url.setResourceValues(resourceValues)
            return true
        } catch {
            return false
        }
    }

    static func load() -> State? {
        guard let url = cacheURL(), let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(State.self, from: data)
    }

    static func decorate(_ snapshot: HabitSyncSnapshot, now: Date = .now) -> HabitSyncSnapshot {
        guard let state = load() else { return snapshot }
        return applying(snapshot, state: state, now: now)
    }

    /// Pure merge: never modify authoritative WCSession/SwiftData snapshots.
    /// Exclude explicit manual overrides, skipped days and old-day caches.
    static func applying(
        _ snapshot: HabitSyncSnapshot, state: State, now: Date = .now
    ) -> HabitSyncSnapshot {
        guard !snapshot.dayKey.isEmpty,
              state.dayKey == snapshot.dayKey,
              now >= state.generatedAt,
              now.timeIntervalSince(state.generatedAt) < 24 * 3600
        else { return snapshot }

        var projected = snapshot
        let qualifying = Set(state.habitIDs)
        var newlyCompleted = 0
        for index in projected.habits.indices {
            let habit = projected.habits[index]
            guard qualifying.contains(habit.id),
                  let rule = state.rules?[habit.id],
                  rule.metric == habit.healthRuleMetric,
                  rule.target == habit.healthRuleTarget,
                  !habit.completed, !habit.skipped, !habit.healthManualOverride
            else { continue }
            projected.habits[index].completed = true
            newlyCompleted += 1
        }
        // Snapshots can be payload-budget trimmed; don't recompute totals
        // from only the visible habit subset.
        projected.completedCount = min(
            max(0, projected.totalCount - projected.skippedCount),
            max(0, snapshot.completedCount + newlyCompleted)
        )
        return projected
    }
}
