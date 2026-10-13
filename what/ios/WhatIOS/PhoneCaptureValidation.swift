import Foundation
import AVFoundation

/// Time shown by the iOS recorder UI is wall-clock time and is NOT proof
/// that audio frames have been encoded. Reject the empty/tiny AAC file case.
enum PhoneCaptureValidation {
    static let minimumAudioDuration: TimeInterval = 0.5
    static let minimumElapsedRatio = 0.65

    enum CaptureError: LocalizedError {
        case unreadable
        case incomplete
        case silentInput

        var errorDescription: String? {
            switch self {
            case .unreadable:
                return "The iPhone did not produce a readable audio file. Please try again."
            case .incomplete:
                return "The microphone stopped capturing audio unexpectedly. Please retry."
            case .silentInput:
                return "The microphone supplied audio frames but no voice signal. Check the active microphone or try Voice Memos."
            }
        }
    }

    static func validateSignal(
        peak: Float, audibleFrames: Int64
    ) throws {
        guard peak.isFinite, peak >= 0.001, audibleFrames > 0 else {
            throw CaptureError.silentInput
        }
    }

    /// Inspect the *decoded AAC file*, not only the real-time audio tap.
    /// Crash recovery uses this same gate before importing staged audio.
    static func validateFileHasSound(_ url: URL) throws {
        let reader = try AVAudioFile(forReading: url)
        let buffer = AVAudioPCMBuffer(
            pcmFormat: reader.processingFormat,
            frameCapacity: 4_096
        )!
        guard reader.processingFormat.commonFormat == .pcmFormatFloat32
        else { throw CaptureError.unreadable }
        while reader.framePosition < reader.length {
            try reader.read(into: buffer, frameCount: 4_096)
            guard buffer.frameLength > 0 else { break }
            guard let samples = buffer.floatChannelData else {
                throw CaptureError.unreadable
            }
            for channel in 0..<Int(reader.processingFormat.channelCount) {
                for index in stride(from: 0, to: Int(buffer.frameLength), by: 8) {
                    if abs(samples[channel][index]) >= 0.001 {
                        return
                    }
                }
            }
        }
        throw CaptureError.silentInput
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
