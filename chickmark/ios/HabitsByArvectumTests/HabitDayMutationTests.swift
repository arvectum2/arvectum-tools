import SwiftData
import XCTest
@testable import HabitsByArvectum

@MainActor
final class HabitDayMutationTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    func testOlderCompletionCannotOverrideNewerCompletionState() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let habitID = UUID()
        let dayKey = "2026-10-01"
        let older = Date(timeIntervalSince1970: 100)
        let newer = Date(timeIntervalSince1970: 200)

        XCTAssertFalse(
            HabitCompletionMutation.setCompletion(
                habitID: habitID,
                dayKey: dayKey,
                completed: false,
                context: context,
                mutationAt: newer,
                mutationID: UUID(
                    uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"
                )!,
                calendar: calendar
            )
        )

        let ledgerAfterNoOp = try context.fetch(
            FetchDescriptor<HabitDayMutation>()
        )
        XCTAssertEqual(ledgerAfterNoOp.count, 1)
        XCTAssertEqual(ledgerAfterNoOp.first?.updatedAt, newer)

        XCTAssertFalse(
            HabitCompletionMutation.setCompletion(
                habitID: habitID,
                dayKey: dayKey,
                completed: true,
                context: context,
                mutationAt: older,
                mutationID: UUID(
                    uuidString: "00000000-0000-0000-0000-000000000001"
                )!,
                calendar: calendar
            )
        )

        XCTAssertTrue(
            try context.fetch(FetchDescriptor<HabitCheckIn>()).isEmpty
        )
    }

    func testNewerSkipRejectsStaleWatchCompletion() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let habitID = UUID()
        let dayKey = "2026-10-01"

        XCTAssertTrue(
            HabitSkipMutation.setSkipped(
                habitID: habitID,
                dayKey: dayKey,
                skipped: true,
                context: context,
                mutationAt: Date(timeIntervalSince1970: 300),
                mutationID: UUID(
                    uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFE"
                )!,
                calendar: calendar
            )
        )

        XCTAssertFalse(
            HabitCompletionMutation.setCompletion(
                habitID: habitID,
                dayKey: dayKey,
                completed: true,
                context: context,
                mutationAt: Date(timeIntervalSince1970: 250),
                mutationID: UUID(
                    uuidString: "00000000-0000-0000-0000-000000000002"
                )!,
                calendar: calendar
            )
        )

        XCTAssertEqual(
            try context.fetch(FetchDescriptor<HabitSkip>()).count,
            1
        )
        XCTAssertTrue(
            try context.fetch(FetchDescriptor<HabitCheckIn>()).isEmpty
        )
    }

    func testEqualTimestampUsesMutationIDAsDeterministicTieBreaker() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let habitID = UUID()
        let dayKey = "2026-10-01"
        let timestamp = Date(timeIntervalSince1970: 400)
        let lowID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000003"
        )!
        let highID = UUID(
            uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFD"
        )!

        XCTAssertTrue(
            HabitCompletionMutation.setCompletion(
                habitID: habitID,
                dayKey: dayKey,
                completed: true,
                context: context,
                mutationAt: timestamp,
                mutationID: lowID,
                calendar: calendar
            )
        )

        XCTAssertTrue(
            HabitCompletionMutation.setCompletion(
                habitID: habitID,
                dayKey: dayKey,
                completed: false,
                context: context,
                mutationAt: timestamp,
                mutationID: highID,
                calendar: calendar
            )
        )

        XCTAssertFalse(
            HabitCompletionMutation.setCompletion(
                habitID: habitID,
                dayKey: dayKey,
                completed: true,
                context: context,
                mutationAt: timestamp,
                mutationID: lowID,
                calendar: calendar
            )
        )

        XCTAssertTrue(
            try context.fetch(FetchDescriptor<HabitCheckIn>()).isEmpty
        )
        let stamps = try context.fetch(
            FetchDescriptor<HabitDayMutation>()
        )
        XCTAssertEqual(stamps.count, 1)
        XCTAssertEqual(stamps.first?.mutationID, highID)
    }

    func testNewerCompletionClearsExistingSkip() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let habitID = UUID()
        let dayKey = "2026-10-01"

        XCTAssertTrue(
            HabitSkipMutation.setSkipped(
                habitID: habitID,
                dayKey: dayKey,
                skipped: true,
                context: context,
                mutationAt: Date(timeIntervalSince1970: 500),
                calendar: calendar
            )
        )

        XCTAssertTrue(
            HabitCompletionMutation.setCompletion(
                habitID: habitID,
                dayKey: dayKey,
                completed: true,
                context: context,
                mutationAt: Date(timeIntervalSince1970: 600),
                calendar: calendar
            )
        )

        XCTAssertTrue(
            try context.fetch(FetchDescriptor<HabitSkip>()).isEmpty
        )
        XCTAssertEqual(
            try context.fetch(FetchDescriptor<HabitCheckIn>()).count,
            1
        )
    }

    func testCompletionAndSkipRemainMutuallyExclusive() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let habitID = UUID()
        let dayKey = "2026-10-01"

        _ = HabitCompletionMutation.setCompletion(
            habitID: habitID,
            dayKey: dayKey,
            completed: true,
            context: context,
            mutationAt: Date(timeIntervalSince1970: 500),
            calendar: calendar
        )

        _ = HabitSkipMutation.setSkipped(
            habitID: habitID,
            dayKey: dayKey,
            skipped: true,
            context: context,
            mutationAt: Date(timeIntervalSince1970: 600),
            calendar: calendar
        )

        XCTAssertTrue(
            try context.fetch(FetchDescriptor<HabitCheckIn>()).isEmpty
        )
        XCTAssertEqual(
            try context.fetch(FetchDescriptor<HabitSkip>()).count,
            1
        )
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
