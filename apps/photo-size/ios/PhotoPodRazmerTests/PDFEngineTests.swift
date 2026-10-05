import PDFKit
import UIKit
import XCTest
@testable import PhotoPodRazmer

final class PDFEngineTests: XCTestCase {
    private let engine = PDFEngine()

    func testInspectReadsPageCount() throws {
        let source = try engine.inspect(data: makePDF(pageCount: 2))
        XCTAssertEqual(source.pageCount, 2)
        XCTAssertGreaterThan(source.sizeBytes, 0)
        XCTAssertNotNil(source.previewImage)
    }

    func testAlreadySmallPDFIsReturnedWithinTarget() throws {
        let source = try engine.inspect(data: makePDF(pageCount: 1))
        let target = source.sizeBytes + 10_000
        let result = try engine.compressByBytes(source: source, requestedMaximumBytes: target)
        XCTAssertTrue(result.alreadyFit)
        XCTAssertLessThanOrEqual(result.outputSizeBytes, target)
    }

    func testImageHeavyPDFCanBeReducedBelowTarget() throws {
        let source = try engine.inspect(data: makePDF(pageCount: 3, noisy: true))
        let target = max(Int64(120_000), source.sizeBytes / 2)
        XCTAssertGreaterThan(source.sizeBytes, target)

        let result = try engine.compressByBytes(source: source, requestedMaximumBytes: target)
        XCTAssertLessThanOrEqual(result.outputSizeBytes, target)
        XCTAssertEqual(PDFDocument(url: result.outputURL)?.pageCount, 3)
    }

    private func makePDF(pageCount: Int, noisy: Bool = false) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { context in
            for index in 0..<pageCount {
                context.beginPage()
                UIColor.white.setFill()
                context.fill(pageRect)

                let title = "PDF test page \(index + 1)"
                title.draw(
                    at: CGPoint(x: 40, y: 40),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 28)]
                )

                if noisy {
                    let image = makeNoiseImage(width: 1100, height: 1500, seed: index + 1)
                    image.draw(in: CGRect(x: 40, y: 110, width: 515, height: 690))
                }
            }
        }
    }

    private func makeNoiseImage(width: Int, height: Int, seed: Int) -> UIImage {
        let count = width * height * 4
        var bytes = [UInt8](repeating: 0, count: count)
        var value = UInt64(seed)
        for i in stride(from: 0, to: count, by: 4) {
            value = value &* 6364136223846793005 &+ 1
            bytes[i] = UInt8(truncatingIfNeeded: value >> 24)
            bytes[i + 1] = UInt8(truncatingIfNeeded: value >> 32)
            bytes[i + 2] = UInt8(truncatingIfNeeded: value >> 40)
            bytes[i + 3] = 255
        }
        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        let cg = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )!
        return UIImage(cgImage: cg)
    }
}
