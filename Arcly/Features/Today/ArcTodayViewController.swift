import Combine
import UIKit

final class ArcTodayViewController: UIViewController {
    private let viewModel: ArcTodayViewModel
    private let contentView = ArcTodayView()
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: ArcTodayViewModel) {
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
        title = String(localized: "Today")
        bindControls()
        bindViewModel()
    }

    // The screen draws its own header, so the bar is hidden here and shown again for pushed screens.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.startUpdating()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.stopUpdating()
    }

    private func bindControls() {
        contentView.actionButton.addAction(
            UIAction { [weak self] _ in self?.actionButtonTapped() },
            for: .primaryActionTriggered
        )
        contentView.settingsButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.showSettings() },
            for: .primaryActionTriggered
        )
        contentView.protocolChip.addAction(
            UIAction { [weak self] _ in self?.viewModel.showSchedule() },
            for: .primaryActionTriggered
        )
        contentView.detailsView.onEdit = { [weak self] in self?.viewModel.editActiveFastStart() }
        contentView.chooseRhythmRow.addAction(
            UIAction { [weak self] _ in self?.viewModel.showSchedule() },
            for: .touchUpInside
        )
    }

    private func bindViewModel() {
        viewModel.$state
            .sink { [weak self] state in
                guard let self else { return }
                contentView.configure(with: state, animated: view.window != nil)
            }
            .store(in: &cancellables)

        viewModel.goalReached
            .sink { UINotificationFeedbackGenerator().notificationOccurred(.success) }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    private func actionButtonTapped() {
        guard viewModel.state.isFasting else {
            viewModel.startFast()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            return
        }
        if viewModel.needsEndConfirmation {
            presentEndConfirmation()
        } else {
            endFast()
        }
    }

    private func endFast() {
        viewModel.endFast()
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    private func presentEndConfirmation() {
        let alert = UIAlertController(
            title: String(localized: "End fast early?"),
            message: viewModel.endConfirmationMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: "Keep Fasting"), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: "End Fast"), style: .destructive) { [weak self] _ in
            self?.endFast()
        })
        present(alert, animated: true)
    }
}
