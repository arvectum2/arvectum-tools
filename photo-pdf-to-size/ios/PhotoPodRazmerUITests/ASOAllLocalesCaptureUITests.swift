import XCTest

/// Native-only marketing evidence. Isolated simulator and DEBUG fixtures;
/// no user photos, PDF files, advertising requests, or App Store changes.
final class ASOAllLocalesCaptureUITests: XCTestCase {
    @MainActor
    func testAllBundledLocalesFourRealModes() {
        let locales = [
            ("ru", "ru_RU"), ("en", "en_US"), ("es", "es_ES"),
            ("fr", "fr_FR"), ("de", "de_DE"), ("it", "it_IT"),
            ("ja", "ja_JP"), ("ko", "ko_KR"), ("pt-BR", "pt_BR"),
            ("pt-PT", "pt_PT"), ("zh-Hans", "zh_Hans_CN"),
            ("zh-Hant", "zh_Hant_TW")
        ]
        let modes = ["fileSize", "pixels", "passport", "pdf"]
        for (language, region) in locales {
            for mode in modes {
                let app = XCUIApplication()
                app.launchArguments = [
                    "-AppleLanguages", "(\(language))",
                    "-AppleLocale", region,
                    "--store-screenshot-clean",
                    mode == "pdf" ? "--qa-pdf-result" : "--qa-photo-fixture",
                    "--store-screenshot-mode", mode
                ]
                app.launchEnvironment["ARVECTUM_NATIVE_QA_FIXTURE"] = "no-fill"
                app.launch()
                let decline = app.buttons["ad-consent-decline"]
                if decline.waitForExistence(timeout: 1) { decline.tap() }
                // Evidence always reflects the actual localized SwiftUI hierarchy.
                XCTAssertTrue(app.wait(for: .runningForeground, timeout: 8),
                              "App failed in \(language)/\(mode)")
                let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                shot.name = "aso-photo--\(language)--\(mode)"
                shot.lifetime = .keepAlways
                add(shot)
                app.terminate()
            }
        }
    }
}
