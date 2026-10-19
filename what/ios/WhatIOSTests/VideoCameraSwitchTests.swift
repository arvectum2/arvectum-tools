import AVFoundation
import XCTest
@testable import WhatIOS

final class VideoCameraSwitchTests: XCTestCase {
    func testExportGateRejectsPreviousSegmentsWhileLastMOVIsOpen() {
        XCTAssertFalse(VideoCaptureFinalizationGate.canCompose(
            startedSegments: 4, finalizedSegments: 3,
            writerIsRecording: false
        ))
        XCTAssertFalse(VideoCaptureFinalizationGate.canCompose(
            startedSegments: 4, finalizedSegments: 4,
            writerIsRecording: true
        ))
        XCTAssertFalse(VideoCaptureFinalizationGate.canCompose(
            startedSegments: 0, finalizedSegments: 0,
            writerIsRecording: false
        ))
        XCTAssertTrue(VideoCaptureFinalizationGate.canCompose(
            startedSegments: 4, finalizedSegments: 4,
            writerIsRecording: false
        ))
        XCTAssertTrue(VideoCaptureFinalizationGate.canCompose(
            startedSegments: 1, finalizedSegments: 1,
            writerIsRecording: false
        ))
    }

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

    func testTenAlternatingCameraSegmentsExportFramesAndAudioInOrder() async throws {
        // Ten actual MOV inputs, not a synthetic metadata-only composition.
        // This tests repeated camera switches without recording new media.
        let sources = try (0..<10).map { try fixture($0.isMultiple(of: 2) ? "back" : "front") }
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-ten-switches-\(UUID().uuidString).mov")
        defer { try? FileManager.default.removeItem(at: destination) }
        let sourceSizes = try sources.map {
            try XCTUnwrap(FileManager.default.attributesOfItem(atPath: $0.path)[.size]
                          as? NSNumber).int64Value
        }
        let originalBytes = try sources.map { try Data(contentsOf: $0) }
        let durations = try await withThrowingTaskGroup(of: (Int, Double).self) { group in
            for (index, source) in sources.enumerated() {
                group.addTask {
                    (index, try await AVURLAsset(url: source).load(.duration).seconds)
                }
            }
            var values = [Double](repeating: 0, count: sources.count)
            for try await (index, seconds) in group { values[index] = seconds }
            return values
        }
        let result = try await VideoSegmentComposer.compose(sources, destination: destination)
        XCTAssertTrue(result.isTemporaryExport)
        let movie = AVURLAsset(url: destination)
        let outputDuration = try await movie.load(.duration).seconds
        let expectedDuration = durations.reduce(0, +)
        XCTAssertEqual(outputDuration, expectedDuration, accuracy: 0.15)
        let audioTracks = try await movie.loadTracks(withMediaType: .audio)
        let isPlayable = try await movie.load(.isPlayable)
        XCTAssertFalse(audioTracks.isEmpty)
        XCTAssertTrue(isPlayable)
        let generator = AVAssetImageGenerator(asset: movie)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.05, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.05, preferredTimescale: 600)
        var cursor = 0.0
        for i in sources.indices {
            let requested = CMTime(seconds: cursor + durations[i] * 0.5,
                                   preferredTimescale: 600)
            var actual = CMTime.invalid
            let frame = try generator.copyCGImage(at: requested, actualTime: &actual)
            let color = try averagePixel(frame)
            print("STRESS_FRAME index=\(i) requested=\(requested.seconds) actual=\(actual.seconds) duration=\(durations[i]) rgb=\(color)")
            if i.isMultiple(of: 2) {
                XCTAssertGreaterThan(color.0, color.2 + 65,
                                     "Back camera segment \(i) should be red")
            } else {
                XCTAssertGreaterThan(color.2, color.0 + 65,
                                     "Front camera segment \(i) should be blue")
            }
            cursor += durations[i]
        }
        for (index, source) in sources.enumerated() {
            XCTAssertEqual(try Data(contentsOf: source), originalBytes[index])
            XCTAssertEqual(try XCTUnwrap(FileManager.default.attributesOfItem(
                atPath: source.path)[.size] as? NSNumber).int64Value, sourceSizes[index])
        }
    }

    func testThirteenAlternatingMOVSegmentsComposeWithoutLosingFinalClip() async throws {
        // Twelve camera swaps produce thirteen independently finalized clips.
        // This is separate from the 12-swap physical QA acceptance: it checks
        // all thirteen actual decoded media segments, not metadata counts.
        let clips = try (0..<13).map { try fixture($0.isMultiple(of: 2) ? "back" : "front") }
        let expected = try await withThrowingTaskGroup(of: (Int, Double).self) { group in
            for (i, clip) in clips.enumerated() {
                group.addTask { (i, try await AVURLAsset(url: clip).load(.duration).seconds) }
            }
            var durations = Array(repeating: 0.0, count: clips.count)
            for try await (index, duration) in group { durations[index] = duration }
            return durations
        }
        XCTAssertFalse(VideoCaptureFinalizationGate.canCompose(
            startedSegments: 13, finalizedSegments: 12, writerIsRecording: false
        ), "Never save a playable twelve-clip prefix while the 13th is open")
        XCTAssertTrue(VideoCaptureFinalizationGate.canCompose(
            startedSegments: 13, finalizedSegments: 13, writerIsRecording: false
        ))
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-thirteen-camera-clips-\(UUID().uuidString).mov")
        defer { try? FileManager.default.removeItem(at: destination) }
        let output = try await VideoSegmentComposer.compose(clips, destination: destination)
        XCTAssertTrue(output.isTemporaryExport)
        let asset = AVURLAsset(url: destination)
        let playable = try await asset.load(.isPlayable)
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        let actualDuration = try await asset.load(.duration).seconds
        XCTAssertTrue(playable)
        XCTAssertFalse(videoTracks.isEmpty)
        XCTAssertFalse(audioTracks.isEmpty)
        XCTAssertEqual(actualDuration, expected.reduce(0, +), accuracy: 0.25)
        let frames = AVAssetImageGenerator(asset: asset)
        frames.appliesPreferredTrackTransform = true
        frames.requestedTimeToleranceBefore = CMTime(seconds: 0.03, preferredTimescale: 600)
        frames.requestedTimeToleranceAfter = CMTime(seconds: 0.03, preferredTimescale: 600)
        var start = 0.0
        for index in clips.indices {
            let at = CMTime(seconds: start + expected[index] / 2,
                            preferredTimescale: 600)
            let frame = try frames.copyCGImage(at: at, actualTime: nil)
            let rgb = try averagePixel(frame)
            if index.isMultiple(of: 2) {
                XCTAssertGreaterThan(rgb.0, rgb.2 + 65, "Back segment \(index) lost")
            } else {
                XCTAssertGreaterThan(rgb.2, rgb.0 + 65, "Front segment \(index) lost")
            }
            start += expected[index]
        }
        XCTAssertEqual(clips.count, 13)
        for clip in clips {
            XCTAssertTrue(FileManager.default.fileExists(atPath: clip.path),
                          "Video composition may never delete a source MOV")
        }
    }

    func testConservativeStorageBudgetHandlesSingleMultiAndOverflow() {
        let mib: Int64 = 1024 * 1024
        XCTAssertEqual(VideoStorageBudget.requiredFreeBytes(sourceBytes: mib,
                                                            segmentCount: 1), 33 * mib)
        XCTAssertEqual(VideoStorageBudget.requiredFreeBytes(sourceBytes: mib,
                                                            segmentCount: 2), 35 * mib)
        XCTAssertEqual(VideoStorageBudget.requiredFreeBytes(sourceBytes: Int64.max,
                                                            segmentCount: 2), Int64.max)
    }

    func testLowFreeSpaceBlocksExportWithoutDeletingOriginalSegments() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("what-lowspace-\(UUID().uuidString)",
                                    isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let originals = try [fixture("back"), fixture("front")]
        let copies = try originals.enumerated().map { index, source in
            let url = root.appendingPathComponent("segment-\(index).mov")
            try FileManager.default.copyItem(at: source, to: url)
            return url
        }
        let bytes = try copies.map { try Data(contentsOf: $0) }
        let destination = root.appendingPathComponent("combined.mov")
        do {
            _ = try await VideoSegmentComposer.compose(
                copies, destination: destination, availableBytesOverride: 1024
            )
            XCTFail("Export must refuse impossible free space")
        } catch VideoStorageBudget.StorageError.insufficientSpace(let required, let available) {
            XCTAssertGreaterThan(required, available)
            XCTAssertEqual(available, 1024)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        for (index, source) in copies.enumerated() {
            XCTAssertEqual(try Data(contentsOf: source), bytes[index])
        }
        // A later retry succeeds with the exact same input files.
        let success = try await VideoSegmentComposer.compose(copies, destination: destination)
        XCTAssertTrue(success.duration > 1.3)
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))
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
