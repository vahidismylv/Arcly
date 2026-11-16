import Combine
import UIKit

final class ArcWeightLogViewController: UIViewController {
    private let viewModel: ArcWeightLogViewModel
    private let textField = UITextField()
    private let unitLabel = UILabel()
    private let errorLabel = UILabel()
    private var cancellables = Set<AnyCancellable>()

    private lazy var saveButton = UIBarButtonItem(
        systemItem: .save,
        primaryAction: UIAction { [weak self] _ in self?.viewModel.save() }
    )

    init(viewModel: ArcWeightLogViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Log Weight")
        view.backgroundColor = ArcColor.background
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in self?.viewModel.cancel() }
        )
        navigationItem.rightBarButtonItem = saveButton
        setUpLayout()

        textField.addAction(UIAction { [weak self] _ in
            self?.viewModel.setText(self?.textField.text ?? "")
        }, for: .editingChanged)

        viewModel.$state
            .removeDuplicates()
            .sink { [weak self] state in self?.render(state) }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textField.becomeFirstResponder()
    }

    private func render(_ state: ArcWeightLogViewModel.State) {
        unitLabel.text = state.unitSymbol
        textField.attributedPlaceholder = NSAttributedString(
            string: state.placeholder,
            attributes: [.foregroundColor: ArcColor.textSecondary]
        )
        textField.accessibilityValue = textField.text?.isEmpty == false ? "\(textField.text ?? "") \(state.unitSymbol)" : nil
        errorLabel.text = state.errorMessage
        errorLabel.isHidden = state.errorMessage == nil
        saveButton.isEnabled = state.canSave
    }

    private func setUpLayout() {
        textField.font = ArcFont.digits(size: 48, weight: .bold, relativeTo: .largeTitle, maximumPointSize: 64)
        textField.textColor = ArcColor.textPrimary
        textField.tintColor = ArcColor.accent
        textField.textAlignment = .right
        textField.keyboardType = .decimalPad
        textField.adjustsFontForContentSizeCategory = true
        textField.accessibilityLabel = String(localized: "Weight")

        unitLabel.font = ArcFont.text(.title2, weight: .semibold)
        unitLabel.textColor = ArcColor.textSecondary
        unitLabel.adjustsFontForContentSizeCategory = true
        unitLabel.isAccessibilityElement = false
        unitLabel.setContentHuggingPriority(.required, for: .horizontal)

        errorLabel.font = ArcFont.text(.subheadline, weight: .medium)
        errorLabel.textColor = ArcColor.error
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.isHidden = true

        let valueRow = UIStackView(arrangedSubviews: [textField, unitLabel])
        valueRow.spacing = ArcSpacing.s
        valueRow.alignment = .firstBaseline

        let stack = UIStackView(arrangedSubviews: [valueRow, errorLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = ArcSpacing.m
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: ArcSpacing.l),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            textField.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            errorLabel.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }
}
