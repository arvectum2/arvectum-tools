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
    @Published var errorMessage: String?

    private let repository: RecordingRepository
    private var player: AVAudioPlayer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?

    init(repository: RecordingRepository = RecordingRepository()) {
        self.repository = repository
        super.init()
        reload()
    }

    func reload() {
        recordings = repository.allRecordings()
        transcripts = repository.transcripts()
    }

    func isAudioAvailable(_ recording: RecordingEnvelope) -> Bool {
        repository.audioExists(for: recording)
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
        guard repository.audioExists(for: recording) else {
            errorMessage = "The audio file is missing. Transcription is unavailable."
            return
        }
        transcribingID = recording.id
        SFSpeechRecognizer.requestAuthorization { [weak self] authorization in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard authorization == .authorized else {
                    self.transcribingID = nil
                    self.errorMessage = "Allow Speech Recognition in Settings to transcribe on this iPhone."
                    return
                }
                self.beginTranscription(recording)
            }
        }
    }

    private func beginTranscription(_ recording: RecordingEnvelope) {
        // Only on-device recognition: never silently upload private recordings.
        let recognizer = SFSpeechRecognizer(locale: Locale.current)
            ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard let recognizer, recognizer.supportsOnDeviceRecognition else {
            transcribingID = nil
            errorMessage = "On-device speech recognition is unavailable for this language."
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
                    do {
                        try self.repository.saveTranscript(text, for: recording.id)
                        self.transcripts[recording.id] = text
                    } catch {
                        self.errorMessage = "Transcription completed, but saving the text failed."
                    }
                    self.transcribingID = nil
                    self.recognitionTask = nil
                    self.recognizer = nil
                } else if let error {
                    self.transcribingID = nil
                    self.recognitionTask = nil
                    self.recognizer = nil
                    self.errorMessage = "Transcription failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
