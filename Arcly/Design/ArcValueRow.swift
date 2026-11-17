import UIKit

/// "Title ..... value ›" row. Only rows that actually do something show a chevron and act as buttons.
final class ArcValueRow: UIControl {
    var value: String? {
        didSet {
            valueLabel.text = value
            accessibilityValue = value
        }
    }

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let chevronView = UIImageView(image: UIImage(systemName: "chevron.right"))
    private let isInteractive: Bool

    override var isHighlighted: Bool {
        didSet {
            guard isInteractive else { return }
            backgroundColor = isHighlighted ? ArcColor.surfaceElevated : .clear
        }
    }

    init(title: String, isInteractive: Bool) {
        self.isInteractive = isInteractive
        super.init(frame: .zero)

        titleLabel.text = title
        titleLabel.font = ArcFont.text(.body)
        titleLabel.textColor = ArcColor.textPrimary

        valueLabel.font = ArcFont.text(.body, weight: .medium)
        valueLabel.textColor = ArcColor.textPrimary
        valueLabel.textAlignment = .natural

        for label in [titleLabel, valueLabel] {
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
        }
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        chevronView.tintColor = ArcColor.textSecondary
        chevronView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .footnote, scale: .medium)
        chevronView.setContentHuggingPriority(.required, for: .horizontal)
        chevronView.isHidden = !isInteractive

        let row = UIStackView(arrangedSubviews: [titleLabel, valueLabel, chevronView])
        row.alignment = .center
        row.spacing = ArcSpacing.s
        row.setCustomSpacing(ArcSpacing.m, after: titleLabel)
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: ArcSpacing.m - 2),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ArcSpacing.m),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ArcSpacing.m),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(ArcSpacing.m - 2))
        ])

        isEnabled = isInteractive
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = isInteractive ? .button : .staticText
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Rotates the chevron to point down while the row's content is expanded.
    func setExpanded(_ isExpanded: Bool, animated: Bool) {
        let changes = {
            self.chevronView.transform = isExpanded ? CGAffineTransform(rotationAngle: .pi / 2) : .identity
        }
        if animated && !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(springDuration: 0.3, bounce: 0, animations: changes)
        } else {
            changes()
        }
        valueLabel.textColor = isExpanded ? ArcColor.accent : ArcColor.textPrimary
    }
}
