import SwiftData
import XCTest
@testable import HabitsByArvectum

final class CrossSurfaceDurabilityTests: XCTestCase {
    @MainActor
    func testExternalCommandsRemainRetryableWhenStoreCannotSave() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let storeURL = directory.appendingPathComponent("habits.store")
        let schema = HabitsSchema.current
        let habitID = UUID()

        do {
            let writable = try makeContainer(
                schema: schema,
                storeURL: storeURL,
                allowsSave: true
            )
            let context = ModelContext(writable)
            context.insert(
                Habit(
                    id: habitID,
                    name: "Read",
                    createdAt: Date().addingTimeInterval(-86_400)
                )
            )
            try context.save()
        }

        var readOnly: ModelContainer? = try makeContainer(
            schema: schema,
            storeURL: storeURL,
            allowsSave: false
        )
        let readOnlyContainer = try XCTUnwrap(readOnly)

        PhoneWatchSyncCoordinator.shared.configure(
            modelContainer: readOnlyContainer
        )
        HabitWidgetCoordinator.shared.configure(
            modelContainer: readOnlyContainer,
            refreshImmediately: false
        )

        let watchCommandID = UUID()
        let watchCommand = HabitCompletionCommand(
            id: watchCommandID,
            habitID: habitID,
            dayKey: HabitDayKey.make(for: .now),
            completed: true
        )

        let snapshot = try XCTUnwrap(
            PhoneWatchSyncCoordinator.shared.apply(
                command: watchCommand
            )
        )

        XCTAssertFalse(
            snapshot.acknowledgedCommandIDs.contains(watchCommandID)
        )
        XCTAssertFalse(
            snapshot.habits.first(where: { $0.id == habitID })?
                .completed ?? true
        )

#if DEBUG
        let suiteName = "CrossSurfaceDurabilityTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        HabitWidgetBridge.defaultsOverride = defaults
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            HabitWidgetBridge.defaultsOverride = nil
        }

        let widgetCommand = HabitWidgetCommand(
            habitID: habitID,
            dayKey: HabitDayKey.make(for: .now),
            completed: true
        )
        HabitWidgetBridge.appendCommand(widgetCommand)
        HabitWidgetCoordinator.shared.processPendingCommands()

        XCTAssertEqual(
            HabitWidgetBridge.loadCommands().map(\.id),
            [widgetCommand.id]
        )
#endif

        let reset = try makeInMemoryContainer(schema: schema)
        PhoneWatchSyncCoordinator.shared.configure(modelContainer: reset)
        HabitWidgetCoordinator.shared.configure(
            modelContainer: reset,
            refreshImmediately: false
        )
        readOnly = nil
    }

    private func makeContainer(
        schema: Schema,
        storeURL: URL,
        allowsSave: Bool
    ) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            "CrossSurfaceDurabilityTests",
            schema: schema,
            url: storeURL,
            allowsSave: allowsSave,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: HabitsMigrationPlan.self,
            configurations: [configuration]
        )
    }

    private func makeInMemoryContainer(
        schema: Schema
    ) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            "CrossSurfaceDurabilityReset",
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: HabitsMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
