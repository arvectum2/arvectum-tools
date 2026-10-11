import SwiftData
import SwiftUI
import UIKit

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(sort: \HabitCheckIn.day) private var checkIns: [HabitCheckIn]
    @Query(sort: \HabitSkip.day) private var skips: [HabitSkip]
    @Query(sort: \HabitPausePeriod.startedAt) private var pausePeriods: [HabitPausePeriod]
    @Query(sort: \OneOffReminder.dueAt) private var oneOffReminders: [OneOffReminder]

    @State private var showingAddHabit = false
    @State private var showingAddOneOffReminder = false
    @State private var editingOneOffReminder: OneOffReminder?
    @State private var undoOffer: CompletionUndoOffer?
    @State private var deepLinkedHabitID: UUID?
    @State private var referenceDate = Date()
    @State private var clockRevision = 0
    @State private var chickInCelebrationID: UUID?
    @State private var chickInCelebrationHabitID: UUID?
    @State private var adEligible = false

    private var activeToday: [Habit] {
        HabitTodayProjection.orderedDueHabits(
            habits: habits,
            on: referenceDate,
            checkIns: checkIns,
            skips: skips,
            pausePeriods: pausePeriods
        )
    }

    private var pendingOneOffReminders: [OneOffReminder] {
        oneOffReminders.filter { !$0.isCompleted }
    }

    private var resolvedCount: Int {
        activeToday.filter {
            isCompleted($0, on: referenceDate) ||
            isSkipped($0, on: referenceDate)
        }.count
    }

    private var clockTaskID: String {
        "\(HabitDayKey.make(for: referenceDate))-\(clockRevision)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.habitsBackground.ignoresSafeArea()

                if habits.filter({ !$0.isArchived }).isEmpty &&
                    pendingOneOffReminders.isEmpty
                {
                    firstHabitEmptyState
                } else {
                    todayContent
                }
            }
            .navigationTitle(L10n.string("today.title"))
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if !habits.isEmpty {
                        NavigationLink {
                            ManageHabitsView()
                        } label: {
                            Image(systemName: "line.3.horizontal")
                        }
                        .accessibilityLabel(
                            L10n.string("manage.accessibility")
                        )
                    }

                    Menu {
                        Button {
                            showingAddHabit = true
                        } label: {
                            Label(
                                L10n.string("add.menu.habit"),
                                systemImage: "repeat"
                            )
                        }

                        Button {
                            showingAddOneOffReminder = true
                        } label: {
                            Label(
                                L10n.string("add.menu.oneoff"),
                                systemImage: "bell.badge"
                            )
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                    .accessibilityLabel(L10n.string("common.add"))
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if adEligible {
                    HabitStickyBannerSlot()
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
            .sheet(isPresented: $showingAddOneOffReminder) {
                AddOneOffReminderView()
            }
            .sheet(item: $editingOneOffReminder) { reminder in
                AddOneOffReminderView(reminder: reminder)
            }
            .navigationDestination(
                isPresented: Binding(
                    get: { deepLinkedHabitID != nil },
                    set: { presented in
                        if !presented { deepLinkedHabitID = nil }
                    }
                )
            ) {
                if let habitID = deepLinkedHabitID,
                   let habit = habits.first(where: {
                       $0.id == habitID && !$0.isArchived
                   }) {
                    HabitDetailView(habit: habit)
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .overlay(alignment: .bottom) {
                if let undoOffer {
                    CompletionUndoToast {
                        undoCompletion(undoOffer)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .task {
                refreshReferenceDate()
                registerForegroundLaunchIfNeeded()
                refreshAdEligibility()
                backfillLegacyDayKeys()
#if DEBUG
                openDebugSurfaceIfRequested()
#endif
                await HabitReminderCoordinator.shared.refreshNow()
                HabitWidgetCoordinator.shared.refresh()
#if DEBUG
                await HabitReminderScheduler.debugDumpIfRequested()
#endif
            }
            .task(id: clockTaskID) {
                let delay = HabitDayBoundary.delay(from: referenceDate)
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                refreshReferenceDate(forceRevision: true)
                await HabitReminderCoordinator.shared.refreshNow()
                HabitWidgetCoordinator.shared.refresh()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    refreshReferenceDate(forceRevision: true)
                    registerForegroundLaunchIfNeeded()
                    refreshAdEligibility()
                    HabitReminderCoordinator.shared.refresh()
                    HabitWidgetCoordinator.shared.refresh()
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.significantTimeChangeNotification
                )
            ) { _ in
                handleClockEnvironmentChange()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: NSNotification.Name.NSSystemTimeZoneDidChange
                )
            ) { _ in
                handleClockEnvironmentChange()
            }
        }
    }

    private var todayContent: some View {
        ScrollView {
            VStack(spacing: 14) {
                if activeToday.isEmpty && pendingOneOffReminders.isEmpty {
                    noHabitsTodayCard
                } else {
                    if !activeToday.isEmpty {
                        TodaySummary(
                            completed: resolvedCount,
                            total: activeToday.count
                        )

                        LazyVStack(spacing: 10) {
                            ForEach(activeToday) { habit in
                                HabitRow(
                                habit: habit,
                                completed: isCompleted(
                                    habit,
                                    on: referenceDate
                                ),
                                skipped: isSkipped(
                                    habit,
                                    on: referenceDate
                                ),
                                streak: HabitMetrics.currentStreak(
                                    habit: habit,
                                    checkIns: checkIns,
                                    skips: skips,
                                    pausePeriods: pausePeriods
                                ),
                                weeklyCount: HabitFrequency.weeklyCompletionCount(
                                    habit: habit,
                                    containing: referenceDate,
                                    checkIns: checkIns
                                ),
                                weeklyTarget: HabitFrequency.effectiveWeeklyTarget(
                                    habit: habit,
                                    containing: referenceDate,
                                    skips: skips,
                                    pausePeriods: pausePeriods
                                ),
                                dailySlots: Set(HabitMultiCheck.slots(
                                    habitID: habit.id,
                                    dayKey: HabitDayKey.make(for: referenceDate),
                                    target: habit.dailyTarget,
                                    checkIns: checkIns
                                ).keys),
                                celebrationID: chickInCelebrationHabitID == habit.id
                                    ? chickInCelebrationID
                                    : nil,
                                onToggle: {
                                    toggle(habit, on: referenceDate)
                                },
                                onSetSlot: { slot, checked in
                                    setSlot(habit, on: referenceDate, slot: slot, checked: checked)
                                },
                                    onSkip: {
                                        toggleSkip(habit, on: referenceDate)
                                    }
                                )
                            }
                        }
                    }

                    if !pendingOneOffReminders.isEmpty {
                        oneOffReminderSection
                    }
                }
            }
            .padding(16)
        }
    }

    private var firstHabitEmptyState: some View {
        ContentUnavailableView {
            Label(L10n.string("today.empty.title"), systemImage: "checkmark.circle")
        } description: {
            Text(L10n.string("today.empty.description"))
        } actions: {
            VStack(spacing: 10) {
                Button(L10n.string("habit.create")) {
                    showingAddHabit = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.arvectumMint)
                .foregroundStyle(Color.arvectumNavy)

                Button(L10n.string("add.menu.oneoff")) {
                    showingAddOneOffReminder = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private var oneOffReminderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.string("oneoff.section"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.habitsSecondaryText)
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)

            LazyVStack(spacing: 10) {
                ForEach(pendingOneOffReminders) { reminder in
                    OneOffReminderRow(
                        reminder: reminder,
                        onComplete: {
                            completeOneOffReminder(reminder)
                        },
                        onEdit: {
                            editingOneOffReminder = reminder
                        },
                        onDelete: {
                            deleteOneOffReminder(reminder)
                        }
                    )
                }
            }
        }
    }

    private var noHabitsTodayCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.title2)
                .foregroundStyle(Color.habitsSecondaryText)
            Text(L10n.string("today.none.title"))
                .font(.headline)
            Text(L10n.string("today.none.description"))
                .font(.subheadline)
                .foregroundStyle(Color.habitsSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    private func completeOneOffReminder(_ reminder: OneOffReminder) {
        guard !reminder.isCompleted else { return }
        reminder.isCompleted = true
        reminder.completedAt = .now
        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        HabitReminderCoordinator.shared.dataDidChange()
    }

    private func deleteOneOffReminder(_ reminder: OneOffReminder) {
        modelContext.delete(reminder)
        try? modelContext.save()
        HabitReminderCoordinator.shared.dataDidChange()
    }

    private func handleDeepLink(_ url: URL) {
        switch HabitDeepLink.destination(from: url) {
        case .today:
            deepLinkedHabitID = nil
#if DEBUG
            emitDeepLinkDiagnostic("today")
#endif
        case .habit(let habitID):
            guard habits.contains(where: {
                $0.id == habitID && !$0.isArchived
            }) else {
#if DEBUG
                emitDeepLinkDiagnostic("habit-missing")
#endif
                return
            }
            deepLinkedHabitID = habitID
#if DEBUG
            emitDeepLinkDiagnostic("habit=\(habitID.uuidString)")
#endif
        case nil:
#if DEBUG
            emitDeepLinkDiagnostic("invalid")
#endif
            break
        }
    }

#if DEBUG
    private func emitDeepLinkDiagnostic(_ value: String) {
        guard ProcessInfo.processInfo.arguments.contains(
            "--diagnose-deeplink"
        ) else { return }
        HabitDebugLog.emit("HABITS_DEEPLINK \(value)")
    }

    private func openDebugSurfaceIfRequested() {
        let arguments = ProcessInfo.processInfo.arguments

        if arguments.contains("--debug-open-add-habit") {
            showingAddHabit = true
            return
        }

        if arguments.contains("--debug-open-add-oneoff") {
            showingAddOneOffReminder = true
            return
        }

        guard arguments.contains("--debug-open-reading-deeplink"),
              let id = UUID(
                  uuidString: "00000000-0000-0000-0000-000000000001"
              ) else { return }

        handleDeepLink(HabitDeepLink.habitURL(id))
    }
#endif

    private func handleClockEnvironmentChange() {
        refreshReferenceDate(forceRevision: true)
        HabitReminderCoordinator.shared.refresh()
        HabitWidgetCoordinator.shared.refresh()
    }

    private func refreshReferenceDate(
        forceRevision: Bool = false
    ) {
        let now = Date()
        let oldKey = HabitDayKey.make(for: referenceDate)
        let newKey = HabitDayKey.make(for: now)

        referenceDate = now
        if forceRevision || oldKey != newKey {
            clockRevision += 1
        }
    }

    private func registerForegroundLaunchIfNeeded() {
        guard !ProcessInfo.processInfo.arguments.contains("--ui-testing") else {
            return
        }
        HabitAdEligibilityStore.shared.registerForegroundLaunchOnce()
    }

    private func refreshAdEligibility() {
        let arguments = ProcessInfo.processInfo.arguments
        guard !arguments.contains("--ui-testing") else {
            adEligible = false
            return
        }

#if DEBUG
        if arguments.contains("--debug-force-ads") {
            adEligible = true
            return
        }
#endif

        adEligible = HabitAdEligibilityStore.shared.isEligible()
    }

    private func isCompleted(_ habit: Habit, on date: Date) -> Bool {
        HabitMetrics.isCompleted(
            habitID: habit.id,
            on: date,
            checkIns: checkIns,
                target: habit.dailyTarget
        )
    }

    private func isSkipped(_ habit: Habit, on date: Date) -> Bool {
        HabitMetrics.isSkipped(
            habitID: habit.id,
            on: date,
            skips: skips
        )
    }

    private func toggle(_ habit: Habit, on date: Date) {
        let calendar = Calendar.autoupdatingCurrent
        let key = HabitDayKey.make(for: date, calendar: calendar)
        let desiredState = !isCompleted(habit, on: date)

        let changed = HabitCompletionMutation.setCompletion(
            habitID: habit.id,
            dayKey: key,
            completed: desiredState,
            context: modelContext,
            mutationAt: .now,
            mutationID: UUID(),
            calendar: calendar
        )

        if desiredState && changed {
            HabitAdEligibilityStore.shared.registerSuccessfulCheckOff()
            refreshAdEligibility()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showUndo(for: habit.id, dayKey: key)
            showChickInCelebration(for: habit.id)
        } else if undoOffer?.habitID == habit.id {
            withAnimation { undoOffer = nil }
        }

        try? modelContext.save()
        HabitDataChangeNotifier.notify()
    }

    private func setSlot(
        _ habit: Habit, on date: Date, slot: Int, checked: Bool
    ) {
        let key = HabitDayKey.make(for: date)
        let previous = HabitMultiCheck.count(
            habitID: habit.id, dayKey: key,
            target: habit.dailyTarget, checkIns: checkIns
        )
        guard HabitMultiCheckMutation.setSlot(
            habitID: habit.id, dayKey: key, slot: slot,
            enabled: checked, context: modelContext
        ) else { return }
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            return
        }
        // Read the authoritative saved count: rapid taps can arrive before
        // SwiftUI's @Query publishes the updated collection.
        let persistedCheckIns = (try? modelContext.fetch(
            FetchDescriptor<HabitCheckIn>()
        )) ?? checkIns
        let newCount = HabitMultiCheck.count(
            habitID: habit.id, dayKey: key,
            target: habit.dailyTarget, checkIns: persistedCheckIns
        )
        if checked && newCount == habit.dailyTarget && previous < habit.dailyTarget {
            HabitAdEligibilityStore.shared.registerSuccessfulCheckOff()
            refreshAdEligibility()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showUndo(for: habit.id, dayKey: key, slot: slot)
            showChickInCelebration(for: habit.id)
        }
        HabitDataChangeNotifier.notify()
    }

    private func showChickInCelebration(for habitID: UUID) {
        let id = UUID()
        withAnimation(.snappy(duration: reduceMotion ? 0.08 : 0.18)) {
            chickInCelebrationHabitID = habitID
            chickInCelebrationID = id
        }

        Task { @MainActor in
            try? await Task.sleep(
                for: .milliseconds(reduceMotion ? 450 : 950)
            )
            guard chickInCelebrationID == id,
                  chickInCelebrationHabitID == habitID else { return }
            withAnimation(.easeOut(duration: reduceMotion ? 0.08 : 0.16)) {
                chickInCelebrationID = nil
                chickInCelebrationHabitID = nil
            }
        }
    }

    private func showUndo(for habitID: UUID, dayKey: String, slot: Int? = nil) {
        let offer = CompletionUndoOffer(
            id: UUID(),
            habitID: habitID,
            dayKey: dayKey,
            slot: slot
        )
        withAnimation(.snappy) {
            undoOffer = offer
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            guard undoOffer?.id == offer.id else { return }
            withAnimation(.snappy) {
                undoOffer = nil
            }
        }
    }

    private func undoCompletion(_ offer: CompletionUndoOffer) {
        if let slot = offer.slot {
            _ = HabitMultiCheckMutation.setSlot(
                habitID: offer.habitID, dayKey: offer.dayKey,
                slot: slot, enabled: false, context: modelContext
            )
        } else {
        _ = HabitCompletionMutation.setCompletion(
            habitID: offer.habitID,
            dayKey: offer.dayKey,
            completed: false,
            context: modelContext,
            mutationAt: .now,
            mutationID: UUID()
        )
        }
        try? modelContext.save()
        HabitDataChangeNotifier.notify()
        withAnimation(.snappy) {
            undoOffer = nil
        }
    }

    private func toggleSkip(_ habit: Habit, on date: Date) {
        let calendar = Calendar.autoupdatingCurrent
        let key = HabitDayKey.make(for: date, calendar: calendar)
        let desiredState = !isSkipped(habit, on: date)

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

    private func backfillLegacyDayKeys() {
        let calendar = Calendar.autoupdatingCurrent
        var changed = false

        for checkIn in checkIns where checkIn.dayKey == nil {
            checkIn.dayKey = HabitDayKey.make(
                for: checkIn.day,
                calendar: calendar
            )
            changed = true
        }

        if changed {
            try? modelContext.save()
        }
    }
}
