import AVFoundation
import XCTest
@testable import WhatIOS

final class VideoCameraSwitchTests: XCTestCase {
    func testSwitchThenStopRetainsAllEarlierSegments() {
        var flow = VideoCaptureTransition()
        XCTAssertTrue(flow.requestSwitch(isRecording: true))
        XCTAssertTrue(flow.shouldSwitchAfterClip)
        XCTAssertFalse(flow.requestSwitch(isRecording: true))

        flow.requestStop(discard: false)
        XCTAssertTrue(flow.isStopping)
        XCTAssertFalse(flow.shouldSwitchAfterClip)
        flow.didStartNextClip()
        XCTAssertEqual(flow.intent, .finish)
    }

    func testDiscardOverridesSwitchAndFinish() {
        var flow = VideoCaptureTransition()
        XCTAssertFalse(flow.requestSwitch(isRecording: false))
        XCTAssertTrue(flow.requestSwitch(isRecording: true))
        flow.requestStop(discard: true)
        flow.requestStop(discard: false)
        XCTAssertTrue(flow.shouldDiscard)
        XCTAssertFalse(flow.shouldSwitchAfterClip)
    }

    func testSwitchCanBeRepeatedAfterNewClipStarts() {
        var flow = VideoCaptureTransition()
        XCTAssertTrue(flow.requestSwitch(isRecording: true))
        flow.didStartNextClip()
        XCTAssertEqual(flow.intent, .recording)
        XCTAssertTrue(flow.requestSwitch(isRecording: true))
    }

    func testSingleClipNeverTranscodesOriginal() async throws {
        let original = try fixture("back")
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-no-reencode-\(UUID().uuidString).mov")
        defer { try? FileManager.default.removeItem(at: destination) }
        let result = try await VideoSegmentComposer.compose(
            [original], destination: destination
        )
        XCTAssertEqual(result.url, original)
        XCTAssertFalse(result.isTemporaryExport)
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertGreaterThan(result.duration, 0.5)
    }

    func testCameraSegmentsExportAsOnePlayableMovieWithAudio() async throws {
        let clips = try [fixture("back"), fixture("front")]
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-camera-switch-\(UUID().uuidString).mov")
        defer { try? FileManager.default.removeItem(at: destination) }

        let result = try await VideoSegmentComposer.compose(
            clips, destination: destination
        )
        XCTAssertTrue(result.isTemporaryExport)
        XCTAssertEqual(result.url, destination)
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))

        let movie = AVURLAsset(url: destination)
        let duration = try await movie.load(.duration).seconds
        XCTAssertGreaterThan(duration, 1.3)
        XCTAssertLessThan(duration, 2.1)
        let videoTracks = try await movie.loadTracks(withMediaType: .video)
        let audioTracks = try await movie.loadTracks(withMediaType: .audio)
        let playable = try await movie.load(.isPlayable)
        XCTAssertGreaterThan(videoTracks.count, 0)
        XCTAssertGreaterThan(audioTracks.count, 0)
        XCTAssertTrue(playable)

        // Test *actual encoded frames*, not just duration/tracks: an invalid
        // composition may report two segments while rendering only one.
        let generator = AVAssetImageGenerator(asset: movie)
        generator.appliesPreferredTrackTransform = true
        let firstFrame = try generator.copyCGImage(
            at: CMTime(seconds: 0.25, preferredTimescale: 600), actualTime: nil
        )
        let secondFrame = try generator.copyCGImage(
            at: CMTime(seconds: 1.05, preferredTimescale: 600), actualTime: nil
        )
        let first = try averagePixel(firstFrame)
        let second = try averagePixel(secondFrame)
        XCTAssertGreaterThan(first.0, first.2 + 70, "First segment should be red")
        XCTAssertGreaterThan(second.2, second.0 + 70, "Second segment should be blue")

        // Export never destroys the originals, even for a successful merge.
        for url in clips {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
    }

    private func averagePixel(_ image: CGImage) throws -> (Int, Int, Int) {
        var pixel = [UInt8](repeating: 0, count: 4)
        let success = pixel.withUnsafeMutableBytes { ptr -> Bool in
            guard let context = CGContext(
                data: ptr.baseAddress, width: 1, height: 1,
                bitsPerComponent: 8, bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            return true
        }
        guard success else {
            throw NSError(domain: "VideoCameraSwitchTests", code: 2)
        }
        return (Int(pixel[0]), Int(pixel[1]), Int(pixel[2]))
    }

    private func fixture(_ name: String) throws -> URL {
        guard let url = Bundle(for: type(of: self)).url(
            forResource: name, withExtension: "mov"
        ) else {
            throw NSError(domain: "VideoCameraSwitchTests", code: 1,
                          userInfo: [NSLocalizedDescriptionKey:
                            "Missing \(name).mov test fixture"])
        }
        return url
    }
}
