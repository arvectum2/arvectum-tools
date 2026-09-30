import Foundation
import PhotosUI
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var mode: ToolMode = .fileSize
    @Published var source: SourceImage?
    @Published var result: ResultImage?
    @Published var targetBytes: Int64? = 5_000_000
    @Published var isCustomTarget = false
    @Published var customValue = ""
    @Published var customUnit: SizeUnit = .kb
    @Published var targetLongSide: Int? = 600
    @Published var isCustomPixels = false
    @Published var customPixelsValue = ""
    @Published var pixelResizeMode: PixelResizeMode = .longSide
    @Published var exactWidthValue = ""
    @Published var exactHeightValue = ""
    @Published var keepPixelAspectRatio = true
    @Published var exportFormat: ExportImageFormat = .jpeg
    @Published var stripMetadata = true
    @Published var passportCropOpen = false
    @Published var documentPreset: DocumentPhotoPreset = .russiaPassport
    @Published var isWorking = false
    @Published var errorMessage: String?
    @Published var saved = false

    private let engine = ImageEngine()

    init() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "--store-screenshot-mode"),
           args.indices.contains(index + 1) {
            switch args[index + 1] {
            case "pixels": mode = .pixels
            case "passport": mode = .passport
            default: mode = .fileSize
            }
        }
        if let index = args.firstIndex(of: "--document-preset"),
           args.indices.contains(index + 1),
           let preset = DocumentPhotoPreset(rawValue: args[index + 1]) {
            documentPreset = preset
            mode = .passport
        }
        if args.contains("--pixel-resize-exact") {
            mode = .pixels
            pixelResizeMode = .exact
            exactWidthValue = "600"
        }
        if let index = args.firstIndex(of: "--store-screenshot-fixture"),
           args.indices.contains(index + 1) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: args[index + 1]))
                let inspected = try engine.inspect(data: data)
                source = inspected
                switch mode {
                case .fileSize:
                    targetBytes = 500_000
                    result = try engine.compressByBytes(
                        source: inspected,
                        requestedMaximumBytes: 500_000
                    )
                case .pixels:
                    targetLongSide = 600
                    result = try engine.resizeLongSide(source: inspected, targetLongSide: 600)
                case .passport:
                    result = try engine.preparePassport(
                        source: inspected,
                        crop: NormalizedCropRect(left: 0, top: 0, right: 1, bottom: 1),
                        preset: documentPreset
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        #endif
    }

    func setMode(_ newMode: ToolMode) {
        mode = newMode
        result = nil
        passportCropOpen = false
        saved = false
        errorMessage = nil
    }

    func selectPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        isWorking = true
        errorMessage = nil
        result = nil
        saved = false
        passportCropOpen = false

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw PhotoToolError.message(tr("Не получилось прочитать выбранное фото."))
                }
                let engine = self.engine
                let inspected = try await Task.detached(priority: .userInitiated) {
                    try engine.inspect(data: data)
                }.value
                source = inspected
                syncExactDimensionsAfterSource()
                isWorking = false
            } catch {
                source = nil
                isWorking = false
                errorMessage = userMessage(error, fallback: tr("Не получилось открыть этот файл."))
            }
        }
    }

    func selectFile(_ url: URL) {
        isWorking = true
        errorMessage = nil
        result = nil
        saved = false
        passportCropOpen = false

        Task {
            do {
                let data = try await Task.detached(priority: .userInitiated) {
                    let hasAccess = url.startAccessingSecurityScopedResource()
                    defer {
                        if hasAccess { url.stopAccessingSecurityScopedResource() }
                    }
                    return try Data(contentsOf: url, options: .mappedIfSafe)
                }.value
                let engine = self.engine
                let inspected = try await Task.detached(priority: .userInitiated) {
                    try engine.inspect(data: data)
                }.value
                source = inspected
                syncExactDimensionsAfterSource()
                isWorking = false
            } catch {
                source = nil
                isWorking = false
                errorMessage = userMessage(error, fallback: tr("Не получилось открыть этот файл."))
            }
        }
    }

    func setPreset(_ bytes: Int64) {
        targetBytes = bytes
        isCustomTarget = false
        result = nil
        saved = false
        errorMessage = nil
    }

    func startCustomTarget() {
        isCustomTarget = true
        customValue = ""
        targetBytes = nil
        result = nil
        saved = false
    }

    func setCustomValue(_ value: String) {
        let filtered = value.filter { $0.isNumber || $0 == "," || $0 == "." }
        customValue = String(filtered.prefix(10))
        targetBytes = parseCustomTarget()
        result = nil
        saved = false
    }

    func setCustomUnit(_ unit: SizeUnit) {
        customUnit = unit
        targetBytes = parseCustomTarget()
        result = nil
        saved = false
    }

    var exactWidth: Int? { validPixelDimension(exactWidthValue) }
    var exactHeight: Int? { validPixelDimension(exactHeightValue) }

    var canResizePixels: Bool {
        guard source != nil else { return false }
        switch pixelResizeMode {
        case .longSide:
            return targetLongSide != nil
        case .exact:
            return exactWidth != nil && exactHeight != nil
        }
    }

    func setStripMetadata(_ strip: Bool) {
        stripMetadata = strip
        result = nil
        saved = false
        errorMessage = nil
    }

    func setExportFormat(_ format: ExportImageFormat) {
        exportFormat = format
        result = nil
        saved = false
        errorMessage = nil
    }

    func setPixelResizeMode(_ newMode: PixelResizeMode) {
        pixelResizeMode = newMode
        result = nil
        saved = false
        errorMessage = nil
        if newMode == .exact {
            syncExactDimensionsAfterSource()
        }
    }

    func setExactWidth(_ value: String) {
        exactWidthValue = cleanPixelDimension(value)
        if keepPixelAspectRatio, let source, let width = exactWidth {
            let height = max(1, Int((Double(width) * Double(source.height) / Double(source.width)).rounded()))
            exactHeightValue = String(min(height, 12_000))
        }
        result = nil
        saved = false
        errorMessage = nil
    }

    func setExactHeight(_ value: String) {
        exactHeightValue = cleanPixelDimension(value)
        if keepPixelAspectRatio, let source, let height = exactHeight {
            let width = max(1, Int((Double(height) * Double(source.width) / Double(source.height)).rounded()))
            exactWidthValue = String(min(width, 12_000))
        }
        result = nil
        saved = false
        errorMessage = nil
    }

    func setKeepPixelAspectRatio(_ keep: Bool) {
        keepPixelAspectRatio = keep
        if keep { syncExactDimensionsAfterSource() }
        result = nil
        saved = false
        errorMessage = nil
    }

    func setPixelPreset(_ value: Int) {
        targetLongSide = value
        isCustomPixels = false
        result = nil
        saved = false
        errorMessage = nil
    }

    func startCustomPixels() {
        isCustomPixels = true
        customPixelsValue = ""
        targetLongSide = nil
        result = nil
        saved = false
    }

    func setCustomPixels(_ value: String) {
        let cleaned = String(value.filter(\.isNumber).prefix(5))
        customPixelsValue = cleaned
        if let number = Int(cleaned), (32...12_000).contains(number) {
            targetLongSide = number
        } else {
            targetLongSide = nil
        }
        result = nil
        saved = false
    }

    func compressByBytes() {
        guard let source, let targetBytes else { return }
        process(fallback: tr("Не получилось уменьшить это изображение.")) { engine in
            try engine.compressByBytes(source: source, requestedMaximumBytes: targetBytes, stripMetadata: self.stripMetadata)
        }
    }

    func resizeByPixels() {
        guard let source else { return }
        switch pixelResizeMode {
        case .longSide:
            guard let targetLongSide else { return }
            process(fallback: tr("Не получилось изменить размер изображения.")) { engine in
                try engine.resizeLongSide(source: source, targetLongSide: targetLongSide, format: self.exportFormat, stripMetadata: self.stripMetadata)
            }
        case .exact:
            guard let width = exactWidth, let height = exactHeight else { return }
            process(fallback: tr("Не получилось изменить размер изображения.")) { engine in
                try engine.resizeExact(source: source, width: width, height: height, format: self.exportFormat, stripMetadata: self.stripMetadata)
            }
        }
    }

    func setDocumentPreset(_ preset: DocumentPhotoPreset) {
        documentPreset = preset
        result = nil
        passportCropOpen = false
        saved = false
        errorMessage = nil
    }

    func openPassportCrop() {
        guard source != nil else { return }
        passportCropOpen = true
        errorMessage = nil
        saved = false
    }

    func preparePassport(_ crop: NormalizedCropRect) {
        guard let source else { return }
        passportCropOpen = false
        process(fallback: tr("Не получилось подготовить фото для документа.")) { engine in
            try engine.preparePassport(source: source, crop: crop, preset: self.documentPreset)
        }
    }

    func backToSelection() {
        result = nil
        passportCropOpen = false
        saved = false
        errorMessage = nil
    }

    func reset() {
        source = nil
        result = nil
        targetBytes = 5_000_000
        isCustomTarget = false
        customValue = ""
        customUnit = .kb
        targetLongSide = 600
        isCustomPixels = false
        customPixelsValue = ""
        pixelResizeMode = .longSide
        exactWidthValue = ""
        exactHeightValue = ""
        keepPixelAspectRatio = true
        exportFormat = .jpeg
        stripMetadata = true
        passportCropOpen = false
        documentPreset = .russiaPassport
        isWorking = false
        errorMessage = nil
        saved = false
    }

    func markSaved(_ success: Bool) {
        saved = success
        if !success {
            errorMessage = tr("Не получилось сохранить файл.")
        }
    }

    private func process(
        fallback: String,
        operation: @escaping (ImageEngine) throws -> ResultImage
    ) {
        isWorking = true
        errorMessage = nil
        saved = false
        result = nil
        let engine = self.engine
        Task {
            do {
                let output = try await Task.detached(priority: .userInitiated) {
                    try operation(engine)
                }.value
                result = output
                isWorking = false
            } catch {
                isWorking = false
                errorMessage = userMessage(error, fallback: fallback)
            }
        }
    }

    private func cleanPixelDimension(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(5))
    }

    private func validPixelDimension(_ value: String) -> Int? {
        guard let number = Int(value), (32...12_000).contains(number) else { return nil }
        return number
    }

    private func syncExactDimensionsAfterSource() {
        guard keepPixelAspectRatio, let source else { return }
        if let width = exactWidth {
            let height = max(1, Int((Double(width) * Double(source.height) / Double(source.width)).rounded()))
            exactHeightValue = String(min(height, 12_000))
        } else if let height = exactHeight {
            let width = max(1, Int((Double(height) * Double(source.width) / Double(source.height)).rounded()))
            exactWidthValue = String(min(width, 12_000))
        }
    }

    private func parseCustomTarget() -> Int64? {
        let normalized = customValue.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value > 0 else { return nil }
        let bytes = Int64((value * Double(customUnit.multiplier)).rounded())
        return (10_000...50_000_000).contains(bytes) ? bytes : nil
    }

    private func userMessage(_ error: Error, fallback: String) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription {
            return description
        }
        return fallback
    }
}
