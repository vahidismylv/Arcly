import UIKit

final class ArcCalendarView: UIView {
    var onSelectDay: ((Date) -> Void)?
    let previousButton = UIButton(type: .system)
    let nextButton = UIButton(type: .system)

    private let monthLabel = UILabel()
    private let weekdayStack = UIStackView()
    private let gridStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with state: ArcHistoryViewModel.State) {
        monthLabel.text = state.monthTitle
        nextButton.isEnabled = state.canShowNextMonth
        nextButton.alpha = state.canShowNextMonth ? 1 : 0

        if weekdayStack.arrangedSubviews.count != state.weekdaySymbols.count {
            weekdayStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            state.weekdaySymbols.forEach { weekdayStack.addArrangedSubview(makeWeekdayLabel($0)) }
        }

        gridStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for start in stride(from: 0, to: state.days.count, by: 7) {
            let row = UIStackView(arrangedSubviews: state.days[start..<min(start + 7, state.days.count)].map(makeDayView))
            row.distribution = .fillEqually
            gridStack.addArrangedSubview(row)
        }
    }

    // MARK: - Layout

    private func setUpLayout() {
        monthLabel.font = ArcFont.text(.headline, weight: .semibold)
        monthLabel.textColor = ArcColor.textPrimary
        monthLabel.textAlignment = .center
        monthLabel.adjustsFontForContentSizeCategory = true
        monthLabel.accessibilityTraits = .header

        configureArrow(previousButton, symbol: "chevron.left", label: String(localized: "Previous month"))
        configureArrow(nextButton, symbol: "chevron.right", label: String(localized: "Next month"))

        let header = UIStackView(arrangedSubviews: [previousButton, monthLabel, nextButton])
        header.alignment = .center

        weekdayStack.distribution = .fillEqually
        weekdayStack.isAccessibilityElement = false
        gridStack.axis = .vertical
        gridStack.spacing = 2

        let stack = UIStackView(arrangedSubviews: [header, weekdayStack, gridStack])
        stack.axis = .vertical
        stack.spacing = ArcSpacing.s
        stack.setCustomSpacing(ArcSpacing.m - 4, after: header)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func configureArrow(_ button: UIButton, symbol: String, label: String) {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: symbol)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(textStyle: .headline)
        configuration.baseForegroundColor = ArcColor.textPrimary
        configuration.contentInsets = .uniform(ArcSpacing.s + 2)
        button.configuration = configuration
        button.accessibilityLabel = label
        button.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func makeWeekdayLabel(_ symbol: String) -> UILabel {
        let label = UILabel()
        label.text = symbol.uppercased()
        label.font = ArcFont.text(.caption2, weight: .semibold, maximumPointSize: 18)
        label.textColor = ArcColor.textSecondary
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.isAccessibilityElement = false
        return label
    }

    private func makeDayView(_ day: ArcHistoryViewModel.CalendarDay?) -> UIView {
        guard let day else { return UIView() }
        let cell = ArcCalendarDayControl(day: day)
        cell.addAction(UIAction { [weak self] _ in self?.onSelectDay?(day.date) }, for: .touchUpInside)
        return cell
    }
}

private final class ArcCalendarDayControl: UIControl {
    private let background = UIView()

    init(day: ArcHistoryViewModel.CalendarDay) {
        super.init(frame: .zero)

        background.layer.cornerRadius = ArcRadius.control - 2
        background.layer.cornerCurve = .continuous
        background.backgroundColor = day.isSelected ? ArcColor.accent : .clear
        background.isUserInteractionEnabled = false

        let label = UILabel()
        label.text = day.number
        label.font = ArcFont.digits(
            size: 16,
            weight: day.isToday || day.isSelected ? .bold : .medium,
            relativeTo: .callout,
            maximumPointSize: 24
        )
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.textColor = textColor(for: day)

        let marker = makeMarker(for: day)

        let stack = UIStackView(arrangedSubviews: [label, marker])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 3
        stack.isUserInteractionEnabled = false

        for view in [background, stack] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            background.centerXAnchor.constraint(equalTo: centerXAnchor),
            background.centerYAnchor.constraint(equalTo: centerYAnchor),
            background.heightAnchor.constraint(equalTo: heightAnchor, constant: -4),
            background.widthAnchor.constraint(equalTo: background.heightAnchor),
            background.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 6),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 1)
        ])

        isEnabled = !day.isFuture
        isAccessibilityElement = true
        accessibilityLabel = day.accessibilityLabel
        accessibilityTraits = day.isSelected ? [.button, .selected] : .button
        if day.isFuture {
            accessibilityTraits.insert(.notEnabled)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            guard background.backgroundColor != ArcColor.accent else { return }
            background.backgroundColor = isHighlighted ? ArcColor.surfaceElevated : .clear
        }
    }

    private func textColor(for day: ArcHistoryViewModel.CalendarDay) -> UIColor {
        if day.isSelected { return ArcColor.onAccent }
        if day.isFuture { return ArcColor.textTertiary }
        if day.isToday { return ArcColor.accent }
        return ArcColor.textPrimary
    }

    private func makeMarker(for day: ArcHistoryViewModel.CalendarDay) -> UIView {
        let marker = UIView()
        marker.layer.cornerRadius = 2.5
        marker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            marker.widthAnchor.constraint(equalToConstant: 5),
            marker.heightAnchor.constraint(equalToConstant: 5)
        ])

        let markerColor = day.isSelected ? ArcColor.onAccent : ArcColor.accent
        switch day.status {
        case .completed:
            marker.backgroundColor = markerColor
        case .endedEarly:
            marker.backgroundColor = day.isSelected ? ArcColor.onAccent.withAlphaComponent(0.5) : ArcColor.textTertiary
        case .active:
            marker.layer.borderWidth = 1
            marker.layer.borderColor = markerColor.cgColor
        case .none:
            marker.alpha = 0
        }
        return marker
    }
}
