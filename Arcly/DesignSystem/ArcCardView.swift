import UIKit

final class ArcCardView: UIView {
    init(content: UIView, insets: NSDirectionalEdgeInsets = .uniform(ArcSpacing.m)) {
        super.init(frame: .zero)
        backgroundColor = ArcColor.surface
        layer.cornerRadius = ArcRadius.card
        layer.cornerCurve = .continuous

        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.leading),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.trailing),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NSDirectionalEdgeInsets {
    static func uniform(_ inset: CGFloat) -> NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
    }
}
