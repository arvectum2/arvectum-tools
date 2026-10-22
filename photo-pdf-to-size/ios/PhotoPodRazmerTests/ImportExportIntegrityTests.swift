import PDFKit
import UIKit
import XCTest
@testable import PhotoPodRazmer

/// Disposable source files only. Exercises the export contract without
/// accessing Files, Photos or App Store data on any physical device.
final class ImportExportIntegrityTests: XCTestCase {
    func testFilesPickerCancellationDoesNotMaskRealExportErrors() {
        let canceled = NSError(
            domain: NSCocoaErrorDomain,
            code: NSUserCancelledError
        )
        XCTAssertTrue(isCanceledFileExport(canceled))

        let diskFailure = NSError(
            domain: NSCocoaErrorDomain,
            code: CocoaError.fileWriteOutOfSpace.rawValue
        )
        XCTAssertFalse(isCanceledFileExport(diskFailure))

        let other = NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotWriteToFile)
        XCTAssertFalse(isCanceledFileExport(other))
    }

    func testResizedJPEGPNGHEICNeverRewriteTheImportedOriginal() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("photo-a4-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }
        let originalURL = directory.appendingPathComponent("source.jpg")
        let originalBytes = QAFixtures.photoData()
        try originalBytes.write(to: originalURL, options: .atomic)

        let engine = ImageEngine()
        let imported = try engine.inspect(data: Data(contentsOf: originalURL))
        for format in [ExportImageFormat.jpeg, .png, .heic] {
            let result = try engine.resizeExact(
                source: imported, width: 600, height: 800,
                format: format, stripMetadata: true
            )
            XCTAssertEqual(result.outputWidth, 600)
            XCTAssertEqual(result.outputHeight, 800)
            XCTAssertNotEqual(result.outputURL, originalURL)
            XCTAssertNotEqual(result.outputURL, imported.localURL)
            XCTAssertEqual(
                Int64(try Data(contentsOf: result.outputURL).count),
                result.outputSizeBytes
            )
            XCTAssertEqual(try Data(contentsOf: originalURL), originalBytes)
        }
    }

    func testPDFImportAndExportDoNotRewriteSourceFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("pdf-a4-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }
        let originalURL = directory.appendingPathComponent("original.pdf")
        let originalBytes = QAFixtures.pdfData()
        try originalBytes.write(to: originalURL, options: .atomic)

        let engine = PDFEngine()
        let inspected = try engine.inspect(fileURL: originalURL)
        XCTAssertNotEqual(inspected.localURL, originalURL)
        XCTAssertEqual(inspected.pageCount, 3)
        let result = try engine.compressByBytes(
            source: inspected,
            requestedMaximumBytes: inspected.sizeBytes + 10_000
        )
        XCTAssertTrue(result.alreadyFit)
        XCTAssertNotEqual(result.outputURL, originalURL)
        XCTAssertEqual(try Data(contentsOf: originalURL), originalBytes)
        XCTAssertEqual(
            Int64(try Data(contentsOf: result.outputURL).count),
            result.outputSizeBytes
        )
        XCTAssertEqual(PDFDocument(url: result.outputURL)?.pageCount, 3)
    }
}
