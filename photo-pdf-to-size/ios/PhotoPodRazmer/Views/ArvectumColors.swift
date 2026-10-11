import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

extension Color {
    static let arvectumMint = Color(red: 67 / 255, green: 229 / 255, blue: 197 / 255)
    static let arvectumNavy = Color(red: 4 / 255, green: 26 / 255, blue: 51 / 255)
    static let arvectumGraphite = Color(red: 36 / 255, green: 52 / 255, blue: 70 / 255)
    static let arvectumPrimaryText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? .white : UIColor(red: 4 / 255, green: 26 / 255, blue: 51 / 255, alpha: 1)
    })
    static let arvectumAccentText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 67 / 255, green: 229 / 255, blue: 197 / 255, alpha: 0.92)
            : UIColor(red: 4 / 255, green: 26 / 255, blue: 51 / 255, alpha: 0.72)
    })
    static let arvectumBorder = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor(red: 4 / 255, green: 26 / 255, blue: 51 / 255, alpha: 0.10)
    })
    static let arvectumStrongBorder = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.24)
            : UIColor(red: 4 / 255, green: 26 / 255, blue: 51 / 255, alpha: 0.22)
    })
    static let arvectumBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 4 / 255, green: 26 / 255, blue: 51 / 255, alpha: 1)
            : UIColor(red: 243 / 255, green: 245 / 255, blue: 247 / 255, alpha: 1)
    })
    static let arvectumSurface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 36 / 255, green: 52 / 255, blue: 70 / 255, alpha: 1)
            : .white
    })
}
