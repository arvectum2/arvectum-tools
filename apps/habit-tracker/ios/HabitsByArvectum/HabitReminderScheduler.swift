import Foundation
import UserNotifications

enum HabitReminderScheduler {
    private static let prefix = "habit-reminder"
    static let planningDayCount = 14
    static let maxPendingRequests = 60

    private struct Candidate {
        let habit: Habit
        let fireDate: Date
        let dayKey: String
    }

    static func ensureAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(
                options: [.alert, .sound]
            )) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    static func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current()
            .notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }

    static func shouldSchedule(habit: Habit) -> Bool {
        habit.reminderEnabled &&
        !habit.isArchived &&
        !habit.isPaused &&
        !habit.usesFlexibleWeeklyTarget
    }

    static func reminderDates(
        habit: Habit,
        checkIns: [HabitCheckIn] = [],
        skips: [HabitSkip] = [],
        from referenceDate: Date,
        daysAhead: Int = planningDayCount,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [Date] {
        guard shouldSchedule(habit: habit), daysAhead > 0 else {
            return []
        }

        let start = calendar.startOfDay(for: referenceDate)
        var dates: [Date] = []

        for offset in 0..<daysAhead {
            guard let day = calendar.date(
                byAdding: .day,
                value: offset,
                to: start
            ) else { continue }

            guard habit.schedule.includes(day, calendar: calendar) else {
                continue
            }

            let completed = HabitMetrics.isCompleted(
                habitID: habit.id,
                on: day,
                checkIns: checkIns,
                calendar: calendar
            )
            let skipped = HabitMetrics.isSkipped(
                habitID: habit.id,
                on: day,
                skips: skips,
                calendar: calendar
            )
            guard !completed && !skipped else { continue }

            guard let fireDate = calendar.date(
                bySettingHour: habit.reminderHour,
                minute: habit.reminderMinute,
                second: 0,
                of: day
            ), fireDate > referenceDate else {
                continue
            }

            dates.append(fireDate)
        }

        return dates
    }

    @MainActor
    static func syncAll(
        habits: [Habit],
        checkIns: [HabitCheckIn],
        skips: [HabitSkip],
        referenceDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) async -> Bool {
        let center = UNUserNotificationCenter.current()
        await removeAllManagedRequests(center: center)

        let eligibleHabits = habits.filter(shouldSchedule)
        guard !eligibleHabits.isEmpty else { return true }
        guard await isAuthorized() else { return false }

        let candidates = eligibleHabits.flatMap { habit in
            reminderDates(
                habit: habit,
                checkIns: checkIns,
                skips: skips,
                from: referenceDate,
                calendar: calendar
            ).map { fireDate in
                Candidate(
                    habit: habit,
                    fireDate: fireDate,
                    dayKey: HabitDayKey.make(
                        for: fireDate,
                        calendar: calendar
                    )
                )
            }
        }
        .sorted {
            if $0.fireDate != $1.fireDate {
                return $0.fireDate < $1.fireDate
            }
            if $0.habit.sortOrder != $1.habit.sortOrder {
                return $0.habit.sortOrder < $1.habit.sortOrder
            }
            return $0.habit.createdAt < $1.habit.createdAt
        }
        .prefix(maxPendingRequests)

        for candidate in candidates {
            var components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: candidate.fireDate
            )
            components.calendar = nil
            components.timeZone = nil

            let request = UNNotificationRequest(
                identifier: identifier(
                    habitID: candidate.habit.id,
                    dayKey: candidate.dayKey
                ),
                content: notificationContent(for: candidate.habit),
                trigger: UNCalendarNotificationTrigger(
                    dateMatching: components,
                    repeats: false
                )
            )

            do {
                try await center.add(request)
            } catch {
                return false
            }
        }

        return true
    }

    static func remove(habitID: UUID) async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        let habitPrefix = "(prefix)-(habitID.uuidString)-"
        let ids = requests
            .map(\.identifier)
            .filter { $0.hasPrefix(habitPrefix) }

        if !ids.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private static func removeAllManagedRequests(
        center: UNUserNotificationCenter
    ) async {
        let ids = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }

        if !ids.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    static func notificationContent(
        for habit: Habit
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = habit.name
        content.body = L10n.string("reminder.notification.body")
        content.sound = .default
        content.categoryIdentifier = HabitNotificationActions.categoryIdentifier
        content.userInfo = [
            HabitNotificationActions.habitIDKey: habit.id.uuidString
        ]
        return content
    }

    static func notificationComponents(
        schedule: HabitSchedule,
        hour: Int,
        minute: Int
    ) -> [DateComponents] {
        weekdayNumbers(for: schedule).map { weekday in
            var components = DateComponents()
            components.weekday = weekday
            components.hour = hour
            components.minute = minute
            return components
        }
    }

    static func weekdayNumbers(
        for schedule: HabitSchedule
    ) -> [Int] {
        (1...7).filter {
            schedule.contains(HabitSchedule.option(for: $0))
        }
    }

    private static func identifier(
        habitID: UUID,
        dayKey: String
    ) -> String {
        "(prefix)-(habitID.uuidString)-(dayKey)"
    }

#if DEBUG
    static func debugDumpIfRequested() async {
        guard ProcessInfo.processInfo.arguments.contains(
            "--diagnose-notifications"
        ) else { return }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let requests = await center.pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix(prefix) }
            .sorted { $0.identifier < $1.identifier }

        HabitDebugLog.emit(
            "HABITS_NOTIFICATION_AUTH=(settings.authorizationStatus.rawValue)"
        )
        HabitDebugLog.emit("HABITS_PENDING_COUNT=(requests.count)")

        for request in requests {
            let next = (request.trigger as? UNCalendarNotificationTrigger)?
                .nextTriggerDate()?
                .ISO8601Format() ?? "nil"
            let components = (request.trigger as? UNCalendarNotificationTrigger)?
                .dateComponents.description ?? "nil"
            HabitDebugLog.emit(
                "HABITS_PENDING id=(request.identifier) " +
                "title=(request.content.title) " +
                "components=(components) next=(next)"
            )
        }
    }
#endif
}
