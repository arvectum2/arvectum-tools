import SwiftUI

struct HealthHabitSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let habit: Habit

    @State private var metric: HealthHabitMetric = .steps
    @State private var targetText = "5000"
    @State private var isEnabled = false
    @State private var isSaving = false
    @State private var errorText: String?

    private var supportedHabit: Bool {
        !habit.isArchived && !habit.supportsIncrementalGoal &&
        !habit.usesFlexibleWeeklyTarget && !habit.usesCompletionInterval
    }

    private var target: Double? {
        guard let value = Double(targetText.replacingOccurrences(of: ",", with: ".")),
              value.isFinite, value > 0, value <= 100_000 else { return nil }
        return value
    }

    var body: some View {
        Form {
            Section {
                Label(L10n.string("health.title"), systemImage: "heart.text.square")
                    .font(.headline)
                Text(L10n.string("health.description"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if !supportedHabit {
                    Text(L10n.string("health.unsupported"))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.orange)
                }
            }

            Section(L10n.string("health.rule.section")) {
                Picker(L10n.string("health.metric.title"), selection: $metric) {
                    ForEach(HealthHabitMetric.allCases) { value in
                        Text(L10n.string(value.titleKey)).tag(value)
                    }
                }
                .onChange(of: metric) { _, value in
                    targetText = String(format: "%.0f", value.defaultTarget)
                }

                HStack {
                    Text(L10n.string("health.target"))
                    Spacer()
                    TextField(L10n.string("health.target"), text: $targetText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .accessibilityIdentifier("health.target")
                    Text(L10n.string(metric.unitKey))
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    Task { await enable() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving { ProgressView() }
                        Text(L10n.string(isEnabled ? "health.save" : "health.connect"))
                        Spacer()
                    }
                }
                .disabled(target == nil || isSaving || !supportedHabit ||
                          !HealthHabitCoordinator.shared.isAvailable)

                if isEnabled {
                    Button(role: .destructive) {
                        HealthHabitRuleStore.shared.disable(for: habit.id)
                        HealthHabitCoordinator.shared.reconfigureObservers()
                        isEnabled = false
                        dismiss()
                    } label: {
                        Text(L10n.string("health.disconnect"))
                    }
                    .disabled(isSaving)
                }
            } footer: {
                Text(L10n.string("health.privacy"))
            }

            if let errorText {
                Section {
                    Text(errorText).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(L10n.string("health.settings"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let existing = HealthHabitRuleStore.shared.rule(for: habit.id) {
                metric = existing.metric
                targetText = existing.target.formatted()
                isEnabled = true
            }
        }
    }

    @MainActor
    private func enable() async {
        guard let target, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await HealthHabitCoordinator.shared.authorize(metric)
            let rule = HealthHabitRule(metric: metric, target: target, enabledAt: .now)
            HealthHabitRuleStore.shared.save(rule, for: habit.id)
            HealthHabitCoordinator.shared.reconfigureObservers()
            await HealthHabitCoordinator.shared.synchronize()
            isEnabled = true
            errorText = nil
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
