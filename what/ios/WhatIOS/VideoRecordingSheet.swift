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
    // Preserve enough background execution time for AVCaptureMovieFileOutput
    // to finalize its current MOV and the repository to durably commit it.
    private var backgroundSaveTask: UIBackgroundTaskIdentifier = .invalid
    private var backgroundSaveRequested = false
    private var foregroundRecoveryInFlight = false
    private nonisolated(unsafe) let recoveryJournal = VideoCaptureJournal()
    private nonisolated(unsafe) var recoveryID: UUID?
    // Advanced only on the camera's serial session queue.
    private nonisolated(unsafe) var nextSegmentNumber = 0

    var onSaved: ((URL, TimeInterval, UUID) throws -> Void)?
    var onRecoverAfterBackground: ((UUID, Int) async -> Bool)?

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

    #if REVIEW_HANDOFF_QA
    /// Read-only AVFoundation liveness snapshot on the capture serial queue.
    /// Logical SwiftUI isRecording can remain true if a device stops its
    /// writer without delivering the expected callback.
    func qaRecordingTransport() async -> String {
        await withCheckedContinuation { (continuation: CheckedContinuation<String, Never>) in
            sessionQueue.async { [self] in
                let clipIndex = max(0, nextSegmentNumber - 1)
                let fileBytes: Int64
                if let id = recoveryID, nextSegmentNumber > 0 {
                    let url = recoveryJournal.segmentURL(for: id, index: clipIndex)
                    fileBytes = (try? url.resourceValues(
                        forKeys: [.fileSizeKey]
                    ))?.fileSize.map(Int64.init) ?? -1
                } else {
                    fileBytes = -1
                }
                continuation.resume(returning:
                    "sessionRunning=\(session.isRunning) "
                    + "writerRecording=\(fileOutput.isRecording) "
                    + "clipIndex=\(clipIndex) fileSizeBytes=\(fileBytes)"
                )
            }
        }
    }
    #endif

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

    /// Inactive precedes Background. Claim a finite iOS background task *before*
    /// requesting AVFoundation's asynchronous stop callback and file import.
    /// Never allow recording video indefinitely behind other apps.
    func finishForBackground(includePreparing: Bool = false) {
        // A camera/microphone permission sheet temporarily makes the scene
        // inactive: do NOT cancel the very first capture while awaiting Allow.
        // Only a real .background transition may stop a preparing camera.
        guard isRecording || isSwitching || isSaving
              || (includePreparing && isPreparing) else { return }
        backgroundSaveRequested = true
        if backgroundSaveTask == .invalid {
            backgroundSaveTask = UIApplication.shared.beginBackgroundTask(
                withName: "UhWhat finalize video capture"
            ) { [weak self] in
                Task { @MainActor [weak self] in
                    // On expiration keep the source journal intact: launch
                    // recovery can handle a finalized but unindexed segment.
                    self?.endBackgroundSaveTask()
                }
            }
        }
        if !isSaving { finish() }
    }

    /// AVFoundation may have stopped its file writer during suspension without
    /// delivering didFinishRecordingTo. Only after the session queue confirms
    /// no writer remains may launch-style recovery inspect these sources.
    func recoverWhenForegrounded() async {
        guard backgroundSaveRequested, !foregroundRecoveryInFlight, !didSave,
              let id = recoveryID else { return }
        foregroundRecoveryInFlight = true
        defer { foregroundRecoveryInFlight = false }
        // Prefer the genuine AVCaptureFileOutput callback over a fallback.
        for _ in 0..<12 {
            if didSave { return }
            if isSaving {
                try? await Task.sleep(nanoseconds: 500_000_000)
                continue
            }
            let recording = await withCheckedContinuation { continuation in
                sessionQueue.async { [self] in
                    let wasRecording = fileOutput.isRecording
                    if wasRecording { fileOutput.stopRecording() }
                    continuation.resume(returning: wasRecording)
                }
            }
            if !recording {
                // Some iOS versions finish the file but suppress the delegate
                // after a background interruption. Give that callback priority.
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if didSave { return }
                if isSaving { continue }
                let stillRecording = await withCheckedContinuation { continuation in
                    sessionQueue.async { [self] in
                        continuation.resume(returning: fileOutput.isRecording)
                    }
                }
                guard !stillRecording else { continue }
                closeSession()
                VideoCaptureJournal.setActive(id, active: false)
                let expectedSegments = await withCheckedContinuation { continuation in
                    sessionQueue.async { [self] in
                        continuation.resume(returning: nextSegmentNumber)
                    }
                }
                let recovered = await onRecoverAfterBackground?(id, expectedSegments) ?? false
                if recovered {
                    didSave = true
                    endBackgroundSaveTask()
                } else {
                    errorMessage = CaptureBrand.text(
                        "Не удалось сразу восстановить видеозапись после сворачивания. Исходный файл сохранён для повторной попытки.",
                        "Could not immediately recover background video. Original file remains available for retry."
                    )
                    endBackgroundSaveTask()
                }
                return
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        // Still writing? Never read an in-flight MOV as if it were finished.
    }

    private func endBackgroundSaveTask() {
        let identifier = backgroundSaveTask
        backgroundSaveTask = .invalid
        if identifier != .invalid {
            UIApplication.shared.endBackgroundTask(identifier)
        }
    }

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
            if didSave { return } // already recovered by foreground fallback
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
                endBackgroundSaveTask()
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
        defer {
            isSaving = false
            endBackgroundSaveTask()
        }

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
        // A switch may have started the next segment before a background
        // Stop invokes a stale didFinish callback from the previous segment.
        // In that case `clips` is a playable prefix while the last original
        // MOV is still being finalized. Never commit it as the complete note.
        let state = await withCheckedContinuation { continuation in
            sessionQueue.async { [self] in
                continuation.resume(returning: (
                    started: nextSegmentNumber,
                    recording: fileOutput.isRecording
                ))
            }
        }
        guard VideoCaptureFinalizationGate.canCompose(
            startedSegments: state.started, finalizedSegments: clips.count,
            writerIsRecording: state.recording
        ) else {
            errorMessage = CaptureBrand.text(
                "Последний фрагмент видео ещё сохраняется. Исходные файлы оставлены для восстановления.",
                "The final video segment has not finished writing. Original files are preserved for recovery."
            )
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
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    VStack(spacing: 16) {
                        ZStack(alignment: .topTrailing) {
                            CameraPreview(session: recorder.session)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        // The preview is its own accessibility element; an ID
                        // on the enclosing ZStack can hide the camera switch
                        // button from VoiceOver and physical XCTest queries.
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(CaptureBrand.text("Превью камеры", "Camera preview"))
                        .accessibilityIdentifier("what.video.preview")

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
                        .frame(
                            height: min(660, max(180, geometry.size.height * 0.62))
                        )
                        .accessibilityElement(children: .contain)
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
                    .frame(maxWidth: 900)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
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
                if phase != .active {
                    recorder.finishForBackground(includePreparing: phase == .background)
                } else {
                    Task { await recorder.recoverWhenForegrounded() }
                }
            }
            .onDisappear {
                if recorder.isRecording || recorder.isSwitching { recorder.finish() }
            }
            .alert(CaptureBrand.text("Видеозапись", "Video capture"),
                   isPresented: Binding(
                       get: { recorder.errorMessage != nil },
                       set: { _ in /* OK handles dismissal; avoid publishing during SwiftUI updates. */ }
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
                .frame(maxWidth: 1080)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                recorder.onRecoverAfterBackground = { [store] id, expectedSegments in
                    await store.recoverInterruptedVideos(
                        requireCompleteSegments: true,
                        expectedSegmentCount: expectedSegments
                    )
                    // A partial note is NOT proof of complete recovery. The
                    // journal must be cleaned before dismissing this sheet.
                    let stillPending = (try? VideoCaptureJournal().pendingSessions())?
                        .contains(where: { $0.id == id }) ?? true
                    return !stillPending && store.localNotes.contains {
                        $0.id == id && $0.kind == .video
                    }
                }
#if REVIEW_HANDOFF_QA
                PhysicalCaptureQAProbe.shared.attachVideoRecorderIfRequested(recorder)
#endif
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
