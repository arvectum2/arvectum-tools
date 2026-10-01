import XCTest
@testable import HabitsByArvectum

final class HabitShortcutsTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "HabitShortcutsTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        HabitWidgetBridge.defaultsOverride = defaults
    }

    override func tearDown() {
        HabitWidgetBridge.defaultsOverride = nil
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testCurrentEntitiesReflectTodaySnapshotOrder() {
        let first = UUID()
        let second = UUID()
        HabitWidgetBridge.saveSnapshot(
            HabitWidgetSnapshot(
                generatedAt: .now,
                dayKey: HabitWidgetBridge.dayKey(for: .now),
                completedCount: 0,
                skippedCount: 0,
                totalCount: 2,
                habits: [
                    HabitWidgetHabit(
                        id: first,
                        name: "Read",
                        symbolName: "book.fill",
                        colorHex: "8B5CF6",
                        completed: false,
                        skipped: false,
                        streak: 2
                    ),
                    HabitWidgetHabit(
                        id: second,
                        name: "Walk",
                        symbolName: "figure.walk",
                        colorHex: "43E5C5",
                        completed: false,
                        skipped: false,
                        streak: 4
                    )
                ]
            )
        )

        XCTAssertEqual(
            HabitShortcutBridge.currentEntities().map(\.id),
            [first, second]
        )
    }

    func testCommandUsesCurrentSnapshotDayAndDesiredState() throws {
        let habitID = UUID()
        let dayKey = HabitWidgetBridge.dayKey(for: .now)
        HabitWidgetBridge.saveSnapshot(
            HabitWidgetSnapshot(
                generatedAt: .now,
                dayKey: dayKey,
                completedCount: 0,
                skippedCount: 0,
                totalCount: 1,
                habits: [
                    HabitWidgetHabit(
                        id: habitID,
                        name: "Read",
                        symbolName: "book.fill",
                        colorHex: "8B5CF6",
                        completed: false,
                        skipped: false,
                        streak: 0
                    )
                ]
            )
        )

        let command = try XCTUnwrap(
            HabitShortcutBridge.command(
                for: habitID,
                completed: true
            )
        )

        XCTAssertEqual(command.habitID, habitID)
        XCTAssertEqual(command.dayKey, dayKey)
        XCTAssertTrue(command.completed)
    }

    func testCommandRejectsHabitNotDueToday() {
        HabitWidgetBridge.saveSnapshot(
            HabitWidgetSnapshot(
                generatedAt: .now,
                dayKey: HabitWidgetBridge.dayKey(for: .now),
                completedCount: 0,
                skippedCount: 0,
                totalCount: 0,
                habits: []
            )
        )

        XCTAssertNil(
            HabitShortcutBridge.command(
                for: UUID(),
                completed: true
            )
        )
    }
}
