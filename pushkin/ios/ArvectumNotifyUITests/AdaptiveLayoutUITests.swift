import XCTest

/// Simulator fixture only; real notification history is never touched.
final class AdaptiveLayoutUITests: XCTestCase {
    /// No external Shortcuts changes. Verify secondary routes and user-critical
    /// actions stay readable/reachable under Accessibility XXXL.
#if compiler(>=6.4)
    @MainActor
    func testVoiceOverHistorySpeechWithoutDecorativeSearchIcon() throws {
        guard #available(iOS 27.0, *) else {
            throw XCTSkip("VoiceOver service requires iOS 27")
        }
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU", "--store-tab", "0"
        ]
        app.launch()

        let service = XCUIDevice.shared.voiceOverService
        _ = try? service.disable()
        _ = try service.enable()
        defer { _ = try? service.disable() }

        var utterances = [try service.currentSpeech().utterance]
        for _ in 1..<5 { utterances.append(try service.moveForward().utterance) }
        print("PUSHKIN_VO_HISTORY=\(utterances)")
        XCTAssertTrue(utterances.contains { $0.localizedCaseInsensitiveContains("История") })
        XCTAssertTrue(utterances.contains {
            $0.localizedCaseInsensitiveContains("Поиск уведомлений")
        })
        XCTAssertFalse(utterances.contains { $0.contains("Search") && $0.contains("Image") },
                       "Decorative magnifying glass must not be separately spoken")
    }

    @MainActor
    func testVoiceOverSettingsLabels() throws {
        guard ProcessInfo.processInfo.environment["ARVECTUM_VOICEOVER_QA"] == "1" else {
            throw XCTSkip("Opt-in VoiceOver service QA; isolated simulator only")
        }
        guard #available(iOS 27.0, *) else {
            throw XCTSkip("VoiceOver service requires iOS 27")
        }
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU", "--store-tab", "2"
        ]
        app.launch()

        let service = XCUIDevice.shared.voiceOverService
        _ = try? service.disable()
        _ = try service.enable()
        defer { _ = try? service.disable() }
        var utterances = [try service.currentSpeech().utterance]
        for _ in 1..<11 { utterances.append(try service.moveForward().utterance) }
        print("PUSHKIN_VO_SETTINGS=\(utterances)")
        XCTAssertTrue(utterances.contains { $0.localizedCaseInsensitiveContains("Настройки") })
        XCTAssertTrue(utterances.contains { $0.localizedCaseInsensitiveContains("Уведомлений") })
    }
#endif

    func testRussianOptionalGroupPlannerActionsAtAXXXL() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU",
            "--store-tab", "1"
        ]
        app.launch()
        let sources = app.tabBars.buttons["Источники"]
        XCTAssertTrue(sources.waitForExistence(timeout: 10))
        sources.tap()
        let route = app.buttons["setup-optional-groups"]
        for _ in 0..<12 where !route.isHittable { app.swipeUp() }
        XCTAssertTrue(route.isHittable)
        route.tap()
        XCTAssertTrue(app.navigationBars["Дополнительные группы"]
            .waitForExistence(timeout: 10))
        // A LabeledContent row is a single accessibility element,
        // not necessarily a StaticText child at XXL.
        let search = app.textFields["group-app-search"]
        for _ in 0..<9 where !search.isHittable { app.swipeUp() }
        XCTAssertTrue(search.isHittable)
        search.tap()
        search.typeText("Telegram\n")
        let telegram = app.buttons["group-select-ph.telegra.Telegraph"]
        XCTAssertTrue(telegram.waitForExistence(timeout: 10))
        let oldValue = telegram.value as? String
        XCTAssertTrue(["Выбрано", "Не выбрано"].contains(oldValue ?? ""), "\(oldValue ?? "nil")")
        telegram.tap()
        let newValue = telegram.value as? String
        XCTAssertNotEqual(newValue, oldValue)
        XCTAssertTrue(["Выбрано", "Не выбрано"].contains(newValue ?? ""), "\(newValue ?? "nil")")
        telegram.tap() // Restore exactly the original plan, no deletion.
        XCTAssertEqual(telegram.value as? String, oldValue)

        let categories: XCUIAccessibilityAuditType = [
            .sufficientElementDescription, .hitRegion, .trait, .textClipped
        ]
        try app.performAccessibilityAudit(for: categories) { issue in
            print("PUSHKIN_GROUPS_AX issue=\(issue.compactDescription) " +
                  "element=\(issue.element?.description ?? "nil") " +
                  "detail=\(issue.detailedDescription)")
            return false
        }
    }

    func testEnglishOptionalGroupPlannerLabels() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            "--store-tab", "1"
        ]
        app.launch()
        let sources = app.tabBars.buttons["Apps"]
        XCTAssertTrue(sources.waitForExistence(timeout: 10))
        sources.tap()
        let route = app.buttons["setup-optional-groups"]
        for _ in 0..<12 where !route.isHittable { app.swipeUp() }
        XCTAssertTrue(route.isHittable)
        route.tap()
        XCTAssertTrue(app.navigationBars["Optional Groups"]
            .waitForExistence(timeout: 10))
        // A LabeledContent row is a single accessibility element,
        // not necessarily a StaticText child at XXL.
        let search = app.textFields["group-app-search"]
        for _ in 0..<9 where !search.isHittable { app.swipeUp() }
        XCTAssertTrue(search.isHittable)
        search.tap()
        search.typeText("Telegram\n")
        let telegram = app.buttons["group-select-ph.telegra.Telegraph"]
        XCTAssertTrue(telegram.waitForExistence(timeout: 10))
        XCTAssertTrue(["Selected", "Not selected"].contains(
            telegram.value as? String ?? ""
        ))
    }

    func testHistoryAccessibilityAuditOfLabelsAndTargets() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU",
            "--store-screenshot-fixture"
        ]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["История"].firstMatch
            .waitForExistence(timeout: 8))

        let auditTypes: XCUIAccessibilityAuditType = [
            .sufficientElementDescription, .hitRegion, .trait, .textClipped
        ]
        try app.performAccessibilityAudit(for: auditTypes) { issue in
            print("PUSHKIN_AX_AUDIT issue=\(issue.compactDescription) " +
                  "detail=\(issue.detailedDescription) " +
                  "element=\(issue.element?.description ?? "nil")")
            return false
        }
    }

    func testSettingsAccessibilityAuditOfLabelsAndTargets() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU",
            "--store-tab", "2"
        ]
        app.launch()
        XCTAssertTrue(app.navigationBars["Настройки"].firstMatch
            .waitForExistence(timeout: 8))

        let auditTypes: XCUIAccessibilityAuditType = [
            .sufficientElementDescription, .hitRegion, .trait, .textClipped
        ]
        try app.performAccessibilityAudit(for: auditTypes) { issue in
            print("PUSHKIN_SETTINGS_AX issue=\(issue.compactDescription) " +
                  "detail=\(issue.detailedDescription) " +
                  "element=\(issue.element?.description ?? "nil")")
            return false
        }
    }

    func testSourcesAccessibilityAuditOfLabelsAndTargets() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU",
            "--store-tab", "1"
        ]
        app.launch()
        XCTAssertTrue(app.navigationBars["Источники"].firstMatch
            .waitForExistence(timeout: 8))

        let auditTypes: XCUIAccessibilityAuditType = [
            .sufficientElementDescription, .hitRegion, .trait, .textClipped
        ]
        try app.performAccessibilityAudit(for: auditTypes) { issue in
            print("PUSHKIN_SOURCES_AX issue=\(issue.compactDescription) " +
                  "detail=\(issue.detailedDescription) " +
                  "element=\(issue.element?.description ?? "nil")")
            return false
        }
    }

    func testAccessibilityXXXLSetupAndCoverageNavigation() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU",
            "--store-tab", "1"
        ]
        app.launch()
        XCTAssertTrue(app.navigationBars["Источники"].firstMatch
            .waitForExistence(timeout: 10))

        // At AXXXL the long setup guide is scrollable; repeat users must
        // not scroll through every step to reach app management.
        let quickAdd = app.buttons["setup-quick-add"].firstMatch
        XCTAssertTrue(quickAdd.waitForExistence(timeout: 8))
        XCTAssertTrue(quickAdd.isHittable)
        XCTAssertGreaterThanOrEqual(quickAdd.frame.width, 40)
        quickAdd.tap()

        XCTAssertTrue(app.staticTexts["Офлайн-каталог"].firstMatch
            .waitForExistence(timeout: 8))
        let addToPushkin = app.buttons["Подключить приложение"].firstMatch
        for _ in 0..<5 where !addToPushkin.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(addToPushkin.isHittable)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Pushkin quick coverage navigation AXXXL"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testAccessibilityXXXLSettingsPrivacyAndHistory() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU",
            "--store-tab", "2"
        ]
        app.launch()
        XCTAssertTrue(app.navigationBars["Настройки"].firstMatch
            .waitForExistence(timeout: 10))
        let brand = app.descendants(matching: .any)["pushkin-brand-compact"].firstMatch
        XCTAssertTrue(brand.exists)
        XCTAssertLessThanOrEqual(brand.frame.height, 40)
        XCTAssertLessThan(brand.frame.width, 260)

        let privacy = app.descendants(matching: .any)["pushkin.settings.privacy-policy"].firstMatch
        for _ in 0..<12 where !privacy.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(privacy.isHittable, "Privacy policy must be reachable at AXXXL")
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Pushkin settings privacy AXXXL"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        // Tab navigation is already covered in its own test at normal type.
        // Do not invoke destructive actions on a shared QA container.
        let history = app.tabBars.buttons["История"].firstMatch
        XCTAssertTrue(history.exists)
    }

    func testHistoryAndSearchSurviveOrientationChanges() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = ["--store-screenshot-fixture"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Delivery update"].firstMatch.waitForExistence(timeout: 14))
        let search = app.textFields["Search notifications"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 8))
        search.tap()
        search.typeText("Delivery")
        XCTAssertTrue(app.staticTexts["Delivery update"].firstMatch.exists)
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.staticTexts["Delivery update"].firstMatch.waitForExistence(timeout: 8))
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.staticTexts["Delivery update"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Settings"].exists)
    }

    func testSetupRemainsAccessibleAfterRotation() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = ["--store-screenshot-fixture"]
        app.launch()
        let apps = app.descendants(matching: .any)["Apps"].firstMatch
        XCTAssertTrue(apps.waitForExistence(timeout: 8))
        apps.tap()
        XCTAssertTrue(app.staticTexts["Apps & Setup"].firstMatch.waitForExistence(timeout: 8)
                      || app.navigationBars["Apps & Setup"].firstMatch.exists)
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.buttons["Apps"].exists)
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.buttons["History"].exists)
    }
}
