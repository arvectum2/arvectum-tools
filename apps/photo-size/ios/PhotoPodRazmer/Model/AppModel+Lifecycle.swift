import Foundation
import PhotosUI
import SwiftUI

@MainActor
extension AppModel {
    func backToSelection() {
        invalidateOperation()
        result = nil
        pdfResult = nil
        passportCropOpen = false
        saved = false
        errorMessage = nil
    }

    func reset() {
        invalidateOperation()
        inputKind = .photo
        mode = .fileSize
        source = nil
        result = nil
        pdfSource = nil
        pdfResult = nil
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

    func markSaveFailed(_ error: Error) {
        saved = false
        let description = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = description.isEmpty
            ? tr("Не получилось сохранить файл.")
            : "\(tr("Не получилось сохранить файл.")) \(description)"
    }
}
