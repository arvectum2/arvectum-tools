import XCTest

/// Missing RU/EN/ES iPhone UI coverage using isolated synthetic habit store.
final class CoreLanguageCoverageUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func checkNewHabit(
        language: String,
        locale: String,
        createLabel: String,
        emptyTitle: String,
        newHabitTitle: String,
        namePlaceholder: String,
        doneLabel: String
    ) {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()

        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Позже", "Later")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }

        let create = app.buttons[createLabel].firstMatch
        XCTAssertTrue(create.waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts[emptyTitle].exists)
        create.tap()
        XCTAssertTrue(app.navigationBars[newHabitTitle].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.textFields[namePlaceholder].firstMatch.exists)
        XCTAssertTrue(app.buttons[doneLabel].firstMatch.exists)
        // Do not save; no local/iCloud health/habit records are changed.
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "chickmark-\(language)-new-habit"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testRussianBaselineNewHabit() {
        checkNewHabit(language: "ru", locale: "ru_RU",
                      createLabel: "Создать привычку",
                      emptyTitle: "Начните с одной привычки",
                      newHabitTitle: "Новая привычка",
                      namePlaceholder: "Название привычки",
                      doneLabel: "Готово")
    }

    @MainActor
    func testEnglishBaselineNewHabit() {
        checkNewHabit(language: "en", locale: "en_US",
                      createLabel: "Create habit",
                      emptyTitle: "Start with one habit",
                      newHabitTitle: "New habit",
                      namePlaceholder: "Habit name",
                      doneLabel: "Done")
    }

    @MainActor
    func testSpanishNewHabit() {
        checkNewHabit(language: "es", locale: "es_ES",
                      createLabel: "Crear hábito",
                      emptyTitle: "Empieza con un hábito",
                      newHabitTitle: "Nuevo hábito",
                      namePlaceholder: "Nombre del hábito",
                      doneLabel: "Listo")
    }
}
