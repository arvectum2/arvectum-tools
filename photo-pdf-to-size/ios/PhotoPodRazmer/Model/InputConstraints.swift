import Foundation

/// Pure input rules shared across photo and PDF workflows.
/// No file I/O or UI dependency; each method can be tested independently.
enum InputConstraints {
    static let minimumBytes: Int64 = 10_000
    static let maximumBytes: Int64 = 50_000_000
    static let minimumPixels = 32
    static let maximumPixels = 12_000

    static func cleanPixels(_ raw: String) -> String {
        String(raw.filter(\.isNumber).prefix(5))
    }

    static func validPixels(_ raw: String) -> Int? {
        guard let pixels = Int(raw), (minimumPixels...maximumPixels).contains(pixels) else {
            return nil
        }
        return pixels
    }

    static func parseBytes(_ raw: String, unit: SizeUnit) -> Int64? {
        let normalized = raw.replacingOccurrences(of: ",", with: ".")
        guard let number = Double(normalized), number.isFinite, number > 0 else { return nil }
        let byteValue = number * Double(unit.multiplier)
        guard byteValue.isFinite,
              byteValue >= Double(minimumBytes) - 0.5,
              byteValue <= Double(maximumBytes) + 0.5 else { return nil }
        let bytes = Int64(byteValue.rounded())
        return (minimumBytes...maximumBytes).contains(bytes) ? bytes : nil
    }
}
