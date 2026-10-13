import AVFoundation
import Foundation

/// Captures the actual microphone buffers and encodes them as original AAC.
/// AVAudioFile must be released to finalize the M4A file.
final class MicrophoneCapturePipeline {
    struct Status {
        let framesWritten: Int64
        let sampleRate: Double
        let hasInputSignal: Bool
        let writeError: Error?

        var audioSeconds: TimeInterval {
            sampleRate > 0 ? Double(framesWritten) / sampleRate : 0
        }
    }

    private let lock = NSLock()
    private var writer: AVAudioFile?
    private var frames: Int64 = 0
    private var hasSignal = false
    private var failure: Error?
    private let sampleRate: Double

    init(url: URL, inputFormat: AVAudioFormat) throws {
        guard inputFormat.channelCount > 0,
              inputFormat.sampleRate > 0,
              inputFormat.commonFormat == .pcmFormatFloat32,
              !inputFormat.isInterleaved else {
            throw NSError(
                domain: "What.Microphone", code: 2,
                userInfo: [NSLocalizedDescriptionKey:
                    "The microphone returned an unsupported audio format."]
            )
        }
        sampleRate = inputFormat.sampleRate
        writer = try AVAudioFile(
            forWriting: url,
            settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: inputFormat.sampleRate,
                AVNumberOfChannelsKey: Int(inputFormat.channelCount),
                AVEncoderBitRateKey: 64_000
            ],
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        defer { lock.unlock() }
        guard let writer, failure == nil, buffer.frameLength > 0 else { return }
        do {
            try writer.write(from: buffer)
            frames += Int64(buffer.frameLength)
            if !hasSignal, let data = buffer.floatChannelData {
                let length = Int(buffer.frameLength)
                let samples = data[0]
                for offset in stride(from: 0, to: length, by: 16) {
                    if abs(samples[offset]) > 0.005 {
                        hasSignal = true
                        break
                    }
                }
            }
        } catch {
            failure = error
        }
    }

    var status: Status {
        lock.lock()
        defer { lock.unlock() }
        return Status(
            framesWritten: frames, sampleRate: sampleRate,
            hasInputSignal: hasSignal, writeError: failure
        )
    }

    @discardableResult
    func close() -> Status {
        lock.lock()
        defer { lock.unlock() }
        writer = nil
        return Status(
            framesWritten: frames, sampleRate: sampleRate,
            hasInputSignal: hasSignal, writeError: failure
        )
    }
}
