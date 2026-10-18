import Foundation
import HealthKit
import SwiftData

enum WaterExportError: LocalizedError {
    case unavailable, notAuthorized, invalidDay, failed
    var errorDescription: String? {
        switch self {
        case .unavailable: "Apple Health is not available on this device."
        case .notAuthorized: "Allow ChickMark to add water in Apple Health settings."
        case .invalidDay: "Invalid date for water tracking."
        case .failed: "Apple Health could not save the water entry."
        }
    }
}

/// Mockable boundary: tests never touch HKHealthStore. The production driver is
/// only invoked after this habit was opted in AND sharing authorization exists.
@MainActor
protocol WaterHealthWriting {
    func requestWriteAccess() async throws
    func isWriteAuthorized() -> Bool
    func upsert(identifier: String, millilitres: Int, version: Int, dayKey: String) async throws
    func removeOwn(identifier: String) async throws
}

@MainActor
final class WaterHealthKitWriter: WaterHealthWriting {
    private let healthStore = HKHealthStore()
    private let water = HKObjectType.quantityType(forIdentifier: .dietaryWater)!

    func requestWriteAccess() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { throw WaterExportError.unavailable }
        try await healthStore.requestAuthorization(toShare: [water], read: [])
        guard isWriteAuthorized() else { throw WaterExportError.notAuthorized }
    }

    func isWriteAuthorized() -> Bool {
        HKHealthStore.isHealthDataAvailable() &&
            healthStore.authorizationStatus(for: water) == .sharingAuthorized
    }

    func upsert(identifier: String, millilitres: Int, version: Int, dayKey: String) async throws {
        guard isWriteAuthorized() else { throw WaterExportError.notAuthorized }
        guard millilitres > 0, version > 0,
              let timestamp = HabitMultiCheck.date(from: dayKey, calendar: .autoupdatingCurrent)
        else { throw WaterExportError.invalidDay }

        let sample = HKQuantitySample(
            type: water,
            quantity: HKQuantity(unit: HKUnit.literUnit(with: .milli),
                                 doubleValue: Double(millilitres)),
            start: timestamp,
            end: timestamp.addingTimeInterval(1),
            metadata: [
                HKMetadataKeySyncIdentifier: identifier,
                HKMetadataKeySyncVersion: version
            ]
        )
        // HealthKit replaces the SAME sync identifier with a higher version,
        // so retries and edited check-ins cannot inflate the daily water total.
        try await healthStore.save(sample)
    }

    func removeOwn(identifier: String) async throws {
        guard isWriteAuthorized() else { throw WaterExportError.notAuthorized }
        let metadata = HKQuery.predicateForObjects(
            withMetadataKey: HKMetadataKeySyncIdentifier,
            allowedValues: [identifier]
        )
        let source = HKQuery.predicateForObjects(from: HKSource.default())
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            metadata, source
        ])
        // Apple Health itself additionally restricts deletion to samples
        // previously saved by this application, never another source.
        _ = try await healthStore.deleteObjects(of: water, predicate: predicate)
    }
}

/// Committing a receipt only AFTER a successful HK operation makes denial,
/// retry, interrupted network and undo safe. A failed operation leaves a
/// previously applied receipt unchanged for a future retry.
@MainActor
struct WaterExportSyncEngine {
    let driver: any WaterHealthWriting
    let store: WaterExportLocalStore

    @discardableResult
    func reconcile(habitID: UUID, dayKey: String,
                   goal: HabitGoalMode, count: Int,
                   calendar: Calendar = .autoupdatingCurrent) async throws -> Bool {
        let rule = store.rule(for: habitID)
        let previous = store.receipt(habitID: habitID, dayKey: dayKey)
        let action = WaterExportPlanning.action(
            habitID: habitID, dayKey: dayKey, goal: goal,
            currentCount: count, rule: rule, receipt: previous, calendar: calendar
        )
        switch action {
        case .none:
            // A previous save may have reached HealthKit before its receipt
            // was committed. On undo/opt-out, a pending intent still demands
            // cleanup of our own identifier even without a receipt.
            guard let pendingVersion = store.pendingVersion(
                habitID: habitID, dayKey: dayKey
            ) else { return false }
            guard driver.isWriteAuthorized() else { throw WaterExportError.notAuthorized }
            let identifier = WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: dayKey)
            if let previous, previous.syncIdentifier == identifier,
               previous.millilitres > 0 {
                // A failed update may have been superseded by an undo back to
                // the original valid quantity. Restore that quantity with a
                // strictly newer version rather than deleting it.
                let version = max(previous.syncVersion, pendingVersion) + 1
                store.setPendingVersion(version, habitID: habitID, dayKey: dayKey)
                try await driver.upsert(identifier: identifier,
                    millilitres: previous.millilitres,
                    version: version, dayKey: dayKey)
                store.setReceipt(WaterExportReceipt(
                    syncIdentifier: identifier, quantity: previous.quantity,
                    millilitres: previous.millilitres, syncVersion: version
                ), habitID: habitID, dayKey: dayKey)
            } else {
                try await driver.removeOwn(identifier: identifier)
            }
            store.setPendingVersion(nil, habitID: habitID, dayKey: dayKey)
            return true
        case .upsert(let identifier, let millilitres, let version):
            guard driver.isWriteAuthorized() else { throw WaterExportError.notAuthorized }
            let committedVersion = max(
                version,
                (store.pendingVersion(habitID: habitID, dayKey: dayKey) ?? 0) + 1
            )
            store.setPendingVersion(committedVersion, habitID: habitID, dayKey: dayKey)
            try await driver.upsert(identifier: identifier, millilitres: millilitres,
                                    version: committedVersion, dayKey: dayKey)
            // Persist only on confirmed success. The metadata ID is stable
            // across attempts, and HK manages its own sync-version replacement.
            store.setReceipt(WaterExportReceipt(
                syncIdentifier: identifier,
                quantity: min(max(count, 0), goal.target),
                millilitres: millilitres, syncVersion: committedVersion
            ), habitID: habitID, dayKey: dayKey)
            store.setPendingVersion(nil, habitID: habitID, dayKey: dayKey)
            return true
        case .delete(let identifier):
            guard driver.isWriteAuthorized() else { throw WaterExportError.notAuthorized }
            try await driver.removeOwn(identifier: identifier)
            store.setReceipt(nil, habitID: habitID, dayKey: dayKey)
            store.setPendingVersion(nil, habitID: habitID, dayKey: dayKey)
            return true
        }
    }
}

/// Driven by local durable check-in changes, not by HealthKit observers.
/// Serializes writes to avoid old/out-of-order aggregate counts racing with
/// newer updates and only considers habits with explicit opt-in or receipts.
@MainActor
final class WaterExportCoordinator {
    static let shared = WaterExportCoordinator()
    private let store = WaterExportLocalStore()
    private let driver: any WaterHealthWriting = WaterHealthKitWriter()
    private var running = false
    private var dirty = false
    private var container: ModelContainer?

    func configure(container: ModelContainer) {
        self.container = container
        requestSync()
    }

    func requestWriteAccess() async throws {
        #if DEBUG
        // UI test runs always use isolated test data. Even if a test taps
        // Save, it must never trigger a system Health permission dialog or
        // write to the simulator's (possibly persistent) health database.
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            throw WaterExportError.notAuthorized
        }
        #endif
        try await driver.requestWriteAccess()
    }

    func checkAuthorization() -> Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            return false
        }
        #endif
        return driver.isWriteAuthorized()
    }

    func rule(for habitID: UUID) -> WaterExportRule? {
        store.rule(for: habitID)
    }

    func setRule(_ rule: WaterExportRule?, for habitID: UUID) {
        store.setRule(rule, for: habitID)
    }

    func requestSync() {
        guard container != nil else { return }
        dirty = true
        guard !running else { return }
        running = true
        Task { @MainActor in
            defer { running = false }
            while dirty {
                dirty = false
                if let container {
                    await reconcile(context: ModelContext(container))
                }
            }
        }
    }

    private func reconcile(context: ModelContext) async {
        let rules = store.allRules
        let allHabits = ((try? context.fetch(FetchDescriptor<Habit>())) ?? [])
        let allChecks = ((try? context.fetch(FetchDescriptor<HabitCheckIn>())) ?? [])
        let ids = Set(rules.map(\.habitID))
        let withReceipts = allHabits.filter { !store.receipts(for: $0.id).isEmpty }
        let involved = allHabits.filter { ids.contains($0.id) }
            + withReceipts.filter { !ids.contains($0.id) }
        let knownIds = store.allKnownHabitIDs.union(ids)
        // Deleted habits can still own HealthKit samples: remove them by
        // their stored receipt/intent IDs without recreating any SwiftData rows.
        let orphanIDs = knownIds.subtracting(Set(involved.map(\.id)))
        guard !involved.isEmpty || !orphanIDs.isEmpty,
              driver.isWriteAuthorized() else { return }
        let engine = WaterExportSyncEngine(driver: driver, store: store)

        for habit in involved {
            let checkIns = allChecks.filter { $0.habitID == habit.id }
            var dayKeys = Set(checkIns.compactMap { row in
                row.dayKey ?? HabitDayKey.make(for: row.day)
            })
            dayKeys.formUnion(store.receipts(for: habit.id).map(\.dayKey))
            dayKeys.formUnion(store.pendingDays(for: habit.id))
            for day in dayKeys.sorted() {
                let count = HabitMultiCheck.count(habitID: habit.id,
                    dayKey: day, target: habit.dailyTarget, checkIns: checkIns)
                do {
                    try await engine.reconcile(habitID: habit.id, dayKey: day,
                        goal: habit.goalMode, count: count)
                } catch {
                    // No receipt change on failure. Next foreground/save will
                    // retry; do not expose private health values via analytics.
                    #if DEBUG
                    print("Water export pending retry: \(type(of: error))")
                    #endif
                }
            }
        }
        for orphanID in orphanIDs {
            let receiptDays = store.receipts(for: orphanID).map(\.dayKey)
            let days = Set(receiptDays + store.pendingDays(for: orphanID))
            for day in days {
                do {
                    try await engine.reconcile(habitID: orphanID, dayKey: day,
                        goal: .scheduled, count: 0)
                } catch {
                    // Leave receipt/intent for later cleanup on next launch.
                }
            }
            // An app-deleted habit must not retain an obsolete local opt-in
            // forever. Clear the rule ONLY if all its own HealthKit samples
            // and pending writes have been successfully reconciled.
            if store.receipts(for: orphanID).isEmpty &&
               store.pendingDays(for: orphanID).isEmpty {
                store.setRule(nil, for: orphanID)
            }
        }
    }
}
