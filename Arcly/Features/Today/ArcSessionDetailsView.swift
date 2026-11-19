import UIKit

/// Two side-by-side facts about the current or last session, e.g. "Started · Yesterday, 20:00".
final class ArcSessionDetailsView: UIView {
    var onEdit: (() -> Void)?

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
        let column = makeLabels(for: detail)
        guard detail.isEditable else { return column }

        let control = ArcEditableDetailControl(content: column)
        control.accessibilityLabel = detail.title
        control.accessibilityValue = detail.value
        control.accessibilityHint = String(localized: "Changes when this fast started.")
        control.addAction(UIAction { [weak self] _ in self?.onEdit?() }, for: .touchUpInside)
        return control
    }

    private func makeLabels(for detail: ArcTodayViewModel.Detail) -> UIView {
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

        var valueView: UIView = valueLabel
        if detail.isEditable {
            let pencil = UIImageView(image: UIImage(systemName: "pencil"))
            pencil.tintColor = ArcColor.accent
            pencil.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .footnote, scale: .medium)
            pencil.setContentHuggingPriority(.required, for: .horizontal)
            let row = UIStackView(arrangedSubviews: [valueLabel, pencil, UIView()])
            row.spacing = ArcSpacing.xs + 2
            row.alignment = .firstBaseline
            valueView = row
        }

        let column = UIStackView(arrangedSubviews: [titleLabel, valueView])
        column.axis = .vertical
        column.spacing = 2
        column.isAccessibilityElement = true
        column.accessibilityLabel = detail.title
        column.accessibilityValue = detail.value
        return column
    }

    private final class ArcEditableDetailControl: UIControl {
        init(content: UIView) {
            super.init(frame: .zero)
            content.isUserInteractionEnabled = false
            content.isAccessibilityElement = false
            content.translatesAutoresizingMaskIntoConstraints = false
            addSubview(content)
            NSLayoutConstraint.activate([
                content.topAnchor.constraint(equalTo: topAnchor),
                content.leadingAnchor.constraint(equalTo: leadingAnchor),
                content.trailingAnchor.constraint(equalTo: trailingAnchor),
                content.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            isAccessibilityElement = true
            accessibilityTraits = .button
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var isHighlighted: Bool {
            didSet { alpha = isHighlighted ? 0.55 : 1 }
        }
    }

    private func updateAxis() {
        stack.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
    }
}
