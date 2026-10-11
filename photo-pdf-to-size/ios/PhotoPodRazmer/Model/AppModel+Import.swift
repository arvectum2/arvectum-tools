import Foundation
import PhotosUI
import SwiftUI

@MainActor
extension AppModel {
    func selectPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        let operationID = beginOperation()
        isWorking = true
        errorMessage = nil
        result = nil
        saved = false
        passportCropOpen = false
        source = nil

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw PhotoToolError.message(tr("Не получилось прочитать выбранное фото."))
                }
                let engine = self.engine
                let inspected = try await Task.detached(priority: .userInitiated) {
                    try engine.inspect(data: data)
                }.value
                guard isCurrentOperation(operationID) else { return }
                source = inspected
                syncExactDimensionsAfterSource()
                isWorking = false
            } catch {
                guard isCurrentOperation(operationID) else { return }
                source = nil
                isWorking = false
                errorMessage = userMessage(error, fallback: tr("Не получилось открыть этот файл."))
            }
        }
    }

    func selectFile(_ url: URL) {
        let operationID = beginOperation()
        isWorking = true
        errorMessage = nil
        result = nil
        saved = false
        passportCropOpen = false
        source = nil

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
                guard isCurrentOperation(operationID) else { return }
                source = inspected
                syncExactDimensionsAfterSource()
                isWorking = false
            } catch {
                guard isCurrentOperation(operationID) else { return }
                source = nil
                isWorking = false
                errorMessage = userMessage(error, fallback: tr("Не получилось открыть этот файл."))
            }
        }
    }

    func selectPDFFile(_ url: URL) {
        let operationID = beginOperation()
        isWorking = true
        errorMessage = nil
        pdfResult = nil
        saved = false
        pdfSource = nil

        Task {
            do {
                let pdfEngine = self.pdfEngine
                let inspected = try await Task.detached(priority: .userInitiated) {
                    let hasAccess = url.startAccessingSecurityScopedResource()
                    defer {
                        if hasAccess { url.stopAccessingSecurityScopedResource() }
                    }
                    return try pdfEngine.inspect(fileURL: url)
                }.value
                guard isCurrentOperation(operationID) else { return }
                pdfSource = inspected
                isWorking = false
            } catch {
                guard isCurrentOperation(operationID) else { return }
                pdfSource = nil
                isWorking = false
                errorMessage = userMessage(error, fallback: tr("Не получилось открыть этот PDF."))
            }
        }
    }
}
