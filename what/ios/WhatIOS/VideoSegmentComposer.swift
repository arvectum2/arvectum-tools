import AVFoundation
import Foundation

/// Joining camera-switch segments is local-only. Files stay on disk until
/// the repository has durably copied the completed movie.
enum VideoSegmentComposer {
    enum CompositionError: LocalizedError {
        case noClips, missingVideoTrack, invalidDuration, exportUnavailable, exportFailed

        var errorDescription: String? {
            switch self {
            case .noClips: return "No video segments were recorded"
            case .missingVideoTrack: return "A video segment has no video track"
            case .invalidDuration: return "A video segment has an invalid duration"
            case .exportUnavailable: return "The device cannot combine camera segments"
            case .exportFailed: return "Could not combine camera segments"
            }
        }
    }

    struct Result {
        let url: URL
        let duration: TimeInterval
        let isTemporaryExport: Bool
    }

    static func compose(_ clips: [URL], destination: URL) async throws -> Result {
        guard !clips.isEmpty else { throw CompositionError.noClips }

        // No transcoding or replacement of the original when no switch occurred.
        if clips.count == 1 {
            let asset = AVURLAsset(url: clips[0])
            let duration = try await asset.load(.duration).seconds
            guard duration.isFinite && duration > 0 else {
                throw CompositionError.invalidDuration
            }
            return Result(url: clips[0], duration: duration, isTemporaryExport: false)
        }

        let composition = AVMutableComposition()
        guard let destinationVideo = composition.addMutableTrack(
            withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid
        ) else { throw CompositionError.exportUnavailable }
        let destinationAudio = composition.addMutableTrack(
            withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid
        )

        struct ClipInstruction {
            let start: CMTime
            let duration: CMTime
            let transform: CGAffineTransform
            let bounds: CGRect
        }
        var clipInstructions: [ClipInstruction] = []
        var cursor = CMTime.zero
        var renderWidth: CGFloat = 0
        var renderHeight: CGFloat = 0

        for url in clips {
            let source = AVURLAsset(url: url)
            let duration = try await source.load(.duration)
            guard duration.isValid, duration.isNumeric,
                  duration.seconds.isFinite, duration.seconds > 0 else {
                throw CompositionError.invalidDuration
            }
            guard let video = try await source.loadTracks(withMediaType: .video).first else {
                throw CompositionError.missingVideoTrack
            }
            try destinationVideo.insertTimeRange(
                CMTimeRange(start: .zero, duration: duration), of: video, at: cursor
            )
            if let audio = try await source.loadTracks(withMediaType: .audio).first {
                try destinationAudio?.insertTimeRange(
                    CMTimeRange(start: .zero, duration: duration), of: audio, at: cursor
                )
            }
            let originalSize = try await video.load(.naturalSize)
            let transform = try await video.load(.preferredTransform)
            let transformedBounds = CGRect(origin: .zero, size: originalSize)
                .applying(transform)
            let width = abs(transformedBounds.width)
            let height = abs(transformedBounds.height)
            guard width >= 1, height >= 1 else {
                throw CompositionError.invalidDuration
            }
            renderWidth = max(renderWidth, width)
            renderHeight = max(renderHeight, height)
            clipInstructions.append(
                ClipInstruction(start: cursor, duration: duration,
                                transform: transform, bounds: transformedBounds)
            )
            cursor = CMTimeAdd(cursor, duration)
        }

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: renderWidth, height: renderHeight)
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = clipInstructions.map { clip in
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: clip.start, duration: clip.duration)
            let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: destinationVideo)
            // The two cameras may have different preferredTransform and
            // video dimensions. Normalize each segment into one movie canvas.
            let normalized = clip.transform.concatenating(
                CGAffineTransform(
                    translationX: -clip.bounds.minX + (renderWidth - abs(clip.bounds.width)) / 2,
                    y: -clip.bounds.minY + (renderHeight - abs(clip.bounds.height)) / 2
                )
            )
            layer.setTransform(normalized, at: clip.start)
            instruction.layerInstructions = [layer]
            return instruction
        }

        guard let exporter = AVAssetExportSession(
            asset: composition, presetName: AVAssetExportPresetHighestQuality
        ), exporter.supportedFileTypes.contains(.mov) else {
            throw CompositionError.exportUnavailable
        }
        exporter.videoComposition = videoComposition
        exporter.outputFileType = .mov
        exporter.outputURL = destination

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            exporter.exportAsynchronously {
                switch exporter.status {
                case .completed:
                    continuation.resume()
                case .failed, .cancelled:
                    continuation.resume(
                        throwing: exporter.error ?? CompositionError.exportFailed
                    )
                default:
                    continuation.resume(throwing: CompositionError.exportFailed)
                }
            }
        }

        return Result(url: destination, duration: cursor.seconds, isTemporaryExport: true)
    }
}
