import SwiftUI

struct StorageRecoveryView: View {
    var body: some View {
        ContentUnavailableView {
            Label(
                L10n.string("storage.error.title"),
                systemImage: "externaldrive.badge.exclamationmark"
            )
        } description: {
            Text(L10n.string("storage.error.message"))
        }
        .padding()
        .accessibilityIdentifier("storage-recovery-view")
    }
}
