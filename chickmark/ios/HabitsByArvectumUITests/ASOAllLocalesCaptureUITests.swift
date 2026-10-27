import XCTest

/// In-memory-only demo; screenshots reflect actual app text and real SwiftUI.
final class ASOAllLocalesCaptureUITests: XCTestCase {
    @MainActor
    func testBundledLanguageHabitListAndNewHabitForm() {
        captureLanguageScreens(only: nil)
    }

    /// Cheap targeted retake after a Korean localization-only editorial fix.
    @MainActor
    func testKoreanHealthTerminologyAndBaseCaptures() {
        captureLanguageScreens(only: "ko")
    }

    @MainActor
    private func captureLanguageScreens(only selectedLanguage: String?) {
        let locales: [(String, String, String, String)] = [
            ("ru", "ru_RU", "Создать привычку", "Чтение"),
            ("en", "en_US", "Create habit", "Reading"),
            ("es", "es_ES", "Crear hábito", "Leer"),
            ("fr", "fr_FR", "Créer une habitude", "Lecture"),
            ("de", "de_DE", "Gewohnheit erstellen", "Lesen"),
            ("it", "it_IT", "Crea abitudine", "Lettura"),
            ("ja", "ja_JP", "習慣を作成", "読書"),
            ("ko", "ko_KR", "습관 만들기", "독서"),
            ("pt-BR", "pt_BR", "Criar hábito", "Leitura"),
            ("pt-PT", "pt_PT", "Criar hábito", "Leitura"),
            ("zh-Hans", "zh_Hans_CN", "创建习惯", "阅读"),
            ("zh-Hant", "zh_Hant_TW", "建立習慣", "閱讀"),
        ]
        for (language, locale, createLabel, readingName) in locales {
            if let selectedLanguage, language != selectedLanguage { continue }
            let filled = XCUIApplication()
            filled.launchArguments = [
                "-AppleLanguages", "(\(language))", "-AppleLocale", locale,
                "--ui-testing", "--disable-cloud-sync", "--seed-watch-sync-demo",
                "--seed-screenshot-demo"
            ]
            filled.launch()
            XCTAssertTrue(filled.wait(for: .runningForeground, timeout: 9))
            capture(name: "aso-chickmark--\(language)--habits")
            let reading = filled.staticTexts[readingName].firstMatch
            if reading.waitForExistence(timeout: 8) {
                reading.tap()
                let more = filled.buttons["detail.more"]
                if more.waitForExistence(timeout: 9) {
                    capture(name: "aso-chickmark--\(language)--progress")
                } else {
                    XCTFail("Habit detail did not open for \(language)")
                }
            } else {
                XCTFail("Localized reading habit missing for \(language): \(readingName)")
            }
            filled.terminate()

            let form = XCUIApplication()
            form.launchArguments = [
                "-AppleLanguages", "(\(language))", "-AppleLocale", locale,
                "--ui-testing", "--disable-cloud-sync"
            ]
            form.launch()
            let create = form.buttons[createLabel].firstMatch
            guard create.waitForExistence(timeout: 9) else {
                XCTFail("New-habit button missing for \(language): \(createLabel)")
                form.terminate()
                continue
            }
            create.tap()
            guard form.textFields.firstMatch.waitForExistence(timeout: 12) else {
                XCTFail("New-habit editor did not open for \(language)")
                form.terminate()
                continue
            }
            if language == "ko" {
                XCTAssertTrue(form.staticTexts["Apple Health"].firstMatch.exists,
                              "The protected Apple Health brand must not be translated as fruit")
                XCTAssertFalse(form.staticTexts["사과 건강"].firstMatch.exists)
            }
            capture(name: "aso-chickmark--\(language)--create")
            // The 4th slot must come ONLY from testLocalizedExpandedReminderOptions.
            // Do not emit duplicate attachment names with a collapsed section.
            form.terminate()
        }
    }

    /// Targeted marketing retake: expanded, real reminder options with no permission request.
    @MainActor
    func testLocalizedExpandedReminderOptions() {
        captureReminderOptions(only: nil)
    }

    @MainActor
    func testKoreanExpandedReminderOptions() {
        captureReminderOptions(only: "ko")
    }

    @MainActor
    private func captureReminderOptions(only selectedLanguage: String?) {
        let locales: [(String, String, String, String, String)] = [
            ("ru", "ru_RU", "Дополнительно", "Напомнить", "Создать привычку"),
            ("en", "en_US", "More options", "Remind me", "Create habit"),
            ("es", "es_ES", "Más opciones", "Recordármelo", "Crear hábito"),
            ("fr", "fr_FR", "Autres options", "Me rappeler", "Créer une habitude"),
            ("de", "de_DE", "Weitere Optionen", "Erinnerung aktivieren", "Gewohnheit erstellen"),
            ("it", "it_IT", "Altre opzioni", "Attiva promemoria", "Crea abitudine"),
            ("ja", "ja_JP", "その他のオプション", "リマインダーを有効化", "習慣を作成"),
            ("ko", "ko_KR", "추가 옵션", "알림", "습관 만들기"),
            ("pt-BR", "pt_BR", "Mais opções", "Lembrar-me", "Criar hábito"),
            ("pt-PT", "pt_PT", "Mais opções", "Lembrar-me", "Criar hábito"),
            ("zh-Hans", "zh_Hans_CN", "更多选项", "提醒我", "创建习惯"),
            ("zh-Hant", "zh_Hant_TW", "更多選項", "提醒我", "建立習慣"),
        ]
        for (language, locale, moreLabel, reminderLabel, createLabel) in locales {
            if let selectedLanguage, language != selectedLanguage { continue }
            let app = XCUIApplication()
            app.launchArguments = [
                "-AppleLanguages", "(\(language))",
                "-AppleLocale", locale,
                "--ui-testing", "--disable-cloud-sync"
            ]
            app.launch()
            let create = app.buttons[createLabel].firstMatch
            guard create.waitForExistence(timeout: 10) else {
                XCTFail("New habit unavailable for \(language)")
                app.terminate()
                continue
            }
            create.tap()
            guard app.textFields.firstMatch.waitForExistence(timeout: 10) else {
                XCTFail("Editor did not load for \(language)")
                app.terminate()
                continue
            }
            let more = app.staticTexts[moreLabel].firstMatch
            for _ in 0..<3 where !more.isHittable { app.swipeUp() }
            guard more.waitForExistence(timeout: 8), more.isHittable else {
                XCTFail("More options missing for \(language): \(moreLabel)")
                app.terminate()
                continue
            }
            more.tap()
            let reminder = app.switches[reminderLabel].firstMatch
            for _ in 0..<3 where !reminder.isHittable { app.swipeUp() }
            guard reminder.waitForExistence(timeout: 8), reminder.isHittable else {
                XCTFail("Expanded reminder toggle missing for \(language): \(reminderLabel)")
                app.terminate()
                continue
            }
            if language == "ko" {
                XCTAssertTrue(app.staticTexts["아이콘"].firstMatch.exists,
                              "Korean UI must use the icon term, not the word for prize")
                XCTAssertFalse(app.staticTexts["상"].firstMatch.exists)
            }
            capture(name: "aso-chickmark--\(language)--reminders")
            app.terminate()
        }
    }

    @MainActor
    private func capture(name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
