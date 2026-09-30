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
    @State private var shareURL: URL?

    var body: some View {
        ZStack {
            Color.arvectumBackground.ignoresSafeArea()

            VStack(spacing: 10) {
                BrandHeader()
                ModeSelector(mode: model.mode) { model.setMode($0) }

                if let result = model.result {
                    ResultCard(
                        result: result,
                        onSave: beginExport,
                        onShare: { shareURL = result.outputURL },
                        onBack: model.backToSelection
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            MainTaskCard(pickerItem: $pickerItem)
                            MainScreenAdSlot()
                        }
                    }
                }

                Text("Arvectum.com")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                    .frame(height: 24)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 4)

            if model.isWorking {
                Color.black.opacity(0.12).ignoresSafeArea()
                ProgressView()
                    .controlSize(.large)
                    .tint(.arvectumMint)
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            }
        }
        .onChange(of: pickerItem) { _, newValue in
            model.selectPhoto(newValue)
        }
        .alert("Фото под размер", isPresented: Binding(
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
            contentType: .data,
            defaultFilename: model.result?.suggestedFileName ?? "foto.jpg"
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
        exporting = true
    }
}

@MainActor
private struct MainTaskCard: View {
    @EnvironmentObject private var model: AppModel
    @Binding var pickerItem: PhotosPickerItem?
    @State private var importingFile = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch model.mode {
            case .fileSize:
                taskHeader(tr("ПО ВЕСУ"), tr("Уменьшить фото до нужного веса"))
                sourceRow
                presetRow
                if model.isCustomTarget { customSizeRow }
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
            case .passport:
                taskHeader(tr("НА ДОКУМЕНТЫ"), tr("Подготовить фото по требованиям документа"))
                documentPresetRow
                sourceRow
                infoBox(model.documentPreset.outputSummary + "\n" + model.documentPreset.guidance)
            }
            Spacer(minLength: 12)
            primaryActionForCurrentMode
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 330, alignment: .topLeading)
        .background(Color.arvectumSurface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.arvectumBorder, lineWidth: 1)
        )
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
        VStack(alignment: .leading, spacing: 7) {
            Text("Страна / документ")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

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
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(Color.arvectumBackground, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var sourceRow: some View {
        let selectedSource = model.source
        return VStack(spacing: 7) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                HStack(spacing: 10) {
                    Image(systemName: selectedSource == nil ? "photo.badge.plus" : "photo.fill")
                        .font(.title3)
                        .foregroundStyle(Color.arvectumPrimaryText)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tr(selectedSource == nil ? "Выбрать фото" : "Фото выбрано"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.arvectumPrimaryText)
                        if let source = selectedSource {
                            Text("\(source.width)×\(source.height) px · \(formatBytes(source.sizeBytes))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("JPEG, PNG, HEIC и другие изображения")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color.arvectumBackground, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button {
                importingFile = true
            } label: {
                Label("Выбрать из Файлов", systemImage: "folder")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.arvectumPrimaryText)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
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
                .frame(height: 116)
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

private struct ResultCard: View {
    let result: ResultImage
    let onSave: () -> Void
    let onShare: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ГОТОВО")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.arvectumAccentText)
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
                    .frame(height: 48)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.arvectumPrimaryText)
            .background(Color.arvectumMint, in: RoundedRectangle(cornerRadius: 16))

            Button(action: onShare) {
                Label("Поделиться", systemImage: "square.and.arrow.up")
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

            Button("Вернуться к настройкам", action: onBack)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.arvectumPrimaryText)
                .frame(maxWidth: .infinity)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.arvectumBackground, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct BrandHeader: View {
    var body: some View {
        HStack {
            Image("ArvectumWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 102, height: 30)
            Spacer()
            Text("Фото под размер")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
        .background(Color.arvectumNavy, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct ModeSelector: View {
    let mode: ToolMode
    let onChange: (ToolMode) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ToolMode.allCases) { item in
                Button {
                    onChange(item)
                } label: {
                    Text(item.title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.arvectumPrimaryText)
                .background(
                    mode == item ? Color.arvectumMint : Color.arvectumSurface,
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            mode == item ? Color.arvectumMint : Color.arvectumBorder,
                            lineWidth: 1
                        )
                )
            }
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
            .buttonStyle(.plain)
            .foregroundStyle(Color.arvectumPrimaryText)
            .padding(.horizontal, 7)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
                selected ? Color.arvectumMint : Color.arvectumBackground,
                in: RoundedRectangle(cornerRadius: 10)
            )
    }
}

private struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }
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
