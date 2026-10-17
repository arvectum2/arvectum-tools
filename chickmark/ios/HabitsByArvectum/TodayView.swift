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
    @State private var pendingReviewPasteRequest: ReviewNotePasteRequest?
    @State private var noteAttachments: [UUID: ReviewNoteAttachment] = [:]
    @State private var showingNoteAttachment: ReviewNoteAttachment?
    @State private var importError: String?
    @State private var undoOffer: CompletionUndoOffer?
    @State private var deepLinkedHabitID: UUID?
    @State private var referenceDate = Date()
    @State private var clockRevision = 0
    @State private var chickInCelebrationID: UUID?
    @State private var chickInCelebrationHabitID: UUID?
    @State private var adEligible = false
    @State private var nativeAdUnavailable = false

    @State private var healthProjectionRevision = 0

    @AppStorage("chickmark.gentleRestart.enabled")
    private var gentleRestartEnabled = false
    @AppStorage("chickmark.gentleRestart.quietDays")
    private var gentleRestartQuietDays = 7
    @AppStorage("chickmark.gentleRestart.snoozedDayKey")
    private var gentleRestartSnoozedDayKey = ""

    private var displayedCheckIns: [HabitCheckIn] {
        _ = healthProjectionRevision
        return HealthHabitCoordinator.shared.visibleCheckIns(for: checkIns, habits: habits)
    }

    private var activeToday: [Habit] {
        HabitTodayProjection.orderedDueHabits(
            habits: habits,
            on: referenceDate,
            checkIns: displayedCheckIns,
            skips: skips,
            pausePeriods: pausePeriods
        )
    }

    private var gentleRestartCandidates: [GentleRestartCandidate] {
        guard gentleRestartEnabled,
              gentleRestartSnoozedDayKey != HabitDayKey.make(for: referenceDate)
        else { return [] }
        return GentleRestart.candidates(
            habits: habits,
            // Same resolved projection as the visible Today checkmark:
            // never invite a Health-completed habit to restart today.
            checkIns: displayedCheckIns,
            skips: skips,
            pausePeriods: pausePeriods,
            today: referenceDate,
            minimumQuietDays: gentleRestartQuietDays
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

                // A genuine sibling footer ensures the scrollable habits
                // area stops ABOVE the native ad, not behind it. A nested
                // safeAreaInset on NavigationStack can instead overlap the
                // scroll viewport after native content changes height.
                VStack(spacing: 0) {
                    if habits.filter({ !$0.isArchived }).isEmpty &&
                        pendingOneOffReminders.isEmpty
                    {
                        firstHabitEmptyState
                            .frame(maxHeight: .infinity)
                    } else {
                        todayContent
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    if adEligible && !nativeAdUnavailable {
                        HabitStickyNativeSlot {
                            // Remove the *whole footer*, not just ad assets.
                            // Otherwise the native host may reserve bottom
                            // safe-area space after a no-fill/binding failure.
                            nativeAdUnavailable = true
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(NotificationCenter.default.publisher(for: .healthHabitProjectionChanged)) { _ in
                healthProjectionRevision += 1
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack(alignment: .center, spacing: 10) {
                    ChickMarkBrandHeader()
                    Spacer(minLength: 4)
                    HStack(spacing: 0) {
                        NavigationLink {
                            ManageHabitsView()
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 20, weight: .medium))
                                .frame(width: 43, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel(L10n.string("manage.accessibility"))

                        Menu {
                            Button {
                                showingAddHabit = true
                            } label: {
                                Label(L10n.string("add.menu.habit"), systemImage: "repeat")
                            }
                            Button {
                                showingAddOneOffReminder = true
                            } label: {
                                Label(L10n.string("add.menu.oneoff"), systemImage: "bell.badge")
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .medium))
                                .frame(width: 43, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel(L10n.string("common.add"))
                    }
                    .tint(.primary)
                    .fixedSize(horizontal: true, vertical: false)
                    .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(Color.habitsBackground)
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
            .sheet(item: $pendingReviewPasteRequest) { request in
                ReviewNoteTransferFlowSheet(request: request) {
                    refreshReviewAttachments()
                }
            }
            .sheet(item: $showingNoteAttachment) { value in
                ReviewNoteAttachmentSheet(attachment: value)
            }
            .alert("Передача из Ухвата", isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )) {
                Button("OK") {}
            } message: {
                Text(importError ?? "")
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
                refreshReviewAttachments()
                openImportedNoteFromNotificationIfNeeded()
                refreshReferenceDate()
                registerForegroundLaunchIfNeeded()
                refreshAdEligibility()
                backfillLegacyDayKeys()
#if DEBUG
                openDebugSurfaceIfRequested()
#endif
                await HabitReminderCoordinator.shared.refreshNow()
#if REVIEW_HANDOFF_QA
                await ReviewNotificationPhysicalQA.inspectScheduledAndDelivered(context: modelContext)
#endif
                await HealthHabitCoordinator.shared.synchronize()
                HabitWidgetCoordinator.shared.refresh()
#if DEBUG
                await HabitReminderScheduler.debugDumpIfRequested()
#endif
            }
            // HealthKit samples may arrive after steps are recorded.
            // Poll only when active; no guarantee of immediate system writes.
            .task(id: scenePhase == .active) {
                guard scenePhase == .active else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(
                        for: .seconds(HealthHabitRefreshPolicy.foregroundSeconds)
                    )
                    guard !Task.isCancelled else { break }
                    guard !HealthHabitRuleStore.shared.allRules.isEmpty else { continue }
                    await HealthHabitCoordinator.shared.synchronize()
                }
            }
            .task(id: clockTaskID) {
                let delay = HabitDayBoundary.delay(from: referenceDate)
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                refreshReferenceDate(forceRevision: true)
                await HabitReminderCoordinator.shared.refreshNow()
#if REVIEW_HANDOFF_QA
                await ReviewNotificationPhysicalQA.inspectScheduledAndDelivered(context: modelContext)
#endif
                await HealthHabitCoordinator.shared.synchronize()
                HabitWidgetCoordinator.shared.refresh()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    refreshReferenceDate(forceRevision: true)
                    registerForegroundLaunchIfNeeded()
                    refreshAdEligibility()
                    HabitReminderCoordinator.shared.refresh()
#if REVIEW_HANDOFF_QA
                    Task {
                        await HabitReminderCoordinator.shared.refreshNow()
                        await ReviewNotificationPhysicalQA.inspectScheduledAndDelivered(context: modelContext)
                    }
#endif
                    HealthHabitCoordinator.shared.refresh()
                    HabitWidgetCoordinator.shared.refresh()
                }
            }
            .onReceive(NotificationCenter.default.publisher(
                for: ReviewNoteNotificationNavigation.notificationName
            )) { _ in
                openImportedNoteFromNotificationIfNeeded()
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
                if !gentleRestartCandidates.isEmpty {
                    gentleRestartCard
                }
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
                                    checkIns: displayedCheckIns,
                                    skips: skips,
                                    pausePeriods: pausePeriods
                                ),
                                weeklyCount: HabitFrequency.weeklyCompletionCount(
                                    habit: habit,
                                    containing: referenceDate,
                                    checkIns: displayedCheckIns
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
                                    checkIns: displayedCheckIns
                                ).keys),
                                healthProgress: HealthHabitCoordinator.shared.progress(
                                    for: habit.id, on: referenceDate
                                ),
                                healthRule: HealthHabitRuleStore.shared.rule(for: habit.id),
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

    private var gentleRestartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L10n.string("restart.card.title"), systemImage: "arrow.uturn.forward.circle")
                .font(.headline)
            Text(L10n.string("restart.card.description"))
                .font(.subheadline)
                .foregroundStyle(Color.habitsSecondaryText)

            ForEach(gentleRestartCandidates.prefix(3)) { candidate in
                if let habit = habits.first(where: { $0.id == candidate.habitID }) {
                    NavigationLink {
                        HabitDetailView(habit: habit)
                    } label: {
                        HStack(spacing: 8) {
                            Text(habit.name)
                                .font(.subheadline.weight(.semibold))
                            Spacer(minLength: 4)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("restart-open-\(habit.id.uuidString)")
                }
            }
            Button(L10n.string("restart.card.later")) {
                gentleRestartSnoozedDayKey = HabitDayKey.make(for: referenceDate)
            }
            .font(.footnote)
            .accessibilityIdentifier("restart-later")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityIdentifier("gentle-restart-card")
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
                        },
                        onOpenNote: noteAttachments[reminder.id].map { attachment in
                            { showingNoteAttachment = attachment }
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
        do {
            try modelContext.save()
            if noteAttachments[reminder.id] != nil {
                try ReviewNoteAttachmentRepository().remove(reminder.id)
                refreshReviewAttachments()
            }
            HabitReminderCoordinator.shared.dataDidChange()
        } catch {
            modelContext.rollback()
            importError = error.localizedDescription
        }
    }

    private func openImportedNoteFromNotificationIfNeeded() {
        if let note = ReviewNoteNotificationNavigation.takePending() {
            showingNoteAttachment = note
        }
    }

    private func refreshReviewAttachments() {
        do {
            noteAttachments = Dictionary(uniqueKeysWithValues:
                try ReviewNoteAttachmentRepository().all().map { ($0.id, $0) })
        } catch {
            importError = "Не удалось открыть переданные заметки: \(error.localizedDescription)"
        }
    }

    private func handleDeepLink(_ url: URL) {
        if ReviewNoteHandoff.nonce(from: url) != nil {
            pendingReviewPasteRequest = ReviewNotePasteRequest(url: url)
            return
        }
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
#if REVIEW_HANDOFF_QA
        adEligible = false
        return
#endif
        let arguments = ProcessInfo.processInfo.arguments
#if DEBUG
        // Isolated demo-only QA. Never force real YAN traffic from XCTest.
        if arguments.contains("--debug-force-ads") &&
            arguments.contains("--chickmark-demo-ads")
        {
            adEligible = true
            return
        }
#endif
        guard !arguments.contains("--ui-testing") else {
            adEligible = false
            return
        }

        adEligible = HabitAdEligibilityStore.shared.isEligible()
    }

    private func isCompleted(_ habit: Habit, on date: Date) -> Bool {
        HabitMetrics.isCompleted(
            habitID: habit.id,
            on: date,
            checkIns: displayedCheckIns,
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
