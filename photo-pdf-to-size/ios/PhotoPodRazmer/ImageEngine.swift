import CoreGraphics
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

final class ImageEngine {
    private let maxDecodePixels: Int64 = 24_000_000
    private let minJPEGQuality = 35
    private let maxJPEGQuality = 95
    private let minShortSide = 480
    private let maxResizeRounds = 8
    private let targetHeadroom = 0.985

    func inspect(data: Data) throws -> SourceImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0 else {
            throw PhotoToolError.message(tr("Не получилось открыть это изображение."))
        }

        let typeIdentifier = CGImageSourceGetType(source) as String?
        let contentType = typeIdentifier.flatMap(UTType.init(_:)) ?? .image
        let allowed = ["public.jpeg", "public.png", "public.heic", "public.heif", "org.webmproject.webp"]
        guard allowed.contains(contentType.identifier) || contentType.conforms(to: .image) else {
            throw PhotoToolError.message(tr("Этот формат пока не поддерживается."))
        }

        guard let raw = UIImage(data: data) else {
            throw PhotoToolError.message(tr("Не получилось открыть это изображение."))
        }
        let image = try normalizedImage(raw)
        guard let cg = image.cgImage else {
            throw PhotoToolError.message(tr("Не получилось определить размер изображения."))
        }

        let ext = contentType.preferredFilenameExtension ?? "img"
        let url = try cacheURL(fileExtension: ext, prefix: "source")
        try data.write(to: url, options: .atomic)

        return SourceImage(
            data: data,
            image: image,
            localURL: url,
            sizeBytes: Int64(data.count),
            width: cg.width,
            height: cg.height,
            contentType: contentType,
            fileExtension: ext
        )
    }

    func compressByBytes(source: SourceImage, requestedMaximumBytes: Int64, stripMetadata: Bool = true) throws -> ResultImage {
        guard requestedMaximumBytes > 0 else {
            throw PhotoToolError.message(tr("Укажите допустимый размер файла."))
        }
        if source.sizeBytes <= requestedMaximumBytes && !stripMetadata {
            return originalResult(source: source, mode: .fileSize, targetBytes: requestedMaximumBytes)
        }

        let metadata = stripMetadata ? nil : preservedMetadata(from: source)
        let internalTarget = max(1, Int64(Double(requestedMaximumBytes) * targetHeadroom))
        var working = try processingImage(source)

        for round in 0...maxResizeRounds {
            let search = try searchBestQuality(image: working, targetBytes: internalTarget, metadata: metadata)
            if let bytes = search.bestBytes {
                guard Int64(bytes.count) <= requestedMaximumBytes else {
                    throw PhotoToolError.message(tr("Не получилось уменьшить файл до выбранного размера."))
                }
                let url = try writeResult(bytes)
                return ResultImage(
                    source: source,
                    outputURL: url,
                    outputSizeBytes: Int64(bytes.count),
                    outputWidth: Int(working.size.width),
                    outputHeight: Int(working.size.height),
                    mode: .fileSize,
                    targetBytes: requestedMaximumBytes,
                    targetLongSide: nil,
                    alreadyFit: false,
                    contentType: .jpeg,
                    documentPreset: nil,
                    printSheet: nil
                )
            }

            guard round < maxResizeRounds else { break }
            let shortSide = min(working.size.width, working.size.height)
            guard shortSide > CGFloat(minShortSide) else { break }

            let ratio = sqrt(Double(internalTarget) / Double(max(search.minimumQualityBytes, 1))) * 0.92
            var scale = min(0.88, max(0.50, ratio))
            if Double(shortSide) * scale < Double(minShortSide) {
                scale = Double(minShortSide) / Double(shortSide)
            }
            if scale >= 0.99 { scale = 0.88 }

            let size = CGSize(
                width: max(1, (working.size.width * scale).rounded(.down)),
                height: max(1, (working.size.height * scale).rounded(.down))
            )
            working = try resizedImage(working, to: size)
        }

        throw PhotoToolError.message(
            tr("Не получилось уменьшить изображение до выбранного размера без заметной потери качества.")
        )
    }

    func resizeLongSide(source: SourceImage, targetLongSide: Int, format: ExportImageFormat = .jpeg, stripMetadata: Bool = true) throws -> ResultImage {
        guard targetLongSide > 0 else {
            throw PhotoToolError.message(tr("Укажите размер длинной стороны."))
        }
        if max(source.width, source.height) <= targetLongSide,
           source.contentType == format.contentType,
           !stripMetadata {
            return originalResult(source: source, mode: .pixels, targetLongSide: targetLongSide)
        }

        let working = try processingImage(source)
        let target = calculateLongSideDimensions(
            width: Int(working.size.width),
            height: Int(working.size.height),
            targetLongSide: targetLongSide
        )
        let resized = try resizedImage(
            working,
            to: CGSize(width: target.width, height: target.height)
        )
        let bytes = try encodedData(image: resized, format: format, metadata: stripMetadata ? nil : preservedMetadata(from: source))
        let url = try writeResult(bytes, fileExtension: format.fileExtension)

        return ResultImage(
            source: source,
            outputURL: url,
            outputSizeBytes: Int64(bytes.count),
            outputWidth: target.width,
            outputHeight: target.height,
            mode: .pixels,
            targetBytes: nil,
            targetLongSide: targetLongSide,
            alreadyFit: false,
            contentType: format.contentType,
            documentPreset: nil,
            printSheet: nil
        )
    }

    func resizeExact(source: SourceImage, width: Int, height: Int, format: ExportImageFormat = .jpeg, stripMetadata: Bool = true) throws -> ResultImage {
        guard (32...12_000).contains(width), (32...12_000).contains(height) else {
            throw PhotoToolError.message(tr("Укажите ширину и высоту от 32 до 12000 px."))
        }
        guard width <= source.width, height <= source.height else {
            throw PhotoToolError.message(tr("Целевой размер не должен быть больше исходного изображения."))
        }
        if source.width == width && source.height == height,
           source.contentType == format.contentType,
           !stripMetadata {
            return originalResult(source: source, mode: .pixels)
        }

        let working = try processingImage(source)
        let resized = try resizedImage(working, to: CGSize(width: width, height: height))
        let bytes = try encodedData(image: resized, format: format, metadata: stripMetadata ? nil : preservedMetadata(from: source))
        let url = try writeResult(bytes, fileExtension: format.fileExtension)

        return ResultImage(
            source: source,
            outputURL: url,
            outputSizeBytes: Int64(bytes.count),
            outputWidth: width,
            outputHeight: height,
            mode: .pixels,
            targetBytes: nil,
            targetLongSide: nil,
            alreadyFit: false,
            contentType: format.contentType,
            documentPreset: nil,
            printSheet: nil
        )
    }

    func preparePassport(source: SourceImage, crop: NormalizedCropRect, preset: DocumentPhotoPreset = .russiaPassport) throws -> ResultImage {
        let working = try processingImage(source)
        guard let cg = working.cgImage else {
            throw PhotoToolError.message(tr("Не получилось подготовить фото для документа."))
        }

        let left = max(0, min(CGFloat(cg.width - 1), crop.left * CGFloat(cg.width)))
        let top = max(0, min(CGFloat(cg.height - 1), crop.top * CGFloat(cg.height)))
        let right = max(left + 1, min(CGFloat(cg.width), crop.right * CGFloat(cg.width)))
        let bottom = max(top + 1, min(CGFloat(cg.height), crop.bottom * CGFloat(cg.height)))
        let rect = CGRect(x: left, y: top, width: right - left, height: bottom - top).integral

        guard let croppedCG = cg.cropping(to: rect) else {
            throw PhotoToolError.message(tr("Не получилось обрезать изображение."))
        }
        let cropped = UIImage(cgImage: croppedCG, scale: 1, orientation: .up)
        let passport = try resizedImage(
            cropped,
            to: CGSize(width: preset.widthPixels, height: preset.heightPixels)
        )

        var quality = try bestQuality(
            image: passport,
            maximumBytes: preset.maximumBytes,
            minimumQuality: 55,
            maximumQuality: 95
        )
        var bytes = try jpegData(
            image: passport,
            quality: CGFloat(quality) / 100,
            dpi: preset.dpi
        )

        if preset.minimumBytes > 0 && bytes.count < preset.minimumBytes {
            quality = 100
            bytes = try jpegData(image: passport, quality: 1.0, dpi: preset.dpi)
        }
        guard bytes.count >= preset.minimumBytes && bytes.count <= preset.maximumBytes else {
            throw PhotoToolError.message(tr("Не получилось подготовить файл нужного размера для заявления."))
        }

        let url = try writeResult(bytes)
        let printSheet = try preset.printSheetSpec.map { spec in
            try makePrintSheet(image: passport, spec: spec)
        }
        return ResultImage(
            source: source,
            outputURL: url,
            outputSizeBytes: Int64(bytes.count),
            outputWidth: preset.widthPixels,
            outputHeight: preset.heightPixels,
            mode: .passport,
            targetBytes: nil,
            targetLongSide: nil,
            alreadyFit: false,
            contentType: .jpeg,
            documentPreset: preset,
            printSheet: printSheet
        )
    }

    private func originalResult(
        source: SourceImage,
        mode: ToolMode,
        targetBytes: Int64? = nil,
        targetLongSide: Int? = nil
    ) -> ResultImage {
        ResultImage(
            source: source,
            outputURL: source.localURL,
            outputSizeBytes: source.sizeBytes,
            outputWidth: source.width,
            outputHeight: source.height,
            mode: mode,
            targetBytes: targetBytes,
            targetLongSide: targetLongSide,
            alreadyFit: true,
            contentType: source.contentType,
            documentPreset: nil,
            printSheet: nil
        )
    }

    private func makePrintSheet(image: UIImage, spec: PrintSheetSpec) throws -> PrintSheetResult {
        let photo = try resizedImage(
            image,
            to: CGSize(width: spec.photoWidthPixels, height: spec.photoHeightPixels)
        )
        let sheetSize = CGSize(width: spec.widthPixels, height: spec.heightPixels)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let sheet = UIGraphicsImageRenderer(size: sheetSize, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: sheetSize))
            let usedWidth = spec.columns * spec.photoWidthPixels
            let usedHeight = spec.rows * spec.photoHeightPixels
            let gapX = CGFloat(max(0, spec.widthPixels - usedWidth)) / CGFloat(spec.columns + 1)
            let gapY = CGFloat(max(0, spec.heightPixels - usedHeight)) / CGFloat(spec.rows + 1)
            for row in 0..<spec.rows {
                for column in 0..<spec.columns {
                    let x = gapX + CGFloat(column) * (CGFloat(spec.photoWidthPixels) + gapX)
                    let y = gapY + CGFloat(row) * (CGFloat(spec.photoHeightPixels) + gapY)
                    photo.draw(in: CGRect(
                        x: x,
                        y: y,
                        width: CGFloat(spec.photoWidthPixels),
                        height: CGFloat(spec.photoHeightPixels)
                    ))
                }
            }
        }
        let data = try jpegData(image: sheet, quality: 0.97, dpi: spec.dpi)
        let url = try writeResult(data, fileExtension: "jpg")
        return PrintSheetResult(
            outputURL: url,
            widthPixels: spec.widthPixels,
            heightPixels: spec.heightPixels,
            dpi: spec.dpi,
            copies: spec.copies,
            label: spec.label
        )
    }

    private func processingImage(_ source: SourceImage) throws -> UIImage {
        let pixels = Int64(source.width) * Int64(source.height)
        guard pixels > maxDecodePixels,
              let imageSource = CGImageSourceCreateWithData(source.data as CFData, nil) else {
            return try flattenedImage(source.image)
        }

        let scale = sqrt(Double(maxDecodePixels) / Double(pixels))
        let maxDimension = Int(Double(max(source.width, source.height)) * scale)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            throw PhotoToolError.message(tr("Изображение слишком большое для обработки на этом устройстве."))
        }
        return try flattenedImage(UIImage(cgImage: cg, scale: 1, orientation: .up))
    }

    private func normalizedImage(_ image: UIImage) throws -> UIImage {
        guard image.imageOrientation != .up || image.scale != 1 else {
            return image
        }
        guard let cg = image.cgImage else {
            throw PhotoToolError.message(tr("Не получилось открыть это изображение."))
        }

        let swapsSides: Bool
        switch image.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored: swapsSides = true
        default: swapsSides = false
        }
        let size = swapsSides
            ? CGSize(width: cg.height, height: cg.width)
            : CGSize(width: cg.width, height: cg.height)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private func flattenedImage(_ image: UIImage) throws -> UIImage {
        guard let cg = image.cgImage else {
            throw PhotoToolError.message(tr("Не получилось обработать это изображение."))
        }
        let size = CGSize(width: cg.width, height: cg.height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private func resizedImage(_ image: UIImage, to size: CGSize) throws -> UIImage {
        guard size.width >= 1, size.height >= 1 else {
            throw PhotoToolError.message(tr("Не получилось изменить размер изображения."))
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private struct QualitySearch {
        let bestBytes: Data?
        let minimumQualityBytes: Int
    }

    private func searchBestQuality(image: UIImage, targetBytes: Int64, metadata: [CFString: Any]? = nil) throws -> QualitySearch {
        let minimum = try jpegData(image: image, quality: CGFloat(minJPEGQuality) / 100, metadata: metadata)
        if Int64(minimum.count) > targetBytes {
            return QualitySearch(bestBytes: nil, minimumQualityBytes: minimum.count)
        }

        var best = minimum
        var low = minJPEGQuality + 1
        var high = maxJPEGQuality
        while low <= high {
            let quality = (low + high) / 2
            let encoded = try jpegData(image: image, quality: CGFloat(quality) / 100, metadata: metadata)
            if Int64(encoded.count) <= targetBytes {
                best = encoded
                low = quality + 1
            } else {
                high = quality - 1
            }
        }
        return QualitySearch(bestBytes: best, minimumQualityBytes: minimum.count)
    }

    private func bestQuality(
        image: UIImage,
        maximumBytes: Int,
        minimumQuality: Int,
        maximumQuality: Int
    ) throws -> Int {
        let highest = try jpegData(image: image, quality: CGFloat(maximumQuality) / 100)
        if highest.count <= maximumBytes { return maximumQuality }

        let lowest = try jpegData(image: image, quality: CGFloat(minimumQuality) / 100)
        guard lowest.count <= maximumBytes else {
            throw PhotoToolError.message(tr("Не получилось уменьшить файл до допустимого размера."))
        }

        var best = minimumQuality
        var low = minimumQuality + 1
        var high = maximumQuality - 1
        while low <= high {
            let quality = (low + high) / 2
            let data = try jpegData(image: image, quality: CGFloat(quality) / 100)
            if data.count <= maximumBytes {
                best = quality
                low = quality + 1
            } else {
                high = quality - 1
            }
        }
        return best
    }

    private func encodedData(image: UIImage, format: ExportImageFormat, metadata: [CFString: Any]? = nil) throws -> Data {
        switch format {
        case .jpeg:
            return try jpegData(image: image, quality: 0.95, metadata: metadata)
        case .png:
            return try imageData(image: image, type: .png, quality: nil, metadata: metadata)
        case .heic:
            return try imageData(image: image, type: .heic, quality: 0.92, metadata: metadata)
        }
    }

    private func imageData(image: UIImage, type: UTType, quality: CGFloat?, metadata: [CFString: Any]? = nil) throws -> Data {
        guard let cg = image.cgImage else {
            throw PhotoToolError.message(tr("Не получилось создать файл выбранного формата."))
        }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            type.identifier as CFString,
            1,
            nil
        ) else {
            throw PhotoToolError.message(tr("Не получилось создать файл выбранного формата."))
        }
        var properties: [CFString: Any] = metadata ?? [:]
        if let quality {
            properties[kCGImageDestinationLossyCompressionQuality] = quality
        }
        CGImageDestinationAddImage(destination, cg, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw PhotoToolError.message(tr("Не получилось создать файл выбранного формата."))
        }
        return data as Data
    }

    private func jpegData(image: UIImage, quality: CGFloat, dpi: Int? = nil, metadata: [CFString: Any]? = nil) throws -> Data {
        guard let cg = image.cgImage else {
            throw PhotoToolError.message(tr("Не получилось создать JPG."))
        }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw PhotoToolError.message(tr("Не получилось создать JPG."))
        }

        var properties: [CFString: Any] = metadata ?? [:]
        properties[kCGImageDestinationLossyCompressionQuality] = quality
        if let dpi {
            properties[kCGImagePropertyDPIWidth] = dpi
            properties[kCGImagePropertyDPIHeight] = dpi
        }

        CGImageDestinationAddImage(destination, cg, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw PhotoToolError.message(tr("Не получилось создать JPG."))
        }
        return data as Data
    }

    private func preservedMetadata(from source: SourceImage) -> [CFString: Any]? {
        guard let imageSource = CGImageSourceCreateWithData(source.data as CFData, nil),
              let raw = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            return nil
        }

        var metadata = raw
        metadata.removeValue(forKey: kCGImagePropertyPixelWidth)
        metadata.removeValue(forKey: kCGImagePropertyPixelHeight)
        metadata.removeValue(forKey: kCGImagePropertyOrientation)
        metadata.removeValue(forKey: kCGImagePropertyHasAlpha)
        return metadata
    }

    private func cacheURL(fileExtension: String, prefix: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PhotoPodRazmer", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("\(prefix)-\(UUID().uuidString).\(fileExtension)")
    }

    private func writeResult(_ data: Data, fileExtension: String = "jpg") throws -> URL {
        let url = try cacheURL(fileExtension: fileExtension, prefix: "result")
        try data.write(to: url, options: .atomic)
        return url
    }
}
