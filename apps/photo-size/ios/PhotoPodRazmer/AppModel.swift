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
    @Published var passportCropOpen = false
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
                    throw PhotoToolError.message("Не получилось прочитать выбранное фото.")
                }
                let engine = self.engine
                let inspected = try await Task.detached(priority: .userInitiated) {
                    try engine.inspect(data: data)
                }.value
                source = inspected
                isWorking = false
            } catch {
                source = nil
                isWorking = false
                errorMessage = userMessage(error, fallback: "Не получилось открыть этот файл.")
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
        process(fallback: "Не получилось уменьшить это изображение.") { engine in
            try engine.compressByBytes(source: source, requestedMaximumBytes: targetBytes)
        }
    }

    func resizeByPixels() {
        guard let source, let targetLongSide else { return }
        process(fallback: "Не получилось изменить размер изображения.") { engine in
            try engine.resizeLongSide(source: source, targetLongSide: targetLongSide)
        }
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
        process(fallback: "Не получилось подготовить фото на паспорт.") { engine in
            try engine.preparePassport(source: source, crop: crop)
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
        passportCropOpen = false
        isWorking = false
        errorMessage = nil
        saved = false
    }

    func markSaved(_ success: Bool) {
        saved = success
        if !success {
            errorMessage = "Не получилось сохранить файл."
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
