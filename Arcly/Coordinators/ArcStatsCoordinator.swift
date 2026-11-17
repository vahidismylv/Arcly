import UIKit

final class ArcStatsCoordinator {
    let navigationController = UINavigationController()

    private let store: ArcFastStore

    init(store: ArcFastStore) {
        self.store = store
        navigationController.tabBarItem = UITabBarItem(
            title: String(localized: "Progress"),
            image: UIImage(systemName: "chart.line.uptrend.xyaxis"),
            selectedImage: nil
        )
        // The screen draws its own large title.
        navigationController.isNavigationBarHidden = true
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
