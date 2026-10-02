import SwiftData
import SwiftUI

struct ManageHabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    private var activeHabits: [Habit] {
        HabitOrdering.sorted(
            habits.filter { !$0.isArchived && !$0.isPaused }
        )
    }

    private var pausedHabits: [Habit] {
        HabitOrdering.sorted(
            habits.filter { !$0.isArchived && $0.isPaused }
        )
    }

    private var archivedHabits: [Habit] {
        HabitOrdering.sorted(habits.filter(\.isArchived))
    }

    var body: some View {
        Group {
            if habits.isEmpty {
                ContentUnavailableView(
                    L10n.string("manage.empty.title"),
                    systemImage: "tray",
                    description: Text(
                        L10n.string("manage.empty.description")
                    )
                )
            } else {
                List {
                    if !activeHabits.isEmpty {
                        Section {
                            Text(L10n.string("manage.active"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .accessibilityAddTraits(.isHeader)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(
                                    EdgeInsets(
                                        top: 4,
                                        leading: 20,
                                        bottom: 2,
                                        trailing: 20
                                    )
                                )

                            ForEach(activeHabits) { habit in
                                habitLink(habit)
                            }
                            .onMove(perform: moveActiveHabits)
                        } footer: {
                            if activeHabits.count > 1 {
                                Text(L10n.string("manage.reorder.hint"))
                                    .foregroundStyle(Color.habitsSecondaryText)
                            }
                        }
                    }

                    if !pausedHabits.isEmpty {
                        Section(L10n.string("manage.paused")) {
                            ForEach(pausedHabits) { habit in
                                habitLink(habit)
                            }
                        }
                    }

                    if !archivedHabits.isEmpty {
                        Section(L10n.string("archive.title")) {
                            ForEach(archivedHabits) { habit in
                                habitLink(habit)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(L10n.string("manage.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if activeHabits.count > 1 {
                EditButton()
            }
        }
    }

    private func habitLink(_ habit: Habit) -> some View {
        NavigationLink {
            HabitDetailView(habit: habit)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            Color(hex: habit.colorHex)
                                .opacity(0.16)
                        )
                    Image(systemName: habit.symbolName)
                        .foregroundStyle(
                            Color.habitsReadableAccent(for: habit.colorHex)
                        )
                }
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(
                        habit.isPaused && !habit.isArchived
                            ? L10n.string("manage.paused")
                            : HabitScheduleText.description(for: habit)
                    )
                    .font(.caption)
                    .foregroundStyle(Color.habitsSecondaryText)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func moveActiveHabits(
        from source: IndexSet,
        to destination: Int
    ) {
        var reordered = activeHabits
        reordered.move(fromOffsets: source, toOffset: destination)

        for (index, habit) in reordered.enumerated() {
            habit.sortOrder = index
        }

        try? modelContext.save()
        HabitDataChangeNotifier.notify()
    }
}
