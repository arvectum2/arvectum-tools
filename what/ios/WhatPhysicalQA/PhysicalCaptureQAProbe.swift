#if REVIEW_HANDOFF_QA
import AVFoundation
import Foundation
import UIKit
import SwiftUI

/// Foreground-only, opt-in physical recording probe used when XCTest UI
/// automation is unavailable. Exists exclusively in the distinct QA bundle.
/// Launch explicitly with QA-only `flips`, `180s`, `early-crash` or `verify`.
@MainActor
final class PhysicalCaptureQAProbe {
    static let shared = PhysicalCaptureQAProbe()
    private var controller: VideoCaptureController?
    private var hasStarted = false
    private var originalIdleTimerDisabled: Bool?
    private var backgroundSheetOriginalIDs = Set<UUID>()
    private var hasBackgroundedSheet = false
    private var activeMode: String?

    private struct Status: Codable {
        let stage: String
        let mode: String
        let recordedFlips: Int
        let details: String
        let timestamp: Date
    }

    private func write(_ stage: String, mode: String, flips: Int = 0, details: String = "") {
        guard let root = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else { return }
        let folder = root.appendingPathComponent("What/PhysicalProbe", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let status = Status(stage: stage, mode: mode, recordedFlips: flips,
                            details: details, timestamp: Date())
        if let encoded = try? JSONEncoder().encode(status) {
            try? encoded.write(to: folder.appendingPathComponent("status.json"), options: .atomic)
        }
    }

    func startIfRequested(store: PhoneStore) {
        guard !hasStarted,
              let argument = ProcessInfo.processInfo.arguments.first(where: {
                  $0.hasPrefix("what-physical-qa=")
              }) else { return }
        hasStarted = true
        let mode = String(argument.dropFirst("what-physical-qa=".count))
        guard ["flips", "180s", "early-crash", "verify", "background-sheet"].contains(mode) else { return }
        activeMode = mode
        originalIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
        UIApplication.shared.isIdleTimerDisabled = true
        write("starting", mode: mode)
        if mode == "background-sheet" {
            // Present the ACTUAL SwiftUI video sheet so that its existing
            // scenePhase != active -> recorder.finish() hook is exercised.
            backgroundSheetOriginalIDs = Set(store.localNotes.map(\.id))
            store.showVideoCapture = true
            write("sheet-presented", mode: mode,
                  details: "Production VideoRecordingSheet requested")
            return
        }
        if mode == "verify" {
            Task { @MainActor [self] in
                let videos = store.localNotes.filter { $0.kind == .video }.prefix(2)
                guard videos.count == 2 else {
                    write("failed", mode: mode, details: "Fewer than two QA videos")
                    finishIdleTimer()
                    return
                }
                do {
                    var metrics: [String] = []
                    for note in videos {
                        guard let url = store.videoURL(for: note) else {
                            throw NSError(domain: "PhysicalProbe", code: 11)
                        }
                        let asset = AVURLAsset(url: url)
                        let playable = try await asset.load(.isPlayable)
                        let duration = try await asset.load(.duration).seconds
                        let videoTracks = try await asset.loadTracks(withMediaType: .video)
                        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
                        guard playable, duration > 0, !videoTracks.isEmpty,
                              !audioTracks.isEmpty else {
                            throw NSError(domain: "PhysicalProbe", code: 12)
                        }
                        metrics.append(String(format: "%.2fs", duration))
                    }
                    write("verified", mode: mode,
                          details: "2 latest local MOVs playable with video/audio: " + metrics.joined(separator: ", "))
                } catch {
                    write("failed", mode: mode, details: error.localizedDescription)
                }
                finishIdleTimer()
            }
            return
        }
        let capture = VideoCaptureController()
        controller = capture
        capture.onSaved = { url, duration, id in
            try store.saveVideo(from: url, duration: duration, id: id)
        }
        capture.start()

        Task { @MainActor [self] in
            // Give AVFoundation enough time to configure, or report failure.
            for _ in 0..<120 where !capture.isRecording && capture.errorMessage == nil {
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            guard capture.isRecording else {
                write("failed", mode: mode, details: capture.errorMessage ?? "Camera did not start")
                finishIdleTimer()
                return
            }
            write("recording", mode: mode)
            if mode == "early-crash" {
                // Host deliberately terminates only this QA process while the
                // first segment is still open. Never auto-save or auto-delete.
                return
            }
            if mode == "flips" {
                for i in 0..<6 {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    guard capture.isRecording else {
                        write("failed", mode: mode, flips: i,
                              details: capture.errorMessage ?? "Capture stopped")
                        finishIdleTimer()
                        return
                    }
                    let expected = capture.cameraPosition == .back
                        ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back
                    capture.switchCamera()
                    for _ in 0..<100 where capture.cameraPosition != expected
                        || !capture.isRecording {
                        try? await Task.sleep(nanoseconds: 200_000_000)
                    }
                    guard capture.cameraPosition == expected && capture.isRecording else {
                        write("failed", mode: mode, flips: i,
                              details: capture.errorMessage ?? "Camera switch timed out")
                        finishIdleTimer()
                        return
                    }
                    write("recording", mode: mode, flips: i + 1)
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            } else {
                try? await Task.sleep(nanoseconds: 180_000_000_000)
            }
            guard capture.isRecording else {
                write("failed", mode: mode, details: capture.errorMessage ?? "Capture interrupted")
                finishIdleTimer()
                return
            }
            write("saving", mode: mode, flips: mode == "flips" ? 6 : 0)
            capture.finish()
            for _ in 0..<900 where !capture.didSave && capture.errorMessage == nil {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            if capture.didSave {
                write("saved", mode: mode, flips: mode == "flips" ? 6 : 0,
                      details: "Video callback durably indexed the MOV")
            } else {
                write("failed", mode: mode,
                      details: capture.errorMessage ?? "Video save timeout")
            }
            finishIdleTimer()
        }
    }

    /// Observe real ScenePhase transitions without synthesizing a background
    /// notification. Only the independent QA executable has this hook.
    func observeScenePhase(_ phase: ScenePhase, store: PhoneStore) {
        guard activeMode == "background-sheet" else { return }
        switch phase {
        case .background:
            hasBackgroundedSheet = true
            write("backgrounded", mode: "background-sheet",
                  details: "ScenePhase.background observed")
        case .active where hasBackgroundedSheet:
            hasBackgroundedSheet = false
            write("foregrounded", mode: "background-sheet")
            Task { @MainActor [self] in
                for _ in 0..<60 {
                    let new = store.localNotes.filter {
                        $0.kind == .video && !backgroundSheetOriginalIDs.contains($0.id)
                    }
                    if new.count == 1 {
                        write("saved-after-background", mode: "background-sheet",
                              details: "Exactly one new durable video UUID, duration=\(new[0].duration ?? 0)")
                        finishIdleTimer()
                        return
                    }
                    if new.count > 1 {
                        write("failed", mode: "background-sheet",
                              details: "Multiple new video UUIDs after one background")
                        finishIdleTimer()
                        return
                    }
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
                write("unresolved", mode: "background-sheet",
                      details: "No new durable note after foreground; inspect capture journal")
                finishIdleTimer()
            }
        default:
            break
        }
    }

    private func finishIdleTimer() {
        if let previous = originalIdleTimerDisabled {
            UIApplication.shared.isIdleTimerDisabled = previous
        }
    }
}
#endif
