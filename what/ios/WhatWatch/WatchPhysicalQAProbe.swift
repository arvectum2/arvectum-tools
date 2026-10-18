#if WATCH_PHYSICAL_QA
import AVFoundation
import Foundation

/// Never compiled into the App Store target. Saves metadata only; raw voice
/// stays in the isolated QA Watch/iPhone containers.
@MainActor
final class WatchPhysicalQAProbe {
    static let shared = WatchPhysicalQAProbe()
    private var started = false

    private struct Status: Codable {
        let stage: String
        let timestamp: Date
        let pending: Int
        let details: String
    }

    private func write(_ stage: String, pending: Int, details: String = "") {
        guard let documents = FileManager.default.urls(for: .documentDirectory,
                                                       in: .userDomainMask).first else { return }
        let folder = documents.appendingPathComponent("WatchPhysicalQA", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder,
                                                 withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(Status(stage: stage,
                                                       timestamp: Date(), pending: pending,
                                                       details: details)) {
            try? data.write(to: folder.appendingPathComponent("status.json"), options: .atomic)
        }
    }

    func startIfRequested(controller: WatchCaptureController) {
        guard !started,
              ProcessInfo.processInfo.arguments.contains("what-watch-qa-record-once") else { return }
        started = true
        let permission: String
        switch AVAudioApplication.shared.recordPermission {
        case .granted: permission = "granted"
        case .denied: permission = "denied — open Watch microphone permissions"
        case .undetermined: permission = "undetermined — confirm on-watch access prompt"
        @unknown default: permission = "unknown"
        }
        write("waiting-for-microphone", pending: controller.pendingCount,
              details: "permission: " + permission)
        pollRecording(controller, attempts: 0)
    }

    private func pollRecording(_ controller: WatchCaptureController, attempts: Int) {
        switch controller.state {
        case .recording:
            write("recording", pending: controller.pendingCount)
            DispatchQueue.main.asyncAfter(deadline: .now() + 7) { [weak self] in
                controller.stopCapture()
                self?.captureFinished(controller)
            }
        case .error(let message):
            write("failed", pending: controller.pendingCount, details: message)
        default:
            if attempts >= 60 {
                write("unresolved", pending: controller.pendingCount,
                      details: "Microphone did not enter recording state")
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.pollRecording(controller, attempts: attempts + 1)
                }
            }
        }
    }

    private func captureFinished(_ controller: WatchCaptureController) {
        switch controller.state {
        case .saved:
            write("saved-on-watch", pending: controller.pendingCount,
                  details: "7-second physical audio stop succeeded")
        case .error(let error):
            write("failed", pending: controller.pendingCount, details: error)
        default:
            write("unresolved", pending: controller.pendingCount,
                  details: "Recording did not reach saved state")
        }
    }
}
#endif
