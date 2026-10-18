#if DEBUG && WATER_PHYSICAL_QA
import Foundation
import HealthKit

/// Exercises the actual WaterExportSyncEngine with a real HealthKit driver
/// and a single synthetic, separately scoped QA habit (not production SwiftData).
@MainActor
enum WaterEditUndoProbe {
    struct Report: Codable {
        let habitID: UUID
        let identifier: String
        let suiteName: String
        let dayKey: String
        var stage: String
        var firstVersion: Int?
        var secondVersion: Int?
        var noOpConfirmed: Bool
        var receiptCleared: Bool
        var residualOwnSamples: Int?
        var detail: String
    }

    private static var reportURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("water-edit-undo-20261018.json")
    }

    static func runIfRequested() {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("--ui-testing"),
              args.contains("--disable-cloud-sync"),
              args.contains("--water-edit-undo-qa"),
              Bundle.main.bundleIdentifier == "ru.arvectum.tools.chickmark.waterqa"
        else { return }
        Task { @MainActor in await run() }
    }

    private static func persist(_ report: Report) throws {
        try JSONEncoder().encode(report).write(to: reportURL, options: .atomic)
    }

    private static func run() async {
        let writer = WaterHealthKitWriter()
        guard HKHealthStore.isHealthDataAvailable(), writer.isWriteAuthorized()
        else { NSLog("Water edit QA: no HealthKit WRITE consent, no action"); return }

        if let data = try? Data(contentsOf: reportURL),
           var older = try? JSONDecoder().decode(Report.self, from: data) {
            // Never start a new sample when a previous execution is ambiguous.
            guard older.stage != "completedClean" else { return }
            do {
                try await writer.removeOwn(identifier: older.identifier)
                older.stage = "recoveredCleanup"
                older.detail = "Interrupted test: removed ONLY original QA sync ID"
                try persist(older)
            } catch {
                older.stage = "cleanupFailed"
                older.detail = "Pending QA ID cleanup failed: \(error)"
                try? persist(older)
            }
            return
        }

        let habitID = UUID()
        let dayKey = HabitDayKey.make(for: .now)
        let suiteName = "ru.arvectum.water-edit-qa." + habitID.uuidString
        let identifier = WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: dayKey)
        var report = Report(
            habitID: habitID, identifier: identifier, suiteName: suiteName,
            dayKey: dayKey, stage: "initialized", firstVersion: nil,
            secondVersion: nil, noOpConfirmed: false,
            receiptCleared: false, residualOwnSamples: nil,
            detail: "One synthetic habit; HealthKit WRITE only, zero READ"
        )
        do {
            try persist(report) // durable BEFORE any system HealthKit operation
            guard let defaults = UserDefaults(suiteName: suiteName) else {
                throw WaterExportError.failed
            }
            let store = WaterExportLocalStore(defaults: defaults)
            guard store.setRule(WaterExportRule(
                millilitresPerUnit: 250,
                enabledAt: Calendar.current.startOfDay(for: .now)
            ), for: habitID) else { throw WaterExportError.failed }
            let engine = WaterExportSyncEngine(driver: writer, store: store)
            let goal = HabitGoalMode.quantity(count: 4)

            report.stage = "firstWriteAttempted"
            try persist(report)
            guard try await engine.reconcile(habitID: habitID,
                    dayKey: dayKey, goal: goal, count: 1),
                  let first = store.receipt(habitID: habitID, dayKey: dayKey),
                  first.millilitres == 250, first.quantity == 1
            else { throw WaterExportError.failed }
            report.firstVersion = first.syncVersion
            report.stage = "firstWriteConfirmed"
            try persist(report)

            report.stage = "editAttempted"
            try persist(report)
            guard try await engine.reconcile(habitID: habitID,
                    dayKey: dayKey, goal: goal, count: 2),
                  let second = store.receipt(habitID: habitID, dayKey: dayKey),
                  second.millilitres == 500, second.quantity == 2,
                  second.syncVersion > first.syncVersion
            else { throw WaterExportError.failed }
            report.secondVersion = second.syncVersion
            report.stage = "editConfirmed"
            try persist(report)

            let duplicateChange = try await engine.reconcile(
                habitID: habitID, dayKey: dayKey, goal: goal, count: 2)
            let unchanged = store.receipt(habitID: habitID, dayKey: dayKey)
            guard !duplicateChange, unchanged?.syncVersion == second.syncVersion
            else { throw WaterExportError.failed }
            report.noOpConfirmed = true
            report.stage = "duplicateNoOpConfirmed"
            try persist(report)

            report.stage = "undoAttempted"
            try persist(report)
            guard try await engine.reconcile(habitID: habitID,
                    dayKey: dayKey, goal: goal, count: 0),
                  store.receipt(habitID: habitID, dayKey: dayKey) == nil
            else { throw WaterExportError.failed }
            report.receiptCleared = true
            report.stage = "undoConfirmed"
            try persist(report)

            // Verify cleanup using the exact QA sync ID + own source. No read
            // authorization: a second delete must find zero remaining records.
            let water = HKObjectType.quantityType(forIdentifier: .dietaryWater)!
            let scoped = NSCompoundPredicate(andPredicateWithSubpredicates: [
                HKQuery.predicateForObjects(
                    withMetadataKey: HKMetadataKeySyncIdentifier,
                    allowedValues: [identifier]),
                HKQuery.predicateForObjects(from: HKSource.default())
            ])
            let remaining = try await HKHealthStore().deleteObjects(
                of: water, predicate: scoped)
            report.residualOwnSamples = remaining
            report.stage = remaining == 0 ? "completedClean" : "cleanupDiscrepancy"
            report.detail = remaining == 0
                ? "250 to 500 mL via real sync engine; duplicate no-op; 0 mL undo; no residual"
                : "Undo left \(remaining) app-owned sample(s); cleanup removed them"
            try persist(report)
            // Only the unique QA preference suite created above, never real
            // app defaults. Journal remains so the test can never repeat.
            if report.stage == "completedClean" {
                defaults.removePersistentDomain(forName: suiteName)
            }
        } catch {
            report.stage = "failedCleanupAttempted"
            report.detail = "Failed in \(report.stage): \(error)"
            try? persist(report)
            do {
                try await writer.removeOwn(identifier: identifier)
                report.stage = "failedButCleaned"
                report.detail = "Original scenario failed; scoped QA sample removed"
            } catch {
                report.stage = "cleanupFailed"
                report.detail = "Original error / cleanup error: \(error)"
            }
            try? persist(report)
        }
    }
}
#endif
