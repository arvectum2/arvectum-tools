import Foundation
import PhotosUI
import SwiftUI

@MainActor
extension AppModel {
    func setMode(_ newMode: ToolMode) {
        invalidateOperation()
        mode = newMode
        result = nil
        passportCropOpen = false
        saved = false
        errorMessage = nil
    }

    func setInputKind(_ kind: InputKind) {
        invalidateOperation()
        inputKind = kind
        result = nil
        pdfResult = nil
        passportCropOpen = false
        saved = false
        errorMessage = nil
    }
}
