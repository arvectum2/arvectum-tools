import SwiftData
import XCTest
@testable import HabitsByArvectum

@MainActor
final class ChickMarkBackupTests: XCTestCase {
    private func context() throws -> ModelContext {
        let schema = HabitsSchema.current
        let config = ModelConfiguration(
            "TestChickMarkBackup",
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: schema, configurations: [config]
        )
        return ModelContext(container)
    }

    func testRoundTripPreservesIdentitiesAndLocalReminders() throws {
        let source = try context()
        let habit = Habit(
            name: "Run", symbolName: "figure.run", reminderEnabled: true,
            reminderHour: 8, weeklyTarget: 3, sortOrder: 2
        )
        source.insert(habit)
        let completion = HabitCheckIn(habitID: habit.id, day: .now)
        source.insert(completion)
        source.insert(OneOffReminder(title: "Start", dueAt: .now))
        source.insert(HabitDayMutation(
            habitID: habit.id, dayKey: completion.dayKey!,
            updatedAt: .now, mutationID: UUID()
        ))
        try source.save()

        let backup = try ChickMarkBackupService.capture(from: source)
        let json = try JSONEncoder().encode(backup)
        let decoded = try JSONDecoder().decode(ChickMarkBackup.self, from: json)
        try decoded.validate()

        let destination = try context()
        try ChickMarkBackupService.restore(decoded, to: destination, mode: .merge)
        let restored = try destination.fetch(FetchDescriptor<Habit>())
        XCTAssertEqual(restored.count, 1)
        XCTAssertEqual(restored[0].id, habit.id)
        XCTAssertEqual(restored[0].name, "Run")
        XCTAssertEqual(restored[0].weeklyTarget, 3)
        XCTAssertEqual(restored[0].reminderHour, 8)
        XCTAssertEqual(try destination.fetch(FetchDescriptor<HabitCheckIn>()).count, 1)
        XCTAssertEqual(try destination.fetch(FetchDescriptor<HabitDayMutation>()).count, 1)
        XCTAssertEqual(try destination.fetch(FetchDescriptor<OneOffReminder>()).count, 1)

        try ChickMarkBackupService.restore(decoded, to: destination, mode: .merge)
        XCTAssertEqual(try destination.fetch(FetchDescriptor<Habit>()).count, 1)
        XCTAssertEqual(try destination.fetch(FetchDescriptor<HabitCheckIn>()).count, 1)
    }

    func testReplaceDropsPreviousRecords() throws {
        let source = try context()
        source.insert(Habit(name: "Keep"))
        try source.save()
        let backup = try ChickMarkBackupService.capture(from: source)
        let destination = try context()
        destination.insert(Habit(name: "Remove"))
        try destination.save()
        try ChickMarkBackupService.restore(backup, to: destination, mode: .replace)
        let records = try destination.fetch(FetchDescriptor<Habit>())
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.name, "Keep")
    }

    func testRejectsWrongFormatBeforeAnyMutation() throws {
        let source = try context()
        source.insert(Habit(name: "Stay"))
        try source.save()
        let backup = try ChickMarkBackupService.capture(from: source)
        let data = try JSONEncoder().encode(backup)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["formatVersion"] = 999
        let tampered = try JSONSerialization.data(withJSONObject: object)
        let invalid = try JSONDecoder().decode(ChickMarkBackup.self, from: tampered)
        XCTAssertThrowsError(try ChickMarkBackupService.restore(invalid, to: source, mode: .replace))
        XCTAssertEqual(try source.fetch(FetchDescriptor<Habit>()).count, 1)
    }
}
