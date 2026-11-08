import UIKit

final class ArcToggleRow: UIView {
    let toggle = UISwitch()

    init(title: String, subtitle: String) {
        super.init(frame: .zero)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = ArcFont.text(.body)
        titleLabel.textColor = ArcColor.textPrimary

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = ArcFont.text(.footnote)
        subtitleLabel.textColor = ArcColor.textSecondary

        for label in [titleLabel, subtitleLabel] {
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
        }

        let labels = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labels.axis = .vertical
        labels.spacing = 2

        toggle.onTintColor = ArcColor.accent
        toggle.accessibilityLabel = title
        toggle.setContentHuggingPriority(.required, for: .horizontal)
        toggle.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [labels, toggle])
        row.alignment = .center
        row.spacing = ArcSpacing.m
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: ArcSpacing.s),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ArcSpacing.s)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
