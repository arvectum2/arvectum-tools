import AppTrackingTransparency
import SwiftUI
import UIKit
@preconcurrency import YandexMobileAds

enum AdUnitIDs {
#if DEBUG
    static let native = "demo-native-app-yandex"
    static let banner = "demo-banner-yandex"
#else
    static let native = "R-M-20141949-1"
    static let banner = "R-M-20141949-2"
#endif
}


@MainActor
final class NativeAdSession: ObservableObject {
    private let loader = NativeAdLoader()
    private var cachedAd: NativeAd?
    private var isLoading = false
    private var waiters: [(Result<NativeAd, Error>) -> Void] = []

    func prefetch() {
        load { _ in }
    }

    func load(_ completion: @escaping (Result<NativeAd, Error>) -> Void) {
        if let cachedAd {
            completion(.success(cachedAd))
            return
        }

        waiters.append(completion)
        guard !isLoading else { return }
        isLoading = true

        let request = AdRequest(adUnitID: AdUnitIDs.native)
        let options = NativeAdOptions()
        loader.loadAd(with: request, options: options) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            if case .success(let ad) = result {
                self.cachedAd = ad
            }
            let callbacks = self.waiters
            self.waiters.removeAll()
            callbacks.forEach { $0(result) }
        }
    }
}

enum AdConsentStore {
    private static let key = "arvectum.ads.user-consent"
    static let privacyPolicyURL = URL(string: "https://arvectum.com/photo-pod-razmer-privacy.html")!

    static var storedConsent: Bool? {
        guard UserDefaults.standard.object(forKey: key) != nil else { return nil }
        return UserDefaults.standard.bool(forKey: key)
    }

    static func save(_ consent: Bool) {
        UserDefaults.standard.set(consent, forKey: key)
    }
}

@MainActor
enum AdSDK {
    static func configure() {
        // Privacy-conservative defaults:
        // - no precise location;
        // - no positive GDPR consent until the user explicitly grants it;
        // - ATT is requested only after positive advertising-data consent.
        YandexAds.setLocationTracking(false)
        YandexAds.setUserConsent(AdConsentStore.storedConsent ?? false)
#if DEBUG
        YandexAds.enableLogging()
#endif
        Task {
            await YandexAds.initializeSDK()
        }
    }

    static func setUserConsent(_ consent: Bool) {
        AdConsentStore.save(consent)
        YandexAds.setUserConsent(consent)

        if consent {
            requestTrackingAuthorizationIfNeeded()
        }
    }

    private static func requestTrackingAuthorizationIfNeeded() {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }

        // Let the SwiftUI consent sheet finish dismissing before the system ATT prompt.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}

struct MainScreenNativeAdSlot: View {
    @ObservedObject var session: NativeAdSession

    var body: some View {
        NativeAdSlot(session: session)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("main-native-ad-slot")
    }
}

struct ResultScreenAdSlot: View {
    var body: some View {
        AdaptiveInlineBannerSlot()
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("result-ad-slot-banner")
    }
}

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

private struct AdaptiveInlineBannerSlot: View {
    @State private var loaded = false

    var body: some View {
        GeometryReader { proxy in
            AdaptiveInlineBannerRepresentable(
                availableWidth: proxy.size.width,
                isLoaded: $loaded
            )
        }
        .frame(height: loaded ? 180 : 1)
        .clipped()
        .animation(.easeInOut(duration: 0.2), value: loaded)
    }
}

private struct AdaptiveInlineBannerRepresentable: UIViewRepresentable {
    let availableWidth: CGFloat
    @Binding var isLoaded: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoaded: $isLoaded)
    }

    func makeUIView(context: Context) -> BannerAdView {
        let width = max(300, availableWidth)
        let size = BannerAdSize.inline(width: width, maxHeight: 180)
        let view = BannerAdView(adSize: size)
        view.delegate = context.coordinator
        view.translatesAutoresizingMaskIntoConstraints = false
        view.loadAd(with: AdRequest(adUnitID: AdUnitIDs.banner))
        return view
    }

    func updateUIView(_ uiView: BannerAdView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, BannerAdViewDelegate {
        private var isLoaded: Binding<Bool>

        init(isLoaded: Binding<Bool>) {
            self.isLoaded = isLoaded
        }

        func bannerAdViewDidLoad(_ bannerAdView: BannerAdView) {
            isLoaded.wrappedValue = true
        }

        func bannerAdViewDidFailLoading(_ bannerAdView: BannerAdView, error: Error) {
            isLoaded.wrappedValue = false
        }

        func bannerAdViewDidClick(_ bannerAdView: BannerAdView) {}

        func bannerAdView(
            _ bannerAdView: BannerAdView,
            didTrackImpression impressionData: ImpressionData?
        ) {}
    }
}

private enum NativeAdPhase {
    case loading
    case loaded
    case failed
}

private struct NativeAdSlot: View {
    @ObservedObject var session: NativeAdSession
    @State private var phase: NativeAdPhase = .loading

    @ViewBuilder
    var body: some View {
        if phase == .failed {
            Color.clear
                .frame(height: 1)
        } else {
            NativeAdRepresentable(session: session, phase: $phase)
                .frame(minHeight: 260)
                .clipped()
                .animation(.easeInOut(duration: 0.16), value: phase == .loaded)
        }
    }
}

private struct NativeAdRepresentable: UIViewRepresentable {
    @ObservedObject var session: NativeAdSession
    @Binding var phase: NativeAdPhase

    func makeCoordinator() -> Coordinator {
        Coordinator(session: session, phase: $phase)
    }

    func makeUIView(context: Context) -> ArvectumNativeAdView {
        let view = ArvectumNativeAdView()
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: ArvectumNativeAdView, context: Context) {}

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: ArvectumNativeAdView,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width, width > 0 else { return nil }
        uiView.bounds.size.width = width
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()
        let target = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let measured = uiView.systemLayoutSizeFitting(
            target,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return CGSize(width: width, height: max(1, ceil(measured.height)))
    }

    @MainActor
    final class Coordinator: NSObject, NativeAdDelegate {
        private let session: NativeAdSession
        private var ad: NativeAd?
        private weak var adView: ArvectumNativeAdView?
        private var phase: Binding<NativeAdPhase>

        init(session: NativeAdSession, phase: Binding<NativeAdPhase>) {
            self.session = session
            self.phase = phase
        }

        func attach(to view: ArvectumNativeAdView) {
            adView = view

#if DEBUG
            if ProcessInfo.processInfo.environment["ARVECTUM_NATIVE_QA_FIXTURE"] == "long" {
                view.applyLongCopyQAFixture()
                DispatchQueue.main.async {
                    self.phase.wrappedValue = .loaded
                }
                return
            }
#endif

            session.load { [weak self] result in
                guard let self, let adView = self.adView else { return }
                switch result {
                case .success(let ad):
                    self.ad = ad
                    ad.delegate = self
                    do {
                        try ad.bind(with: adView)
                        self.phase.wrappedValue = .loaded
                    } catch {
                        self.phase.wrappedValue = .failed
                    }
                case .failure:
                    self.phase.wrappedValue = .failed
                }
            }
        }

        func nativeAdDidClick(_ ad: NativeAd) {}

        func nativeAd(
            _ ad: NativeAd,
            didTrackImpression impressionData: ImpressionData?
        ) {}
    }
}

@MainActor
private final class ArvectumNativeAdView: YandexMobileAds.NativeAdView {
    private let title = UILabel()
    private let domain = UILabel()
    private let warning = UILabel()
    private let sponsored = UILabel()
    private let age = UILabel()
    private let feedback = UIButton(type: .system)
    private let callToAction = UIButton(type: .system)
    private let media = YandexMobileAds.NativeMediaView()
    private let icon = UIImageView()
    private let price = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        configureLayout()
        bindAssets()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        backgroundColor = .white
        layer.cornerRadius = 18
        layer.masksToBounds = true

        [title, domain, warning, sponsored, age, price].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = UIColor(red: 4/255, green: 26/255, blue: 51/255, alpha: 1)
        }

        title.font = .boldSystemFont(ofSize: 16)
        title.numberOfLines = 2
        domain.font = .systemFont(ofSize: 11)
        sponsored.font = .systemFont(ofSize: 11, weight: .semibold)
        age.font = .systemFont(ofSize: 11)
        price.font = .systemFont(ofSize: 12, weight: .semibold)
        warning.font = .systemFont(ofSize: 10)
        warning.numberOfLines = 0

        media.translatesAutoresizingMaskIntoConstraints = false
        media.layer.cornerRadius = 12
        media.clipsToBounds = true

        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        icon.layer.cornerRadius = 10
        icon.clipsToBounds = true

        feedback.translatesAutoresizingMaskIntoConstraints = false

        callToAction.translatesAutoresizingMaskIntoConstraints = false
        callToAction.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        callToAction.setTitleColor(
            UIColor(red: 4/255, green: 26/255, blue: 51/255, alpha: 1),
            for: .normal
        )
        callToAction.backgroundColor = UIColor(
            red: 67/255, green: 229/255, blue: 197/255, alpha: 1
        )
        callToAction.layer.cornerRadius = 10
    }

    private func configureLayout() {
        let adMeta = UIStackView(arrangedSubviews: [sponsored, age])
        adMeta.translatesAutoresizingMaskIntoConstraints = false
        adMeta.axis = .horizontal
        adMeta.spacing = 5
        adMeta.alignment = .center
        adMeta.backgroundColor = UIColor.white.withAlphaComponent(0.90)
        adMeta.layer.cornerRadius = 6
        adMeta.isLayoutMarginsRelativeArrangement = true
        adMeta.layoutMargins = UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)

        let titleStack = UIStackView(arrangedSubviews: [title, domain, price])
        titleStack.axis = .vertical
        titleStack.spacing = 1

        let infoRow = UIStackView(arrangedSubviews: [icon, titleStack, callToAction])
        infoRow.axis = .horizontal
        infoRow.alignment = .center
        infoRow.spacing = 7

        let mediaContainer = UIView()
        mediaContainer.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addSubview(media)
        mediaContainer.addSubview(adMeta)
        mediaContainer.addSubview(feedback)

        let stack = UIStackView(arrangedSubviews: [
            mediaContainer, infoRow, warning
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            mediaContainer.heightAnchor.constraint(equalToConstant: 160),
            media.topAnchor.constraint(equalTo: mediaContainer.topAnchor),
            media.leadingAnchor.constraint(equalTo: mediaContainer.leadingAnchor),
            media.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor),
            media.bottomAnchor.constraint(equalTo: mediaContainer.bottomAnchor),

            adMeta.topAnchor.constraint(equalTo: mediaContainer.topAnchor, constant: 6),
            adMeta.leadingAnchor.constraint(equalTo: mediaContainer.leadingAnchor, constant: 6),

            feedback.topAnchor.constraint(equalTo: mediaContainer.topAnchor, constant: 6),
            feedback.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor, constant: -6),
            feedback.widthAnchor.constraint(equalToConstant: 28),
            feedback.heightAnchor.constraint(equalToConstant: 28),

            icon.widthAnchor.constraint(equalToConstant: 40),
            icon.heightAnchor.constraint(equalToConstant: 40),
            callToAction.widthAnchor.constraint(greaterThanOrEqualToConstant: 88),
            callToAction.heightAnchor.constraint(equalToConstant: 34),

            warning.heightAnchor.constraint(greaterThanOrEqualToConstant: 24)
        ])
    }

#if DEBUG
    func applyLongCopyQAFixture() {
        title.text = "Очень длинный рекламный заголовок для проверки компактной вёрстки"
        domain.text = "example-advertiser-long-domain.example"
        sponsored.text = "Реклама"
        age.text = "18+"
        price.text = "от 12 999 ₽"
        warning.text = "Рекламодатель: ООО «Очень длинное название компании». ОГРН 1234567890123"
        callToAction.setTitle("Подробнее", for: .normal)
        icon.backgroundColor = UIColor.systemGray5
        media.backgroundColor = UIColor.systemGray4
    }
#endif

    private func bindAssets() {
        titleLabel = title
        domainLabel = domain
        warningLabel = warning
        sponsoredLabel = sponsored
        ageLabel = age
        feedbackButton = feedback
        callToActionButton = callToAction
        mediaView = media
        iconImageView = icon
        priceLabel = price
    }
}
