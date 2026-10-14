import Foundation
import HealthKit

/// Device-local, ephemeral projection. Rules come from the iPhone but HealthKit
/// samples, totals and pass/fail outcomes never enter WatchConnectivity or CloudKit.
struct WatchHealthEvaluation {
    let progress: [UUID: WatchHealthProgress]
    let qualifyingIDs: Set<UUID>

    static let empty = WatchHealthEvaluation(progress: [:], qualifyingIDs: [])
}

enum WatchHealthEvaluator {
    static func evaluate(for habits: [HabitSyncHabit], on date: Date = .now) async -> WatchHealthEvaluation {
        // WatchKit terminates an app requesting HealthKit reads when its own
        // Info.plist omits the privacy purpose string (the phone's plist does
        // not cover the independently running watchOS app).
        guard let purpose = Bundle.main.object(
            forInfoDictionaryKey: "NSHealthShareUsageDescription"
        ) as? String, !purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return .empty }
        guard HKHealthStore.isHealthDataAvailable() else { return .empty }
        let configured = habits.filter {
            guard let target = $0.healthRuleTarget else { return false }
            return $0.healthRuleMetric != nil && target.isFinite && target > 0
        }
        guard !configured.isEmpty else { return .empty }
        let store = HKHealthStore()
        let types: Set<HKObjectType> = Set(configured.compactMap {
            sampleType(for: $0.healthRuleMetric)
        })
        guard !types.isEmpty else { return .empty }
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                store.requestAuthorization(toShare: [], read: types) { success, error in
                    if let error { continuation.resume(throwing: error) }
                    else if !success { continuation.resume(throwing: NSError(domain: "HealthAccess", code: 1)) }
                    else { continuation.resume() }
                }
            }
        } catch { return .empty }

        let calendar = Calendar.autoupdatingCurrent
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return .empty }
        var result = Set<UUID>()
        var progress: [UUID: WatchHealthProgress] = [:]
        // Reuse the same local query for habits bound to the same metric.
        // Measurements are never serialized or sent to the phone.
        var values: [String: Double] = [:]
        for habit in configured {
            guard let metric = habit.healthRuleMetric,
                  let target = habit.healthRuleTarget,
                  sampleType(for: metric) != nil else { continue }
            let value: Double
            if let cached = values[metric] {
                value = cached
            } else {
                do {
                    value = try await measure(metric: metric, store: store, start: start, end: end)
                } catch { continue }
                values[metric] = value
            }
            guard value.isFinite else { continue }
            progress[habit.id] = WatchHealthProgress(metric: metric, current: value, target: target)
            if !habit.completed && !habit.skipped && !habit.healthManualOverride &&
                value >= target {
                result.insert(habit.id)
            }
        }
        return WatchHealthEvaluation(progress: progress, qualifyingIDs: result)
    }

    private static func sampleType(for metric: String?) -> HKSampleType? {
        switch metric {
        case "steps": HKObjectType.quantityType(forIdentifier: .stepCount)
        case "walkingDistance": HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)
        case "workoutMinutes", "runningWorkout": HKObjectType.workoutType()
        case "sleepHours": HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        default: nil
        }
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
