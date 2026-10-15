import XCTest

final class ReviewDemoUITests: XCTestCase {
    func testReviewDemoWithSyntheticNotes() throws {
        let app = XCUIApplication()
        app.launch()
        let record = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["Начать запись", "Start recording"])
        ).firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 15))
        capture(app, named: "01 Quick capture")
        Thread.sleep(forTimeInterval: 3)
        let library = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@", "Мои записи", "My recordings")
        ).firstMatch
        XCTAssertTrue(library.exists)
        library.tap()
        XCTAssertTrue(app.navigationBars["Ухват"].waitForExistence(timeout: 8) ||
                      app.navigationBars["UhWhat?"].exists)
        capture(app, named: "02 Library with synthetic voice notes")
        Thread.sleep(forTimeInterval: 3)
        let play = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Прослушать аудио", "Play audio")
        ).firstMatch
        if play.exists {
            play.tap()
            Thread.sleep(forTimeInterval: 3)
            let stop = app.buttons.matching(
                NSPredicate(format: "label == %@ OR label == %@", "Остановить аудио", "Stop audio")
            ).firstMatch
            if stop.exists { stop.tap() }
        }
        let edit = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Править текст", "Edit text")
        ).firstMatch
        if edit.exists {
            edit.tap()
            Thread.sleep(forTimeInterval: 2)
            capture(app, named: "03 Editable transcript")
            Thread.sleep(forTimeInterval: 3)
            let cancel = app.buttons.matching(
                NSPredicate(format: "label == %@ OR label == %@", "Отмена", "Cancel")
            ).firstMatch
            if cancel.exists { cancel.tap() }
        }
        let back = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Вернуться к быстрой записи", "Back to quick recording")
        ).firstMatch
        if back.exists {
            back.tap()
            Thread.sleep(forTimeInterval: 2)
            XCTAssertTrue(record.exists)
        }
    }
    private func capture(_ app: XCUIApplication, named name: String) {
        let a = XCTAttachment(screenshot: app.screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }
}
