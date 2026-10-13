import AVFoundation
import Foundation

/// Captures the actual microphone buffers and encodes them as original AAC.
/// AVAudioFile must be released to finalize the M4A file.
final class MicrophoneCapturePipeline {
    struct Status {
        let framesWritten: Int64
        let firstFrameUptime: TimeInterval?
        let sampleRate: Double
        let hasInputSignal: Bool
        let writeError: Error?
        let peak: Float
        let audibleFrames: Int64

        var containsActualSound: Bool {
            // Samples with an absolute amplitude below 0.0001 may be
            // numerical dither; all-zero input must never pass this gate.
            audibleFrames > 0 && peak >= 0.001
        }

        var audioSeconds: TimeInterval {
            sampleRate > 0 ? Double(framesWritten) / sampleRate : 0
        }
    }

    private let lock = NSLock()
    private var writer: AVAudioFile?
    private var frames: Int64 = 0
    private var firstFrameUptime: TimeInterval?
    private var hasSignal = false
    private var maximumPeak: Float = 0
    private var audibleFrameCount: Int64 = 0
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
            if firstFrameUptime == nil {
                firstFrameUptime = ProcessInfo.processInfo.systemUptime
            }
            frames += Int64(buffer.frameLength)
            if let data = buffer.floatChannelData {
                let count = Int(buffer.frameLength)
                // Sample the first input channel. We keep only numeric
                // aggregates; no speech content leaves the phone.
                let values = data[0]
                for offset in stride(from: 0, to: count, by: 8) {
                    let amplitude = abs(values[offset])
                    maximumPeak = max(maximumPeak, amplitude)
                    if amplitude >= 0.001 {
                        hasSignal = true
                        audibleFrameCount += 8
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
            framesWritten: frames, firstFrameUptime: firstFrameUptime,
            sampleRate: sampleRate,
            hasInputSignal: hasSignal, writeError: failure,
            peak: maximumPeak, audibleFrames: audibleFrameCount
        )
    }

    @discardableResult
    func close() -> Status {
        lock.lock()
        defer { lock.unlock() }
        writer = nil
        return Status(
            framesWritten: frames, firstFrameUptime: firstFrameUptime,
            sampleRate: sampleRate,
            hasInputSignal: hasSignal, writeError: failure,
            peak: maximumPeak, audibleFrames: audibleFrameCount
        )
    }
}
