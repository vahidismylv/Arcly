import UIKit

enum ArcColor {
    static let background = UIColor(hex: 0x101C2B)
    static let surface = UIColor(hex: 0x1C2B3B)
    static let surfaceElevated = UIColor(hex: 0x253749)
    static let border = UIColor(hex: 0x2E4256)
    static let separator = UIColor(hex: 0x2A3B4E)

    static let accent = UIColor(hex: 0xFFC69D)
    static let accentSecondary = UIColor(hex: 0xF29E72)
    static let accentMuted = UIColor(hex: 0xFFC69D, alpha: 0.16)
    static let onAccent = UIColor(hex: 0x2B1A0F)

    /// The fasting part of the day; the eating part uses the accent.
    static let fasting = UIColor(hex: 0x5D7C9C)

    static let textPrimary = UIColor(hex: 0xF5F1EA)
    static let textSecondary = UIColor(hex: 0x98A8BA)
    static let textTertiary = UIColor(hex: 0x6E8094)

    static let error = UIColor(hex: 0xFF8F87)
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
