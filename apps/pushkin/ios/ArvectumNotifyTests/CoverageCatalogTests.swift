import XCTest
@testable import ArvectumNotify

final class CoverageCatalogTests: XCTestCase {
    func testProductionCatalogHasExactly1000UniqueApps() {
        let entries = CoverageCatalog.entries
        XCTAssertEqual(entries.count, 1000)
        XCTAssertEqual(Set(entries.map(\.bundleIdentifier)).count, 1000)
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

    func testCommonPickerPrioritizesMassMarketApps() {
        let bundles = Set(CoverageCatalog.commonEntries.map(\.bundleIdentifier))
        XCTAssertTrue(bundles.contains("ph.telegra.Telegraph"))
        XCTAssertTrue(bundles.contains("ru.ozon.OzonStore"))
        XCTAssertTrue(bundles.contains("RU.WILDBERRIES.MOBILEAPP"))
        XCTAssertTrue(bundles.contains("com.minsvyaz.gosuslugi"))
    }
}
