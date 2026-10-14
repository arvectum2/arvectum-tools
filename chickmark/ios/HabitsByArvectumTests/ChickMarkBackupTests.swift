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

    // A1: a JSON merge must be repeatable and must not replace an existing
    // device's private history, even when all supported record kinds coexist.
    func testMergeRetainsExistingDataAndIsIdempotentAcrossHistoryKinds() throws {
        let source = try context()
        let habit = Habit(name: "Archive", reminderEnabled: true)
        source.insert(habit)
        let t0 = Date(timeIntervalSince1970: 1_760_000_000)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let check = HabitCheckIn(habitID: habit.id, day: t0, calendar: utc)
        source.insert(check)
        source.insert(HabitSkip(habitID: habit.id, day: t0.addingTimeInterval(86_400), calendar: utc))
        source.insert(HabitPausePeriod(habitID: habit.id, startedAt: t0.addingTimeInterval(2 * 86_400), calendar: utc))
        source.insert(HabitDayMutation(habitID: habit.id, dayKey: try XCTUnwrap(check.dayKey),
                                       updatedAt: t0, mutationID: UUID()))
        source.insert(OneOffReminder(title: "Inspect", dueAt: t0))
        try source.save()

        let exported = try ChickMarkBackupService.capture(from: source)
        let backup = try JSONDecoder().decode(ChickMarkBackup.self,
                                               from: JSONEncoder().encode(exported))
        let target = try context()
        let preExisting = Habit(name: "Keep my local history")
        target.insert(preExisting)
        let original = HabitCheckIn(habitID: preExisting.id, day: t0, calendar: utc)
        target.insert(original)
        try target.save()

        for _ in 0..<2 {
            try ChickMarkBackupService.restore(backup, to: target, mode: .merge)
            let restored = try target.fetch(FetchDescriptor<HabitCheckIn>())
            XCTAssertEqual(restored.count, 2)
            XCTAssertEqual(Set(restored.map(\.id)), [check.id, original.id])
            XCTAssertEqual(restored.first(where: { $0.id == check.id })?.dayKey, check.dayKey)
        }
        XCTAssertEqual(try target.fetch(FetchDescriptor<Habit>()).count, 2)
        XCTAssertEqual(try target.fetch(FetchDescriptor<HabitSkip>()).count, 1)
        XCTAssertEqual(try target.fetch(FetchDescriptor<HabitPausePeriod>()).count, 1)
        XCTAssertEqual(try target.fetch(FetchDescriptor<HabitDayMutation>()).count, 1)
        XCTAssertEqual(try target.fetch(FetchDescriptor<OneOffReminder>()).count, 1)
        XCTAssertTrue(try target.fetch(FetchDescriptor<Habit>()).contains {
            $0.id == preExisting.id && $0.name == "Keep my local history"
        })
    }

    // A1: corrupt cross-references are rejected before any merge or replace
    // can mutate existing history on the receiving device.
    func testOrphanedCheckInRejectsImportWithoutMutatingHistory() throws {
        let source = try context()
        let habit = Habit(name: "Imported")
        source.insert(habit)
        source.insert(HabitCheckIn(habitID: habit.id, day: .now))
        try source.save()
        let backup = try ChickMarkBackupService.capture(from: source)
        let data = try JSONEncoder().encode(backup)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var records = try XCTUnwrap(object["checkIns"] as? [[String: Any]])
        records[0]["habitID"] = UUID().uuidString
        object["checkIns"] = records
        let invalid = try JSONDecoder().decode(ChickMarkBackup.self,
                    from: JSONSerialization.data(withJSONObject: object))

        let target = try context()
        let existing = Habit(name: "Unchanged")
        target.insert(existing)
        let old = HabitCheckIn(habitID: existing.id, day: .now)
        target.insert(old)
        try target.save()
        for mode: ChickMarkBackupService.ImportMode in [.merge, .replace] {
            XCTAssertThrowsError(try ChickMarkBackupService.restore(invalid, to: target, mode: mode))
        }
        let habits = try target.fetch(FetchDescriptor<Habit>())
        let checkIns = try target.fetch(FetchDescriptor<HabitCheckIn>())
        XCTAssertEqual(habits.map(\.id), [existing.id])
        XCTAssertEqual(checkIns.map(\.id), [old.id])
    }

    // A1/A4: ephemeral HealthKit readings must not leak to JSON backup.
    func testExportContainsNoHealthKitProjectionOrRawMeasurements() throws {
        let source = try context()
        source.insert(Habit(name: "Walking"))
        try source.save()
        let data = try JSONEncoder().encode(ChickMarkBackupService.capture(from: source))
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertFalse(json.contains("healthRuleMetric"))
        XCTAssertFalse(json.contains("healthRuleTarget"))
        XCTAssertFalse(json.contains("completedDayKeys"))
        XCTAssertFalse(json.contains("liveProgress"))
        XCTAssertFalse(json.contains("healthSamples"))
    }

}
