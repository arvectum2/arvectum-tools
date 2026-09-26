import SwiftUI
import UIKit

struct PassportCropView: View {
    let image: UIImage
    let onCancel: () -> Void
    let onConfirm: (NormalizedCropRect) -> Void

    @State private var zoom: CGFloat = 1
    @State private var committedZoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var committedOffset: CGSize = .zero
    @State private var viewport: CGSize = .zero

    var body: some View {
        ZStack {
            Color.arvectumBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("НА ПАСПОРТ")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.arvectumNavy.opacity(0.72))
                        Text("Подогнать фото под 35×45")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.arvectumNavy)
                    }
                    Spacer()
                    Button("Отмена", action: onCancel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.arvectumNavy)
                }

                Text("Перемещайте фото и масштабируйте двумя пальцами.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                GeometryReader { proxy in
                    cropViewport(size: proxy.size)
                        .onAppear { viewport = proxy.size }
                        .onChange(of: proxy.size) { _, value in
                            viewport = value
                            offset = clamped(offset, viewport: value, zoom: zoom)
                            committedOffset = offset
                        }
                }
                .aspectRatio(
                    CGFloat(ImageEngine.passportWidth) / CGFloat(ImageEngine.passportHeight),
                    contentMode: .fit
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.arvectumMint, lineWidth: 2)
                )

                Text("620×797 px · 450 DPI · JPEG")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button {
                    guard viewport.width > 0, viewport.height > 0 else { return }
                    onConfirm(normalizedCrop())
                } label: {
                    Text("Подготовить фото")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.arvectumNavy)
                .background(Color.arvectumMint, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(14)
        }
    }

    private func cropViewport(size: CGSize) -> some View {
        let baseScale = max(
            size.width / max(image.size.width, 1),
            size.height / max(image.size.height, 1)
        )
        let totalScale = baseScale * zoom
        let displaySize = CGSize(
            width: image.size.width * totalScale,
            height: image.size.height * totalScale
        )

        return ZStack {
            Color.black.opacity(0.92)
            Image(uiImage: image)
                .resizable()
                .frame(width: displaySize.width, height: displaySize.height)
                .offset(offset)
        }
        .clipped()
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    let proposed = CGSize(
                        width: committedOffset.width + value.translation.width,
                        height: committedOffset.height + value.translation.height
                    )
                    offset = clamped(proposed, viewport: size, zoom: zoom)
                }
                .onEnded { _ in
                    offset = clamped(offset, viewport: size, zoom: zoom)
                    committedOffset = offset
                }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    zoom = min(5, max(1, committedZoom * value))
                    offset = clamped(offset, viewport: size, zoom: zoom)
                }
                .onEnded { _ in
                    zoom = min(5, max(1, zoom))
                    committedZoom = zoom
                    offset = clamped(offset, viewport: size, zoom: zoom)
                    committedOffset = offset
                }
        )
    }

    private func clamped(
        _ proposed: CGSize,
        viewport: CGSize,
        zoom: CGFloat
    ) -> CGSize {
        guard viewport.width > 0, viewport.height > 0 else { return .zero }
        let baseScale = max(
            viewport.width / max(image.size.width, 1),
            viewport.height / max(image.size.height, 1)
        )
        let displayWidth = image.size.width * baseScale * zoom
        let displayHeight = image.size.height * baseScale * zoom
        let maxX = max(0, (displayWidth - viewport.width) / 2)
        let maxY = max(0, (displayHeight - viewport.height) / 2)

        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }

    private func normalizedCrop() -> NormalizedCropRect {
        let baseScale = max(
            viewport.width / max(image.size.width, 1),
            viewport.height / max(image.size.height, 1)
        )
        let totalScale = baseScale * max(zoom, 1)
        let displayWidth = image.size.width * totalScale
        let displayHeight = image.size.height * totalScale
        let leftOnScreen = (viewport.width - displayWidth) / 2 + offset.width
        let topOnScreen = (viewport.height - displayHeight) / 2 + offset.height

        let sourceLeft = min(max(-leftOnScreen / totalScale, 0), image.size.width)
        let sourceTop = min(max(-topOnScreen / totalScale, 0), image.size.height)
        let sourceRight = min(
            max((viewport.width - leftOnScreen) / totalScale, 0),
            image.size.width
        )
        let sourceBottom = min(
            max((viewport.height - topOnScreen) / totalScale, 0),
            image.size.height
        )

        return NormalizedCropRect(
            left: sourceLeft / image.size.width,
            top: sourceTop / image.size.height,
            right: sourceRight / image.size.width,
            bottom: sourceBottom / image.size.height
        )
    }
}
