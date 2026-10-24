import XCTest
@testable import HabitsByArvectum

final class LocalizationTests: XCTestCase {
    private let requiredKeys = [
        "today.title",
        "brand.website.accessibility",
        "today.progress.format",
        "today.empty.title",
        "today.empty.description",
        "today.none.title",
        "today.none.description",
        "habit.add.accessibility",
        "habit.create",
        "habit.section",
        "habit.name.placeholder",
        "habit.streak.one",
        "habit.streak.format",
        "habit.streak.start",
        "habit.complete",
        "habit.undo",
        "habit.new.title",
        "habit.edit.title",
        "habit.edit.action",
        "section.appearance",
        "section.days",
        "section.reminder",
        "section.moreOptions",
        "appearance.color",
        "appearance.icon",
        "schedule.everyday",
        "schedule.weekdays",
        "schedule.weekdays.description",
        "schedule.custom",
        "reminder.toggle",
        "reminder.time",
        "reminder.notification.body",
        "notification.denied.title",
        "notification.denied.message",
        "notification.openSettings",
        "common.cancel",
        "common.done",
        "common.save",
        "common.ok",
        "common.add",
        "common.delete",
        "add.menu.habit",
        "add.menu.oneoff",
        "oneoff.section",
        "oneoff.new.title",
        "oneoff.edit.title",
        "oneoff.title.placeholder",
        "oneoff.when",
        "oneoff.dateTime",
        "oneoff.hint",
        "oneoff.notification.body",
        "oneoff.notification.denied.message",
        "oneoff.complete",
        "oneoff.edit",
        "oneoff.actions",
        "restart.settings.shortTitle",
        "restart.settings.disabledHint",
        "oneoff.delete",
        "oneoff.today.format",
        "oneoff.tomorrow.format",
        "quick.water", "quick.multicheck",
        "quick.reading",
        "quick.walk",
        "quick.workout",
        "weekday.mon.short",
        "weekday.tue.short",
        "weekday.wed.short",
        "weekday.thu.short",
        "weekday.fri.short",
        "weekday.sat.short",
        "weekday.sun.short",
        "detail.history.title",
        "detail.history.hint",
        "detail.archive",
        "detail.restore",
        "detail.delete",
        "detail.delete.title",
        "detail.delete.message",
        "detail.more.accessibility",
        "stats.streak",
        "stats.completion",
        "stats.checkins",
        "status.completed",
        "status.notCompleted",
        "accessibility.color.format",
        "accessibility.symbol.format",
        "accessibility.selected",
        "storage.error.title",
        "storage.error.message",
        "shortcut.habit.type",
        "shortcut.habit.parameter",
        "shortcut.complete.title",
        "shortcut.complete.description",
        "shortcut.complete.success",
        "shortcut.undo.title",
        "shortcut.undo.description",
        "shortcut.undo.success",
        "shortcut.notDue",
        "insights.noData", "insights.title", "insights.week", "insights.month",
        "insights.ratio", "insights.skipped", "insights.note",
        "backup.menu", "backup.export", "backup.import",
        "backup.chooseMode", "backup.merge", "backup.replace",
        "backup.warning", "backup.result", "backup.success",
        "habit.multi.target.format", "habit.multi.target.hint",
        "habit.multi.target.locked", "habit.multi.slot.format",
        "habit.multi.checked", "habit.multi.unchecked",
        "habit.goal.kind", "habit.goal.checks", "habit.goal.quantity",
        "habit.goal.duration", "habit.goal.quantity.format",
        "habit.goal.duration.format", "habit.goal.quantity.progress",
        "habit.goal.duration.progress", "habit.goal.add", "habit.goal.subtract",
        "groups.select", "groups.none", "groups.add", "groups.delete", "groups.placeholder",
        "backup.error.version", "backup.error.invalid", "backup.error.unreadable",
        "insights.weekly.title", "insights.fourWeeks", "insights.twelveWeeks",
        "insights.weekly.note", "insights.weekly.ratio", "insights.weekly.neutral",
        "insights.interval.title", "insights.ninetyDays", "insights.interval.note",
        "insights.interval.occurrences", "insights.interval.average", "insights.interval.noGap",
        "habit.history.edit", "habit.history.progress", "habit.history.error"
    ]

    func testPickerOffersOnlyBundledLocales() {
        XCTAssertEqual(ChickMarkLanguage.supported, ["ru", "en", "es", "de", "fr", "it", "pt-BR"])
        XCTAssertEqual(
            ChickMarkLanguage.orderedLanguages(["fr", "en", "Base", "ru", "es", "en"]),
            ["ru", "en", "es", "fr"]
        )
        XCTAssertEqual(
            ChickMarkLanguage.resolvedIdentifier(
                for: "system", preferred: ["fr-FR", "es-ES"],
                available: ChickMarkLanguage.supported
            ),
            "fr"
        )
        XCTAssertEqual(
            ChickMarkLanguage.resolvedIdentifier(
                for: "fr", preferred: ["ja-JP"],
                available: ChickMarkLanguage.supported
            ),
            "fr"
        )
        XCTAssertEqual(
            ChickMarkLanguage.orderedLanguages(["en", "ja", "de"]),
            ["en", "de", "ja"]
        )
    }

    func testItalianCatalogAndSystemLocaleSelection() {
        let available = ChickMarkLanguage.supported
        XCTAssertEqual(
            ChickMarkLanguage.resolvedIdentifier(for: "system", preferred: ["it-IT", "en"],
                                                available: available), "it")
        XCTAssertEqual(ChickMarkLanguage.displayName(for: "it"), "Italiano")
        XCTAssertEqual(L10n.string("today.title", language: "it"), "Oggi")
        XCTAssertEqual(L10n.string("habit.create", language: "it"), "Crea abitudine")
        let template = L10n.string("today.progress.format", language: "it")
        XCTAssertEqual(String(format: template, 1, 3), "Spuntate: 1 di 3")
    }

    func testBrazilianPortugueseRegionalLocaleResolutionAndCopy() {
        let available = ["ru", "en", "de", "pt-BR"]
        XCTAssertEqual(
            ChickMarkLanguage.resolvedIdentifier(
                for: "system", preferred: ["pt-BR", "en-US"],
                available: available
            ),
            "pt-BR"
        )
        XCTAssertEqual(
            ChickMarkLanguage.resolvedIdentifier(
                for: "system", preferred: ["pt_BR", "en-US"],
                available: available
            ),
            "pt-BR"
        )
        XCTAssertEqual(
            ChickMarkLanguage.resolvedIdentifier(
                for: "pt-BR", preferred: ["en-US"], available: available
            ),
            "pt-BR"
        )
        XCTAssertEqual(ChickMarkLanguage.displayName(for: "pt-BR"), "Português (Brasil)")
        XCTAssertEqual(L10n.string("today.title", language: "pt-BR"), "Hoje")
        XCTAssertEqual(L10n.string("habit.create", language: "pt-BR"), "Criar hábito")
        let template = L10n.string("today.progress.format", language: "pt-BR")
        XCTAssertEqual(String(format: template, 1, 3), "Marcados: 1 de 3")
    }

    func testUnsupportedSystemLanguageFallsBackToEnglish() {
        let available = ["ru", "en", "es"]
        for systemLanguages in [["fr"], ["ja-JP"], ["hi-IN", "zh-Hans"]] {
            XCTAssertEqual(
                ChickMarkLanguage.resolvedIdentifier(
                    for: "system", preferred: systemLanguages, available: available
                ),
                "en"
            )
        }
        XCTAssertEqual(
            ChickMarkLanguage.resolvedIdentifier(
                for: "system", preferred: ["fr-FR", "es-ES"], available: available
            ),
            "es"
        )
        XCTAssertEqual(
            ChickMarkLanguage.resolvedIdentifier(
                for: "ru", preferred: ["ja-JP"], available: available
            ),
            "ru"
        )
        XCTAssertEqual(
            ChickMarkLanguage.resolvedIdentifier(
                for: "fr", preferred: ["ja-JP"], available: available
            ),
            "en"
        )
    }

    func testTodayProgressNamesResolvedNotJustCompletedHabits() {
        for (language, expected) in [
            ("ru", "Отмечено: 1 из 3"),
            ("en", "Marked: 1 of 3"),
            ("es", "Marcados: 1 de 3"),
            ("fr", "Validées : 1 sur 3")
        ] {
            let template = L10n.string("today.progress.format", language: language)
            XCTAssertEqual(String(format: template, 1, 3), expected)
        }
    }

    func testFrenchHabitCopyAndFormats() {
        XCTAssertEqual(L10n.string("today.title", language: "fr"), "Aujourd’hui")
        XCTAssertEqual(L10n.string("habit.create", language: "fr"), "Créer une habitude")
        XCTAssertEqual(L10n.string("habit.name.placeholder", language: "fr"), "Nom de l’habitude")
        XCTAssertEqual(L10n.string("language.title", language: "fr"), "Langue")
        XCTAssertEqual(L10n.string("language.system", language: "fr"), "Langue du système")
        let title = L10n.string("habit.streak.format", language: "fr")
        XCTAssertEqual(String(format: title, 12), "12 jours de suite")
        let days = L10n.string("today.progress.format", language: "fr")
        XCTAssertEqual(String(format: days, 1, 3), "Validées : 1 sur 3")
        XCTAssertEqual(
            String(format: L10n.string("schedule.interval.description.format", language: "fr"), 1),
            "Tous les 1 j après validation"
        )
        XCTAssertEqual(
            String(format: L10n.string("insights.weekly.ratio", language: "fr"), 1, 2),
            "Semaines : 1/2"
        )
        XCTAssertEqual(L10n.string("nonexistent.localized.key", language: "fr"),
                       "nonexistent.localized.key")
    }

    func testEnglishAndRussianContainAllRequiredKeys() throws {
        for language in ["en", "ru", "es", "fr"] {
            let path = try XCTUnwrap(
                Bundle.main.path(
                    forResource: language,
                    ofType: "lproj"
                )
            )
            let bundle = try XCTUnwrap(Bundle(path: path))

            for key in requiredKeys {
                let value = bundle.localizedString(
                    forKey: key,
                    value: nil,
                    table: nil
                )
                XCTAssertNotEqual(
                    value,
                    key,
                    "Missing \(language) localization for \(key)"
                )
            }
        }
    }
}
