import XCTest

final class CaptureFirstUITests: XCTestCase {
    func testCaptureFirstHomeAndLibraryBackNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        let start = app.buttons["Start recording"]
        XCTAssertTrue(start.waitForExistence(timeout: 10),
                      "The recording button must be immediately visible at launch.")

        let saved = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "My recordings")
        ).firstMatch
        XCTAssertTrue(saved.exists,
                      "The saved-notes library must always be reachable.")
        saved.tap()

        let returnToRecording = app.buttons["Back to quick recording"]
        XCTAssertTrue(returnToRecording.waitForExistence(timeout: 5),
                      "The library must offer a one-tap return to capture.")
        XCTAssertTrue(app.navigationBars["What?"].exists)
        returnToRecording.tap()

        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertTrue(saved.exists)
    }
}
