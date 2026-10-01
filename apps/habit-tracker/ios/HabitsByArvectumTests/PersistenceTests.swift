import SwiftData
import XCTest
@testable import HabitsByArvectum

final class PersistenceTests: XCTestCase {
    func testHabitAndCheckInSurviveContainerRecreation() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        let storeURL = directory.appendingPathComponent("habits.store")
        let schema = Schema([
            Habit.self,
            HabitCheckIn.self,
            HabitSkip.self,
            HabitPausePeriod.self,
            HabitDayMutation.self
        ])
        let habitID = UUID()
        let checkInDate = Date(timeIntervalSince1970: 1_790_784_000)
        let skipDate = checkInDate.addingTimeInterval(86_400)
        let pauseDate = skipDate.addingTimeInterval(86_400)
        var checkInCalendar = Calendar(identifier: .gregorian)
        checkInCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let expectedDayKey = HabitDayKey.make(
            for: checkInDate,
            calendar: checkInCalendar
        )

        do {
            let container = try makeContainer(
                schema: schema,
                storeURL: storeURL
            )
            let context = ModelContext(container)
            context.insert(
                Habit(
                    id: habitID,
                    name: "Чтение",
                    symbolName: "book.fill",
                    colorHex: "43E5C5",
                    reminderEnabled: true,
                    reminderHour: 7,
                    reminderMinute: 45,
                    pausedAt: pauseDate
                )
            )
            context.insert(
                HabitCheckIn(
                    habitID: habitID,
                    day: checkInDate,
                    calendar: checkInCalendar
                )
            )
            context.insert(
                HabitSkip(
                    habitID: habitID,
                    day: skipDate,
                    calendar: checkInCalendar
                )
            )
            context.insert(
                HabitPausePeriod(
                    habitID: habitID,
                    startedAt: pauseDate,
                    calendar: checkInCalendar
                )
            )
            try context.save()
        }

        do {
            let container = try makeContainer(
                schema: schema,
                storeURL: storeURL
            )
            let context = ModelContext(container)
            let habits = try context.fetch(FetchDescriptor<Habit>())
            let checkIns = try context.fetch(FetchDescriptor<HabitCheckIn>())
            let skips = try context.fetch(FetchDescriptor<HabitSkip>())
            let pausePeriods = try context.fetch(
                FetchDescriptor<HabitPausePeriod>()
            )

            XCTAssertEqual(habits.count, 1)
            XCTAssertEqual(habits.first?.id, habitID)
            XCTAssertEqual(habits.first?.name, "Чтение")
            XCTAssertEqual(habits.first?.reminderEnabled, true)
            XCTAssertEqual(habits.first?.reminderHour, 7)
            XCTAssertEqual(habits.first?.reminderMinute, 45)
            XCTAssertEqual(habits.first?.pausedAt, pauseDate)
            XCTAssertEqual(checkIns.count, 1)
            XCTAssertEqual(checkIns.first?.habitID, habitID)
            XCTAssertEqual(checkIns.first?.day, checkInDate)
            XCTAssertEqual(checkIns.first?.dayKey, expectedDayKey)
            XCTAssertEqual(skips.count, 1)
            XCTAssertEqual(skips.first?.habitID, habitID)
            XCTAssertEqual(
                skips.first?.dayKey,
                HabitDayKey.make(
                    for: skipDate,
                    calendar: checkInCalendar
                )
            )
            XCTAssertEqual(pausePeriods.count, 1)
            XCTAssertEqual(pausePeriods.first?.habitID, habitID)
            XCTAssertEqual(
                pausePeriods.first?.startDayKey,
                HabitDayKey.make(
                    for: pauseDate,
                    calendar: checkInCalendar
                )
            )
            XCTAssertNil(pausePeriods.first?.endDayKeyExclusive)
        }
    }

    private func makeContainer(
        schema: Schema,
        storeURL: URL
    ) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            "PersistenceTests",
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}
