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
        case .passport: return tr("На документы")
        }
    }
}

enum PixelResizeMode: String, CaseIterable, Identifiable {
    case longSide
    case exact

    var id: String { rawValue }

    var title: String {
        switch self {
        case .longSide: return tr("Длинная сторона")
        case .exact: return tr("Точно W×H")
        }
    }
}

enum ExportImageFormat: String, CaseIterable, Identifiable {
    case jpeg
    case png
    case heic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .jpeg: return "JPEG"
        case .png: return "PNG"
        case .heic: return "HEIC"
        }
    }

    var contentType: UTType {
        switch self {
        case .jpeg: return .jpeg
        case .png: return .png
        case .heic: return .heic
        }
    }

    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        case .heic: return "heic"
        }
    }
}

enum DocumentPhotoPreset: String, CaseIterable, Identifiable, Equatable {
    case russiaPassport
    case usPassportPrint
    case usVisaDigital
    case indiaEVisa
    case ukPassportPrint

    var id: String { rawValue }

    var title: String {
        switch self {
        case .russiaPassport: return tr("Россия · паспорт")
        case .usPassportPrint: return tr("США · паспорт (печать)")
        case .usVisaDigital: return tr("США · виза (digital)")
        case .indiaEVisa: return tr("Индия · e-Visa")
        case .ukPassportPrint: return tr("Великобритания · паспорт (печать)")
        }
    }

    var widthPixels: Int {
        switch self {
        case .russiaPassport: return 620
        case .usPassportPrint, .usVisaDigital: return 600
        case .indiaEVisa: return 900
        case .ukPassportPrint: return 413
        }
    }

    var heightPixels: Int {
        switch self {
        case .russiaPassport: return 797
        case .usPassportPrint, .usVisaDigital, .indiaEVisa: return widthPixels
        case .ukPassportPrint: return 531
        }
    }

    var dpi: Int? {
        switch self {
        case .russiaPassport: return 450
        case .usPassportPrint, .usVisaDigital, .ukPassportPrint: return 300
        case .indiaEVisa: return nil
        }
    }

    var minimumBytes: Int {
        switch self {
        case .russiaPassport, .indiaEVisa: return 10_000
        default: return 0
        }
    }

    var maximumBytes: Int {
        switch self {
        case .usVisaDigital: return 240_000
        case .indiaEVisa: return 1_000_000
        default: return 5_000_000
        }
    }

    var outputSummary: String {
        switch self {
        case .russiaPassport:
            return "35×45 mm · 620×797 px · 450 DPI · JPEG"
        case .usPassportPrint:
            return "2×2 in · 600×600 px · 300 DPI · JPEG"
        case .usVisaDigital:
            return tr("600×600 px · JPEG · ≤240 KB")
        case .indiaEVisa:
            return tr("900×900 px · JPEG · 10 KB–1 MB")
        case .ukPassportPrint:
            return "35×45 mm · 413×531 px · 300 DPI · JPEG"
        }
    }

    var guidance: String {
        switch self {
        case .russiaPassport:
            return tr("Кадрирование вручную. Лицо и фон приложение не изменяет.")
        case .usPassportPrint:
            return tr("Формат для печати 2×2 дюйма. Проверьте размер головы перед подачей.")
        case .usVisaDigital:
            return tr("Цифровое фото для визы США: квадратный JPEG до 240 КБ.")
        case .indiaEVisa:
            return tr("Для India e-Visa: квадратный JPEG от 10 КБ до 1 МБ.")
        case .ukPassportPrint:
            return tr("Формат для печати 35×45 мм. Для онлайн-паспорта GOV.UK просит не обрезать фото самостоятельно.")
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
    let documentPreset: DocumentPhotoPreset?

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
