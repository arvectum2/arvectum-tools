import XCTest
@testable import ArvectumNotify

final class CoverageCatalogTests: XCTestCase {
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
