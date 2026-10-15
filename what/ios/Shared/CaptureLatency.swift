import Foundation
import os

/// Anonymous, device-local tap-handler -> microphone readiness measurements.
/// Neither recording IDs nor audio/transcription content enter diagnostics.
enum CaptureLatency {
    static let maximumSamples = 30
    private static let prefix = "uhwhat.capture.start_ms."

    static func p95(milliseconds: [Double]) -> Double? {
        let valid = milliseconds.filter { $0.isFinite && $0 >= 0 }
            .sorted()
        guard !valid.isEmpty else { return nil }
        let rank = Int(ceil(Double(valid.count) * 0.95)) - 1
        return valid[rank]
    }

    static func samples(for source: String, defaults: UserDefaults = .standard) -> [Double] {
        defaults.array(forKey: prefix + source) as? [Double] ?? []
    }

    static func record(startedAt: TimeInterval, source: String,
                       now: TimeInterval = ProcessInfo.processInfo.systemUptime,
                       defaults: UserDefaults = .standard) {
        let elapsed = (now - startedAt) * 1_000
        guard elapsed.isFinite, elapsed >= 0, elapsed <= 120_000 else { return }
        var history = samples(for: source, defaults: defaults)
        history.append(elapsed)
        if history.count > maximumSamples {
            history.removeFirst(history.count - maximumSamples)
        }
        defaults.set(history, forKey: prefix + source)
        Logger(subsystem: "ru.arvectum.tools.what", category: "capture-timing")
            .info("\(source, privacy: .public) microphone-ready \(Int(elapsed), privacy: .public) ms; samples=\(history.count, privacy: .public)")
    }
}
