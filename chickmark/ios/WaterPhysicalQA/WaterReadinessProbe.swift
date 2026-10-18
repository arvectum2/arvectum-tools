#if DEBUG && WATER_PHYSICAL_QA
import Foundation
import HealthKit

/// Physical QA reports capability and permission state ONLY.
/// Does NOT request authorization or query/insert/delete samples.
enum WaterReadinessProbe {
    static func runIfRequested() {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("--ui-testing"),
              args.contains("--water-readiness"),
              Bundle.main.bundleIdentifier == "ru.arvectum.tools.chickmark.waterqa" else { return }
        let supported = HKHealthStore.isHealthDataAvailable()
        let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater)!
        let permission = supported
            ? HKHealthStore().authorizationStatus(for: waterType).rawValue
            : -1
        let report: [String: Any] = [
            "kind": "water-readiness-only",
            "deviceHealthKitAvailable": supported,
            "dietaryWaterWriteAuthorizationRawValue": permission,
            "didRequestAuthorization": false,
            "didReadHealthSamples": false,
            "didWriteHealthSamples": false,
            "didDeleteHealthSamples": false,
            "qaBundleIdentifier": Bundle.main.bundleIdentifier ?? "",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("water-readiness.json")
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        if JSONSerialization.isValidJSONObject(report),
           let data = try? JSONSerialization.data(withJSONObject: report, options: [.sortedKeys]) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
#endif
