import Foundation

/// Validates finalized Apple Watch audio before reporting durable success.
/// Wall-clock timer alone is NOT evidence of recorded audio frames.
enum WatchCaptureValidation {
    static func isPlausibleAudio(
        bytes: Int,
        decodedDuration: TimeInterval,
        expectedDuration: TimeInterval
    ) -> Bool {
        guard bytes >= 512,
              decodedDuration.isFinite,
              decodedDuration >= 0.35,
              expectedDuration.isFinite,
              expectedDuration >= 0 else { return false }
        // The decoded track must represent most of the time shown on screen.
        return expectedDuration <= 0.5 ||
            decodedDuration >= expectedDuration * 0.65
    }
}
