import UIKit

struct ArcBarChartModel: Equatable {
    struct Bar: Equatable {
        /// Hours; zero means there is no bar for this slot.
        let value: Double
        /// This bar's own goal in hours, drawn as a short mark when there is no shared goal line.
        let goal: Double?
        let isGoalReached: Bool
        let label: String?
    }

    var bars: [Bar]
    /// A single dashed line, used only when every bar shares the same goal.
    var goalLine: Double?
    var goalLabel: String?
}

final class ArcBarChartView: UIView {
    private enum Metrics {
        static let axisHeight: CGFloat = 22
        static let axisLabelWidth: CGFloat = 30
        static let barSpacingRatio: CGFloat = 0.38
        static let maximumBarCornerRadius: CGFloat = 5
        static let headroom = 1.15
        static let gridLineCount = 4
        static let goalLabelSpacing: CGFloat = 6
    }

    private let gridLayer = CAShapeLayer()
    private let reachedLayer = CAShapeLayer()
    private let belowGoalLayer = CAShapeLayer()
    private let goalMarksLayer = CAShapeLayer()
    private let goalLineLayer = CAShapeLayer()
    private let goalLabel = UILabel()
    private var gridLabels: [UILabel] = []
    private var axisLabels: [(index: Int, label: UILabel)] = []
    private var model = ArcBarChartModel(bars: [], goalLine: nil, goalLabel: nil)

    override init(frame: CGRect) {
        super.init(frame: frame)
        gridLayer.strokeColor = ArcColor.separator.cgColor
        gridLayer.lineWidth = 0.5

        reachedLayer.fillColor = ArcColor.accent.cgColor
        belowGoalLayer.fillColor = ArcColor.accent.withAlphaComponent(0.35).cgColor

        goalMarksLayer.strokeColor = ArcColor.textPrimary.withAlphaComponent(0.75).cgColor
        goalMarksLayer.lineWidth = 2
        goalMarksLayer.lineCap = .round

        goalLineLayer.strokeColor = ArcColor.textSecondary.cgColor
        goalLineLayer.lineWidth = 1
        goalLineLayer.lineDashPattern = [4, 4]
        goalLineLayer.fillColor = nil

        goalLabel.font = ArcFont.digits(size: 11, weight: .semibold, relativeTo: .caption2, maximumPointSize: 15)
        goalLabel.textColor = ArcColor.accent
        goalLabel.adjustsFontForContentSizeCategory = true

        gridLabels = (0...Metrics.gridLineCount).map { _ in makeAxisLabel(alignment: .right) }
        gridLabels.forEach(addSubview)

        [gridLayer, belowGoalLayer, reachedLayer, goalMarksLayer, goalLineLayer].forEach(layer.addSublayer)
        addSubview(goalLabel)
        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with model: ArcBarChartModel, animated: Bool) {
        let barCountChanged = model.bars.count != self.model.bars.count
        self.model = model
        goalLabel.text = model.goalLabel
        goalLabel.isHidden = model.goalLine == nil
        rebuildAxisLabels()

        if animated && barCountChanged && !UIAccessibility.isReduceMotionEnabled {
            // Bar counts differ between ranges, so morphing paths would look broken; crossfade instead.
            let transition = CATransition()
            transition.type = .fade
            transition.duration = 0.25
            layer.add(transition, forKey: "rangeChange")
            layoutChart(animated: false)
        } else {
            layoutChart(animated: animated)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutChart(animated: false)
    }

    // MARK: - Scale

    private var plotRect: CGRect {
        let trailing = goalLabel.isHidden ? 0 : goalLabel.intrinsicContentSize.width + Metrics.goalLabelSpacing
        return CGRect(
            x: Metrics.axisLabelWidth,
            y: ArcSpacing.s,
            width: max(bounds.width - Metrics.axisLabelWidth - trailing, 0),
            height: max(bounds.height - Metrics.axisHeight - ArcSpacing.s, 0)
        )
    }

    // Rounded up to whole hours per grid step so the axis reads "4h, 8h, 12h, 16h".
    private var maximumValue: Double {
        let highestBar = model.bars.map(\.value).max() ?? 0
        let highestGoal = (model.bars.compactMap(\.goal) + [model.goalLine].compactMap { $0 }).max() ?? 0
        let raw = max(highestBar, highestGoal) * Metrics.headroom
        let step = max(ceil(raw / Double(Metrics.gridLineCount)), 1)
        return step * Double(Metrics.gridLineCount)
    }

    private func y(for value: Double, in plot: CGRect) -> CGFloat {
        plot.maxY - CGFloat(max(value, 0) / maximumValue) * plot.height
    }

    // MARK: - Drawing

    private func layoutChart(animated: Bool) {
        let plot = plotRect
        guard plot.width > 0, plot.height > 0 else { return }

        let grid = CGMutablePath()
        for (index, label) in gridLabels.enumerated() {
            let value = maximumValue * Double(index) / Double(Metrics.gridLineCount)
            let lineY = y(for: value, in: plot)
            grid.move(to: CGPoint(x: plot.minX, y: lineY))
            grid.addLine(to: CGPoint(x: plot.maxX, y: lineY))
            label.text = String(localized: "\(Int(value.rounded()))h")
            label.sizeToFit()
            label.frame = CGRect(
                x: 0,
                y: lineY - label.bounds.height / 2,
                width: Metrics.axisLabelWidth - ArcSpacing.xs - 2,
                height: label.bounds.height
            )
        }

        let reached = CGMutablePath()
        let belowGoal = CGMutablePath()
        let goalMarks = CGMutablePath()
        for (index, bar) in model.bars.enumerated() {
            let rect = barRect(at: index, value: bar.value, in: plot)
            if rect.height > 0 {
                let radius = min(Metrics.maximumBarCornerRadius, rect.width / 2)
                let path = UIBezierPath(
                    roundedRect: rect,
                    byRoundingCorners: [.topLeft, .topRight],
                    cornerRadii: CGSize(width: radius, height: radius)
                ).cgPath
                (bar.isGoalReached ? reached : belowGoal).addPath(path)
            }
            if model.goalLine == nil, let goal = bar.goal {
                let markY = y(for: goal, in: plot)
                goalMarks.move(to: CGPoint(x: rect.minX + 1, y: markY))
                goalMarks.addLine(to: CGPoint(x: rect.maxX - 1, y: markY))
            }
        }

        let goalLine = CGMutablePath()
        if let line = model.goalLine {
            let lineY = y(for: line, in: plot)
            goalLine.move(to: CGPoint(x: plot.minX, y: lineY))
            goalLine.addLine(to: CGPoint(x: plot.maxX, y: lineY))
            goalLabel.sizeToFit()
            goalLabel.center = CGPoint(x: bounds.maxX - goalLabel.bounds.width / 2, y: lineY)
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gridLayer.path = grid
        setPath(reached, on: reachedLayer, animated: animated)
        setPath(belowGoal, on: belowGoalLayer, animated: animated)
        goalMarksLayer.path = goalMarks
        goalLineLayer.path = goalLine
        CATransaction.commit()

        for (index, label) in axisLabels {
            label.sizeToFit()
            let rect = barRect(at: index, value: 0, in: plot)
            label.center = CGPoint(x: rect.midX, y: plot.maxY + Metrics.axisHeight / 2 + 2)
        }
    }

    private func barRect(at index: Int, value: Double, in plot: CGRect) -> CGRect {
        let count = CGFloat(max(model.bars.count, 1))
        let slot = plot.width / count
        let width = slot * (1 - Metrics.barSpacingRatio)
        let top = y(for: value, in: plot)
        return CGRect(x: plot.minX + slot * CGFloat(index) + (slot - width) / 2, y: top, width: width, height: plot.maxY - top)
    }

    private func setPath(_ path: CGPath, on shapeLayer: CAShapeLayer, animated: Bool) {
        if animated, !UIAccessibility.isReduceMotionEnabled, let current = shapeLayer.presentation()?.path ?? shapeLayer.path {
            let animation = CASpringAnimation(keyPath: "path")
            animation.fromValue = current
            animation.toValue = path
            animation.damping = 20
            animation.stiffness = 220
            animation.duration = animation.settlingDuration
            shapeLayer.add(animation, forKey: "path")
        }
        shapeLayer.path = path
    }

    private func rebuildAxisLabels() {
        axisLabels.forEach { $0.label.removeFromSuperview() }
        axisLabels = model.bars.enumerated().compactMap { index, bar in
            guard let text = bar.label else { return nil }
            let label = makeAxisLabel(alignment: .center)
            label.text = text
            addSubview(label)
            return (index, label)
        }
        setNeedsLayout()
    }

    private func makeAxisLabel(alignment: NSTextAlignment) -> UILabel {
        let label = UILabel()
        label.font = ArcFont.digits(size: 11, weight: .medium, relativeTo: .caption2, maximumPointSize: 15)
        label.textColor = ArcColor.textSecondary
        label.textAlignment = alignment
        label.adjustsFontForContentSizeCategory = true
        return label
    }
}
