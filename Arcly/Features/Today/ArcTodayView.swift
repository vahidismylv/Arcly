import UIKit

final class ArcTodayView: UIView {
    let settingsButton = ArcButton(style: .chip)
    let protocolChip = ArcButton(style: .chipAccent)
    let chooseRhythmRow = ArcValueRow(title: String(localized: "Choose your rhythm"), isInteractive: true)
    let detailsView = ArcSessionDetailsView()
    let actionButton = ArcButton(style: .primary)

    private let streakChip = ArcButton(style: .chip)
    private let dateLabel = UILabel()
    private let timerLabel = UILabel()
    private let statusTitleLabel = UILabel()
    private let statusDetailLabel = UILabel()
    private let horizonView = ArcHorizonView()
    private lazy var detailsCard = ArcCardView(content: detailsView)
    private lazy var firstLaunchCard = makeFirstLaunchCard()
    private let weekStrip = ArcWeekStripView()
    private let chipsStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ArcColor.background
        setUpLayout()
        updateChipsAxis()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: ArcTodayView, _: UITraitCollection) in
            view.updateChipsAxis()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with state: ArcTodayViewModel.State, animated: Bool) {
        dateLabel.text = state.dateText
        protocolChip.text = state.protocolTitle
        protocolChip.accessibilityValue = state.protocolTitle
        chooseRhythmRow.value = state.protocolTitle
        streakChip.text = state.streakText
        streakChip.isHidden = state.streakText == nil

        timerLabel.attributedText = timerText(main: state.timerMain, seconds: state.timerSeconds)
        timerLabel.accessibilityLabel = state.timerAccessibilityLabel
        statusTitleLabel.text = state.statusTitle
        statusTitleLabel.textColor = state.phase == .goalReached ? ArcColor.accent : ArcColor.textSecondary
        statusDetailLabel.text = state.statusDetail
        statusDetailLabel.isHidden = state.statusDetail.isEmpty

        let isRunning = state.phase == .fasting || state.phase == .goalReached
        horizonView.setProgress(state.horizonProgress, isActive: isRunning, animated: animated)

        detailsView.configure(with: state.details)
        detailsCard.isHidden = state.details.isEmpty
        firstLaunchCard.isHidden = state.phase != .firstLaunch
        weekStrip.configure(with: state.week, accessibilityValue: state.weekAccessibilityValue)

        updateActionButton(isFasting: state.isFasting, animated: animated)
    }

    // MARK: - Layout

    private func setUpLayout() {
        let stack = UIStackView(arrangedSubviews: [
            makeHeader(),
            makeTitleBlock(),
            makeTimerBlock(),
            horizonView,
            detailsCard,
            firstLaunchCard,
            ArcCardView(content: weekStrip)
        ])
        stack.axis = .vertical
        stack.spacing = ArcSpacing.m - 4
        stack.setCustomSpacing(ArcSpacing.m, after: stack.arrangedSubviews[1])
        stack.setCustomSpacing(0, after: stack.arrangedSubviews[2])

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.addSubview(stack)
        // The main action lives outside the scroll view so it stays reachable at any text size.
        addSubview(actionButton)

        let content = scrollView.contentLayoutGuide
        let horizonHeight = horizonView.heightAnchor.constraint(equalTo: horizonView.widthAnchor, multiplier: 0.4)
        horizonHeight.priority = .defaultHigh

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -ArcSpacing.s),

            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: ArcSpacing.xs),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: ArcSpacing.m + 4),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -(ArcSpacing.m + 4)),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -ArcSpacing.s),

            actionButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ArcSpacing.m + 4),
            actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(ArcSpacing.m + 4)),
            actionButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -ArcSpacing.m),

            horizonHeight,
            horizonView.heightAnchor.constraint(lessThanOrEqualToConstant: 180)
        ])
    }

    private func makeHeader() -> UIView {
        let wordmark = UILabel()
        wordmark.text = "arcly"
        wordmark.font = ArcFont.text(.title2, weight: .bold, maximumPointSize: 30)
        wordmark.textColor = ArcColor.textPrimary
        wordmark.adjustsFontForContentSizeCategory = true
        wordmark.accessibilityTraits = .header
        wordmark.accessibilityLabel = "Arcly"

        settingsButton.symbolName = "gearshape"
        settingsButton.accessibilityLabel = String(localized: "Settings")
        settingsButton.setContentHuggingPriority(.required, for: .horizontal)

        let header = UIStackView(arrangedSubviews: [wordmark, settingsButton])
        header.alignment = .center
        return header
    }

    private func makeTitleBlock() -> UIView {
        dateLabel.font = ArcFont.text(.caption1, weight: .semibold)
        dateLabel.textColor = ArcColor.textSecondary

        let titleLabel = UILabel()
        titleLabel.text = String(localized: "Time for yourself.")
        titleLabel.font = ArcFont.text(.largeTitle, weight: .bold)
        titleLabel.textColor = ArcColor.textPrimary
        titleLabel.accessibilityTraits = .header

        for label in [dateLabel, titleLabel] {
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
        }

        protocolChip.accessibilityLabel = String(localized: "Fasting protocol")
        protocolChip.accessibilityHint = String(localized: "Opens your schedule.")

        // Purely informative, so it shouldn't behave like a button for VoiceOver.
        streakChip.symbolName = "flame"
        streakChip.symbolColor = ArcColor.accent
        streakChip.isUserInteractionEnabled = false
        streakChip.accessibilityTraits = .staticText

        chipsStack.addArrangedSubview(protocolChip)
        chipsStack.addArrangedSubview(streakChip)
        chipsStack.spacing = ArcSpacing.s
        chipsStack.alignment = .leading

        let chipsRow = UIStackView(arrangedSubviews: [chipsStack, UIView()])
        let block = UIStackView(arrangedSubviews: [dateLabel, titleLabel, chipsRow])
        block.axis = .vertical
        block.spacing = ArcSpacing.xs
        block.setCustomSpacing(ArcSpacing.m - 4, after: titleLabel)
        return block
    }

    private func makeTimerBlock() -> UIView {
        timerLabel.textAlignment = .center
        timerLabel.adjustsFontForContentSizeCategory = true
        timerLabel.adjustsFontSizeToFitWidth = true
        timerLabel.minimumScaleFactor = 0.6
        timerLabel.accessibilityTraits = .updatesFrequently

        statusTitleLabel.font = ArcFont.text(.subheadline, weight: .medium)
        statusDetailLabel.font = ArcFont.text(.body)
        statusDetailLabel.textColor = ArcColor.textPrimary

        for label in [statusTitleLabel, statusDetailLabel] {
            label.textAlignment = .center
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
        }

        let block = UIStackView(arrangedSubviews: [timerLabel, statusTitleLabel, statusDetailLabel])
        block.axis = .vertical
        block.spacing = 2
        block.setCustomSpacing(ArcSpacing.s, after: statusTitleLabel)
        return block
    }

    private func makeFirstLaunchCard() -> UIView {
        let message = UILabel()
        message.text = String(localized: "Pick the rhythm that suits you, then start your first fast whenever you're ready.")
        message.font = ArcFont.text(.subheadline)
        message.textColor = ArcColor.textSecondary
        message.numberOfLines = 0
        message.adjustsFontForContentSizeCategory = true

        let messageContainer = UIView()
        message.translatesAutoresizingMaskIntoConstraints = false
        messageContainer.addSubview(message)
        NSLayoutConstraint.activate([
            message.topAnchor.constraint(equalTo: messageContainer.topAnchor, constant: ArcSpacing.m),
            message.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: ArcSpacing.m),
            message.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -ArcSpacing.m),
            message.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor)
        ])

        let stack = UIStackView(arrangedSubviews: [messageContainer, chooseRhythmRow])
        stack.axis = .vertical
        stack.spacing = ArcSpacing.xs
        let card = ArcCardView(content: stack, insets: .uniform(0))
        card.clipsToBounds = true
        return card
    }

    // The seconds are set smaller so the hours and minutes read first.
    private func timerText(main: String, seconds: String) -> NSAttributedString {
        let text = NSMutableAttributedString(string: main, attributes: [
            .font: ArcFont.digits(size: 64, weight: .bold, relativeTo: .largeTitle, maximumPointSize: 88),
            .foregroundColor: ArcColor.textPrimary
        ])
        text.append(NSAttributedString(string: seconds, attributes: [
            .font: ArcFont.digits(size: 28, weight: .semibold, relativeTo: .title2, maximumPointSize: 40),
            .foregroundColor: ArcColor.textSecondary
        ]))
        return text
    }

    private func updateActionButton(isFasting: Bool, animated: Bool) {
        let title = isFasting ? String(localized: "End fast") : String(localized: "Start fast")
        guard actionButton.text != title else { return }

        let changes = { self.actionButton.text = title }
        if animated && !UIAccessibility.isReduceMotionEnabled {
            UIView.transition(with: actionButton, duration: 0.25, options: .transitionCrossDissolve, animations: changes)
        } else {
            changes()
        }
    }

    private func updateChipsAxis() {
        chipsStack.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
    }
}
