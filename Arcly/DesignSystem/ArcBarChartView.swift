import UIKit

struct ArcBarChartModel: Equatable {
    struct Bar: Equatable {
        let value: Double
        let label: String?
    }

    var bars: [Bar]
    var goal: Double
    var goalLabel: String
}

final class ArcBarChartView: UIView {
    private enum Metrics {
        static let axisHeight: CGFloat = 20
        static let barSpacingRatio: CGFloat = 0.35
        static let maximumBarCornerRadius: CGFloat = 4
        static let goalHeadroom = 1.25
        static let goalLabelSpacing: CGFloat = 6
    }

    private let reachedLayer = CAShapeLayer()
    private let belowGoalLayer = CAShapeLayer()
    private let goalLineLayer = CAShapeLayer()
    private let goalLabel = UILabel()
    private var axisLabels: [(index: Int, label: UILabel)] = []
    private var model = ArcBarChartModel(bars: [], goal: 0, goalLabel: "")

    override init(frame: CGRect) {
        super.init(frame: frame)
        reachedLayer.fillColor = ArcColor.accent.cgColor
        belowGoalLayer.fillColor = ArcColor.accent.withAlphaComponent(0.35).cgColor

        goalLineLayer.strokeColor = ArcColor.textSecondary.cgColor
        goalLineLayer.lineWidth = 1
        goalLineLayer.lineDashPattern = [4, 4]
        goalLineLayer.fillColor = nil

        goalLabel.font = ArcFont.digits(size: 11, weight: .medium, relativeTo: .caption2, maximumPointSize: 15)
        goalLabel.textColor = ArcColor.textSecondary
        goalLabel.adjustsFontForContentSizeCategory = true

        [belowGoalLayer, reachedLayer, goalLineLayer].forEach(layer.addSublayer)
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
        rebuildAxisLabels()

        if animated && barCountChanged {
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

    // MARK: - Drawing

    // The goal label gets its own trailing gutter so tall bars never cover it.
    private var plotRect: CGRect {
        let gutter = goalLabel.isHidden ? 0 : goalLabel.intrinsicContentSize.width + Metrics.goalLabelSpacing
        return CGRect(x: 0, y: 0, width: max(bounds.width - gutter, 0), height: max(bounds.height - Metrics.axisHeight, 0))
    }

    private var maximumValue: Double {
        let highestBar = model.bars.map(\.value).max() ?? 0
        return max(model.goal * Metrics.goalHeadroom, highestBar, 1)
    }

    private func layoutChart(animated: Bool) {
        goalLabel.isHidden = model.goal <= 0
        let plot = plotRect
        guard plot.width > 0, plot.height > 0 else { return }

        let reached = CGMutablePath()
        let belowGoal = CGMutablePath()
        for (index, bar) in model.bars.enumerated() {
            let rect = barRect(at: index, value: bar.value, in: plot)
            guard rect.height > 0 else { continue }
            let radius = min(Metrics.maximumBarCornerRadius, rect.width / 2)
            let path = UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: [.topLeft, .topRight],
                cornerRadii: CGSize(width: radius, height: radius)
            ).cgPath
            if bar.value >= model.goal {
                reached.addPath(path)
            } else {
                belowGoal.addPath(path)
            }
        }

        let goalY = plot.maxY - CGFloat(model.goal / maximumValue) * plot.height
        let goalLine = CGMutablePath()
        goalLine.move(to: CGPoint(x: plot.minX, y: goalY))
        goalLine.addLine(to: CGPoint(x: plot.maxX, y: goalY))

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        setPath(reached, on: reachedLayer, animated: animated)
        setPath(belowGoal, on: belowGoalLayer, animated: animated)
        goalLineLayer.path = goalLine
        goalLineLayer.isHidden = model.goal <= 0
        CATransaction.commit()

        goalLabel.sizeToFit()
        goalLabel.center = CGPoint(x: bounds.maxX - goalLabel.bounds.width / 2, y: goalY)

        for (index, label) in axisLabels {
            label.sizeToFit()
            let rect = barRect(at: index, value: 0, in: plot)
            label.center = CGPoint(x: rect.midX, y: plot.maxY + Metrics.axisHeight / 2)
        }
    }

    private func barRect(at index: Int, value: Double, in plot: CGRect) -> CGRect {
        let count = CGFloat(max(model.bars.count, 1))
        let slot = plot.width / count
        let width = slot * (1 - Metrics.barSpacingRatio)
        let height = CGFloat(max(value, 0) / maximumValue) * plot.height
        return CGRect(x: plot.minX + slot * CGFloat(index) + (slot - width) / 2, y: plot.maxY - height, width: width, height: height)
    }

    private func setPath(_ path: CGPath, on shapeLayer: CAShapeLayer, animated: Bool) {
        if animated, let current = shapeLayer.presentation()?.path ?? shapeLayer.path {
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
            let label = UILabel()
            label.text = text
            label.font = ArcFont.digits(size: 11, weight: .medium, relativeTo: .caption2, maximumPointSize: 15)
            label.textColor = ArcColor.textSecondary
            label.adjustsFontForContentSizeCategory = true
            addSubview(label)
            return (index, label)
        }
        setNeedsLayout()
    }
}
