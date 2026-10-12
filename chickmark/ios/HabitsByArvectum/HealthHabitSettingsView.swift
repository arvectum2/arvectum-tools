import SwiftUI

struct HealthHabitSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let habit: Habit

    @State private var metric: HealthHabitMetric = .steps
    @State private var targetText = "5000"
    @State private var isEnabled = false
    @State private var isSaving = false
    @State private var errorText: String?
    @FocusState private var targetFocused: Bool

    private var supportedHabit: Bool {
        !habit.isArchived && !habit.supportsIncrementalGoal &&
        (!habit.usesFlexibleWeeklyTarget || metric.supportsWeeklyGoal) &&
        !habit.usesCompletionInterval
    }

    private var target: Double? {
        guard let value = Double(targetText.replacingOccurrences(of: ",", with: ".")),
              value.isFinite, value > 0, value <= 100_000 else { return nil }
        return value
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView {
                    settingsContent
                }
            } else {
                settingsContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .background(Color.habitsBackground)
        .navigationTitle(L10n.string("health.settings"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.string("common.done")) {
                    targetFocused = false
                }
            }
        }
        .task {
            if let existing = HealthHabitRuleStore.shared.rule(for: habit.id) {
                metric = existing.metric
                targetText = existing.target.formatted()
                isEnabled = true
            }
        }
    }

    /// A single-screen configuration surface: only selection, threshold and
    /// primary actions. Longer privacy/Shortcuts guidance stays in app help.
    private var settingsContent: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "heart.text.square.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                Text(habit.name)
                    .font(.headline)
                    .lineLimit(2)
                Spacer(minLength: 0)
                if isEnabled {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .accessibilityLabel(L10n.string("health.connected.hint"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text(L10n.string("health.metric.title"))
                        .font(.subheadline.weight(.medium))
                    Spacer(minLength: 8)
                    Picker(L10n.string("health.metric.title"), selection: $metric) {
                        ForEach(HealthHabitMetric.allCases) { value in
                            Text(L10n.string(value.titleKey)).tag(value)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .onChange(of: metric) { _, value in
                        targetText = String(format: "%.0f", value.defaultTarget)
                    }
                    .accessibilityIdentifier("health.metric")
                }
                .frame(minHeight: 48)

                Divider()

                HStack(spacing: 10) {
                    Text(L10n.string("health.target"))
                        .font(.subheadline.weight(.medium))
                    Spacer(minLength: 8)
                    TextField(L10n.string("health.target"), text: $targetText)
                        .keyboardType(.decimalPad)
                        .focused($targetFocused)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 85)
                        .accessibilityIdentifier("health.target")
                    Text(L10n.string(metric.unitKey))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: 48)
            }
            .padding(.horizontal, 14)
            .background(
                Color.habitsSurface,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )

            if !supportedHabit {
                Label(L10n.string("health.unsupported"), systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                targetFocused = false
                Task { await enable() }
            } label: {
                HStack(spacing: 10) {
                    if isSaving { ProgressView().tint(.white) }
                    Text(L10n.string(isEnabled ? "health.save" : "health.connect"))
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .disabled(target == nil || isSaving || !supportedHabit ||
                      !HealthHabitCoordinator.shared.isAvailable)
            .accessibilityIdentifier("health.connect.action")

            if isEnabled {
                Button(role: .destructive) {
                    HealthHabitRuleStore.shared.disable(for: habit.id)
                    HealthHabitCoordinator.shared.reconfigureObservers()
                    HealthHabitCoordinator.shared.refresh()
                    PhoneWatchSyncCoordinator.shared.dataDidChange()
                    isEnabled = false
                    dismiss()
                } label: {
                    Text(L10n.string("health.disconnect"))
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .disabled(isSaving)
            }

            if let errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
    }

    @MainActor
    private func enable() async {
        guard let target, supportedHabit, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await HealthHabitCoordinator.shared.authorize(metric)
            let rule = HealthHabitRule(metric: metric, target: target, enabledAt: .now)
            HealthHabitRuleStore.shared.save(rule, for: habit.id)
            HealthHabitCoordinator.shared.reconfigureObservers()
            PhoneWatchSyncCoordinator.shared.dataDidChange()
            await HealthHabitCoordinator.shared.synchronize()
            isEnabled = true
            errorText = nil
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
