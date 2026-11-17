import UIKit

enum ArcFont {
    static func text(
        _ style: UIFont.TextStyle,
        weight: UIFont.Weight = .regular,
        maximumPointSize: CGFloat? = nil
    ) -> UIFont {
        let font = UIFont.systemFont(ofSize: defaultPointSize(for: style), weight: weight)
        return scaled(font, relativeTo: style, maximumPointSize: maximumPointSize)
    }

    /// Fixed-width digits so a ticking timer never shifts horizontally.
    static func digits(
        size: CGFloat,
        weight: UIFont.Weight = .semibold,
        relativeTo style: UIFont.TextStyle = .body,
        maximumPointSize: CGFloat? = nil
    ) -> UIFont {
        let font = UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
        return scaled(font, relativeTo: style, maximumPointSize: maximumPointSize)
    }

    private static func scaled(_ font: UIFont, relativeTo style: UIFont.TextStyle, maximumPointSize: CGFloat?) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: style)
        guard let maximumPointSize else { return metrics.scaledFont(for: font) }
        return metrics.scaledFont(for: font, maximumPointSize: maximumPointSize)
    }

    // UIFontMetrics expects the size at the default content size category and scales it itself.
    private static func defaultPointSize(for style: UIFont.TextStyle) -> CGFloat {
        let traits = UITraitCollection(preferredContentSizeCategory: .large)
        return UIFontDescriptor.preferredFontDescriptor(withTextStyle: style, compatibleWith: traits).pointSize
    }
}
