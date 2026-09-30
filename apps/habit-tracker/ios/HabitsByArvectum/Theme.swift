import SwiftUI
import UIKit

extension Color {
    static let arvectumMint = Color(hex: "43E5C5")
    static let arvectumPurple = Color(hex: "8B5CF6")
    static let arvectumOrange = Color(hex: "F59E42")
    static let arvectumNavy = Color(hex: "041A33")
    static let arvectumGraphite = Color(hex: "243446")

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
