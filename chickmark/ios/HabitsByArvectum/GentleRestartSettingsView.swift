import SwiftUI

/// Device-local preference: no migration, network sync, or modification of
/// check-ins. The user can return to the original schedule at any time.
struct GentleRestartSettingsView: View {
    @AppStorage("chickmark.gentleRestart.enabled")
    private var enabled = false

    @AppStorage("chickmark.gentleRestart.quietDays")
    private var quietDays = 7

    var body: some View {
        Form {
            Section {
                Toggle(L10n.string("restart.settings.enable"), isOn: $enabled)
                    .accessibilityIdentifier("restart-enabled")
                Picker(
                    L10n.string("restart.settings.threshold"),
                    selection: $quietDays
                ) {
                    ForEach(GentleRestart.minimumOptions, id: \.self) { days in
                        Text(L10n.format("restart.days", days)).tag(days)
                    }
                }
                .disabled(!enabled)
                .accessibilityIdentifier("restart-threshold")
            } header: {
                Text(L10n.string("restart.settings.title"))
            } footer: {
                Text(L10n.string("restart.settings.explanation"))
            }
        }
        .navigationTitle(L10n.string("restart.settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("gentle-restart-settings")
    }
}
