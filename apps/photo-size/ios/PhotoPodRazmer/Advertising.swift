import SwiftUI
import UIKit
@preconcurrency import YandexMobileAds

enum AdVariant: String {
    case native
    case banner
}

enum AdExperiment {
    static func current() -> AdVariant {
#if DEBUG
        if let raw = ProcessInfo.processInfo.environment["ARVECTUM_AD_VARIANT"],
           let forced = AdVariant(rawValue: raw) {
            return forced
        }
#endif
        // Simplicity gate: keep production monetization compact and predictable.
        // The taller native layout stays available in DEBUG for later experiments.
        return .banner
    }
}

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
enum AdSDK {
    static func configure() {
        // Keep the first monetized release privacy-conservative:
        // no precise location, no ATT/IDFA request, no assumed GDPR consent.
        YandexAds.setLocationTracking(false)
        YandexAds.setUserConsent(false)
#if DEBUG
        YandexAds.enableLogging()
#endif
        Task {
            await YandexAds.initializeSDK()
        }
    }
}

struct ResultScreenAdSlot: View {
    @State private var variant = AdExperiment.current()

    var body: some View {
        Group {
            switch variant {
            case .native:
                NativeAdSlot()
            case .banner:
                AdaptiveInlineBannerSlot()
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("result-ad-slot-\(variant.rawValue)")
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

private struct NativeAdSlot: View {
    @State private var loaded = false

    var body: some View {
        NativeAdRepresentable(isLoaded: $loaded)
            .frame(height: loaded ? nil : 1)
            .clipped()
            .animation(.easeInOut(duration: 0.2), value: loaded)
    }
}

private struct NativeAdRepresentable: UIViewRepresentable {
    @Binding var isLoaded: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoaded: $isLoaded)
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
        private let loader = NativeAdLoader()
        private var ad: NativeAd?
        private weak var adView: ArvectumNativeAdView?
        private var isLoaded: Binding<Bool>

        init(isLoaded: Binding<Bool>) {
            self.isLoaded = isLoaded
        }

        func attach(to view: ArvectumNativeAdView) {
            adView = view
            let request = AdRequest(adUnitID: AdUnitIDs.native)
            let options = NativeAdOptions()

            loader.loadAd(with: request, options: options) { [weak self] result in
                guard let self, let adView = self.adView else { return }

                switch result {
                case .success(let ad):
                    self.ad = ad
                    ad.delegate = self
                    do {
                        try ad.bind(with: adView)
                        self.isLoaded.wrappedValue = true
                    } catch {
                        self.isLoaded.wrappedValue = false
                    }
                case .failure:
                    self.isLoaded.wrappedValue = false
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
    private let body = UILabel()
    private let favicon = UIImageView()
    private let reviewCount = UILabel()

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

        [title, domain, warning, sponsored, age, price, body, reviewCount].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = UIColor(red: 4/255, green: 26/255, blue: 51/255, alpha: 1)
        }

        title.font = .boldSystemFont(ofSize: 16)
        title.numberOfLines = 2
        body.font = .systemFont(ofSize: 13)
        body.numberOfLines = 2
        domain.font = .systemFont(ofSize: 11)
        sponsored.font = .systemFont(ofSize: 11, weight: .semibold)
        age.font = .systemFont(ofSize: 11)
        price.font = .systemFont(ofSize: 12, weight: .semibold)
        reviewCount.font = .systemFont(ofSize: 11)
        warning.font = .systemFont(ofSize: 10)
        warning.numberOfLines = 0

        media.translatesAutoresizingMaskIntoConstraints = false
        media.layer.cornerRadius = 12
        media.clipsToBounds = true

        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        icon.layer.cornerRadius = 10
        icon.clipsToBounds = true

        favicon.translatesAutoresizingMaskIntoConstraints = false
        favicon.contentMode = .scaleAspectFit

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
        adMeta.axis = .horizontal
        adMeta.spacing = 6

        let titleStack = UIStackView(arrangedSubviews: [title, domain, body])
        titleStack.axis = .vertical
        titleStack.spacing = 2

        let header = UIStackView(arrangedSubviews: [icon, titleStack, feedback])
        header.axis = .horizontal
        header.alignment = .top
        header.spacing = 8

        let lower = UIStackView(arrangedSubviews: [price, reviewCount, callToAction])
        lower.axis = .horizontal
        lower.alignment = .center
        lower.spacing = 8

        let stack = UIStackView(arrangedSubviews: [
            adMeta, header, media, lower, warning
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 7
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),

            icon.widthAnchor.constraint(equalToConstant: 44),
            icon.heightAnchor.constraint(equalToConstant: 44),
            feedback.widthAnchor.constraint(equalToConstant: 28),
            feedback.heightAnchor.constraint(equalToConstant: 28),
            callToAction.heightAnchor.constraint(greaterThanOrEqualToConstant: 38),

            media.heightAnchor.constraint(greaterThanOrEqualToConstant: 160),
            media.heightAnchor.constraint(equalTo: media.widthAnchor, multiplier: 9/16),

            warning.heightAnchor.constraint(greaterThanOrEqualToConstant: 30)
        ])
    }

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
        faviconImageView = favicon
        reviewCountLabel = reviewCount
        bodyLabel = body
    }
}
