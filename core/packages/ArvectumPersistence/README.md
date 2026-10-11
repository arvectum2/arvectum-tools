# ArvectumPersistence

Only stateless serialization primitives are shared. `ArvectumJSONCodec.swift` is compiled directly into the ChickMark and What? iPhone targets via XcodeGen.

**Compatibility:** The codec deliberately uses unmodified Foundation defaults. Existing on-disk JSON bytes, keys, dates and property formats must remain compatible. Changing strategies requires a separate migration and regression testing for *every* consumer.

Not shared: SwiftData/CloudKit databases, UserDefaults keys, watch transfer envelopes, audio file lifecycle, product-specific errors, consent or analytics events. Those belong to their product owners.

Logs: use Apple's OSLog framework directly with app-local categories; do not create a central event bus or copy app analytics into Core. Analytics privacy, consent, and schemas are product-owned.
