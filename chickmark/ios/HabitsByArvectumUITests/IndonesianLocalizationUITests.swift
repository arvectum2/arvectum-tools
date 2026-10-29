import XCTest

/// Indonesian iPhone simulator QA: isolated empty SwiftData, no CloudKit or HealthKit mutations.
final class IndonesianLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testIndonesianEmptyStateAndNewHabitForm() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)", "-AppleLocale", "id_ID",
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Later", "Позже")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }
        let create = app.buttons["Buat kebiasaan"].firstMatch
        XCTAssertTrue(create.waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Mulai dari satu kebiasaan"].exists)
        create.tap()
        XCTAssertTrue(app.navigationBars["Kebiasaan baru"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.textFields["Nama kebiasaan"].firstMatch.exists)
        XCTAssertTrue(app.buttons["Selesai"].firstMatch.exists)
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "chickmark-nl-new-habit"
        capture.lifetime = .keepAlways
        add(capture)
    }
}
