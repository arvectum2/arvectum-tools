import SwiftData
import UIKit
import UserNotifications

enum OneOffReminderNotificationActions {
    static let categoryIdentifier = "ONE_OFF_REMINDER"
    static let completeIdentifier = "ONE_OFF_COMPLETE"
    static let reminderIDKey = "oneOffReminderID"
}

enum HabitNotificationActions {
    static let categoryIdentifier = "HABIT_REMINDER"
    static let completeIdentifier = "HABIT_COMPLETE"
    static let skipIdentifier = "HABIT_SKIP_TODAY"
    static let habitIDKey = "habitID"

    static func register() {
        let complete = UNNotificationAction(
            identifier: completeIdentifier,
            title: L10n.string("notification.action.complete"),
            options: []
        )
        let skip = UNNotificationAction(
            identifier: skipIdentifier,
            title: L10n.string("notification.action.skip"),
            options: []
        )
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [complete, skip],
            intentIdentifiers: [],
            options: []
        )
        let oneOffComplete = UNNotificationAction(
            identifier: OneOffReminderNotificationActions.completeIdentifier,
            title: L10n.string("notification.action.complete"),
            options: []
        )
        let oneOffCategory = UNNotificationCategory(
            identifier: OneOffReminderNotificationActions.categoryIdentifier,
            actions: [oneOffComplete],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current()
            .setNotificationCategories([category, oneOffCategory])
    }
}

@MainActor
final class HabitNotificationActionCoordinator {
    static let shared = HabitNotificationActionCoordinator()

    private var modelContainer: ModelContainer?

    private init() {}

    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    @discardableResult
    func markCompleted(
        habitID: UUID,
        at date: Date = .now,
        mutationID: UUID = UUID(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        guard let modelContainer else { return false }
        let context = ModelContext(modelContainer)
        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        guard let habit = habits.first(where: { $0.id == habitID }),
              !habit.isArchived,
              !habit.isPaused
        else {
            return false
        }

        let checkIns = (try? context.fetch(
            FetchDescriptor<HabitCheckIn>()
        )) ?? []
        let skips = (try? context.fetch(
            FetchDescriptor<HabitSkip>()
        )) ?? []
        let pausePeriods = (try? context.fetch(
            FetchDescriptor<HabitPausePeriod>()
        )) ?? []

        guard HabitFrequency.isDue(
            habit: habit,
            on: date,
            checkIns: checkIns,
            skips: skips,
            pausePeriods: pausePeriods,
            calendar: calendar
        ) else {
            return false
        }

        let dayKey = HabitDayKey.make(for: date, calendar: calendar)
        _ = HabitCompletionMutation.setCompletion(
            habitID: habitID,
            dayKey: dayKey,
            completed: true,
            context: context,
            mutationAt: date,
            mutationID: mutationID,
            calendar: calendar
        )

        do {
            try context.save()
            HabitDataChangeNotifier.notify()
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    func markOneOffCompleted(reminderID: UUID) -> Bool {
        guard let modelContainer else { return false }
        let context = ModelContext(modelContainer)
        let reminders = (try? context.fetch(
            FetchDescriptor<OneOffReminder>()
        )) ?? []

        guard let reminder = reminders.first(where: {
            $0.id == reminderID && !$0.isCompleted
        }) else {
            return false
        }

        reminder.isCompleted = true
        reminder.completedAt = .now

        do {
            try context.save()
            HabitReminderCoordinator.shared.dataDidChange()
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    func skipToday(
        habitID: UUID,
        at date: Date = .now,
        mutationID: UUID = UUID(),
        calendar: Calendar = .autoupdatingCurrent
    ) -> Bool {
        guard let modelContainer else { return false }
        let context = ModelContext(modelContainer)
        let habits = (try? context.fetch(FetchDescriptor<Habit>())) ?? []
        guard let habit = habits.first(where: { $0.id == habitID }),
              !habit.isArchived,
              !habit.isPaused
        else {
            return false
        }

        let checkIns = (try? context.fetch(
            FetchDescriptor<HabitCheckIn>()
        )) ?? []
        let skips = (try? context.fetch(
            FetchDescriptor<HabitSkip>()
        )) ?? []
        let pausePeriods = (try? context.fetch(
            FetchDescriptor<HabitPausePeriod>()
        )) ?? []

        guard HabitFrequency.isDue(
            habit: habit,
            on: date,
            checkIns: checkIns,
            skips: skips,
            pausePeriods: pausePeriods,
            calendar: calendar
        ) else {
            return false
        }

        let dayKey = HabitDayKey.make(for: date, calendar: calendar)
        _ = HabitSkipMutation.setSkipped(
            habitID: habitID,
            dayKey: dayKey,
            skipped: true,
            context: context,
            mutationAt: date,
            mutationID: mutationID,
            calendar: calendar
        )

        do {
            try context.save()
            HabitDataChangeNotifier.notify()
            return true
        } catch {
            return false
        }
    }
}

final class HabitsAppDelegate: NSObject, UIApplicationDelegate,
    UNUserNotificationCenterDelegate
{
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        HabitNotificationActions.register()
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        if response.actionIdentifier ==
            OneOffReminderNotificationActions.completeIdentifier,
           let rawReminderID = userInfo[
               OneOffReminderNotificationActions.reminderIDKey
           ] as? String,
           let reminderID = UUID(uuidString: rawReminderID)
        {
            Task { @MainActor in
                _ = HabitNotificationActionCoordinator.shared
                    .markOneOffCompleted(reminderID: reminderID)
                completionHandler()
            }
            return
        }

        guard
            let rawID = userInfo[
                HabitNotificationActions.habitIDKey
            ] as? String,
            let habitID = UUID(uuidString: rawID)
        else {
            completionHandler()
            return
        }

        Task { @MainActor in
            switch response.actionIdentifier {
            case HabitNotificationActions.completeIdentifier:
                _ = HabitNotificationActionCoordinator.shared.markCompleted(
                    habitID: habitID
                )
            case HabitNotificationActions.skipIdentifier:
                _ = HabitNotificationActionCoordinator.shared.skipToday(
                    habitID: habitID
                )
            default:
                break
            }
            completionHandler()
        }
    }
}
