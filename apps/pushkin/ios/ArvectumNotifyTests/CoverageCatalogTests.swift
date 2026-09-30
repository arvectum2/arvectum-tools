import XCTest
@testable import ArvectumNotify

final class CoverageCatalogTests: XCTestCase {
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

    func testAppStoreFallbackFindsWorkingCopy() async throws {
        let results = try await CustomCoverageService.searchAppStore(
            term: "Working Copy",
            countryCodes: ["ru", "gb"]
        )
        XCTAssertTrue(
            results.contains {
                $0.bundleId == "com.appliedphasor.working-copy"
            },
            "Results: \(results.map { "\($0.trackName)=\($0.bundleId)" })"
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
