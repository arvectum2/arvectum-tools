import AppIntents
import Foundation
import WidgetKit

struct HabitShortcutEntity: AppEntity, Hashable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource(
            "shortcut.habit.type",
            defaultValue: "Habit"
        )
    )
    static var defaultQuery = HabitShortcutQuery()

    let id: UUID
    let name: String
    let symbolName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            image: .init(systemName: symbolName)
        )
    }
}

struct HabitShortcutQuery: EntityQuery {
    func entities(
        for identifiers: [UUID]
    ) async throws -> [HabitShortcutEntity] {
        let wanted = Set(identifiers)
        return HabitShortcutBridge.currentEntities()
            .filter { wanted.contains($0.id) }
    }

    func suggestedEntities() async throws -> [HabitShortcutEntity] {
        HabitShortcutBridge.currentEntities()
    }
}

enum HabitShortcutBridge {
    static func currentEntities(
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [HabitShortcutEntity] {
        HabitWidgetBridge.loadCurrentSnapshot(
            now: now,
            calendar: calendar
        ).habits.map {
            HabitShortcutEntity(
                id: $0.id,
                name: $0.name,
                symbolName: $0.symbolName
            )
        }
    }

    static func command(
        for habitID: UUID,
        completed: Bool,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> HabitWidgetCommand? {
        let snapshot = HabitWidgetBridge.loadCurrentSnapshot(
            now: now,
            calendar: calendar
        )
        guard !snapshot.dayKey.isEmpty,
              snapshot.habits.contains(where: { $0.id == habitID }) else {
            return nil
        }

        return HabitWidgetCommand(
            habitID: habitID,
            dayKey: snapshot.dayKey,
            completed: completed
        )
    }

    static func perform(
        habit: HabitShortcutEntity,
        completed: Bool
    ) async -> Bool {
        guard let command = command(
            for: habit.id,
            completed: completed
        ) else {
            return false
        }

        HabitWidgetBridge.appendCommand(command)
        HabitWidgetBridge.applyOptimistic(command)

        if let processor = HabitWidgetIntentRuntime.processor {
            await processor()
        }

        WidgetCenter.shared.reloadTimelines(
            ofKind: "HabitsTodayWidget"
        )
        return true
    }
}

struct CompleteHabitShortcutIntent: AppIntent {
    static var title = LocalizedStringResource(
        "shortcut.complete.title",
        defaultValue: "Complete Habit"
    )
    static var description = IntentDescription(
        LocalizedStringResource(
            "shortcut.complete.description",
            defaultValue: "Mark one of today's habits as complete."
        )
    )

    @Parameter(
        title: LocalizedStringResource(
            "shortcut.habit.parameter",
            defaultValue: "Habit"
        )
    )
    var habit: HabitShortcutEntity

    init() {}

    init(habit: HabitShortcutEntity) {
        self.habit = habit
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let success = await HabitShortcutBridge.perform(
            habit: habit,
            completed: true
        )

        if success {
            return .result(
                dialog: IntentDialog(
                    LocalizedStringResource(
                        "shortcut.complete.success",
                        defaultValue: "Marked \(habit.name) complete."
                    )
                )
            )
        }

        return .result(
            dialog: IntentDialog(
                LocalizedStringResource(
                    "shortcut.notDue",
                    defaultValue: "That habit is not due today."
                )
            )
        )
    }
}

struct UndoHabitShortcutIntent: AppIntent {
    static var title = LocalizedStringResource(
        "shortcut.undo.title",
        defaultValue: "Undo Habit"
    )
    static var description = IntentDescription(
        LocalizedStringResource(
            "shortcut.undo.description",
            defaultValue: "Mark one of today's habits as incomplete."
        )
    )

    @Parameter(
        title: LocalizedStringResource(
            "shortcut.habit.parameter",
            defaultValue: "Habit"
        )
    )
    var habit: HabitShortcutEntity

    init() {}

    init(habit: HabitShortcutEntity) {
        self.habit = habit
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let success = await HabitShortcutBridge.perform(
            habit: habit,
            completed: false
        )

        if success {
            return .result(
                dialog: IntentDialog(
                    LocalizedStringResource(
                        "shortcut.undo.success",
                        defaultValue: "Marked \(habit.name) incomplete."
                    )
                )
            )
        }

        return .result(
            dialog: IntentDialog(
                LocalizedStringResource(
                    "shortcut.notDue",
                    defaultValue: "That habit is not due today."
                )
            )
        )
    }
}

struct HabitsAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CompleteHabitShortcutIntent(),
            phrases: [
                "Complete a habit in \(.applicationName)",
                "Check off a habit in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource(
                "shortcut.complete.title",
                defaultValue: "Complete Habit"
            ),
            systemImageName: "checkmark.circle.fill"
        )

        AppShortcut(
            intent: UndoHabitShortcutIntent(),
            phrases: [
                "Undo a habit in \(.applicationName)",
                "Mark a habit incomplete in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource(
                "shortcut.undo.title",
                defaultValue: "Undo Habit"
            ),
            systemImageName: "arrow.uturn.backward.circle"
        )
    }
}
