#if DEBUG && PUSHKIN_PHYSICAL_QA
import Foundation
import SwiftData

/// QA-only, safe and repeatable in-place migration sentinel.
/// Never runs in App Store builds and never erases or overwrites any record.
@MainActor
enum PersistentUpgradeQAProbe {
    private static let marker = "QA-ONLY-PUSHKIN-MIGRATION-20261019"
    private static let bundle = "ru.arvectum.tools.notify.physicalqa"

    static func runIfRequested() {
        guard Bundle.main.bundleIdentifier == bundle else { return }
        let arguments = ProcessInfo.processInfo.arguments
        let seed = arguments.contains("--qa-upgrade-sentinel-seed")
        let verify = arguments.contains("--qa-upgrade-sentinel-verify")
        guard seed || verify else { return }
        let output = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("pushkin-persist-upgrade-report.json")
        do {
            let context = ModelContext(NotifyStore.modelContainer)
            var records = try context.fetch(FetchDescriptor<CapturedNotification>())
            let beforeCount = records.count
            if seed && !records.contains(where: { $0.titleText == marker }) {
                context.insert(CapturedNotification(
                    sourceApp: "QA only",
                    titleText: marker,
                    subtitleText: "",
                    bodyText: "Synthetic persistent fixture, no personal notification",
                    receivedAt: .now, capturedAt: .now
                ))
                try context.save()
                records = try context.fetch(FetchDescriptor<CapturedNotification>())
            }
            let matches = records.filter { $0.titleText == marker }
            let ok = matches.count == 1 && (!verify || records.count >= 1)
            let payload: [String: Any] = [
                "status": ok ? "PASS" : "FAIL",
                "bundle": bundle, "mode": seed ? "seed" : "verify",
                "beforeCount": beforeCount, "afterCount": records.count,
                "markerCount": matches.count,
                "markerID": matches.first?.id.uuidString ?? "",
                "appBuild": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
            ]
            let bytes = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
            try bytes.write(to: output, options: .atomic)
        } catch {
            let payload: [String: String] = [
                "status": "FAIL", "reason": "SwiftData QA migration inspection failed"
            ]
            if let bytes = try? JSONSerialization.data(withJSONObject: payload) {
                try? bytes.write(to: output, options: .atomic)
            }
        }
    }
}
#endif
