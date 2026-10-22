import SwiftUI

/// Local preference; never rewrites historical check-ins or schedules.
struct GentleRestartSettingsView: View {
    @AppStorage("chickmark.gentleRestart.enabled") private var enabled = false
    @AppStorage("chickmark.gentleRestart.quietDays") private var quietDays = 7
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Form {
            Section {
                Text(L10n.string("restart.settings.title"))
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                if dynamicTypeSize.isAccessibilitySize {
                    // The full section heading above identifies this
                    // preference visually. An icon and a fully labeled switch
                    // avoid a duplicate clipped Text row at AXXXL.
                    HStack(spacing: ArvectumDesignMetrics.spaceM) {
                        Image(systemName: "arrow.uturn.forward.circle")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Spacer()
                        Toggle(isOn: $enabled) { EmptyView() }
                            .labelsHidden()
                            .accessibilityLabel(L10n.string("restart.settings.enable"))
                            .accessibilityIdentifier("restart-enabled")
                    }
                    .frame(minHeight: ArvectumDesignMetrics.accessibilityActionSize)
                } else {
                    Toggle(L10n.string("restart.settings.enable"), isOn: $enabled)
                        .accessibilityIdentifier("restart-enabled")
                }

                if enabled {
                    if dynamicTypeSize.isAccessibilitySize {
                        HStack(spacing: ArvectumDesignMetrics.spaceM) {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                            Spacer(minLength: ArvectumDesignMetrics.spaceS)
                            thresholdPicker.labelsHidden()
                                .accessibilityLabel(L10n.string("restart.settings.threshold"))
                        }
                        .frame(minHeight: ArvectumDesignMetrics.accessibilityActionSize)
                    } else {
                        thresholdPicker
                    }
                } else {
                    // iOS 27's disabled Picker misses the NotEnabled AX trait.
                    // Show an informational, non-actionable row instead.
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.string("restart.settings.threshold"))
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityHint(L10n.string("restart.settings.disabledHint"))
                        Text(L10n.format("restart.days", quietDays))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(L10n.string("restart.settings.explanation"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .navigationTitle(dynamicTypeSize.isAccessibilitySize
            ? L10n.string("restart.settings.shortTitle")
            : L10n.string("restart.settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("gentle-restart-settings")
    }

    private var thresholdPicker: some View {
        Picker(L10n.string("restart.settings.threshold"), selection: $quietDays) {
            ForEach(GentleRestart.minimumOptions, id: \.self) { days in
                Text(L10n.format("restart.days", days)).tag(days)
            }
        }
        .accessibilityIdentifier("restart-threshold")
    }
}
