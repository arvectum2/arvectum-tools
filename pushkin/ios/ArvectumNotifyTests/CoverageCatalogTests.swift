import XCTest
@testable import ArvectumNotify

final class CoverageCatalogTests: XCTestCase {
    func testLocalizedOptionalGroupCopyAndCounts() {
        XCTAssertEqual(PushkinCopy.text("Optional Groups", language: "ru-RU"),
                       "Дополнительные группы")
        XCTAssertEqual(PushkinCopy.text("Clear group plan", language: "ru"),
                       "Очистить план")
        XCTAssertEqual(PushkinCopy.appCount(1, language: "ru"), "1 приложение")
        XCTAssertEqual(PushkinCopy.appCount(2, language: "ru"), "2 приложения")
        XCTAssertEqual(PushkinCopy.appCount(5, language: "ru"), "5 приложений")
        XCTAssertEqual(PushkinCopy.appCount(11, language: "ru"), "11 приложений")
        XCTAssertEqual(PushkinCopy.appCount(21, language: "ru"), "21 приложение")
        XCTAssertEqual(PushkinCopy.appCount(25, language: "ru"), "25 приложений")
        XCTAssertEqual(PushkinCopy.appCount(25, language: "en"), "25 apps")
    }

    func testRussianCopyAndEnglishFallback() {
        XCTAssertEqual(
            PushkinCopy.text("History", language: "ru-RU"),
            "История"
        )
        XCTAssertEqual(
            PushkinCopy.text("Apps", language: "ru"),
            "Источники"
        )
        XCTAssertEqual(
            PushkinCopy.text("History", language: "en-GB"),
            "History"
        )
        XCTAssertEqual(
            PushkinCopy.text("Unknown label", language: "ru"),
            "Unknown label"
        )
        XCTAssertEqual(
            PushkinCopy.text("History is empty", language: "ru-RU"),
            "История пока пуста"
        )
    }

    func testPendingSourceNameIsBriefWithoutChangingSourceIdentity() {
        XCTAssertEqual(
            PushkinDisplayName.brief("CapCut: Photo & Video Editor"),
            "CapCut"
        )
        XCTAssertEqual(PushkinDisplayName.brief("Telegram"), "Telegram")
        XCTAssertEqual(PushkinDisplayName.brief("  "), "")
    }

    func testProductionCatalogHasExactly1000UniqueApps() {
        let entries = CoverageCatalog.entries
        XCTAssertEqual(entries.count, 1000)
        XCTAssertEqual(Set(entries.map(\.bundleIdentifier)).count, 1000)
        XCTAssertFalse(entries.contains {
            $0.bundleIdentifier == "ru.arvectum.pushkin.futuretest"
        })
    }

    func testBaseAndEveryMicroPackageAreBundled() {
        XCTAssertNotNil(CoverageCatalog.basePackageURL)
        let missing = CoverageCatalog.entries.filter {
            CoverageCatalog.packageURL(for: $0) == nil
        }
        XCTAssertTrue(
            missing.isEmpty,
            "Missing micro-packages: \(missing.prefix(10).map(\.name))"
        )
    }

    func testCoveragePackageURLsAreLocalFiles() {
        XCTAssertEqual(CoverageCatalog.basePackageURL?.isFileURL, true)
        XCTAssertTrue(
            CoverageCatalog.entries.allSatisfy {
                CoverageCatalog.packageURL(for: $0)?.isFileURL == true
            }
        )
    }

    func testCommonPickerPrioritizesMassMarketApps() {
        let bundles = Set(CoverageCatalog.commonEntries.map(\.bundleIdentifier))
        XCTAssertTrue(bundles.contains("ph.telegra.Telegraph"))
        XCTAssertTrue(bundles.contains("ru.ozon.OzonStore"))
        XCTAssertTrue(bundles.contains("ru.yandex.ytaxi"))
        XCTAssertTrue(bundles.contains("ru.doublegis.grymmobile"))
        XCTAssertFalse(bundles.contains("ru.arvectum.pushkin.futuretest"))
    }
}
