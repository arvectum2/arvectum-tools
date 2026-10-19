import XCTest
@testable import HabitsByArvectum

@MainActor
private final class FakeWaterHealthDriver: WaterHealthWriting {
    var authorized = true
    var fail = false
    var failAfterWrite = false
    var upserts: [(id: String, ml: Int, version: Int)] = []
    var removals: [String] = []

    func requestWriteAccess() async throws {
        if !authorized { throw WaterExportError.notAuthorized }
    }
    func isWriteAuthorized() -> Bool { authorized }
    func upsert(identifier: String, millilitres: Int,
                version: Int, dayKey: String) async throws {
        if fail { throw WaterExportError.failed }
        upserts.append((identifier, millilitres, version))
        if failAfterWrite { throw WaterExportError.failed }
    }
    func removeOwn(identifier: String) async throws {
        if fail { throw WaterExportError.failed }
        removals.append(identifier)
    }
}

@MainActor
final class WaterExportSnapshotTests: XCTestCase {
    private struct SimulatedReadError: Error {}

    func testValidEmptyDatabaseIsNotConflatedWithQueryFailure() {
        let snapshot = WaterExportSnapshot.load(
            readHabits: { [] },
            readCheckIns: { [] }
        )
        XCTAssertNotNil(snapshot)
        XCTAssertEqual(snapshot?.habits.count, 0)
        XCTAssertEqual(snapshot?.checkIns.count, 0)
    }

    func testHabitFetchFailureSkipsAllHealthReconciliation() {
        var checksQueried = false
        let snapshot = WaterExportSnapshot.load(
            readHabits: { throw SimulatedReadError() },
            readCheckIns: {
                checksQueried = true
                return []
            }
        )
        XCTAssertNil(snapshot, "A failed habit read must NEVER become an empty list")
        XCTAssertFalse(checksQueried, "Do not run further queries on failed snapshot")
    }

    func testCheckInFetchFailureCannotEraseExistingWaterSamples() {
        let habit = Habit(name: "Water QA")
        let snapshot = WaterExportSnapshot.load(
            readHabits: { [habit] },
            readCheckIns: { throw SimulatedReadError() }
        )
        XCTAssertNil(snapshot, "A failed check-in read must NEVER become count 0")
    }

    func testSuccessfulSnapshotContainsBothDataSets() {
        let habit = Habit(name: "Water QA")
        let snapshot = WaterExportSnapshot.load(
            readHabits: { [habit] },
            readCheckIns: { [] }
        )
        XCTAssertEqual(snapshot?.habits.map(\.id), [habit.id])
        XCTAssertEqual(snapshot?.checkIns.count, 0)
    }
}

@MainActor
final class WaterExportSyncTests: XCTestCase {
    private let habit = UUID(uuidString: "00000000-0000-0000-0000-0000000000A7")!
    private func setup() -> (WaterExportLocalStore, FakeWaterHealthDriver, String, String) {
        let suite = "water-sync-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let store = WaterExportLocalStore(defaults: defaults)
        let start = Calendar.current.startOfDay(for: .now)
        store.setRule(WaterExportRule(millilitresPerUnit: 250, enabledAt: start), for: habit)
        return (store, FakeWaterHealthDriver(), HabitDayKey.make(for: .now), suite)
    }
    func testDamagedConsentDoesNotInvokeHealthKitFakeWriter() async {
        let (store, driver, day, suite) = setup()
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("not-valid-json".utf8), forKey: "chickmark.water.rules.v1")
        let engine = WaterExportSyncEngine(driver: driver, store: store)
        do {
            _ = try await engine.reconcile(habitID: habit, dayKey: day,
                goal: .quantity(count: 10), count: 2)
            XCTFail("Corrupt consent must suspend export")
        } catch {}
        XCTAssertTrue(driver.upserts.isEmpty)
        XCTAssertTrue(driver.removals.isEmpty)
    }

    func testUpsertThenDuplicateIsNoopAndIncrementIsVersioned() async throws {
        let (store, driver, day, suite) = setup()
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let engine = WaterExportSyncEngine(driver: driver, store: store)
        let syncResult0 = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 3)
        XCTAssertTrue(syncResult0)
        XCTAssertEqual(driver.upserts.map(\.ml), [750])
        XCTAssertEqual(store.receipt(habitID: habit, dayKey: day)?.syncVersion, 1)
        let syncResult1 = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 3)
        XCTAssertFalse(syncResult1)
        XCTAssertEqual(driver.upserts.count, 1)
        let syncResult2 = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 4)
        XCTAssertTrue(syncResult2)
        XCTAssertEqual(driver.upserts.map(\.ml), [750, 1000])
        XCTAssertEqual(driver.upserts.map(\.version), [1, 2])
        XCTAssertEqual(store.receipt(habitID: habit, dayKey: day)?.millilitres, 1000)
    }
    func testDeniedPermissionCannotWriteOrCommitReceipt() async throws {
        let (store, driver, day, suite) = setup()
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        driver.authorized = false
        let engine = WaterExportSyncEngine(driver: driver, store: store)
        do {
            _ = try await engine.reconcile(habitID: habit, dayKey: day,
                goal: .quantity(count: 10), count: 2)
            XCTFail("Expected write permission denial")
        } catch {}
        XCTAssertTrue(driver.upserts.isEmpty)
        XCTAssertNil(store.receipt(habitID: habit, dayKey: day))
    }
    func testFailureRetainsPriorReceiptForRetry() async throws {
        let (store, driver, day, suite) = setup()
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let engine = WaterExportSyncEngine(driver: driver, store: store)
        let syncResult3 = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 2)
        XCTAssertTrue(syncResult3)
        driver.fail = true
        do {
            _ = try await engine.reconcile(habitID: habit, dayKey: day,
                goal: .quantity(count: 10), count: 5)
            XCTFail("Expected injected failure")
        } catch {}
        XCTAssertEqual(store.receipt(habitID: habit, dayKey: day)?.millilitres, 500)
        driver.fail = false
        let syncResult4 = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 5)
        XCTAssertTrue(syncResult4)
        XCTAssertEqual(driver.upserts.map(\.version), [1, 3])
        XCTAssertEqual(store.receipt(habitID: habit, dayKey: day)?.millilitres, 1250)
    }
    func testUndoAndOptOutRemoveOnlyRecordedIdentifier() async throws {
        let (store, driver, day, suite) = setup()
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let engine = WaterExportSyncEngine(driver: driver, store: store)
        let syncResult5 = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 1)
        XCTAssertTrue(syncResult5)
        let syncResult6 = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 0)
        XCTAssertTrue(syncResult6)
        XCTAssertEqual(driver.removals, [
            WaterExportPlanning.syncIdentifier(habitID: habit, dayKey: day)
        ])
        XCTAssertNil(store.receipt(habitID: habit, dayKey: day))
        let syncResult7 = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 0)
        XCTAssertFalse(syncResult7)
        // Existing entry removed on explicit rule disable.
        let syncResult8 = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 2)
        XCTAssertTrue(syncResult8)
        store.setRule(nil, for: habit)
        let syncResult9 = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 2)
        XCTAssertTrue(syncResult9)
        XCTAssertEqual(driver.removals.count, 2)
    }
    func testSameDayUndoAndSecondWaterEntryKeepVersionIncreasing() async throws {
        let (store, driver, day, suite) = setup()
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let engine = WaterExportSyncEngine(driver: driver, store: store)
        let first = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 2)
        XCTAssertTrue(first)
        XCTAssertEqual(store.highestVersion(habitID: habit, dayKey: day), 1)
        let deleted = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 0)
        XCTAssertTrue(deleted)
        XCTAssertNil(store.receipt(habitID: habit, dayKey: day))
        XCTAssertEqual(store.highestVersion(habitID: habit, dayKey: day), 1)
        let again = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 4)
        XCTAssertTrue(again)
        XCTAssertEqual(driver.upserts.map(\.version), [1, 2],
            "Recreated daily sample must never reuse sync version 1.")
        XCTAssertEqual(driver.removals.count, 1)
        XCTAssertEqual(store.receipt(habitID: habit, dayKey: day)?.syncVersion, 2)
    }

    func testCrashAfterAppleWriteRetriesWithHigherSyncVersion() async throws {
        let (store, driver, day, suite) = setup()
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let engine = WaterExportSyncEngine(driver: driver, store: store)
        driver.failAfterWrite = true
        do {
            _ = try await engine.reconcile(habitID: habit, dayKey: day,
                goal: .quantity(count: 10), count: 2)
            XCTFail("Expected simulated crash after HealthKit write")
        } catch {}
        XCTAssertEqual(driver.upserts.map(\.version), [1])
        XCTAssertNil(store.receipt(habitID: habit, dayKey: day))
        XCTAssertEqual(store.pendingVersion(habitID: habit, dayKey: day), 1)
        driver.failAfterWrite = false
        let recovered = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 2)
        XCTAssertTrue(recovered)
        XCTAssertEqual(driver.upserts.map(\.version), [1, 2])
        XCTAssertEqual(store.receipt(habitID: habit, dayKey: day)?.syncVersion, 2)
        XCTAssertNil(store.pendingVersion(habitID: habit, dayKey: day))
    }
    func testUndoAfterInterruptedFirstWriteRemovesOnlyPendingOwnSample() async throws {
        let (store, driver, day, suite) = setup()
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let engine = WaterExportSyncEngine(driver: driver, store: store)
        driver.failAfterWrite = true
        do {
            _ = try await engine.reconcile(habitID: habit, dayKey: day,
                goal: .quantity(count: 10), count: 1)
        } catch {}
        driver.failAfterWrite = false
        let removed = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 0)
        XCTAssertTrue(removed)
        XCTAssertEqual(driver.removals, [
            WaterExportPlanning.syncIdentifier(habitID: habit, dayKey: day)
        ])
        XCTAssertNil(store.receipt(habitID: habit, dayKey: day))
        XCTAssertNil(store.pendingVersion(habitID: habit, dayKey: day))
    }
    func testFailedUpdateThenRevertCompensatesWithoutDeletingOriginal() async throws {
        let (store, driver, day, suite) = setup()
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let engine = WaterExportSyncEngine(driver: driver, store: store)
        let initial = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 2)
        XCTAssertTrue(initial)
        driver.failAfterWrite = true
        do {
            _ = try await engine.reconcile(habitID: habit, dayKey: day,
                goal: .quantity(count: 10), count: 3)
        } catch {}
        driver.failAfterWrite = false
        let restored = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 2)
        XCTAssertTrue(restored)
        XCTAssertEqual(driver.upserts.map(\.version), [1, 2, 3])
        XCTAssertEqual(driver.upserts.map(\.ml), [500, 750, 500])
        XCTAssertTrue(driver.removals.isEmpty)
        XCTAssertEqual(store.receipt(habitID: habit, dayKey: day)?.millilitres, 500)
    }
    // Real-world quantity UI edits ultimately drive this same daily count
    // reconciler. All records here are isolated and use the fake Health driver.
    func testWaterCheckinsEditUndoAndReentryKeepOneOwnedDailySample() async throws {
        let (store, driver, day, suite) = setup()
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let engine = WaterExportSyncEngine(driver: driver, store: store)
        let goal: HabitGoalMode = .quantity(count: 10)

        for count in [1, 2, 3, 2, 0, 4] {
            let change1 = try await engine.reconcile(
                habitID: habit, dayKey: day, goal: goal, count: count
            )
            XCTAssertTrue(change1, "Each real change must be reconciled")
        }

        let ownID = WaterExportPlanning.syncIdentifier(habitID: habit, dayKey: day)
        XCTAssertEqual(Set(driver.upserts.map(\.id)), [ownID],
            "Every edit must address the same daily sample, not add a new one")
        XCTAssertEqual(driver.upserts.map(\.ml), [250, 500, 750, 500, 1000])
        XCTAssertEqual(driver.upserts.map(\.version), [1, 2, 3, 4, 5])
        XCTAssertEqual(driver.removals, [ownID], "Undo to zero removes only own sample")
        XCTAssertEqual(store.receipt(habitID: habit, dayKey: day)?.millilitres, 1000)
        XCTAssertEqual(store.highestVersion(habitID: habit, dayKey: day), 5)
        let change2 = try await engine.reconcile(
            habitID: habit, dayKey: day, goal: goal, count: 4
        )
        XCTAssertFalse(change2, "Second request for the same count must not write again")
    }

    func testRevokedWritePermissionPreservesReceiptUntilRegrant() async throws {
        let (store, driver, day, suite) = setup()
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let engine = WaterExportSyncEngine(driver: driver, store: store)
        let goal: HabitGoalMode = .quantity(count: 10)
        let change3 = try await engine.reconcile(
            habitID: habit, dayKey: day, goal: goal, count: 2
        )
        XCTAssertTrue(change3)
        driver.authorized = false
        do {
            _ = try await engine.reconcile(habitID: habit, dayKey: day,
                                           goal: goal, count: 3)
            XCTFail("Revoked authorization must reject a new HealthKit write")
        } catch WaterExportError.notAuthorized {
            // Expected: the habit itself still exists; HealthKit is unchanged.
        }
        XCTAssertEqual(driver.upserts.map(\.ml), [500])
        XCTAssertTrue(driver.removals.isEmpty)
        XCTAssertEqual(store.receipt(habitID: habit, dayKey: day)?.millilitres, 500)

        driver.authorized = true
        let change4 = try await engine.reconcile(
            habitID: habit, dayKey: day, goal: goal, count: 3
        )
        XCTAssertTrue(change4)
        XCTAssertEqual(driver.upserts.map(\.ml), [500, 750])
        XCTAssertEqual(driver.upserts.map(\.version), [1, 2])
        XCTAssertEqual(store.receipt(habitID: habit, dayKey: day)?.millilitres, 750)
        XCTAssertNil(store.pendingVersion(habitID: habit, dayKey: day))
    }

    func testTwoDaysExportIndependentlyAndUndoOnlyTargetDay() async throws {
        let (store, driver, today, suite) = setup()
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let tomorrowDate = try XCTUnwrap(Calendar.current.date(
            byAdding: .day, value: 1, to: .now
        ))
        let tomorrow = HabitDayKey.make(for: tomorrowDate)
        XCTAssertNotEqual(today, tomorrow)
        let engine = WaterExportSyncEngine(driver: driver, store: store)
        let goal: HabitGoalMode = .quantity(count: 10)

        let change5 = try await engine.reconcile(
            habitID: habit, dayKey: today, goal: goal, count: 1
        )

        XCTAssertTrue(change5)
        let change6 = try await engine.reconcile(
            habitID: habit, dayKey: tomorrow, goal: goal, count: 2
        )
        XCTAssertTrue(change6)
        XCTAssertEqual(Set(driver.upserts.map(\.id)).count, 2,
                       "Days must have independent HealthKit sync identifiers")
        XCTAssertEqual(driver.upserts.map(\.ml), [250, 500])
        XCTAssertEqual(driver.upserts.map(\.version), [1, 1])

        let change7 = try await engine.reconcile(
            habitID: habit, dayKey: today, goal: goal, count: 0
        )

        XCTAssertTrue(change7)
        XCTAssertEqual(driver.removals, [
            WaterExportPlanning.syncIdentifier(habitID: habit, dayKey: today)
        ])
        XCTAssertNil(store.receipt(habitID: habit, dayKey: today))
        XCTAssertEqual(store.receipt(habitID: habit, dayKey: tomorrow)?.millilitres, 500)
    }

    func testDeleteFailureRetainsReceiptForLaterRetry() async throws {
        let (store, driver, day, suite) = setup()
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        let engine = WaterExportSyncEngine(driver: driver, store: store)
        let syncResult10 = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 3)
        XCTAssertTrue(syncResult10)
        driver.fail = true
        do {
            _ = try await engine.reconcile(habitID: habit, dayKey: day,
                goal: .quantity(count: 10), count: 0)
            XCTFail("Expected injected delete failure")
        } catch {}
        XCTAssertNotNil(store.receipt(habitID: habit, dayKey: day))
        driver.fail = false
        let syncResult11 = try await engine.reconcile(habitID: habit, dayKey: day,
            goal: .quantity(count: 10), count: 0)
        XCTAssertTrue(syncResult11)
        XCTAssertNil(store.receipt(habitID: habit, dayKey: day))
    }
}
