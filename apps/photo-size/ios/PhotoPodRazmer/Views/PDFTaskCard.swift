import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

@MainActor
struct PDFTaskCard: View {
    @EnvironmentObject private var model: AppModel
    @State private var importingPDF = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(tr("PDF ПО ВЕСУ"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.arvectumAccentText)
                Text(tr("Уменьшить PDF до нужного веса"))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.arvectumPrimaryText)
            }

            Button {
                importingPDF = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: model.pdfSource == nil ? "doc.badge.plus" : "doc.fill")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tr(model.pdfSource == nil ? "Выбрать PDF" : "PDF выбран"))
                            .font(.subheadline.weight(.semibold))
                        if let source = model.pdfSource {
                            Text("\(source.pageCount) \(pageWord(source.pageCount)) · \(formatBytes(source.sizeBytes))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(tr("PDF-файл из приложения «Файлы»"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(Color.arvectumPrimaryText)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(Color.arvectumBackground, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .fileImporter(
                isPresented: $importingPDF,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    model.selectPDFFile(url)
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(tr("Максимальный вес"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 5) {
                    ForEach(fileSizePresets, id: \.0) { preset in
                        Chip(
                            text: tr(preset.1),
                            selected: !model.isCustomTarget && model.targetBytes == preset.0
                        ) { model.setPreset(preset.0) }
                    }
                    Chip(text: tr("Свой"), selected: model.isCustomTarget) {
                        model.startCustomTarget()
                    }
                }
            }

            if model.isCustomTarget {
                HStack(spacing: 8) {
                    TextField(tr("Например, 750"), text: Binding(
                        get: { model.customValue },
                        set: { model.setCustomValue($0) }
                    ))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                    Picker(tr("Единица"), selection: Binding(
                        get: { model.customUnit },
                        set: { model.setCustomUnit($0) }
                    )) {
                        ForEach(SizeUnit.allCases) { unit in
                            Text(tr(unit.rawValue)).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 108)
                }
            }

            Text(tr("Обработка выполняется только на устройстве. При сильном сжатии страницы PDF растрируются, поэтому поиск и выделение текста в готовом файле могут быть недоступны."))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.arvectumBackground, in: RoundedRectangle(cornerRadius: 12))

            Button(action: model.compressPDFByBytes) {
                Text(tr("Уменьшить PDF"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.arvectumPrimaryText)
            .background(
                model.pdfSource != nil && model.targetBytes != nil ? Color.arvectumMint : Color.arvectumBackground,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .opacity(model.pdfSource != nil && model.targetBytes != nil ? 1 : 0.65)
            .disabled(model.pdfSource == nil || model.targetBytes == nil)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.arvectumSurface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.arvectumBorder, lineWidth: 1)
        )
    }

    private func pageWord(_ count: Int) -> String {
        tr(count == 1 ? "страница" : "страниц")
    }
}
