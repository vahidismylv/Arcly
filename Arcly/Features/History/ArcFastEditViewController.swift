import Combine
import UIKit

final class ArcFastEditViewController: UIViewController {
    private let viewModel: ArcFastEditViewModel
    private let contentView = ArcFastEditView()
    private var cancellables = Set<AnyCancellable>()
    private var lastErrorMessage: String?

    private lazy var saveButton = UIBarButtonItem(
        systemItem: .save,
        primaryAction: UIAction { [weak self] _ in self?.viewModel.save() }
    )

    init(viewModel: ArcFastEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Edit Fast")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .cancel,
            primaryAction: UIAction { [weak self] _ in self?.viewModel.cancel() }
        )
        navigationItem.rightBarButtonItem = saveButton
        bindControls()
        bindViewModel()
    }

    private func bindControls() {
        let startPicker = contentView.startPicker
        startPicker.addAction(UIAction { [weak self] _ in
            self?.viewModel.setStartDate(startPicker.date)
        }, for: .valueChanged)

        let endPicker = contentView.endPicker
        endPicker.addAction(UIAction { [weak self] _ in
            self?.viewModel.setEndDate(endPicker.date)
        }, for: .valueChanged)
    }

    private func bindViewModel() {
        viewModel.$state
            .removeDuplicates()
            .sink { [weak self] state in self?.render(state) }
            .store(in: &cancellables)
    }

    private func render(_ state: ArcFastEditViewModel.State) {
        contentView.configure(with: state)
        saveButton.isEnabled = state.canSave
        // Unsaved edits shouldn't vanish on an accidental swipe down.
        isModalInPresentation = state.hasChanges

        if let message = state.errorMessage, message != lastErrorMessage {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
        lastErrorMessage = state.errorMessage
    }
}
