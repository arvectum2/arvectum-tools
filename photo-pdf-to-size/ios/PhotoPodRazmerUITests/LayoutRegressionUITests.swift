import XCTest

final class LayoutRegressionUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private enum LocaleCase: CaseIterable {
        case ru
        case en

        var arguments: [String] {
            switch self {
            case .ru:
                return ["-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU"]
            case .en:
                return ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
            }
        }

        var modeButtons: [String] {
            switch self {
            case .ru:
                return ["", "mode-pixels", "mode-passport"]
            case .en:
                return ["", "mode-pixels", "mode-passport"]
            }
        }
    }

    private enum ThemeCase: String, CaseIterable {
        case light
        case dark

        var arguments: [String] {
            ["-AppleInterfaceStyle", rawValue.capitalized]
        }
    }

    private func launch(locale: LocaleCase, theme: ThemeCase) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = locale.arguments + theme.arguments
        app.launchEnvironment["ARVECTUM_NATIVE_QA_FIXTURE"] = "long"
        app.launch()
        let decline = app.buttons["ad-consent-decline"]
        if decline.waitForExistence(timeout: 1.5) {
            decline.tap()
        }
        return app
    }

    private func assertHomeFitsWithoutScroll(
        _ app: XCUIApplication,
        modeButton: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if !modeButton.isEmpty {
            let button = app.buttons[modeButton]
            XCTAssertTrue(button.waitForExistence(timeout: 4), file: file, line: line)
            button.tap()
        }

        let card = app.descendants(matching: .any)["main-task-card"]
        let ad = app.descendants(matching: .any)["main-native-ad-slot"]
        let footer = app.descendants(matching: .any)["app-footer"]

        XCTAssertTrue(card.waitForExistence(timeout: 4), file: file, line: line)
        XCTAssertTrue(ad.waitForExistence(timeout: 4), file: file, line: line)
        XCTAssertTrue(footer.waitForExistence(timeout: 4), file: file, line: line)

        XCTAssertLessThanOrEqual(footer.frame.maxY, app.frame.maxY + 1, file: file, line: line)
        XCTAssertLessThanOrEqual(
            ad.frame.maxY,
            footer.frame.minY + 1,
            "Native ad is clipped below the visible viewport",
            file: file,
            line: line
        )
        XCTAssertGreaterThan(ad.frame.height, 200, "Native QA fixture is not fully laid out", file: file, line: line)
    }

    func testModeNamesExplainActionsInRussianAndEnglish() {
        for locale in LocaleCase.allCases {
            let app = launch(locale: locale, theme: .light)
            let names: [(String, String)]
            switch locale {
            case .ru:
                names = [
                    ("mode-fileSize", "Сжать файл"),
                    ("mode-pixels", "Изменить размер"),
                    ("mode-passport", "Фото на документы"),
                    ("mode-pdf", "Обработать PDF")
                ]
            case .en:
                names = [
                    ("mode-fileSize", "Compress file"),
                    ("mode-pixels", "Resize photo"),
                    ("mode-passport", "ID photo"),
                    ("mode-pdf", "Work with PDF")
                ]
            }
            for (identifier, label) in names {
                let button = app.buttons[identifier]
                XCTAssertTrue(button.waitForExistence(timeout: 6), identifier)
                XCTAssertEqual(button.label, label, identifier)
            }
            app.terminate()
        }
    }

    func testWorstCaseNativeNoScrollRUAndENLightDark() {
        for locale in LocaleCase.allCases {
            for theme in ThemeCase.allCases {
                let app = launch(locale: locale, theme: theme)
                for button in locale.modeButtons {
                    assertHomeFitsWithoutScroll(app, modeButton: button)
                }
                app.terminate()
            }
        }
    }
}
