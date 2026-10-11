import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct BeforeAfterPreview: View {
    let result: ResultImage

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
    let onSave: () -> Void
    let onShare: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(tr("ГОТОВО"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.arvectumAccentText)
                Spacer()
                Button(action: onBack) {
                    Label(tr("Изменить настройки"), systemImage: "slider.horizontal.3")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .frame(height: 32)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.arvectumPrimaryText)
                .background(Color.arvectumBackground, in: Capsule())
            }

            Text(tr(result.alreadyFit ? "PDF уже подходит" : "PDF подготовлен"))
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.arvectumPrimaryText)

            HStack(spacing: 12) {
                if let preview = result.previewImage ?? result.source.previewImage {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 92, height: 122)
                        .background(Color.arvectumBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 44))
                        .frame(width: 92, height: 122)
                        .background(Color.arvectumBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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

            Button(action: onSave) {
                Label(tr("Сохранить файл"), systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.arvectumPrimaryText)
            .background(Color.arvectumMint, in: RoundedRectangle(cornerRadius: 16))

            Button(action: onShare) {
                Label(tr("Поделиться"), systemImage: "square.and.arrow.up")
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
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.arvectumPrimaryText)
        }
        .padding(10)
        .background(Color.arvectumBackground, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ResultCard: View {
    let result: ResultImage
    let onSave: () -> Void
    let onSavePrintSheet: () -> Void
    let onShare: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: result.mode == .passport ? 7 : 12) {
            HStack(spacing: 8) {
                Text("ГОТОВО")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.arvectumAccentText)

                Spacer(minLength: 8)

                Button(action: onBack) {
                    Label("Изменить настройки", systemImage: "slider.horizontal.3")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .padding(.horizontal, 10)
                        .frame(height: 32)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.arvectumPrimaryText)
                .background(Color.arvectumBackground, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.arvectumStrongBorder, lineWidth: 1)
                )
                .accessibilityIdentifier("edit-settings-button")
            }

            Text(tr(result.alreadyFit ? "Фото уже подходит" : "Фото подготовлено"))
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.arvectumPrimaryText)

            BeforeAfterPreview(result: result)

            HStack(spacing: 10) {
                stat(tr("Размер"), formatBytes(result.outputSizeBytes))
                stat(tr("Разрешение"), "\(result.outputWidth)×\(result.outputHeight)")
            }

            if result.mode == .passport, let preset = result.documentPreset {
                Text(preset.outputSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button(action: onSave) {
                Label("Сохранить файл", systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: result.mode == .passport ? 42 : 48)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.arvectumPrimaryText)
            .background(Color.arvectumMint, in: RoundedRectangle(cornerRadius: 16))

            if let sheet = result.printSheet {
                Button(action: onSavePrintSheet) {
                    Label("Лист для печати", systemImage: "square.grid.2x2")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: result.mode == .passport ? 40 : 46)
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
                    .frame(maxWidth: .infinity)
                    .frame(height: result.mode == .passport ? 40 : 46)
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
