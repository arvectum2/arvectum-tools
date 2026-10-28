import AVFoundation
import Foundation

/// User-initiated Files import. Never changes or removes the source file.
enum AudioFileImportService {
    enum ImportError: LocalizedError {
        case notLocalFile, tooLarge, invalidAudio, unsupportedFormat, conversionFailed
        var errorDescription: String? {
            switch self {
            case .notLocalFile: return CaptureBrand.text("Выберите файл в «Файлах».", "Choose a file in Files.")
            case .tooLarge: return CaptureBrand.text("Аудио больше 500 МБ. Исходник не изменён.", "Audio exceeds 500 MB. Your original is safe.")
            case .invalidAudio: return CaptureBrand.text("В файле нет воспроизводимого аудио.", "The file has no playable audio.")
            case .unsupportedFormat: return CaptureBrand.text("Этот аудиоформат не поддерживается.", "This audio format is unsupported.")
            case .conversionFailed: return CaptureBrand.text("Не удалось преобразовать в M4A. Исходник сохранён.", "Could not convert to M4A. Your original is safe.")
            }
        }
    }

    struct PreparedAudio {
        let url: URL
        let duration: TimeInterval
        let disposableURL: URL?
        func cleanUp() {
            if let disposableURL { try? FileManager.default.removeItem(at: disposableURL) }
        }
    }

    static func prepare(_ source: URL) async throws -> PreparedAudio {
        guard source.isFileURL else { throw ImportError.notLocalFile }
        let attrs = try FileManager.default.attributesOfItem(atPath: source.path)
        guard let size = attrs[.size] as? NSNumber, size.int64Value > 0 else { throw ImportError.invalidAudio }
        guard size.int64Value <= 500_000_000 else { throw ImportError.tooLarge }
        let asset = AVURLAsset(url: source)
        guard !(try await asset.loadTracks(withMediaType: .audio)).isEmpty else { throw ImportError.invalidAudio }
        let duration = CMTimeGetSeconds(try await asset.load(.duration))
        guard duration.isFinite, duration >= PhoneCaptureValidation.minimumAudioDuration else { throw ImportError.invalidAudio }
        if source.pathExtension.lowercased() == "m4a" {
            guard let player = try? AVAudioPlayer(contentsOf: source),
                  player.duration >= PhoneCaptureValidation.minimumAudioDuration else { throw ImportError.invalidAudio }
            return PreparedAudio(url: source, duration: player.duration, disposableURL: nil)
        }
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A),
              exporter.supportedFileTypes.contains(.m4a) else { throw ImportError.unsupportedFormat }
        let converted = FileManager.default.temporaryDirectory.appendingPathComponent("what-import-\(UUID()).m4a")
        exporter.outputURL = converted
        exporter.outputFileType = .m4a
        // A completed export can still yield an unreadable output. Only
        // transfer cleanup ownership after validating the decoded M4A.
        var validatedOutput = false
        defer { if !validatedOutput { try? FileManager.default.removeItem(at: converted) } }
        await withCheckedContinuation { continuation in
            exporter.exportAsynchronously { continuation.resume() }
        }
        guard exporter.status == .completed,
              let player = try? AVAudioPlayer(contentsOf: converted),
              player.duration >= PhoneCaptureValidation.minimumAudioDuration else { throw ImportError.conversionFailed }
        validatedOutput = true
        return PreparedAudio(url: converted, duration: player.duration, disposableURL: converted)
    }
}

/// Bounded serial imports: a bad file must not prevent good recordings from
/// reaching the existing protected repository. Nothing is rolled back/deleted.
struct AudioBatchImportSummary: Equatable {
    static let maximumSelection = 10
    let imported: Int
    let failed: Int
    let tooMany: Bool

    @MainActor
    static func process(
        _ files: [URL], importOne: (URL) async throws -> Void
    ) async -> AudioBatchImportSummary {
        guard files.count <= maximumSelection else {
            return AudioBatchImportSummary(imported: 0, failed: 0, tooMany: true)
        }
        var imported = 0
        var failed = 0
        for file in files {
            if Task.isCancelled { break }
            do {
                try await importOne(file)
                imported += 1
            } catch {
                failed += 1
            }
        }
        return AudioBatchImportSummary(imported: imported, failed: failed, tooMany: false)
    }
}
