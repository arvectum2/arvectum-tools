import AppTrackingTransparency
import SwiftUI
import UIKit
@preconcurrency import YandexMobileAds

private enum NativeAdPhase {
    case loading
    case loaded
    case failed
}

struct NativeAdSlot: View {
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
                // A cached ad can complete synchronously from makeUIView.
                // Defer all SwiftUI Binding changes until after the view update.
                DispatchQueue.main.async { [weak self] in
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
