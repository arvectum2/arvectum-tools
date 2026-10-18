import XCTest

/// QA on isolated iPad/Duo simulator (not actual hinge or physical camera).
final class AdaptiveLayoutUITests: XCTestCase {
    func testCaptureAndUnifiedLibraryKeepStateAcrossRotation() throws {
        let app = XCUIApplication()
        app.launch()
        let record = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Начать запись", "Start recording")
        ).firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 15))
        let saved = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@",
                        "Мои записи", "My recordings")
        ).firstMatch
        XCTAssertTrue(saved.exists)
        saved.tap()
        let back = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Вернуться к быстрой записи", "Back to quick recording")
        ).firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        let newText = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Создать текстовую заметку", "New text note")
        ).firstMatch
        XCTAssertTrue(newText.waitForExistence(timeout: 10))
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        XCTAssertTrue(newText.exists)
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        back.tap()
        XCTAssertTrue(record.waitForExistence(timeout: 10))
    }
}
