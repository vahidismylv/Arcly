import UIKit

final class ArcProtocolCardView: UIControl {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(springDuration: 0.25, bounce: 0.3) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
            }
        }
    }

    init(title: String, subtitle: String) {
        super.init(frame: .zero)
        layer.cornerRadius = ArcRadius.card
        layer.cornerCurve = .continuous
        layer.borderWidth = 2

        titleLabel.text = title
        titleLabel.font = ArcFont.digits(size: 22, weight: .bold, relativeTo: .title2)
        titleLabel.textColor = ArcColor.textPrimary

        subtitleLabel.text = subtitle
        subtitleLabel.font = ArcFont.text(.footnote)
        subtitleLabel.textColor = ArcColor.textSecondary
        subtitleLabel.numberOfLines = 0

        for label in [titleLabel, subtitleLabel] {
            label.adjustsFontForContentSizeCategory = true
        }

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = ArcSpacing.xs
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: ArcSpacing.m),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ArcSpacing.m),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ArcSpacing.m),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ArcSpacing.m)
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
        backgroundColor = isSelected ? ArcColor.surfaceElevated : ArcColor.surface
        layer.borderColor = (isSelected ? ArcColor.accent : UIColor.clear).cgColor
        accessibilityTraits = isSelected ? [.button, .selected] : .button
    }
}
