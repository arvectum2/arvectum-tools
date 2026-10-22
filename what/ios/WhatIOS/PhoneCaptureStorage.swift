import Foundation

/// Protects the recoverable, pre-commit iPhone microphone recording.
/// All operations here are metadata-only for legacy files; no personal
/// recordings are decoded, renamed, removed or rewritten during migration.
struct PhoneCaptureStorage {
    let directory: URL
    let files: FileManager

    func prepare() throws {
        try files.createDirectory(at: directory, withIntermediateDirectories: true)
        // New AVAudioFile writers inherit this policy. Existing incomplete
        // files need an explicit metadata-only upgrade.
        try PrivateMediaProtection.protect(directory, fileManager: files)
        try PrivateMediaProtection.migrateFiles(in: directory, fileManager: files)
    }

    func writeManifest<T: Encodable>(_ item: T, to path: URL) throws {
        try JSONEncoder().encode(item).write(
            to: path,
            options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        )
    }

    func protectAudioBeforeRecording(_ path: URL) throws {
        // AVAudioFile has already opened the inode, but the microphone engine
        // must not start until this has succeeded. Failure must be fail-closed.
        try PrivateMediaProtection.protect(path, fileManager: files)
    }
}
