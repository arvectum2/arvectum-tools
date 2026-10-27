import XCTest
@testable import PhotoPodRazmer

final class DocumentPhotoPresetTests: XCTestCase {
    func testNewVisaPresetsUseOfficialSizeRanges() {
        let schengen = DocumentPhotoPreset.schengenVisaPrint
        XCTAssertEqual(schengen.widthPixels, 413)
        XCTAssertEqual(schengen.heightPixels, 531)
        XCTAssertEqual(schengen.dpi, 300)
        XCTAssertNotNil(schengen.printSheetSpec)

        let china = DocumentPhotoPreset.chinaVisaDigital
        XCTAssertEqual(china.widthPixels, 354)
        XCTAssertEqual(china.heightPixels, 472)
        XCTAssertEqual(china.minimumBytes, 40_000)
        XCTAssertEqual(china.maximumBytes, 120_000)
        XCTAssertNil(china.printSheetSpec)

        let canada = DocumentPhotoPreset.canadaPassportPrint
        XCTAssertEqual(canada.widthPixels, 591)
        XCTAssertEqual(canada.heightPixels, 827)
        XCTAssertEqual(canada.dpi, 300)
        XCTAssertNil(canada.printSheetSpec)
        XCTAssertTrue(canada.guidance.contains("Канада") || !canada.guidance.isEmpty)
    }

    func testPresetsDoNotDisplaceExistingCases() {
        XCTAssertTrue(DocumentPhotoPreset.allCases.contains(.russiaPassport))
        XCTAssertTrue(DocumentPhotoPreset.allCases.contains(.ukPassportPrint))
        XCTAssertEqual(DocumentPhotoPreset.allCases.count, 8)
    }
}
