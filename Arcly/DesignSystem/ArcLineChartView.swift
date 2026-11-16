import UIKit

final class ArcLineChartView: UIView {
    private enum Metrics {
        static let lineWidth: CGFloat = 2
        static let dotDiameter: CGFloat = 8
    }

    private let lineLayer = CAShapeLayer()
    private let dotLayer = CAShapeLayer()
    private var values: [Double] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        lineLayer.strokeColor = ArcColor.accentSecondary.cgColor
        lineLayer.fillColor = nil
        lineLayer.lineWidth = Metrics.lineWidth
        lineLayer.lineCap = .round
        lineLayer.lineJoin = .round

        dotLayer.fillColor = ArcColor.accentSecondary.cgColor
        dotLayer.strokeColor = ArcColor.surface.cgColor
        dotLayer.lineWidth = 2

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
