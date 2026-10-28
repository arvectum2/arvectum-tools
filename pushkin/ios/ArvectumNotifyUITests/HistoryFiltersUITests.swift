import XCTest

final class HistoryFiltersUITests: XCTestCase {
    func testFilterBySourceThenResetPreservesHistory() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US",
                               "--store-screenshot-fixture"]
        app.launch()
        let delivery = app.staticTexts["Delivery update"].firstMatch
        let design = app.staticTexts["Design team"].firstMatch
        XCTAssertTrue(delivery.waitForExistence(timeout: 14))
        XCTAssertTrue(design.exists)

        let source = app.buttons["pushkin.filter.source"]
        XCTAssertTrue(source.waitForExistence(timeout: 8))
        source.tap()
        let telegram = app.buttons["Telegram"].firstMatch
        XCTAssertTrue(telegram.waitForExistence(timeout: 8))
        telegram.tap()
        XCTAssertTrue(design.waitForExistence(timeout: 8))
        XCTAssertFalse(delivery.exists, "Source filter must hide other apps, not delete them")

        let reset = app.buttons["pushkin.filter.clear"]
        XCTAssertTrue(reset.waitForExistence(timeout: 6))
        reset.tap()
        XCTAssertTrue(delivery.waitForExistence(timeout: 8))
        XCTAssertTrue(design.exists)
    }
}
