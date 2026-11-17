import UIKit

final class ArcStatCardView: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ArcColor.surface
        layer.cornerRadius = ArcRadius.card
        layer.cornerCurve = .continuous
        layer.borderWidth = ArcBorder.width
        layer.borderColor = ArcColor.border.cgColor

        titleLabel.font = ArcFont.text(.footnote, weight: .medium)
        titleLabel.textColor = ArcColor.textSecondary
        titleLabel.numberOfLines = 0

        valueLabel.font = ArcFont.digits(size: 28, weight: .bold, relativeTo: .title1)
        valueLabel.textColor = ArcColor.textPrimary
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.6

        for label in [titleLabel, valueLabel] {
            label.adjustsFontForContentSizeCategory = true
        }

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = ArcSpacing.xs
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: ArcSpacing.m),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ArcSpacing.m),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ArcSpacing.m),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -ArcSpacing.m)
        ])

        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, value: String, accessibilityValue: String? = nil) {
        titleLabel.text = title
        valueLabel.text = value
        accessibilityLabel = title
        self.accessibilityValue = accessibilityValue ?? value
    }
}
