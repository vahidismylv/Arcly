import UIKit

final class ArcTodayView: UIView {
    let protocolChip = ArcButton(style: .chip)
    let streakChip = ArcButton(style: .chip)
    let dialView = ArcDialView()
    let actionButton = ArcButton(style: .primary)

    private let scrollView = UIScrollView()
    private let chipsStack = UIStackView()
    private let contentStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ArcColor.background
        setUpChips()
        setUpLayout()
        updateChipsAxis()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: ArcTodayView, _: UITraitCollection) in
            view.updateChipsAxis()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with state: ArcTodayViewModel.State, animated: Bool) {
        protocolChip.text = state.protocolTitle
        streakChip.text = state.streakTitle
        dialView.configure(with: state.dial, animated: animated)
        actionButton.style = state.isFasting ? .secondary : .primary
        actionButton.text = state.isFasting ? String(localized: "End Fast") : String(localized: "Start Fast")
    }

    private func setUpChips() {
        protocolChip.symbolName = "clock"
        protocolChip.symbolColor = ArcColor.textSecondary
        streakChip.symbolName = "flame.fill"
        streakChip.symbolColor = ArcColor.accentSecondary

        chipsStack.addArrangedSubview(protocolChip)
        chipsStack.addArrangedSubview(streakChip)
        chipsStack.spacing = ArcSpacing.s
        chipsStack.alignment = .center
    }

    private func setUpLayout() {
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = ArcSpacing.l
        [chipsStack, dialView, actionButton].forEach(contentStack.addArrangedSubview)

        scrollView.alwaysBounceVertical = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let content = scrollView.contentLayoutGuide
        let frame = scrollView.frameLayoutGuide
        // Centers the content on regular sizes while still letting it scroll at accessibility sizes.
        let fillHeight = content.heightAnchor.constraint(equalTo: frame.heightAnchor)
        fillHeight.priority = .defaultLow
        let dialFillsWidth = dialView.widthAnchor.constraint(equalTo: contentStack.widthAnchor)
        dialFillsWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),

            content.widthAnchor.constraint(equalTo: frame.widthAnchor),
            content.heightAnchor.constraint(greaterThanOrEqualTo: frame.heightAnchor),
            fillHeight,

            contentStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: ArcSpacing.m),
            contentStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -ArcSpacing.m),
            contentStack.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            contentStack.topAnchor.constraint(greaterThanOrEqualTo: content.topAnchor, constant: ArcSpacing.l),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -ArcSpacing.l),

            dialView.widthAnchor.constraint(lessThanOrEqualToConstant: 360),
            dialFillsWidth,
            dialView.heightAnchor.constraint(equalTo: dialView.widthAnchor),

            actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 220),
            actionButton.widthAnchor.constraint(lessThanOrEqualTo: contentStack.widthAnchor),
            chipsStack.widthAnchor.constraint(lessThanOrEqualTo: contentStack.widthAnchor)
        ])
    }

    private func updateChipsAxis() {
        chipsStack.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
    }
}
