# ArvectumDiagnostics

Shared, local-only OSLog error reporting with explicit subsystem/category and **fixed, non-personal error codes**. Does not send analytics or telemetry. No data from notification bodies, audio, files, metadata, account identifiers, dynamic exception descriptions or user-entered strings may be logged.

Products retain their own localized user-facing errors and domain error enums. This helper does **not** change error handling, retry policies, consent or UI. Present consumers: What? Watch recording failures and ChickMark backup-import failures. Other products opt in only at reviewed, privacy-safe failure boundaries.
