import AVFoundation
import Foundation

/// A transport ACK must mean that a decodable recording is saved, not just
/// that arbitrary bytes with a valid UUID have reached the iPhone.
enum WatchDeliveredAudioValidation {
    enum Failure: Error { case unreadableAudio }

    @discardableResult
    static func validate(_ url: URL, expectedDuration: TimeInterval) throws -> TimeInterval {
        let bytes = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard let player = try? AVAudioPlayer(contentsOf: url),
              WatchCaptureValidation.isPlausibleAudio(
                bytes: bytes, decodedDuration: player.duration,
                expectedDuration: expectedDuration
              ) else {
            throw Failure.unreadableAudio
        }
        return player.duration
    }
}
