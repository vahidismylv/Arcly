import CoreText
import UIKit

enum ArcFont {
    static func text(
        _ style: UIFont.TextStyle,
        weight: UIFont.Weight = .regular,
        maximumPointSize: CGFloat? = nil
    ) -> UIFont {
        let font = UIFont.systemFont(ofSize: defaultPointSize(for: style), weight: weight)
        let metrics = UIFontMetrics(forTextStyle: style)
        guard let maximumPointSize else { return metrics.scaledFont(for: font) }
        return metrics.scaledFont(for: font, maximumPointSize: maximumPointSize)
    }

    static func digits(
        size: CGFloat,
        weight: UIFont.Weight = .semibold,
        relativeTo style: UIFont.TextStyle = .body,
        maximumPointSize: CGFloat? = nil
    ) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        let descriptor = (base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor)
            .addingAttributes([
                .featureSettings: [[
                    UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                    UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector
                ]]
            ])
        let font = UIFont(descriptor: descriptor, size: size)
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
