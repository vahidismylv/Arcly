import UIKit

final class ArcStatsCoordinator {
    let navigationController = UINavigationController()

    private let store: ArcFastStore

    init(store: ArcFastStore) {
        self.store = store
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.tabBarItem = UITabBarItem(
            title: String(localized: "Stats"),
            image: UIImage(systemName: "chart.bar.xaxis"),
            selectedImage: nil
        )
    }

    func start() {
        let viewModel = ArcStatsViewModel(store: store)
        viewModel.onLogWeight = { [weak self] in self?.showWeightLog() }
        navigationController.setViewControllers([ArcStatsViewController(viewModel: viewModel)], animated: false)
    }

    private func showWeightLog() {
        let viewModel = ArcWeightLogViewModel(store: store)
        let sheet = UINavigationController(rootViewController: ArcWeightLogViewController(viewModel: viewModel))
        viewModel.onFinish = { [weak sheet] in
            sheet?.dismiss(animated: true)
        }
        sheet.sheetPresentationController?.detents = [.medium()]
        sheet.sheetPresentationController?.prefersGrabberVisible = true
        navigationController.present(sheet, animated: true)
    }
}
