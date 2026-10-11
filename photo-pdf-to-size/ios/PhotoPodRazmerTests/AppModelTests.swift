import XCTest
@testable import PhotoPodRazmer

@MainActor
final class AppModelTests: XCTestCase {
    func testInputConstraintsAcceptBothDecimalSeparators() {
        XCTAssertEqual(InputConstraints.parseBytes("1.5", unit: .mb), 1_500_000)
        XCTAssertEqual(InputConstraints.parseBytes("1,5", unit: .mb), 1_500_000)
        XCTAssertEqual(InputConstraints.parseBytes("100", unit: .kb), 100_000)
        XCTAssertNil(InputConstraints.parseBytes("0", unit: .kb))
        XCTAssertNil(InputConstraints.parseBytes("9", unit: .kb))
        XCTAssertNil(InputConstraints.parseBytes("51", unit: .mb))
        XCTAssertNil(InputConstraints.parseBytes("not a number", unit: .kb))
        XCTAssertNil(InputConstraints.parseBytes("1..5", unit: .mb))
    }

    func testPixelBoundsAndFiltering() {
        XCTAssertEqual(InputConstraints.cleanPixels("640px"), "640")
        XCTAssertEqual(InputConstraints.validPixels("32"), 32)
        XCTAssertEqual(InputConstraints.validPixels("12000"), 12_000)
        XCTAssertNil(InputConstraints.validPixels("31"))
        XCTAssertNil(InputConstraints.validPixels("12001"))
        XCTAssertNil(InputConstraints.validPixels(""))
    }

    func testCustomFileSizeAndPixelModes() {
        let model = AppModel()
        model.startCustomTarget()
        XCTAssertNil(model.targetBytes)
        model.setCustomValue("1,5")
        model.setCustomUnit(.mb)
        XCTAssertEqual(model.targetBytes, 1_500_000)

        model.setPixelResizeMode(.exact)
        model.setExactWidth("640px")
        model.setExactHeight("480px")
        XCTAssertEqual(model.exactWidth, 640)
        XCTAssertEqual(model.exactHeight, 480)
        model.setExactWidth("99999")
        XCTAssertNil(model.exactWidth)
        XCTAssertFalse(model.canResizePixels)
    }

    func testSwitchingModesInvalidatesPendingOperations() {
        let model = AppModel()
        let token = model.beginOperation()
        model.isWorking = true
        XCTAssertTrue(model.isCurrentOperation(token))

        model.setInputKind(.pdf)
        XCTAssertFalse(model.isCurrentOperation(token))
        XCTAssertFalse(model.isWorking)

        let next = model.beginOperation()
        model.setMode(.passport)
        XCTAssertFalse(model.isCurrentOperation(next))
    }

    func testResetRestoresPrivacyAndDefaults() {
        let model = AppModel()
        model.setStripMetadata(false)
        model.setExportFormat(.png)
        model.setMode(.passport)
        model.setInputKind(.pdf)
        model.setPreset(100_000)
        model.reset()

        XCTAssertEqual(model.inputKind, .photo)
        XCTAssertEqual(model.mode, .fileSize)  // updated by reset
        XCTAssertEqual(model.targetBytes, 5_000_000)
        XCTAssertEqual(model.exportFormat, .jpeg)
        XCTAssertTrue(model.stripMetadata)
        XCTAssertNil(model.result)
        XCTAssertNil(model.pdfResult)
        XCTAssertFalse(model.isWorking)
    }

    func testImportImageFromLocalFile() async throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".jpg")
        try QAFixtures.photoData().write(to: file, options: .atomic)
        defer { try? FileManager.default.removeItem(at: file) }
        let model = AppModel()
        model.selectFile(file)
        for _ in 0..<150 where model.isWorking {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTAssertFalse(model.isWorking)
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(model.source?.width, 1200)
        XCTAssertEqual(model.source?.height, 1600)
    }

    func testImportPDFFromLocalFile() async throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".pdf")
        try QAFixtures.pdfData().write(to: file, options: .atomic)
        defer { try? FileManager.default.removeItem(at: file) }
        let model = AppModel()
        model.selectPDFFile(file)
        for _ in 0..<150 where model.isWorking {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTAssertFalse(model.isWorking)
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(model.pdfSource?.pageCount, 3)
    }
}
