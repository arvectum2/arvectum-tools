import ArvectumCore
import SwiftUI

/// Read-only source preview; task selection and import/export state
/// remain in ContentView/AppModel while the Duo window width changes.
struct AdaptiveSourcePreview: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            if model.inputKind == .photo, let source = model.source {
                sourceCard(image: source.image,
                           description: "\(source.width)×\(source.height) px")
            } else if model.inputKind == .pdf,
                      let source = model.pdfSource,
                      let image = source.previewImage {
                sourceCard(image: image,
                           description: String(format: tr("%1$d %2$@"), source.pageCount, pdfPageWord(source.pageCount)))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: model.inputKind == .photo ? "photo" : "doc.richtext")
                        .font(.system(size: 42))
                        .foregroundStyle(Color.arvectumMint)
                    Text(tr("Выберите исходный файл"))
                        .font(.headline)
                        .foregroundStyle(Color.arvectumPrimaryText)
                    Text(tr("Предпросмотр появится здесь после выбора файла."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 220)
                .padding(16)
                .background(Color.arvectumSurface, in: RoundedRectangle(cornerRadius: 20))
                .accessibilityIdentifier("adaptive-source-placeholder")
            }
        }
    }

    private func sourceCard(image: UIImage, description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(tr("Исходный файл"))
                .font(.headline)
                .foregroundStyle(Color.arvectumPrimaryText)
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 370)
                .accessibilityLabel(tr("Предпросмотр исходного файла"))
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.arvectumSurface, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityIdentifier("adaptive-source-preview")
    }
}
