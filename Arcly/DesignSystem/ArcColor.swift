import UIKit

enum ArcColor {
    static let background = UIColor(hex: 0x0E0F12)
    static let surface = UIColor(hex: 0x17181C)
    static let surfaceElevated = UIColor(hex: 0x1F2126)
    static let separator = UIColor(hex: 0x2A2C33)

    static let accent = UIColor(hex: 0x7C5CFF)
    static let accentSecondary = UIColor(hex: 0xA78BFA)

    static let textPrimary = UIColor(hex: 0xF2F2F5)
    static let textSecondary = UIColor(hex: 0x8E8E99)
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
