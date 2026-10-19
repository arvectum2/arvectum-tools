#if WATCH_PHYSICAL_QA
import AVFoundation
import Foundation

/// Never compiled into the App Store target. Saves metadata only; raw voice
/// stays in the isolated QA Watch/iPhone containers.
@MainActor
final class WatchPhysicalQAProbe {
    static let shared = WatchPhysicalQAProbe()
    private var started = false
    private var heldTransport = false
    private var capturedID: UUID?
    private var existingBeforeTest = Set<UUID>()

    private struct Status: Codable {
        let stage: String
        let timestamp: Date
        let pending: Int
        let details: String
        let captureID: UUID?
    }

    private func write(_ stage: String, pending: Int, details: String = "") {
        guard let documents = FileManager.default.urls(for: .documentDirectory,
                                                       in: .userDomainMask).first else { return }
        let folder = documents.appendingPathComponent("WatchPhysicalQA", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder,
                                                 withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(Status(stage: stage,
                                                       timestamp: Date(), pending: pending,
                                                       details: details,
                                                       captureID: capturedID)) {
            try? data.write(to: folder.appendingPathComponent("status.json"), options: .atomic)
        }
    }

    func startIfRequested(controller: WatchCaptureController) {
        guard !started else { return }
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("what-watch-qa-audit") {
            started = true
            let ids = currentOutboundAudioIDs()
            let base = FileManager.default.urls(for: .documentDirectory,
                                                in: .userDomainMask).first!
            let files = ids.map { id -> String in
                let url = base.appendingPathComponent("WhatOutbound/" + id.uuidString + ".m4a")
                let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                let decoded = (try? AVAudioPlayer(contentsOf: url))?.duration ?? 0
                return "\(id.uuidString): bytes=\(bytes), duration=\(decoded)"
            }
            write("audit", pending: controller.pendingCount,
                  details: "Orphan or queued source metadata only: " + files.joined(separator: "; "))
            return
        }
        let hold = arguments.contains("what-watch-qa-hold-and-send")
        guard hold || arguments.contains("what-watch-qa-record-once") else { return }
        started = true
        existingBeforeTest = Set(currentOutboundAudioIDs())
        heldTransport = hold
        if hold { controller.qaSetTransportHeld(true) }
        let permission: String
        switch AVAudioApplication.shared.recordPermission {
        case .granted: permission = "granted"
        case .denied: permission = "denied — open Watch microphone permissions"
        case .undetermined: permission = "undetermined — confirm on-watch access prompt"
        @unknown default: permission = "unknown"
        }
        write("waiting-for-microphone", pending: controller.pendingCount,
              details: "permission: " + permission)
        guard AVAudioApplication.shared.recordPermission == .granted else { return }
        // Only QA can initiate an unattended microphone recording, and ONLY
        // with the explicit, opt-in launch argument from a developer test.
        controller.startCapture()
        pollRecording(controller, attempts: 0)
    }

    private func pollRecording(_ controller: WatchCaptureController, attempts: Int) {
        switch controller.state {
        case .recording:
            capturedID = currentOutboundAudioIDs().first {
                !existingBeforeTest.contains($0)
            }
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

    private func currentOutboundAudioIDs() -> [UUID] {
        guard let folder = FileManager.default.urls(for: .documentDirectory,
                             in: .userDomainMask).first?
                             .appendingPathComponent("WhatOutbound", isDirectory: true),
              let urls = try? FileManager.default.contentsOfDirectory(
                  at: folder, includingPropertiesForKeys: nil
              ) else { return [] }
        return urls.filter { $0.pathExtension == "m4a" }
            .compactMap { UUID(uuidString: $0.deletingPathExtension().lastPathComponent) }
    }

    private func checkAcknowledgement(_ controller: WatchCaptureController, attempt: Int = 0) {
        guard let id = capturedID else {
            write("unresolved", pending: controller.pendingCount,
                  details: "Capture UUID absent in QA watch outbound directory")
            return
        }
        let stillOnWatch = currentOutboundAudioIDs().contains(id)
        if controller.pendingCount == 0 && !stillOnWatch {
            write("ack-observed", pending: 0,
                  details: "Watch UUID removed only after receiver ACK; original absent")
            return
        }
        if attempt >= 180 {
            write("pending", pending: controller.pendingCount,
                  details: "No ACK after 90 seconds; source audio preserved=" + String(stillOnWatch))
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkAcknowledgement(controller, attempt: attempt + 1)
        }
    }

    private func captureFinished(_ controller: WatchCaptureController) {
        switch controller.state {
        case .saved:
            capturedID = capturedID ?? currentOutboundAudioIDs().first {
                !existingBeforeTest.contains($0)
            }
            write("saved-on-watch", pending: controller.pendingCount,
                  details: "7-second physical AAC stored locally")
            if heldTransport {
                // Wait while the original is durably queued, then release
                // only this QA-app transport. No system network toggles.
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                    guard let self else { return }
                    let present = self.capturedID.map {
                        self.currentOutboundAudioIDs().contains($0)
                    } ?? false
                    guard present, controller.pendingCount >= 1 else {
                        self.write("failed", pending: controller.pendingCount,
                                   details: "Original was not durable while QA transport paused")
                        controller.qaSetTransportHeld(false)
                        return
                    }
                    self.write("offline-queued", pending: controller.pendingCount,
                               details: "AAC remained durable for 10 seconds with QA-only transport held")
                    self.heldTransport = false
                    controller.qaSetTransportHeld(false)
                    self.checkAcknowledgement(controller)
                }
            } else {
                checkAcknowledgement(controller)
            }
        case .error(let error):
            let fresh = currentOutboundAudioIDs().first {
                !existingBeforeTest.contains($0)
            }
            capturedID = capturedID ?? fresh
            var detail = error
            if let id = capturedID,
               let base = FileManager.default.urls(for: .documentDirectory,
                                                  in: .userDomainMask).first {
                let url = base.appendingPathComponent("WhatOutbound/" + id.uuidString + ".m4a")
                let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                let decoded = (try? AVAudioPlayer(contentsOf: url))?.duration ?? 0
                detail += " | preserved AAC bytes=\(bytes), decodedSeconds=\(decoded)"
            }
            write("failed", pending: controller.pendingCount, details: detail)
        default:
            write("unresolved", pending: controller.pendingCount,
                  details: "Recording did not reach saved state")
        }
    }
}
#endif
