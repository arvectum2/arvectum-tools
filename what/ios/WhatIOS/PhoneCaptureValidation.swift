import Foundation

/// Time shown by the iOS recorder UI is wall-clock time and is NOT proof
/// that audio frames have been encoded. Reject the empty/tiny AAC file case.
enum PhoneCaptureValidation {
    static let minimumAudioDuration: TimeInterval = 0.5
    static let minimumElapsedRatio = 0.65

    enum CaptureError: LocalizedError {
        case unreadable
        case incomplete

        var errorDescription: String? {
            switch self {
            case .unreadable:
                return "The iPhone did not produce a readable audio file. Please try again."
            case .incomplete:
                return "The microphone stopped capturing audio unexpectedly. Please retry."
            }
        }
    }

    static func validate(
        actualDuration: TimeInterval,
        elapsedTime: TimeInterval
    ) throws {
        guard actualDuration.isFinite, elapsedTime.isFinite,
              actualDuration >= minimumAudioDuration,
              elapsedTime > 0,
              actualDuration / elapsedTime >= minimumElapsedRatio else {
            throw CaptureError.incomplete
        }
    }
}
