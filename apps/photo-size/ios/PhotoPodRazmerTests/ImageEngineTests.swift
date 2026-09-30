import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import PhotoPodRazmer

final class ImageEngineTests: XCTestCase {
    private let engine = ImageEngine()

    func testLongSideDimensionsPreserveAspectRatio() {
        XCTAssertEqual(
            calculateLongSideDimensions(width: 4000, height: 3000, targetLongSide: 600),
            ImageDimensions(width: 600, height: 450)
        )
        XCTAssertEqual(
            calculateLongSideDimensions(width: 3000, height: 4000, targetLongSide: 600),
            ImageDimensions(width: 450, height: 600)
        )
    }

    func testResizeLongSideProducesExactTarget() throws {
        let source = try engine.inspect(data: makeNoiseJPEG(width: 1200, height: 900))
        let result = try engine.resizeLongSide(source: source, targetLongSide: 600)
        XCTAssertEqual(max(result.outputWidth, result.outputHeight), 600)
        XCTAssertEqual(result.outputWidth, 600)
        XCTAssertEqual(result.outputHeight, 450)
    }
    func testFileSizeCompressionStaysBelowLimit() throws {
        let source = try engine.inspect(data: makeNoiseJPEG(width: 1600, height: 1200))
        let target: Int64 = 150_000
        XCTAssertGreaterThan(source.sizeBytes, target)

        let result = try engine.compressByBytes(
            source: source,
            requestedMaximumBytes: target
        )

        XCTAssertLessThanOrEqual(result.outputSizeBytes, target)
        XCTAssertEqual(result.mode, .fileSize)
    }

    func testPassportOutputContract() throws {
        let source = try engine.inspect(data: makeNoiseJPEG(width: 1000, height: 1286))
        let crop = NormalizedCropRect(left: 0, top: 0, right: 1, bottom: 1)
        let result = try engine.preparePassport(source: source, crop: crop)

        XCTAssertEqual(result.outputWidth, 620)
        XCTAssertEqual(result.outputHeight, 797)
        XCTAssertGreaterThanOrEqual(result.outputSizeBytes, 10_000)
        XCTAssertLessThanOrEqual(result.outputSizeBytes, 5_000_000)
        let data = try Data(contentsOf: result.outputURL)
        let imageSource = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        let properties = try XCTUnwrap(
            CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]
        )
        XCTAssertEqual((properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue, 620)
        XCTAssertEqual((properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue, 797)
        XCTAssertEqual((properties[kCGImagePropertyDPIWidth] as? NSNumber)?.intValue, 450)
        XCTAssertEqual((properties[kCGImagePropertyDPIHeight] as? NSNumber)?.intValue, 450)
    }

    private func makeNoiseJPEG(width: Int, height: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        var state: UInt32 = 0x12345678
        for index in stride(from: 0, to: bytes.count, by: 4) {
            state = state &* 1664525 &+ 1013904223
            bytes[index] = UInt8(truncatingIfNeeded: state >> 16)
            state = state &* 1664525 &+ 1013904223
            bytes[index + 1] = UInt8(truncatingIfNeeded: state >> 16)
            state = state &* 1664525 &+ 1013904223
            bytes[index + 2] = UInt8(truncatingIfNeeded: state >> 16)
            bytes[index + 3] = 255
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let provider = try XCTUnwrap(CGDataProvider(data: Data(bytes) as CFData))
        let cgImage = try XCTUnwrap(
            CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
            )
        )

        let mutable = NSMutableData()
        let destination = try XCTUnwrap(
            CGImageDestinationCreateWithData(
                mutable,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        )
        CGImageDestinationAddImage(
            destination,
            cgImage,
            [kCGImageDestinationLossyCompressionQuality: 0.98] as CFDictionary
        )
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return mutable as Data
    }
}
