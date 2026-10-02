import SwiftData
import SwiftUI

struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(sort: \HabitCheckIn.day) private var checkIns: [HabitCheckIn]
    @Query(sort: \HabitSkip.day) private var skips: [HabitSkip]
    @Query(sort: \HabitPausePeriod.startedAt) private var pausePeriods: [HabitPausePeriod]

    @Bindable var habit: Habit
    @State private var showingDeleteConfirmation = false
    @State private var showingEditHabit = false

    private var habitCheckIns: [HabitCheckIn] {
        checkIns.filter { $0.habitID == habit.id }
    }

    private var habitSkips: [HabitSkip] {
        skips.filter { $0.habitID == habit.id }
    }

    private var habitPausePeriods: [HabitPausePeriod] {
        pausePeriods.filter { $0.habitID == habit.id }
    }

    private var recentDays: [Date] {
        HabitHistoryCalendar.visibleDays(
            endingInWeekContaining: .now,
            weeks: 6
        )
    }

    private var weekdaySymbols: [String] {
        HabitHistoryCalendar.weekdaySymbols()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                identityCard
                statsCard
                historyCard
                if canSkipToday {
                    skipTodayButton
                }
                if habit.isPaused && !habit.isArchived {
                    resumeButton
                }
            }
            .padding(16)
        }
        .background(Color.habitsBackground)
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !habit.isArchived {
                    Button {
                        showingEditHabit = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel(L10n.string("habit.edit.action"))
                }

                Menu {
                    if !habit.isArchived && !habit.isPaused {
                        Button(action: togglePause) {
                            Label(
                                L10n.string("detail.pause"),
                                systemImage: "pause.fill"
                            )
                        }
                    }

                    Button(action: toggleArchive) {
                        Label(
                            habit.isArchived
                                ? L10n.string("detail.restore")
                                : L10n.string("detail.archive"),
                            systemImage: habit.isArchived
                                ? "tray.and.arrow.up"
                                : "archivebox"
                        )
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label(
                            L10n.string("detail.delete"),
                            systemImage: "trash"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel(L10n.string("detail.more.accessibility"))
            }
        }
        .sheet(isPresented: $showingEditHabit) {
            AddHabitView(habit: habit)
        }
        .confirmationDialog(
            L10n.string("detail.delete.title"),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.string("common.delete"), role: .destructive, action: deleteHabit)
            Button(L10n.string("common.cancel"), role: .cancel) {}
        } message: {
            Text(L10n.string("detail.delete.message"))
        }
    }

    private var identityCard: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    identityIcon
                    identityText
                }
            } else {
                HStack(spacing: 14) {
                    identityIcon
                    identityText
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var identityIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: habit.colorHex).opacity(0.16))
            Image(systemName: habit.symbolName)
                .font(.title2)
                .foregroundStyle(Color.habitsReadableAccent(for: habit.colorHex))
        }
        .frame(width: 54, height: 54)
        .accessibilityHidden(true)
    }

    private var identityText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(habit.name)
                .font(.title3.weight(.semibold))
            Text(HabitScheduleText.description(for: habit))
                .font(.subheadline)
                .foregroundStyle(Color.habitsSecondaryText)

            if habit.isPaused {
                Label(
                    L10n.string("manage.paused"),
                    systemImage: "pause.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(Color.habitsSecondaryText)
            } else if HabitReminderScheduler.shouldSchedule(habit: habit) {
                Label(reminderDescription, systemImage: "bell.fill")
                    .font(.caption)
                    .foregroundStyle(Color.habitsSecondaryText)
            }
        }
    }

    private var statsCard: some View {
        let currentStreak = HabitMetrics.currentStreak(
            habit: habit,
            checkIns: checkIns,
            skips: skips,
            pausePeriods: pausePeriods
        )
        let bestStreak = HabitMetrics.bestStreak(
            habit: habit,
            checkIns: checkIns,
            skips: skips,
            pausePeriods: pausePeriods
        )
        let completionPercent = Int(
            HabitMetrics.completionRate(
                habit: habit,
                checkIns: checkIns,
                skips: skips,
                pausePeriods: pausePeriods
            ) * 100
        )

        let content = Group {
            stat(
                value: String(currentStreak),
                label: L10n.string("stats.streak"),
                systemImage: "flame.fill",
                secondary: L10n.format(
                    "stats.best.format",
                    bestStreak
                )
            )
            stat(
                value: "\(completionPercent)%",
                label: L10n.string("stats.completion"),
                systemImage: "chart.line.uptrend.xyaxis"
            )
            stat(
                value: "\(habitCheckIns.count)",
                label: L10n.string("stats.checkins"),
                systemImage: "checkmark.circle.fill"
            )
        }

        return Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 10) { content }
            } else {
                HStack(spacing: 10) { content }
            }
        }
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.string("detail.history.title"))
                .font(.headline)

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 6),
                    count: 7
                ),
                spacing: 6
            ) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { item in
                    Text(item.element)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.habitsSecondaryText)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }

                ForEach(recentDays, id: \.self) { date in
                    dayCell(date)
                }
            }

            Text(L10n.string("detail.history.hint"))
                .font(.caption)
                .foregroundStyle(Color.habitsSecondaryText)
        }
        .padding(16)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var canSkipToday: Bool {
        guard !habit.isArchived, !habit.isPaused else { return false }
        let calendar = Calendar.autoupdatingCurrent
        return HabitFrequency.isDue(
            habit: habit,
            on: .now,
            checkIns: checkIns,
            skips: skips,
            pausePeriods: pausePeriods,
            calendar: calendar
        ) && !HabitMetrics.isCompleted(
            habitID: habit.id,
            on: .now,
            checkIns: checkIns,
            calendar: calendar
        )
    }

    private var isSkippedToday: Bool {
        HabitMetrics.isSkipped(
            habitID: habit.id,
            on: .now,
            skips: skips
        )
    }

    private var skipTodayButton: some View {
        Button {
            toggleSkip(.now)
        } label: {
            Label(
                isSkippedToday
                    ? L10n.string("habit.skip.undo")
                    : L10n.string("habit.skip.today"),
                systemImage: isSkippedToday
                    ? "arrow.uturn.backward"
                    : "forward.end"
            )
            .frame(maxWidth: .infinity)
            .frame(minHeight: 46)
            .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
        .tint(Color.habitsWarningText)
    }

    private var resumeButton: some View {
        Button(action: togglePause) {
            Label(
                L10n.string("detail.resume"),
                systemImage: "play.fill"
            )
            .frame(maxWidth: .infinity)
            .frame(minHeight: 46)
            .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
    }

    private func toggleArchive() {
        let restoring = habit.isArchived
        habit.isArchived.toggle()
        if restoring && !habit.isArchived {
            habit.sortOrder = HabitOrdering.nextOrder(
                in: habits.filter { $0.id != habit.id }
            )
        }
        try? modelContext.save()
        HabitDataChangeNotifier.notify()
        if habit.isArchived { dismiss() }
    }

    private func stat(
        value: String,
        label: String,
        systemImage: String,
        secondary: String? = nil
    ) -> some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.habitsReadableAccent(for: habit.colorHex))
                .accessibilityHidden(true)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.habitsSecondaryText)

            if let secondary {
                Text(secondary)
                    .font(.caption2)
                    .foregroundStyle(Color.habitsSecondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(
            secondary.map { "\(value), \($0)" } ?? value
        )
    }

    private func dayCell(_ date: Date) -> some View {
        let calendar = Calendar.autoupdatingCurrent
        let scheduled = habit.usesFlexibleWeeklyTarget
            ? false
            : habit.schedule.includes(date, calendar: calendar)
        let eligible = habit.usesFlexibleWeeklyTarget || scheduled
        let completed = HabitMetrics.isCompleted(
            habitID: habit.id,
            on: date,
            checkIns: checkIns,
            calendar: calendar
        )
        let skipped = HabitMetrics.isSkipped(
            habitID: habit.id,
            on: date,
            skips: skips,
            calendar: calendar
        )
        let dayKey = HabitDayKey.make(for: date, calendar: calendar)
        let beforeCreation = date < calendar.startOfDay(for: habit.createdAt)
        let today = calendar.startOfDay(for: .now)
        let future = date > today
        let paused = habitPausePeriods.contains { $0.contains(dayKey: dayKey) }
        let missed = !habit.usesFlexibleWeeklyTarget &&
            scheduled &&
            date < today &&
            !beforeCreation &&
            !paused &&
            !completed &&
            !skipped
        let enabled = eligible && !beforeCreation && !future && !paused

        return Button {
            toggle(date)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(dayBackground(
                        scheduled: scheduled,
                        completed: completed,
                        skipped: skipped,
                        missed: missed,
                        disabled: beforeCreation || future || paused
                    ))
                    .aspectRatio(1, contentMode: .fit)

                Text("\(calendar.component(.day, from: date))")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(completed ? Color.black : .primary)

                if missed {
                    Image(systemName: "xmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(4)
                        .accessibilityHidden(true)
                } else if skipped {
                    Image(systemName: "minus")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Color.habitsWarningText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(4)
                        .accessibilityHidden(true)
                } else if paused {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundStyle(Color.habitsSecondaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(4)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .contextMenu {
            if enabled {
                Button {
                    toggleSkip(date)
                } label: {
                    Label(
                        skipped
                            ? L10n.string("habit.skip.undo")
                            : L10n.string("habit.skip.today"),
                        systemImage: skipped
                            ? "arrow.uturn.backward"
                            : "forward.end"
                    )
                }
            }
        }
        .accessibilityLabel(
            accessibilityLabel(
                for: date,
                completed: completed,
                skipped: skipped,
                missed: missed,
                paused: paused
            )
        )
    }

    private func dayBackground(
        scheduled: Bool,
        completed: Bool,
        skipped: Bool,
        missed: Bool,
        disabled: Bool
    ) -> Color {
        if completed { return Color(hex: habit.colorHex) }
        if skipped { return Color.arvectumOrange.opacity(0.24) }
        if missed { return Color.red.opacity(0.10) }
        if disabled { return Color.secondary.opacity(0.04) }
        if scheduled { return Color.secondary.opacity(0.12) }
        return Color.secondary.opacity(0.05)
    }

    private func toggle(_ date: Date) {
        let calendar = Calendar.autoupdatingCurrent
        let key = HabitDayKey.make(for: date, calendar: calendar)
        let desiredState = !HabitMetrics.isCompleted(
            habitID: habit.id,
            on: date,
            checkIns: checkIns,
            calendar: calendar
        )

        _ = HabitCompletionMutation.setCompletion(
            habitID: habit.id,
            dayKey: key,
            completed: desiredState,
            context: modelContext,
            mutationAt: .now,
            mutationID: UUID(),
            calendar: calendar
        )

        try? modelContext.save()
        HabitDataChangeNotifier.notify()
    }

    private func toggleSkip(_ date: Date) {
        let calendar = Calendar.autoupdatingCurrent
        let key = HabitDayKey.make(for: date, calendar: calendar)
        let desiredState = !HabitMetrics.isSkipped(
            habitID: habit.id,
            on: date,
            skips: skips,
            calendar: calendar
        )

        _ = HabitSkipMutation.setSkipped(
            habitID: habit.id,
            dayKey: key,
            skipped: desiredState,
            context: modelContext,
            mutationAt: .now,
            mutationID: UUID(),
            calendar: calendar
        )

        try? modelContext.save()
        HabitDataChangeNotifier.notify()
    }

    private var reminderDescription: String {
        let date = Calendar.autoupdatingCurrent.date(
            bySettingHour: habit.reminderHour,
            minute: habit.reminderMinute,
            second: 0,
            of: .now
        ) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    private func togglePause() {
        let now = Date()
        let calendar = Calendar.autoupdatingCurrent

        if habit.isPaused {
            let endKey = HabitDayKey.make(for: now, calendar: calendar)
            if let openPeriod = habitPausePeriods.last(where: {
                $0.endDayKeyExclusive == nil
            }) {
                openPeriod.endedAt = now
                openPeriod.endDayKeyExclusive = endKey
            }
            habit.pausedAt = nil
            habit.sortOrder = HabitOrdering.nextOrder(
                in: habits.filter { $0.id != habit.id }
            )
        } else {
            habit.pausedAt = now
            modelContext.insert(
                HabitPausePeriod(
                    habitID: habit.id,
                    startedAt: now,
                    calendar: calendar
                )
            )
        }

        try? modelContext.save()
        HabitDataChangeNotifier.notify()
    }

    private func accessibilityLabel(
        for date: Date,
        completed: Bool,
        skipped: Bool,
        missed: Bool,
        paused: Bool
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        let status: String
        if completed {
            status = L10n.string("status.completed")
        } else if skipped {
            status = L10n.string("status.skipped")
        } else if paused {
            status = L10n.string("status.paused")
        } else if missed {
            status = L10n.string("status.missed")
        } else {
            status = L10n.string("status.notCompleted")
        }

        return "\(formatter.string(from: date)), \(status)"
    }

    private func deleteHabit() {
        for checkIn in habitCheckIns {
            modelContext.delete(checkIn)
        }
        for skip in habitSkips {
            modelContext.delete(skip)
        }
        for pausePeriod in habitPausePeriods {
            modelContext.delete(pausePeriod)
        }
        let mutations = (try? modelContext.fetch(
            FetchDescriptor<HabitDayMutation>()
        )) ?? []
        for mutation in mutations where mutation.habitID == habit.id {
            modelContext.delete(mutation)
        }
        modelContext.delete(habit)
        try? modelContext.save()
        HabitDataChangeNotifier.notify()
        dismiss()
    }
}
