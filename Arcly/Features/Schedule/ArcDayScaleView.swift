import UIKit

/// A 24-hour bar that starts at the fasting start: the fasting part first, then the eating window.
final class ArcDayScaleView: UIView {
    private let fastingBar = UIView()
    private let eatingBar = UIView()
    private let startLabel = UILabel()
    private let goalLabel = UILabel()
    private let endLabel = UILabel()
    private var fastingWidth: NSLayoutConstraint?
    private let barContainer = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
        isAccessibilityElement = true
        accessibilityLabel = String(localized: "Your day")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(fastingHours: Int, startText: String, goalText: String, accessibilityValue: String) {
        startLabel.text = startText
        goalLabel.text = goalText
        endLabel.text = startText
        self.accessibilityValue = accessibilityValue

        fastingWidth?.isActive = false
        fastingWidth = fastingBar.widthAnchor.constraint(equalTo: barContainer.widthAnchor, multiplier: CGFloat(fastingHours) / 24)
        fastingWidth?.isActive = true
    }

    private func setUpLayout() {
        fastingBar.backgroundColor = ArcColor.fasting
        eatingBar.backgroundColor = ArcColor.accent
        barContainer.layer.cornerRadius = 5
        barContainer.clipsToBounds = true

        for bar in [fastingBar, eatingBar] {
            bar.translatesAutoresizingMaskIntoConstraints = false
            barContainer.addSubview(bar)
        }
        NSLayoutConstraint.activate([
            barContainer.heightAnchor.constraint(equalToConstant: 10),
            fastingBar.leadingAnchor.constraint(equalTo: barContainer.leadingAnchor),
            fastingBar.topAnchor.constraint(equalTo: barContainer.topAnchor),
            fastingBar.bottomAnchor.constraint(equalTo: barContainer.bottomAnchor),
            eatingBar.leadingAnchor.constraint(equalTo: fastingBar.trailingAnchor, constant: 2),
            eatingBar.trailingAnchor.constraint(equalTo: barContainer.trailingAnchor),
            eatingBar.topAnchor.constraint(equalTo: barContainer.topAnchor),
            eatingBar.bottomAnchor.constraint(equalTo: barContainer.bottomAnchor)
        ])

        for label in [startLabel, goalLabel, endLabel] {
            label.font = ArcFont.digits(size: 13, weight: .medium, relativeTo: .footnote)
            label.textColor = ArcColor.textSecondary
            label.adjustsFontForContentSizeCategory = true
        }
        goalLabel.textColor = ArcColor.textPrimary
        endLabel.textAlignment = .right

        let labels = UIStackView(arrangedSubviews: [startLabel, goalLabel, endLabel])
        labels.distribution = .equalCentering

        let legend = UIStackView(arrangedSubviews: [
            makeLegendItem(color: ArcColor.fasting, text: String(localized: "Fasting")),
            makeLegendItem(color: ArcColor.accent, text: String(localized: "Eating")),
            UIView()
        ])
        legend.spacing = ArcSpacing.m

        let stack = UIStackView(arrangedSubviews: [labels, barContainer, legend])
        stack.axis = .vertical
        stack.spacing = ArcSpacing.s
        stack.setCustomSpacing(ArcSpacing.m - 4, after: barContainer)
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func makeLegendItem(color: UIColor, text: String) -> UIView {
        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 4
        dot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 12),
            dot.heightAnchor.constraint(equalToConstant: 12)
        ])

        let label = UILabel()
        label.text = text
        label.font = ArcFont.text(.caption1)
        label.textColor = ArcColor.textSecondary
        label.adjustsFontForContentSizeCategory = true

        let item = UIStackView(arrangedSubviews: [dot, label])
        item.spacing = ArcSpacing.s - 2
        item.alignment = .center
        return item
    }
}
