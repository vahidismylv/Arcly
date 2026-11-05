import UIKit

struct ArcDialModel: Equatable {
    /// Positions on the dial are fractions of a day: 0 is midnight at the top, 0.5 is noon at the bottom.
    var fastingWindowStart: Double
    var fastingWindowLength: Double
    var currentTime: Double
    var progress: Double
    var isGoalReached: Bool
    var phase: String
    var elapsed: String
    var detail: String
    var accessibilityValue: String
}

final class ArcDialView: UIView {
    private enum Metrics {
        static let outerLineWidth: CGFloat = 10
        static let progressLineWidth: CGFloat = 14
        static let markerDiameter: CGFloat = 14
        static let tickGap: CGFloat = 6
        static let majorTickLength: CGFloat = 8
        static let minorTickLength: CGFloat = 4
        static let labelGap: CGFloat = 12
        static let progressGap: CGFloat = 14
        static let labeledHours = [0, 6, 12, 18]
    }

    private let eatingLayer = CAShapeLayer()
    private let fastingLayer = CAShapeLayer()
    private let tickLayer = CAShapeLayer()
    private let progressContainer = CALayer()
    private let progressTrackLayer = CAShapeLayer()
    private let progressGradient = CAGradientLayer()
    private let progressMask = CAShapeLayer()
    private let markerLayer = CAShapeLayer()

    private let hourLabels: [Int: UILabel]
    private let phaseLabel = UILabel()
    private let elapsedLabel = UILabel()
    private let detailLabel = UILabel()

    private var model: ArcDialModel?

    override init(frame: CGRect) {
        hourLabels = Dictionary(uniqueKeysWithValues: Metrics.labeledHours.map { ($0, Self.makeHourLabel(hour: $0)) })
        super.init(frame: frame)
        setUpLayers()
        setUpLabels()
        isAccessibilityElement = true
        accessibilityLabel = String(localized: "Fasting timer")
        accessibilityTraits = .updatesFrequently
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with model: ArcDialModel, animated: Bool) {
        let previous = self.model
        self.model = model

        phaseLabel.text = model.phase
        elapsedLabel.text = model.elapsed
        detailLabel.text = model.detail
        accessibilityValue = model.accessibilityValue

        setNeedsLayout()
        setProgress(model.progress, animated: animated)
        if previous?.isGoalReached != model.isGoalReached {
            applyGoalState(isReached: model.isGoalReached)
        }
    }

    func pulse() {
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1, 1.05, 1]
        animation.keyTimes = [0, 0.35, 1]
        animation.duration = 0.7
        animation.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]
        progressContainer.add(animation, forKey: "pulse")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Paths change every tick; without this the layers would implicitly animate each redraw.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layoutRings()
        layoutHourLabels()
        CATransaction.commit()
    }

    // MARK: - Setup

    private func setUpLayers() {
        for ring in [eatingLayer, fastingLayer] {
            ring.fillColor = UIColor.clear.cgColor
            ring.lineWidth = Metrics.outerLineWidth
        }
        eatingLayer.strokeColor = ArcColor.separator.cgColor
        fastingLayer.strokeColor = ArcColor.accent.cgColor
        fastingLayer.lineCap = .round

        tickLayer.strokeColor = ArcColor.textSecondary.cgColor
        tickLayer.lineWidth = 1
        tickLayer.lineCap = .round

        progressTrackLayer.fillColor = UIColor.clear.cgColor
        progressTrackLayer.strokeColor = ArcColor.surfaceElevated.cgColor
        progressTrackLayer.lineWidth = Metrics.progressLineWidth

        progressMask.fillColor = UIColor.clear.cgColor
        progressMask.strokeColor = UIColor.black.cgColor
        progressMask.lineWidth = Metrics.progressLineWidth
        progressMask.lineCap = .round
        progressMask.strokeEnd = 0

        progressGradient.type = .conic
        progressGradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        progressGradient.endPoint = CGPoint(x: 0.5, y: 0)
        progressGradient.colors = [ArcColor.accent.cgColor, ArcColor.accentSecondary.cgColor]
        progressGradient.mask = progressMask
        progressGradient.isHidden = true

        progressContainer.shadowColor = ArcColor.accent.cgColor
        progressContainer.shadowOffset = .zero
        progressContainer.shadowRadius = 12
        progressContainer.shadowOpacity = 0
        progressContainer.addSublayer(progressTrackLayer)
        progressContainer.addSublayer(progressGradient)

        markerLayer.fillColor = ArcColor.textPrimary.cgColor
        markerLayer.strokeColor = ArcColor.background.cgColor
        markerLayer.lineWidth = 3

        [eatingLayer, fastingLayer, tickLayer, progressContainer, markerLayer].forEach(layer.addSublayer)
    }

    private func setUpLabels() {
        hourLabels.values.forEach(addSubview)

        phaseLabel.font = ArcFont.text(.subheadline, weight: .semibold, maximumPointSize: 22)
        phaseLabel.textColor = ArcColor.textSecondary

        elapsedLabel.font = ArcFont.digits(size: 44, relativeTo: .largeTitle, maximumPointSize: 56)
        elapsedLabel.textColor = ArcColor.textPrimary

        detailLabel.font = ArcFont.text(.footnote, maximumPointSize: 20)
        detailLabel.textColor = ArcColor.textSecondary
        detailLabel.numberOfLines = 2

        let labels = [phaseLabel, elapsedLabel, detailLabel]
        for label in labels {
            label.textAlignment = .center
            label.adjustsFontForContentSizeCategory = true
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.5
        }

        let stack = UIStackView(arrangedSubviews: labels)
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = ArcSpacing.xs
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.52)
        ])
    }

    private static func makeHourLabel(hour: Int) -> UILabel {
        let label = UILabel()
        label.text = hour.formatted()
        label.font = ArcFont.digits(size: 11, weight: .medium, relativeTo: .caption2, maximumPointSize: 14)
        label.textColor = ArcColor.textSecondary
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    // MARK: - Layout

    private var dialCenter: CGPoint {
        CGPoint(x: bounds.midX, y: bounds.midY)
    }

    private var outerRadius: CGFloat {
        min(bounds.width, bounds.height) / 2 - Metrics.markerDiameter / 2
    }

    private var tickOuterRadius: CGFloat {
        outerRadius - Metrics.outerLineWidth / 2 - Metrics.tickGap
    }

    private var labelRadius: CGFloat {
        tickOuterRadius - Metrics.majorTickLength - Metrics.labelGap
    }

    private var progressRadius: CGFloat {
        labelRadius - Metrics.progressGap - Metrics.progressLineWidth / 2
    }

    private func layoutRings() {
        guard outerRadius > 0 else { return }
        let windowStart = model?.fastingWindowStart ?? 0
        let windowLength = model?.fastingWindowLength ?? 0

        eatingLayer.path = arc(radius: outerRadius, from: 0, to: 1)
        fastingLayer.path = arc(radius: outerRadius, from: windowStart, to: windowStart + windowLength)
        tickLayer.path = ticksPath()

        let progressPath = arc(radius: max(progressRadius, 0), from: 0, to: 1)
        progressContainer.frame = bounds
        progressTrackLayer.path = progressPath
        progressGradient.frame = bounds
        progressMask.frame = bounds
        progressMask.path = progressPath
        progressContainer.shadowPath = progressPath.copy(
            strokingWithWidth: Metrics.progressLineWidth,
            lineCap: .round,
            lineJoin: .round,
            miterLimit: 0
        )

        let markerSize = CGSize(width: Metrics.markerDiameter, height: Metrics.markerDiameter)
        markerLayer.bounds = CGRect(origin: .zero, size: markerSize)
        markerLayer.path = CGPath(ellipseIn: markerLayer.bounds, transform: nil)
        markerLayer.position = point(radius: outerRadius, dayFraction: model?.currentTime ?? 0)
        markerLayer.isHidden = model == nil
    }

    private func layoutHourLabels() {
        for (hour, label) in hourLabels {
            label.sizeToFit()
            label.center = point(radius: labelRadius, dayFraction: Double(hour) / 24)
        }
    }

    private func ticksPath() -> CGPath {
        let path = CGMutablePath()
        for hour in 0..<24 {
            let length = hour.isMultiple(of: 6) ? Metrics.majorTickLength : Metrics.minorTickLength
            let fraction = Double(hour) / 24
            path.move(to: point(radius: tickOuterRadius, dayFraction: fraction))
            path.addLine(to: point(radius: tickOuterRadius - length, dayFraction: fraction))
        }
        return path
    }

    private func arc(radius: CGFloat, from start: Double, to end: Double) -> CGPath {
        UIBezierPath(
            arcCenter: dialCenter,
            radius: radius,
            startAngle: angle(for: start),
            endAngle: angle(for: end),
            clockwise: true
        ).cgPath
    }

    private func point(radius: CGFloat, dayFraction: Double) -> CGPoint {
        let angle = angle(for: dayFraction)
        return CGPoint(x: dialCenter.x + radius * cos(angle), y: dialCenter.y + radius * sin(angle))
    }

    private func angle(for dayFraction: Double) -> CGFloat {
        -.pi / 2 + CGFloat(dayFraction) * 2 * .pi
    }

    // MARK: - Progress

    private func setProgress(_ progress: Double, animated: Bool) {
        let target = CGFloat(min(max(progress, 0), 1))
        progressGradient.isHidden = target == 0
        guard target != progressMask.strokeEnd else { return }

        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressMask.presentation()?.strokeEnd ?? progressMask.strokeEnd
            animation.toValue = target
            animation.duration = 0.6
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            progressMask.add(animation, forKey: "strokeEnd")
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        progressMask.strokeEnd = target
        CATransaction.commit()
    }

    private func applyGoalState(isReached: Bool) {
        let colors = isReached
            ? [ArcColor.accentSecondary.cgColor, ArcColor.accentSecondary.cgColor]
            : [ArcColor.accent.cgColor, ArcColor.accentSecondary.cgColor]
        progressGradient.colors = colors
        progressContainer.shadowOpacity = isReached ? 0.6 : 0
    }
}
