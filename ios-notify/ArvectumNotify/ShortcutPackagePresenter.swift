import SwiftUI
import UIKit

struct ShortcutPackagePresenter: UIViewControllerRepresentable {
    @Binding var packageURL: URL?
    let onSentToApplication: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            packageURL: $packageURL,
            onSentToApplication: onSentToApplication
        )
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(
        _ uiViewController: UIViewController,
        context: Context
    ) {
        guard let packageURL else { return }
        guard context.coordinator.presentedURL != packageURL else {
            return
        }

        context.coordinator.presentedURL = packageURL

        DispatchQueue.main.async {
            UIApplication.shared.open(packageURL, options: [:]) { opened in
                if opened {
                    context.coordinator.onDirectOpenSucceeded()
                    return
                }

                let interaction = UIDocumentInteractionController(
                    url: packageURL
                )
                interaction.uti = "com.apple.shortcut"
                interaction.delegate = context.coordinator
                context.coordinator.interaction = interaction

                let presented = interaction.presentOpenInMenu(
                    from: uiViewController.view.bounds,
                    in: uiViewController.view,
                    animated: true
                )

                if !presented {
                    context.coordinator.finish(resetOnly: true)
                }
            }
        }
    }

    final class Coordinator: NSObject,
        UIDocumentInteractionControllerDelegate {
        @Binding private var packageURL: URL?
        private let onSentToApplication: () -> Void

        var interaction: UIDocumentInteractionController?
        var presentedURL: URL?

        init(
            packageURL: Binding<URL?>,
            onSentToApplication: @escaping () -> Void
        ) {
            _packageURL = packageURL
            self.onSentToApplication = onSentToApplication
        }

        func documentInteractionController(
            _ controller: UIDocumentInteractionController,
            willBeginSendingToApplication application: String?
        ) {
            onSentToApplication()
        }

        func documentInteractionControllerDidDismissOpenInMenu(
            _ controller: UIDocumentInteractionController
        ) {
            finish(resetOnly: true)
        }

        func onDirectOpenSucceeded() {
            onSentToApplication()
            finish(resetOnly: true)
        }

        func finish(resetOnly: Bool) {
            interaction = nil
            presentedURL = nil
            packageURL = nil
        }
    }
}
