import UIKit

final class ArcStatsView: UIView {
    let rangeControl: UISegmentedControl
    let logWeightButton = ArcButton(style: .outline)

    private let sessionsCard = ArcStatCardView()
    private let averageCard = ArcStatCardView()
    private let metricsRow = UIStackView()
    private let barChart = ArcBarChartView()
    private let chartCaptionLabel = UILabel()
    private lazy var weightCard = makeWeightCard()
    private let latestWeightLabel = UILabel()
    private let lastEntryLabel = UILabel()
    private let weightChangeLabel = UILabel()
    private let weightEmptyLabel = UILabel()
    private let weightChart = ArcLineChartView()
    private let bestStreakRow = ArcValueRow(title: String(localized: "Longest streak"), isInteractive: false)

    init(ranges: [ArcStatsViewModel.Range]) {
        rangeControl = UISegmentedControl(items: ranges.map(\.title))
        super.init(frame: .zero)
        backgroundColor = ArcColor.background
        setUpLayout()
        updateMetricsAxis()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: ArcStatsView, _: UITraitCollection) in
            view.updateMetricsAxis()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with state: ArcStatsViewModel.State, ranges: [ArcStatsViewModel.Range], animated: Bool) {
        rangeControl.selectedSegmentIndex = ranges.firstIndex(of: state.range) ?? 0
        sessionsCard.configure(title: String(localized: "Sessions"), value: state.sessionsValue)
        averageCard.configure(
            title: String(localized: "Average"),
            value: state.averageValue,
            accessibilityValue: state.averageAccessibilityValue
        )

        barChart.configure(with: state.chart, animated: animated)
        barChart.accessibilityLabel = String(localized: "Fasting duration, last \(state.range.title)")
        barChart.accessibilityValue = state.chartAccessibilityValue
        chartCaptionLabel.text = state.chartCaption
        bestStreakRow.value = state.bestStreakValue

        weightCard.isHidden = state.weight == nil
        if let weight = state.weight {
            configureWeight(weight)
        }
    }

    // MARK: - Layout

    private func setUpLayout() {
        let titleLabel = UILabel()
        titleLabel.text = String(localized: "Your progress")
        titleLabel.font = ArcFont.text(.largeTitle, weight: .bold)
        titleLabel.textColor = ArcColor.textPrimary
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityTraits = .header

        rangeControl.accessibilityLabel = String(localized: "Period")

        metricsRow.addArrangedSubview(sessionsCard)
        metricsRow.addArrangedSubview(averageCard)
        metricsRow.distribution = .fillEqually
        metricsRow.spacing = ArcSpacing.s + 4

        let content = UIStackView(arrangedSubviews: [
            titleLabel,
            rangeControl,
            metricsRow,
            makeDurationCard(),
            weightCard,
            ArcCardView(content: bestStreakRow, insets: .uniform(0))
        ])
        content.axis = .vertical
        content.spacing = ArcSpacing.m - 4
        content.setCustomSpacing(ArcSpacing.m, after: titleLabel)

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.addSubview(content)

        let guide = scrollView.contentLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            guide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            content.topAnchor.constraint(equalTo: guide.topAnchor, constant: ArcSpacing.s),
            content.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: ArcSpacing.m + 4),
            content.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -(ArcSpacing.m + 4)),
            content.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -ArcSpacing.l),
            rangeControl.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])
    }

    private func makeDurationCard() -> UIView {
        barChart.heightAnchor.constraint(equalToConstant: 200).isActive = true

        chartCaptionLabel.font = ArcFont.text(.footnote)
        chartCaptionLabel.textColor = ArcColor.textSecondary
        chartCaptionLabel.numberOfLines = 0
        chartCaptionLabel.adjustsFontForContentSizeCategory = true

        let stack = UIStackView(arrangedSubviews: [
            ArcSectionHeaderLabel(text: String(localized: "Duration")),
            barChart,
            chartCaptionLabel
        ])
        stack.axis = .vertical
        stack.spacing = ArcSpacing.m - 4
        return ArcCardView(content: stack)
    }

    private func makeWeightCard() -> UIView {
        logWeightButton.symbolName = "plus"
        logWeightButton.setContentHuggingPriority(.required, for: .horizontal)
        let header = UIStackView(arrangedSubviews: [ArcSectionHeaderLabel(text: String(localized: "Weight")), logWeightButton])
        header.alignment = .center
        header.spacing = ArcSpacing.s

        latestWeightLabel.font = ArcFont.digits(size: 32, weight: .bold, relativeTo: .title1)
        latestWeightLabel.textColor = ArcColor.textPrimary
        lastEntryLabel.font = ArcFont.text(.footnote)
        lastEntryLabel.textColor = ArcColor.textSecondary
        weightChangeLabel.font = ArcFont.text(.subheadline, weight: .medium)
        weightChangeLabel.textColor = ArcColor.textPrimary
        weightEmptyLabel.font = ArcFont.text(.subheadline)
        weightEmptyLabel.textColor = ArcColor.textSecondary
        for label in [latestWeightLabel, lastEntryLabel, weightChangeLabel, weightEmptyLabel] {
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
        }

        weightChart.heightAnchor.constraint(equalToConstant: 72).isActive = true

        let stack = UIStackView(arrangedSubviews: [header, latestWeightLabel, lastEntryLabel, weightChangeLabel, weightChart, weightEmptyLabel])
        stack.axis = .vertical
        stack.spacing = ArcSpacing.xs
        stack.setCustomSpacing(ArcSpacing.s, after: header)
        stack.setCustomSpacing(ArcSpacing.m - 4, after: weightChangeLabel)
        let card = ArcCardView(content: stack)
        card.isHidden = true
        return card
    }

    private func configureWeight(_ weight: ArcStatsViewModel.Weight) {
        logWeightButton.text = weight.buttonTitle
        latestWeightLabel.text = weight.latest
        latestWeightLabel.isHidden = weight.latest == nil
        latestWeightLabel.accessibilityValue = weight.accessibilityValue
        lastEntryLabel.text = weight.lastEntry
        lastEntryLabel.isHidden = weight.lastEntry == nil
        weightChangeLabel.text = weight.change
        weightChangeLabel.isHidden = weight.change == nil
        weightEmptyLabel.text = weight.emptyMessage
        weightEmptyLabel.isHidden = weight.emptyMessage == nil
        weightChart.configure(with: weight.chartValues)
        weightChart.isHidden = weight.chartValues.count < 2
    }

    private func updateMetricsAxis() {
        metricsRow.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
    }
}
