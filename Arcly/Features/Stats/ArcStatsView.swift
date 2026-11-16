import UIKit

final class ArcStatsView: UIView {
    let rangeControl: UISegmentedControl
    let logWeightButton = ArcButton(style: .primary)

    private let metricsGrid = UIStackView()
    private var metricCards: [ArcStatCardView] = []
    private var metricRows: [UIStackView] = []
    private let barChart = ArcBarChartView()
    private let weightSection = UIStackView()
    private let latestWeightLabel = UILabel()
    private let weightChangeLabel = UILabel()
    private let weightChart = ArcLineChartView()
    private let recentEntriesStack = UIStackView()

    init(ranges: [ArcStatsViewModel.Range]) {
        rangeControl = UISegmentedControl(items: ranges.map(\.title))
        super.init(frame: .zero)
        backgroundColor = ArcColor.background
        setUpLayout()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: ArcStatsView, _: UITraitCollection) in
            view.updateMetricRowsAxis()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with state: ArcStatsViewModel.State, ranges: [ArcStatsViewModel.Range], animated: Bool) {
        if metricCards.count != state.metrics.count {
            rebuildMetricCards(count: state.metrics.count)
        }
        for (card, metric) in zip(metricCards, state.metrics) {
            card.configure(title: metric.title, value: metric.value, accessibilityValue: metric.accessibilityValue)
        }

        rangeControl.selectedSegmentIndex = ranges.firstIndex(of: state.range) ?? 0
        barChart.configure(with: state.chart, animated: animated)
        barChart.accessibilityLabel = String(localized: "Fasting duration, last \(state.range.title)")
        barChart.accessibilityValue = state.chartAccessibilityValue

        weightSection.isHidden = state.weight == nil
        if let weight = state.weight {
            configureWeight(weight)
        }
    }

    // MARK: - Layout

    private func setUpLayout() {
        metricsGrid.axis = .vertical
        metricsGrid.spacing = ArcSpacing.s

        let content = UIStackView(arrangedSubviews: [metricsGrid, makeDurationSection(), makeWeightSection()])
        content.axis = .vertical
        content.spacing = ArcSpacing.l

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.addSubview(content)

        let guide = scrollView.contentLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            guide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            content.topAnchor.constraint(equalTo: guide.topAnchor, constant: ArcSpacing.s),
            content.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: ArcSpacing.m),
            content.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -ArcSpacing.m),
            content.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -ArcSpacing.l)
        ])
    }

    private func makeDurationSection() -> UIView {
        rangeControl.selectedSegmentTintColor = ArcColor.accent
        rangeControl.setTitleTextAttributes([.foregroundColor: ArcColor.textPrimary], for: .selected)
        rangeControl.setTitleTextAttributes([.foregroundColor: ArcColor.textSecondary], for: .normal)

        barChart.heightAnchor.constraint(equalToConstant: 180).isActive = true

        let card = UIStackView(arrangedSubviews: [rangeControl, barChart])
        card.axis = .vertical
        card.spacing = ArcSpacing.m
        return makeSection(title: String(localized: "Fasting duration"), content: ArcCardView(content: card))
    }

    private func makeWeightSection() -> UIView {
        latestWeightLabel.font = ArcFont.digits(size: 28, weight: .bold, relativeTo: .title1)
        latestWeightLabel.textColor = ArcColor.textPrimary
        weightChangeLabel.font = ArcFont.text(.subheadline)
        weightChangeLabel.textColor = ArcColor.textSecondary
        for label in [latestWeightLabel, weightChangeLabel] {
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
        }

        weightChart.heightAnchor.constraint(equalToConstant: 72).isActive = true
        recentEntriesStack.axis = .vertical
        recentEntriesStack.spacing = ArcSpacing.s
        logWeightButton.text = String(localized: "Log weight")
        logWeightButton.symbolName = "plus"

        let card = UIStackView(arrangedSubviews: [latestWeightLabel, weightChangeLabel, weightChart, recentEntriesStack, logWeightButton])
        card.axis = .vertical
        card.spacing = ArcSpacing.s
        card.setCustomSpacing(ArcSpacing.m, after: weightChart)
        card.setCustomSpacing(ArcSpacing.m, after: recentEntriesStack)

        let section = makeSection(title: String(localized: "Weight"), content: ArcCardView(content: card))
        weightSection.addArrangedSubview(section)
        weightSection.isHidden = true
        return weightSection
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

    private func rebuildMetricCards(count: Int) {
        metricsGrid.arrangedSubviews.forEach { $0.removeFromSuperview() }
        metricCards = (0..<count).map { _ in ArcStatCardView() }
        metricRows = stride(from: 0, to: count, by: 2).map { start in
            let cards: [UIView] = Array(metricCards[start..<min(start + 2, count)])
            let row = UIStackView(arrangedSubviews: cards.count == 2 ? cards : cards + [UIView()])
            row.distribution = .fillEqually
            row.spacing = ArcSpacing.s
            metricsGrid.addArrangedSubview(row)
            return row
        }
        updateMetricRowsAxis()
    }

    private func updateMetricRowsAxis() {
        let isAccessibilitySize = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        metricRows.forEach { $0.axis = isAccessibilitySize ? .vertical : .horizontal }
    }

    private func configureWeight(_ weight: ArcStatsViewModel.Weight) {
        latestWeightLabel.text = weight.latest
        weightChangeLabel.text = weight.change
        weightChangeLabel.isHidden = weight.change == nil
        weightChart.configure(with: weight.chartValues)
        weightChart.isHidden = weight.chartValues.count < 2

        recentEntriesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for entry in weight.recentEntries {
            recentEntriesStack.addArrangedSubview(makeEntryRow(entry))
        }
    }

    private func makeEntryRow(_ entry: ArcStatsViewModel.Weight.Entry) -> UIView {
        let dateLabel = UILabel()
        dateLabel.text = entry.date
        dateLabel.font = ArcFont.text(.subheadline)
        dateLabel.textColor = ArcColor.textSecondary

        let valueLabel = UILabel()
        valueLabel.text = entry.value
        valueLabel.font = ArcFont.digits(size: 15, weight: .medium, relativeTo: .subheadline)
        valueLabel.textColor = ArcColor.textPrimary
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        for label in [dateLabel, valueLabel] {
            label.adjustsFontForContentSizeCategory = true
        }

        let row = UIStackView(arrangedSubviews: [dateLabel, valueLabel])
        row.spacing = ArcSpacing.s
        row.isAccessibilityElement = true
        row.accessibilityLabel = entry.date
        row.accessibilityValue = entry.value
        return row
    }
}
