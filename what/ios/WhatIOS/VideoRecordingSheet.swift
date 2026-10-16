import AVFoundation
import AVKit
import SwiftUI
import UIKit

/// Video recording starts immediately after required permissions are granted.
/// The original .mov is copied to durable local storage before dismissal.
@MainActor
final class VideoCaptureController: NSObject, ObservableObject,
                                    AVCaptureFileOutputRecordingDelegate {
    @Published private(set) var isRecording = false
    @Published private(set) var startedAt: Date?
    @Published private(set) var isPreparing = false
    @Published var errorMessage: String?
    @Published var didSave = false

    // Capture configuration and output run only on the serial sessionQueue.
    nonisolated(unsafe) let session = AVCaptureSession()
    private nonisolated(unsafe) let fileOutput = AVCaptureMovieFileOutput()
    private nonisolated let sessionQueue = DispatchQueue(label: "ru.arvectum.what.video.session")
    private var started = false
    private var discarded = false
    private var stopping = false
    var onSaved: ((URL, TimeInterval) throws -> Void)?

    func start() {
        guard !started else { return }
        started = true
        isPreparing = true
        Task {
            let video = await permission(for: .video)
            guard video else {
                isPreparing = false
                errorMessage = CaptureBrand.text(
                    "Разрешите доступ к камере в настройках.",
                    "Enable camera access in Settings."
                )
                return
            }
            let audio = await permission(for: .audio)
            guard audio else {
                isPreparing = false
                errorMessage = CaptureBrand.text(
                    "Разрешите доступ к микрофону в настройках.",
                    "Enable microphone access in Settings."
                )
                return
            }
            guard !stopping else { isPreparing = false; return }
            configureAndStart()
        }
    }

    private func permission(for mediaType: AVMediaType) async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: mediaType)
        default: return false
        }
    }

    private func configureAndStart() {
        sessionQueue.async { [self] in
            do {
                session.beginConfiguration()
                session.sessionPreset = .high
                guard let camera = AVCaptureDevice.default(
                    .builtInWideAngleCamera, for: .video, position: .back
                ), let microphone = AVCaptureDevice.default(for: .audio) else {
                    throw CaptureError.unavailable
                }
                let videoInput = try AVCaptureDeviceInput(device: camera)
                let audioInput = try AVCaptureDeviceInput(device: microphone)
                guard session.canAddInput(videoInput),
                      session.canAddInput(audioInput),
                      session.canAddOutput(fileOutput) else {
                    throw CaptureError.unavailable
                }
                session.addInput(videoInput)
                session.addInput(audioInput)
                session.addOutput(fileOutput)
                session.commitConfiguration()
                session.startRunning()

                let root = FileManager.default.urls(
                    for: .applicationSupportDirectory, in: .userDomainMask
                ).first!.appendingPathComponent("What/VideoCaptures", isDirectory: true)
                try FileManager.default.createDirectory(
                    at: root, withIntermediateDirectories: true
                )
                let path = root.appendingPathComponent(UUID().uuidString + ".mov")
                fileOutput.startRecording(to: path, recordingDelegate: self)
            } catch {
                if session.isRunning { session.stopRunning() }
                Task { @MainActor in
                    isPreparing = false
                    errorMessage = "Unable to start video capture: \(error.localizedDescription)"
                }
            }
        }
    }

    func finish(discard: Bool = false) {
        guard !stopping else { return }
        discarded = discard
        stopping = true
        sessionQueue.async { [self] in
            if fileOutput.isRecording {
                fileOutput.stopRecording()
            } else {
                if session.isRunning { session.stopRunning() }
                Task { @MainActor in isPreparing = false }
            }
        }
    }

    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        Task { @MainActor in
            startedAt = Date()
            isPreparing = false
            isRecording = true
            if stopping { finishPendingStop() }
        }
    }

    private func finishPendingStop() {
        sessionQueue.async { [self] in
            if fileOutput.isRecording { fileOutput.stopRecording() }
        }
    }

    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        Task { @MainActor in
            isRecording = false
            isPreparing = false
            let elapsed = startedAt.map { Date().timeIntervalSince($0) } ?? 0
            sessionQueue.async { [self] in
                if session.isRunning { session.stopRunning() }
            }
            if discarded {
                try? FileManager.default.removeItem(at: outputFileURL)
                return
            }
            if let error {
                errorMessage = "Video capture interrupted: \(error.localizedDescription)"
                return // Preserve incomplete source for diagnostics/recovery.
            }
            do {
                guard elapsed > 0 else { throw CaptureError.empty }
                try onSaved?(outputFileURL, elapsed)
                try? FileManager.default.removeItem(at: outputFileURL)
                didSave = true
            } catch {
                errorMessage = "Video could not be saved: \(error.localizedDescription)"
                // The source remains in Application Support for recovery.
            }
        }
    }

    private enum CaptureError: LocalizedError {
        case unavailable, empty
        var errorDescription: String? {
            switch self {
            case .unavailable: return "Camera or microphone unavailable"
            case .empty: return "No video was captured"
            }
        }
    }
}

final class CameraPreviewHost: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> CameraPreviewHost {
        let view = CameraPreviewHost()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    func updateUIView(_ view: CameraPreviewHost, context: Context) {}
}

struct VideoRecordingSheet: View {
    @ObservedObject var recorder: VideoCaptureController
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                CameraPreview(session: recorder.session)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .accessibilityLabel(CaptureBrand.text("Превью камеры", "Camera preview"))
                if let start = recorder.startedAt {
                    TimelineView(.periodic(from: .now, by: 0.5)) { time in
                        Text(duration(time.date.timeIntervalSince(start)))
                            .font(.title2.monospacedDigit())
                    }
                } else {
                    ProgressView(CaptureBrand.text("Подготовка камеры…", "Preparing camera…"))
                }
                Button {
                    recorder.finish()
                } label: {
                    Label(CaptureBrand.text("Стоп и сохранить", "Stop and save"),
                          systemImage: "stop.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(!recorder.isRecording)
            }
            .padding()
            .navigationTitle(CaptureBrand.text("Видеозаметка", "Video note"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CaptureBrand.text("Отменить", "Discard"), role: .destructive) {
                        recorder.finish(discard: true)
                        dismiss()
                    }
                }
            }
            .interactiveDismissDisabled(recorder.isRecording)
            .onAppear { recorder.start() }
            .onChange(of: recorder.didSave) { _, saved in
                if saved { dismiss() }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active && recorder.isRecording { recorder.finish() }
            }
            .onDisappear {
                if recorder.isRecording { recorder.finish() }
            }
            .alert(CaptureBrand.text("Видеозапись", "Video capture"),
                   isPresented: Binding(
                       get: { recorder.errorMessage != nil },
                       set: { if !$0 { recorder.errorMessage = nil } }
                   )) {
                Button("OK") { recorder.errorMessage = nil; dismiss() }
            } message: {
                Text(recorder.errorMessage ?? "")
            }
        }
    }

    private func duration(_ seconds: TimeInterval) -> String {
        let elapsed = max(0, Int(seconds))
        return String(format: "%02d:%02d", elapsed / 60, elapsed % 60)
    }
}

struct VideoPlaybackSheet: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VideoPlayer(player: AVPlayer(url: url))
                .padding()
                .navigationTitle(CaptureBrand.text("Видеозаметка", "Video note"))
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(CaptureBrand.text("Закрыть", "Close")) { dismiss() }
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}


/// New sheet identity creates a new camera session for every long press.
struct VideoCaptureHost: View {
    @EnvironmentObject private var store: PhoneStore
    @StateObject private var recorder = VideoCaptureController()

    var body: some View {
        VideoRecordingSheet(recorder: recorder)
            .onAppear {
                recorder.onSaved = { [store] url, duration in
                    try store.saveVideo(from: url, duration: duration)
                }
            }
    }
}


/// Extract poster from local original media, never from a remote service.
struct VideoPoster: View {
    let url: URL
    @State private var poster: UIImage?

    var body: some View {
        ZStack {
            Color.secondary.opacity(0.16)
            if let poster {
                Image(uiImage: poster)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "video")
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: url) {
            // Asset image generation can be slow; avoid blocking the Inbox.
            let image = await Task.detached(priority: .utility) { () -> UIImage? in
                let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
                generator.appliesPreferredTrackTransform = true
                guard let cgImage = try? generator.copyCGImage(
                    at: CMTime(seconds: 0.3, preferredTimescale: 600),
                    actualTime: nil
                ) else { return nil }
                return UIImage(cgImage: cgImage)
            }.value
            poster = image
        }
        .clipped()
    }
}
