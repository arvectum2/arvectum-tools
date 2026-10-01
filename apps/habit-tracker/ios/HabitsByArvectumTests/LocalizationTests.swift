import XCTest
@testable import HabitsByArvectum

final class LocalizationTests: XCTestCase {
    private let requiredKeys = [
        "today.title",
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
        "common.delete",
        "quick.water",
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
        "accessibility.selected"
    ]

    func testEnglishAndRussianContainAllRequiredKeys() throws {
        for language in ["en", "ru"] {
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
