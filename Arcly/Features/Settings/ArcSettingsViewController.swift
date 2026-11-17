import Combine
import UIKit

final class ArcSettingsViewController: UIViewController {
    private let viewModel: ArcSettingsViewModel
    private let contentView: ArcSettingsView
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: ArcSettingsViewModel) {
        self.viewModel = viewModel
        contentView = ArcSettingsView(unitTitles: viewModel.weightUnits.map { ArcWeightFormatter.symbol(for: $0) })
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
        title = String(localized: "Settings")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak self] _ in self?.viewModel.done() }
        )
        bindControls()
        bindViewModel()
    }

    private func bindControls() {
        let unitControl = contentView.unitControl
        unitControl.addAction(UIAction { [weak self] _ in
            guard let self, viewModel.weightUnits.indices.contains(unitControl.selectedSegmentIndex) else { return }
            viewModel.selectWeightUnit(viewModel.weightUnits[unitControl.selectedSegmentIndex])
        }, for: .valueChanged)

        let toggle = contentView.weightLogRow.toggle
        toggle.addAction(UIAction { [weak self] _ in
            self?.viewModel.setWeightLogEnabled(toggle.isOn)
        }, for: .valueChanged)

        contentView.openSettingsButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.openSystemSettings() },
            for: .primaryActionTriggered
        )
    }

    private func bindViewModel() {
        viewModel.$state
            .removeDuplicates()
            .sink { [weak self] state in
                guard let self else { return }
                let unitIndex = viewModel.weightUnits.firstIndex(of: state.weightUnit) ?? 0
                contentView.configure(with: state, unitIndex: unitIndex, animated: view.window != nil)
            }
            .store(in: &cancellables)

        // The user may flip the permission in the Settings app and come straight back.
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in self?.viewModel.refreshNotificationAccess() }
            .store(in: &cancellables)
    }
}
