import UIKit

enum AppColors {
    static let background = dynamic(
        light: UIColor(hex: 0xF2F5F8),
        dark: UIColor(hex: 0x101419)
    )

    static let surface = dynamic(
        light: UIColor(hex: 0xFFFFFF),
        dark: UIColor(hex: 0x1A2028)
    )

    static let navigationBackground = dynamic(
        light: UIColor(hex: 0xE9EEF4),
        dark: UIColor(hex: 0x141A21)
    )

    static let textPrimary = dynamic(
        light: UIColor(hex: 0x111827),
        dark: UIColor(hex: 0xF3F4F6)
    )

    static let textSecondary = dynamic(
        light: UIColor(hex: 0x4B5563),
        dark: UIColor(hex: 0x9CA3AF)
    )

    static let accent = dynamic(
        light: UIColor(hex: 0x1C63F0),
        dark: UIColor(hex: 0x69A2FF)
    )

    static let separator = dynamic(
        light: UIColor(hex: 0xD6DCE4),
        dark: UIColor(hex: 0x2A3441)
    )

    static let destructive = dynamic(
        light: UIColor(hex: 0xCF2F2F),
        dark: UIColor(hex: 0xFF7070)
    )

    static let selection = dynamic(
        light: UIColor(hex: 0xDDE9FF),
        dark: UIColor(hex: 0x2C3E60)
    )

    private static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }
}

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
