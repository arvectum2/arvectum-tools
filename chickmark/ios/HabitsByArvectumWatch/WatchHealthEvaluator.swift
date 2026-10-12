import Foundation
import HealthKit

/// Device-local, ephemeral projection. Rules come from the iPhone but HealthKit
/// samples, totals and pass/fail outcomes never enter WatchConnectivity or CloudKit.
enum WatchHealthEvaluator {
    static func qualifyingIDs(for habits: [HabitSyncHabit], on date: Date = .now) async -> Set<UUID> {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }
        let configured = habits.filter { $0.healthRuleMetric != nil && $0.healthRuleTarget != nil }
        guard !configured.isEmpty else { return [] }
        let store = HKHealthStore()
        let types: Set<HKObjectType> = Set(configured.compactMap { habit -> HKSampleType? in
            switch habit.healthRuleMetric {
            case "steps": return HKObjectType.quantityType(forIdentifier: .stepCount)
            case "walkingDistance": return HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)
            case "workoutMinutes", "runningWorkout": return HKObjectType.workoutType()
            case "sleepHours": return HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
            default: return nil
            }
        })
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                store.requestAuthorization(toShare: [], read: types) { success, error in
                    if let error { continuation.resume(throwing: error) }
                    else if !success { continuation.resume(throwing: NSError(domain: "HealthAccess", code: 1)) }
                    else { continuation.resume() }
                }
            }
        } catch { return [] }

        let calendar = Calendar.autoupdatingCurrent
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        var result = Set<UUID>()
        for habit in configured {
            guard !habit.completed, !habit.skipped, !habit.healthManualOverride,
                  let metric = habit.healthRuleMetric,
                  let target = habit.healthRuleTarget, target > 0 else { continue }
            let value: Double
            do {
                value = try await measure(metric: metric, store: store, start: start, end: end)
            } catch { continue }
            if value >= target { result.insert(habit.id) }
        }
        return result
    }

    private static func measure(metric: String, store: HKHealthStore,
                                start: Date, end: Date) async throws -> Double {
        if metric == "sleepHours" {
            let calendar = Calendar.autoupdatingCurrent
            let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: start)!
            let from = calendar.date(byAdding: .day, value: -1, to: noon)!
            let to = min(noon, Date())
            let samples = try await querySamples(store: store,
                type: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
                predicate: HKQuery.predicateForSamples(withStart: from, end: to))
            let periods = samples.compactMap { sample -> (Date, Date)? in
                guard let sample = sample as? HKCategorySample,
                      let state = HKCategoryValueSleepAnalysis(rawValue: sample.value),
                      HKCategoryValueSleepAnalysis.allAsleepValues.contains(state) else { return nil }
                return (max(from, sample.startDate), min(to, sample.endDate))
            }.filter { $0.1 > $0.0 }.sorted { $0.0 < $1.0 }
            var coveredUntil = from
            var total: TimeInterval = 0
            for (lower, upper) in periods {
                if upper > coveredUntil {
                    total += upper.timeIntervalSince(max(lower, coveredUntil))
                    coveredUntil = upper
                }
            }
            return total / 3600
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end,
                                                     options: [.strictStartDate, .strictEndDate])
        if metric == "runningWorkout" || metric == "workoutMinutes" {
            let samples = try await querySamples(store: store, type: HKObjectType.workoutType(),
                                                 predicate: predicate)
            let durations = samples.compactMap { $0 as? HKWorkout }
                .filter { metric != "runningWorkout" || $0.workoutActivityType == .running }
                .map { $0.duration / 60 }
            return metric == "runningWorkout" ? (durations.max() ?? 0) : durations.reduce(0, +)
        }
        let type = metric == "steps" ? HKQuantityType(.stepCount) : HKQuantityType(.distanceWalkingRunning)
        return try await withCheckedThrowingContinuation { continuation in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, result, error in
                if let error { continuation.resume(throwing: error); return }
                let raw = result?.sumQuantity()?.doubleValue(for: metric == "steps" ? .count() : .meter()) ?? 0
                continuation.resume(returning: metric == "steps" ? raw : raw / 1000)
            }
            store.execute(q)
        }
    }

    private static func querySamples(store: HKHealthStore, type: HKSampleType,
                                     predicate: NSPredicate) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            let q = HKSampleQuery(sampleType: type, predicate: predicate,
                                  limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: samples ?? []) }
            }
            store.execute(q)
        }
    }
}
