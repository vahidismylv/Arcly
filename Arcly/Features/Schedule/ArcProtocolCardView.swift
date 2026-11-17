import UIKit

final class ArcProtocolCardView: UIControl {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue, !UIAccessibility.isReduceMotionEnabled else { return }
            UIView.animate(springDuration: 0.25, bounce: 0.3) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
            }
        }
    }

    init(title: String, subtitle: String) {
        super.init(frame: .zero)
        layer.cornerRadius = ArcRadius.control + 2
        layer.cornerCurve = .continuous

        titleLabel.text = title
        titleLabel.font = ArcFont.digits(size: 20, weight: .semibold, relativeTo: .title3)
        titleLabel.textAlignment = .center

        subtitleLabel.text = subtitle
        subtitleLabel.font = ArcFont.text(.caption1)
        subtitleLabel.textColor = ArcColor.textSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        for label in [titleLabel, subtitleLabel] {
            label.adjustsFontForContentSizeCategory = true
        }

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: ArcSpacing.m - 4),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ArcSpacing.s),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ArcSpacing.s),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(ArcSpacing.m - 4))
        ])

        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityValue = subtitle
        updateAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateAppearance() {
        backgroundColor = isSelected ? ArcColor.accentMuted : ArcColor.surface
        layer.borderWidth = isSelected ? 1.5 : ArcBorder.width
        layer.borderColor = (isSelected ? ArcColor.accent : ArcColor.border).cgColor
        titleLabel.textColor = isSelected ? ArcColor.accent : ArcColor.textPrimary
        accessibilityTraits = isSelected ? [.button, .selected] : .button
    }
}
