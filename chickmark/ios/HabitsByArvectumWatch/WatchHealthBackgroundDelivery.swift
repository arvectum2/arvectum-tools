import Foundation
import HealthKit
import WidgetKit
import OSLog

/// Register while launching, including when watchOS wakes the process for a
/// HealthKit background delivery. HealthKit grants a limited background
/// execution budget: never promise real-time complication updates.
/// Only opt-in metrics already present in the local watch snapshot are used.
@MainActor
final class WatchHealthBackgroundDelivery {
    static let shared = WatchHealthBackgroundDelivery()

    private let healthStore = HKHealthStore()
    private let log = Logger(
        subsystem: "ru.arvectum.tools.habits.watch",
        category: "health-background"
    )
    private var queries: [String: HKObserverQuery] = [:]
    private var observedTypes: [String: HKSampleType] = [:]
    private var running = false

    private init() {}

    func configure() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        // Don't read the derived WidgetKit overlay: it is not authoritative
        // about the metric and target currently set on the iPhone.
        let snapshot = WatchComplicationBridge.currentSnapshot(
            WatchComplicationBridge.loadSnapshot()
        )
        var types: [String: HKSampleType] = [:]
        for habit in snapshot.habits {
            guard let metric = habit.healthRuleMetric,
                  let target = habit.healthRuleTarget, target > 0,
                  let type = Self.sampleType(metric) else { continue }
            types[type.identifier] = type
        }
        // Remove observation when the final habit for a data type disconnects.
        for key in Array(queries.keys) where types[key] == nil {
            if let query = queries.removeValue(forKey: key) {
                healthStore.stop(query)
            }
            if let old = observedTypes.removeValue(forKey: key) {
                healthStore.disableBackgroundDelivery(for: old) { _, _ in }
            }
        }
        for (key, type) in types where queries[key] == nil {
            let observer = HKObserverQuery(sampleType: type, predicate: nil) {
                [weak self] _, completion, error in
                guard error == nil else {
                    completion()
                    return
                }
                Task { @MainActor in
                    if let self {
                        await self.updateProjection()
                    }
                    completion()
                }
            }
            queries[key] = observer
            observedTypes[key] = type
            healthStore.execute(observer)
            healthStore.enableBackgroundDelivery(
                for: type, frequency: .immediate
            ) { [weak self] success, error in
                guard !success else { return }
                Task { @MainActor in
                    self?.log.error(
                        "Watch HealthKit background delivery unavailable: \(error?.localizedDescription ?? "unknown", privacy: .public)"
                    )
                }
            }
        }
    }

    private static func sampleType(_ metric: String) -> HKSampleType? {
        switch metric {
        case "steps":
            return HKObjectType.quantityType(forIdentifier: .stepCount)
        case "walkingDistance":
            return HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)
        case "workoutMinutes", "runningWorkout":
            return HKObjectType.workoutType()
        case "sleepHours":
            return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        default:
            return nil
        }
    }

    private static func sameHealthRules(
        _ current: [HabitSyncHabit], _ expected: [HabitSyncHabit]
    ) -> Bool {
        guard current.count == expected.count else { return false }
        for index in current.indices {
            let currentHabit = current[index]
            let expectedHabit = expected[index]
            if currentHabit.id != expectedHabit.id ||
                currentHabit.healthRuleMetric != expectedHabit.healthRuleMetric ||
                currentHabit.healthRuleTarget != expectedHabit.healthRuleTarget {
                return false
            }
        }
        return true
    }

    private func updateProjection() async {
        guard !running else { return }
        running = true
        defer { running = false }

        let before = WatchComplicationBridge.currentSnapshot(
            WatchComplicationBridge.loadSnapshot()
        )
        guard !before.dayKey.isEmpty,
              before.habits.contains(where: { $0.healthRuleMetric != nil })
        else { return }

        // Authorization was requested by WatchTodayView earlier, with user
        // consent. Never prompt when watchOS delivers a background event.
        let result = await WatchHealthEvaluator.evaluate(
            for: before.habits, requestAuthorization: false
        )
        let after = WatchComplicationBridge.currentSnapshot(
            WatchComplicationBridge.loadSnapshot()
        )
        guard after.dayKey == before.dayKey,
              after.generatedAt == before.generatedAt,
              Self.sameHealthRules(after.habits, before.habits)
        else { return }

        // An empty read could mean HealthKit read access isn't yet granted.
        // It must not erase a previously verified checkoff in the background.
        guard result.progress.values.contains(where: { $0.current > 0 }) else { return }
        if WatchLocalHealthProjection.save(
            dayKey: after.dayKey,
            habitIDs: result.qualifyingIDs,
            habits: after.habits
        ) {
            WidgetCenter.shared.reloadTimelines(ofKind: "HabitsWatchComplication")
        }
    }
}
