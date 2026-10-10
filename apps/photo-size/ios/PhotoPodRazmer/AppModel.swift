import Foundation
import PhotosUI
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var inputKind: InputKind = .photo
    @Published var mode: ToolMode = .fileSize
    @Published var source: SourceImage?
    @Published var result: ResultImage?
    @Published var pdfSource: SourcePDF?
    @Published var pdfResult: ResultPDF?
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

    let engine = ImageEngine()
    let pdfEngine = PDFEngine()
    var activeOperationID = UUID()

    init() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--qa-photo-fixture") {
            do {
                source = try engine.inspect(data: QAFixtures.photoData())
                targetBytes = 100_000
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        if args.contains("--qa-pdf-fixture") || args.contains("--qa-pdf-result") {
            inputKind = .pdf
            do {
                let inspected = try pdfEngine.inspect(data: QAFixtures.pdfData())
                pdfSource = inspected
                targetBytes = 1_000_000
                if args.contains("--qa-pdf-result") {
                    pdfResult = try pdfEngine.compressByBytes(
                        source: inspected,
                        requestedMaximumBytes: 1_000_000
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        if let index = args.firstIndex(of: "--store-screenshot-mode"),
           args.indices.contains(index + 1) {
            switch args[index + 1] {
            case "pixels": mode = .pixels
            case "passport": mode = .passport
            case "pdf": inputKind = .pdf
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

}
