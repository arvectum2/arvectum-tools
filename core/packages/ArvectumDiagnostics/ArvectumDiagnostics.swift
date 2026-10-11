import Foundation
import OSLog

/// Local-only operational diagnostics. Never log document text, audio,
/// notification payloads, credentials, or user-provided error descriptions.
enum ArvectumDiagnostics {
    static func failure(
        subsystem: String,
        category: String,
        operation: String,
        code: String
    ) {
        let logger = Logger(subsystem: subsystem, category: category)
        logger.error("Operation \(operation, privacy: .public) failed (\(code, privacy: .public))")
    }
}
