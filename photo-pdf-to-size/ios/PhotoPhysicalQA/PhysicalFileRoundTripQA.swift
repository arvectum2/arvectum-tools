#if DEBUG && PHOTO_PHYSICAL_QA
import Foundation
import PDFKit

/// Runs ONLY for the isolated QA app and one strictly-named sample in its
/// private Documents directory. Doesn't read Files Recents or Photos.
@MainActor
enum PhysicalFileRoundTripQA {
    struct Record: Codable {
        var status: String
        var inputBytes: Int
        var outputBytes: Int
        var inputPages: Int
        var outputPages: Int
        var alreadyFit: Bool
        var error: String
    }

    static func run(engine: PDFEngine) {
        guard Bundle.main.bundleIdentifier == "ru.arvectum.tools.tosize.physicalqa" else { return }
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let input = dir.appendingPathComponent("ARVECTUM_QA_LARGE_INPUT.pdf")
        let output = dir.appendingPathComponent("ARVECTUM_QA_OUTPUT.pdf")
        let report = dir.appendingPathComponent("ARVECTUM_QA_RESULT.json")
        var result = Record(status: "failed", inputBytes: 0, outputBytes: 0,
                            inputPages: 0, outputPages: 0, alreadyFit: false, error: "")
        defer {
            if let data = try? JSONEncoder().encode(result) {
                try? data.write(to: report, options: .atomic)
            }
        }
        do {
            let source = try engine.inspect(fileURL: input)
            let compressed = try engine.compressByBytes(
                source: source, requestedMaximumBytes: 500_000
            )
            let data = try Data(contentsOf: compressed.outputURL)
            guard let pdf = PDFDocument(data: data),
                  pdf.pageCount == source.pageCount,
                  !compressed.alreadyFit,
                  data.count <= 500_000 else {
                result.error = "File failed page-count, reduction, or size validation"
                return
            }
            try data.write(to: output, options: .atomic)
            result.inputBytes = Int(source.sizeBytes)
            result.outputBytes = data.count
            result.inputPages = source.pageCount
            result.outputPages = pdf.pageCount
            result.alreadyFit = compressed.alreadyFit
            result.status = "passed"
        } catch {
            result.error = String(describing: error)
        }
    }
}
#endif
