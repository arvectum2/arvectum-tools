import Foundation
import PhotosUI
import SwiftUI

@MainActor
extension AppModel {
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
        let cleaned = InputConstraints.cleanPixels(value)
        customPixelsValue = cleaned
        if let number = InputConstraints.validPixels(cleaned) {
            targetLongSide = number
        } else {
            targetLongSide = nil
        }
        result = nil
        saved = false
    }
}
