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

    @State private var showingAddHabit = false
    @State private var undoOffer: CompletionUndoOffer?
    @State private var deepLinkedHabitID: UUID?
    @State private var referenceDate = Date()
    @State private var clockRevision = 0
    @State private var chickInCelebrationID: UUID?

    private var activeToday: [Habit] {
        HabitTodayProjection.orderedDueHabits(
            habits: habits,
            on: referenceDate,
            checkIns: checkIns,
            skips: skips,
            pausePeriods: pausePeriods
        )
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

                if habits.filter({ !$0.isArchived }).isEmpty {
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

                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                    .accessibilityLabel(L10n.string("habit.add.accessibility"))
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
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
            .overlay(alignment: .topTrailing) {
                if let chickInCelebrationID {
                    ChickInCelebrationView()
                        .id(chickInCelebrationID)
                        .padding(.top, 58)
                        .padding(.trailing, 12)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
            .task {
                refreshReferenceDate()
                registerForegroundLaunchIfNeeded()
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
                if activeToday.isEmpty {
                    noHabitsTodayCard
                } else {
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
                                onToggle: {
                                    toggle(habit, on: referenceDate)
                                },
                                onSkip: {
                                    toggleSkip(habit, on: referenceDate)
                                }
                            )
                        }
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
            Button(L10n.string("habit.create")) {
                showingAddHabit = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.arvectumMint)
            .foregroundStyle(Color.arvectumNavy)
        }
        .padding()
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

    private func isCompleted(_ habit: Habit, on date: Date) -> Bool {
        HabitMetrics.isCompleted(
            habitID: habit.id,
            on: date,
            checkIns: checkIns
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
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showUndo(for: habit.id, dayKey: key)
            showChickInCelebration()
        } else if undoOffer?.habitID == habit.id {
            withAnimation { undoOffer = nil }
        }

        try? modelContext.save()
        HabitDataChangeNotifier.notify()
    }

    private func showChickInCelebration() {
        let id = UUID()
        withAnimation(.snappy(duration: reduceMotion ? 0.08 : 0.18)) {
            chickInCelebrationID = id
        }

        Task { @MainActor in
            try? await Task.sleep(
                for: .milliseconds(reduceMotion ? 450 : 950)
            )
            guard chickInCelebrationID == id else { return }
            withAnimation(.easeOut(duration: reduceMotion ? 0.08 : 0.16)) {
                chickInCelebrationID = nil
            }
        }
    }

    private func showUndo(for habitID: UUID, dayKey: String) {
        let offer = CompletionUndoOffer(
            id: UUID(),
            habitID: habitID,
            dayKey: dayKey
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
        _ = HabitCompletionMutation.setCompletion(
            habitID: offer.habitID,
            dayKey: offer.dayKey,
            completed: false,
            context: modelContext,
            mutationAt: .now,
            mutationID: UUID()
        )
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

private struct TodaySummary: View {
    let completed: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.format("today.progress.format", completed, total))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.habitsSecondaryText)

            ProgressView(value: progress)
                .tint(Color.arvectumMint)
                .scaleEffect(x: 1, y: 1.5)
        }
        .padding(16)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}

private struct ChickInCelebrationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pecking = false
    @State private var grainScale: CGFloat = 1
    @State private var grainOpacity = 1.0

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.arvectumOrange)
                .frame(width: 10, height: 6)
                .rotationEffect(.degrees(-18))
                .scaleEffect(grainScale)
                .opacity(grainOpacity)
                .offset(x: 4, y: 8)

            Image("ChickMarkMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 62, height: 62)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(radius: 6, y: 2)
                .rotationEffect(
                    .degrees(pecking ? -8 : 2),
                    anchor: .bottomTrailing
                )
                .offset(
                    x: pecking ? -6 : 14,
                    y: pecking ? 4 : 0
                )
        }
        .frame(width: 82, height: 68)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }

            withAnimation(.easeIn(duration: 0.16)) {
                pecking = true
            }

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(160))
                withAnimation(.easeOut(duration: 0.12)) {
                    grainScale = 0.15
                    grainOpacity = 0
                }
                withAnimation(.spring(duration: 0.28, bounce: 0.35)) {
                    pecking = false
                }
            }
        }
    }
}

private struct HabitRow: View {
    let habit: Habit
    let completed: Bool
    let skipped: Bool
    let streak: Int
    let weeklyCount: Int
    let weeklyTarget: Int
    let onToggle: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink {
                HabitDetailView(habit: habit)
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: habit.colorHex).opacity(0.16))
                        Image(systemName: habit.symbolName)
                            .font(.headline)
                            .foregroundStyle(Color.habitsReadableAccent(for: habit.colorHex))
                    }
                    .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(habit.name)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                        if skipped {
                            Label(
                                L10n.string("habit.skipped.today"),
                                systemImage: "minus.circle.fill"
                            )
                            .font(.caption)
                            .foregroundStyle(Color.habitsSecondaryText)
                        } else if habit.usesFlexibleWeeklyTarget {
                            Label(
                                L10n.format(
                                    "habit.weekly.progress.format",
                                    weeklyCount,
                                    weeklyTarget
                                ),
                                systemImage: "calendar.badge.checkmark"
                            )
                            .font(.caption)
                            .foregroundStyle(Color.habitsSecondaryText)
                        } else if streak > 0 {
                            Label(
                                L10n.streak(streak),
                                systemImage: "flame.fill"
                            )
                            .font(.caption)
                            .foregroundStyle(Color.habitsSecondaryText)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 4)

            Button(action: onToggle) {
                Image(
                    systemName: completed
                        ? "checkmark.circle.fill"
                        : (skipped ? "minus.circle.fill" : "circle")
                )
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(
                    completed
                        ? Color.habitsReadableAccent(for: habit.colorHex)
                        : (skipped ? Color.habitsWarningText : Color.habitsSecondaryText)
                )
                .frame(width: 44, height: 44)
                .symbolEffect(.bounce, value: completed)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                completed
                    ? L10n.string("habit.undo")
                    : L10n.string("habit.complete")
            )
        }
        .padding(14)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 18))
        .contextMenu {
            Button(action: onSkip) {
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
        .accessibilityAction(
            named: Text(
                skipped
                    ? L10n.string("habit.skip.undo")
                    : L10n.string("habit.skip.today")
            )
        ) {
            onSkip()
        }
    }
}
