import XCTest
@testable import HabitsByArvectum

final class ChickMarkProductLinksTests: XCTestCase {
    func testSiteLinksForAllSupportedLanguagesAndFallback() {
        XCTAssertEqual(
            ChickMarkProductLinks.landingPage(for: "ru-RU").absoluteString,
            "https://arvectum.com/tools/chickmark/index.html"
        )
        XCTAssertEqual(
            ChickMarkProductLinks.landingPage(for: "en-GB").absoluteString,
            "https://arvectum.com/tools/chickmark/en/index.html"
        )
        XCTAssertEqual(
            ChickMarkProductLinks.landingPage(for: "es-MX").absoluteString,
            "https://arvectum.com/tools/chickmark/es/index.html"
        )
        XCTAssertEqual(
            ChickMarkProductLinks.landingPage(for: "fr-FR").absoluteString,
            "https://arvectum.com/tools/chickmark/en/index.html"
        )
    }

    func testVersionComesFromBundleMetadata() {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String
        XCTAssertNotNil(version)
        XCTAssertNotEqual(version, "")
    }
}
