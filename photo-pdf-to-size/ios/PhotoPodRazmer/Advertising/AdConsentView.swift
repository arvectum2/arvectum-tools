import SwiftUI

/// Read-only advertising disclosure. No user tracking or consent prompts.
struct AdConsentSheet: View {
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label(tr("Реклама в приложении"), systemImage: "hand.raised")
                .font(.title2.weight(.semibold))
            Text(tr("Фото и PDF обрабатываются только на iPhone и не передаются рекламной сети. Приложение не запрашивает геолокацию или разрешение ATT. Рекламный SDK может собирать технические данные, включая идентификаторы устройства."))
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            Link(destination: AdPrivacyPolicy.url) {
                Label(tr("Политика конфиденциальности"), systemImage: "safari")
            }
            Spacer(minLength: 0)
            Button(tr("Закрыть")) { onClose() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, minHeight: 48)
                .accessibilityIdentifier("ad-privacy-close")
        }
        .padding(22)
        .background(Color.arvectumBackground)
    }
}
