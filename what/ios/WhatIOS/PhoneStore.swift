import AVFoundation
import Combine
import Foundation
import Speech

@MainActor
final class PhoneStore: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var recordings: [RecordingEnvelope] = []
    @Published private(set) var playingID: UUID?
    @Published private(set) var transcribingID: UUID?
    @Published private(set) var transcripts: [UUID: String] = [:]
    @Published private(set) var archivedIDs = Set<UUID>()
    @Published private(set) var lastWatchQueueSnapshot: WatchQueueSnapshot?
    @Published private(set) var batchTranscriptionActive = false
    @Published var showPhoneCapture = false
    @Published var errorMessage: String?
    @Published var transcriptionLocale = UserDefaults.standard.string(forKey: "what.transcription.locale") ?? "ru-RU" {
        didSet { UserDefaults.standard.set(transcriptionLocale, forKey: "what.transcription.locale") }
    }

    private let repository: RecordingRepository
    private var player: AVAudioPlayer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?
    private var batchIDs: [UUID] = []
    let phoneRecorder = PhoneRecordingController()

    init(repository: RecordingRepository = RecordingRepository()) {
        self.repository = repository
        super.init()
        reload()
        reloadWatchQueueStatus()
        phoneRecorder.onSaved = { [weak self] recording in
            self?.reload()
            self?.transcribeIfAuthorized(recording)
        }
    }

    func reloadWatchQueueStatus() {
        lastWatchQueueSnapshot = PhoneConnectivityManager.shared.lastWatchQueueSnapshot
    }

    func reload() {
        recordings = repository.allRecordings()
        transcripts = repository.transcripts()
        do {
            archivedIDs = try repository.archivedIDs()
        } catch {
            errorMessage = "Could not read the archive: \(error.localizedDescription)"
        }
    }

    func setArchived(_ recording: RecordingEnvelope, archived: Bool) {
        do {
            try repository.setArchived(recording.id, archived: archived)
            archivedIDs = try repository.archivedIDs()
        } catch {
            errorMessage = "Could not update the archive: \(error.localizedDescription)"
        }
    }

    func delete(_ recording: RecordingEnvelope) {
        if playingID == recording.id {
            player?.stop()
            player = nil
            playingID = nil
        }
        if transcribingID == recording.id {
            cancelTranscription()
        }

        do {
            try repository.deleteRecording(recording.id)
            reload()
        } catch {
            reload()
            errorMessage = "Recording deletion was not completed: \(error.localizedDescription)"
        }
    }

    /// Received Watch audio is immediately indexed if iOS Speech permission
    /// was already granted; never silently prompt for permission from a background
    /// WatchConnectivity callback.
    func receivedRecording(_ recordingID: UUID?) {
        reload()
        guard let recordingID,
              let recording = recordings.first(where: { $0.id == recordingID })
        else { return }
        transcribeIfAuthorized(recording)
    }

    private func transcribeIfAuthorized(_ recording: RecordingEnvelope) {
        guard transcripts[recording.id] == nil,
              SFSpeechRecognizer.authorizationStatus() == .authorized else { return }
        if transcribingID != nil {
            if !batchIDs.contains(recording.id) {
                batchIDs.append(recording.id)
                batchTranscriptionActive = true
            }
        } else {
            transcribe(recording)
        }
    }

    func transcribeMissing() {
        guard transcribingID == nil && !batchTranscriptionActive else { return }
        batchIDs = recordings
            .filter { transcripts[$0.id] == nil && repository.audioExists(for: $0) }
            .sorted { $0.createdAt < $1.createdAt }
            .map(\.id)
        batchTranscriptionActive = !batchIDs.isEmpty
        transcribeNextInBatch()
    }

    private func transcribeNextInBatch() {
        guard transcribingID == nil else { return }
        while !batchIDs.isEmpty {
            let id = batchIDs.removeFirst()
            if transcripts[id] != nil { continue }
            if let recording = recordings.first(where: { $0.id == id }),
               repository.audioExists(for: recording) {
                transcribe(recording)
                return
            }
        }
        batchTranscriptionActive = false
    }

    private func finishTranscription() {
        transcribingID = nil
        recognitionTask = nil
        recognizer = nil
        if batchTranscriptionActive { transcribeNextInBatch() }
    }

    func cancelTranscription() {
        batchIDs.removeAll()
        batchTranscriptionActive = false
        // Clear the active ID first so late authorization / result callbacks
        // cannot overwrite a manually corrected transcript.
        transcribingID = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        recognizer = nil
    }

    func updateTranscript(_ text: String, for recording: RecordingEnvelope) throws {
        if transcribingID == recording.id {
            cancelTranscription()
        }
        try repository.updateTranscript(text, for: recording.id)
        transcripts[recording.id] = text
    }

    func prepareExport(
        _ recording: RecordingEnvelope,
        selection: RecordingExportSelection
    ) -> PreparedRecordingExport? {
        do {
            return try RecordingExportService.prepare(
                recording: recording,
                audioURL: repository.audioURL(for: recording),
                transcript: transcripts[recording.id],
                selection: selection
            )
        } catch {
            errorMessage = "Unable to prepare the export: \(error.localizedDescription)"
            return nil
        }
    }

    func isAudioAvailable(_ recording: RecordingEnvelope) -> Bool {
        repository.audioExists(for: recording)
    }

    func isAudioComplete(_ recording: RecordingEnvelope) -> Bool {
        guard repository.audioExists(for: recording),
              let player = try? AVAudioPlayer(contentsOf: repository.audioURL(for: recording))
        else { return false }
        return (try? PhoneCaptureValidation.validate(
            actualDuration: player.duration,
            elapsedTime: recording.duration
        )) != nil
    }

    func beginPhoneCapture() {
        player?.stop()
        player = nil
        playingID = nil
        // Do not reconfigure the shared audio session while an old recognition
        // or playback operation is still using it.
        if transcribingID != nil { cancelTranscription() }
        showPhoneCapture = true
    }

    func togglePlayback(_ recording: RecordingEnvelope) {
        if playingID == recording.id {
            player?.stop()
            player = nil
            playingID = nil
            return
        }
        player?.stop()
        playingID = nil
        player = nil
        guard repository.audioExists(for: recording) else {
            errorMessage = "The audio file is missing. Keep the recording on your Watch until it can be transferred again."
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let audioPlayer = try AVAudioPlayer(contentsOf: repository.audioURL(for: recording))
            audioPlayer.delegate = self
            guard audioPlayer.prepareToPlay(), audioPlayer.play() else {
                errorMessage = "Audio playback could not start."
                return
            }
            player = audioPlayer
            playingID = recording.id
        } catch {
            errorMessage = "Audio could not be played: \(error.localizedDescription)"
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playingID = nil
        self.player = nil
        if !flag { errorMessage = "Audio playback ended unexpectedly." }
    }

    func transcribe(_ recording: RecordingEnvelope) {
        guard transcribingID == nil else { return }
        guard transcripts[recording.id] == nil || !batchTranscriptionActive else {
            return
        }
        guard repository.audioExists(for: recording) else {
            errorMessage = "The audio file is missing. Transcription is unavailable."
            return
        }
        guard isAudioComplete(recording) else {
            errorMessage = "Audio is incomplete: the microphone did not capture the full recording. Please record it again."
            if batchTranscriptionActive { transcribeNextInBatch() }
            return
        }
        // A valid-looking AAC file can contain entirely zeroed microphone
        // buffers (observed after iPhone Mirroring). Never send such files to
        // Speech: it can only return "No speech detected".
        guard (try? PhoneCaptureValidation.validateFileHasSound(
            repository.audioURL(for: recording)
        )) != nil else {
            errorMessage = "This recording contains no microphone sound. Restart the iPhone if needed and record again; speech recognition cannot recover missing audio."
            if batchTranscriptionActive { transcribeNextInBatch() }
            return
        }
        transcribingID = recording.id
        SFSpeechRecognizer.requestAuthorization { [weak self] authorization in
            Task { @MainActor [weak self] in
                // Authorization can return after cancellation or deletion.
                guard let self, self.transcribingID == recording.id else { return }
                guard authorization == .authorized else {
                    self.batchIDs.removeAll()
                    self.batchTranscriptionActive = false
                    self.finishTranscription()
                    self.errorMessage = "Allow Speech Recognition in Settings to transcribe on this iPhone."
                    return
                }
                self.beginTranscription(recording)
            }
        }
    }

    private func beginTranscription(_ recording: RecordingEnvelope) {
        guard transcribingID == recording.id else { return }
        // Only on-device recognition: never silently upload private recordings.
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: transcriptionLocale)),
              recognizer.supportsOnDeviceRecognition,
              recognizer.isAvailable else {
            batchIDs.removeAll()
            batchTranscriptionActive = false
            finishTranscription()
            errorMessage = "On-device speech recognition is unavailable for the selected language. Choose another language or check installed speech recognition support in iOS Settings."
            return
        }
        self.recognizer = recognizer
        let request = SFSpeechURLRecognitionRequest(url: repository.audioURL(for: recording))
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self, self.transcribingID == recording.id else { return }
                if let result, result.isFinal {
                    let text = result.bestTranscription.formattedString
                    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        self.errorMessage = "Speech was not detected. Try another recording or language."
                        self.finishTranscription()
                        return
                    }
                    do {
                        try self.repository.saveTranscript(text, for: recording.id)
                        self.transcripts[recording.id] = text
                    } catch {
                        self.errorMessage = "Transcription completed, but saving the text failed."
                    }
                    self.finishTranscription()
                } else if let error {
                    self.finishTranscription()
                    self.errorMessage = "Transcription failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
