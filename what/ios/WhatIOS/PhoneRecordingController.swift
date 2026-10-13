import AVFoundation
import Combine
import Foundation

/// iPhone captures are written under Application Support before being imported.
/// Uncommitted audio is never erased on a failed repository write.
@MainActor
final class PhoneRecordingController: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published private(set) var isRecording = false
    @Published private(set) var requestingPermission = false
    @Published private(set) var startedAt: Date?
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
    private var recorder: AVAudioRecorder?
    private var pending: Pending?
    private var startGeneration = UUID()
    private var interruptionObserver: NSObjectProtocol?

    init(repository: RecordingRepository = RecordingRepository(),
         fileManager: FileManager = .default) {
        self.repository = repository
        files = fileManager
        let base = fileManager.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        directory = base.appendingPathComponent("What/PhoneCaptures", isDirectory: true)
        super.init()
        try? files.createDirectory(at: directory, withIntermediateDirectories: true)
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
        guard !isRecording && recorder == nil && !requestingPermission else { return }
        let generation = UUID()
        startGeneration = generation
        let application = AVAudioApplication.shared
        switch application.recordPermission {
        case .granted:
            begin()
        case .denied:
            errorMessage = "Enable microphone access to What? in iPhone Settings."
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

    nonisolated func audioRecorderDidFinishRecording(
        _ recorder: AVAudioRecorder, successfully flag: Bool
    ) {
        Task { @MainActor [weak self] in
            guard let self, self.recorder === recorder, self.isRecording else {
                return
            }
            self.handleCaptureInterruption()
        }
    }

    private func begin() {
        guard recorder == nil && !isRecording else { return }
        let item = Pending(
            id: UUID(), createdAt: Date(), expectedElapsed: nil
        )
        let url = audioURL(for: item.id)
        do {
            let session = AVAudioSession.sharedInstance()
            // Capture-only session avoids output route changes and competing
            // playback configuration while a new microphone recording begins.
            try session.setCategory(.record, mode: .default)
            try session.setPreferredSampleRate(44_100)
            try session.setActive(true)
            guard session.isInputAvailable else {
                throw NSError(
                    domain: "What.PhoneCapture", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "No microphone input is available."]
                )
            }
            try files.createDirectory(at: directory, withIntermediateDirectories: true)
            try JSONEncoder().encode(item).write(
                to: metadataURL(for: item.id), options: .atomic
            )
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: session.sampleRate,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            let next = try AVAudioRecorder(url: url, settings: settings)
            next.delegate = self
            guard next.prepareToRecord(), next.record(), next.isRecording else {
                throw CocoaError(.fileWriteUnknown)
            }
            recorder = next
            pending = item
            isRecording = true
            startedAt = item.createdAt
        } catch {
            errorMessage = "Could not start recording: \(error.localizedDescription)"
            try? files.removeItem(at: metadataURL(for: item.id))
            if files.fileExists(atPath: url.path) {
                // Only a failed and never-started file may be discarded here.
                try? files.removeItem(at: url)
            }
        }
    }

    @discardableResult
    func finish() -> RecordingEnvelope? {
        guard let recorder, let item = pending else { return nil }
        let elapsed = max(0, Date().timeIntervalSince(item.createdAt))
        recorder.delegate = nil
        recorder.stop()
        self.recorder = nil
        pending = nil
        isRecording = false
        startedAt = nil
        try? AVAudioSession.sharedInstance().setActive(false)

        let url = audioURL(for: item.id)
        do {
            // Persist expected capture length even if validation/import fails.
            // Recovery must not import a half-second fragment as a six-second
            // recording merely because the audio file is decodable.
            let completed = Pending(
                id: item.id, createdAt: item.createdAt,
                expectedElapsed: elapsed
            )
            try JSONEncoder().encode(completed).write(
                to: metadataURL(for: item.id), options: .atomic
            )
            guard files.fileExists(atPath: url.path),
                  let player = try? AVAudioPlayer(contentsOf: url)
            else {
                throw PhoneCaptureValidation.CaptureError.unreadable
            }
            let measured = player.duration
            try PhoneCaptureValidation.validate(
                actualDuration: measured,
                elapsedTime: elapsed
            )
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
            // Keep staging file + manifest for recovery; no destructive cleanup.
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
        recorder?.delegate = nil
        recorder?.stop()
        recorder = nil
        pending = nil
        isRecording = false
        startedAt = nil
        try? AVAudioSession.sharedInstance().setActive(false)
        try? files.removeItem(at: audioURL(for: item.id))
        try? files.removeItem(at: metadataURL(for: item.id))
    }

    private func recoverCompletedCaptures() {
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
            if let elapsed = item.expectedElapsed {
                guard (try? PhoneCaptureValidation.validate(
                    actualDuration: player.duration,
                    elapsedTime: elapsed
                )) != nil else { continue }
            }
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
