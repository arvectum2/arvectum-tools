import Foundation

/// Metadata-only migration of durable user media. Does not decode, copy,
/// rename, remove or rewrite existing recordings or recovery leftovers.
/// File types are checked to avoid following links inside an app container.
enum PrivateMediaProtection {
    static let afterFirstUnlock = FileProtectionType.completeUntilFirstUserAuthentication

    static func protect(_ url: URL, fileManager: FileManager = .default) throws {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let current = attributes[.protectionKey] as? FileProtectionType
        // Preserve the stronger Complete class when the file already has it.
        guard current != afterFirstUnlock && current != .complete else { return }
        try fileManager.setAttributes(
            [.protectionKey: afterFirstUnlock], ofItemAtPath: url.path
        )
    }

    static func migrateFiles(in directory: URL,
                             fileManager: FileManager = .default) throws {
        guard fileManager.fileExists(atPath: directory.path) else { return }
        let files = try fileManager.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.isRegularFileKey]
        )
        for file in files {
            let properties = try file.resourceValues(forKeys: [.isRegularFileKey])
            guard properties.isRegularFile == true else { continue }
            // Includes unfinished .incoming/.repair media: don't leave
            // orphaned recoverable footage in an unprotected inode.
            try protect(file, fileManager: fileManager)
        }
    }
}
