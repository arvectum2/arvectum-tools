import AVFoundation
import AVKit
import SwiftUI
import UIKit

/// Video capture starts directly from the long press on the home button.
/// Switching cameras closes the current segment, starts the other camera,
/// then combines the segments into one local .mov when the user saves.
/// Original segments are deleted only after the repository confirms the save.
@MainActor
final class VideoCaptureController: NSObject, ObservableObject,
                                    AVCaptureFileOutputRecordingDelegate {
    @Published private(set) var isRecording = false
    @Published private(set) var isSwitching = false
    @Published private(set) var isSaving = false
    @Published private(set) var cameraPosition: AVCaptureDevice.Position = .back
    @Published private(set) var startedAt: Date?
    @Published private(set) var isPreparing = false
    @Published var errorMessage: String?
    @Published var didSave = false

    nonisolated(unsafe) let session = AVCaptureSession()
    private nonisolated(unsafe) let fileOutput = AVCaptureMovieFileOutput()
    private nonisolated let sessionQueue = DispatchQueue(label: "ru.arvectum.what.video.session")

    private var started = false
    private var stopping = false
    private var flow = VideoCaptureTransition()
    private var clips: [URL] = []
    private var hasDamagedSegments = false
    private nonisolated(unsafe) let recoveryJournal = VideoCaptureJournal()
    private nonisolated(unsafe) var recoveryID: UUID?
    // Advanced only on the camera's serial session queue.
    private nonisolated(unsafe) var nextSegmentNumber = 0

    var onSaved: ((URL, TimeInterval, UUID) throws -> Void)?

    deinit {
        if let recoveryID {
            VideoCaptureJournal.setActive(recoveryID, active: false)
        }
    }

    var canSwitchCamera: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video,
                                position: .front) != nil
            && AVCaptureDevice.default(.builtInWideAngleCamera, for: .video,
                                       position: .back) != nil
    }

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
            guard !stopping else {
                isPreparing = false
                return
            }
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

    private nonisolated func nextClipURL() throws -> URL {
        guard let recoveryID else { throw CaptureError.unavailable }
        let number = nextSegmentNumber
        nextSegmentNumber += 1
        return recoveryJournal.segmentURL(for: recoveryID, index: number)
    }

    private func configureAndStart() {
        do {
            // Persist capture identity before AVFoundation writes any bytes.
            recoveryID = try recoveryJournal.begin()
            if let recoveryID {
                VideoCaptureJournal.setActive(recoveryID, active: true)
            }
        } catch {
            isPreparing = false
            errorMessage = CaptureBrand.text(
                "Не удалось создать безопасное хранилище для видеозаписи: ",
                "Could not prepare durable video capture storage: "
            ) + error.localizedDescription
            return
        }
        sessionQueue.async { [self] in
            do {
                session.beginConfiguration()
                do {
                    session.sessionPreset = .high
                    guard let camera = AVCaptureDevice.default(
                        .builtInWideAngleCamera, for: .video, position: .back
                    ), let microphone = AVCaptureDevice.default(for: .audio) else {
                        throw CaptureError.unavailable
                    }
                    let videoInput = try AVCaptureDeviceInput(device: camera)
                    let audioInput = try AVCaptureDeviceInput(device: microphone)
                    guard session.canAddInput(videoInput), session.canAddInput(audioInput),
                          session.canAddOutput(fileOutput) else {
                        throw CaptureError.unavailable
                    }
                    session.addInput(videoInput)
                    session.addInput(audioInput)
                    session.addOutput(fileOutput)
                    session.commitConfiguration()
                } catch {
                    session.commitConfiguration()
                    throw error
                }

                session.startRunning()
                fileOutput.startRecording(
                    to: try nextClipURL(), recordingDelegate: self
                )
            } catch {
                if session.isRunning { session.stopRunning() }
                Task { @MainActor in
                    isPreparing = false
                    errorMessage = CaptureBrand.text(
                        "Не удалось запустить видеозапись: ",
                        "Unable to start video: "
                    ) + error.localizedDescription
                }
            }
        }
    }

    /// A movie-file output cannot reliably hot-swap a camera in the middle of
    /// a file. Close the current segment before reconfiguring the input.
    func switchCamera() {
        guard canSwitchCamera, !isSwitching, !isSaving, !stopping,
              flow.requestSwitch(isRecording: isRecording) else { return }
        isSwitching = true
        isRecording = false
        let target: AVCaptureDevice.Position = cameraPosition == .back ? .front : .back
        sessionQueue.async { [self] in
            if fileOutput.isRecording {
                fileOutput.stopRecording()
            } else {
                Task { @MainActor in
                    failSwitch(CaptureError.unavailable)
                }
            }
        }
        // The actual camera replacement begins in didFinishRecordingTo.
        pendingCameraPosition = target
    }

    private var pendingCameraPosition: AVCaptureDevice.Position?

    func finish(discard: Bool = false) {
        guard !isSaving, !stopping else { return }
        var discardSafely = discard
        if discard, let recoveryID {
            do {
                // Persist the user's explicit Discard before deleting clips.
                // A crash after dismissal must never resurrect a deleted note.
                try recoveryJournal.markDiscarded(recoveryID)
            } catch {
                discardSafely = false
                errorMessage = CaptureBrand.text(
                    "Невозможно безопасно удалить черновик; сохраняем видео. ",
                    "Cannot safely discard the draft; saving the video. "
                ) + error.localizedDescription
            }
        }
        flow.requestStop(discard: discardSafely)
        stopping = true

        // The pending switch's stopRecording is already in progress;
        // didFinishRecordingTo will honor this newer Stop/Discard action.
        if isSwitching { return }

        sessionQueue.async { [self] in
            if fileOutput.isRecording {
                fileOutput.stopRecording()
            } else if session.isRunning {
                session.stopRunning()
                Task { @MainActor in
                    isPreparing = false
                    if flow.shouldDiscard {
                        clearTemporaryClips()
                        if let recoveryID {
                            try? recoveryJournal.removeSavedSession(recoveryID)
                            VideoCaptureJournal.setActive(recoveryID, active: false)
                        }
                    }
                }
            }
        }
    }

    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        Task { @MainActor in
            if startedAt == nil { startedAt = Date() }
            flow.didStartNextClip()
            isPreparing = false
            isSwitching = false
            isRecording = true
            if stopping { stopPendingClip() }
        }
    }

    private func stopPendingClip() {
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
            if flow.shouldDiscard {
                clips.append(outputFileURL)
                closeSession()
                clearTemporaryClips()
                if let recoveryID {
                    try? recoveryJournal.removeSavedSession(recoveryID)
                    VideoCaptureJournal.setActive(recoveryID, active: false)
                }
                isSwitching = false
                isPreparing = false
                return
            }

            if error == nil {
                clips.append(outputFileURL)
            } else {
                // Do not erase a partially written original after a camera
                // interruption. It remains in VideoCaptures for recovery.
                hasDamagedSegments = true
                flow.requestStop(discard: false)
                stopping = true
                errorMessage = CaptureBrand.text(
                    "Запись прервана; уже снятые фрагменты будут сохранены. ",
                    "Capture interrupted; saved segments will be preserved. "
                ) + error!.localizedDescription
            }

            if flow.shouldSwitchAfterClip && !stopping {
                guard let target = pendingCameraPosition else {
                    failSwitch(CaptureError.unavailable)
                    return
                }
                switchInputAndStartNextClip(target)
            } else {
                isSwitching = false
                closeSession()
                await saveCompletedVideo()
            }
        }
    }

    private func switchInputAndStartNextClip(_ target: AVCaptureDevice.Position) {
        sessionQueue.async { [self] in
            do {
                guard let oldInput = session.inputs.compactMap({
                    $0 as? AVCaptureDeviceInput
                }).first(where: { $0.device.hasMediaType(.video) }),
                      let nextCamera = AVCaptureDevice.default(
                        .builtInWideAngleCamera, for: .video, position: target
                      ) else {
                    throw CaptureError.unavailable
                }
                let nextInput = try AVCaptureDeviceInput(device: nextCamera)
                session.beginConfiguration()
                session.removeInput(oldInput)
                guard session.canAddInput(nextInput) else {
                    if session.canAddInput(oldInput) {
                        session.addInput(oldInput)
                    }
                    session.commitConfiguration()
                    throw CaptureError.unavailable
                }
                session.addInput(nextInput)
                session.commitConfiguration()
                let path = try nextClipURL()
                fileOutput.startRecording(to: path, recordingDelegate: self)
                Task { @MainActor in
                    cameraPosition = target
                    pendingCameraPosition = nil
                }
            } catch {
                Task { @MainActor in
                    failSwitch(error)
                }
            }
        }
    }

    private func failSwitch(_ error: Error) {
        flow.requestStop(discard: false)
        stopping = true
        pendingCameraPosition = nil
        isSwitching = false
        isRecording = false
        closeSession()
        errorMessage = CaptureBrand.text(
            "Не удалось переключить камеру. Уже снятое видео сохраняется. ",
            "Could not switch camera. Saving video captured so far. "
        ) + error.localizedDescription
        Task { await saveCompletedVideo() }
    }

    private func closeSession() {
        sessionQueue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }

    private func clearTemporaryClips() {
        for clip in clips { try? FileManager.default.removeItem(at: clip) }
        clips.removeAll()
    }

    private func saveCompletedVideo() async {
        guard !isSaving else { return }
        isSaving = true
        isPreparing = false
        defer { isSaving = false }

        guard !clips.isEmpty else {
            if errorMessage == nil {
                errorMessage = CaptureBrand.text(
                    "Видео не записано.", "No video was captured."
                )
            }
            return
        }

        guard let recoveryID else {
            errorMessage = "Missing capture ID — original segments were preserved."
            return
        }
        let destination = recoveryJournal.mergedURL(for: recoveryID)
        // A previous interrupted export can leave a generated partial file.
        // Only the generated combination, never a camera segment, is replaced.
        try? FileManager.default.removeItem(at: destination)
        do {
            let composed = try await VideoSegmentComposer.compose(
                clips, destination: destination
            )
            // Never treat an absent host callback as a successful save:
            // the segments must remain recoverable in that case.
            guard let onSaved else { throw CaptureError.saveHandlerUnavailable }
            try onSaved(composed.url, composed.duration, recoveryID)
            if !hasDamagedSegments {
                // Only now is the movie durably indexed and safe to clean up.
                try? recoveryJournal.removeSavedSession(recoveryID)
                clips.removeAll()
            }
            VideoCaptureJournal.setActive(recoveryID, active: false)
            // Interrupted/corrupt originals stay available for manual salvage.
            didSave = true
        } catch {
            // Keep *all* originals intact if merging or importing failed.
            errorMessage = CaptureBrand.text(
                "Не удалось сохранить видеозаметку: ",
                "Video note could not be saved: "
            ) + error.localizedDescription
        }
    }

    private enum CaptureError: LocalizedError {
        case unavailable, saveHandlerUnavailable
        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "Requested camera or microphone is unavailable"
            case .saveHandlerUnavailable:
                return "Local video storage is not ready"
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
                ZStack(alignment: .topTrailing) {
                    CameraPreview(session: recorder.session)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .accessibilityLabel(CaptureBrand.text("Превью камеры", "Camera preview"))

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        recorder.switchCamera()
                    } label: {
                        Image(systemName: "camera.rotate.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(.black.opacity(0.6), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!recorder.canSwitchCamera || !recorder.isRecording
                              || recorder.isSwitching || recorder.isSaving)
                    .opacity(recorder.canSwitchCamera ? 1 : 0.45)
                    .padding(14)
                    .accessibilityIdentifier("what.video.switchCamera")
                    .accessibilityLabel(
                        recorder.cameraPosition == .back
                            ? CaptureBrand.text("Переключить на фронтальную камеру",
                                                "Switch to front camera")
                            : CaptureBrand.text("Переключить на основную камеру",
                                                "Switch to back camera")
                    )
                    .accessibilityHint(
                        CaptureBrand.text("Переключение ненадолго прерывает запись, но все фрагменты сохраняются в одной видеозаметке.",
                                          "Switching briefly pauses recording; all segments are saved as one note.")
                    )
                }
                if recorder.isSaving {
                    ProgressView(CaptureBrand.text("Сохраняем видеозаметку…",
                                                  "Saving video note…"))
                } else if recorder.isSwitching {
                    ProgressView(CaptureBrand.text("Переключаем камеру…",
                                                  "Switching camera…"))
                } else if let start = recorder.startedAt {
                    HStack {
                        Spacer()
                        Label(
                            recorder.cameraPosition == .back
                                ? CaptureBrand.text("Основная", "Back")
                                : CaptureBrand.text("Фронтальная", "Front"),
                            systemImage: recorder.cameraPosition == .back
                                ? "camera.fill" : "person.crop.square"
                        )
                        .font(.subheadline)
                    }
                    .overlay {
                        TimelineView(.periodic(from: .now, by: 0.5)) { time in
                            Text(duration(time.date.timeIntervalSince(start)))
                                .font(.title2.monospacedDigit())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityLabel(CaptureBrand.text(
                                    "Длительность записи", "Recording duration"))
                        }
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
                .disabled((!recorder.isRecording && !recorder.isSwitching)
                          || recorder.isSaving)
            }
            .padding()
            .navigationTitle(CaptureBrand.text("Видеозаметка", "Video note"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CaptureBrand.text("Отменить", "Discard"), role: .destructive) {
                        if !recorder.isSaving {
                            recorder.finish(discard: true)
                            dismiss()
                        }
                    }
                }
            }
            .interactiveDismissDisabled(recorder.isRecording
                                        || recorder.isSwitching || recorder.isSaving)
            .onAppear { recorder.start() }
            .onChange(of: recorder.didSave) { _, saved in
                if saved { dismiss() }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active && (recorder.isRecording || recorder.isSwitching) {
                    recorder.finish()
                }
            }
            .onDisappear {
                if recorder.isRecording || recorder.isSwitching { recorder.finish() }
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
                recorder.onSaved = { [store] url, duration, id in
                    try store.saveVideo(from: url, duration: duration, id: id)
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
