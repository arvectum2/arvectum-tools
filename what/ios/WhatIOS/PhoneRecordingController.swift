import AVFoundation
import Combine
import Foundation

/// iPhone captures are written under Application Support before being imported.
/// Uncommitted audio is never erased on a failed repository write.
@MainActor
final class PhoneRecordingController: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var requestingPermission = false
    @Published private(set) var startedAt: Date?
    @Published private(set) var microphoneConnected = false
    @Published private(set) var hasDetectedSignal = false
    @Published private(set) var microphoneRoute = "Checking microphone…"
    @Published var errorMessage: String?

    var onSaved: ((RecordingEnvelope) -> Void)?

    private struct Pending: Codable {
        let id: UUID
        let createdAt: Date
        /// Wall time measured when Stop was tapped; used during crash recovery
        /// to avoid resurrecting an AAC file whose mic stopped recording.
        let expectedElapsed: TimeInterval?
    }

    private let directory: URL
    private let repository: RecordingRepository
    private let files: FileManager
    private let captureStorage: PhoneCaptureStorage
    private var engine: AVAudioEngine?
    private var pipeline: MicrophoneCapturePipeline?
    private var pending: Pending?
    private var startGeneration = UUID()
    private var captureRequestedAt: TimeInterval?
    private var readinessLogged = false
    private var interruptionObserver: NSObjectProtocol?

    init(repository: RecordingRepository = RecordingRepository(),
         fileManager: FileManager = .default,
         captureDirectory: URL? = nil) {
        self.repository = repository
        files = fileManager
        let base = fileManager.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        directory = captureDirectory
            ?? base.appendingPathComponent("What/PhoneCaptures", isDirectory: true)
        captureStorage = PhoneCaptureStorage(directory: directory, files: fileManager)
        super.init()
        recoverCompletedCaptures()
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let kind = notification.userInfo?[
                AVAudioSessionInterruptionTypeKey
            ] as? UInt,
                  kind == AVAudioSession.InterruptionType.began.rawValue else {
                return
            }
            Task { @MainActor [weak self] in
                self?.handleCaptureInterruption()
            }
        }
    }

    private func audioURL(for id: UUID) -> URL {
        directory.appendingPathComponent(id.uuidString + ".m4a")
    }

    private func metadataURL(for id: UUID) -> URL {
        directory.appendingPathComponent(id.uuidString + ".json")
    }

    func start() {
        guard !isRecording && engine == nil && !requestingPermission else { return }
        let generation = UUID()
        startGeneration = generation
        captureRequestedAt = ProcessInfo.processInfo.systemUptime
        readinessLogged = false
        let application = AVAudioApplication.shared
        switch application.recordPermission {
        case .granted:
            begin()
        case .denied:
            errorMessage = CaptureBrand.text("Разрешите Ухвату доступ к микрофону в настройках iPhone.", "Enable microphone access to UhWhat? in iPhone Settings.")
        case .undetermined:
            requestingPermission = true
            AVAudioApplication.requestRecordPermission { [weak self] allowed in
                Task { @MainActor [weak self] in
                    guard let self,
                          self.startGeneration == generation else { return }
                    self.requestingPermission = false
                    if allowed {
                        self.begin()
                    } else {
                        self.errorMessage = "Microphone access was not granted."
                    }
                }
            }
        @unknown default:
            errorMessage = "Microphone permission is unavailable."
        }
    }

    deinit {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
    }

    private func handleCaptureInterruption() {
        guard isRecording else { return }
        let didSave = finish() != nil
        errorMessage = didSave
            ? "Microphone was interrupted. The captured part was saved."
            : "Microphone was interrupted before usable audio was captured. Try recording again."
    }

    private func begin() {
        guard engine == nil && !isRecording else { return }
        let item = Pending(id: UUID(), createdAt: Date(), expectedElapsed: nil)
        let url = audioURL(for: item.id)
        do {
            // Never start the microphone if older recovery copies cannot
            // be protected. Their contents must survive unchanged.
            try captureStorage.prepare()
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
            if let builtIn = session.availableInputs?.first(where: {
                $0.portType == .builtInMic
            }) {
                // Prefer the actual iPhone microphone over connected
                // Bluetooth/USB/Continuity input devices when available.
                try session.setPreferredInput(builtIn)
            }
            microphoneRoute = session.currentRoute.inputs
                .map { $0.portName }.joined(separator: ", ")
            if microphoneRoute.isEmpty {
                microphoneRoute = "No active input route"
            }
            guard session.isInputAvailable else {
                throw NSError(
                    domain: "What.Microphone", code: 1,
                    userInfo: [NSLocalizedDescriptionKey:
                        "No microphone input is available on this iPhone."]
                )
            }
            let nextEngine = AVAudioEngine()
            let input = nextEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.channelCount > 0 && format.sampleRate > 0 else {
                throw NSError(
                    domain: "What.Microphone", code: 3,
                    userInfo: [NSLocalizedDescriptionKey:
                        "iOS microphone returned no active audio channels."]
                )
            }
            try captureStorage.writeManifest(item, to: metadataURL(for: item.id))
            let nextPipeline = try MicrophoneCapturePipeline(
                url: url, inputFormat: format
            )
            do {
                try captureStorage.protectAudioBeforeRecording(url)
            } catch {
                _ = nextPipeline.close()
                throw error
            }
            input.installTap(onBus: 0, bufferSize: 1_024, format: format) {
                [weak nextPipeline] buffer, _ in
                nextPipeline?.append(buffer)
            }
            do {
                try nextEngine.start()
            } catch {
                input.removeTap(onBus: 0)
                _ = nextPipeline.close()
                throw error
            }
            engine = nextEngine
            pipeline = nextPipeline
            pending = item
            isRecording = true
            startedAt = item.createdAt
            microphoneConnected = false
            hasDetectedSignal = false
        } catch {
            errorMessage = "Microphone could not start: \(error.localizedDescription)"
            try? files.removeItem(at: metadataURL(for: item.id))
            try? files.removeItem(at: url)
            engine = nil
            pipeline = nil
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }

    func refreshMicrophoneStatus() {
        guard isRecording, let pipeline else { return }
        let status = pipeline.status
        if status.framesWritten > 0 {
            microphoneConnected = true
            noteFirstMicrophoneBuffer(status)
        }
        if status.hasInputSignal {
            hasDetectedSignal = true
        }
        if let error = status.writeError {
            errorMessage = "Audio capture stopped: \(error.localizedDescription)"
        }
    }

    private func noteFirstMicrophoneBuffer(_ status: MicrophoneCapturePipeline.Status) {
        guard !readinessLogged,
              let request = captureRequestedAt,
              let firstFrame = status.firstFrameUptime else { return }
        readinessLogged = true
        CaptureLatency.record(startedAt: request, source: "iphone",
                              now: firstFrame)
    }

    @discardableResult
    func finish() -> RecordingEnvelope? {
        guard let engine, let pipeline, let item = pending else { return nil }
        let elapsed = max(0, Date().timeIntervalSince(item.createdAt))
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        self.engine = nil
        self.pipeline = nil
        let status = pipeline.close()
        noteFirstMicrophoneBuffer(status)
        pending = nil
        isRecording = false
        startedAt = nil
        microphoneConnected = false
        hasDetectedSignal = false
        try? AVAudioSession.sharedInstance().setActive(false)

        let url = audioURL(for: item.id)
        do {
            let completed = Pending(
                id: item.id, createdAt: item.createdAt,
                expectedElapsed: elapsed
            )
            try captureStorage.writeManifest(
                completed, to: metadataURL(for: item.id)
            )
            if let error = status.writeError { throw error }
            try PhoneCaptureValidation.validate(
                actualDuration: status.audioSeconds, elapsedTime: elapsed
            )
            try PhoneCaptureValidation.validateSignal(
                peak: status.peak, audibleFrames: status.audibleFrames
            )
            guard files.fileExists(atPath: url.path),
                  let player = try? AVAudioPlayer(contentsOf: url)
            else {
                throw PhoneCaptureValidation.CaptureError.unreadable
            }
            let measured = player.duration
            try PhoneCaptureValidation.validate(
                actualDuration: measured, elapsedTime: elapsed
            )
            try PhoneCaptureValidation.validateFileHasSound(url)
            let accepted = try repository.acceptTemporaryFile(url, metadata: [
                TransferMetadataKey.id: item.id.uuidString,
                TransferMetadataKey.createdAt: item.createdAt.timeIntervalSince1970,
                TransferMetadataKey.duration: measured
            ])
            guard case let .stored(saved) = accepted else { return nil }
            try? files.removeItem(at: url)
            try? files.removeItem(at: metadataURL(for: item.id))
            onSaved?(saved)
            return saved
        } catch {
            errorMessage = "Recording was not saved: \(error.localizedDescription) A recovery copy is kept on this iPhone."
            return nil
        }
    }

    func cancelPendingStart() {
        startGeneration = UUID()
        requestingPermission = false
    }

    func discard() {
        cancelPendingStart()
        guard let item = pending else { return }
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        _ = pipeline?.close()
        engine = nil
        pipeline = nil
        pending = nil
        isRecording = false
        startedAt = nil
        microphoneConnected = false
        hasDetectedSignal = false
        try? AVAudioSession.sharedInstance().setActive(false)
        try? files.removeItem(at: audioURL(for: item.id))
        try? files.removeItem(at: metadataURL(for: item.id))
    }

    private func recoverCompletedCaptures() {
        // A failed upgrade blocks automated recovery; retry next launch.
        // Never silently import or delete an unprotected legacy source.
        do {
            try captureStorage.prepare()
        } catch {
            errorMessage = "Cannot secure recovery recordings: \(error.localizedDescription)"
            return
        }
        let manifests = (try? files.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        ))?.filter { $0.pathExtension == "json" } ?? []
        for manifest in manifests {
            guard let data = try? Data(contentsOf: manifest),
                  let item = try? JSONDecoder().decode(Pending.self, from: data)
            else { continue }
            let url = audioURL(for: item.id)
            guard files.fileExists(atPath: url.path),
                  let player = try? AVAudioPlayer(contentsOf: url),
                  player.duration >= PhoneCaptureValidation.minimumAudioDuration else {
                continue
            }
            // A process kill can leave expectedElapsed unset. Never import
            // a silent AAC file as a successful recording in that path.
            guard (try? PhoneCaptureValidation.validateRecoveredFile(
                url, actualDuration: player.duration,
                expectedElapsed: item.expectedElapsed
            )) != nil else { continue }
            do {
                let saved = try repository.acceptTemporaryFile(url, metadata: [
                    TransferMetadataKey.id: item.id.uuidString,
                    TransferMetadataKey.createdAt: item.createdAt.timeIntervalSince1970,
                    TransferMetadataKey.duration: player.duration
                ])
                if case .stored = saved {
                    try? files.removeItem(at: url)
                    try? files.removeItem(at: manifest)
                }
            } catch {
                // Retry on next app launch; source remains intact.
            }
        }
    }
}
