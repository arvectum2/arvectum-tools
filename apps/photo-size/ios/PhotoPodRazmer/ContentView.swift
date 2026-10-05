import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

private let fileSizePresets: [(Int64, String)] = [
    (100_000, "100 КБ"),
    (500_000, "500 КБ"),
    (1_000_000, "1 МБ"),
    (2_000_000, "2 МБ"),
    (5_000_000, "5 МБ")
]

private let pixelPresets: [(Int, String)] = [
    (600, "600 px"),
    (450, "450 px"),
    (300, "300 px")
]

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var pickerItem: PhotosPickerItem?
    @State private var exporting = false
    @State private var exportDocument = ExportDocument(data: Data())
    @State private var exportFilename = "file.dat"
    @State private var exportContentType: UTType = .data
    @State private var shareURL: URL?
    @State private var showingAdPrivacySettings = false
    @StateObject private var mainNativeAdSession = NativeAdSession()

    var body: some View {
        ZStack {
            Color.arvectumBackground.ignoresSafeArea()

            VStack(spacing: 6) {
                BrandHeader(
                    showHome: model.result != nil || model.pdfResult != nil,
                    onHome: model.backToSelection
                )

                if model.result == nil && model.pdfResult == nil {
                    ModeSelector(
                        kind: model.inputKind,
                        mode: model.mode,
                        onPhotoMode: {
                            model.setInputKind(.photo)
                            model.setMode($0)
                        },
                        onPDF: { model.setInputKind(.pdf) }
                    )
                }

                if let result = model.result {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 6) {
                            ResultCard(
                                result: result,
                                onSave: beginExport,
                                onSavePrintSheet: beginPrintSheetExport,
                                onShare: { shareURL = result.outputURL },
                                onBack: model.backToSelection
                            )
                            ResultScreenAdSlot()
                        }
                    }
                } else if let pdfResult = model.pdfResult {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 6) {
                            PDFResultCard(
                                result: pdfResult,
                                onSave: beginPDFExport,
                                onShare: { shareURL = pdfResult.outputURL },
                                onBack: model.backToSelection
                            )
                            ResultScreenAdSlot()
                        }
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 4) {
                            if model.inputKind == .photo {
                                MainTaskCard(pickerItem: $pickerItem)
                            } else {
                                PDFTaskCard()
                            }
                            MainScreenNativeAdSlot(session: mainNativeAdSession)
                        }
                    }
                }

                HStack(spacing: 6) {
                    Text("Arvectum.com")
                    Text("·")
                    Button(tr("Реклама и конфиденциальность")) {
                        showingAdPrivacySettings = true
                    }
                    .buttonStyle(.plain)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.3)
                .frame(height: (model.result == nil && model.pdfResult == nil) ? 24 : 16)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("app-footer")
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)
            .padding(.bottom, 0)

            if model.isWorking {
                Color.black.opacity(0.12).ignoresSafeArea()
                ProgressView()
                    .controlSize(.large)
                    .tint(.arvectumMint)
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            }
        }
        .onAppear {
            mainNativeAdSession.prefetch()
        }
        .sheet(isPresented: $showingAdPrivacySettings) {
            AdConsentSheet { value in
                AdSDK.setUserConsent(value)
                showingAdPrivacySettings = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: pickerItem) { _, newValue in
            model.selectPhoto(newValue)
        }
        .alert("Фото и PDF под размер", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .fullScreenCover(isPresented: $model.passportCropOpen) {
            if let source = model.source {
                PassportCropView(
                    image: source.image,
                    preset: model.documentPreset,
                    onCancel: { model.passportCropOpen = false },
                    onConfirm: model.preparePassport
                )
            }
        }
        .fileExporter(
            isPresented: $exporting,
            document: exportDocument,
            contentType: exportContentType,
            defaultFilename: exportFilename
        ) { result in
            model.markSaved((try? result.get()) != nil)
        }
        .sheet(isPresented: Binding(
            get: { shareURL != nil },
            set: { if !$0 { shareURL = nil } }
        )) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
    }

    private func beginExport() {
        guard let result = model.result,
              let data = try? Data(contentsOf: result.outputURL) else {
            model.errorMessage = tr("Не получилось сохранить файл.")
            return
        }
        exportDocument = ExportDocument(data: data)
        exportFilename = result.suggestedFileName
        exportContentType = result.contentType
        exporting = true
    }

    private func beginPDFExport() {
        guard let result = model.pdfResult,
              let data = try? Data(contentsOf: result.outputURL) else {
            model.errorMessage = tr("Не получилось сохранить файл.")
            return
        }
        exportDocument = ExportDocument(data: data)
        exportFilename = result.suggestedFileName
        exportContentType = .pdf
        exporting = true
    }

    private func beginPrintSheetExport() {
        guard let sheet = model.result?.printSheet,
              let data = try? Data(contentsOf: sheet.outputURL) else {
            model.errorMessage = tr("Не получилось подготовить лист для печати.")
            return
        }
        exportDocument = ExportDocument(data: data)
        exportFilename = sheet.suggestedFileName
        exportContentType = .jpeg
        exporting = true
    }
}

@MainActor
private struct MainTaskCard: View {
    @EnvironmentObject private var model: AppModel
    @Binding var pickerItem: PhotosPickerItem?
    @State private var importingFile = false
    @State private var advancedOptionsExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch model.mode {
            case .fileSize:
                taskHeader(tr("ПО ВЕСУ"), tr("Уменьшить фото до нужного веса"))
                sourceRow
                presetRow
                if model.isCustomTarget { customSizeRow }
                advancedOptionsRow
            case .pixels:
                taskHeader(tr("ПО РАЗМЕРУ"), tr("Изменить размер в пикселях"))
                sourceRow
                pixelResizeModeRow
                if model.pixelResizeMode == .longSide {
                    pixelPresetRow
                    if model.isCustomPixels { customPixelsRow }
                } else {
                    exactPixelsRow
                }
                advancedOptionsRow
            case .passport:
                taskHeader(tr("НА ДОКУМЕНТЫ"), tr("Подготовить фото по требованиям документа"))
                documentPresetRow
                sourceRow
                infoBox(model.documentPreset.outputSummary + "\n" + model.documentPreset.guidance)
            }
            primaryActionForCurrentMode
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.arvectumSurface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.arvectumBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("main-task-card")
    }

    @ViewBuilder
    private var primaryActionForCurrentMode: some View {
        switch model.mode {
        case .fileSize:
            primaryAction(
                title: tr("Уменьшить фото"),
                enabled: model.source != nil && model.targetBytes != nil,
                action: model.compressByBytes
            )
        case .pixels:
            primaryAction(
                title: tr("Изменить размер"),
                enabled: model.canResizePixels,
                action: model.resizeByPixels
            )
        case .passport:
            primaryAction(
                title: tr("Подготовить фото"),
                enabled: model.source != nil,
                action: model.openPassportCrop
            )
        }
    }

    private var documentPresetRow: some View {
        Picker("Страна / документ", selection: Binding(
            get: { model.documentPreset },
            set: { model.setDocumentPreset($0) }
        )) {
            ForEach(DocumentPhotoPreset.allCases) { preset in
                Text(preset.title).tag(preset)
            }
        }
        .pickerStyle(.menu)
        .tint(Color.arvectumPrimaryText)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        .background(Color.arvectumBackground, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel(Text(tr("Страна / документ")))
    }

    private var sourceRow: some View {
        let selectedSource = model.source
        return HStack(spacing: 8) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                HStack(spacing: 9) {
                    Image(systemName: selectedSource == nil ? "photo.badge.plus" : "photo.fill")
                        .font(.title3)
                        .foregroundStyle(Color.arvectumPrimaryText)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tr(selectedSource == nil ? "Выбрать фото" : "Фото выбрано"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.arvectumPrimaryText)
                            .lineLimit(1)
                        if let source = selectedSource {
                            Text("\(source.width)×\(source.height) px · \(formatBytes(source.sizeBytes))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        } else {
                            Text("JPEG, PNG, HEIC и другие изображения")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 11)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .background(Color.arvectumBackground, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button {
                importingFile = true
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: "folder")
                        .font(.body.weight(.semibold))
                    Text(tr("Файлы"))
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                }
                .frame(width: 76, height: 62)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("import-files-button")
            .foregroundStyle(Color.arvectumPrimaryText)
            .background(Color.arvectumBackground, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.arvectumBorder, lineWidth: 1)
            )
            .fileImporter(
                isPresented: $importingFile,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    model.selectFile(url)
                }
            }
        }
    }

    private var presetRow: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Максимальный вес")
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
    }

    private var advancedOptionsRow: some View {
        DisclosureGroup(isExpanded: $advancedOptionsExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                if model.mode == .pixels {
                    exportFormatRow
                }
                metadataPrivacyRow
            }
            .padding(.top, 8)
        } label: {
            Label("Дополнительно", systemImage: "slider.horizontal.3")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.arvectumPrimaryText)
        }
        .tint(Color.arvectumPrimaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.arvectumBackground, in: RoundedRectangle(cornerRadius: 14))
    }

    private var metadataPrivacyRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Удалить EXIF/GPS", isOn: Binding(
                get: { model.stripMetadata },
                set: { model.setStripMetadata($0) }
            ))
            .font(.caption.weight(.semibold))
            .tint(.arvectumMint)
            .accessibilityIdentifier("strip-metadata-toggle")

            Text(model.stripMetadata
                 ? "Геолокация и метаданные не попадут в готовый файл."
                 : "Метаданные исходного фото будут сохранены, где это поддерживает формат.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var exportFormatRow: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Формат экспорта")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(ExportImageFormat.allCases) { format in
                    Chip(text: format.title, selected: model.exportFormat == format) {
                        model.setExportFormat(format)
                    }
                }
            }
        }
    }

    private var pixelResizeModeRow: some View {
        HStack(spacing: 6) {
            ForEach(PixelResizeMode.allCases) { item in
                Chip(text: item.title, selected: model.pixelResizeMode == item) {
                    model.setPixelResizeMode(item)
                }
            }
        }
    }

    private var pixelPresetRow: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Длинная сторона")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(pixelPresets, id: \.0) { preset in
                    Chip(
                        text: tr(preset.1),
                        selected: !model.isCustomPixels && model.targetLongSide == preset.0
                    ) { model.setPixelPreset(preset.0) }
                }
                Chip(text: tr("Свой"), selected: model.isCustomPixels) {
                    model.startCustomPixels()
                }
            }
        }
    }

    private var exactPixelsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ширина")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("px", text: Binding(
                        get: { model.exactWidthValue },
                        set: { model.setExactWidth($0) }
                    ))
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("exact-width-field")
                }

                Text("×")
                    .foregroundStyle(.secondary)
                    .padding(.top, 18)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Высота")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("px", text: Binding(
                        get: { model.exactHeightValue },
                        set: { model.setExactHeight($0) }
                    ))
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("exact-height-field")
                }
            }

            Toggle("Сохранять пропорции", isOn: Binding(
                get: { model.keepPixelAspectRatio },
                set: { model.setKeepPixelAspectRatio($0) }
            ))
            .font(.caption.weight(.semibold))
            .tint(.arvectumMint)

            if !model.keepPixelAspectRatio {
                Text("Без фиксации пропорций изображение может исказиться.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var customSizeRow: some View {
        HStack(spacing: 8) {
            TextField("Например, 750", text: Binding(
                get: { model.customValue },
                set: { value in model.setCustomValue(value) }
            ))
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)

            Picker("Единица", selection: Binding(
                get: { model.customUnit },
                set: { unit in model.setCustomUnit(unit) }
            )) {
                ForEach(SizeUnit.allCases) { unit in
                    Text(tr(unit.rawValue)).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 108)
        }
    }

    private var customPixelsRow: some View {
        TextField("32–12000 px", text: Binding(
            get: { model.customPixelsValue },
            set: { value in model.setCustomPixels(value) }
        ))
        .keyboardType(.numberPad)
        .textFieldStyle(.roundedBorder)
    }

    private func taskHeader(_ accent: String, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(accent)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.arvectumAccentText)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.arvectumPrimaryText)
        }
    }

    private func primaryAction(
        title: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.arvectumPrimaryText)
        .background(
            enabled ? Color.arvectumMint : Color.arvectumBackground,
            in: RoundedRectangle(cornerRadius: 16)
        )
        .opacity(enabled ? 1 : 0.65)
        .disabled(!enabled)
        .padding(.top, 2)
    }

    private func infoBox(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.arvectumBackground, in: RoundedRectangle(cornerRadius: 14))
    }
}

@MainActor
private struct PDFTaskCard: View {
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

private struct BeforeAfterPreview: View {
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

private struct PDFResultCard: View {
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

private struct ResultCard: View {
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

private struct BrandHeader: View {
    let showHome: Bool
    let onHome: () -> Void

    var body: some View {
        HStack {
            Image("ArvectumWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 102, height: 30)

            Spacer()

            if showHome {
                Button(action: onHome) {
                    Label(tr("Фото и PDF под размер"), systemImage: "house.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(tr("На главный экран")))
                .accessibilityIdentifier("home-button")
            } else {
                Text(tr("Фото и PDF под размер"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
        .background(Color.arvectumNavy, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct ModeSelector: View {
    let kind: InputKind
    let mode: ToolMode
    let onPhotoMode: (ToolMode) -> Void
    let onPDF: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ToolMode.allCases) { item in
                Button {
                    onPhotoMode(item)
                } label: {
                    Text(item.title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.arvectumPrimaryText)
                .background(
                    kind == .photo && mode == item ? Color.arvectumMint : Color.arvectumSurface,
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            kind == .photo && mode == item ? Color.arvectumMint : Color.arvectumBorder,
                            lineWidth: 1
                        )
                )
            }

            Button(action: onPDF) {
                Text("PDF")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.arvectumPrimaryText)
            .background(
                kind == .pdf ? Color.arvectumMint : Color.arvectumSurface,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(kind == .pdf ? Color.arvectumMint : Color.arvectumBorder, lineWidth: 1)
            )
        }
    }
}

private struct Chip: View {
    let text: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(text, action: action)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .allowsTightening(true)
            .buttonStyle(.plain)
            .foregroundStyle(Color.arvectumPrimaryText)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
                selected ? Color.arvectumMint : Color.arvectumBackground,
                in: RoundedRectangle(cornerRadius: 10)
            )
    }
}

private struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data, .jpeg, .png, .heic, .pdf] }
    static var writableContentTypes: [UTType] { [.data, .jpeg, .png, .heic, .pdf] }
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension Color {
    static let arvectumMint = Color(red: 67 / 255, green: 229 / 255, blue: 197 / 255)
    static let arvectumNavy = Color(red: 4 / 255, green: 26 / 255, blue: 51 / 255)
    static let arvectumGraphite = Color(red: 36 / 255, green: 52 / 255, blue: 70 / 255)
    static let arvectumPrimaryText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? .white : UIColor(red: 4 / 255, green: 26 / 255, blue: 51 / 255, alpha: 1)
    })
    static let arvectumAccentText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 67 / 255, green: 229 / 255, blue: 197 / 255, alpha: 0.92)
            : UIColor(red: 4 / 255, green: 26 / 255, blue: 51 / 255, alpha: 0.72)
    })
    static let arvectumBorder = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor(red: 4 / 255, green: 26 / 255, blue: 51 / 255, alpha: 0.10)
    })
    static let arvectumStrongBorder = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.24)
            : UIColor(red: 4 / 255, green: 26 / 255, blue: 51 / 255, alpha: 0.22)
    })
    static let arvectumBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 4 / 255, green: 26 / 255, blue: 51 / 255, alpha: 1)
            : UIColor(red: 243 / 255, green: 245 / 255, blue: 247 / 255, alpha: 1)
    })
    static let arvectumSurface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 36 / 255, green: 52 / 255, blue: 70 / 255, alpha: 1)
            : .white
    })
}
