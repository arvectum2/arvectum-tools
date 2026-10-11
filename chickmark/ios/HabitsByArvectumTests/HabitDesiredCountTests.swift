import SwiftData
import XCTest
@testable import HabitsByArvectum

@MainActor
final class HabitDesiredCountTests: XCTestCase {
    private let dayKey = "2026-10-10"

    private func context() throws -> ModelContext {
        let schema = Schema([
            Habit.self, HabitCheckIn.self, HabitSkip.self,
            HabitPausePeriod.self, HabitDayMutation.self
        ])
        let container = try ModelContainer(
            for: schema, configurations: [
                ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            ]
        )
        return ModelContext(container)
    }

    func testOutOfOrderDesiredCountsConvergeAndReplayIsIdempotent() throws {
        let context = try context()
        let habit = Habit(name: "Water", weeklyTarget: 1005)
        context.insert(habit)
        let early = Date(timeIntervalSince1970: 1_780_000_000)
        let late = early.addingTimeInterval(3)
        let earlierID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let laterID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        XCTAssertTrue(HabitCompletionMutation.setCompletion(
            habitID: habit.id, dayKey: dayKey,
            completed: false, desiredCount: 4, context: context,
            mutationAt: early, mutationID: earlierID
        ))
        try context.save()

        XCTAssertTrue(HabitCompletionMutation.setCompletion(
            habitID: habit.id, dayKey: dayKey,
            completed: false, desiredCount: 2, context: context,
            mutationAt: late, mutationID: laterID
        ))
        try context.save()
        let rows = try context.fetch(FetchDescriptor<HabitCheckIn>())
        XCTAssertEqual(rows.count, 2)
        XCTAssertFalse(HabitCompletionMutation.setCompletion(
            habitID: habit.id, dayKey: dayKey,
            completed: false, desiredCount: 4, context: context,
            mutationAt: early, mutationID: earlierID
        ))
        XCTAssertFalse(HabitCompletionMutation.setCompletion(
            habitID: habit.id, dayKey: dayKey,
            completed: false, desiredCount: 2, context: context,
            mutationAt: late, mutationID: laterID
        ))
        XCTAssertEqual(try context.fetch(FetchDescriptor<HabitCheckIn>()).count, 2)
    }

    func testOldCommandsWithoutDesiredCountStillDecode() throws {
        let watch = HabitCompletionCommand(
            habitID: UUID(), dayKey: dayKey, completed: true
        )
        let widget = HabitWidgetCommand(
            habitID: UUID(), dayKey: dayKey, completed: false
        )

        func stripNewField(_ data: Data) throws -> Data {
            var value = try XCTUnwrap(
                JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            value.removeValue(forKey: "desiredCount")
            return try JSONSerialization.data(withJSONObject: value)
        }

        let legacyWatchData = try stripNewField(JSONEncoder().encode(watch))
        let legacyWidgetData = try stripNewField(JSONEncoder().encode(widget))
        XCTAssertNil(
            try JSONDecoder().decode(
                HabitCompletionCommand.self, from: legacyWatchData
            ).desiredCount
        )
        XCTAssertNil(
            try JSONDecoder().decode(
                HabitWidgetCommand.self, from: legacyWidgetData
            ).desiredCount
        )
    }

    func testWatchPendingCommandReconciliationUsesPartialCount() {
        let habit = UUID()
        let now = Date(timeIntervalSince1970: 1_800_000_010)
        var snapshot = HabitSyncSnapshot(
            generatedAt: now, dayKey: dayKey,
            completedCount: 0, totalCount: 1,
            habits: [.init(
                id: habit, name: "Water", symbolName: "drop.fill",
                colorHex: "43E5C5", completed: false, streak: 0,
                dailyTarget: 5, dailyCount: 1
            )]
        )
        let command = HabitCompletionCommand(
            habitID: habit, dayKey: dayKey, completed: false,
            desiredCount: 3, createdAt: now.addingTimeInterval(1)
        )
        let optimistic = HabitSyncReconciler.reconcile(
            incoming: snapshot, pendingCommands: [command]
        )
        XCTAssertEqual(optimistic.snapshot.habits[0].dailyCount, 3)
        XCTAssertEqual(optimistic.remainingCommands.count, 1)

        snapshot.generatedAt = now.addingTimeInterval(2)
        snapshot.habits[0].dailyCount = 3
        let settled = HabitSyncReconciler.reconcile(
            incoming: snapshot, pendingCommands: [command]
        )
        XCTAssertTrue(settled.remainingCommands.isEmpty)
    }
}
