import UIKit

/// Two side-by-side facts about the current or last session, e.g. "Started · Yesterday, 20:00".
final class ArcSessionDetailsView: UIView {
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.distribution = .fillEqually
        stack.spacing = ArcSpacing.m
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        updateAxis()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: ArcSessionDetailsView, _: UITraitCollection) in
            view.updateAxis()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with details: [ArcTodayViewModel.Detail]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for detail in details {
            stack.addArrangedSubview(makeColumn(detail))
        }
    }

    private func makeColumn(_ detail: ArcTodayViewModel.Detail) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = detail.title
        titleLabel.font = ArcFont.text(.footnote)
        titleLabel.textColor = ArcColor.textSecondary

        let valueLabel = UILabel()
        valueLabel.text = detail.value
        valueLabel.font = ArcFont.text(.body, weight: .semibold)
        valueLabel.textColor = ArcColor.textPrimary

        for label in [titleLabel, valueLabel] {
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
        }

        let column = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        column.axis = .vertical
        column.spacing = 2
        column.isAccessibilityElement = true
        column.accessibilityLabel = detail.title
        column.accessibilityValue = detail.value
        return column
    }

    private func updateAxis() {
        stack.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
    }
}
