import Foundation

/// Shared stateless JSON serialization using Foundation's default strategies.
///
/// IMPORTANT: Default date, key and floating-point strategies preserve the
/// persisted wire representation of existing What? and ChickMark payloads.
/// Product-specific migration, schemas, files and keys remain app-owned.
enum ArvectumJSONCodec {
    static func encode<Value: Encodable>(_ value: Value) throws -> Data {
        try JSONEncoder().encode(value)
    }

    static func decode<Value: Decodable>(
        _ type: Value.Type,
        from data: Data
    ) throws -> Value {
        try JSONDecoder().decode(type, from: data)
    }
}
