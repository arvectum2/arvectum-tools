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
    @FocusState private var nameFocused: Bool

    private let quickNames = ["Вода", "Чтение", "Прогулка", "Тренировка"]

    init(habit: Habit? = nil) {
        self.habit = habit
        _name = State(initialValue: habit?.name ?? "")
        _colorHex = State(initialValue: habit?.colorHex ?? HabitPalette.colors[0])
        _symbolName = State(initialValue: habit?.symbolName ?? HabitPalette.symbols[0])
        _schedule = State(initialValue: habit?.schedule ?? .everyDay)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Привычка") {
                    TextField("Например, читать 20 минут", text: $name)
                        .focused($nameFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            if canSave { save() }
                        }

                    if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(quickNames, id: \.self) { title in
                                    Button(title) {
                                        name = title
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }

                Section("Внешний вид") {
                    colorPicker
                    symbolPicker
                }

                Section("Дни") {
                    weekdayPicker

                    HStack {
                        Button("Каждый день") {
                            schedule = .everyDay
                        }
                        Spacer()
                        Button("Будни") {
                            schedule = .weekdays
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
            .navigationTitle(habit == nil ? "Новая привычка" : "Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if habit == nil { nameFocused = true }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(habit == nil ? "Готово" : "Сохранить", action: save)
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        schedule.rawValue != 0
    }

    private var colorPicker: some View {
        HStack(spacing: 14) {
            ForEach(HabitPalette.colors, id: \.self) { hex in
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
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Цвет привычки")
            }
        }
        .padding(.vertical, 4)
    }

    private var symbolPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(HabitPalette.symbols, id: \.self) { symbol in
                    Button {
                        symbolName = symbol
                    } label: {
                        Image(systemName: symbol)
                            .frame(width: 38, height: 38)
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
                        .frame(height: 36)
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
            }
        }
    }

    private var weekdayItems: [(label: String, option: HabitSchedule)] {
        [
            ("Пн", .monday),
            ("Вт", .tuesday),
            ("Ср", .wednesday),
            ("Чт", .thursday),
            ("Пт", .friday),
            ("Сб", .saturday),
            ("Вс", .sunday)
        ]
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, schedule.rawValue != 0 else { return }

        if let habit {
            habit.name = trimmed
            habit.symbolName = symbolName
            habit.colorHex = colorHex
            habit.schedule = schedule
        } else {
            modelContext.insert(
                Habit(
                    name: trimmed,
                    symbolName: symbolName,
                    colorHex: colorHex,
                    scheduleMask: schedule.rawValue
                )
            )
        }

        try? modelContext.save()
        dismiss()
    }
}
