import XCTest

/// Vietnamese source QA using synthetic photo/PDF fixtures, no personal library or ad requests.
final class VietnameseLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func launch(_ fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(vi)", "-AppleLocale", "vi_VN", fixture
        ]
        app.launchEnvironment["ARVECTUM_NATIVE_QA_FIXTURE"] = "no-fill"
        app.launch()
        let decline = app.buttons["ad-consent-decline"]
        if decline.waitForExistence(timeout: 5) {
            XCTAssertTrue(app.buttons["ad-consent-accept"].isHittable)
            decline.tap()
        }
        return app
    }

    @MainActor
    func testVietnamesePhotoResult() {
        let app = launch("--qa-photo-fixture")
        let button = app.buttons["mode-pixels"]
        XCTAssertTrue(button.waitForExistence(timeout: 12))
        XCTAssertTrue(button.isHittable)
        let start = app.buttons["Giảm kích thước ảnh"]
        XCTAssertTrue(start.waitForExistence(timeout: 12))
        start.tap()
        XCTAssertTrue(app.buttons["result-save-primary"].waitForExistence(timeout: 30))
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "photo-pdf-vietnamese-photo"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testVietnamesePDFResult() {
        let app = launch("--qa-pdf-fixture")
        let pdf = app.buttons["mode-pdf"]
        XCTAssertTrue(pdf.waitForExistence(timeout: 12))
        XCTAssertTrue(pdf.isHittable)
        let start = app.buttons["Giảm dung lượng PDF"]
        XCTAssertTrue(start.waitForExistence(timeout: 12))
        start.tap()
        XCTAssertTrue(app.buttons["result-save-primary"].waitForExistence(timeout: 30))
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "photo-pdf-vietnamese-pdf"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
