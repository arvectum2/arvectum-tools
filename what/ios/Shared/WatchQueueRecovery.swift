import Foundation

/// Discovers finalized audio files that were written before the process died,
/// but whose UUIDs never reached the persisted Watch transfer queue.
///
/// Never deletes invalid/incomplete source files. The caller must persist
/// any recovered queue entries before attempting transfers.
enum WatchQueueRecovery {
    static func recover(
        from directory: URL,
        knownIDs: Set<UUID>,
        fileManager: FileManager = .default,
        decodedDuration: (URL) -> TimeInterval?
    ) -> [RecordingEnvelope] {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [
                .creationDateKey, .fileSizeKey
            ]
        ) else { return [] }

        return urls.sorted {
            $0.lastPathComponent < $1.lastPathComponent
        }.compactMap { url in
            guard url.pathExtension.lowercased() == "m4a",
                  let id = UUID(
                      uuidString: url.deletingPathExtension().lastPathComponent
                  ),
                  !knownIDs.contains(id),
                  let properties = try? url.resourceValues(forKeys: [
                      .creationDateKey, .fileSizeKey
                  ]),
                  let actualDuration = decodedDuration(url),
                  WatchCaptureValidation.isPlausibleAudio(
                      bytes: properties.fileSize ?? 0,
                      decodedDuration: actualDuration,
                      expectedDuration: 0
                  ) else { return nil }
            return RecordingEnvelope(
                id: id,
                createdAt: properties.creationDate ?? Date(),
                duration: actualDuration,
                fileName: url.lastPathComponent
            )
        }
    }
}
