import Foundation
import HealthKit

/// WidgetKit fetches this timeline in its own extension process. Read only the
/// today's on-Watch step sum for opted-in step habits. We never prompt for
/// authorization from a complication; the host Watch app requests it.
/// This also works when the host app hasn't been foregrounded since steps
/// changed, unlike the previous app-group cache-only provider.
enum WatchComplicationHealthReader {
    static func project(
        _ cached: HabitSyncSnapshot, on now: Date,
        completion: @escaping (HabitSyncSnapshot) -> Void
    ) {
        guard HKHealthStore.isHealthDataAvailable(),
              cached.habits.contains(where: {
                  $0.healthRuleMetric == "steps" &&
                  $0.healthRuleTarget != nil &&
                  !$0.completed && !$0.skipped
              })
        else {
            completion(cached)
            return
        }

        // The widget has a constrained execution window. If HealthKit isn't
        // available promptly, return the existing safe derived snapshot.
        let once = OneShot(completion: completion)
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 4) {
            once.finish(cached)
        }

        let calendar = Calendar.autoupdatingCurrent
        let start = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start)
        else {
            once.finish(cached)
            return
        }

        let store = HKHealthStore()
        let predicate = HKQuery.predicateForSamples(
            withStart: start, end: end,
            options: [.strictStartDate, .strictEndDate]
        )
        let query = HKStatisticsQuery(
            quantityType: HKQuantityType(.stepCount),
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, stats, error in
            guard error == nil,
                  let quantity = stats?.sumQuantity() else {
                once.finish(cached)
                return
            }
            let steps = quantity.doubleValue(for: .count())
            once.finish(
                WatchLocalHealthProjection.applyingLiveSteps(
                    cached, steps: steps, now: now
                )
            )
        }
        store.execute(query)
    }

    private final class OneShot {
        private let lock = NSLock()
        private var done = false
        private let callback: (HabitSyncSnapshot) -> Void

        init(completion: @escaping (HabitSyncSnapshot) -> Void) {
            callback = completion
        }

        func finish(_ snapshot: HabitSyncSnapshot) {
            lock.lock()
            let shouldRun = !done
            done = true
            lock.unlock()
            if shouldRun { callback(snapshot) }
        }
    }
}
