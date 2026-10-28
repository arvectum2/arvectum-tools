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

    func testInAppWebOnlyAcceptsOwnedHTTPSPages() {
        for path in ["https://arvectum.com/privacy",
                     "https://arvectum.com/contact.html",
                     "https://arvectum.com/tools/chickmark/en/index.html"] {
            XCTAssertNotNil(ChickMarkWebPage(url: URL(string: path)!))
        }
        for path in ["http://arvectum.com/privacy",
                     "https://evil-arvectum.com/privacy",
                     "https://arvectum.com.evil.test/privacy",
                     "https://example.com",
                     "habits-arvectum://habit/123",
                     "https://person@arvectum.com/private"] {
            XCTAssertNil(ChickMarkWebPage(url: URL(string: path)!))
        }
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
