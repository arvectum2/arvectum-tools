import Foundation
import XCTest
@testable import HabitsByArvectum

final class HabitWidgetBridgeTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "HabitsWidgetBridgeTests.\(UUID().uuidString)"
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

    func testSnapshotRoundTrip() {
        let habitID = UUID()
        let snapshot = HabitWidgetSnapshot(
            generatedAt: Date(timeIntervalSince1970: 1_800_000_000),
            dayKey: "2027-01-15",
            completedCount: 1,
            skippedCount: 1,
            totalCount: 3,
            habits: [
                HabitWidgetHabit(
                    id: habitID,
                    name: "Reading",
                    symbolName: "book.fill",
                    colorHex: "8B5CF6",
                    completed: true,
                    skipped: false,
                    streak: 12
                )
            ]
        )

        HabitWidgetBridge.saveSnapshot(snapshot)

        XCTAssertEqual(HabitWidgetBridge.loadSnapshot(), snapshot)
        XCTAssertEqual(HabitWidgetBridge.loadSnapshot().resolvedCount, 2)
        XCTAssertEqual(
            HabitWidgetBridge.loadSnapshot().progress,
            2.0 / 3.0,
            accuracy: 0.0001
        )
    }

    func testCurrentSnapshotRejectsPreviousCalendarDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(
            from: DateComponents(year: 2027, month: 1, day: 16, hour: 0, minute: 1)
        )!
        let stale = HabitWidgetSnapshot(
            generatedAt: now.addingTimeInterval(-120),
            dayKey: "2027-01-15",
            completedCount: 2,
            skippedCount: 0,
            totalCount: 2,
            habits: []
        )
        HabitWidgetBridge.saveSnapshot(stale)

        XCTAssertEqual(
            HabitWidgetBridge.loadCurrentSnapshot(
                now: now,
                calendar: calendar
            ),
            .empty
        )
    }

    func testCurrentSnapshotKeepsSameCalendarDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(
            from: DateComponents(year: 2027, month: 1, day: 16, hour: 23, minute: 59)
        )!
        let snapshot = HabitWidgetSnapshot(
            generatedAt: now,
            dayKey: "2027-01-16",
            completedCount: 1,
            skippedCount: 0,
            totalCount: 2,
            habits: []
        )
        HabitWidgetBridge.saveSnapshot(snapshot)

        XCTAssertEqual(
            HabitWidgetBridge.loadCurrentSnapshot(
                now: now,
                calendar: calendar
            ),
            snapshot
        )
    }

    func testAppendCommandIsIdempotentByCommandID() {
        let command = HabitWidgetCommand(
            id: UUID(),
            habitID: UUID(),
            dayKey: "2027-01-15",
            completed: true,
            createdAt: Date(timeIntervalSince1970: 1_800_000_000)
        )

        HabitWidgetBridge.appendCommand(command)
        HabitWidgetBridge.appendCommand(command)

        XCTAssertEqual(HabitWidgetBridge.loadCommands(), [command])
    }

    func testOptimisticCompletionClearsSkipAndUpdatesCounts() {
        let habitID = UUID()
        HabitWidgetBridge.saveSnapshot(
            HabitWidgetSnapshot(
                generatedAt: .distantPast,
                dayKey: "2027-01-15",
                completedCount: 0,
                skippedCount: 1,
                totalCount: 1,
                habits: [
                    HabitWidgetHabit(
                        id: habitID,
                        name: "Walk",
                        symbolName: "figure.walk",
                        colorHex: "43E5C5",
                        completed: false,
                        skipped: true,
                        streak: 3
                    )
                ]
            )
        )

        let command = HabitWidgetCommand(
            habitID: habitID,
            dayKey: "2027-01-15",
            completed: true
        )
        HabitWidgetBridge.applyOptimistic(command)

        let result = HabitWidgetBridge.loadSnapshot()
        XCTAssertEqual(result.completedCount, 1)
        XCTAssertEqual(result.skippedCount, 0)
        XCTAssertTrue(result.habits[0].completed)
        XCTAssertFalse(result.habits[0].skipped)
    }

    func testOptimisticCommandForDifferentDayIsIgnored() {
        let habitID = UUID()
        let original = HabitWidgetSnapshot(
            generatedAt: Date(timeIntervalSince1970: 1_800_000_000),
            dayKey: "2027-01-15",
            completedCount: 0,
            skippedCount: 0,
            totalCount: 1,
            habits: [
                HabitWidgetHabit(
                    id: habitID,
                    name: "Water",
                    symbolName: "drop.fill",
                    colorHex: "43E5C5",
                    completed: false,
                    skipped: false,
                    streak: 0
                )
            ]
        )
        HabitWidgetBridge.saveSnapshot(original)

        HabitWidgetBridge.applyOptimistic(
            HabitWidgetCommand(
                habitID: habitID,
                dayKey: "2027-01-16",
                completed: true
            )
        )

        XCTAssertEqual(HabitWidgetBridge.loadSnapshot(), original)
    }

    func testRapidCommandsForSameHabitDayCompactToLatestState() {
        let habitID = UUID()

        for index in 0..<50 {
            HabitWidgetBridge.appendCommand(
                HabitWidgetCommand(
                    id: UUID(),
                    habitID: habitID,
                    dayKey: "2027-01-15",
                    completed: index.isMultiple(of: 2),
                    createdAt: Date(timeIntervalSince1970: Double(index))
                )
            )
        }

        let commands = HabitWidgetBridge.loadCommands()
        XCTAssertEqual(commands.count, 1)
        XCTAssertEqual(commands.first?.createdAt, Date(timeIntervalSince1970: 49))
        XCTAssertEqual(commands.first?.completed, false)
    }


    func testWidgetPresentationKeepsUnresolvedHabitsVisibleFirst() {
        let completed = HabitWidgetHabit(
            id: UUID(),
            name: "Reading",
            symbolName: "book.fill",
            colorHex: "8B5CF6",
            completed: true,
            skipped: false,
            streak: 4
        )
        let unresolvedA = HabitWidgetHabit(
            id: UUID(),
            name: "Water",
            symbolName: "drop.fill",
            colorHex: "43E5C5",
            completed: false,
            skipped: false,
            streak: 2
        )
        let skipped = HabitWidgetHabit(
            id: UUID(),
            name: "Walk",
            symbolName: "figure.walk",
            colorHex: "F59E0B",
            completed: false,
            skipped: true,
            streak: 1
        )
        let unresolvedB = HabitWidgetHabit(
            id: UUID(),
            name: "Journal",
            symbolName: "pencil",
            colorHex: "8B5CF6",
            completed: false,
            skipped: false,
            streak: 0
        )

        let result = HabitWidgetPresentation.prioritized([
            completed,
            unresolvedA,
            skipped,
            unresolvedB
        ])

        XCTAssertEqual(
            result.map(\.id),
            [
                unresolvedA.id,
                unresolvedB.id,
                completed.id,
                skipped.id
            ]
        )
    }

    func testCommandQueueIsBoundedToNewestHundredTargets() {
        for index in 0..<105 {
            HabitWidgetBridge.appendCommand(
                HabitWidgetCommand(
                    id: UUID(),
                    habitID: UUID(),
                    dayKey: "2027-01-15",
                    completed: index.isMultiple(of: 2),
                    createdAt: Date(timeIntervalSince1970: Double(index))
                )
            )
        }

        let commands = HabitWidgetBridge.loadCommands()
        XCTAssertEqual(commands.count, 100)
        XCTAssertEqual(
            commands.first?.createdAt,
            Date(timeIntervalSince1970: 5)
        )
        XCTAssertEqual(
            commands.last?.createdAt,
            Date(timeIntervalSince1970: 104)
        )
    }
}
