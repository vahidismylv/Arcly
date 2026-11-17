import UIKit

/// Seven day markers for the current week. The meaning is also spelled out for VoiceOver
/// and in the legend, so it never relies on colour alone.
final class ArcWeekStripView: UIView {
    private enum Metrics {
        static let markerWidth: CGFloat = 12
        static let markerHeight: CGFloat = 26
    }

    private let titleLabel = UILabel()
    private let daysStack = UIStackView()
    private let legendStack = UIStackView()
    private let layoutStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.text = String(localized: "Your week")
        titleLabel.font = ArcFont.text(.subheadline, weight: .semibold)
        titleLabel.textColor = ArcColor.textPrimary
        titleLabel.adjustsFontForContentSizeCategory = true

        daysStack.axis = .horizontal
        daysStack.spacing = ArcSpacing.s + 2

        legendStack.axis = .vertical
        legendStack.spacing = ArcSpacing.xs
        legendStack.addArrangedSubview(makeLegendItem(status: .completed, text: String(localized: "Goal reached")))
        legendStack.addArrangedSubview(makeLegendItem(status: .endedEarly, text: String(localized: "Ended early")))

        let titleColumn = UIStackView(arrangedSubviews: [titleLabel, legendStack])
        titleColumn.axis = .vertical
        titleColumn.spacing = ArcSpacing.s
        titleColumn.alignment = .leading

        layoutStack.addArrangedSubview(titleColumn)
        layoutStack.addArrangedSubview(daysStack)
        layoutStack.spacing = ArcSpacing.m
        layoutStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(layoutStack)

        NSLayoutConstraint.activate([
            layoutStack.topAnchor.constraint(equalTo: topAnchor),
            layoutStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            layoutStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            layoutStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        daysStack.setContentHuggingPriority(.required, for: .horizontal)
        updateAxis()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: ArcWeekStripView, _: UITraitCollection) in
            view.updateAxis()
        }

        isAccessibilityElement = true
        accessibilityLabel = titleLabel.text
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with days: [ArcTodayViewModel.WeekDay], accessibilityValue: String) {
        self.accessibilityValue = accessibilityValue
        daysStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for day in days {
            daysStack.addArrangedSubview(makeDayView(day))
        }
    }

    // Side by side at regular sizes; stacked when large text needs the width.
    private func updateAxis() {
        let isAccessibilitySize = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        layoutStack.axis = isAccessibilitySize ? .vertical : .horizontal
        layoutStack.alignment = isAccessibilitySize ? .leading : .center
    }

    // MARK: - Views

    private func makeDayView(_ day: ArcTodayViewModel.WeekDay) -> UIView {
        let marker = makeMarker(status: day.status, isFuture: day.isFuture)

        let label = UILabel()
        label.text = day.symbol
        label.font = ArcFont.text(.caption1, weight: day.isToday ? .bold : .medium, maximumPointSize: 20)
        label.textColor = day.isToday ? ArcColor.accent : ArcColor.textSecondary
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true

        let column = UIStackView(arrangedSubviews: [marker, label])
        column.axis = .vertical
        column.alignment = .center
        column.spacing = ArcSpacing.s - 2
        return column
    }

    private func makeMarker(status: ArcDayStatus, isFuture: Bool, height: CGFloat = Metrics.markerHeight) -> UIView {
        let marker = UIView()
        marker.layer.cornerRadius = Metrics.markerWidth / 2
        marker.layer.cornerCurve = .continuous

        switch status {
        case .completed:
            marker.backgroundColor = ArcColor.accent
        case .endedEarly:
            marker.backgroundColor = ArcColor.textTertiary
        case .active:
            marker.backgroundColor = ArcColor.accentMuted
            marker.layer.borderWidth = 1.5
            marker.layer.borderColor = ArcColor.accent.cgColor
        case .none:
            marker.backgroundColor = ArcColor.surfaceElevated
            marker.alpha = isFuture ? 0.45 : 1
        }

        marker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            marker.widthAnchor.constraint(equalToConstant: Metrics.markerWidth),
            marker.heightAnchor.constraint(equalToConstant: height)
        ])
        return marker
    }

    private func makeLegendItem(status: ArcDayStatus, text: String) -> UIView {
        let marker = makeMarker(status: status, isFuture: false, height: Metrics.markerWidth)

        let label = UILabel()
        label.text = text
        label.font = ArcFont.text(.caption1)
        label.textColor = ArcColor.textSecondary
        label.adjustsFontForContentSizeCategory = true

        let item = UIStackView(arrangedSubviews: [marker, label])
        item.spacing = ArcSpacing.s - 2
        item.alignment = .center
        return item
    }
}
