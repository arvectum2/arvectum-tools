import AVFoundation
import Combine
import Foundation

@MainActor
final class PhoneStore: ObservableObject {
    @Published private(set) var recordings: [RecordingEnvelope] = []

    private let repository: RecordingRepository
    private var player: AVAudioPlayer?

    init(repository: RecordingRepository = RecordingRepository()) {
        self.repository = repository
        reload()
    }

    func reload() {
        recordings = repository.allRecordings()
    }

    func play(_ recording: RecordingEnvelope) {
        do {
            player = try AVAudioPlayer(contentsOf: repository.audioURL(for: recording))
            player?.prepareToPlay()
            player?.play()
        } catch {
            player = nil
        }
    }
}
