import SwiftUI
import UIKit

extension Color {
    static let arvectumMint = Color(hex: "43E5C5")
    static let arvectumPurple = Color(hex: "8B5CF6")
    static let arvectumOrange = Color(hex: "F59E42")
    static let arvectumNavy = Color(hex: "041A33")
    static let arvectumGraphite = Color(hex: "243446")

    static let habitsSecondaryText = Color(
        uiColor: UIColor { traits in
            UIColor(
                habitsHex: traits.userInterfaceStyle == .dark
                    ? "C8C8C8"
                    : "555555"
            )
        }
    )

    static let habitsControlAccent = Color(
        uiColor: UIColor { traits in
            UIColor(
                habitsHex: traits.userInterfaceStyle == .dark
                    ? "C8B1FF"
                    : "6C3FD1"
            )
        }
    )

    static let habitsWarningText = Color(
        uiColor: UIColor { traits in
            UIColor(
                habitsHex: traits.userInterfaceStyle == .dark
                    ? "FFB15C"
                    : "6A2A00"
            )
        }
    )

    static func habitsReadableAccent(for hex: String) -> Color {
        let normalized = hex.uppercased()
        let pair: (light: String, dark: String)

        switch normalized {
        case "43E5C5":
            pair = ("007A68", "43E5C5")
        case "8B5CF6":
            pair = ("6C3FD1", "B99AFF")
        case "F59E42":
            pair = ("9A4B00", "FFB15C")
        case "4F9CF9":
            pair = ("1D5FAF", "75B4FF")
        case "EC6F8C":
            pair = ("A83252", "FF9AB0")
        case "76C66B":
            pair = ("2F6F2A", "9BE28F")
        default:
            pair = ("243446", "C8C8C8")
        }

        return Color(
            uiColor: UIColor { traits in
                UIColor(
                    habitsHex: traits.userInterfaceStyle == .dark
                        ? pair.dark
                        : pair.light
                )
            }
        )
    }

    static let habitsBackground = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.035, green: 0.055, blue: 0.08, alpha: 1)
                : UIColor(red: 0.965, green: 0.972, blue: 0.98, alpha: 1)
        }
    )

    static let habitsSurface = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.10, green: 0.13, blue: 0.17, alpha: 1)
                : .white
        }
    )

    init(hex: String) {
        let cleaned = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        self.init(red: red, green: green, blue: blue)
    }
}

private extension UIColor {
    convenience init(habitsHex hex: String) {
        let cleaned = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}

enum HabitPalette {
    static let colors = [
        "43E5C5",
        "8B5CF6",
        "F59E42",
        "4F9CF9",
        "EC6F8C",
        "76C66B"
    ]

    static let symbols = [
        "checkmark",
        "drop.fill",
        "book.fill",
        "figure.walk",
        "dumbbell.fill",
        "moon.stars.fill",
        "brain.head.profile",
        "heart.fill"
    ]
}
