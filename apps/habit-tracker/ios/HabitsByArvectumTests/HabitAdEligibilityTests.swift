import XCTest
@testable import HabitsByArvectum

final class HabitAdEligibilityTests: XCTestCase {
    func testEligibilityRequiresAllThreeThresholds() {
        let firstLaunch = Date(timeIntervalSince1970: 1_000_000)
        let eligibleAt = firstLaunch.addingTimeInterval(
            HabitAdEligibility.minimumAge
        )

        XCTAssertTrue(
            HabitAdEligibility.isEligible(
                snapshot: HabitAdEngagementSnapshot(
                    firstLaunchAt: firstLaunch,
                    coldLaunchCount: 5,
                    successfulCheckOffCount: 3
                ),
                now: eligibleAt
            )
        )

        XCTAssertFalse(
            HabitAdEligibility.isEligible(
                snapshot: HabitAdEngagementSnapshot(
                    firstLaunchAt: firstLaunch,
                    coldLaunchCount: 4,
                    successfulCheckOffCount: 3
                ),
                now: eligibleAt
            )
        )
        XCTAssertFalse(
            HabitAdEligibility.isEligible(
                snapshot: HabitAdEngagementSnapshot(
                    firstLaunchAt: firstLaunch,
                    coldLaunchCount: 5,
                    successfulCheckOffCount: 2
                ),
                now: eligibleAt
            )
        )
        XCTAssertFalse(
            HabitAdEligibility.isEligible(
                snapshot: HabitAdEngagementSnapshot(
                    firstLaunchAt: firstLaunch,
                    coldLaunchCount: 5,
                    successfulCheckOffCount: 3
                ),
                now: eligibleAt.addingTimeInterval(-1)
            )
        )
    }

    func testStorePersistsLaunchAndCheckOffCounts() throws {
        let suite = "HabitAdEligibilityTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = HabitAdEligibilityStore(defaults: defaults)
        let firstLaunch = Date(timeIntervalSince1970: 2_000_000)

        store.registerForegroundLaunchOnce(now: firstLaunch)
        store.registerForegroundLaunchOnce(
            now: firstLaunch.addingTimeInterval(60)
        )
        store.registerSuccessfulCheckOff()
        store.registerSuccessfulCheckOff()

        var snapshot = store.snapshot()
        XCTAssertEqual(snapshot.firstLaunchAt, firstLaunch)
        XCTAssertEqual(snapshot.coldLaunchCount, 1)
        XCTAssertEqual(snapshot.successfulCheckOffCount, 2)

        let nextProcess = HabitAdEligibilityStore(defaults: defaults)
        nextProcess.registerForegroundLaunchOnce(
            now: firstLaunch.addingTimeInterval(120)
        )
        snapshot = nextProcess.snapshot()
        XCTAssertEqual(snapshot.firstLaunchAt, firstLaunch)
        XCTAssertEqual(snapshot.coldLaunchCount, 2)
    }
}
