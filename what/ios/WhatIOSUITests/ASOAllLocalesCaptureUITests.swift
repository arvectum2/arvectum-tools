import XCTest

/// Marketing source captures: native SwiftUI text, disposable in-memory simulator.
/// No real microphone/camera use, no deletion of Watch or iPhone recordings.
final class ASOAllLocalesCaptureUITests: XCTestCase {
    @MainActor
    func testBundledLanguagesHomeLibraryAndSettings() {
        let locales = [
            ("ru", "ru_RU"), ("en", "en_US"), ("es", "es_ES"),
            ("fr", "fr_FR"), ("de", "de_DE"), ("it", "it_IT"),
            ("ja", "ja_JP"), ("ko", "ko_KR"), ("pt-BR", "pt_BR"),
            ("pt-PT", "pt_PT"), ("zh-Hans", "zh_Hans_CN"),
            ("zh-Hant", "zh_Hant_TW")
        ]
        for (language, locale) in locales {
            let app = XCUIApplication()
            app.launchArguments = [
                "-AppleLanguages", "(\(language))", "-AppleLocale", locale,
                "-what.transcription.locale", "en-US", "--qa-spanish-axxxl-home"
            ]
            app.launch()
            let record = app.buttons["what.record.primary"]
            guard record.waitForExistence(timeout: 10) else {
                XCTFail("Missing actual home UI for \(language)")
                app.terminate()
                continue
            }
            capture(name: "aso-what--\(language)--home")
            let library = app.buttons["what.open.library"]
            guard library.isHittable else {
                XCTFail("Library unreachable: \(language)")
                app.terminate()
                continue
            }
            library.tap()
            let settings = app.buttons["what.library.settings"]
            guard settings.waitForExistence(timeout: 8) else {
                XCTFail("Library UI missing: \(language)")
                app.terminate()
                continue
            }
            capture(name: "aso-what--\(language)--library")
            settings.tap()
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
            capture(name: "aso-what--\(language)--settings")
            app.terminate()

            let note = XCUIApplication()
            note.launchArguments = [
                "-AppleLanguages", "(\(language))", "-AppleLocale", locale,
                "-what.transcription.locale", "en-US", "--qa-spanish-axxxl-home"
            ]
            note.launch()
            let addText = note.buttons["what.new.text"]
            guard addText.waitForExistence(timeout: 10) else {
                XCTFail("Quick text-note action missing: \(language)")
                note.terminate()
                continue
            }
            addText.tap()
            guard note.textViews["what.text.editor"].waitForExistence(timeout: 10) else {
                XCTFail("Text-note editor did not appear: \(language)")
                note.terminate()
                continue
            }
            capture(name: "aso-what--\(language)--text")
            note.terminate()
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
