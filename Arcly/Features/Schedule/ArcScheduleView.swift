import UIKit

final class ArcScheduleView: UIView {
    let protocolCards: [ArcProtocolCardView]
    let customHoursStepper = UIStepper()
    let startTimeRow = ArcValueRow(title: String(localized: "Start"), isInteractive: true)
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
    let saveButton = ArcButton(style: .primary)

    private let horizonView = ArcHorizonView()
    private let rhythmSummaryLabel = UILabel()
    private let dayScaleView = ArcDayScaleView()
    private let goalTimeRow = ArcValueRow(title: String(localized: "Goal"), isInteractive: false)
    private let pickerContainer = UIView()
    private let customHoursLabel = UILabel()
    private let footnoteLabel = UILabel()
    private let contentStack = UIStackView()
    private var cardRows: [UIStackView] = []
    private lazy var customHoursCard = makeCustomHoursCard()

    private(set) var isPickerExpanded = false

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

    func configure(with state: ArcScheduleViewModel.State, animated: Bool) {
        rhythmSummaryLabel.text = state.rhythmSummary
        horizonView.setProgress(Double(state.fastingHours) / 24, isActive: true, animated: animated)
        dayScaleView.configure(
            fastingHours: state.fastingHours,
            startText: state.startTimeText,
            goalText: state.goalTimeText,
            accessibilityValue: state.dayScaleAccessibilityValue
        )
        startTimeRow.value = state.startTimeText
        goalTimeRow.value = state.goalTimeText
        footnoteLabel.text = state.footnote
        saveButton.isEnabled = state.canSave
        setCustomHours(state.customHours, isVisible: state.selectedOption == .custom, animated: animated)
    }

    func setPickerExpanded(_ isExpanded: Bool, animated: Bool) {
        isPickerExpanded = isExpanded
        startTimeRow.setExpanded(isExpanded, animated: animated)
        startTimeRow.accessibilityHint = isExpanded
            ? String(localized: "Hides the time picker.")
            : String(localized: "Shows a time picker.")
        animateVisibility(of: pickerContainer, isVisible: isExpanded, animated: animated)
    }

    private func setCustomHours(_ hours: Int, isVisible: Bool, animated: Bool) {
        customHoursLabel.text = String(localized: "\(hours) hours")
        customHoursStepper.value = Double(hours)
        customHoursStepper.accessibilityValue = customHoursLabel.text
        animateVisibility(of: customHoursCard, isVisible: isVisible, animated: animated)
    }

    private func animateVisibility(of view: UIView, isVisible: Bool, animated: Bool) {
        guard view.isHidden == isVisible else { return }
        let changes = {
            view.isHidden = !isVisible
            view.alpha = isVisible ? 1 : 0
            self.contentStack.layoutIfNeeded()
        }
        if animated && !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(springDuration: 0.35, bounce: 0, animations: changes)
        } else {
            changes()
        }
    }

    // MARK: - Layout

    private func setUpLayout() {
        contentStack.axis = .vertical
        contentStack.spacing = ArcSpacing.m

        let protocolHeader = ArcSectionHeaderLabel(text: String(localized: "Protocol"))
        let remindersHeader = ArcSectionHeaderLabel(text: String(localized: "Reminders"))
        [
            makeRhythmCard(),
            protocolHeader,
            makeCardsGrid(),
            customHoursCard,
            makeTimingCard(),
            remindersHeader,
            ArcCardView(content: makeRemindersList(), insets: NSDirectionalEdgeInsets(
                top: ArcSpacing.xs, leading: ArcSpacing.m, bottom: ArcSpacing.xs, trailing: ArcSpacing.m
            )),
            makeFootnote(),
            saveButton
        ].forEach(contentStack.addArrangedSubview)

        contentStack.setCustomSpacing(ArcSpacing.l, after: contentStack.arrangedSubviews[0])
        contentStack.setCustomSpacing(ArcSpacing.l, after: contentStack.arrangedSubviews[4])
        customHoursCard.isHidden = true
        pickerContainer.isHidden = true
        saveButton.text = String(localized: "Save")

        let scrollView = UIScrollView()
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
            contentStack.topAnchor.constraint(equalTo: content.topAnchor, constant: ArcSpacing.s),
            contentStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: ArcSpacing.m + 4),
            contentStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -(ArcSpacing.m + 4)),
            contentStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -ArcSpacing.l)
        ])
    }

    private func makeRhythmCard() -> UIView {
        let title = UILabel()
        title.text = String(localized: "Your rhythm")
        title.font = ArcFont.text(.title3, weight: .semibold)
        title.textColor = ArcColor.textPrimary
        title.adjustsFontForContentSizeCategory = true
        title.accessibilityTraits = .header

        rhythmSummaryLabel.font = ArcFont.text(.subheadline, weight: .medium)
        rhythmSummaryLabel.textColor = ArcColor.textSecondary
        rhythmSummaryLabel.textAlignment = .center
        rhythmSummaryLabel.numberOfLines = 0
        rhythmSummaryLabel.adjustsFontForContentSizeCategory = true

        let horizonHeight = horizonView.heightAnchor.constraint(equalTo: horizonView.widthAnchor, multiplier: 0.3)
        horizonHeight.priority = .defaultHigh
        horizonHeight.isActive = true

        let stack = UIStackView(arrangedSubviews: [title, horizonView, rhythmSummaryLabel])
        stack.axis = .vertical
        stack.spacing = ArcSpacing.s
        return ArcCardView(content: stack)
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
        customHoursLabel.textColor = ArcColor.accent
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

    private func makeTimingCard() -> UIView {
        startTimePicker.datePickerMode = .time
        startTimePicker.preferredDatePickerStyle = .wheels
        startTimePicker.minuteInterval = 5
        startTimePicker.accessibilityLabel = String(localized: "Fasting starts at")
        startTimePicker.translatesAutoresizingMaskIntoConstraints = false
        pickerContainer.addSubview(startTimePicker)
        NSLayoutConstraint.activate([
            startTimePicker.topAnchor.constraint(equalTo: pickerContainer.topAnchor),
            startTimePicker.centerXAnchor.constraint(equalTo: pickerContainer.centerXAnchor),
            startTimePicker.bottomAnchor.constraint(equalTo: pickerContainer.bottomAnchor),
            startTimePicker.widthAnchor.constraint(lessThanOrEqualTo: pickerContainer.widthAnchor)
        ])

        let scaleContainer = UIView()
        dayScaleView.translatesAutoresizingMaskIntoConstraints = false
        scaleContainer.addSubview(dayScaleView)
        NSLayoutConstraint.activate([
            dayScaleView.topAnchor.constraint(equalTo: scaleContainer.topAnchor, constant: ArcSpacing.m),
            dayScaleView.leadingAnchor.constraint(equalTo: scaleContainer.leadingAnchor, constant: ArcSpacing.m),
            dayScaleView.trailingAnchor.constraint(equalTo: scaleContainer.trailingAnchor, constant: -ArcSpacing.m),
            dayScaleView.bottomAnchor.constraint(equalTo: scaleContainer.bottomAnchor, constant: -ArcSpacing.s)
        ])

        let stack = UIStackView(arrangedSubviews: [
            scaleContainer,
            ArcSeparatorView(),
            startTimeRow,
            pickerContainer,
            ArcSeparatorView(),
            goalTimeRow
        ])
        stack.axis = .vertical
        let card = ArcCardView(content: stack, insets: .uniform(0))
        card.clipsToBounds = true
        return card
    }

    private func makeRemindersList() -> UIView {
        let list = UIStackView()
        list.axis = .vertical
        for (index, row) in [startReminderRow, goalReminderRow, beforeEndReminderRow].enumerated() {
            if index > 0 {
                list.addArrangedSubview(ArcSeparatorView())
            }
            list.addArrangedSubview(row)
        }
        return list
    }

    private func makeFootnote() -> UIView {
        footnoteLabel.font = ArcFont.text(.footnote)
        footnoteLabel.textColor = ArcColor.textSecondary
        footnoteLabel.textAlignment = .center
        footnoteLabel.numberOfLines = 0
        footnoteLabel.adjustsFontForContentSizeCategory = true
        return footnoteLabel
    }

    private func updateCardRowsAxis() {
        let isAccessibilitySize = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        for row in cardRows {
            row.axis = isAccessibilitySize ? .vertical : .horizontal
        }
    }
}
