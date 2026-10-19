#if DEBUG && WATER_PHYSICAL_QA
import Foundation
import HealthKit

/// One-shot, write-only, real-device acceptance of the PRODUCTION
/// WaterHealthKitWriter, restricted to this independently signed QA bundle.
/// A durable receipt prevents accidental duplicate samples after interruption.
@MainActor
enum WaterLiveWriteProbe {
    private struct Receipt: Codable {
        let qaIdentifier: String
        var stage: String
        var detail: String
        var saveCompleted: Bool
        var ownDeletionCompleted: Bool
        var residualOwnSamples: Int?
    }

    private static var reportURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("water-live-write-20261018.json")
    }

    static func runIfRequested() {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("--ui-testing"),
              args.contains("--water-live-qa"),
              args.contains("--disable-cloud-sync"),
              Bundle.main.bundleIdentifier == "ru.arvectum.tools.chickmark.waterqa"
        else { return }
        Task { @MainActor in await run() }
    }

    private static func persist(_ receipt: Receipt) throws {
        let data = try JSONEncoder().encode(receipt)
        try data.write(to: reportURL, options: .atomic)
    }

    private static func run() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let writer = WaterHealthKitWriter()

        // A past attempt's journal is never overwritten. If there was any
        // uncertainty about whether a sample was saved, first attempt ONLY
        // to clean up the same application-owned sync identifier.
        if let existing = try? Data(contentsOf: reportURL),
           var previous = try? JSONDecoder().decode(Receipt.self, from: existing) {
            guard ["saveAttempted", "saved", "cleanupFailed", "saveUncertain"].contains(previous.stage) else {
                NSLog("WaterLive QA: one-shot already ran; no additional writes")
                return
            }
            guard writer.isWriteAuthorized() else {
                NSLog("WaterLive QA: pending cleanup but not authorized, abort")
                return
            }
            do {
                try await writer.removeOwn(identifier: previous.qaIdentifier)
                previous.stage = "cleanupRecovered"
                previous.ownDeletionCompleted = true
                try persist(previous)
            } catch {
                previous.stage = "cleanupFailed"
                previous.detail = "Recovery cleanup: \(error)"
                try? persist(previous)
            }
            return
        }

        let identifier = "arvectum.chickmark.water.qa." + UUID().uuidString
        var receipt = Receipt(
            qaIdentifier: identifier,
            stage: "authorizationRequested",
            detail: "Only 250 mL synthetic entry; never read Health samples",
            saveCompleted: false,
            ownDeletionCompleted: false,
            residualOwnSamples: nil
        )
        do {
            try persist(receipt)
            // Apple's system consent: user can approve or deny. No read access.
            try await writer.requestWriteAccess()
            receipt.stage = "authorized"
            try persist(receipt)

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = .autoupdatingCurrent
            formatter.dateFormat = "yyyy-MM-dd"
            let today = formatter.string(from: Date())

            receipt.stage = "saveAttempted"
            try persist(receipt)
            do {
                try await writer.upsert(
                    identifier: identifier, millilitres: 250,
                    version: 1, dayKey: today
                )
                receipt.saveCompleted = true
                receipt.stage = "saved"
                try persist(receipt)
            } catch {
                receipt.stage = "saveUncertain"
                receipt.detail = "Save failed/uncertain: \(error)"
                try? persist(receipt)
                // Do not attempt any other writes after uncertain save.
                return
            }

            do {
                // Exercises the production own-source, metadata-scoped deletion.
                try await writer.removeOwn(identifier: identifier)
                receipt.ownDeletionCompleted = true
                receipt.stage = "deleted"
                try persist(receipt)

                // Verify no same-ID QA-owned samples remain using the *same*
                // HealthKit delete API and no READ permission. Only this app's
                // exact metadata sync ID is targeted; zero means clean.
                let water = HKObjectType.quantityType(forIdentifier: .dietaryWater)!
                let onlyOurID = HKQuery.predicateForObjects(
                    withMetadataKey: HKMetadataKeySyncIdentifier,
                    allowedValues: [identifier]
                )
                let onlyOurSource = HKQuery.predicateForObjects(from: HKSource.default())
                let scope = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    onlyOurID, onlyOurSource
                ])
                let residual = try await HKHealthStore().deleteObjects(
                    of: water, predicate: scope
                )
                receipt.residualOwnSamples = residual
                receipt.stage = residual == 0 ? "completedClean" : "unexpectedResidualRemoved"
                receipt.detail = residual == 0
                    ? "Saved 250 mL and removed same QA sync identifier, zero residual"
                    : "Production cleanup left \(residual) owned sample(s), removed in verification"
                try persist(receipt)
            } catch {
                receipt.stage = "cleanupFailed"
                receipt.detail = "Deletion/verification failed: \(error)"
                try? persist(receipt)
            }
        } catch {
            receipt.stage = "authorizationDeniedOrJournalError"
            receipt.detail = "Consent / file error: \(error)"
            try? persist(receipt)
        }
    }
}
#endif
