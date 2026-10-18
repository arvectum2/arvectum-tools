import Foundation

/// A conservative, advisory space check before exporting or importing a video.
/// It cannot guarantee future disk capacity: AVFoundation and the OS can use
/// additional space, so all write failures must still leave originals intact.
enum VideoStorageBudget {
    enum StorageError: LocalizedError {
        case insufficientSpace(required: Int64, available: Int64)

        var errorDescription: String? {
            switch self {
            case .insufficientSpace:
                return CaptureBrand.text(
                    "Недостаточно свободного места для безопасного сохранения видео. Исходные фрагменты остаются на устройстве. Освободите место и повторите восстановление.",
                    "Not enough free storage to safely save this video. Original segments remain on this device. Free up space and retry recovery."
                )
            }
        }
    }

    private static let reserveBytes: Int64 = 32 * 1024 * 1024

    /// For one clip we need a durable copy in the library. For multiple clips
    /// the movie export AND the durable library copy may coexist with sources.
    /// Allow for re-encoding growth without allocating temporary test media.
    static func requiredFreeBytes(sourceBytes: Int64, segmentCount: Int) -> Int64 {
        guard sourceBytes > 0, segmentCount > 0 else { return reserveBytes }
        let multiplier: Int64 = segmentCount == 1 ? 1 : 3
        let (scaled, overflow) = sourceBytes.multipliedReportingOverflow(by: multiplier)
        if overflow { return Int64.max }
        let (withReserve, addOverflow) = scaled.addingReportingOverflow(reserveBytes)
        return addOverflow ? Int64.max : withReserve
    }

    static func ensureCapacity(
        for clips: [URL], destination: URL,
        availableBytesOverride: Int64? = nil,
        fileManager: FileManager = .default
    ) throws {
        guard !clips.isEmpty else { return }
        var totalBytes: Int64 = 0
        for clip in clips {
            guard let value = try fileManager.attributesOfItem(atPath: clip.path)[.size]
                    as? NSNumber else { return }
            let (sum, overflow) = totalBytes.addingReportingOverflow(value.int64Value)
            totalBytes = overflow ? Int64.max : sum
        }
        let required = requiredFreeBytes(sourceBytes: totalBytes,
                                         segmentCount: clips.count)
        // Apple's ImportantUsage metric accounts for system-reclaimable space.
        // If the OS cannot report a capacity, proceed and rely on safe write
        // failures instead of preventing the user from saving anything.
        let folder = destination.deletingLastPathComponent()
        let reported = try? folder.resourceValues(forKeys: [
            .volumeAvailableCapacityForImportantUsageKey
        ]).volumeAvailableCapacityForImportantUsage
        guard let available = availableBytesOverride ?? reported else { return }
        guard available >= required else {
            throw StorageError.insufficientSpace(required: required,
                                                 available: max(0, available))
        }
    }
}
