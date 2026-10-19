#if DEBUG && PUSHKIN_PHYSICAL_QA
import AppIntents
import Foundation
import SwiftData

/// Exercises the exact production AppIntent -> SwiftData path with synthetic
/// QA data only; NOT a claim that an iOS Shortcuts notification trigger fired.
@MainActor
enum DirectIntentQAProbe {
    private static let source = "QA-ONLY-PUSHKIN-INTENT-SENDER"
    private static let title = "QA-ONLY-APPINTENT-PERSIST-20261019"

    static func runIfRequested() {
        guard Bundle.main.bundleIdentifier == "ru.arvectum.tools.notify.physicalqa",
              ProcessInfo.processInfo.arguments.contains("--qa-direct-intent-verify")
        else { return }
        Task { @MainActor in await verify() }
    }

    private static func verify() async {
        let output = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("pushkin-direct-intent-report.json")
        do {
            let context = ModelContext(NotifyStore.modelContainer)
            let before = try context.fetch(FetchDescriptor<CapturedNotification>())
            if !before.contains(where: { $0.titleText == title }) {
                // Two near-simultaneous deliveries must collapse as the real
                // persistence actor dedupes an identical 2-second replay.
                for _ in 0..<2 {
                    var intent = CaptureNotificationIntent()
                    intent.sourceApp = source
                    intent.notificationTitle = title
                    intent.notificationSubtitle = "Only synthetic test data"
                    intent.notificationMessage = "No Shortcuts or personal notification access"
                    _ = try await intent.perform()
                }
            }
            let after = try context.fetch(FetchDescriptor<CapturedNotification>())
            let matches = after.filter { $0.titleText == title && $0.sourceApp == source }
            let status = matches.count == 1 ? "PASS" : "FAIL"
            let report: [String: Any] = [
                "status": status,
                "markerCount": matches.count,
                "totalRecords": after.count,
                "previousRecordsKept": before.allSatisfy { record in
                    after.contains(where: { $0.id == record.id })
                },
                "source": "synthetic-qa-only",
                "shortcutsTriggerWasInvoked": false
            ]
            let data = try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys])
            try data.write(to: output, options: .atomic)
        } catch {
            if let data = try? JSONSerialization.data(withJSONObject: [
                "status": "FAIL", "cause": "QA AppIntent verification failed"
            ]) { try? data.write(to: output, options: .atomic) }
        }
    }
}
#endif
