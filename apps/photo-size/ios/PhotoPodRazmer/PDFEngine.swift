import CoreGraphics
import Foundation
import PDFKit
import UIKit

final class PDFEngine {
    private let targetHeadroom = 0.985
    private let minQuality = 0.24
    private let maxQuality = 0.90
    private let renderScales: [CGFloat] = [2.0, 1.65, 1.35, 1.1, 0.9, 0.72, 0.58, 0.46]
    private let binarySearchIterations = 5

    func inspect(data: Data) throws -> SourcePDF {
        let url = try cacheURL(prefix: "source")
        try data.write(to: url, options: .atomic)
        return try inspectCachedFile(at: url, sizeBytes: Int64(data.count))
    }

    func inspect(fileURL: URL) throws -> SourcePDF {
        let url = try cacheURL(prefix: "source")
        try FileManager.default.copyItem(at: fileURL, to: url)
        return try inspectCachedFile(at: url, sizeBytes: try fileSize(of: url))
    }

    func compressByBytes(source: SourcePDF, requestedMaximumBytes: Int64) throws -> ResultPDF {
        guard requestedMaximumBytes >= 10_000 else {
            throw PhotoToolError.message(tr("Укажите допустимый размер файла."))
        }

        if source.sizeBytes <= requestedMaximumBytes {
            let url = try cacheURL(prefix: "result")
            try FileManager.default.copyItem(at: source.localURL, to: url)
            return ResultPDF(
                source: source,
                outputURL: url,
                outputSizeBytes: source.sizeBytes,
                targetBytes: requestedMaximumBytes,
                alreadyFit: true,
                previewImage: source.previewImage
            )
        }

        guard let document = PDFDocument(url: source.localURL), document.pageCount > 0 else {
            throw PhotoToolError.message(tr("Не получилось открыть этот PDF."))
        }

        let internalTarget = max(1, Int64(Double(requestedMaximumBytes) * targetHeadroom))

        for scale in renderScales {
            let minimum = try makeCandidate(
                document: document,
                scale: scale,
                jpegQuality: minQuality
            )

            guard minimum.sizeBytes <= internalTarget else {
                removeIfPresent(minimum.url)
                continue
            }

            var best = minimum
            let maximum = try makeCandidate(
                document: document,
                scale: scale,
                jpegQuality: maxQuality
            )

            if maximum.sizeBytes <= internalTarget {
                removeIfPresent(best.url)
                best = maximum
            } else {
                removeIfPresent(maximum.url)
                var low = minQuality
                var high = maxQuality

                for _ in 0..<binarySearchIterations {
                    let quality = (low + high) / 2
                    let candidate = try makeCandidate(
                        document: document,
                        scale: scale,
                        jpegQuality: quality
                    )

                    if candidate.sizeBytes <= internalTarget {
                        removeIfPresent(best.url)
                        best = candidate
                        low = quality
                    } else {
                        removeIfPresent(candidate.url)
                        high = quality
                    }
                }
            }

            let resultURL = try cacheURL(prefix: "result")
            try FileManager.default.moveItem(at: best.url, to: resultURL)
            let resultDocument = PDFDocument(url: resultURL)

            return ResultPDF(
                source: source,
                outputURL: resultURL,
                outputSizeBytes: best.sizeBytes,
                targetBytes: requestedMaximumBytes,
                alreadyFit: false,
                previewImage: resultDocument.flatMap(previewImage)
            )
        }

        throw PhotoToolError.message(tr("Не получилось уменьшить PDF до выбранного размера без слишком сильной потери качества."))
    }

    private struct RenderedPage {
        let image: UIImage
        let mediaBox: CGRect
    }

    private struct Candidate {
        let url: URL
        let sizeBytes: Int64
    }

    private func inspectCachedFile(at url: URL, sizeBytes: Int64) throws -> SourcePDF {
        guard let document = PDFDocument(url: url), document.pageCount > 0 else {
            removeIfPresent(url)
            throw PhotoToolError.message(tr("Не получилось открыть этот PDF."))
        }

        return SourcePDF(
            localURL: url,
            sizeBytes: sizeBytes,
            pageCount: document.pageCount,
            previewImage: previewImage(document)
        )
    }

    private func makeCandidate(
        document: PDFDocument,
        scale: CGFloat,
        jpegQuality: CGFloat
    ) throws -> Candidate {
        let url = try cacheURL(prefix: "candidate")
        do {
            try makePDF(
                document: document,
                scale: scale,
                jpegQuality: jpegQuality,
                outputURL: url
            )
            return Candidate(url: url, sizeBytes: try fileSize(of: url))
        } catch {
            removeIfPresent(url)
            throw error
        }
    }

    private func makePDF(
        document: PDFDocument,
        scale: CGFloat,
        jpegQuality: CGFloat,
        outputURL: URL
    ) throws {
        guard let consumer = CGDataConsumer(url: outputURL as CFURL),
              let context = CGContext(consumer: consumer, mediaBox: nil, nil) else {
            throw PhotoToolError.message(tr("Не получилось создать PDF."))
        }

        for index in 0..<document.pageCount {
            try autoreleasepool {
                guard let page = document.page(at: index) else {
                    throw PhotoToolError.message(tr("Не получилось прочитать страницу PDF."))
                }

                let renderedPage = renderPage(page, scale: scale, pageCount: document.pageCount)

                guard let jpeg = renderedPage.image.jpegData(compressionQuality: jpegQuality),
                      let compressedImage = UIImage(data: jpeg)?.cgImage else {
                    throw PhotoToolError.message(tr("Не получилось сжать страницу PDF."))
                }

                var mediaBox = CGRect(
                    x: 0,
                    y: 0,
                    width: renderedPage.mediaBox.width,
                    height: renderedPage.mediaBox.height
                )
                let pageInfo = [
                    kCGPDFContextMediaBox as String:
                        NSData(bytes: &mediaBox, length: MemoryLayout<CGRect>.size)
                ] as CFDictionary

                context.beginPDFPage(pageInfo)
                context.draw(compressedImage, in: mediaBox)
                context.endPDFPage()
            }
        }

        context.closePDF()
    }

    private func renderPage(
        _ page: PDFPage,
        scale: CGFloat,
        pageCount: Int
    ) -> RenderedPage {
        let box = page.bounds(for: .mediaBox)
        let pageCountScale = min(1, sqrt(12 / CGFloat(max(pageCount, 1))))
        let memoryAwareScale = scale * pageCountScale
        let maxSide = max(box.width, box.height)
        let boundedScale = min(memoryAwareScale, 2400 / max(maxSide, 1))
        let pixelSize = CGSize(
            width: max(1, floor(box.width * boundedScale)),
            height: max(1, floor(box.height * boundedScale))
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: pixelSize, format: format)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: pixelSize))
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: 0, y: pixelSize.height)
            context.cgContext.scaleBy(x: boundedScale, y: -boundedScale)
            page.draw(with: .mediaBox, to: context.cgContext)
            context.cgContext.restoreGState()
        }

        return RenderedPage(image: image, mediaBox: box)
    }

    private func previewImage(_ document: PDFDocument) -> UIImage? {
        guard let page = document.page(at: 0) else { return nil }
        return page.thumbnail(of: CGSize(width: 480, height: 640), for: .mediaBox)
    }

    private func fileSize(of url: URL) throws -> Int64 {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        guard let size = values.fileSize else {
            throw PhotoToolError.message(tr("Не получилось определить размер PDF."))
        }
        return Int64(size)
    }

    private func removeIfPresent(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private func cacheURL(prefix: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PhotoPodRazmerPDF", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("\(prefix)-\(UUID().uuidString).pdf")
    }
}
