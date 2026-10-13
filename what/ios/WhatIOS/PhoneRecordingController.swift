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
    @Published var errorMessage: String?

    var onSaved: ((RecordingEnvelope) -> Void)?

    private struct Pending: Codable {
        let id: UUID
        let createdAt: Date
    }

    private let directory: URL
    private let repository: RecordingRepository
    private let files: FileManager
    private var recorder: AVAudioRecorder?
    private var pending: Pending?
    private var startGeneration = UUID()

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

    private func begin() {
        guard recorder == nil && !isRecording else { return }
        let item = Pending(id: UUID(), createdAt: Date())
        let url = audioURL(for: item.id)
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord, mode: .default, options: [.defaultToSpeaker]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            try files.createDirectory(at: directory, withIntermediateDirectories: true)
            try JSONEncoder().encode(item).write(
                to: metadataURL(for: item.id), options: .atomic
            )
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 16_000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            let next = try AVAudioRecorder(url: url, settings: settings)
            guard next.prepareToRecord(), next.record() else {
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
        let duration = max(0, recorder.currentTime)
        recorder.stop()
        self.recorder = nil
        pending = nil
        isRecording = false
        startedAt = nil
        try? AVAudioSession.sharedInstance().setActive(false)

        let url = audioURL(for: item.id)
        do {
            guard duration > 0.1, files.fileExists(atPath: url.path) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            let accepted = try repository.acceptTemporaryFile(url, metadata: [
                TransferMetadataKey.id: item.id.uuidString,
                TransferMetadataKey.createdAt: item.createdAt.timeIntervalSince1970,
                TransferMetadataKey.duration: duration
            ])
            guard case let .stored(saved) = accepted else { return nil }
            try? files.removeItem(at: url)
            try? files.removeItem(at: metadataURL(for: item.id))
            onSaved?(saved)
            return saved
        } catch {
            // Keep staging file + manifest for recovery; no destructive cleanup.
            errorMessage = "Recording could not be saved yet. Its local recovery copy was kept: \(error.localizedDescription)"
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
                  player.duration > 0.1 else { continue }
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
