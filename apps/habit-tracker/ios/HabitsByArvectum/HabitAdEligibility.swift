import Foundation

struct HabitAdEngagementSnapshot: Equatable {
    let firstLaunchAt: Date?
    let coldLaunchCount: Int
    let successfulCheckOffCount: Int
}

enum HabitAdEligibility {
    static let minimumAge: TimeInterval = 3 * 24 * 60 * 60
    static let minimumColdLaunches = 5
    static let minimumSuccessfulCheckOffs = 3

    static func isEligible(
        snapshot: HabitAdEngagementSnapshot,
        now: Date = .now
    ) -> Bool {
        guard let firstLaunchAt = snapshot.firstLaunchAt else {
            return false
        }

        return now.timeIntervalSince(firstLaunchAt) >= minimumAge &&
            snapshot.coldLaunchCount >= minimumColdLaunches &&
            snapshot.successfulCheckOffCount >= minimumSuccessfulCheckOffs
    }
}

final class HabitAdEligibilityStore {
    static let shared = HabitAdEligibilityStore()

    private enum Key {
        static let firstLaunchAt = "habits.ads.firstLaunchAt"
        static let coldLaunchCount = "habits.ads.coldLaunchCount"
        static let successfulCheckOffCount = "habits.ads.successfulCheckOffCount"
    }

    private let defaults: UserDefaults
    private var registeredForegroundLaunchThisProcess = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func registerForegroundLaunchOnce(now: Date = .now) {
        guard !registeredForegroundLaunchThisProcess else { return }
        registeredForegroundLaunchThisProcess = true
        registerColdLaunch(now: now)
    }

    private func registerColdLaunch(now: Date = .now) {
        if defaults.object(forKey: Key.firstLaunchAt) == nil {
            defaults.set(now, forKey: Key.firstLaunchAt)
        }
        defaults.set(
            defaults.integer(forKey: Key.coldLaunchCount) + 1,
            forKey: Key.coldLaunchCount
        )
    }

    func registerSuccessfulCheckOff() {
        defaults.set(
            defaults.integer(forKey: Key.successfulCheckOffCount) + 1,
            forKey: Key.successfulCheckOffCount
        )
    }

    func snapshot() -> HabitAdEngagementSnapshot {
        HabitAdEngagementSnapshot(
            firstLaunchAt: defaults.object(forKey: Key.firstLaunchAt) as? Date,
            coldLaunchCount: defaults.integer(forKey: Key.coldLaunchCount),
            successfulCheckOffCount: defaults.integer(
                forKey: Key.successfulCheckOffCount
            )
        )
    }

    func isEligible(now: Date = .now) -> Bool {
        HabitAdEligibility.isEligible(snapshot: snapshot(), now: now)
    }
}
