import XCTest

/// Simulator acceptance only; physical Duo hinge/camera/Watch acceptance
/// remains a separate product release gate.
final class AdaptiveLayoutUITests: XCTestCase {
    func testRecordingNavigationSurvivesSizeAndOrientationChanges() throws {
        let app = XCUIApplication()
        app.launch()

        let record = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Начать запись", "Start recording")
        ).firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 15))
        let library = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@",
                        "Мои записи", "My recordings")
        ).firstMatch
        XCTAssertTrue(library.exists)
        library.tap()

        let back = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Вернуться к быстрой записи", "Back to quick recording")
        ).firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(back.waitForExistence(timeout: 10),
                      "Library navigation must survive resizing.")
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        back.tap()
        XCTAssertTrue(record.waitForExistence(timeout: 10))
        XCUIDevice.shared.orientation = .portrait
    }
}
