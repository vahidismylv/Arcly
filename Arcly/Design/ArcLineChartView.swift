import UIKit

final class ArcLineChartView: UIView {
    private enum Metrics {
        static let lineWidth: CGFloat = 2
        static let dotDiameter: CGFloat = 8
    }

    private let areaLayer = CAGradientLayer()
    private let areaMask = CAShapeLayer()
    private let lineLayer = CAShapeLayer()
    private let dotLayer = CAShapeLayer()
    private var values: [Double] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        areaLayer.colors = [ArcColor.accent.withAlphaComponent(0.22).cgColor, ArcColor.accent.withAlphaComponent(0).cgColor]
        areaLayer.startPoint = CGPoint(x: 0.5, y: 0)
        areaLayer.endPoint = CGPoint(x: 0.5, y: 1)
        areaLayer.mask = areaMask

        lineLayer.strokeColor = ArcColor.accent.cgColor
        lineLayer.fillColor = nil
        lineLayer.lineWidth = Metrics.lineWidth
        lineLayer.lineCap = .round
        lineLayer.lineJoin = .round

        dotLayer.fillColor = ArcColor.accent.cgColor
        dotLayer.strokeColor = ArcColor.surface.cgColor
        dotLayer.lineWidth = 2

        layer.addSublayer(areaLayer)
        layer.addSublayer(lineLayer)
        layer.addSublayer(dotLayer)
        isAccessibilityElement = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with values: [Double]) {
        self.values = values
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let points = plottedPoints()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let line = CGMutablePath()
        if let first = points.first, points.count > 1 {
            line.move(to: first)
            points.dropFirst().forEach { line.addLine(to: $0) }
        }
        lineLayer.path = line

        let area = CGMutablePath()
        if let first = points.first, let last = points.last, points.count > 1 {
            area.move(to: CGPoint(x: first.x, y: bounds.maxY))
            points.forEach { area.addLine(to: $0) }
            area.addLine(to: CGPoint(x: last.x, y: bounds.maxY))
            area.closeSubpath()
        }
        areaLayer.frame = bounds
        areaMask.frame = bounds
        areaMask.path = area

        if let last = points.last {
            let half = Metrics.dotDiameter / 2
            dotLayer.path = CGPath(ellipseIn: CGRect(x: last.x - half, y: last.y - half, width: half * 2, height: half * 2), transform: nil)
        } else {
            dotLayer.path = nil
        }
        CATransaction.commit()
    }

    // A flat series is drawn through the middle rather than collapsing onto an edge.
    private func plottedPoints() -> [CGPoint] {
        guard let minimum = values.min(), let maximum = values.max() else { return [] }
        let inset = Metrics.dotDiameter / 2 + Metrics.lineWidth
        let plot = bounds.insetBy(dx: inset, dy: inset)
        guard plot.width > 0, plot.height > 0 else { return [] }

        let span = maximum - minimum
        let stepX = values.count > 1 ? plot.width / CGFloat(values.count - 1) : 0
        return values.enumerated().map { index, value in
            let normalized = span > 0 ? CGFloat((value - minimum) / span) : 0.5
            let x = values.count > 1 ? plot.minX + stepX * CGFloat(index) : plot.midX
            return CGPoint(x: x, y: plot.maxY - normalized * plot.height)
        }
    }
}
