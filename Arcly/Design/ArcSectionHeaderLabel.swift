import UIKit

final class ArcSectionHeaderLabel: UILabel {
    init(text: String) {
        super.init(frame: .zero)
        self.text = text
        font = ArcFont.text(.headline, weight: .semibold)
        textColor = ArcColor.textPrimary
        numberOfLines = 0
        adjustsFontForContentSizeCategory = true
        accessibilityTraits = .header
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ArcSeparatorView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ArcColor.separator
        isAccessibilityElement = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 0.5)
    }
}
