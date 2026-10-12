import Foundation
import HealthKit
import SwiftData

enum HealthHabitMetric: String, Codable, CaseIterable, Identifiable {
    case steps
    case walkingDistance
    case workoutMinutes
    case runningWorkout
    case sleepHours

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .steps: "health.metric.steps"
        case .walkingDistance: "health.metric.distance"
        case .workoutMinutes: "health.metric.workouts"
        case .runningWorkout: "health.metric.running"
        case .sleepHours: "health.metric.sleep"
        }
    }

    var unitKey: String {
        switch self {
        case .steps: "health.unit.steps"
        case .walkingDistance: "health.unit.kilometers"
        case .workoutMinutes, .runningWorkout: "health.unit.minutes"
        case .sleepHours: "health.unit.hours"
        }
    }

    var defaultTarget: Double {
        switch self {
        case .steps: 5_000
        case .walkingDistance: 3
        case .workoutMinutes, .runningWorkout: 20
        case .sleepHours: 7
        }
    }

    var sampleType: HKSampleType {
        switch self {
        case .steps:
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        case .walkingDistance:
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        case .workoutMinutes, .runningWorkout:
            HKObjectType.workoutType()
        case .sleepHours:
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        }
    }

    var quantityUnit: HKUnit {
        switch self {
        case .steps: .count()
        case .walkingDistance: .meter()
        case .workoutMinutes, .runningWorkout: .minute()
        case .sleepHours: .hour()
        }
    }

    func normalized(_ value: Double) -> Double {
        self == .walkingDistance ? value / 1_000 : value
    }

    /// A weekly goal is meaningful for an individual qualifying run, not
    /// cumulative daily steps or arbitrary workout minutes.
    var supportsWeeklyGoal: Bool { self == .runningWorkout }
}

struct HealthHabitRule: Codable, Equatable {
    let metric: HealthHabitMetric
    let target: Double
    let enabledAt: Date

    var isValid: Bool {
        target.isFinite && target > 0 && target <= 100_000
    }
}

struct HealthHabitEvidence: Codable {
    let mutationID: UUID
    let metric: HealthHabitMetric
    let markedAt: Date
}

/// Local-only preferences and source attribution. Neither HealthKit samples nor
/// raw values enter SwiftData, CloudKit, widgets, the Watch, or the ad SDK.
@MainActor
final class HealthHabitRuleStore {
    static let shared = HealthHabitRuleStore()

    private let defaults: UserDefaults
    private let rulesKey = "chickmark.health.rules.v1"
    private let evidenceKey = "chickmark.health.evidence.v1"
    private var rules: [String: HealthHabitRule]
    private var evidence: [String: HealthHabitEvidence]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        rules = Self.decode([String: HealthHabitRule].self, from: defaults.data(forKey: rulesKey)) ?? [:]
        evidence = Self.decode([String: HealthHabitEvidence].self, from: defaults.data(forKey: evidenceKey)) ?? [:]
    }

    func rule(for habitID: UUID) -> HealthHabitRule? {
        rules[habitID.uuidString]
    }

    var activeMetrics: Set<HealthHabitMetric> {
        Set(rules.values.map(\.metric))
    }

    var allRules: [(UUID, HealthHabitRule)] {
        rules.compactMap { key, value in UUID(uuidString: key).map { ($0, value) } }
    }

    func save(_ rule: HealthHabitRule, for habitID: UUID) {
        guard rule.isValid else { return }
        rules[habitID.uuidString] = rule
        persistRules()
    }

    func disable(for habitID: UUID) {
        rules.removeValue(forKey: habitID.uuidString)
        persistRules()
    }

    func source(for habitID: UUID, dayKey: String, mutationID: UUID) -> HealthHabitMetric? {
        let key = "\(habitID.uuidString):\(dayKey)"
        guard let record = evidence[key], record.mutationID == mutationID else { return nil }
        return record.metric
    }

    func record(_ source: HealthHabitEvidence, habitID: UUID, dayKey: String) {
        evidence["\(habitID.uuidString):\(dayKey)"] = source
        // Source badges are retained locally for 120 days; check-ins remain permanent.
        let expiry = Date().addingTimeInterval(-120 * 24 * 60 * 60)
        evidence = evidence.filter { $0.value.markedAt >= expiry }
        defaults.set(try? JSONEncoder().encode(evidence), forKey: evidenceKey)
    }

    private func persistRules() {
        defaults.set(try? JSONEncoder().encode(rules), forKey: rulesKey)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

enum HealthHabitAutoPolicy {
    /// A manual action (including Watch/Shortcuts/undo) always takes precedence.
    /// A recorded mutation blocks auto-recompletion even if its check-in was removed.
    static func shouldComplete(
        habit: Habit,
        rule: HealthHabitRule,
        day: Date,
        now: Date,
        checkIns: [HabitCheckIn],
        skips: [HabitSkip],
        pausePeriods: [HabitPausePeriod],
        mutations: [HabitDayMutation],
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        guard rule.isValid, !habit.isArchived, !habit.isPaused,
              !habit.supportsIncrementalGoal,
              (!habit.usesFlexibleWeeklyTarget || rule.metric.supportsWeeklyGoal),
              !habit.usesCompletionInterval else { return false }

        let start = calendar.startOfDay(for: day)
        guard start <= now,
              start >= calendar.startOfDay(for: rule.enabledAt),
              start >= calendar.startOfDay(for: habit.createdAt) else { return false }
        let key = HabitDayKey.make(for: day, calendar: calendar)

        guard !mutations.contains(where: { $0.habitID == habit.id && $0.dayKey == key }),
              !skips.contains(where: { $0.habitID == habit.id && $0.dayKey == key }),
              !checkIns.contains(where: {
                  $0.habitID == habit.id &&
                  ($0.dayKey == key || ($0.dayKey == nil &&
                      HabitDayKey.make(for: $0.day, calendar: calendar) == key))
              }),
              !pausePeriods.contains(where: { $0.habitID == habit.id && $0.contains(dayKey: key) })
        else { return false }

        return HabitFrequency.isDue(habit: habit, on: day, checkIns: checkIns,
                                    skips: skips, pausePeriods: pausePeriods, calendar: calendar)
    }
}

enum HealthHabitError: LocalizedError {
    case unavailable
    case authorizationFailed
    var errorDescription: String? {
        switch self {
        case .unavailable: L10n.string("health.error.unavailable")
        case .authorizationFailed: L10n.string("health.error.authorization")
        }
    }
}

/// HealthKit is accessed on the iPhone only; accepted completions use the same
/// mutation ledger and sync transport as manual check-ins.
@MainActor
final class HealthHabitCoordinator {
    static let shared = HealthHabitCoordinator()

    private let healthStore = HKHealthStore()
    private var container: ModelContainer?
    private var observers: [HKObserverQuery] = []
    private var runningSync: Task<Void, Never>?

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func configure(container: ModelContainer) {
        self.container = container
        reconfigureObservers()
        refresh()
    }

    func authorize(_ metric: HealthHabitMetric) async throws {
        guard isAvailable else { throw HealthHabitError.unavailable }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: [], read: [metric.sampleType]) { success, error in
                if let error { continuation.resume(throwing: error) }
                else if !success { continuation.resume(throwing: HealthHabitError.authorizationFailed) }
                else { continuation.resume() }
            }
        }
        // Apple doesn't disclose whether read access was denied. An empty
        // result is *not* proof that authorization was granted or refused.
    }

    func reconfigureObservers() {
        for observer in observers { healthStore.stop(observer) }
        observers.removeAll()
        let activeMetrics = HealthHabitRuleStore.shared.activeMetrics
        let deliveryKey = "chickmark.health.background.active.v1"
        if activeMetrics.isEmpty {
            // Avoid accessing HealthKit before the user opts in.
            if UserDefaults.standard.bool(forKey: deliveryKey) {
                healthStore.disableAllBackgroundDelivery { _, _ in }
                UserDefaults.standard.set(false, forKey: deliveryKey)
            }
            return
        }
        guard isAvailable else { return }
        UserDefaults.standard.set(true, forKey: deliveryKey)
        // Multiple rules can share the same HealthKit sample type (both
        // "running" and "all workouts" use HKWorkoutType). Observe once per
        // type; never disable a type still in use by another enabled rule.
        let requestedTypes = Dictionary(
            activeMetrics.map { ($0.sampleType.identifier, $0.sampleType) },
            uniquingKeysWith: { first, _ in first }
        )
        for candidate in HealthHabitMetric.allCases {
            let type = candidate.sampleType
            if requestedTypes[type.identifier] == nil {
                healthStore.disableBackgroundDelivery(for: type) { _, _ in }
            }
        }

        for type in requestedTypes.values {
            let observer = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, finish, _ in
                Task { @MainActor [weak self] in
                    await self?.synchronize()
                    finish()
                }
            }
            observers.append(observer)
            healthStore.execute(observer)
            healthStore.enableBackgroundDelivery(for: type, frequency: .hourly) { _, _ in }
        }
    }

    func refresh() {
        Task { await synchronize() }
    }

    func synchronize() async {
        if let runningSync {
            await runningSync.value
            return
        }
        let task = Task { await reconcile() }
        runningSync = task
        await task.value
        runningSync = nil
    }

    private func reconcile() async {
        guard isAvailable, let container else { return }
        let settings = HealthHabitRuleStore.shared
        guard !settings.allRules.isEmpty else { return }

        let context = ModelContext(container)
        guard let habits = try? context.fetch(FetchDescriptor<Habit>()),
              let initialCheckIns = try? context.fetch(FetchDescriptor<HabitCheckIn>()),
              let skips = try? context.fetch(FetchDescriptor<HabitSkip>()),
              let pauses = try? context.fetch(FetchDescriptor<HabitPausePeriod>()),
              let initialMutations = try? context.fetch(FetchDescriptor<HabitDayMutation>()) else { return }
        var checkIns = initialCheckIns
        var mutations = initialMutations

        let now = Date()
        let calendar = Calendar.autoupdatingCurrent
        let earliest = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))!
        var measurements: [String: Double] = [:]

        for (habitID, rule) in settings.allRules {
            guard let habit = habits.first(where: { $0.id == habitID }) else { continue }
            var day = max(earliest, calendar.startOfDay(for: rule.enabledAt))
            while day <= now {
                let key = HabitDayKey.make(for: day, calendar: calendar)
                if HealthHabitAutoPolicy.shouldComplete(
                    habit: habit, rule: rule, day: day, now: now,
                    checkIns: checkIns, skips: skips, pausePeriods: pauses,
                    mutations: mutations, calendar: calendar
                ), let end = calendar.date(byAdding: .day, value: 1, to: day) {
                    let cacheKey = "\(rule.metric.rawValue):\(key)"
                    let value: Double?
                    if let cached = measurements[cacheKey] {
                        value = cached
                    } else {
                        value = try? await read(metric: rule.metric, from: day, to: end)
                        if let value { measurements[cacheKey] = value }
                    }

                    if let value, value >= rule.target {
                        let mutationID = UUID()
                        let didChange = HabitCompletionMutation.setCompletion(
                            habitID: habitID, dayKey: key, completed: true,
                            context: context, mutationAt: .now,
                            mutationID: mutationID, calendar: calendar
                        )
                        if didChange {
                            do {
                                try context.save()
                                // Refresh the in-memory view so that flexible weekly
                                // goals stop after the requested number of days.
                                checkIns = (try? context.fetch(FetchDescriptor<HabitCheckIn>())) ?? checkIns
                                mutations = (try? context.fetch(FetchDescriptor<HabitDayMutation>())) ?? mutations
                                settings.record(
                                    HealthHabitEvidence(mutationID: mutationID,
                                                        metric: rule.metric, markedAt: .now),
                                    habitID: habitID, dayKey: key
                                )
                                HabitDataChangeNotifier.notify()
                            } catch {
                                context.rollback()
                                return
                            }
                        }
                    }
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
        }
    }

    private func read(metric: HealthHabitMetric, from start: Date, to end: Date) async throws -> Double {
        if metric == .sleepHours {
            let calendar = Calendar.autoupdatingCurrent
            // Attribute the night to the wake-up day; noon-to-noon avoids
            // splitting sleep at midnight or counting a nap in both days.
            let wakeDayNoon = calendar.date(bySettingHour: 12, minute: 0, second: 0,
                                            of: start) ?? start.addingTimeInterval(12 * 3600)
            guard let priorNoon = calendar.date(byAdding: .day, value: -1,
                                                 to: wakeDayNoon) else { return 0 }
            let cappedEnd = min(wakeDayNoon, Date())
            guard cappedEnd > priorNoon else { return 0 }
            return try await readSleep(from: priorNoon, to: cappedEnd) / 3600
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: start, end: end, options: [.strictStartDate, .strictEndDate]
        )
        if metric == .workoutMinutes || metric == .runningWorkout {
            return try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: HKObjectType.workoutType(),
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: nil
                ) { _, samples, error in
                    if let error { continuation.resume(throwing: error); return }
                    let workouts = (samples ?? []).compactMap { $0 as? HKWorkout }
                    let minutes = metric == .runningWorkout
                        ? workouts.filter { $0.workoutActivityType == .running }
                            .map { $0.duration / 60 }.max() ?? 0
                        : workouts.reduce(0.0) { $0 + $1.duration / 60 }
                    continuation.resume(returning: minutes)
                }
                healthStore.execute(query)
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: metric.sampleType as! HKQuantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error { continuation.resume(throwing: error); return }
                let raw = result?.sumQuantity()?.doubleValue(for: metric.quantityUnit) ?? 0
                continuation.resume(returning: metric.normalized(raw))
            }
            healthStore.execute(query)
        }
    }

    private func readSleep(from start: Date, to end: Date) async throws -> TimeInterval {
        // Overlapping samples are intentionally allowed, then merged to avoid
        // double counting iPhone/Watch/third-party stage records.
        let predicate = HKQuery.predicateForSamples(
            withStart: start, end: end, options: []
        )
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                let intervals = (samples ?? []).compactMap { sample -> HealthSleepInterval? in
                    guard let stage = sample as? HKCategorySample,
                          let state = HKCategoryValueSleepAnalysis(rawValue: stage.value),
                          HKCategoryValueSleepAnalysis.allAsleepValues.contains(state) else {
                        return nil
                    }
                    return HealthSleepInterval(start: stage.startDate, end: stage.endDate)
                }
                continuation.resume(returning: HealthSleepIntervals.totalDuration(
                    intervals, from: start, to: end
                ))
            }
            healthStore.execute(query)
        }
    }
}

/// Pure interval union. HealthKit may contain duplicate overlapping sleep
/// readings from more than one tracker.
struct HealthSleepInterval {
    let start: Date
    let end: Date
}

enum HealthSleepIntervals {
    static func totalDuration(
        _ intervals: [HealthSleepInterval], from start: Date, to end: Date
    ) -> TimeInterval {
        guard end > start else { return 0 }
        let clipped = intervals.compactMap { item -> HealthSleepInterval? in
            let lower = max(item.start, start)
            let upper = min(item.end, end)
            return upper > lower ? HealthSleepInterval(start: lower, end: upper) : nil
        }.sorted { $0.start < $1.start }
        var accumulated: TimeInterval = 0
        var mergedEnd = start
        for item in clipped {
            let lower = max(item.start, mergedEnd)
            if item.end > lower { accumulated += item.end.timeIntervalSince(lower) }
            mergedEnd = max(mergedEnd, item.end)
        }
        return accumulated
    }
}
