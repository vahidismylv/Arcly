import UIKit

final class ArcSettingsView: UIView {
    let unitControl: UISegmentedControl
    let weightLogRow = ArcToggleRow(
        title: String(localized: "Log weight"),
        subtitle: String(localized: "Show weight tracking in Progress")
    )
    let openSettingsButton = ArcButton(style: .secondary)

    private let notificationTitleLabel = UILabel()
    private let notificationDetailLabel = UILabel()

    init(unitTitles: [String]) {
        unitControl = UISegmentedControl(items: unitTitles)
        super.init(frame: .zero)
        backgroundColor = ArcColor.background
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with state: ArcSettingsViewModel.State, unitIndex: Int, animated: Bool) {
        unitControl.selectedSegmentIndex = unitIndex
        weightLogRow.toggle.setOn(state.isWeightLogEnabled, animated: animated)
        notificationTitleLabel.text = state.notificationTitle
        notificationDetailLabel.text = state.notificationDetail
        openSettingsButton.isHidden = state.notificationAccess != .denied
    }

    // MARK: - Layout

    private func setUpLayout() {
        let stack = UIStackView(arrangedSubviews: [
            ArcSectionHeaderLabel(text: String(localized: "Weight")),
            makeWeightCard(),
            ArcSectionHeaderLabel(text: String(localized: "Notifications")),
            makeNotificationsCard()
        ])
        stack.axis = .vertical
        stack.spacing = ArcSpacing.s
        stack.setCustomSpacing(ArcSpacing.l, after: stack.arrangedSubviews[1])

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.addSubview(stack)

        let content = scrollView.contentLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: ArcSpacing.m),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: ArcSpacing.m),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -ArcSpacing.m),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -ArcSpacing.l)
        ])
    }

    private func makeWeightCard() -> UIView {
        let unitLabel = makeLabel(text: String(localized: "Units"), style: .body, color: ArcColor.textPrimary)
        unitControl.accessibilityLabel = String(localized: "Weight units")
        unitControl.setContentHuggingPriority(.required, for: .horizontal)

        let unitRow = UIStackView(arrangedSubviews: [unitLabel, unitControl])
        unitRow.alignment = .center
        unitRow.spacing = ArcSpacing.m
        unitRow.isLayoutMarginsRelativeArrangement = true
        unitRow.directionalLayoutMargins = NSDirectionalEdgeInsets(top: ArcSpacing.s, leading: 0, bottom: ArcSpacing.s, trailing: 0)

        let list = UIStackView(arrangedSubviews: [unitRow, ArcSeparatorView(), weightLogRow])
        list.axis = .vertical
        return ArcCardView(content: list, insets: NSDirectionalEdgeInsets(
            top: ArcSpacing.s, leading: ArcSpacing.m, bottom: ArcSpacing.s, trailing: ArcSpacing.m
        ))
    }

    private func makeNotificationsCard() -> UIView {
        notificationTitleLabel.font = ArcFont.text(.body, weight: .semibold)
        notificationTitleLabel.textColor = ArcColor.textPrimary
        notificationDetailLabel.font = ArcFont.text(.footnote)
        notificationDetailLabel.textColor = ArcColor.textSecondary
        for label in [notificationTitleLabel, notificationDetailLabel] {
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
        }

        openSettingsButton.text = String(localized: "Open Settings")
        openSettingsButton.symbolName = "gearshape"

        let stack = UIStackView(arrangedSubviews: [notificationTitleLabel, notificationDetailLabel, openSettingsButton])
        stack.axis = .vertical
        stack.spacing = ArcSpacing.xs
        stack.setCustomSpacing(ArcSpacing.m, after: notificationDetailLabel)
        return ArcCardView(content: stack)
    }

    private func makeLabel(text: String, style: UIFont.TextStyle, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = ArcFont.text(style)
        label.textColor = color
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }
}
