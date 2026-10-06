import CoreGraphics
import Foundation
import PDFKit
import UIKit

final class PDFEngine {
    private let targetHeadroom = 0.985
    private let minQuality = 0.24
    private let maxQuality = 0.90
    private let renderScales: [CGFloat] = [2.0, 1.65, 1.35, 1.1, 0.9, 0.72, 0.58, 0.46]

    func inspect(data: Data) throws -> SourcePDF {
        guard let document = PDFDocument(data: data), document.pageCount > 0 else {
            throw PhotoToolError.message(tr("Не получилось открыть этот PDF."))
        }
        let url = try cacheURL(prefix: "source")
        try data.write(to: url, options: .atomic)
        return SourcePDF(
            data: data,
            localURL: url,
            sizeBytes: Int64(data.count),
            pageCount: document.pageCount,
            previewImage: previewImage(document)
        )
    }

    func compressByBytes(source: SourcePDF, requestedMaximumBytes: Int64) throws -> ResultPDF {
        guard requestedMaximumBytes >= 10_000 else {
            throw PhotoToolError.message(tr("Укажите допустимый размер файла."))
        }

        if source.sizeBytes <= requestedMaximumBytes {
            let url = try cacheURL(prefix: "result")
            try source.data.write(to: url, options: .atomic)
            return ResultPDF(
                source: source,
                outputURL: url,
                outputSizeBytes: source.sizeBytes,
                targetBytes: requestedMaximumBytes,
                alreadyFit: true,
                previewImage: source.previewImage
            )
        }

        guard let document = PDFDocument(data: source.data) else {
            throw PhotoToolError.message(tr("Не получилось открыть этот PDF."))
        }

        let internalTarget = max(1, Int64(Double(requestedMaximumBytes) * targetHeadroom))
        var smallest: Data?

        for scale in renderScales {
            autoreleasepool {
                guard let pages = try? renderPages(document: document, scale: scale), !pages.isEmpty else { return }
                var low = minQuality
                var high = maxQuality
                var best: Data?

                for _ in 0..<7 {
                    let quality = (low + high) / 2
                    guard let candidate = try? makePDF(pages: pages, jpegQuality: quality) else { break }
                    if smallest == nil || candidate.count < smallest!.count { smallest = candidate }

                    if Int64(candidate.count) <= internalTarget {
                        best = candidate
                        low = quality
                    } else {
                        high = quality
                    }
                }

                if best == nil, let candidate = try? makePDF(pages: pages, jpegQuality: minQuality),
                   Int64(candidate.count) <= internalTarget {
                    best = candidate
                }

                if let best, Int64(best.count) <= requestedMaximumBytes {
                    smallest = best
                } else {
                    smallest = nil
                }
            }

            if let data = smallest, Int64(data.count) <= requestedMaximumBytes {
                let url = try cacheURL(prefix: "result")
                try data.write(to: url, options: .atomic)
                let resultDocument = PDFDocument(data: data)
                return ResultPDF(
                    source: source,
                    outputURL: url,
                    outputSizeBytes: Int64(data.count),
                    targetBytes: requestedMaximumBytes,
                    alreadyFit: false,
                    previewImage: resultDocument.flatMap(previewImage)
                )
            }
        }

        throw PhotoToolError.message(tr("Не получилось уменьшить PDF до выбранного размера без слишком сильной потери качества."))
    }

    private struct RenderedPage {
        let image: UIImage
        let mediaBox: CGRect
    }

    private func renderPages(document: PDFDocument, scale: CGFloat) throws -> [RenderedPage] {
        var pages: [RenderedPage] = []
        pages.reserveCapacity(document.pageCount)

        let pageCountScale = min(1, sqrt(12 / CGFloat(max(document.pageCount, 1))))
        let memoryAwareScale = scale * pageCountScale

        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let box = page.bounds(for: .mediaBox)
            let maxSide = max(box.width, box.height)
            let boundedScale = min(memoryAwareScale, 2400 / max(maxSide, 1))
            let pixelSize = CGSize(
                width: max(1, floor(box.width * boundedScale)),
                height: max(1, floor(box.height * boundedScale))
            )

            let renderer = UIGraphicsImageRenderer(size: pixelSize)
            let image = renderer.image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: pixelSize))
                context.cgContext.saveGState()
                context.cgContext.translateBy(x: 0, y: pixelSize.height)
                context.cgContext.scaleBy(x: boundedScale, y: -boundedScale)
                page.draw(with: .mediaBox, to: context.cgContext)
                context.cgContext.restoreGState()
            }
            pages.append(RenderedPage(image: image, mediaBox: box))
        }

        guard !pages.isEmpty else {
            throw PhotoToolError.message(tr("PDF не содержит страниц."))
        }
        return pages
    }

    private func makePDF(pages: [RenderedPage], jpegQuality: CGFloat) throws -> Data {
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: nil, nil) else {
            throw PhotoToolError.message(tr("Не получилось создать PDF."))
        }

        for page in pages {
            guard let jpeg = page.image.jpegData(compressionQuality: jpegQuality),
                  let compressedImage = UIImage(data: jpeg)?.cgImage else {
                throw PhotoToolError.message(tr("Не получилось сжать страницу PDF."))
            }

            var mediaBox = CGRect(x: 0, y: 0, width: page.mediaBox.width, height: page.mediaBox.height)
            let pageInfo = [kCGPDFContextMediaBox as String: NSData(bytes: &mediaBox, length: MemoryLayout<CGRect>.size)] as CFDictionary
            context.beginPDFPage(pageInfo)
            context.draw(compressedImage, in: mediaBox)
            context.endPDFPage()
        }
        context.closePDF()
        return data as Data
    }

    private func previewImage(_ document: PDFDocument) -> UIImage? {
        guard let page = document.page(at: 0) else { return nil }
        return page.thumbnail(of: CGSize(width: 480, height: 640), for: .mediaBox)
    }

    private func cacheURL(prefix: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PhotoPodRazmerPDF", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("\(prefix)-\(UUID().uuidString).pdf")
    }
}
