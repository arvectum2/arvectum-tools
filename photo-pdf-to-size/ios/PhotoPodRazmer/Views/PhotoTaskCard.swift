import ArvectumCore
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

@MainActor
struct MainTaskCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var model: AppModel
    @Binding var pickerItem: PhotosPickerItem?
    @State private var importingFile = false
    @State private var advancedOptionsExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch model.mode {
            case .fileSize:
                taskHeader(tr("СЖАТЬ ФОТО"), tr("Уменьшить размер файла до нужного значения"))
                sourceRow
                presetRow
                if model.isCustomTarget { customSizeRow }
                advancedOptionsRow
            case .pixels:
                taskHeader(tr("ИЗМЕНИТЬ РАЗМЕР"), tr("Изменить размер в пикселях"))
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
                taskHeader(tr("ФОТО НА ДОКУМЕНТЫ"), tr("Подготовить фото по требованиям документа"))
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

    // In accessibility mode each import choice gets its own row and
    // sufficient height for real localized labels. Side-by-side fixed
    // 62pt controls hid both labels in Spanish at AXXXL.
    private var sourceRow: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 8) {
                    photoSourcePicker
                    fileSourceImporter
                }
            } else {
                HStack(spacing: 0) {
                    photoSourcePicker
                    Divider().frame(height: 34)
                    fileSourceImporter
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.arvectumBackground, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.arvectumBorder, lineWidth: 1)
        )
    }

    private var photoSourcePicker: some View {
        let selectedSource = model.source
        let accessibility = dynamicTypeSize.isAccessibilitySize
        return PhotosPicker(selection: $pickerItem, matching: .images) {
            HStack(spacing: 9) {
                Image(systemName: selectedSource == nil ? "photo.badge.plus" : "photo.fill")
                    .font(.title3)
                    .foregroundStyle(Color.arvectumPrimaryText)
                VStack(alignment: .leading, spacing: 4) {
                    Text(tr(selectedSource == nil ? "Выбрать фото" : "Фото выбрано"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.arvectumPrimaryText)
                        .lineLimit(accessibility ? 2 : 1)
                    if let source = selectedSource {
                        Text(String(
                            format: tr("%1$d×%2$d px · %3$@"),
                            source.width, source.height, formatBytes(source.sizeBytes)
                        ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(accessibility ? 3 : 1)
                            .minimumScaleFactor(0.8)
                    } else {
                        Text("JPEG, PNG, HEIC и другие изображения")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(accessibility ? 3 : 1)
                            .minimumScaleFactor(0.8)
                    }
                }
                Spacer(minLength: 4)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, accessibility ? 12 : 0)
            .frame(maxWidth: .infinity, minHeight: accessibility ? 100 : 62)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var fileSourceImporter: some View {
        Button {
            importingFile = true
        } label: {
            Label(tr("Файлы"), systemImage: "folder")
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .frame(
                    maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil,
                    minHeight: dynamicTypeSize.isAccessibilitySize ? 60 : 36
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("import-files-button")
        .foregroundStyle(Color.arvectumPrimaryText)
        .padding(.horizontal, 8)
        .background(Color.arvectumSurface, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.arvectumBorder, lineWidth: 1)
        )
        .padding(dynamicTypeSize.isAccessibilitySize ? 6 : 8)
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

    private var presetRow: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(tr("Размер файла до"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            AdaptiveChipRow {
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

            AdaptiveChipRow {
                ForEach(ExportImageFormat.allCases) { format in
                    Chip(text: format.title, selected: model.exportFormat == format) {
                        model.setExportFormat(format)
                    }
                }
            }
        }
    }

    private var pixelResizeModeRow: some View {
        AdaptiveChipRow {
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
            AdaptiveChipRow {
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
