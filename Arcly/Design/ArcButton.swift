import UIKit

final class ArcButton: UIButton {
    enum Style {
        case primary
        case secondary
        case outline
        case chip
        case chipAccent
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

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue, !UIAccessibility.isReduceMotionEnabled else { return }
            UIView.animate(springDuration: 0.25, bounce: 0.3) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
            }
        }
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
        let foreground = foregroundColor(for: style)

        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .capsule
        configuration.baseBackgroundColor = backgroundColor(for: style)
        configuration.baseForegroundColor = foreground
        configuration.contentInsets = contentInsets(for: style)
        configuration.imagePadding = ArcSpacing.xs + 2
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(font: font, scale: .small)
        configuration.titleLineBreakMode = .byTruncatingTail
        configuration.titleAlignment = .center

        switch style {
        case .outline:
            configuration.background.strokeColor = ArcColor.accent
            configuration.background.strokeWidth = ArcBorder.width
        case .chip:
            configuration.background.strokeColor = ArcColor.border
            configuration.background.strokeWidth = ArcBorder.width
        case .primary, .secondary, .chipAccent:
            break
        }

        if let text {
            configuration.attributedTitle = AttributedString(text, attributes: AttributeContainer([.font: font]))
        }
        if let symbolName, let image = UIImage(systemName: symbolName) {
            configuration.image = image.withTintColor(symbolColor ?? foreground, renderingMode: .alwaysOriginal)
        }

        self.configuration = configuration
    }

    private func font(for style: Style) -> UIFont {
        switch style {
        case .primary, .secondary: ArcFont.text(.headline, weight: .semibold)
        case .outline: ArcFont.text(.subheadline, weight: .semibold)
        case .chip, .chipAccent: ArcFont.text(.subheadline, weight: .semibold)
        }
    }

    private func backgroundColor(for style: Style) -> UIColor {
        switch style {
        case .primary: ArcColor.accent
        case .secondary: ArcColor.surfaceElevated
        case .outline: .clear
        case .chip: ArcColor.surface
        case .chipAccent: ArcColor.accentMuted
        }
    }

    private func foregroundColor(for style: Style) -> UIColor {
        switch style {
        case .primary: ArcColor.onAccent
        case .secondary, .outline, .chipAccent: ArcColor.accent
        case .chip: ArcColor.textPrimary
        }
    }

    private func contentInsets(for style: Style) -> NSDirectionalEdgeInsets {
        switch style {
        case .primary, .secondary:
            NSDirectionalEdgeInsets(top: ArcSpacing.m, leading: ArcSpacing.l, bottom: ArcSpacing.m, trailing: ArcSpacing.l)
        case .outline, .chip, .chipAccent:
            NSDirectionalEdgeInsets(top: ArcSpacing.s, leading: ArcSpacing.m - 2, bottom: ArcSpacing.s, trailing: ArcSpacing.m - 2)
        }
    }
}
