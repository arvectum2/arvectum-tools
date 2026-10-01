import Foundation
import UserNotifications

enum HabitReminderScheduler {
    private static let prefix = "habit-reminder"
    static let planningDayCount = 14
    static let maxPendingRequests = 60


    struct ReminderPlanItem: Equatable {
        let habitID: UUID
        let fireDate: Date
        let dayKey: String
    }

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


    static func reminderPlan(
        habits: [Habit],
        checkIns: [HabitCheckIn] = [],
        skips: [HabitSkip] = [],
        from referenceDate: Date,
        daysAhead: Int = planningDayCount,
        limit: Int = maxPendingRequests,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [ReminderPlanItem] {
        guard daysAhead > 0, limit > 0 else { return [] }

        let candidates = habits
            .filter(shouldSchedule)
            .flatMap { habit in
                reminderDates(
                    habit: habit,
                    checkIns: checkIns,
                    skips: skips,
                    from: referenceDate,
                    daysAhead: daysAhead,
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

        return candidates.prefix(limit).map {
            ReminderPlanItem(
                habitID: $0.habit.id,
                fireDate: $0.fireDate,
                dayKey: $0.dayKey
            )
        }
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

        let plan = reminderPlan(
            habits: eligibleHabits,
            checkIns: checkIns,
            skips: skips,
            from: referenceDate,
            calendar: calendar
        )
        let habitsByID = Dictionary(
            uniqueKeysWithValues: eligibleHabits.map { ($0.id, $0) }
        )

        for item in plan {
            guard let habit = habitsByID[item.habitID] else { continue }

            var components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: item.fireDate
            )
            components.calendar = nil
            components.timeZone = nil

            let request = UNNotificationRequest(
                identifier: requestIdentifier(
                    habitID: item.habitID,
                    dayKey: item.dayKey
                ),
                content: notificationContent(for: habit),
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

    static func requestIdentifier(
        habitID: UUID,
        dayKey: String
    ) -> String {
        [prefix, habitID.uuidString, dayKey].joined(separator: "-")
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
            "HABITS_NOTIFICATION_AUTH=" +
            String(settings.authorizationStatus.rawValue)
        )
        HabitDebugLog.emit(
            "HABITS_PENDING_COUNT=" + String(requests.count)
        )

        for request in requests {
            let next = (request.trigger as? UNCalendarNotificationTrigger)?
                .nextTriggerDate()?
                .ISO8601Format() ?? "nil"
            let components = (request.trigger as? UNCalendarNotificationTrigger)?
                .dateComponents.description ?? "nil"
            HabitDebugLog.emit(
                "HABITS_PENDING id=" + request.identifier +
                " title=" + request.content.title +
                " components=" + components +
                " next=" + next
            )
        }
    }
#endif
}
