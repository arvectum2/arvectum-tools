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

    func testLanguagePreferenceMapsToAllThreeTranslationBundles() {
        XCTAssertEqual(L10n.string("manage.title", language: "ru"), "Управление")
        XCTAssertEqual(L10n.string("manage.title", language: "en"), "Manage habits")
        XCTAssertEqual(L10n.string("manage.title", language: "es"), "Gestionar hábitos")
        XCTAssertEqual(L10n.string("language.title", language: "ru"), "Язык")
        XCTAssertEqual(L10n.string("language.title", language: "en"), "Language")
        XCTAssertEqual(L10n.string("language.title", language: "es"), "Idioma")
        XCTAssertEqual(ChickMarkLanguage.effectiveIdentifier(for: "es"), "es")
        XCTAssertEqual(ChickMarkLanguage.effectiveIdentifier(for: "ru"), "ru")
        XCTAssertEqual(ChickMarkLanguage.effectiveIdentifier(for: "en"), "en")
    }

    func testVersionComesFromBundleMetadata() {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String
        XCTAssertNotNil(version)
        XCTAssertNotEqual(version, "")
    }
}
