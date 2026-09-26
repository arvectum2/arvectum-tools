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
                    MainTaskCard(pickerItem: $pickerItem)
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
                    .tint(.arvectumNavy)
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
            model.errorMessage = "Не получилось сохранить файл."
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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch model.mode {
            case .fileSize:
                taskHeader("ПО ВЕСУ", "Уменьшить фото до нужного веса")
                sourceRow
                presetRow
                if model.isCustomTarget { customSizeRow }
                primaryAction(
                    title: "Уменьшить фото",
                    enabled: model.source != nil && model.targetBytes != nil,
                    action: model.compressByBytes
                )
            case .pixels:
                taskHeader("ПО РАЗМЕРУ", "Задать размер длинной стороны")
                sourceRow
                pixelPresetRow
                if model.isCustomPixels { customPixelsRow }
                primaryAction(
                    title: "Изменить размер",
                    enabled: model.source != nil && model.targetLongSide != nil,
                    action: model.resizeByPixels
                )
            case .passport:
                taskHeader("НА ПАСПОРТ", "Подогнать фото под 35×45")
                sourceRow
                infoBox(
                    "620×797 px · 450 DPI · JPEG\n" +
                    "Кадрирование вручную. Лицо и фон приложение не изменяет."
                )
                primaryAction(
                    title: "Кадрировать 35×45",
                    enabled: model.source != nil,
                    action: model.openPassportCrop
                )
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.arvectumSurface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.arvectumNavy.opacity(0.10), lineWidth: 1)
        )
    }

    private var sourceRow: some View {
        let selectedSource = model.source
        return PhotosPicker(selection: $pickerItem, matching: .images) {
            HStack(spacing: 10) {
                Image(systemName: selectedSource == nil ? "photo.badge.plus" : "photo.fill")
                    .font(.title3)
                    .foregroundStyle(Color.arvectumNavy)
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedSource == nil ? "Выбрать фото" : "Фото выбрано")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.arvectumNavy)
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
    }

    private var presetRow: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Максимальный вес")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 5) {
                ForEach(fileSizePresets, id: \.0) { preset in
                    Chip(
                        text: preset.1,
                        selected: !model.isCustomTarget && model.targetBytes == preset.0
                    ) { model.setPreset(preset.0) }
                }
                Chip(text: "Свой", selected: model.isCustomTarget) {
                    model.startCustomTarget()
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
                        text: preset.1,
                        selected: !model.isCustomPixels && model.targetLongSide == preset.0
                    ) { model.setPixelPreset(preset.0) }
                }
                Chip(text: "Свой", selected: model.isCustomPixels) {
                    model.startCustomPixels()
                }
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
                    Text(unit.rawValue).tag(unit)
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
                .foregroundStyle(Color.arvectumNavy.opacity(0.72))
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.arvectumNavy)
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
        .foregroundStyle(Color.arvectumNavy)
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

private struct ResultCard: View {
    let result: ResultImage
    let onSave: () -> Void
    let onShare: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ГОТОВО")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.arvectumNavy.opacity(0.72))
            Text(result.alreadyFit ? "Фото уже подходит" : "Фото подготовлено")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.arvectumNavy)

            HStack(spacing: 10) {
                stat("Размер", formatBytes(result.outputSizeBytes))
                stat("Разрешение", "\(result.outputWidth)×\(result.outputHeight)")
            }

            if result.mode == .passport {
                Text("620×797 px · 450 DPI · JPEG")
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
            .foregroundStyle(Color.arvectumNavy)
            .background(Color.arvectumMint, in: RoundedRectangle(cornerRadius: 16))

            Button(action: onShare) {
                Label("Поделиться", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.arvectumNavy)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.arvectumNavy.opacity(0.22), lineWidth: 1)
            )

            Button("Вернуться к настройкам", action: onBack)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.arvectumNavy)
                .frame(maxWidth: .infinity)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.arvectumSurface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.arvectumNavy.opacity(0.10), lineWidth: 1)
        )
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.arvectumNavy)
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
                .foregroundStyle(Color.arvectumNavy)
                .background(
                    mode == item ? Color.arvectumMint : Color.arvectumSurface,
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            mode == item ? Color.arvectumMint : Color.arvectumNavy.opacity(0.10),
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
            .foregroundStyle(Color.arvectumNavy)
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
