import SwiftUI

// Presentation-only components extracted from TodayView.
struct OneOffReminderRow: View {
    let reminder: OneOffReminder
    let onComplete: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var dueText: String {
        let calendar = Calendar.autoupdatingCurrent
        let time = reminder.dueAt.formatted(
            date: .omitted,
            time: .shortened
        )

        if calendar.isDateInToday(reminder.dueAt) {
            return L10n.format("oneoff.today.format", time)
        }
        if calendar.isDateInTomorrow(reminder.dueAt) {
            return L10n.format("oneoff.tomorrow.format", time)
        }
        return reminder.dueAt.formatted(
            date: .abbreviated,
            time: .shortened
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.arvectumOrange)
                .frame(width: 40, height: 40)
                .background(
                    Color.arvectumOrange.opacity(0.13),
                    in: Circle()
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(dueText)
                .font(.caption)
                .foregroundStyle(Color.habitsSecondaryText)
            }

            Spacer(minLength: 4)

            Menu {
                Button(action: onEdit) {
                    Label(
                        L10n.string("oneoff.edit"),
                        systemImage: "pencil"
                    )
                }
                Button(role: .destructive, action: onDelete) {
                    Label(
                        L10n.string("oneoff.delete"),
                        systemImage: "trash"
                    )
                }
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(L10n.string("oneoff.edit"))

            Button(action: onComplete) {
                Image(systemName: "circle")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.habitsSecondaryText)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.string("oneoff.complete"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Color.habitsSurface,
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
}

struct TodaySummary: View {
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

struct ChickInCelebrationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pecking = false
    @State private var grainScale: CGFloat = 0.72
    @State private var grainOpacity = 0.0
    @State private var mascotScale: CGFloat = 0.92

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.arvectumOrange)
                .frame(width: 11, height: 6)
                .rotationEffect(.degrees(-18))
                .scaleEffect(grainScale)
                .opacity(grainOpacity)
                .offset(x: 3, y: 11)

            Image("ChickMarkMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 68)
                .shadow(
                    color: Color.arvectumMint.opacity(0.28),
                    radius: 7,
                    y: 2
                )
                .scaleEffect(mascotScale)
                .rotationEffect(
                    .degrees(pecking ? -10 : 1),
                    anchor: .bottomTrailing
                )
                .offset(
                    x: pecking ? -4 : 13,
                    y: pecking ? 5 : 0
                )
        }
        .frame(width: 86, height: 72)
        .accessibilityHidden(true)
        .onAppear {
            if reduceMotion {
                mascotScale = 1
                grainOpacity = 0
                return
            }

            withAnimation(.spring(duration: 0.24, bounce: 0.22)) {
                mascotScale = 1
            }
            withAnimation(.easeOut(duration: 0.12)) {
                grainScale = 1
                grainOpacity = 1
            }

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(.easeIn(duration: 0.15)) {
                    pecking = true
                }

                try? await Task.sleep(for: .milliseconds(150))
                withAnimation(.easeOut(duration: 0.12)) {
                    grainScale = 0.12
                    grainOpacity = 0
                }
                withAnimation(.spring(duration: 0.30, bounce: 0.32)) {
                    pecking = false
                    mascotScale = 1.04
                }

                try? await Task.sleep(for: .milliseconds(190))
                withAnimation(.easeOut(duration: 0.16)) {
                    mascotScale = 1
                }
            }
        }
    }
}

struct HabitRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let habit: Habit
    let completed: Bool
    let skipped: Bool
    let streak: Int
    let weeklyCount: Int
    let weeklyTarget: Int
    let dailySlots: Set<Int>
    let celebrationID: UUID?
    let onToggle: () -> Void
    let onSetSlot: (Int, Bool) -> Void
    let onSkip: () -> Void


    private var identityLink: some View {
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
                        } else if habit.usesCompletionInterval {
                            Label(
                                HabitScheduleText.description(for: habit),
                                systemImage: "clock.arrow.circlepath"
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
    }

    @ViewBuilder
    private var progressControls: some View {
            if habit.usesQuantitativeGoal || habit.usesDurationGoal {
                VStack(spacing: 2) {
                    Text(habit.usesDurationGoal
                         ? L10n.format(
                            "habit.goal.duration.progress", dailySlots.count * 5,
                            habit.durationMinutes
                         )
                         : L10n.format(
                            "habit.goal.quantity.progress", dailySlots.count,
                            habit.quantityTarget
                         ))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.habitsSecondaryText)
                    HStack(spacing: 10) {
                        Button {
                            if let last = dailySlots.max() { onSetSlot(last, false) }
                        } label: {
                            Image(systemName: "minus.circle")
                                .frame(width: 38, height: 38)
                        }
                        .disabled(dailySlots.isEmpty)
                        .accessibilityLabel(L10n.string("habit.goal.subtract"))
                        Button {
                            if let next = (1...habit.dailyTarget).first(where: {
                                !dailySlots.contains($0)
                            }) { onSetSlot(next, true) }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .frame(width: 38, height: 38)
                        }
                        .disabled(dailySlots.count >= habit.dailyTarget)
                        .accessibilityLabel(L10n.string("habit.goal.add"))
                    }
                    .font(.title3)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.habitsReadableAccent(for: habit.colorHex))
                }
            } else if habit.usesDailyMultiple {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(minimum: 44), spacing: 4),
                        count: habit.dailyTarget
                    ),
                    spacing: 4
                ) {
                    ForEach(1...habit.dailyTarget, id: \.self) { slot in
                        Button {
                            onSetSlot(slot, !dailySlots.contains(slot))
                        } label: {
                            Image(systemName: dailySlots.contains(slot)
                                  ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 23))
                                .frame(width: dynamicTypeSize.isAccessibilitySize ? 54 : 29, height: 44)
                                .foregroundStyle(Color.habitsReadableAccent(for: habit.colorHex))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(L10n.format(
                            "habit.multi.slot.format", slot, habit.dailyTarget
                        ))
                        .accessibilityValue(
                            dailySlots.contains(slot)
                                ? L10n.string("habit.multi.checked")
                                : L10n.string("habit.multi.unchecked")
                        )
                    }
                }
            } else {
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
    }

    var body: some View {
        Group {
            if habit.supportsIncrementalGoal {
                VStack(alignment: .leading, spacing: 10) {
                    identityLink
                        .frame(maxWidth: .infinity, alignment: .leading)
                    progressControls
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                HStack(spacing: 12) {
                    identityLink
                    Spacer(minLength: 4)
                    progressControls
                }
            }
        }
        .padding(14)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(alignment: .trailing) {
            if let celebrationID {
                ChickInCelebrationView()
                    .id(celebrationID)
                    .padding(.trailing, 4)
                    .transition(
                        .scale(scale: 0.8).combined(with: .opacity)
                    )
                    .allowsHitTesting(false)
            }
        }
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
