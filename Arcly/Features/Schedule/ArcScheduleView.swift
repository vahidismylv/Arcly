import UIKit

final class ArcScheduleView: UIView {
    let previewDial = ArcDialView()
    let protocolCards: [ArcProtocolCardView]
    let customHoursStepper = UIStepper()
    let startTimePicker = UIDatePicker()
    let startReminderRow = ArcToggleRow(
        title: String(localized: "Fasting start"),
        subtitle: String(localized: "Every day at your start time")
    )
    let goalReminderRow = ArcToggleRow(
        title: String(localized: "Goal reached"),
        subtitle: String(localized: "When your fast hits its goal")
    )
    let beforeEndReminderRow = ArcToggleRow(
        title: String(localized: "30 minutes left"),
        subtitle: String(localized: "Shortly before the goal")
    )

    private let customHoursLabel = UILabel()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var cardRows: [UIStackView] = []
    private lazy var customHoursCard = makeCustomHoursCard()

    init(options: [ArcScheduleViewModel.OptionContent]) {
        protocolCards = options.map { ArcProtocolCardView(title: $0.title, subtitle: $0.subtitle) }
        super.init(frame: .zero)
        backgroundColor = ArcColor.background
        setUpLayout()
        updateCardRowsAxis()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: ArcScheduleView, _: UITraitCollection) in
            view.updateCardRowsAxis()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCustomHours(_ hours: Int, isVisible: Bool, animated: Bool) {
        customHoursLabel.text = String(localized: "\(hours) hours")
        customHoursStepper.value = Double(hours)
        customHoursStepper.accessibilityValue = customHoursLabel.text

        guard customHoursCard.isHidden == isVisible else { return }
        let changes = {
            self.customHoursCard.isHidden = !isVisible
            self.customHoursCard.alpha = isVisible ? 1 : 0
            self.contentStack.layoutIfNeeded()
        }
        if animated {
            UIView.animate(springDuration: 0.35, bounce: 0, animations: changes)
        } else {
            changes()
        }
    }

    // MARK: - Layout

    private func setUpLayout() {
        contentStack.axis = .vertical
        contentStack.spacing = ArcSpacing.l

        contentStack.addArrangedSubview(makePreview())
        contentStack.addArrangedSubview(makeSection(title: String(localized: "Protocol"), content: makeCardsGrid()))
        contentStack.addArrangedSubview(customHoursCard)
        contentStack.addArrangedSubview(makeSection(
            title: String(localized: "Fasting starts at"),
            content: ArcCardView(content: makeStartTimePicker(), insets: .uniform(ArcSpacing.s))
        ))
        contentStack.addArrangedSubview(makeSection(
            title: String(localized: "Reminders"),
            content: ArcCardView(content: makeRemindersList(), insets: NSDirectionalEdgeInsets(
                top: ArcSpacing.s, leading: ArcSpacing.m, bottom: ArcSpacing.s, trailing: ArcSpacing.m
            ))
        ))
        customHoursCard.isHidden = true

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let content = scrollView.contentLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            contentStack.topAnchor.constraint(equalTo: content.topAnchor, constant: ArcSpacing.m),
            contentStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: ArcSpacing.m),
            contentStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -ArcSpacing.m),
            contentStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -ArcSpacing.l)
        ])
    }

    private func makePreview() -> UIView {
        previewDial.showsProgress = false
        previewDial.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(previewDial)
        NSLayoutConstraint.activate([
            previewDial.topAnchor.constraint(equalTo: container.topAnchor),
            previewDial.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            previewDial.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            previewDial.widthAnchor.constraint(equalToConstant: 240),
            previewDial.heightAnchor.constraint(equalTo: previewDial.widthAnchor)
        ])
        return container
    }

    private func makeCardsGrid() -> UIView {
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = ArcSpacing.s

        for start in stride(from: 0, to: protocolCards.count, by: 2) {
            let cards: [UIView] = Array(protocolCards[start..<min(start + 2, protocolCards.count)])
            // A trailing spacer keeps a lone last card at half width.
            let row = UIStackView(arrangedSubviews: cards.count == 2 ? cards : cards + [UIView()])
            row.distribution = .fillEqually
            row.spacing = ArcSpacing.s
            cardRows.append(row)
            grid.addArrangedSubview(row)
        }
        return grid
    }

    private func makeCustomHoursCard() -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = String(localized: "Fasting hours")
        titleLabel.font = ArcFont.text(.body)
        titleLabel.textColor = ArcColor.textPrimary
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0

        customHoursLabel.font = ArcFont.digits(size: 17, relativeTo: .body)
        customHoursLabel.textColor = ArcColor.accentSecondary
        customHoursLabel.adjustsFontForContentSizeCategory = true
        customHoursLabel.isAccessibilityElement = false

        customHoursStepper.accessibilityLabel = titleLabel.text
        customHoursStepper.setContentHuggingPriority(.required, for: .horizontal)

        let labels = UIStackView(arrangedSubviews: [titleLabel, customHoursLabel])
        labels.axis = .vertical
        labels.spacing = 2

        let row = UIStackView(arrangedSubviews: [labels, customHoursStepper])
        row.alignment = .center
        row.spacing = ArcSpacing.m
        return ArcCardView(content: row)
    }

    private func makeStartTimePicker() -> UIView {
        startTimePicker.datePickerMode = .time
        startTimePicker.preferredDatePickerStyle = .wheels
        startTimePicker.minuteInterval = 5
        startTimePicker.accessibilityLabel = String(localized: "Fasting starts at")
        return startTimePicker
    }

    private func makeRemindersList() -> UIView {
        let list = UIStackView()
        list.axis = .vertical
        let rows = [startReminderRow, goalReminderRow, beforeEndReminderRow]
        for (index, row) in rows.enumerated() {
            if index > 0 {
                list.addArrangedSubview(makeSeparator())
            }
            list.addArrangedSubview(row)
        }
        return list
    }

    private func makeSection(title: String, content: UIView) -> UIView {
        let header = UILabel()
        header.text = title
        header.font = ArcFont.text(.subheadline, weight: .semibold)
        header.textColor = ArcColor.textSecondary
        header.adjustsFontForContentSizeCategory = true
        header.accessibilityTraits = .header

        let section = UIStackView(arrangedSubviews: [header, content])
        section.axis = .vertical
        section.spacing = ArcSpacing.s
        return section
    }

    private func makeSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = ArcColor.separator
        separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        return separator
    }

    private func updateCardRowsAxis() {
        let isAccessibilitySize = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        for row in cardRows {
            row.axis = isAccessibilitySize ? .vertical : .horizontal
        }
    }
}
