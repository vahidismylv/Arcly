import UIKit

final class ArcFastEditView: UIView {
    let startPicker = UIDatePicker()
    let endPicker = UIDatePicker()

    private let summaryLabel = UILabel()
    private let errorLabel = UILabel()
    private let errorRow = UIStackView()
    private var pickerRows: [UIStackView] = []
    private lazy var endRow = makePickerRow(title: String(localized: "End"), picker: endPicker)
    private let endSeparator = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ArcColor.background
        setUpLayout()
        updatePickerRowsAxis()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: ArcFastEditView, _: UITraitCollection) in
            view.updatePickerRowsAxis()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with state: ArcFastEditViewModel.State) {
        startPicker.maximumDate = state.maximumDate
        endPicker.maximumDate = state.maximumDate
        if startPicker.date != state.startDate {
            startPicker.date = state.startDate
        }
        if let endDate = state.endDate, endPicker.date != endDate {
            endPicker.date = endDate
        }

        let isRunning = state.endDate == nil
        endRow.isHidden = isRunning
        endSeparator.isHidden = isRunning

        summaryLabel.text = state.summary
        errorLabel.text = state.errorMessage
        errorRow.accessibilityLabel = state.errorMessage
        errorRow.isHidden = state.errorMessage == nil
    }

    // MARK: - Layout

    private func setUpLayout() {
        endSeparator.backgroundColor = ArcColor.separator
        endSeparator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true

        let pickers = UIStackView(arrangedSubviews: [
            makePickerRow(title: String(localized: "Start"), picker: startPicker),
            endSeparator,
            endRow
        ])
        pickers.axis = .vertical

        summaryLabel.font = ArcFont.text(.subheadline)
        summaryLabel.textColor = ArcColor.textSecondary
        summaryLabel.numberOfLines = 0
        summaryLabel.adjustsFontForContentSizeCategory = true

        setUpErrorRow()

        let stack = UIStackView(arrangedSubviews: [
            ArcCardView(content: pickers, insets: NSDirectionalEdgeInsets(
                top: ArcSpacing.s, leading: ArcSpacing.m, bottom: ArcSpacing.s, trailing: ArcSpacing.m
            )),
            summaryLabel,
            errorRow
        ])
        stack.axis = .vertical
        stack.spacing = ArcSpacing.m
        stack.setCustomSpacing(ArcSpacing.s, after: summaryLabel)

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.addSubview(stack)

        let content = scrollView.contentLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: ArcSpacing.m),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: ArcSpacing.m),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -ArcSpacing.m),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -ArcSpacing.l)
        ])
    }

    private func setUpErrorRow() {
        let icon = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        icon.tintColor = ArcColor.error
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .subheadline)
        icon.setContentHuggingPriority(.required, for: .horizontal)

        errorLabel.font = ArcFont.text(.subheadline, weight: .medium)
        errorLabel.textColor = ArcColor.error
        errorLabel.numberOfLines = 0
        errorLabel.adjustsFontForContentSizeCategory = true

        errorRow.addArrangedSubview(icon)
        errorRow.addArrangedSubview(errorLabel)
        errorRow.spacing = ArcSpacing.s
        errorRow.alignment = .firstBaseline
        errorRow.isHidden = true
        errorRow.isAccessibilityElement = true
        errorRow.accessibilityTraits = .staticText
    }

    private func makePickerRow(title: String, picker: UIDatePicker) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = ArcFont.text(.body)
        label.textColor = ArcColor.textPrimary
        label.adjustsFontForContentSizeCategory = true

        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.accessibilityLabel = title
        picker.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [label, picker])
        row.spacing = ArcSpacing.m
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: ArcSpacing.s, leading: 0, bottom: ArcSpacing.s, trailing: 0)
        pickerRows.append(row)
        return row
    }

    private func updatePickerRowsAxis() {
        let isAccessibilitySize = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        for row in pickerRows {
            row.axis = isAccessibilitySize ? .vertical : .horizontal
            row.alignment = isAccessibilitySize ? .leading : .center
        }
    }
}
