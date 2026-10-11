import Foundation
import PhotosUI
import SwiftUI

@MainActor
extension AppModel {
    func compressByBytes() {
        guard let source, let targetBytes else { return }
        let stripMetadata = self.stripMetadata
        process(fallback: tr("Не получилось уменьшить это изображение.")) { engine in
            try engine.compressByBytes(source: source, requestedMaximumBytes: targetBytes, stripMetadata: stripMetadata)
        }
    }

    func compressPDFByBytes() {
        guard let pdfSource, let targetBytes else { return }
        let operationID = beginOperation()
        isWorking = true
        errorMessage = nil
        saved = false
        pdfResult = nil
        let pdfEngine = self.pdfEngine

        Task {
            do {
                let output = try await Task.detached(priority: .userInitiated) {
                    try pdfEngine.compressByBytes(source: pdfSource, requestedMaximumBytes: targetBytes)
                }.value
                guard isCurrentOperation(operationID) else { return }
                pdfResult = output
                isWorking = false
            } catch {
                guard isCurrentOperation(operationID) else { return }
                isWorking = false
                errorMessage = userMessage(error, fallback: tr("Не получилось уменьшить этот PDF."))
            }
        }
    }

    func resizeByPixels() {
        guard let source else { return }
        let exportFormat = self.exportFormat
        let stripMetadata = self.stripMetadata
        switch pixelResizeMode {
        case .longSide:
            guard let targetLongSide else { return }
            process(fallback: tr("Не получилось изменить размер изображения.")) { engine in
                try engine.resizeLongSide(source: source, targetLongSide: targetLongSide, format: exportFormat, stripMetadata: stripMetadata)
            }
        case .exact:
            guard let width = exactWidth, let height = exactHeight else { return }
            process(fallback: tr("Не получилось изменить размер изображения.")) { engine in
                try engine.resizeExact(source: source, width: width, height: height, format: exportFormat, stripMetadata: stripMetadata)
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
        let documentPreset = self.documentPreset
        process(fallback: tr("Не получилось подготовить фото для документа.")) { engine in
            try engine.preparePassport(source: source, crop: crop, preset: documentPreset)
        }
    }
}
