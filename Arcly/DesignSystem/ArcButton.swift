import UIKit

final class ArcButton: UIButton {
    enum Style {
        case primary
        case secondary
        case chip
    }

    var style: Style {
        didSet { if style != oldValue { applyConfiguration() } }
    }

    var text: String? {
        didSet { if text != oldValue { applyConfiguration() } }
    }

    var symbolName: String? {
        didSet { if symbolName != oldValue { applyConfiguration() } }
    }

    var symbolColor: UIColor? {
        didSet { applyConfiguration() }
    }

    init(style: Style) {
        self.style = style
        super.init(frame: .zero)
        applyConfiguration()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (button: ArcButton, _: UITraitCollection) in
            button.applyConfiguration()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Fonts are baked into the configuration, so it is rebuilt whenever Dynamic Type changes.
    private func applyConfiguration() {
        let font = font(for: style)
        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .capsule
        configuration.baseBackgroundColor = backgroundColor(for: style)
        configuration.baseForegroundColor = foregroundColor(for: style)
        configuration.contentInsets = contentInsets(for: style)
        configuration.imagePadding = ArcSpacing.xs
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(font: font, scale: .small)
        configuration.titleLineBreakMode = .byTruncatingTail

        if let text {
            configuration.attributedTitle = AttributedString(text, attributes: AttributeContainer([.font: font]))
        }
        if let symbolName, let image = UIImage(systemName: symbolName) {
            let tint = symbolColor ?? foregroundColor(for: style)
            configuration.image = image.withTintColor(tint, renderingMode: .alwaysOriginal)
        }

        self.configuration = configuration
    }

    private func font(for style: Style) -> UIFont {
        switch style {
        case .primary, .secondary: ArcFont.text(.headline, weight: .semibold)
        case .chip: ArcFont.text(.footnote, weight: .semibold)
        }
    }

    private func backgroundColor(for style: Style) -> UIColor {
        switch style {
        case .primary: ArcColor.accent
        case .secondary: ArcColor.surfaceElevated
        case .chip: ArcColor.surface
        }
    }

    private func foregroundColor(for style: Style) -> UIColor {
        switch style {
        case .primary, .chip: ArcColor.textPrimary
        case .secondary: ArcColor.accentSecondary
        }
    }

    private func contentInsets(for style: Style) -> NSDirectionalEdgeInsets {
        switch style {
        case .primary, .secondary:
            NSDirectionalEdgeInsets(top: ArcSpacing.m, leading: ArcSpacing.l, bottom: ArcSpacing.m, trailing: ArcSpacing.l)
        case .chip:
            NSDirectionalEdgeInsets(top: ArcSpacing.s, leading: ArcSpacing.m, bottom: ArcSpacing.s, trailing: ArcSpacing.m)
        }
    }
}
