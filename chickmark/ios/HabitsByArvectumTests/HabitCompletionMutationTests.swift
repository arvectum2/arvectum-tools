import SwiftData
import XCTest
@testable import HabitsByArvectum

@MainActor
final class HabitCompletionMutationTests: XCTestCase {
    func testDuplicateCompleteDeliveryCreatesSingleCheckIn() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let habitID = UUID()
        let dayKey = "2026-10-01"

        XCTAssertTrue(
            HabitCompletionMutation.setCompletion(
                habitID: habitID,
                dayKey: dayKey,
                completed: true,
                context: context
            )
        )
        XCTAssertFalse(
            HabitCompletionMutation.setCompletion(
                habitID: habitID,
                dayKey: dayKey,
                completed: true,
                context: context
            )
        )
        try context.save()

        let checkIns = try context.fetch(FetchDescriptor<HabitCheckIn>())
        XCTAssertEqual(checkIns.count, 1)
        XCTAssertEqual(checkIns.first?.habitID, habitID)
        XCTAssertEqual(checkIns.first?.dayKey, dayKey)
    }

    func testCompleteThenUndoConvergesToIncomplete() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let habitID = UUID()
        let dayKey = "2026-10-01"

        _ = HabitCompletionMutation.setCompletion(
            habitID: habitID,
            dayKey: dayKey,
            completed: true,
            context: context
        )
        XCTAssertTrue(
            HabitCompletionMutation.setCompletion(
                habitID: habitID,
                dayKey: dayKey,
                completed: false,
                context: context
            )
        )
        XCTAssertFalse(
            HabitCompletionMutation.setCompletion(
                habitID: habitID,
                dayKey: dayKey,
                completed: false,
                context: context
            )
        )
        try context.save()

        XCTAssertTrue(
            try context.fetch(FetchDescriptor<HabitCheckIn>()).isEmpty
        )
    }

    func testCompletionWinsOverExistingSkip() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let habitID = UUID()
        let day = date(2026, 10, 1)
        context.insert(
            HabitSkip(
                habitID: habitID,
                day: day,
                calendar: calendar
            )
        )
        try context.save()

        XCTAssertTrue(
            HabitCompletionMutation.setCompletion(
                habitID: habitID,
                dayKey: "2026-10-01",
                completed: true,
                context: context,
                calendar: calendar
            )
        )
        try context.save()

        XCTAssertTrue(
            try context.fetch(FetchDescriptor<HabitSkip>()).isEmpty
        )
        XCTAssertEqual(
            try context.fetch(FetchDescriptor<HabitCheckIn>()).count,
            1
        )
    }

    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: 12
            )
        )!
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Habit.self,
            HabitCheckIn.self,
            HabitSkip.self,
            HabitPausePeriod.self,
            HabitDayMutation.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}
