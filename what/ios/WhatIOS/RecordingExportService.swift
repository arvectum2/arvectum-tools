import Foundation
import SwiftUI
import UIKit

enum RecordingExportSelection {
    case audio
    case transcript
    case audioAndTranscript
}

/// Temporary copies for sharing. The source audio and saved text never change.
struct PreparedRecordingExport: Identifiable {
    let id = UUID()
    let directory: URL
    let items: [URL]

    func cleanUp() {
        try? FileManager.default.removeItem(at: directory)
    }
}

enum RecordingExportService {
    enum ExportError: Error {
        case audioMissing
        case transcriptMissing
    }

    static func prepare(
        recording: RecordingEnvelope,
        audioURL: URL,
        transcript: String?,
        selection: RecordingExportSelection,
        fileManager: FileManager = .default
    ) throws -> PreparedRecordingExport {
        let includesAudio = selection == .audio || selection == .audioAndTranscript
        let includesTranscript = selection == .transcript || selection == .audioAndTranscript

        if includesAudio && !fileManager.fileExists(atPath: audioURL.path) {
            throw ExportError.audioMissing
        }
        if includesTranscript &&
            (transcript?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
            throw ExportError.transcriptMissing
        }

        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("WhatExport-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        do {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let stem = "What-\(formatter.string(from: recording.createdAt))-\(recording.id.uuidString.prefix(8))"
            var items: [URL] = []
            if includesAudio {
                let copied = directory.appendingPathComponent("\(stem).m4a")
                try fileManager.copyItem(at: audioURL, to: copied)
                items.append(copied)
            }
            if includesTranscript, let transcript {
                let copied = directory.appendingPathComponent("\(stem).txt")
                try Data(transcript.utf8).write(to: copied, options: .atomic)
                items.append(copied)
            }
            return PreparedRecordingExport(directory: directory, items: items)
        } catch {
            try? fileManager.removeItem(at: directory)
            throw error
        }
    }
}

struct RecordingShareSheet: UIViewControllerRepresentable {
    let export: PreparedRecordingExport

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: export.items, applicationActivities: nil
        )
        controller.completionWithItemsHandler = { _, _, _, _ in
            export.cleanUp()
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
