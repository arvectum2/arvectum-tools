import SwiftData
import SwiftUI

struct HabitProgressDaySelection: Identifiable {
    let date: Date
    var id: String { HabitDayKey.make(for: date) }
}

/// Edits an individual historical day; does not change past days or the
/// scheduled goal itself. Keeps the published SwiftData model unchanged.
struct HabitProgressEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let habit: Habit
    let date: Date
    @State private var selectedSlots: Set<Int> = []
    @State private var errorMessage: String?
    @State private var showingError = false

    private var dayKey: String { HabitDayKey.make(for: date) }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text(habit.name)
                    .font(.headline)
                Text(date.formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if habit.usesDailyMultiple {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 54, maximum: 80))],
                        spacing: 12
                    ) {
                        ForEach(1...habit.dailyTarget, id: \.self) { slot in
                            Button {
                                update(slot: slot, enabled: !selectedSlots.contains(slot))
                            } label: {
                                Image(
                                    systemName: selectedSlots.contains(slot)
                                        ? "checkmark.circle.fill" : "circle"
                                )
                                .font(.title2)
                                .foregroundStyle(Color.habitsReadableAccent(for: habit.colorHex))
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L10n.format(
                                "habit.multi.slot.format", slot, habit.dailyTarget
                            ))
                            .accessibilityValue(
                                selectedSlots.contains(slot)
                                    ? L10n.string("habit.multi.checked")
                                    : L10n.string("habit.multi.unchecked")
                            )
                        }
                    }
                } else {
                    HStack(spacing: 18) {
                        Button {
                            if let last = selectedSlots.max() {
                                update(slot: last, enabled: false)
                            }
                        } label: {
                            Image(systemName: "minus.circle")
                                .frame(minWidth: 54, minHeight: 54)
                        }
                        .disabled(selectedSlots.isEmpty)
                        .accessibilityLabel(L10n.string("habit.goal.subtract"))

                        Spacer()
                        Text(progressText)
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                            .accessibilityIdentifier("history.goal.progress")
                        Spacer()

                        Button {
                            if let next = (1...habit.dailyTarget).first(where: {
                                !selectedSlots.contains($0)
                            }) {
                                update(slot: next, enabled: true)
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .frame(minWidth: 54, minHeight: 54)
                        }
                        .disabled(selectedSlots.count >= habit.dailyTarget)
                        .accessibilityLabel(L10n.string("habit.goal.add"))
                    }
                    .font(.title2)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.habitsReadableAccent(for: habit.colorHex))
                }

                Text(L10n.format(
                    "habit.history.progress",
                    selectedSlots.count,
                    habit.dailyTarget
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(20)
            .navigationTitle(L10n.string("habit.history.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.string("common.done")) { dismiss() }
                }
            }
            .onAppear(perform: refresh)
            .alert(L10n.string("habit.history.error"), isPresented: $showingError) {
                Button(L10n.string("common.ok"), role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var progressText: String {
        if habit.usesDurationGoal {
            return L10n.format(
                "habit.goal.duration.progress",
                selectedSlots.count * 5, habit.durationMinutes
            )
        }
        return L10n.format(
            "habit.goal.quantity.progress",
            selectedSlots.count, habit.quantityTarget
        )
    }

    private func refresh() {
        let rows = (try? modelContext.fetch(FetchDescriptor<HabitCheckIn>())) ?? []
        selectedSlots = Set(HabitMultiCheck.slots(
            habitID: habit.id,
            dayKey: dayKey,
            target: habit.dailyTarget,
            checkIns: rows
        ).keys)
    }

    private func update(slot: Int, enabled: Bool) {
        let accepted = HabitMultiCheckMutation.setSlot(
            habitID: habit.id,
            dayKey: dayKey,
            slot: slot,
            enabled: enabled,
            context: modelContext
        )
        guard accepted else {
            refresh()
            return
        }
        do {
            try modelContext.save()
            refresh()
            HabitDataChangeNotifier.notify()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            showingError = true
            refresh()
        }
    }
}
