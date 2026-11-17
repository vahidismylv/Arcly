import UIKit

/// The brand motif: a point travels along an arc above the horizon while an abstract sun rises with it.
/// Purely decorative for VoiceOver; the screens that use it describe progress in text.
final class ArcHorizonView: UIView {
    private enum Metrics {
        static let horizonRatio: CGFloat = 0.8
        static let arcInsetRatio: CGFloat = 0.07
        static let arcPeakRatio: CGFloat = 0.84
        static let arcLift: CGFloat = 4
        static let sunRatio: CGFloat = 0.15
        static let dotRadius: CGFloat = 5.5
        static let haloRadius: CGFloat = 11
        static let animationDuration: CFTimeInterval = 0.8
    }

    private let glowLayer = CAGradientLayer()
    private let sunClipLayer = CALayer()
    private let sunLayer = CAGradientLayer()
    private let reflectionLayer = CAGradientLayer()
    private let horizonLineLayer = CAGradientLayer()
    private let arcTrackLayer = CAShapeLayer()
    private let arcProgressLayer = CAShapeLayer()
    private let haloLayer = CAShapeLayer()
    private let dotLayer = CAShapeLayer()

    private(set) var progress: Double = 0
    private(set) var isActive = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = false
        isUserInteractionEnabled = false
        setUpLayers()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// - Parameters:
    ///   - progress: 0...1, how far along the arc the point is.
    ///   - isActive: an inactive horizon rests at dawn with a dimmed point and sun.
    func setProgress(_ progress: Double, isActive: Bool, animated: Bool) {
        let clamped = min(max(progress, 0), 1)
        guard clamped != self.progress || isActive != self.isActive else { return }

        let previousProgress = self.progress
        self.progress = clamped
        self.isActive = isActive

        let shouldAnimate = animated && !UIAccessibility.isReduceMotionEnabled && bounds.width > 0
        CATransaction.begin()
        if shouldAnimate {
            CATransaction.setAnimationDuration(Metrics.animationDuration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
            animateDot(from: previousProgress, to: clamped)
        } else {
            CATransaction.setDisableActions(true)
        }
        applyState()
        CATransaction.commit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layoutStaticLayers()
        applyState()
        CATransaction.commit()
    }

    // MARK: - Setup

    private func setUpLayers() {
        glowLayer.type = .radial
        glowLayer.colors = [
            ArcColor.accentSecondary.withAlphaComponent(0.34).cgColor,
            ArcColor.accentSecondary.withAlphaComponent(0.1).cgColor,
            ArcColor.accentSecondary.withAlphaComponent(0).cgColor
        ]
        glowLayer.locations = [0, 0.45, 1]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1, y: 1)

        sunLayer.colors = [ArcColor.accent.cgColor, ArcColor.accentSecondary.cgColor]
        sunLayer.startPoint = CGPoint(x: 0.5, y: 0)
        sunLayer.endPoint = CGPoint(x: 0.5, y: 1)
        sunClipLayer.masksToBounds = true
        sunClipLayer.addSublayer(sunLayer)

        // An ellipse centred on the horizon, so the reflection fades out on every side.
        reflectionLayer.type = .radial
        reflectionLayer.colors = [ArcColor.accent.withAlphaComponent(0.16).cgColor, ArcColor.accent.withAlphaComponent(0).cgColor]
        reflectionLayer.startPoint = CGPoint(x: 0.5, y: 0)
        reflectionLayer.endPoint = CGPoint(x: 1, y: 1)

        horizonLineLayer.colors = [
            ArcColor.accent.withAlphaComponent(0).cgColor,
            ArcColor.accent.withAlphaComponent(0.55).cgColor,
            ArcColor.accent.withAlphaComponent(0).cgColor
        ]
        horizonLineLayer.startPoint = CGPoint(x: 0, y: 0.5)
        horizonLineLayer.endPoint = CGPoint(x: 1, y: 0.5)

        arcTrackLayer.fillColor = nil
        arcTrackLayer.strokeColor = ArcColor.textSecondary.withAlphaComponent(0.35).cgColor
        arcTrackLayer.lineWidth = 1.5
        arcTrackLayer.lineCap = .round

        arcProgressLayer.fillColor = nil
        arcProgressLayer.strokeColor = ArcColor.accent.cgColor
        arcProgressLayer.lineWidth = 2
        arcProgressLayer.lineCap = .round

        haloLayer.fillColor = ArcColor.accent.withAlphaComponent(0.22).cgColor
        dotLayer.fillColor = ArcColor.textPrimary.cgColor

        [glowLayer, sunClipLayer, reflectionLayer, horizonLineLayer, arcTrackLayer, arcProgressLayer, haloLayer, dotLayer]
            .forEach(layer.addSublayer)
    }

    // MARK: - Geometry

    private struct Arc {
        let center: CGPoint
        let radius: CGFloat
        let startAngle: CGFloat
        let endAngle: CGFloat

        func point(at progress: Double) -> CGPoint {
            let angle = startAngle + (endAngle - startAngle) * CGFloat(progress)
            return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        }

        func path(from start: Double = 0, to end: Double = 1) -> CGPath {
            UIBezierPath(
                arcCenter: center,
                radius: radius,
                startAngle: startAngle + (endAngle - startAngle) * CGFloat(start),
                endAngle: startAngle + (endAngle - startAngle) * CGFloat(end),
                clockwise: end >= start
            ).cgPath
        }
    }

    private var horizonY: CGFloat {
        bounds.height * Metrics.horizonRatio
    }

    private var sunRadius: CGFloat {
        min(bounds.width * Metrics.sunRatio, horizonY * 0.62)
    }

    // A circular segment whose chord sits just above the horizon, so the point rises and sets with it.
    private var arc: Arc {
        let left = bounds.width * Metrics.arcInsetRatio
        let right = bounds.width - left
        let chordY = horizonY - Metrics.arcLift
        let sagitta = max(chordY - Metrics.haloRadius - 2, 1) * Metrics.arcPeakRatio
        let halfChord = (right - left) / 2
        let radius = (halfChord * halfChord + sagitta * sagitta) / (2 * sagitta)
        let center = CGPoint(x: bounds.midX, y: chordY - sagitta + radius)
        return Arc(
            center: center,
            radius: radius,
            startAngle: atan2(chordY - center.y, left - center.x),
            endAngle: atan2(chordY - center.y, right - center.x)
        )
    }

    private var sunRise: CGFloat {
        isActive ? 0.15 + 0.85 * CGFloat(progress) : 0.1
    }

    private func layoutStaticLayers() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let arc = arc

        arcTrackLayer.path = arc.path()
        arcProgressLayer.path = arc.path()

        sunClipLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: horizonY)
        let radius = sunRadius
        sunLayer.bounds = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)
        sunLayer.cornerRadius = radius

        reflectionLayer.frame = CGRect(x: bounds.width * 0.15, y: horizonY, width: bounds.width * 0.7, height: bounds.height - horizonY)
        horizonLineLayer.frame = CGRect(x: 0, y: horizonY, width: bounds.width, height: 1)

        let glowSize = radius * 4
        glowLayer.bounds = CGRect(x: 0, y: 0, width: glowSize, height: glowSize)

        haloLayer.path = UIBezierPath(ovalIn: CGRect(x: -Metrics.haloRadius, y: -Metrics.haloRadius, width: Metrics.haloRadius * 2, height: Metrics.haloRadius * 2)).cgPath
        dotLayer.path = UIBezierPath(ovalIn: CGRect(x: -Metrics.dotRadius, y: -Metrics.dotRadius, width: Metrics.dotRadius * 2, height: Metrics.dotRadius * 2)).cgPath
    }

    // MARK: - State

    private func applyState() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let radius = sunRadius
        // Even at the goal the sun only just clears the horizon, staying well below the arc.
        let sunCenter = CGPoint(x: bounds.midX, y: horizonY + radius * (0.55 - 0.65 * sunRise))
        let point = arc.point(at: isActive ? progress : 0)

        sunLayer.position = sunCenter
        sunLayer.opacity = isActive ? 1 : 0.85
        glowLayer.position = sunCenter
        glowLayer.opacity = Float(0.25 + 0.75 * sunRise)
        reflectionLayer.opacity = Float(0.4 + 0.6 * sunRise)

        arcProgressLayer.strokeEnd = isActive ? CGFloat(progress) : 0

        // The point's movement comes only from the keyframe animation along the arc.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        dotLayer.position = point
        haloLayer.position = point
        CATransaction.commit()

        dotLayer.opacity = isActive ? 1 : 0.6
        haloLayer.opacity = isActive ? 1 : 0
    }

    // Implicit animation would move the point in a straight line; this keeps it on the arc.
    private func animateDot(from start: Double, to end: Double) {
        guard start != end, isActive || end > 0 else { return }
        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.path = arc.path(from: start, to: end)
        animation.calculationMode = .paced
        animation.duration = Metrics.animationDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        dotLayer.add(animation, forKey: "travel")
        haloLayer.add(animation, forKey: "travel")
    }
}
