import ArvectumCore
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// A result's status and settings are navigation controls, not the content.
/// At accessibility sizes they stack and cap their typography to avoid
/// truncated fixed-height pills. The rest of the result stays scrollable.
private struct ResultTopBar: View {
    let onBack: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) { controls }
            } else {
                HStack(spacing: 8) { controls }
            }
        }
        .dynamicTypeSize(dynamicTypeSize.isAccessibilitySize ? .accessibility1 : dynamicTypeSize)
    }

    @ViewBuilder
    private var controls: some View {
        Text(tr("ГОТОВО"))
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.arvectumAccentText)

        if !dynamicTypeSize.isAccessibilitySize {
            Spacer(minLength: 8)
        }

        Button(action: onBack) {
            Label(tr("Изменить настройки"), systemImage: "slider.horizontal.3")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, 10)
                .frame(minHeight: 40)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.arvectumPrimaryText)
        .background(Color.arvectumBackground, in: Capsule())
        .overlay(Capsule().stroke(Color.arvectumStrongBorder, lineWidth: 1))
        .accessibilityIdentifier("edit-settings-button")
    }
}

struct BeforeAfterPreview: View {
    let result: ResultImage
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var outputImage: UIImage {
        UIImage(contentsOfFile: result.outputURL.path) ?? result.source.image
    }

    var body: some View {
        HStack(spacing: 10) {
            preview(
                title: tr("До"),
                image: result.source.image,
                dimensions: "\(result.source.width)×\(result.source.height)",
                bytes: result.source.sizeBytes
            )
            preview(
                title: tr("После"),
                image: outputImage,
                dimensions: "\(result.outputWidth)×\(result.outputHeight)",
                bytes: result.outputSizeBytes
            )
        }
        .dynamicTypeSize(dynamicTypeSize.isAccessibilitySize ? .accessibility1 : dynamicTypeSize)
    }

    private func preview(title: String, image: UIImage, dimensions: String, bytes: Int64) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.arvectumAccentText)

            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: result.mode == .passport ? 84 : 116)
                .clipped()
                .background(Color.arvectumBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                // Visual thumbnail is accompanied by spoken "Before/After",
                // dimensions and file size. Do not announce an unnamed Image.
                .accessibilityHidden(true)

            Text("\(dimensions) · \(formatBytes(bytes))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PDFResultCard: View {
    let result: ResultPDF
    let onShare: () -> Void
    let onBack: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ResultTopBar(onBack: onBack)

            Text(tr(result.alreadyFit ? "PDF уже подходит" : "PDF подготовлен"))
                .font(.title3.weight(.semibold))
                .dynamicTypeSize(dynamicTypeSize.isAccessibilitySize ? .accessibility1 : dynamicTypeSize)
                .foregroundStyle(Color.arvectumPrimaryText)

            HStack(spacing: 12) {
                if let preview = result.previewImage ?? result.source.previewImage {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 92, height: 122)
                        .background(Color.arvectumBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 44))
                        .frame(width: 92, height: 122)
                        .background(Color.arvectumBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityHidden(true)
                }

                VStack(spacing: 8) {
                    stat(tr("До"), formatBytes(result.source.sizeBytes))
                    stat(tr("После"), formatBytes(result.outputSizeBytes))
                    stat(tr("Страниц"), "\(result.source.pageCount)")
                }
            }

            Text(tr("PDF обработан локально на устройстве и никуда не загружался."))
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(action: onShare) {
                Label(tr("Поделиться"), systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .dynamicTypeSize(dynamicTypeSize.isAccessibilitySize ? .accessibility1 : dynamicTypeSize)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 46)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.arvectumPrimaryText)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.arvectumStrongBorder, lineWidth: 1)
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 430, alignment: .topLeading)
        .background(Color.arvectumSurface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.arvectumBorder, lineWidth: 1)
        )
    }

    private func stat(_ label: String, _ value: String) -> some View {
        let stacked = dynamicTypeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if !stacked {
                Spacer(minLength: 4)
            }
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.arvectumPrimaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        // Keep label and value individually legible instead of wrapping a
        // short amount onto multiple lines beside the PDF preview.
        .dynamicTypeSize(stacked ? .accessibility1 : dynamicTypeSize)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.arvectumBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ResultCard: View {
    let result: ResultImage
    let onSavePrintSheet: () -> Void
    let onShare: () -> Void
    let onBack: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: result.mode == .passport ? 7 : 12) {
            ResultTopBar(onBack: onBack)

            Text(tr(result.alreadyFit ? "Фото уже подходит" : "Фото подготовлено"))
                .font(.title3.weight(.semibold))
                .dynamicTypeSize(dynamicTypeSize.isAccessibilitySize ? .accessibility1 : dynamicTypeSize)
                .foregroundStyle(Color.arvectumPrimaryText)

            BeforeAfterPreview(result: result)

            HStack(spacing: 10) {
                stat(tr("Размер"), formatBytes(result.outputSizeBytes))
                stat(tr("Разрешение"), "\(result.outputWidth)×\(result.outputHeight)")
            }
            .dynamicTypeSize(dynamicTypeSize.isAccessibilitySize ? .accessibility1 : dynamicTypeSize)

            if result.mode == .passport, let preset = result.documentPreset {
                Text(preset.outputSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let sheet = result.printSheet {
                Button(action: onSavePrintSheet) {
                    Label("Лист для печати", systemImage: "square.grid.2x2")
                        .font(.headline)
                        .dynamicTypeSize(dynamicTypeSize.isAccessibilitySize ? .accessibility1 : dynamicTypeSize)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: result.mode == .passport ? 40 : 46)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.arvectumPrimaryText)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.arvectumStrongBorder, lineWidth: 1)
                )

                Text(sheet.label + " · " + tr("Печатать без масштабирования"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Button(action: onShare) {
                Label("Поделиться", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .dynamicTypeSize(dynamicTypeSize.isAccessibilitySize ? .accessibility1 : dynamicTypeSize)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: result.mode == .passport ? 40 : 46)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.arvectumPrimaryText)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.arvectumStrongBorder, lineWidth: 1)
            )

        }
        .padding(result.mode == .passport ? 10 : 14)
        .frame(
            maxWidth: .infinity,
            minHeight: result.mode == .passport ? 0 : 430,
            alignment: .topLeading
        )
        .background(Color.arvectumSurface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.arvectumBorder, lineWidth: 1)
        )
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.arvectumPrimaryText)
                .lineLimit(1)
        }
        .padding(result.mode == .passport ? 8 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.arvectumBackground, in: RoundedRectangle(cornerRadius: 14))
    }
}
