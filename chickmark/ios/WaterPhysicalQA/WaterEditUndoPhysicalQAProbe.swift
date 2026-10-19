#if DEBUG && WATER_PHYSICAL_QA
import Foundation
import HealthKit

/// A single disposable QA-only live HealthKit transaction. Never runs in the
/// production target, never queries another source's samples, and fail-closes
/// to cleanup (rather than repeating a possibly saved entry) on re-launch.
@MainActor
enum WaterEditUndoPhysicalQAProbe {
    private struct Journal: Codable {
        let habitID: UUID
        let dayKey: String
        let syncID: String
        var stage: String
        var countsCompleted: [Int]
        var residualOwnSamples: Int?
        var error: String?
    }

    private static let suite = "ru.arvectum.chickmark.waterqa.editundo.20261019"
    private static let file = "water-edit-undo-live-qa.json"

    private static var reportURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!.appendingPathComponent(file)
    }

    static func runIfRequested() {
        let args = ProcessInfo.processInfo.arguments
        guard Bundle.main.bundleIdentifier == "ru.arvectum.tools.chickmark.waterqa",
              args.contains("--ui-testing"), args.contains("--disable-cloud-sync"),
              args.contains("--water-edit-undo-live-qa") else { return }
        Task { @MainActor in await execute() }
    }

    private static func persist(_ journal: Journal) throws {
        try JSONEncoder().encode(journal).write(to: reportURL, options: .atomic)
    }

    private static func cleanOnlyOwnSample(
        writer: WaterHealthKitWriter,
        journal: inout Journal
    ) async {
        guard writer.isWriteAuthorized() else {
            journal.error = "Cleanup requires write authorization"
            journal.stage = "cleanupPending"
            try? persist(journal)
            return
        }
        do {
            // Remove ONLY the exact QA sync ID and the currently signed
            // application's HKSource. Never use a date-wide delete.
            try await writer.removeOwn(identifier: journal.syncID)
            let water = HKObjectType.quantityType(forIdentifier: .dietaryWater)!
            let id = HKQuery.predicateForObjects(
                withMetadataKey: HKMetadataKeySyncIdentifier,
                allowedValues: [journal.syncID]
            )
            let owned = HKQuery.predicateForObjects(from: HKSource.default())
            let scope = NSCompoundPredicate(andPredicateWithSubpredicates: [id, owned])
            let residual = try await HKHealthStore().deleteObjects(
                of: water, predicate: scope
            )
            journal.residualOwnSamples = residual
            journal.stage = residual == 0 ? "completedClean" : "unexpectedResidualRemoved"
            try persist(journal)
        } catch {
            journal.stage = "cleanupPending"
            journal.error = "Own-sample cleanup error: \(type(of: error))"
            try? persist(journal)
        }
    }

    private static func execute() async {
        let writer = WaterHealthKitWriter()
        if let bytes = try? Data(contentsOf: reportURL),
           var journal = try? JSONDecoder().decode(Journal.self, from: bytes) {
            // No repeat writes after a restart or an uncertain save.
            guard journal.stage != "completedClean" else { return }
            await cleanOnlyOwnSample(writer: writer, journal: &journal)
            return
        }

        guard HKHealthStore.isHealthDataAvailable(), writer.isWriteAuthorized(),
              let defaults = UserDefaults(suiteName: suite) else {
            NSLog("WaterEditUndo QA not authorized or suite unavailable, refusing test")
            return
        }
        let habit = UUID()
        let day = HabitDayKey.make(for: Date())
        var journal = Journal(
            habitID: habit, dayKey: day,
            syncID: WaterExportPlanning.syncIdentifier(habitID: habit, dayKey: day),
            stage: "prepared", countsCompleted: [], residualOwnSamples: nil,
            error: nil
        )
        // Persist unique ownership scope BEFORE asking the real writer to save.
        do { try persist(journal) }
        catch { return }

        let store = WaterExportLocalStore(defaults: defaults)
        let engine = WaterExportSyncEngine(driver: writer, store: store)
        guard store.setRule(WaterExportRule(
            millilitresPerUnit: 250, enabledAt: Date()
        ), for: habit) else {
            journal.stage = "failedBeforeWrite"
            try? persist(journal)
            return
        }
        let goal: HabitGoalMode = .quantity(count: 10)
        for count in [1, 2, 0, 3, 0] {
            journal.stage = "attemptingCount_\(count)"
            do {
                try persist(journal)
                let performed = try await engine.reconcile(
                    habitID: habit, dayKey: day, goal: goal, count: count
                )
                guard performed else { throw WaterExportError.failed }
                journal.countsCompleted.append(count)
                try persist(journal)
            } catch {
                journal.stage = "writeFailedCleanupRequired"
                journal.error = "Error type \(type(of: error)) at count \(count)"
                try? persist(journal)
                await cleanOnlyOwnSample(writer: writer, journal: &journal)
                return
            }
        }
        let record = store.receipt(habitID: habit, dayKey: day)
        let pending = store.pendingVersion(habitID: habit, dayKey: day)
        guard record == nil, pending == nil,
              store.highestVersion(habitID: habit, dayKey: day) >= 3 else {
            journal.stage = "ledgerNotClean"
            try? persist(journal)
            await cleanOnlyOwnSample(writer: writer, journal: &journal)
            return
        }
        journal.stage = "ledgerCleanVerifyingOwnHealthKit"
        try? persist(journal)
        await cleanOnlyOwnSample(writer: writer, journal: &journal)
        _ = store.setRule(nil, for: habit)
    }
}
#endif
