import Foundation
import UIKit
import UniformTypeIdentifiers

func tr(_ key: String) -> String {
    Bundle.main.localizedString(forKey: key, value: key, table: nil)
}

enum ToolMode: String, CaseIterable, Identifiable {
    case fileSize
    case pixels
    case passport

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fileSize: return tr("По весу")
        case .pixels: return tr("По размеру")
        case .passport: return tr("На паспорт")
        }
    }
}

enum SizeUnit: String, CaseIterable, Identifiable {
    case kb = "КБ"
    case mb = "МБ"

    var id: String { rawValue }
    var multiplier: Int64 { self == .kb ? 1_000 : 1_000_000 }
}

struct NormalizedCropRect {
    let left: CGFloat
    let top: CGFloat
    let right: CGFloat
    let bottom: CGFloat
}

struct SourceImage {
    let data: Data
    let image: UIImage
    let localURL: URL
    let sizeBytes: Int64
    let width: Int
    let height: Int
    let contentType: UTType
    let fileExtension: String
}

struct ResultImage {
    let source: SourceImage
    let outputURL: URL
    let outputSizeBytes: Int64
    let outputWidth: Int
    let outputHeight: Int
    let mode: ToolMode
    let targetBytes: Int64?
    let targetLongSide: Int?
    let alreadyFit: Bool
    let contentType: UTType

    var suggestedFileName: String {
        let suffix: String
        switch mode {
        case .fileSize: suffix = tr("filename.file_size")
        case .pixels: suffix = tr("filename.pixels")
        case .passport: suffix = tr("filename.passport")
        }
        return "foto-\(suffix).\(contentType.preferredFilenameExtension ?? "jpg")"
    }
}

struct ImageDimensions: Equatable {
    let width: Int
    let height: Int
}

func calculateLongSideDimensions(width: Int, height: Int, targetLongSide: Int) -> ImageDimensions {
    precondition(width > 0 && height > 0 && targetLongSide > 0)
    if width >= height {
        return ImageDimensions(
            width: targetLongSide,
            height: max(1, Int((Double(height) * Double(targetLongSide) / Double(width)).rounded()))
        )
    }
    return ImageDimensions(
        width: max(1, Int((Double(width) * Double(targetLongSide) / Double(height)).rounded())),
        height: targetLongSide
    )
}

func formatBytes(_ bytes: Int64) -> String {
    if bytes >= 1_000_000 {
        let value = Double(bytes) / 1_000_000
        let format = tr(value >= 10 ? "%.1f МБ" : "%.2f МБ")
        return String(format: format, locale: Locale.current, value)
    }
    return String(format: tr("%.0f КБ"), locale: Locale.current, Double(bytes) / 1_000)
}

enum PhotoToolError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let text): return text
        }
    }
}
