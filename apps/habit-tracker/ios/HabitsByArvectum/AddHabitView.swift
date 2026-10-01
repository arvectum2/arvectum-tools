import SwiftData
import SwiftUI

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let habit: Habit?

    @State private var name: String
    @State private var colorHex: String
    @State private var symbolName: String
    @State private var schedule: HabitSchedule
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var showingNotificationDenied = false
    @State private var requestingNotificationPermission = false
    @State private var optionsExpanded: Bool
    @State private var customDaysExpanded: Bool
    @FocusState private var nameFocused: Bool

    private var quickHabits: [(title: String, symbol: String)] {
        [
            (L10n.string("quick.water"), "drop.fill"),
            (L10n.string("quick.reading"), "book.fill"),
            (L10n.string("quick.walk"), "figure.walk"),
            (L10n.string("quick.workout"), "dumbbell.fill")
        ]
    }

    init(habit: Habit? = nil) {
        self.habit = habit
        _name = State(initialValue: habit?.name ?? "")
        _colorHex = State(initialValue: habit?.colorHex ?? HabitPalette.colors[0])
        _symbolName = State(initialValue: habit?.symbolName ?? HabitPalette.symbols[0])
        let initialSchedule = habit?.schedule ?? .everyDay
        _schedule = State(initialValue: initialSchedule)
        _reminderEnabled = State(initialValue: habit?.reminderEnabled ?? false)
        _customDaysExpanded = State(
            initialValue: initialSchedule != .everyDay &&
                initialSchedule != .weekdays
        )
        _optionsExpanded = State(
            initialValue: habit?.reminderEnabled == true ||
                habit?.colorHex != HabitPalette.colors[0] ||
                habit?.symbolName != HabitPalette.symbols[0]
        )

        let hour = habit?.reminderHour ?? 20
        let minute = habit?.reminderMinute ?? 0
        let time = Calendar.autoupdatingCurrent.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: .now
        ) ?? .now
        _reminderTime = State(initialValue: time)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.string("habit.section")) {
                    TextField(L10n.string("habit.name.placeholder"), text: $name)
                        .focused($nameFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            if canSave { save() }
                        }

                    if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(quickHabits, id: \.title) { item in
                                    Button(item.title) {
                                        name = item.title
                                        symbolName = item.symbol
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }

                Section(L10n.string("section.days")) {
                    HStack(spacing: 10) {
                        schedulePresetButton(
                            title: L10n.string("schedule.everyday"),
                            preset: .everyDay
                        )
                        schedulePresetButton(
                            title: L10n.string("schedule.weekdays"),
                            preset: .weekdays
                        )
                        Spacer()
                    }

                    DisclosureGroup(
                        isExpanded: $customDaysExpanded
                    ) {
                        weekdayPicker
                            .padding(.top, 8)
                    } label: {
                        Text(L10n.string("schedule.custom"))
                    }
                }

                Section {
                    DisclosureGroup(
                        isExpanded: $optionsExpanded
                    ) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(L10n.string("appearance.color"))
                                .font(.subheadline.weight(.semibold))
                            colorPicker

                            Text(L10n.string("appearance.icon"))
                                .font(.subheadline.weight(.semibold))
                            symbolPicker

                            Toggle(
                                L10n.string("reminder.toggle"),
                                isOn: $reminderEnabled
                            )
                            .onChange(of: reminderEnabled) { _, enabled in
                                guard enabled else { return }
                                requestNotificationPermission()
                            }

                            if reminderEnabled {
                                DatePicker(
                                    L10n.string("reminder.time"),
                                    selection: $reminderTime,
                                    displayedComponents: .hourAndMinute
                                )
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        Text(L10n.string("section.moreOptions"))
                    }
                }
            }
            .navigationTitle(
                habit == nil
                    ? L10n.string("habit.new.title")
                    : L10n.string("habit.edit.title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if habit == nil { nameFocused = true }
            }
            .alert(
                L10n.string("notification.denied.title"),
                isPresented: $showingNotificationDenied
            ) {
                Button(L10n.string("common.ok"), role: .cancel) {}
            } message: {
                Text(L10n.string("notification.denied.message"))
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.cancel")) { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(
                        habit == nil
                            ? L10n.string("common.done")
                            : L10n.string("common.save"),
                        action: save
                    )
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        schedule.rawValue != 0 &&
        !requestingNotificationPermission
    }

    private func schedulePresetButton(
        title: String,
        preset: HabitSchedule
    ) -> some View {
        let selected = schedule == preset

        return Button {
            schedule = preset
            customDaysExpanded = false
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(
                    selected ? Color.arvectumNavy : .primary
                )
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .padding(.vertical, 2)
                .background(
                    selected
                        ? Color.arvectumMint
                        : Color.secondary.opacity(0.10),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var colorPicker: some View {
        HStack(spacing: 6) {
            ForEach(Array(HabitPalette.colors.enumerated()), id: \.offset) { item in
                let index = item.offset
                let hex = item.element
                Button {
                    colorHex = hex
                } label: {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 30, height: 30)
                        .overlay {
                            if colorHex == hex {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    L10n.format("accessibility.color.format", index + 1)
                )
                .accessibilityValue(
                    colorHex == hex
                        ? L10n.string("accessibility.selected")
                        : ""
                )
            }
        }
    }

    private var symbolPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(HabitPalette.symbols.enumerated()), id: \.offset) { item in
                    let index = item.offset
                    let symbol = item.element
                    Button {
                        symbolName = symbol
                    } label: {
                        Image(systemName: symbol)
                            .frame(width: 44, height: 44)
                            .foregroundStyle(
                                symbolName == symbol
                                    ? Color.arvectumNavy
                                    : .primary
                            )
                            .background(
                                symbolName == symbol
                                    ? Color.arvectumMint
                                    : Color.secondary.opacity(0.10),
                                in: RoundedRectangle(cornerRadius: 11)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        L10n.format("accessibility.symbol.format", index + 1)
                    )
                    .accessibilityValue(
                        symbolName == symbol
                            ? L10n.string("accessibility.selected")
                            : ""
                    )
                }
            }
        }
    }

    private var weekdayPicker: some View {
        HStack(spacing: 6) {
            ForEach(weekdayItems, id: \.label) { item in
                let selected = schedule.contains(item.option)
                Button {
                    if selected {
                        schedule.remove(item.option)
                    } else {
                        schedule.insert(item.option)
                    }
                } label: {
                    Text(item.label)
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(
                            selected ? Color.arvectumNavy : .primary
                        )
                        .background(
                            selected
                                ? Color.arvectumMint
                                : Color.secondary.opacity(0.10),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    private var weekdayItems: [(label: String, option: HabitSchedule)] {
        [
            (L10n.string("weekday.mon.short"), .monday),
            (L10n.string("weekday.tue.short"), .tuesday),
            (L10n.string("weekday.wed.short"), .wednesday),
            (L10n.string("weekday.thu.short"), .thursday),
            (L10n.string("weekday.fri.short"), .friday),
            (L10n.string("weekday.sat.short"), .saturday),
            (L10n.string("weekday.sun.short"), .sunday)
        ]
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, schedule.rawValue != 0 else { return }

        let components = Calendar.autoupdatingCurrent.dateComponents(
            [.hour, .minute],
            from: reminderTime
        )
        let reminderHour = components.hour ?? 20
        let reminderMinute = components.minute ?? 0
        let savedHabit: Habit

        if let habit {
            habit.name = trimmed
            habit.symbolName = symbolName
            habit.colorHex = colorHex
            habit.schedule = schedule
            habit.reminderEnabled = reminderEnabled
            habit.reminderHour = reminderHour
            habit.reminderMinute = reminderMinute
            savedHabit = habit
        } else {
            let newHabit = Habit(
                name: trimmed,
                symbolName: symbolName,
                colorHex: colorHex,
                scheduleMask: schedule.rawValue,
                reminderEnabled: reminderEnabled,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute
            )
            modelContext.insert(newHabit)
            savedHabit = newHabit
        }

        try? modelContext.save()
        HabitDataChangeNotifier.notify()
        Task { @MainActor in
            let synced = await HabitReminderScheduler.sync(habit: savedHabit)
            if !synced && savedHabit.reminderEnabled {
                savedHabit.reminderEnabled = false
                try? modelContext.save()
            }
        }
        dismiss()
    }

    private func requestNotificationPermission() {
        requestingNotificationPermission = true
        Task {
            let granted = await HabitReminderScheduler.ensureAuthorization()
            await MainActor.run {
                requestingNotificationPermission = false
                if !granted {
                    reminderEnabled = false
                    showingNotificationDenied = true
                }
            }
        }
    }
}
