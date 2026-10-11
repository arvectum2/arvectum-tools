import AppTrackingTransparency
import SwiftUI
import UIKit
@preconcurrency import YandexMobileAds

struct AdConsentSheet: View {
    let onDecision: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.badge.person.crop")
                    .font(.title2)
                    .foregroundStyle(Color.arvectumMint)

                Text(tr("Реклама в приложении"))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.arvectumPrimaryText)
            }

            Text(tr("«Фото и PDF под размер» бесплатно и поддерживается рекламой. Реклама будет показываться независимо от вашего выбора. Вы можете разрешить или не разрешить Yandex Mobile Ads обработку данных для рекламы. Если разрешите, iOS может отдельно спросить разрешение на отслеживание. При отказе реклама останется, но без доступа к рекламному идентификатору. Фото и PDF обрабатываются только на устройстве, геолокация отключена."))
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Link(destination: AdConsentStore.privacyPolicyURL) {
                Label(tr("Политика конфиденциальности"), systemImage: "safari")
                    .font(.subheadline.weight(.semibold))
            }

            Spacer(minLength: 0)

            Button {
                onDecision(true)
            } label: {
                Text(tr("Разрешить обработку данных"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.arvectumPrimaryText)
            .background(Color.arvectumMint, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityIdentifier("ad-consent-accept")

            Button {
                onDecision(false)
            } label: {
                Text(tr("Не разрешать обработку данных"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.arvectumPrimaryText)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.arvectumStrongBorder, lineWidth: 1)
            )
            .accessibilityIdentifier("ad-consent-decline")
        }
        .padding(20)
        .background(Color.arvectumBackground)
    }
}
