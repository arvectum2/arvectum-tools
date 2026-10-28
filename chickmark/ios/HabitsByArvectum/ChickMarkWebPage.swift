import SafariServices
import SwiftUI

/// Only known Arvectum HTTPS pages use the in-app browser. App-to-app deep
/// links, iOS Settings, email and untrusted URLs keep their own system flow.
struct ChickMarkWebPage: Identifiable, Equatable {
    let url: URL
    var id: String { url.absoluteString }

    init?(url: URL) {
        guard url.scheme?.lowercased() == "https",
              url.host?.lowercased() == "arvectum.com",
              url.user == nil, url.password == nil else { return nil }
        self.url = url
    }
}

/// A visible ChickMark-owned dismiss control remains available even when
/// SafariViewService hosts its own browser controls in a separate process.
struct ChickMarkWebSheet: View {
    let page: ChickMarkWebPage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "lock.shield")
                    .accessibilityHidden(true)
                Text("arvectum.com")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button(L10n.string("common.done")) { dismiss() }
                    .font(.subheadline.weight(.semibold))
                    .frame(minWidth: 60, minHeight: 44)
                    .accessibilityIdentifier("chickmark.web.close")
            }
            .padding(.horizontal, 16)
            .background(Color.habitsSurface)
            Divider()
            ChickMarkSafariController(url: page.url)
        }
    }
}

private struct ChickMarkSafariController: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
