import SwiftData
import SwiftUI

struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(sort: \HabitCheckIn.day) var checkIns: [HabitCheckIn]
    @Query(sort: \HabitSkip.day) var skips: [HabitSkip]
    @Query(sort: \HabitPausePeriod.startedAt) var pausePeriods: [HabitPausePeriod]
    @Query(sort: \HabitDayMutation.updatedAt) private var dayMutations: [HabitDayMutation]

    @Bindable var habit: Habit
    @State private var showingDeleteConfirmation = false
    @State private var showingEditHabit = false
    @State private var showingExtendedHistory = false
    @State private var editingProgressDay: HabitProgressDaySelection?

    @State private var healthProjectionRevision = 0

    private var displayedCheckIns: [HabitCheckIn] {
        _ = healthProjectionRevision
        return HealthHabitCoordinator.shared.visibleCheckIns(for: checkIns, habits: habits)
    }

    private var habitCheckIns: [HabitCheckIn] {
        displayedCheckIns.filter { $0.habitID == habit.id }
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

    /// The primary habit card fits a single screen. Extra history/insights are
    /// behind an explicit drilldown; accessibility text sizes retain scrolling.
    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView {
                    habitOverview(weeks: 4)
                        .padding(12)
                }
            } else {
                ViewThatFits(in: .vertical) {
                    habitOverview(weeks: 4)
                    habitOverview(weeks: 3)
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .background(Color.habitsBackground)
        .navigationTitle(habit.name)
        .onReceive(NotificationCenter.default.publisher(for: .healthHabitProjectionChanged)) { _ in
            healthProjectionRevision += 1
        }
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
        .sheet(isPresented: $showingExtendedHistory) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 12) {
                        historyCard
                        if habit.usesFlexibleWeeklyTarget {
                            weeklyInsightsCard
                        } else if habit.usesCompletionInterval {
                            intervalInsightsCard
                        } else {
                            insightsCard
                        }
                    }
                    .padding(16)
                }
                .background(Color.habitsBackground)
                .navigationTitle(L10n.string("detail.more.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.string("common.done")) {
                            showingExtendedHistory = false
                        }
                    }
                }
            }
        }
        .sheet(item: $editingProgressDay) { selection in
            HabitProgressEditor(habit: habit, date: selection.date)
                .presentationDetents([.medium, .large])
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

    @ViewBuilder
    private func habitOverview(weeks: Int) -> some View {
        VStack(spacing: 10) {
            identityCard
            statsCard
            compactHistoryCard(weeks: weeks)
            healthIntegrationCard

            if canSkipToday {
                skipTodayButton
            }
            if habit.isPaused && !habit.isArchived {
                resumeButton
            }

            Button {
                showingExtendedHistory = true
            } label: {
                HStack {
                    Label(L10n.string("detail.more.title"), systemImage: "chart.bar.xaxis")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .frame(minHeight: 44)
                .padding(.horizontal, 14)
                .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("detail.more")
        }
    }

    private var healthIntegrationCard: some View {
        NavigationLink {
            HealthHabitSettingsView(habit: habit)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "heart.text.square")
                    .foregroundStyle(Color.accentColor)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.string("health.integrations.title"))
                        .font(.subheadline.weight(.semibold))
                    Text(L10n.string(
                        HealthHabitRuleStore.shared.rule(for: habit.id) == nil
                            ? "health.connect.hint" : "health.connected.hint"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(10)
            .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("health.settings.open")
    }

    private var identityCard: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    identityIcon
                    identityText
                }
            } else {
                HStack(spacing: 12) {
                    identityIcon
                    identityText
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var identityIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: habit.colorHex).opacity(0.16))
            Image(systemName: habit.symbolName)
                .font(.title2)
                .foregroundStyle(Color.habitsReadableAccent(for: habit.colorHex))
        }
        .frame(width: 44, height: 44)
        .accessibilityHidden(true)
    }

    private var identityText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(habit.name)
                .font(.title3.weight(.semibold))
            Text(HabitScheduleText.description(for: habit))
                .font(.subheadline)
                .foregroundStyle(Color.habitsSecondaryText)

            if HealthHabitCoordinator.shared.hasLocalCompletion(
                habitID: habit.id, dayKey: HabitDayKey.make(for: .now)
            ) {
                Label(L10n.string("health.auto.completed"), systemImage: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(Color.habitsSecondaryText)
            }

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
            checkIns: displayedCheckIns,
            skips: skips,
            pausePeriods: pausePeriods
        )
        let bestStreak = HabitMetrics.bestStreak(
            habit: habit,
            checkIns: displayedCheckIns,
            skips: skips,
            pausePeriods: pausePeriods
        )
        let completionPercent = Int(
            HabitMetrics.completionRate(
                habit: habit,
                checkIns: displayedCheckIns,
                skips: skips,
                pausePeriods: pausePeriods
            ) * 100
        )

        let content = Group {
            if habit.usesCompletionInterval {
                stat(
                    value: completionIntervalNextDueText,
                    label: L10n.string("stats.nextDue"),
                    systemImage: "calendar"
                )
                stat(
                    value: L10n.format(
                        "stats.interval.days.format",
                        habit.completionIntervalDays
                    ),
                    label: L10n.string("stats.interval"),
                    systemImage: "clock.arrow.circlepath"
                )
                stat(
                    value: "\(HabitMetrics.completedDayCount(habit: habit, checkIns: displayedCheckIns))",
                    label: L10n.string("stats.checkins"),
                    systemImage: "checkmark.circle.fill"
                )
            } else {
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
                    value: "\(HabitMetrics.completedDayCount(habit: habit, checkIns: displayedCheckIns))",
                    label: L10n.string("stats.checkins"),
                    systemImage: "checkmark.circle.fill"
                )
            }
        }

        return Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 10) { content }
            } else {
                HStack(spacing: 10) { content }
            }
        }
    }

    private func compactHistoryCard(weeks: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.string("detail.history.recent"))
                .font(.subheadline.weight(.semibold))
            historyGrid(
                days: HabitHistoryCalendar.visibleDays(
                    endingInWeekContaining: .now, weeks: weeks
                ),
                compact: true
            )
        }
        .padding(12)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.string("detail.history.title"))
                .font(.headline)
            historyGrid(days: recentDays, compact: false)
            Text(L10n.string("detail.history.hint"))
                .font(.caption)
                .foregroundStyle(Color.habitsSecondaryText)
        }
        .padding(16)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    private func historyGrid(days: [Date], compact: Bool) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: compact ? 5 : 6), count: 7),
            spacing: compact ? 5 : 6
        ) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { item in
                Text(item.element)
                    // Seven-column calendar stays legible even at AX text sizes;
                    // the full date remains spoken by the day button below.
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.habitsSecondaryText)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }

            ForEach(days, id: \.self) { date in
                dayCell(date)
            }
        }
    }

    private var canSkipToday: Bool {
        guard !habit.isArchived, !habit.isPaused else { return false }
        let calendar = Calendar.autoupdatingCurrent
        return HabitFrequency.isDue(
            habit: habit,
            on: .now,
            checkIns: displayedCheckIns,
            skips: skips,
            pausePeriods: pausePeriods,
            calendar: calendar
        ) && !HabitMetrics.isCompleted(
            habitID: habit.id,
            on: .now,
            checkIns: displayedCheckIns,
            calendar: calendar,
                target: habit.dailyTarget
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
        // One fixed row height: the streak's "best" line must not make its
        // card taller than completion % and check-in count.
        .frame(height: dynamicTypeSize.isAccessibilitySize ? nil : 102)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("stats.card." + systemImage)
        .accessibilityLabel(label)
        .accessibilityValue(
            secondary.map { "\(value), \($0)" } ?? value
        )
    }

    private func dayCell(_ date: Date) -> some View {
        let calendar = Calendar.autoupdatingCurrent
        let intervalScheduled = habit.usesCompletionInterval &&
            HabitFrequency.isDue(
                habit: habit,
                on: date,
                checkIns: displayedCheckIns,
                skips: skips,
                pausePeriods: pausePeriods,
                calendar: calendar
            )
        let scheduled = habit.usesCompletionInterval
            ? intervalScheduled
            : (habit.usesFlexibleWeeklyTarget
                ? false
                : habit.schedule.includes(date, calendar: calendar))
        let eligible = habit.usesCompletionInterval ||
            habit.usesFlexibleWeeklyTarget ||
            scheduled
        let completed = HabitMetrics.isCompleted(
            habitID: habit.id,
            on: date,
            checkIns: displayedCheckIns,
            calendar: calendar,
                target: habit.dailyTarget
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
            if habit.supportsIncrementalGoal {
                editingProgressDay = HabitProgressDaySelection(date: date)
            } else {
                toggle(date)
            }
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
                    .font(.system(size: 11, weight: .semibold))
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
        .accessibilityIdentifier("history.day.\(dayKey)")
        .accessibilityValue(
            habit.supportsIncrementalGoal
                ? L10n.format(
                    "habit.history.progress",
                    HabitMultiCheck.count(
                        habitID: habit.id,
                        dayKey: dayKey,
                        target: habit.dailyTarget,
                        checkIns: checkIns
                    ),
                    habit.dailyTarget
                )
                : ""
        )
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
            checkIns: displayedCheckIns,
            calendar: calendar,
                target: habit.dailyTarget
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

    private var completionIntervalNextDueText: String {
        let calendar = Calendar.autoupdatingCurrent
        guard let dueDate = HabitFrequency.nextCompletionIntervalDueDate(
            habit: habit,
            checkIns: displayedCheckIns,
            through: .now,
            calendar: calendar
        ) else {
            return "—"
        }

        if dueDate <= calendar.startOfDay(for: .now) {
            return L10n.string("today.title")
        }

        return dueDate.formatted(date: .abbreviated, time: .omitted)
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
        for checkIn in checkIns.filter({ $0.habitID == habit.id }) {
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
        do { try modelContext.save() } catch {
            modelContext.rollback()
            return
        }
        HealthHabitRuleStore.shared.disable(for: habit.id)
        HealthHabitCoordinator.shared.reconfigureObservers()
        HabitDataChangeNotifier.notify()
        dismiss()
    }
}
