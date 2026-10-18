import XCTest
@testable import HabitsByArvectum

final class WaterExportPlanningTests: XCTestCase {
    private let habitID = UUID(uuidString: "00000000-0000-0000-0000-000000000071")!
    private let day = "2026-10-18"
    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
    private var optIn: WaterExportRule {
        WaterExportRule(
            millilitresPerUnit: 250,
            enabledAt: utc.date(from: DateComponents(year: 2026, month: 10, day: 18))!
        )
    }
    private func evaluate(
        _ count: Int, rule: WaterExportRule?, receipt: WaterExportReceipt? = nil,
        goal: HabitGoalMode = .quantity(count: 10), dayKey: String = "2026-10-18"
    ) -> WaterExportAction {
        WaterExportPlanning.action(
            habitID: habitID, dayKey: dayKey, goal: goal, currentCount: count,
            rule: rule, receipt: receipt, calendar: utc
        )
    }
    func testDisabledByDefaultRegardlessOfHabitNameOrQuantity() {
        XCTAssertEqual(evaluate(3, rule: nil), .none)
    }
    func testExplicitVolumeConversionUsesUserSuppliedSize() {
        XCTAssertEqual(evaluate(3, rule: optIn), .upsert(
            identifier: WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: day),
            millilitres: 750, syncVersion: 1))
    }
    func testIdenticalCountAndVolumeAreIdempotent() {
        let identifier = WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: day)
        XCTAssertEqual(evaluate(3, rule: optIn,
            receipt: .init(syncIdentifier: identifier, quantity: 3,
                           millilitres: 750, syncVersion: 5)), .none)
    }
    func testCorrectionsAdvanceVersionWithoutDuplicatingDay() {
        let identifier = WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: day)
        XCTAssertEqual(evaluate(2, rule: optIn,
            receipt: .init(syncIdentifier: identifier, quantity: 3,
                           millilitres: 750, syncVersion: 5)),
            .upsert(identifier: identifier, millilitres: 500, syncVersion: 6))
    }
    func testUndoRequestsRemovalOnlyOfOwnRecordedSample() {
        let identifier = WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: day)
        XCTAssertEqual(evaluate(0, rule: optIn,
            receipt: .init(syncIdentifier: identifier, quantity: 1,
                           millilitres: 250, syncVersion: 1)),
            .delete(identifier: identifier))
        XCTAssertEqual(evaluate(0, rule: optIn), .none)
    }
    func testDisablingRuleRemovesPreviouslyOwnedSampleOnly() {
        let identifier = WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: day)
        let receipt = WaterExportReceipt(syncIdentifier: identifier, quantity: 2,
                                         millilitres: 500, syncVersion: 1)
        XCTAssertEqual(evaluate(2, rule: nil, receipt: receipt), .delete(identifier: identifier))
        XCTAssertEqual(evaluate(2, rule: nil), .none)
    }
    func testNoSyncForNonQuantitativeHabit() {
        XCTAssertEqual(evaluate(1, rule: optIn, goal: .scheduled), .none)
        XCTAssertEqual(evaluate(1, rule: optIn, goal: .duration(minutes: 30)), .none)
    }
    func testOptInNeverBackfillsPreviousDays() {
        XCTAssertEqual(evaluate(5, rule: optIn, dayKey: "2026-10-17"), .none)
        XCTAssertEqual(evaluate(5, rule: optIn, dayKey: "2026-10-18"), .upsert(
            identifier: WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: day),
            millilitres: 1250, syncVersion: 1))
    }
    func testInvalidAndNonexistentDayIsIgnored() {
        XCTAssertEqual(evaluate(4, rule: optIn, dayKey: "2026-02-30"), .none)
    }
    func testInvalidVolumeRejected() {
        XCTAssertFalse(WaterExportRule(millilitresPerUnit: 0, enabledAt: .now).isValid)
        XCTAssertFalse(WaterExportRule(millilitresPerUnit: 1001, enabledAt: .now).isValid)
        XCTAssertTrue(WaterExportRule(millilitresPerUnit: 300, enabledAt: .now).isValid)
    }
    func testCountClampsToHabitTarget() {
        XCTAssertEqual(evaluate(100, rule: optIn, goal: .quantity(count: 8)), .upsert(
            identifier: WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: day),
            millilitres: 2000, syncVersion: 1))
    }
    func testLocalStoreIsolatedByUserDefaultsSuite() {
        let suite = "chickmark-water-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WaterExportLocalStore(defaults: defaults)
        XCTAssertNil(store.rule(for: habitID))
        store.setRule(optIn, for: habitID)
        XCTAssertEqual(store.rule(for: habitID), optIn)
        let identifier = WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: day)
        let receipt = WaterExportReceipt(syncIdentifier: identifier,
                                         quantity: 3, millilitres: 750, syncVersion: 1)
        store.setReceipt(receipt, habitID: habitID, dayKey: day)
        XCTAssertEqual(store.receipt(habitID: habitID, dayKey: day), receipt)
        store.setRule(nil, for: habitID)
        XCTAssertNil(store.rule(for: habitID))
        // Keep receipt after opt-out until confirmed removal from Apple Health.
        XCTAssertEqual(store.receipt(habitID: habitID, dayKey: day), receipt)
        store.setReceipt(nil, habitID: habitID, dayKey: day)
        XCTAssertNil(store.receipt(habitID: habitID, dayKey: day))
    }
    func testOwnedReceiptsAndPendingIntentsAreDiscoverableForDeletedHabits() {
        let suite = "water-orphan-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WaterExportLocalStore(defaults: defaults)
        store.setRule(optIn, for: habitID)
        let own = WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: day)
        store.setReceipt(.init(syncIdentifier: own,
                               quantity: 2, millilitres: 500, syncVersion: 1),
                         habitID: habitID, dayKey: day)
        let pendingDay = "2026-10-19"
        store.setPendingVersion(2, habitID: habitID, dayKey: pendingDay)

        XCTAssertTrue(store.allKnownHabitIDs.contains(habitID))
        XCTAssertEqual(store.receipts(for: habitID).map(\.dayKey), [day])
        XCTAssertEqual(store.pendingDays(for: habitID), [pendingDay])

        // Dropping local opt-in is NOT sufficient to forget HealthKit cleanup.
        store.setRule(nil, for: habitID)
        XCTAssertTrue(store.allKnownHabitIDs.contains(habitID))
        XCTAssertNotNil(store.receipt(habitID: habitID, dayKey: day))
        store.setReceipt(nil, habitID: habitID, dayKey: day)
        XCTAssertTrue(store.allKnownHabitIDs.contains(habitID))
        store.setPendingVersion(nil, habitID: habitID, dayKey: pendingDay)
        XCTAssertFalse(store.allKnownHabitIDs.contains(habitID))
    }
    func testManualEnableOrDisableCannotOverwriteDamagedWaterLedgers() {
        let suite = "water-rule-atomic-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WaterExportLocalStore(defaults: defaults)
        let broken = Data("not-json".utf8)
        defaults.set(broken, forKey: "chickmark.water.rules.v1")
        XCTAssertFalse(store.setRule(optIn, for: habitID))
        XCTAssertFalse(store.setRule(nil, for: habitID))
        XCTAssertEqual(defaults.data(forKey: "chickmark.water.rules.v1"), broken)
        defaults.removeObject(forKey: "chickmark.water.rules.v1")
        XCTAssertTrue(store.setRule(optIn, for: habitID))
        XCTAssertEqual(store.rule(for: habitID), optIn)
        defaults.set(broken, forKey: "chickmark.water.receipts.v1")
        XCTAssertFalse(store.setRule(nil, for: habitID))
        XCTAssertEqual(store.rule(for: habitID), optIn)
    }

    func testCorruptConsentLedgerNeverBecomesEmptyOrTriggersHealthCleanup() {
        let suite = "water-corrupted-consent-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WaterExportLocalStore(defaults: defaults)
        XCTAssertTrue(store.canSafelyReconcile)
        let identifier = WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: day)
        store.setReceipt(.init(syncIdentifier: identifier,
                               quantity: 2, millilitres: 500, syncVersion: 1),
                         habitID: habitID, dayKey: day)
        defaults.set(Data("broken json".utf8), forKey: "chickmark.water.rules.v1")
        XCTAssertFalse(store.canSafelyReconcile)
        XCTAssertNotNil(store.receipt(habitID: habitID, dayKey: day))
        // Nothing in the app is allowed to infer opt-out from this damage.
        defaults.removeObject(forKey: "chickmark.water.rules.v1")
        XCTAssertTrue(store.canSafelyReconcile)
    }

    func testCorruptReceiptAndPendingLedgersFailClosedIndependently() {
        let suite = "water-corrupted-receipt-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WaterExportLocalStore(defaults: defaults)
        store.setRule(optIn, for: habitID)
        for key in ["chickmark.water.receipts.v1",
                    "chickmark.water.pendingWriteVersions.v1"] {
            defaults.set(Data("not-json".utf8), forKey: key)
            XCTAssertFalse(store.canSafelyReconcile, "Must block on \(key)")
            defaults.removeObject(forKey: key)
            XCTAssertTrue(store.canSafelyReconcile)
        }
    }
}
