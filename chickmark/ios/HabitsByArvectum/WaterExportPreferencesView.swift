import SwiftUI

/// Explicit control, only shown for an existing *quantity* habit. Opening this
/// sheet does NOT request HealthKit permissions or export anything.
struct WaterExportPreferencesView: View {
    @Environment(\.dismiss) private var dismiss

    let habit: Habit
    @State private var enabled = false
    @State private var millilitres = 250
    @State private var saving = false
    @State private var errorMessage: String?

    private var coordinator: WaterExportCoordinator { .shared }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(L10n.string("water.export.toggle"), isOn: $enabled)
                        .accessibilityIdentifier("water.export.toggle")
                    if enabled {
                        Stepper(
                            L10n.format("water.export.volume", millilitres),
                            value: $millilitres, in: 10...1_000, step: 10
                        )
                        .accessibilityIdentifier("water.export.volume")
                        Text(L10n.string("water.export.example"))
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                } header: {
                    Text(L10n.string("water.export.title"))
                } footer: {
                    Text(L10n.string("water.export.explanation"))
                }
                Section {
                    Label(L10n.string("water.export.privacy"), systemImage: "hand.raised")
                        .font(.footnote)
                }
            }
            .navigationTitle(L10n.string("water.export.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.string("common.save")) {
                        save()
                    }
                    .disabled(saving)
                    .accessibilityIdentifier("water.export.save")
                }
            }
            .disabled(saving)
            .onAppear {
                guard let rule = coordinator.rule(for: habit.id) else { return }
                enabled = true
                millilitres = rule.millilitresPerUnit
            }
            .alert(L10n.string("water.export.error"), isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(L10n.string("common.ok"), role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func save() {
        guard habit.usesQuantitativeGoal else { return }
        guard coordinator.canUpdateRules else {
            errorMessage = L10n.string("water.export.storage.error")
            return
        }
        saving = true
        Task { @MainActor in
            defer { saving = false }
            if enabled {
                do {
                    // A user pressing Save explicitly opts into writing
                    // dietaryWater. A failed/denied request creates no rule.
                    try await coordinator.requestWriteAccess()
                    let enabledAt = coordinator.rule(for: habit.id)?.enabledAt ?? Date()
                    guard coordinator.setRule(WaterExportRule(
                        millilitresPerUnit: millilitres, enabledAt: enabledAt
                    ), for: habit.id) else {
                        errorMessage = L10n.string("water.export.storage.error")
                        return
                    }
                } catch {
                    errorMessage = error.localizedDescription
                    return
                }
            } else {
                guard coordinator.setRule(nil, for: habit.id) else {
                    errorMessage = L10n.string("water.export.storage.error")
                    return
                }
            }
            coordinator.requestSync()
            dismiss()
        }
    }
}
