import Foundation
import PhotosUI
import SwiftUI

@MainActor
extension AppModel {
    // A selection, mode change or reset invalidates all previous async completions.
    // Expensive work may finish, but stale results must never appear in the UI.
    func beginOperation() -> UUID {
        let identifier = UUID()
        activeOperationID = identifier
        return identifier
    }

    func invalidateOperation() {
        activeOperationID = UUID()
        isWorking = false
    }

    func isCurrentOperation(_ identifier: UUID) -> Bool {
        activeOperationID == identifier
    }

    func process(
        fallback: String,
        operation: @escaping (ImageEngine) throws -> ResultImage
    ) {
        let operationID = beginOperation()
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
                guard isCurrentOperation(operationID) else { return }
                result = output
                isWorking = false
            } catch {
                guard isCurrentOperation(operationID) else { return }
                isWorking = false
                errorMessage = userMessage(error, fallback: fallback)
            }
        }
    }

    func cleanPixelDimension(_ value: String) -> String {
        InputConstraints.cleanPixels(value)
    }

    func validPixelDimension(_ value: String) -> Int? {
        InputConstraints.validPixels(value)
    }

    func syncExactDimensionsAfterSource() {
        guard keepPixelAspectRatio, let source else { return }
        if let width = exactWidth {
            let height = max(1, Int((Double(width) * Double(source.height) / Double(source.width)).rounded()))
            exactHeightValue = String(min(height, 12_000))
        } else if let height = exactHeight {
            let width = max(1, Int((Double(height) * Double(source.width) / Double(source.height)).rounded()))
            exactWidthValue = String(min(width, 12_000))
        }
    }

    func parseCustomTarget() -> Int64? {
        InputConstraints.parseBytes(customValue, unit: customUnit)
    }

    func userMessage(_ error: Error, fallback: String) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription {
            return description
        }
        return fallback
    }
}
